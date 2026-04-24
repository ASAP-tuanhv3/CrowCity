# Follower Entity

> **Status**: In Review (major revision 2026-04-22; 2026-04-24 consistency-check sync — `collision_transfer_per_tick = 2` → dynamic `∈ [1, 4]`; 2026-04-24 Batch 3 — Overview tier-2 render reference "4 on a distant one" → "1 billboard impostor per crowd" per Follower LOD Manager sole-owner declaration)
> **Author**: user + game-designer + art-director + technical-artist + gameplay-programmer + systems-designer + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine) primary; 4 (Cosmetic Expression) via skin; 3 (5-Minute Clean Rounds) via no-persistence

## Overview

The **Follower Entity** is the client-side visual representation of every follower in every crowd on the server — the thousands of chunky, cheerful civilians that make the snowball visible. Each entity is a tiny, CFrame-driven rig (4-6 Parts, no Humanoid) flocked via boids behavior toward its crowd's authoritative position. It has no server-side existence beyond its crowd's aggregate count; it exists only as pixels, only on the client, only while on-screen. This split is what makes the game's vision possible — **ADR-0001 (Crowd Replication Strategy)** decoupled authoritative gameplay count from rendered part count so a 300-follower crowd on server might render as 80 entities on the closest client and a single billboard impostor on a distant one, preserving the mob feeling without the rendering cost. Three LOD tiers span close (0-20m, 400-tri full rig), medium (20-40m, 100-tri simplified primitive), and far (40-100m, one billboard impostor per crowd — tier 2 cap owned by Follower LOD Manager §F3); beyond 100m, entities are culled. The entity owns its own procedural walk animation, its hue tint, its hat accessory, and its snap-in-on-absorb and pop-out-on-loss visual moments — every instant the player feels the pack grow or shrink happens here. Without this system, `Crowd State Manager` is a number on a scoreboard; with it, `Crowd State Manager` is an army.

## Player Fantasy

You're a walking parade and every soul you touch wants in. Your pack of cheerful little civilians bobs and jostles behind you in a rolling flood of your color, each one snapped from blank white into your hue the instant you brushed them — a satisfying little tick on the counter, a tiny cheer in the crowd. The hat you picked sits on every single head, so your identity reads from a block away, and the rival cresting that distant rooftop gives himself away by the shimmer of his own color against the skyline. When packs collide it's war by subtraction: followers peel off you one by one, flipping hue as they cross over, and the counter you were worshipping a second ago starts bleeding down. Even stripped to a lone figure, the camera still loves you — there's always one more civilian around the corner, one more flood to build, one more minute to crown yourself.

## Detailed Design

### Core Rules

**Entity identity**
- A "follower" = a Part instance occupying index `i` in crowd's render pool at a moment in time. Identity is ephemeral + index-relative. No stable ID, no GUID. Downstream systems reference `crowdId`, never a Part handle.

**Rig Part layout — 2-Part composite (locked)**

| Part | Geometry | Role |
|---|---|---|
| `Body` | Single `MeshPart`, 400 tri (at LOD 0) — torso + head + merged limbs pre-baked into one mesh | Receives hue `Color3`; primary CFrame-driven Part; walk bob tween target. **`Anchored = true`** (required — prevents gravity fighting per-frame CFrame writes) |
| `Hat` | `MeshPart` from Skin System, single mesh per skin | `WeldConstraint(Part0=Body, Part1=Hat)` parented **under Body** (not under crowd Folder — a WeldConstraint parented outside its constrained Parts is inactive in Roblox); color = skin-defined (not hue-tinted) |

LOD 0: 2 Parts × 80 followers = 160 moving Parts per crowd worst case. Mobile-safe.

**Procedural walk animation**
- Per `RenderStepped` frame, accumulate travel distance `d` from `Body.Position` delta (studs).
- `Body.CFrame = Root_target * CFrame.new(0, abs(sin(d * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP, 0)`
- `WALK_FREQ_HZ = 1.5` (distance-based — faster movement = faster bob step)
- `WALK_BOB_AMP = 0.15` studs
- No limb animation — limbs are pre-baked into the Body MeshPart.
- At standstill (`|d_delta| < 0.01 studs/frame`): bob freezes at current phase.
- **Phase offset on spawn**: each follower initializes `d = math.random() * (1 / WALK_FREQ_HZ)` — a random phase in `[0, 0.667)` studs. Prevents crowd-wide synchronized bob lockstep. Do NOT reset on despawn/respawn; re-randomize each time.
- **`d` is NOT reset on LOD swap**: accumulate continuously across tier transitions. LOD 1/2 ignore `d` but LOD-0 re-entry resumes from current value, preserving each follower's unique phase.

**Hue application**
- On spawn + on hue-flip during Peeling: `Body.Color = HUE_COLORS[hue_index]` using `Color3` (NOT `BrickColor` — faster C++ property write, no string palette lookup).
- Hat color = skin-defined, unchanged by crowd hue.
- **Dirty flag guard**: crowd-wide hue stored as `_currentHue`. Per-follower hue write skipped on steady-state frames. Only writes when `_currentHue ~= newHue` (after hue-flip or skin change).
- **Hue reconciliation timer**: if `_currentHue != CrowdStateClient.get(crowdId).hue` for more than `HUE_RECONCILE_FRAMES = 4` consecutive frames (≈ 66ms, one broadcast interval), force-write hue regardless of dirty flag. Guards against dropped broadcasts carrying hue-change events silently leaving followers the wrong color.
- **`Spawning:SlideIn` white-state**: on the first frame of a SlideIn spawn, `Body.Color = Color3.new(1,1,1)` (neutral white) for exactly 1 frame before being set to crowd hue on frame 2. This delivers the "snapped from blank white into your hue" conversion moment stated in the Player Fantasy. White-state frame is only applied on SlideIn (absorb path), not on FadeIn (cap-growth path).

**Hat attachment**
- At spawn: Skin System provides active hat MeshPart template. Clone → set offset `(0, headOffsetY, 0)` relative to Body → create `WeldConstraint` with `Part0 = Body`, `Part1 = Hat`, parented **under Body** (not crowd Folder — constraint must be parented under one of its Parts to be active in Roblox). Hat cleanup handled via `Janitor` which tracks Body's children.
- Hat stays with follower through `Peeling` (does NOT swap to rival hat) until arrival at rival pool. Hat swaps on the arrival `Despawning → Spawning` cycle, NOT mid-transit.

**Crowd ownership**
- Each follower carries `crowdId: string` attribute on Body. Per-frame reads go through `CrowdStateClient.get(crowdId)`. If `get` returns `nil` (crowd destroyed mid-frame) → entity → `Despawning` immediately.

**Pool architecture**
- 3 global pools (one per LOD tier), shared across all crowds. Owned by `CrowdManagerClient` singleton. Per-crowd `FollowerEntityClient.new(crowdId, janitor)` instances consume from pools.
- Pool grants Part on spawn, reclaims on despawn (CFrame parked off-camera, hidden). No GC on LOD swap.
- Pool prealloc: **460 × LOD 0 Body** + **460 × Hat** slots; 100 × LOD 1 simplified; 60 × LOD 2 billboard. Sizing rationale: 290 baseline demand (1 own-crowd × 80 + 7 rivals × 30) + 120 concurrent Peeling followers at sustained collision (4/tick × 15 Hz × 2s transit) + ~50 Despawning overlap = ~460 required. Old value of 200 was insufficient for full-lobby close-camera gameplay.

**Spawn triggers**

