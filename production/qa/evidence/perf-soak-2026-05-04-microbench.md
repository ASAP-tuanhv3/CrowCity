# Follower Entity perf soak — AC-17 partial evidence (microbench)

**Date**: 2026-05-04 (updated 2026-05-05 with wire-in pass)
**Story**: production/epics/follower-entity/story-011-perf-soak-validation.md
**Status**: PARTIAL — pure-module microbench + production wire-in PASS; manual Studio Player 60-second soak STILL DEFERRED for human sign-off
**Scenario**: Composition microbenchmark via integration test
**Hardware**: TestEZ headless harness (run-in-roblox + Roblox Studio)
**Build**: rojo-built `test.project.json`

## Verdict: PARTIAL PASS — pure-module composition under budget proxy

The 8 pure modules (Boids, Animation, SpawnStates, SpawnThrottleQueue,
HueReconciler, PeelSelection, PeelTransit, PoolResize, LODTierMath) compose
correctly into a full per-frame pipeline.

### Microbench: 80 follower × 60 frame composition timing

**Test**: `tests/integration/follower-entity/full_pipeline_composition.spec.luau`
- `test_pipeline_AC17_80_followers_60_frames_under_budget_proxy`

**Setup**: 80 LOD-0 followers in random offsets within 5-stud radius around
crowd_center (0,0,0). Steady-state target hue. 60 frames @ dt = 1/60.

**Pipeline per frame**:
1. Teleport detection (LODTierMath.shouldTeleportSnap)
2. Hue dirty-flag evaluation (HueReconciler.evaluate)
3. Per-follower state machine:
   - Active: Boids F1-F4 + Animation F8/F9 (LOD-gated)
   - SlideIn: position lerp (boids suspended)
   - FadeIn: alpha tween (boids active)
   - Peeling: PeelTransit retarget + hue-flip latch + arrival check

**Result**: 60-frame composition completed in well under 500 ms
(generous CI ceiling — actual values typically 2-50 ms depending on host).
80 followers Active throughout; no state corruption.

### What this evidence DOES validate

- ✓ The 8 pure modules compose into a working pipeline (interface contracts)
- ✓ State transitions fire correctly across module boundaries
  (Active ↔ SlideIn ↔ FadeIn ↔ Peeling ↔ Despawning)
- ✓ Hue dirty-flag short-circuits steady-state writes (1 hue write across 60
  frames for 80 followers; AC-4b confirmed at composition layer)
- ✓ Pure-module hot path allocates no Roblox Instances per frame (AC-18
  structural invariant — verified by audit + integration test array sizes)
- ✓ Module timing fits within order-of-magnitude budget pre-Roblox-API overhead

### What this evidence DOES NOT validate (DEFERRED)

- ✗ Production-fidelity 60-second sustained soak in Roblox Player (AC-17 explicit)
- ✗ p99 frame budget ≤ 2.5 ms with full Roblox Studio Micro Profiler (`debug.profilebegin`)
- ✗ BasePart property writes (Body.Color, Body.CFrame, Transparency)
- ✗ VFXManager.playEffect dispatch on hue-flip (Story 4-8 caller side)
- ✗ Pool.grantBundle / returnBundle integration overhead
- ✗ RunService.RenderStepped wiring overhead
- ✗ Mobile-platform validation (separate AC, deferred to MVP-Integration-1)

### Wire-in pass — COMPLETE (added 2026-05-05)

The 8 pure modules have been adopted into production `FollowerEntity/Client.luau`
and `CrowdManagerClient.luau`:

- `Client.luau` (~470 LOC) — extended with new parallel arrays + real
  `spawnFromAbsorb`, `spawnFadeInAtCenter`, `startPeel`, `setLOD`,
  `setPoolSize`, `getPeelingCount`, full per-frame `_update` composing
  Boids + Animation + SpawnStates + HueReconciler + PeelTransit + LODTierMath.
  Backward-compatible (`#self._positions == 0` gates new pipeline so legacy
  `_debugSeedActiveFollowers` tests still pass).
- `CrowdManagerClient.luau` — global `SpawnThrottleQueue` instance; per-frame
  drain at SPAWN_THROTTLE_PER_FRAME=4; `enqueueAbsorbSpawn` public API for
  AbsorbClient sibling system; injected `_getCrowdState` getter into each
  `FollowerEntityClient` at construction.
- **Profiler wrap added**: `debug.profilebegin("FollowerEntityClient_Update")`
  / `debug.profileend()` wraps the per-frame iteration body in `onRenderStepped`.
- 12 new wire-in integration tests in
  `tests/integration/follower-entity/wire_in_end_to_end.spec.luau` exercise
  the production singleton path. Test suite: 594/594 passing.

### Required to close AC-17 fully (still manual)

1. ~~Wire-in pass~~ COMPLETE
2. ~~Wrap RenderStepped in profiler labels~~ COMPLETE
   ```lua
   ```lua
   RunService.RenderStepped:Connect(function(dt)
     debug.profilebegin("FollowerEntityClient_Update")
     for crowdId, client in self._crowds do
       client:_perFrameUpdate(dt)
     end
     debug.profileend()
   end)
   ```
3. **Build perf-fixture place**: 1 crowd × 80 LOD-0 followers, scripted patrol path.
4. **Manual capture**: run in Roblox Player (NOT Studio mode) for 60 s. Open
   Micro Profiler (Ctrl+F6). Filter label `FollowerEntityClient_Update`.
   Export 3,600 samples.
5. **Compute p99**: sort descending; sample at index 36 (1% × 3600). Target ≤ 2.5 ms.

## Sample distribution

*Not applicable — no Studio Player run yet. Microbench distribution is over
60 frames not 3600 (the AC's required sample size for p99).*

## Sign-off

- [ ] gameplay-programmer (pending wire-in pass)
- [ ] qa-lead (pending Studio capture)

## Notes

- Pure-module ADR-0007 audit clean: zero `Instance.new`, `WaitForChild`,
  `:Wait()`, `task.wait`, `Player.Character`, `Heartbeat:Connect`,
  `CrowdStateBroadcast`, `RunService` references in any function body.
- Test suite: 582 / 582 passing (unit + integration).
- Story 4-11 remains **BLOCKED** until Studio capture + sign-off.
