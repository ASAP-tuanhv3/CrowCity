# Story 002: Phase dispatch loop + pcall isolation + ctx assembly

> **Epic**: tick-orchestrator
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md` (TickOrchestrator §15a spin-off; ADR-0002 + architecture.md §5.4 are the canonical spec)
**Requirement**: `TR-csm-008` (tick simultaneity rule), `TR-ccr-001` (Phase 1 ordering), `TR-ccr-011` (Phase 9 PeelDispatch), `TR-ccr-015` (phase ordering invariant), `TR-relic-007` (Phase 2 ordering), `TR-relic-008` (Phase 2 + 3 visibility), `TR-chest-016` (Phase 4 cadence), `TR-absorb-001` (Phase 3 cadence)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 — TickOrchestrator — 15 Hz Server Tick Sequencing
**ADR Decision Summary**: Phase 1..9 statically wired and dispatched in fixed order each tick; each callback wrapped in `pcall` so an exception in phase X logs and lets remaining phases continue (next tick re-runs all phases); no yields permitted inside any phase callback (yielded yet still completes phase from caller's view because Heartbeat callback resumes — but downstream count-vs-broadcast atomicity may be violated, hence Forbidden).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: MEDIUM
**Engine Notes**: `pcall` in Luau strict mode catches `error()` but NOT runtime `task.wait` yields (those do not raise). The "no yield inside phase" requirement is a code-review rule (control-manifest L132) — this story implements the `pcall` wrapper that catches synchronous errors and adds an instrumentation point that flags yields if a delegate is wired (deferred to story-005).

**Control Manifest Rules (Core layer)**:
- Required: Phase callbacks synchronous; no `task.wait` / `task.defer` / yields inside any phase callback (manifest L62); `pcall` wrapper per phase — exception logs + continues remaining phases; next tick recovers (L63).
- Required: Static 9-phase sequence locked: 1.Collision → 2.Relic → 3.Absorb → 4.Chest → 5.CSM:Eval → 6.MSM:Timer → 7.MSM:Elim → 8.CSM:Cast → 9.PeelDispatch (L60).
- Forbidden: Never yield inside TickOrchestrator phase callback (L132).

---

## Acceptance Criteria

*From ADR-0002 §Architecture (L93-103) + §Simultaneity Resolution (L180-185) + §Validation Criteria L2/5/6, scoped to this story:*

- [ ] `_runTick(tickCount: number)` body iterates `_phases` in ascending `phase` order (1, 2, 3, ..., 9) — NOT in input-table-order; the iteration order is determined by the `phase` field, not insertion order
- [ ] Per-tick `ctx` constructed once at top of `_runTick`: `local ctx: TickContext = { tickCount = tickCount, outPairs = {}, outPeel = {} }`. The same `ctx` reference passes to every phase callback this tick
- [ ] `outPairs` and `outPeel` are FRESH empty tables every tick (not module-level scratch reused across ticks) — guarantees no cross-tick state bleed
- [ ] Each phase invoked via `pcall(phase.callback, tickCount, ctx)`; on `not ok` log via `warn(string.format("TickOrchestrator: Phase %d (%s) errored at tick %d: %s", phase.phase, phase.name, tickCount, tostring(err)))` and CONTINUE to next phase
- [ ] When `_tickDelegate ~= nil`, `_runTick` calls `_tickDelegate(tickCount)` and RETURNS — phases are NOT iterated when a delegate is set (test-only short-circuit, per story-001)
- [ ] An `error()` raised inside Phase 3's callback does not prevent Phase 4-9 from running this tick (ADR-0002 §Validation L6)
- [ ] An `error()` in any phase does not corrupt `_tickCount` — next Heartbeat increments normally (the increment lives in story-001's Heartbeat handler, which is unaffected by phase errors thanks to `pcall`)
- [ ] An `error()` in Phase 3 is logged exactly once per tick (not duplicated if same phase errors again next tick)
- [ ] **A `task.wait(0.5)` injected inside a phase callback** does NOT block other phases this tick from completing — `pcall` will return after `task.wait` resumes; while we accept that ADR-0002 marks this as Forbidden, this AC validates the orchestrator still recovers (the `while` accumulator drain in story-001 + `pcall` here together resume cleanly on next Heartbeat)
- [ ] Phase iteration order proven deterministic: 1000-tick fixture run with recorder-callbacks records identical phase-id sequence every run

---

## Implementation Notes

*Derived from ADR-0002 §Architecture pseudocode (L93-102) + §Simultaneity Resolution (L180-185):*

- Sort `_phases` by `phase` field once during `_registerPhases` (story-001) so iteration is just `for i = 1, 9 do local phase = self._phases[i] ... end` at runtime — avoids per-tick sort cost.
- `pcall` signature: `local ok, err = pcall(phase.callback, tickCount, ctx)`. Use `warn` not `error` for log — `error` would re-raise and break the per-phase isolation guarantee.
- Do NOT use `xpcall` with traceback handler — ADR-0004 L137 forbids `debug.traceback` in hot loops (~100 µs per call, consumes Phase 1-4 budget). Plain `pcall` only.
- The `outPairs` + `outPeel` typing in TickContext is `{ any }` per ADR-0002 §Key Interfaces L129-130 — concrete types live in CCR (`{ CollisionPair }`) and Chest (`{ PeelEntry }`) modules. This story only constructs the empty tables; consumers cast at usage site.
- ADR-0002 §Risk 4 catch-up: story-001's `while` loop calls `_runTick` per accrued tick — this story's body must remain re-entrant-safe (no shared mutable module-level state apart from `_tickCount`/`_accumulator` already managed in story-001).
- The "no yield inside phase" forbidden rule is enforced at code-review (control-manifest L132); this story's `pcall` does not detect yields. Yielding inside a phase will return control to the Heartbeat callback after the wait resumes, so subsequent phases run *after* the yield — breaking atomicity but not crashing. Story-005's instrumentation will flag total tick time exceeding budget, which surfaces yields indirectly.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-001**: Module skeleton, `_registerPhases` assertion, accumulator + Heartbeat connection, `start/stop/getCurrentTick/setTickDelegate` API surface.
- **story-003**: Boot-time `_registerPhases({...})` call with named callbacks; this story tests via fixture-injected stub callbacks.
- **story-005**: Per-phase `os.clock` timing instrumentation; this story does not measure phase duration.
- **CSM/MSM/CCR/etc epic stories**: Real callback implementations for Phase 1-9. This story validates the orchestrator's iteration + isolation contract using stub callbacks only.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC: Iteration order is by `phase` field, not insertion order**
  - Given: fixture passes `_registerPhases` a table with entries in scrambled order (e.g. {phase=5, ...}, {phase=1, ...}, {phase=9, ...}, ...)
  - When: one tick fires (via real Heartbeat or `setTickDelegate`-disabled path)
  - Then: per-phase recorder hooks fire in 1, 2, 3, 4, 5, 6, 7, 8, 9 order regardless of input table order
  - Edge cases: input order matches 1..9 (sanity); input order reversed 9..1; randomly shuffled

- **AC: Fresh `ctx.outPairs` + `ctx.outPeel` per tick**
  - Given: a Phase 1 callback that appends `{a=tickCount}` to `ctx.outPairs`; Phase 2 callback that records `#ctx.outPairs`
  - When: 5 ticks fire
  - Then: Phase 2 records `#ctx.outPairs == 1` every tick (not 1, 2, 3, 4, 5)
  - Edge cases: same assertion for `ctx.outPeel`; verify Phase 9 sees what Phase 1 wrote this tick (cross-phase ctx propagation works)

