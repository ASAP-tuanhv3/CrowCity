# Requirements Traceability Index

> Last Updated: 2026-04-26
> Source: `/architecture-review` 2026-04-26 (full mode)
> Engine: Roblox (engine-ref pinned 2026-04-20)
> Coverage: ~33% Covered / 21% Partial / 46% Gap (286 TRs)

This index maps every GDD technical requirement to its governing ADR(s).
Per-TR text lives in `tr-registry.yaml`. This file is the read-friendly view.

Stories embed the **TR-ID** + **ADR** columns; they DO NOT embed the requirement text (it may revise).

---

## How to Read

| Status | Meaning |
|---|---|
| ✅ **Covered** | At least one Accepted/Proposed ADR explicitly addresses this TR |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is implicit |
| ❌ **Gap** | No ADR currently addresses this TR; named required ADR identified |

Required-ADR shorthand:
- **A1** = ADR-0001 Crowd Replication Strategy (Proposed, amended 3×)
- **A2** = ADR-0002 TickOrchestrator (Proposed)
- **A3** = ADR-0003 Performance Budget (Proposed)
- **A4** = ADR-0004 CSM Authority (Proposed)
- **A6** = ADR-0006 Module Placement Rules (Proposed)
- **A5** = ADR-0005 MSM/RoundLifecycle Split (NOT YET WRITTEN)
- **A7** = ADR-0007 Client Rendering Strategy (NOT YET WRITTEN, deferrable)
- **A8** = ADR-0008 NPC Spawner Authority (NOT YET WRITTEN)
- **A9** = ADR-0009 VFX Suppression Tiers (NOT YET WRITTEN, deferrable)
- **A10** = ADR-0010 Server-Auth Validation Policy (NOT YET WRITTEN)
- **A11** = ADR-0011 Persistence Schema + Pillar 3 Exclusions (NOT YET WRITTEN)

---

## Coverage Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered | 95 | 33% |
| ⚠️ Partial | 60 | 21% |
| ❌ Gap | 131 | 46% |
| **Total TRs** | **286** | **100%** |

---

## Per-System Matrix

### game-concept (12 TRs — 7 ✅ / 1 ⚠️ / 4 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-game-concept-001 | Platform | ✅ | A1 §Constraints |
| TR-game-concept-002 | Gameplay | ⚠️ | A2 §Phase 3 (orchestration only) → owns design contract in absorb GDD |
| TR-game-concept-003 | Core | ✅ | A2 §Phase 1 + A4 §updateCount("Collision") |
| TR-game-concept-004 | Gameplay | ✅ | A2 §Phase 4 + A4 §updateCount("Chest") |
| TR-game-concept-005 | State | ❌ | A11 needed |
| TR-game-concept-006 | Authority | ✅ | A4 §Pillar 4 anti-P2W |
| TR-game-concept-007 | Render/UI | ✅ | A4 §Permitted cosmetic data flow |
| TR-game-concept-008 | Persistence | ❌ | A11 needed |
| TR-game-concept-009 | Networking | ✅ | A1 §Constraints |
| TR-game-concept-010 | Render | ✅ | A4 §Permitted cosmetic data flow |
| TR-game-concept-011 | Content | n/a | content scope, not architectural |
| TR-game-concept-012 | Authority | ✅ | A1 §Decision + A4 |

### systems-index (10 TRs — 5 ✅ / 1 ⚠️ / 4 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-systems-index-001 | meta | n/a | catalogue, not architectural |
| TR-systems-index-002 | Networking | ✅ | A1 §Prototype Validation |
| TR-systems-index-003 | Performance/Core | ✅ | A1 §Decision (no Humanoid) |
| TR-systems-index-004 | Performance/Render | ⚠️ | A1 §Decision Architecture Diagram + A3 §Instance caps (note D3 drift in source GDD text "80/30/15/4") |
| TR-systems-index-005 | Core/Timing | ✅ | A2 §Decision |
| TR-systems-index-006 | State | ❌ | A5 needed |
| TR-systems-index-007 | Gameplay | ❌ | A8 needed |
| TR-systems-index-008 | Core | ✅ | A6 §Source Tree Map |
| TR-systems-index-009 | Persistence | ⚠️ | A6 §Vendored Policy (placement); A11 needed (schema) |
| TR-systems-index-010 | Core/Networking | ❌ | A5 needed |

