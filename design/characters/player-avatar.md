# Character Profile: Player Avatar

> **Status**: Draft (Sprint 1 Design-Lock)
> **Asset slot**: `AssetId.Mesh.CharPlayerAvatar`
> **Linked GDD**: `design/gdd/follower-entity.md` (avatar shares many followers' constraints), `design/gdd/game-concept.md` (Pillar 2 identity)
> **Linked**: `design/art/art-bible.md`, `design/accessibility-requirements.md`

## 1. Role + fantasy

The player avatar is the leader at the front of each player's crowd — the figure that the player is controlling. Visually, the avatar is the silhouette identity-signaler: across the arena, players can see "that's THE [hue] player" because the avatar is at the front of their parade.

Per `design/gdd/game-concept.md` Pillar 2 (Social Anxiety / Identity): "the rival cresting that distant rooftop gives himself away by the shimmer of his own color against the skyline." The avatar IS that shimmer. The avatar is what makes the rival recognizable from a block away.

When the player makes a move (turn, accelerate, absorb), the avatar is the visible expression of that move. The rest of the crowd follows; the avatar leads.

## 2. Rig structure

**Single-Part Roblox Avatar substitute** for MVP:

| Part | Mesh | Purpose | Constraints |
|------|------|---------|-------------|
| **Body** | Single `MeshPart`, **600 tri max** | Custom-mesh player avatar — slightly larger / more detailed than followers to read as "leader" | `Anchored = false` (player avatar IS Humanoid-driven for input parity with Roblox controls); colored by crowd hue |

**Why Humanoid-driven (vs followers' CFrame-driven)**: The player avatar is the input target. Roblox `Humanoid` provides the established cross-platform control surface (WASD / D-pad / touch joystick) without custom input-handling code. Trading off some performance for input fidelity is the right call here — the player avatar count is exactly 1 per player (8-12 per server), not the 300+/crowd of followers.

**Why 600-tri (vs follower 400)**: The avatar reads at closer camera distance and is the visual focus of "I am playing." A small detail bump above followers creates the leader-vs-pack hierarchy without breaking the family resemblance per `art-bible.md §8.4` cel-shaded silhouette discipline.

**Why no separate hat slot**: Player avatar uses `SelectedSkin` from `PlayerData` to drive its hat — same `WeldConstraint(Body, Hat)` pattern as followers. Hat mesh comes from Skin System per the chosen `OwnedSkins` entry. Functionally identical to follower hat attachment.

## 3. Proportions + silhouette

**Silhouette must read as "THIS PLAYER" from arena-overview distance.** Per Pillar 2, the player must be able to identify themselves AND identify rival leaders from far away.

| Spec | Value | Rationale |
|------|-------|-----------|
| Height | ~3.5 studs (slightly taller than follower's 3 studs) | Leader-pack hierarchy; avatar is slightly more visible |
| Width | ~2 studs (same as follower) | Same chunky civilian family — keeps visual coherence |
| Head:body | ~1:2.3 | Slightly more head-prominent than follower (1:2.5) — leader silhouette emphasis |
| Pose | Forward-leaning slight (active stance) — distinct from follower's parade-walk and NPC's drift | Reads as "moving with intent" |
| Hat slot | Yes — `WeldConstraint(Body, Hat)` driven by `PlayerData.SelectedSkin` | Same pattern as follower |
| Pattern overlay | Yes — receives crowd's pattern overlay (per `design/accessibility-requirements.md` Standard-elevated requirement) | Avatar is the most-visible per-player entity; pattern encoding here is essential for colorblind-mode identity |

## 4. Palette + color rules

**Avatar Body color = crowd's assigned hue** (same as followers):

```luau
PlayerAvatar.Body.Color = HUE_COLORS[playerCrowdHueIndex]
```

When player's crowd's hue changes (rare — only on collision peel events affecting the leader), the avatar's body color updates immediately. No separate palette rules — the avatar is part of the crowd's visual identity package.

**Hat color = `SelectedSkin`-defined**, hue-independent (same as follower hats per `design/characters/follower.md` §4).

**Pattern overlay = crowd's assigned pattern**, applied to the avatar Body MeshPart same way as to followers.

## 5. Animation hooks

### Idle / walk / run animations

Roblox `Humanoid` provides standard idle / walk / run animation states out-of-the-box. `Animator` instance under `Humanoid` plays the relevant `Animation` instances. For MVP:

- Use Roblox's default `R15` animation set as a baseline
- Override the walk animation with a slightly more "leader" cadence (faster step, slight forward lean)
- Idle animation: short cycle, subtle bob (not the comatose default)

Custom animations are an art-director-owned deliverable in Sprint 2.

### Skin / hat swap animation

When player changes `SelectedSkin` mid-match (allowed if Pillar 4 cosmetic free-swap policy ratified) or between rounds:
- 0.2s scale-down on current Hat → instant swap → 0.2s scale-up on new Hat
- No body-color change during swap (hue is unchanged by skin)

### Hue-flip animation (on collision peel that affects the leader)

If a collision peel causes the player's crowd hue to flip (rare design edge case — TBD whether possible per `design/gdd/crowd-collision-resolution.md`):
- Avatar Body color tweens 0.3s from old hue → new hue
- Hat unchanged
- Visual signals "you've been re-identified"

This edge case may not be possible in MVP — confirm with game-designer per OQ-4 below.

## 6. Asset specifications

### CharPlayerAvatar mesh

| Spec | Value |
|------|-------|
| AssetId slot | `AssetId.Mesh.CharPlayerAvatar` (placeholder `rbxassetid://0` until production upload) |
| Triangle budget | **600 tri max** |
| Texture budget | 512×512 albedo + 256×256 normal (optional) |
| UV layout | Single UV island; 0.95 padding |
| Pivot | At feet center |
| Anchored | `false` (Humanoid-driven; needs gravity for jumping / falling per Roblox controls) |
| CanCollide | `true` (default Humanoid behavior — collides with arena geometry; collision groups configured per `ANATOMY.md §11`) |
| Material | Cel-shaded per `art-bible.md §8.4` — same shader as follower for visual consistency |
| Hat attachment | `WeldConstraint(Part0=Body, Part1=HatMesh)`; HatMesh ID from `AssetId.Skin[playerData.SelectedSkin]` lookup |

### Default skin (`FollowerDefault`)

The player avatar's default-state hat (when player has just joined and `SelectedSkin = "Default"` per `DefaultPlayerData.luau`). Reserved per `AssetId.Skin.FollowerDefault`. Visual direction: simple, neutral hat that reads at arena distance — possibly a baseball cap or visor per `art-bible.md §8.4`.

### MVP cosmetic skin slate (per Skin epic — story 001)

Per `AssetId.Skin.*` reserved entries (5 cosmetic-shop slots):
- `FollowerDefault` — starting skin (free)
- `FollowerCity1` / `FollowerCity2` — urban-themed cosmetics
- `FollowerNeon` — neon-pop cosmetic (per `art-bible.md §8.4` Neon-permit policy — saturated palette flex)
- `FollowerEvent1` — first event/seasonal skin

Each skin's hat mesh has its own AssetId slot (Skin System owns); each must read as a distinct silhouette from arena-overview distance. Cosmetic items unlock via Coins or Robux dev products per ADR-0011 §Currency Authority.

## 7. Edge cases

- **Player's `SelectedSkin` not in `OwnedSkins`** (theoretically impossible — server validates ownership before allowing skin equip per `design/gdd/follower-entity.md` skin-equip flow): avatar falls back to `FollowerDefault` hat. Server logs a `[PlayerAvatar]` warning. Client receives `PlayerDataUpdated` with corrected `SelectedSkin = "Default"`.
- **Player avatar and follower visually identical**: avoid by making the avatar slightly taller + slight forward-lean pose. Confirm distinction at 30m / 60m / 90m camera distance during VS playtest.
- **Player joins mid-round** (per `design/gdd/match-state-machine.md` ParticipationFlag): avatar spawns at server-designated spawn point with default skin; player can swap skin via main-menu or pause-menu Settings → Equip flow.
- **Player AFK**: per `design/gdd/match-state-machine.md` AFKToggle, server marks player Away. Avatar still rendered (does NOT despawn) — followers remain following but the avatar doesn't move. Visual: avatar idle-animates in place; followers cluster around. Could be confused for "player is here but stationary by choice" — see Pause-Menu UX `design/ux/pause-menu.md` §AFKToggle for fuller treatment.
- **Player eliminated** (CSM state=3): avatar receives same desaturation visual as crowd; eliminated overlay text on player nameplate per Player Nameplate GDD.

## 8. Open questions

| ID | Question | Owner | Deadline |
|----|----------|-------|----------|
| OQ-1 | Custom animation pack vs Roblox default R15 — is Sprint 2 art capacity available for custom walk / idle / run / jump animations, or do we ship with default Roblox animations and custom animations are post-launch? | art-director + producer | Sprint 1 |
| OQ-2 | The 0.5-stud height difference between player (3.5) and follower (3) — does it read as "leader" at 60m camera distance, or is it imperceptible? Need VS playtest verification. Alternative: 4-stud avatar height (more clearly leader). | ux-designer + game-designer | Sprint 2 (during VS playtest) |
| OQ-3 | Camera framing — is the player camera always centered on the avatar (third-person follow), or does it lift up over the crowd at high follower counts to keep the parade in frame? Default Roblox camera vs custom. | game-designer | Sprint 2 |
| OQ-4 | Is leader-side hue-flip on collision peel actually possible in MVP design, or is the leader's crowd hue invariant for the round? Affects whether §5 hue-flip animation is needed. | game-designer | Sprint 1 |
| OQ-5 | First-launch FTUE — does the avatar have a brief "name input" or "skin pick" overlay before VisibleNormal, or does the player drop into match with default skin? Per `design/ux/main-menu.md` §FTUE-interaction, FTUE overlays main menu — needs clarity on whether avatar customization is part of FTUE or a separate flow. | ux-designer + producer | Sprint 1 |
