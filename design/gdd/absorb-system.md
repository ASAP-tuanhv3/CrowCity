# Absorb System

> **Status**: Designed (2026-04-24 Batch 2 propagation — radius range updated to composed [1.53, 18.04]; ρ_neutral → ρ_design rename; F4 Pillar 5 table recalibrated at ρ=0.075; F3 N_max examples refreshed; AC-17 overlap count 1200 → 3600 per NPC_POOL_SIZE=300; DSN-B-MATH late-round rescue math flagged as advisory — resolution deferred Batch 5.)
> **Author**: user + game-designer + systems-designer + art-director + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine) PRIMARY; 5 (Comeback Always Possible) via count-based radius advantage for small crowds

## Overview

The **Absorb System** is the server-authoritative gameplay core that turns every neutral NPC a player's crowd touches into one more follower. Every 15 Hz server tick (cadence locked by **ADR-0001 Crowd Replication Strategy**), for every active crowd, the system runs a circle-overlap test against every active neutral NPC using the crowd's authoritative `position` and `radius` (both served by Crowd State Manager, radius derived from `radius_from_count`). Every overlap triggers one `CrowdStateServer.updateCount(crowdId, +1)` plus one `Absorbed` signal carrying `(crowdId, npcLastPosition)` — consumed by Follower Entity to spawn the visible slide-in, by VFX Manager to play the absorb snap, and by NPC Spawner to reclaim the NPC instance. This is Pillar 1 made mechanical: the growth loop that players feel as a counter ticking up 47, 48, 49 is nothing but a tight overlap check firing 15 times per second. Small crowds absorb fast because small-count radius is low so each overlap is one NPC; large crowds saturate because the radius grows slower than the cap rises (`sqrt` curve) — Pillar 5 comeback comes from this math, not from a special case. Without this system, the core loop has no growth input at all.

## Player Fantasy

You are a walking stampede in the making, and every white stranger you brush past snaps into your color and falls in behind you. The counter pulses — **1, 2, 3** — then blurs as you plow a packed sidewalk, the crunch of `sfx_absorb_snap` rattling off like a happy machine gun, each pitch a little higher or lower than the last. Your first absorb lights up the dopamine circuit; a street-sweep run down a crowded block turns it into a drum roll. Late in the round the numbers start rolling through **50, 100, 200** and the city is wearing your color. You don't recruit followers. You don't command them. You just walk, and the crowd grows.

## Detailed Design

### Core Rules

The Absorb System runs inside the existing 15 Hz server hit-detection loop established by **ADR-0001**. It does NOT own a separate tick; piggybacks on the same pass that drives Crowd Collision Resolution.

**Tick participation**
- Active only while system state is `Ticking` (see C.2).
- Within each tick, iterate all active crowds × all active neutral NPCs.

**Overlap test (2D, squared distance)**
- `overlaps = (dx² + dz²) <= radius²`
- Y axis ignored — elevated crowds can still absorb ground-level NPCs in city map with varying floor elevations.
- `crowd.position` and `crowd.radius` read from Crowd State Manager record this tick. Both server-authoritative.
- `radius²` precomputed once per crowd per tick; reused for all NPC tests (perf).

**Contention resolution (NPC overlaps multiple crowds)**
- NPC assigned to exactly one crowd: `argmin(distance_2d(crowd.position, npc.position))`.
- Tiebreak on exact-equal distance: lower `crowdId` string wins (lexicographic, deterministic).
- Exactly ONE `Absorbed` event + ONE `updateCount(+1)` fire per NPC per tick.

**Per-overlap action (sequential per NPC)**
1. Fire `Absorbed(crowdId, npc.position)` signal — consumed by Follower Entity, VFX Manager, Audio layer.
2. Call `CrowdStateServer.updateCount(crowdId, +1)`.
3. Call `NPCSpawner.reclaim(npcId)` — removes NPC from active set.

Step 2 BEFORE step 3: count incremented before NPC leaves active pool so state is consistent at `Absorbed` signal dispatch.

**State precondition**
- Skip if `crowd.state == Eliminated`. Process normally for `Active` and `GraceWindow` per Crowd State §C write-access contract.

**Count ceiling**
- 300-follower cap enforced entirely inside `CrowdStateServer.updateCount` via F5 clamp. No additional guard here; excess silently truncated by Crowd State.