### crowd-state-manager (24 TRs — 13 ✅ / 4 ⚠️ / 7 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-csm-001 | Authority | ⚠️ | A1 §Key Interfaces + A6 (CrowdId helper noted) |
| TR-csm-002 | State | ✅ | A1 §Key Interfaces (count [1, 300]) |
| TR-csm-003 | Core | ❌ | CSM internal lag formula — design-internal, no ADR |
| TR-csm-004 | Render | ✅ | A1 §Key Interfaces (immutable hue) + A4 §Read-vs-Write |
| TR-csm-005 | Gameplay | ✅ | A1 §Key Interfaces (max 4 activeRelics) |
| TR-csm-006 | State | ⚠️ | A2 §Phase 5; F7 timer formula design-internal |
| TR-csm-007 | Gameplay/Balance | ❌ | F3 formula — design-internal |
| TR-csm-008 | Core | ✅ | A2 §simultaneity rules |
| TR-csm-009 | Authority | ✅ | A4 §Read-vs-Write + Architecture §5.5 |
| TR-csm-010 | Gameplay/Render | ✅ | A1 §Key Interfaces |
| TR-csm-011 | Networking | ✅ | A1 §Key Interfaces |
| TR-csm-012 | Networking | ✅ | A1 §Key Interfaces (5 named events) |
| TR-csm-013 | State/Networking | ✅ | A1 amend (state=Eliminated continues) |
| TR-csm-014 | Authority | ✅ | A4 §Write-Access Matrix |
| TR-csm-015 | Authority | ❌ | A5 needed (participation snapshot timing) |
| TR-csm-016 | Authority | ✅ | A6 §Source Tree Map |
| TR-csm-017 | Authority | ✅ | A4 §Pillar 4 anti-P2W |
| TR-csm-018 | Core | ❌ | F2 internal — design only |
| TR-csm-019 | Gameplay | ✅ | A2 §Phase 1 (CCR symmetry rule) |
| TR-csm-020 | Performance | ✅ | A3 §Phase 5/8 (0.6 ms total) |
| TR-csm-021 | Render | ✅ | A1 §Key Interfaces |
| TR-csm-022 | Networking | ✅ | A4 §Write-Access Matrix + Architecture §5.1 |
| TR-csm-023 | State/Authority | ❌ | A5 needed (peakTimestamp owner) |
| TR-csm-024 | Gameplay/Balance | ✅ | A1 amend Batch 1 |

### match-state-machine (20 TRs — 4 ✅ / 4 ⚠️ / 12 ❌)

All ❌ rows resolve to **A5 MSM/RoundLifecycle Split** unless noted.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-msm-001 | Core | ❌ | A5 |
| TR-msm-002 | Authority | ❌ | A5 |
| TR-msm-003 | Core | ❌ | A5 |
| TR-msm-004 | Authority | ⚠️ | A2 §Phase 7 partial; A5 finalises |
| TR-msm-005 | Core/Timing | ✅ | A2 §Phase 6 |
| TR-msm-006 | Authority | ❌ | A5 |
| TR-msm-007 | Core/Timing | ✅ | A2 §simultaneity Phase 6 < Phase 7 |
| TR-msm-008 | Authority | ❌ | A5 |
| TR-msm-009 | Networking | ⚠️ | Architecture §5.7 (no ADR locks wire format); A5 finalises |
| TR-msm-010 | Authority | ❌ | A5 |
| TR-msm-011 | Authority | ❌ | A5 |
| TR-msm-012 | UI/Core | ❌ | A5 |
| TR-msm-013 | Networking | ⚠️ | Architecture §5.7; A5 finalises |
| TR-msm-014 | Persistence/Networking | ⚠️ | Architecture §4.5 + A6 §ProfileStore note; A11 finalises schema |
| TR-msm-015 | Authority | ✅ | A2 §Phase 7 (double-signal guard) |
| TR-msm-016 | Gameplay | ❌ | A5 (spectator mode) |
| TR-msm-017 | Authority | ❌ | A5 (grant-before-broadcast invariant) |
| TR-msm-018 | Performance | ✅ | A3 §Phase 6/7 (0.1 ms total) |
| TR-msm-019 | Core/Timing | ✅ | A2 §Decision |
| TR-msm-020 | Networking | ❌ | A5 (clock consistency invariant) |

### round-lifecycle (16 TRs — 1 ✅ / 4 ⚠️ / 11 ❌)

