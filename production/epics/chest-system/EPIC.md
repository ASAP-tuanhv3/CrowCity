# Epic: ChestSystem (Chest System)

> **Layer**: Feature
> **GDD**: design/gdd/chest-system.md
> **Architecture Module**: ChestSystem (server) + ChestDraftClient (client) (architecture.md §2.3 row 6 + §5.5)
> **Status**: Ready
> **Stories**: 11 stories drafted 2026-05-06 (lean mode; QL-STORY-READY skipped)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Spawn — ChestComponent + ProximityPrompt + T1/T2/T3 tier | Logic | Ready | ADR-0006 + ADR-0003 |
| 002 | Guard pipeline — 6-stage strict serial reject | Logic | Ready | ADR-0010 |
| 003 | Open exclusivity — 2D distance + UserId tiebreak | Logic | Ready | ADR-0010 |
| 004 | F1 base_toll_scaled formula | Logic | Ready | GDD F1 |
| 005 | F2 effective_toll + queryChestToll + Relic modifier register | Logic | Ready | ADR-0004 + GDD F2 |
| 006 | Atomic claim — Phase 4 deduction + state + ChestPeelOff | Logic | Ready | ADR-0002 + ADR-0004 |
| 007 | F3 draft roll — distinct + re-roll + rarity fallback + refund | Logic | Ready | GDD F3 + ADR-0001 |
| 008 | ChestDraftOffer/Pick remotes + 8s timeout + grant + destroy | Integration | Ready | ADR-0001 + ADR-0010 |
| 009 | destroyAll cleanup — DraftOpen auto-pick first + state cleanup | Logic | Ready | ADR-0005 + ADR-0002 |
| 010 | DC mid-DraftOpen + Eliminated draft modal close | Integration | Ready | ADR-0005 + ADR-0001 |
| 011 | Respawn pipeline + Part materialize tween + Toll billboard | Visual/Feel | Ready | ADR-0003 + GDD §C9 |

## Overview

This epic delivers the server-authoritative spawn, proximity-interaction, toll-deduction, and relic-draft-orchestration layer for every chest instance in a round. Static chest Parts are tagged with `ChestTag` + `ChestTierAttribute` by Level Design; on `RoundLifecycle.createAll()` the system scans tagged instances, attaches a `ChestComponent` via `ComponentCreator` (ANATOMY §9), activates the `ProximityPrompt`, and raises the overhead toll billboard. When a player with `participationFlag = TRUE` and crowd state `Active` triggers the prompt, a serial 6-guard pre-check pipeline runs — Match State `Active`, relic slots not full, live `count > queryChestToll(tier, baseToll)` — any failure greys the prompt and rejects silently (no toll ever partial-spent). On success the system deducts the toll atomically via `CrowdStateServer.updateCount(crowdId, -effectiveToll, "Chest")`, rolls a 3-candidate draft from `RelicRegistry` filtered by tier + excluding held, broadcasts the draft to the opening client's modal UI, and on pick fires `RelicEffectHandler.grant(crowdId, specId)` before destroying the chest instance and scheduling tier respawn. Also exposes `setRelicModifier` / `clearRelicModifier` APIs consumed by non-state toll-discount relics (`TollBreaker`). Server-guards on `participationFlag AND state == Active`. Chests disappear at `RoundLifecycle.destroyAll()` and never persist (Pillar 3).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: CSM Authority | `updateCount(-toll, "Chest")` permitted; one of 4 write-callers per Pillar 4 anti-P2W matrix | LOW |
| ADR-0002: TickOrchestrator | Phase 4 chest tick (toll deduction atomicity); Phase 9 cleanup for destroyed chest instances | LOW |
| ADR-0003: Performance Budget | 9 ProximityPrompt instance cap (3 tiers × 3 chests); UI binding cost budget | MEDIUM |
| ADR-0010: Server-Authoritative Validation | All toll/draft state server-only; client modal is display-only | LOW |
| ADR-0001: Crowd Replication Strategy | Reliable RemoteEvent for draft broadcast + pick (low-frequency, no UREvent) | LOW |
| ADR-0006: Module Placement Rules | Server module under `ServerStorage/Source/ChestSystem/`; client modal under `ReplicatedStorage/Source/ChestDraftClient.luau` | LOW |

## GDD Requirements

21 TRs from `tr-registry.yaml`. Coverage:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-chest-001 | Core — atomic toll deduction | ✅ ADR-0004 + ADR-0002 atomicity |
| TR-chest-002 | Authority — 6-guard pipeline | ⚠️ Architecture §5.5 (no ADR locks pipeline) |
| TR-chest-003 | State — 7-state per-chest machine | ⚠️ Architecture §5.5 |
| TR-chest-004 | Core — F1 toll formula `queryChestToll` | ❌ F1 design-internal |
| TR-chest-005 | Networking — draft RemoteEvent | ⚠️ Architecture §5.5 + ADR-0004 |
| TR-chest-006..009 | State — chest state-machine internals | ❌ design-internal |
| TR-chest-010 | Networking — destroyed-chest cleanup | ⚠️ ADR-0002 §Phase 9 |
| TR-chest-011 | Core — ChestComponent creation order | ⚠️ Architecture §5.5 |
| TR-chest-012..015 | Core/State — respawn/destroyAll/spec rules | ❌ design-internal |
| TR-chest-016 | Timing — toll deduction phase ordering | ✅ ADR-0002 §Phase 4 |
| TR-chest-017 | State — modal close-on-elim hook | ❌ design-internal |
| TR-chest-018 | UI — UI binding | ❌ design-internal (UI binding) |
| TR-chest-019 | Authority — `setRelicModifier` API | ⚠️ Architecture §5.5 |
| TR-chest-020 | Authority — atomic deduct-then-grant | ✅ ADR-0002 atomicity |
| TR-chest-021 | UI — 9 ProximityPrompt instance cap | ✅ ADR-0003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/chest-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All UI/Visual stories (chest billboard, draft modal, confetti VFX) have evidence docs with sign-off in `production/qa/evidence/`
- Atomic toll-deduction-then-grant invariant verified end-to-end (no partial toll, no orphan grants)

## Next Step

Run `/create-stories chest-system` to break this epic into implementable stories.
