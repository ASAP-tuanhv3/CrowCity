# Epic: NPCSpawner (NPC Spawner)

> **Layer**: Feature
> **GDD**: design/gdd/npc-spawner.md
> **Architecture Module**: NPCSpawner (architecture.md §2.3 row 1)
> **Status**: Ready
> **Stories**: 9 stories drafted 2026-05-06 (lean mode; QL-STORY-READY skipped)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Pool bootstrap — 300 Parts chunked + Heartbeat + ARENA validation | Logic | Ready | ADR-0008 + ADR-0006 |
| 002 | reclaim() synchronous + double-reclaim assert | Logic | Ready | ADR-0008 |
| 003 | getAllActiveNPCs frozen snapshot + cache invalidation | Logic | Ready | ADR-0008 |
| 004 | Idle walk + boundary reflection (Heartbeat tick callback) | Logic | Ready | ADR-0008 |
| 005 | Respawn pipeline — delay, position, crowd exclusion, fallback | Logic | Ready | ADR-0008 |
| 006 | Respawn fade-in (TweenService 1→0 over 0.3s) | Visual/Feel | Ready | ADR-0008 |
| 007 | destroyAll() cleanup — cancel pending timers + tweens | Logic | Ready | ADR-0005 + ADR-0008 |
| 008 | F2/F4 density guards — R_absorb EPSILON guard + steady-state | Logic | Ready | ADR-0008 |
| 009 | UREvent NpcStateBroadcast + client mirror pool | Integration | Ready | ADR-0001 + ADR-0008 |

## Overview

This epic delivers the server-authoritative service that manages the full lifecycle of neutral citizen NPCs — the white, player-less figures that populate the arena and serve as raw material for the Absorb System. On `RoundLifecycle.createAll()` the spawner pre-populates the map with `NPC_POOL_SIZE = 300` reusable instances drawn from a chunked-allocation pool (25/batch via `task.defer` to avoid boot-tick spike), assigns each a starting position via the min-distance gate (consults `CSM.getAllCrowdPositions`), and starts an idle walk pattern. Per-tick it exposes `getAllActiveNPCs()` — a frozen copy of a mutable internal snapshot — consumed by Absorb at 15 Hz for overlap testing. On `reclaim(npcId)` (synchronous call from Absorb), it marks the NPC inactive, returns it to the pool, and schedules a respawn at an unoccupied map position after a configurable delay. Respawned NPCs fade in via Transparency tween (1→0 over 0.3s). NPC positions replicate via `UnreliableRemoteEvent` with client-side interpolation per ADR-0008 §Replication Channel — NOT native Roblox Part replication. The system owns two values that feed Absorb pacing formulas: `NPC_WALK_SPEED` and `ρ_design`. Without this system, the Absorb System has nothing to overlap and the core loop has no input.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: NPC Spawner Authority + Replication Channel | Pool size + replication channel + min-distance gate + reclaim contract; resolves C2 conflict | MEDIUM |
| ADR-0002: TickOrchestrator | Spawner is non-tick service (no Heartbeat); Absorb consumes via Phase 3 callback | LOW |
| ADR-0003: Performance Budget | 60 visible-NPC instance cap; 25/batch chunked pre-allocation; bandwidth table amended for UREvent NPC channel | MEDIUM |
| ADR-0001: Crowd Replication Strategy | UREvent infra + bandwidth ceiling shared with crowd broadcast | HIGH (post-cutoff buffer + UREvent) |
| ADR-0010: Server-Authoritative Validation | No client-driven NPC mutation; reclaim is server-internal contract | LOW |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/NPCSpawner/init.luau` | LOW |

## GDD Requirements

16 TRs from `tr-registry.yaml`. Coverage post-ADR-0008 acceptance (closes C2):

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-npc-spawner-001 | Performance — Pool size 300 + chunked pre-alloc | ✅ ADR-0008 §Pool Sizing |
| TR-npc-spawner-002..004 | Lifecycle — spawn/reclaim/respawn | ✅ ADR-0008 §Lifecycle Contract |
| TR-npc-spawner-005..008 | Authority — F1-F4 formulas (walk speed, density, fade-in, min-distance) | ✅ ADR-0008 §Spawn Formulas |
| TR-npc-spawner-009..014 | State — pool partition, idle walk, respawn schedule | ✅ ADR-0008 §State Machine |
| TR-npc-spawner-015 | Networking — UREvent channel definition | ✅ ADR-0008 §Replication Channel (closes C2) |
| TR-npc-spawner-016 | Networking — 60 visible NPC instance cap | ⚠️ ADR-0003 §Instance cap |

**Note**: requirements-traceability.md is dated 2026-04-26 (pre-A8 acceptance). Run `/architecture-review` after Sprint 4 sequencing to refresh coverage matrix with A8 closure.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/npc-spawner.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel stories (NPC fade-in animation) have evidence docs with sign-off in `production/qa/evidence/`
- Absorb System integration verified end-to-end: `getAllActiveNPCs()` consumed at 15 Hz; `reclaim(npcId)` round-trips correctly

## Next Step

Run `/create-stories npc-spawner` to break this epic into implementable stories.