- **AC: `tickCount` argument equals `ctx.tickCount` and matches `getCurrentTick` post-tick**
  - Given: a recorder phase that captures `(tickCount, ctx.tickCount)`
  - When: 10 ticks fire
  - Then: `tickCount == ctx.tickCount` every tick; recorded values are 0, 1, 2, ..., 9; `TickOrchestrator.getCurrentTick()` after returns 10
  - Edge cases: tickCount monotonic — never repeats, never decreases

- **AC: `error()` in a phase logs + remaining phases run (VC-6)**
  - Given: Phase 3 callback raises `error("synthetic")`; Phases 1, 2, 4-9 record their invocation
  - When: one tick fires
  - Then: Phases 1, 2, 4, 5, 6, 7, 8, 9 all recorded as invoked; one `warn` log line containing `"Phase 3"` + `"synthetic"` produced
  - Edge cases: error in Phase 1 → Phases 2-9 still run; error in Phase 9 → no impact on broadcasts (Phase 8 already ran); error in two phases same tick → both warns logged independently

- **AC: `error()` does not corrupt tick count or accumulator**
  - Given: Phase 5 callback raises every tick
  - When: 30 ticks fire
  - Then: `getCurrentTick()` returns 30; cadence over 30-tick window matches story-001 ±0.1 % budget; phases 1-4, 6-9 invoked exactly 30 times each
  - Edge cases: same with intermittent errors (every 3rd tick); same with all 9 phases erroring (orchestrator stays alive — pure-warn-log mode)

- **AC: `task.wait(0.5)` inside a phase does not crash the orchestrator (VC-5)**
  - Given: Phase 4 callback calls `task.wait(0.5)` then returns
  - When: one Heartbeat callback's drain loop processes 1 accrued tick
  - Then: `pcall` returns OK after wait resumes; Phases 5-9 run after the wait (within same Heartbeat callback resume); no crash; subsequent ticks recover
  - Edge cases: confirm `warn` is NOT logged for non-error yield (this is technically Forbidden per L132 but not detected here — story-005 jitter telemetry surfaces it as oversize tick time)

- **AC: `_tickDelegate` short-circuit bypasses phase iteration**
  - Given: `setTickDelegate(recorder)` set; `_registerPhases` populated with stub phase callbacks that fire their own recorders
  - When: 5 ticks fire
  - Then: delegate recorder fires 5 times; phase recorders fire 0 times (delegate short-circuit per story-001 contract)
  - Edge cases: `setTickDelegate(nil)` after delegate run → phase iteration resumes on next tick

- **AC: Deterministic phase order across 1000 ticks**
  - Given: 9 stub phase callbacks each appending their `phase.phase` to a shared list
  - When: 1000 ticks fire
  - Then: list has length 9000; every consecutive 9-element slice is exactly `{1, 2, 3, 4, 5, 6, 7, 8, 9}`
  - Edge cases: verify list grows monotonically; no out-of-order entry under any tick

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tick-orchestrator/phase_dispatch_test.luau` (iteration order, ctx propagation, deterministic 1000-tick fixture) + `tests/unit/tick-orchestrator/error_isolation_test.luau` (pcall + error + log + recovery).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (module skeleton + accumulator + `_registerPhases` assertion + Heartbeat connection)
- Unlocks: story-003 (boot wiring with real callbacks), story-005 (instrumentation hook on top of phase iteration)
