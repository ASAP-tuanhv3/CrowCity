# BUG-002 — Followers Clumped Like a Ball Despite Boid Forces Wired

**Severity**: S2 (Visual/Feel — sprint goal not directly blocked but quality issue)
**Status**: Open
**Reported**: 2026-05-09 by tuanhv3 (manual QA in Studio Local Server, 2 clients)
**Sprint**: 6
**Story refs**: 6-1 (visual loop) — observed during TC-S1-03 / TC-S1-04
**Test case**: TC-S1-04 in `production/qa/test-cases-sprint-6-2026-05-09.md`

## Summary

Spawned followers cluster tightly at a single point ("stuck together like a ball") and remain clumped regardless of player movement. Boid separation/cohesion/follow-leader forces ARE wired in code (`src/ReplicatedStorage/Source/FollowerEntity/Client.luau:643-660`) and exercised by Story 4-3 unit tests, but the observable in-Studio behavior shows no spread.

## Steps to Reproduce

1. `rojo serve` connect Studio
2. Test → Local Server → 2 players → Start
3. Wait for `[MSM] State → Active`. Player crowd spawns with 10 followers (CROWD_START_COUNT=10)
4. Observe follower cluster around Client 1 character at standstill — followers visually overlap at one point
5. Walk Client 1 character around the world. Observe follower bundle as the player moves
6. Stop. Observe again

## Expected (per TC-S1-04)

Follower bundle occupies a visibly larger screen area as count grows. At baseline count=10, followers should already be visibly distinct entities, separated by ≥ SEPARATION_RADIUS (2.5 studs). During motion they should arc and trail in a swarm shape, not a point.

## Actual

Followers stay clumped as a tight ball both at standstill and while moving. No visible separation even though all 10 spawn close together (which should trigger maximum separation force per F1 boid math).

User verbatim: "the initial follower stuck together like a ball" + confirmed "stay clumped no matter what" when moving.

## Impact

- Visual fidelity does not match GDD §F4 boid swarm intent
- Crowdsmith identity (visible swarm of followers) compromised — looks like one entity
- Player cannot read crowd size at a glance — count is illegible from visuals
- BLOCKING for Sprint 7 art/design review of crowd readability
- NOT directly blocking the count-grow loop (BUG-001 owns that)

## Investigation Pointers

Boid forces ARE wired correctly per code review:
- `Boids.separation` called at `src/ReplicatedStorage/Source/FollowerEntity/Client.luau:643`
- `Boids.cohesion` at line 647
- `Boids.followLeader` at line 650
- `Boids.finalVelocity` composes V with weights at line 651
- `Boids.applyVelocity` writes new position to `self._positions[i]` at line 660
- Tuning values look reasonable: SEPARATION_WEIGHT=1.5, COHESION_WEIGHT=1.0, FOLLOW_LEADER_WEIGHT=3.0, SEPARATION_RADIUS=2.5, NEIGHBOR_RADIUS=6.0, MAX_SPEED=16

Plausible causes (most-likely first):

### 1. CFrame composition does not use boid `_positions[i]`
Line 660 writes `self._positions[i] = newPos` from boid math, but the actual CFrame applied to the rendered bundle (line 685+ region) may be sourcing from a different field (rootTarget, lastCrowdCenter, or LOD-tier-specific impostor offset). If the boid output is computed but never rendered, followers stay at their spawn offset forever.

### 2. All `_spawnOffsets[i]` are zero or near-zero
Line 300: `self._spawnOffsets[i] = position - self._lastCrowdCenter`. If pool spawn positions all collapse to the same offset (e.g. all spawn at `crowd.position` with no random scatter), every follower starts at the SAME point. Boid separation needs nonzero distance to compute direction (EPSILON=0.001 prevents NaN but produces near-zero displacement per tick).

### 3. Followers never reach `FOLLOWER_STATE_ACTIVE`
Boid math only runs in the `state == FOLLOWER_STATE_ACTIVE` branch (line 640). If followers are stuck in `FOLLOWER_STATE_FADE_IN` or `SLIDE_IN`, boids never apply. Verify state machine progression in Studio: print `_followerStates` table after spawn.

### 4. `renderF4` flag false on all followers
Line 641: `if renderF4 then` — F4 boid math gated. If LOD tier is forcing impostor mode (LOD 1+), boids are skipped. Verify `_tier` value on followers near the player (LOD 0 expected at < 30 studs).

### 5. Bundle CFrame override path
Line 685-688 has tier-specific CFrame composition. The LOD 1+ path "rootTarget unchanged" may keep followers anchored to crowd center regardless of boid position update.

## Recommended Sprint 7 Investigation

1. **Add per-follower position log:** print `_positions[1]` and `_positions[5]` once/sec for 5s after spawn. Confirm boid math is actually mutating the array (not stuck at spawn position).
2. **Verify CFrame source:** read the actual CFrame assignment block at line 685-720 (truncated in this analysis). Confirm `bundle.body.CFrame` reads from `_positions[i]`, not `_spawnOffsets[i] + _lastCrowdCenter`.
3. **Spawn scatter check:** read `Pool.luau` to confirm `computeSpawnPositions` returns scattered positions, not all-zero offsets. If all-zero, boid F1 separation force returns near-zero magnitude (EPSILON guard).
4. **LOD tier check:** force LOD 0 manually and re-test. If followers spread under LOD 0 but clump under LOD 1+, the impostor path is overriding boid output.

## Related

- Story 4-3 (Boids F1-F4) — unit tests pass in isolation; check `tests/unit/follower-entity/boids_*.spec.luau`
- Story 4-4 (walk-bob + sway animation) — runs alongside boids
- Story 4-5 (FadeIn / Despawning state machine) — see SpawnStates.luau
- BUG-001 — separate but related: the count-grow path may surface this issue more visibly once absorb works (more clumped balls)

## Workaround

None for end-user. Developer can manually set `FollowerBoidsConfig.SEPARATION_WEIGHT = 5.0` (above documented [0.5, 4.0] range) to force visible spread. Not for production — masks the underlying defect.
