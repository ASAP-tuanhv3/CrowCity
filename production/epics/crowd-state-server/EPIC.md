# Epic: CrowdStateServer (Crowd State Manager)

> **Layer**: Core
> **GDD**: design/gdd/crowd-state-manager.md
> **Architecture Module**: CrowdStateServer (architecture.md §3.2 row 2; API §5.1)
> **Status**: Ready (8 stories drafted 2026-04-28)
> **Stories**: 8 Ready

## Stories

| # | Story | Type | Status | Primary ADR |
|---|-------|------|--------|-------------|
| 001 | [Module skeleton + record schema + create/destroy + DC handler](story-001-module-skeleton-create-destroy-dc.md) | Logic | Ready | ADR-0001 + ADR-0004 + ADR-0006 |
| 002 | [updateCount + DeltaSource + F5 clamp + CountChanged + CrowdCountClamped](story-002-updatecount-deltasource-clamp-signals.md) | Logic | Ready | ADR-0004 |
| 003 | [Hue F6 + activeRelics cap](story-003-hue-f6-active-relics-cap.md) | Logic | Ready | ADR-0001 + ADR-0004 |
| 004 | [F1 composed radius + recomputeRadius write contract](story-004-f1-composed-radius-recompute.md) | Logic | Ready | ADR-0001 + ADR-0004 |
| 005 | [F2 position lag + nil HumanoidRootPart guard](story-005-f2-position-lag-nil-hrp-guard.md) | Logic | Ready | ADR-0004 |
| 006 | [Phase 5 state evaluator + F7 grace timer + CrowdEliminated](story-006-phase5-state-evaluator-f7-grace-timer.md) | Logic | Ready | ADR-0001 + ADR-0002 + ADR-0004 |
| 007 | [Read accessors + setStillOverlapping + Eliminated exclusion](story-007-read-accessors-set-still-overlapping.md) | Logic | Ready | ADR-0004 |
| 008 | [Phase 8 broadcastAll + buffer codec + Eliminated continues + perf](story-008-phase8-broadcastall-perf-eliminated-broadcast.md) | Integration | Ready | ADR-0001 + ADR-0002 + ADR-0003 |

Order: 001 → 002 → 003 + 004 + 005 (parallelizable post-002) → 006 (depends on 002 + 005 + 007) → 007 (depends on 001) → 008 (depends on 001..007).

## Overview

This epic delivers the authoritative server-side hub for every per-crowd record (count, hue, position, radius, state, tick, activeRelics, stillOverlapping, timer_start). CSM is the sole writer of crowd state and the sole publisher of the broadcast wire (`CrowdStateBroadcast` UREvent + 5 reliable named events). It enforces the 4-caller `updateCount` write contract (Absorb / Collision / Chest / Relic — cosmetic systems forbidden by Pillar 4 anti-P2W invariant), composes radius via `recomputeRadius` (RelicEffectHandler-only), and runs the Phase 5 state evaluator (Active ↔ GraceWindow ↔ Eliminated transitions) plus Phase 8 broadcast.

