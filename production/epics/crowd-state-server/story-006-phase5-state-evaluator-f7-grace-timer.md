# Story 006: Phase 5 state evaluator + F7 grace timer + state transitions + CrowdEliminated

> **Epic**: crowd-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §States and Transitions + §Formulas/F7 + §Server API
**Requirement**: `TR-csm-006` (Phase 5 + F7 timer), `TR-csm-013` (Eliminated continues; transition firing), `TR-csm-008` (tick simultaneity), `TR-csm-019` (CCR symmetry — Phase 1 read by Phase 5)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 §Phase Sequence (Phase 5 = `CSM.stateEvaluate`); ADR-0001 §Key Interfaces (CrowdEliminated reliable named event; Eliminated state continues broadcasting); ADR-0004 §Write-Access Matrix (`stateEvaluate` sole caller TickOrchestrator).
**ADR Decision Summary**: Phase 5 evaluates crowd state transitions per tick using F7 grace-timer logic. Active → GraceWindow when count hits 1 + still overlapping rival. GraceWindow → Active when overlap clears OR count goes back above 1 via Absorb/Relic up-delta. GraceWindow → Eliminated when grace timer (3.0 s) expires AND still overlapping. Tie-break: simultaneous timer-expiry + overlap-clear → Active (overlap-clear wins). On Active→Eliminated, fires `CrowdEliminated` reliable RemoteEvent.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `os.clock()` for grace-timer math (template-proven, LOW); reliable `RemoteEvent` (LOW).

**Control Manifest Rules (Core layer)**:
- Required: `stateEvaluate(tickCount)` is Phase 5 callback, sole caller TickOrchestrator (manifest L75); CrowdEliminated reliable named event (L86); Eliminated crowds continue broadcasting until `RoundLifecycle.destroyAll` (L88).
- Forbidden: never yield inside Phase 5 (manifest L62); no revival from Eliminated in MVP (GDD §States L94).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-11 (Grace entry + Active exit, F7)** — B at `count=3` Active, overlapping a larger rival. Collision drip reduces B.count to 1 with rival still present. B transitions to GraceWindow and a 3-second timer starts (`record.timer_start = os.clock()`). If B moves out of all rival overlaps before 3s expire (CCR calls `setStillOverlapping(B.crowdId, false)`), B transitions back to Active at `count=1`.
- [ ] **AC-12 (Grace → Eliminated, F7)** — B in GraceWindow with overlap persisting; 3.0 seconds elapse; B transitions to Eliminated; `count` is NOT mutated further (Eliminated is count-immutable per §States L83); collision drip on B stops (CCR responsibility — CSM signals via state).
- [ ] **AC-13 (Tie-Break)** — B in GraceWindow at exactly t=3.0s. Grace timer expires AND rival overlap clears on the same tick. B transitions to Active at `count=1` (overlap-clear WINS; Eliminated NOT triggered).
- [ ] `stateEvaluate(tickCount: number): ()` exposed per architecture.md §5.1 L548.
- [ ] `stateEvaluate` body order:
  1. Call `_updatePositions()` (story-005 helper) FIRST so position is current for this tick.
  2. For each record, evaluate state transitions per F7.
  3. Fire `CrowdEliminated` reliable for any Active→Eliminated transitions (one per crowd).
- [ ] F7 grace timer: `should_eliminate = still_overlapping AND (os.clock() - timer_start) >= GRACE_WINDOW_SEC`. `GRACE_WINDOW_SEC = 3.0`.
- [ ] When count drops to 1 via `updateCount(-, "Collision")` AND `record.stillOverlapping == true` AND state == "Active" → state = "GraceWindow", `timer_start = os.clock()`. **Implementation choice**: detection of "count just hit 1 with overlap" can live in `updateCount` (story-002 calls a state-check helper) OR in `stateEvaluate` (Phase 5 reads `count` and `stillOverlapping`). **Decision**: state transition logic lives in `stateEvaluate` to keep Phase 5 the single point of state authority. `updateCount` does NOT directly write `state`.
- [ ] When count rises above 1 (Absorb / Relic+) AND state == "GraceWindow" → state = "Active", `timer_start = nil`.
- [ ] When state == "GraceWindow" AND `record.stillOverlapping == false` → state = "Active" at `count=1`, `timer_start = nil`. (Overlap-clear → exit grace.)
- [ ] When state == "GraceWindow" AND grace timer expired AND `record.stillOverlapping == true` → state = "Eliminated"; `record.state = "Eliminated"`; fire `CrowdEliminated` reliable to all clients.
- [ ] No revival from Eliminated — `state == "Eliminated"` is terminal until `destroy(crowdId)` is called.
- [ ] `CrowdEliminated` payload: `{crowdId}` per GDD L142.

---

## Implementation Notes

*Derived from ADR-0002 §Phase 5 + ADR-0001 §Key Interfaces + GDD §States table + F7 formula:*

- F7 formula reference (GDD L307-L315):
  ```
  should_transition_to_grace = (state == "Active") AND (count == 1) AND still_overlapping
  should_eliminate = (state == "GraceWindow") AND still_overlapping AND (os.clock() - timer_start >= GRACE_WINDOW_SEC)
  should_exit_grace_via_overlap_clear = (state == "GraceWindow") AND (NOT still_overlapping)
  should_exit_grace_via_count_rise = (state == "GraceWindow") AND (count > 1)
  ```
