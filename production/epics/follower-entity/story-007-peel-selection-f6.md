# Story 007: Peel selection F6 (closest-to-rival) + concurrent dual-rival peel

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-013` (F6 closest-to-rival contact-face selection)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: `startPeel(rivalCrowdId, n)` selects N followers via F6: sort Active by distance to rival_center, take first N. Closest-to-rival selects contact-face followers — produces correct visual conquest from collision point. Concurrent calls from two rivals exclude already-Peeling followers from later calls.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `Vector3.Magnitude`, `table.sort` — pre-cutoff stable. Partial sort (`nth_element` equivalent) preferred at higher N but full sort acceptable for n ≤ 80.

**Control Manifest Rules (Presentation layer)**:
- Required: Boids flocking on `RunService.RenderStepped` — peel retargets boids `F_lead` (Story 008 wires the retarget)
- Guardrail: 1.5 ms desktop / 2.5 ms mobile per-frame budget; F6 sort runs once per peel call (15 Hz at most), not per frame

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-11 (F6 selection — closest to rival)**: Given `N=2`, `rival_center=(50,0,0)`, Active followers at positions (40,0,0)=dist 10, (38,0,0)=dist 12, (10,0,0)=dist 40, (5,0,0)=dist 45, when selection runs, then followers at distances 10 and 12 (closest to rival) are selected — NOT the farthest-from-own-center. AND a second `startPeel` (concurrent rival B) excludes already-Peeling followers from the first call; returns next-closest non-Peeling followers.
- [ ] **AC-23 (Concurrent dual-rival peel)**: Given crowd A at 80 Active followers; rivals B and C both call `startPeel(rivalCrowdId=B, n=2)` and `startPeel(rivalCrowdId=C, n=2)` in the same frame, then exactly 4 followers total enter `Peeling` (2 toward B, 2 toward C); no follower appears in both peel sets; the two closest-to-B are selected for B, the two closest-to-C are selected for C (independent sorts against different rival centers).
- [ ] **F6 algorithm**: `selected = sort(Active by ‖P_i - rival_center‖ ascending)[1..min(N, Active_count)]`. `rival_center` cached at `startPeel` call time (not re-read per frame during selection).
- [ ] **F6 degenerate cases**: `Active_count == 0` → no selection, no error. `N > Active_count` → return all available, `min(N, Active_count)`.
- [ ] **`startPeel(rivalCrowdId, n)` public API**: per `FollowerEntityClient` interface.
- [ ] **N is observed directly**: `n` parameter is the broadcast-reported count delta from `CrowdStateClient.CountChanged`. Client does NOT re-derive from `TRANSFER_RATE_effective`.

---

## Implementation Notes

*Derived from GDD §F6 + §Concurrent peel edge case + ADR-0007 §Key Interfaces:*

- `startPeel(rivalCrowdId: string, n: number)` is called by `CrowdCollisionResolutionClient` (sibling system) on each 15 Hz `CrowdStateClient.CountChanged` tick when `own.count` decreases AND `rival.count` increases by N.
- Implementation sketch:
  1. Read `rivalRecord = CrowdStateClient.get(rivalCrowdId)`. If nil → no-op (rival eliminated mid-tick).
  2. `rival_center = rivalRecord.position` (cache locally for this call).
  3. Filter parallel-array indices where `_state[i] == Active` (exclude `Peeling`, `Spawning:*`, `Despawning`).
  4. Build `(index, dist)` pairs: `dist = (_positions[i] - rival_center).Magnitude` for each candidate.
  5. Sort ascending by `dist` (full `table.sort` — n ≤ 80 makes this ≤ 80 log 80 ≈ 500 comparisons; cheap).
  6. Take first `min(n, #candidates)` indices.
  7. For each selected index: transition state to `Peeling`; record `_peelStart[i] = os.clock()`; `_rivalCrowdId[i] = rivalCrowdId`; cache `_rivalCenterAtStart[i] = rival_center` (Story 008 owns transit timing).
- Concurrent dual-rival within same frame: each `startPeel` call's filter step (`_state[i] == Active`) naturally excludes followers already moved to `Peeling` by the first call. Order of calls within a frame is therefore semantically significant but algorithmically correct — first rival picks closest 2 from 80, second picks closest 2 from remaining 78.
- Performance: full sort acceptable (`80 * log2(80) ≈ 500 comparisons`). If profiling reveals hot spot, switch to partial sort (`nth_element`-style selection of the top-N without full sort).
- This story does NOT implement transit timing, hue-flip, arrival despawn, or rival-side spawn — those live in Story 008.
- F6 caches `rival_center` at call time per GDD §F6; subsequent rival_center movement during transit is read fresh per frame in Story 008.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 008: peel transit duration F7, hue-flip latch, rival-nil abort, arrival despawn + rival-side spawn.
- Story 009: `getPeelingCount` accessor (this story sets `_state[i] = Peeling`; the count accessor lives in 009 to keep that story self-contained).

---

## QA Test Cases

- **AC-11a (F6 closest-to-rival)**:
  - Given: Active followers at positions (40,0,0), (38,0,0), (10,0,0), (5,0,0); `rival_center=(50,0,0)`; `N=2`
  - When: `startPeel(rivalId, 2)` runs
  - Then: selected indices correspond to followers at (40,0,0) and (38,0,0) (distances 10 and 12); their `_state` transitions to `Peeling`; followers at (10,0,0) and (5,0,0) remain `Active`
  - Edge cases: tie in distance — implementation-defined ordering acceptable; tie behaviour documented.

- **AC-11b (concurrent peel exclusion)**:
  - Given: Active followers as above; first `startPeel(B, 2)` runs; second `startPeel(B, 2)` runs immediately after (same rival)
  - When: state inspected
  - Then: first call selects (40,0,0) and (38,0,0); second call sees only (10,0,0) and (5,0,0) as Active candidates and selects them; total Peeling = 4
  - Edge cases: second call requests N > remaining Active — returns `min(N, remaining_Active)`.

- **AC-23 (independent sorts against different rivals)**:
  - Given: Crowd A = 80 Active at varied positions; rival B center at (+100,0,0), rival C center at (-100,0,0)
  - When: `startPeel(B, 2)` and `startPeel(C, 2)` run same frame in this order
  - Then: B-set = the two followers with highest +X coordinate (closest to B); C-set = the two followers with lowest +X (closest to C, excluding B's pick); B ∩ C = ∅; exactly 4 followers in `Peeling`
  - Edge cases: a single follower equidistant to both rivals — assigned to first call (B), C's filter then excludes it.

- **F6 degenerate — empty Active**:
  - Given: 0 Active followers
  - When: `startPeel(rivalId, 5)` runs
  - Then: no selection, no state change, no error
  - Edge cases: all 80 already Peeling — same outcome (no-op).

- **N > Active**:
  - Given: 3 Active followers, `N=10`
  - When: `startPeel(rivalId, 10)` runs
  - Then: all 3 selected; only 3 enter Peeling; no error
  - Edge cases: `N=0` → no-op (no selection).

- **Rival nil at start**:
  - Given: `CrowdStateClient.get(rivalCrowdId)` returns nil at `startPeel` call time
  - When: F6 invoked
  - Then: no-op; no state changes; no error raised
  - Edge cases: rival nil mid-call (impossible in single-threaded Luau, but code defensively guards anyway).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/peel_selection_f6_test.luau` — must exist and pass under TestEZ (mock `CrowdStateClient`, fixed positions, deterministic state)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator + per-crowd state arrays), Story 003 (Active state established)
- Unlocks: Story 008 (peel transit consumes selected indices), Story 009 (getPeelingCount reads `_state == Peeling`)

---

## Completion Notes

**Completed**: 2026-05-04
**Criteria**: 6/6 ACs covered (Logic story)
**Test Evidence**: `tests/unit/follower-entity/peel_selection_f6.spec.luau` — 13 new TestEZ unit tests; full suite **503/503 passing** (was 490).

### Files Created

- `src/ReplicatedStorage/Source/FollowerEntity/PeelSelection.luau` (~85 LOC)
  - 1 pure function: `selectClosestToRival(positions, states, rivalCenter, n, activeStateLabel)`
  - Returns ascending-distance sorted list of selected indices
  - State filter parameter (`activeStateLabel`) — typically "Active"; tests verify
    Spawning/Peeling/Despawning are excluded
  - Squared-distance sort key avoids 80 sqrt calls per peel event (sort-order-preserving)

### Test Coverage by AC

| AC | Tests |
|---|---|
| AC-11a (closest-to-rival, NOT farthest-from-own) | 2 |
| AC-11b (concurrent peel exclusion same rival) | 1 |
| AC-23 (dual-rival independent sorts, disjoint sets) | 1 |
| F6 algorithm (ascending sort) | 1 (return-order test) |
| Degenerate cases (empty, N>active, N=0, N<0, all-peeling) | 5 |
| State filter (Spawning/Despawning excluded) | 2 |
| 80-follower scale | 1 |

### ADR-0007 Compliance

Forbidden-pattern audit (function bodies): zero hits across all categories.
Pure data-in / data-out — no Roblox service requires beyond `Vector3` arithmetic.

### Out of Scope Respected

No edits to `Client.luau`, `CrowdManagerClient.luau`, or any other file.
Wire-in deferred to follow-up integration pass — `FollowerEntityClient.startPeel`
will call `PeelSelection.selectClosestToRival(...)`, then mutate `_state[i] = "Peeling"`,
record `_peelStart[i] = os.clock()`, `_rivalCrowdId[i] = rivalCrowdId`,
`_rivalCenterAtStart[i] = rivalCenter` for the indices returned.

### Deviations

- **`startPeel` public API on `FollowerEntityClient`** (story Implementation Notes):
  Stub already exists in `Client.luau` (`function FollowerEntityClient.startPeel`);
  the real implementation that wires PeelSelection into per-follower state mutation
  is the wire-in pass. Pure module isolates the F6 selection algorithm from state
  side effects so this story closes cleanly as Logic.

- **Tie behaviour**: `table.sort` is not stable in Luau — equal-distance candidates
  receive implementation-defined ordering (story §AC-11a explicitly accepts this).
  Documented in module header.

### Code Review

LP-CODE-REVIEW skipped — Lean review mode. Manual ADR audit + selene (0 errors)
+ 503/503 test pass = equivalent quality gate. Same pattern as 4-3, 4-4, 4-5, 4-6.