**NPC Spawner contract (provisional — to be codified in NPC Spawner GDD)**
- `NPCSpawner.getAllActiveNPCs(): {NeutralNPC}` — authoritative list iterated each tick. Excludes NPCs currently being reclaimed.
- `NPCSpawner.reclaim(npcId)` — marks NPC inactive, returns to spawn pool. After this call, NPC absent from future `getAllActiveNPCs()` results.
- **MUST be synchronous within the tick.** If reclaim is async, Absorb System may double-absorb the same NPC across ticks — NPC Spawner GDD must confirm synchrony OR this GDD must add an "absorbed-this-tick" exclusion set as a corrective guard.

### States and Transitions

Binary system-level state. No per-absorb state machine.

| State | Description |
|---|---|
| `Dormant` | No tick running. No NPC iteration. Between rounds or before first round. |
| `Ticking` | 15 Hz loop active. All C.1 rules apply. |

| Trigger | From | To |
|---|---|---|
| `RoundLifecycle.createAll()` completes | Dormant | Ticking |
| `RoundLifecycle.destroyAll()` fires | Ticking | Dormant |

`createAll` → Ticking implies all Crowd State records exist before the first absorb tick runs. `destroyAll` stopping tick before record destruction ensures final tick does not race against an empty crowd table.

No `Paused` state. Mid-round server load spikes absorbed by Heartbeat-accumulator timing (same as Crowd State Manager).

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|---|---|---|---|
| Crowd State Manager | Read + Write | Read: `crowd.position/radius/state` each tick. Write: `updateCount(crowdId, +1)` per NPC. | Precondition: state ∈ {Active, GraceWindow}. Contract per Crowd State §C. |
| NPC Spawner | Read + Call | `getAllActiveNPCs()` each tick; `reclaim(npcId)` per absorb | Designed 2026-04-22; contract satisfied per `npc-spawner.md` §C. Reclaim synchronous. |
| Follower Entity (client) | Signal | `Absorbed(crowdId, npcLastPosition)` → `spawnFromAbsorb` queues 0.4s slide-in | Signal crosses server → client via reliable RemoteEvent. |
| VFX Manager | Signal | `Absorbed` → `VFXEffect.AbsorbSnap` @ `npcLastPosition` | Designed 2026-04-23; 6/frame per-frame cap owned by VFX Manager §C Rule 9. |
| Audio (undesigned) | Signal | `Absorbed` → `sfx_absorb_snap` w/ pitch random ±0.1 | Polyphony cap owned by Audio GDD; see V/A for batching rule. |
| Round Lifecycle | Control | `createAll()` → Ticking. `destroyAll()` → Dormant. | Absorb System registers listener during init. |

### Design tensions flagged

1. **NPC Spawner reclaim synchrony vs double-absorb**: If `reclaim(npcId)` is async (deferred to next frame), the same NPC can appear in `getAllActiveNPCs()` again and be absorbed twice — phantom +1 + phantom slide-in. NPC Spawner GDD must guarantee synchronous reclaim OR this GDD adds absorbed-this-tick exclusion set. Low-frequency count inflation risk; hard to reproduce.

2. **`crowdId` lexicographic tiebreak bias**: Lower `crowdId` (earlier UserId join) wins every equidistant contention. Systematic advantage over 5-minute match in dense NPC areas. Minor Pillar 5 tension. Mitigation options: random tiebreak (non-deterministic), per-NPC alternating (complex), accept bias (likely negligible at typical density). Flag for playtest observation.

3. **`Absorbed` signal volume saturation**: At 15 Hz w/ large crowd sweeping dense NPC cluster, `Absorbed` fires many times per second. Follower Entity spawn throttle (4/frame) handles visual; Audio layer needs polyphony cap or per-crowd cooldown. V/A proposes 4+/tick batching rule. Belongs in Audio GDD but flagged here at contract boundary.

## Formulas

### F1. overlap_check

`(dx² + dz²) <= radius²` where `radius² = radius_from_count(crowd.count)²`

| Variable | Type | Range | Description |
|---|---|---|---|
| `dx` | float | (-∞, +∞) | `npc.x - crowd.x` |
| `dz` | float | (-∞, +∞) | `npc.z - crowd.z` |
| `distance_sq` | float | [0, +∞) | Squared 2D distance; Y ignored |
| `radius_sq` | float | [2.34, 325.44] | `radius_from_count(count, radiusMultiplier)²`; post-composed per CSM F1; precompute per tick. Baseline-only range [9.30, 144.72] at μ=1.0; MVP (μ≤1.35 Wingspan) max [9.30, 263.74]; full composed [2.34, 325.44] at μ∈[0.5, 1.5]. |

