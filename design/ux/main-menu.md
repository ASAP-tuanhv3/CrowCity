# UX Specification: Crowdsmith Main Menu

> **Status**: Draft
> **Author**: ux-designer (Sprint 1 Design-Lock — auto-authored 2026-04-27)
> **Last Updated**: 2026-04-27
> **Screen / Flow Name**: `MainMenu` — `UILayerId.MainMenu` (`UILayerType.Menu`)
> **Platform Target**: All (PC, Mobile, Console / Xbox)
> **Related GDDs**: `design/gdd/game-concept.md` (Pillars 1, 3, 4, 5; target audience; session-level loop)
> **Related ADRs**: ADR-0001 (Crowd Replication Strategy), ADR-0011 (persistence schema — `OwnedSkins`, `SelectedSkin`, `Coins`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`)
> **Related UX Specs**: `design/ux/hud.md` (sibling spec — pattern conventions, typography minimums, UIHandler registration, data binding tables); `design/accessibility-requirements.md` (Standard tier committed 2026-04-27)
> **Related Art Docs**: `design/art/art-bible.md` §3 Shape Language, §4 Color System, §7 UI/HUD Visual Direction, §8.4 Material Standards / Neon-permit policy
> **Accessibility Tier**: Standard (per `design/accessibility-requirements.md` §Tier Definitions)
> **Source of truth for mechanics**: `design/gdd/game-concept.md`. This document is authoritative for UX — layout, tap targets, typography minimums, contrast contracts, state transitions, data binding, and accessibility annotations. Sprint 2 Vertical Slice build implements against this spec.

---

## 1. Overview

The main menu is the top-of-session identity and navigation surface. It is the first thing a returning player sees after the loading screen resolves and the first thing a new player sees after the FTUE photosensitivity warning screen clears. It is the game's **identity display surface** (Pillar 4 — Cosmetic Expression) and the **single primary call-to-action surface** (Play button enters the matchmaking queue).

**What the main menu does:**
Displays the player's current cosmetic state (equipped skin, Coins balance), surfaces lifetime achievement milestones (LifetimeAbsorbs, LifetimeWins), and provides entry points to the Shop (skin selection), Settings (accessibility + audio + input-remap), and the Roblox-platform matchmaking queue.

**When it is visible:**
- After the loading screen finishes and player data is ready (normal boot path).
- After returning from a completed match round (Intermission → main menu restore path — see §4).
- Hidden during active gameplay (another `UILayerType.Menu` layer opening eclipses it; the HUD layer is always coexistent with gameplay).
- Never visible simultaneously with `UILayerId.PauseMenu` or `UILayerId.RelicDraft` — all three are `UILayerType.Menu` and UIHandler enforces mutex (one Menu open at a time; opening any Menu closes the previous).

**What it owns:**
- The eight named widgets described in §3.
- The Play → matchmaking entry-point interaction.
- The Shop and Settings button entry-point interactions (navigation only — the panels themselves are separate layers, out of scope for this spec).
- The `SelectedSkin` preview display (follower model render or icon — see §3.6 and OQ-3).
- The Coins balance display (read-only surface, no purchase/spend here).
- The lifetime stats display (LifetimeAbsorbs + LifetimeWins, read-only).

**What it delegates:**
- Visual style, exact color values, font assets — to art-director (`art-bible.md` §7).
- Shop panel content (skin selection, purchase flows) — to `UILayerId.Shop` (future spec `design/ux/shop.md` — not authored as of this date).
- Settings panel content (accessibility sliders, audio buses, input remap) — to `UILayerId.Settings` (future spec — not authored as of this date).
- Roblox-managed UI surface — the top-bar, chat panel, leaderboard, and friends list are all Roblox platform UI. This spec does NOT attempt to replicate or position those elements. Section §1.1 documents what we explicitly do not own.
- Audio cues on button presses — to Audio Manager (SFX intent flagged per widget in §3).
- Loading screen (boot-phase — completes before main menu is shown) — separate concern.

### 1.1 Roblox-Managed UI — What We Do NOT Own

The following Roblox platform elements are always on-screen in a Roblox experience. This spec positions our widgets to avoid visual conflict with them but does not design or modify them:

| Element | Roblox Position | Crowdsmith Layout Response |
|---------|----------------|---------------------------|
| Roblox top-bar (menu, settings icon, volume, leaderboard) | Top-left and top-right corners (approximately 36px tall) | All Crowdsmith widgets use `Position.Y.Offset ≥ 48px` from top to avoid overlap |
| On-screen chat button/panel | Bottom-left (mobile) or dedicated sidebar (PC) | No Crowdsmith widgets occupy bottom-left on mobile during main menu; Play button is bottom-center |
| Friends online count | Roblox top-bar area | No conflict — Crowdsmith branding is top-center |

`ScreenGui.IgnoreGuiInset = false` is recommended for the main menu layer — let Roblox inset handling push content below the top-bar automatically. (Contrast with HUD: `IgnoreGuiInset = true` was used there to allow full-screen positioning. Main menu does not need full-bleed positioning; the inset safe-zone is acceptable.)

---

## 2. Layout Map

All positions use Roblox `UDim2` scale-based anchoring. The semi-transparent dark backing plate (60–70% black opacity, `UICorner` radius 8px, per `art-bible.md §3 UI Shape Grammar`) applies to all interactive widgets and stats panels. No drop shadows (per art bible §7 Legibility Strategy: "No drop shadows as primary legibility").

Mobile is the binding constraint (per CLAUDE.md Technical Preferences — "Mobile-first layout — Roblox audience skews mobile").

### 2.1 Mobile Layout (Portrait-orientation binding constraint)

```
┌──────────────────────────────────────────────────────────────┐
│  [Roblox top-bar — NOT owned — 36px tall]                    │
│  ────────────────────────────────────────────────────────    │
│                                                              │
│                 ┌────────────────────────┐                  │
│                 │  TitleBrandingWidget   │                  │
│                 │  top-center            │                  │
│                 │  "CROWDSMITH" logo     │                  │
│                 │  (ImageLabel)          │                  │
│                 └────────────────────────┘                  │
│                                                              │
│  ┌──────────────────────┐   ┌──────────────────────────┐   │
│  │  SkinPreviewWidget   │   │  CoinsBalanceWidget      │   │
│  │  left-center         │   │  right-center            │   │
│  │  [follower icon]     │   │  ⬡ 1,240                 │   │
│  │  "FollowerCity1"     │   │  (Coins balance label)   │   │
│  └──────────────────────┘   └──────────────────────────┘   │
│                                                              │
│           ┌────────────────────────────────────┐            │
│           │       LifetimeStatsWidget          │            │
│           │       center                       │            │
│           │   ⚑ 2,847 absorbs   ★ 14 wins     │            │
│           └────────────────────────────────────┘            │
│                                                              │
│           ┌────────────────────────────────────┐            │
│           │           PlayButtonWidget         │            │
│           │      PRIMARY CTA — center          │            │
│           │           ▶  PLAY                  │            │
│           └────────────────────────────────────┘            │
│                                                              │
│  ┌──────────────────────┐   ┌──────────────────────────┐   │
│  │    ShopButtonWidget  │   │  SettingsButtonWidget    │   │
│  │    left of center    │   │  right of center         │   │
│  │    [shop icon] SHOP  │   │  [gear icon] SETTINGS    │   │
│  └──────────────────────┘   └──────────────────────────┘   │
│                                                              │
│                                                              │
│  [Roblox chat — NOT owned — bottom-left]                     │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Desktop Layout (Landscape — 16:9 reference at 1080p)

```
┌──────────────────────────────────────────────────────────────┐
│  [Roblox top-bar — NOT owned]                                │
│  ────────────────────────────────────────────────────────    │
│                                                              │
│              ┌──────────────────────────────┐               │
│              │      TitleBrandingWidget     │               │
│              │      top-center              │               │
│              │      "CROWDSMITH" logo       │               │
│              └──────────────────────────────┘               │
│                                                              │
│  ┌──────────────────┐                ┌──────────────────┐   │
│  │  SkinPreviewWidget│               │  CoinsBalance    │   │
│  │  left-center      │               │  top-right       │   │
│  │  [icon + label]   │               │  ⬡ 1,240         │   │
│  └──────────────────┘                └──────────────────┘   │
│                                                              │
│              ┌──────────────────────────────┐               │
│              │    LifetimeStatsWidget       │               │
│              │    center                    │               │
│              │  ⚑ 2,847 absorbs  ★ 14 wins │               │
│              └──────────────────────────────┘               │
│                                                              │
│              ┌──────────────────────────────┐               │
│              │       PlayButtonWidget       │               │
│              │       PRIMARY CTA            │               │
│              │       ▶  PLAY                │               │
│              └──────────────────────────────┘               │
│                                                              │
│       ┌────────────────┐       ┌──────────────────┐         │
│       │ ShopButton     │       │  SettingsButton  │         │
│       │ [shop icon]    │       │  [gear icon]     │         │
│       │ SHOP           │       │  SETTINGS        │         │
│       └────────────────┘       └──────────────────┘         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Key layout invariants:**
- `TitleBrandingWidget` is always top-center. It does not shift between platforms.
- `PlayButtonWidget` is always the visually dominant element — largest single interactive element on screen.
- `ShopButtonWidget` and `SettingsButtonWidget` are always presented as a symmetric pair below Play.
- `CoinsBalanceWidget` is always top-right (mirroring the Roblox "Robux" balance position in the top-bar — spatial proximity to the platform currency provides an intuitive inventory-overview scan).
- `SkinPreviewWidget` is always left-aligned on both platforms (portrait: left-center; landscape: left panel) — persistent left position establishes it as the player's identity display, distinct from the right-side economy surface.
- On mobile, all interactive targets (Play, Shop, Settings) are positioned in the lower two-thirds of the screen — within mobile thumb-reach zone per Fitts's Law considerations.
- `LifetimeStatsWidget` is center, below the skin/coins row and above the Play button — it provides context ("why I play") before the player commits to the CTA.

---

## 3. Per-Widget Specifications

### 3.1 `TitleBrandingWidget`

**Purpose:** Establishes game identity at boot. First thing a player reads after the loading screen. Sets the visual tone (Pillar 4 — identity; art bible §1 Visual Identity Statement — "bold silhouette, no gradients, no realism").

**Position:**
- Both platforms: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.0, 56)` — top-center, 56px below top edge (sufficient clearance below 36px Roblox top-bar with 20px breathing room).

**Size:** `UDim2(0, 360, 0, 96)` on mobile; `UDim2(0, 480, 0, 120)` on desktop.

**Content:**
- Primary content: `ImageLabel` containing the Crowdsmith logo/wordmark asset (`AssetId.UiBrandLogo` — to be created by art-director).
- Fallback text: if `AssetId.UiBrandLogo` is not yet available (pre-art sprint), a `TextLabel` reading `"CROWDSMITH"`, `GothamBold`, 48px on mobile / 64px on desktop, `#FFFFFF`, no backing plate — the wordmark is always on a visually clean area.
- No backing plate — title is the hero element, not subordinate to a panel.

**Animation:**
- On layer show (`VisibleNormal` state entry): fade in via `BackgroundTransparency 1.0 → 0.0` or `ImageTransparency 1.0 → 0.0` over `0.4s`, `EasingStyle.Quad, EasingDirection.Out`. Reduce-motion: instant show (no tween) when photosensitivity reduction toggle is ON.
- No looping animation. Static after entrance. (Looping/idle menu animation is a potential post-launch polish item — see §10 Open Questions OQ-1.)

**Neon permit:** Per `art-bible.md §8.4` — Neon material is permitted on "chest VFX emitters + ability indicators + UI billboards ONLY. Never on structural geometry." Logo wordmark may use Neon-adjacent color (#00CFFF Cyan or #FF2D78 Hot Pink) for accent highlights if art-director approves per §8.4. Default wordmark is white (`#F5F5F5`) on neutral background.

**Data binding:** Static — no PlayerData reads. Asset ID only.

**Interaction:** Non-interactive. `Frame.Active = false`.

**Visibility:** Shown in `VisibleNormal` and `Loading` and `Connecting` and `ErrorState`. Hidden in `Hidden` and `Eclipsed`.

**Accessibility:**
- ImageLabel: provide a descriptive `Name` property (`"CrowdsmithLogo"`) for any screen-reader accessibility annotation.
- Fallback TextLabel (if used): 48px minimum at mobile exceeds 28px menu minimum (per `design/accessibility-requirements.md §Visual` — "28px @ portrait orientation due to viewing distance").
- No color-only signal — the wordmark communicates brand identity, not a game state. Color is decorative.
- No flashing on entrance. Fade-in is single-occurrence, non-looping.

---

### 3.2 `PlayButtonWidget`

**Purpose:** Primary CTA (Call to Action). Enters the Roblox matchmaking queue or returns to an active match. The visual hierarchy must make this the player's most obvious next action (Fitts's Law — large target, prominent position, high contrast).

**Position:**
- Mobile: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.60, 0)` — 60% down from top, center. Within thumb-reach zone on phones ≥5.5 inches.
- Desktop: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.58, 0)` — similar vertical band.

