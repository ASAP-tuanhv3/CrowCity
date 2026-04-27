# Crowdsmith Character Index

> **Status**: Draft (Sprint 1 Design-Lock)
> **Last Updated**: 2026-04-27
> **Linked**: `design/art/art-bible.md`, `design/gdd/follower-entity.md`, `design/gdd/npc-spawner.md`, `design/gdd/game-concept.md`, `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau`

This directory holds visual profiles for every character entity in Crowdsmith. Each profile defines proportions, palette assignments, animation hooks, asset slot mappings, and silhouette direction so artists can produce production-ready meshes that fit the technical constraints of Roblox + ADR-0001 (Crowd Replication Strategy).

## Character Roster

| Character | Role | Mesh Slots | Profile |
|-----------|------|------------|---------|
| **Follower** | The cheerful civilians that make up every crowd. The visible representation of "your snowball." | `AssetId.Mesh.CharFollowerBody`, `AssetId.Mesh.CharFollowerHat` | [follower.md](follower.md) |
| **Neutral NPC** | The unaffiliated civilians wandering the arena, waiting to be absorbed into a crowd. | `AssetId.Mesh.CharNpcNeutral` | [npc-neutral.md](npc-neutral.md) |
| **Player Avatar** | The leader at the front of each player's crowd — the silhouette identity-signaling who's playing. | `AssetId.Mesh.CharPlayerAvatar` | [player-avatar.md](player-avatar.md) |

## Anti-roster (out of scope MVP)

- Boss characters (no boss fights in MVP — Pillar 3 clean rounds)
- Customizable player avatar above-the-shoulders (face / hair customization is out of scope; identity comes from crowd hue + hat skin per Pillar 2)
- Pet characters / cosmetic followers (cosmetic followers are skin-only — not a separate roster entry)
- Cinematic / cutscene characters (no cutscenes in MVP)

## Cross-character invariants

These rules apply to ALL characters in the roster:

1. **Character classes** per `art-bible.md §8.8`:
   - `Char*` prefix — character meshes (followers, players, NPCs)
   - All character mesh asset names are reserved in `AssetId.Mesh` per asset-id-registry epic
2. **Roblox primitives only** — `MeshPart` instances, no Humanoid (per Follower Entity GDD §Core Rules — followers are CFrame-driven for performance)
3. **Anchored = true** on all character Parts (CFrame-driven; gravity is forbidden — would fight per-frame writes per Follower Entity GDD)
4. **Color application** — `Body.Color = Color3.fromRGB(...)` (NOT `BrickColor` — faster C++ property write per Follower Entity GDD §Hue rendering)
5. **No facial animation** — Crowdsmith reads from a distance; faces are not part of the visual surface (per `art-bible.md §8.4` cel-shaded silhouette focus)
6. **No voice lines / no spoken dialogue** in MVP — characters communicate via crowd-count visuals + audio cues only (`AssetId.Sound.*Cue`)
7. **Hue palette** — 8 colors per `HUE_PALETTE_SIZE` constant; each crowd is assigned one hue at `CrowdCreated` time + a pattern-overlay per `design/accessibility-requirements.md` (Standard tier elevated requirement)

## Character production order (Sprint 2 art deliverables)

| Priority | Character | Why this order |
|----------|-----------|----------------|
| 1 | Neutral NPC | Required first — Vertical Slice cannot demonstrate the absorb mechanic (Pillar 1 dopamine) without NPCs to absorb |
| 2 | Follower (Body + Hat) | Required for Vertical Slice — the visible crowd is the game |
| 3 | Player Avatar | Can be substituted with default Roblox avatar for VS playtests; production-ready avatar lands in Sprint 3 |