**Output**: bool. Squaring avoids `sqrt` at NPC-test time (radius sqrt paid once per crowd per tick).
**Example (count=10)**: `radius = 4.24`, `radius² = 17.98`. NPC at `dx=3.0, dz=2.5` → `9 + 6.25 = 15.25 <= 17.98` → absorbed.

### F2. contention_winner

`winner = argmin_{c ∈ overlapping_crowds}(distance_2d(c.position, npc.position))`; ties → `argmin(crowdId)` lex.

| Variable | Type | Range | Description |
|---|---|---|---|
| `overlapping_crowds` | set | size [1, 12] | Crowds passing F1 for this NPC |
| `crowdId` | string | `"UserId"` | Lower value wins tie |

**Output**: single `crowdId`. Contention rare. Lex-order tiebreak is deterministic but biased toward earlier joiners (flagged E).
**Example**: NPC at (50,0,50). Crowd A (id="3") dist=3.1, Crowd B (id="1") dist=3.8 → A wins on distance. If both dist=3.5 → B wins on lower id.

### F3. absorbs_per_tick_upper_bound

`N_max = floor(π * radius² * ρ_design)`

| Variable | Type | Range | Description |
|---|---|---|---|
| `radius` | float | [1.53, 18.04] | Post-composed `crowd.radius` from CSM F1 (base × radiusMultiplier). MVP range [3.05, 16.24] (μ=1.0 baseline to μ=1.35 Wingspan at count=300). |
| `ρ_design` | float | (0, +∞) | Neutral NPC density (NPCs/stud²). **Upstream dep — NPC Spawner** (renamed from prior `ρ_neutral` per /review-all-gdds FC-7). |
| `N_max` | int | [0, unbounded] | Physical cap on simultaneous absorbs per tick |

**Output at `ρ_design = 0.075`** (NPC Spawner F2 equilibrium, 300-pool / 4000-studs² arena): count=10 → ~4; count=100 → ~15; count=300 → ~34. Prior calibration at ρ=0.05 superseded.
**Dependency flag**: `ρ_design` owned by NPC Spawner GDD; `N_max` finalized upon NPC Spawner F1 registration of `ARENA_WALKABLE_AREA_SQ`.

### F4. absorb_rate_curve (Pillar 5 comeback math)

`R_absorb = (radius * 2 * v_npc) * ρ_design` — continuous approximation, not per-tick formula.

| Variable | Type | Range | Description |
|---|---|---|---|
| `radius` | float | [1.53, 18.04] | Post-composed `crowd.radius` from CSM F1. MVP range [3.05, 16.24] (μ=1.0 baseline to μ=1.35 Wingspan at count=300). |
| `v_npc` | float | (0, 28] studs/s | NPC walk speed. **Upstream dep — NPC Spawner** (`NPC_WALK_SPEED = 16` locked) |
| `ρ_design` | float | (0, +∞) | Density (NPCs/stud²). Renamed from `ρ_neutral` per /review-all-gdds FC-7. |
| `R_absorb` | float | [0, +∞) | Expected absorbs/sec under uniform density |

**Pillar 5 comeback math (at `v=16, ρ_design=0.075`)** — MVP baseline μ=1.0:

| count | radius | R_absorb /sec | R_absorb / count (% growth/sec) |
|---|---|---|---|
| 1 | 3.05 | **7.32** | **732%** (floor-rescue ceiling) |
| 10 | 4.24 | 10.2 | 102% |
| 100 | 8.0 | 19.2 | 19.2% |
| 300 | 12.03 | 28.9 | 9.6% |

Large crowds absorb MORE per second in absolute terms but FAR FEWER as a fraction of count. Trailing crowd at 10 followers can double in ~1 second from a street sweep; leading crowd at 300 grows ~10%/sec. `sqrt` compression in `radius_from_count` IS the sole Pillar 5 comeback mechanic — no special catch-up rule needed. Prior calibration at ρ=0.05 superseded by NPC Spawner F2 equilibrium.

