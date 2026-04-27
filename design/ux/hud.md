# UX Specification: Crowdsmith In-Game HUD

> **Status**: Draft
> **Author**: ux-designer (Sprint 1 Design-Lock — auto-authored 2026-04-27)
> **Last Updated**: 2026-04-27
> **Screen / Flow Name**: `HUD` — `UILayerId.HUD` (`UILayerType.HeadsUpDisplay`)
> **Platform Target**: All (PC, Mobile, Console / Xbox)
> **Related GDDs**: `design/gdd/hud.md` (authoritative mechanic spec, 22 ACs), `design/gdd/game-concept.md` (Pillars 1, 2, 5)
> **Related ADRs**: ADR-0001 (Crowd Replication Strategy — Accepted), architecture.md §3.1, §5.7
> **Related UX Specs**: `design/ux/accessibility-requirements.md` (Standard tier committed 2026-04-27); relic-card.md (to be authored, VS+)
> **Accessibility Tier**: Standard (elevated — photosensitivity reduction toggle + hue-pattern alternative encoding per `design/accessibility-requirements.md`)
> **Source of truth for mechanics**: `design/gdd/hud.md`. This document is authoritative for UX — spacing, tap targets, animation curves, contrast contracts, state-transition choreography, and accessibility annotation. Sprint 2 Vertical Slice build implements against this spec.

---

## 1. Overview

The HUD is the persistent screen-space overlay that makes the match state glanceable without interrupting input. It owns exactly eleven widget instances, all created once at boot and never destroyed — visibility toggled by `MatchStateChanged` state transitions (per HUD GDD Core Rule 2).

**What the HUD does:**
Binds live server data to glanceable screen-space output. Every absorb is visible in the crowd count. Every second is visible in the timer. Every relic earned is visible on the shelf. Every rival's standing is visible in the mini-leaderboard.

**When it is visible:**
The HUD layer (`UILayerId.HUD`, `UILayerType.HeadsUpDisplay`) is always registered and coexists with gameplay. Widget-level `.Visible` is the gating surface, not layer visibility. At layer level, the HUD is always on.

**What it owns:**
- The eleven named widgets (see §2).
- The `MAX-CROWD` debounce state (per HUD GDD Core Rule 5 + architecture.md §3.4).
- The AFK-toggle interaction path (`ToggleParticipation` remote).
- The `HUD.setWidgetOverride(widgetName, stateBool?)` API surface for FTUE tutorial stage handlers.

**What it delegates:**
- Visual style, colors, font assets — to art-director (art bible §7).
- Relic card draft UI — to `UILayerId.RelicDraft` (separate `UILayerType.Menu` layer, Chest System owned).
- Round Result Screen — to Result Screen layer (VS GDD, not yet authored).
- Player nameplates — to `PlayerNameplate` client module (BillboardGui per character, separate concern).
- Chest billboards — to `ChestBillboard` client module.
- Audio cues — to Audio Manager (SFX intent per HUD GDD §Visual/Audio Requirements).

---

## 2. Layout Map

All positions use Roblox `UDim2` with scale-based anchoring except where noted. The dark-plate backing behind each widget is 60–70% black opacity rounded rect per art bible §7. No drop shadows.

### 2.1 Mobile Layout (binding constraint — thumb-reach zones)

```
┌────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────┐  ┌────────────────────────┐  │
│  │  TimerWidget            │  │  MiniLeaderboardWidget  │  │
│  │  top-center             │  │  top-right              │  │
│  │  "2:14"  (M:SS)         │  │  1. Rival — 187         │  │
│  └─────────────────────────┘  │  2. Rival — 142         │  │
│                               │  ─── ─── ─── (strikethrough)│
│                               │  6. You  —  55          │  │
│                               └────────────────────────┘  │
│                                                            │
│                                                            │
│       ╔═══════════════════════════════════╗               │
│       ║   3   (CountdownOverlayWidget)    ║               │
│       ║   full-screen center              ║               │
│       ╚═══════════════════════════════════╝               │
│                         (Countdown:Snap only)              │
│                                                            │
│  ┌──────────┐  ┌──────────────────────────────────────┐  │
│  │ AFKButton│  │ ELIMINATED  (EliminatedLabelWidget)   │  │
│  │ top-right│  │ top-center — if own crowd eliminated  │  │
│  │ "AFK"    │  └──────────────────────────────────────┘  │
│  │(Lobby/   │                                             │
│  │ Cntdwn:R)│                                             │
│  └──────────┘                                             │
│                                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  │
│  │ SoloWaitWidget — center, when #activeRivals == 0   │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
│                                                            │
│  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  │
│  │ LobbyWaitLabelWidget — center, Lobby only          │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
│                                                            │
│  ┌─────────────────────────────────┐                      │
│  │ RelicShelfWidget                │                      │
│  │ bottom-right                    │                      │
│  │ [◉][★][⬡][▢]  ← slots 1-4     │                      │
│  └─────────────────────────────────┘                      │
│  ┌──────────┐              ┌───────────────────────────┐  │
│  │ Joystick │              │ CrowdCountWidget          │  │
│  │ (mobile  │              │ bottom-center             │  │
│  │  only)   │              │ "  210  "                 │  │
│  │ bottom-  │              │ [MAX CROWD flash overlay] │  │
│  │ left     │              └───────────────────────────┘  │
│  └──────────┘                                             │
│                                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  │
│  │ ServerClosingLabelWidget — center (ServerClosing)   │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
└────────────────────────────────────────────────────────────┘
```

### 2.2 Desktop Layout

```
┌────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────┐  │
│  │  CrowdCountWidget   TimerWidget    MiniLeaderboard   │  │
│  │  top-center, large  top-center     top-right         │  │
│  │  "  210  "          "2:14"         1. Rival  — 187   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                            │
│             ╔══════════════════════════════╗               │
│             ║     3                        ║               │
│             ║  (CountdownOverlayWidget)    ║               │
│             ╚══════════════════════════════╝               │
│                    (Countdown:Snap only)                   │
│                                                            │
│  ┌──────────┐  ┌──────────────────────────────────────┐  │
│  │ AFKButton│  │ ELIMINATED  (EliminatedLabelWidget)   │  │
│  │ top-right│  │ top-center, below timer               │  │
│  │(Lobby/   │  └──────────────────────────────────────┘  │
│  │ Cntdwn:R)│                                             │
│  └──────────┘                                             │
│                                                            │
│         ┌───────────────────────────────────────────┐     │
│         │        RelicShelfWidget                   │     │
│         │        bottom-center (desktop)            │     │
│         │     [◉]   [★]   [⬡]   [▢]               │     │
│         └───────────────────────────────────────────┘     │
│                                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  │
│  │ SoloWaitWidget — center                             │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
│                                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  │
│  │ LobbyWaitLabelWidget — center, Lobby only          │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
│                                                            │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐  │
│  │ ServerClosingLabelWidget — center (ServerClosing)   │  │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘  │
└────────────────────────────────────────────────────────────┘
```

**Key layout invariants:**
- No widget overlaps another in its default visible state. `EliminatedLabelWidget` and `SoloWaitWidget` are conditional overlays that never compete with each other (elimination logically precedes solo-wait irrelevance).
- `MaxCrowdFlashWidget` is positioned exactly over `CrowdCountWidget` — same anchor, same size. It is a transparent overlay that only becomes opaque during the 1.0s flash sequence.
- `CountdownOverlayWidget` is full-screen centered with a dark backing plate. It is the only widget that visually dominates the screen.
- AFK button is always in the upper-right corner on both mobile and desktop. It does not shift between platforms — only its pixel anchor changes based on `ViewportSize`.

---

## 3. Per-Widget Specifications

### 3.1 `CrowdCountWidget`

**Purpose:** The dopamine spine of Pillar 1. Displays own crowd count. Drives count-pop animation on upward +10 decade crossing.

**Position:**
- Mobile: `AnchorPoint(0.5, 1.0)`, `Position UDim2(0.5, 0, 1.0, -90)` — bottom-center, 90px above safe-area bottom. Within right-thumb glance zone.
- Desktop: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.0, 16)` — top-center.

**Size:** `UDim2(0, 160, 0, 72)` screen-space. Dark-plate backing occupies full size; `TextLabel` occupies inner `UDim2(1, -16, 1, -8)` with padding.

**Typography:**
- Font: `GothamBold`, `TextScaled = true`, minimum computed size 32px at 1080p (per `design/accessibility-requirements.md` §Visual — "32px @ 1080p for crowd count").
- Text color: `#FFFFFF` (white) on the dark backing plate.
- Contrast: 7:1 minimum against dark backing (per accessibility doc §Visual — "7:1 minimum for HUD count + timer").