All ❌ rows → **A5**.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-round-lifecycle-001 | State | ❌ | A5 |
| TR-round-lifecycle-002 | Authority | ❌ | A5 |
| TR-round-lifecycle-003 | Authority | ❌ | A5 |
| TR-round-lifecycle-004 | Authority | ❌ | A5 |
| TR-round-lifecycle-005 | Authority | ❌ | A5 |
| TR-round-lifecycle-006 | Authority | ⚠️ | A2 §Phase 7; A5 finalises |
| TR-round-lifecycle-007 | Authority | ❌ | A5 |
| TR-round-lifecycle-008 | State/Persistence | ⚠️ | A6 §Wally Janitor; A5 lifecycle |
| TR-round-lifecycle-009 | Authority | ❌ | A5 |
| TR-round-lifecycle-010 | Authority | ⚠️ | A3 §Memory + Architecture §5.3 |
| TR-round-lifecycle-011 | Networking | ✅ | A4 §Write-Access Matrix (CountChanged subscribe) |
| TR-round-lifecycle-012 | State | ❌ | A5 |
| TR-round-lifecycle-013 | Networking | ❌ | A5 (broadcast-shape stripping) |
| TR-round-lifecycle-014 | Authority | ❌ | A5 |
| TR-round-lifecycle-015 | Authority | ❌ | A5 |
| TR-round-lifecycle-016 | Performance | ⚠️ | A3 §Reserve (not explicitly allocated) |

### crowd-replication-strategy (27 TRs — 25 ✅ / 2 ⚠️ / 0 ❌)

Best-covered system. ADR-0001 + GDD are 1:1.

All TR-crs-001 through TR-crs-024 ✅ A1 (varies by §Decision / Key Interfaces / Risks / amends).
TR-crs-025 / 026 ✅ A3 §Network bandwidth budget + Burst allowance.
TR-crs-027 ✅ A1 + A4.

⚠️ items: TR-crs-021 cross-channel ordering "advisory" (no ADR locks); TR-crs-024 mid-round join blocked (A1 negative consequence note).

### follower-entity (20 TRs — 3 ✅ / 2 ⚠️ / 15 ❌)

All ❌ rows → **A7 Client Rendering Strategy** unless noted.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-follower-entity-001 | Core | ✅ | A1 §Decision (no Humanoid) |
| TR-follower-entity-002 | Core | ⚠️ | **C1 conflict** — A1 says 4-6-part, GDD says 2-Part |
| TR-follower-entity-003 | Performance | ❌ | A7 |
| TR-follower-entity-004 | Performance | ⚠️ | A3 §Reserve (implicit) |
| TR-follower-entity-005 | State | ❌ | design-internal (F8 walk-bob) |
| TR-follower-entity-006 | State | ❌ | A7 |
| TR-follower-entity-007 | State | ❌ | design-internal |
| TR-follower-entity-008 | Authority | ❌ | A7 |
| TR-follower-entity-009 | Core | ❌ | A7 |
| TR-follower-entity-010 | State | ❌ | design-internal |
| TR-follower-entity-011 | State | ❌ | A7 |
| TR-follower-entity-012 | State | ❌ | A7 |
| TR-follower-entity-013 | Networking | ❌ | A7 |
| TR-follower-entity-014 | Performance | ❌ | A7 |
| TR-follower-entity-015 | Render | ✅ | A1 §Decision + A3 §Instance caps |
| TR-follower-entity-016 | State | ❌ | A7 |
| TR-follower-entity-017 | State | ❌ | design-internal |
| TR-follower-entity-018 | State | ❌ | A7 |
| TR-follower-entity-019 | State | ❌ | A7 |
| TR-follower-entity-020 | Authority | ✅ | A4 §Pillar 4 + A1 §authority model |

### follower-lod-manager (13 TRs — 4 ✅ / 2 ⚠️ / 7 ❌)

All ❌ → **A7**.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-lod-001 | Networking | ⚠️ | Architecture §3.4 + A1 §Tick rates |
| TR-lod-002 | Performance | ❌ | A7 |
| TR-lod-003 | State | ❌ | A7 |
| TR-lod-004 | Performance | ⚠️ | A3 §Mobile binding (implicit) |
| TR-lod-005 | Authority | ❌ | A7 |
| TR-lod-006 | Render | ✅ | A1 amend Batch 3 |
| TR-lod-007 | Performance | ❌ | A7 |
| TR-lod-008 | Render | ✅ | A1 §Decision |
| TR-lod-009 | Render | ✅ | A1 §Decision |
| TR-lod-010 | State | ❌ | A7 |
| TR-lod-011 | State | ❌ | A7 |
| TR-lod-012 | Networking | ✅ | A1 amend (CrowdEliminated reliable) |
| TR-lod-013 | State | ❌ | A7 |