- Tie-break for AC-13: evaluate `should_exit_grace_via_overlap_clear` BEFORE `should_eliminate` in the conditional chain. `still_overlapping == false` short-circuits the elimination check. Per GDD §States L82 GraceWindow keeps "still_overlapping flag set by CollisionResolver — last-write-wins within tick".
- Order within a single record's evaluation:
  1. If state == "Eliminated" → continue (terminal).
  2. If state == "Active" AND count == 1 AND stillOverlapping → state = "GraceWindow"; timer_start = os.clock(). (Edge: count hits 1 same tick as overlap-clear → still_overlapping=false → no transition.)
  3. If state == "GraceWindow":
     a. If `not stillOverlapping` → state = "Active"; timer_start = nil.
     b. Else if count > 1 → state = "Active"; timer_start = nil.
     c. Else if `os.clock() - timer_start >= GRACE_WINDOW_SEC` → state = "Eliminated"; queue CrowdEliminated fire.
  4. If state == "Active" → no-op (already handled in step 2).
- Fire `CrowdEliminated` AFTER all records evaluated this tick — append to a tick-local list during evaluation, fire at end (avoids re-entrancy issues if a fanout subscriber synchronously triggers another transition).
- `GRACE_WINDOW_SEC = 3.0` constant exposed at module top per GDD L309.
- `os.clock()` is the monotonic timer per manifest L117 ("Server-side `os.clock` / `tick` is sole timing authority").

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-002**: `updateCount` is invoked by 4 callers; it does NOT write `state` (Phase 5 owns state writes).
- **story-005**: `_updatePositions` helper called from inside `stateEvaluate` body.
- **story-007**: `setStillOverlapping(crowdId, flag)` — CSM read here; the writer side lives in story-007.
- **story-008**: `broadcastAll` Phase 8 reads `record.state` and packs into payload (Eliminated continues broadcasting until destroy).
- **TickOrchestrator epic**: Phase 5 boot wiring with `CSMStateEvaluateStub.tick` → replaced post this story by `CrowdStateServer.stateEvaluate` callback. The replacement happens via `_registerPhases` table edit in `start.server.luau` (per tick-orchestrator story-003 stub-replacement contract).
- **CCR epic**: `setStillOverlapping` callers — CCR Phase 1 marks pairs.
- **AbsorbSystem / RelicSystem epics**: count-rising deltas via `updateCount(+N)`; Phase 5 detects count>1 in GraceWindow and transitions to Active.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-11 (grace entry)**: Record at `count=3, state="Active", stillOverlapping=true`. Simulate `updateCount(id, -2, "Collision")` → count=1. Invoke `stateEvaluate(tickCount=1)` (or directly invoke for unit test). Assert `state == "GraceWindow"`, `timer_start ~= nil`. Edge cases: count=1 + stillOverlapping=false (no rival) → state stays "Active"; count=2 → state stays "Active".

- **AC-11 (active exit via overlap-clear)**: Record at `state="GraceWindow", count=1, stillOverlapping=true, timer_start = os.clock()-1.0` (1s into grace). Set `stillOverlapping=false` (CCR cleared). Invoke `stateEvaluate(tickCount=N)`. Assert `state == "Active"`, `timer_start == nil`. Edge cases: 0s into grace → still exits; just below 3s → still exits.

- **AC-11 (active exit via count rise)**: Record at `state="GraceWindow", count=1, stillOverlapping=true, timer_start = os.clock()-1.0`. Simulate `updateCount(id, +5, "Absorb")` → count=6. Invoke `stateEvaluate`. Assert `state == "Active"`, `timer_start == nil`.

- **AC-12 (grace → eliminated)**: Record at `state="GraceWindow", count=1, stillOverlapping=true, timer_start = os.clock()-3.5` (3.5s elapsed > 3.0s threshold). Invoke `stateEvaluate`. Assert `state == "Eliminated"`. Network mock subscribed to `RemoteEventName.CrowdEliminated` receives `{crowdId}` exactly once. Subsequent `stateEvaluate` calls → no further CrowdEliminated fire (terminal state).

- **AC-13 (tie-break overlap-clear-wins)**: Record at `state="GraceWindow", count=1, stillOverlapping=true, timer_start = os.clock()-3.0` (exactly at threshold). On the SAME tick CCR also calls `setStillOverlapping(id, false)`. Invoke `stateEvaluate`. Assert `state == "Active"` NOT "Eliminated"; `timer_start == nil`. Network mock receives NO `CrowdEliminated` event.

- **No revival from Eliminated**: Record at `state="Eliminated", count=1`. Simulate `updateCount(id, +50, "Absorb")` (per AC-04 clamp would normally apply; here count already at 1; for test fixture force count=51 directly). Invoke `stateEvaluate`. Assert `state == "Eliminated"` (no transition out).

- **CrowdEliminated payload + once-per-transition**: 3 crowds A/B/C; fixture forces A and C to grace-expiry simultaneously this tick. Invoke `stateEvaluate`. Network mock receives 2 events: `{crowdId="A"}` and `{crowdId="C"}` in some order. No duplicate.

- **stateEvaluate calls _updatePositions first**: instrument `_updatePositions` to set a flag; fixture invokes `stateEvaluate`; assert flag set before any state transition logic ran.

- **Performance**: 12 crowds, mixed states, fixture invokes `stateEvaluate`; `os.clock` delta < 0.2 ms (Phase 5 budget per manifest L164).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/state_evaluator_test.luau` (transitions + tie-break + terminal Eliminated) + `tests/unit/crowd-state-server/grace_timer_test.luau` (F7 timer math + simultaneity).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (record schema), story-002 (updateCount integrates with state-aware count writes), story-005 (`_updatePositions` helper), story-007 (`setStillOverlapping` writer + read pattern)
- Unlocks: story-008 (broadcastAll reads state for payload encoding); MSM Phase 7 elimConsumer (drains CrowdEliminated reliable events queued here)
