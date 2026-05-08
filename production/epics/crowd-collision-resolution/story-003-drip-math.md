# Story 003: F3 drip rate + per-pair updateCount + equal-count mutual drain

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-004`, `TR-ccr-005`, `TR-ccr-006`, `TR-ccr-016`, `TR-ccr-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority
**ADR Decision Summary**: CollisionResolver is one of 4 callers of `updateCount(crowdId, ±delta, "Collision")`. Per-pair drip: attacker gains, defender loses `delta_per_tick = ceil(TRANSFER_RATE_effective / 15)` clamped `[1, 4]`. Equal-count → mutual drain (both lose). Triple-overlap stacks naturally per pair.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: `updateCount(crowdId, ±delta, "Collision")` 4-caller rule (ADR-0004)
- Required: F3 delta clamped `[1, 4]` (GDD)
- Forbidden: AbsorbSystem-side count clamp — CSM F5 owns ceiling (ADR-0004 + Absorb story-005)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-07 (Drip application, F3)**: GIVEN A (count=100, Active) + B (count=50, Active), TRANSFER_RATE_BASE=15, TRANSFER_RATE_SCALE=0.15, TRANSFER_RATE_MAX=60, SERVER_TICK_HZ=15, WHEN one tick elapses, THEN `updateCount("A", +2, "Collision")` then `updateCount("B", -2, "Collision")` fire (count_delta=50 → effective=22.5 → ceil(22.5/15)=2).
- [ ] **AC-08 (Equal-count mutual drain)**: GIVEN A (count=50, Active) + B (count=50, Active) overlapping → both `updateCount(-1, "Collision")`; neither gets `+`. (count_delta=0 → effective=15 → delta_per_tick=1; mutual rule).
- [ ] **F3 clamp**: delta_per_tick ∈ `[1, 4]` enforced — small differentials still tick at 1; massive differentials capped at 4.
- [ ] **Triple-overlap stacks naturally**: 3 crowds A/B/C all mutually overlapping → each pair processes independently; A drips with B, A drips with C, B drips with C — no special triple logic.

---

## Implementation Notes

*Derived from GDD §F3 + ADR-0004 §Write-Access Matrix:*

- Constants (extend `SharedConstants/CollisionResolverConstants.luau`): `TRANSFER_RATE_BASE = 15`, `TRANSFER_RATE_SCALE = 0.15`, `TRANSFER_RATE_MAX = 60`, `SERVER_TICK_HZ = 15`, `DELTA_PER_TICK_MIN = 1`, `DELTA_PER_TICK_MAX = 4`.
- F3 implementation:
  ```
  local cd = math.abs(countA - countB)
  local effective = math.min(TRANSFER_RATE_BASE + cd * TRANSFER_RATE_SCALE, TRANSFER_RATE_MAX)
  local delta = math.clamp(math.ceil(effective / SERVER_TICK_HZ), DELTA_PER_TICK_MIN, DELTA_PER_TICK_MAX)
  ```
- Per-pair logic:
  - if `countA > countB`: `csm.updateCount(a, +delta, "Collision")`; `csm.updateCount(b, -delta, "Collision")`.
  - if `countA < countB`: reverse.
  - if `countA == countB`: both `updateCount(_, -1, "Collision")` (mutual drain at delta=1 per equal-count rule).
- Triple-overlap: pair pass already iterates each unordered pair independently; A-B drip, A-C drip, B-C drip applied in order.
- Order within tick: drip calls happen in pair-iteration order (alphabetic by canonical pairKey from Story 002). Order-determinism matters for snapshot-based tests.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-002: skeleton + pair iteration.
- Story 004: state-based skip.
- Story 005: overlap-bit feed (separate post-drip pass).

---

## QA Test Cases

- **AC-07 (Drip A 100 vs B 50)**:
  - Given: A count=100 r=8, B count=50 r=8, both Active, distSq=64 (overlap)
  - When: 1 tick fires
  - Then: `updateCount("A", +2, "Collision")` once; `updateCount("B", -2, "Collision")` once; ordered call sequence
  - Edge cases: A count=110 → cd=60 → effective=15+9=24 → delta=ceil(24/15)=2; A count=150 → cd=100 → effective=15+15=30 → delta=2; A count=300 → effective=60 (capped) → delta=4.

- **AC-08 (Equal-count mutual drain)**:
  - Given: A count=50, B count=50, both Active, overlap
  - When: 1 tick fires
  - Then: 2 updateCount calls: `("A", -1)` and `("B", -1)`, source="Collision"; no `+` calls
  - Edge cases: count=1 each — both drain to 0 (CSM clamp owns floor 1; mutual results in count=1 each via clamp).

