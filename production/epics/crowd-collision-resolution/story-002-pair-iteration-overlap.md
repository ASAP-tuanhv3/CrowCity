# Story 002: F1 pair overlap test + F2 pair_key + O(p²) unique iteration

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-002`, `TR-ccr-003`, `TR-ccr-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: F1 + F2 are GDD-internal formulas. Server-authoritative (no client-asserted overlap). 2D squared-distance test (Y ignored). Unique unordered pairs `i<j` lex-canonicalized.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Read-only consumer of CSM `getAllActive()` (ADR-0004)
- Required: F2 pair_key canonical lex form (GDD)
- Forbidden: Mutate CSM table (ADR-0004)
- Forbidden: `math.sqrt` per overlap test (use squared distance)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-03 (Pair iteration unique pairs)**: GIVEN crowds `"111"`, `"222"`, `"333"`, WHEN one tick runs, THEN exactly 3 unique unordered pairs visited (`"111|222"`, `"111|333"`, `"222|333"`); no self-pair; no duplicate.
- [ ] **AC-04 (F1 — Pair overlap test, Y ignored)**: GIVEN A `(0,0,0)` r=8 and B `(10,50,0)` r=8 → `distance_sq=100`, `combined_radius_sq=256`, overlap=true. C `(20,0,0)` r=8 → `distance_sq=400 > 256` → overlap=false.
- [ ] **AC-05 (F2 — pair_key canonical)**: `pairKey("3891","512")` and `pairKey("512","3891")` both return `"3891|512"` (lex compare: `"3" < "5"` makes `"3891"` lex-lower).
- [ ] **AC-15 (Stacked position)**: A and B at identical XZ → `distance_sq=0`, `combined_radius_sq>=0` → overlap=true; no divide-by-zero.

---

## Implementation Notes

*Derived from GDD §F1 + §F2:*

- F1 form: `function isOverlap(ax, az, bx, bz, raSq, rbSq) local dx,dz=ax-bx,az-bz return (dx*dx + dz*dz) <= (raSq + 2*math.sqrt(raSq*rbSq) + rbSq) end` — but per GDD use composed radius: `combined = (radiusA + radiusB)^2` precomputed once per pair. Simpler: precompute `radiusA + radiusB` then square.
- F2 `pairKey(a, b)`: `if a < b then return a .. "|" .. b else return b .. "|" .. a end` — string lex compare.
- Iteration: cache `local active = csm.getAllActive()`; double loop `for i=1,#active do for j=i+1,#active do ... end end` produces lex-sorted unique pairs naturally if `active` is pre-sorted by crowdId; otherwise build pairKey via F2.
- Pre-sort `active` by `crowdId` once at top of tick to make `pairKey` cheap for AC-10 diff (Story 006 consumes).
- Output: `_overlapPairs = { {a, b, pairKey, distSq} ... }` — only overlapping pairs accumulated; non-overlap pairs discarded.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: skeleton + Phase 1 wiring.
- Story 003: F3 drip math.
- Story 004: skip conditions.
- Story 005: overlap-bit feed.
- Story 006: pairEntered diff.

---

## QA Test Cases

- **AC-03 (Unique pairs)**:
  - Given: 3 crowds with 3-element active list
  - When: pair iteration runs
  - Then: spy on F1 isOverlap call shows 3 invocations; pairKeys exactly `{"111|222","111|333","222|333"}`
  - Edge cases: 1 crowd → 0 pairs; 2 crowds → 1 pair; 12 crowds → 66 pairs.

- **AC-04 (F1 Y-ignored)**:
  - Given: A `(0,0,0)` r=8, B `(10,50,0)` r=8, C `(20,0,0)` r=8
  - When: pairs evaluated
  - Then: A-B overlap=true; A-C overlap=false; B-C overlap=false
  - Edge cases: exact boundary (distSq == combinedSq) → overlap=true (≤ inclusive).

- **AC-05 (F2 pair_key)**:
  - Given: id pairs `("3891","512")`, `("512","3891")`, `("000","999")`, `("aaa","aab")`
  - When: pairKey called
  - Then: `"3891|512"`, `"3891|512"`, `"000|999"`, `"aaa|aab"`
  - Edge cases: equal strings (impossible — CSM rejects duplicate ids).

- **AC-15 (Stacked position)**:
  - Given: A and B at `(5,0,5)`, A r=3.05, B r=3.05
  - When: overlap evaluated
  - Then: distSq=0; overlap=true; no error
  - Edge cases: r=0 → degenerate but combinedSq=0 → overlap on stack only.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/pair_iteration_overlap.spec.luau` — must exist and pass

**Status**: [x] Created 2026-05-08 — 18 it() blocks (AC-03 ×5, AC-04 ×4, AC-05 ×5, AC-15 ×3, scratch-cleared ×1)

---

## Dependencies

- Depends on: Story 001 (Phase 1 skeleton).
- Unlocks: Stories 003, 005, 006 (consume `_overlapPairs`).

---

## Completion Notes

**Completed**: 2026-05-08 (Sprint 6 task 6-6)
**Criteria**: 4/4 covered (AC-03 / AC-04 / AC-05 / AC-15) via `tests/unit/collision/pair_iteration_overlap.spec.luau` — 18 it() blocks.
**Approach**: Extended existing CollisionResolver module (Story 001 skeleton) with module-level helpers (`pairKey` lex-canonical + `isOverlapSq` 2D squared-distance + module-level `crowdIdComparator` for zero-alloc sort). Replaced Story 001 stub in `tickPhase1` with: pre-sort `active` by crowdId (lex-deterministic pair order regardless of CSM `pairs()` traversal) + `i<j` double loop populating `_overlapPairs` with `{ a, b, pairKey, distSq }` per overlapping pair. F1 squared-distance overlap, Y axis ignored, no `math.sqrt`. Test-only accessors `_getOverlapPairsLength`, `_snapshotOverlapPairs`, `_pairKey`, `_isOverlapSq` exposed for unit testing without leaking mutable scratch.
**Audit gates**: `selene src/` 0/7/0 baseline maintained (one transient `manual_table_clone` warning fixed in-loop via `table.clone`); `audit-asset-ids.sh` PASS; `audit-persistence.sh` PASS.
**Code Review**: Skipped (lean mode). gameplay-programmer + qa-tester ad-hoc reviews APPROVED WITH SUGGESTIONS; all 4 suggestions applied in-loop (hoist comparator, use pairKey helper not inline shortcut, add B-C non-overlap integration test, add a/b ref identity assertion).
**ADR-0004 mutation question resolved**: `table.sort(active, ...)` mutates the local copy of the fresh array returned by `getAllActive`. Read-only contract targets CrowdRecord field mutation, not local-array reordering. CSM doc-comment lines 367-368 explicitly states "fresh array each call — callers may discard or hold". Code comment lines 174-176 documents reasoning.
**Deviations**:
- ADVISORY — F1 invocation spy-count assertion (story QA row "spy on F1 isOverlap call shows 3 invocations") not implemented. Output-equivalence assertion (pair count + pairKey set + a/b refs) is stronger correctness proof. `isOverlapSq` is module-local; wrapping would require refactor for zero behavior gain.
- ADVISORY (carried from Story 001) — `getClock()` discard each tick line 164. AbsorbSystem precedent line 178. Sub-µs cost vs Phase 1 0.6 ms budget.
**Files changed**:
- `src/ServerStorage/Source/CollisionResolver/init.luau` (extended: helpers + replaced stub + 4 test-only accessors)
- `tests/unit/collision/pair_iteration_overlap.spec.luau` (new, 18 it() blocks)
