# UX Specification: Pause Menu (in-match overlay)

> **Status**: Draft (Sprint 1 Design-Lock)
> **Author**: ux-designer (auto-authored 2026-04-27)
> **Last Updated**: 2026-04-27
> **Linked**: `design/ux/hud.md`, `design/ux/main-menu.md`, `design/accessibility-requirements.md`, `design/gdd/match-state-machine.md`, `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau`

---

## 1. Overview

### What this UX IS

An **in-match overlay menu** providing access to Settings, AFKToggle, and Leave-Match while a 5-minute Crowdsmith round is in progress. Triggered by Esc key (PC) / Start button (gamepad) / Roblox top-bar menu (mobile).

### What this UX IS NOT

**This menu does NOT pause gameplay.** Crowdsmith is multiplayer (8-12 players per server, server-authoritative round timer per Pillar 3 clean rounds). One player cannot stop the world. Per `design/accessibility-requirements.md` §"Known Intentional Limitations": "True pause not feasible... Mitigation: AFKToggle marks player as away."

The name "pause menu" is conventional — players expect Esc to open something — but the experience is structurally different from single-player pause menus. Every UX decision below flows from this constraint: the world remains visible, the round timer keeps counting, other players keep playing, and the player can dismiss the overlay at any time without consequence.

### Layer ownership

- `UILayerId.PauseMenu` (per `UILayerId.luau`)
- `UILayerType.Menu` (per `UILayerTypeByLayerId.luau`) — mutex with `MainMenu` + `RelicDraft` (UIHandler single-Menu rule)
- HUD coexists (HUD is `HeadsUpDisplay`-type — both layers visible simultaneously per UIHandler rules)
- Module path (Sprint 2): `src/ReplicatedStorage/Source/UI/UILayers/PauseMenuLayer/init.luau`
- Template reference: `src/ReplicatedStorage/Source/UI/UILayers/UIExampleHud.luau` (canonical `setup(parent)` → `UIHandler.registerLayer(LAYER_ID, UILayerType.Menu, self)` → connect to returned `visibilityChangedSignal`)

---

## 2. Layout Map

### Mobile (portrait, primary target)

```
┌─────────────────────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← HUD (still visible behind overlay,
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   per HeadsUpDisplay coexistence)
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│  ░░ ┌─────────────────────────────┐ ░░░│
│  ░░ │   MATCH IN PROGRESS         │ ░░░│ ← StatusTextWidget (top of panel)
│  ░░ │   Round timer: 03:24        │ ░░░│   live timer echoed
│  ░░ ├─────────────────────────────┤ ░░░│
│  ░░ │                             │ ░░░│
│  ░░ │       [  RESUME  ]          │ ░░░│ ← ResumeButtonWidget (primary CTA)
│  ░░ │                             │ ░░░│
│  ░░ │    [  Mark as Away  ]       │ ░░░│ ← AFKToggleButtonWidget
│  ░░ │                             │ ░░░│
│  ░░ │       [  Settings  ]        │ ░░░│ ← SettingsButtonWidget
│  ░░ │                             │ ░░░│
│  ░░ │      [  Leave Match  ]      │ ░░░│ ← LeaveMatchButtonWidget (secondary)
│  ░░ │                             │ ░░░│
│  ░░ └─────────────────────────────┘ ░░░│
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← DimBackgroundWidget
└─────────────────────────────────────────┘   (semi-opaque, world visible behind)
```

### Desktop (landscape)

```
┌──────────────────────────────────────────────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← HUD top-bar
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ ┌─────────────────────────┐ ░░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │  MATCH IN PROGRESS       │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │  Round timer: 03:24      │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ ├──────────────────────────┤ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │      [  RESUME  ]        │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │   [  Mark as Away  ]     │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │      [  Settings  ]      │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ │     [  Leave Match  ]    │ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░ └──────────────────────────┘ ░░░░░░░░░░░░░░░░│
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
└──────────────────────────────────────────────────────────────────┘
```

Layout invariants:
- Panel centered horizontally and vertically
- Panel width: 60% of viewport on mobile, 30% on desktop
- DimBackgroundWidget covers full viewport at 0.5 opacity (world visible at ~50%)
- HUD remains rendered AT FULL OPACITY behind the dim (player must be able to see live count + timer + leaderboard)
- ScreenGui `IgnoreGuiInset = false` — defer to Roblox safe-area on mobile