### npc-spawner (16 TRs — 0 ✅ / 2 ⚠️ / 14 ❌)

All ❌ → **A8 NPC Spawner Authority**. C2 conflict resolution gates this.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-npc-spawner-001..014 | various | ❌ | A8 (pool, respawn, F1-F4 formulas, density gate) |
| TR-npc-spawner-015 | Networking | ⚠️ | **C2 conflict** — A1 covers UREvent infra; channel undefined |
| TR-npc-spawner-016 | Networking | ⚠️ | A3 §Instance cap (60 visible NPCs) |

### absorb-system (12 TRs — 4 ✅ / 3 ⚠️ / 5 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-absorb-001 | Networking | ✅ | A2 §Phase 3 |
| TR-absorb-002 | Core | ❌ | design-internal F1 |
| TR-absorb-003 | Authority | ❌ | design-internal contention rule |
| TR-absorb-004 | Authority | ✅ | A4 §updateCount("Absorb") |
| TR-absorb-005 | State | ✅ | A1 §Key Interfaces (clamp [1, 300]) |
| TR-absorb-006 | Authority | ⚠️ | A2 §Phase 3 partial |
| TR-absorb-007 | Authority | ❌ | A8 (NPCSpawner.reclaim contract) |
| TR-absorb-008 | Authority | ⚠️ | design-internal |
| TR-absorb-009 | Performance | ❌ | F3 design |
| TR-absorb-010 | Performance | ❌ | F4 design |
| TR-absorb-011 | Networking | ⚠️ | Architecture §5.7 + A10 needed |
| TR-absorb-012 | Authority | ✅ | A4 §Read-vs-Write (state machine internal) |

### crowd-collision-resolution (20 TRs — 8 ✅ / 4 ⚠️ / 8 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-ccr-001 | Networking | ✅ | A2 §Phase 1 |
| TR-ccr-002 | Performance | ⚠️ | A3 §Phase 1 budget (0.6 ms) |
| TR-ccr-003 | Core | ❌ | design-internal F1 |
| TR-ccr-004 | Authority | ✅ | A4 §updateCount("Collision") |
| TR-ccr-005 | Authority | ⚠️ | A2 §simultaneity (equal-count rule) |
| TR-ccr-006 | Authority | ❌ | F3 design — needs A10 or design-internal |
| TR-ccr-007 | Authority | ⚠️ | A2 §Phase 1 (state-skip rule) |
| TR-ccr-008 | Authority | ✅ | A4 §setStillOverlapping |
| TR-ccr-009 | Networking | ❌ | A10 (PairEntered reliable contract) |
| TR-ccr-010 | Networking | ❌ | design-internal (peel emission) |
| TR-ccr-011 | Performance | ✅ | A2 §Phase 9 |
| TR-ccr-012 | Networking | ❌ | A10 (relevance filter) |
| TR-ccr-013 | Networking | ❌ | A10 |
| TR-ccr-014 | Networking | ⚠️ | A1 (peel not specifically named) |
| TR-ccr-015 | Authority | ✅ | A2 §Phase ordering |
| TR-ccr-016 | Authority | ✅ | A4 §Write-Access Matrix |
| TR-ccr-017 | State | ❌ | F2 design |
| TR-ccr-018 | Authority | ✅ | A2 §simultaneity |
| TR-ccr-019 | Authority | ✅ | A4 §Write-Access Matrix |
| TR-ccr-020 | Performance | ✅ | A3 §Phase 1 |

