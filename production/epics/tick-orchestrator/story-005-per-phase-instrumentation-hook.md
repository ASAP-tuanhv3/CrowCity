# Story 005: Per-phase instrumentation hook (mobile jitter telemetry)

> **Epic**: tick-orchestrator
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md` (TickOrchestrator §15a + perf budget link); ADR-0002 §Risks Risk 1 (mobile Heartbeat jitter); ADR-0003 §Validation Sprint Plan + Per-Tick Budget (3.0 ms total)
**Requirement**: `TR-systems-index-005` (15 Hz cadence accuracy); `TR-csm-020` (Phase 5/8 budget); `TR-msm-018` (Phase 6/7 budget); ADR-0002 §Validation L7 (per-phase total ≤ 3 ms at full load) + L1 (cadence ±0.1 % desktop / ±0.3 % mobile)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 §Risks Risk 1 (mobile jitter mitigation) + §Migration Plan L5 (60 s soak on iPhone SE emu); ADR-0003 §Validation Sprint Plan (mobile + multi-client + soak validation deferred to MVP integration).
**ADR Decision Summary**: A non-default-on instrumentation hook records per-phase `os.clock` deltas + total tick time + tick-arrival jitter so MVP integration sprints can validate the ±0.1 / ±0.3 % cadence and the 3.0 ms per-tick CPU budget on real devices. Disabled in production by default to avoid hot-path overhead.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: MEDIUM
**Engine Notes**: `os.clock()` is the canonical per-frame Luau timer (microsecond precision) — used for per-phase deltas. `os.clock` is in-training-data (LOW). Rate-limited `warn` log via guard counter — `warn` is template-proven (LOW). Avoid `debug.profilebegin`/`profileend` here — Roblox's MicroProfiler is the in-Studio measurement tool, not appropriate for runtime telemetry hook.

**Control Manifest Rules (Core layer)**:
- Required: TickOrchestrator is sole `RunService.Heartbeat:Connect` accumulator (manifest L59); cadence `_tickPeriod = 1/15` (L64).
- Performance Guardrails: Total per-tick budget 3.0 ms (manifest L159); per-phase breakdown L160-L169.
- Forbidden: `debug.traceback` for runtime caller validation — ~100 µs/call, brittle (manifest L137 is for ADR-0004 but the same hot-path principle applies here — do NOT use traceback in instrumentation).

---

## Acceptance Criteria

*From ADR-0002 §Risks Risk 1 + §Validation L1+L7 + ADR-0003 §Validation Sprint Plan, scoped to this story:*

- [ ] `TickOrchestrator` exposes `setInstrumentationEnabled(enabled: boolean): ()` — toggles per-tick instrumentation. Default `false`. Idempotent.
- [ ] `TickOrchestrator` exposes `getLastTickTimings(): TickTimings?` — returns the most recent completed tick's per-phase + total deltas + arrival jitter, or `nil` if instrumentation is disabled OR no tick has yet completed
- [ ] `TickTimings` exported type:
  ```lua
  export type TickTimings = {
      tickCount: number,
      totalMs: number,                                    -- sum of phase deltas (excludes pcall+log overhead)
      phaseMs: { [number]: number },                      -- key = phase 1..9; value = ms
      arrivalJitterMs: number,                            -- abs(actualPeriod - 1/15) * 1000; spike alarm metric
      heartbeatDt: number,                                -- raw dt the Heartbeat was invoked with
      timestamp: number,                                  -- os.clock at tick entry
  }
  ```
- [ ] When instrumentation is **enabled**: per-phase `os.clock` start/end captured, deltas stored in a module-level `_lastTimings` table (one allocation reused across ticks — no per-tick GC pressure), total computed, arrival jitter computed against expected period (1/15 s) using the prior tick's `timestamp` field
- [ ] When instrumentation is **disabled**: `_runTick` execution path adds NO `os.clock` calls at all (the conditional branch is checked once at top of `_runTick`); `getLastTickTimings()` returns `nil` and burns zero tick-hot-path cost
- [ ] Instrumentation overhead measured: ≤ 0.05 ms per tick when DISABLED (the conditional branch); ≤ 0.20 ms per tick when ENABLED (10 `os.clock` calls + table writes); validated via dedicated benchmark test
- [ ] Spike alarm: when `arrivalJitterMs > 5.0` (mobile threshold per ADR-0002 §Risks Risk 1 mitigation), a single rate-limited `warn` is emitted: `warn(string.format("[TickOrch] Heartbeat jitter %.2f ms at tick %d", jitterMs, tickCount))`. Limit: ≤ 1 warn per second per spike-class to avoid log flood (template-proven rate-limit pattern)
- [ ] Boot wiring (story-003): the boot block calls `TickOrchestrator.setInstrumentationEnabled(false)` immediately after `start()`, and the boot block has a clearly-marked TODO comment showing how to flip to `true` for an MVP integration sprint
- [ ] Mobile validation NOT performed this story — only the hook lands. ADR-0003 §Validation Sprint Plan defers iPhone SE 60 s soak to MVP integration (a separate task once Core epics ship)

---

## Implementation Notes

*Derived from ADR-0002 §Risks Risk 1 + §Migration L5 + ADR-0003 §Validation Sprint Plan + manifest §Performance Guardrails Server Per-Tick CPU L157-170:*

- The `if not _instrumentationEnabled then` early-out at top of `_runTick` is the SOLE way to keep disabled overhead near-zero. Do NOT compute or capture timestamps inside the disabled branch.
- Reuse one `_lastTimings` table — clear `phaseMs[i] = nil for i = 1, 9` then re-fill, rather than `_lastTimings = {}` per tick. Avoids per-tick table allocation.
- Arrival jitter formula: `arrivalJitterMs = math.abs(currentTimestamp - previousTimestamp - _tickPeriod) * 1000`. When previous timestamp not yet set (first tick), record `0`.
- The `warn` rate-limit pattern: a module-local `_lastJitterWarnTime: number?` field; only emit `warn` when `os.clock() - _lastJitterWarnTime >= 1.0`. Cheap and adequate.
- Total tick time (in `totalMs`) is the sum of per-phase deltas. This excludes the `pcall` overhead + log overhead — the budget in ADR-0003 covers phase work, not orchestrator overhead.
- `getLastTickTimings()` returns the SAME table reference every call; callers MUST treat as read-only (consistent with CSM `getAllActive` read-only contract per manifest L155-156). Doc-comment on the public method declares this.
- Do NOT integrate this with analytics yet — the Analytics module is template stub; that integration lives in the Analytics epic. This story leaves `getLastTickTimings()` as a query API only.

---

## Out of Scope

*Handled by neighbouring stories or epics — do not implement here:*

- **story-001 + story-002**: Module skeleton + dispatch loop — this story extends `_runTick` with a guarded instrumentation block.
- **story-003**: Boot wiring — extended this story by one line: `setInstrumentationEnabled(false)`.
- **story-004**: BindToClose stop — unrelated.
- **MVP integration sprint task**: Actual 60 s iPhone SE soak + multi-client cadence validation — explicitly deferred per ADR-0003 §Validation Sprint Plan. This story exposes the hook so that sprint can flip `setInstrumentationEnabled(true)` and read `getLastTickTimings()` per tick.
- **Analytics epic**: Pushing `TickTimings` to analytics events — not in scope; the hook is query-only this story.
- **Per-phase budget enforcement**: ADR-0003 sets per-phase budgets (manifest L160-L169); this story exposes the measurement, not enforcement. Throttling/circuit-breaker if Phase X consistently overshoots is a future ADR amendment.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC: Public API surface**
  - Given: project compiles cleanly under `--!strict`
  - When: module loaded
  - Then: `setInstrumentationEnabled` and `getLastTickTimings` are functions; `TickTimings` type is exported
  - Edge cases: `getLastTickTimings()` before any tick fires → returns `nil`

- **AC: Default disabled**
  - Given: fresh module load (no `setInstrumentationEnabled` called)
  - When: `setTickDelegate(nil); _registerPhases(stubs); start();` and 5 ticks fire
  - Then: `getLastTickTimings()` returns `nil` (instrumentation off by default)
  - Edge cases: `setInstrumentationEnabled(false)` explicit call → still returns `nil` after ticks

- **AC: Enabled — populates timings**
  - Given: 9 stub phase callbacks each `task.wait(0)` and otherwise no-op
  - When: `setInstrumentationEnabled(true); start();` and 5 ticks fire
  - Then: `getLastTickTimings()` returns a table with `tickCount == 4` (zero-indexed; 5th tick was index 4); `phaseMs[1..9]` all numeric ≥ 0; `totalMs` ≈ sum(phaseMs[1..9]); `heartbeatDt` ≈ 1/15
  - Edge cases: per-phase deltas usually < 1 ms for stubs; `arrivalJitterMs` < 5 on test rig

- **AC: Disabled-mode overhead ≤ 0.05 ms / tick**
  - Given: 9 trivial stub callbacks (instant return)
  - When: 1000 ticks fire with instrumentation DISABLED; `os.clock` measured externally per Heartbeat callback
  - Then: average `_runTick` time ≤ 0.05 ms (the conditional-branch overhead and 9 `pcall` calls)
  - Edge cases: pcall overhead bounded; benchmark uses `setTickDelegate` set to a recorder that calls `_runTick` internally? — actually run via real Heartbeat to capture wall-clock

- **AC: Enabled-mode overhead ≤ 0.20 ms / tick**
  - Given: 9 trivial stub callbacks
  - When: 1000 ticks fire with instrumentation ENABLED
  - Then: average `_runTick` time ≤ 0.20 ms (10 `os.clock` calls + table writes per tick)
  - Edge cases: assert `getLastTickTimings()` returns valid timings every tick

- **AC: `_lastTimings` reused (no GC pressure)**
  - Given: instrumentation enabled
  - When: 100 ticks fire; reference to `getLastTickTimings()` captured after tick 1 and tick 100
  - Then: same table reference (`==`) — table is reused, not reallocated
  - Edge cases: `phaseMs` keys `1..9` are mutated per tick (overwritten, not appended)

- **AC: Arrival jitter computed against prior tick**
  - Given: instrumentation enabled; instrumented Heartbeat fixture firing with `dt = 2/15` (one accrued + one extra-late tick) every other call
  - When: 6 ticks fire (3 Heartbeat callbacks)
  - Then: ticks 0+2+4 have `arrivalJitterMs ≈ 0` (regular cadence), ticks 1+3+5 have `arrivalJitterMs > 0` (jitter spike)
  - Edge cases: tick 0 (first ever) `arrivalJitterMs == 0` (no prior timestamp)

- **AC: Spike alarm rate-limited to ≤ 1/s per class**
  - Given: instrumentation enabled; fixture forces `arrivalJitterMs = 10` for 30 consecutive ticks (over 2 s)
  - When: `warn` logger captured
  - Then: warn count ≤ 3 (one per second over 2 s window)
  - Edge cases: jitter drops below 5 → no warn even if previously warned; jitter spike returns after 5 s gap → warn fires immediately

- **AC: `getLastTickTimings()` is read-only-by-convention**
  - Given: instrumentation enabled
  - When: caller mutates `getLastTickTimings().phaseMs[1] = 999`
  - Then: next tick overwrites the value (mutation persists for one tick then disappears) — documenting that callers must NOT mutate
  - Edge cases: doc-comment present on public method

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tick-orchestrator/instrumentation_test.luau` (default-disabled, populates-when-enabled, table-reuse, jitter formula, rate-limit warn) + `tests/unit/tick-orchestrator/instrumentation_overhead_benchmark_test.luau` (≤0.05 ms disabled, ≤0.20 ms enabled).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (`_runTick` skeleton + Heartbeat handler + `_tickCount`), story-002 (`_runTick` body to instrument), story-003 (boot wiring extends with `setInstrumentationEnabled(false)` line)
- Unlocks: MVP integration sprint mobile-cadence validation task (out-of-scope here); future Analytics epic can subscribe to timings query
