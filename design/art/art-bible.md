# Crowdsmith — Art Bible

*Created: 2026-04-20*
*Status: Draft*

> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED — Lean review mode.

## Visual Identity Anchor (source: `design/gdd/game-concept.md`)

Roblox Default Stylized — chunky low-poly, cel-shaded, bold silhouette-first. No gradients, no realism. Each player's crowd = one vivid signature hue.

---

## 1. Visual Identity Statement

**One-line visual rule**: *Every asset must read as a bold silhouette at 50 meters on a mobile screen — no gradients, no realism, no ambiguity.*

This rule is the single gate every asset must pass before entering production. It derives directly from the core readability crisis: 8-12 player crowds of 100-300 followers, all moving simultaneously, must be instantly discriminable. Ambiguous silhouettes or muddy colors kill the **Snowball Dopamine** pillar at its root — if you can't tell your crowd from a rival's in a split second, growth never feels yours.

### Supporting Principles

1. **Silhouette-first geometry** (serves Pillar 1: Snowball Dopamine, Pillar 5: Comeback Always Possible)
   Every character, chest, car, and building must have a distinct outline that communicates its function without color.
   *Design test*: cover the screen with a black silhouette mask. If the asset type and team ownership are not immediately legible, the geometry must be revised before color is applied.

2. **Flat saturated color, no exceptions** (serves Pillar 4: Cosmetic Expression, Pillar 1: Snowball Dopamine)
   Colors are identifiers, not decoration. Every hue carries a single meaning — crowd ownership or interactable tier.
   *Design test*: if a color value has a gradient stop or a specular highlight that competes with the crowd color reading, it fails.

3. **Environmental subordination** (serves Pillar 1: Snowball Dopamine, Pillar 3: 5-Minute Clean Rounds)
   The city is a stage. Its job is to make crowds pop, not to compete.
   *Design test*: composite any crowd color against environment. If environment saturation within 10 studs of a follower exceeds that follower's signature hue, the environment asset fails.

---

## 2. Mood & Atmosphere

All mood shifts use `Lighting` service (Ambient, Brightness, ColorShift_Top/Bottom) and PointLight/SurfaceLight on chest tiers. No post-processing shaders — Roblox doesn't expose them.

| Game State | Primary Emotion | Lighting | Adjectives | Energy |
|-----------|----------------|----------|-----------|--------|
| **Match intro / lobby** | Anticipation, social curiosity | Warm golden-hour, Brightness ~2, soft shadows, low contrast | Relaxed, friendly, bright, open, inviting | Low |
| **Early round (0-2 min)** | Excitement building | Bright neutral daylight, Brightness ~3, high ambient | Crisp, clear, breezy, playful, open | Low-medium |
| **Mid round (2-4 min)** | Tension, calculation | Cooler ColorShift_Top, +20% contrast | Charged, dynamic, competitive, decisive | Medium-high |
| **Final showdown (4-5 min)** | High stakes, adrenaline | Warm-cool contrast sharp, ColorShift_Bottom warm amber for ground shadows | Electric, tense, saturated, punchy | High |
| **Victory screen** | Euphoria, pride | Hard-cut celebratory warm white, Brightness ~4, confetti burst (flat quad particles) | Triumphant, warm, festive, clean | Burst → settle |
| **Elimination** | Surprise, NOT shame | Brief desaturate flash (0.3s), clean spectator camera. **No red tones** — read as punishment | Quick, clean, matter-of-fact, neutral | Abrupt drop |

Pillar 5 (Comeback Always Possible) demands elimination must not feel punishing — next-round queue button within 2 seconds, no slow death animation, no mocking camera linger.

---

## 3. Shape Language

### Character Silhouette Philosophy

Players and followers share the Roblox R15 base (for players) and a simplified 4-6-part custom rig (for followers — see Section 8.6). Both push toward chibi/chunky proportions: large head, short legs, wide torso. The oversized head produces the crowd's visual atom — a bumpy ridge line that reads at distance even through LOD reductions.

*Design test*: at 50m render distance on a 375px-wide mobile viewport, a cluster of 10 followers must produce a legible bumpy silhouette (heads forming a ridge). If the cluster reads as a blob, head scale must increase.

### Follower Silhouette

