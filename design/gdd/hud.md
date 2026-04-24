# HUD

> **Status**: In Design (2026-04-24 consistency-check sync — 7 stale "CSM/Chest amendment required" flags cleared: `CrowdCountClamped` signal LANDED in CSM Batch 1; Chest System minimap downgrade LANDED in Chest Batch 4 with all 7 minimap refs marked deferred to VS+. No functional changes to HUD mechanics.)
> **Author**: user + game-designer + ux-designer + ui-programmer + art-director + technical-artist
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine) + 3 (5-Min Clean Rounds) + 2 (Risky Chests)
> **MVP Scope**: Crowd count, round timer, relic shelf, mini-leaderboard, 3-2-1 overlay, AFK button, MAX CROWD flash, Eliminated label, Solo-wait UI, Lobby wait label. No minimap per art bible §7. Chest billboard / Relic card modal / Result screen / Nameplate delegated to other GDDs.

## Overview

The **HUD** is the client-side screen-space overlay that binds live game state to glance-readable visuals every frame. It consumes five data streams — `CrowdStateBroadcast` (15 Hz, own crowd count + rival leaderboard counts), `MatchStateChanged` (reliable, timer + state-gated visibility), `CrowdRelicChanged` (reliable, 4-slot relic shelf), `ParticipationChanged` (reliable, AFK toggle state), and client-cached `RelicRegistry` (boot-loaded for slot icon/copy lookup) — and renders them through `UIHandler`'s layer system (ANATOMY §8) as a single `HeadsUpDisplay` layer that coexists with gameplay. Each element is an independent widget bound to one data source: crowd count widget reads `CrowdStateClient.get(ownCrowdId).count` + subscribes to `CountChanged`, timer widget reads Match State F6 interp, relic shelf listens to `CrowdRelicChanged` and re-renders the full `{RelicSnapshot}` array on each broadcast. The HUD is stateless itself — all state lives in its upstream data sources. State-gated visibility (timer hidden in Lobby, AFK button hidden in Active, 3-2-1 only in Countdown:Snap) is driven by `MatchStateChanged`. There is no minimap in MVP per art bible §7 — chest discovery happens via diegetic beams above crowd silhouette height.

For the player, the HUD is the counter that climbs. Every absorb is a number popping bigger on the bottom of the screen; every toll is the number peeling down; every chest pull is a new icon filling a slot on the shelf; every rival eliminated is their row fading off the leaderboard. The crowd count is the dopamine spine of Pillar 1 — absorb + HUD pop + audio chime are a single unified beat, and the HUD half of that beat is what the player stares at. The round timer is Pillar 3 made visible — the 5-minute promise counted down to 0. The relic shelf is Pillar 2 kept tangible between chests — every slot filled is a decision earned, every empty slot a question still open. The HUD is the layer that tells the player *what's happening right now and how long they have to keep doing it*, without ever interrupting input.

**Scope (MVP)**: crowd count + timer + relic shelf + mini-leaderboard + 3-2-1 overlay + AFK button + MAX CROWD flash + Eliminated label + Solo-wait indicator + "Waiting for players (N/2)" Lobby label. Chest Billboard, Relic Card draft modal, Round Result Screen, Lobby Main Menu, and Player Nameplate are delegated to their own GDDs.

## Player Fantasy

Everything I need, nothing I don't.

Your thumb is on the joystick, your crowd is a roar of two hundred and ten silhouettes, rivals are circling the far plaza, and the round is bleeding down. One glance at the bottom of the screen: **210**. One glance up: **0:30**. One glance at the shelf: Surge, TollBreaker, empty slot, empty slot. Full picture, one heartbeat, decision made — sprint the last T2 or chase the smaller rival. The HUD is a pit crew. It reports, it doesn't demand. While the map screams and the audio swells and your crowd is a noisy miracle underneath you, the HUD stays still, small, and exact — the one stable thing on screen telling you what's true *right now*.

This is the HUD's job: it takes the dopamine of Pillar 1 and gives it a visible spine (the count climbs and pops, the count climbs and pops). It takes the promise of Pillar 3 and counts it down in numerals big enough to read on a phone at arena distance. It takes the draft of Pillar 2 and hangs it in your peripheral vision as a four-slot shelf that fills across five minutes, so every time your thumb hits a chest prompt, you already know how much room you have left. The HUD never interrupts input — it never pops a modal, never pauses, never demands confirmation. Mobile-first is not a compromise here; it's the fantasy. The whole game fits in one thumb-glance, and the HUD is the glance.

> **Scope clarification (added 2026-04-24 per DSN-NEW-1 of gdd-cross-review-2026-04-24-pm.md).** "The HUD never pops a modal" describes the HUD *layer itself* — the count, timer, relic shelf, leaderboard, AFK button, 3-2-1 overlay, MAX CROWD flash, and solo-wait widgets all run non-blocking, never pause input, never demand confirmation. The Chest draft card (chest-system.md §C) is a **separate UI layer** owned by Chest System (UILayer `RelicDraft`, `UILayerType.Menu`), not the HUD. It is the one intentional gameplay pause in MVP — a **visible exposure-cost decision beat** where the player's crowd stands still absorbing toll and the player picks 1-of-3 cards within `DRAFT_TIMEOUT_SEC = 8s` (auto-pick on timeout). The draft card is a Chest-owned layer, not a HUD widget; the "never modal" rule applies to the HUD layer and its widgets only. Full interaction spec to be authored by `/ux-design design/ux/relic-card.md` in UX phase; until then chest-system.md §C is authoritative for the interaction contract. The HUD count + timer + relic shelf remain rendered behind the draft card (no blackout, no blur) so the player retains peripheral state-awareness during the pause.

## Detailed Design

### Core Rules

**1. HUD Layer Registration.** On client boot, after `UIHandler` initializes, HUD registers as a single `UILayer` of `UILayerType.HeadsUpDisplay` (coexists with gameplay; not a Menu type). Layer contains a root `ScreenGui` with `ResetOnSpawn = false`, `ZIndexBehavior = Sibling`. All widgets are children of this root; widgets persist for client lifetime.

**2. Element Lifecycle — Persistent with Visibility Gates.** Every HUD widget is instantiated once at boot, never destroyed. Widget visibility is toggled via `.Visible` property only, driven by `MatchStateChanged` events. No create-on-demand. This keeps transitions instant and memory bounded.

**3. Data Binding — One Source per Widget.** Each widget subscribes to exactly one authoritative source:
- `CrowdCountWidget` → `CrowdStateClient.get(ownCrowdId).count` + listens to `CrowdStateClient.CountChanged(ownCrowdId)` signal
- `TimerWidget` → Match State F6 interp: `displayedSeconds = clamp(stateEndsAt - (tick() - clockOffset), 0, state_duration)`. Recomputes every `RenderStepped` during Active; cached per-second-rounded value for display
- `RelicShelfWidget` → subscribes `CrowdRelicChanged` reliable RemoteEvent; replaces full 4-slot array on each broadcast
- `MiniLeaderboardWidget` → subscribes `CrowdStateBroadcast`; computes top-3 by descending count + self-rank row
- `CountdownOverlayWidget` → listens `MatchStateChanged`; visible only during `Countdown:Snap` state
- `AFKButtonWidget` → reads `ParticipationChanged` remote; visible only in `Lobby` + `Countdown:Ready`
- `EliminatedLabelWidget` → listens `CrowdEliminated` signal for own crowdId
- `SoloWaitWidget` → visible only in Match State `SoloWait` sub-state (if applicable from MSM F7) or when `#activeRivals == 0` during Active
- `LobbyWaitLabelWidget` → visible in Lobby; text: `"Waiting for players (N/2)"` where N = current participant count

