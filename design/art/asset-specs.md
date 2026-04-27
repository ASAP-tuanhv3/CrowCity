# Asset Specifications: AssetId Registry Slots

> **Status**: Draft (Sprint 1 Design-Lock)
> **Last Updated**: 2026-04-27
> **Linked**: `design/art/art-bible.md`, `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau`, `design/characters/`, `design/gdd/vfx-manager.md`, `design/gdd/chest-system.md`, `design/accessibility-requirements.md`

This document is the central asset-specification reference. It defines triangle budgets, texture budgets, UV-layout guidance, naming conventions, and Studio Asset Manager workflow for every reserved slot in `AssetId.luau`.

Per ADR-0006 (Module Placement Rules), every asset reference in `src/` must resolve through `AssetId.luau`. This document tells art production WHAT goes into each `rbxassetid://N` slot.

---

## 1. Asset categories overview

Per `AssetId.luau` (Foundation epic):

| Category | Slot count | Owner | Production-readiness gate |
|----------|-----------|-------|---------------------------|
| `AssetId.Skin` | 5 | Skin System (VS+) | Sprint 2 (`FollowerDefault` only); Sprint 5 (full slate) |
| `AssetId.Mesh.Char*` | 4 | Character profiles (`design/characters/`) | Sprint 2 (Vertical Slice build) |
| `AssetId.Mesh.Prop*` | 3 | Chest System (`design/gdd/chest-system.md`) | Sprint 2 (T1+T2); T3 deferred Alpha |
| `AssetId.Mesh.Env*` | 4 | Level design (TBD epic) | Sprint 2 (placeholder); final art Sprint 4 |
| `AssetId.Particle` | 12 | VFX Manager (`design/gdd/vfx-manager.md`) | Sprint 2 (4 critical: AbsorbSnap, MaxCrowdFlash, ChestOpenT1Confetti, RelicGrantCommon); rest Sprint 3 |
| `AssetId.Sound` | 10 | Audio Manager (VS+) | Sprint 2 (4 critical: MatchStartCue, MatchEndCue, AbsorbCue, EliminationCue); rest Sprint 3 |

Total: **38 reserved slots**. All currently `rbxassetid://0` placeholders. Real uploads happen via Studio Asset Manager (out of scope for Foundation epics; production deliverable).

---

## 2. Cross-asset invariants (apply to ALL slots)

These rules apply uniformly across all asset categories:

### 2.1 Style baseline

- Per `art-bible.md §8.4` Neon-permit policy — cel-shaded silhouette discipline; saturated palette only when permitted (player crowds ARE permitted per identity-signaling exception)
- High-contrast silhouettes — every asset must read at arena-overview camera distance
- No photorealistic textures; no PBR materials with metallic / smoothness; cel-shaded flat surfaces

### 2.2 Performance baseline (per ADR-0001 + ADR-0003)

- Total triangle budget per arena: ≤500K tri at peak (8 player crowds × ~100 LOD-0 followers × 460 tri ≈ 368K + props + environment)
- Texture memory: ≤80 MB resident per client
- Particle count: ≤300 active particles per frame (per VFX Manager GDD F2 suppression-tier 1 default)

### 2.3 Naming + filing

- Asset name = AssetId slot key verbatim (e.g. `CharFollowerBody.fbx` → uploads to slot `AssetId.Mesh.CharFollowerBody`)
- Source files (`.blend`, `.fbx`, `.png` masters) live in `assets/` repo path (gitignored beyond first commit; large-file storage TBD)
- Final Studio uploads tracked in `design/art/asset-upload-manifest.md` (Sprint 2 deliverable — not yet authored)

### 2.4 Studio Asset Manager workflow (Sprint 2 production)

Per Roblox documentation:
1. Upload mesh / texture / sound to Studio Asset Manager
2. Studio assigns `rbxassetid://N` URI
3. Update `AssetId.luau` slot from `rbxassetid://0` placeholder to real `rbxassetid://N`
4. Run `bash tools/audit-asset-ids.sh` → exit 0 (no magic-string drift)
5. Commit `AssetId.luau` change with `feat: AssetId — wire <slot> upload` commit message

**MVP discipline**: only `AssetId.luau` changes when uploading. No magic-string asset IDs anywhere else in `src/` per ADR-0006 §Verification Required A.

---

## 3. Skin category specs (`AssetId.Skin.*`)

5 reserved slots. Each is a complete cosmetic skin = hat mesh + texture + (optional) follower-Body texture variant.