**⚠️ DSN-B-MATH advisory (late-round density collapse — resolution deferred Batch 5):**
The 7.32/s rescue rate at count=1 assumes ρ_design=0.075 (round-start, full NPC pool of 300). At late round, with 12 players × avg count≈100 absorbed into crowds, the remaining neutral density collapses: `ρ_effective ≈ (300 − 12×100) / 4000 ≈ -0.3` is non-physical, indicating the pool is empty before 12×100 — more realistically ρ_effective settles around 0.011 after NPC Spawner respawn equilibrium kicks in (F2 population_at_rest ~44 active neutrals at peak combat). Scaled rescue rate: `7.32 × (0.011/0.075) ≈ 1.07/s → only ~3 absorbs within 3-second grace window`. Pillar 5 floor-rescue math may FAIL exactly at the late-round scenario it is designed for. **Resolution options (all deferred to Batch 5 design pass):** scale `GRACE_WINDOW_SEC` dynamically by `ρ_effective`; elevate NPC density floor when any crowd hits count=1 (burst respawn to guarantee minimum ρ in rescue window); re-derive Pillar 5 calibration at realistic late-round density. Not resolved in this Batch 2 pass — propagation only surfaces the math.

### Tuning knobs

| Knob | Owner | Value | Notes |
|---|---|---|---|
| `ABSORB_RADIUS_BASE` | Crowd State (via `radius_from_count`) | 2.5 studs | Inherited constant |
| `ABSORB_RADIUS_SCALE` | Crowd State (via `radius_from_count`) | 0.55 | Inherited. Steepens/flattens sqrt curve → direct Pillar 5 lever |
| `NPC_WALK_SPEED` | NPC Spawner | 16 studs/s (registry-locked) | Linear multiplier on R_absorb |
| `ρ_design` | NPC Spawner (F1 derivation: `NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ`) | 0.075/stud² (300/4000) | Scales N_max + R_absorb proportionally; primary pacing lever. Renamed from `ρ_neutral`. |

All Absorb-relevant knobs are inherited — Absorb System owns no tunable values of its own. The mechanic is purely a consequence of Crowd State's `radius_from_count` curve interacting with NPC Spawner's density + speed.

## Edge Cases

### Crowd state
- **If count would exceed 300 on absorb**: `updateCount(+1)` clamp silent-truncates via Crowd State F5. No Absorb-side guard. Excess absorbs fire signals normally (client still sees slide-in VFX + snap audio) but `count` stays at 300.
- **If crowd state == `Eliminated`**: skip absorb entirely. No signal fire, no NPC reclaim. Per Crowd State §C precondition.
- **If crowd state == `GraceWindow` AND count==1 absorbs a neutral**: `updateCount(+1)` raises count to 2. Per Crowd State §C.2, this transitions `GraceWindow → Active`. Absorb System does NOT own this transition — Crowd State Manager owns it. Same-tick caller ordering (Collision → Relic → Absorb → Chest) means Absorb fires after GraceWindow entry check, transition-out happens cleanly.

### Contention / tiebreak
- **Contention exact-distance tie**: `argmin(crowdId)` lex-order fallback. Deterministic. Known earlier-joiner bias (flagged C tension 2).
- **Zero active crowds**: outer iteration no-ops. Early-return optimization before calling `getAllActiveNPCs()`.
- **Zero active NPCs**: inner loop no-ops per crowd. Tick cost = O(crowds), not O(crowds × npcs).

### NPC Spawner contract edges
- **NPC spawned mid-tick inside crowd radius**: absent from tick-start snapshot. Not absorbed this tick. Absorbed on next tick. **Contract requirement**: `getAllActiveNPCs()` must return a point-in-time snapshot, NOT a live reference.
- **Reclaim partially fails** (pool return error, etc.): NPC must still be flagged inactive atomically BEFORE `reclaim` returns. **Contract requirement**: inactive-flag is the gate; pool-return success is orthogonal. If pool full, NPC is discarded (Follower Entity §E silent-drop behavior) but inactive flag still applies. No double-absorb possible if contract upheld.
- **Double-absorb via async reclaim**: see C tension 1.

### Position / geometry
- **Elevated crowd (rooftop) overlapping ground NPC via XZ distance**: INTENTIONAL — Y ignored per C.1. Crowd on rooftop 20 studs up absorbs ground NPC if `dx² + dz² <= radius²`. Documented as confirmed-by-design.
- **Player teleport (>30 studs sudden move)**: `crowd.position` lag-follows via `CROWD_POS_LAG = 0.15` over ~8 ticks (~0.53s). During convergence, absorb uses lagging position — NPCs near OLD position absorb-eligible for the lag window. Accepted: the lag filter is an explicit anti-exploit measure, and 0.53s window is imperceptible. Teleport relics or void-fall trigger this harmless cosmetic edge.

