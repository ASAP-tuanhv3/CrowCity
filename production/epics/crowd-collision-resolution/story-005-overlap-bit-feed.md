# Story 005: Overlap-bit feed — setStillOverlapping post-drip

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Complete
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

**Status**: [x] Created 2026-05-08 — 17 it() blocks (AC-09 ×6 incl ordering, AC-14 ×2, TR-019 ×2, AC-13 ×1, per-side ×3, scratch ×1, snapshot+fan-out ×1, single-crowd ×1).

---

## Dependencies

- Depends on: Stories 001-004.
- Unlocks: CSM `setStillOverlapping` consumer paths (CSM Phase 5 stateEvaluate consumes).

---

## Completion Notes

**Completed**: 2026-05-08 (Sprint 6 task 6-9)
**Criteria**: 4/4 covered (AC-09 / AC-14 / TR-019 / AC-13 partial) via `tests/unit/collision/overlap_bit_feed.spec.luau` — 17 it() blocks.
**Approach**: Restructured Story 003+004 drip pass into unified loop with per-side overlap-bit aggregation. New `_overlapCrowds: { [string]: boolean }` scratch dict cleared per tick. Per-side eligibility: nil → no contribute; Eliminated → no contribute; Active/GraceWindow → contribute. Aggregation BEFORE drip-skip guards (intentional — pairs that skip drip due to GraceWindow / nil-partner still contribute eligible sides). Post-drip fan-out loop iterates `active` (cached top-of-tick snapshot) and emits exactly one `setStillOverlapping(crowd.crowdId, _overlapCrowds[id] == true)` per active crowd. New `_snapshotOverlapCrowds` test accessor.
**Audit gates**: `selene src/` 0/7/0 baseline maintained; `audit-asset-ids.sh` PASS; `audit-persistence.sh` PASS; static grep confirms `setStillOverlapping` has exactly one production call site (CollisionResolver line 420).
**Code Review**: Skipped (lean mode). gameplay-programmer APPROVED; qa-tester GAPS (advisory). All 4 fixes applied in-loop:
1. **DOC-001**: renamed misleading test title (was "B flag=false" but asserted true) — now clarifies per-side-not-per-pair eligibility
2. **GAP-001**: added total-callCount + per-crowd-callCount assertions to Eliminated + 2 GraceWindow tests (guards against fan-out accidentally skipping non-Active crowds)
3. **GAP-002**: removed unused `flagSeq` field from helper
4. **GAP-003**: snapshot test now also asserts fan-out callCount + non-overlapping crowd's flag=false (closes aggregation-vs-consumer-path gap)
**Resolved decisions**:
- Aggregation positioning BEFORE drip-skip is correct — moving it AFTER would silently break GraceWindow + nil-partner pairs from contributing
- Unconditional `setStillOverlapping(_, false)` for non-overlapping crowds is required — eliding `false` writes would leave CSM Phase 5 reading stale `stillOverlapping=true`, trapping crowds in GraceWindow indefinitely
- `setStillOverlapping` IS in CCR's authorized write surface per ADR-0004 §Write-Access Matrix; Story 004's prior `_setStillOverlappingSpy.callCount() == 0` assertion was retroactively wrong (Story 005 makes it 12 across 3 ticks × 4 crowds — corrected in skip_conditions.spec)
**Mock back-compat fixes** (4 spec files updated for Story 005 fan-out call):
- `phase1_skeleton.spec.luau`: buildMockCsm + 2 inline mocks extended with `get` + `setStillOverlapping` no-ops
- `pair_iteration_overlap.spec.luau`: buildMockCsm + scratch-clear inline mock extended with `setStillOverlapping`
- `drip_math.spec.luau`: buildMockCsm extended with `setStillOverlapping`
- `skip_conditions.spec.luau`: no-state-writes test updated — setStillOverlapping callCount now expected at 12 (Story 005 authorized write); transitionTo + setState remain at 0
**Deviations**:
- ADVISORY (carried from Story 001) — `getClock()` discard each tick. AbsorbSystem precedent.
**Files changed**:
- `src/ServerStorage/Source/CollisionResolver/init.luau` (drip pass restructured: per-side aggregation + post-drip fan-out + _overlapCrowds scratch + _snapshotOverlapCrowds accessor + header doc updates)
- `tests/unit/collision/overlap_bit_feed.spec.luau` (new, 17 it() blocks)
- `tests/unit/collision/phase1_skeleton.spec.luau` (mock back-compat: get + setStillOverlapping no-ops on 4 mock surfaces)
- `tests/unit/collision/pair_iteration_overlap.spec.luau` (mock back-compat: setStillOverlapping no-ops on 2 mock surfaces)
- `tests/unit/collision/drip_math.spec.luau` (mock back-compat: setStillOverlapping no-op on buildMockCsm)
- `tests/unit/collision/skip_conditions.spec.luau` (no-state-writes test count corrected: 0 → 12)
