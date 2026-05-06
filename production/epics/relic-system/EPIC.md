# Epic: RelicSystem (Relic System)

> **Layer**: Feature
> **GDD**: design/gdd/relic-system.md
> **Architecture Module**: RelicSystem (architecture.md §2.3 row 7 + §5.6)
> **Status**: Ready
> **Stories**: 11 stories drafted 2026-05-06 (lean mode; QL-STORY-READY skipped)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | RelicRegistry static load + 3 reference relic specs | Logic | Ready | ADR-0006 + ADR-0011 |
| 002 | Slot state machine + grant atomic + slot-cap defensive late-check | Logic | Ready | ADR-0004 + ADR-0001 |
| 003 | Hook dispatch — Phase 2 onTick + onAcquire/onExpire ordering | Logic | Ready | ADR-0002 |
| 004 | Surge — count relic via updateCount + GraceWindow rules | Logic | Ready | ADR-0004 |
| 005 | Wingspan — radius multiplier via recomputeRadius | Logic | Ready | ADR-0004 |
| 006 | TollBreaker — non-state modifier publish to Chest System | Logic | Ready | ADR-0004 + Chest §5.5 |
| 007 | CrowdRelicChanged broadcast + privateState exclusion + duration | Logic | Ready | ADR-0001 |
| 008 | clearAll T9 + DC flush via CrowdDestroyed + idempotency | Logic | Ready | ADR-0005 |
| 009 | grant() guards — Eliminated reject + Pillar 3 audit + onTick | Logic | Ready | ADR-0004 + ADR-0011 |
| 010 | Phase 2 perf budget — 0.1 ms/tick advisory soak | Integration | Ready | ADR-0003 |
| 011 | Delete RelicSystemStub + selene clean post-removal | Config/Data | Ready | ADR-0006 |

## Overview

This epic delivers the server-authoritative registry, dispatch, and round-scoped lifecycle owner for every run-modifying effect a player can acquire during a match. Each crowd holds up to `MAX_RELIC_SLOTS = 4` active relics (cap owned by CSM); grants flow exclusively from Chest System after a successful follower-toll payment and vanish at match end. The system itself is thin: a static `RelicRegistry` of typed specs (id, rarity, effect hooks, stack rules, UI copy) loaded at boot, plus a `RelicEffectHandler` module that wires each acquired relic to the system it actually modifies — count-mutating relics route through `CrowdStateServer.updateCount(.., "Relic")` (never direct), radius relics write a multiplier into the crowd record before `radius_from_count` is stored, and non-state relics (move speed, toll discount, absorb radius, crowd magnetism) publish their modifier to the owning system (Follower Entity, Chest, Absorb). The handler is the integration seam; the registry is the content surface. Lifecycle is framed by Match State Machine: `clearAll()` fires at T9 (Intermission entry) after `RoundLifecycle.destroyAll()`, and `CrowdRelicChanged` (reliable, snapshot-on-change) tells clients when to redraw the HUD slot bar. State strictly ephemeral — no relic survives a round (Pillar 3), no persistent power progression, no Eliminated revival in MVP. MVP scope: framework + 3 reference relics (TollBreaker, Surge, Wingspan) replacing the current `RelicSystemStub`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: CSM Authority | `updateCount(.., "Relic")` permitted; `recomputeRadius` is RelicEffectHandler-only; `addActiveRelic`/`removeActiveRelic` per Write-Access Matrix amendment | LOW |
| ADR-0001: Crowd Replication Strategy | `CrowdRelicChanged` reliable RemoteEvent + `activeRelics` array (max 4) record schema | HIGH (post-cutoff) |
| ADR-0002: TickOrchestrator | Phase 2 + Phase 3 visibility; phase ordering per simultaneity rules | LOW |
| ADR-0011: Persistence Schema + Pillar 3 Exclusions | Relics are explicitly forbidden in `PlayerDataKey`/`DefaultPlayerData` (audit-persistence gate enforces) | LOW |
| ADR-0010: Server-Authoritative Validation | All grant flows server-only; no client-asserted relic claims | LOW |
| ADR-0006: Module Placement Rules | Server module under `ServerStorage/Source/RelicSystem/init.luau` | LOW |

## GDD Requirements

21 TRs from `tr-registry.yaml`. Coverage:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-relic-001 | State — `MAX_RELIC_SLOTS = 4` cap | ✅ ADR-0001 + Architecture §5.1 |
| TR-relic-002 | Core — RelicRegistry static load | ❌ design-internal |
| TR-relic-003 | Authority — atomic grant flow | ❌ design-internal (atomic grant) |
| TR-relic-004 | Core — `updateCount("Relic")` permitted | ✅ ADR-0004 |
| TR-relic-005 | Core — `recomputeRadius` RelicEffectHandler-only | ✅ ADR-0004 |
| TR-relic-006 | Networking — non-state relic modifier publishing | ❌ design-internal |
| TR-relic-007 | Timing — Phase ordering | ✅ ADR-0002 |
| TR-relic-008 | Timing — Phase 2 + Phase 3 visibility | ✅ ADR-0002 |
| TR-relic-009 | State — `clearAll` at T9 | ⚠️ ADR-0002 §Phase 5/8; ADR-0005 finalises clearAll T9 |
| TR-relic-010 | Networking — `CrowdRelicChanged` reliable | ✅ ADR-0001 |
| TR-relic-011..018 | State/Authority/Timing — relic-spec internals | ❌ design-internal (per relic-spec) |
| TR-relic-019 | Networking — Write-Access | ⚠️ ADR-0004 |
| TR-relic-020 | Persistence — Pillar 3 exclusion | ✅ ADR-0011 |
| TR-relic-021 | Core — relic-spec internal | ❌ relic-spec-internal |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/relic-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- 3 reference relics (TollBreaker, Surge, Wingspan) implemented + integration-tested with Chest grant + CSM updateCount paths
- `RelicSystemStub` deleted from `_PhaseStubs/`; selene clean post-removal
- `clearAll` at T9 verified end-to-end (no relic state survives Intermission)

## Next Step

Run `/create-stories relic-system` to break this epic into implementable stories.
