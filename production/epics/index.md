# Epics Index

Last Updated: 2026-05-02
Engine: Roblox (Luau, `--!strict`) — engine reference pinned 2026-04-20
Manifest Version: 2026-04-27

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [asset-id-registry](asset-id-registry/EPIC.md) | Foundation | AssetId Registry | N/A — art bible §8.8–8.9 | 4 stories | Complete |
| [network-layer-ext](network-layer-ext/EPIC.md) | Foundation | Network Layer Extensions | N/A — template ext + ADR-0001/0010 | 5 stories | Complete |
| [player-data-schema](player-data-schema/EPIC.md) | Foundation | PlayerData Schema (ADR-0011) | N/A — schema locked by ADR-0011 | 3 stories | Complete |
| [ui-handler-layer-reg](ui-handler-layer-reg/EPIC.md) | Foundation | UIHandler Layer Registration | N/A — UI prereq | 2 stories | Complete |
| [tick-orchestrator](tick-orchestrator/EPIC.md) | Core | TickOrchestrator | design/gdd/crowd-collision-resolution.md (§15a spin-off) + ADR-0002 | 5 stories | Ready |
| [crowd-state-server](crowd-state-server/EPIC.md) | Core | Crowd State Manager | design/gdd/crowd-state-manager.md | 8 stories | Ready |
| [match-state-server](match-state-server/EPIC.md) | Core | Match State Machine | design/gdd/match-state-machine.md | 8 stories | Ready |
| [round-lifecycle](round-lifecycle/EPIC.md) | Core | Round Lifecycle | design/gdd/round-lifecycle.md | 5 stories | Ready |
| [crowd-replication-broadcast](crowd-replication-broadcast/EPIC.md) | Core | Crowd Replication Broadcast Path (bi-layer Core+Presentation) | design/gdd/crowd-replication-strategy.md | 5 stories | Ready |
| [npc-spawner](npc-spawner/EPIC.md) | Feature | NPC Spawner | design/gdd/npc-spawner.md | Not yet created | Ready |
| [absorb-system](absorb-system/EPIC.md) | Feature | Absorb System | design/gdd/absorb-system.md | Not yet created | Ready |
| [crowd-collision-resolution](crowd-collision-resolution/EPIC.md) | Feature | Crowd Collision Resolution | design/gdd/crowd-collision-resolution.md | Not yet created | Ready |
| [chest-system](chest-system/EPIC.md) | Feature | Chest System | design/gdd/chest-system.md | Not yet created | Ready |
| [relic-system](relic-system/EPIC.md) | Feature | Relic System | design/gdd/relic-system.md | Not yet created | Ready |
| [follower-entity](follower-entity/EPIC.md) | Feature | Follower Entity (client) | design/gdd/follower-entity.md | Not yet created | **Ready (ADR-0007 dependency)** |

## Layer Coverage

| Layer | Epics Created | Notes |
|-------|---------------|-------|
| Foundation | 4 / 8 architecture rows | Path A scope: epics created only for systems with significant new work. Currency / Zone / ComponentCreator / Collision Groups deferred — fold into consuming-system stories per architecture §2.1. **Status: Complete.** |
| Core | 5 / 5 | TickOrchestrator + CSM + MSM + RoundLifecycle + Crowd Replication Broadcast Path. All 5 Ready; 3-1..3-10 must-have closed Sprint 3. |
| Feature | **6 / 7** | NPCSpawner + AbsorbSystem + CollisionResolver + ChestSystem + RelicSystem + FollowerEntity (client). FollowerLODManager belongs to Presentation layer per architecture §2.4. All 6 Ready (FollowerEntity stories still Blocked on ADR-0007 Accept; A7 Proposed 2026-05-02 — pending `/architecture-review`). |
| Presentation | 0 | Run `/create-epics layer: presentation` after Feature stories begin landing |

## Feature Layer ADR Gap

| Gap | Impact | Resolution |
|-----|--------|-----------|
| **ADR-0007 Proposed 2026-05-02; Pending Accept** | FollowerEntity epic stories Blocked on A7 Accept. C1 conflict ALREADY resolved in registry (`humanoid_on_followers` canonical 2-Part since 2026-04-22; `follower-entity.md` Overview prose synced 2026-05-02). | Run `/architecture-review` in a fresh session to validate A7 + promote to Accepted, then `/create-stories follower-entity` |

`requirements-traceability.md` is dated 2026-04-26 (pre-A8/A10/A11 acceptance). Run `/architecture-review` after Sprint 4 sequencing to refresh per-system coverage matrix with A8/A10/A11 closure.

## Core Dependency Order (story implementation)

1. **tick-orchestrator** — required by every other Core epic (Phase 5/6/7/8 hooks)
2. **crowd-state-server** — depends on TickOrchestrator (Phase 5 + 8); writes via 4-caller contract
3. **match-state-server** — depends on TickOrchestrator (Phase 6 + 7) + CSM (CrowdEliminated subscribe)
4. **round-lifecycle** — depends on CSM (CountChanged subscribe + create/destroy) + MSM (sole caller)
5. **crowd-replication-broadcast** — depends on Foundation Network + Foundation buffer codec + CSM record schema

## Feature Dependency Order (story implementation)

1. **npc-spawner** — depends on Core RoundLifecycle (`createAll`/`destroyAll` hooks); produces `NPCSpawner.reclaim` contract for Absorb
2. **absorb-system** — depends on NPCSpawner + CSM `updateCount("Absorb")` + TickOrch Phase 3
3. **crowd-collision-resolution** — depends on CSM `updateCount("Collision")` + `setStillOverlapping` + TickOrch Phase 1; emits peel buffer for FollowerEntity
4. **chest-system** — depends on CSM `updateCount("Chest")` + RelicSystem framework + TickOrch Phase 4
5. **relic-system** — depends on CSM `updateCount("Relic")` + `recomputeRadius` + ChestSystem grant flow
6. **follower-entity** (client) — depends on CrowdReplicationBroadcast mirror + Collision peel buffer + ADR-0007 (NOT WRITTEN — blocking)

## Next Steps

Sprint 3 just closed core spine. 10/10 must-have stories landed (`feat(sprint-3): close stories 3-2..3-10` commit `083437d` 2026-05-02).

Recommended sequence:
- **Step 1**: `/architecture-decision` for ADR-0007 Client Rendering Strategy (closes C1 conflict + 15 TR gap on FollowerEntity epic)
- **Step 2**: `/create-stories npc-spawner` — first Feature epic on dependency chain (no ADR gap; A8 fully covers)
- **Step 3**: `/sprint-plan` for Sprint 4 — sequence NPC + Absorb + RoundLifecycle integration; pull Sprint 3 backlog (3-11..3-15) into nice-to-have if velocity allows
- **Step 4**: After Sprint 4 lands NPC + Absorb: `/create-stories crowd-collision-resolution` + `/create-stories chest-system` + `/create-stories relic-system`
- **Step 5**: After ADR-0007 Accepted: `/create-stories follower-entity`
- **Step 6**: After Feature stories begin landing: `/create-epics layer: presentation` (HUD, Player Nameplate, Chest Billboard, VFX Manager, FollowerLODManager, CrowdStateClient, MatchStateClient)
- **Step 7**: After Vertical Slice playable end-to-end: re-run `/gate-check production` (forward-looking Production → Polish)
