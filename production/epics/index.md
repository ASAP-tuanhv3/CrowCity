# Epics Index

Last Updated: 2026-04-27
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

## Layer Coverage

| Layer | Epics Created | Notes |
|-------|---------------|-------|
| Foundation | 4 / 8 architecture rows | Path A scope: epics created only for systems with significant new work. Currency / Zone / ComponentCreator / Collision Groups deferred — fold into consuming-system stories per architecture §2.1. **Status: Complete.** |
| Core | 5 / 5 | TickOrchestrator + CSM + MSM + RoundLifecycle + Crowd Replication Broadcast Path. All 5 Ready. |
| Feature | 0 | Run `/create-epics layer: feature` after Core stories begin landing |
| Presentation | 0 | Run last |

## Core Dependency Order (story implementation)

1. **tick-orchestrator** — required by every other Core epic (Phase 5/6/7/8 hooks)
2. **crowd-state-server** — depends on TickOrchestrator (Phase 5 + 8); writes via 4-caller contract
3. **match-state-server** — depends on TickOrchestrator (Phase 6 + 7) + CSM (CrowdEliminated subscribe)
4. **round-lifecycle** — depends on CSM (CountChanged subscribe + create/destroy) + MSM (sole caller)
5. **crowd-replication-broadcast** — depends on Foundation Network + Foundation buffer codec + CSM record schema

## Next Steps

All 5 Core epics now have stories drafted (31 stories total).

Story implementation order (per dependency chain):
- **tick-orchestrator stories** (001 → 002 → 003 → 004+005) — foundation of every Phase callback
- **crowd-state-server stories** (001 → 002 → 003+004+005 || → 006 → 007 → 008) — Core authority hub
- **match-state-server stories** (001 → 002 → 003+004 → 005 → 006+007 → 008) — round state machine
- **round-lifecycle stories** (001 → 002+003+004 → 005) — round-scoped aux + placement sort
- **crowd-replication-broadcast stories** (001 → 002+003 → 004 → 005) — client mirror + transport phase

Recommended next actions:
- Run `/story-readiness production/epics/tick-orchestrator/story-001-core-module-skeleton-cadence.md` to validate first story
- Run `/dev-story production/epics/tick-orchestrator/story-001-core-module-skeleton-cadence.md` to begin implementation (or `/sprint-plan` to sequence Sprint 2 Vertical Slice Build)
- After all 5 epics' stories begin landing, run `/gate-check pre-production` to re-evaluate the gate verdict
- Then `/create-epics layer: feature` for Absorb / NPCSpawner / Follower / CCR / Chest / Relic