Followers scale to ~80% of player character scale — player is visually largest entity in their own crowd. Follower billboard impostor (LOD 2) texture is **taller than wide (64×128)** to preserve the head ridge readable silhouette.

### Environment Geometry

- **Buildings**: rectangular block masses, strong vertical thrust, flat or simple pitched roofs. Detail is silhouette, not texture.
- **Cars**: exaggerated boxy proportions, oversized wheels, cab clearly distinct from body.
- **Props (bench, lamppost, bin)**: single-function shapes with one exaggerated feature.

*Design test*: no prop placed within 6 studs of street corridor center. No prop's silhouette may fragment a cluster of 5 followers at ground level.

### UI Shape Grammar

Rounded rectangles, corner radius 8px screen-space. Bold outlines 2-3px equivalent on interactive elements. No hairline borders — fail on low-DPI mobile. Numbers use blocky display fonts with strong weight.

### Hero vs. Supporting

- **Heroes** (player, chests, cars, buildings-when-interactable): strong outlines, max saturation, top of hierarchy.
- **Supporting** (environment, ground, props): desaturated, smooth edges, no outlines — they recede.

---

## 4. Color System

### Primary Palette

| Role | Hex | Usage |
|------|-----|-------|
| Neutral White | #F5F5F5 | Neutral NPCs — the mass to be absorbed |
| Environment Stone | #8A8A8A | Building facades, roads, sidewalks |
| Environment Accent | #5A6A7A | Window insets, door frames |
| Chest Gold (T1) | #FFD700 | T1 chest glow + icon |
| Chest Silver-Blue (T2) | #72B5F5 | T2 car glow — cool separation from Gold |
| Chest Violet (T3) | #B44FFF | T3 building glow — premium |
| UI Ink | #1A1A1A | Text on light; icon outlines |

### Player Crowd Colors (12 signature hues, 1 per player)

Round-start auto-assigned. **Locked safe palette** — enforces minimum 30-degree LCH perceptual distance under deuteranopia simulation.

| # | Name | Hex | Notes |
|---|------|-----|-------|
| 1 | Hot Pink | #FF2D78 | Distinct from Red |
| 2 | Cyan | #00CFFF | Separates from Blue |
| 3 | Lime | #7FFF00 | Reads against stone environment |
| 4 | Orange | #FF7A00 | Separates from Yellow/Red |
| 5 | Electric Blue | #0055FF | Deep blue |
| 6 | Yellow | #FFE500 | Increase outline weight to 3-unit; dark nameplate drop-shadow |
| 7 | Purple | #9B00FF | Saturation distinct from Chest Violet |
| 8 | Red | #FF2222 | Avoid adjacency with Hot Pink same round |
| 9 | Teal | #00E5B0 | Green component separates from Cyan |
| 10 | Coral | #FF5F57 | Lightness separates from Red/Orange |
| 11 | Mint | #00FF99 | Temperature separates from Lime |
| 12 | Gold-Yellow | #FFAA00 | Contrast to Electric Blue |

All followers also render a **2-unit black outline** — silhouette discrimination when hue fails. Hat/accessory shape varies per skin — shape-based backup discrimination. Yellow gets 3-unit outline to prevent wash against light city.

### Neutral NPC Treatment

#F5F5F5 with light-grey outline. Must be visually quieter than any player crowd. Flat grey hat, no bright elements. Absorb flash = brief white-then-signature-hue snap.

### Chest Tier Color Coding

Warm → cool → violet progression creates linear readability ramp. Player should identify tier by glow color *before* reading text.

*Design test*: screenshot of all three tiers in one frame w/ crowds. New player must identify tiers by color alone.

### Environment Palette

Saturation ceiling **20%** on all environment surfaces. Ground #9A9A9A minimum. Grayscale test: city screenshot converted to greyscale should still read as a city; add crowds back — crowds should be the first thing that reads in color.

### Colorblind Safety

- All 12 crowd hues validated under deuteranopia/protanopia/tritanopia simulation
- 2-unit black outline on every follower (shape redundancy)
- Relic rarity uses **shape redundancy** (circle / diamond / starburst / hexagon frame per rarity tier) — color is secondary signal
- Chest tier redundancy: color + unique icon shape per tier (chest icon / car icon / building icon)

---