### chest-system (21 TRs — 4 ✅ / 6 ⚠️ / 11 ❌)

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-chest-001 | Core | ✅ | A4 §updateCount("Chest") + A2 atomicity |
| TR-chest-002 | Authority | ⚠️ | Architecture §5.5 (no ADR locks pipeline) |
| TR-chest-003 | State | ⚠️ | Architecture §5.5 |
| TR-chest-004 | Core | ❌ | F1 design |
| TR-chest-005 | Networking | ⚠️ | Architecture §5.5 + A4 |
| TR-chest-006 | State | ❌ | design-internal |
| TR-chest-007 | Authority | ❌ | design-internal |
| TR-chest-008 | Core | ❌ | design-internal |
| TR-chest-009 | State | ❌ | design-internal |
| TR-chest-010 | Networking | ⚠️ | A2 §Phase 9 |
| TR-chest-011 | Core | ⚠️ | Architecture §5.5 |
| TR-chest-012 | Core | ❌ | design-internal |
| TR-chest-013 | Networking | ❌ | design-internal |
| TR-chest-014 | Persistence | ❌ | design-internal |
| TR-chest-015 | Core | ❌ | design-internal (T9 destroyAll order) |
| TR-chest-016 | Timing | ✅ | A2 §Phase 4 |
| TR-chest-017 | State | ❌ | design-internal |
| TR-chest-018 | UI | ❌ | design-internal (UI binding) |
| TR-chest-019 | Authority | ⚠️ | Architecture §5.5 |
| TR-chest-020 | Authority | ✅ | A2 §atomicity |
| TR-chest-021 | UI | ✅ | A3 §Instance caps (9 prompts) |

### relic-system (21 TRs — 7 ✅ / 2 ⚠️ / 12 ❌)

Most ❌ are design-internal (relic-specific tuning, framework hooks). A11 covers persistence-related rule.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-relic-001 | State | ✅ | A1 §Key Interfaces + Architecture §5.1 |
| TR-relic-002 | Core | ❌ | design-internal |
| TR-relic-003 | Authority | ❌ | design-internal (atomic grant) |
| TR-relic-004 | Core | ✅ | A4 §updateCount("Relic") |
| TR-relic-005 | Core | ✅ | A4 §recomputeRadius RelicEffectHandler-only |
| TR-relic-006 | Networking | ❌ | design-internal (modifier publishing) |
| TR-relic-007 | Timing | ✅ | A2 §Phase ordering |
| TR-relic-008 | Timing | ✅ | A2 §Phase 2 + Phase 3 visibility |
| TR-relic-009 | State | ⚠️ | A2 §Phase 5/8; A5 finalises clearAll T9 |
| TR-relic-010 | Networking | ✅ | A1 §Key Interfaces (CrowdRelicChanged) |
| TR-relic-011 | State | ❌ | design-internal |
| TR-relic-012 | Authority | ❌ | design-internal |
| TR-relic-013 | Timing | ❌ | design-internal |
| TR-relic-014 | Persistence | ❌ | design-internal |
| TR-relic-015 | Core | ❌ | relic-spec-internal |
| TR-relic-016 | Core | ❌ | relic-spec-internal |
| TR-relic-017 | Core | ❌ | relic-spec-internal |
| TR-relic-018 | Authority | ❌ | design-internal |
| TR-relic-019 | Networking | ⚠️ | A4 §Write-Access Matrix |
| TR-relic-020 | Persistence | ❌ | A11 needed (Pillar 3 exclusion) |
| TR-relic-021 | Core | ✅ | Architecture §5.6 (Relic framework) |

### hud (20 TRs — 3 ✅ / 2 ⚠️ / 15 ❌)

Most ❌ are design-internal UI rules; A1 + A6 cover infrastructure, A3 covers budget.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-hud-001 | UI | ⚠️ | A6 §Source Tree Map (UIHandler) |
| TR-hud-002..016 | UI | ❌ | design-internal HUD rules |
| TR-hud-006 | Performance | ⚠️ | A1 §Risk 3 (stale defense) |
| TR-hud-017 | Performance | ⚠️ | A3 §Client per-frame HUD 1.0 ms (D2 drift) |
| TR-hud-018 | Networking | ✅ | A1 amend Batch 1 (CrowdCountClamped) |
| TR-hud-019 | Networking | ✅ | A1 §Key Interfaces (CrowdRelicChanged) |
| TR-hud-020 | UI | ❌ | design-internal |

### player-nameplate (15 TRs — 4 ✅ / 4 ⚠️ / 7 ❌)

