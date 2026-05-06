# Story 005: Overlap-bit feed — setStillOverlapping post-drip

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-008`, `TR-ccr-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority
**ADR Decision Summary**: CollisionResolver is sole caller of `setStillOverlapping(crowdId, flag)`. Last-write-wins within tick — exactly one call per crowd per tick. Called AFTER all drip calls this tick.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: `setStillOverlapping(crowdId, flag)` sole caller — CollisionResolver (ADR-0004)
- Required: Last-write-wins within tick (ADR-0004 — exactly 1 call per crowd per tick)
- Required: Calls AFTER all drip this tick (GDD Rule 6)
- Forbidden: Multiple setStillOverlapping calls per crowd per tick (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-09 (Overlap-bit feed)**: GIVEN tick where A-B overlap (both Active), C no overlaps, D in GraceWindow with overlap to A, WHEN full pair pass completes, THEN `setStillOverlapping("A", true)`, `("B", true)`, `("C", false)`, `("D", true)` each called exactly once; no crowd called twice; calls happen AFTER all drip calls.
- [ ] **AC-14 (2-vs-2 mutual GraceWindow)**: GIVEN A (count=2 Active) and B (count=2 Active) overlap, WHEN one tick fires (equal-count drain), THEN both drop to count=1; setStillOverlapping(A, true) AND setStillOverlapping(B, true) fire this tick; CSM transitions both to GraceWindow this tick. Next tick: pair skipped for drip (neither Active); setStillOverlapping still reports `true` for both.
- [ ] **GraceWindow overlap reported (TR-019)**: GraceWindow crowd's overlap status STILL reported (`true` if any overlap pair exists) — CSM uses to drive timer expiry.

---

## Implementation Notes

*Derived from GDD §C Rule 6 + ADR-0004 §Write-Access Matrix:*

- After drip pass (Story 003): build per-crowd overlap flag from `_overlapPairs`:
  - `local overlapCrowds = {}` set; for each pair in _overlapPairs (regardless of state-skip from Story 004): `overlapCrowds[a.id] = true; overlapCrowds[b.id] = true`. Note: state-skipped pairs (nil-skip) DO NOT contribute; Eliminated-skip pairs contribute the Active side; GraceWindow contributes both sides.
  - Iterate ALL crowds in `csm.getAllActive()` (cached at top of tick): `csm.setStillOverlapping(crowd.id, overlapCrowds[crowd.id] == true)`.
- Order within tick: must run AFTER drip. Implementation: drip pass appends to scratch; overlap-bit pass runs as separate loop after.
- Edge: crowd absent from getAllActive (i.e., destroyed mid-tick) — not iterated, no setStillOverlapping call (CSM cleanup at next tick).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: drip math.
- Story 004: skip conditions (which pairs reach overlap-bit aggregation).
- Story 006: pairEntered diff (separate from overlap-bit).

---

## QA Test Cases

- **AC-09 (Overlap-bit feed)**:
  - Given: A-B overlap (Active), C no overlaps, D-A overlap (D in GraceWindow)
  - When: tick fires
  - Then: spy on csm.setStillOverlapping shows exactly 4 calls in some order: `(A,true) (B,true) (C,false) (D,true)`; each crowdId exactly once
  - Edge cases: 12 crowds, 0 overlaps → 12 calls all `false`; sequence after drip — drip spy timestamps precede overlap-bit timestamps.

- **AC-14 (2-vs-2 mutual GraceWindow)**:
  - Given: A count=2 Active, B count=2 Active, overlap
  - When: tick fires (equal-count drain in Story 003)
  - Then: updateCount(-1) twice (Story 003); setStillOverlapping(A, true) + (B, true); CSM (mocked) sees count drops + transitions to GraceWindow; next tick — Story 004 skips drip but Story 005 still reports overlap-bit true if pair still in `_overlapPairs`
  - Edge cases: A reduces to count=0 → CSM clamps to 1 → Eliminated trigger from CSM (not CCR's job); next tick A is Eliminated → Story 004 skips both contributions; Story 005 reports B-true (if any other overlap) or false.

- **AC-13 (Write-access contract)** [partial — covered fully in Story 010]:
  - Given: full tick over 3 Active-vs-Active overlapping pairs
  - When: tick completes
  - Then: ONLY CSM methods invoked: `getAllActive()` once, `get(id)` as needed, `updateCount(id, ±delta, "Collision")` 6 times, `setStillOverlapping(id, bool)` once per active crowd
  - Edge cases: extra methods (e.g., `transitionTo*`) → fail.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/overlap_bit_feed.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-004.
- Unlocks: CSM `setStillOverlapping` consumer paths (CSM Phase 5 stateEvaluate consumes).
