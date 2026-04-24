---
name: Crowdsmith Project Context
description: Game concept, design pillars, registered constants, and GDD authoring status as of 2026-04-23
type: project
---

Crowd City + roguelike chest/relic layer on Roblox. 5-min rounds, 8-12 players, round-scoped only.

Key constants (from registry 2026-04-23):
- CROWD_START_COUNT = 10, MAX_CROWD_COUNT = 300
- T1_TOLL = 10, T2_TOLL = 40, T3_TOLL = 120
- MAX_RELIC_SLOTS = 4, DRAFT_CANDIDATE_COUNT = 3, DRAFT_REROLL_ATTEMPTS_PER_SLOT = 3
- radius_from_count formula: 2.5 + sqrt(count) * 0.55; base range [3.05, 12.03]; with Wingspan x1.35 up to 18.04 studs
- SERVER_TICK_HZ = 15

MVP relic pool (3 relics only):
- TollBreaker (Common, T1+T2): 0.70x toll
- Surge (Rare, T2+T3): +40 count one-shot
- Wingspan (Epic, T2+T3): x1.35 radius permanent

Pillars: P2 = decision depth (primary for chests), P5 = comeback via small-crowd raids.

GDD status as of 2026-04-23: Chest System GDD skeleton created, economy calibration delivered for §F+§G. Relic System GDD approved. All core systems (CSM, MSM, Round Lifecycle, Follower Entity, LOD, Absorb, NPC Spawner, Crowd Collision) approved.

**Why:** Chest economy calibration was delivered 2026-04-23 to feed Chest System GDD §F (Formulas) and §G (Tuning Knobs). Starting values are provisional; playtest iteration expected.
**How to apply:** Use registered constants as canonical source. Flag any proposed deviations explicitly before writing to GDD.
