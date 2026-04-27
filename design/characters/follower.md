# Character Profile: Follower

> **Status**: Draft (Sprint 1 Design-Lock)
> **Asset slots**: `AssetId.Mesh.CharFollowerBody`, `AssetId.Mesh.CharFollowerHat`
> **Linked GDD**: `design/gdd/follower-entity.md` (canonical source for rig + animation + LOD)
> **Linked ADR**: ADR-0001 (Crowd Replication Strategy)
> **Linked**: `design/art/art-bible.md`, `design/accessibility-requirements.md`

## 1. Role + fantasy

The follower is the visible representation of every crowd member that ever existed in any round of Crowdsmith. When a player has 300 followers, the player has a parade. When a player has 10, the player has a panicked little band. When a player has 1, the player is alone but the camera still loves them.

Per `design/gdd/follower-entity.md` Player Fantasy: "You're a walking parade and every soul you touch wants in. Your pack of cheerful little civilians bobs and jostles behind you in a rolling flood of your color, each one snapped from blank white into your hue the instant you brushed them — a satisfying little tick on the counter, a tiny cheer in the crowd."

Followers ARE the Pillar 1 dopamine surface. Their visual appearance, their hue, their movement, and their snap-conversion-on-absorb is the game's emotional payoff.

## 2. Rig structure (locked per Follower Entity GDD §Core Rules)

**2-Part composite — non-negotiable** (locked by ADR-0001 + LOD performance budget):

| Part | Mesh | Purpose | Constraints |
|------|------|---------|-------------|
| **Body** | Single `MeshPart`, **400 tri at LOD 0** | Torso + head + merged limbs pre-baked into one mesh | `Anchored = true` (required — gravity is forbidden); receives hue `Color3`; CFrame-driven; walk-bob tween target |
| **Hat** | `MeshPart` from Skin System, single mesh per skin | Player identity signaling (visible from distance) | `WeldConstraint(Part0=Body, Part1=Hat)` parented under Body; color = skin-defined (NOT hue-tinted) |

**Why 2-Part / 400-tri**: Performance budget per ADR-0001. Crowd of 300 followers × 8 players × LOD-0 460-tri ceiling = arena triangle count tractable on mobile + desktop sustained 60 FPS (verified by `prototypes/crowd-sync/` PROCEED).

## 3. Proportions + silhouette

**Silhouette direction**: cel-shaded chunky civilian per `art-bible.md §8.4`. Distinctive silhouette is critical — followers must be recognizable from arena overview shots at LOD 1 (100 tri simplified primitive) and even LOD 2 (single billboard impostor).

| Spec | Value | Rationale |
|------|-------|-----------|
| Height | ~3 studs (player-relative — slightly shorter than default Roblox avatar) | Crowd readability — followers should not visually overwhelm the player avatar |
| Width (shoulders) | ~2 studs | Chunky, "cheerful civilian" not "athletic" |
| Head:body ratio | ~1:2.5 | Slightly large head for cel-shaded readability per `art-bible.md §8.4` |
| Limbs | Pre-baked into Body mesh | No separate Arm / Leg parts — 2-Part rig invariant per GDD §Core Rules |
| Hat slot offset | `Vector3.new(0, headOffsetY, 0)` where `headOffsetY` ≈ 1.4 studs | Sits centered above Body; Hat mesh extends upward from this anchor |
| Pose | Neutral standing posture (Body mesh is locked-pose; movement is CFrame translation only) | No skeletal animation — limb walk illusion via Body bob (§Core Rules walk animation formula) |

## 4. Palette + hue rules

**Hue is the identity signal** (Pillar 2). Follower Body color is set every frame to the assigned crowd hue:

```luau
Body.Color = HUE_COLORS[hue_index]
```

`HUE_COLORS` is the 8-entry palette per `art-bible.md §8.4 Neon-permit policy` — each entry is a saturated cel-shaded color.

**Hat is hue-independent**: Hat mesh keeps its skin-defined color; does NOT receive hue tint. This means the follower visual = `[hue-tinted Body] + [skin-colored Hat]` — two layers of identity, two layers of customization.

### Hue palette (canonical)

Reference 8 hue indices per Crowd State Manager GDD:

| Index | Color name | RGB approximate | Visual feel |
|-------|-----------|----------------|-------------|
| 1 | Coral | `(255, 107, 107)` | Warm, energetic |
| 2 | Mango | `(255, 167, 84)` | Cheerful, midday |
| 3 | Lemon | `(245, 220, 80)` | Bright, attention-grabbing |
| 4 | Lime | `(120, 220, 100)` | Fresh, new-game-feel |
| 5 | Mint | `(80, 220, 200)` | Cool, calming |
| 6 | Sky | `(80, 180, 245)` | Open, trustworthy |
| 7 | Lilac | `(180, 130, 230)` | Distinctive, premium |
| 8 | Bubblegum | `(245, 130, 200)` | Playful, identifiable |

**Final RGB values are owned by art-director — these are placeholders**. The 8-color count is locked; specific values may shift during art-bible §8.4 final palette ratification.

### Pattern overlay (Standard-tier accessibility elevation per `design/accessibility-requirements.md`)

Each crowd ALSO receives a pattern overlay (stripe / dot / chevron / solid / etc., 8 patterns total) applied via `SurfaceAppearance` or texture decal. Pattern is mandatory for colorblind compatibility — hue alone fails Standard tier per accessibility doc §Visual.

