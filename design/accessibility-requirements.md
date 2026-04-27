# Accessibility Requirements: Crowdsmith

> **Status**: Committed
> **Author**: ux-designer (Sprint 1 Design-Lock — auto-authored 2026-04-27)
> **Last Updated**: 2026-04-27
> **Accessibility Tier Target**: **Standard**
> **Platform(s)**: PC, Mobile (iOS / Android), Console (Xbox)
> **External Standards Targeted**:
> - WCAG 2.1 Level AA (contrast + text sizing)
> - Game Accessibility Guidelines (Basic + Intermediate categories)
> - Xbox Accessibility Guidelines (XAG) — Partial (covers menus + HUD; gameplay rumble out of scope MVP)
> - Apple / Google Accessibility Guidelines — Yes (mobile is a target platform)
> **Accessibility Consultant**: None engaged (post-launch audit planned — see §Audit History)
> **Linked Documents**: `design/gdd/systems-index.md`, `design/gdd/game-concept.md` (Pillar 1+2 photosensitivity / hue concerns), `design/art/art-bible.md` §8.4 Neon-permit policy, `docs/architecture/adr-0011-persistence-schema.md` (Pillar 4 cosmetic-only)

> **Why this document exists**: Per-screen accessibility annotations belong in
> UX specs. This document captures Crowdsmith's project-wide accessibility
> commitments, the feature matrix across all systems, the test plan, and the
> audit history. Created during Sprint 1 Design-Lock per `/gate-check`
> requirement. Updated after each `/gate-check` pass and whenever a new system
> is added to `systems-index.md`.

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Critical text readable; no color-only signals; independent volume controls; no photosensitivity risk. | Low |
| **Standard** | All Basic + full input remapping + subtitle support + adjustable text size + at least one colorblind mode + no un-extendable timed inputs. | Medium |
| **Comprehensive** | All Standard + screen-reader menus + mono audio + difficulty assists + HUD repositioning + reduced motion + visual indicators for all gameplay-critical audio. | High |
| **Exemplary** | All Comprehensive + full subtitle customization + high contrast mode + cognitive load assists + tactile/haptic alternatives + external audit. | Very High |

### This Project's Commitment

**Target Tier**: **Standard**

**Rationale**: Crowdsmith is a Roblox party game (5-minute rounds, 8-12 players per server) with felt pillars built around visual identity (Pillar 2 — hue-shift crowd colors) and dopamine-driven count-up VFX (Pillar 1 — particle bursts, max-crowd flash). The Roblox audience skews young and broad (PC + mobile + console + Xbox), with Roblox demographics showing ~12% of players use platform accessibility features per the Roblox 2024 transparency report. Standard tier addresses the highest-impact barriers for this audience: colorblind modes are critical because hue-shift IS the identity-signaling mechanism (Pillar 2) — without alternative encoding, ~8% of male players cannot distinguish their crowd from neighbors. Photosensitivity protection is critical because Pillar 1 dopamine VFX (max-crowd flash, absorb particle bursts) carries Harding FPA risk. Standard tier is also the floor for Xbox ID@Xbox consideration. Comprehensive tier (screen reader, mono audio, HUD repositioning) is deferred to post-launch — Roblox's `AccessibilityService` API has limited surface, and Comprehensive features require dedicated engineering capacity not available pre-launch.

**Features explicitly in scope (beyond Standard tier baseline)**:
- **Photosensitivity reduction toggle** elevated from Comprehensive — Pillar 1 VFX (`MaxCrowdFlash`, `AbsorbSnap`, `ChestOpenT2Confetti`) tested against Harding FPA standard; reduction mode caps flash amplitude by 80%. Required by design — count-up VFX is core to gameplay.
- **Hue-pattern alternative encoding** elevated from Comprehensive — every crowd's hue is paired with a distinct pattern overlay (stripe / dot / chevron / solid) per `art-bible.md §8.4` Neon-permit policy. Pillar 2 identity-signaling cannot rely on hue alone.