**Size:**
- Mobile: `UDim2(0, 280, 0, 72)` — 72px height exceeds the 44px minimum tap target; visually dominant.
- Desktop: `UDim2(0, 360, 0, 80)`.

**Structure:**
- `TextButton` instance (not `ImageButton` — text label is the primary identity signal for accessibility).
- Label text: `"PLAY"` (normal / matchmaking-idle state) or `"RETURN TO MATCH"` (if a match is in progress — see §4 State Transitions).
- Font: `GothamBold`, 32px on mobile / 36px on desktop.
- Background: Accent color (art-director assigns — art bible §4 Primary Palette does not specify a UI CTA color; this spec recommends a desaturated-warm-white `#E8E8E8` or the player's assigned skin hue as a tint — see OQ-2 for creative-direction question).
- `UICorner` radius 8px per art bible §3 Shape Grammar.
- Bold `UIStroke` outline 2-3px (per art bible §3 — "Bold outlines 2-3px equivalent on interactive elements").

**States:**

| State | Button Text | Visual Treatment |
|-------|-------------|-----------------|
| `Idle` (no active match) | `"PLAY"` | Normal appearance |
| `Loading` (player data still loading) | `"PLAY"` (greyed) | `Active = false`; opacity 50%; non-interactive |
| `Connecting` (post-click, queue entering) | `"JOINING..."` | `Active = false`; spinner icon or text pulse; non-interactive during connect |
| `InMatch` (server has an active match for this player) | `"RETURN TO MATCH"` | Same size and position; text changes only |
| `ErrorState` | `"PLAY"` (greyed) | `Active = false`; error notice is handled by `ErrorNoticeWidget` (see §3.8) |

**Interaction:**
- `TextButton.Activated` fires `Network.fireServer(RemoteEventName.RequestJoinMatch)` (to be defined in Sprint 2 — see §8 Implementation References).
- Client enters `Connecting` state immediately on button press (optimistic UI for responsiveness — button disables and shows "JOINING..." before server confirmation).
- If server responds with failure (full server, etc.), client reverts to `Idle` state and shows `ErrorNoticeWidget` with specific error text.
- No double-fire protection needed at UX layer — `Active = false` during `Connecting` blocks repeat presses.

**Keyboard / Gamepad:**
- Default keyboard: `Enter` or `Space` when Play button has focus.
- Default gamepad: `A` button (ButtonA).
- Tab navigation: Play button should be the first focusable element in tab order after screen loads. Gamepad navigation wraps: Play → Shop → Settings → Play.

**Audio:** On `Activated`: `PlayButtonPress` audio cue (SFX intent — Audio Manager owns asset). On `Connecting` → failure revert: `ErrorCue` audio cue.

**Accessibility:**
- Minimum 72px height on mobile — 28px above 44px minimum tap target per `design/accessibility-requirements.md §Motor`.
- Text label "PLAY" communicates action without icon reliance — no color-only signal.
- `Loading` and `Connecting` states both disable via `Active = false` AND reduce opacity to 50% — two non-color signals for non-interactive state (opacity + text change).
- Keyboard and gamepad reachable per §7.
- Contrast: button label `#1A1A1A` on light backing OR `#FFFFFF` on dark/accent backing — 4.5:1 minimum in both variants (verify against final art-director color assignment).

---

### 3.3 `ShopButtonWidget`

**Purpose:** Entry point to the cosmetic shop. Surfaces skin selection (Pillar 4 — Cosmetic Expression). The shop panel itself (browsing, preview, purchase) is out of scope for this spec; this widget is navigation only.

**Position:**
- Mobile: `AnchorPoint(1.0, 0.0)`, `Position UDim2(0.39, 0, 0.74, 0)` — left of center-axis, below Play button. In a symmetric pair with SettingsButtonWidget.
- Desktop: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.38, 0, 0.73, 0)` — same left-of-center placement.

**Size:**
- Mobile: `UDim2(0, 140, 0, 56)` — 56px height meets 44px minimum.
- Desktop: `UDim2(0, 160, 0, 60)`.

**Structure:**
- `TextButton` with leading icon (`ImageLabel` child, 28×28px, left-aligned within button) + text label.
- Label: `"SHOP"`, `GothamBold`, 20px. Icon: `AssetId.UiIconShop` (flat 2-color icon per art bible §7 Iconography — "All icons flat, 2-color max").
- `UICorner` radius 8px. `UIStroke` 2px outline.

**Data binding:** Static — no PlayerData reads. (New skin notification badge: see OQ-4 — unresolved.)

**Interaction:**
- `TextButton.Activated` fires `UIHandler.show(UILayerId.Shop)` — opens the Shop layer, which eclipses MainMenu (Menu mutex). When Shop closes, MainMenu restores to `VisibleNormal` (see §4 Eclipsed state).
- Note: `UILayerId.Shop` does not yet exist as of 2026-04-27. Sprint 2 will create it. This button's activation is a forward dependency.

**Keyboard / Gamepad:**
- Keyboard: `Tab` from Play, focus shop button, `Enter`/`Space` to activate.
- Gamepad: `LB` (LeftBumper) shortcut OR D-pad left from Play to navigate to Shop.
- Gamepad shortcut binding is flagged for the control manifest (deferred VS+ per `design/accessibility-requirements.md §Motor`).

**Accessibility:**
- 56px minimum height on mobile — exceeds 44px tap-target minimum.
- Label "SHOP" is unambiguous without icon (icon is supplementary, not sole identifier).
- Contrast: 4.5:1 minimum for "SHOP" text against backing color.

---

### 3.4 `SettingsButtonWidget`

**Purpose:** Entry point to accessibility and input settings. Ensures settings are always one tap from the main menu (per `design/accessibility-requirements.md` Standard tier — settings must be "findable at all times, not buried in submenus").

**Position:**
- Mobile: `AnchorPoint(0.0, 0.0)`, `Position UDim2(0.61, 0, 0.74, 0)` — symmetric to ShopButtonWidget (right of center-axis, same vertical band).
- Desktop: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.62, 0, 0.73, 0)`.