**Displayed text:**
- Active: `tostring(count)` — e.g., `"210"`.
- Self-eliminated: `"0"` with subtitle `"— spectating"` at 18px below. Subtitle is a second `TextLabel` child, same backing frame.
- Not-yet-replicated (nil from CSM): `"—"` placeholder (per HUD GDD Edge Cases).
- Stale data (>0.5s broadcast gap): freeze at last known value — no change in display (per HUD GDD Core Rule 6).

**Count-pop animation (Pillar 1):**
Triggered when `F1 = (newCount > oldCount) AND (floor(newCount/10) > floor(oldCount/10))` evaluates `TRUE` (per HUD GDD F1).
- `TweenService`: scale `1.0 → 1.3 → 1.0` over `COUNT_POP_SCALE_DURATION = 0.15s`, `EasingStyle.Back, EasingDirection.Out`.
- Applied to the entire `CrowdCountWidget` frame, not the TextLabel alone, so the backing plate scales with it.
- Single tween per broadcast tick — multi-decade jumps (e.g., Surge +40) produce exactly one pop (per HUD GDD AC-6).
- No pop on downward deltas (toll deductions, collision losses).
- Concurrent-safe: if a second pop trigger arrives while a tween is in flight, `TweenService:Create()` on the same instance cancels the previous tween (Roblox `TweenService` behavior — new tween overwrites). No crash, no stacking (per HUD GDD AC-20).

**Reduce-motion behavior:** When photosensitivity reduction toggle is ON (per accessibility doc), scale-max caps at `1.1` instead of `1.3`. Duration unchanged. The scale bounce is tactile feedback, not decorative motion — it cannot be removed entirely without breaking Pillar 1 feedback loop.

**Data binding:** `CrowdStateClient.CountChanged(ownCrowdId)` signal. Reads `CrowdStateClient.get(ownCrowdId).count`.

**Interaction:** Passive — no tap/click response. Non-interactive in MVP.

**Visibility:** See §4 State Transitions. Shown in Countdown:Ready, Countdown:Snap, Active, Result. Hidden in Lobby, Intermission, ServerClosing.

**Accessibility:**
- Text: 32px minimum at 1080p, `TextScaled = true`, scales on mobile.
- Contrast: 7:1 against dark backing plate.
- No color-only signal — count is a number, not color-coded.
- Reduce-motion: scale-max reduced (see above).

---

### 3.2 `TimerWidget`

**Purpose:** Makes Pillar 3 (5-minute clean rounds) visible. Displays current match-state countdown in M:SS format.

**Position:**
- Mobile: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.0, 12)` — top-center.
- Desktop: top-center, same anchor, shares horizontal space with `CrowdCountWidget` and `MiniLeaderboardWidget` in a horizontal layout via `UIListLayout`.

**Size:** `UDim2(0, 120, 0, 48)`.

**Typography:**
- Font: `GothamBold`, minimum 20px computed at 1080p (per accessibility doc §Visual — "20px for non-critical HUD").
- Normal state: `#FFFFFF` text on dark backing.
- Urgent state (last ≤10s of Active): text shifts to `#FF2222` (red), scale `1.1×` applied to the widget frame via `TweenService` instant-snap (not animated — instant to avoid additive motion during high-pressure final seconds).

**Display formula (HUD GDD F2):**
```
displayedSeconds = clamp(stateEndsAt - (tick() - clockOffset), 0, state_duration)
displayText = string.format("%d:%02d", math.floor(s/60), math.floor(s%60))
```
Updates on whole-second tick only — avoids 60 Hz text thrashing. Clock offset recomputed on each `MatchStateChanged` receipt.

**State-gated content:**
- `Countdown:Ready`: counts `7 → 0` (COUNTDOWN_READY_SEC).
- `Active`: counts `5:00 → 0:00` (ROUND_DURATION_SEC = 300).

**Urgency trigger:** `displayedSeconds <= TIMER_URGENT_THRESHOLD_SEC (10)` during Active. Text turns `#FF2222`, frame scales to `1.1×`. Does not revert until state changes.

**Accessibility:**
- Color shift to red at final 10s is NOT the sole urgency signal — numeric countdown is the primary signal (per accessibility doc §Color-as-Only-Indicator Audit: "bold/blink at <30s"). Bold is already enforced (GothamBold). At ≤10s, text may also pulse opacity `1.0 → 0.85 → 1.0` at 1 Hz for additional urgency without relying on color alone. Reduce-motion: pulse suppressed; color shift retained.
- Contrast: 7:1 minimum in both white and red states against dark backing.
- No pattern encoding needed — timer is numeric text, unambiguous.

**Data binding:** `MatchStateClient.displayedSeconds()` (F6 formula), `RunService.RenderStepped` (per-second whole-tick comparison).

**Interaction:** Passive.

**Visibility:** Shown during `Countdown:Ready` and `Active` only. Hidden all other states (per HUD GDD Core Rule 7 state table and AC-9).

---

### 3.3 `MiniLeaderboardWidget`

**Purpose:** Social pressure readout. Surfaces rival crowd standings at a glance — who is ahead, who is behind. Serves Pillar 2 (Social Anxiety/Identity) by keeping rival threat visible.

**Position:**
- Both platforms: `AnchorPoint(1.0, 0.0)`, `Position UDim2(1.0, -12, 0.0, 12)` — top-right corner, 12px from edge.

**Size:** `UDim2(0, 210, 0, 150)` — 4 rows × 32px height + 22px header-label + padding.

**Layout:** `UIListLayout` vertical, spacing 4px. Each row is a `Frame` containing:
- Rank label `TextLabel` (`"1."`, `"2."`, etc.) — 24px width, right-aligned.
- Name label `TextLabel` — `GothamBold`, 18px minimum, crowd display name, truncated at 12 chars with `"…"` suffix.
- Count label `TextLabel` — right-aligned in row, 18px minimum, `tostring(count)`.
- Row background: signature crowd hue with 20% opacity tint (identity signal — not sole indicator, row rank number is the position signal).
- Eliminated state: row text `Strikethrough = true` (Roblox `TextLabel` property), opacity 50%, linger `ELIM_LINGER_SEC = 5.0s` then row fades out.

**Row count logic (per HUD GDD Core Rule 10):**
- Show top-3 crowds by descending count.
- If own crowd is outside top-3, append a 4th row: `"[rank]. You — [count]"`.
- Maximum 4 rows at any time.
- Tiebreak: secondary sort by `crowdId` ascending (consistent with MSM F4).

**Pattern overlay on rows:**
Per accessibility doc §Hue-pattern alternative encoding: each crowd's row background shows both the signature hue tint AND the crowd's assigned `patternIndex` (stripe / dot / chevron / solid). This is applied as a small 16px pattern swatch on the left edge of each row, ensuring crowd identity reads without color reliance.

**Typography:** `Gotham` regular, 18px minimum for name/count rows. Header label `"RIVALS"` at 16px.

**Data binding:** `CrowdStateBroadcast` unreliable remote (15 Hz), consumed via `CrowdStateClient`.

**Interaction:** Passive. No expand/collapse in MVP (open question OQ-3 from HUD GDD deferred to post-playtest).

**Visibility:** Shown only during `Active` state. Hidden all other states (per HUD GDD state table). Hidden in `Result` state — Round Result Screen takes over placement rendering.

**Accessibility:**
- 18px minimum per row text.
- Contrast 4.5:1 minimum for name/count text against row background (WCAG AA normal text).
- Eliminated state uses strikethrough AND 50% opacity — not color alone.
- Pattern swatch provides hue-independent identity signal per accessibility doc.
- Truncation of long names avoids overflow on small viewports.

---

### 3.4 `RelicShelfWidget`

**Purpose:** Keeps Pillar 2 decisions tangible. Displays the 4 relic slots (filled or empty) so the player always knows their current build state between chest opens.

**Position:**
- Mobile: `AnchorPoint(1.0, 1.0)`, `Position UDim2(1.0, -12, 1.0, -100)` — bottom-right, above safe-area bottom, mirroring the non-movement thumb.
- Desktop: `AnchorPoint(0.5, 1.0)`, `Position UDim2(0.5, 0, 1.0, -24)` — bottom-center.

**Size:** `UDim2(0, 296, 0, 72)` — 4 slots × 64px + 3 gaps × (296 - 256) / 3 ≈ 13px gaps.