| Trigger | Action |
|---|---|
| Render-cap grows (distance or count change) | Pool grants N parts; each spawned at random offset within crowd `radius`; state → `Spawning:FadeIn` (0.3s) |
| Absorb event | Spawn at neutral NPC last-known position; `Body.Color = Color3.new(1,1,1)` (white, 1 frame); state → `Spawning:SlideIn` (0.4s lerp to crowd center); hue applied on frame 2 of SlideIn |
| Collision peel (rival side) | Pool grants part at rival crowd center; state → `Spawning:FadeIn` (0.3s) — synchronous with peel-in-transit from source crowd |

**Spawn throttle**
- Max 4 spawns per client frame across all crowds. Excess queued to next `RenderStepped`. Prevents burst-absorb stutter (walking through 10 neutral NPCs in 2s → 10 spawns queued, 4/frame).

**Write-access contract**
- Follower Entity is read-only client consumer. It never writes to `CrowdStateClient`, `CrowdStateServer`, or any server state.
- Public mutators exposed to other client systems: `setPoolSize(crowdId, n)` (from LOD Manager), `spawnFromAbsorb(crowdId, worldPos)` (from Absorb), `startPeel(crowdId, rivalCrowdId, n)` (from Crowd Collision Resolution client side).

### States and Transitions

4 per-follower states.

| State | Visible | Animation | Flocking target | LOD active |
|---|---|---|---|---|
| `Spawning:FadeIn` | yes (tween α 0→1, 0.3s) | yes | crowd center | current tier |
| `Spawning:SlideIn` | yes (CFrame lerp from NPC pos → crowd center, 0.4s; boids writes **suspended**, lerp drives Body.CFrame exclusively; Body.Color=white frame 1, then crowd hue) | yes | crowd center (target) | current tier |
| `Active` | yes | yes | crowd center | tier per distance |
| `Peeling` | yes | yes | **RIVAL** crowd center | follows distance LOD (may drop to billboard mid-transit at long distance) |
| `Despawning` | fading (α 1→0, 0.2s) or instant | no | frozen | — |

| From | To | Trigger | Notes |
|---|---|---|---|
| — | `Spawning:FadeIn` | pool cap growth | new pool allocation |
| — | `Spawning:SlideIn` | Absorb event | spawn at NPC pos |
| `Spawning:*` | `Active` | tween completes | hand off to boids |
| `Active` | `Peeling` | collision peel tick selects this index | boids target switches to rival |
| `Active` | `Despawning` | render-cap shrink (this index > new cap) | returned to pool after fade |
| `Active` | `Despawning` | crowd destroyed (`CrowdStateClient.get == nil`) | instant despawn |
| `Peeling` | `Despawning` | peel transit reaches rival crowd center | hue-flip at 50% transit; at arrival despawn from self + rival-side spawn triggers |
| `Despawning` | — | tween completes OR instant | Part returned to pool |

**Hue-flip timing**: time-based, at `elapsed >= T_hue_flip` (F7: `T_hue_flip = T_peel * 0.5`). Implemented as a threshold-crossing with a `_hueFlipApplied: boolean` latch initialized `false` at `startPeel`; set `true` on first frame where `elapsed >= T_hue_flip`. Single-frame `Body.Color` swap. VFX Manager notified at flip point for white-flash effect. Float equality (`elapsed == T_hue_flip`) MUST NOT be used — use `>=` with latch to guarantee exactly one flip regardless of frame timing.

**Peeling immunity from cap-shrink**: entities in `Peeling` state are NOT evicted by `setPoolSize(crowdId, n)`. LOD Manager MUST query `getPeelingCount(crowdId)` and subtract from eviction pool.

### Interactions with Other Systems

**Crowd State Manager (client cache)**
- Follower Entity READS `CrowdStateClient.get(crowdId).{position, count, hue}` every `RenderStepped`.
- `position` = boids leader target. `count` for render-cap comparison (consumed by LOD Manager). `hue` read once on spawn + once on hue-flip.
- If `get` returns `nil` → entity → `Despawning` immediately.

**Follower LOD Manager** (sibling system, not yet designed)
- LOD Manager owns 0.1s distance-check tick + render-cap computation.
- Calls `FollowerEntity.setLOD(crowdId, lodTier)` on tier change.
- Calls `FollowerEntity.setPoolSize(crowdId, n)` on cap change. MUST call `getPeelingCount(crowdId)` first to avoid evicting mid-peel entities.

**Absorb System** (client side, not yet designed)
- Fires event `(crowdId, npcLastPosition)` on absorb.
- Follower Entity: spawn-throttle queue checks; if room, spawn at `npcLastPosition`, state → `Spawning:SlideIn`; else queue for next frame.
- VFX for absorb (burst/sparkle) owned by VFX Manager, not Follower Entity.

**Crowd Collision Resolution (client-visual side, not yet designed)**
- Each 15 Hz broadcast tick: if own-crowd `count` decreased by N AND rival-crowd `count` increased by N → call `FollowerEntity.startPeel(ownCrowdId, rivalCrowdId, n)`.
- Follower Entity picks `n = |ownCount_delta_this_tick|` followers **closest to the rival crowd center** (F6) → state `Peeling`, retargets boids to rival. Selecting followers at the contact face (nearest rival) produces the correct visual of conquest from the collision point; selecting by farthest-from-own-center produced spaghetti routing around the mob. `n` is observed directly from the broadcast-reported count delta, NOT derived from `TRANSFER_RATE_effective` (server authoritative value flows through `CrowdStateClient.CountChanged`; client visualizes the observed delta, not a re-derived formula).
- On arrival: despawn from own pool, spawn on rival pool (`Spawning:FadeIn`).

**Skin System** (Vertical Slice tier)
- `SkinSystem.getHatTemplate(hueIndex): MeshPart` — cloned per entity on spawn.
- `SkinSystem.getBodyColor(hueIndex): Color3` — redundant with crowd hue; skin may override via relic effects (future scope).
- No mid-round skin swap in MVP.

**VFX Manager** (not yet designed)
- `VFXManager.playEffect(VFXEffect.HueShift, entity.Body.CFrame)` at 50% peel transit.
- Absorb burst VFX owned by Absorb System, not Follower Entity.

**Implementation note** (gameplay-programmer): `FollowerEntityClient` lives at `src/ReplicatedStorage/Source/Crowd/FollowerEntityClient.luau` as a per-crowd class. Per-follower state stored as parallel arrays (not per-instance table keys) for Luau table-iter cache locality. Coordinator singleton `CrowdManagerClient` owns `{[string]: FollowerEntityClient.ClassType}` map and drives all updates from one `RenderStepped` connection.

### Design tensions flagged

1. **Peeling immunity from pool-shrink race** — LOD Manager must NOT evict mid-peel entities. Solved via `getPeelingCount(crowdId)` query. Contract requirement on Follower LOD Manager GDD.
2. **Absorb spawn burst stutter** — 10 simultaneous absorbs would attempt 10 spawns same frame. Solved via 4/frame spawn throttle queue.
3. **Client peel timing desync vs authoritative 15 Hz drip** — peel visual triggered by broadcast delta; 15 Hz broadcast can miss ticks. Cosmetic-only desync acceptable per ADR-0001. Visual tolerance spec defers to Crowd Replication Strategy GDD when authored.

## Formulas

### F1. boids_separation_force

