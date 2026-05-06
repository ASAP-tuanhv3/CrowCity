# Epic: AbsorbSystem (Absorb System)

> **Layer**: Feature
> **GDD**: design/gdd/absorb-system.md
> **Architecture Module**: AbsorbSystem (architecture.md §2.3 row 4)
> **Status**: Ready
> **Stories**: 7 stories drafted 2026-05-06 (lean mode; QL-STORY-READY skipped)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Phase 3 callback skeleton + DI scaffold | Logic | Ready | ADR-0002 + ADR-0006 |
| 002 | F1 overlap test + F2 contention resolution | Logic | Ready | ADR-0010 |
| 003 | Per-overlap sequence + reclaim contract + snapshot atomicity | Logic | Ready | ADR-0008 + ADR-0004 |
| 004 | State guards — Active / GraceWindow allow, Eliminated skip | Logic | Ready | ADR-0004 |
| 005 | Count clamp passthrough + Absorbed reliable RemoteEvent | Logic | Ready | ADR-0001 + ADR-0010 |
| 006 | V/A consumers — VFX AbsorbSnap + audio batching + streak escalation | Visual/Feel | Ready | ADR-0004 + VFX GDD |
| 007 | Perf soak — 3600 overlap tests p99 ≤1.5ms | Integration | Ready | ADR-0003 |

## Overview

This epic delivers the server-authoritative gameplay core that turns every neutral NPC a player's crowd touches into one more follower. Every 15 Hz server tick (Phase 3, cadence locked by ADR-0001 + ADR-0002), for every active crowd, the system runs a circle-overlap test against every active neutral NPC using the crowd's authoritative `position` and `radius` (both served by CrowdStateServer, radius derived from F1 `radius_from_count`). Every overlap triggers one `CrowdStateServer.updateCount(crowdId, +1, "Absorb")` write plus one `Absorbed(crowdId, npcLastPosition)` reliable signal — consumed by Follower Entity (slide-in spawn), VFX Manager (snap burst), and NPC Spawner (reclaim). This is Pillar 1 made mechanical: the growth loop players feel as a counter ticking up 47, 48, 49 is a tight overlap check firing 15 times per second. Small crowds absorb fast (low radius → one NPC per overlap); large crowds saturate (sqrt curve → radius grows slower than count cap) — Pillar 5 comeback comes from this math.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: TickOrchestrator | Phase 3 absorb tick callback contract (15 Hz piggyback, no separate loop) | LOW |
| ADR-0004: CSM Authority | `updateCount(+1, "Absorb")` write; one of 4 permitted callers per Pillar 4 anti-P2W matrix | LOW |
| ADR-0008: NPC Spawner Authority | `NPCSpawner.reclaim(npcId)` synchronous-callback contract; pool partition rules | MEDIUM |
| ADR-0001: Crowd Replication Strategy | `Absorbed` reliable RemoteEvent payload schema; count clamp [1, 300] | HIGH (post-cutoff) |
| ADR-0010: Server-Authoritative Validation | Overlap test runs server-only; no client-asserted absorb claims | LOW |
| ADR-0003: Performance Budget | Phase 3 budget (≤0.5 ms/tick @ 8 crowds × 60 NPCs) | MEDIUM |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/AbsorbSystem/init.luau` | LOW |

## GDD Requirements

12 TRs from `tr-registry.yaml`. Coverage post-A8/A10 acceptance:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-absorb-001 | Networking — Phase 3 piggyback | ✅ ADR-0002 |
| TR-absorb-002 | Core — F1 overlap formula (circle 2D dist²) | ❌ design-internal F1 |
| TR-absorb-003 | Authority — contention rule (crowd-vs-crowd same-tick NPC claim) | ❌ design-internal |
| TR-absorb-004 | Authority — `updateCount(+1, "Absorb")` permitted | ✅ ADR-0004 |
| TR-absorb-005 | State — count clamp [1, 300] | ✅ ADR-0001 |
| TR-absorb-006 | Authority — Phase 3 partial vs full overlap rule | ⚠️ ADR-0002 §Phase 3 partial |
| TR-absorb-007 | Authority — `NPCSpawner.reclaim` contract | ✅ ADR-0008 |
| TR-absorb-008 | Authority — concurrent absorb-vs-collision precedence | ❌ design-internal |
| TR-absorb-009 | Performance — F3 budget table | ❌ F3 design-internal |
| TR-absorb-010 | Performance — F4 caching rule | ❌ F4 design-internal |
| TR-absorb-011 | Networking — `Absorbed` reliable event | ✅ ADR-0001 + ADR-0010 |
| TR-absorb-012 | Authority — state-machine internal (no Eliminated absorbs) | ✅ ADR-0004 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/absorb-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- Phase 3 budget verified ≤0.5 ms/tick @ 8 crowds × 60 NPCs (synthetic; real-soak deferred to MVP-Integration-1)
- End-to-end integration with NPCSpawner + CSM + Follower Entity verified via integration test

## Next Step

Run `/create-stories absorb-system` to break this epic into implementable stories.
