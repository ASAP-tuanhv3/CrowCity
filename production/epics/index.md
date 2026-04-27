# Epics Index

Last Updated: 2026-04-27
Engine: Roblox (Luau, `--!strict`) — engine reference pinned 2026-04-20
Manifest Version: 2026-04-27

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [asset-id-registry](asset-id-registry/EPIC.md) | Foundation | AssetId Registry | N/A — art bible §8.8–8.9 | 4 stories | Ready |
| [network-layer-ext](network-layer-ext/EPIC.md) | Foundation | Network Layer Extensions | N/A — template ext + ADR-0001/0010 | 5 stories | Ready |
| [player-data-schema](player-data-schema/EPIC.md) | Foundation | PlayerData Schema (ADR-0011) | N/A — schema locked by ADR-0011 | 3 stories | Ready |
| [ui-handler-layer-reg](ui-handler-layer-reg/EPIC.md) | Foundation | UIHandler Layer Registration | N/A — UI prereq | 2 stories | Ready |

## Layer Coverage

| Layer | Epics Created | Notes |
|-------|---------------|-------|
| Foundation | 4 / 8 architecture rows | Path A scope: epics created only for systems with significant new work. Currency / Zone / ComponentCreator / Collision Groups deferred — fold into consuming-system stories per architecture §2.1. |
| Core | 0 | Pending `/create-epics layer: core` (TickOrchestrator, CSM, MSM, RoundLifecycle, Crowd Replication broadcast path) |
| Feature | 0 | Run after Core |
| Presentation | 0 | Run last |

## Next Steps

- Run `/create-stories asset-id-registry` (smallest, lowest risk — start here)
- Run `/create-stories network-layer-ext` (Core depends on it)
- Run `/create-stories player-data-schema`
- Run `/create-stories ui-handler-layer-reg`
- After all 4 Foundation epics have stories, run `/create-epics layer: core`

Foundation+Core epics together unblock Sprint 1 (Vertical Slice Foundation milestone).
After Core is staged, run `/gate-check pre-production` to re-evaluate the gate verdict.
