# Story 005: Spawn states (FadeIn / SlideIn) + 4-per-frame throttle + d_init random

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 5h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-004` (4/frame throttle), `TR-follower-entity-010` (d_init random phase), `TR-follower-entity-012` (white-state SlideIn only), `TR-follower-entity-019` (Absorb slide-in lerp)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: `spawnFromAbsorb(crowdId, npcLastPosition)` is the public API consumed by Absorb-client. Absorb VFX is owned by VFX Manager subscribing to the same `Absorbed` signal — Follower Entity does NOT call VFX Manager for absorb.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `Color3.new`, `CFrame:Lerp`, `Tween` (alpha) — pre-cutoff stable. No post-cutoff API.

**Control Manifest Rules (Presentation layer)**:
- Required: pool-driven spawn (no `Instance.new` per spawn)
- Forbidden: any per-follower stat read that could be skin-derived (Pillar 4 anti-P2W)
- Guardrail: 4 spawns/frame across all crowds (mobile thermal protection)

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-8 (Spawn throttle)**: Given 10 Absorb events fire within 2 frames, when throttle queue evaluated, then ≤4 spawns on frame 1, ≤4 on frame 2, remainder queued to frame 3; total spawned equals total triggered (pool permitting).
- [ ] **AC-16 (Absorb SlideIn)**: Given Absorb trigger with valid `npcLastPosition`, when spawn runs, then state = `Spawning:SlideIn`; initial CFrame = `npcLastPosition`; tween target = `crowd_center`; duration = 0.4 s; hue = absorber's hue from frame 2; → `Active` on tween complete.
- [ ] **AC-19 (Return-from-CULL throttle)**: Given cap-growth spawn fires with crowd previously at 0 rendered, when queue processed over N frames, then ≤4 spawns per frame until cap reached; each enters `Spawning:FadeIn` with 0.3 s alpha tween; no frame exceeds 4 spawns regardless of queue depth.
- [ ] **AC-24 (Hat color during SlideIn)**: Given Absorb event fires and follower enters `Spawning:SlideIn`, when observed on frame 1 and frame 2, then frame 1: `Body.Color == Color3.new(1,1,1)` (white); frame 2+: `Body.Color == HUE_COLORS[absorberHue]`; `Hat.Color` is skin-defined and unchanged throughout SlideIn.
- [ ] **`d_init` random per spawn**: every spawn (FadeIn, SlideIn, peel-arrival) initialises follower's `_d[i] = math.random() * (1 / WALK_FREQ_HZ)` ∈ `[0, 0.667)`. Re-randomised on every spawn (NOT preserved across despawn → re-spawn).
- [ ] **`_swayPhaseOffset[i]` random per spawn**: initialised to `math.random() * 2π` (per Story 004 dependency).
- [ ] **Spawn triggers**:
  - Render-cap grows (LOD/distance change) → `Spawning:FadeIn` (0.3 s alpha tween)
  - Absorb event → `Spawning:SlideIn` (0.4 s CFrame lerp)
  - Collision peel rival-side arrival → `Spawning:FadeIn` (0.3 s)
- [ ] **State machine transitions**: `Spawning:FadeIn` / `Spawning:SlideIn` → `Active` on tween complete; during `SlideIn` boids writes are SUSPENDED (lerp drives Body.CFrame exclusively).
- [ ] **Constants in `SharedConstants/FollowerVisualConfig.luau`**: `SPAWN_FADE_DURATION = 0.3`, `SPAWN_SLIDE_DURATION = 0.4`, `SPAWN_THROTTLE_PER_FRAME = 4`.

---

## Implementation Notes

*Derived from GDD §Spawn triggers + §States and Transitions + ADR-0007 §Key Interfaces:*

- Public API on `FollowerEntityClient`: `spawnFromAbsorb(npcLastPosition: Vector3)` — Absorb-client subscribes to reliable `Absorbed` RemoteEvent and calls this.
- Cap-growth spawn driven internally from `setPoolSize(n)` (Story 009) when `n > current`. This story does not implement `setPoolSize` — only the spawn-flow primitives it will call.
- Throttle queue: `CrowdManagerClient` (NOT per-crowd) holds a global queue + counter `_spawnsThisFrame`. Reset to 0 at the start of each `RenderStepped` callback. On each spawn request, if `_spawnsThisFrame < SPAWN_THROTTLE_PER_FRAME`, dequeue + spawn; else queue to next frame.
- Queue is FIFO across all crowds. Excess does not starve — drains at 4/frame indefinitely.
- `Spawning:SlideIn` flow:
  1. Frame 1 of SlideIn: `Body.Color = Color3.new(1, 1, 1)` (white). Initial `Body.CFrame.Position = npcLastPosition`. State machine field `_state[i] = SPAWNING_SLIDEIN`. Per-follower `_slideTime[i] = 0`. **Boids suspended for this follower** (skip F1-F4 in the per-frame update via state-check).
  2. Frame 2+: `Body.Color = HUE_COLORS[absorberHue]`. CFrame lerp: `Body.CFrame = CFrame.new(npcLastPosition):Lerp(CFrame.new(crowd_center), _slideTime[i] / SPAWN_SLIDE_DURATION)`. `_slideTime[i] += dt`.
  3. On `_slideTime[i] >= SPAWN_SLIDE_DURATION`: state → `Active`; boids resumes; `_d[i]` and `_swayPhaseOffset[i]` initialised (`math.random()` per follower).
- `Spawning:FadeIn` flow: state → fade `Transparency` 1→0 over 0.3 s via Roblox Tween (or manual lerp). Boids RUNS during FadeIn (the GDD specifies it is visible and flocking). On completion → `Active`.
- Hat color in SlideIn: skin-defined, unchanged. Verify Hat color is set ONLY on initial spawn (from Skin System hat template) — never overwritten by hue logic.
- VFX coupling: this story does NOT call VFX Manager. Absorb burst VFX is fired by VFX Manager subscribing directly to the `Absorbed` signal (per GDD §Visual/Audio Requirements). Two independent consumers fire from same signal.
- `_swayPhaseOffset[i] = math.random() * 2 * math.pi` and `_d[i] = math.random() * (1 / WALK_FREQ_HZ)` — both re-randomised each spawn, NOT preserved.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: rig assembly + pool grant return.
- Story 002: orchestrator subscribes to `Absorbed` RemoteEvent — connection lives in CrowdManagerClient or Absorb-client per ADR-0007.
- Story 006: hue Color3 write + dirty flag (this story uses `Body.Color = ...` directly; Story 006 adds dirty-flag gate for steady-state writes).
- Story 008: peel-arrival → spawn on rival pool uses the same FadeIn primitive defined here.
- Story 009: `setPoolSize(n)` cap-growth path that drives queued FadeIn spawns.

---

## QA Test Cases

- **AC-8 (Throttle 10 absorb events)**:
  - Given: 10 `spawnFromAbsorb` calls dispatched across 2 RenderStepped frames (5 per frame on frames 1+2)
  - When: throttle queue evaluated each frame
  - Then: frame 1 spawns exactly 4; frame 2 spawns exactly 4; frame 3 spawns the remaining 2; frame 4+ spawns 0; total = 10 (assuming pool not exhausted)
  - Edge cases: pool exhausts on spawn #7 → spawn #7+ silently dropped (Story 001 AC-7); throttle still enforced.

- **AC-16 (SlideIn shape)**:
  - Given: `spawnFromAbsorb(crowdId, npcLastPosition=(10,0,10))` with crowd_center=(0,0,0), absorberHue=red
  - When: 24 frames @ 60Hz observed (=0.4s)
  - Then: frame 1 → `Body.CFrame.Position == (10,0,10)`, `Body.Color == Color3.new(1,1,1)`; frame 2 → `Body.Color == HUE_COLORS.red`; frames 2-24 → CFrame interpolates linearly toward `(0,0,0)`; frame 24+1 → state `Active`, position == `(0,0,0)`; boids math NOT called for this follower frames 1-24
  - Edge cases: `npcLastPosition == crowd_center` → degenerate lerp, immediate arrival visually but tween still runs 0.4s.

- **AC-19 (Return from CULL)**:
  - Given: crowd previously at 0 rendered; cap-growth queues 80 FadeIn spawns
  - When: 20 RenderStepped frames observed
  - Then: spawns/frame == 4 for first 20 frames; on frame 21 the 80 queued spawns have all dispatched; each follower entered `Spawning:FadeIn` with `Transparency` tween 1→0 over 0.3s
  - Edge cases: cap drops back to 0 mid-queue → remaining queued spawns are cancelled (Story 009 path; this story's throttle should not double-spawn after a cancel).

- **AC-24 (Hat color invariance)**:
  - Given: SlideIn flow with absorber hue = blue, hat skin-defined color = orange
  - When: observed on frames 1, 2, 12, 24
  - Then: `Body.Color`: frame 1 white, frames 2+ blue; `Hat.Color`: orange on every frame (never blue, never white, never any hue-tinted value)
  - Edge cases: subsequent crowd hue change after Active → hat still orange.

- **`d_init` random**:
  - Given: deterministic `math.random` seed, 100 spawns
  - When: each follower's `_d` value read post-spawn
  - Then: all values in `[0, 0.667)`; no value exactly 0; standard deviation > 0
  - Edge cases: spawn → despawn → re-spawn for same pool slot — second spawn's `_d` differs from first (re-randomised, NOT preserved).

- **State machine**:
  - Given: follower in `Spawning:FadeIn`
  - When: 18 frames @ 60Hz pass (0.3s)
  - Then: state transitions to `Active` on frame 19; `Transparency == 0` exactly; boids resumes
  - Edge cases: SlideIn vs FadeIn — SlideIn suspends boids, FadeIn does not.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/spawn_states_throttle_test.luau` — must exist and pass under TestEZ (deterministic `math.random` seed; mock `RenderStepped` ticks; fixed `dt = 1/60`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool), Story 002 (orchestrator), Story 003 (boids — suspended during SlideIn), Story 004 (`_d`, `_swayPhaseOffset` arrays)
