# Active Session State

*Last updated: 2026-04-20*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [ ] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — BLOCKING high-risk
- [ ] GDD authoring — MVP systems in design order
- [ ] `/review-all-gdds` — cross-consistency check
- [ ] `/gate-check pre-production`

## Key Decisions

- **Game**: Crowdsmith — Crowd City + roguelike chest/relic layer
- **Engine**: Roblox (Luau --!strict), cross-platform
- **Review mode**: lean (directors at phase gates only)
- **Visual anchor**: Roblox Default Stylized — chunky low-poly, cel-shaded, silhouette-first, no gradients
- **Crowd signature hue system**: 12 pre-validated safe palette, each player = one hue, black 2-unit outline for colorblind shape discrimination
- **Follower rigging**: custom 4-6-part CFrame rig, NO Humanoid (performance-binding at 800+ instances)
- **Meta progression**: cosmetic-only (skins), no persistent power

## Files in Flight

- `design/gdd/game-concept.md` — Approved
- `design/art/art-bible.md` — Draft, lean sign-off skipped
- `design/gdd/systems-index.md` — Draft

## Open Questions

- Q1 (concept): Can Roblox replicate 100-300 follower entities per player smoothly at 8-12 players/server? → Resolve via `/prototype crowd-sync`
- Q2 (concept): Starting T1 chest toll value for first-raid-at-minute-1 target? → Playtest iteration after prototype
- Q3 (concept): Daily quest completion time target? → Resolve during Daily Quest System GDD

## Next Step (recommended)

`/prototype crowd-sync` — validate crowd replication technical risk before locking MVP GDDs. Alternative: start GDD authoring with `AssetId Registry` (low-risk, unblocks others) while prototype runs in parallel.

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design
Task: Systems index written; prototype crowd-sync is next blocker
<!-- /STATUS -->