**Features explicitly out of scope (deferred post-launch)**:
- Screen reader support for in-game world (Roblox `AccessibilityService` covers menus only via Roblox-managed UI; gameplay-world narration requires custom implementation beyond MVP capacity).
- Full subtitle customization (game has no voiced dialogue; SFX captions are the audio surface — see §Auditory).
- Tactile/haptic alternatives for audio cues (Roblox haptic API mobile-first; Xbox rumble integration deferred to post-launch parity sprint).
- HUD repositioning (Roblox UI architecture would require significant refactor; not feasible MVP).

---

## Visual Accessibility

> Crowdsmith's visual surface is heavy on color (Pillar 2 hue-shift identity)
> and high-frequency particle effects (Pillar 1 dopamine VFX). Both must be
> handled carefully — neither can be removed without breaking core fantasy.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Minimum text size — menu UI | Standard | All menu screens (MainMenu / PauseMenu / Shop) | Not Started | 24px @ 1080p, scale on mobile (28px @ portrait orientation due to viewing distance). |
| Minimum text size — HUD | Standard | Crowd count + match timer + leaderboard | Not Started | 32px @ 1080p for crowd count (it IS the dopamine readout per HUD GDD AC-1). 20px for non-critical HUD. |
| Text contrast — UI text | Standard | All UI text | Not Started | Body 4.5:1 minimum (WCAG AA); large text 3:1. Test against `art-bible.md §8.4` Neon palette — neon-on-neon backgrounds are forbidden by art-bible AND fail contrast. |
| Text contrast — HUD count + timer | Standard | Top-bar HUD | Not Started | 7:1 minimum (WCAG AAA) — HUD must read against ANY arena background including saturated player crowds. Use opaque background plate per HUD GDD §C. |
| Colorblind mode — Protanopia | Standard | All hue-shift gameplay | Not Started | Red-green (~6% men). Pillar 2 hue palette MUST shift signals: red crowds → orange/yellow, green crowds → teal. Verify with Coblis simulator on every `HUE_PALETTE_SIZE` index. |
| Colorblind mode — Deuteranopia | Standard | All hue-shift gameplay | Not Started | Green-red (~1% men). Often same palette adjustment as Protanopia. |
| Colorblind mode — Tritanopia | Standard | All hue-shift gameplay | Not Started | Blue-yellow (rare ~0.001%). Shift blue to purple, yellow to orange. |
| Hue-pattern alternative encoding | Standard (elevated) | Per-crowd identity signaling | Not Started | Each crowd gets a pattern overlay (stripe / dot / chevron / solid) IN ADDITION to hue. Pattern palette has 8 distinct entries; assigned alongside hue at CrowdCreated time (CSM Batch 1 amendment — `Network.fireAllClients(CrowdCreated, {crowdId, hue, patternIndex})`). Followers + nameplate + minimap-marker all share the pattern. Required — Pillar 2 identity cannot rely on hue alone. |
| Color-as-only-indicator audit | Basic | All UI + gameplay | Not Started | See §Color-as-Only-Indicator Audit table below. |
| UI scaling | Standard | All UI elements | Not Started | Range 75%-150%. Default 100%. Mobile auto-scales by viewport. |
| High contrast mode | Comprehensive | (out of scope MVP) | Deferred | Roblox UI primitives lack a built-in high-contrast toggle; deferred. |
| Brightness/gamma controls | Basic | Global graphics setting | Not Started | Roblox `Settings:GetService("UserSettings")` exposes platform brightness; expose in-game override slider (-50% to +50%). |
| **Photosensitivity / Harding FPA audit** | Standard (elevated) | Pillar 1 VFX | Not Started | Audit `MaxCrowdFlash`, `AbsorbSnap`, `ChestOpenT2Confetti`, `ChestPeelMarch` against Harding FPA standard (no >3 flashes/sec above luminance threshold). Findings: documented per particle ID in §Per-VFX Photosensitivity Audit table. |
| Photosensitivity reduction toggle | Standard (elevated) | All Pillar 1 VFX | Not Started | Settings toggle. ON: flash amplitude scaled by 0.2; particle count capped at VFX-suppression-tier 3 default (per VFX Manager GDD F2). OFF (default): full Pillar 1 expression. |
| Pre-launch photosensitivity warning screen | Basic | Game launch | Not Started | Modal at first launch + in About menu. Lists "frequent flashing lights, color-shift effects, rapid particle bursts." Required — Pillar 1 cannot ship without this notice. |
| Motion/animation reduction mode | Standard | UI transitions + camera shake + VFX | Not Started | Reduces: screen shake on absorb / collision (50% amplitude), camera bob on chest open, looping menu animations. Cannot reduce: follower movement (would break Pillar 1 readability). |
| Subtitles — on/off | Basic | All voiced content | N/A | MVP has no voiced dialogue. SFX captions cover audio surface — see §Auditory. |