### Timing / concurrency
- **Server lag spike → Heartbeat accumulator runs 2 ticks rapid**: each tick independent. Synchronous reclaim (the contract) means NPCs absorbed in tick N absent from tick N+1 snapshot. No double-absorb risk from rapid recovery. Async reclaim would break this.
- **Server → client signal gap**: `Absorbed` fires server tick N; client receives frame N+k (reliable RemoteEvent). NPC Spawner may have respawned new neutral at same world position mid-gap. Follower slide-in visually overlaps new white NPC for sub-perceptible frames (different hue, 60fps). Known cosmetic artifact; no action.
- **Absorb fires same tick as `RoundLifecycle.destroyAll`**: loop state → Dormant before next tick, but in-flight absorbs complete their sequential 3-step action (signal, updateCount, reclaim) within the current tick. Destruction applies cleanly on next tick's Dormant check.

### Cross-system (provisional contracts)
- **If Relic modifies absorb radius** (e.g., "Magnet radius +50%"): Absorb reads single authoritative `crowd.radius`. Relic System writes modifier into Crowd State record; `radius_from_count` output multiplied before storage. Absorb reads post-multiplied value. **Contract requirement for Relic GDD**: radius relics store modifier in CrowdState, not via ephemeral buffs on the Absorb System. Absorb remains ignorant of relic math.
- **If NPC Spawner empty during round** (all absorbed, none respawned): `getAllActiveNPCs()` returns empty. Absorb System no-ops. NPC Spawner's respawn pacing owns this — Absorb will happily absorb nothing until respawn. Flag for NPC Spawner pacing design.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| ADR-0001 Crowd Replication | Proposed | 15 Hz server tick cadence; server-authoritative hit detection architecture | Architecture foundation |
| Crowd State Manager | In Revision | Read `position/radius/state`; write `updateCount(crowdId, +1)`; `radius_from_count` formula | Read + Write |
| NPC Spawner | Designed 2026-04-22 (Consistency-sync 2026-04-24) | `getAllActiveNPCs()` per-tick snapshot; `reclaim(npcId)` synchronous | Read + call |
| Round Lifecycle | In Revision | `createAll()` → start ticking; `destroyAll()` → stop ticking | Control signals |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Follower Entity (client) | Designed 2026-04-22 (Batch 3 Applied 2026-04-24) | `Absorbed(crowdId, npcLastPosition)` signal | Server → client RemoteEvent |
| VFX Manager | Designed 2026-04-23 (Consistency-sync 2026-04-24) | `Absorbed` signal consumed → `VFXEffect.AbsorbSnap @ npcLastPosition` | Server → client RemoteEvent |
| Audio | Not Started (VS-tier) | `Absorbed` signal → `sfx_absorb_snap` w/ pitch random + batching rules (see V/A) | Server → client RemoteEvent |
| Daily Quest System (Alpha) | Not Started | Absorb count tracked via signal consumption | Read-only analytics |
| Analytics (Alpha, template stubs) | Partial | `Absorbed` events feed analytics pipeline | Read-only analytics |

### Provisional contracts (flagged for cross-check)
- **NPC Spawner `getAllActiveNPCs()` snapshot semantics** — must be point-in-time, not live reference. Mid-tick spawns absent from current iteration.
- **NPC Spawner `reclaim()` synchronous + atomic inactive-flag** — contract requirement; if async, double-absorb risk requires absorbed-this-tick exclusion set in C.1.
- **NPC Spawner defines `NPC_WALK_SPEED` + `ρ_design`** (renamed from `ρ_neutral` per Batch 2 propagation) — Absorb F3/F4 consume these. NPC Spawner GDD designed; values locked in registry (`NPC_WALK_SPEED=16`, `ρ_design=0.075`).
- **Relic System radius modifier storage location** — Relic must write multiplier into Crowd State record; `radius_from_count` output multiplied before storage. Absorb reads post-multiplied `crowd.radius` only.
- **VFX Manager `VFXEffect.AbsorbSnap` handler** — consumer contract defined here.
- **Audio GDD polyphony cap for `sfx_absorb_snap`** — batching rule in V/A §2 (4+ in tick window batches to single sound).

