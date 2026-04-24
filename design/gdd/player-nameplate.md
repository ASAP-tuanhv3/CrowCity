# Player Nameplate

> **Status**: In Design (2026-04-24 consistency-check sync — 3 stale "CSM amendment required" flags for `CrowdCreated` signal cleared; CSM Batch 1 LANDED the signal as reliable RemoteEvent with payload `{crowdId, hue, initialCount}`. Polling fallback no longer needed.)
> **Author**: user + game-designer + ux-designer + ui-programmer + art-director
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine) via rival identification at glance + 4 (Cosmetic Expression) via hue-broadcast identity

## Overview

The **Player Nameplate** is the diegetic world-space `BillboardGui` floating above every character (local player + rivals + neutral NPCs with no nameplate — neutrals are nameless). Each nameplate displays the owning player's crowd count + signature-hue-tinted text, rendered with a double-outline (2px white outer + 1px black inner per art bible §7) for legibility over light and dark arena surfaces. Vertical offset scales with crowd size — 1.0× at count 1-50, 1.5× at 51-150, 2.5× at 151+ — so the nameplate always clears the follower silhouette regardless of crowd density. Font weight bumps one step at 151+ to maintain readability at distance. Nameplate is a per-character client-side attachment: on `PlayerAdded → CharacterAdded`, a `NameplateComponent` is created and parented to the character's primary part; the component subscribes to `CrowdStateClient.CountChanged(crowdId)` and updates the `TextLabel` in place. Fade to 0 on `CrowdEliminated`; hide completely during `Lobby` state (pre-round); `MaxDistance` cull at 120 studs (arena diagonal worst-case) for mobile performance.

For the player, the nameplate is the one piece of UI that turns a faceless crowd into a decision. When you see a rival mob cresting a plaza you don't count their followers — you read their nameplate: **187**. Your own count is **142**. Three moves happen in one glance: *am I bigger, can I catch them, can I escape?* The hue-tint above their heads says who they are (your signature pink vs their signature cyan), the count says how dangerous they are, the offset height tells you the same thing visually from distance even before the number resolves. This is Pillar 1 made spatial — the dopamine of *my crowd bigger* is only possible because the nameplate lets you read the comparison without opening a menu, without a minimap, without a targeting reticle. Approach is the verb (per Chest fantasy); nameplate is how you decide what to approach.

**Scope (MVP)**: per-player nameplate with count + hue + double-outline + offset scaling per art bible §7. No player names in MVP (Roblox DisplayName can be added in VS for social identity — deferred). No guild tags, no level badges, no achievements — pure signal: who + count.

## Player Fantasy

They're not players. They're numbers with a color, walking.

The arena has no leaderboard for rivals — only heads. Every enemy crowd is a walking stat block broadcasting exactly what it is. A rising tower of tinted text says *I'm bigger than you now.* A short, steady plate says *come try me.* Across the plaza, their nameplate is already in your field of view before their crowd renders in full — the count, the hue, the height above the mob's silhouette. You don't check a menu. You don't open a scoreboard. You look up. Bigger than you — flee. Smaller — chase. Close enough to gamble — approach. The decision is read, not calculated.

The nameplate is the line between silhouette and rival. Neutrals are nameless — just drifting white shapes you sweep up. The moment a mob wears a plate, it has a name that matters: *this is a player, this is their weight, this is their color*. Double-outline for legibility against any city surface, hue-tint for Pillar 4 identity broadcast (their signature color says *who* they are with the same pop as your own), vertical offset climbing as their count climbs so you read the silhouette before the digits. Every rival you ever face in this game, you will face them through this nameplate first. It is the one piece of UI that makes the other eleven crowds on the server into opponents instead of decor.

## Detailed Design

### Core Rules

**1. Nameplate Lifecycle — Per-Character Component.** On `Players.PlayerAdded` client-side hook, subscribe to the new player's `CharacterAdded` signal. On each `CharacterAdded`: create a `NameplateComponent` parented to the character's `HumanoidRootPart` (or equivalent primary part if humanoid-less — see NPC Spawner CFrame rig pattern). On `CharacterRemoving` / `PlayerRemoving`: `NameplateComponent:destroy()` via Janitor.

**2. BillboardGui Configuration.** Each nameplate is a `BillboardGui` with:
- `Adornee = character.HumanoidRootPart`
- `StudsOffsetWorldSpace = Vector3.new(0, vertical_offset, 0)` (see F1 offset formula)
- `Size = UDim2.fromOffset(200, 50)` at base; scales with offset tier
- `AlwaysOnTop = false` (occludable by walls for spatial read)
- `LightInfluence = 0` (flat-design per art bible §7; not shaded by environment)
- `MaxDistance = NAMEPLATE_MAX_DISTANCE = 120` studs (arena diagonal worst-case; mobile cull)

**3. Double-Outline TextLabel Structure.** Roblox `TextLabel.TextStroke*` provides single-pass outline only. Double-outline (2px white outer + 1px black inner per art bible §7) requires a `UIStroke` Instance on a primary `TextLabel` for the 1px black inner, plus a secondary `TextLabel` cloned behind with its own `UIStroke` at 2px white for the outer. Both TextLabels carry identical `Text`, `TextColor3`, `Font`. Both update in one code path on `CountChanged`.