**Size:** Same as ShopButtonWidget — `UDim2(0, 140, 0, 56)` mobile / `UDim2(0, 160, 0, 60)` desktop. Symmetric pairing is intentional affordance — equal visual weight signals equal importance.

**Structure:**
- `TextButton` with gear icon (`AssetId.UiIconSettings`, 28×28px) + `"SETTINGS"` label, `GothamBold`, 20px.
- `UICorner` radius 8px. `UIStroke` 2px outline. Same visual treatment as ShopButtonWidget.

**Interaction:**
- `TextButton.Activated` fires `UIHandler.show(UILayerId.Settings)`.
- Note: `UILayerId.Settings` does not yet exist as of 2026-04-27. Same Sprint 2 forward dependency as ShopButtonWidget.

**Keyboard / Gamepad:**
- Keyboard: `Tab` from Shop, focus settings button, `Enter`/`Space` to activate.
- Gamepad: `RB` (RightBumper) shortcut OR D-pad right from Play.

**Accessibility:**
- 56px height exceeds 44px minimum.
- Label "SETTINGS" is the highest-priority accessibility surface label — it must be legible at minimum font size without icon reliance. Icon is supplementary.
- Settings button must ALWAYS be visible and enabled — never greyed or hidden during `Loading` or `Connecting` states (player may need to access accessibility settings at any time).
- Contrast: 4.5:1 minimum.

---

### 3.5 `LifetimeStatsWidget`

**Purpose:** Surfaces the player's lifetime achievement data (LifetimeAbsorbs + LifetimeWins) as a persistent reward signal. Per Pillar 4 (Cosmetic Expression — "Meta progression is identity") and game-concept.md §Retention Hooks ("Investment: skin collection, leaderboard rank"). Showing lifetime stats creates a sense of owned history — each returning player sees evidence of their investment.

**Position:**
- Both platforms: `AnchorPoint(0.5, 0.0)`, `Position UDim2(0.5, 0, 0.47, 0)` — center, between skin/coins row and the Play button.

**Size:** `UDim2(0, 340, 0, 56)` — single horizontal row showing two stats side by side.

**Structure:**
- Backing: dark plate `UICorner` 8px, 65% opacity.
- Two `TextLabel` children in a `UIListLayout` horizontal, equal widths.
- Left stat: absorb count — format: `"[icon] [N,NNN] absorbs"` where icon is `AssetId.UiIconAbsorb` (16×16px flat inline icon), N formatted with comma separators, `Gotham` regular, 20px minimum.
- Right stat: win count — format: `"[icon] [N] wins"` where icon is `AssetId.UiIconStar` (16×16px), same typography.
- Separator: a 1px `Frame` vertical divider at center of the widget, 60% opacity. Not a color-only element — the distinct text labels are the primary identifiers.

**Number formatting:**
- LifetimeAbsorbs ≥ 1,000: use comma-separator format (`"1,247 absorbs"`). ≥ 1,000,000: `"1.2M absorbs"`.
- LifetimeWins: no abbreviation needed at expected ranges (tens to low hundreds at MVP).
- Zero-state (new player, LifetimeAbsorbs = 0, LifetimeWins = 0): display `"0 absorbs"` and `"0 wins"` — do not hide the widget. The zero state contextualizes the player's first session. This connects to FTUE — see §9.

**Data binding:**
```
PlayerDataClient.getValue(PlayerDataKey.LifetimeAbsorbs) -- integer
PlayerDataClient.getValue(PlayerDataKey.LifetimeWins)    -- integer
```
Rebind on `PlayerDataUpdated` signal (in case data loads late or is updated mid-session). Read once on `setup()`, then subscribe.

**Interaction:** Passive — non-interactive. `Frame.Active = false`. No expand/collapse.

**Visibility:** Shown in `VisibleNormal`. Hidden in `VisiblePreLogin` (no data yet), `Loading`, `Connecting`, `ErrorState`, `Hidden`, `Eclipsed`.

**Accessibility:**
- 20px minimum font per accessibility doc §Visual — "24px @ 1080p for menu UI" (this widget is non-critical ambient information, reduced to 20px floor; 24px recommended target).
- Number + label text format ensures no color-only communication (the stat labels "absorbs" and "wins" are textual, not color-coded).
- Icons are supplementary — if icon asset is unavailable, text label alone is sufficient.
- Contrast: 4.5:1 minimum for stat text against dark backing.

---

### 3.6 `SkinPreviewWidget`

**Purpose:** Displays the currently equipped skin (SelectedSkin). This is the primary Pillar 4 (Cosmetic Expression) surface on the main menu — the player's identity is broadcast via their crowd, so the main menu must surface that identity visually. Seeing their skin before entering a match reinforces "my crowd looks like me."

**Position:**
- Mobile: `AnchorPoint(0.0, 0.0)`, `Position UDim2(0.04, 0, 0.26, 0)` — left side, middle of screen.
- Desktop: `AnchorPoint(0.0, 0.0)`, `Position UDim2(0.05, 0, 0.28, 0)` — similar left-panel position.

**Size:**
- Mobile: `UDim2(0, 120, 0, 140)` — tall enough for a follower icon with name label below.
- Desktop: `UDim2(0, 140, 0, 160)`.