| Slot | Visual direction | Hat mesh tri budget | Hat texture | Per-skin Body texture? | Production sprint |
|------|------------------|---------------------|-------------|-----------------------|-------------------|
| `FollowerDefault` | Simple neutral hat (baseball cap / visor / similar) per `art-bible.md §8.4` cel-shaded baseline | 150 tri | 128×128 albedo | No (uses default hue palette) | Sprint 2 |
| `FollowerCity1` | Urban-themed (taxi cap / construction hard-hat / fedora) | 150 tri | 128×128 albedo | Optional — if skin has body-texture variant (e.g. street-vendor uniform), 256×256 | Sprint 5 |
| `FollowerCity2` | Second urban variant (cyclist helmet / chef hat / etc.) | 150 tri | 128×128 albedo | Optional | Sprint 5 |
| `FollowerNeon` | Saturated neon-pop hat per `art-bible.md §8.4` Neon-permit (LED visor / glow-rim hat) | 150 tri | 128×128 albedo + 128×128 emissive | Optional — possibly emissive-rim Body | Sprint 5 |
| `FollowerEvent1` | First seasonal/event skin (TBD theme — owned by live-ops) | 150 tri | 128×128 albedo | Optional | Sprint 5+ |

### Skin asset slot constraints

- Hat mesh attaches to follower Body via `WeldConstraint(Body, Hat)` per `design/characters/follower.md` §2 — must have a clear neck/head anchor pivot at `Vector3.new(0, 0, 0)` of the hat MeshPart
- Hat color is skin-defined (NOT hue-tinted) per `design/characters/follower.md` §4 — texture color is what ships
- Hat must read at LOD 0 (close-camera 0-20m) only; hidden at LOD 1+ per `design/gdd/follower-entity.md` LOD spec — design accordingly (don't waste detail on far-distance viewing that won't happen)
- All 40 skin-on-hue combinations (5 skins × 8 hues) must read distinctly at arena-overview distance per `design/characters/follower.md` §OQ-4

---

## 4. Mesh category specs

### 4.1 Character meshes (`AssetId.Mesh.Char*`)

See `design/characters/` for full per-character profiles. Summary:

| Slot | Tri budget (LOD 0) | Tri budget (LOD 1) | Texture | Profile doc |
|------|---------------------|---------------------|---------|-------------|
| `CharFollowerBody` | 400 | 100 | 256×256 albedo + optional 256×256 normal | `design/characters/follower.md` §6 |
| `CharFollowerHat` | 150 | (LOD 1 invisible) | 128×128 albedo per skin (Skin System owns) | `design/characters/follower.md` §6 |
| `CharPlayerAvatar` | 600 | (no LOD 1 — avatar is always close-camera) | 512×512 albedo + optional 256×256 normal | `design/characters/player-avatar.md` §6 |
| `CharNpcNeutral` | 300 | (no LOD 1 — defer until Integration sprint perf pressure) | 256×256 albedo | `design/characters/npc-neutral.md` §6 |

### 4.2 Prop meshes (`AssetId.Mesh.Prop*`)

3 reserved slots — chest system per `design/gdd/chest-system.md`.

| Slot | Visual direction | Tri budget | Texture | Production sprint |
|------|------------------|-----------|---------|-------------------|
| `PropChestT1` | Treasure chest baseline — wooden/cardboard shipping crate aesthetic; opens with hinged lid animation | 250 tri | 256×256 albedo | Sprint 2 (Vertical Slice MVP) |
| `PropChestT2Car` | T2 chest is a stylized car (taxi/sedan); player-readable as "vehicle = bigger reward" per Chest GDD §C.T2 | 800 tri | 512×512 albedo + 256×256 normal optional | Sprint 2 (Vertical Slice MVP) |
| `PropChestT3Building` | T3 chest is a small-scale stylized building — Alpha-tier reward; gameplay deferred to Alpha milestone | 1500 tri | 1024×1024 albedo | Sprint 5+ (Alpha) |

### Prop asset constraints

- All chests are `Anchored = true`; static placement in arena per Chest System GDD spawn-point tagging
- Hinged-lid animation (T1) and door-open animation (T2 car / T3 building) handled via `TweenService` from `ChestStateChanged` remote per `design/gdd/chest-system.md` §C 7-state machine
- ProximityPrompt billboard attached at Body pivot — distance + interaction radius per Chest GDD `CHEST_PROMPT_DISTANCE`
- T3 building chest is **bigger triangle budget** because it's a one-off Alpha-tier reward; the visual scale must communicate "epic loot" per Pillar 1 dopamine-on-rare-reward
- Chest tier silhouettes must be distinct from each other AND from other arena props (per `design/accessibility-requirements.md` §Color-as-Only-Indicator — tier signal cannot rely on color alone)

### 4.3 Environment meshes (`AssetId.Mesh.Env*`)

4 reserved slots — arena geometry per (TBD) level-design epic.