**4. Count Pop Animation.** When `CrowdCountWidget` observes a delta `Δ` such that the new count crosses a multiple of 10 upward (`floor(newCount / 10) > floor(oldCount / 10)`), trigger scale tween: `TextLabel.UDim2` scales 1.0 → 1.3 → 1.0 over 0.15s via `TweenService` with `EasingStyle.Back, EasingDirection.Out`. No pop on downward deltas (toll, collision). Multiple crossings in one broadcast tick (e.g., Surge +40 at count=55 → 95 crosses 60/70/80/90) trigger a single pop, not 4.

**5. MAX CROWD Flash.** When `CrowdStateClient` observes `count == 300` AND `#activeRelics > 0` with a just-granted count relic (`CrowdRelicChanged` just fired with new slot AND count clamp occurred), flash "MAX CROWD" label in the count widget for 1.0s: opacity 0→1 over 0.1s, hold 0.6s, 1→0 over 0.3s. Detection via CSM's `updateCount` clamp path (server fires `CrowdCountClamped` signal to owning client).

**6. Stale-data Handling.** If `CrowdStateClient` reports `(os.clock() - lastBroadcastTime) > STALE_THRESHOLD_SEC (0.5)`, count widget FREEZES at last known value. No interpolation toward 0. No "missing" text. Widget resumes on next broadcast. (Registry-locked per CSM §G.)

**7. Timer State-Gated Display.**
- `Lobby`: timer hidden; lobby wait label visible
- `Countdown:Ready`: timer shows `COUNTDOWN_READY_SEC = 7` → 0
- `Countdown:Snap`: timer hidden; 3-2-1 overlay shown (3s countdown, full-screen centered)
- `Active`: timer shows `ROUND_DURATION_SEC = 300` → 0
- `Result`: timer hidden; Round Result Screen (separate GDD, VS) takes over
- `Intermission`: timer hidden
- `ServerClosing`: timer hidden; "Server closing" label shown (from Match State §ServerClosing)

**8. 3-2-1 Countdown Overlay.** Full-screen centered, `TextLabel` with `GothamBold` at 96pt. Numeric "3" → "2" → "1" → fade out. Each numeral visible for 1.0s; fade-out 0.1s between numerals. Visible only during `Countdown:Snap` state (`COUNTDOWN_SNAP_SEC = 3`). Centered semi-transparent dark plate backing (70% opacity). Non-interactive — pure visual.

**9. AFK Button Behavior.** `TextButton` bottom-right (mobile) / top-right (desktop). Visible only in `Lobby` + `Countdown:Ready`. Tap fires `RemoteEventName.ToggleParticipation` (client → server). Server validates per MSM §C rules (asymmetric freeze during Countdown:Snap). Button text reflects current participation: "AFK" when TRUE (opt-out option), "JOIN" when FALSE. Button disabled (greyed) when `MatchStateChanged` state is not Lobby or Countdown:Ready; never visible in Countdown:Snap/Active/Result/Intermission.

**10. Mini-Leaderboard Update Rule.** Updated per `CrowdStateBroadcast` receipt (~15 Hz). Computes top-3 crowds by descending `count`. If own crowd is outside top-3, appends own crowd as 4th row with actual rank (e.g., "6. You — 42"). 4 rows max. Eliminated crowds (`crowdState == "Eliminated"`) render with strikethrough + 50% opacity for `ELIM_LINGER_SEC = 5.0` then removed from list. Name display uses player display name; color uses signature hue (`hue_index_assignment` per CSM).

**11. Relic Shelf Rendering.** Fixed 4-slot horizontal row. Each slot is a `Frame` with rarity-shape frame (Common circle, Rare starburst, Epic hexagon per art bible §7), centered `ImageLabel` using `RelicRegistry[specId].ui.iconAssetId`, optional radial `UIGradient` countdown when `ticksRemaining` is non-nil. Empty slots render dim outlined placeholder (50% opacity, no icon). Order: ascending `slotIndex` left-to-right.

**12. Relic Slot Interaction.** Desktop: hover any slot shows tooltip with `spec.ui.shortDesc` (60-char max). Mobile: tap-and-hold (0.3s) shows tooltip. Tooltip is a `BillboardGui` relative to the slot; auto-dismisses on release or 3s timeout. Does NOT interrupt gameplay input.

**13. Eliminated Label.** When own `crowdState` transitions to `Eliminated`, large "ELIMINATED" text fades in (top-center, `GothamBold` 48pt, red hue). Crowd count widget switches to `"0"` + "— spectating" subtitle. Camera-follow handoff owned by Spectator Mode (separate component; HUD only renders the label). Label persists through `Result` state.

**14. Frame Budget.** HUD processing budget: `< 1.5 ms per RenderStepped` at peak (worst case: all widgets updating). Most frames use `< 0.3 ms`. Target verified via MicroProfiler during playtest.

### States and Transitions

HUD has no state machine of its own. Widget visibility is derived from Match State via a visibility table:

| Widget | Lobby | Countdown:Ready | Countdown:Snap | Active | Result | Intermission | ServerClosing |
|---|---|---|---|---|---|---|---|
| `CrowdCountWidget` | hidden | shown (preview) | shown | shown | shown | hidden | hidden |
| `TimerWidget` | hidden | shown (7→0) | hidden | shown (300→0) | hidden | hidden | hidden |
| `RelicShelfWidget` | hidden | shown (empty) | shown | shown | shown | hidden | hidden |
| `MiniLeaderboardWidget` | hidden | hidden | hidden | shown | hidden (Result screen takes over) | hidden | hidden |
| `CountdownOverlayWidget` | hidden | hidden | shown (3→0) | hidden | hidden | hidden | hidden |
| `AFKButtonWidget` | shown | shown | hidden | hidden | hidden | hidden | hidden |
| `EliminatedLabelWidget` | hidden | hidden | hidden | shown if self-eliminated | shown if self-eliminated | hidden | hidden |
| `SoloWaitWidget` | hidden | hidden | hidden | shown if `#activeRivals == 0` | hidden | hidden | hidden |
| `LobbyWaitLabelWidget` | shown | hidden | hidden | hidden | hidden | hidden | hidden |
| `ServerClosingLabelWidget` | hidden | hidden | hidden | hidden | hidden | hidden | shown |
| `MaxCrowdFlashWidget` | hidden | hidden | hidden | flash-triggered | hidden | hidden | hidden |