**Slot layout:** `UIListLayout` horizontal, `FillDirection = Horizontal`, spacing 10px, sorted by ascending `slotIndex` left-to-right. Each slot is 64×64px.

**Slot visual states:**

| State | Visual |
|-------|--------|
| Empty | Dim outlined placeholder Frame, 50% opacity, no icon, rarity-shape frame not shown |
| Filled — Common | Circle rarity frame, centered `ImageLabel` with `spec.ui.iconAssetId` |
| Filled — Rare | Starburst rarity frame, icon |
| Filled — Epic/Legendary | Hexagon rarity frame, icon |
| Filled — countdown active | Radial `UIGradient` clockhand sweep indicating `ticksRemaining` countdown |
| Unknown specId | `"?"` icon + warn-color (amber) frame (per HUD GDD AC-17) |

Rarity frame shapes are rendered as border `Frame` instances with `UICorner` or as pre-authored `ImageLabel` overlays using `AssetId.UiRelicFrameCommon / UiRelicFrameRare / UiRelicFrameEpic`. Shape is the primary rarity signal; color is secondary (per art bible §7 + accessibility doc §Color-as-Only-Indicator Audit).

**Countdown ring:** When `ticksRemaining` is non-nil, a `UIGradient` applied to a circular overlay Frame creates a clockwise-depleting arc. Client-side interpolation: last `ticksRemaining` value minus frames elapsed since receipt (drift <67ms acceptable, next `CrowdRelicChanged` corrects on expiry).

**Tooltip (per HUD GDD Core Rule 12):**
- Desktop: hover over filled slot → tooltip `BillboardGui` (from `GuiPrefabs/HudTooltip`) appears adjacent to slot with `spec.ui.shortDesc` (60-char max), `Gotham` 14px.
- Mobile: tap-and-hold ≥0.3s → same tooltip. Auto-dismisses on release or 3.0s timeout.
- Tooltip does not interrupt gameplay input — it fires no remotes, acquires no exclusive input lock.
- Tooltip auto-dismisses if widget visibility changes to hidden (hard guard per HUD GDD Edge Cases).

**Data binding:** `CrowdRelicChanged` reliable remote; `RelicRegistry[specId]` client-side boot-loaded for `iconAssetId` and `shortDesc`.

**Interaction:** Tooltip only (non-blocking). No activate/use action from shelf — relics apply passively.

**Visibility:** Shown from `Countdown:Ready` through `Result`. Hidden in Lobby, Intermission, ServerClosing (per state table). Persists through Result so player sees final relic loadout.

**Accessibility:**
- Shape-redundant rarity encoding (circle/starburst/hexagon) per art bible §7 and HUD GDD AC-21. No color-only rarity communication.
- Icon minimum 64×64px tap-target on mobile — exceeds 44×44px minimum per accessibility doc §Motor.
- Tooltip text 14px minimum on white backing (per art bible §7 — "Relic card labels: 10pt absolute minimum" — this spec sets 14px as the HUD tooltip standard, which exceeds the card minimum).
- Empty placeholder at 50% opacity is visually distinct from filled slot without relying on color.

---

### 3.5 `CountdownOverlayWidget`

**Purpose:** Marks the Countdown:Snap moment — the transition from lobby anticipation to active gameplay. Full-screen "3–2–1" provides a shared ritual beat for all players simultaneously.

**Position:** `AnchorPoint(0.5, 0.5)`, `Position UDim2(0.5, 0, 0.5, 0)` — center screen. Full-screen effective due to `CountdownBackingFrame` opacity spanning the `ScreenGui`.

**Structure:**
- `CountdownBackingFrame`: `Frame` sized `UDim2(1, 0, 1, 0)`, `BackgroundTransparency = 0.70` (semi-transparent dark, 70% opacity as specified in HUD GDD Core Rule 8).
- `NumeralLabel`: `TextLabel` centered on backing, `GothamBold`, 96pt, `#FFFFFF`.

**Numeral cycle (per HUD GDD Core Rule 8):**
- Each numeral ("3", "2", "1") displayed for 1.0s (`COUNTDOWN_OVERLAY_NUMERAL_SEC`).
- 0.1s `TextTransparency` tween between numerals (1.0 → 0.0 for each new numeral).
- Total: 3.0s exactly, matching `COUNTDOWN_SNAP_SEC = 3`.
- On state exit to `Active`: `CountdownOverlayWidget.Visible = false` immediately in the same `MatchStateChanged` handler pass (per HUD GDD AC-18 — no stale numeral render).

**Data binding:** `MatchStateChanged` signal — visible only on `Countdown:Snap` entry; `RunService.RenderStepped` for per-second numeral cycle.

**Interaction:** Non-interactive. `ZIndex` high enough to render above other widgets; `Active = false` on the Frame to pass through all input events to gameplay below.

**Visibility:** `Countdown:Snap` only. Hard lock — appearing in any other state is a correctness failure (per HUD GDD state table invariant).

**Accessibility:**
- Large 96pt numeral is readable at all supported sizes and viewing distances.
- Numeric 3–2–1 is language-agnostic — no localization needed.
- No reduce-motion interaction: this overlay is a one-time synchronization beat, not a looping animation.
- 70% backing opacity maintains adequate contrast for numeral text (> 7:1 against average arena background once backing is applied).

---

### 3.6 `AFKButtonWidget`

**Purpose:** Lets players opt in/out of a match during lobby period. Supports cognitive accessibility (social pause) per accessibility doc §Cognitive — "AFKToggle marks player as away; server skips on elimination check."

**Position:**
- Both platforms: `AnchorPoint(1.0, 0.0)`, `Position UDim2(1.0, -12, 0.0, 12)` — top-right.
- On mobile, positioned below `MiniLeaderboardWidget` when leaderboard is visible (leaderboard only shows during Active; AFK button only shows in Lobby/Countdown:Ready — they never coexist, so no visual collision in practice).

**Size:** `UDim2(0, 90, 0, 44)` — minimum 44px height per accessibility doc §Motor tap-target minimum.

**Typography:** `Gotham` regular, 16px minimum. Bold on active state.

**States:**

| `isParticipating` | Button Text | Visual Treatment |
|-------------------|-------------|------------------|
| `true` (participating) | `"AFK"` | Normal/active appearance — tap to mark AFK |
| `false` (AFK) | `"JOIN"` | Highlighted border — tap to re-join |

**Interaction:**
- `TextButton.Activated` event fires `Network.fireServer(RemoteEventName.ToggleParticipation)`.
- Client does NOT optimistically update button state. Waits for server `ParticipationChanged` reliable remote to confirm, then updates text (per HUD GDD Core Rule 9 — "HUD reflects the result, never assumes immediate state change").
- Button `Active = false` (input passthrough disabled) when widget is hidden. Defensive guard against hidden-frame tap events.

**Input method (keyboard/gamepad):**
- The HUD is otherwise non-interactive, but the AFK button IS interactive. It must be keyboard/gamepad reachable during Lobby state.
- Default key binding: `F` (keyboard), `Select / Back` (gamepad — deferred to control manifest; flag here for `ContextActionService` wiring).
- This is remappable per accessibility doc §Motor — `ContextActionService` binding, persisted in `PlayerDataKey.RemappingProfile` (deferred VS+; MVP uses default).

**Visibility:** Shown in `Lobby` and `Countdown:Ready` only. Hidden all other states. Disabled (`.Active = false`) but not destroyed when hidden.

**Accessibility:**
- 44px minimum height tap target met.
- Text label "AFK" / "JOIN" communicates state unambiguously — no color-only signal.
- Keyboard/gamepad reachable via documented binding.
- Contrast: button background must achieve 4.5:1 for button label text. Dark-plate or accent-color backing per art bible §7 satisfies this.

---

### 3.7 `MaxCrowdFlashWidget`

**Purpose:** Announces the momentary achievement of hitting the 300-count cap — a rare, high-reward event (Pillar 1 dopamine moment, elevated). Overlays `CrowdCountWidget` exactly.

**Position:** Same anchor and size as `CrowdCountWidget` — overlay. `ZIndex` one step above `CrowdCountWidget`.

**Structure:** Single `TextLabel` with text `"MAX CROWD"`, `GothamBold`, 20px, `#FFFFFF`, centered on backing. Backing inherits `CrowdCountWidget`'s dark plate (widget is sized identically).

