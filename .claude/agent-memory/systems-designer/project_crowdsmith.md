---
name: Project Context — Crowdsmith
description: Game concept, locked constants, and GDD authoring status for Crowdsmith arena crowd game
type: project
---

Crowdsmith is a Roblox 5-minute arena game (ROUND_DURATION_SEC=300). 8-12 players each command a crowd of followers (start 10, cap 300). Core loop: absorb neutral NPCs, collide with rivals, buy relics at chests. Pillars: 1=Snowball Dopamine, 3=5-Min Clean Rounds, 4=Cosmetic Expression, 5=Comeback Always Possible.

**Architecture foundation**: ADR-0001 (Proposed) — server-authoritative, 15 Hz tick (Heartbeat accumulator), UnreliableRemoteEvent for crowd broadcast, O(p²) overlap checks validated at 12 players × 66 pairs.

**GDD status as of 2026-04-22**:
- Crowd State Manager: In Revision (drip model §C.3 LOCKED)
- Absorb System: Designed
- Follower Entity: In Review
- Round Lifecycle: In Revision
- NPC Spawner: Designed
- Crowd Collision Resolution: NOT STARTED — active design session

**Locked constants** (registry `design/registry/entities.yaml`):
- SERVER_TICK_HZ = 15
- MAX_CROWD_COUNT = 300
- CROWD_START_COUNT = 10
- TRANSFER_RATE_BASE = 15, SCALE = 0.15, MAX = 60 (followers/sec)
- GRACE_WINDOW_SEC = 3.0
- radius_from_count = 2.5 + sqrt(count) * 0.55

**How to apply**: All proposed formulas and constants must be checked against this registry. New cross-system facts flagged for registry addition at session end.