---

## 3. Per-Widget Specs

### 3.1 DimBackgroundWidget

| Property | Value |
|----------|-------|
| Class | `Frame` |
| Position | `UDim2.new(0, 0, 0, 0)` |
| Size | `UDim2.new(1, 0, 1, 0)` (full viewport) |
| BackgroundColor3 | Black `Color3.fromRGB(0, 0, 0)` |
| BackgroundTransparency | `0.5` (50% opaque — world visible behind) |
| ZIndex | 1 (below panel) |
| Active | `true` (consumes input — prevents click-through to gameplay during overlay) |
| Visibility | always visible while PauseMenu layer visible |
| Accessibility | reduce-motion: no fade-in transition; instantaneous appearance/dismissal |

### 3.2 PausePanelFrame (container)

| Property | Value |
|----------|-------|
| Class | `Frame` |
| Position | `UDim2.fromScale(0.5, 0.5)`, `AnchorPoint = Vector2.new(0.5, 0.5)` |
| Size | mobile: `UDim2.new(0.6, 0, 0, 380)` ; desktop: `UDim2.new(0.3, 0, 0, 360)` |
| BackgroundColor3 | per art-bible §UI palette dark-neutral |
| BackgroundTransparency | `0.05` (mostly opaque — high-contrast over dim) |
| ZIndex | 2 (above dim) |
| UICorner | `CornerRadius = UDim.new(0, 12)` |
| UIStroke | `Thickness = 2`, color per art-bible UI accent |
| Children | StatusTextWidget, ResumeButtonWidget, AFKToggleButtonWidget, SettingsButtonWidget, LeaveMatchButtonWidget |

### 3.3 StatusTextWidget

| Property | Value |
|----------|-------|
| Class | `TextLabel` |
| Position | top of panel `UDim2.new(0, 12, 0, 12)` |
| Size | `UDim2.new(1, -24, 0, 56)` |
| Text | `"MATCH IN PROGRESS\nRound timer: MM:SS"` (two lines) |
| Font | per art-bible — bold for label, regular for timer |
| TextSize | label 18px @ 1080p / timer 16px |
| TextColor3 | high-contrast (≥7:1 against panel bg) |
| TextWrapped | `true` |
| TextXAlignment | `Center` |
| Data binding | reads `MatchStateChanged` signal for state context; reads round-timer via existing HUD timer instance (re-bind same signal) |
| Visibility | always visible while PauseMenu open |
| Why | **Expectation-management**. Counter the "I opened pause, the world should stop" assumption. Show timer continuing. |
| Accessibility | screen-reader-readable: "Match in progress, round timer 3 minutes 24 seconds remaining" |

### 3.4 ResumeButtonWidget (primary CTA)

| Property | Value |
|----------|-------|
| Class | `TextButton` |
| Position | `UDim2.new(0, 12, 0, 80)` (below status) |
| Size | `UDim2.new(1, -24, 0, 56)` |
| Text | `"RESUME"` |
| Font | bold |
| TextSize | 24px (largest button — primary action) |
| TextColor3 | per art-bible — call-to-action accent |
| BackgroundColor3 | per art-bible CTA color |
| Default selection | this widget on overlay open (gamepad / keyboard navigation lands here first) |
| Input bindings | `Esc` (PC) / `B` button (gamepad) — also dismisses; redundant safety so player cannot accidentally trigger destructive action on cancel |
| Action | `UIHandler.hide(UILayerId.PauseMenu)` |
| Side effects | none — round was never paused, gameplay continues |
| Visibility | always visible while PauseMenu open |
| Accessibility | screen-reader: "Resume button. Returns to gameplay." 7:1 contrast against panel. |

### 3.5 AFKToggleButtonWidget