**Invariants:**
- Widget transitions driven by `MatchStateChanged` broadcast receipt on client; single handler updates all widget `.Visible` properties in one pass.
- `CountdownOverlayWidget` visible ONLY during `Countdown:Snap` — this is a hard lock; any bug showing it elsewhere is a correctness failure.
- `AFKButtonWidget` hidden during `Countdown:Snap` regardless of previous state — enforces MSM asymmetric freeze.
- `EliminatedLabelWidget` + `SoloWaitWidget` can coexist with other widgets — they don't replace count/timer; they overlay.
- `RelicShelfWidget` persists from `Countdown:Ready` through `Result` — keeps slot continuity visible across state transitions.

### Interactions with Other Systems

**Widget-to-source binding contracts:**

| Widget | Source | Event/API | Update frequency |
|---|---|---|---|
| `CrowdCountWidget` | CSM | `CrowdStateClient.get(ownCrowdId).count` + `CountChanged` signal | Per broadcast (15 Hz); count pop on +10 crossing |
| `TimerWidget` | MSM | `MatchStateClient.get()` + F6 formula | Per `RenderStepped`; display text refreshes on whole-second tick |
| `RelicShelfWidget` | Relic | `CrowdRelicChanged` reliable remote | On change only (never per-tick) |
| `MiniLeaderboardWidget` | CSM | `CrowdStateBroadcast` full payload | Per broadcast (15 Hz) |
| `CountdownOverlayWidget` | MSM | `MatchStateChanged`; F1 timer for 3→2→1 ticks | On state entry + per whole-second |
| `AFKButtonWidget` | MSM | `ParticipationChanged` reliable remote | On change only |
| `EliminatedLabelWidget` | CSM | `CrowdEliminated` signal | On event only |
| `SoloWaitWidget` | MSM | Match State `soloWaitActive` flag (MSM F7) or `#activeRivals == 0` derived | On state change |
| `LobbyWaitLabelWidget` | MSM + CSM | `MatchStateChanged` + Players count | On join/leave events |
| `ServerClosingLabelWidget` | MSM | `MatchStateChanged == "ServerClosing"` | On state entry |
| `MaxCrowdFlashWidget` | CSM | `CrowdCountClamped` signal (new — see below) | On clamp event |

**New signal contract proposed — `CrowdCountClamped`:**
CSM fires `CrowdCountClamped` signal to the owning client when `updateCount` clamps at `MAX_CROWD_COUNT = 300`. Payload: `{crowdId, attemptedDelta, actualDelta}`. Not a broadcast — targeted `FireClient` to the owning player. HUD consumes for MAX CROWD flash. **Requires CSM GDD amendment to expose this signal.** Flag in Dependencies.

**Integration contracts:**
- **UIHandler (template, ANATOMY §8)** — HUD registers as `UILayerType.HeadsUpDisplay` layer. HUD does NOT call `UIHandler.openMenu` / `closeMenu` (those are Menu-type operations). HUD visibility is always TRUE at the layer level; widget-level `.Visible` is the gating surface.
- **Crowd State Manager** — client read-only: `CrowdStateClient.get(crowdId)`, `CountChanged` signal, `CrowdStateBroadcast` reliable + unreliable remotes. Proposed new signal `CrowdCountClamped`.
- **Match State Machine** — `MatchStateClient.get()`, `MatchStateChanged` reliable remote, F6 timer interp formula, `ParticipationChanged` reliable remote.
- **Relic System** — `CrowdRelicChanged` reliable remote subscription; client-side `RelicRegistry` boot-loaded for icon/copy lookup (`spec.ui.iconAssetId`, `spec.ui.shortDesc`).
- **Round Lifecycle** — no direct interaction. HUD reads live counts via CSM; Round Lifecycle reads placements at Result via Match State broadcast.
- **Chest System** — **no direct HUD consumer in MVP.** Chest Billboard UI (separate GDD) owns all chest-local visuals. No minimap per art bible §7. Future: if playtest shows chest discovery breaks, revisit (§Open Questions).
- **Player Nameplate** (separate MVP system row 21) — HUD does not render nameplates. Nameplate GDD owns `BillboardGui` per character.
- **Round Result Screen** (VS GDD) — takes over rendering during `Result` state. HUD hides timer + mini-leaderboard during Result; Result Screen draws placements.
- **Lobby / Main Menu UI** (VS GDD) — separate `UILayerType.Menu` layer. Coexists with HUD's Lobby widgets but takes focus.
- **Spectator Mode** (future component) — HUD's `EliminatedLabelWidget` is passive; camera-follow handoff is separate concern.
- **FTUE / Tutorial** (template skeleton) — tutorial stages may temporarily override HUD widget visibility via `FtueManagerClient` setup/teardown hooks. HUD exposes `HUD.setWidgetOverride(widgetName, state)` API for tutorial-only visibility locks; cleared on teardown.

**No server-to-client writes from HUD:**
HUD consumes data only. The ONE exception: AFK button tap fires `ToggleParticipation` remote (client → server). Server validates and broadcasts `ParticipationChanged` back; HUD reflects the result, never assumes immediate state change.

## Formulas

HUD is primarily data binding. Two client-side formulas warrant specification.

### F1. `crowd_count_pop_trigger`

Detect upward crossing of a multiple of 10 to gate the count pop animation.

`should_pop = (newCount > oldCount) AND (floor(newCount / 10) > floor(oldCount / 10))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `oldCount` | `c_prev` | int | [1, 300] | Last observed count |
| `newCount` | `c_curr` | int | [1, 300] | New count from broadcast |
| `should_pop` | — | bool | — | Trigger TweenService scale 1.0→1.3→1.0 |

**Output range:** boolean. Pop frequency: roughly every 10 absorbs (~0.8s at R_absorb=13/s) = ~1 pop/sec sustained at mid-game. Burst relics (Surge +40) produce single pop, not 4 — formula naturally collapses multi-decade jumps.

**Example:**
- `oldCount=49, newCount=51`: `floor(51/10)=5 > floor(49/10)=4` → pop ✓
- `oldCount=55, newCount=57`: `floor(57/10)=5 == floor(55/10)=5` → no pop
- `oldCount=55, newCount=95` (Surge): `floor(95/10)=9 > floor(55/10)=5` → single pop ✓
- `oldCount=50, newCount=48` (collision): `48 < 50` → no pop (down-delta filter)

### F2. `timer_display_seconds` (consumed from Match State §F6)

Client-side timer display using Match State's clock-corrected interp.

`displayedSeconds = clamp(stateEndsAt - (tick() - clockOffset), 0, state_duration)`

Where `clockOffset` is recomputed on every `MatchStateChanged` receipt:
`clockOffset = (tick() - serverTimestamp) - (Players.LocalPlayer.Ping / 2000)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `stateEndsAt` | — | float | — | Server epoch when current state expires (from MSM broadcast) |
| `clockOffset` | `δ` | float | — | Cached per-broadcast clock + one-way delay correction |
| `tick()` | — | float | — | Client wall-clock (Unix epoch) |
| `state_duration` | — | float | state-specific | `COUNTDOWN_READY_SEC=7`, `COUNTDOWN_SNAP_SEC=3`, `ROUND_DURATION_SEC=300`, `RESULT_DURATION_SEC=10`, etc. |
| `displayedSeconds` | — | float | `[0, state_duration]` | Clamped output for TextLabel |