### Color-as-Only-Indicator Audit

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| Crowd hue (gameplay) | 8-color hue palette | Player identity (which crowd is whose) | Pattern overlay (stripe / dot / chevron / solid — 8 patterns × 8 hues = 64 distinct visual signatures); player nameplate above crowd shows player name + UserId | Not Started |
| Player nameplate count color | Hue (matches crowd hue) | Tier indicator (font-step thresholds per Player Nameplate GDD F2) | Numeric count value displayed; size scales with tier (offset-tier per Player Nameplate GDD F1) | Not Started |
| Match timer urgency | Color shift to red at <30s | Final-minute warning (HUD GDD F2) | Numeric count shown; bold/blink at <30s; FinalMinuteCue audio | Not Started |
| Eliminated state visual | Crowd hue desaturates to grey | Player out of round (CSM state=3) | Crowd visually shrinks (count → 0); EliminationCue audio; "ELIMINATED" overlay text on player nameplate | Not Started |
| Relic-rarity border | Common/Rare/Epic color (gold/blue/purple) | Relic tier in draft modal | Tier name displayed below relic icon; star count (1/2/3) on icon | Not Started |
| Chest tier T1/T2/T3 model | Tier-distinct mesh shape | Chest tier (PropChestT1/T2Car/T3Building) | Mesh silhouette is tier-distinct by design; numeric tier text on prompt billboard | Not Started |
| Crowd-count flash trigger | White flash on `MAX_CROWD_FLASH` event | Player hit count cap | MaxCrowdFlash audio cue + "MAX!" text overlay on count | Not Started |

### Per-VFX Photosensitivity Audit

> Audited against Harding FPA standard. Pillar 1 VFX cannot ship without this
> table green or with documented mitigation.

| VFX Effect ID | Concern | Mitigation | Status |
|---------------|---------|------------|--------|
| `MaxCrowdFlash` | Full-screen white flash | Cap flash amplitude at 0.5 (was 1.0 design); duration 0.15 s; once-per-state-entry only (no repeating) | Not Started |
| `AbsorbSnap` | Frequent particle bursts during peak gameplay (60+/min) | Particle count cap per `VFX Manager GDD F2` suppression tier; reduce-motion toggle drops tier 1→3 | Not Started |
| `ChestOpenT2Confetti` | Rapid color-shift particles | Already capped at 60 particles/frame per `Absorb GDD §V/A`; verify final tuning <3 flashes/sec | Not Started |
| `ChestPeelMarch` | Linear particle stream (no flash concern) | None — informational only | Not Started |
| `RelicGrantEpic` | Brief screen flash on grant | Cap amplitude 0.4; once per draft pick | Not Started |
| `MatchEndCue` (visual) | Result-screen confetti | Already paced at 1.5 s steady, no flash | Not Started |

---

## Motor Accessibility

