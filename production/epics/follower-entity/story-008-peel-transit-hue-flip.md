# Story 008: Peel transit F7 + hue-flip latch + rival-nil abort

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 5h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-007` (>= threshold-crossing latch, no float equality), `TR-follower-entity-014` (PEEL_MAX_DURATION cap), `TR-follower-entity-018` (hat retained through peel)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Peel transit retargets boids `F_lead` to `rival_center`. Hue flip at `T_peel * 0.5` via `>=` threshold-crossing with `_hueFlipApplied` boolean latch (mandatory — float equality forbidden). VFX Manager notified on flip with `VFXEffect.HueShift`. Rival-nil mid-peel → abort path: switch boids target back to own crowd, transition to Active on arrival (NOT Despawning).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `os.clock()`, `Color3`, `CFrame` — pre-cutoff stable.

**Control Manifest Rules (Presentation layer)**:
- Required: Custom non-Humanoid CFrame rig — no MoveTo, no AlignPosition during transit
- Guardrail: per-frame budget; transit math runs per follower per frame, must stay tight

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-5 (Hue flip at 50% peel)**: Given Active follower; `startPeel` selects it at `t=0` with `T_peel=2.0s` (`d_peel=40, PEEL_SPEED=20`); when `elapsed` first exceeds `T_hue_flip = 1.0s` (threshold-crossing, NOT float equality), then (a) `Body.Color` flips to rival hue in exactly 1 frame; (b) `_hueFlipApplied` latch set `true` — no second flip fires before arrival; (c) `VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame)` called once; (d) Hat color unchanged (skin-defined).
- [ ] **AC-12 (F7 peel duration)**: Given `d_peel=40, PEEL_SPEED=20, PEEL_MAX_DURATION=3.0`, then `T_peel=2.0s`, hue flip at `t=1.0s`. AND given `d_peel=120`, then `T_peel=3.0s` (capped); body arrives at rival center via direct CFrame on completion, NOT full 120-stud travel.
- [ ] **AC-22 (Rival nil mid-peel)**: Given follower in `Peeling` state targeting `rivalCrowdId`; when `CrowdStateClient.get(rivalCrowdId)` returns `nil` on the next per-frame read, then follower switches boids target to own-crowd center; transitions to `Active` on arrival (NOT `Despawning`); pool slot retained; no rival-side spawn fires.
- [ ] **F7 formula**: `T_peel = min(d_peel / PEEL_SPEED, PEEL_MAX_DURATION)`; `T_hue_flip = T_peel * 0.5`. `d_peel = ‖P_start - rival_center‖` cached at `startPeel` call.
- [ ] **`d_peel == 0` guard**: instant arrival — apply hue flip + arrival events immediately same frame; no transit; skip to Despawning → rival Spawning.
- [ ] **`_hueFlipApplied` latch**: per-follower boolean, initialised `false` at `startPeel`, set `true` on first frame where `elapsed >= T_hue_flip`. MUST use `>=` threshold-crossing — float equality (`elapsed == T_hue_flip`) is forbidden.
- [ ] **Hat retention**: hat stays with follower through `Peeling` (does NOT swap to rival hat) until arrival at rival pool. Hat swaps on the arrival `Despawning → Spawning` cycle (Story 005 + Story 001), NOT mid-transit.
- [ ] **Boids retarget**: during `Peeling`, `F_lead` reads `rival_center` (cached at start, refreshed each frame from `CrowdStateClient.get(rivalCrowdId)` if non-nil; uses cached value otherwise).
- [ ] **Arrival**: when `elapsed >= T_peel`: despawn from own pool (return Part); fire rival-side spawn trigger (`Spawning:FadeIn` per Story 005 on the rival crowd's `FollowerEntityClient`).
- [ ] **Capped peel CFrame snap**: when `d_peel > PEEL_SPEED * PEEL_MAX_DURATION`, follower travels for `PEEL_MAX_DURATION` then CFrame-snaps to rival center on arrival (does NOT lerp the remaining distance).
- [ ] **VFX call**: `VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame)` called exactly once per follower per peel (gated by latch).
- [ ] **Constants in `SharedConstants/FollowerVisualConfig.luau`**: `PEEL_SPEED = 20`, `PEEL_MAX_DURATION = 3.0`.

---

## Implementation Notes

*Derived from GDD §F7 + §Hue-flip timing + §Edge Cases (rival nil mid-peel):*

- Per-follower state added: `_peelStart[i]: number` (`os.clock`), `_T_peel[i]: number`, `_T_hue_flip[i]: number`, `_hueFlipApplied[i]: boolean`, `_rivalCrowdId[i]: string?`, `_rivalCenterCached[i]: Vector3`, `_d_peel[i]: number`.
- On `startPeel(rivalCrowdId, n)` selecting follower `i` (Story 007 selects; Story 008 sets transit fields):
  ```
  _peelStart[i] = os.clock()
  _rivalCenterCached[i] = CrowdStateClient.get(rivalCrowdId).position
  _d_peel[i] = (_positions[i] - _rivalCenterCached[i]).Magnitude
  _T_peel[i] = math.min(_d_peel[i] / PEEL_SPEED, PEEL_MAX_DURATION)
  _T_hue_flip[i] = _T_peel[i] * 0.5
  _hueFlipApplied[i] = false
  _rivalCrowdId[i] = rivalCrowdId
  ```
- `d_peel == 0` guard: `if _T_peel[i] == 0 then` → apply hue flip + dispatch arrival immediately same frame, skip transit.
- Per-frame update for follower in Peeling state:
  1. `elapsed = os.clock() - _peelStart[i]`.
  2. `rivalRecord = CrowdStateClient.get(_rivalCrowdId[i])`. If non-nil: `_rivalCenterCached[i] = rivalRecord.position`. If nil: keep cached value AND trigger rival-nil abort path (see below).
  3. Boids `F_lead` reads `_rivalCenterCached[i]` (replacing the own-crowd center for this follower).
  4. Hue-flip: `if (not _hueFlipApplied[i]) and (elapsed >= _T_hue_flip[i]) then Body.Color = HUE_COLORS[rivalHue]; _hueFlipApplied[i] = true; VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame) end`.
  5. Arrival: `if elapsed >= _T_peel[i] then` — despawn this follower (state → `Despawning`); fire rival-side spawn (`rivalCrowdManager.spawnAtCenter(rivalCrowdId)` or equivalent FadeIn trigger). If `_d_peel[i] > PEEL_SPEED * PEEL_MAX_DURATION`, set CFrame directly to `rival_center` before the despawn fade (capped peel CFrame snap).
- **Rival-nil abort path (AC-22)**:
  - `if rivalRecord == nil then` → switch boids target back to own-crowd center; mark `_peelAborted[i] = true`. On reaching own-crowd center (or on next frame if already in transit), transition to `Active` (not Despawning); reset `_rivalCrowdId[i] = nil`; do NOT fire rival-side spawn.
  - If own crowd is also nil at abort time → Despawning immediately (Story 002 nil-check path).
- **VFX dispatch**: import `VFXManager` (singleton); call `playEffect(VFXEffect.HueShift, Body.CFrame)` exactly at the latch transition. The latch ensures one-shot.
- **Hat unchanged**: do NOT touch `Hat.Color` during transit. Hat replacement happens on rival-side spawn (`Spawning:FadeIn` clones a fresh hat from the rival's skin).
- **Float equality forbidden**: never write `if elapsed == _T_hue_flip[i]` — at 60 FPS, `_T_hue_flip = 1.0` may never land exactly on a frame boundary. The `>=` check + boolean latch is the correct pattern.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 007: F6 selection of which followers peel.
- Story 005: `Spawning:FadeIn` flow that fires on rival-side arrival.
- Story 009: `getPeelingCount(crowdId)` accessor (this story sets state to `Peeling`; the accessor reads the parallel array).

---

## QA Test Cases

- **AC-5 (Hue flip at 50% peel + latch + VFX)**:
  - Given: follower at `_positions[i]=(0,0,0)`, `rival_center=(40,0,0)`, `startPeel` invoked at `os.clock() = T0`; mock advances `os.clock` by `1/60` per frame
  - When: per-frame update runs each frame for 2.0 s
  - Then: at the first frame where `elapsed >= 1.0s`: `Body.Color` flips to rival hue, `_hueFlipApplied[i] == true`, `VFXManager.playEffect` called exactly once with `(VFXEffect.HueShift, Body.CFrame)`; before that frame, no hue write, no VFX call; after that frame, no second flip fires before arrival
  - Edge cases: frame straddles `T_hue_flip` boundary — `>=` ensures one-frame trigger.

- **AC-12a (T_peel uncapped)**:
  - Given: `d_peel=40, PEEL_SPEED=20`
  - When: `_T_peel[i]` computed
  - Then: `_T_peel[i] == 2.0`, `_T_hue_flip[i] == 1.0`
  - Edge cases: `d_peel=0` → instant arrival path.

- **AC-12b (T_peel capped)**:
  - Given: `d_peel=120, PEEL_SPEED=20, PEEL_MAX_DURATION=3.0`
  - When: `_T_peel[i]` computed
  - Then: `_T_peel[i] == 3.0` (capped); on arrival frame, `Body.CFrame.Position == rival_center` (snapped, not 60-stud-traveled)
  - Edge cases: `d_peel == PEEL_SPEED * PEEL_MAX_DURATION` exactly — boundary case, `_T_peel == 3.0` either path.

- **AC-22 (Rival nil mid-peel)**:
  - Given: follower in `Peeling` to rival B; `CrowdStateClient.get("B")` mocked nil mid-transit
  - When: per-frame update runs after the nil
  - Then: boids `F_lead` retargets to own-crowd center; on reaching own-crowd center, state → `Active` (NOT `Despawning`); `_rivalCrowdId[i] == nil` after; no rival-side spawn fired; pool slot retained
  - Edge cases: own crowd ALSO nil at abort time — state → `Despawning` (Story 002 path).

- **`_hueFlipApplied` latch**:
  - Given: simulated edge-case where `os.clock()` jumps backward (impossible in practice; use mock)
  - When: per-frame update runs
  - Then: `_hueFlipApplied[i]` once true stays true for the lifetime of the peel; no second flip can fire
  - Edge cases: `_T_hue_flip == 0` (zero-distance peel) — flip applies same frame as `startPeel`.

- **Hat retention during transit**:
  - Given: follower with hat color = orange, peel transit to rival B (B hat color = purple)
  - When: observed every frame during transit
  - Then: `Hat.Color == orange` on every frame; on arrival despawn, follower's Part returns to pool with hat still orange; rival-side spawn (Story 005) clones a NEW Part with B's purple hat
  - Edge cases: rival skin changes mid-transit (out of MVP scope; documented).

- **Float equality forbidden — code search**:
  - Given: implementation files for hue-flip
  - When: grep for `elapsed == _T_hue_flip` or any `== T_hue_flip` pattern
  - Then: zero matches (only `>=` patterns allowed)
  - Edge cases: comments mentioning "do not use float equality" are acceptable matches.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/peel_transit_hue_flip_test.luau` — must exist and pass under TestEZ (mock `os.clock`, `CrowdStateClient`, `VFXManager`; deterministic frame ticks at `1/60` advance)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator), Story 003 (boids `F_lead` retargetable per-follower), Story 005 (rival-side `Spawning:FadeIn` arrival path), Story 006 (hue write protocol), Story 007 (F6 selection sets initial Peeling state)
- Unlocks: Story 009 (`getPeelingCount` reads `_state == Peeling`)