## 5. Character Design Direction

### Player/Follower Archetype

Player = full Roblox R15 rig, unique (8-12 on screen). Follower = simplified custom 4-6-part rig driven by CFrame (see Section 8.6). Same visual archetype: "cheerful urban civilian, Roblox-proportioned." One character mesh family, one material palette.

### Skin System

A skin = (1) body signature hue (the crowd color, auto-applied), (2) swappable hat/headgear accessory mesh, (3) optional flat torso print texture (1-2 flat colors max).

Modular design: new skin = new hat + color slot. NOT full retex. Affordable production rate at 10-15 skin sets by V1.5.

*Design test*: any new hat mesh must read shape from 20m in LOD 0, must not obscure the head silhouette dome (crowd ridge-line).

### Expression/Pose

R15 rig constrains expressions to accessory-driven (hats, face decals). Crowd followers = single looping walk (Roblox catalog "Walk"). Player may have custom idle telegraphing active relic effect — **V1.5 aspirational, not MVP**. Poses upright, energetic, slight forward lean on walk.

### LOD Tiers (reconciled — hybrid 3-tier)

| LOD | Distance | Geometry | Target Tri |
|-----|----------|----------|-----------|
| **LOD 0** | 0-20m | Full custom rig (follower) / full R15 (player) | Follower 400 tri / Player 1,500 tri |
| **LOD 1** | 20-40m | Simplified box body, sphere head, cylinder limbs. Hat → flat disc | 100 tri |
| **LOD 2** | 40-100m | Billboard impostor (BillboardGui + ImageLabel, 64×128 sprite) | 2 tri |
| **Cull** | 100m+ | Hidden | 0 |

*Design test*: at 60m, cluster of 20 billboard followers must read as a crowd, not a flat color rectangle. If reads as rectangle, billboard sprite needs more defined profile.

Client-side distance check runs every 0.1s (not every frame) via ComponentCreator-tagged follower component.

---

## 6. Environment Design Language

### Architectural Style

Modernist cartoon blocks — simplified mid-century commercial district. Flat roofs, rectangular massing, minimal ornament. Legible urban grid creates clear street corridors for crowd routing. Street corridors = gameplay arteries — environment must emphasize and preserve them.

### Texture Philosophy

Roblox native materials only in MVP: `SmoothPlastic` (building facades), `Plastic` (props/vehicles), `Metal` (car panels only). No custom textures. V1 may add flat-design decals for storefronts/signage — no gradients, no photo-derived imagery.

### Prop Density

Low. Ground between buildings stays clear enough for 50-follower crowd to route without visual fragmentation. **No prop within 6 studs of street corridor center.** Prop clusters at street corners only. Low density also serves draw-call budget.

### Chest Tier Visual Design

All three tiers share universal language — solves crowd-occlusion problem from concept doc:

- **PointLight glow** (matching tier color, pulsing)
- **Vertical neon beam** (narrow cylinder Part, tier color, extends 15 studs above object — visible above any crowd)
- **BillboardGui tier icon** (2D flat, above crowd height)

Tier-specific:

- **T1 chest**: 2×2×2 stud box. Gold glow/beam/icon. Early-game cluster target.
- **T2 car**: standard car prop. Silver-blue glow/beam, car icon. ~15-follower toll.
- **T3 building**: entire building face pulses violet at intervals. Violet beam widest. Building silhouette icon. Late-game only.

*Design test*: screenshot of T1 chest surrounded by 50 followers. Beam + icon must be visible above crowd silhouette.

### Environmental Storytelling

City starts fully populated with neutral white NPCs. As crowds absorb, streets clear. By minute 3, emptied streets visually tell the story of territory claimed. Free storytelling from mechanic — no additional assets required.

---

## 7. UI/HUD Visual Direction

*Integrates UX readability review — mobile is the binding constraint.*

### Diegetic World-Space

- **Crowd size nameplate**: BillboardGui above player/rival characters. **Vertical offset scales with crowd size**: 1-50 standard, 51-150 push 1.5×, 151+ push 2.5× + font weight +1 step. **Double-outline** (2px white outer, 1px black inner) for legibility over both light and dark world surfaces.
- **Chest toll**: BillboardGui above chest, tall enough to read above crowd at tier height.
- **Chest tier icon**: BillboardGui above beam (see Section 6).