```
F_sep = Σ (P_i - P_j) / max(‖P_i - P_j‖², ε)
        for all j where ‖P_i - P_j‖ < SEPARATION_RADIUS
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `P_i` | Vector3 | world | Position of this follower |
| `P_j` | Vector3 | world | Neighbor's position |
| `SEPARATION_RADIUS` | float | (0, `NEIGHBOR_RADIUS`] studs | Repel radius — default **2.5** |
| `ε` | float | 0.001 | Guard against divide-by-zero on overlap |

**Output range:** unbounded magnitude (normalized downstream in F4). Zero if no neighbors within SEPARATION_RADIUS.
**Example:** P_i=(0,0,0), neighbor at (1,0,0), SEPARATION_RADIUS=3 → `F_sep = (-1, 0, 0)`.

### F2. boids_cohesion_force

```
if N == 0 then F_coh = Vector3.zero  -- guard: no division by zero
else
    centroid = (1/N) Σ P_j  for j within NEIGHBOR_RADIUS
    F_coh = centroid - P_i
end
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `N` | int | [0, ~80] | Neighbor count within cohesion radius |
| `NEIGHBOR_RADIUS` | float | (0, 12] studs | Cohesion + awareness radius — default **6.0** |
| `F_coh` | Vector3 | bounded by NEIGHBOR_RADIUS | Pull toward local centroid |

**N=0 guard (required):** when isolated (no neighbors within NEIGHBOR_RADIUS), `N=0` → skip `(1/N)` computation entirely and return `Vector3.zero`. Luau evaluates `1/0` as `math.huge`, and `math.huge * empty_sum = nan`. Returning zero when N=0 also means F4 will skip this component (zero-vector guard in F4 applies).
**Output range:** magnitude ≤ NEIGHBOR_RADIUS. Zero when isolated.
**Example:** P_i=(0,0,0), neighbors at (4,0,0) + (2,0,0) → centroid=(3,0,0), F_coh=(3,0,0).

### F3. boids_follow_leader_force

```
F_lead = CrowdStateClient.get(crowdId).position - P_i
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `crowdId` | string | — | Follower's owning crowd |
| `P_i` | Vector3 | world | Follower's position |

**Output range:** magnitude = distance to leader. Zero when at leader position.
**Nil-guard:** if `CrowdStateClient.get(crowdId)` returns `nil`, entity → `Despawning` and F3 not evaluated.
**Y-axis behavior:** F_lead includes the Y component of the leader position. Followers will track the leader's altitude (ramps, jumps). No Y-clamping is specified — this is intentional. On maps with significant vertical variation, follower Y tracking may cause floating/sinking mid-ramp; this is acceptable for MVP. Flag for revisit if arena has >3 stud elevation changes.
**Example:** crowd at (10,0,0), follower at (0,0,0) → F_lead = (10,0,0).

### F4. boids_final_velocity

```
-- Zero-vector guard (required): only add a component if its force is non-zero.
-- normalize(zero_vector) in Luau produces NaN if implemented as v/v.Magnitude.
V_raw = Vector3.zero
if F_sep.Magnitude > 0 then V_raw += F_sep.Unit * SEPARATION_WEIGHT end
if F_coh.Magnitude > 0 then V_raw += F_coh.Unit * COHESION_WEIGHT end
if F_lead.Magnitude > 0 then V_raw += F_lead.Unit * FOLLOW_LEADER_WEIGHT end

-- Zero V_raw guard: if all forces cancel, hold position this frame.
if V_raw.Magnitude == 0 then
    P_new = P_i  -- no movement
else
    V_final = clamp(V_raw.Magnitude, 0, MAX_SPEED) * V_raw.Unit
    P_new = P_i + V_final * dt
end
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `SEPARATION_WEIGHT` | float | [0.0, 5.0] | Default **1.5** |
| `COHESION_WEIGHT` | float | [0.0, 5.0] | Default **1.0** |
| `FOLLOW_LEADER_WEIGHT` | float | [0.0, 10.0] | Default **3.0** |
| `MAX_SPEED` | float | [1.0, 30.0] studs/s | Default **16** — must be ≥ PlayerWalkSpeed |
| `dt` | float | — | `RenderStepped` delta time |

**Output range:** magnitude ∈ [0, MAX_SPEED]. Direction is weighted blend. Zero when all forces absent.
**Example:** F_sep=(-1,0,0), F_coh=(1,0,0), F_lead=(0.6,0,0.8), weights default → V_raw = (-1,0,0)×1.5 + (1,0,0)×1.0 + (0.6,0,0.8).Unit×3.0 = (-1.5+1.0+1.8, 0, 2.4) = (1.3, 0, 2.4); ‖V_raw‖ = 2.73 ≤ 16 → V_final = 2.73 × (1.3,0,2.4)/2.73 = (1.3, 0, 2.4). `P_new = P_i + (1.3, 0, 2.4) * dt`.

### F5. lod_tier_assignment

```
tier = 0     if d_camera ≤ 20
tier = 1     if 20 < d_camera ≤ 40
tier = 2     if 40 < d_camera ≤ 100
tier = CULL  if d_camera > 100
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `d_camera` | float | [0, ∞) studs | Camera → crowd center distance (refreshed every 0.1s tick) |
| `tier` | enum | {0, 1, 2, CULL} | Output LOD tier |

**Render cap lookup** (LOD Manager consumes):

| Tier | Own crowd | Rival crowd |
|---|---|---|
| 0 | 80 | 30 |
| 1 | 15 | 15 |
| 2 | 4 | 4 |
| CULL | 0 | 0 |

**Example:** d=35 → tier 1 → 15 rendered. d=101 → CULL → 0 rendered.

### F6. peel_N_selection (closest to rival)

```
rival_center = CrowdStateClient.get(rivalCrowdId).position  -- cached at startPeel time
dist_i = ‖P_i - rival_center‖  for all i in Active state
sort Active ascending by dist_i    -- closest to rival first (contact face)
selected = first min(N, Active_count) indices
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `rival_center` | Vector3 | world | `CrowdStateClient.get(rivalCrowdId).position` at `startPeel` invocation — cached for peel duration |
| `N` | int | [1, render_cap] | Observed `|ownCount_delta|` from broadcast tick. At defaults ranges [1, 4] per registry `collision_transfer_per_tick` formula with dynamic `TRANSFER_RATE_effective`. Client does not re-derive; reads server-reported delta directly. Clamped: `N_eff = min(N, Active_count)`. |

**Selection rationale:** closest-to-rival selects followers on the contact face of the collision — the side physically in contact with the rival mob. They peel toward a crowd they were already approaching. Previous "farthest from own center" sent perimeter followers from all directions, including behind the player, producing visible spaghetti routing around the mob.
**Output range:** exactly `min(N, Active_count)` indices. Zero if Active pool is empty.
**Implementation note:** at N≤4 and pool ≤80, full sort acceptable (~80 comparisons). Partial sort (nth_element) preferred if N scales.
**Example:** rival_center=(50,0,0), Active followers at positions (40,0,0), (38,0,0), (10,0,0), (5,0,0). N=2, distances to rival=[10, 12, 40, 45]. Sort ascending → selected: distances 10 and 12 (followers at (40,0,0) and (38,0,0) — closest to rival, on the contact face).

### F7. peel_transit_duration

```
T_peel = min(d_peel / PEEL_SPEED, PEEL_MAX_DURATION)
T_hue_flip = T_peel * 0.5

-- d_peel=0 guard:
if T_peel == 0 then
    -- instant arrival: apply hue flip + arrival events immediately this frame
    -- no transit; skip to Despawning → rival Spawning
end
```

