# Story 009: setPoolSize + Peeling immunity + getPeelingCount accessor

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-008` (Peeling immunity from cap-shrink eviction)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: `setPoolSize(n)` defensively re-clamps `actualN = max(n, getPeelingCount())` — Peeling subset is held immune within the same tick. Eviction targets `Active` + `Despawning` only. LOD Manager precomputes `n_effective = max(rawCap, getPeelingCount())` BEFORE calling setPoolSize per LOD GDD §F4 — defensive clamp guards against a buggy LOD caller.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: pure logic; no engine API risk.

**Control Manifest Rules (Presentation layer)**:
- Required: pool grant/return discipline (Story 001)
- Forbidden: per-frame `Instance.new`
- Guardrail: ≤150 rendered Parts per client view (cap shrink fires when this is exceeded)

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-9 (Peeling immunity)**: Given follower in `Peeling`, `setPoolSize(crowdId, n)` called with `n < current`, when LOD Manager queries `getPeelingCount(crowdId)`, then returns peel count; eviction only touches `Active` + `Despawning`; `Peeling` untouched.
- [ ] **AC-25 (setPoolSize cap scope — Active only)**: Given crowd with 10 Active + 3 Peeling (total 13), when `setPoolSize(crowdId, 8)` called, then 2 Active enter `Despawning:FadeOut`; all 3 Peeling remain `Peeling` untouched; `getPeelingCount(crowdId)` returns 3 after.
- [ ] **`setPoolSize(n)` defensive re-clamp**: implementation entry: `actualN = math.max(n, self:getPeelingCount())`. This guards against a buggy LOD caller that forgot the precomputation. Eviction count = `current_Active + current_Despawning - actualN` (never negative).
- [ ] **`getPeelingCount(crowdId): number`**: counts indices where `_state[i] == Peeling`.
- [ ] **Cap-growth path**: when `actualN > current_Active + current_Despawning`, queue (`actualN - current`) cap-growth FadeIn spawns into the throttle queue (Story 005).
- [ ] **Cap-shrink eviction order**: when shrinking, evict candidates in order: first `Despawning:FadeOut` followers already fading, then highest-distance-from-crowd-center `Active` followers (perimeter first; tightens the visible flock toward center).

---

## Implementation Notes

*Derived from ADR-0007 §Eviction-protection contract + GDD §Peeling immunity:*

- `getPeelingCount(self): number` iterates `_state` array counting `_state[i] == Peeling`. O(n) but n ≤ 80; cheap enough to call from LOD Manager every 0.1 s tick.
- `setPoolSize(self, n: number)` implementation:
  ```
  local peelCount = self:getPeelingCount()
  local actualN = math.max(n, peelCount)  -- defensive re-clamp
  local activeCount = self:_countByState(Active)
  local despawningCount = self:_countByState(Despawning)
  local nonPeelTotal = activeCount + despawningCount
  if actualN > nonPeelTotal then
      -- cap growth: queue (actualN - nonPeelTotal) FadeIn spawns via throttle queue
      local toSpawn = actualN - nonPeelTotal
      for k = 1, toSpawn do
          self:_queueFadeInSpawn()
      end
  elseif actualN < nonPeelTotal then
      -- cap shrink: evict (nonPeelTotal - actualN) followers, perimeter-first
      local toEvict = nonPeelTotal - actualN
      local candidates = self:_collectActiveAndDespawning()
      table.sort(candidates, function(a, b)
          return self:_distFromCenter(a) > self:_distFromCenter(b)  -- farthest first
      end)
      for k = 1, math.min(toEvict, #candidates) do
          self:_transitionToDespawning(candidates[k])
      end
  end
  -- actualN == nonPeelTotal: no-op
  ```
- Eviction NEVER touches `_state[i] == Peeling`. Peeling completion (Story 008 arrival) reduces peel count naturally; LOD Manager's next 0.1 s tick refines `n_effective` downward.
- Distance-from-center sort uses `(_positions[i] - crowd_center).Magnitude`. Tie-breaker: lower index first.
- Eviction sets `_state[i] = Despawning`; the existing per-frame update fires the 0.2 s alpha tween and returns the Part to pool on completion.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 005: actual `Spawning:FadeIn` flow + 4/frame throttle queue (this story enqueues, that story dequeues).
- Story 010: LOD tier change side-effects (`setLOD(tier)` — tier value affects render cap lookup; this story takes `n` as the cap directly).

---

## QA Test Cases

- **AC-9 (Peeling immunity sanity)**:
  - Given: 5 Active + 2 Peeling = 7 total in pool; `setPoolSize(crowdId, 4)` called
  - When: eviction runs
  - Then: `getPeelingCount` returns 2 (unchanged); eviction reduces Active to 2 (5 - 3 evicted = 2); 2 Peeling remain Peeling; `actualN = max(4, 2) = 4` correctly applied
  - Edge cases: `n < peelCount` (e.g. `setPoolSize(1)` with peelCount=2) — defensive clamp raises `actualN = 2`; only Despawning+Active reduced to 0; Peeling = 2 retained; total slots used = 2 (correct).

- **AC-25 (setPoolSize cap scope)**:
  - Given: 10 Active + 3 Peeling = 13 in pool; `setPoolSize(crowdId, 8)` called
  - When: state inspected after eviction
  - Then: Active = 8, Despawning = 2 (the 2 farthest evicted), Peeling = 3; `getPeelingCount(crowdId) == 3`; total = 13 (Despawning still occupies pool until fade completes)
  - Edge cases: same call when 5 Active + 8 Peeling = 13: `actualN = max(8, 8) = 8`; eviction touches only Active (5 → 5, 0 evicted because nonPeelTotal=5 < 8); cap-growth queues 3 FadeIn spawns.

- **getPeelingCount accessor**:
  - Given: 80-follower parallel arrays with mixed states (10 Active, 60 Peeling, 5 Despawning, 5 Spawning:FadeIn)
  - When: `getPeelingCount()` called
  - Then: returns 60
  - Edge cases: empty pool → returns 0; all Peeling → returns full count.

- **Cap growth path**:
  - Given: 5 Active + 0 Peeling = 5 in pool; `setPoolSize(crowdId, 12)` called
  - When: state inspected after call (before throttle dequeues)
  - Then: 7 FadeIn spawns enqueued in CrowdManagerClient throttle queue; Active still 5 (spawns happen on subsequent frames per Story 005 throttle)
  - Edge cases: cap growth when peelCount > rawCap — defensive clamp uses peelCount; no growth occurs.

- **Eviction perimeter-first order**:
  - Given: 5 Active at distances from center [10, 5, 20, 8, 15]; `setPoolSize(crowdId, 3)` called (evict 2)
  - When: eviction runs
  - Then: followers at distances 20 and 15 are the ones transitioned to Despawning; followers at 10, 8, 5 remain Active
  - Edge cases: tie in distance — lower index evicted first.

- **Defensive clamp — buggy caller**:
  - Given: peelCount=5; LOD Manager (buggy) calls `setPoolSize(crowdId, 2)` without precomputing `n_effective`
  - When: setPoolSize entry runs
  - Then: `actualN = max(2, 5) = 5`; no Peeling follower evicted; only Active+Despawning subset evaluated against actualN=5
  - Edge cases: peelCount=0 + n=2 → `actualN = max(2, 0) = 2`; normal path.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/set_pool_size_peeling_immunity_test.luau` — must exist and pass under TestEZ (parallel-array fixtures with controlled state distribution)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (per-crowd state arrays), Story 005 (throttle queue for cap growth), Story 007 (`Peeling` state set), Story 008 (`Peeling` lifetime)
- Unlocks: Story 010 (`setLOD` swap calls `setPoolSize` with the new tier's cap value), Story 012 (LOD swap evidence consumes setPoolSize behaviour)