**Structure:**
- Backing: dark plate `UICorner` 8px, 65% opacity.
- Primary content: `ImageLabel` sized to fill upper 80% of widget (`UDim2(1, -16, 0.80, -8)`) displaying the equipped skin's preview icon (`AssetId["UiSkinPreview_" .. selectedSkin]` — resolved from SelectedSkin enum key).
- Skin name label: `TextLabel` at bottom 20% of widget, `Gotham` regular, 16px, text = human-readable skin name (e.g., `"City 1"` for `FollowerCity1`). Name must not be the raw enum key.
- "Change" affordance label (optional — see OQ-5): small secondary `TextLabel` or `TextButton` labelled `"Change"` beneath the skin name, that triggers `UIHandler.show(UILayerId.Shop)`. Provides a direct path from identity preview to the shop. Deferred to creative-direction decision — see §10 OQ-5.

**Skin name mapping (MVP — 5 reserved skins):**

| PlayerDataKey value | Display name |
|--------------------|-------------|
| `FollowerDefault` | `"Default"` |
| `FollowerCity1` | `"City 1"` |
| `FollowerCity2` | `"City 2"` |
| `FollowerNeon` | `"Neon"` |
| `FollowerEvent1` | `"Event I"` |

**Missing asset fallback:** If `AssetId["UiSkinPreview_" .. selectedSkin]` is nil (asset not yet uploaded), show the `ImageLabel` with a placeholder icon (`AssetId.UiSkinPreviewPlaceholder`) + the skin name label. Never show an empty panel.

**Data binding:**
```
PlayerDataClient.getValue(PlayerDataKey.SelectedSkin) -- SelectedSkin enum key (string)
```
Rebind on `PlayerDataUpdated`. If SelectedSkin changes while main menu is visible (e.g., player just purchased and equipped in Shop, then returned), the preview updates immediately.

**Interaction:** Non-interactive in baseline MVP. `Frame.Active = false`. (The "Change" affordance in OQ-5, if approved, would make this a `TextButton` — see §10.)

**Visibility:** Shown in `VisibleNormal`. Hidden in `VisiblePreLogin`, `Loading`, `Connecting`, `ErrorState`, `Hidden`, `Eclipsed`.

**Accessibility:**
- ImageLabel skin icon: 16px minimum text for the skin name label. Skin identity is communicated by both icon AND text name — not icon alone.
- No color-only signal — skin identity uses both icon (shape/silhouette) and text name.
- If skin preview is not loaded/available, the fallback placeholder + text name ensures the widget is never informationally empty.
- Contrast: 4.5:1 minimum for skin name label against dark backing.

---

### 3.7 `CoinsBalanceWidget`

**Purpose:** Surfaces the player's Coins balance (soft currency) — keeping the economy surface-area visible at the main menu primes players to consider shop purchases (Pillar 4 — Cosmetic Expression). Mirrors the Roblox platform Robux display pattern (top-right) so players apply their existing mental model: "the number in the top corner is my money."

**Position:**
- Mobile: `AnchorPoint(1.0, 0.0)`, `Position UDim2(0.96, 0, 0.26, 0)` — right side, symmetric to `SkinPreviewWidget` left position.
- Desktop: `AnchorPoint(1.0, 0.0)`, `Position UDim2(0.95, 0, 0.28, 0)`.

**Size:** `UDim2(0, 120, 0, 52)` — compact; does not dominate the screen (economy surface should be visible, not a focal point competing with Play button).

**Structure:**
- Backing: dark plate `UICorner` 8px, 65% opacity.
- Inline icon: `ImageLabel` `AssetId.UiIconCoin` (20×20px, coin symbol — flat 2-color per art bible §7).
- Balance label: `TextLabel` right of icon, `GothamBold`, 22px, `#FFFFFF`. Format: comma-separated integer (e.g., `"1,240"`). Maximum display: 999,999 — above that, display `"1.0M+"`.
- "Coins" sub-label (optional): small `Gotham` regular 12px beneath the balance number reading `"COINS"`. Provides context for first-time players who have not yet associated the coin icon with the currency (see OQ-6 for direction).

**Data binding:**
```
PlayerDataClient.getValue(PlayerDataKey.Coins) -- integer
```
Rebind on `PlayerDataUpdated`.

**Earn-animation (Pillar 1 adjacent):**
When Coins value increases while the main menu is visible (e.g., returning from a match and PlayerData updates), trigger a count-up animation: the number counts from old value to new value over 0.8s using a lerp formula. This makes currency earnings visible and satisfying — same principle as the HUD count-pop. Reduce-motion: instant update (no tween).

**Interaction:** Passive — non-interactive. `Frame.Active = false`. Coins are not spent from the main menu directly (Shop layer handles purchases).

**Visibility:** Shown in `VisibleNormal`. Hidden in `VisiblePreLogin`, `Loading`, `Connecting`, `ErrorState`, `Hidden`, `Eclipsed`.

**Accessibility:**
- 22px minimum exceeds 24px recommended for menu UI — verify against final implementation at 1080p. If below 24px computed at 1080p, increase to 24px.
- Number + "COINS" label: no color-only signal. The amount is a number; the currency type is labeled in text.
- Icon is supplementary to the label — contrast ratio of coin icon outline to backing: 3:1 minimum (large graphic, per WCAG §1.4.11).
- Contrast of balance text: 4.5:1 minimum.

---

### 3.8 `ErrorNoticeWidget`

**Purpose:** Communicates transient error conditions — server full, data load failure, connection timeout — without navigating the player away from the main menu. Provides actionable context: what failed, and what the player can do next.

**Position:** `AnchorPoint(0.5, 1.0)`, `Position UDim2(0.5, 0, 0.58, -8)` — centered just above the Play button. Appears as an informational overlay in the same vertical zone as the Play button so the player's eye naturally reads error → button.

**Size:** `UDim2(0, 320, 0, 52)`.

**Structure:**
- Backing: dark plate `UICorner` 8px, 80% opacity (slightly higher opacity than other widgets — error state warrants full readability).
- Icon: `ImageLabel` `AssetId.UiIconWarning` (16×16px, amber warning symbol) — left-aligned within widget.
- Message: `TextLabel`, `Gotham` regular, 18px, text content is dynamic (see error types below).

**Error types and message text:**

| Error Condition | Display Text | Play button state |
|----------------|-------------|-------------------|
| Server full | `"No open servers — try again shortly"` | Re-enabled after 3s |
| Data load timeout | `"Could not load your data — tap to retry"` | Re-enabled (triggers retry) |
| Network error | `"Connection issue — check your connection"` | Re-enabled after 3s |
| Unknown | `"Something went wrong — please retry"` | Re-enabled after 3s |

**Auto-dismiss:** Error notice auto-hides after 6.0s (per `design/accessibility-requirements.md §Cognitive` — "Notification toasts: ≥5s display"). Non-actionable errors dismiss automatically. For `data load timeout`, the notice persists until player retries or dismisses.

**Interaction:**
- Non-interactive except for data load timeout case: `TextButton.Activated` on the notice frame triggers `Network.fireServer(RemoteEventName.RequestPlayerDataRetry)` (forward dependency — Sprint 2).
- For non-interactive errors: `Frame.Active = false`.

**Visibility:** Hidden by default (`Visible = false`). Shown programmatically by `MainMenuLayer` on error signal receipt. Auto-hides after display duration.

**Accessibility:**
- 18px minimum text.
- Error state communicated by text AND amber icon — not by color (red) alone.
- Message text is descriptive — not "Error code 503."
- Auto-dismiss at 6.0s satisfies the ≥5s display requirement for notification toasts.
- If the user has motored their way into a retry loop (repeated data-load failures), the notice persists — it does not flash or strobe.
- Contrast: 4.5:1 for message text against dark backing.

---

## 4. State Transitions

The main menu layer (`UILayerId.MainMenu`, `UILayerType.Menu`) has seven distinct states. State changes are handled by a single `MatchStateChanged` + `UIHandler` visibility handler pass in `MainMenuLayer.luau`.

### 4.1 State Definitions