**Animation (per HUD GDD Core Rule 5):**
- Opacity: `0 → 1` over `0.1s`, hold `0.6s`, `1 → 0` over `0.3s`. Total: `1.0s`.
- Implemented as `TextLabel.TextTransparency` tween sequence via `TweenService`. No separate backing — text overlays the count number, briefly replacing it visually.

**Photosensitivity (per accessibility doc §Per-VFX Photosensitivity Audit):**
- `MaxCrowdFlash` concern: full-screen flash potential. Mitigation: this is widget-scoped (NOT full-screen), opacity peak 1.0 (white text, not white screen). The widget was already scoped to the count widget bounds in the GDD — this spec confirms it is NOT a full-screen white flash.
- However, the high-contrast appearance at exactly the moment when `CrowdCountClamped` fires may pair with a `RelicGrantVFX` if a relic was just granted. The HUD owns the debounce (once-per-cap-entry, per architecture.md §3.4 and CSM Batch 1).
- Photosensitivity reduction mode: if toggle is ON, `MaxCrowdFlashWidget` text opacity peak is capped at `0.5` (per accessibility doc §Per-VFX Photosensitivity Audit table — "Cap flash amplitude at 0.5").
- Audio: `HudMaxCrowdFlash` internal signal fires for Audio Manager to play crowd-audio swell (per HUD GDD §SFX intent).

**Trigger:** `CrowdCountClamped` reliable remote (server → owning client, local-filtered). HUD owns once-per-cap-entry debounce (per CSM Batch 1 contract). No repeat-trigger within single `Active` state entry unless count dips below 300 and climbs again.

**Data binding:** `CrowdCountClamped` reliable remote via `CrowdStateClient`.

**Interaction:** Non-interactive. `Active = false`.

**Visibility:** Flash-triggered during `Active` only. `.Visible` managed by animation sequence (set `true` at flash start, `false` at flash end via `TweenInfo` `Completed` callback).

**Accessibility:**
- Non-color identifier: "MAX CROWD" text reads without color dependence.
- Photosensitivity reduction cap confirmed.
- Audio swell (HudMaxCrowdFlash signal to Audio Manager) is the auditory backup per accessibility doc §Gameplay-Critical SFX Audit.

---

### 3.8 `EliminatedLabelWidget`

**Purpose:** Informs the player their crowd has been eliminated. Persists through the Result state so the player understands their position. Does NOT feel punishing — per art bible §2 Mood table (Elimination: "surprise, NOT shame").

**Position:** `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.0, 56)` — top-center, below where `TimerWidget` sits, so it does not collide with the timer.

**Size:** `UDim2(0, 360, 0, 88)`. Contains two TextLabels stacked vertically:
1. `"ELIMINATED"` — `GothamBold` 48pt, `#FF4444` (red-adjacent, not pure red `#FF2222` which would feel punishing — use a slightly softer variant). Fades in over `0.3s` `TextTransparency` tween.
2. `"— spectating"` — `Gotham` regular 18px, `#CCCCCC` subtitle, appears simultaneously.

Note: The art bible §2 states "No red tones — read as punishment" for the Elimination state. This applies to the world-space desaturation effect. The HUD ELIMINATED label uses red-adjacent hue because it must be clearly legible and communicates state — distinct from the world camera effect. This is a UX override of the ambient mood rule; the label must read.

**Fade-in:** `TweenService` `TextTransparency 1.0 → 0.0` over `0.3s` on both labels simultaneously. `EasingStyle.Quad, EasingDirection.Out`.

**CrowdCountWidget behavior during eliminated state:**
- `CrowdCountWidget` text switches to `"0"` with `"— spectating"` subtitle (handled at `EliminatedLabelWidget` show time — `CrowdCountWidget` receives a separate signal path; see §3.1).

**Persistence:** Widget remains visible through `Result` state (per HUD GDD Core Rule 13 and AC-16). Not cleared by `MatchStateChanged → Result`.

**Data binding:** `CrowdEliminated` reliable signal for own `crowdId`, via `CrowdStateClient`.

**Interaction:** Passive.

**Visibility:** Shown when own crowd eliminated during `Active`; persists through `Result`. Hidden in all other states.

**Accessibility:**
- Text communicates state without color reliance — "ELIMINATED" label is sufficient text.
- Red hue on label is backed by explicit text, not color-only signal.
- 48pt minimum exceeds readability threshold for all supported devices.
- Off-screen elimination directional indicator (for observing other eliminations): per accessibility doc §Auditory — "Off-screen elimination: screen-edge directional indicator pointing toward source." This indicator is NOT a HUD widget — it is a separate lightweight overlay system owned by the VFX Manager or a dedicated `OffscreenIndicator` component (implementation dependency flag — see §11 Open Questions). The `EliminatedLabelWidget` only covers own-crowd elimination.

---

### 3.9 `SoloWaitWidget`

**Purpose:** Informs the player they are the last active crowd in the match — solo-win timer is running. Reduces confusion about why nothing is happening.

**Position:** `AnchorPoint(0.5, 0.5)`, `Position UDim2(0.5, 0, 0.45, 0)` — slightly above center (avoids conflict with `CrowdCountWidget` at bottom-center).

**Size:** `UDim2(0, 420, 0, 64)`.

**Content:** `TextLabel`, `Gotham` regular, 20px minimum. Text: `"Waiting for rivals: [N]s"` where N is the solo-wait countdown timer value (MSM F7 `SOLO_WAIT_SEC`).

**Update:** Per `MatchStateChanged` state changes and a local countdown via `RunService.Heartbeat` — displays remaining solo-wait seconds.

**Dismissal:** `SoloWaitWidget.Visible = false` on next `MatchStateChanged` event that is not `Active` with `#activeRivals == 0`, or when a rival crowd rejoins/activates (per HUD GDD Edge Cases — "MSM F7 cancels the solo-win timer; HUD removes SoloWaitWidget on next MatchStateChanged").

**Data binding:** `MatchStateChanged`, `CrowdStateBroadcast` (to detect `#activeRivals == 0`), and derived local countdown.

**Interaction:** Passive.

**Visibility:** Shown during `Active` when `#activeRivals == 0`. Hidden all other states.

**Accessibility:**
- Text communicates condition and countdown numerically — no color reliance.
- 20px minimum text size.

---

### 3.10 `LobbyWaitLabelWidget`

**Purpose:** Sets player expectation in the lobby — how many players are needed before the round starts.

**Position:** `AnchorPoint(0.5, 0.5)`, `Position UDim2(0.5, 0, 0.5, 0)` — center screen.

**Size:** `UDim2(0, 440, 0, 80)`.

**Content:** `TextLabel`, `GothamBold`, 24px. Text: `"Waiting for players ([N]/[maxPlayers])"` — N = current participant count, maxPlayers = server capacity (e.g., `"Waiting for players (4/8)"`).

**Update:** Per `MatchStateChanged` events and `Players.PlayerAdded` / `Players.PlayerRemoving` on client.

**Data binding:** `MatchStateChanged`, client `Players` API.

**Interaction:** Passive.

**Visibility:** Shown in `Lobby` only. Hidden once `MatchStateChanged` transitions to `Countdown:Ready`.

**Accessibility:**
- 24px text minimum.
- Numeric format does not rely on color.

---

### 3.11 `ServerClosingLabelWidget`

**Purpose:** Informs players the server is shutting down cleanly. Prevents confusion about sudden disconnection.

**Position:** `AnchorPoint(0.5, 0.5)`, `Position UDim2(0.5, 0, 0.5, 0)` — center screen.

**Size:** `UDim2(0, 440, 0, 80)`.

**Content:** `TextLabel`, `GothamBold`, 24px, `#FFFFFF`. Text: `"Server closing"`.

**Data binding:** `MatchStateChanged == "ServerClosing"`.

**Interaction:** Passive.

**Visibility:** `ServerClosing` state only.

**Accessibility:** Text communicates state without color reliance. 24px minimum.

---

## 4. State Transitions

This section documents what changes per widget across all seven match states. Derived from HUD GDD state table (§States and Transitions). The `MatchStateChanged` handler updates all widget `.Visible` properties in a single pass before the next render frame.

### 4.1 State Visibility Table