Most ❌ → design-internal nameplate rules.

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-nameplate-001 | UI | ❌ | design-internal (BillboardGui pattern) |
| TR-nameplate-002 | UI | ❌ | art-bible §3 + design-internal |
| TR-nameplate-003 | UI | ❌ | design-internal |
| TR-nameplate-004 | State | ⚠️ | A1 §Key Interfaces (hue field) |
| TR-nameplate-005..008 | UI | ❌ | design-internal F1/F2 + state |
| TR-nameplate-009 | Performance | ⚠️ | A3 §Instance caps |
| TR-nameplate-010 | Core | ✅ | A6 §Source Tree Map (client-side only) |
| TR-nameplate-011 | Performance | ⚠️ | A1 §Risk 3 |
| TR-nameplate-012 | UI | ❌ | design-internal |
| TR-nameplate-013 | Performance | ⚠️ | A3 §Client per-frame Nameplate 0.5 ms |
| TR-nameplate-014 | Core | ✅ | A1 §Key Interfaces + A4 §CountChanged |
| TR-nameplate-015 | State | ✅ | A1 amend (CrowdEliminated reliable) |

### vfx-manager (19 TRs — 3 ✅ / 5 ⚠️ / 11 ❌)

Most ❌ → A9 VFX Suppression Tiers (deferrable).

| TR-ID | Domain | Status | ADR(s) |
|---|---|---|---|
| TR-vfx-001 | Core | ✅ | A6 §Source Tree Map (client-only) |
| TR-vfx-002 | Core | ⚠️ | A6 + Architecture §3.4 |
| TR-vfx-003 | Networking | ⚠️ | A1 §Key Interfaces (partial) |
| TR-vfx-004 | Core | ✅ | A6 §Source Tree Map (AssetId enum) |
| TR-vfx-005 | Core | ❌ | A9 |
| TR-vfx-006 | Performance | ⚠️ | A3 §Instance caps |
| TR-vfx-007 | Performance | ✅ | A3 §Worst-Case Instance Caps |
| TR-vfx-008 | Performance | ❌ | A9 (per-effect priority lock) |
| TR-vfx-009 | Performance | ⚠️ | A3 + A9 |
| TR-vfx-010 | Performance | ❌ | A9 |
| TR-vfx-011 | Core | ❌ | A9 |
| TR-vfx-012 | Networking | ❌ | design-internal |
| TR-vfx-013 | Timing | ❌ | design-internal |
| TR-vfx-014 | Performance | ⚠️ | A2 §no-yield (compatible) |
| TR-vfx-015 | Core | ❌ | A9 |
| TR-vfx-016 | Core | ❌ | A9 |
| TR-vfx-017 | State | ❌ | A9 |
| TR-vfx-018 | Performance | ✅ | A3 §Instance caps |
| TR-vfx-019 | Performance | ❌ | A9 (priority assignments) |

---

## Uncovered Requirements (Priority Fix List)

Required ADRs prioritised by Gap-TR count + criticality:

### Foundation / Core layer gaps (BLOCKING)

1. **ADR-0005 MSM/RoundLifecycle Split** — closes ~35 Gap TRs (msm + round-lifecycle).
2. **ADR-0008 NPC Spawner Authority** — closes ~14 Gap TRs + resolves **C2 conflict** (NPC replication channel).

### Core / Feature layer gaps (should-have)

3. **ADR-0010 Server-Auth Validation Policy** — closes ~10 Gap TRs (CCR PairEntered, peel relevance, absorb reliable, chest 6-guard pattern).
4. **ADR-0011 Persistence Schema + Pillar 3 Exclusions** — closes ~5 Gap TRs.

### Presentation layer gaps (deferrable)

5. **ADR-0007 Client Rendering Strategy** — closes ~22 Gap TRs (rig + boids + LOD detail).
6. **ADR-0009 VFX Suppression Tier Assignments** — closes ~6 Gap TRs.

### Existing-ADR amendments (BLOCKING for transition to Accepted)

- **ADR-0001 §Decision** — fix C1 follower rig 4-6-part vs 2-Part (recommend defer to A7).
- **ADR-0004 §ADR Dependencies** — D1 reciprocal-ref drift (add A6 to Depends On OR remove §Module Placement Firewall "depends on ADR-0006 codification" wording).

### Documentation drift (NON-BLOCKING)

- **D2** — HUD GDD AC-22 cite A3 § Client per-frame budget; clarify peak vs steady framing.
- **D3** — `systems-index.md` row #11 description "80/30/15/4" → "80/30/15/1 billboard" sync.

---

## History

| Date | Coverage % | Notes |
|---|---|---|
| 2026-04-26 | 33% Covered / 21% Partial / 46% Gap | Initial RTM. Registry populated 286 entries. 5 ADRs Proposed. 6 ADRs outstanding (4 should-have, 2 deferrable). |
