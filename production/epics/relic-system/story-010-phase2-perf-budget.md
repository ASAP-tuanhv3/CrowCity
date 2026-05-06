# Story 010: Phase 2 perf budget — 0.1 ms/tick advisory soak

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §AC-23
**Requirement**: covered by `TR-relic-007`, `TR-relic-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 Performance Budget
**ADR Decision Summary**: Phase 2 RelicSystem budget = 0.2 ms/tick (manifest); GDD AC-23 advisory tighter at 0.1 ms/tick measured via `os.clock()` instrumentation in Studio test environment. Fallback: 5-min soak with no TickOrchestrator watchdog warnings.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `os.clock` + `debug.profilebegin/end` available pre-cutoff.

**Control Manifest Rules:**
- Phase 2 RelicSystem: 0.2 ms/tick (12 crowds × 4 relics × <5 µs) (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md` AC-23:*

- [ ] **AC-23 (Phase 2 perf — advisory)**: 3 active crowds each with 2 Active tick-hook relics → TickOrchestrator Phase 2 fires; total time inside Relic handler tick pass ≤ 0.1 ms via `os.clock()` instrumentation in Studio test.
- [ ] **Fallback soak**: 5-min soak in Studio; no TickOrchestrator watchdog warnings (per ADR-0002 phase pcall behavior).
- [ ] **Evidence file**: `production/qa/evidence/relic-perf-phase2-2026-XX-XX.md`.

---

## Implementation Notes

*Derived from ADR-0003 + perf-fixture pattern (Sprint 4):*

- Reuse perf-fixture; add `[R]` hotkey: spawn 3 crowds × 2 onTick relics each; pin TickOrchestrator at 15 Hz; soak 60 ticks minimum.
- Wrap `tickPhase2` in fixture-only `os.clock()` deltas. Compute mean + p99 across 60 samples.
- Synthetic onTick relic: declare in test-only registry — `hookSet.onTick = true`, handler does trivial work `(_, _, _, _) -> {}`. Six total handlers running per tick (3 crowds × 2).
- Acceptable margin: AC-23 advisory says 0.1 ms; manifest says 0.2 ms. Pass if ≤ 0.2 ms (manifest binding); flag CONCERNS if 0.1 < x ≤ 0.2 ms.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-009: implementation (this story validates).
- Real-server soak (deferred MVP-Integration-1).

---

## QA Test Cases

- **AC-23 (Phase 2 ≤ 0.1 ms advisory)** [Integration — Studio]:
  - Setup: open `perf-fixture.rbxl`; press `[R]`; soak 60 ticks
  - Verify: read os.clock instrumentation; compute p99 of Phase 2 tick body
  - Pass condition: p99 ≤ 0.1 ms ideally; ≤ 0.2 ms manifest binding; evidence committed

- **Fallback soak**:
  - Setup: 5-min soak with normal Phase 2 (3 crowds × 2 onTick relics)
  - Verify: no TickOrchestrator watchdog warnings in Output
  - Pass condition: documented in evidence

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/relic-perf-phase2-2026-XX-XX.md` — p99 + soak + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-009; perf-fixture from Sprint 4.
- Unlocks: Relic epic Definition of Done.
