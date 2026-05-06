# Story 004: Skip conditions — nil/Eliminated state guards + GraceWindow handling

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-007`, `TR-ccr-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 TickOrchestrator §Phase 1 state-skip + ADR-0004 CSM Authority
**ADR Decision Summary**: Skip pairs where either crowd is nil or `state == "Eliminated"`. Drip restricted to both Active. GraceWindow crowd's overlap-bit STILL reported (`setStillOverlapping(true)`) — CSM's GraceWindow timer expires next tick if overlap persists.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Eliminated crowds skip per ADR-0002 Phase 1 state-skip rule
- Required: GraceWindow overlap-bit still reported (ADR-0004 CSM consumer)
- Forbidden: Issue state-transition calls from CCR (ADR-0004 — CSM owns transitions)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-06 (Skip conditions)**: GIVEN pair where `csm.get(A.id) == nil` OR `B.state == "Eliminated"`, WHEN tick runs, THEN: (a) no `updateCount` for either pair side; (b) `setStillOverlapping(_, true)` NOT set from these pairs; (c) no Luau error thrown.
- [ ] **GraceWindow drip suspended**: GraceWindow ↔ Active overlapping pair → no drip (drip restricted to both-Active per Rule 5); but overlap-bit STILL reported for both.
- [ ] **GraceWindow ↔ GraceWindow**: no drip; overlap-bit reported for both.
- [ ] **No state writes**: code grep verifies CCR module never calls `csm.transitionTo*` or any state mutator other than `updateCount` + `setStillOverlapping`.

---

## Implementation Notes

*Derived from GDD §C Rule 4 + §States and Transitions:*

- After Story 002's pair pass, before drip (Story 003): for each overlap pair `{a, b}`:
  - Look up `csm.get(a.id)` and `csm.get(b.id)`. If either nil → skip pair entirely (no drip, no overlap-bit contribution from this pair to those crowds).
  - If `a.state == "Eliminated"` or `b.state == "Eliminated"` → skip drip; continue to overlap-bit (still reported for non-Eliminated side).
  - If `a.state == "Active"` and `b.state == "Active"` → run drip (Story 003).
  - If at least one is `GraceWindow` → no drip, but overlap-bit reported for both (Story 005 consumes).
- Code-review grep gate: `grep -rn "transitionTo\|setState" src/ServerStorage/Source/CollisionResolver/` returns zero matches.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: skeleton.
- Story 002: pair iteration.
- Story 003: drip math (this story gates which pairs reach drip).
- Story 005: overlap-bit set call (this story decides which crowds eligible).

---

## QA Test Cases

- **AC-06 (Skip nil/Eliminated)**:
  - Given: pair (A, B) where csm.get("A") nil; pair (C, D) where C state==Eliminated
  - When: tick
  - Then: `csm.updateCount` spy zero calls for these pairs; no setStillOverlapping(true) from these pairs
  - Edge cases: both nil → skip silently; one Eliminated + one Active → drip skipped, overlap-bit reported only for the Active side (Story 005).

- **GraceWindow drip suspended**:
  - Given: A state=GraceWindow, B state=Active, overlap
  - When: tick
  - Then: zero updateCount calls for this pair; setStillOverlapping(A, true) AND setStillOverlapping(B, true) deferred to Story 005 (this story marks pair as "skip drip, report overlap-bit")
  - Edge cases: both GraceWindow → same behavior.

- **No state writes**:
  - Given: full source under `src/ServerStorage/Source/CollisionResolver/`
  - When: grep for `transitionTo\|setState\|setStateAsync`
  - Then: zero matches
  - Edge cases: comments containing the strings — handle with anchored regex.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/skip_conditions.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-002.
- Unlocks: Stories 003 (gated drip), 005 (overlap-bit consumer).