### Screen-Space HUD (mobile layout)

| Element | Position (mobile) | Position (desktop) |
|---------|-------------------|---------------------|
| **Crowd size (own)** | Bottom-center (thumb-reach glance zone) | Top-center, large display font |
| **Round timer** | Top-center, secondary weight | Top-center |
| **Mini-leaderboard** | Top-right, collapsible tap-to-expand pill | Top-right, 3-4 rows |
| **Relic shelf** | **Bottom-right** (mirrors joystick, non-movement thumb) | Bottom-center |
| **On-screen joystick** | Bottom-left (mobile only) | — |

No minimap in MVP. Arena small enough that visual orientation maintains.

### Legibility Strategy

- **Screen-space HUD**: semi-transparent dark plate (60-70% black opacity, rounded rect) behind all elements. Consistent with flat-design rule (no gradients, no drop shadows).
- **Diegetic billboards**: double-outline (white outer + black inner).
- **No drop shadows** as primary legibility — conflict with flat-design pillar, unreliable on dynamic backgrounds.

### Typography

- **Display font** (crowd count, toll, timer): bold blocky sans-serif, zero-ambiguity numerals. `GothamBold` baseline. Round-state ≥28pt screen size. Toll ≥18pt at standard chest distance.
- **UI font** (menus, labels): `Gotham` regular ≥14pt, high contrast always. No thin fonts anywhere.
- **Relic card labels**: 10pt absolute minimum, on white card backing.

### Iconography

All icons flat, 2-color max (fill + outline on white), square aspect with rounded corners.

**Relic icons MUST use family-shape system before scaling past 8 relics** (mitigates the 25-30 icon recognition limit):

| Family | Silhouette Motif | Examples |
|--------|------------------|----------|
| Movement | Arrow motif | Speed, jump, dash |
| Absorb | Magnet motif | Radius, snap distance, chain |
| Toll | Coin motif | Chest discount, free-toll chance |
| Crowd | Cluster motif | Follower trail, tether, shield |
| Rare/unique | Starburst motif | Round-changing relics |

**Relic rarity frames** (shape redundancy for colorblind):
- Common = circle frame
- Uncommon = diamond frame
- Rare = starburst frame
- Legendary = hexagon frame

*Design test*: cover text label on relic card — icon alone must communicate category to a new player within 2 seconds.

### Animation Feel

- **Crowd count pop**: scale bounce 1.0 → 1.3 → 1.0 over 0.15s per +10 followers
- **Chest open**: burst of flat-color confetti quads in tier color; chest scales up then dissolves; relic card slides up from chest position
- **Relic reveal**: card flips (Y-axis rotate, flat-shaded, no 3D shine), lands face-up with brief tier-color glow pulse
- **Crowd absorb**: absorbed neutral flashes white → snaps to signature hue. No trail, no stretch — *the snap is the moment*
- **Number pop (toll sacrifice)**: red minus-number floats up from chest, fades

---

## 8. Asset Standards — Engine Constraints

*Authoritative table — tech-artist constraints bind. Applies to all production assets.*

### 8.1 Hard Constraints Summary

| Category | Triangle Budget | Texture Res | Notes |
|----------|----------------|-------------|-------|
| Player character | 1,500 tri | 256×256 | No SurfaceAppearance; SmoothPlastic + BrickColor |
| Follower character | 400 tri | None (vertex/material) | No SurfaceAppearance, NO Humanoid |
| T1 chest (small prop) | 300 tri | 128×128 | Single texture atlas |
| T2 car (medium prop) | 800 tri | 256×256 | Single SurfaceAppearance ColorMap only |
| T3 building (large prop) | 2,500 tri | 512×512 | Shared atlas |
| Environment block | 1,200 tri | Shared 512×512 | Max 4 unique materials |
| Decorative prop | 200 tri | None (material + BrickColor) | No SurfaceAppearance |
| Per-scene triangle ceiling | ~3-4M rendered | — | Mobile-safe target |
| Concurrent particles | 2,000 | — | Scene-wide budget |
| Texture memory ceiling | <512MB GPU | — | Roblox Dev Console monitored |

### 8.2 MeshPart Constraints

