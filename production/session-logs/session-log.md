## Session End: 20260414_163525
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_163853
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_164045
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_164734
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_164924
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_165328
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_165533
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260414_165631
### Commits
7461442 Initial commit
### Uncommitted Changes
CLAUDE.md
---

## Session End: 20260420_111813
### Commits
2f0d9e3 feat: Added claude studio
---

## Session End: 20260420_112517
### Commits
2f0d9e3 feat: Added claude studio
### Uncommitted Changes
production/session-logs/session-log.md
---

## Session End: 20260420_112918
### Commits
2f0d9e3 feat: Added claude studio
### Uncommitted Changes
production/session-logs/session-log.md
---

## Session End: 20260420_152824
### Commits
2f0d9e3 feat: Added claude studio
### Uncommitted Changes
production/session-logs/session-log.md
---

## Session End: 20260420_154201
### Commits
2f0d9e3 feat: Added claude studio
### Uncommitted Changes
CLAUDE.md
production/session-logs/session-log.md
wally.toml
---

## Session End: 20260420_163214
### Commits
2f0d9e3 feat: Added claude studio
### Uncommitted Changes
CLAUDE.md
production/session-logs/session-log.md
wally.toml
---

## Archived Session State: 20260420_170421
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
---

## Session End: 20260420_170421
### Commits
0ac3880 docs: Added document
2f0d9e3 feat: Added claude studio
---