| Widget | Lobby | Countdown:Ready | Countdown:Snap | Active | Result | Intermission | ServerClosing |
|--------|-------|-----------------|----------------|--------|--------|--------------|---------------|
| `CrowdCountWidget` | hidden | shown | shown | shown | shown | hidden | hidden |
| `TimerWidget` | hidden | shown (7→0) | hidden | shown (5:00→0:00) | hidden | hidden | hidden |
| `RelicShelfWidget` | hidden | shown (empty) | shown | shown | shown | hidden | hidden |
| `MiniLeaderboardWidget` | hidden | hidden | hidden | shown | hidden | hidden | hidden |
| `CountdownOverlayWidget` | hidden | hidden | shown | hidden | hidden | hidden | hidden |
| `AFKButtonWidget` | shown | shown | hidden | hidden | hidden | hidden | hidden |
| `EliminatedLabelWidget` | hidden | hidden | hidden | shown if self-elim | shown if self-elim | hidden | hidden |
| `SoloWaitWidget` | hidden | hidden | hidden | shown if `#rivals==0` | hidden | hidden | hidden |
| `LobbyWaitLabelWidget` | shown | hidden | hidden | hidden | hidden | hidden | hidden |
| `ServerClosingLabelWidget` | hidden | hidden | hidden | hidden | hidden | hidden | shown |
| `MaxCrowdFlashWidget` | hidden | hidden | hidden | flash-trigger | hidden | hidden | hidden |

### 4.2 Transition Choreography

**Lobby → Countdown:Ready:**
- `AFKButtonWidget` remains shown (no change).
- `LobbyWaitLabelWidget` hides (instant).
- `CrowdCountWidget` shows (instant — preview mode; count may be 0 or starting value).
- `RelicShelfWidget` shows (instant — all 4 slots empty).
- `TimerWidget` shows with `COUNTDOWN_READY_SEC = 7` starting value.

**Countdown:Ready → Countdown:Snap:**
- `AFKButtonWidget` hides (instant — enforces MSM asymmetric freeze per HUD GDD Core Rule 9).
- `TimerWidget` hides (instant).
- `CountdownOverlayWidget` shows — numeral cycle "3 → 2 → 1" begins immediately.

**Countdown:Snap → Active:**
- `CountdownOverlayWidget` hides (same handler pass as timer show — per HUD GDD AC-18, no stale numeral).
- `TimerWidget` shows with `ROUND_DURATION_SEC = 300`.
- `MiniLeaderboardWidget` shows (first `CrowdStateBroadcast` populates rows).

**Active → Result:**
- `TimerWidget` hides.
- `MiniLeaderboardWidget` hides (Result Screen takes over placement rendering).
- `CrowdCountWidget`, `RelicShelfWidget`, `EliminatedLabelWidget` (if applicable) persist.
- `MaxCrowdFlashWidget` hides if mid-flash; any in-flight tween completes (acceptable per HUD GDD Edge Cases).

**Result → Intermission:**
- All widgets hidden except none — full HUD hidden for Intermission duration.

**Any → ServerClosing:**
- All widgets immediately hidden except `ServerClosingLabelWidget` which becomes shown.

### 4.3 Invariants

- `CountdownOverlayWidget` visible ONLY during `Countdown:Snap` — correctness-critical (per HUD GDD state table invariant).
- `AFKButtonWidget` hidden during `Countdown:Snap` regardless of previous state.
- `EliminatedLabelWidget` and `SoloWaitWidget` do not replace `CrowdCountWidget` — they overlay independently.
- `RelicShelfWidget` persists from `Countdown:Ready` through `Result` — slot continuity across transitions.
- Single-pass visibility update on `MatchStateChanged` — no per-widget independent handlers for state-gated visibility; one handler function iterates all widgets.

---

## 5. Pillar 1 — Dopamine Moments

Pillar 1 (Snowball Dopamine): "Every absorb must feel intrinsically great." The HUD is the visual spine of this pillar — absorb + count pop + audio chime are a single unified beat.

### 5.1 Count-Pop Animation Full Spec

**Trigger:** `F1 = (newCount > oldCount) AND (floor(newCount / 10) > floor(oldCount / 10))` evaluates `TRUE`.

**Tween parameters:**
```
TweenService:Create(
    CrowdCountWidget,                   -- Target: the widget Frame
    TweenInfo.new(
        COUNT_POP_SCALE_DURATION,       -- 0.15s default
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out,
        0,                              -- repeatCount
        false,                          -- reverses
        0                               -- delayTime
    ),
    { Size = SCALE_MAX_SIZE }           -- 1.3x of base size
)
```

The widget `Size` tween goes from `BASE_SIZE` → `SCALE_MAX_SIZE` → `BASE_SIZE` (two-phase: `Back Out` handles the bounce-back naturally via overshoot). Both the dark plate and the TextLabel scale together.

**Scale max:** `COUNT_POP_SCALE_MAX = 1.3` → `SCALE_MAX_SIZE = UDim2(0, 208, 0, 94)` (160×72 × 1.3). At 1.3×, the widget expands into center-screen without overlapping `TimerWidget` (vertical separation is ≥80px on mobile).

**Reduce-motion:** Scale-max capped at `1.1` → `SCALE_MAX_SIZE = UDim2(0, 176, 0, 79)`.

**Audio sync:** `HudCountPop` internal signal fires on tween start. Audio Manager may play optional chime. Risk of spam at high absorb rate noted in HUD GDD OQ-2 — Audio Manager resolves separately. HUD fires signal unconditionally on each pop; Audio Manager controls frequency.

**Multiple pops in one broadcast tick:** Only the terminal `CountChanged` signal from a given broadcast is processed (CSM broadcasts a single count value per tick, not a delta stream). The `F1` formula collapses multi-decade jumps to a single pop naturally.

**Concurrent animation safety:** If a new pop triggers while a previous tween is in flight, `TweenService:Create()` on the same instance cancels the previous tween. No nil-reference risk; `CrowdCountWidget` instance persists for client lifetime (per HUD GDD Core Rule 2 + AC-20).

### 5.2 MaxCrowdFlash — Full Trigger Spec

**Trigger chain:**
1. Server: `CSM.updateCount` hits ceiling clamp at `MAX_CROWD_COUNT = 300`.
2. Server fires `CrowdCountClamped` reliable `RemoteEvent` to owning player (local-filtered, not broadcast).
3. Client `CrowdStateClient` receives and fires local signal.
4. HUD consumes — checks debounce (once-per-cap-entry guard).
5. `MaxCrowdFlashWidget` animation sequence plays.

**Debounce contract (per CSM Batch 1 + architecture.md §3.4):**
HUD owns a boolean `_maxCrowdFlashDebounce`. Set `true` on flash start. Reset to `false` on next `MatchStateChanged` event that is not `Active`, or when own crowd count drops below 300 (observable from next `CrowdStateBroadcast`). While `true`, incoming `CrowdCountClamped` signals are silently dropped.

**Animation sequence:**
```
Phase 1: TextTransparency 1.0 → 0.0, duration 0.1s, EasingStyle.Quad Out
Phase 2: hold 0.6s (no tween — task.delay)
Phase 3: TextTransparency 0.0 → 1.0, duration 0.3s, EasingStyle.Quad In
Total: 1.0s
MaxCrowdFlashWidget.Visible = false after Phase 3 completes
```

**Photosensitivity reduction mode:** Peak `TextTransparency` is `0.5` instead of `0.0` (text shows at 50% opacity instead of full). Duration unchanged.

**State-gate:** Flash only executes during `Active` match state. If `CrowdCountClamped` arrives in any other state (e.g., race condition during Result), it is silently dropped (per HUD GDD Edge Cases: "Flash still visible because count widget persists through Result" — this spec is more restrictive. If the count widget is visible in Result, and the flash is still in-flight from Active transition, the in-flight flash completes, but no new flash initiates in Result state).

**Audio:** `HudMaxCrowdFlash` internal signal fires, Audio Manager plays crowd-audio swell.

### 5.3 Absorb Count Flash Sync with `AbsorbCue` Audio

The `AbsorbCue` audio (fired by VFX Manager on each absorb event) and the count-pop animation are not directly synchronized in code — they are synchronous through the broadcast cadence. The absorb → CSM.updateCount → P8 broadcastAll → CrowdStateClient.CountChanged → HUD pop path means the pop fires at most 67ms (one broadcast tick) after the absorb event that triggered the audio. At 15 Hz this is imperceptible — the beat of "snap + chime + pop" lands as unified per HUD GDD §Player Fantasy.

No explicit synchronization primitives are required. The broadcast loop is the sync mechanism.

---

## 6. Pillar 2 — Identity Rendering

Pillar 2 (Risky Chests, per HUD GDD): "The relic shelf is Pillar 2 kept tangible between opens." However, for the HUD's identity rendering responsibility, this section covers how own-crowd identity is encoded in the HUD surface — specifically the hue + pattern-overlay encoding per accessibility doc §Hue-pattern alternative encoding.