| Slot | Visual direction | Tri budget | Texture | Production sprint |
|------|------------------|-----------|---------|-------------------|
| `EnvBuildingBlockA` | Tileable city-block-style building — per `art-bible.md §8.4` neon-rooftop policy permits saturated accents | 1200 tri (modular) | 1024×1024 albedo (atlas-shared with `EnvBuildingBlockB`) | Sprint 4 (final art); Sprint 2 = greybox |
| `EnvBuildingBlockB` | Second variant for arena variety — alley building / shopfront / etc. | 1200 tri | 1024×1024 albedo (atlas-shared) | Sprint 4; Sprint 2 = greybox |
| `EnvFloor` | Tileable street/plaza floor — neutral palette so crowds read against it | 50 tri (large flat plane) | 512×512 albedo (tiling) | Sprint 4; Sprint 2 = greybox |
| `EnvBoundaryWall` | Arena edge marker — visually distinct from buildings to communicate "you cannot go past this" | 200 tri | 256×256 albedo | Sprint 2 (Vertical Slice — placeholder OK) |

### Environment asset constraints

- All env meshes have `CanCollide = true` and use the `EnvCollisionGroup` collision group (per `ANATOMY.md §11`); `EnvBoundaryWall` collides with player avatars to keep them in-arena
- Environment palette is intentionally LOW-saturation per `art-bible.md §8.4` — crowds are the focal point, environment is the stage
- `EnvFloor` color must NOT be in the 8-color hue palette (avoid visual confusion with crowds) per `design/characters/npc-neutral.md` §4 same-rule rationale
- Greybox versions (Sprint 2) are functionally complete — final art (Sprint 4) is a non-blocking visual upgrade

---

## 5. Particle category specs (`AssetId.Particle.*`)

12 reserved slots — VFX Manager GDD §V/A canonical inventory. All particle effects use Roblox `ParticleEmitter` instances with `Texture` property set to the asset slot.

| Slot | Effect | Particle texture budget | Lifetime | Particle count peak | Photosensitivity audit | Production sprint |
|------|--------|------------------------|----------|---------------------|----------------------|-------------------|
| `AbsorbSnap` | Single-frame burst on follower spawn from absorb | 64×64 albedo | 0.3s | 12 | Tier 3 (60+/min frequency) — reduction toggle ON drops to 6 particles | Sprint 2 |
| `CollisionContactRing` | Ring on crowd-vs-crowd contact | 128×128 albedo | 0.5s | 24 | Tier 1 | Sprint 3 |
| `ChestPeelMarch` | Linear stream during peel transit | 64×64 albedo | 1.0s (per follower transit) | 8 per peeling follower | Tier 1 — informational only | Sprint 3 |
| `ChestOpenT1Confetti` | T1 chest open burst | 32×32 albedo (4-color set) | 1.5s | 60 (already capped per Absorb GDD §V/A) | Tier 2 | Sprint 2 |
| `ChestOpenT2Confetti` | T2 chest open (rare) | 32×32 albedo (4-color set) | 2.0s | 80 | Tier 3 — photosensitivity reduction toggle drops particle count by 50% | Sprint 3 |
| `ChestDraftOpen` | Draft modal open VFX | 64×64 albedo | 0.4s | 16 | Tier 1 | Sprint 3 |
| `RelicGrantCommon` | Common-rarity relic VFX (1-star) | 64×64 albedo (cool palette) | 0.8s | 20 | Tier 1 | Sprint 2 |
| `RelicGrantRare` | Rare-rarity relic VFX (2-star) | 64×64 albedo (warm palette + sparkle) | 1.2s | 40 | Tier 2 | Sprint 3 |
| `RelicGrantEpic` | Epic-rarity relic VFX (3-star) | 128×128 albedo + emissive 64×64 | 1.5s | 60 | Tier 3 — brief flash on grant; reduction-toggle caps amplitude 0.4 | Sprint 3 |
| `RelicExpire` | Relic timer-out VFX | 64×64 albedo | 0.6s | 16 | Tier 1 | Sprint 3 |
| `PeelVanish` | Single-frame poof on follower despawn from peel | 32×32 albedo | 0.3s | 8 | Tier 1 | Sprint 3 |
| `MaxCrowdFlash` | Full-screen white flash on count-cap-clamp | 256×256 albedo (overlay sprite) | 0.15s | 1 (full-screen) | **Tier 3 critical** — Harding FPA audit required; reduction-toggle caps amplitude at 0.5 | Sprint 2 |

### Particle asset constraints

- Each particle texture slot has a name matching the AssetId key
- Texture sizes optimize for batched-emit cost per `design/gdd/vfx-manager.md` §C
- Photosensitivity audit per `design/accessibility-requirements.md` §Per-VFX Photosensitivity Audit — every particle effect documented with Tier 1 / 2 / 3 photosensitivity-reduction-toggle behavior
- Particle textures live in Studio Asset Manager — single texture per slot (no sprite atlases in MVP)

---

