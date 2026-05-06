---
name: UX Sprint 1 Design-Lock context
description: State of UX work at Sprint 1 Design-Lock (2026-04-27) — what was authored, what is pending, key decisions made
type: project
---

Sprint 1 Design-Lock UX deliverables (2026-04-27):
- `design/accessibility-requirements.md` — Standard tier committed, with photosensitivity reduction + hue-pattern alternative encoding elevated to Standard-elevated.
- `design/ux/hud.md` — HUD UX spec authored, gates Pre-Production → Production phase gate.
- `design/ux/main-menu.md` — Main menu UX spec authored (2026-04-27); 8 widgets, 7 states, full accessibility + input + FTUE sections.

**Why:** Phase gate requires UX specs before Sprint 2 Vertical Slice build begins. HUD and main-menu specs are the Sprint 1 UX deliverables; relic-card.md is deferred to VS+.

**How to apply:** Next UX work is `design/ux/relic-card.md` (Relic Draft modal, owned by Chest System) — deferred to VS. Also pending: shop.md, settings.md, pause-menu.md. Interaction patterns library at `design/ux/interaction-patterns.md` does not yet exist.

Key UX decisions locked in HUD spec:
- Off-screen elimination directional indicator is Standard-elevated accessibility requirement (§8.5 of hud.md) — implementation ownership not yet resolved (open question OQ-2 in hud.md).
- Pattern-overlay encoding for leaderboard rows is mandatory (not optional) per Standard-elevated tier.
- AFK button keyboard binding default is `F`; gamepad binding deferred to control manifest.
- HUD is non-interactive except AFKButtonWidget and relic tooltip (display-only).
- MaxCrowdFlashWidget is widget-scoped (NOT full-screen flash) — photosensitivity risk is lower than initially flagged, but reduction mode is still required.