> Crowdsmith's motor demands are moderate: ProximityPrompt holds (chest open),
> directional movement, occasional draft-modal taps. No fast-twitch combat.
> Roblox handles cross-platform input natively — focus on remapping + hold-to-toggle.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Full input remapping | Standard | All gameplay inputs, all platforms | Not Started | Use `ContextActionService` per `.claude/docs/technical-preferences.md`. Inputs to remap: WASD movement, AFKToggle key, ChestInteract hold-key, RelicDraftPick keys 1-3. Roblox stores rebinds via player profile; persist via `PlayerDataKey.RemappingProfile` (deferred VS+ — MVP uses Roblox-default Studio settings). |
| Input method switching | Standard | PC | Not Started | Roblox handles natively via UserInputService; verify HUD prompt icons swap (keyboard/mouse vs gamepad) on input-method change. |
| One-hand mode | Standard | All inputs | Not Started | Audit: ChestInteract hold (1 button), AFKToggle (1 button), movement (D-pad / WASD). All single-input — game is one-hand-friendly by design. Document in §Per-Feature Matrix. |
| Hold-to-press alternatives | Standard | ChestInteract proximity hold | Not Started | ChestInteract uses ProximityPrompt hold (per Chest GDD §C). Provide toggle alternative: first press starts hold-progress, second press cancels. Roblox `ProximityPromptService` supports this via `RequiresLineOfSight` + `HoldDuration` swap to tap-mode. |
| Rapid input alternatives | Standard | None — game has no rapid-input | N/A | Crowdsmith has no button-mash mechanics. Pillar 5 grace-window is passive (no input required). |
| Input timing adjustments | Standard | Chest open hold duration | Not Started | Default `CHEST_PROMPT_HOLD_SEC = 0.5` per Chest GDD; provide multiplier 0.5x-3.0x. At 3.0x, hold becomes 1.5s. RelicDraftPick has `DRAFT_TIMEOUT_SEC = 8s` per Chest GDD; multiplier extends to 24s at 3.0x. |
| Aim assist | Standard | None — no ranged combat | N/A | Crowdsmith has no aim mechanics. Following crowds use auto-pathfind per Follower Entity GDD. |
| Auto-sprint / movement | Standard | None — no sprint mechanic | N/A | Crowd-following is passive movement; no sprint to toggle. |
| HUD element repositioning | Comprehensive | Out of scope MVP | Deferred | Roblox UI architecture refactor required; deferred post-launch. |

---

## Cognitive Accessibility

> 5-minute rounds + Pillar 5 grace-window + Pillar 3 clean-state-wipe make
> Crowdsmith inherently low-cognitive-load by design. Main concerns are tutorial
> persistence and objective clarity in early rounds.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Difficulty options | Standard | None — multiplayer party game | N/A | Difficulty is emergent from player count; no Easy/Normal/Hard slider applicable. Pillar 5 grace-window IS the comeback assist. |
| Pause anywhere | Basic | Multiplayer constraint | Modified | True pause not feasible (8-12 players, server-authoritative round timer). Mitigation: AFKToggle (per MSM GDD) marks player as away — server skips them on T6 elimination check; player can re-engage anytime. Functions as social pause. |
| Tutorial persistence | Standard | FTUE handlers | Not Started | Per `CLAUDE.md §FTUE`, FtueStage progresses through stages. Add: each stage's prompt re-shown via in-game Help menu (`UILayerId.MainMenu` → Help submenu — design TBD VS+). MVP: FTUE stages re-trigger on player request via chat command. |
| Quest / objective clarity | Standard | HUD GDD spec | Not Started | Active objective ALWAYS visible: "Absorb crowds to grow" → "Survive to round end" → "Reach top-3 placement." Show in HUD top-strip per HUD GDD AC-3. No auto-dismissing instructions. |
| Visual indicators for audio-only information | Standard | All gameplay-critical SFX | Not Started | See §Gameplay-Critical SFX Audit below. Every audio cue that changes player action requires a visual equivalent. |
| Reading time for UI | Standard | Notification toasts + draft modal | Not Started | Draft modal `DRAFT_TIMEOUT_SEC = 8s` baseline; player input cancels timer (no auto-dismiss while interacting). Notification toasts (e.g. `[Player] eliminated`): ≥5s display, no auto-dismiss for actionable content (draft modal). |
| Cognitive load documentation | Comprehensive | Per-system | Deferred | Per-system load evaluation deferred to Sprint 2 (when Core stories author UX specs). Default — flag any system requiring >4 simultaneous tracks for review. |
| Navigation assists | Standard | None — single-arena game | N/A | No world navigation; arena is bounded by `EnvBoundaryWall`. |

---

## Auditory Accessibility