- **F3 clamp**:
  - Given: A count=10, B count=10 → cd=0 → delta=1 (min); A count=300, B count=10 → cd=290 → effective=15+43.5=58.5 capped 60 → delta=4 (max)
  - When: tick
  - Then: deltas honor `[1,4]` clamp
  - Edge cases: floating-point ceil — verify integer output.

- **Triple-overlap**:
  - Given: 3 mutually overlapping equal-count crowds
  - When: 1 tick
  - Then: 6 updateCount calls (3 pairs × 2 sides); all `-1`
  - Edge cases: 3 crowds with monotonic counts A<B<C (higher count = attacker; gains followers per GDD §F3) — drip flows per pair: A↓ from B, A↓ from C, B↓ from C, B↑ from A, C↑ from A, C↑ from B. Net: A loses to both larger crowds, C gains from both smaller crowds, B is net-zero (gains from A, loses to C).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/drip_math.spec.luau` — must exist and pass

**Status**: [x] Created 2026-05-08 — 19 it() blocks (AC-07 ×4, AC-08 ×2, F3 clamp ×8, Triple-overlap ×3, cross-cutting ×3)

---

## Dependencies

- Depends on: Story 001 (skeleton), Story 002 (pair iteration produces _overlapPairs).
- Unlocks: Stories 005 (overlap-bit feeds CSM), 007 (equal-count peel buffer entries).

---

## Completion Notes

**Completed**: 2026-05-08 (Sprint 6 task 6-7)
**Criteria**: 4/4 covered (AC-07 / AC-08 / F3 clamp / Triple-overlap) via `tests/unit/collision/drip_math.spec.luau` — 19 it() blocks.
**Approach**: Created `SharedConstants/CollisionResolverConstants.luau` (6 GDD-locked F3 inputs: TRANSFER_RATE_BASE/SCALE/MAX, SERVER_TICK_HZ, DELTA_PER_TICK_MIN/MAX). Added module-level `computeDeltaPerTick(countA, countB)` helper implementing F3: `cd = abs(countA - countB); effective = min(BASE + cd*SCALE, MAX); delta = clamp(ceil(effective/HZ), MIN, MAX)`. Extended `tickPhase1` body with drip pass after pair-iteration loop: iterate `_overlapPairs`; per-pair branch by count comparison — equal → both `updateCount(-DELTA_PER_TICK_MIN, "Collision")`; differential → attacker `+delta`, defender `-delta` via `csm.updateCount(crowdId, ±delta, "Collision")`. Triple-overlap stacks naturally per pair (TR-ccr-018). Tightened `_overlapPairs` type to formal `CollisionPair` alias exported at module top. Test-only `_computeDeltaPerTick` accessor for unit-testing F3 independent of pair iteration.
**Audit gates**: `selene src/` 0/7/0 baseline maintained; `audit-asset-ids.sh` PASS; `audit-persistence.sh` PASS.
**Code Review**: Skipped (lean mode). gameplay-programmer + qa-tester ad-hoc reviews APPROVED WITH SUGGESTIONS; all 5 suggestions applied in-loop:
1. Tightened `_overlapPairs: { CollisionPair }` formal type alias (export type at module top).
2. Fixed test comment cd=290 inaccuracy (DELTA_PER_TICK_MAX clamp, not TRANSFER_RATE_MAX cap — rate cap kicks in at cd>=300).
3. Added F3 clamp story-doc narrative edges (A=110/B=50 cd=60→delta=2; A=150/B=50 cd=100→delta=2).
4. Added AC-07 ordered call sequence test verifying attacker call precedes defender via `getCall(1)`/`getCall(2)`.
5. Story-doc triple-overlap narrative corrected (line 94): original "1↑ from 2, 1↑ from 3..." inverted GDD §F3 attacker rule. Updated to "higher count = attacker; gains followers" with correct A↓/B↓/B↑/C↑ flows.
**Single-source-of-truth resolution**: Equal-count branch passes `-CollisionResolverConstants.DELTA_PER_TICK_MIN` rather than literal `-1`. Both produce delta=1 today via formula route too (cd=0 → effective=15 → ceil(15/15)=1), but constant reference keeps the floor synchronized if the constant is amended.
**Deviations**:
- ADVISORY (carried from Story 001) — `getClock()` discard each tick. AbsorbSystem precedent.
**Files changed**:
- `src/ReplicatedStorage/Source/SharedConstants/CollisionResolverConstants.luau` (new)
- `src/ServerStorage/Source/CollisionResolver/init.luau` (extended: CollisionPair export type + computeDeltaPerTick + drip pass + _computeDeltaPerTick test surface + tightened _overlapPairs type)
- `tests/unit/collision/drip_math.spec.luau` (new, 19 it() blocks)