### Bidirectional consistency notes
- **REQUIRES** Crowd State §C write-access contract (`AbsorbSystem | +1 per neutral absorbed`) — already locked.
- **REQUIRES** Follower Entity `spawnFromAbsorb(crowdId, worldPos)` API — already locked in Follower Entity §C.3.
- **CREATES** NPC Spawner contract requirements — tracked for when that GDD is authored.
- **CREATES** Daily Quest / Analytics downstream consumers — `Absorbed` signal is the integration point.

### Engine constraints inherited
- Server-only hit detection per ADR-0001 (no client authority)
- No client spawn throttle at this layer (Follower Entity handles 4/frame)
- `RemoteEvent` reliable delivery (not Unreliable) — absorb events must not drop

### No cross-server dependency
Absorb is entirely within a single Roblox server. No MessagingService.

## Tuning Knobs

Absorb System owns ZERO tunable values of its own. The mechanic is purely a consequence of upstream formulas + constants. Tuning lives in the owners.

### Inherited from upstream (consumed here, NOT duplicated)

| Knob | Owner | Value | Lever |
|---|---|---|---|
| `ABSORB_RADIUS_BASE` | Crowd State (`radius_from_count`) | 2.5 studs | Shifts radius at all counts; affects both absorb + collision |
| `ABSORB_RADIUS_SCALE` | Crowd State (`radius_from_count`) | 0.55 | **Primary Pillar 5 comeback lever** — steepens/flattens sqrt curve |
| `MAX_CROWD_COUNT` | Crowd State | 300 | Cap for silent-truncate on excess absorbs |
| `SERVER_TICK_HZ` | ADR-0001 | 15 Hz | Tick cadence |
| `NPC_WALK_SPEED` | NPC Spawner | 16 studs/s (registry-locked) | Linear multiplier on `R_absorb` |
| `ρ_design` | NPC Spawner (F1 derivation) | 0.075/stud² (300/4000) | Primary pacing lever — scales `N_max` + `R_absorb` proportionally. Renamed from `ρ_neutral` per /review-all-gdds FC-7. |

### Implementation-side only (not design knobs)
- None. Absorb System is stateless across ticks; no internal buffers to size.

### Where this lives (implementation guidance)
- No dedicated `SharedConstants/AbsorbConfig.luau` file. Absorb reads directly from:
  - `SharedConstants/CrowdConfig.luau` (inherited Crowd State values)
  - `SharedConstants/NpcConfig.luau` (when NPC Spawner authored)

**Design note**: If you want to tune absorb feel — walk speed, density, radius curve — you're editing Crowd State or NPC Spawner configs, not this system. This GDD is the integration contract, not a tuning surface.

## Visual/Audio Requirements

### VFX — AbsorbSnap

**Particles (10 flat-quad burst)**
- Spawn at `npcLastPosition` (NOT at crowd center)
- Color: immediate signature-hue on spawn (NOT white → hue transition; the follower mesh already does the single-frame hue flip per art bible §4)
- Lifetime: 0.3s
- Velocity: 0 (radial scatter ≤1 stud)
- Emitter destroyed after burst fires
- Budget: enforced by VFX Manager `ABSORB_PER_FRAME_CAP = 6` globally (vfx-manager.md §C Rule 9 + §Tuning L321) → max 60 particles/frame from AbsorbSnap; excess dispatches suppressed at VFX dispatcher, not here. Scene-wide ceiling 2,000 particles per art bible §8.7. (Updated 2026-04-24 per SCE-NEW-2 — prior "10×4/frame=40" cite was stale; VFX Manager owns the per-frame cap, which is 6 emits × 10 particles = 60.)

**Radial flash disc (additional punctuation)**
- 1 non-particle `Part` (Neon material, signature hue, 0.5-stud radius disc, 0 thickness)
- Tween scale 0 → 1.5 studs → 0 over 0.15s, then destroy
- Does NOT count against particle ceiling (non-particle)
- Provides "impact punctuation" without post-processing (art bible §8.4 — no bloom/glow allowed)

**Trigger timing**: client frame, at slide-in start (NOT server detection tick). Visual snap must coincide with player's view of follower beginning its move. Server-tick trigger would create perceptible gap between NPC disappearance and VFX.

### Audio — sfx_absorb_snap

**Character**: short (<0.2s), percussive with tonal tail.
- Attack: dry click / light pop (impact clarity)
- Tail: brief pitched sine decay ~100ms (signature-hue-agnostic — single sound file serves all 12 hues)
- Pitch range: base pitch ±0.1 semitone randomize per event