## Archived Session State: 20260420_211207
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
- [~] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — code written, execution + metrics capture pending user
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_211207
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_215627
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
- [~] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — code written, execution + metrics capture pending user
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_215627
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_215938
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
- [~] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — code written, execution + metrics capture pending user
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_215938
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_220256
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
- [~] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — code written, execution + metrics capture pending user
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_220256
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_220837
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
- [~] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — code written, execution + metrics capture pending user
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_220837
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_225752
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_225752
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260420_231555
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260420_231555
### Commits
0ac3880 docs: Added document
### Uncommitted Changes
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260421_141644
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [ ] GDD authoring — next MVP system (Follower Entity, Match State Machine, NPC Spawner, Absorb, or Round Lifecycle)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260421_141644
### Uncommitted Changes
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260421_142040
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [ ] GDD authoring — next MVP system (Follower Entity, Match State Machine, NPC Spawner, Absorb, or Round Lifecycle)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260421_142040
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260421_234015
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [ ] GDD authoring — next MVP system (Round Lifecycle implements T4/T9 hooks, Follower Entity, NPC Spawner, Absorb, or Crowd Collision)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260421_234015
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260421_234148
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [ ] GDD authoring — next MVP system (Round Lifecycle implements T4/T9 hooks, Follower Entity, NPC Spawner, Absorb, or Crowd Collision)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260421_234148
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_003540
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [ ] GDD authoring — next MVP system (Follower Entity, NPC Spawner, Absorb, Crowd Collision, or cross-GDD sync patches for Match State §F + Crowd State §F)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_003540
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_004008
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [ ] GDD authoring — next MVP system (Follower Entity, NPC Spawner, Absorb, Crowd Collision, or cross-GDD sync patches for Match State §F + Crowd State §F)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_004008
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_132038
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [ ] GDD authoring — next MVP system (Follower LOD Manager, Absorb, Crowd Collision, NPC Spawner, Chest, Relic, or cross-GDD sync patches)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_132038
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_133110
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [ ] GDD authoring — next MVP system (Follower LOD Manager, Absorb, Crowd Collision, NPC Spawner, Chest, Relic, or cross-GDD sync patches)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_133110
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_134857
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [ ] GDD authoring — next MVP system (Follower LOD Manager, Absorb, Crowd Collision, NPC Spawner, Chest, Relic, or cross-GDD sync patches)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_134857
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_153523
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [ ] GDD authoring — next MVP system (Absorb, Crowd Collision, NPC Spawner, Chest, Relic)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_153523
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_154108
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [ ] GDD authoring — next MVP system (Absorb, Crowd Collision, NPC Spawner, Chest, Relic)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_154108
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_160646
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [ ] GDD authoring — next MVP (Crowd Collision Resolution, NPC Spawner, Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_160646
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_160939
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [ ] GDD authoring — next MVP (Crowd Collision Resolution, NPC Spawner, Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_160939
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260422_161525
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
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [ ] GDD authoring — next MVP (Crowd Collision Resolution, NPC Spawner, Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design / Prototype
Task: Crowd-sync prototype harness built; user execution + REPORT.md completion pending
<!-- /STATUS -->
---

## Session End: 20260422_161525
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_000651
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [ ] GDD authoring — next MVP (Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Crowd Collision Resolution GDD complete (pending design-review in fresh session)
<!-- /STATUS -->
---

## Session End: 20260423_000651
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_001034
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [ ] GDD authoring — next MVP (Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Crowd Collision Resolution GDD complete (pending design-review in fresh session)
<!-- /STATUS -->
---

## Session End: 20260423_001034
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_001106
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [ ] GDD authoring — next MVP (Chest, Relic, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Crowd Collision Resolution GDD complete (pending design-review in fresh session)
<!-- /STATUS -->
---

## Session End: 20260423_001106
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_001404
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [~] Relic System GDD — In Design 2026-04-23 (scope C: framework + 3 reference relics). Skeleton created `design/gdd/relic-system.md`. Next section: Overview.
- [ ] GDD authoring — next MVP (Chest, HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Relic System GDD (scope C) — skeleton created, authoring Overview
<!-- /STATUS -->
---

## Session End: 20260423_001404
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_092716
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [ ] GDD authoring — next MVP (Chest System — direct dependent of Relic; then HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Relic System GDD ✓ Designed. Next: /design-review in fresh session, then Chest System GDD.
<!-- /STATUS -->
---

## Session End: 20260423_092716
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_095647
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [ ] GDD authoring — next MVP (Chest System — direct dependent of Relic; then HUD)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Relic System GDD ✓ Designed. Next: /design-review in fresh session, then Chest System GDD.
<!-- /STATUS -->
---

## Session End: 20260423_095647
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_130630
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [ ] GDD authoring — next MVP (HUD — consumer of most prior GDDs)
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Chest System GDD ✓ Designed. Next: /design-review fresh session, then HUD GDD.
<!-- /STATUS -->
---

## Session End: 20260423_130630
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_145624
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: HUD GDD ✓ Designed. Next: /design-review fresh session, then Player Nameplate / VFX Manager / Crowd Replication Strategy.
<!-- /STATUS -->
---

## Session End: 20260423_145624
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_160124
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: HUD GDD ✓ Designed. Next: /design-review fresh session, then Player Nameplate / VFX Manager / Crowd Replication Strategy.
<!-- /STATUS -->
---

## Session End: 20260423_160124
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_224344
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: VFX Manager GDD ✓ Designed 2026-04-23. Next: /design-review fresh session; then Crowd Replication Strategy GDD (last MVP system) or /consistency-check.
<!-- /STATUS -->
---

## Session End: 20260423_224344
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260423_224948
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: VFX Manager GDD ✓ Designed + /consistency-check ✓ ran (2 pre-existing conflicts deferred). Next: /propagate-design-change for radius range stale, resolve CROWD_START_COUNT patch, or /design-system Crowd Replication Strategy.
<!-- /STATUS -->
---

## Session End: 20260423_224948
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_094347
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Crowd Replication Strategy GDD ✓ Designed 2026-04-24. ALL MVP GDDs authored. Next: /consistency-check, /propagate-design-change for pending amendments (ADR-0001 payload, radius range stale, CROWD_START_COUNT patch), or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_094347
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_095255
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /consistency-check ✓ clean (1 internal inconsistency fixed). 14 MVP GDDs authored. Next: /propagate-design-change for pending amendments (ADR-0001 payload + buffer mandate, radius range stale, CROWD_START_COUNT patch) or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_095255
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_102440
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_102440
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_113842
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_113842
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_114400
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_114400
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_114732
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_114732
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_115324
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_115324
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_115436
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_115436
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_115608
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_115608
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_115920
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_115920
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_120044
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_120044
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_120135
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_120135
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_120530
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_120530
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_120710
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_120710
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_120919
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_120919
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_121118
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_121118
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_121254
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_121254
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_121435
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [ ] CSM GDD amendment — add `radiusMultiplier` field (flagged by Relic System §Dependencies). Run `/propagate-design-change design/gdd/relic-system.md`
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ ADR-0001 + CSM amended. Next: /architecture-review (pre-Accepted gate), /propagate-design-change on relic-system.md (radius range cascade), design decision on CROWD_START_COUNT, or /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_121435
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_121758
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 refreshed 2026-04-24. CROWD_START_COUNT locked 10. 7 downstream GDDs unblocked. Next: /consistency-check (verify Batch 1 clean), then /propagate-design-change on relic-system.md (Batch 2 radius cascade), then address Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_121758
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_122013
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 refreshed 2026-04-24. CROWD_START_COUNT locked 10. 7 downstream GDDs unblocked. Next: /consistency-check (verify Batch 1 clean), then /propagate-design-change on relic-system.md (Batch 2 radius cascade), then address Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_122013
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_122237
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 refreshed 2026-04-24. CROWD_START_COUNT locked 10. 7 downstream GDDs unblocked. Next: /consistency-check (verify Batch 1 clean), then /propagate-design-change on relic-system.md (Batch 2 radius cascade), then address Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_122237
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_122708
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 refreshed 2026-04-24. CROWD_START_COUNT locked 10. 7 downstream GDDs unblocked. Next: /consistency-check (verify Batch 1 clean), then /propagate-design-change on relic-system.md (Batch 2 radius cascade), then address Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_122708
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_123125
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 + Relic-sync 2026-04-24. /consistency-check ✓ 2 conflicts fixed, 2 registry notes refreshed. 7 downstream GDDs unblocked; Relic GDD synced to two-arg recomputeRadius signature. Next: Batch 2 radius-range cascade — /propagate-design-change anchored on absorb-system.md OR crowd-collision-resolution.md to fix stale F1 var tables [3.05, 12.03] → [1.53, 18.04]. Then Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_123125
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_123336
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 + Relic-sync 2026-04-24. /consistency-check ✓ 2 conflicts fixed, 2 registry notes refreshed. 7 downstream GDDs unblocked; Relic GDD synced to two-arg recomputeRadius signature. Next: Batch 2 radius-range cascade — /propagate-design-change anchored on absorb-system.md OR crowd-collision-resolution.md to fix stale F1 var tables [3.05, 12.03] → [1.53, 18.04]. Then Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_123336
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_123606
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: /propagate-design-change ✓ CSM Batch 1 + ADR-0001 + Relic-sync 2026-04-24. /consistency-check ✓ 2 conflicts fixed, 2 registry notes refreshed. 7 downstream GDDs unblocked; Relic GDD synced to two-arg recomputeRadius signature. Next: Batch 2 radius-range cascade — /propagate-design-change anchored on absorb-system.md OR crowd-collision-resolution.md to fix stale F1 var tables [3.05, 12.03] → [1.53, 18.04]. Then Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_123606
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_123950
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 in progress — /propagate-design-change ✓ Absorb (radius range + ρ rename + F4 recalibrate + DSN-B-MATH advisory). Next: /propagate-design-change design/gdd/crowd-collision-resolution.md (F1 radius range + Follower Entity collision_transfer_per_tick=2 fix + AC-17 perf 1200→3600). Then /consistency-check to verify. Then Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + DSN-B-MATH grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_123950
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_124154
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 in progress — /propagate-design-change ✓ Absorb (radius range + ρ rename + F4 recalibrate + DSN-B-MATH advisory). Next: /propagate-design-change design/gdd/crowd-collision-resolution.md (F1 radius range + Follower Entity collision_transfer_per_tick=2 fix + AC-17 perf 1200→3600). Then /consistency-check to verify. Then Batch 3-5 (LOD ownership, Chest/Relic/MSM contracts, design decisions FLAG-1/2/3 + DSN-B-MATH grace math). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_124154
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_124517
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 ✓ complete — /propagate-design-change Absorb + CCR applied. Next: /consistency-check (verify Batch 2 clean against registry). Then Batch 3 (LOD tier 2 cap 3-way reconciliation — follower-entity.md / follower-lod-manager.md / crowd-replication-strategy.md — declare Follower LOD Manager sole owner). Then Batch 4 (Chest/Relic/MSM contracts: chest Active guard, draft modal close-on-elim hook, MSM/CCR/CSM handler order). Then Batch 5 (design decisions FLAG-1/2/3 + DSN-B-MATH). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_124517
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_124740
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 ✓ complete — /propagate-design-change Absorb + CCR applied. Next: /consistency-check (verify Batch 2 clean against registry). Then Batch 3 (LOD tier 2 cap 3-way reconciliation — follower-entity.md / follower-lod-manager.md / crowd-replication-strategy.md — declare Follower LOD Manager sole owner). Then Batch 4 (Chest/Relic/MSM contracts: chest Active guard, draft modal close-on-elim hook, MSM/CCR/CSM handler order). Then Batch 5 (design decisions FLAG-1/2/3 + DSN-B-MATH). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_124740
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_125304
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 ✓ + /consistency-check ✓ (6 fixes: CSM range, NPC Spawner radius+pool+sync, Follower Entity dynamic transfer, change-impact footnote). Registry clean 66/66. Next: Batch 3 — LOD tier 2 cap 3-way reconciliation (follower-entity.md / follower-lod-manager.md / crowd-replication-strategy.md — declare Follower LOD Manager sole owner of render caps + LOD distances). Then Batch 4 (Chest `crowdState == Active` guard + draft modal close-on-elim hook + MSM/CCR/CSM handler order). Then Batch 5 (design decisions FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_125304
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_125651
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batch 2 ✓ + /consistency-check ✓ (6 fixes: CSM range, NPC Spawner radius+pool+sync, Follower Entity dynamic transfer, change-impact footnote). Registry clean 66/66. Next: Batch 3 — LOD tier 2 cap 3-way reconciliation (follower-entity.md / follower-lod-manager.md / crowd-replication-strategy.md — declare Follower LOD Manager sole owner of render caps + LOD distances). Then Batch 4 (Chest `crowdState == Active` guard + draft modal close-on-elim hook + MSM/CCR/CSM handler order). Then Batch 5 (design decisions FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_125651
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_130114
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batches 1+2+3 ✓ — CSM hub + Relic sync + Absorb + CCR + LOD tier reconciliation. /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). Next: Batch 4 — Chest `crowdState == Active` guard (RC-B-NEW-1) + draft modal close-on-opener-elim hook (S4-B1) + MSM/CCR/CSM same-tick handler order lock (RC-B-NEW-4). Anchor on chest-system.md OR match-state-machine.md. Then Batch 5 (design decisions FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_130114
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_130724
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batches 1+2+3 ✓ — CSM hub + Relic sync + Absorb + CCR + LOD tier reconciliation. /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). Next: Batch 4 — Chest `crowdState == Active` guard (RC-B-NEW-1) + draft modal close-on-opener-elim hook (S4-B1) + MSM/CCR/CSM same-tick handler order lock (RC-B-NEW-4). Anchor on chest-system.md OR match-state-machine.md. Then Batch 5 (design decisions FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_130724
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_131150
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batches 1+2+3 ✓ + Batch 4 partial (chest-system.md ✓). /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). Next: /propagate-design-change design/gdd/match-state-machine.md for RC-B-NEW-4 same-tick handler order lock (CCR → CSM elim → MSM timer → T7 winner). Then /consistency-check. Then Batch 5 design decisions (FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_131150
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_134457
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: Batches 1+2+3 ✓ + Batch 4 partial (chest-system.md ✓). /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). Next: /propagate-design-change design/gdd/match-state-machine.md for RC-B-NEW-4 same-tick handler order lock (CCR → CSM elim → MSM timer → T7 winner). Then /consistency-check. Then Batch 5 design decisions (FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue). Re-run /review-all-gdds after Batches 1-4.
<!-- /STATUS -->
---

## Session End: 20260424_134457
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_135618
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: **Batches 1-4 ✓ COMPLETE** — CSM hub + Relic sync + Absorb + CCR + LOD reconciliation + Chest contracts + MSM handler order. /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). All consistency + contract blockers from /review-all-gdds 2026-04-24 resolved. Next: /consistency-check (final verify) → re-run /review-all-gdds to close out consistency blockers → Batch 5 design decisions (FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue) — these require design discussion, not propagation. /gate-check pre-production blocked on Batch 5 resolution.
<!-- /STATUS -->
---

## Session End: 20260424_135618
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_140554
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: **Batches 1-4 ✓ COMPLETE** — CSM hub + Relic sync + Absorb + CCR + LOD reconciliation + Chest contracts + MSM handler order. /consistency-check ✓ twice. ADR-0001 amended 3x in place (still Proposed). All consistency + contract blockers from /review-all-gdds 2026-04-24 resolved. Next: /consistency-check (final verify) → re-run /review-all-gdds to close out consistency blockers → Batch 5 design decisions (FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue) — these require design discussion, not propagation. /gate-check pre-production blocked on Batch 5 resolution.
<!-- /STATUS -->
---

## Session End: 20260424_140554
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_142011
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [x] /consistency-check 2026-04-24 post-Batch-4 — 3 🔴 GDD-wide sync-back issues + 1 ⚠️ soft flag. All fixed: (H) HUD 7-site sync (status, L250 Dependencies row, L272 Chest row, L276 OQ #1, L277 OQ #2, L288-289 Bidirectional, L383 Event table) — CrowdCountClamped LANDED CSM Batch 1, Chest minimap LANDED Chest Batch 4; (N) Player Nameplate 3-site sync (status, L274 Provisional, L280 Bidirectional, L454 OQ #1) — CrowdCreated LANDED CSM Batch 1; (R) Round Lifecycle 4-site sync (status, L85 Interactions row, L94 bidirectional, L100 OQ, L251/L257 patches, L234 Dependencies table) — CountChanged LANDED CSM Batch 1 as server-side BindableEvent `(crowdId, oldCount, newCount, deltaSource)`; (V) VFX Manager L282 soft flag annotated "informational, no contract action needed". Registry still clean 66/66. systems-index updated: HUD, Player Nameplate, Round Lifecycle, VFX Manager all marked "Consistency-sync 2026-04-24".
- [ ] `/gate-check pre-production`

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — GDD Authoring
Task: **Batches 1-4 ✓ + 3 /consistency-check passes ✓** — all CSM / Chest amendment flags cleared across HUD, Nameplate, Round Lifecycle, VFX. Registry clean 66/66. ADR-0001 amended 3x (still Proposed). Next: re-run /review-all-gdds to close out consistency blockers → Batch 5 design decisions (FLAG-1 Wingspan / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue — design discussions, not propagations). Then /gate-check pre-production.
<!-- /STATUS -->
---

## Session End: 20260424_142011
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_144840
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [x] /consistency-check 2026-04-24 post-Batch-4 — 3 🔴 GDD-wide sync-back issues + 1 ⚠️ soft flag. All fixed: (H) HUD 7-site sync (status, L250 Dependencies row, L272 Chest row, L276 OQ #1, L277 OQ #2, L288-289 Bidirectional, L383 Event table) — CrowdCountClamped LANDED CSM Batch 1, Chest minimap LANDED Chest Batch 4; (N) Player Nameplate 3-site sync (status, L274 Provisional, L280 Bidirectional, L454 OQ #1) — CrowdCreated LANDED CSM Batch 1; (R) Round Lifecycle 4-site sync (status, L85 Interactions row, L94 bidirectional, L100 OQ, L251/L257 patches, L234 Dependencies table) — CountChanged LANDED CSM Batch 1 as server-side BindableEvent `(crowdId, oldCount, newCount, deltaSource)`; (V) VFX Manager L282 soft flag annotated "informational, no contract action needed". Registry still clean 66/66. systems-index updated: HUD, Player Nameplate, Round Lifecycle, VFX Manager all marked "Consistency-sync 2026-04-24".
- [x] `/gate-check systems-design-to-technical-setup` 2026-04-24 — Verdict CONCERNS. All 4 PHASE-GATE directors CONCERNS (CD Pillar 2+5 compromise / TD aggregate-budget ADR needed / PR Design-Lock Sprint recommendation / AD modal philosophy + cel-shading amendment). Report: production/gate-checks/2026-04-24-systems-design-to-technical-setup.md. Stage not advanced. Path A selected: land 5 pre-architecture text fixes before /create-architecture.
- [x] Pre-architecture text fixes (Path A) landed 2026-04-24:
  - SCE-NEW-1: `relic-system.md` §8 renamed "GraceWindow + Eliminated Interaction" — onTick on Eliminated tolerates no-op via CSM F5 clamp; no early-unregister for MVP
  - SCE-NEW-2: `absorb-system.md` L277 rewritten to cite VFX `ABSORB_PER_FRAME_CAP = 6` (60 particles/frame)
  - SCE-NEW-3: `absorb-system.md` L78/80/207/214/215/254 status refreshed — NPC Spawner Designed, VFX Manager Designed; Audio (undesigned) correct
  - DSN-NEW-1: `hud.md` L25 scope clarification — "HUD never modal" applies to HUD layer; Chest draft is Chest-owned `RelicDraft` Menu-type layer (intentional pause). Full UX spec deferred to `/ux-design design/ux/relic-card.md`
  - DSN-NEW-2: `crowd-state-manager.md` L195 anti-P2W contract — cosmetic systems MUST NOT mutate crowd record fields; presentation-only flow via CrowdStateClient read-side
  - (bonus) AD concern 2: `design/art/art-bible.md` L12 cel-shading mechanism clarified — outline Part geometry + flat BrickColor, NOT a shader pass
- [ ] /create-architecture (ready to begin; recommended first ADRs per TD: TickOrchestrator → Perf Budget → CSM Authority → MSM/Round Lifecycle)
- [ ] Batch 5 design decisions (in parallel with architecture): DSN-B-1 Wingspan μ-cap/dist-gate, DSN-B-2 T1 toll scaling, DSN-B-3 placement rule (peakCount weight OR passivity penalty), DSN-B-MATH grace-rescue math (dynamic timer / density floor / recalibration) — creative-director sign-off with revisit dates

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

## Session Extract — /review-all-gdds 2026-04-24 (PM re-run)
- Verdict: CONCERNS (upgraded from FAIL)
- GDDs reviewed: 14
- Prior blockers resolved: 7 RC-B-NEW + 11 pre-existing + 12 DA asymmetries — all propagated in GDD text (registry 66/66 clean)
- Flagged for revision (Warning, hygiene): relic-system.md (onTick Eliminated rule), absorb-system.md (L277 4/frame stale + dep-table status), chest-system.md (modal philosophy via /ux-design), crowd-state-manager.md OR game-concept.md (anti-P2W skin guard)
- Flagged for revision (Open — deferred Batch 5): relic-system.md (DSN-B-1 Wingspan), chest-system.md (DSN-B-2 T1 toll), round-lifecycle.md (DSN-B-3 turtle), absorb-system.md (DSN-B-MATH grace rescue)
- Blocking issues: 0 consistency + 0 scenario; 4 design-theory items deferred Batch 5 by explicit creative-director-sign-off path
- Systems-index status: unchanged (labels accurate; no Needs Revision flags added per user)
- Recommended next: /gate-check pre-production (with Batch 5 deferral acknowledgement) OR land 5 minor text fixes first (items 1-5 of report §5.1)
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24-pm.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — Architecture Kickoff Ready
Task: **Path A complete 2026-04-24** — all 6 pre-architecture text fixes landed (SCE-NEW-1/2/3 + DSN-NEW-1 + DSN-NEW-2 + art bible cel-shading). Gate Systems Design → Technical Setup CONCERNS resolved to architecture-ready state. Next: `/create-architecture` to produce master architecture + prioritized ADR list (recommended first ADRs per TD: TickOrchestrator → Perf Budget → CSM Authority → MSM/Round Lifecycle). Batch 5 design decisions run in parallel (DSN-B-1/2/3 + DSN-B-MATH, creative-director sign-off required).
<!-- /STATUS -->
---

## Session End: 20260424_144840
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_145110
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [x] /consistency-check 2026-04-24 post-Batch-4 — 3 🔴 GDD-wide sync-back issues + 1 ⚠️ soft flag. All fixed: (H) HUD 7-site sync (status, L250 Dependencies row, L272 Chest row, L276 OQ #1, L277 OQ #2, L288-289 Bidirectional, L383 Event table) — CrowdCountClamped LANDED CSM Batch 1, Chest minimap LANDED Chest Batch 4; (N) Player Nameplate 3-site sync (status, L274 Provisional, L280 Bidirectional, L454 OQ #1) — CrowdCreated LANDED CSM Batch 1; (R) Round Lifecycle 4-site sync (status, L85 Interactions row, L94 bidirectional, L100 OQ, L251/L257 patches, L234 Dependencies table) — CountChanged LANDED CSM Batch 1 as server-side BindableEvent `(crowdId, oldCount, newCount, deltaSource)`; (V) VFX Manager L282 soft flag annotated "informational, no contract action needed". Registry still clean 66/66. systems-index updated: HUD, Player Nameplate, Round Lifecycle, VFX Manager all marked "Consistency-sync 2026-04-24".
- [x] `/gate-check systems-design-to-technical-setup` 2026-04-24 — Verdict CONCERNS. All 4 PHASE-GATE directors CONCERNS (CD Pillar 2+5 compromise / TD aggregate-budget ADR needed / PR Design-Lock Sprint recommendation / AD modal philosophy + cel-shading amendment). Report: production/gate-checks/2026-04-24-systems-design-to-technical-setup.md. Stage not advanced. Path A selected: land 5 pre-architecture text fixes before /create-architecture.
- [x] Pre-architecture text fixes (Path A) landed 2026-04-24:
  - SCE-NEW-1: `relic-system.md` §8 renamed "GraceWindow + Eliminated Interaction" — onTick on Eliminated tolerates no-op via CSM F5 clamp; no early-unregister for MVP
  - SCE-NEW-2: `absorb-system.md` L277 rewritten to cite VFX `ABSORB_PER_FRAME_CAP = 6` (60 particles/frame)
  - SCE-NEW-3: `absorb-system.md` L78/80/207/214/215/254 status refreshed — NPC Spawner Designed, VFX Manager Designed; Audio (undesigned) correct
  - DSN-NEW-1: `hud.md` L25 scope clarification — "HUD never modal" applies to HUD layer; Chest draft is Chest-owned `RelicDraft` Menu-type layer (intentional pause). Full UX spec deferred to `/ux-design design/ux/relic-card.md`
  - DSN-NEW-2: `crowd-state-manager.md` L195 anti-P2W contract — cosmetic systems MUST NOT mutate crowd record fields; presentation-only flow via CrowdStateClient read-side
  - (bonus) AD concern 2: `design/art/art-bible.md` L12 cel-shading mechanism clarified — outline Part geometry + flat BrickColor, NOT a shader pass
- [ ] /create-architecture (ready to begin; recommended first ADRs per TD: TickOrchestrator → Perf Budget → CSM Authority → MSM/Round Lifecycle)
- [ ] Batch 5 design decisions (in parallel with architecture): DSN-B-1 Wingspan μ-cap/dist-gate, DSN-B-2 T1 toll scaling, DSN-B-3 placement rule (peakCount weight OR passivity penalty), DSN-B-MATH grace-rescue math (dynamic timer / density floor / recalibration) — creative-director sign-off with revisit dates

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

## Session Extract — /review-all-gdds 2026-04-24 (PM re-run)
- Verdict: CONCERNS (upgraded from FAIL)
- GDDs reviewed: 14
- Prior blockers resolved: 7 RC-B-NEW + 11 pre-existing + 12 DA asymmetries — all propagated in GDD text (registry 66/66 clean)
- Flagged for revision (Warning, hygiene): relic-system.md (onTick Eliminated rule), absorb-system.md (L277 4/frame stale + dep-table status), chest-system.md (modal philosophy via /ux-design), crowd-state-manager.md OR game-concept.md (anti-P2W skin guard)
- Flagged for revision (Open — deferred Batch 5): relic-system.md (DSN-B-1 Wingspan), chest-system.md (DSN-B-2 T1 toll), round-lifecycle.md (DSN-B-3 turtle), absorb-system.md (DSN-B-MATH grace rescue)
- Blocking issues: 0 consistency + 0 scenario; 4 design-theory items deferred Batch 5 by explicit creative-director-sign-off path
- Systems-index status: unchanged (labels accurate; no Needs Revision flags added per user)
- Recommended next: /gate-check pre-production (with Batch 5 deferral acknowledgement) OR land 5 minor text fixes first (items 1-5 of report §5.1)
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24-pm.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — Architecture Kickoff Ready
Task: **Path A complete 2026-04-24** — all 6 pre-architecture text fixes landed (SCE-NEW-1/2/3 + DSN-NEW-1 + DSN-NEW-2 + art bible cel-shading). Gate Systems Design → Technical Setup CONCERNS resolved to architecture-ready state. Next: `/create-architecture` to produce master architecture + prioritized ADR list (recommended first ADRs per TD: TickOrchestrator → Perf Budget → CSM Authority → MSM/Round Lifecycle). Batch 5 design decisions run in parallel (DSN-B-1/2/3 + DSN-B-MATH, creative-director sign-off required).
<!-- /STATUS -->
---

## Session End: 20260424_145110
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

## Archived Session State: 20260424_145707
# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [x] /consistency-check 2026-04-24 post-Batch-4 — 3 🔴 GDD-wide sync-back issues + 1 ⚠️ soft flag. All fixed: (H) HUD 7-site sync (status, L250 Dependencies row, L272 Chest row, L276 OQ #1, L277 OQ #2, L288-289 Bidirectional, L383 Event table) — CrowdCountClamped LANDED CSM Batch 1, Chest minimap LANDED Chest Batch 4; (N) Player Nameplate 3-site sync (status, L274 Provisional, L280 Bidirectional, L454 OQ #1) — CrowdCreated LANDED CSM Batch 1; (R) Round Lifecycle 4-site sync (status, L85 Interactions row, L94 bidirectional, L100 OQ, L251/L257 patches, L234 Dependencies table) — CountChanged LANDED CSM Batch 1 as server-side BindableEvent `(crowdId, oldCount, newCount, deltaSource)`; (V) VFX Manager L282 soft flag annotated "informational, no contract action needed". Registry still clean 66/66. systems-index updated: HUD, Player Nameplate, Round Lifecycle, VFX Manager all marked "Consistency-sync 2026-04-24".
- [x] `/gate-check systems-design-to-technical-setup` 2026-04-24 — Verdict CONCERNS. All 4 PHASE-GATE directors CONCERNS (CD Pillar 2+5 compromise / TD aggregate-budget ADR needed / PR Design-Lock Sprint recommendation / AD modal philosophy + cel-shading amendment). Report: production/gate-checks/2026-04-24-systems-design-to-technical-setup.md. Stage not advanced. Path A selected: land 5 pre-architecture text fixes before /create-architecture.
- [x] Pre-architecture text fixes (Path A) landed 2026-04-24:
  - SCE-NEW-1: `relic-system.md` §8 renamed "GraceWindow + Eliminated Interaction" — onTick on Eliminated tolerates no-op via CSM F5 clamp; no early-unregister for MVP
  - SCE-NEW-2: `absorb-system.md` L277 rewritten to cite VFX `ABSORB_PER_FRAME_CAP = 6` (60 particles/frame)
  - SCE-NEW-3: `absorb-system.md` L78/80/207/214/215/254 status refreshed — NPC Spawner Designed, VFX Manager Designed; Audio (undesigned) correct
  - DSN-NEW-1: `hud.md` L25 scope clarification — "HUD never modal" applies to HUD layer; Chest draft is Chest-owned `RelicDraft` Menu-type layer (intentional pause). Full UX spec deferred to `/ux-design design/ux/relic-card.md`
  - DSN-NEW-2: `crowd-state-manager.md` L195 anti-P2W contract — cosmetic systems MUST NOT mutate crowd record fields; presentation-only flow via CrowdStateClient read-side
  - (bonus) AD concern 2: `design/art/art-bible.md` L12 cel-shading mechanism clarified — outline Part geometry + flat BrickColor, NOT a shader pass
- [x] Batch 5 partial landed 2026-04-24:
  - DSN-B-2 T1 toll scaling — `chest-system.md` F1 new `base_toll_scaled(tier, count) = max(T_FLAT, ceil(count × T_PCT))`. Registry: T1/T2/T3_TOLL repurposed as FLOORS; +3 constants T1_TOLL_PCT=0.08, T2_TOLL_PCT=0.20, T3_TOLL_PCT=0. At count=300: T1=24, T2=60, T3=120 (flat). Pre-relic pipeline step e1/e2 updated; F2 renumbered. T3 flat (already 40% of MAX). Guard 3f unchanged.
  - DSN-B-3 turtle placement — `round-lifecycle.md` §F3 rewritten. Old "survivor-always-beats-eliminated" invariant removed; Rank 2..N single unified sort by composite key (peakCount desc, survived desc, finalCount desc, eliminationTime desc, UserId asc). Turtler@peak=10 now ranks below aggressive-eliminated@peak=299. Downstream refs updated (L34/35/209/224/275/339). Broadcast schema unchanged — clients derive survived from `eliminationTime == nil`.
- [ ] Batch 5 deferred (need playtest data — revisit post-VS):
  - DSN-B-1 Wingspan μ-cap vs `NPC_RESPAWN_MIN_CROWD_DIST > r_max × μ_max` gate — μ=1.35 sit-still feel needs hands; revisit at VS playtest
  - DSN-B-MATH grace-rescue math (late-round ρ≈0.011 collapse) — dynamic timer by ρ_effective vs density floor at count=1; needs late-round density telemetry from VS
- [ ] /create-architecture (ready; recommended first ADRs per TD: TickOrchestrator → Perf Budget → CSM Authority → MSM/Round Lifecycle)

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

## Session Extract — /review-all-gdds 2026-04-24 (PM re-run)
- Verdict: CONCERNS (upgraded from FAIL)
- GDDs reviewed: 14
- Prior blockers resolved: 7 RC-B-NEW + 11 pre-existing + 12 DA asymmetries — all propagated in GDD text (registry 66/66 clean)
- Flagged for revision (Warning, hygiene): relic-system.md (onTick Eliminated rule), absorb-system.md (L277 4/frame stale + dep-table status), chest-system.md (modal philosophy via /ux-design), crowd-state-manager.md OR game-concept.md (anti-P2W skin guard)
- Flagged for revision (Open — deferred Batch 5): relic-system.md (DSN-B-1 Wingspan), chest-system.md (DSN-B-2 T1 toll), round-lifecycle.md (DSN-B-3 turtle), absorb-system.md (DSN-B-MATH grace rescue)
- Blocking issues: 0 consistency + 0 scenario; 4 design-theory items deferred Batch 5 by explicit creative-director-sign-off path
- Systems-index status: unchanged (labels accurate; no Needs Revision flags added per user)
- Recommended next: /gate-check pre-production (with Batch 5 deferral acknowledgement) OR land 5 minor text fixes first (items 1-5 of report §5.1)
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24-pm.md

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

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production
Feature: Systems Design — Architecture Kickoff Ready
Task: **Path A ✓ + Batch 5 partial ✓ 2026-04-24**. Pre-architecture fixes (6) + DSN-B-2 toll scaling + DSN-B-3 peak-dominance placement all landed. Registry +3 constants (T1/T2/T3_TOLL_PCT). Deferred to post-VS: DSN-B-1 Wingspan + DSN-B-MATH grace-rescue (playtest-dependent). Next: `/create-architecture` → TickOrchestrator + Perf Budget + CSM Authority + MSM/Round Lifecycle ADRs.
<!-- /STATUS -->
---

## Session End: 20260424_145707
### Uncommitted Changes
design/art/art-bible.md
design/gdd/systems-index.md
design/registry/entities.yaml
docs/registry/architecture.yaml
production/session-logs/agent-audit.log
production/session-logs/session-log.md
production/session-state/active.md
---