- Per-mesh tri limit: 20,000 hard (Roblox). Never approach; split into composited MeshParts under one Model.
- `CollisionFidelity`: **default `Box`** for static environment + props. `Hull` for chests/cars (approximate convex). **`PreciseConvexDecomposition` banned on followers** — prohibitive cost at 800+ instances.
- **All static geometry `Anchored = true`**. Unanchored without physics = needless simulation overhead.
- **No CSG Unions in production** — break occlusion culling, inflate memory, can't use SurfaceAppearance. MeshPart only (imported from FBX/OBJ via Asset Manager).

### 8.3 Texture Budgets

Priority order for color application:

1. **BrickColor + Roblox material enum** (SmoothPlastic). Zero texture cost. Use for everything possible.
2. **SurfaceAppearance ColorMap only** (128×128 or 256×256). Only for painted flat color BrickColor can't express.
3. **Vertex color via multi-BrickColor Part assemblies**. Preferred over SurfaceAppearance when >2 colors needed.

**Banned**: NormalMap, MetalnessMap, RoughnessMap. No PBR. Fight flat aesthetic AND blow mobile memory.

**Atlas policy**: T3 buildings + environment blocks sharing visual material set share a single 512×512 atlas. Target: ≤6 unique SurfaceAppearance across the entire city.

### 8.4 Material Standards

- **Default**: `Enum.Material.SmoothPlastic` for all character + prop geometry
- **Lower priority**: `Enum.Material.Plastic` (ground planes, wall infill)
- **Neon**: chest VFX emitters + ability indicators + UI billboards ONLY. Never on structural geometry
- **Metal / Wood**: banned on character/follower geometry. Permitted on environment props only when silhouette benefits

### 8.5 LOD Policy

Roblox has no built-in MeshPart LOD — implement manually.

- **`StreamingEnabled = true`** (mandatory)
- **`ModelStreamingMode = Atomic`** on multi-part Model assemblies
- **`StreamingTargetRadius`** starts 150 studs, tune via playtest
- **Follower LOD swap**: client-side distance check every 0.1s via ComponentCreator-tagged follower component. Tiers per Section 5 LOD table.

### 8.6 Rigging Standards

- **Player characters**: standard Roblox R15 rig + standard accessory attachment. No custom bones.
- **Followers**: **NO Humanoid instance**. Humanoid carries pathfinding + physics + health state — at 800+ followers this is prohibitive.
  - Custom rig: root Part + 4-6 child Parts (torso, head, 2 arms, 2 legs)
  - Movement + animation: CFrame writes from server, replicated to clients
  - No Motor6D animation system
  - Procedural arm-swing / head-bob via CFrame math client-side
  - Bone count: **0 Bone instances, Parts only**
- **AlignPosition / AlignOrientation**: permitted for knockback / absorb pull, but **disable immediately after effect resolves**. Leaving active constraints on 800+ chars destroys physics thread.

### 8.7 VFX / Particle Budgets

- Per-emitter rate cap: **20 particles/sec** during active emission
- Burst emission cap (chest open): **40 particles total per event**
- Scene-wide concurrent particle ceiling: **2,000**. Client VFX manager tracks count, suppresses lower-priority emitters approaching 1,800.

Tool selection:
- `ParticleEmitter` — ambient FX, chest bursts, absorb sparkle
- `Beam` — player↔follower tether, ability charge
- `Trail` — projectile motion, fast-moving follower scatter (≤4 concurrent per player)

Crowd absorb: single 10-particle 0.3s burst anchored at followers' last position; **destroy emitter after burst** — never leave attached to destroyed followers.

### 8.8 File Naming Convention

PascalCase, no spaces, matches Rojo-expected Instance names.

Pattern: `[Category][AssetName][Variant][Suffix]`

Examples:
- `CharFollowerBase.mesh`
- `CharFollowerBillboardLod2.png`
- `PropChestTier1.mesh`
- `EnvBuildingBlockA.mesh`
- `TexChestTier1Color.png`
- `UiIconRelicAbsorbRadius.png`
- `VfxAbsorbSnapSmall.png`

Suffixes: `Color` (ColorMap), `Mesh`, `Rig`. **Never include resolution in filename** — import setting, not filename concern.

### 8.9 Rojo Mapping