CSM is the spine of the gameplay tick — every Feature system writes through `updateCount`, every client mirrors via `CrowdStateClient`, and `CrowdEliminated` reliable signals fan out to MSM (Phase 7) + RoundLifecycle. This epic does NOT include the broadcast wire codec (lives in Foundation `network-layer-ext` story-003) or the client mirror (separate Replication Broadcast epic) — only the server module + its public API + Phase 5 evaluator + `broadcastAll` Phase 8 hook.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: CSM Authority | 4-caller write contract + Pillar 4 anti-P2W invariant + Read-vs-Write matrix; CountChanged BindableEvent server-only | LOW |
| ADR-0001: Crowd Replication Strategy | Wire format (5 reliable events + UREvent broadcast) + record schema (count [1, 300], hue [1, 12] immutable, max 4 activeRelics) | HIGH (UREvent + buffer post-cutoff) |
| ADR-0002: TickOrchestrator | Phase 5 stateEvaluate + Phase 8 broadcastAll callback contract | MEDIUM |
| ADR-0010: Server-Authoritative Validation | Silent rejection model; no parameter mutation crossing the wire boundary | LOW |
| ADR-0011: Persistence Schema + Pillar 3 Exclusions | CSM record fields are round-scoped — explicitly NEVER in `PlayerDataKey`/`DefaultPlayerData` (audit gate enforced) | LOW |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/CrowdStateServer/init.luau`; client cannot `require` from ServerStorage | LOW |

## GDD Requirements

24 TRs from `tr-registry.yaml`. Coverage post-ADR-0005 acceptance:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-csm-001 | Authority — CrowdId helper | ⚠️ ADR-0001 §Key Interfaces + ADR-0006 |
| TR-csm-002 | State — count [1, 300] | ✅ ADR-0001 |
| TR-csm-003 | Core — internal lag formula | ❌ design-internal (no ADR needed) |
| TR-csm-004 | Render — immutable hue | ✅ ADR-0001 + ADR-0004 |
| TR-csm-005 | Gameplay — max 4 activeRelics | ✅ ADR-0001 |
| TR-csm-006 | State — Phase 5 + F7 timer | ⚠️ ADR-0002 §Phase 5; F7 design-internal |
| TR-csm-007 | Gameplay/Balance — F3 placement | ❌ design-internal (no ADR needed) |
| TR-csm-008 | Core — simultaneity | ✅ ADR-0002 |
| TR-csm-009 | Authority — Read-vs-Write | ✅ ADR-0004 + arch §5.5 |
| TR-csm-010 | Gameplay/Render — radius composition | ✅ ADR-0001 |
| TR-csm-011 | Networking — Key Interfaces | ✅ ADR-0001 |
| TR-csm-012 | Networking — 5 named reliable events | ✅ ADR-0001 |
| TR-csm-013 | State/Networking — Eliminated continues broadcasting | ✅ ADR-0001 amend |
| TR-csm-014 | Authority — Write-Access Matrix | ✅ ADR-0004 |
| TR-csm-015 | Authority — participation snapshot timing | ✅ ADR-0005 (closed post-2026-04-26) |
| TR-csm-016 | Authority — module placement | ✅ ADR-0006 |
| TR-csm-017 | Authority — Pillar 4 anti-P2W | ✅ ADR-0004 |
| TR-csm-018 | Core — F2 internal | ❌ design-internal (no ADR needed) |
| TR-csm-019 | Gameplay — CCR symmetry rule | ✅ ADR-0002 §Phase 1 |
| TR-csm-020 | Performance — Phase 5/8 budget | ✅ ADR-0003 |
| TR-csm-021 | Render — Key Interfaces | ✅ ADR-0001 |
| TR-csm-022 | Networking — Write-Access + arch §5.1 | ✅ ADR-0004 |
| TR-csm-023 | State/Authority — peakTimestamp owner | ✅ ADR-0005 (closed post-2026-04-26) |
| TR-csm-024 | Gameplay/Balance — radius range | ✅ ADR-0001 amend Batch 1 |

**Coverage after ADR-0005 Accepted**: 19 ✅ / 2 ⚠️ / 3 design-internal.

⚠️ The 3 ❌ rows (TR-csm-003 / 007 / 018) are intentionally design-internal — F-formula tuning that lives in the GDD body, not subject to ADR governance. Stories citing these TRs reference the GDD section directly.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, and closed via `/story-done`
- `CrowdStateServer/init.luau` exposes the 11-method API per architecture.md §5.1: `create / destroy / updateCount / recomputeRadius / get / getAllActive / getAllCrowdPositions / setStillOverlapping / stateEvaluate / broadcastAll`, plus `CountChanged` BindableEvent
- All 24 acceptance criteria from `design/gdd/crowd-state-manager.md` are verified
- 4-caller write contract enforced (code-review + architecture invariant — cosmetic Skin System NEVER appears as `updateCount` caller; audit grep zero matches)
- Phase 5 state evaluator transitions Active → GraceWindow (count hit 1 + overlap), GraceWindow → Active (overlap cleared), GraceWindow → Eliminated (timer expired + still overlapping)
- 5 reliable RemoteEvents (`CrowdCreated / CrowdDestroyed / CrowdEliminated / CrowdCountClamped / CrowdRelicChanged`) fire per architecture §5.1 guarantees
- `broadcastAll` Phase 8 hook calls Foundation buffer codec → fires `CrowdStateBroadcast` UREvent (Replication Broadcast epic owns wire-format details)
- `updateCount` clamps to F5 [1, 300] and returns post-clamp count
- `recomputeRadius` asserts caller-side multiplier ∈ [0.5, 1.5] (RelicEffectHandler-only)
- Logic stories pass automated TestEZ tests in `tests/unit/crowd-state-server/` (write-contract enforcement, clamp boundaries, state-evaluator transitions, signal fanout, double-destroy idempotence)
- Audit gates green: `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` exit 0
- Pillar 3 exclusion verified: no CSM fields appear in `PlayerDataKey` / `DefaultPlayerData`

## Next Step

Run `/create-stories crowd-state-server` to break this epic into implementable stories.