**4. Text Content.** `TextLabel.Text = tostring(count)`. No player name in MVP. No commas in numbers ("187" not "1,87"). No suffix units. Eliminated crowd shows `"0"` during fade-out (see Rule 11).

**5. Hue Tint.** `TextLabel.TextColor3` reads from `CrowdStateClient.get(crowdId).hue` — the safe-palette color assigned via `hue_index_assignment` formula per CSM. On `CountChanged` event receipt, hue is also re-read from the same source (defensive — hue could theoretically change via future relic; re-read is cheap).

**6. Vertical Offset — Count Tier Mapping.** Per art bible §7 diegetic rules. See Formula F1. Base offset `NAMEPLATE_BASE_OFFSET_STUDS = 4.0` studs above root part. Tier multipliers: 1× for count ∈ [1, 50], 1.5× for count ∈ [51, 150], 2.5× for count ∈ [151, 300]. Tier boundaries are hard crossings (no interpolation — the visual step is the feedback channel: when a crowd's plate visibly *jumps higher*, you know they crossed a growth threshold). `StudsOffsetWorldSpace.Y` updates on `CountChanged` when tier changes; no per-frame tween.

**7. Font Weight Step.** Primary text uses `GothamBold`. At count ≥ 151 (tier 3), switch to `GothamBlack` (one step heavier per art bible §7) for distance readability. Font swap fires on tier crossing same frame as offset change.

**8. Text Size Scaling.** `TextLabel.TextScaled = false` + fixed `TextSize`. Base `NAMEPLATE_TEXT_SIZE = 28pt` per art bible §7 "round-state ≥28pt". Same across all tiers — legibility is provided by offset + font-weight, not size thrashing.

**9. Hide During Non-Active States.** Nameplate `.Enabled = false` when Match State != `Active` AND != `Result`. Specifically hidden in Lobby, Countdown:Ready, Countdown:Snap (no round yet — nothing to size up), Intermission, ServerClosing. Result state shows nameplate at last-known count (frozen; result screen renders placements separately).

**10. Self-Nameplate Visibility.** Local player's own nameplate visible on-camera only in third-person perspective (default Roblox camera). In first-person / shoulder views (future), hide own nameplate to avoid self-occlusion. For MVP third-person default: always visible.

**11. Eliminated Crowd Fade-Out.** On `CrowdEliminated` signal for any crowd: nameplate opacity tweens (`TextTransparency` 0 → 1) over `NAMEPLATE_ELIM_FADE_SEC = 1.5` seconds, parallel to `UIStroke.Transparency` tween. After tween, `.Enabled = false`. Nameplate stays destroyed until next round's `createAll`. Does not re-appear on revive (no MVP revive).

**12. Stale-Data Handling.** If `CrowdStateClient.get(crowdId)` reports broadcast staleness > `STALE_THRESHOLD_SEC = 0.5` (CSM registry), nameplate freezes at last-known count + hue. No interpolation to 0. No "?" placeholder. No error. (Matches HUD widget stale-data rule for consistency.)

**13. MaxDistance Cull.** `BillboardGui.MaxDistance = 120` studs. Beyond 120 studs, Roblox renders no BillboardGui. Arena diagonal worst-case ≈ 90 studs (`sqrt(ARENA_WALKABLE_AREA_SQ = 4000)` approx); 120-stud cull provides 30-stud margin.

**14. No Server-Side Counterpart.** Nameplate is 100% client-side. Server never creates, never fires nameplate-specific remotes. State comes from existing `CrowdStateBroadcast`. No additional bandwidth cost.

**15. Frame Budget.** Nameplate processing target: `< 0.2 ms per RenderStepped` across all 12 nameplates combined (static BillboardGuis; Roblox renders natively; only `CountChanged` triggers update code). Verified via MicroProfiler.

### States and Transitions

Each `NameplateComponent` is a simple state machine bound to its character's lifecycle + the owning crowd's state.

| State | Description |
|---|---|
| `Uncreated` | Pre-component; character hasn't spawned yet. No BillboardGui exists. |
| `Hidden` | BillboardGui created, `.Enabled = false`. Owning crowd in non-Active match state, or owner is spectator pre-crowd. |
| `Visible` | `.Enabled = true`, rendering count + hue. Normal Active state. |
| `Fading` | Eliminated transition in progress; opacity tweening 0→1 over 1.5s. |
| `Destroyed` | Component destroyed via Janitor on CharacterRemoving / PlayerRemoving / roundEnd. No BillboardGui exists. |

| # | From | To | Trigger | Owner |
|---|---|---|---|---|
| T1 | `Uncreated` | `Hidden` | `CharacterAdded` fires; component constructs BillboardGui | NameplateComponent |
| T2 | `Hidden` | `Visible` | `MatchStateChanged → Active` AND CSM reports crowd exists | NameplateComponent listener |
| T3 | `Visible` | `Hidden` | `MatchStateChanged → Lobby/Countdown/Intermission/ServerClosing` | NameplateComponent |
| T4 | `Visible` | `Visible` | `CountChanged` or `HueChanged` fires; update text + offset + font | NameplateComponent (no state change — data refresh) |
| T5 | `Visible` | `Fading` | `CrowdEliminated` signal for owning crowdId | NameplateComponent |
| T6 | `Fading` | `Hidden` | 1.5s fade complete | NameplateComponent (deferred task) |
| T7 | any | `Destroyed` | `CharacterRemoving` / `PlayerRemoving` / round-end | Janitor in component |

**Invariants:**
- One `NameplateComponent` per character at all times. No double-component; no orphaned BillboardGui.
- `Visible → Fading` is irreversible within a round (no revive).
- `Hidden` can be entered from `Visible` or `Fading` on MatchStateChanged; `Visible` re-entered only via new `Active` state (next round).
- `Destroyed` is terminal per component instance; new component created on next `CharacterAdded`.
- BillboardGui always parented to `Adornee` at construction; never reparented.

### Interactions with Other Systems

**Binding contracts:**

| Field | Source | Update trigger |
|---|---|---|
| `TextLabel.Text` | `CrowdStateClient.get(crowdId).count` | `CountChanged` signal |
| `TextLabel.TextColor3` | `CrowdStateClient.get(crowdId).hue` via `hue_index_assignment` formula | Set at T2 entry + re-read on `CountChanged` defensively |
| `StudsOffsetWorldSpace.Y` | F1 `vertical_offset = base × tier_mult(count)` | `CountChanged` when tier crosses boundary |
| `TextLabel.Font` | F2 `font_weight(count)` — GothamBold or GothamBlack | `CountChanged` when count crosses 150/151 boundary |
| `BillboardGui.Enabled` | Match State + eliminated flag | `MatchStateChanged` + `CrowdEliminated` |

**Integration contracts (one-line each):**

- **Crowd State Manager** — client read-only: `CrowdStateClient.get(crowdId)` for `{count, hue}`; `CountChanged(crowdId)` signal subscription; `CrowdEliminated(crowdId)` signal. Zero server-side work.
- **Match State Machine** — client read-only: `MatchStateClient.get()` + `MatchStateChanged` reliable remote for visibility gating.
- **Character / CharacterSpawner (template)** — nameplate attaches on `CharacterAdded`; destroys on `CharacterRemoving`. No modification required to `CharacterSpawner` beyond existing template behavior.
- **HUD** — no direct interaction. HUD owns its own ScreenGui; nameplate is BillboardGui. No shared state, no shared code path.
- **NPC Spawner** — NPC Parts never receive a nameplate (neutrals nameless per fantasy). `NameplateComponent` skips construction for Parts without an associated player/`Player` object.
- **Follower Entity** — follower-entity Parts never receive a nameplate (they are the mob, not the leader). Nameplate attaches only to player characters (the one character each player controls).
- **Art Bible §7** — binding: 2px white outer + 1px black inner outline; vertical offset scaling tiers 1×/1.5×/2.5× at count 1-50/51-150/151+; font-weight step at 151+; GothamBold baseline; ≥28pt round-state.
- **ADR-0001 Crowd Replication** — inherits `SERVER_TICK_HZ = 15` cadence via CSM broadcast; `STALE_THRESHOLD_SEC = 0.5` for freeze-last-known.
- **Skin System** (VS) — no direct dependency. Skin affects follower body + hat; player character nameplate continues reading `hue` from CSM independently. Skin changes do NOT re-hue the nameplate beyond the CSM-broadcast hue.
- **Spectator Mode** (future) — spectator's own character has no crowd in CSM; component detects `CrowdStateClient.get(crowdId) == nil` and enters `Hidden` state permanently until crowd exists.

**Cross-system facts introduced** (candidates for registry):
- `NAMEPLATE_BASE_OFFSET_STUDS = 4.0`
- `NAMEPLATE_MAX_DISTANCE = 120`
- `NAMEPLATE_ELIM_FADE_SEC = 1.5`
- `NAMEPLATE_TEXT_SIZE = 28`
- `NAMEPLATE_OUTER_OUTLINE_PX = 2`
- `NAMEPLATE_INNER_OUTLINE_PX = 1`

## Formulas

Two formulas govern nameplate visual scaling per count.

### F1. `nameplate_vertical_offset`

Step function mapping crowd count to vertical offset (art bible §7 tiers).

`vertical_offset = NAMEPLATE_BASE_OFFSET_STUDS × tier_mult(count)`

Where:
```
tier_mult(count) =
    1.0   if count ∈ [1, 50]
    1.5   if count ∈ [51, 150]
    2.5   if count ∈ [151, 300]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `count` | `n` | int | [1, 300] | Crowd count from CSM |
| `NAMEPLATE_BASE_OFFSET_STUDS` | `B` | float | 4.0 | Base studs above root part |
| `tier_mult` | — | float | {1.0, 1.5, 2.5} | Count-tier multiplier |
| `vertical_offset` | — | float | {4.0, 6.0, 10.0} | `StudsOffsetWorldSpace.Y` value |

**Output range:** `vertical_offset ∈ {4.0, 6.0, 10.0}` studs — discrete, three values only.

**Example:**
- `count=10` → `1.0 × 4.0 = 4.0` studs (standard)
- `count=50` → `1.0 × 4.0 = 4.0` studs (upper boundary tier 1)
- `count=51` → `1.5 × 4.0 = 6.0` studs (jumps — visible step feedback)
- `count=150` → `1.5 × 4.0 = 6.0` studs (upper boundary tier 2)
- `count=151` → `2.5 × 4.0 = 10.0` studs (jumps — visible step feedback)
- `count=300` → `2.5 × 4.0 = 10.0` studs (max)

**Edge behavior:** Step function intentional — visible "jump" at tier crossing communicates growth threshold. Smooth interpolation would hide the feedback beat. See §Edge Cases for tier-boundary hysteresis (flickering at count oscillating 50↔51).

### F2. `nameplate_font_weight`

Step function mapping count to font for distance legibility.

`font_weight(count) = GothamBold if count <= 150 else GothamBlack`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `count` | `n` | int | [1, 300] | Crowd count from CSM |
| `font_weight` | — | enum | {GothamBold, GothamBlack} | Font family name |

**Output:** Binary switch at count=150/151 boundary (same boundary as F1 tier 2→3). Font swap fires same frame as offset jump for unified visual step.

**Example:**
- `count=150` → `GothamBold`
- `count=151` → `GothamBlack` + offset 6.0 → 10.0 studs (compound tier-3 feedback)

### Non-formulas — explicit reference

| Math | Owner | Why not here |
|---|---|---|
| `hue_index_assignment` | CSM registry | Nameplate reads resolved hue from CrowdStateClient; does not compute assignment |
| `radius_from_count`, `collision_transfer_per_tick` | CSM / CCR | Nameplate reads count only; no geometry or collision math |
| Text stroke rendering | Roblox native (`UIStroke` Instance) | Engine-provided; nameplate configures properties only |
| Billboard cull distance | Roblox native (`BillboardGui.MaxDistance`) | Engine-provided; single constant |

## Edge Cases

### Tier boundary / count oscillation

- **If count oscillates 50↔51 rapidly (collision drain + absorb recovery)**: offset + font visually flicker between tier 1 and tier 2. Introduce **hysteresis**: once count crosses upward to 51, stay in tier 2 until count drops to ≤48 (3-count buffer). Similarly 150/151 uses 148 as downward boundary. Net effect: tier visible step remains a meaningful feedback beat, not a flicker spam.
- **If count = 0 (mid-transition to Eliminated)**: nameplate enters `Fading` state per Rule 11; text shows last-known count, not "0". Fade-out masks the visual.
- **If count briefly hits 300 then clamps back via collision**: offset stays at tier-3 (max). No hysteresis at the ceiling — clamping at 300 is informative per MAX CROWD flash.

### Lifecycle / CharacterAdded races

- **If `CharacterAdded` fires before `PlayerAdded` callback registers (Roblox race)**: template `PlayerAdded → CharacterAdded` pattern handles this via deferred connection; nameplate constructs on next `CharacterAdded`.
- **If character respawns mid-round (Roblox `Humanoid.Died` → respawn)**: MVP has no player-death mechanic (movement-only game per concept anti-pillar). Defensive: on `CharacterRemoving` → `CharacterAdded` within same match state, nameplate re-attaches seamlessly. No visible hitch if `HumanoidRootPart` position carries over.
- **If `Adornee` part is destroyed externally (debug, admin, bug)**: `BillboardGui.Adornee` becomes nil; Roblox renders nothing. NameplateComponent detects via `instance:GetPropertyChangedSignal("Parent")` and enters `Destroyed`. Defensive — should not occur in normal play.

### Match State transitions

- **If `MatchStateChanged → Active` fires before any crowd created in CSM (race)**: component checks `CrowdStateClient.get(crowdId)`; if `nil`, enters `Hidden`; subscribes to CSM `CrowdCreated` signal for first-create handoff. Retries on next state-change check.
- **If `Intermission → Lobby` fires before `CrowdEliminated → Fading` tween completes**: tween cancelled by state-change handler; state jumps to `Hidden` immediately. Player doesn't see half-faded stale nameplate in Lobby.
- **If `Result` state lingers after eliminated crowd's fade completes**: nameplate remains `Hidden` through Result. Result Screen (VS GDD) owns winner reveal; nameplate doesn't dramatize.

### Replication / Broadcast

- **If `CrowdStateBroadcast` arrives with `count` missing / nil for a crowdId**: component reads `nil`; falls back to last-known value; no error. Stale-data rule applies.
- **If `CountChanged` fires but `Adornee` is 120+ studs away**: Roblox engine culls render; update code still runs (cheap — TextLabel.Text assign). No wasted frames.
- **If player joins mid-round (spectator)**: their local client receives `CrowdStateBroadcast` for all existing crowds. `PlayerAdded` loop creates nameplate components for each existing player character. All 11 rival nameplates spawn within 1 frame.

### Self-nameplate

- **If local player has no crowd (early-join spectator)**: own nameplate enters `Hidden` and stays there until next round's `CrowdCreated`. No visible "0" plate on self.
- **If local player switches perspective (first-person zoom)**: Roblox camera mode change — MVP always third-person default; no handling required. Future first-person mode: hide own nameplate via `CameraType` property check.

### Cross-system

- **If `hue_index_assignment` returns unexpected index (out-of-range)**: CSM GDD locks formula output to [1, 12]; nameplate reads resolved `hue: Color3` directly, not the index. Never sees raw index. No defense needed.
- **If CSM `STALE_THRESHOLD_SEC = 0.5` triggers mid-frame**: nameplate's next `CountChanged` subscription does not fire (no new broadcast); TextLabel stays at last value. Freeze-last-known behavior matches HUD §Core Rule 6.
- **If CrowdEliminated fires but CrowdStateClient already shows count=0 (normal case)**: Rule 11 fade kicks off; no conflict. Nameplate's internal count reads `0` briefly before tween completes.
- **If skin system (VS) changes hue mid-match (future)**: CSM broadcasts `HueChanged` signal (hypothetical — CSM GDD does not define this today). MVP scope: hue is set at `createAll` and never changes. Nameplate re-reads hue defensively on `CountChanged` to catch future-skin scenarios.

### Performance / Budget

- **If 12 players all have count crossing tier boundary same tick (Surge relic same-frame chain)**: 12 nameplate updates in one frame. Each update: TextLabel.Text assign + StudsOffsetWorldSpace vector write + Font enum swap. Cost ~0.005ms × 12 = 0.06ms. Well under 0.2ms budget.
- **If 11 rivals + self all visible on-screen (worst case)**: 12 BillboardGuis rendered simultaneously. Roblox handles natively; ~0.1ms per frame render cost. Acceptable on min-spec mobile.
- **If player camera spins rapidly (disorientation)**: BillboardGui billboards to camera natively; no nameplate-specific handling required.

### Accessibility

- **If colorblind player can't distinguish rival hue**: art bible §4 locks 12-hue safe palette pre-validated for deuteranopia + protanopia + tritanopia. Nameplate inherits via CSM `hue_index_assignment`. Shape redundancy NOT present on nameplate itself (text only); relies on palette + double-outline contrast for discrimination.
- **If UI text too small at far camera distance**: `MaxDistance = 120` culls before font becomes unreadable. Font-weight step at 151+ counters distance-based legibility loss. Verified in playtest on iPhone SE.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| UIHandler (template, ANATOMY §8) | Approved | None — nameplate is `BillboardGui` per character, NOT registered as UILayer. Parented to character, not ScreenGui. | N/A |
| Character / CharacterSpawner (template) | Approved | `Players.PlayerAdded` + `Player.CharacterAdded` + `CharacterRemoving` signals. `HumanoidRootPart` as `Adornee`. | Read-only (event subscriptions) |
| Crowd State Manager | In Review | `CrowdStateClient.get(crowdId)` for `{count, hue}`; `CountChanged(crowdId)` signal; `CrowdEliminated(crowdId)` signal | Read-only |
| Match State Machine | In Revision | `MatchStateClient.get()` + `MatchStateChanged` reliable remote for visibility gating | Read-only |
| Network Layer (template) | Approved | Consumes `CrowdStateBroadcast` + `CrowdRelicChanged` + `MatchStateChanged` remotes (already subscribed by CSM/MSM/Relic clients; nameplate reads via those clients, not remotes directly) | Indirect read |
| PlayerData / ProfileStore (template) | Approved | None — nameplate ephemeral, no persistence | N/A |
| ADR-0001 Crowd Replication | Proposed | `STALE_THRESHOLD_SEC = 0.5` for freeze-last-known; 15 Hz broadcast cadence inherited | Reused constants |
| Art Bible §7 (HUD/UI visual direction) | Approved | 2px + 1px double-outline; offset tiers 1×/1.5×/2.5× at count 1-50/51-150/151+; font-weight step at 151+; GothamBold baseline; ≥28pt | Design reference |
| Pillar 1 (Snowball Dopamine) | Approved | Nameplate is the rival-read feedback channel for sizing-up decision | Locks fantasy |
| Pillar 4 (Cosmetic Expression) | Approved | Hue broadcast identity via nameplate tint | Locks visual identity |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| HUD | Designed (pending review) | No direct interaction. Nameplate and HUD are siblings; HUD §F confirms "HUD does not render nameplates." | None |
| Spectator Mode (future component) | Not Started | Nameplate hides automatically when owner has no crowd in CSM. Spectator needs no nameplate-specific API. | Indirect |
| Skin System (VS) | Not Started | No interaction. Skin changes follower body + hat; nameplate hue is CSM-driven independently. | None |
| Chest Billboard UI | Not Started | Independent `BillboardGui` per chest (not per character). No overlap. | None |
| FTUE / Tutorial | Not Started (VS) | Tutorial may temporarily highlight own-nameplate or rival-nameplate for teaching. Nameplate exposes `NameplateComponent:setHighlight(state: bool)` API — brightens outline 2x for tutorial moments. Optional; MVP without highlight. | Write (via function call) |

### Provisional assumptions (flagged for cross-check)

1. **CSM `HueChanged` signal** — proposed hypothetical for future skin-mid-match hue changes. MVP doesn't need it (hue locked at `createAll`). Flagged here as future amendment if/when Skin System introduces mid-round hue mutation.
2. **`Players.LocalPlayer` camera default third-person** — assumed. First-person / shoulder-view future modes require own-nameplate hide rule.
3. **`UIStroke` Instance** — assumed available in Roblox Studio. Verify at prototype stage (should be; API stable since ~2022).
4. ✓ **RESOLVED 2026-04-24** via CSM Batch 1. `CrowdCreated` reliable RemoteEvent now declared in CSM §Network event contract with payload `{crowdId, hue, initialCount}`, fires from `CrowdStateServer.create()` at round start for every player. Nameplate subscribes directly; no polling fallback needed. Mid-round-join race handled natively.

### Bidirectional consistency notes

- **RESOLVES** CSM §Dependencies "Player Nameplate: `CrowdStateClient.get(crowdId).count/hue` for rival identification" — contract formalized.
- **RESOLVES** HUD §Dependencies Nameplate delegation — HUD confirmed does not render nameplates.
- ✓ **CSM GDD Batch 1 landed `CrowdCreated` signal 2026-04-24** — reliable RemoteEvent; no polling fallback needed.
- **Systems Index update**: mark Player Nameplate "Designed (pending review)"; add back-ref on CSM, Match State, HUD.

### No cross-server or persistence dependency

Nameplate is 100% client-side, round-scoped. No DataStore, no MessagingService, no server-side remote. Runs entirely from existing CSM/MSM broadcasts.

## Tuning Knobs

### Nameplate visual knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `NAMEPLATE_BASE_OFFSET_STUDS` | 4.0 | [2.0, 8.0] | F1 base offset above root part | 8+ = plate floats way above head; disconnect | <2 = plate clips into head/shoulders; hard to read | Art bible §7 lock at 4.0 default |
| `NAMEPLATE_MAX_DISTANCE` | 120 studs | [80, 200] | `BillboardGui.MaxDistance` cull | 200+ = mobile GPU burden (12 billboards drawn always) | <80 = rivals off-screen but in-play can't be sized up | `ARENA_WALKABLE_AREA_SQ` + camera FOV |
| `NAMEPLATE_ELIM_FADE_SEC` | 1.5 | [0.5, 3.0] | Eliminated fade-out duration | 3+ = lingering ghost-plate confuses Result screen | <0.5 = jarring pop-off | Match State `RESULT_DURATION_SEC = 10` (fade completes before Result ends) |
| `NAMEPLATE_TEXT_SIZE` | 28 | [20, 48] | Base TextLabel font size | 48+ = plate too big, obscures follower silhouette | <20 = unreadable at arena distance on mobile | Art bible §7 ≥28pt round-state lock |
| `NAMEPLATE_OUTER_OUTLINE_PX` | 2 | locked | Art bible §7 locked | — | — | Companion to inner outline |
| `NAMEPLATE_INNER_OUTLINE_PX` | 1 | locked | Art bible §7 locked | — | — | Companion to outer outline |
| `NAMEPLATE_TIER_HYSTERESIS` | 3 | [1, 10] | Count-buffer preventing tier flicker at boundaries (downward drops 3 below threshold before tier reverts) | 10+ = tier drop too slow, visuals out of sync | <1 = flicker returns at boundary oscillation | F1 tier thresholds (50/150) |

### Tier thresholds (art bible §7 locked — not tuning knobs)

- Tier 1 upper bound: count=50 (offset 1×, font GothamBold)
- Tier 2 upper bound: count=150 (offset 1.5×, font GothamBold)
- Tier 3 upper bound: count=300 (offset 2.5×, font GothamBlack)

### Locked constants (amendment required to change)

- `STALE_THRESHOLD_SEC = 0.5` — CSM registry; freeze-last-known behavior
- `SERVER_TICK_HZ = 15` — ADR-0001; broadcast cadence
- `MAX_CROWD_COUNT = 300` — CSM; tier 3 upper bound
- Font baseline `GothamBold` / `GothamBlack` — art bible §7
- 12-hue safe palette — art bible §4
- Double-outline spec (2px white + 1px black) — art bible §7

### Where knobs live (implementation guidance)

- Constants → `ReplicatedStorage/Source/SharedConstants/NameplateConfig.luau`
- `NameplateComponent` → `ReplicatedStorage/Source/UI/Nameplate/NameplateComponent.luau`
- Entry hook (per `Players.PlayerAdded` + `CharacterAdded`) → called from client bootstrap `ReplicatedFirst/Source/start.server.luau` post-character-load
- Prefab (BillboardGui + two stacked TextLabels + UIStrokes) → `ReplicatedStorage/Instances/GuiPrefabs/Nameplate`
- `NameplateComponent` exposes `:setHighlight(state: bool)` for FTUE hook (Rule: VS-tier addition)

## Visual/Audio Requirements

Nameplate IS a visual UI element. Spec is art-bible §7 realization.

### Visual spec (from art bible §7)

- **BillboardGui** anchored to character `HumanoidRootPart`, world-space (`SizeOffset` + `StudsOffsetWorldSpace`)
- **Double-outline**: 2px white outer (`UIStroke` on background TextLabel) + 1px black inner (`UIStroke` on foreground TextLabel). Both `Transparency = 0` while Visible.
- **Typography**:
  - Base: `GothamBold`, `TextSize = 28` (NAMEPLATE_TEXT_SIZE)
  - Tier 3 (count≥151): `GothamBlack` (font-weight +1 step)
- **Text color**: signature hue per `hue_index_assignment` — safe-palette 12 hues (art bible §4)
- **Vertical offset** per F1: 4.0 studs (tier 1) / 6.0 (tier 2) / 10.0 (tier 3)
- **Size**: `UDim2.fromOffset(200, 50)` at base
- **Cull distance**: `MaxDistance = 120` studs
- **Flat-design**: `LightInfluence = 0` (no environment shading); no drop shadows; no gradients
- **Billboard occlusion**: `AlwaysOnTop = false` — walls occlude nameplate (spatial read, not radar cheat)

### Event catalog

| Event | Fires on | Payload | Receivers |
|---|---|---|---|
| `NameplateTierStepUp` | Count crosses tier boundary upward (50→51 or 150→151) | `{crowdId, newTier}` | Audio Manager (optional tier-up chime — VS polish) |
| `NameplateFadeStart` | `CrowdEliminated` signal | `{crowdId}` | Audio Manager (optional nameplate fade SFX — redundant with Eliminated sting from HUD; may skip) |
| `NameplateHighlightSet` | `NameplateComponent:setHighlight(bool)` called (FTUE) | `{crowdId, highlighted}` | VFX Manager (optional highlight glow — VS tutorial) |

### SFX intent (mostly silent in MVP)

- **Tier step-up chime** (optional, VS polish) — subtle bump when rival plate visibly jumps higher. Could amplify sizing-up beat. Audio Director decides. MVP ships silent.
- **No per-count-change audio** — would spam at 15 Hz absorb rate. Count updates are silent (HUD count pop owns any audio payload).

### VFX intent

- **No per-frame particle emissions** — nameplate is static TextLabel + UIStroke
- **No animated tween on count update** — instant TextLabel.Text assign (art bible §7 "the snap is the moment")
- **Fade-out on eliminated**: simple `TextTransparency` + `UIStroke.Transparency` tween over 1.5s
- **Highlight (future FTUE)**: `UIStroke.Thickness` 2×2px + 1×1px → 4×4 + 2×2, or secondary glow `UIStroke.Color3` pulse. VS scope.

**Art bible §7 compliance:**
- Double-outline matches diegetic world-space rule
- Flat-design, no shaders, no gradients
- Hue-tint via 12-color safe palette (colorblind-validated)

📌 **Asset Spec** — V/A defined. Run `/asset-spec system:player-nameplate` after art bible final (simple: 1 BillboardGui prefab + 2 UIStroke configs + GothamBold/Black font refs).

## UI Requirements

Nameplate IS a UI element (diegetic world-space). Minimal additional UX spec.

### Layout

One BillboardGui per character, anchored to HumanoidRootPart. Vertical offset per F1. Billboards render always-facing-camera automatically via Roblox engine.

### Widget structure

```
BillboardGui (Adornee = HumanoidRootPart)
├── OuterLabel (TextLabel, ZIndex 0)
│   └── UIStroke (2px white, Thickness=2)
└── InnerLabel (TextLabel, ZIndex 1, same Text/Color as OuterLabel)
    └── UIStroke (1px black, Thickness=1)
```

Both labels parented directly to `BillboardGui`; ZIndex differentiates stacking.

### No on-screen UI from nameplate

Nameplate is 100% world-space. Does NOT consume screen real estate. Does NOT compete with HUD widgets (different layer — BillboardGui vs ScreenGui).

### Data flow summary

```
CrowdStateBroadcast (server, 15 Hz)
    ↓
CrowdStateClient.CountChanged / CrowdEliminated / .get (client)
    ↓
NameplateComponent subscribes, updates TextLabel.Text + TextColor3 + StudsOffsetWorldSpace + Font
    ↓
BillboardGui rendered natively (billboards to camera, culled at MaxDistance)
```

No remotes from nameplate. No user input. Pure render consumer.

**📌 UX Flag — Player Nameplate**: Diegetic world-space element, not screen-space. Does not require `/ux-design` companion spec (UX covered inline by this GDD + art bible §7). Skip UX pass for nameplate specifically.

## Acceptance Criteria

**AC-1 — Lifecycle: Construction on CharacterAdded.** GIVEN player present in session AND match in any state, WHEN `Player.CharacterAdded` fires, THEN `NameplateComponent` created and `BillboardGui` parented to `HumanoidRootPart` within same frame; no second component if event fires twice for same character. *Evidence: unit.*

**AC-2 — Lifecycle: Destruction on CharacterRemoving.** GIVEN `NameplateComponent` exists for character, WHEN `CharacterRemoving` fires, THEN `NameplateComponent:destroy()` called via Janitor, `BillboardGui` removed, no orphaned instances. *Evidence: unit.*

**AC-3 — BillboardGui Configuration.** GIVEN nameplate constructed, WHEN component inspected at construction, THEN `Adornee = HumanoidRootPart`, `AlwaysOnTop = false`, `LightInfluence = 0`, `MaxDistance = 120`, `Size = UDim2.fromOffset(200, 50)`. *Evidence: unit.*

**AC-4 — Double-Outline Structure.** GIVEN nameplate BillboardGui constructed, WHEN child hierarchy inspected, THEN exactly 2 TextLabel instances (foreground + background); each carries UIStroke child; foreground UIStroke.Thickness=1 (black inner); background UIStroke.Thickness=2 (white outer); both labels share identical Text, TextColor3, Font. *Evidence: unit.*

**AC-5 — Text Content Format.** GIVEN count of any int [1, 300], WHEN `CountChanged` fires with that value, THEN `TextLabel.Text = tostring(count)` with no commas, no suffixes, no player name; count=187 displays "187". *Evidence: unit.*

**AC-6 — Hue Tint from CSM.** GIVEN `CrowdStateClient.get(crowdId).hue` returns valid Color3, WHEN nameplate enters `Visible` AND on each subsequent `CountChanged`, THEN both TextLabel.TextColor3 equal CSM-returned hue; CSM hue change reflected on next CountChanged. *Evidence: unit.*

**AC-7 — F1 Tier Boundary Math.** GIVEN `NAMEPLATE_BASE_OFFSET_STUDS = 4.0`, WHEN CountChanged fires with 1, 50, 51, 150, 151, 300, THEN `StudsOffsetWorldSpace.Y` = 4.0, 4.0, 6.0, 6.0, 10.0, 10.0 respectively. *Evidence: unit.*

**AC-8 — F2 Font Step at Boundary.** GIVEN nameplate Visible, WHEN count crosses 150→151, THEN both TextLabel.Font switches GothamBold→GothamBlack same frame as offset jumps 6.0→10.0; reverse direction (after hysteresis) restores GothamBold. *Evidence: unit.*

**AC-9 — Hidden in Non-Active States.** GIVEN nameplate Visible, WHEN `MatchStateChanged` fires to Lobby, Countdown (Ready/Snap), Intermission, or ServerClosing, THEN `BillboardGui.Enabled = false` before next frame; does not reappear until `MatchStateChanged → Active`. *Evidence: unit.*

**AC-10 — Eliminated Fade 1.5s.** GIVEN nameplate Visible, WHEN `CrowdEliminated` fires for owning crowdId, THEN `TextTransparency` + `UIStroke.Transparency` tween 0→1 over exactly 1.5s (`NAMEPLATE_ELIM_FADE_SEC`); after tween `BillboardGui.Enabled = false`. *Evidence: integration.*

**AC-11 — Stale-Data Freeze.** GIVEN `CrowdStateClient` reports staleness > `STALE_THRESHOLD_SEC = 0.5`, WHEN no CountChanged arrives, THEN nameplate displays last-known count + hue; no error; no "?" placeholder. *Evidence: unit.*

**AC-12 — MaxDistance Cull at 120.** GIVEN nameplate with `MaxDistance = 120`, WHEN camera at 121 studs from Adornee, THEN Roblox does not render BillboardGui. *Evidence: manual (Studio playtest, advisory).*

**AC-13 — No Server-Side Counterpart.** GIVEN nameplate system running, WHEN server-side audit performed, THEN no Script or RemoteEvent specific to nameplates exists; no nameplate-specific network traffic in Developer Console Network tab. *Evidence: manual (server audit, advisory).*

**AC-14 — Frame Budget: 12 Simultaneous Updates.** GIVEN 12 players all receive CountChanged same tick, WHEN all 12 update handlers execute, THEN total CPU cost < 0.2ms via MicroProfiler; worst-case all-tier-crossing ~0.06ms. *Evidence: manual (MicroProfiler 12-player test place, advisory).*

**AC-15 — Tier Hysteresis: No Flicker at 50/51.** GIVEN count in tier 1 (≤50) and crosses up to 51, WHEN count drops back to 50 then 51 repeatedly within one tick, THEN offset does not revert to 4.0 until count drops ≤47 (50-3=47 via `NAMEPLATE_TIER_HYSTERESIS=3`); no per-frame visual flicker. *Evidence: unit.*

**AC-16 — Fade Cancelled by MatchStateChanged During Elimination.** GIVEN nameplate in Fading (tween in progress), WHEN `MatchStateChanged → Intermission` fires before 1.5s tween completes, THEN tween cancelled, `BillboardGui.Enabled = false` immediately; no partially-faded nameplate in Intermission. *Evidence: unit.*

**AC-17 — Mid-Round Join: All Rival Nameplates Spawn Within 1 Frame.** GIVEN 11 players already in active round with nameplates visible, WHEN 12th player joins and client receives `CrowdStateBroadcast` for all existing crowds, THEN all 11 rival NameplateComponent instances constructed within 1 rendered frame of PlayerAdded loop; no rival nameplate absent or delayed. *Evidence: integration (Studio multi-client).*

**AC-18 — Text Legibility at 120-Stud Cull (Mobile).** GIVEN nameplate with `TextSize=28`, GothamBold, double-outline, WHEN viewed at 119 studs on min-spec mobile (iPhone SE), THEN count text legible to observer without zoom; screenshot + lead sign-off in `production/qa/evidence/`. *Evidence: manual (mobile playtest, advisory).*

**AC classification summary:**
- BLOCKING — unit: AC-1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 15, 16
- BLOCKING — integration: AC-10, 17
- ADVISORY — manual: AC-12, 13, 14, 18

## Open Questions

1. ✓ **RESOLVED 2026-04-24** — CSM Batch 1 exposed `CrowdCreated` reliable RemoteEvent with payload `{crowdId, hue, initialCount}`. Mid-round-join race handled natively; no polling fallback needed. See `docs/architecture/change-impact-2026-04-24-csm-batch1.md`.
2. **CSM `HueChanged` signal** — hypothetical for future skin-mid-match hue changes. MVP locks hue at `createAll`; signal not needed. Flag for revisit when Skin System (VS) implements mid-round hue mutation. Owner: CSM + Skin System.
3. **DisplayName on nameplate** — MVP shows count only. Roblox DisplayName for social identity is VS-tier add. Decide during VS: display name below count, or separate line, or replace count? Owner: ux-designer + game-designer (VS).
4. **Tier-up chime audio** — optional audio tied to `NameplateTierStepUp` event. Could amplify Pillar 1 sizing-up beat or add noise pollution. Audio Director decides in Audio Manager GDD (VS). MVP ships silent.
5. **FTUE highlight API (`setHighlight`)** — spec'd here, VS-tier implementation. FTUE GDD must codify exact widgetName / highlight payload. Owner: FTUE GDD (VS).
6. **First-person camera own-nameplate hide** — MVP assumes third-person only. If first-person mode ever ships, own-nameplate must hide to avoid self-occlusion. Owner: Camera GDD (if authored) or game-designer.