| Property | Value |
|----------|-------|
| Class | `TextButton` |
| Position | `UDim2.new(0, 12, 0, 144)` |
| Size | `UDim2.new(1, -24, 0, 48)` |
| Text | dynamic: `"Mark as Away"` if currently Active / `"Mark as Active"` if currently Away |
| Font | regular |
| TextSize | 18px |
| TextColor3 | high-contrast |
| BackgroundColor3 | secondary-action color per art-bible |
| Data binding | reads current AFK state from local cache (last fired AFKToggle response) |
| Action | `Network.fireServer(RemoteEventName.AFKToggle)` ; updates label after server confirms |
| Side effect | server marks player Away/Active (per `design/gdd/match-state-machine.md`); player skipped on T6 elimination eval if Away at T6 |
| Visibility | always visible while PauseMenu open |
| Accessibility | label changes communicate state; screen-reader: "AFK toggle. Currently Active." or "Currently Away. Press to return to active play." |
| Why | This IS the player-controlled comeback-pause mitigation — the closest thing to "pause" Crowdsmith offers without breaking multiplayer round-state. |

### 3.6 SettingsButtonWidget

| Property | Value |
|----------|-------|
| Class | `TextButton` |
| Position | `UDim2.new(0, 12, 0, 200)` |
| Size | `UDim2.new(1, -24, 0, 48)` |
| Text | `"Settings"` |
| Font | regular |
| TextSize | 18px |
| TextColor3 | high-contrast |
| BackgroundColor3 | secondary-action color |
| Action | open Settings panel (Settings panel UX out-of-scope this spec — separate `design/ux/settings.md` later) |
| Per-accessibility-doc invariant | Settings button must be reachable at all times — accessibility settings cannot require leaving a match |
| Visibility | always visible while PauseMenu open |
| Accessibility | screen-reader: "Settings menu. Opens accessibility, audio, and input options." |

### 3.7 LeaveMatchButtonWidget (secondary, destructive)

| Property | Value |
|----------|-------|
| Class | `TextButton` |
| Position | `UDim2.new(0, 12, 0, 256)` |
| Size | `UDim2.new(1, -24, 0, 48)` |
| Text | `"Leave Match"` |
| Font | regular |
| TextSize | 18px |
| TextColor3 | warning color per art-bible (destructive action) |
| BackgroundColor3 | muted destructive (not red; subdued) |
| Action | open ConfirmingLeaveMatch sub-state (modal confirmation) |
| Why confirmation | Pillar 3 clean-round = leaving forfeits the match irreversibly. Single-tap leave = high regret risk on accidental tap. Confirmation gate per accessibility doc §Cognitive — no destructive auto-actions. |
| Visibility | always visible while PauseMenu open |
| Accessibility | screen-reader: "Leave Match button. Opens confirmation. Will forfeit current match if confirmed." |

### 3.8 ConfirmDialogWidget (sub-state of LeaveMatch)

Activated when LeaveMatchButtonWidget pressed; dismissed by Cancel or Confirm.

| Property | Value |
|----------|-------|
| Class | `Frame` (modal-style overlay above main panel) |
| Position | centered on PausePanelFrame |
| Size | `UDim2.new(1, -40, 0, 200)` |
| Children | confirmation label `"You'll forfeit this match. Cannot be undone. Continue?"` + Cancel button + Confirm button |
| Default selection | Cancel (safe default — gamepad/keyboard navigation lands on Cancel first) |
| Cancel action | dismiss confirm dialog, return to PauseMenu state |
| Confirm action | exit match: `Network.fireServer(RemoteEventName.AFKToggle)` to mark Away (server-graceful exit) → wait for ack → `UIHandler.hide(PauseMenu)` → `UIHandler.show(MainMenu)` |
| Esc / B / Cancel | dismiss dialog, NOT dismiss PauseMenu (two-step cancel) |
| Accessibility | high-contrast, screen-reader-readable, no auto-dismiss |

---

## 4. State Transitions

### 4.1 Layer states

| State | Condition | Trigger to enter | Trigger to exit |
|-------|-----------|------------------|-----------------|
| Hidden | not visible | layer initially hidden after registerLayer | n/a |
| Visible | overlay rendered, all 6 widgets active | `UIHandler.show(UILayerId.PauseMenu)` (Esc/Start/top-bar trigger) | `UIHandler.hide(...)` (Resume button / Esc / B) |
| ConfirmingLeaveMatch | overlay + ConfirmDialogWidget on top | LeaveMatchButtonWidget pressed | Cancel button OR confirm flow OR Esc/B |
| Eclipsed | hidden because RelicDraft or MainMenu was opened (UIHandler single-Menu rule) | another Menu-type layer opened | original Menu closed (auto-restore is NOT done — player must reopen via Esc) |

### 4.2 Transition rules