| State | When Active | What Is Visible |
|-------|-------------|----------------|
| `Hidden` | During active gameplay (in-match), during `Eclipsed` sub-state | Nothing — layer disabled |
| `VisiblePreLogin` | Player joined, data not yet loaded | TitleBrandingWidget only (prevents flash of incomplete UI) |
| `VisibleNormal` | Player data loaded, not in match | All widgets except ErrorNoticeWidget |
| `Loading` | Data loading in progress (spinner on title) | TitleBrandingWidget only |
| `Connecting` | Play button pressed, waiting for server | TitleBrandingWidget + PlayButtonWidget (in Connecting state text) + SettingsButtonWidget |
| `ErrorState` | Connection or data failure | All VisibleNormal widgets + ErrorNoticeWidget; Play button greyed |
| `Eclipsed` | Shop / Settings panel is open (Menu mutex) | MainMenu layer hidden; UIHandler restores on eclipsing layer close |

**`Eclipsed` is not a true state in the layer's own state machine** — it is UIHandler-managed. When `UIHandler.show(UILayerId.Shop)` is called, UIHandler automatically hides `UILayerId.MainMenu` (Menu type mutex). When Shop closes, UIHandler fires `visibilityChanged(true)` on MainMenu, restoring `VisibleNormal` without the MainMenu needing to track the eclipse itself.

### 4.2 State Transition Choreography

**Boot → VisiblePreLogin:**
- Loading screen resolves. `MainMenuLayer.setup()` is called.
- Show `TitleBrandingWidget` with fade-in (`0.4s` ease-out). All other widgets hidden.
- Simultaneously initiate `PlayerDataClient` read (data may already be loaded; check cache first).

**VisiblePreLogin → VisibleNormal:**
- `PlayerDataUpdated` fires with all required keys available.
- Show remaining widgets in cascade: `SkinPreviewWidget` and `CoinsBalanceWidget` fade in together (`0.3s`), then `LifetimeStatsWidget` (`0.2s` delay + `0.3s` fade), then `PlayButtonWidget` (`0.3s` delay + `0.3s` fade), then `ShopButtonWidget` and `SettingsButtonWidget` (`0.2s` delay + `0.2s` fade).
- Total cascade: ~1.0s from first widget to last. This staged entrance prevents a "wall of UI" and gives the player's eye a guided path (brand → identity → stats → CTA).
- Reduce-motion: all widgets appear simultaneously, no stagger, no fade (instant show).

**VisibleNormal → Connecting (Play pressed):**
- Play button text changes to `"JOINING..."`.
- Play button `Active = false`.
- Shop and Settings buttons `Active = false` (prevent navigation mid-connect).
- `SettingsButtonWidget` remains `Active = true` (player may need accessibility options even during connection).
- No other widget visibility changes — player can still see their stats and skin during the brief connection window.

**Connecting → VisibleNormal (connection failure):**
- Play button text reverts to `"PLAY"`. `Active = true`.
- Shop and Settings buttons re-enabled.
- `ErrorNoticeWidget` appears with appropriate message.

**Connecting → Hidden (match joined successfully):**
- Whole layer hides (UIHandler layer visibility = false).
- Transition: instant hide (no fade-out — the match loading sequence begins immediately; a fade here would compete with the loading screen).

**Any match end → VisibleNormal (match complete):**
- After round result screen, Intermission state begins. MainMenu layer becomes visible again via `UIHandler.show(UILayerId.MainMenu)` called from the match-end flow (implementation dependency — match-end flow is out of scope this spec, flag in §8 Implementation References).
- On show, perform a fresh `PlayerDataClient` read to pick up Coins earned and updated lifetime stats.
- If Coins increased: `CoinsBalanceWidget` runs the count-up earn-animation (§3.7).

**VisibleNormal → Eclipsed (Shop or Settings opened):**
- UIHandler hides MainMenu automatically (Menu mutex).
- No action needed from `MainMenuLayer` code — UIHandler fires `visibilityChanged(false)`.

**Eclipsed → VisibleNormal (Shop or Settings closed):**
- UIHandler fires `visibilityChanged(true)`.
- `MainMenuLayer` re-enables its `ScreenGui`.
- No widget re-animation on restore (player is returning to a known state, not a fresh entrance).

### 4.3 Widget Visibility Table

| Widget | Hidden | VisiblePreLogin | VisibleNormal | Loading | Connecting | ErrorState | Eclipsed |
|--------|--------|----------------|---------------|---------|-----------|------------|---------|
| `TitleBrandingWidget` | off | on | on | on | on | on | off |
| `PlayButtonWidget` | off | off | on | off | on (greyed) | on (greyed) | off |
| `ShopButtonWidget` | off | off | on | off | off | on | off |
| `SettingsButtonWidget` | off | off | on | off | on | on | off |
| `LifetimeStatsWidget` | off | off | on | off | off | on | off |
| `SkinPreviewWidget` | off | off | on | off | off | on | off |
| `CoinsBalanceWidget` | off | off | on | off | off | on | off |
| `ErrorNoticeWidget` | off | off | off | off | off | on | off |

**Invariants:**
- `SettingsButtonWidget` is never hidden during Connecting — accessibility settings must always be reachable.
- `ErrorNoticeWidget` is only shown in `ErrorState` — it is never visible alongside `VisiblePreLogin` or `Connecting`.
- No widget overlap in default states: `SkinPreviewWidget` (left) and `CoinsBalanceWidget` (right) are in the same vertical band but opposite horizontal sides — they do not compete.

---

## 5. Pillar Expression

### 5.1 Pillar 4 — Cosmetic Expression (Primary pillar for main menu)

Per `game-concept.md §Pillar 4`: "Meta progression is identity. Follower crowd mirrors player skin — every player broadcasts identity at scale." The main menu is the **pre-match identity confirmation moment**. Before entering the arena, the player sees:

1. **Their skin** — `SkinPreviewWidget` shows the selected follower appearance. This answers "what will my crowd look like?" before the match begins.
2. **Their earned history** — `LifetimeStatsWidget` shows how many followers they have absorbed and how many rounds they have won. This answers "what have I accomplished?" and reinforces investment.
3. **Their currency** — `CoinsBalanceWidget` shows what they have to spend. This answers "what can I still get?" and connects the session loop: play → earn → shop → play.

The layout flow (brand → identity → history → play) follows the player's natural motivation arc: *this is the game* → *this is me in it* → *this is what I've done* → *let's play*.

**Skin preview design test (per art bible §1):** The skin icon in `SkinPreviewWidget` must read as a distinct silhouette at the widget size (120×112px on mobile). The follower's hat silhouette must be legible — per art bible §5 "any new hat mesh must read shape from 20m in LOD 0, must not obscure the head silhouette dome." At 120px icon size, the same silhouette-clarity standard applies. If a skin icon does not pass this test at widget size, the icon asset must be revised.

### 5.2 Pillar 1 — Snowball Dopamine (Indirect — return-from-match moment)

Pillar 1 ("Every absorb must feel intrinsically great") applies to the main menu only at the post-match return moment: when the player returns from a match and sees their Coins balance update. The `CoinsBalanceWidget` count-up animation (§3.7) is this pillar's expression on the main menu — growth is made visible, even in the meta layer. Absorbs translate to currency, currency is visible: the dopamine loop completes.

### 5.3 Pillar 3 — 5-Minute Clean Rounds (Indirect — framing context)

The main menu must not imply persistent power or carry-over. The lifetime stats (LifetimeAbsorbs, LifetimeWins) communicate long-term identity **without implying power**. The display is cosmetic-historical, not a stat-block that suggests gameplay advantages. No "level," no "XP bar," no "power rating." Pillar 3 integrity requires that the main menu look like a social leaderboard, not an RPG character sheet.

### 5.4 Pillar 2 and Pillar 5 — Not Directly Expressed Here

Pillar 2 (Risky Chests) has no surface area on the main menu — chest decisions are in-match.
Pillar 5 (Comeback Always Possible) has no surface area on the main menu — the comeback mechanism is the grace-window, which is gameplay-side. However, the framing of stats (showing wins, not losses; showing absorbs accumulated, not rounds lost) is a soft Pillar 5 expression: the main menu celebrates what the player has achieved, not where they have failed.

---

## 6. Accessibility Annotations

Source of all requirements: `design/accessibility-requirements.md` Standard tier (applied verbatim).

### 6.1 Text Size Requirements

Per `design/accessibility-requirements.md §Visual`: "24px @ 1080p, scale on mobile (28px @ portrait orientation due to viewing distance)" for menu UI.