**Dedup at high-density ticks** (art-director locked rule):
- 1-3 events within 66ms (one 15 Hz tick window): individual sounds (max 3 simultaneous voices)
- 4+ events within 66ms tick window: batch into single sound w/ pitch +0.15 semitone (brighter) + volume +20% (louder = "cluster absorb" moment)
- Prevents audio stacking artifacts; rewards cluster walks with distinct audio signature

**Spatial audio**: 3D positional, anchored at `npcLastPosition`. Includes local player's own absorbs (camera usually near, minimal impact cost).

### Feedback escalation

**NO screen shake at any count.** Global disruption at 100+ absorbs/min = nauseating on mobile, breaks "intrinsically great" feel.

**Escalation via audio + nameplate only**:
- At 10+ absorbs within 3-second window (streak threshold): batched absorb sound gets +0.3 pitch shift
- Crowd-count nameplate pop animation scales `1.0 → 1.4 → 1.0` (from standard `1.0 → 1.3 → 1.0` per art bible §7)
- Additive to existing system, costs nothing new visually, respects mobile platform

### Art bible compliance anchors

| Bible section | Application |
|---|---|
| §1 Visual Identity ("bold silhouette at 50m") | Particle suppression elsewhere (Follower Entity §V) protects crowd silhouette; AbsorbSnap is the ONE permitted VFX bursting inside a crowd |
| §4 Flat Color / No Gradients | Particles spawn at hue (no white→hue lerp); follower single-frame color flip |
| §7 Animation Feel ("the snap is the moment") | Flash disc + pitch-random snap = snap punctuation. No lingering trail. |
| §8.4 Material Standards | Neon permitted for VFX emitters + flash disc |
| §8.7 VFX Budgets | 10-particle burst within 40-cap; flash disc non-particle; instances destroyed after 0.3s / 0.15s |
| §2 Mood — Pillar 1 Snowball | Audio+nameplate escalation delivers crescendo without mobile-hostile screen shake |
| §8.10 Perf Validation | Tween+destroy pattern; no orphaned instances |

**📌 Asset Spec** — Visual/Audio defined. After art bible approved, run `/asset-spec system:absorb-system` to produce per-asset visual descriptions + generation prompts.

### Tuning knob additions (from V/A)

| Knob | Default | Range | Notes |
|---|---|---|---|
| `ABSORB_SFX_BATCH_THRESHOLD` | 4 events/tick | [2, 8] | Events in 66ms window before batching kicks in |
| `ABSORB_SFX_BATCH_PITCH_BOOST` | +0.15 semitones | [0, 0.5] | Pitch shift on batched sound |
| `ABSORB_SFX_BATCH_VOLUME_BOOST` | +20% | [0, 50] | Volume boost on batched sound |
| `ABSORB_STREAK_THRESHOLD` | 10 absorbs / 3s | [5, 20] | Streak detection window |
| `ABSORB_STREAK_PITCH_SHIFT` | +0.3 semitones | [0.1, 0.6] | Streak-mode pitch boost |

## Acceptance Criteria

All ACs Logic-tier (TestEZ + mocked CrowdStateServer, NPCSpawner, VFXManager, AudioManager, injected clock) except AC-17 (Integration, Micro Profiler).

**AC-1 (F1 overlap, Y ignored)** — GIVEN crowd at `(0,10,0)`, radius=5, NPC at `(3,0,4)`, WHEN overlap test runs, THEN `dx²+dz² = 25 <= 25` TRUE → absorbed. AND NPC at `(4,0,4)` → `32 > 25` FALSE → not absorbed.

**AC-2 (F2 lex tiebreak)** — GIVEN crowds `"alpha"` + `"beta"` both at distance 4.9 from same NPC, WHEN contention resolves, THEN `"alpha"` wins (lex); `"beta"` does not fire Absorbed.

**AC-3 (F2 distance)** — GIVEN `"zulu"` at dist 3.0 + `"alpha"` at dist 4.0, WHEN contention resolves, THEN `"zulu"` wins regardless of lex order.

**AC-4 (Unlimited absorbs per tick)** — GIVEN crowd w/ 8 NPCs all within radius, WHEN 1 tick fires, THEN all 8 fire `Absorbed`; `updateCount(+1)` called 8 times; `NPC.reclaim` called 8 times.

