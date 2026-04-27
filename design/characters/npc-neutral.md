# Character Profile: Neutral NPC

> **Status**: Draft (Sprint 1 Design-Lock)
> **Asset slot**: `AssetId.Mesh.CharNpcNeutral`
> **Linked GDD**: `design/gdd/npc-spawner.md`
> **Linked**: `design/art/art-bible.md`, `design/gdd/follower-entity.md`, `design/gdd/game-concept.md`

## 1. Role + fantasy

The neutral NPC is the unaffiliated civilian wandering the arena, oblivious to the territorial war happening around them, available to be absorbed into any crowd that brushes past. They are the supply pool of Pillar 1 dopamine — without them, the absorb mechanic has nothing to absorb.

Per `design/gdd/game-concept.md` Pillar 1 source ("the oblivious drifter"): the neutral NPC's defining characteristic is that they DO NOT BELONG to anyone yet. They are pre-conversion. They are anonymous. They are a person waiting to be claimed.

When a player's crowd touches a neutral NPC:
1. NPC despawns at its current position
2. A new follower spawns in the player's crowd
3. Per Follower Entity §SlideIn — the new follower is white (`Color3.new(1,1,1)`) for exactly 1 frame, then transitions to the player's crowd hue

This is the conversion moment Pillar 1 is built around. The visual transformation from "anonymous wandering NPC" to "your colored follower" is the dopamine hit. The NPC's design must support that transformation by being VISUALLY CONSPICUOUSLY UNCLAIMED before it happens.

## 2. Rig structure

**Single-Part rig** — simpler than follower because NPCs are throwaway entities:

| Part | Mesh | Purpose | Constraints |
|------|------|---------|-------------|
| **Body** | Single `MeshPart`, **300 tri max** | Torso + head + merged limbs pre-baked into one mesh | `Anchored = true`; receives no hue tint (always neutral); CFrame-driven by `NpcSpawner` per `design/gdd/npc-spawner.md` |

**Why no Hat**: NPCs are pre-conversion. Hats are identity signals. NPCs have no identity. Per `design/gdd/game-concept.md` Pillar 1 fantasy "oblivious drifter" — NPCs are deliberately anonymous and silhouette-distinct from claimed followers.

**Why 300-tri (vs follower 400)**: NPCs do not carry the cosmetic-shop layer (no hat). Lower triangle budget allows more NPCs on screen simultaneously per `design/gdd/npc-spawner.md` performance budget.

## 3. Proportions + silhouette

**Silhouette must read as "civilian, not crowd member"** — visually distinct enough that a player's eye can track NPCs separately from existing crowds.

| Spec | Value | Rationale |
|------|-------|-----------|
| Height | ~3 studs (same as follower — same ground-truth body proportions) | When absorbed, the silhouette transition is hue + hat only; height should match to avoid visual jump |
| Width | ~2 studs | Same chunky civilian proportion as follower |
| Head:body | ~1:2.5 | Same as follower for cel-shaded readability |
| Pose | Neutral standing or shuffling — slightly different from follower's parade-pose to read as "wandering, not following" | Distinguishes NPCs from followers at distance |
| **No hat slot** | Confirmed | Single-mesh; no `WeldConstraint` for hat attachment |

## 4. Palette + color rules

**NPCs are visually NEUTRAL — always**:

```luau
NpcBody.Color = Color3.fromRGB(220, 215, 210)  -- warm-neutral grey/cream
```

The exact RGB is owned by art-director — likely a slightly warm off-white that:
1. Is clearly NOT in the 8-color hue palette (so it cannot be confused for a faraway claimed crowd)
2. Reads from arena-overview distance as "background figure" — present but not territorially significant
3. Provides high contrast for the white-frame Spawning:SlideIn transition (white = transition state, neutral-cream = unclaimed steady state)

**No pattern overlay** on NPCs — pattern is reserved for crowd identity signaling (per `design/accessibility-requirements.md` Standard-elevated requirement). NPCs are deliberately non-identifying.

## 5. Animation hooks

### Idle wander animation

Per `design/gdd/npc-spawner.md`: NPCs have a slow random-walk pattern within a bounded arena radius. CFrame-driven by `NpcSpawner` server-side; client-side procedural walk-bob is similar to follower (`Body.CFrame = ... * sin(...)` pattern).