**Display rule:** HUD converts `displayedSeconds` to `"M:SS"` format via `string.format("%d:%02d", math.floor(displayedSeconds / 60), math.floor(displayedSeconds % 60))`. Updates on whole-second tick only (avoids 60-Hz text thrashing). Last 10 seconds of Active turn text red + scale 1.1× for urgency.

**Output range at 0.5 Hz RenderStepped sample:** For Active (300s state), display ticks every 1s from `5:00 → 0:00`. Edge case: rounding boundary — if `displayedSeconds = 59.5`, display shows `"0:59"` (floor). Flicker between `"1:00"` and `"0:59"` prevented by sub-second caching.

### Non-formulas — explicit reference

| Math | Owner | Why not here |
|---|---|---|
| `radius_from_count`, `collision_transfer_per_tick`, etc. | CSM / ADR-0001 | HUD only reads count; never computes radius |
| `effective_toll_chain` | Relic §F1 | Chest Billboard displays; HUD minimap NOT in MVP |
| `hue_index_assignment` | CSM | HUD reads color from CrowdStateClient.get(id).hue |
| Leaderboard sort | HUD reads `CrowdStateBroadcast` | Trivial sort, no formula |
| Rarity-shape mapping (Common→circle etc.) | Art bible §7 | Static lookup table, not a formula |

## Edge Cases

### Data / Binding