**Rival-nil abort path (required):** if `CrowdStateClient.get(rivalCrowdId) == nil` at any point during Peeling transit, abort peel: follower reverses boids target back to own-crowd center, transitions to `Active` on arrival. This handles rival elimination mid-peel without zombie pool slots. Own-crowd nil (own crowd eliminated while returning) → `Despawning` immediately.

| Variable | Type | Range | Description |
|---|---|---|---|
| `d_peel` | float | [0, ~500] studs | Distance from follower's start position to rival crowd center at `startPeel` time |
| `PEEL_SPEED` | float | [8.0, 30.0] studs/s | Default **20** — feels urgent, faster than walk |
| `PEEL_MAX_DURATION` | float | [1.0, 5.0] s | Default **3.0** — caps far-distance peels |
| `rival_center_cached` | Vector3 | world | Rival center captured at `startPeel` call; used as initial boids target. Updated each frame from `CrowdStateClient.get(rivalCrowdId)` if non-nil. |

**Output range:** [0, PEEL_MAX_DURATION]. Hue flip at 50% transit time.
**Example (normal):** d_peel=40, PEEL_SPEED=20 → T_peel = 2.0s, flip at t=1.0s.
**Example (capped):** d_peel=120 → T_peel = min(6.0, 3.0) = 3.0s. Follower travels 60 studs then CFrame-snaps to rival center at arrival. Acceptable at LOD 2 distance.

### F8. walk_bob_offset (locked)

```
y_bob = abs(sin(d * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP
Body.CFrame = Root_target * CFrame.new(micro_sway_x, y_bob, 0)
-- micro_sway_x: see F9 below; 0 when moving (non-standstill)
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `d` | float | [0, ∞) studs | Cumulative travel distance; initialized to random phase offset `d_init ∈ [0, 1/WALK_FREQ_HZ)` on spawn; NOT reset on LOD swap |
| `d_init` | float | [0, 0.667) | Random per-follower phase offset at spawn — desynchronizes crowd bob |
| `WALK_FREQ_HZ` | float | locked **1.5** | Bob cycles per stud traveled — scales with movement speed |
| `WALK_BOB_AMP` | float | locked **0.15** studs | Peak vertical displacement |

**Output range:** [0, 0.15] studs. `abs(sin)` ensures upward-only bounce — never dips below Root_target.
**Standstill guard:** skip `d` accumulation if `|d_delta| < 0.01 studs/frame`. Bob phase frozen at last non-standstill value.
**LOD continuity:** `d` continues accumulating across LOD swaps. LOD 1/2 geometry does not use F8. LOD 0 re-entry picks up at current `d`, preserving per-follower phase.
**Example:** d=0.167 stud (quarter-period) → y_bob = sin(π/2) * 0.15 = 0.15 (peak).

### F9. micro_sway_offset (standstill only)

```
-- Applied only when |d_delta| < STANDSTILL_THRESHOLD (standstill guard active)
-- LOD 0 only; zero at LOD 1+
t = os.clock()  -- wall time, seconds
micro_sway_x = sin(t * 2π * MICRO_SWAY_FREQ_HZ + sway_phase_offset) * MICRO_SWAY_AMP
Body.CFrame = Root_target * CFrame.new(micro_sway_x, last_y_bob, 0)
-- sway_phase_offset initialized to math.random() * 2π at spawn (per-follower)
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `t` | float | [0, ∞) s | Wall clock time (`os.clock()`) — time-based, NOT distance-based |
| `sway_phase_offset` | float | [0, 2π) | Per-follower random phase initialized at spawn; desynchronizes idle sway |
| `MICRO_SWAY_AMP` | float | [0, 0.10] studs | Horizontal sway amplitude — default **0.03** |
| `MICRO_SWAY_FREQ_HZ` | float | [0.1, 2.0] | Sway cycles per second — default **0.4** |
| `last_y_bob` | float | [0, 0.15] studs | F8 bob value frozen at standstill entry |

**Output range:** [-MICRO_SWAY_AMP, +MICRO_SWAY_AMP] on local X axis (world X approximation acceptable at this amplitude).
**Compositing with F8:** F8 provides Y offset; F9 provides X offset. Combined: `CFrame.new(micro_sway_x, y_bob, 0)`. During movement, `micro_sway_x = 0` and F8 applies normally. During standstill, `d` stops accumulating (bob frozen), F9 applies with `last_y_bob`.
**Phase offset requirement:** `sway_phase_offset` MUST be per-follower random. All-zero phase offsets produce synchronized lateral oscillation (metronome effect), defeating the purpose.
**Example:** t=1.0s, sway_phase_offset=π/3, MICRO_SWAY_FREQ_HZ=0.4, MICRO_SWAY_AMP=0.03 → micro_sway_x = sin(2π × 0.4 × 1.0 + π/3) × 0.03 ≈ sin(3.56) × 0.03 ≈ -0.011 studs.

### Cross-system constraints

- `SEPARATION_RADIUS < NEIGHBOR_RADIUS` — assert at startup or separation force never finds neighbors to flee.
- `collision_transfer_per_tick` formula (registry-sourced; dynamic `TRANSFER_RATE_effective`) drives F6 N. N is observed directly from broadcast count delta; client does not re-derive. If `TRANSFER_RATE_BASE/SCALE/MAX` are revised in registry, server drip rate changes but client F6 still reads the actual delta.
- `MAX_SPEED` must be ≥ player walk speed (Roblox default ~16 studs/s), otherwise followers fall behind.
- Formula knobs (NEIGHBOR_RADIUS, SEPARATION_* weights, MAX_SPEED, PEEL_*) are internal to this GDD — NOT registered yet. Flag for registry if Follower LOD Manager or Absorb GDDs reference them by name.
- **F2 N=0 guard is mandatory** — implementation must check `N == 0` before `(1/N)`. Zero cohesion returns `Vector3.zero`.
- **F4 zero-vector guard is mandatory** — each force component must check `.Magnitude > 0` before `.Unit`. V_raw zero → `P_new = P_i` (hold position).
- **`d` accumulation never resets on LOD swap** — `d` is per-follower state that persists across tier transitions. Only resets on follower despawn (pool reclaim), re-initialized to random phase offset on next spawn claim.
- **`_hueFlipApplied` latch is mandatory** — hue-flip must use `>=` threshold crossing with boolean latch, never float equality.

## Edge Cases

### Crowd lifecycle
- **If `CrowdStateClient.get(crowdId)` returns `nil` during per-frame read**: entity → `Despawning` immediately; Part returned to pool on fade completion.
- **If source crowd destroyed mid-peel** (Eliminated + `destroyAll` during Peeling transit): follower continues transit using current `rival_center` from `CrowdStateClient.get(rivalCrowdId)` (updated each frame). Normal `Despawning → rival Spawning` cycle on arrival. No source-crowd read during transit.
- **If rival crowd destroyed mid-peel** (`CrowdStateClient.get(rivalCrowdId) == nil` during Peeling transit): abort peel — follower switches boids target back to own-crowd center, transitions to `Active` on arrival (no despawn, no rival spawn). If own crowd is also nil at abort time: → `Despawning` immediately.
- **If hue on source crowd changes mid-peel** (e.g., relic effect): ignore. Body retains pre-peel hue; hat retains pre-peel player identity; destination hue applied on arrival only.