| Widget | Text Element | Required Size | Basis |
|--------|-------------|---------------|-------|
| `TitleBrandingWidget` | Wordmark fallback text | 48px minimum mobile / 64px desktop | Branding hero — intentionally large |
| `PlayButtonWidget` | "PLAY" / "JOINING..." / "RETURN TO MATCH" | 32px mobile / 36px desktop | Primary CTA — accessibility doc large-text 3:1 threshold applies; font weight compensates |
| `ShopButtonWidget` | "SHOP" | 20px minimum | Accessibility doc 24px menu-UI floor (rounded down for compact secondary button; increase to 24px if layout allows) |
| `SettingsButtonWidget` | "SETTINGS" | 20px minimum | Same; raise to 24px if layout allows |
| `LifetimeStatsWidget` | Absorb count + Win count | 20px minimum (24px target) | Non-critical info; 20px floor, 24px recommended |
| `SkinPreviewWidget` | Skin name label | 16px minimum | Small supplementary label; below menu floor — acceptable for secondary label beneath icon |
| `CoinsBalanceWidget` | Balance number | 22px minimum | Verify ≥24px computed at 1080p; accessibility doc 24px floor |
| `CoinsBalanceWidget` | "COINS" sub-label | 14px minimum | Very small secondary label — optional (see OQ-6) |
| `ErrorNoticeWidget` | Error message | 18px minimum | Non-critical ambient error — 18px acceptable for transient notice; raise to 24px if layout allows |

All `TextLabel` instances: use `TextScaled = false` with explicit `TextSize` + `UITextSizeConstraint.MinTextSize` to guarantee floor. Mobile-adaptive approach: use `TextScaled = true` with both `MaxTextSize` and `MinTextSize` properties set per the table above. Do not rely on `TextScaled = true` alone (Roblox can scale below floor on small viewports).

### 6.2 Contrast Requirements

Per `design/accessibility-requirements.md §Visual`: "Body 4.5:1 minimum (WCAG AA); large text 3:1. Test against `art-bible.md §8.4` Neon palette — neon-on-neon backgrounds are forbidden by art-bible AND fail contrast."

| Widget | Background | Text / Element Color | Required Ratio | Notes |
|--------|-----------|---------------------|---------------|-------|
| `PlayButtonWidget` | Accent (art-director TBD) | `#FFFFFF` or `#1A1A1A` | 4.5:1 minimum | Verify both light-on-dark and dark-on-light permutations against final art color |
| `ShopButtonWidget` | Dark plate ~`#1A1A1A` at 65% | `#FFFFFF` | 4.5:1 minimum | |
| `SettingsButtonWidget` | Dark plate | `#FFFFFF` | 4.5:1 minimum | |
| `LifetimeStatsWidget` | Dark plate | `#FFFFFF` | 4.5:1 minimum | |
| `SkinPreviewWidget` skin name | Dark plate | `#FFFFFF` | 4.5:1 minimum | |
| `CoinsBalanceWidget` balance | Dark plate | `#FFFFFF` | 4.5:1 minimum | |
| `ErrorNoticeWidget` message | Dark plate 80% opacity | `#FFFFFF` | 4.5:1 minimum | Amber icon on dark plate: 3:1 minimum for large graphic per WCAG 1.4.11 |
| Any `UIStroke` button outline | Screen background | Outline color | 3:1 minimum | Outline must be distinguishable from background |

Neon-on-neon prohibition (art bible §8.4 + accessibility doc): no Neon BrickColor material on elements that contain text. UI panels use `SmoothPlastic` + `Color3` tinted frames, not Neon material Parts. Neon is reserved for VFX emitters and ability indicators only.

### 6.3 Photosensitivity Safety

Per `design/accessibility-requirements.md §Visual — Photosensitivity`:

| Widget | Animation | Risk | Treatment |
|--------|-----------|------|-----------|
| `TitleBrandingWidget` | Single fade-in on show | None — single occurrence, 0.4s | No mitigation required. Reduce-motion: instant show |
| `PlayButtonWidget` | State text change (instant) | None | No animation to mitigate |
| `CoinsBalanceWidget` | Count-up on coins earn | None — not a flash; smooth value change | Reduce-motion: instant update |
| Widget cascade on `VisiblePreLogin → VisibleNormal` | Staggered fade-ins | None — staggered fades are low-frequency, below Harding FPA threshold | Reduce-motion: all instant |
| `ErrorNoticeWidget` | Appears (instant) | None | No animation |

**No flash effects on the main menu.** The main menu contains zero photosensitivity risk events as designed. The photosensitivity reduction toggle (from Settings) applies to in-match VFX only; no main menu effects are suppressed by it.

### 6.4 Color-as-Only-Indicator Audit — Main Menu

| Location | Color Signal | What It Communicates | Non-Color Backup |
|----------|-------------|---------------------|-----------------|
| `PlayButtonWidget` disabled state | Greyed-out appearance | Button non-interactive | `Active = false` (no press response) + text changes to `"JOINING..."` |
| `ErrorNoticeWidget` | Amber warning icon | Error condition | Warning text message + "warning" icon shape (triangle) |
| `CoinsBalanceWidget` coin icon | Gold coin color | Currency type | "COINS" text label (when shown) + coin icon shape |
| `LifetimeStatsWidget` absorb/win icons | Icon color | Stat type | Distinct icon shapes (absorb = magnet motif, win = star) + text labels "absorbs" / "wins" |

No color-only indicators on main menu. Every color signal has a shape, icon, or text backup.

### 6.5 No Flashing Content Without Warning

The main menu contains no flashing content. The photosensitivity warning modal (per `design/accessibility-requirements.md §Visual` — "Pre-launch photosensitivity warning screen — Modal at first launch") is shown on first session before the main menu appears (FtueStage-gated — see §9.3). It covers all in-match VFX; the main menu itself requires no additional warning.

### 6.6 Input Accessibility Summary

See §7 for full input handling. Summary:
- Full keyboard navigation (Tab order: Play → Shop → Settings → wrap).
- Full gamepad navigation (A to confirm, B to cancel/back, bumpers as optional shortcuts).
- No time-constrained inputs on main menu (no countdown, no auto-dismiss CTA).
- Settings always reachable — `SettingsButtonWidget` is never hidden during any non-Hidden/Eclipsed state.
- Touch targets: minimum 44×44px per accessibility doc §Motor. All interactive widgets meet or exceed. Play button at 72px height, Shop/Settings at 56px height.

---

## 7. Input Handling

### 7.1 Keyboard Input

| Action | Default Key | Target Widget | Notes |
|--------|------------|--------------|-------|
| Navigate | `Tab` | All interactive elements | Tab order: `PlayButtonWidget` → `ShopButtonWidget` → `SettingsButtonWidget` → wrap to `PlayButtonWidget` |
| Navigate reverse | `Shift + Tab` | All interactive elements | Reverse of above |
| Confirm / Activate | `Enter` or `Space` | Focused button | Fires `Activated` on the focused `TextButton` |
| Shortcut — Play | `Enter` (when no focus or on first load) | `PlayButtonWidget` | Default focus on `PlayButtonWidget` at layer show |
| Close error notice | `Escape` | `ErrorNoticeWidget` | Dismisses notice if visible; no other Escape action on main menu |

Tab-order implementation: Use `GuiObject.NextSelectionDown` / `NextSelectionRight` / `NextSelectionLeft` / `NextSelectionUp` chaining. For main menu's linear layout, wire: `PlayButton.NextSelectionDown = ShopButton`, `ShopButton.NextSelectionDown = SettingsButton`, `SettingsButton.NextSelectionDown = PlayButton` (wrap). Mirror in Up direction.

### 7.2 Gamepad Input

| Action | Default Button | Target Widget | Notes |
|--------|---------------|--------------|-------|
| Confirm (Play) | `ButtonA` | `PlayButtonWidget` (focused) | Default focus is Play button on layer show |
| Navigate | D-pad Up/Down/Left/Right | Between interactive buttons | Uses `NextSelection*` chain above |
| Shortcut — Shop | `LeftBumper` (LB) | `ShopButtonWidget` | Deferred to control manifest (VS+); flag for `ContextActionService` wiring |
| Shortcut — Settings | `RightBumper` (RB) | `SettingsButtonWidget` | Same — deferred to control manifest |
| Dismiss error | `ButtonB` | `ErrorNoticeWidget` | Standard "back/cancel" action; dismisses notice if visible |
| Back / Cancel | `ButtonB` | (nothing, main menu is root navigation) | On main menu with no sub-panel open, `ButtonB` has no action — do not accidentally close the main menu (the player cannot "go back" from the main menu to something meaningful in Roblox) |