> Crowdsmith has no voiced dialogue in MVP. Audio surface is 10 *Cue SFX
> (per `AssetId.Sound`) + ambient music. Visual equivalents required for every
> gameplay-critical SFX per Pillar 1 visual-audio doubling.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Subtitles for spoken dialogue | Basic | N/A — no dialogue | N/A | MVP has no voiced lines. Re-evaluate if VS+ adds narration. |
| Closed captions for gameplay-critical SFX | Comprehensive | 10 *Cue SFX from `AssetId.Sound` | Standard (elevated) | Required for Pillar 1 visual-audio doubling. See §Gameplay-Critical SFX Audit table. |
| Mono audio option | Comprehensive | Out of scope MVP | Deferred | Roblox mono-audio toggle requires `SoundService.AmbientReverb` config + per-Sound mono-routing; deferred. |
| Independent volume controls | Basic | Music / SFX / UI buses | Not Started | Per `SoundManager.luau` (template — migrated to AssetId.Sound this session): Music bus + SFX bus + UI bus, three sliders 0-100% default 70%. Persist via `PlayerDataKey.AudioSettings` (deferred VS+ — MVP uses session-only). |
| Visual representations for directional audio | Comprehensive | Off-screen events | Standard (elevated) | Off-screen elimination + relic grant events: screen-edge indicator pointing toward source. Required because Pillar 2 social anxiety relies on awareness of nearby threats. |
| Hearing aid compatibility | Standard | High-frequency cues | Not Started | Audit each `AssetId.Sound` cue for frequency range. Any cue >4kHz must have low-frequency or visual equivalent. |

### Gameplay-Critical SFX Audit

| AssetId.Sound key | What It Communicates | Visual Backup | Caption Required | Status |
|-------------------|---------------------|---------------|-----------------|--------|
| `AbsorbCue` | Player just absorbed an opponent | Crowd count incremented + AbsorbSnap particle + count flash on HUD | No — visuals sufficient | Not Started |
| `ChestOpenT1Cue` | Chest opened, drops about to spawn | ChestOpenT1Confetti VFX + chest mesh anim | No — visuals sufficient | Not Started |
| `ChestOpenT2Cue` | T2 chest opened (rare) | ChestOpenT2Confetti VFX + draft modal opens | No — visuals sufficient | Not Started |
| `RelicGrantCommonCue` / `RelicGrantRareCue` / `RelicGrantEpicCue` | Relic granted to player | RelicGrantVFX + relic shelf updates on HUD | No — visuals sufficient | Not Started |
| `MatchStartCue` | Round started | "GO!" overlay + match timer starts | No — visuals sufficient | Not Started |
| `MatchEndCue` | Round ended | Result screen + leaderboard | No — visuals sufficient | Not Started |
| `EliminationCue` | A player was eliminated | Off-screen: screen-edge directional indicator (Standard-elevated). On-screen: crowd desaturates + nameplate "ELIMINATED" | **YES — directional indicator required** for off-screen eliminations | Not Started |
| `FinalMinuteCue` | <60s remaining in round | Match timer pulses + color shift to red | No — visuals sufficient | Not Started |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Xbox (Roblox) | Xbox Accessibility Guidelines (XAG) — Partial | Input remapping via Xbox Ease of Access; subtitle/caption support | Not Started | Roblox Xbox client honors platform-level XAG settings for system-wide colorblind + UI scaling. Verify in Studio Xbox-emulator. |
| iOS (Roblox) | Apple Accessibility / Dynamic Type | Dynamic Type for menu text; VoiceOver on Roblox-managed UI | Not Started | Roblox iOS client passes through Dynamic Type for `TextLabel` instances. VoiceOver covers Roblox top-bar; in-game UI requires per-screen `AccessibilityService` annotations (Roblox post-cutoff API — verify). |
| Android (Roblox) | Android Accessibility / TalkBack | TalkBack on Roblox-managed UI | Not Started | Same as iOS — Roblox handles top-bar; in-game requires explicit annotations. |
| PC (Roblox) | Steam controller remapping (if Steam launch) | Steam Input pass-through | Deferred | Crowdsmith ships through Roblox catalog — Steam launch out of scope. |

---

## Per-Feature Accessibility Matrix