### 6.1 Hue Encoding in HUD

The HUD directly renders crowd identity in two locations:

1. **`MiniLeaderboardWidget` row backgrounds** — each row's signature hue tint identifies the crowd.
2. **`RelicShelfWidget` slot frames** — rarity-color frames signal relic tier (NOT crowd identity; rarity color encoding is separate).

For item 1: the hue tint on leaderboard rows is the primary crowd-identity signal in the HUD. However, per accessibility doc (Standard-elevated, §Hue-pattern alternative encoding): "Pattern palette has 8 distinct entries; assigned alongside hue at CrowdCreated time."

### 6.2 Pattern-Overlay Encoding (Mandatory)

Each crowd is assigned a `patternIndex` at `CrowdCreated` time (CSM Batch 1 amendment — `{crowdId, hue, patternIndex}` in payload per accessibility doc). The pattern is one of: `Stripe / Dot / Chevron / Cross / Diagonal / Wave / Grid / Solid`.

**HUD surfaces that must render pattern:**

| Widget | Pattern application | Method |
|--------|--------------------|---------| 
| `MiniLeaderboardWidget` row left edge | 16×32px pattern swatch | Small `Frame` with `UIPattern` or pre-authored 16×32 `ImageLabel` per pattern type, tinted with crowd hue |
| `MiniLeaderboardWidget` "You" row | Same pattern swatch | Own crowd's assigned pattern |

Pattern swatches do NOT need to appear on `CrowdCountWidget` (own identity is unambiguous — it's the player's own number). Pattern encoding serves peer-crowd discrimination, which only the leaderboard requires in the HUD layer. (Nameplates and follower bodies carry pattern in world-space — that is `PlayerNameplate` and `FollowerEntity` concern.)

**Pattern ImageLabel assets:** `AssetId.UiPatternStripe`, `AssetId.UiPatternDot`, etc. 8 total assets, 16×32px each, white-on-transparent (tinted via `ImageColor3` = crowd signature hue). Asset registry at `SharedConstants/AssetId.luau`.

**Why pattern is mandatory (not optional):**
Per accessibility doc §Hue-pattern alternative encoding: "Required — Pillar 2 identity-signaling cannot rely on hue alone." This is a Standard-elevated commitment. Any implementation that omits pattern encoding from leaderboard rows fails the accessibility tier requirement.

### 6.3 Relic Shelf Identity

The relic shelf does not encode crowd identity — it encodes relic rarity (shape) and relic type (icon). The player's own-crowd identity context for the shelf is implicit (it's always your own shelf). No pattern encoding needed on shelf slots.

---

## 7. Pillar 5 — Comeback Signaling

Pillar 5 (Comeback Always Possible): small crowd can win via smart chest play. The HUD's role in Pillar 5 is subtle: it must NOT visually shame low count, and it must NOT over-signal the grace-window state in a way that telegraphs vulnerability to rivals.

### 7.1 Grace-Window Visual Treatment

The grace-window is a server-side CSM state (`CrowdState.GraceWindow`) applied when a crowd's count hits 1 while overlapping a larger rival. It is a brief timer-protected window before elimination. Per HUD GDD: HUD receives `CrowdEliminated` on elimination, not during the grace-window itself.

**HUD behavior during grace-window:**
- `CrowdCountWidget` continues displaying count normally (count = 1 or near-1).
- No special "grace" indicator in the HUD. The GraceWindow state is NOT surfaced to the player in the HUD — it is a server-side protection mechanic, and surfacing it would expose vulnerability information.
- The `EliminatedLabelWidget` does NOT show during GraceWindow — it only shows on confirmed `CrowdEliminated` signal.

**Rationale (UX theory — affordance and mental model):** Making the grace-window invisible to the HUD removes the "nearly dead" signal that could cause cognitive panic and poor decision-making. The player can only observe it indirectly through count dropping near 1. This is intentional — Pillar 5 requires the player to feel capable of a comeback, not pre-defeated.

### 7.2 Comeback-Rescue Moments

The following HUD moments create positive feedback for comeback scenarios:

1. **Count pop after low-count absorb:** If a crowd is at count 5 and absorbs enough neutrals to cross 10, the count-pop fires. Even at tiny counts, the pop fires — it does not have a minimum-count threshold. This gives low-count players immediate positive feedback.

2. **Relic shelf slot fills after chest open:** When a player opens a chest at any count and receives a relic, `RelicShelfWidget` updates with the new icon. The visual "slot filled" moment signals capability, not weakness. This is a key Pillar 5 HUD beat.

3. **SoloWait countdown:** If all rivals are eliminated (solo-win scenario), `SoloWaitWidget` counts down visibly. This countdown is the player's reward signal — they can see the win approaching.

### 7.3 Eliminated State — Non-Punishing Design

Per art bible §2 Mood table: "Elimination: surprise, NOT shame." HUD implementation:
- `EliminatedLabelWidget` fades in (smooth, 0.3s — not a jarring flash).
- "— spectating" subtitle is calm, informational.
- No color changes to the environment triggered by HUD (world-space desaturation is world-space VFX concern).
- No "LOSER" language. "ELIMINATED" is factual.
- Queue button / next-round prompt is owned by Result Screen (separate GDD) — HUD does not render it, ensuring the "next round within 2 seconds" Pillar 5 requirement is handled by the appropriate layer.

---

## 8. Accessibility Annotations

This section provides per-widget accessibility annotation as required by the project accessibility checklist. Source of requirements: `design/accessibility-requirements.md` Standard tier (elevated for photosensitivity + pattern encoding).

### 8.1 Text Size Requirements

| Widget | Text Element | Required Size | Basis |
|--------|-------------|---------------|-------|
| `CrowdCountWidget` | Count number | 32px minimum @ 1080p | Accessibility doc §Visual — "32px @ 1080p for crowd count" |
| `CrowdCountWidget` | "— spectating" subtitle | 18px minimum | Accessibility doc §Visual — "20px for non-critical HUD" (rounded down for subtitle context) |
| `TimerWidget` | Timer text (M:SS) | 20px minimum | Accessibility doc §Visual — "20px for non-critical HUD" |
| `MiniLeaderboardWidget` | Row name + count | 18px minimum | Accessibility doc §Visual — leaderboard rows fall in non-critical HUD category |
| `RelicShelfWidget` | Tooltip text | 14px minimum | Art bible §7 — "Relic card labels: 10pt absolute minimum"; HUD spec sets higher floor |
| `AFKButtonWidget` | Button label | 16px minimum | Accessibility doc §Visual — "24px @ 1080p for menu UI" (button is small; 16px is the floor for legibility) |
| `CountdownOverlayWidget` | Numeral (3/2/1) | 96pt (locked) | HUD GDD Core Rule 8 |
| `EliminatedLabelWidget` | "ELIMINATED" | 48pt (locked) | HUD GDD Core Rule 13 |
| `EliminatedLabelWidget` | "— spectating" | 18px minimum | Non-critical subtitle |
| `LobbyWaitLabelWidget` | Wait text | 24px minimum | Menu-adjacent text size floor |
| `ServerClosingLabelWidget` | Status text | 24px minimum | Same |
| `SoloWaitWidget` | Countdown text | 20px minimum | Non-critical HUD |
| `MaxCrowdFlashWidget` | "MAX CROWD" text | 20px minimum | Non-critical — brief flash |

All TextLabel instances use `TextScaled = false` with explicit font size in points (not `TextScaled = true`) to guarantee minimum sizes are honoured. Roblox `TextScaled` can scale text down on smaller viewports — explicit sizing with `UIConstraint.MinTextSize` guards the floor. Alternatively: use `TextScaled = true` with `TextSizeConstraint.MaxTextSize` and `MinTextSize` set per the table above.

### 8.2 Contrast Requirements