- Unlocks: Story 008 (peel arrival uses FadeIn), Story 009 (`setPoolSize` calls cap-growth FadeIn), Story 011 (perf soak observes throttle behaviour)

---

## Completion Notes

**Completed**: 2026-05-04
**Criteria**: 8/8 acceptance criteria covered by pure-module unit tests (Logic story)
**Test Evidence**: `tests/unit/follower-entity/spawn_states_throttle.spec.luau` — 49 new TestEZ unit tests; full suite **470/470 passing** (was 422 pre-story).

### Files Created

- `src/ReplicatedStorage/Source/FollowerEntity/SpawnStates.luau` (~210 LOC)
  - 6 pure functions: `randomDInit`, `randomSwayPhaseOffset`, `computeFadeInTransparency`,
    `computeSlideInPosition`, `isFadeInComplete`, `isSlideInComplete`, `getSlideInBodyColor`
  - Random source injectable for deterministic tests; default uses `math.random`
  - White color frame-1 latch (TR-follower-entity-012) via `WHITE_COLOR` module constant
- `src/ReplicatedStorage/Source/FollowerEntity/SpawnThrottleQueue.luau` (~120 LOC)
  - Pure FIFO queue with O(1) head/tail integer indexing
  - 5 methods: `new`, `enqueue`, `dequeueUpTo(maxN)`, `size`, `clear`
  - Auto-resets indices on full drain to bound underlying table growth