| System (per `systems-index.md`) | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| Crowd State Manager | Hue identity signaling (Pillar 2) | None | Track 8-12 crowds simultaneously | None — silent system | Partial | Pattern overlay + nameplate text address visual; cognitive load of 8-12 crowds is design-intended (game IS the multi-crowd visual) |
| Match State Machine | None | AFKToggle (1 input) | Round-state clarity (Active / GraceWindow / Eliminated) | MatchStart/EndCue audio | Partial | HUD shows match state per HUD GDD; AFKToggle remappable |
| Round Lifecycle | Result screen colors | None | T0-T9 timeline understanding | FinalMinuteCue + MatchEndCue | Partial | Timer pulse + color shift visual backup planned |
| Follower Entity | Crowd visual = identity (Pillar 2) | None | Visual count interpretation | None | Partial | Pattern overlay (Standard-elevated) + nameplate count |
| Follower LOD Manager | Tier 2 billboard impostor visual | None | None | None | OK by design | Single billboard per distant crowd reduces visual complexity |
| Absorb System | AbsorbSnap VFX (Pillar 1 photosensitivity) | None | Recognize own absorbs vs others | AbsorbCue audio | Partial | Photosensitivity reduction toggle covers VFX; visual count flash on HUD covers audio |
| NPC Spawner | NPC vs player visual distinction | None | None — NPCs are interaction targets | None | Not Started | NPCs need distinct silhouette per `art-bible.md` (no hat — single mesh) |
| Crowd Collision Resolution | None | None | None | CollisionContactEvent audio | OK | Background mechanic; no player-facing tracking required |
| Relic System | Rarity color (Common/Rare/Epic) | RelicDraftPick keys | Pick within DRAFT_TIMEOUT_SEC | RelicGrant*Cue per rarity | Partial | Tier-name + star-count covers colorblind; timeout multiplier covers motor |
| VFX Manager | Pillar 1 photosensitivity | None | None | None | Partial | Per-VFX Harding audit table required; suppression-tier on reduce-motion toggle |
| Crowd Replication Strategy | None | None | None | None | OK | Server-side; no player-facing surface |
| Chest System | Chest tier mesh distinction | ProximityPrompt hold + RelicDraftPick | Draft modal timeout | ChestOpenT1/T2/DraftCue audio | Partial | Hold-to-toggle alternative + timeout multiplier required |
| HUD | Top-bar contrast + count readability | None | Multi-element scan (count + timer + leaderboard + relic shelf) | None | Not Started | UX spec required (`design/ux/hud.md`) — gates UX-Design Sprint 1 work |
| Player Nameplate | Hue + count color (Pillar 2) | None | None | None | Partial | Pattern overlay required; offset-tier sizing per Nameplate GDD F1 |

---

## Accessibility Test Plan

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Text contrast ratios | Automated — contrast analyzer on all UI screenshots | All HUD + menu states | Body 4.5:1; large 3:1; HUD 7:1 | ux-designer | Not Started |
| Colorblind modes | Manual — Coblis simulator on gameplay screenshots in each mode | 8-crowd arena snapshot in Protanopia/Deuteranopia/Tritanopia | All crowds distinguishable; pattern overlay visible | ux-designer | Not Started |
| Pattern-overlay encoding | Manual — disable hue, verify pattern is sole identifier | 8 distinct pattern × 8 crowds | All 8 crowds distinguishable in greyscale | ux-designer | Not Started |
| Photosensitivity Harding FPA | Automated tool (Photosensitive Epilepsy Analysis Tool) | All Pillar 1 VFX recordings | Zero >3 flashes/sec above luminance | ux-designer | Not Started |
| Photosensitivity reduction toggle | Manual — enable, replay all Pillar 1 VFX moments | MaxCrowdFlash + AbsorbSnap + ChestOpenT2Confetti | Flash amplitude visibly reduced; particle count capped | qa-tester | Not Started |
| Input remapping | Manual — remap all defaults, complete tutorial + first match | All defaults rebound via Settings menu | All actions accessible; binds persist | qa-tester | Not Started |
| ChestInteract hold-to-toggle | Manual — enable toggle, open chest | All chest tiers | Toggle activates hold; second press cancels | qa-tester | Not Started |
| Timing extension multiplier | Manual — set 3.0x, run draft modal + chest hold | DRAFT_TIMEOUT_SEC + CHEST_PROMPT_HOLD_SEC | Timing extends per multiplier | qa-tester | Not Started |
| Off-screen directional indicators | Manual — provoke off-screen elimination | Player A eliminated off-screen of Player B | Screen-edge indicator points toward Player A | ux-designer | Not Started |
| User testing — colorblind | External user test | 1 protan + 1 deutan + 1 tritan participant | All complete a full round; no color-clarification requests | producer | Not Started — Sprint 3 |
| User testing — photosensitivity | External user test (with photosensitive participant + medical clearance) | Reduction toggle ON + OFF | Participant comfortable in reduction mode | producer | Not Started — Sprint 3 |