### Spawn queue
- **If absorb burst (10 NPCs in 2s)**: throttle to 4/frame; queue remainder. Prevents frame-spike from 10 simultaneous Part instantiations.
- **If spawn queued while pool slot `Despawning`**: queued request waits for fade completion + Part pool return. No concurrent transparency tweens on same Part. New spawn claims slot after return.
- **If pool prealloc exhausted** (`pool.grant()` returns `nil`): spawn silently dropped; crowd still renders with fewer followers. Log warning once per session. Pool default is now 460 — sized for full-lobby worst-case. If warning fires in production, raise `POOL_PREALLOC_LOD0_BODY` toward the 640 maximum (8 crowds × 80 own-cap — absolute ceiling).

### Peel
- **If peel-in-flight during cap-shrink**: `Peeling` entities are immune from eviction. LOD Manager MUST call `getPeelingCount(crowdId)` and subtract before `setPoolSize`.
- **If Active pool < N during peel** (F6 degenerate): return `min(N, Active_count)`. Fewer followers peel; gameplay continues.
- **If peel distance capped** (`d_peel > PEEL_SPEED × PEEL_MAX_DURATION`): `T_peel = 3.0s`; follower travels partial distance then teleports to rival center at arrival. Acceptable at LOD 2 distance (visible only as billboard).
- **If concurrent peel from 2 rivals same tick** (B and C both peel from A): each `startPeel` runs F6 independently on current `Active` pool. Second call filters out already-`Peeling` followers from first. Combined effect: 4 peels from crowd of 80 — negligible.

### Animation / visual
- **If follower at standstill** (`|d_delta| < 0.01 studs/frame`): skip `d` accumulation, bob freezes at current phase. Prevents idle-physics micro-jitter bob.
- **If LOD swap mid-bob cycle**: `d` is NOT reset on LOD swap. LOD 1/2 geometry ignores bob formula; LOD 0 resumes from current `d` value on re-entry. Each follower's unique phase offset (initialized at spawn) is preserved across tier transitions, preventing synchronized-bob lockstep after LOD demote.
- **If player teleport (>30 studs in 1 tick)**: followers skip boids interpolation that frame; CFrame directly to `crowd_center + offset`. Rubber-band snap matches player-character motion. `TELEPORT_THRESHOLD = 30` studs.
- **If render-cap restores from 0 (cull) to N at 95m camera return**: spawn throttle applies normally. At 4/frame, 15 followers populate over ~67ms (4 frames @60 FPS). Acceptable; no throttle bypass.

### Skin / assets
- **If `SkinSystem.getHatTemplate(skin_id)` returns `nil`**: spawn Body-only rig (no hat). Log warning with `crowdId + skin_id` for QA. No error, no stall. Visually distinct but functionally correct.

### Numerical / overlap
- **If two followers share exact position** (F1 separation divide-by-zero): `EPSILON = 0.001` guard in denominator prevents crash. Force magnitude remains bounded.
- **If F6 outermost selection w/ Active pool = 0**: no-op. Peel drops to `min(N, 0) = 0`. No followers transfer that tick.
- **If hue-flip mid-frame triggers 80 `Body.Color` writes**: no GC pressure — scalar property writes, no table alloc. Dirty-flag already gates steady-state. Peel-arrival hue-flips are unavoidable but cheap.

### Network timing
- **If client peel visual desyncs from server 15 Hz drip** (lag spike, dropped broadcast): cosmetic-only desync, acceptable per ADR-0001. Visual tolerance spec defers to Crowd Replication Strategy GDD when authored.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| ADR-0001 Crowd Replication Strategy | Proposed | Entire client-side follower architecture: client-only, 15 Hz broadcast, render caps, 3-tier LOD, boids, non-Humanoid rig | Architecture foundation |
| Crowd State Manager | Designed (pending review) | `CrowdStateClient.get(crowdId).{position, count, hue}` — per-frame reads | Read-only cache consumer |
| Art Bible §5 + §8 | Approved | LOD tier geometry (400/100/2 tri), BrickColor + Plastic material, no Humanoid, no SurfaceAppearance, custom rig not R15 | Visual specs |
| AssetId Registry | Convention (art bible §8.9) | Body MeshPart AssetIds, Hat AssetIds, Billboard sprite AssetIds | Asset references |
| `Packages.janitor` | Wally dep | `Janitor` instance per crowd for cleanup on `destroyAll` | Lifecycle |
| `ReplicatedStorage/Source/Signal.luau` | Template | Signal instance type (consumed from Absorb + Collision events) | Type reference |
| `ReplicatedStorage/Source/ComponentCreator.luau` | Template | NOT consumed — CrowdManagerClient uses direct instance management, not CollectionService tag-driven pattern (pooling makes ComponentCreator inappropriate) | Anti-pattern flag |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Follower LOD Manager (sibling) | Not Started | `setLOD(crowdId, tier)`, `setPoolSize(crowdId, n)`, `getPeelingCount(crowdId): number` | Called by LOD Manager |
| Absorb System | Not Started | `spawnFromAbsorb(crowdId, worldPos: Vector3)` | Called by Absorb on event |
| Crowd Collision Resolution (client) | Not Started | `startPeel(ownCrowdId, rivalCrowdId, n: number)` | Called on collision drip tick |
| Skin System | Not Started (VS) | Follower Entity CONSUMES `SkinSystem.getHatTemplate(skin_id)` + `getBodyColor(hueIndex)` at spawn | Read-only |
| VFX Manager | Not Started | Follower Entity CALLS `VFXManager.playEffect(VFXEffect.HueShift, cframe)` at 50% peel transit | Outbound notification |
| CrowdManagerClient (sibling implementation singleton) | Not Started | Constructs + owns `FollowerEntityClient.new(crowdId, janitor)` instances; drives all per-frame updates from single `RenderStepped` connection | Orchestrator |

### Provisional assumptions (flagged for cross-check)
- `CrowdStateClient.get(crowdId)` signature + return type — assumed from Crowd State Manager §C.3. Must be implemented when Crowd State Manager's client cache is built.
- `VFXManager.playEffect(effect, cframe)` signature — placeholder; VFX Manager GDD not yet authored.
- `SkinSystem.getHatTemplate` + `.getBodyColor` signatures — placeholders; Skin System GDD is VS-tier, not yet authored. **MVP fallback**: default skin hat per hue index (hardcoded in `SharedConstants/DefaultSkin.luau`).

### Bidirectional consistency notes
- **REQUIRES** `CrowdStateServer.CountChanged` signal (for client-side cache push that drives boids leader updates). Already flagged in Round Lifecycle §F as needing Crowd State §F patch.
- **REQUIRES** Follower LOD Manager GDD to honor `getPeelingCount` contract before any `setPoolSize` call. Blocking requirement — race condition otherwise.
- **REQUIRES** Crowd Collision Resolution GDD (not yet authored) to call `startPeel` at 15 Hz tick when collision drip fires. Contract defined here.