**AC-5 (Piggyback 15 Hz tick)** — GIVEN Crowd State loop at 15 Hz, WHEN AbsorbSystem init, THEN no separate `task.delay` / `RunService.Heartbeat` registered by AbsorbSystem; absorb eval invoked exactly once per Crowd State tick via shared callback. (Verify via scheduler spy.)

**AC-6 (Per-overlap sequence)** — GIVEN 1 NPC in radius of 1 crowd, WHEN 1 tick fires, THEN `Absorbed` signal fires BEFORE `updateCount`; `updateCount(+1)` called BEFORE `NPC.reclaim`. (Ordered-call spy assertion.)

**AC-7 (Skip Eliminated)** — GIVEN crowd state == `Eliminated` AND NPC in radius, WHEN 1 tick fires, THEN `Absorbed` NOT fired; `NPC.reclaim` NOT called.

**AC-8 (Active + GraceWindow allowed)** — GIVEN crowd A in Active + crowd B in GraceWindow, each w/ NPC in radius, WHEN 1 tick fires, THEN both fire `Absorbed` + `reclaim` normally.

**AC-9 (300 ceiling truncate — no AbsorbSide guard)** — GIVEN crowd at count 300 + NPC in radius, WHEN 1 tick fires, THEN AbsorbSystem calls `updateCount(+1)` + `reclaim` UNCONDITIONALLY (no `if count >= 300` branch in AbsorbSystem). Crowd State F5 truncation is sole guard.

**AC-10 (Zero crowds early-return)** — GIVEN 0 registered crowds, WHEN 1 tick fires, THEN inner NPC loop body NEVER entered (verify `NPCSpawner.getSnapshot` call count == 0).

**AC-11 (Zero NPCs no-op)** — GIVEN 1 Active crowd + empty NPC snapshot, WHEN 1 tick fires, THEN no `Absorbed` signals; no errors; tick completes normally.

**AC-12 (NPC snapshot atomicity)** — GIVEN `NPCSpawner.getSnapshot` returns N NPCs at tick start, WHEN AbsorbSystem iterates + calls `reclaim` per absorbed, THEN `reclaim` called ONLY on NPCs in the tick-start snapshot, NEVER on mid-tick-added NPCs. (Frozen-table mock asserts.)

**AC-13 (GraceWindow → Active transition NOT owned here)** — GIVEN crowd in GraceWindow + NPC in radius, WHEN 1 tick fires w/ `Absorbed` + `updateCount(+1)`, THEN AbsorbSystem issues NO state-transition calls. Crowd State owns the `GraceWindow → Active` transition via its own `updateCount` observer.

**AC-14 (V/A signal consumers)** — GIVEN 1 NPC absorbed in tick, WHEN `Absorbed` fires, THEN `VFXEffect.AbsorbSnap` invoked once @ NPC position; `sfx_absorb_snap` plays once.

**AC-15 (V/A audio batching)** — GIVEN 4 NPCs absorbed same tick (within 66ms), WHEN audio batch evaluates, THEN exactly 1 sound plays (NOT 4); sound pitched +0.15 above baseline; volume +20% above baseline.

**AC-16 (V/A streak escalation)** — GIVEN 10 `Absorbed` events fired within 3-second window (injected clock mock), WHEN 10th event fires, THEN audio plays w/ pitch +0.3 above baseline; crowd nameplate scale tween reaches 1.4 peak.

**AC-17 (Perf — Integration tier)** — GIVEN 12 crowds × 300 NPCs each (3,600 overlap tests per tick, per `NPC_POOL_SIZE=300` registry lock), WHEN 60 consecutive ticks execute in live Roblox Server, THEN p99 tick cost via `debug.profilebegin("AbsorbTick")` ≤ 1.5ms (scaled 3× from prior 0.5ms budget proportional to NPC pool 200→300). Evidence: `production/qa/evidence/perf-soak-absorb-[date].txt` (Micro Profiler JSON export, p99 extracted). NOT satisfiable by TestEZ alone.

---

**Test placement**: `tests/unit/absorb/absorb_system.spec.luau` (Logic tier 1-16); `production/qa/evidence/` (Integration tier 17).

**DI requirements**: AbsorbSystem must accept `CrowdStateServer`, `NPCSpawner`, `VFXManager`, `AudioManager`, clock function as injected deps. Otherwise ACs 5, 6, 12, 14, 15, 16 cannot be isolated.

**Guard**: AC-13 explicitly prevents state-transition scope creep. State machine stays in Crowd State Manager.