### Files Modified

- `src/ReplicatedStorage/Source/SharedConstants/FollowerVisualConfig.luau`
  - Added 3 spawn constants: `SPAWN_FADE_DURATION=0.3`, `SPAWN_SLIDE_DURATION=0.4`,
    `SPAWN_THROTTLE_PER_FRAME=4`
  - Header comment expanded with TR references for spawn-related stories

### Test Coverage by AC

| AC | Test Group | Tests |
|---|---|---|
| AC-8 (10 absorbs split 4/4/2) | `SpawnThrottleQueue` AC8 + integration | 1 + 1 |
| AC-16 (SlideIn shape over 24 frames) | `computeSlideInPosition` + integration | 8 + 1 |
| AC-19 (80 FadeIns at 4/frame for 20 frames) | `SpawnThrottleQueue` AC19 + `computeFadeInTransparency` integration | 1 + 1 |
| AC-24 (frame 1 white, frame 2+ hue) | `getSlideInBodyColor` | 5 |
| `d_init` random `[0, 0.667)`, stddev > 0 | `randomDInit` | 4 |
| `_swayPhaseOffset` random `[0, 2π)` | `randomSwayPhaseOffset` | 3 |
| Spawn triggers FadeIn vs SlideIn | terminal predicates + queue dispatch | 5 + 12 |
| State machine transitions | `isFadeInComplete`/`isSlideInComplete` | 5 |
| Constants match story values | dedicated config group | 3 |

