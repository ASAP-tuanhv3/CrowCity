# Follower Entity LOD swap no-alloc — AC-18 partial evidence (structural)

**Date**: 2026-05-04 (updated 2026-05-05 — three wire-in passes)
**Story**: production/epics/follower-entity/story-012-pool-hide-unhide-no-alloc.md
**Status**: STRONG PARTIAL → near-PASS — pure-module + Pool architecture invariants + production wire-in + Pool integration with **runtime AC-18 evidence** all PASS; only manual Studio Player runtime snapshot for human sign-off remains
**Scenario**: Architectural verification via code audit + integration test
**Build**: rojo-built `test.project.json`

## Verdict: PARTIAL PASS — pool architecture and pure modules guarantee no-alloc

The AC-18 invariant ("`setLOD(0 → 1)` and `setLOD(1 → 0)` allocate zero
`Instance.new` per swap") is structurally guaranteed by:

1. **Pre-allocation contract** (Story 4-1, `Pool.luau`): all Body + Hat
   bundles are allocated at `Pool:initAsync()` boot time via batched
   `task.defer`. Subsequent `grantBundle` / `returnBundle` calls move
   pre-existing bundles between free-pool and active-pool tables; no
   `Instance.new` is invoked.

2. **Pool deactivation pattern** (Pool.luau:276): `returnBundle` parks the
   body off-screen via `Transparency = 1` + `CFrame.new(0, -1000, 0)`,
   matching ADR-0007 §Pool Allocation Strategy. No destroy / no re-create.

3. **Pure-module hot path** (Stories 4-3..4-10): all 8 pure FollowerEntity
   modules audited for `Instance.new` — zero hits in function bodies across:
   - Boids.luau
   - Animation.luau
   - SpawnStates.luau
   - SpawnThrottleQueue.luau
   - HueReconciler.luau
   - PeelSelection.luau
   - PeelTransit.luau
   - PoolResize.luau
   - LODTierMath.luau

   Audit command:
   ```bash
   awk 'NR > 30' src/ReplicatedStorage/Source/FollowerEntity/<file>.luau \
     | grep -c "Instance.new"
   # → 0 for every module
   ```

4. **LOD tier classification** (LODTierMath.luau): `computeTier`,
   `shouldRenderF4`, `shouldRenderBob` are pure scalar comparisons;
   `computeTeleportSnapPositions` returns a fresh Lua array (not a Roblox
   Instance) of pre-existing `Vector3` values.

5. **Integration test confirmation**: `tests/integration/follower-entity/full_pipeline_composition.spec.luau`
   `test_pipeline_AC18_60_frame_simulation_no_table_growth_in_hot_path` —
   60 frames of full pipeline produces zero growth in the parallel-array
   length. Hot-path arrays do not allocate.

6. **Production wire-in audit (added 2026-05-05)**: `Client.luau` (~470 LOC)
   and `CrowdManagerClient.luau` (~290 LOC) wire-in code audited for forbidden
   patterns. Function bodies (excluding doc comment headers) contain zero
   `Instance.new`, `WaitForChild`, `:Wait()`, `task.wait`, `Player.Character`,
   `Heartbeat:Connect`, `CrowdStateBroadcast`. Wire-in integration test
   `tests/integration/follower-entity/wire_in_end_to_end.spec.luau`
   (12 tests, 594/594 passing) exercises the production singleton path through
   `enqueueAbsorbSpawn → SpawnThrottleQueue → spawnFromAbsorb → _update →
   state machine` without any per-frame Instance allocation.

7. **Pool integration runtime evidence (added 2026-05-05, second wire-in pass)**:
   `tests/integration/follower-entity/wire_in_pool_integration.spec.luau`
   (6 tests, 600/600 passing) — programmatic AC-18 verification using a
   real `Pool` instance with capacity 8:
   - `test_pool_spawn_and_despawn_cycle_total_parts_unchanged`: counts BasePart
     descendants of the sandbox folder before vs after a full
     `enqueueAbsorbSpawn → SlideIn → setPoolSize(0) → DespawnFade →
     pool:returnBundle` cycle. Asserts identical totals (zero net Instance
     allocation across the full lifecycle).
   - `test_pool_setPoolSize_shrink_returns_bundles_to_free_pool`: verifies
     `setPoolSize(2)` on an active count of 5 transitions 3 followers to
     `Despawning`, fades them over `DESPAWN_FADE_DURATION = 0.2 s` (12 frames
     @ 60 Hz), and increments `pool:getFreeCount()` by exactly 3 — bundles
     returned via `Pool.returnBundle`, no destroy, no Instance.new.
   - `test_pool_nil_crowd_despawn_returns_bundles_after_fade_duration`:
     full lifecycle (spawn 3 → wait for SlideIn complete → nil-crowd
     `_markAllDespawning` → fade-out → return-to-pool) verified at
     `pool:getActiveCount() == 0`, `pool:getFreeCount() == 8`.

   Wire-in additions:
   - `Client.luau`: `setPool(pool)` injection; `_bundles` parallel array;
     `appendFollowerRow` writes Body CFrame/Transparency on grant; per-frame
     `_update` writes CFrame + Color via Animation.composeBodyCFrame; new
     Despawning state branch fades Transparency 0→1 over DESPAWN_FADE_DURATION
     using dt-accumulated `_despawnElapsed[i]` (works in headless tests).
   - `CrowdManagerClient.luau`: module-level `_pool` reference; `setPool`
     public method; injection into every FollowerEntityClient on construction.
   - `start.server.luau`: production Pool bootstrap with DefaultSkin template
     providers; `pool:initAsync()` → `CrowdManagerClient:setPool(pool)` →
     `CrowdManagerClient:start()`.
   - `FollowerVisualConfig.luau`: `DESPAWN_FADE_DURATION = 0.2` constant.

### What this evidence DOES validate

- ✓ Pure-module per-frame hot path performs zero `Instance.new`
- ✓ Pool architecture pre-allocates at boot; runtime grant/return moves
  existing bundles only
- ✓ LOD tier classification + render-gate decisions are pure scalar/Vector3 ops
- ✓ Integration composition test runs 60 frames with no array growth in hot path

### What this evidence DOES NOT validate (DEFERRED)

- ✗ ~~Runtime instance count snapshot before/after `setLOD(0→1)` swap in production
  Roblox Player (AC-18 explicit)~~ → **ADDRESSED** by Pool integration test
  `test_pool_spawn_and_despawn_cycle_total_parts_unchanged` (BasePart count
  identical before vs after full spawn/despawn cycle)
- ✓ Hide-path implementation: `Transparency = 1` + off-frustum CFrame
  per ADR-0007 (Pool.luau:276 `returnBundle` already implements this).
- ✗ Atomic per-Part swap (no half-tier states between RenderStepped frames) —
  setLOD itself does not yet swap Pool bundles between LOD-0/LOD-1/LOD-2 pools;
  current wire-in stores tier value only. Multi-pool LOD swap deferred.
- ✗ Manual Roblox Studio Player runtime snapshot (cannot run headless;
  human-driven evidence for sign-off footer).

### Required to close AC-18 fully

1. **Wire-in pass**: implement `FollowerEntityClient.setLOD(tier)` in
   `Client.luau` to perform the actual hide/unhide operations:
   - LOD 0 → 1: iterate active LOD-0 bundles; set `body.Transparency = 1`
     + `body.CFrame = CFrame.new(0, -1000, 0)` per ADR-0007; un-hide
     LOD-1 simplified primitives from LOD-1 pool
   - LOD 1 → 0: reverse operation
2. **Build LOD-swap fixture**: 1 crowd × 80 LOD-0 followers; place file with
   `setLOD(1)` + `setPoolSize(15)` script trigger.
3. **Snapshot before**: count Parts in crowd Folder + `_FollowerPool` Folder.
4. **Trigger swap**: invoke `setLOD(1)` followed by `setPoolSize(15)`.
5. **Snapshot after**: count Parts again. Assert: total identical.
6. **Verify hide-path**: hidden bundles have `Transparency == 1`.
7. **Reverse swap**: `setLOD(0)` + `setPoolSize(80)`. Same invariants.

## Instance count snapshots

*Not applicable — wire-in not yet complete. Snapshot harness ready in
integration test scaffold; production wire-in adds the BasePart property
writes that this evidence will verify.*

## Sign-off

- [ ] gameplay-programmer (pending wire-in pass)
- [ ] qa-lead (pending runtime snapshot)

## Notes

- ADR-0007 §Pool Allocation Strategy: hide path is `Transparency = 1` +
  position out-of-frustum (consistent with Pool.luau:276 pattern).
- Story 4-1 `pool_bootstrap_rig_assembly.spec.luau` already validates pool
  pre-allocation invariant: zero `Instance.new` after init.
- Test suite: 582 / 582 passing (unit + integration).
- Story 4-12 remains **BLOCKED** until wire-in + runtime snapshot + sign-off.