NPC walk speed and bob amplitude SHOULD be visibly different from follower walk speed/bob — gives the player a subconscious cue about which entities are "available to absorb" vs "already claimed."

Suggested values (final tuning by game-designer in `npc-spawner.md` §Tuning Knobs):
- NPC walk speed: ~30% of follower walk speed (slow drift, not energetic parade)
- NPC bob amplitude: ~50% of follower (subtler bob — they're not excited)

### Despawn animation (on absorb)

When a crowd touches an NPC:
- NPC `:Destroy()` immediately (or returned to pool if NpcSpawner uses pooling)
- Single-frame puff particle at NPC last-known position via `AssetId.Particle.AbsorbSnap`
- Audio cue `AssetId.Sound.AbsorbCue`
- Follower `Spawning:SlideIn` triggered at NPC position (per Follower Entity §SlideIn)

The visual transition is **explicitly ordered**: NPC despawns first, then follower spawns. There is no overlap frame where both exist — the conversion is discrete.

### Spawn animation (on round start / NPC pool refresh)

NPCs FadeIn from invisible to full opacity over ~0.5s when spawned by `NpcSpawner`. No white-state frame (white-state is reserved for follower SlideIn).

## 6. Asset specifications

### CharNpcNeutral mesh

| Spec | Value |
|------|-------|
| AssetId slot | `AssetId.Mesh.CharNpcNeutral` (placeholder `rbxassetid://0` until production upload) |
| Triangle budget | **300 tri max** |
| Texture budget | 256×256 albedo single-material |
| UV layout | Single UV island; 0.95 padding |
| Pivot | At feet center |
| Anchored | `true` (server-CFrame-driven; gravity forbidden) |
| CanCollide | `false` (NPCs do not collide with world; collide only with crowd-touch detection per Absorb GDD) |
| Material | Cel-shaded per `art-bible.md §8.4` — same shader as follower for visual consistency, neutral palette only |

**One mesh shipped**. No LOD variants — NPCs are arena-pool-budgeted (max 200 active per round per `design/gdd/npc-spawner.md`) and don't need distance LOD because they're scattered, not flocked. If performance pressure emerges in MVP-Integration sprint, add LOD 1 (~100 tri) at 30m distance.

## 7. Edge cases

- **NPC absorbed mid-`FadeIn`**: cancel FadeIn, despawn immediately; spawn follower with SlideIn at the same position. No visual artifact.
- **NPC pool exhausted**: per `design/gdd/npc-spawner.md`, server caps active NPCs at 200; new spawns wait for pool slot. Visual: arena gets sparse if all NPCs claimed and respawn timer hasn't hit. Pillar 5 grace-window ensures absorbed players can rebuild.
- **NPC walks outside arena bounds**: `EnvBoundaryWall` collision groups + server-side bounds check teleports the NPC back inside. Visual: should never be observable (boundary walls are the arena edge).
- **Server crash during NPC respawn**: NPCs reset to baseline pool count on next round per Pillar 3 clean-state-wipe (T9 destroyAll → clearAll). No persistence; no concern.

## 8. Open questions

| ID | Question | Owner | Deadline |
|----|----------|-------|----------|
| OQ-1 | Final neutral color RGB — art-director ratification needed. Currently `(220, 215, 210)` warm-neutral cream is a placeholder. Must (a) be visibly outside hue palette, (b) read distinctly from arena background, (c) work in all colorblind modes. | art-director | Sprint 2 |
| OQ-2 | Does NPC have a face or features at all (eyes, mouth) at the cel-shaded simplified style of `art-bible.md §8.4`? Or are they featureless silhouettes? | art-director | Sprint 2 |
| OQ-3 | LOD 1 simplified mesh — needed for MVP, or defer until performance pressure observed in Integration sprint? Recommended: defer; ship MVP single-LOD. | game-designer + technical-artist | Sprint 2 |
| OQ-4 | NPC reaction to nearby crowd — do they animate any "noticing" or "fleeing" or "drifting toward" behavior? Currently spec says oblivious; per Pillar 1 fantasy "oblivious drifter" suggests no reaction. Confirm. | game-designer + creative-director | Sprint 1 |
