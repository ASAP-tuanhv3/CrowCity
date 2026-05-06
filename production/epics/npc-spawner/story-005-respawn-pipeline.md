# Story 005: Respawn pipeline — delay, position, crowd exclusion, fallback

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md`
**Requirement**: `TR-npc-spawner-002`, `TR-npc-spawner-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Respawn Contract
**ADR Decision Summary**: After reclaim, schedule respawn at `Uniform[5s, 10s]` delay (F3). Respawn position chosen so that `dist(pos, every active crowd) >= NPC_RESPAWN_MIN_CROWD_DIST = 30m` (consults `CSM.getAllCrowdPositions` read-only). If no valid position after N retries, fallback rule: pick farthest-from-crowds candidate (best-effort).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `task.delay` for respawn timer; CSM `getAllCrowdPositions` is read-only API per ADR-0004.

**Control Manifest Rules (Feature layer)**:
- Required: NPCSpawner read-only CSM consumer — `getAllCrowdPositions()` only (ADR-0008)
- Required: Respawn delay `Uniform[5s, 10s]` per F3 (GDD)
- Required: Respawn position dist ≥ 30m from active crowds (ADR-0008)
- Forbidden: NPCSpawner mutate CSM (ADR-0004 + ADR-0008)
- Forbidden: Mid-round `Instance.new` — reuse parked Part (ADR-0008)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-10 (Respawn delay Uniform[MIN, MAX])**: 1000-sample of respawn delays — mean ≈ 7.5s, min ≥ 5.0s, max ≤ 10.0s, distribution uniform (KS test passes at α=0.05).
- [ ] **AC-11 (Respawn position respects crowd exclusion)**: respawned NPC pos satisfies `min_dist(pos, anyCrowdCenter) >= 30m` for ≥99% of respawns under typical crowd layout.
- [ ] **AC-12 (Respawn fallback)**: when no valid position after `NPC_RESPAWN_MAX_RETRIES = 50` samples, fallback picks position with max `min_dist` to any crowd (best-effort), and emits one warning log per round (rate-limited).
- [ ] **Reuse parked Part**: respawn does NOT call `Instance.new` — reuses Part from `_pool` set inactive by reclaim.

---

## Implementation Notes

*Derived from ADR-0008 §Respawn Contract:*

- `_scheduleRespawn(npc)` body (called from end of reclaim Story 002):
  - `local delay = uniform(NPC_RESPAWN_MIN_DELAY, NPC_RESPAWN_MAX_DELAY)` (5s, 10s).
  - `npc._respawnTimer = task.delay(delay, function() _doRespawn(npc) end)`.
- `_doRespawn(npc)`:
  - Sample candidate position: uniform random in arena bounds.
  - Compute `min_dist` to any crowd center via `csm.getAllCrowdPositions()` (read-only).
  - Accept if `min_dist >= NPC_RESPAWN_MIN_CROWD_DIST`. Reject + retry up to `NPC_RESPAWN_MAX_RETRIES = 50`.
  - On retry exhaustion: pick the candidate with the largest seen `min_dist` (track during retries); log warning rate-limited 1/round.
  - Set `npc.Part.CFrame = CFrame.new(pos)`; `npc.Part.Transparency = 1` (Story 006 fades to 0); `npc.active = true`; push into active list; invalidate cache.
  - Reset walk loop state: `npc._walkStart = t_now`, fresh `_heading` + `_walkDur`.
- `_destroyAll` (Story 007) cancels all `_respawnTimer` via stored handles.
- Constants: `NPC_RESPAWN_MIN_DELAY = 5.0`, `NPC_RESPAWN_MAX_DELAY = 10.0`, `NPC_RESPAWN_MIN_CROWD_DIST = 30`, `NPC_RESPAWN_MAX_RETRIES = 50`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: reclaim hooks `_scheduleRespawn` at end.
- Story 006: Transparency 1→0 fade (this story sets transparency=1; fade owned by 006).
- Story 007: destroyAll cancels timers.
- Story 008: F4 steady-state population guard.

---

## QA Test Cases

- **AC-10 (Uniform delay)**:
  - Given: injected RNG seeded; 1000 reclaims observed
  - When: each delay sample recorded
  - Then: min ≥ 5.0, max ≤ 10.0, mean ∈ [7.4, 7.6], KS test p > 0.05 vs Uniform(5,10)
  - Edge cases: edge of bounds — boundary inclusive on min, exclusive on max (or both inclusive — choose convention; document in code).

- **AC-11 (Crowd exclusion)**:
  - Given: 4 crowds at fixed positions; respawn 100 NPCs
  - When: position assignment runs
  - Then: ≥99 of 100 respawns satisfy min_dist ≥ 30m to any crowd
  - Edge cases: crowds packed in center — fallback rule kicks in for some; no crash.

- **AC-12 (Fallback)**:
  - Given: arena fully covered by crowd 30m exclusion zones (synthetic constructed scenario)
  - When: respawn attempt runs
  - Then: 50 retries exhausted; fallback picks max-min-dist candidate; warning logged once per round
  - Edge cases: zero crowds → first sample accepted (no exclusion); single crowd → simple sphere exclusion.

- **Reuse Part**:
  - Given: spy on `Instance.new`
  - When: 100 respawns run
  - Then: spy count == 0
  - Edge cases: same Part reused → CFrame set + transparency reset + active=true.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/respawn_pipeline.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool), Story 002 (reclaim hook), Story 003 (cache invalidation), Story 004 (walk loop state).
- Unlocks: Story 006 (fade-in tween), Story 007 (timer cancel), Story 008 (steady-state).
