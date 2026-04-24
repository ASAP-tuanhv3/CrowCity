---
name: Crowdsmith project context
description: Core concept, pillars, scope, and key design decisions for the Crowdsmith game project
type: project
---

Crowdsmith is a 5-minute Roblox arena game (hypercasual .io + roguelike relic-draft hybrid). Players absorb neutral NPCs to grow a crowd of followers, pay follower tolls at tiered chests for random run-scoped relics, and crush smaller rival crowds. Cosmetic-only meta progression.

**Pillars:**
1. Snowball Dopamine — absorb + VFX + audio must feel intrinsically great
2. Risky Chests — chest + relic systems drive mid-round decision depth
3. 5-Minute Clean Rounds — round lifecycle + match state machine enforce round purity; no persistent power
4. Cosmetic Expression — skins apply to player and entire follower crowd
5. Comeback Always Possible — collision resolution + relic variance keep underdog path open

**MVP scope:** 13 core systems. T1 + T2 chests. 3 reference relics. No T3 in MVP.

**Tick ordering (locked):** Collision → Relic → Absorb → Chest last (per CSM §E)

**Key locked numbers:**
- SERVER_TICK_HZ = 15 (ADR-0001)
- MAX_RELIC_SLOTS = 4 (CSM)
- MAX_CROWD_COUNT = 300
- CROWD_START_COUNT = 10
- T1_TOLL = 10, T2_TOLL = 40, T3_TOLL = 120
- GRACE_WINDOW_SEC = 3.0
- Draft candidates = 3, reroll attempts = 3, timeout = 8s

**Why:** Core loop must answer "is absorb + chest + relic fun?" before any vertical slice work.

**How to apply:** All design decisions should trace back to a pillar. Pillar 3 (round purity) blocks any persistent-power proposals. Pillar 5 (comeback) shapes edge cases toward player-friendly defaults.