Pattern slot: applied to Body MeshPart `SurfaceAppearance.ColorMap` or per-follower `Decal` overlay. Implementation TBD — see follower-entity GDD Open Question OQ-pattern-overlay.

## 5. Animation hooks

Per Follower Entity GDD §Core Rules (locked):

### Walk animation (procedural, no skeletal)

- Per `RenderStepped`: accumulate travel distance `d` from `Body.Position` delta (studs)
- `Body.CFrame = Root_target * CFrame.new(0, abs(sin(d * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP, 0)`
- `WALK_FREQ_HZ` and `WALK_BOB_AMP` are tuning knobs in Follower Entity §Tuning Knobs
- No limb animation — limbs are pre-baked into the Body MeshPart

### Spawn animations

- **SlideIn** (absorb path): 0.4s lerp from NPC last-known position → crowd center; `Body.Color = white` for 1 frame, then crowd hue (the "snapped from blank white into your hue" Pillar 1 conversion moment)
- **FadeIn** (cap-growth path): from null state to full opacity over short duration; no white-state frame

### Despawn animations

- **PopOut** (absorb-by-rival): scale + fade over 0.3s; particle puff via `AssetId.Particle.AbsorbSnap`
- **PeelOff** (collision peel): 0.5s linear transit from origin crowd → rival crowd; hue-flip at 50% transit per Follower Entity §F7

### LOD transitions

- LOD 0 → LOD 1 at 20m: 400-tri Body → 100-tri simplified primitive (no hat — hat is invisible at this distance)
- LOD 1 → LOD 2 at 40m: simplified primitive → single billboard impostor per crowd (not per-follower; LOD 2 cap = 1 per crowd per Follower LOD Manager GDD)
- Beyond 100m: culled

## 6. Asset specifications

### CharFollowerBody mesh (LOD 0)

| Spec | Value |
|------|-------|
| AssetId slot | `AssetId.Mesh.CharFollowerBody` (placeholder `rbxassetid://0` until production upload) |
| Triangle budget | **400 tri max** at LOD 0 |
| Texture budget | 256×256 albedo + 256×256 normal (optional); single-material |
| UV layout | Single UV island per mesh; 0.95 padding around island edges to prevent texture bleeding at MIP levels |
| Pivot | At feet center (so `Body.Position` corresponds to ground contact) |
| Anchored | `true` (required — CFrame-driven; gravity forbidden) |
| CanCollide | `false` (followers do not collide with world geometry; only crowd-vs-crowd resolution per `design/gdd/crowd-collision-resolution.md`) |
| Material | Per `art-bible.md §8.4` — cel-shaded surface appearance (likely `MaterialVariant` with custom shader OR `SurfaceAppearance` with neon-permit) |

### CharFollowerBody mesh (LOD 1, simplified)

| Spec | Value |
|------|-------|
| Triangle budget | **100 tri max** |
| Same UV layout as LOD 0 (allows shared texture) |
| Used at distance 20m-40m |

### CharFollowerHat mesh (Skin System)

| Spec | Value |
|------|-------|
| AssetId slot | Skin System owns hat slots; reserved per skin in `AssetId.Skin.*` (e.g. `FollowerCity1` skin defines its hat mesh ID) |
| Triangle budget | **150 tri max** per hat (additional to Body 400) |
| Texture budget | 128×128 albedo per hat |
| Visible at LOD 0 only (hidden at LOD 1+) |
| MVP hat slate (5 reserved skins per Skin §Story 001): `FollowerDefault` + `FollowerCity1` + `FollowerCity2` + `FollowerNeon` + `FollowerEvent1` |

## 7. Edge cases

- **Hue palette index 0 (white)**: reserved for `Spawning:SlideIn` first-frame "blank white" state. Not assigned to any crowd as steady-state hue.
- **Hat missing or failed-to-load**: Body still renders; gameplay continues. Visual identity falls back to hue-only (not ideal but non-blocking). Hat reload on next frame via Skin System.
- **Pattern overlay missing**: Body still renders with hue alone. Visual identity falls back to hue-only. Logs warning per `[FollowerEntity]` prefix; flags accessibility regression but non-blocking.
- **Crowd destroyed mid-frame**: follower transitions to `Despawning` immediately per `design/gdd/follower-entity.md` §States.

## 8. Open questions

| ID | Question | Owner | Deadline |
|----|----------|-------|----------|
| OQ-1 | Is the cel-shaded surface implemented via `MaterialVariant` (Roblox built-in) or `SurfaceAppearance` with custom shader? Roblox does not expose custom shaders directly. | art-director + technical-artist | Sprint 2 (before art production) |
| OQ-2 | How does pattern overlay attach to a 400-tri Body? Texture-baked variants (8 textures × 8 hues = 64 combinations) vs runtime `Decal` overlay vs `SurfaceAppearance.ColorMap` swap? | art-director + game-designer | Sprint 2 |
| OQ-3 | Does the Hat mesh need separate LOD 0 / LOD 1 variants, or is it always invisible at LOD 1+? Currently spec says invisible at LOD 1+; confirm with art-director. | art-director | Sprint 2 |
| OQ-4 | Hat-on-skin permutations: 5 MVP skins × 8 hue palettes = 40 visual combinations. Need to verify all 40 read distinctly from arena-overview distance. | ux-designer + art-director | Sprint 1 (before art production lock) |