### Engine constraints inherited
- No Humanoid (`forbidden_pattern` per `architecture.yaml`)
- No custom shaders (Roblox doesn't expose)
- No GPU instancing (Roblox doesn't expose) — Part count IS the cost driver per technical-artist
- Max follower visual budget: GraphicsTexture <512MB per art bible §8.10

### No cross-server dependency
Follower Entity is client-side only. Zero server replication beyond consuming `CrowdStateClient` cache populated by `UnreliableRemoteEvent`.

## Tuning Knobs

### Boids knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low |
|---|---|---|---|---|---|
| `NEIGHBOR_RADIUS` | 6.0 studs | [3.0, 12.0] | Awareness + cohesion radius | Heavier per-frame; flock feels slurry | Followers ignore each other, scatter |
| `SEPARATION_RADIUS` | 2.5 studs | [1.0, `NEIGHBOR_RADIUS`) | Inter-follower push | Crowd sparse, holes in pack | Overlap, visual clipping |
| `SEPARATION_WEIGHT` | 1.5 | [0.5, 4.0] | Anti-clump strength | Crowd sprawls wide | Followers pile on each other |
| `COHESION_WEIGHT` | 1.0 | [0.3, 3.0] | Grouping pull | Tight ball, fights separation | Loose flock, feels disorganized |
| `FOLLOW_LEADER_WEIGHT` | 3.0 | [1.0, 8.0] | Leader-tracking force (dominant) | Immediate snap, no inertia | Crowd lags behind player visibly |
| `MAX_SPEED` | 16 studs/s | [8.0, 24.0] — must ≥ PlayerWalkSpeed | Max follower travel speed | Followers clip through obstacles | Followers fall behind player |

### Animation knobs (mostly locked)

| Knob | Default | Safe range | Affects | Notes |
|---|---|---|---|---|
| `WALK_FREQ_HZ` | **1.5** (locked) | [1.0, 2.5] | Bob cadence per stud traveled | Art bible §5 feel lock |
| `WALK_BOB_AMP` | **0.15** studs (locked) | [0.05, 0.30] | Peak vertical bob | Art bible §5 feel lock |
| `STANDSTILL_THRESHOLD` | 0.01 studs/frame | [0.001, 0.1] | Min delta to advance bob phase | Too low = jitter bob at idle; too high = bob freezes during slow walk |

### Peel knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low |
|---|---|---|---|---|---|
| `PEEL_SPEED` | 20 studs/s | [8.0, 40.0] | Peel transit speed | Reads as teleport | Transit drags past next drip tick |
| `PEEL_MAX_DURATION` | 3.0s | [1.5, 5.0] | Hard cap on transit time | Cross-map peels lag rounds | Short peels teleport visually |
| `TELEPORT_THRESHOLD` | 30 studs | [10, 100] | Crowd center jump → skip boids interp | Rubber-band on all movement | Flock ignores legitimate teleports |

### Spawn / Despawn tween

| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `SPAWN_FADE_DURATION` | 0.3s | [0.1, 1.0] | Cap-growth + rival-peel-arrival fade-in |
| `SPAWN_SLIDE_DURATION` | 0.4s | [0.2, 1.0] | Absorb slide-from-NPC-position |
| `DESPAWN_FADE_DURATION` | 0.2s | [0.1, 0.5] | Cap-shrink fade-out |
| `SPAWN_THROTTLE_PER_FRAME` | 4 | [1, 10] | Max spawns per `RenderStepped` across all crowds |

### Pool knobs

| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `POOL_PREALLOC_LOD0_BODY` | **460** | [200, 640] | Body MeshPart pool size — 640 is the absolute ceiling (8 crowds × 80 own-cap) |
| `POOL_PREALLOC_LOD0_HAT` | **460** | [200, 640] | Hat MeshPart pool size — matches Body count 1:1 |
| `POOL_PREALLOC_LOD1` | 100 | [50, 200] | Simplified LOD 1 Part pool |
| `POOL_PREALLOC_LOD2_BILLBOARD` | 60 | [30, 120] | BillboardGui pool |

### Numerical guard

| Constant | Value | Purpose |
|---|---|---|
| `EPSILON` | 0.001 | F1 divide-by-zero guard on overlapping followers |
| `HUE_RECONCILE_FRAMES` | 4 | Frames of hue dirty-flag mismatch before force-reconcile (≈66ms, one broadcast interval) |

### Locked constants (NOT tuning knobs — changing requires ADR or Pillar amendment)
- LOD distances 20/40/100m — locked by art bible §5
- LOD tri budgets 400/100/2 — locked by art bible §8
- Render caps 80/30/15/4 — locked by ADR-0001
- `WALK_FREQ_HZ = 1.5`, `WALK_BOB_AMP = 0.15` — art bible §5
- `MAX_CROWD_COUNT = 300` — inherited from Crowd State Manager
- `collision_transfer_per_tick ∈ [1, 4]` — dynamic per CSM §F3 (`TRANSFER_RATE_effective / SERVER_TICK_HZ`; depends on `count_delta` between attacker/defender). Inherited from Crowd State Manager. Prior static "= 2" value superseded 2026-04-22 when CSM F3 became dynamic.

### Inherited from upstream GDDs (don't duplicate)
- `MAX_CROWD_COUNT`, `HUE_PALETTE_SIZE`, `TRANSFER_RATE_BASE/SCALE/MAX`, `SERVER_TICK_HZ` — owned by Crowd State Manager / ADR-0001

### Where knobs live (implementation guidance)
- All boids knobs → `SharedConstants/FollowerBoidsConfig.luau`
- Peel + teleport + tween → `SharedConstants/FollowerVisualConfig.luau`
- Pool preallocs → `SharedConstants/FollowerPoolConfig.luau`

## Visual/Audio Requirements

### VFX triggers

- `Spawning:FadeIn` (cap growth / rival peel arrival) → **NONE.** Pure alpha tween 0→1 over 0.3s. No emitter. Any particle at this volume (up to 80 spawns/s burst) would blow art bible §8.7 particle ceiling.
- `Spawning:SlideIn` arrival (absorb) → **Absorb snap burst.** Single `ParticleEmitter` at NPC's last world position: 10 flat-quad particles, signature-hue color, 0.3s lifetime, 0 velocity (radial scatter ≤1 stud). Emitter destroyed immediately after burst. **Owned entirely by Absorb System + VFX Manager** — VFX Manager subscribes directly to the `Absorbed(crowdId, npcLastPosition)` signal and plays `VFXEffect.AbsorbSnap` at `npcLastPosition` on signal receipt (client frame). Follower Entity does NOT call VFX Manager for absorb; the two consumers (Follower Entity's `spawnFromAbsorb` + VFX Manager's effect) fire independently from the same Absorbed signal.
- `Peeling` hue-flip at 50% transit → **White-flash shell.** Single-frame `Body.Color = Color3.new(1,1,1)` followed by target rival hue on next frame (already spec'd in §C.2). **No particle required.** `VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame)` notification dispatched. VFX Manager MAY add a 0.1s Neon-material pulse ring (1-Part BillboardGui, 32×32px, rival hue, instant scale-up then alpha-fade) if particle budget permits. Particle-free fallback is acceptable.
- `Despawning:FadeOut` (cap shrink, 0.2s) → **NONE.** Pure alpha tween 1→0.
- `Despawning` cull eviction at 100m → **NONE.** Entity is billboard impostor at that range; any particle is sub-pixel. Instant cull or alpha fade per state machine.

**Budget check**: worst case = 4 absorbs/frame × 10 particles = 40 particles/frame spike, within art bible §8.7 burst cap (40/event). Scene steady-state well under 2,000 ceiling.

### Audio triggers

De-duplication is mandatory at 80+ followers per crowd.

- `Spawning:SlideIn` arrival (absorb) → **`sfx_absorb_snap`** (1 SFX per absorb EVENT, not per follower). Played once by Absorb System at event origin. Pitch randomize ±0.25 (`PlaybackSpeed` range [0.75, 1.25] ≈ ±4 semitones) — minimum required to defeat machine-gun repetition on burst absorb; ±0.1 (prior value) was insufficient (~1.7 semitones). Absorb audio fires on reliable `GameplayEvent` arrival, NOT on 15 Hz broadcast tick — the de-dupe tick-map does not apply to this path. Absorb System is responsible for its own burst-absorb de-dupe if needed.
- Peel hue-flip at 50% transit → **`sfx_crowd_peel_flip`** (1 SFX per peel BATCH tick). `startPeel(n)` fires once per 15 Hz tick; audio plays once for that tick regardless of n. Subtle, non-punishing tone (short staccato blip, not a loss sting — Pillar 5).
- `Spawning:FadeIn` → **NONE** from Follower Entity. Crowd-murmur ambient layer (scales with crowd count, delivers the "crowd-size audio swell" sensation from game-concept.md) is owned by **Audio Manager** (VS-tier). Follower Entity does not own ambient audio — it fires discrete events only. **Dependency**: Audio Manager GDD must specify the murmur layer and consume `CrowdStateClient.count` to scale it.
- `Despawning:FadeOut` (cap shrink) → **NONE.** Recede without punctuation.
- Cull eviction → **NONE.** Off-screen, zero audio.

**Master de-dupe rule**: no broadcast-tick audio event may fire more than once per 15 Hz server tick per crowd. `CrowdManagerClient` holds a per-crowd `lastAudioTick` map; any audio request within the same tick is suppressed. This rule applies to `sfx_crowd_peel_flip` only. `sfx_absorb_snap` fires on reliable `GameplayEvent` (not broadcast tick) and is not subject to this de-dupe map.

### Animation style reinforcements

- **Idle / standstill** (`|d_delta| < 0.01`): bob phase frozen per F8 guard. **Micro-sway (F9)**: each follower applies ±0.03 stud horizontal sine at 0.4 Hz using its per-follower `sway_phase_offset` (randomized at spawn). Per-follower phase is mandatory — all-zero phase produces synchronized metronome oscillation, not organic idle jostling. Amplitude below bob — perceptible at LOD 0, invisible at LOD 1+. See F9 for full formula.
- **Peeling transit pose**: walk bob continues at 1.5 Hz distance-based cadence throughout `Peeling`. Peel speed 20 studs/s > walk ~16 studs/s → bob cadence naturally quickens, reads as running urgency without a separate animation state. No `WALK_FREQ_HZ` override for peel.
- **Despawning fade**: pure alpha tween, 0.2s, no wind-up pose. Instant-fade reads as "plucked away" per art bible §7 absorb-snap register: "the snap is the moment."

### Art bible compliance anchors

- **§1 — Visual Identity Statement** ("bold silhouette at 50m"): 2-Part rig, black outline, and `abs(sin)` upward-only bob preserve the crown-silhouette ridge at distance. Micro-sway ensures silhouette reads as alive at standstill. VFX suppression on despawn/cull protects this — particle noise around cull-tier entities would fragment the crowd read.
- **§4 — Flat Saturated Color / No Gradients**: Hue-flip is a single-frame `Color3` property write, not a lerp. White-flash is an identity-flash (Neutral White → rival hue), mirroring §4 Neutral NPC Treatment. No gradient, no color tween — the discontinuity IS the signal.
- **§8.7 — VFX / Particle Budgets**: Per-emitter cap 20 p/s, burst cap 40 per event, scene ceiling 2,000. The absorb-snap burst (10 particles, destroyed after emission) and full particle suppression on all other Follower Entity events are direct compliance. Audio de-duplication mirrors this applied to the sound domain.

### Tuning knob additions (animation)

| Knob | Default | Range | Notes |
|---|---|---|---|
| `MICRO_SWAY_AMP` | 0.03 studs | [0, 0.10] | Horizontal idle sway amplitude; 0 disables |
| `MICRO_SWAY_FREQ_HZ` | 0.4 | [0.1, 2.0] | Idle sway frequency — time-based, NOT distance-based |
| `sway_phase_offset` | `math.random() × 2π` | [0, 2π) | Per-follower random phase at spawn — NOT a config knob, but a per-instance runtime value. Listed here for documentation completeness. |

## Acceptance Criteria

**AC-1 (Rig assembly)** — GIVEN follower spawned with `crowdId` and pool grants Body+Hat, WHEN rig assembled, THEN: (a) exactly 1 `Body` MeshPart + 1 `Hat` MeshPart, NO `Humanoid`; (b) `Body.Anchored == true`; (c) `WeldConstraint` exists with `Part0=Body, Part1=Hat`, parented under Body (not crowd Folder); (d) `Hat.CFrame` offset `(0, headOffsetY, 0)` relative to Body; (e) follower's `d` is initialized to a random value in `[0, 1/WALK_FREQ_HZ)`, not 0.

**AC-2 (Walk bob)** — GIVEN Active w/ `|d_delta| >= 0.01`, WHEN `RenderStepped` fires, THEN `Body.CFrame.Y == Root_target.Y + abs(sin(d * 2π * 1.5)) * 0.15` within ±0.001 studs.

**AC-3 (Standstill freeze)** — GIVEN stationary `|d_delta| < 0.01` for 3 frames, WHEN `RenderStepped` fires each frame, THEN `d` does not increase; `y_bob` frozen at last non-idle value.

**AC-4 (Hue = Color3 + dirty flag)** — GIVEN spawn with hue `h`, WHEN `Body.Color` assigned, THEN value is `Color3` (not `BrickColor`). AND on subsequent frames with unchanged crowd hue, no `Body.Color` write (verify via spy).

**AC-5 (Hue flip at 50% peel)** — GIVEN Active follower, `startPeel` selects it at t=0 with T_peel=2.0s (d_peel=40, PEEL_SPEED=20), WHEN `elapsed` first exceeds `T_hue_flip = 1.0s` (threshold-crossing, NOT float equality), THEN: (a) `Body.Color` flips to rival hue in exactly 1 frame; (b) `_hueFlipApplied` latch is set `true` — no second flip fires before arrival; (c) `VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame)` called once; (d) hat color unchanged.

**AC-6 (Hat template missing)** — GIVEN `SkinSystem.getHatTemplate(skin_id) == nil`, WHEN spawn attempted, THEN follower has Body only (no Hat, no WeldConstraint); warning logged with `{crowdId, skin_id}`; no error thrown.

**AC-7 (Pool exhaustion)** — GIVEN `pool.grant() == nil`, WHEN spawn attempted, THEN silently dropped (no Part, no error); crowd continues rendering; warning logged exactly once per session.

**AC-8 (Spawn throttle)** — GIVEN 10 Absorb events fire within 2 frames, WHEN throttle queue evaluated, THEN ≤4 spawns on frame 1, ≤4 on frame 2, remainder queued to frame 3; total spawned equals total triggered (pool permitting).

**AC-9 (Peeling immunity)** — GIVEN follower in `Peeling`, `setPoolSize(crowdId, n)` called with `n < current`, WHEN LOD Manager queries `getPeelingCount(crowdId)`, THEN returns peel count; eviction only touches `Active` + `Despawning`; `Peeling` untouched.

**AC-10 (Crowd destroyed)** — GIVEN Active and `CrowdStateClient.get(crowdId) == nil`, WHEN per-frame update runs, THEN follower → `Despawning` that frame; F1-F4 not evaluated; Part returned to pool after 0.2s fade.

**AC-11 (F6 peel selection — closest to rival)** — GIVEN N=2, `rival_center=(50,0,0)`, Active followers at positions (40,0,0)=(dist 10), (38,0,0)=(dist 12), (10,0,0)=(dist 40), (5,0,0)=(dist 45). WHEN selection runs, THEN followers at distances 10 and 12 (closest to rival) are selected — NOT the farthest-from-own-center. AND second `startPeel` call (concurrent rival B) excludes already-`Peeling` entities from the first call; returns next-closest non-Peeling followers.

**AC-12 (F7 peel duration)** — GIVEN `d_peel = 40, PEEL_SPEED = 20, PEEL_MAX_DURATION = 3.0`, THEN `T_peel = 2.0s`, hue flip at t=1.0s. AND GIVEN `d_peel = 120`, THEN `T_peel = 3.0s` (capped); body arrives at rival center via direct CFrame on completion, not full 120-stud travel.

**AC-13 (F5 LOD tiers)** — GIVEN camera distances [0, 20, 20.1, 40, 40.1, 100, 100.1], WHEN tier computed, THEN [0, 0, 1, 1, 2, 2, CULL]. AND WHEN LOD swap fires (e.g., LOD-1→LOD-0 demote), THEN `d` is NOT reset; each follower's per-follower `d` value carries over; follower at LOD-0 re-entry bobs at its unique phase, not at phase 0.

**AC-14 (Teleport snap)** — GIVEN player teleports > 30 studs in 1 frame (crowd center delta > `TELEPORT_THRESHOLD`), WHEN boids update runs, THEN followers skip `V_final` interp; CFrame direct to `crowd_center + spawn_offset`. Subsequent frame resumes normal boids.

**AC-15 (F1 overlap EPSILON guard)** — GIVEN `P_i == P_j` exactly, WHEN F1 evaluates, THEN denom `max(0, 0.001)`; force magnitude finite and bounded; no NaN, no inf, no Luau error.

**AC-16 (Absorb slide-in)** — GIVEN Absorb trigger fires with valid `npcLastPosition`, WHEN spawn runs, THEN state = `Spawning:SlideIn`; initial CFrame = `npcLastPosition`; tween target = crowd_center; duration = 0.4s; hue = absorber's hue from frame 1; → `Active` on tween complete.

**AC-17 (Perf soak — Integration)** — GIVEN 80 LOD-0 followers on desktop client (60 FPS target, **160 Parts** = 2 Parts × 80 followers), WHEN 60-sec sustained playtest with Roblox Micro Profiler (label `FollowerEntityClient_Update`), THEN per-frame update loop ≤ 2.5ms at p99 (p99 = sort 3,600 samples descending, read sample at index 36). Evidence: `production/qa/evidence/perf-soak-[date].txt`. Note: 80-follower scenario is baseline; a full-lobby scenario (290 LOD-0 followers) must be profiled separately before mobile-cap decisions are finalized.

**AC-18 (Pool hide/unhide, no alloc — Integration)** — GIVEN pre-allocated pools at startup (**460 Body + 460 Hat** + 100 LOD 1 + 60 LOD 2), WHEN LOD tier swap occurs (0→1), THEN: (a) LOD-0 Body hidden (not destroyed) — verify via `Body.LocalTransparencyModifier = 1` or equivalent hide path; (b) LOD-1 Part un-hidden from LOD-1 pool; (c) count of instances under the crowd Folder before and after swap is identical (no net alloc, no net destroy). Evidence: `production/qa/evidence/lod-swap-[date].txt`.

**AC-19 (Return-from-CULL throttle)** — GIVEN cap-growth spawn fires with crowd previously at 0 rendered (returned from CULL), WHEN queue processed over N frames, THEN ≤4 spawns per frame until cap reached; each enters `Spawning:FadeIn` with 0.3s alpha tween; no frame exceeds 4 spawns regardless of queue depth.

**AC-20 (F4 boids final velocity)** — GIVEN `F_sep = (-1,0,0)`, `F_coh = (1,0,0)`, `F_lead = (0.6,0,0.8)`, default weights (SEP=1.5, COH=1.0, LEAD=3.0), WHEN `V_raw` computed per F4 zero-vector-guarded formula, THEN `V_raw ≈ (1.3, 0, 2.4)`, `‖V_raw‖ ≈ 2.73`. `V_final = clamp(2.73, 0, 16) × (1.3,0,2.4)/2.73 ≈ (1.3, 0, 2.4)`. `P_new = P_i + (1.3, 0, 2.4) * dt`. AND GIVEN `F_sep = F_coh = F_lead = Vector3.zero` (all forces absent), THEN `V_raw = Vector3.zero` → `P_new = P_i` (no movement, no NaN).

**AC-21 (Micro-sway standstill, F9)** — GIVEN Active follower at standstill (`|d_delta| < 0.01`) for 5 consecutive frames at LOD 0, WHEN `RenderStepped` fires, THEN `Body.CFrame.X` oscillates as `sin(t × 2π × 0.4 + sway_phase_offset) × 0.03` within ±0.001 studs; phase offset is per-follower and not equal across followers in the same crowd (verify via spy on two simultaneously standstill followers — phase offsets must differ). At LOD 1 or LOD 2: `micro_sway_x = 0`.

**AC-22 (Rival crowd nil mid-peel)** — GIVEN follower in `Peeling` state targeting `rivalCrowdId`, WHEN `CrowdStateClient.get(rivalCrowdId)` returns `nil` on the next per-frame read, THEN: follower switches boids target to own-crowd center; transitions to `Active` on arrival (not `Despawning`); pool slot retained; no rival-side spawn fires.

**AC-23 (Concurrent dual-rival peel)** — GIVEN crowd A at 80 Active followers, rivals B and C both call `startPeel(A→B, n=2)` and `startPeel(A→C, n=2)` in the same frame. WHEN both F6 calls complete, THEN: (a) exactly 4 followers total enter `Peeling` (2 toward B, 2 toward C); (b) no follower appears in both peel sets; (c) the two closest-to-B followers are selected for B, the two closest-to-C followers are selected for C (independent sorts against different rival centers).

**AC-24 (Hat color during SlideIn)** — GIVEN Absorb event fires and follower enters `Spawning:SlideIn`, WHEN observed on frame 1 and frame 2 of SlideIn, THEN: frame 1: `Body.Color == Color3.new(1,1,1)` (white); frame 2+: `Body.Color == HUE_COLORS[absorberHue]`; Hat.Color is skin-defined and unchanged throughout SlideIn.

**AC-25 (setPoolSize cap scope — Active only)** — GIVEN crowd with 10 Active followers and 3 Peeling followers (total 13 in pool), WHEN `setPoolSize(crowdId, 8)` is called, THEN: eviction applies to Active + Despawning only; 2 Active followers enter `Despawning:FadeOut`; all 3 Peeling followers remain in `Peeling` state untouched; `getPeelingCount(crowdId)` still returns 3.

**AC-26 (Bob suppression at LOD 1 and LOD 2)** — GIVEN Active follower at LOD 1 or LOD 2 with `|d_delta| >= 0.01`, WHEN `RenderStepped` fires, THEN F8 bob formula is NOT applied to `Body.CFrame`; `d` continues accumulating (for LOD-0 re-entry phase continuity); micro-sway F9 is also NOT applied at LOD 1/2.

---

**Test placement**: `tests/unit/crowd/follower_entity_test.luau` for ACs 1-16, 19-26 (TestEZ + mocked `CrowdStateClient` via dependency injection). ACs 17-18 are integration-tier — evidence in `production/qa/evidence/`.

**Blocking gates before story Done**: ACs 1-16, 19-26 require passing TestEZ run. AC-17 requires Micro Profiler evidence file (80-follower baseline) present and within 2.5ms p99. AC-18 requires folder instance-count equality before/after LOD swap confirmation.