**Open**:
- Player presses Esc / Start / Roblox top-bar menu pause
- HUD remains visible behind the overlay (HeadsUpDisplay coexistence)
- Default focus: ResumeButtonWidget

**Close (Resume)**:
- ResumeButtonWidget pressed OR Esc OR B
- Round was never paused — instant return to gameplay state
- No visual fade-out (reduce-motion safe; instant)

**Mutex with RelicDraft**:
- If player opens PauseMenu while RelicDraftModal is open: per UIHandler single-Menu rule, the previously-open Menu is closed.
- **Forfeit decision**: opening PauseMenu while RelicDraftModal is open → draft is forfeited (no relic granted; player loses the draft opportunity).
- Surfaced in §11 Open Questions as OQ-1.

**Mutex with MainMenu**:
- MainMenu only displays out-of-match (per `design/ux/main-menu.md`). PauseMenu only displays in-match. Mutex never observable in normal flow.
- Edge case: server crash mid-match → MainMenu shown via match-end-return-path → if PauseMenu was open at crash time, it's auto-dismissed by MainMenu opening.

**Match end while PauseMenu open**:
- T9 round-end fires `MatchEndCue` + result screen logic
- PauseMenu auto-dismisses; result screen takes over
- No prompt; no confirmation — match is over regardless of pause-menu state

---

## 5. Multiplayer-pause-impossibility expression

The single biggest UX risk in this spec is the user expectation gap: "I pressed Esc / pause, why is the world still moving?"

Four UX devices counter this:

1. **StatusTextWidget**: explicit `"MATCH IN PROGRESS"` heading + live round-timer mirror at the top of the panel. Player cannot miss that the round is continuing.

2. **DimBackgroundWidget at 0.5 opacity**: world is visibly continuing. Crowds keep moving. Other players keep absorbing. The player sees this — eliminates the "oh the world stopped" expectation before it can form.

3. **HUD coexistence**: HUD is `HeadsUpDisplay`-type per `UILayerTypeByLayerId.luau` — it stays at full opacity. Live count, timer, leaderboard remain visible behind the overlay. The player retains full match awareness.

4. **AFKToggleButtonWidget**: provides the closest thing to "pause" — a server-acknowledged "I'm not playing right now" state that the player can toggle on/off without leaving. This is the player-controlled comeback-pause from `design/accessibility-requirements.md` §Cognitive.

These four together convert "broken pause expectation" into "I have non-pause options for needing a moment." The absence of a true pause is communicated, not hidden.

---

## 6. Accessibility annotations

### 6.1 Text size + contrast

| Widget | Text size (1080p) | Contrast minimum | Notes |
|--------|-------------------|------------------|-------|
| StatusTextWidget label "MATCH IN PROGRESS" | 18px bold | 7:1 | High-priority status; AAA contrast |
| StatusTextWidget timer | 16px regular | 7:1 | Numeric timer; AAA contrast |
| ResumeButton text | 24px bold | 7:1 | Primary CTA; largest text on panel |
| AFKToggle / Settings / LeaveMatch text | 18px regular | 7:1 | Secondary buttons; AAA contrast |
| ConfirmDialog label | 18px regular | 7:1 | Destructive-confirm; high-contrast |

All measurements scale on mobile per accessibility-requirements.md §UI scaling.

### 6.2 Photosensitivity reduction mode

- DimBackgroundWidget: NO fade-in (instant appearance regardless of mode)
- No animations on widgets
- Already photosensitivity-safe by design (no flashing, no rapid color shifts)

### 6.3 Reduce-motion mode

