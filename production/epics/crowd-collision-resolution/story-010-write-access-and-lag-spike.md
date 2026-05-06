# Story 010: Write-access contract integration + lag-spike 2-tick handling

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-015`, `TR-ccr-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 TickOrchestrator + ADR-0004 CSM Authority
**ADR Decision Summary**: Phase ordering locked: Collision (P1) first, Absorb (P3) second, Broadcast (P8) third, PeelDispatch (P9) last. Lag-spike 2-tick: TickOrchestrator runs accumulator-driven catch-up; 2 ticks fire sequentially in same Heartbeat callback. CCR write-access strictly limited to: `getAllActive`, `get`, `updateCount`, `setStillOverlapping`.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Core layer):**
- Required: TickOrchestrator runs accumulator catch-up — multiple ticks per Heartbeat OK (ADR-0002)
- Required: CCR write-access exactly per ADR-0004 §Write-Access Matrix (ADR-0004)
- Forbidden: CCR call any CSM method outside `getAllActive`/`get`/`updateCount`/`setStillOverlapping` (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-13 (Write-access contract)**: GIVEN full tick over 3 Active-vs-Active overlapping pairs, WHEN tick completes, THEN ONLY CSM methods invoked are: `getAllActive()` (1×), `get(id)` (as needed), `updateCount(id, ±delta, "Collision")` (2× per drip pair), `setStillOverlapping(id, bool)` (1× per active crowd). No other CSM methods called. Verified via spy.
- [ ] **AC-16 (Lag-spike 2-tick overflow)**: GIVEN A (count=10) + B (count=10) overlapping, WHEN Heartbeat fires with accumulator holding 2 full ticks (`dt ≈ 133 ms`), THEN TickOrchestrator runs tick loop twice sequentially in that callback; CCR's tickPhase1 fires twice; updateCount(-1) twice per side (total -2 each); accumulator resets below threshold; no third tick fires.
- [ ] **Phase ordering integration**: tick spy log shows: `Phase1(CCR) → Phase2 → Phase3(Absorb) → ... → Phase8(Broadcast) → Phase9(Peel)`. CCR fires first; Absorb sees CCR's count writes; broadcast sees both.

---

## Implementation Notes

*Derived from ADR-0002 §Phase Order + GDD AC-16:*

- This story is mostly verification — Stories 001-008 build the system; this story tests the integration with TickOrchestrator + CSM.
- Test infrastructure: integration test spawns a mock TickOrchestrator with `setTickDelegate` test hook (per ADR-0002 §Test hook); pumps accumulator with synthetic dt; observes phase ordering via call-spy on each phase callback.
- AC-16 lag-spike: pump dt=0.133s; assert `tickPhase1` fires 2× sequentially; updateCount spy total `-2` per side; accumulator post-tick `< 1/15`.
- AC-13 spy: blanket spy on all CSM public methods; assert only allowed names appear; assert call counts match expected (1, n, 6, 3 per AC's example).
- No new code — Stories 001-008 implementations are what's verified.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- TickOrchestrator implementation itself (Sprint 3 closed).
- Stories 001-008: building the system under test.
- Story 011: perf measurement.

---

## QA Test Cases

- **AC-13 (Write-access)** [Integration]:
  - Given: 3 Active-vs-Active overlapping pairs; CSM with all-method spy
  - When: 1 full tick (Phase 1-9)
  - Then: spy log matches exactly: `getAllActive ×1`, `get(id) ×N` (ad-hoc), `updateCount ×6` (3 pairs × 2 sides), `setStillOverlapping ×N` (one per active crowd in getAllActive return)
  - Edge cases: extra method names (e.g., `transitionTo`) → fail.

- **AC-16 (Lag-spike 2-tick)** [Integration]:
  - Given: TickOrchestrator with accumulator; A count=10, B count=10 overlapping; pump dt=0.133s once
  - When: Heartbeat fires
  - Then: tickPhase1 spy fires 2× in same Heartbeat call; total updateCount(-1) calls = 4 (2 per side); after callback, accumulator < 1/15
  - Edge cases: dt=0.20s → 3 ticks; dt=0.066s → 1 tick; dt=0.001s → 0 ticks.

- **Phase ordering integration** [Integration]:
  - Given: 1 overlap pair + 1 NPC absorb-eligible
  - When: 1 tick
  - Then: spy timestamps show Phase 1 (CCR) → Phase 3 (Absorb) → Phase 8 (Broadcast) → Phase 9 (Peel) in order
  - Edge cases: phase callback raises pcall → next phase still fires (ADR-0002 pcall-per-phase isolation).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/collision/write_access_contract.spec.luau` — must exist and pass
- `tests/integration/collision/lag_spike_two_tick.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-008 fully implemented; TickOrchestrator (Sprint 3 closed).
- Unlocks: Story 011 (perf soak runs over the same integration baseline).
