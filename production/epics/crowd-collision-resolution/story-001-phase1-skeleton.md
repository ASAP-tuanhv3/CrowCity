# Story 001: Phase 1 callback skeleton + Dormant/Ticking states

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 TickOrchestrator + ADR-0006 Module Placement
**ADR Decision Summary**: CollisionResolver registers Phase 1 callback (first per tick, before Absorb) with TickOrchestrator. Dormant state (no active crowds) → no work; Ticking state → run pair pass. No own Heartbeat:Connect. Module at `ServerStorage/Source/CollisionResolver/init.luau`.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: All Luau files start with `--!strict` (ADR-0006)
- Required: Server module under `ServerStorage/Source/CollisionResolver/init.luau` (ADR-0006)
- Required: Phase 1 first per tick (ADR-0002)
- Forbidden: Competing `RunService.Heartbeat:Connect` for gameplay-tick work (ADR-0002)
- Forbidden: Yield inside Phase 1 callback (ADR-0002)
- Guardrail: Phase 1 budget ≤0.6 ms / tick (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-01 (Tick cadence)**: GIVEN resolver in `Ticking` state and 66ms elapsed, WHEN TickOrchestrator Heartbeat accumulator crosses `1/15`, THEN `CollisionResolver.tickPhase1()` fires exactly once; accumulator resets; no double-fire until next 66ms.
- [ ] **AC-02 (Dormant no-op)**: GIVEN resolver in `Dormant` state, WHEN tick callback fires, THEN `CrowdStateServer.getAllActive()` not called; no `updateCount`/`setStillOverlapping`/`PairEntered`/`FireClient` calls fire.
- [ ] **DI scaffold**: `CollisionResolver.init(deps)` accepts `csm`, `peelDispatcher`, `clock` — no module-scoped `require()` of these inside Phase 1 body.
- [ ] **State transitions**: `Dormant → Ticking` on first `getAllActive() ~= empty`; `Ticking → Dormant` on `getAllActive() == empty` or `destroyAll()`.

---

## Implementation Notes

*Derived from ADR-0002 §Phase 1 + GDD §States and Transitions:*

- Module folder-as-module entry. Public surface: `init(deps)`, `tickPhase1(tickCount)`, `getState() -> "Dormant" | "Ticking"`.
- Phase wiring: in `start.server.luau` post-require: `TickOrchestrator.registerPhase(1, CollisionResolver.tickPhase1)`.
- Dormant gate: at top of `tickPhase1`, `local active = csm.getAllActive(); if #active == 0 then state = "Dormant"; return end; state = "Ticking"`.
- No yield: pure synchronous body (Story 002+ fill in pair pass).
- Internal scratch: `_overlapPairs = {}` reused across ticks (cleared at top of each tick — table.clear).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: F1 + F2 pair iteration.
- Story 003: F3 drip math.
- Stories 004-007: skip / overlap-bit / pairEntered / equal-count.
- Stories 008-009: peel dispatch + client.
- Stories 010-011: integration + perf.

---

## QA Test Cases

- **AC-01 (Tick cadence)**:
  - Given: TickOrchestrator mocked at 15 Hz; resolver in Ticking
  - When: 66ms elapses
  - Then: `tickPhase1` spy fires exactly once; accumulator resets
  - Edge cases: 33ms elapsed → no fire; 200ms backlog → fires 3 times sequentially (Story 010 owns lag-spike).

- **AC-02 (Dormant no-op)**:
  - Given: state == Dormant; csm.getAllActive returns `{}`
  - When: tick fires
  - Then: spy on csm.getAllActive shows the early-return read; spy on csm.updateCount/setStillOverlapping zero calls; PairEntered + FireClient zero
  - Edge cases: nil return treated as empty.

- **DI scaffold**:
  - Given: missing dep
  - When: `init({csm = ..., peelDispatcher = nil, clock = ...})`
  - Then: assertion fires at init
  - Edge cases: re-init same deps idempotent.

- **State transitions**:
  - Given: Dormant; first non-empty getAllActive
  - When: tickPhase1 fires
  - Then: getState() returns "Ticking"
  - Edge cases: csm goes empty mid-round → Dormant on next tick.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/phase1_skeleton.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TickOrchestrator (Sprint 3 closed); CrowdStateServer (Sprint 3 partial — already exposes getAllActive).
- Unlocks: All other CCR stories.