- Pause panel: NO scale-in or slide-in animation. Instant appearance.
- Confirm dialog: NO transition. Instant appearance.
- HUD elements behind dim continue normal animation (HUD's own reduce-motion settings apply per `design/ux/hud.md`)

### 6.4 Screen reader (Roblox AccessibilityService surface)

All buttons and labels expose `AccessibilityName` + `AccessibilityDescription` per Roblox post-cutoff API:
- ResumeButton: "Resume button. Returns to active gameplay."
- AFKToggleButton (dynamic): "Toggle Away mode. Currently [Active/Away]." (state in label so non-screen-reader users also see it)
- SettingsButton: "Settings menu. Opens accessibility, audio, and input options."
- LeaveMatchButton: "Leave Match. Opens confirmation. Will forfeit this match if confirmed."

OQ-2 (§11): Roblox `AccessibilityService` post-cutoff API verification needed for dynamic label updates on AFK state change.

### 6.5 Colorblind mode

Pause menu uses palette per art-bible UI surface only — NO per-crowd hue-pattern encoding needed (no per-crowd identity signaling on this menu). Per accessibility-requirements.md §Color-as-Only-Indicator, LeaveMatch button uses muted-warning color paired with explicit text "Leave Match" — no color-only meaning.

---

## 7. Input handling

### 7.1 Activation

| Input | Action |
|-------|--------|
| `Esc` (PC keyboard) | Open PauseMenu (if currently in match Active state); Close PauseMenu (if PauseMenu currently open) |
| `Start` button (gamepad) | Open PauseMenu; Close PauseMenu |
| Roblox top-bar pause icon (mobile) | Open PauseMenu |
| `B` button (gamepad) | Cancel — equivalent to Resume button |

### 7.2 Navigation within PauseMenu

| Input | Action |
|-------|--------|
| `Tab` / D-pad up-down | Move focus between buttons |
| `Enter` / A button / mouse click / touch tap | Activate focused button |
| `Esc` / `B` button | Resume (always — never trigger destructive action on cancel) |

### 7.3 Within ConfirmDialog

| Input | Action |
|-------|--------|
| `Esc` / `B` button / Cancel button | Dismiss dialog, return to PauseMenu (NOT dismiss PauseMenu — two-step cancel) |
| `Enter` / A button / Confirm button | Forfeit match, return to MainMenu |

### 7.4 Input priority invariant

`Esc` / `B` is **always Resume** (in PauseMenu state) or **always Cancel** (in ConfirmingLeaveMatch state). Never triggers destructive action. Per accessibility-requirements.md §Motor — destructive actions require explicit confirmation, never primary cancel input.

---

## 8. Pillar interactions

### Pillar 3 (Clean 5-Min Rounds)

- LeaveMatch is **forfeit** (irreversible per session). No "save state and leave" — round state is server-authoritative + in-memory + cleared at T9 per ADR-0011 §Pillar 3.
- ConfirmDialog gate prevents accidental forfeit.
- Match-end (T9) auto-dismisses PauseMenu — the world's lifecycle takes precedence over the menu's lifecycle.

### Pillar 4 (Cosmetic Expression)

- SettingsButton reachable mid-match — players can toggle accessibility / audio / input remap without leaving. Per accessibility doc, this is required at Standard tier (cannot gate accessibility behind "leave match first").
- LeaveMatch path returns to MainMenu where shop is reachable. No mid-match shop access (Pillar 3: shop is not part of round state).

### Pillar 5 (Comeback Mechanic)

- AFKToggle is the player-facing "I need a moment" mitigation. Player can mark Away without leaving — server skips them on T6 elimination eval if Away. Player can toggle back to Active anytime to re-engage.
- This is the ONLY player-controlled "pause" Crowdsmith offers. Documented in accessibility-requirements.md §Cognitive as the multiplayer-pause-impossibility mitigation.

---

## 9. Implementation references

| Reference | Path |
|-----------|------|
| Module path (Sprint 2 will create) | `src/ReplicatedStorage/Source/UI/UILayers/PauseMenuLayer/init.luau` |
| Template pattern | `src/ReplicatedStorage/Source/UI/UILayers/UIExampleHud.luau` (canonical setup → registerLayer → connect) |
| Layer ID | `UILayerId.PauseMenu` |
| Layer type | `UILayerType.Menu` (mutex with MainMenu / RelicDraft per UIHandler single-Menu rule) |
| Trigger to open | Roblox `UserInputService.InputBegan` watching `Enum.KeyCode.Escape` (PC) / `Enum.KeyCode.ButtonStart` (gamepad); Roblox top-bar pause-icon (mobile, automatic) |
| AFK toggle wire | `Network.fireServer(RemoteEventName.AFKToggle)` (per `RemoteEventName.luau` extended in network-layer-ext story 002) |
| HUD coexistence | HUD layer remains in `_layerDataById` table per `UIHandler.luau:31`; both layers' `visibilityChangedSignal` fire independently |
| Forfeit-leave wire | `Network.fireServer(RemoteEventName.AFKToggle)` (server-side AFK = graceful exit per MSM); subsequent client-side `UIHandler.hide(PauseMenu) → UIHandler.show(MainMenu)` |

### Setup pattern

```luau
function PauseMenuLayer.setup(parent: Instance)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PauseMenu"
    screenGui.IgnoreGuiInset = false
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = ...

    -- Create DimBackgroundWidget, PausePanelFrame, all 6 button widgets, ConfirmDialog (initially Hidden)
    -- ...

    screenGui.Parent = parent
    PauseMenuLayer._screenGui = screenGui

    local visibilityChanged = UIHandler.registerLayer(
        UILayerId.PauseMenu,
        UILayerType.Menu,
        PauseMenuLayer
    )

    visibilityChanged:Connect(function(isVisible: any)
        if PauseMenuLayer._screenGui then
            PauseMenuLayer._screenGui.Enabled = isVisible :: boolean
        end
    end)

    -- DO NOT call UIHandler.show on setup — start hidden until Esc is pressed.
end
```

Initially hidden (unlike UIExampleHud which auto-shows). Triggered externally by Esc / Start input handler.

---

## 10. Coexistence with HUD

Per `UILayerTypeByLayerId.luau`:
- `UILayerId.HUD = UILayerType.HeadsUpDisplay` — coexists with anything
- `UILayerId.PauseMenu = UILayerType.Menu` — single-Menu-active rule

When PauseMenu opens:
- HUD stays visible (its own `visibilityChangedSignal` does NOT fire — HUD is unaffected)
- Live count + timer + leaderboard remain at full opacity behind the dim
- Player retains full match awareness — no "I have no idea what's happening" gap

This is required by §5 expectation-management. If HUD were forced hidden by PauseMenu opening, the player would lose all match context and feel like they paused — undermining the explicit messaging of `MATCH IN PROGRESS`.

When PauseMenu closes:
- No HUD state change required (HUD never changed)
- PauseMenu's `visibilityChangedSignal:Fire(false)` → only PauseMenu's ScreenGui disables

When RelicDraftModal opens during PauseMenu (impossible by design but defensive):
- UIHandler single-Menu rule: PauseMenu is closed (its `visibilityChangedSignal:Fire(false)` fires)
- HUD is unaffected
- Player would see RelicDraftModal in front of HUD without PauseMenu — by design

---

## 11. Open Questions

| ID | Question | Owner | Deadline |
|----|----------|-------|----------|
| OQ-1 | If player opens PauseMenu while RelicDraftModal is open (mutex single-Menu rule auto-closes RelicDraft), does the draft forfeit lose the relic OR get re-offered? **Recommended**: forfeit. Pillar 3 clean-round says draft is round-scope state and the player chose to interrupt. | game-designer + creative-director | Sprint 2 (before Chest System story implementation) |
| OQ-2 | Roblox `AccessibilityService` post-cutoff API verification — does it support dynamic label updates on AFKToggle state change, or only static `AccessibilityName`? | ux-designer | Sprint 1 |
| OQ-3 | Does opening PauseMenu during the 3-2-1 countdown (per HUD GDD `321Countdown` widget) auto-defer until Active state? Recommended: yes — disable Esc input during 3-2-1 to prevent confusion. | game-designer | Sprint 2 |
| OQ-4 | Roblox top-bar pause-icon (mobile) — does it auto-trigger our PauseMenu, or does Roblox show its own native pause modal? Need verification. If Roblox's native modal is shown, our PauseMenu may not be reachable on mobile without an explicit in-game pause button. | ux-designer | Sprint 1 |
| OQ-5 | LeaveMatch confirmation — should there be a "Quick Leave" option for players who legitimately want to leave fast (e.g. emergency)? Default: no — confirmation is non-negotiable per accessibility doc cognitive guidance. | producer | Sprint 1 |
| OQ-6 | When match-end fires while PauseMenu is open, should the result screen modal SUPERSEDE PauseMenu's mutex rule (force-close PauseMenu + open Result), or wait for player to dismiss PauseMenu first? Recommended: supersede — match-end is round-lifecycle event, not user-controlled flow. | game-designer | Sprint 2 |
| OQ-7 | AFKToggle UI feedback latency — between user pressing the button and server ack, what does the label show? "Marking…" loading state? Or update immediately and roll back on rejection? Standard pattern: optimistic update + rollback on rejection. | ux-designer + lead-programmer | Sprint 2 |