---

## Known Intentional Limitations

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| Screen reader for in-game world | Comprehensive | Roblox `AccessibilityService` covers managed UI only; gameplay narration needs custom system | Affects blind / low-vision players who navigate menus but cannot independently play | Document as post-launch goal; partial mitigation via verbose UI labels in menus |
| Mono audio option | Comprehensive | Roblox mono routing requires per-Sound config refactor | Affects single-sided-deafness players | Document; track for post-launch SoundManager v2 |
| HUD repositioning | Comprehensive | Roblox UI architecture refactor required | Affects players with peripheral vision limits + adaptive hardware | Document; not feasible MVP |
| Tactile/haptic alternatives | Exemplary | Cross-platform haptic API integration deferred | Affects deaf players relying on rumble | Xbox controller rumble in MVP scope; mobile + DualSense post-launch |
| Full subtitle customization | Exemplary | No voiced dialogue in MVP | None — out of game-design scope | Re-evaluate if VS+ adds narration |
| True pause | Standard | Multiplayer round-timer is server-authoritative; pausing one player would desync 8-12 others | Affects players with time-pressure cognitive needs (panic / interruption) | AFKToggle marks player away; server skips on elimination check — functional social pause |

---

## Audit History

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| 2026-04-27 | ux-designer (Sprint 1 auto-author) | Document creation | Tier commitment + feature matrix | Standard tier committed; Pillar 1 photosensitivity + Pillar 2 hue-pattern alternative encoding flagged as elevated requirements | In Progress |
| (TBD Sprint 1) | ux-designer | Internal review | Pre-VS-build checklist against committed tier | (Pending) | Not Started |
| (TBD Sprint 3) | External — Roblox Accessibility Reviewers | User testing | Colorblind + photosensitivity user testing | (Pending) | Not Started — Sprint 3 |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | Contrast + text sizing — applied to all HUD + menu specs |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Game-specific feature checklist |
| Xbox Accessibility Guidelines (XAG) | https://docs.microsoft.com/gaming/accessibility/guidelines | Roblox Xbox client compliance |
| Coblis (colorblind simulator) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Test all 8 hue palette indices in Protanopia/Deuteranopia/Tritanopia |
| Photosensitive Epilepsy Analysis Tool (PEAT / Harding FPA) | https://trace.umd.edu/peat/ | Required test for Pillar 1 VFX |
| Roblox AccessibilityService | https://create.roblox.com/docs/reference/engine/classes/AccessibilityService | Platform integration surface (post-cutoff API; verify in Studio) |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | Sprint 3 user-testing service |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Does Roblox `AccessibilityService` (post-cutoff API) support dynamic HUD-element annotations or only static menu labels? | ux-designer | Sprint 1 | Unresolved — verify in Studio against engine-reference docs |
| Does pattern-overlay encoding (Standard-elevated) integrate with Follower Entity 2-Part rig (`CharFollowerBody` + `CharFollowerHat`) without breaking existing animation? | art-director | Sprint 1 (before art specs lock) | Unresolved — pattern as `SurfaceAppearance` overlay or as separate decal layer |
| What is the photosensitivity warning screen's exact wording, and does it need legal review for Roblox publishing? | producer | Before VS playtest | Unresolved |
| Is the AFKToggle "social pause" mitigation acceptable given accessibility expectation of "true pause anywhere"? | producer + creative-director | Sprint 1 | Unresolved — alternative: round-extension on AFK detection |