| Widget | Background | Text Color | Required Ratio | Notes |
|--------|-----------|------------|---------------|-------|
| `CrowdCountWidget` | Dark plate (~#1A1A1A, 60-70% opacity) | `#FFFFFF` | 7:1 minimum | Accessibility doc §Visual — HUD count 7:1 (WCAG AAA) |
| `TimerWidget` | Dark plate | `#FFFFFF` normal / `#FF4444` urgent | 7:1 normal; 4.5:1 urgent red | Urgent red #FF4444 achieves 4.5:1 against dark plate |
| `MiniLeaderboardWidget` rows | Crowd-hue tint (~20% opacity over dark plate) | `#FFFFFF` or `#EEEEEE` | 4.5:1 minimum | WCAG AA normal text; verify each hue-tint combination |
| `RelicShelfWidget` tooltip | White backing | `#1A1A1A` | 4.5:1 minimum | Art bible §7 tooltip uses white card backing |
| `AFKButtonWidget` | Dark plate + accent | `#FFFFFF` | 4.5:1 minimum | Button label contrast |
| `CountdownOverlayWidget` numeral | Dark overlay (70% backing) | `#FFFFFF` | >7:1 against darkened bg | 70% black overlay ensures high contrast |
| `EliminatedLabelWidget` | Dark plate | `#FF4444` | 4.5:1 minimum | Red text on dark backing — achieves AA |
| `LobbyWaitLabelWidget` | Dark plate | `#FFFFFF` | 4.5:1 minimum | Non-critical |
| `MaxCrowdFlashWidget` | Transparent (over count widget dark plate) | `#FFFFFF` | 7:1 | Same backing as count widget |

All ratios are verified against the dark plate backing (`#1A1A1A` at 60-70% opacity). In practice, verify with the Coblis contrast tool using a screenshot of the HUD at each state in the final implementation.

### 8.3 Photosensitivity Reduction Mode

| Widget | Effect | Reduction-mode behavior |
|--------|--------|------------------------|
| `CrowdCountWidget` | Scale pop 1.0→1.3→1.0 | Scale max capped at 1.1 |
| `MaxCrowdFlashWidget` | Opacity 0→1→0 flash | Opacity peak capped at 0.5 (50% opacity) |
| `CountdownOverlayWidget` | Numeral fade 0.1s transitions | No reduction — single occurrence, not rapid |
| `TimerWidget` | Opacity pulse at <10s | Pulse suppressed; red color shift retained |
| `EliminatedLabelWidget` | Fade-in 0.3s | No reduction — single occurrence |

Toggle stored in `Settings` layer, applied via `HudConfig.reduceMotion: boolean`. HUD reads this flag at widget-animation call sites.

### 8.4 Pattern-Overlay Encoding

Per §6.2 above — `MiniLeaderboardWidget` rows render a 16×32px pattern swatch (the crowd's assigned `patternIndex`) on the left edge of each row. This is mandatory for Standard-elevated accessibility tier. Pattern provides crowd identity without relying on hue alone, ensuring players with protanopia/deuteranopia/tritanopia can distinguish rival crowds.

Pattern swatch size: 16×32px. This is below the 44×44px interactive tap-target threshold — however, the swatch is non-interactive (display only), so the minimum tap-target does not apply.

### 8.5 Off-Screen Elimination Directional Indicator

Per accessibility doc §Auditory — "Off-screen elimination: screen-edge directional indicator." This is Standard-elevated. The indicator shows when an `EliminationCue` event fires for a crowd that is off-screen relative to the local player's camera.

Implementation surface: A separate lightweight overlay widget (not one of the 11 primary HUD widgets) — an `OffscreenIndicatorWidget` that renders a small arrow icon at the screen edge pointing toward the eliminated crowd's last position. It auto-fades after 2.0s.

This widget is considered an **accessibility-required extension** to the 11-widget spec. It is owned by the same `UIHud.luau` layer module but counted separately. It subscribes to `CrowdEliminated` reliable remote (all crowds, not just own) + camera orientation.

Implementation dependency: requires `WorldToViewportPoint` API to determine if a 3D position is within the camera frustum. This is a standard Roblox API within training data — no post-cutoff risk.

### 8.6 Input Accessibility

The HUD is non-interactive in MVP except:
- `AFKButtonWidget` (keyboard/gamepad reachable — see §9).
- Relic tooltip on `RelicShelfWidget` (hover/tap-hold only, no keyboard-required interaction).
- Relic tooltip is display-only and not a blocking interaction, so it does not need keyboard-only accessibility — it falls under the "not keyboard-required" category (information also available via gameplay and relic shelf icon alone).

---

## 9. Input Handling

The HUD is a passive display layer in MVP. This section documents the complete input contract.

### 9.1 Input-Interactive Elements

| Widget | Input | Platform | Action | Notes |
|--------|-------|----------|--------|-------|
| `AFKButtonWidget` | `TextButton.Activated` | Touch / Mouse click | Fires `ToggleParticipation` remote | Only active when `Visible = true` (Lobby / Countdown:Ready) |
| `AFKButtonWidget` | Default key `F` | Keyboard | Same as above | `ContextActionService` binding; remappable (Standard tier motor) |
| `AFKButtonWidget` | Gamepad `Select` | Xbox controller | Same as above | Flag for control manifest; deferred binding until vs. sprint |
| `RelicShelfWidget` slot | Mouse hover | PC | Show tooltip | Passive — no game state change |
| `RelicShelfWidget` slot | Touch tap-hold ≥0.3s | Mobile | Show tooltip | Passive — no game state change |
| Pause trigger | `Esc` | Keyboard | Opens `UILayerId.PauseMenu` | Handled by `PauseMenu` layer, NOT by HUD; HUD has no pause behavior |
| Pause trigger | Gamepad `Start` | Xbox controller | Opens `UILayerId.PauseMenu` | Same — not HUD-owned |

### 9.2 Non-Interactive Widgets

All widgets except `AFKButtonWidget` are pure display. Their `Frame.Active = false` at all times. No `TextButton` instances except `AFKButtonWidget`. No `InputBegan` connections on HUD widgets except the tooltip tap-hold gesture detector on `RelicShelfWidget`.

### 9.3 Pause Menu Interaction

The `PauseMenu` (UILayerId.PauseMenu, `UILayerType.Menu`) opens over the HUD layer. The HUD remains rendered beneath it — per HUD GDD Core Rule 1 (HeadsUpDisplay type coexists) and UIHandler behavior. The HUD does not respond to `PauseMenu` open/close events; its widget visibility is governed solely by `MatchStateChanged`.

### 9.4 FTUE Override API

Tutorial stage handlers may need to highlight or hide specific HUD widgets. The HUD exposes:

```lua
HUD.setWidgetOverride(widgetName: string, state: boolean?)
-- state = true: force visible
-- state = false: force hidden
-- state = nil: clear override, resume normal state-gated visibility
```

Accepted `widgetName` values (enum-stable identifiers):
- `"CrowdCountWidget"`
- `"TimerWidget"`
- `"RelicShelfWidget"`
- `"MiniLeaderboardWidget"`
- `"CountdownOverlayWidget"`
- `"AFKButtonWidget"`
- `"EliminatedLabelWidget"`
- `"SoloWaitWidget"`
- `"LobbyWaitLabelWidget"`
- `"ServerClosingLabelWidget"`
- `"MaxCrowdFlashWidget"`

Override is cleared on `teardown(player)` of the FTUE stage handler. If a `MatchStateChanged` fires while an override is active, the normal visibility computed by the state table is held in a pending variable and applied when the override is cleared (do not immediately overwrite override with state-computed value — the tutorial lock must hold).

---

## 10. Implementation References

### 10.1 Layer Module Ownership

The HUD is implemented in:
- **Primary module:** `src/ReplicatedStorage/Source/UI/UILayers/HudLayer/init.luau` (to be created in Core epic — does not exist yet as of 2026-04-27).
- **Widget sub-modules:** `src/ReplicatedStorage/Source/UI/UILayers/HudLayer/[WidgetName].luau` (one per widget, following `HudConfig.luau` tuning-knob imports).

### 10.2 Template Pattern Reference

The canonical implementation pattern is `UIExampleHud.luau` (template-provided). The HUD must follow this pattern exactly:

```lua
-- src/ReplicatedStorage/Source/UI/UILayers/HudLayer/init.luau
--!strict

local UIHandler = require(...)
local UILayerId = require(...SharedConstants.UILayerId)
local UILayerType = require(...SharedConstants.UILayerType)

local HudLayer = {}
HudLayer.__index = HudLayer

function HudLayer.setup(parent: ScreenGui)
    -- 1. Create root ScreenGui child frame (or use parent directly)
    -- 2. Instantiate all 11 widgets (once — never recreated)
    -- 3. Register with UIHandler
    local visibilityChangedSignal = UIHandler.registerLayer(
        UILayerId.HUD,
        UILayerType.HeadsUpDisplay,
        HudLayer
    )
    -- 4. Connect visibilityChangedSignal (layer-level on/off — rarely fires for HUD)
    -- 5. Connect MatchStateChanged for widget-level visibility updates
    -- 6. Connect per-widget data sources (CountChanged, CrowdStateBroadcast, etc.)
end

function HudLayer.teardown()
    -- Disconnect all connections via Janitor
end

return HudLayer
```

Key requirements from `UIExampleHud.luau` pattern:
- `setup(parent)` creates `ScreenGui` with `ResetOnSpawn = false`, `ZIndexBehavior = Sibling`.
- Calls `UIHandler.registerLayer(UILayerId.HUD, UILayerType.HeadsUpDisplay, self)`.
- Connects to the returned `visibilityChangedSignal`.
- All connections managed by `Janitor` (destroyed in `teardown`).

### 10.3 Data Sources Summary

| Widget | Source Module | Remote/Signal | Call |
|--------|-------------|---------------|------|
| `CrowdCountWidget` | `CrowdStateClient` | `CountChanged` signal | `CrowdStateClient.get(ownCrowdId).count` |
| `TimerWidget` | `MatchStateClient` | `RunService.RenderStepped` | `MatchStateClient.displayedSeconds()` |
| `RelicShelfWidget` | Network | `CrowdRelicChanged` reliable RemoteEvent | `{crowdId, slots: {RelicSnapshot}}` |
| `MiniLeaderboardWidget` | `CrowdStateClient` | `CrowdStateBroadcast` unreliable | Full crowd table |
| `CountdownOverlayWidget` | `MatchStateClient` | `MatchStateChanged` | State `"Countdown:Snap"` |
| `AFKButtonWidget` | Network | `ParticipationChanged` reliable | `{isParticipating}` |
| `EliminatedLabelWidget` | `CrowdStateClient` | `CrowdEliminated` reliable | Own crowdId match |
| `SoloWaitWidget` | `MatchStateClient` + `CrowdStateClient` | `MatchStateChanged` + broadcast | `#activeRivals == 0` derived |
| `LobbyWaitLabelWidget` | `MatchStateClient` + `Players` | `MatchStateChanged` + `PlayerAdded/Removing` | Player count N |
| `ServerClosingLabelWidget` | `MatchStateClient` | `MatchStateChanged` | State `"ServerClosing"` |
| `MaxCrowdFlashWidget` | `CrowdStateClient` | `CrowdCountClamped` reliable | Own crowdId, debounced |

### 10.4 Constants Module

All tuning knobs live in `src/ReplicatedStorage/Source/SharedConstants/HudConfig.luau`:

```lua
-- HudConfig.luau (to be created)
return {
    COUNT_POP_SCALE_DURATION = 0.15,    -- seconds
    COUNT_POP_SCALE_MAX = 1.3,          -- multiplier
    MAX_CROWD_FLASH_DURATION = 1.0,     -- seconds total
    MAX_CROWD_FLASH_FADE_IN = 0.1,      -- seconds
    MAX_CROWD_FLASH_HOLD = 0.6,         -- seconds
    MAX_CROWD_FLASH_FADE_OUT = 0.3,     -- seconds
    TIMER_URGENT_THRESHOLD_SEC = 10,    -- seconds
    LEADERBOARD_ROW_COUNT = 3,          -- top-N shown + self
    ELIM_LINGER_SEC = 5.0,              -- eliminated row linger
    REDUCE_MOTION_SCALE_MAX = 1.1,      -- cap when reduceMotion = true
    REDUCE_MOTION_FLASH_OPACITY = 0.5,  -- max flash opacity when reduceMotion = true
}
```

### 10.5 Widget Prefab Location

Per HUD GDD §Where knobs live:
- Tooltip BillboardGui prefabs: `src/ReplicatedStorage/Instances/GuiPrefabs/HudTooltip`
- Widget prefabs: `src/ReplicatedStorage/Instances/GuiPrefabs/HudWidgets/`
- Layer entry: `src/ReplicatedStorage/Source/UI/UILayers/HudLayer/init.luau`

### 10.6 UILayerId and UILayerType Registration

Confirmed in `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau` (shipped):
- `UILayerId.HUD = "HUD"` registered.

Confirmed in `src/ReplicatedStorage/Source/SharedConstants/UILayerTypeByLayerId.luau` (shipped):
- `[UILayerId.HUD] = UILayerType.HeadsUpDisplay` mapped.

No changes needed to either file. HUD layer module calls `UIHandler.registerLayer(UILayerId.HUD, UILayerType.HeadsUpDisplay, self)` and the type is resolved from the shipped registry.

---

## 11. Open Questions

The following questions remain unresolvable from current source documents and require creative-director, art-director, or engineering input before this spec can be marked Approved.

| # | Question | Owner | Deadline | Impact |
|---|----------|-------|----------|--------|
| OQ-1 | **AFK button placement on mobile (HUD GDD OQ-3):** Current spec places AFK at top-right. On mobile, this may visually crowd the `MiniLeaderboardWidget` column. However, since leaderboard is only visible during Active and AFK button only during Lobby/Countdown:Ready, they never coexist — this resolves the concern without requiring position change. Confirm this logic is acceptable, or flag if playtest reveals otherwise. | ux-designer + playtest | First multi-player playtest | Layout |
| OQ-2 | **Off-screen elimination directional indicator ownership:** §8.5 identifies this as a Standard-elevated accessibility requirement. Implementation surface is ambiguous — HUD layer vs. VFX Manager vs. a dedicated `OffscreenIndicator` module. Recommend: owned by HUD layer (it is a 2D screen-space UI element, not a 3D VFX). Requires engineering confirmation from `ui-programmer` before Core epic scoping. | ui-programmer + ux-designer | Pre-Core epic scoping | Implementation |
| OQ-3 | **Pattern-overlay asset design for leaderboard rows:** The 8 pattern assets (`UiPatternStripe`, `UiPatternDot`, etc.) need art-direction sign-off on size, density, and legibility at 16×32px. They must be distinguishable from each other in greyscale (accessibility test: disable hue, verify 8 patterns distinct). Owner: art-director. | art-director | Before Core epic art asset sprint | Visual |
| OQ-4 | **`EliminatedLabelWidget` red hue vs. art bible §2 "No red tones" rule:** §3.8 explains the rationale for using red-adjacent `#FF4444` for the label despite the art bible's mood-table note (which applies to world-space elimination visuals). This is a UX-side override proposal. Requires art-director sign-off to confirm the distinction is correct and no visual conflict exists. | art-director + ux-designer | Before art pass on HUD | Visual |
| OQ-5 | **Leaderboard collapse on mobile (HUD GDD §Tuning Knobs note):** HUD GDD mentions "Collapsible if needed post-playtest." This spec does not implement collapse (no `LEADERBOARD_ROW_COUNT` change + no tap-to-toggle). If playtest shows leaderboard is visually crowding on small phones (iPhone SE 375px width), the `MiniLeaderboardWidget` may need a tap-to-toggle "pill" version. Flag for first playtest report. Owner: ux-designer post-playtest. | ux-designer | Post first playtest | Layout |
| OQ-6 | **Tooltip on `RelicShelfWidget` — keyboard accessibility:** Relic tooltips are show-on-hover/tap-hold only. For keyboard users (no hover), the tooltip is inaccessible. However, relic tooltips are supplemental information (the icon already communicates the relic family category via icon family shape), not gameplay-critical. This spec treats tooltips as non-critical supplemental and does not require keyboard accessibility. Confirm this is acceptable under Standard accessibility tier or flag for Comprehensive. | ux-designer + producer | Pre-VS build | Accessibility |
| OQ-7 | **HUD GDD OQ-5 / CSM `CrowdCountClamped` signal status:** Per HUD GDD §Provisional assumptions point 1 — "RESOLVED 2026-04-24 via CSM Batch 1." This spec treats the signal as confirmed. If CSM implementation deviates from the payload contract `{crowdId, attemptedDelta, clampedCount}`, `MaxCrowdFlashWidget` trigger must be adjusted. Owner: gameplay-programmer (CSM implementation). | gameplay-programmer | Before HUD Core story implementation | Wire contract |

---

*Spec scope: Sprint 1 Design-Lock. Implementation epic: Core (HUD Layer). Implementation story references: `UILayerId.HUD` + `UILayerType.HeadsUpDisplay` registered (shipped). `UIHud.luau` creation story in Core epic backlog.*

*This document is the authoritative UX specification for `design/gdd/hud.md`. Stories referencing specific HUD widgets must cite this doc for UX detail and the HUD GDD for mechanic ACs.*