## 6. Sound category specs (`AssetId.Sound.*`)

10 reserved slots — `*Cue` audio cues per `design/gdd/game-concept.md` Pillar 1 audio inventory.

| Slot | Sound type | Format | Duration | Volume default | Production sprint |
|------|-----------|--------|----------|----------------|-------------------|
| `AbsorbCue` | Quick absorb confirmation tick | OGG Vorbis 44.1 kHz mono | 0.15s | 0.7 (DEFAULT_SFX_VOLUME per SoundManager) | Sprint 2 |
| `ChestOpenT1Cue` | T1 chest open SFX | OGG mono | 0.5s | 0.7 | Sprint 2 |
| `ChestOpenT2Cue` | T2 chest open (richer than T1) | OGG mono | 0.8s | 0.7 | Sprint 3 |
| `RelicGrantCommonCue` | Common relic chime (single tone) | OGG mono | 0.4s | 0.7 | Sprint 3 |
| `RelicGrantRareCue` | Rare relic chime (2 tones) | OGG mono | 0.6s | 0.7 | Sprint 3 |
| `RelicGrantEpicCue` | Epic relic chime (3 tones + stinger) | OGG stereo | 1.0s | 0.7 | Sprint 3 |
| `MatchStartCue` | Round start fanfare | OGG stereo | 1.5s | 0.5 (DEFAULT_MUSIC_VOLUME — fanfare bus) | Sprint 2 |
| `MatchEndCue` | Round end fanfare | OGG stereo | 2.0s | 0.5 | Sprint 2 |
| `EliminationCue` | Player-elimination SFX (other players hear it for opponents) | OGG mono | 0.6s | 0.7 | Sprint 2 |
| `FinalMinuteCue` | <60s remaining warning | OGG mono | 0.8s | 0.7 | Sprint 3 |

### Sound asset constraints

- All sounds live in `AssetId.Sound` registry; consumers (SoundManager + future AudioManager epic) wrap with their own Volume + Looped defaults per ADR-0011 cosmetic-only invariant
- Each sound's accessibility annotation in `design/accessibility-requirements.md` §Gameplay-Critical SFX Audit — `EliminationCue` is the only SFX requiring directional indicator (Standard-elevated requirement)
- All sound files master-tracked in `assets/audio/` (gitignored beyond first commit; LFS or external storage TBD by audio-director)
- Hearing-aid-compatibility audit: `RelicGrantEpicCue` 3-tone progression + `FinalMinuteCue` warning are the only cues with high-frequency content >4kHz; both have visual backups per accessibility doc

---

## 7. Asset upload manifest (Sprint 2 deliverable)

When Sprint 2 art production begins, create `design/art/asset-upload-manifest.md` to track:
- Artist assignment per slot
- Source-file path
- Studio upload date
- Real `rbxassetid://N` value (committed to `AssetId.luau` after upload)
- Quality verification (does it render correctly in Studio playtest)

This manifest is updated per upload per the Studio Asset Manager workflow in §2.4.

---

## 8. Open questions

| ID | Question | Owner | Deadline |
|----|----------|-------|----------|
| OQ-1 | Texture atlas vs per-asset textures — at 38 slots × N MIPs, do we exceed the 80 MB texture memory budget? Answer requires Sprint 2 measurement. Recommended: profile after Sprint 2 first uploads, atlas if needed in Sprint 3. | technical-artist + art-director | Sprint 3 |
| OQ-2 | Source-file storage — `assets/` directory; Git LFS, external bucket (S3/GCS), or in-repo committed binaries? Decision affects clone time + sync workflow. | producer + technical-director | Sprint 1 (before art production starts) |
| OQ-3 | LOD 1 mesh production for `CharFollowerBody` and `CharNpcNeutral` — Sprint 2 ship as part of Vertical Slice, or defer LOD 1 to Sprint 3 and ship VS at LOD 0 with reduced view distance? | technical-artist + game-designer | Sprint 2 (during VS build) |
| OQ-4 | Pattern-overlay encoding (per `design/accessibility-requirements.md` Standard-elevated) — texture-baked variants (8 patterns × 8 hues = 64 textures) vs runtime `Decal` overlay vs `SurfaceAppearance.ColorMap` swap. Affects `CharFollowerBody` + `CharPlayerAvatar` texture budget significantly. | technical-artist + art-director | Sprint 1 |
| OQ-5 | Audio export format — OGG Vorbis is Roblox-recommended; do we need WAV master-tracking per asset for re-export, or directly upload OGG? | audio-director | Sprint 1 |
| OQ-6 | Skin emissive material variant for `FollowerNeon` — does Roblox `SurfaceAppearance` support emissive workflow without custom shader, or do we use `BillboardGui` overlay for the LED-rim effect? | technical-artist + art-director | Sprint 2 |