`ContextActionService` is used for all custom gamepad bindings per `.claude/docs/technical-preferences.md`. The default `SelectionImageObject` is used for gamepad cursor unless art-director provides a custom selection indicator.

### 7.3 Touch Input

| Action | Gesture | Target Widget | Notes |
|--------|---------|--------------|-------|
| Tap Play | Single tap | `PlayButtonWidget` | `TextButton.Activated` |
| Tap Shop | Single tap | `ShopButtonWidget` | Same |
| Tap Settings | Single tap | `SettingsButtonWidget` | Same |
| Tap error dismiss | Single tap (on actionable errors) | `ErrorNoticeWidget` | Only for data-load-timeout error type |

No swipe, drag, pinch, or long-press interactions on the main menu in MVP.

### 7.4 AFKToggle — Not Applicable

The `AFKToggle` interaction is a gameplay mechanic (HUD-owned, Lobby/Countdown states only). It does not appear on the main menu. The player is outside of a match while on the main menu, so AFK state has no meaning here.

### 7.5 Focus Management on Layer Show

When `MainMenuLayer` becomes visible (via `UIHandler.show(UILayerId.MainMenu)`), programmatically set `GuiService.SelectedObject = PlayButtonWidget` to ensure gamepad players are not left with no focused element. This must execute after the cascade-entrance animation completes (or immediately on layer show in reduce-motion mode).

---

## 8. Implementation References

### 8.1 Layer Module Ownership

The main menu is implemented in:
- **Primary module:** `src/ReplicatedStorage/Source/UI/UILayers/MainMenuLayer/init.luau` (to be created in Sprint 2).
- **Widget sub-modules:** `src/ReplicatedStorage/Source/UI/UILayers/MainMenuLayer/[WidgetName].luau` (optional — one per widget if complexity warrants it, following the pattern established in `HudLayer/`).

### 8.2 Template Pattern Reference

Follow `UIExampleHud.luau` (`src/ReplicatedStorage/Source/UI/UILayers/UIExampleHud.luau`) as the canonical implementation pattern. The main menu must use the same UIHandler registration contract:

```lua
-- src/ReplicatedStorage/Source/UI/UILayers/MainMenuLayer/init.luau
--!strict

local UIHandler = require(...SharedSource.UI.UIHandler)
local UILayerId = require(...SharedConstants.UILayerId)
local UILayerType = require(...SharedConstants.UILayerType)

local MainMenuLayer = {}
MainMenuLayer._screenGui = nil :: ScreenGui?

function MainMenuLayer.setup(parent: Instance)
    -- 1. Create root ScreenGui (ResetOnSpawn = false, IgnoreGuiInset = false)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainMenu"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = false  -- Let Roblox inset protect top-bar area
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- 2. Instantiate all 8 widgets (once — never recreated while session is live)
    -- ... (widget creation code)

    screenGui.Parent = parent
    MainMenuLayer._screenGui = screenGui

    -- 3. Register with UIHandler as Menu type
    local visibilityChanged = UIHandler.registerLayer(
        UILayerId.MainMenu,
        UILayerType.Menu,
        MainMenuLayer
    )

    -- 4. Connect layer-level visibility (UIHandler mutex management)
    visibilityChanged:Connect(function(isVisible: boolean)
        if MainMenuLayer._screenGui then
            MainMenuLayer._screenGui.Enabled = isVisible
        end
    end)

    -- 5. Connect per-widget data sources
    -- PlayerDataClient.PlayerDataUpdated:Connect(MainMenuLayer._onDataUpdated)
    -- MatchStateClient.MatchStateChanged:Connect(MainMenuLayer._onMatchStateChanged)

    -- 6. Do NOT call UIHandler.show() here — main menu show is triggered externally
    --    by the client boot flow after data loads
end

function MainMenuLayer.teardown()
    -- Disconnect all connections via Janitor
end

return MainMenuLayer
```

Key differences from `UIExampleHud.luau` pattern:
- `UILayerType.Menu` (not `HeadsUpDisplay`) — this triggers mutex behavior.
- `IgnoreGuiInset = false` — main menu respects Roblox top-bar safe area.
- Does NOT auto-call `UIHandler.show()` in `setup()` — show is triggered by the client boot flow when data is ready (avoids flash of incomplete UI in `VisiblePreLogin` state).

### 8.3 Data Sources Summary

| Widget | Source Module | Key / Signal | Read Pattern |
|--------|-------------|-------------|-------------|
| `LifetimeStatsWidget` | `PlayerDataClient` | `PlayerDataKey.LifetimeAbsorbs`, `PlayerDataKey.LifetimeWins` | `getValue()` on `PlayerDataUpdated` |
| `SkinPreviewWidget` | `PlayerDataClient` | `PlayerDataKey.SelectedSkin` | `getValue()` on `PlayerDataUpdated` |
| `CoinsBalanceWidget` | `PlayerDataClient` | `PlayerDataKey.Coins` | `getValue()` on `PlayerDataUpdated` |
| `PlayButtonWidget` (InMatch state) | Match state signal | `MatchStateClient.MatchStateChanged` | Check if player has an active match slot |
| `ErrorNoticeWidget` | Network / data error signals | Various failure remotes | Per §3.8 error types |

All reads use `PlayerDataClient.getValue(PlayerDataKey.[Key])` — never read PlayerData directly from the server or bypass the client cache. All writes are server-side only (purchases, match-join) — main menu is a read-only surface for PlayerData.

### 8.4 Constants Module

All tuning knobs for the main menu live in `src/ReplicatedStorage/Source/SharedConstants/MainMenuConfig.luau` (to be created in Sprint 2):

```lua
-- MainMenuConfig.luau (to be created)
return {
    TITLE_FADE_DURATION = 0.4,          -- seconds; TitleBrandingWidget entrance
    CASCADE_WIDGET_FADE_DURATION = 0.3, -- seconds; per-widget fade in cascade
    CASCADE_IDENTITY_ROW_DELAY = 0.3,   -- seconds; skin+coins row delay
    CASCADE_STATS_DELAY = 0.5,          -- seconds; lifetime stats delay
    CASCADE_PLAY_DELAY = 0.6,           -- seconds; play button delay
    CASCADE_SECONDARY_DELAY = 0.8,      -- seconds; shop+settings delay
    COINS_COUNTUP_DURATION = 0.8,       -- seconds; earn animation duration
    ERROR_NOTICE_DISPLAY_SEC = 6.0,     -- seconds; non-actionable error auto-dismiss
    PLAY_BUTTON_REACTIVATE_DELAY = 3.0, -- seconds; Play re-enables after server-full error
}
```

### 8.5 RemoteName Forward Dependencies

The following `RemoteEventName` entries must be added to `src/ReplicatedStorage/Source/Network/RemoteName/RemoteEventName.luau` in Sprint 2:

| Remote | Direction | Purpose | Notes |
|--------|-----------|---------|-------|
| `RequestJoinMatch` | Client → Server | Play button CTA — request matchmaking queue entry | Server responds with success or error type |
| `RequestPlayerDataRetry` | Client → Server | Retry data load on timeout | Optional — may reuse existing data-load flow |

These do not exist as of 2026-04-27. Sprint 2 Implementation stories must add them following the existing `RemoteEventName` enum pattern.

### 8.6 UILayerId Forward Dependencies

The following `UILayerId` entries must be added in Sprint 2 when their specs are authored:

| Layer | Type | Opened from Main Menu | Spec |
|-------|------|-----------------------|------|
| `UILayerId.Shop` | Menu | ShopButtonWidget.Activated | `design/ux/shop.md` (not yet authored) |
| `UILayerId.Settings` | Menu | SettingsButtonWidget.Activated | `design/ux/settings.md` (not yet authored) |