Mesh + texture source files live under `assets/` (OUTSIDE `src/`, NOT synced by Rojo). Upload via Studio Asset Manager. Reference by AssetId in Luau.

**AssetId registry**: `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` — string constants mapping logical names to `rbxassetid://` URIs. **No Luau file may hardcode an asset ID inline.**

```
assets/
  meshes/         -- Source FBX/OBJ (upload-only)
  textures/       -- Source PNG (upload-only)

src/ReplicatedStorage/Source/SharedConstants/
  AssetId.luau    -- Logical-name → rbxassetid:// map (Rojo-managed)
```

### 8.10 Performance Validation Workflow

**MicroProfiler** (`Ctrl+F6` Studio / `microprofiler` console):

| Label | Target | Red flag |
|-------|--------|----------|
| `Render/Prepared` | <4ms mobile | >4ms = overdraw / tri count |
| `Humanoid` | 0 for followers | Any reading = Humanoid leak on follower |
| `Physics/Stepped` | <3ms | Unanchored geometry or active constraints |
| `Heartbeat` script time | <1ms combined | LOD manager or CFrame loop too expensive |

**Developer Console > Memory > GraphicsTexture**: <512MB target. >300MB before full arena population = audit SurfaceAppearance usage.

**Stats service**: `Stats.GetTotalMemoryUsageMb()` — log at 30s, 2min, 5min round marks.

**Device Emulator QA gates**: every story requires one iPhone SE emulation pass (720×1280) + one Xbox One emulation pass before Done. <45 FPS dip on mobile emulation = blocking defect.

---

## 9. Reference Direction

### Crowd City (Voodoo)

- **Draw from**: top-down crowd color coding clarity; absorb snap-and-color-change as absorb-feel model; minimal UI with most info in world-space nameplates.
- **Diverge from**: Crowd City's entirely grey environment sacrifices world character. Crowdsmith needs enough city character to feel like a place worth being in (Pillar 4). Also diverge from its 2D flatness — we want toy-town 3D.

### Stumble Guys

- **Draw from**: exaggerated chibi proportions (large head) prove readability in chaotic multiplayer. High-saturation skin palette validates per-player signature hue.
- **Diverge from**: Stumble Guys' environment visual noise (tilting platforms, obstacles) occasionally obscures character reads. Crowdsmith environments MUST be aggressively cleaner. Elimination animations comedic and lingering — Crowdsmith must be brief and non-punishing (Pillar 5).

### Brawl Stars (Supercell)

- **Draw from**: camera distance + character scale proven readable at arena distances on mobile. Bold flat arena floor with minimal texture noise = direct reference for play-space visual discipline. Rarity-tier color coding (Rare/Super Rare/Legendary) = model for T1/T2/T3 chest tier language.
- **Diverge from**: Brawl Stars has character-unique silhouettes — every Brawler distinct body shape. Crowdsmith uses ONE shared follower mesh. Do not differentiate follower silhouettes by skin — signature hue does that work.

### Paper.io 2 (Voodoo)

- **Draw from**: pure flat color territory carrying spatial information instantly. Crowd-color-vs-grey-environment contrast is the exact dynamic we want.
- **Diverge from**: Paper.io is 2D, abstract, no geometry. Crowdsmith 3D city must retain visual interest so players want to be seen in the world (Pillar 4).

### Dave the Diver (MINTROCKET)

- **Draw from**: warm, cozy, inviting mood with saturated colors that feel cheerful rather than aggressive — emotional register for our lobby/intro state and overall tone. Cozy UI card design (big bold illustrations, warm white backgrounds, rounded corners) = direct relic card reference.
- **Diverge from**: Dave uses rich gradients throughout UI + painterly depth underwater. Crowdsmith BANS gradients (§1). Translate cozy warmth via flat-color palette warmth (amber-adjacent lighting, rounded forms) — no gradients allowed.

---

## Next Steps

- `/design-review design/gdd/game-concept.md` — validate concept completeness
- `/map-systems` — decompose Crowdsmith into systems + dependencies
- `/design-system [system-name]` — per-system GDDs (one at a time)
- `/consistency-check` — once GDDs exist, scan against this art bible
- `/asset-spec` — generate per-asset visual specs + AI generation prompts from approved GDDs
- `/create-architecture` — master architecture blueprint