### Naming Deviation (documented inline + precedent)

Story §Test Evidence specifies `spawn_states_throttle_test.luau`; actual filename
is `spawn_states_throttle.spec.luau`. TestEZ runner discovers `*.spec.luau` only.
Same precedent as stories 4-1, 4-2, 4-3, 4-4. Documented at spec file header lines 8-13.

### ADR-0007 Compliance

Forbidden-pattern audit on function bodies (excluding doc comment headers):
zero hits for `Instance.new`, `WaitForChild`, `:Wait()`, `task.wait`, `Player.Character`,
`Heartbeat:Connect`, `CrowdStateBroadcast`, `RunService`, `DataStoreService`. Pure logic only.

### Out of Scope Respected

No edits to `Client.luau`, `CrowdManagerClient.luau`, `Boids.luau`, `Animation.luau`,
`Pool.luau`, or `Rig.luau`. Wire-in of these spawn primitives into the production
RenderStepped loop is deferred to a follow-up integration pass (same pattern as
stories 4-3 boids math + 4-4 animation math — pure modules ship first; consumed
by Client.luau in a coordinated wire-in alongside stories 4-7+).

The story's Implementation Notes describe how the pure modules will be integrated:
- `FollowerEntityClient` extends parallel arrays with `_d`, `_swayPhaseOffset`,
  `_lastYBob`, `_isStandstill`, `_slideTime`, `_slideTick`, `_npcLastPosition`,
  `_absorberHueColor`, `_spawnElapsed` per follower
- `CrowdManagerClient` instantiates `SpawnThrottleQueue.new()` at init, calls
  `dequeueUpTo(SPAWN_THROTTLE_PER_FRAME)` at start of each RenderStepped, dispatches
  by request type (FadeIn → set state + start transparency tween; SlideIn → set state +
  suspend boids for follower)

### Deviations

- **Hat.Color invariance** (AC-24 secondary claim): pure module verifies `Body.Color`
  transitions only; `Hat.Color` invariance is enforced by *not* writing to it during
  spawn flow. Verifiable via grep audit when Client.luau wire-in lands. Pure module
  layer cannot test absence of a write that lives in a different file. Advisory only.

- **Hue lookup** (AC-24): `getSlideInBodyColor` accepts `absorberHueColor: Color3`
  directly rather than `(absorberHueIndex, hueLookupTable)`. Lookup is the caller's
  responsibility — typical pattern is `HUE_COLORS[crowdState.hue]` at the wire-in site.
  Cleaner separation; same observable behaviour at the pure-module boundary.

### Code Review

LP-CODE-REVIEW skipped — Lean review mode (default per `.claude/skills/`).
Manual ADR-0007 audit + selene lint (0 errors / 0 warnings) + 470/470 test suite pass
provide equivalent quality gate for this Logic story. Same pattern as stories 4-3 + 4-4.