Note: `UILayerId.Shop` and `UILayerId.Settings` are NOT yet in `SharedConstants/UILayerId.luau` (as of 2026-04-27, the file only registers `DataErrorNotice`, `ExampleHud`, `ResetDataButton`, `HUD`, `RelicDraft`, `MainMenu`, `PauseMenu`). Sprint 2 must add them.

---

## 9. FTUE Interaction

### 9.1 FTUE System Overview

Per `CLAUDE.md §FTUE`: `FtueStage` is a string stored in `PlayerDataKey.FtueStage`. On `PlayerAdded`, `FtueManagerServer` reads the current stage and runs the stage handler's `handleAsync(player)`. On the client, `FtueManagerClient` watches `PlayerDataUpdated` for stage changes and calls `setup(player)` / `teardown(player)` on the matching client handler.

The main menu is **not a FTUE stage itself**. FTUE runs alongside or sequentially with the main menu experience. The main menu's relationship to FTUE is as the backdrop against which early FTUE prompts may fire.

### 9.2 First Session Flow

On a new player's first session (FtueStage = `FtueStage.Stage1` or initial state):

1. **Photosensitivity warning modal** fires before the main menu is shown (see §9.3).
2. Main menu enters `VisibleNormal` state.
3. `FtueManagerClient` may fire `Stage1.setup(player)` — any Stage1 client-side prompt overlays the main menu. Stage1 is likely a contextual hint pointing toward the Play button. The main menu itself does not change for FTUE — FTUE prompts are a separate UI overlay layer.
4. Player taps Play — enters match — FTUE Stage1 completion condition is met in-match (e.g., first absorb).

The main menu is not "skipped" on first launch. New players see the same main menu as returning players. The difference is FTUE overlay prompts layered on top.

**Lifetime stats zero-state on first session (§3.5 note):** `LifetimeStatsWidget` shows `"0 absorbs"` and `"0 wins"`. This is intentional — the zero state is not hidden because it contextualizes the very first session as the start of a journey. It is not a "failure state" from a Pillar 5 perspective; the player has not yet played a match.

### 9.3 Photosensitivity Warning Screen

Per `design/accessibility-requirements.md §Visual` — "Pre-launch photosensitivity warning screen: Modal at first launch + in About menu."

The photosensitivity warning is a **separate modal layer** (`UILayerId.PhotosensitivityWarning` — not yet registered as of this date), shown before the main menu on first session only. It is gated on FtueStage (first session check). After the player acknowledges it (single "I understand" button), it dismisses and the main menu enters `VisibleNormal` state.

This spec does not design the warning modal content — that is a future spec. This spec establishes that the main menu is blocked from `VisibleNormal` state until the warning has been acknowledged (FtueStage guard).

**FtueStage guard implementation note:**
```lua
-- In MainMenuLayer._onDataUpdated():
-- Before transitioning to VisibleNormal, check:
if FtueStageClient.needsPhotosensitivityWarning() then
    UIHandler.show(UILayerId.PhotosensitivityWarning)
    -- MainMenu stays in VisiblePreLogin until warning dismisses
    -- Warning layer on dismiss calls UIHandler.show(UILayerId.MainMenu)
end
```

`FtueStageClient.needsPhotosensitivityWarning()` returns `true` if this is the first session (FtueStage == initial stage AND no existing `PhotsensitivityWarningAcknowledged` flag in PlayerData). The flag key (`PlayerDataKey.PhotosensitivityWarningAcknowledged`) is a deferred PlayerData addition — see §10 OQ-7.

### 9.4 Returning Player Flow

For players with any FtueStage beyond Stage1 (returning players):
- Main menu shows normally in `VisibleNormal`.
- No FTUE prompts overlay the main menu (FTUE has already completed or has moved to in-match stages).
- If FtueStage = `FtueStage.Complete` (all stages done): main menu is a clean surface with no tutorial elements.

### 9.5 FTUE Override API — Main Menu Does Not Need It

Unlike the HUD (which exposes `HUD.setWidgetOverride(widgetName, stateBool?)`), the main menu does not need a widget-override API for FTUE. FTUE interactions with the main menu are limited to:
1. A pre-menu modal (photosensitivity warning) that blocks `VisibleNormal` entry.
2. Overlay prompt layers (not this layer's concern — handled by the FTUE layer itself).

The main menu does not dim, reorder, or disable its own widgets for tutorial purposes. If a future FTUE stage requires directing attention to a specific main menu widget (e.g., an arrow pointing at ShopButtonWidget), the FTUE overlay layer provides that arrow — main menu state is unchanged.

---

## 10. Open Questions

Items requiring creative-direction or producer resolution before Sprint 2 implementation begins.

| # | Question | Domain | Urgency | Resolution |
|---|----------|--------|---------|-----------|
| OQ-1 | Should `TitleBrandingWidget` have a looping idle animation (e.g., slow shimmer on wordmark, crowd icon orbiting the logo)? Current spec is static after entrance. Looping animation adds Pillar 1 energy but requires extra art assets and careful photosensitivity review. | art-director + ux-designer | Low — post-launch polish candidate | Unresolved |
| OQ-2 | What is the Play button accent color? The accessibility doc mandates 4.5:1 contrast against the button label. Art bible §4 does not define a CTA color. Options: (a) Lime `#7FFF00` (high energy, distinct from all crowd hues); (b) White `#F5F5F5` with dark label; (c) Player's assigned skin hue (identity-linked, but unavailable at boot-time before skin loads). | art-director | Sprint 2 blocking | Unresolved |
| OQ-3 | How is the skin preview rendered? Three options: (a) Static `ImageLabel` icon per skin (requires 5 pre-authored icon assets — low implementation cost, fast, reliable); (b) Viewport3D of the follower model (visually rich, shows hat shape + material accurately, higher implementation cost — `ViewportFrame` in Roblox); (c) Roblox thumbnail API `Players:GetUserThumbnailAsync` (not applicable — this is a follower skin, not the player avatar). Recommendation: (a) for MVP with (b) as VS+ upgrade. | ui-programmer + art-director | Sprint 2 blocking | Unresolved |
| OQ-4 | Should `ShopButtonWidget` show a notification badge (e.g., a red dot or "NEW" label) when a new daily-rotating skin is available in the shop? This adds engagement but requires the main menu to subscribe to a "shop inventory changed" signal. Deferred to VS+ if not in MVP scope. | game-designer + ux-designer | Low — VS+ candidate | Unresolved |
| OQ-5 | Should `SkinPreviewWidget` include a `"Change"` tap target that opens the Shop directly from the skin preview panel? This is a direct-navigation affordance (user sees skin → tap "Change" → goes to shop). Adds a second path to the Shop alongside the ShopButtonWidget. UX theory: multiple entry points to high-value surfaces reduce friction (reduces Fitts's Law distance for the task "change skin"). Risk: two entry points to one panel may confuse navigation model. | ux-designer + game-designer | Low — MVP convenience feature | Unresolved |
| OQ-6 | Should `CoinsBalanceWidget` include a `"COINS"` sub-label beneath the number? Without it, new players may not understand the coin icon represents in-game currency (not Robux). With it, the widget is taller and may need more vertical space. Alternative: tooltip on tap showing `"Coins — spend in the Shop"`. | ux-designer | Sprint 2 | Unresolved |
| OQ-7 | `PlayerDataKey.PhotosensitivityWarningAcknowledged` is referenced in §9.3 but does not exist in the current PlayerData schema (7 keys: Coins, OwnedSkins, SelectedSkin, LifetimeAbsorbs, LifetimeWins, FtueStage, Inventory). Adding it requires a new key in `SharedConstants/PlayerDataKey.luau` and a default value in `DefaultPlayerData.luau`. Producer must confirm schema amendment is in scope for Sprint 1 or Sprint 2. | producer + lead-programmer | Sprint 1 / Sprint 2 gate | Unresolved |
| OQ-8 | Post-match return path: what triggers `UIHandler.show(UILayerId.MainMenu)` after a round ends? The Round Result Screen, Intermission state, and main menu restore are part of the match-end flow (not yet specced). This spec depends on that trigger existing in Sprint 2. Flag as an implementation dependency. | game-designer + ux-designer | Sprint 2 | Unresolved — forward dependency on match-end flow spec |

---

*Spec authored: 2026-04-27. Next review: Sprint 2 kickoff. Author: ux-designer.*