- **If `CrowdStateClient.get(ownCrowdId)` returns nil (not yet replicated)**: HUD count widget shows "—" placeholder. No errors. Resumes on first broadcast.
- **If broadcast gap > STALE_THRESHOLD_SEC (0.5)**: count + leaderboard freeze at last known value. Registry-locked (CSM §G). No "missing" text.
- **If `CrowdRelicChanged` receipt has `slots = {}` (empty array)**: all 4 shelf slots render as empty placeholders. Legitimate state (round start + clearAll).
- **If `RelicRegistry[specId]` lookup returns nil (unknown specId in broadcast)**: slot renders with generic "?" icon + warn-color frame; log client-side. Indicates registry version drift (server has newer relic, client hasn't reloaded).
- **If `CrowdStateBroadcast` contains more crowds than expected (>12)**: leaderboard caps at 12 total; ignore extras. Defensive; bug in CSM replication if ever hits.

### State Transitions

- **If `MatchStateChanged` arrives while client in hung state (long frame drop)**: visibility handler runs on next `RenderStepped`; HUD may display wrong widgets for 1 frame. Acceptable. No hard guards.
- **If client misses `MatchStateChanged` (reliable remote should prevent, but lag-spike)**: Match State §E reconciliation via `MatchStateClient.reconcile(payload)` runs on next broadcast; HUD visibility refreshes. Tolerated up to 1 transition miss.
- **If round ends (Active → Result) with player's crowd count at 300**: MAX CROWD flash may fire same frame as timer hides. Sequence: MatchStateChanged handler runs first (hides timer), then CrowdCountClamped signal (fires flash on now-hidden count widget). Flash still visible because count widget persists through Result. OK.
- **If 3-2-1 overlay visible when MatchStateChanged to `Active` arrives (state transition on 3s boundary)**: overlay fades out in same frame; timer widget becomes visible. Brief 0-1 frame overlap acceptable.
- **If player rejoins during `Result` state (DC + reconnect)**: full per-player `MatchStateChanged` fires; HUD visibility computed fresh from current state. Mini-leaderboard unavailable (Result screen takes over). Returned player sees result screen as late-join per MSM §E.

### Widget-specific

- **If count widget receives `CrowdCountClamped` signal but count != 300 (bug / race)**: flash fires anyway; harmless. Log for audit.
- **If multiple count deltas in one broadcast cross 2+ decade boundaries (e.g., +80 from 15 → 95)**: single pop animation (F1 formula). Not 8 stacked pops. Last delta wins.
- **If AFK button tapped during Countdown:Snap (should be hidden)**: UI guard already disables visibility; defensive server-side guard rejects toggle. No effect client-side.
- **If Eliminated label shows but crowd subsequently revived via future mechanic**: MVP has no revival (per CSM §C). If ever added, HUD consumes transition signal and hides label. Flagged for post-MVP.
- **If SoloWait triggered but rival reconnects before SOLO_WAIT_SEC elapses**: MSM F7 cancels the solo-win timer; HUD removes SoloWait indicator on next MatchStateChanged. No false "victory" shown.
- **If leaderboard has 2+ crowds at identical count**: sort stable by `crowdId` ascending (secondary key). Visual parity; matches MSM F4 tiebreak for consistency.
- **If relic slot's `ticksRemaining` reaches 0 between broadcasts**: client-side countdown ring animates smoothly (interpolated from last known `ticksRemaining` minus frames since receipt). Next `CrowdRelicChanged` broadcast on expiry corrects. Drift acceptable (<67ms).
- **If tooltip open while state transitions to hidden**: tooltip auto-dismisses on widget hide. Hard guard.

### Performance / Budget

- **If 12 rivals all actively absorbing (broadcast payload maxed)**: leaderboard sort + render cost ~0.1ms. Well under 1.5ms frame budget.
- **If count pop triggered mid-frame of other widget animation**: TweenService handles concurrent tweens natively. No conflict.
- **If RelicRegistry lookup cost is O(1) (table index)**: always. No performance degradation at any pool size.
- **If mobile device at lowest-tier GPU**: HUD frame cost <1ms target; verified via MicroProfiler on min-spec device (iPhone SE per Follower Entity target).

### Input

- **If player taps AFK button during Countdown:Snap (button hidden but underlying frame still processing)**: Roblox GUI `Active = false` on hide blocks input events. Defensive server guard.
- **If tutorial overrides widget visibility and tutorial ends mid-state**: `HUD.setWidgetOverride(widgetName, nil)` clears override; normal state visibility resumes on next `MatchStateChanged`.
- **If screen rotates on mobile (portrait ↔ landscape)**: layout recomputes via `UIAspectRatioConstraint`. No fixed-pixel positions. Mobile binding.

### Accessibility

- **If colorblind player can't distinguish rarity frames**: shape-redundancy per art bible §7 (circle/starburst/hexagon). No color-only rarity indication. Verified during UX review.
- **If text too small on low-DPI screen**: all font sizes specified in `TextScaled = true` scaled UDim; respect Roblox `UIScale`. Minimum 14pt (art bible §7).

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| UIHandler (template, ANATOMY §8) | Approved | `registerLayer(layerId, layerType, setupFn, teardownFn)` as `UILayerType.HeadsUpDisplay`; no open/close calls | Register only |
| Network Layer (template) | Approved | Reliable RemoteEvents: `MatchStateChanged`, `CrowdRelicChanged`, `ParticipationChanged`, `ToggleParticipation`; unreliable `CrowdStateBroadcast` | Consumer + 1 outbound |
| PlayerData / ProfileStore (template) | Approved | None — HUD is ephemeral; no persistence | N/A |
| Crowd State Manager | Batch 1 Applied 2026-04-24 | `CrowdStateClient.get/subscribe`, `CountChanged` server-side BindableEvent, `CrowdStateBroadcast` unreliable remote, `CrowdCountClamped` reliable RemoteEvent (✓ CSM Batch 1 landed; local-filtered to owning player; HUD owns debounce per Batch 1 contract) | Read-only |
| Match State Machine | In Revision | `MatchStateClient.get()`, `MatchStateChanged` reliable remote, F6 timer interp, F1 tick, `ParticipationChanged` remote, `ToggleParticipation` (client→server) | Read + 1 write |
| Relic System | Designed (pending review) | `CrowdRelicChanged` reliable remote; client-side `RelicRegistry` boot-loaded for `spec.ui.iconAssetId` + `spec.ui.shortDesc` lookup | Read-only |
| AssetId Registry (art bible §8.9 convention) | Approved | Relic icon asset IDs via `RelicRegistry[specId].ui.iconAssetId` resolution | String-constant read |
| Art Bible §7 (HUD visual direction) | Approved | Mobile-first layout; dark plate 60-70% opacity; GothamBold ≥28pt; rarity-shape frames; count pop 1.0→1.3→1.0 over 0.15s; NO MINIMAP MVP | Design reference |
| ADR-0001 Crowd Replication | Proposed | `STALE_THRESHOLD_SEC = 0.5` for freeze-last-known behavior | Reused constant |
| Pillar 1 (Snowball Dopamine) | Approved | Count pop animation is the primary Pillar 1 visual | Locks design |
| Pillar 3 (5-Min Clean Rounds) | Approved | Timer visibility is Pillar 3 promise made visible | Locks design |
| Pillar 2 (Risky Chests) | Approved | Relic shelf is Pillar 2 kept tangible between opens | Locks design |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| FTUE / Tutorial | Not Started (VS) | `HUD.setWidgetOverride(widgetName, stateBool?)` — temporarily overrides `.Visible`; `nil` clears. Used by tutorial stage handlers for highlight/hide | Write (via function call) |
| Relic System | Designed | Consumes `CrowdRelicChanged` (bidirectional confirmed — Relic §Dependencies lists HUD downstream) | Read |
| Player Nameplate (separate MVP row 21) | Not Started | None — Nameplate is `BillboardGui` per character, owned separately | N/A |
| Round Result Screen (VS) | Not Started | HUD hides timer + mini-leaderboard during Result; Result Screen assumes full control | Visibility contract |
| Lobby / Main Menu UI (VS) | Not Started | Separate `UILayerType.Menu`; coexists but takes focus. HUD Lobby widgets (`LobbyWaitLabelWidget`, `AFKButtonWidget`) remain visible beneath menu layer | Z-order contract |
| Spectator Mode (future component) | Not Started | HUD's `EliminatedLabelWidget` passive render; Spectator owns camera. HUD reads `CrowdEliminated` signal for own crowd | Read-only |
| Daily Quest Panel (Alpha) | Not Started | None directly; quest notifications may piggyback via `UILayerType.HeadsUpDisplay` sibling layer | N/A |
| Analytics (Alpha) | Not Started | None — HUD emits no analytics events directly; it's a view layer | N/A |
| Chest System | Batch 4 Applied 2026-04-24 | **No MVP consumer.** No minimap per art bible §7 (HUD locks no-minimap-MVP). Chest Billboard UI (separate GDD) handles chest-local visuals. ✓ Chest System Batch 4 2026-04-24 downgraded all 7 minimap references to "DEFERRED to VS+"; `ChestStateChanged` broadcast remains wired for post-MVP HUD consumption. | N/A |

### Provisional assumptions (flagged for cross-check)

1. ✓ **RESOLVED 2026-04-24** via CSM Batch 1. `CrowdCountClamped` reliable RemoteEvent now declared in CSM §Network event contract with payload `{crowdId, attemptedDelta, clampedCount}`, fires on `updateCount` ceiling clamp at 300, local-filtered to owning player. HUD owns the once-per-cap-entry debounce per Batch 1 contract.
2. ✓ **RESOLVED 2026-04-24** via Chest Batch 4. Chest System downgraded all 7 minimap references to "DEFERRED to VS+" per art bible §7 / HUD no-minimap-MVP decision. MVP chest discovery via billboard + ProximityPrompt.GUI. `ChestStateChanged` broadcast remains wired for post-MVP HUD consumption. Chest Open Question OQ-4 "Minimap + HUD scope" updated to match.
3. **Player Nameplate GDD** (MVP row 21, not yet authored) must specify: `BillboardGui` per character (separate from HUD ScreenGui); hue-tint + outline + count display; vertical offset scale per art bible §7 diegetic rules.
4. **Round Result Screen GDD** (VS) must specify: takes full visibility control during `Result` state; reads MSM broadcast `meta.placements[]` for render; hides after `RESULT_DURATION_SEC = 10`.
5. **FTUE stage handlers** will use `HUD.setWidgetOverride` during tutorial stages. FTUE GDD (VS) must document exact widgetName strings matching this GDD's widget identifiers.
6. **RelicRegistry client-side boot-load** — Relic System assumes `RelicRegistry` is accessible from client. Confirm `RelicSpec` module lives in `ReplicatedStorage/Source/Relics/` (not ServerStorage). Flag if otherwise.

### Bidirectional consistency notes

- **RESOLVES** CSM §Dependencies "HUD: read-only `CrowdStateClient.get(crowdId).count`" — confirmed.
- **RESOLVES** MSM §Dependencies "HUD: F6 timer + state-gated visibility" — confirmed.
- **RESOLVES** Relic System §Dependencies "HUD subscribes `CrowdRelicChanged`" — confirmed.
- ✓ **CSM GDD Batch 1 landed `CrowdCountClamped` signal 2026-04-24** — local-filtered reliable RemoteEvent; HUD-owned debounce per contract.
- ✓ **Chest System GDD Batch 4 landed minimap downgrade 2026-04-24** — all 7 minimap references marked "DEFERRED to VS+" aligned with HUD no-minimap-MVP decision.
- **Systems Index update**: mark HUD "Designed (pending review)"; note MVP scope excludes minimap.

### No cross-server or persistence dependency

HUD is client-only, round-scoped. No DataStore, no MessagingService. All state read from upstream broadcasts; widget state derived, never owned.

## Tuning Knobs

### Animation / Feel

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `COUNT_POP_SCALE_DURATION` | 0.15 s | [0.1, 0.3] | Scale tween duration on +10 crossing | 0.3+ = pops overlap, feels laggy | <0.1 = pop imperceptible | Art bible §7 locks 0.15 default |
| `COUNT_POP_SCALE_MAX` | 1.3 | [1.1, 1.5] | Peak scale during pop | 1.5+ = visual hogs screen | 1.1 = pop invisible | Art bible §7 |
| `MAX_CROWD_FLASH_DURATION` | 1.0 s | [0.5, 2.0] | MAX CROWD label visible duration | 2.0+ = overstays | <0.5 = missed by player | Audio `ChestCountMaxFlash` duration |
| `COUNTDOWN_OVERLAY_NUMERAL_SEC` | 1.0 s | locked | Each 3/2/1 numeral display duration | — | — | `COUNTDOWN_SNAP_SEC = 3` (3 × 1.0 = 3.0; hard-locked to sum) |
| `TIMER_URGENT_THRESHOLD_SEC` | 10 s | [5, 30] | Last N seconds turn timer red + scale 1.1× | 30+ = urgent state for 10% of round, desensitizes | <5 = insufficient warning | Adds audio sync hook for Audio Manager |

### Leaderboard

| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `LEADERBOARD_ROW_COUNT` | 3 (+ self if >3) | [2, 5] | Top-N displayed rows |
| `ELIM_LINGER_SEC` | 5.0 s | [2, 10] | How long eliminated crowds render strikethrough before removal |
| `LEADERBOARD_UPDATE_HZ` | 15 (per broadcast) | locked | Update frequency; tied to CSM `SERVER_TICK_HZ` |

### Layout / Positioning (per art bible §7 anchors)

Not tuning knobs — these are art-bible-locked:
- Mobile count position: bottom-center; desktop: top-center
- Mobile relic shelf: bottom-right; desktop: bottom-center
- Mobile joystick: bottom-left (mobile-only)
- Timer: top-center (both)
- Mini-leaderboard: top-right (both)

### Stale / Performance

| Knob | Default | Safe range | Affects | Owner |
|---|---|---|---|---|
| `STALE_THRESHOLD_SEC` | 0.5 | [0.2, 2.0] | Broadcast gap before widget freeze | **CSM §G locked** — do not override here |
| `HUD_FRAME_BUDGET_MS` | 1.5 | [0.5, 3.0] | Per-frame processing cap | Advisory budget; verified via MicroProfiler |

### Locked constants (not tuning knobs — amendment required)

- `MAX_RELIC_SLOTS = 4` — CSM registry; slot count UI assumes
- `DRAFT_CANDIDATE_COUNT = 3` — Relic registry; not HUD concern but influences draft UI peer
- `ROUND_DURATION_SEC = 300` — MSM registry; timer upper bound
- `COUNTDOWN_SNAP_SEC = 3` — MSM registry; 3-2-1 overlay duration
- `STALE_THRESHOLD_SEC = 0.5` — CSM registry
- Rarity frame shapes (Common circle, Rare starburst, Epic hexagon) — art bible §7
- Font GothamBold / Gotham regular — art bible §7
- No-minimap MVP — art bible §7 lock

### Where knobs live (implementation guidance)

- Animation constants → `ReplicatedStorage/Source/SharedConstants/HudConfig.luau`
- Widget modules → `ReplicatedStorage/Source/UI/UILayers/HudLayer/[WidgetName].luau`
- Layer entry → `ReplicatedStorage/Source/UI/UILayers/HudLayer/init.luau`
- Registered via `UIHandler.registerLayer(UILayerId.Hud, UILayerType.HeadsUpDisplay, ...)` per ANATOMY §8
- Tooltip BillboardGui prefabs → `ReplicatedStorage/Instances/GuiPrefabs/HudTooltip`
- Widget prefabs → `ReplicatedStorage/Instances/GuiPrefabs/HudWidgets/`

## Visual/Audio Requirements

HUD is the UI category itself — V/A spec is the art-bible §7 realization. Asset rendering owned directly by HUD widgets; audio triggers shared with CSM + Chest + Relic event catalogs.

### Visual spec (from art bible §7)

- **Color palette**: semi-transparent dark plate 60-70% black opacity rounded rect behind all HUD elements. Flat-design: no gradients, no drop shadows.
- **Typography**:
  - Display (count, toll, timer): `GothamBold` ≥28pt on round state
  - UI (labels, menus): `Gotham` regular ≥14pt, high contrast
  - Tooltip labels: 10pt absolute minimum
- **Rarity frames** (shape redundancy, colorblind-safe per art bible §7):
  - Common = circle frame
  - Uncommon = diamond frame (future pool)
  - Rare = starburst frame
  - Epic/Legendary = hexagon frame
- **Count pop**: scale bounce 1.0 → 1.3 → 1.0 over 0.15s, `TweenService EasingStyle.Back, EasingDirection.Out`
- **3-2-1 overlay**: 96pt GothamBold centered; semi-transparent dark plate backing; numerals 1.0s each; 0.1s fade between
- **Timer urgency**: last 10s red + scale 1.1× (`TIMER_URGENT_THRESHOLD_SEC = 10`)
- **ELIMINATED label**: GothamBold 48pt top-center red hue; fade in over 0.3s
- **MAX CROWD flash**: opacity 0→1 (0.1s) → hold (0.6s) → 1→0 (0.3s); total 1.0s
- **Leaderboard row**: crowd hue-tint signature color per `hue_index_assignment` formula; name + count; eliminated strikethrough + 50% opacity

### Event catalog (HUD fires AND consumes)

| Event | Direction | Payload | Receivers / Triggers |
|---|---|---|---|
| `HudCountPop` | HUD internal | `{newCount, delta}` | Audio Manager consumes for optional +10 chime (TBD with Audio Director) |
| `HudMaxCrowdFlash` | HUD internal | `{crowdId}` | Audio Manager consumes for MAX CROWD audio swell (tied to CSM `CrowdCountClamped`) |
| `HudCountdownTick` | HUD internal | `{numeral: 3/2/1}` | Audio Manager consumes for 3-2-1 beat (tier-scaled ticks) |
| `HudTimerUrgent` | HUD internal | `{secondsRemaining}` | Audio Manager — last 10s heartbeat audio |
| `CrowdCountClamped` | CSM → client (local-filtered) | `{crowdId, attemptedDelta, clampedCount}` | **HUD consumes** for MAX CROWD flash. ✓ CSM Batch 1 Applied 2026-04-24. HUD owns once-per-cap-entry debounce per contract. |
| `CrowdRelicChanged` | Server → client | `{crowdId, slots: {RelicSnapshot}}` | HUD relic shelf |
| `MatchStateChanged` | Server → all | `{state, serverTimestamp, stateEndsAt, meta}` | HUD state-gated visibility + timer |
| `CrowdStateBroadcast` | Server → all | aggregate crowd table | HUD count + leaderboard |
| `ParticipationChanged` | Server → single client | `{isParticipating}` | HUD AFK button text toggle |

### SFX intent (handoff to Audio Director / Sound Designer)

- **Count pop chime (optional)** — short, high-pitched tick per +10 crossing. Risk: spam at high absorb rate. Consider threshold escalation (per +50 instead). Flag for Audio Manager GDD.
- **MAX CROWD swell** — deep crowd-audio peak; tied to visual flash; 1.0s duration max
- **3-2-1 beats** — ascending tick-tick-tick-snap cadence (3 high → 2 higher → 1 highest → snap on Active entry)
- **Timer urgent heartbeat** — last 10s: subtle low-freq thump per second
- **Eliminated sting** — single deep "thud" at label fade-in start

### VFX intent (handoff to Technical Artist)

- Count pop is pure `TweenService` on `TextLabel.Size` — no particle emissions
- 3-2-1 overlay fade uses `TextLabel.TextTransparency` tween
- ELIMINATED label uses `TextTransparency` fade-in
- No per-frame particle emissions from HUD — all effects are event-triggered tweens

**Art bible §7 compliance:**
- Mobile-first layout respects thumb-reach zones
- No drop shadows (flat-design pillar)
- Dark plate backing for text legibility
- Icon family-shape system for rarity

📌 **Asset Spec** — V/A requirements defined. After art bible production begins, run `/asset-spec system:hud` to produce per-asset specs (rarity frame shapes, empty-slot placeholder, tooltip backing, dark plate tiles, AFK button states, ELIMINATED label, MAX CROWD label, lobby wait label).

## UI Requirements

HUD is the UI. This section documents the widget layout realization.

### Layout — mobile (binding constraint)

```
┌─────────────────────────────────────────┐
│           [0:42]     [Mini-Board]      │  ← top: timer, leaderboard
│                       [2.] Rival — 187 │
│                       [3.] Rival — 142 │
│                       [6. You — 55]    │
│                                        │
│                                        │
│            (3-2-1 only Countdown:Snap) │  ← center overlay
│                                        │
│                                        │
│  [◯ AFK]               [🔴🟦▢▢]      │  ← bottom: AFK (Lobby only),
│  (Lobby)                  (relic shelf) │    relic shelf (bottom-right)
│                                        │
│  [Joystick]        [ 210 ]             │  ← bottom: joystick, count
│  (mobile)          (count)              │
└─────────────────────────────────────────┘
```

### Layout — desktop

```
┌─────────────────────────────────────────┐
│            [ 210 ]   [0:42]  [Board]   │  ← top: count, timer, board
│                                        │
│              (3-2-1 center)            │
│                                        │
│                                        │
│               [🔴🟦▢▢]                │  ← bottom-center: relic shelf
│                                        │
└─────────────────────────────────────────┘
```

### Widget layout specs (mobile anchors)

| Widget | Anchor | Size | Notes |
|---|---|---|---|
| `CrowdCountWidget` | Bottom-center, thumb-reach glance zone | 120×60 pts | 28pt+ display font; dark plate backing |
| `TimerWidget` | Top-center | 100×40 pts | 24pt display font; last 10s red |
| `RelicShelfWidget` | Bottom-right (mobile) / Bottom-center (desktop) | 280×70 pts | 4 slots × 60pt square + 10pt gaps |
| `MiniLeaderboardWidget` | Top-right | 200×140 pts (4 rows × 30pt + header) | Collapsible if needed post-playtest |
| `CountdownOverlayWidget` | Center (full-screen ScreenGui anchor) | 200×200 pts | 96pt centered numeral |
| `AFKButtonWidget` | Top-right (below leaderboard, mobile) / Top-right (desktop) | 80×40 pts | Hidden outside Lobby/Countdown:Ready |
| `EliminatedLabelWidget` | Top-center (below timer anchor) | 300×80 pts | 48pt red |
| `SoloWaitWidget` | Center-below-timer | 400×60 pts | "Waiting for rivals: 9s" format |
| `LobbyWaitLabelWidget` | Center | 400×80 pts | "Waiting for players (N/2)" |
| `ServerClosingLabelWidget` | Center | 400×80 pts | "Server closing" |
| `MaxCrowdFlashWidget` | Overlay on count widget | same as count | Non-interactive |

### Data flow summary

```
Server broadcasts (CrowdStateBroadcast, MatchStateChanged, CrowdRelicChanged, CrowdCountClamped)
    ↓
Client-side signals + reliable remotes
    ↓
HUD widgets subscribe individually; stateless render
    ↓
UIHandler.HeadsUpDisplay layer (always visible at layer level; widget .Visible per state)
```

**Outbound (1 path only):**
```
AFK button tap → ToggleParticipation remote → server validates → ParticipationChanged reliable remote → HUD refreshes
```

**📌 UX Flag — HUD**: This GDD is the canonical HUD spec. For pixel-level per-widget UX (spacing, tap targets, animation curves, tooltip layout), run `/ux-design` for `design/ux/hud.md` in Phase 4. Stories referencing specific widgets should cite the UX spec, not this GDD directly.

## Acceptance Criteria

**AC-1 — HUD layer registers as HeadsUpDisplay.** GIVEN client boots and UIHandler initialized, WHEN `HudLayer/init.luau` setup runs, THEN `UIHandler.registerLayer` called exactly once with `UILayerType.HeadsUpDisplay`; root `ScreenGui` has `ResetOnSpawn = false` + `ZIndexBehavior = Sibling`; no second registration on respawn. *Evidence: integration.*

**AC-2 — All widgets instantiated once at boot, never recreated.** GIVEN any match state transition fires, WHEN widget visibility changes, THEN no widget Instance created or destroyed; only `.Visible` toggles; widget count in ScreenGui remains constant across transitions. *Evidence: integration (descendant count before/after 3 transitions).*

**AC-3 — Each widget subscribes to exactly one data source.** GIVEN HUD initialized, WHEN source binding inspected, THEN `CrowdCountWidget` → `CountChanged` only; `TimerWidget` → F6 + RenderStepped only; `RelicShelfWidget` → `CrowdRelicChanged` only; no widget holds >1 authoritative signal connection. *Evidence: unit.*

**AC-4 — Count pop triggers on upward +10 crossing (F1).** GIVEN `CrowdCountWidget` visible, WHEN `CountChanged` fires with `oldCount=49, newCount=51`, THEN TweenService scale tween 1.0→1.3→1.0 over 0.15s fires exactly once. *Evidence: unit.*

**AC-5 — Count pop does NOT fire on downward delta or same-decade change.** GIVEN `CrowdCountWidget` visible, WHEN (a) `oldCount=55 newCount=57` same decade and (b) `oldCount=60 newCount=48` downward, THEN no tween fires either case. *Evidence: unit.*

**AC-6 — Surge +40 crossing multiple decades fires exactly one pop.** GIVEN count=55, WHEN single broadcast delivers `newCount=95` (crosses 60/70/80/90), THEN exactly one scale tween fires, not four. *Evidence: unit.*

**AC-7 — MAX CROWD flash triggers on `CrowdCountClamped`.** GIVEN player's crowd reaches 300 and `CrowdCountClamped` fires, WHEN `MaxCrowdFlashWidget` receives signal during Active, THEN label animates opacity 0→1 over 0.1s, holds 0.6s, fades 1→0 over 0.3s (total 1.0s); hidden before and after. *Evidence: unit.*

**AC-8 — Stale broadcast freezes count widget at last known value.** GIVEN `CrowdStateClient` delivered a count then broadcasts stop, WHEN `(os.clock() - lastBroadcastTime) > 0.5`, THEN count displays last value unchanged; no "—", no interpolation toward 0, no error; resumes normal display on next broadcast. *Evidence: unit.*

**AC-9 — Timer visibility is state-gated per visibility table.** GIVEN HUD active, WHEN `MatchStateChanged` fires for each state (Lobby, Countdown:Ready, Countdown:Snap, Active, Result, Intermission, ServerClosing), THEN `TimerWidget.Visible` TRUE only in Countdown:Ready and Active; countdown is 7→0 in Countdown:Ready and 300→0 in Active. *Evidence: integration.*

**AC-10 — Timer format "M:SS" with urgent-red at last 10 seconds (F2).** GIVEN Active timer running, WHEN `displayedSeconds = 599` display is `"9:59"`; at 60 is `"1:00"`; at 9 is `"0:09"` red at scale 1.1×, THEN format = `string.format("%d:%02d", math.floor(s/60), math.floor(s%60))`; red+scale trigger at `<=10`; updates on whole-second tick only. *Evidence: unit.*

**AC-11 — 3-2-1 overlay visible only during Countdown:Snap.** GIVEN any match state, WHEN `MatchStateChanged` fires, THEN `CountdownOverlayWidget.Visible = TRUE` only in `Countdown:Snap`; FALSE all others; numerals cycle 3→2→1 at 1.0s intervals with 0.1s fade between. *Evidence: integration.*

**AC-12 — AFK button visible only in Lobby and Countdown:Ready.** GIVEN any state transition, WHEN `MatchStateChanged` fires, THEN `AFKButtonWidget.Visible = TRUE` only in Lobby + Countdown:Ready; FALSE all others; label shows "AFK" when participation=true, "JOIN" when false. *Evidence: integration.*

**AC-13 — Mini-leaderboard shows top-3 plus self-rank row when outside top-3.** GIVEN `CrowdStateBroadcast` with 8 crowds, player ranked 6th, WHEN leaderboard renders, THEN exactly 4 rows: ranks 1/2/3 + "6. You — [count]"; eliminated crowds strikethrough + 50% opacity for 5.0s then removed. *Evidence: unit.*

**AC-14 — Relic shelf renders rarity-shape frames + icon.** GIVEN `CrowdRelicChanged` with Common slot 1, Rare slot 2, Epic slot 3, empty slot 4, WHEN `RelicShelfWidget` processes, THEN slot 1 circle, slot 2 starburst, slot 3 hexagon, slot 4 dim placeholder 50% opacity no icon; left-to-right by ascending slotIndex. *Evidence: manual (screenshot, lead sign-off).*

**AC-15 — Relic tooltip on hover (desktop) / tap-hold (mobile).** GIVEN shelf visible with filled slot, WHEN player hovers (desktop) OR tap-holds ≥0.3s (mobile), THEN tooltip BillboardGui appears with `spec.ui.shortDesc`; auto-dismisses on release or 3.0s; no remote event, no input block. *Evidence: manual (desktop + mobile walkthrough).*

**AC-16 — Eliminated label fades in, persists through Result.** GIVEN own crowd receives `CrowdEliminated` during Active, WHEN transition occurs, THEN "ELIMINATED" (GothamBold 48pt red) fades in top-center; count widget shows "0 — spectating"; label remains visible through Result; not hidden by `MatchStateChanged → Result`. *Evidence: integration.*

**AC-17 — Unknown specId renders "?" icon, no error.** GIVEN `CrowdRelicChanged` with specId not in client-side `RelicRegistry`, WHEN `RelicShelfWidget` processes slot, THEN renders "?" icon + warn-color frame; no Luau error; warn log written; other slots render normally. *Evidence: unit.*

**AC-18 — State transition during 3-2-1 overlay dismisses correctly.** GIVEN overlay showing numeral "2" during Countdown:Snap, WHEN `MatchStateChanged` fires → Active mid-overlay, THEN overlay `Visible = FALSE` same frame; `TimerWidget.Visible = TRUE` same handler pass; no stale numeral renders. *Evidence: integration.*

**AC-19 — Rejoin during Result delivers correct HUD layout.** GIVEN player DCs + reconnects during Result, WHEN client receives per-player `MatchStateChanged` with state=Result, THEN HUD renders per visibility table: timer hidden, mini-leaderboard hidden, `EliminatedLabelWidget` shown if self-eliminated, `CrowdCountWidget` shown; no Active-only widgets visible. *Evidence: integration.*

**AC-20 — Count pop concurrent-safe with other animations.** GIVEN count pop tween in flight, WHEN second `CountChanged` fires crossing another decade before first tween completes, THEN TweenService handles both without error; no nil-reference or overwrite crash; widget functional after both complete. *Evidence: unit.*

**AC-21 — Colorblind rarity discrimination via shape frames.** GIVEN player with deuteranopia / protanopia views shelf, WHEN Common + Rare + Epic relics simultaneously on shelf, THEN each rarity distinguishable by shape alone (circle/starburst/hexagon) without color reliance. *Evidence: manual (Coblis simulation screenshot, lead sign-off).*

**AC-22 — HUD frame budget <1.5ms per RenderStepped at peak.** GIVEN match with 12 rivals broadcasting, count pop animating, shelf full, WHEN MicroProfiler sampled on min-spec hardware (iPhone SE), THEN HUD processing cost ≤1.5ms per RenderStepped; average cost <0.3ms. *Evidence: manual (MicroProfiler trace screenshot, advisory — hardware not CI-reproducible).*

**AC classification summary:**
- BLOCKING — unit: AC-3, 4, 5, 6, 7, 8, 10, 13, 17, 20
- BLOCKING — integration: AC-1, 2, 9, 11, 12, 16, 18, 19
- ADVISORY — manual: AC-14 (shape frame screenshot), AC-15 (tooltip walkthrough), AC-21 (colorblind sim), AC-22 (frame budget)

## Open Questions

1. **Chest discovery under crowd occlusion** — art bible §7 asserts "arena small enough that visual orientation maintains". If playtest shows count=200+ players can't spot T1 chests (diegetic beams occluded by own crowd), MVP may need minimap amendment. Owner: playtest verdict + art-director + HUD. Target: first multi-player playtest session.
2. **Count pop audio trigger frequency** — per +10 crossing = ~1 pop/sec sustained = potentially spammy for audio. Audio Director may prefer per +50 audio (visual still pops per +10). Owner: Audio Manager GDD (VS).
3. **AFK button placement (mobile)** — current plan top-right below leaderboard. May collide visually with leaderboard. Alternative: bottom-left near joystick. Resolve in `/ux-design design/ux/hud.md` (Phase 4). Owner: ux-designer.
4. **Count pop on downward delta (toll-peel visual)** — currently filters downward. Question: should a negative pop animation (shrink 1.0→0.85→1.0) fire on toll deduction to reinforce sacrifice feel? Not MVP; flag for playtest. Owner: game-designer + ux-designer.
5. **CSM `CrowdCountClamped` signal amendment** — required for MAX CROWD flash. Not yet in CSM GDD. Owner: run `/propagate-design-change design/gdd/hud.md` after approval.
6. **Chest System amendment** — L338/L503/OQ-4 assume HUD minimap. Must amend. Owner: run `/propagate-design-change` after HUD approval.
7. **Tutorial widget override API naming** — `HUD.setWidgetOverride(widgetName: string, state: boolean?)` — widget identifiers (e.g., "CrowdCountWidget", "RelicShelfWidget") must be enum-stable. Owner: FTUE GDD (VS) must codify.
