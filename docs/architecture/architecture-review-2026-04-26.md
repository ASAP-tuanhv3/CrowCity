# Architecture Review Report — 2026-04-26

**Date**: 2026-04-26
**Engine**: Roblox (continuously-updated live service; engine-ref pinned 2026-04-20)
**Mode**: `/architecture-review full`
**GDDs Reviewed**: 16 (game-concept, systems-index, crowd-state-manager, match-state-machine, round-lifecycle, crowd-replication-strategy, follower-entity, follower-lod-manager, npc-spawner, absorb-system, crowd-collision-resolution, chest-system, relic-system, hud, player-nameplate, vfx-manager)
**ADRs Reviewed**: 5 (0001 Crowd Replication, 0002 TickOrchestrator, 0003 Performance Budget, 0004 CSM Authority, 0006 Module Placement)
**Architecture Doc**: `docs/architecture/architecture.md` v1.0

---

## Verdict: **CONCERNS**

No blocking cross-ADR conflicts. Two amendable conflicts surfaced. Coverage gaps trace cleanly to 4 already-named should-have ADRs (expected workflow artifact). All 5 ADRs in `Proposed` status — stories blocked until ≥ Accepted. tr-registry populated this pass (286 entries).

---

## 1. Traceability Summary

| Status | Count | % |
|---|---|---|
| ✅ Covered | ~95 | 33% |
| ⚠️ Partial | ~60 | 21% |
| ❌ Gap | ~131 | 46% |
| **Total TRs** | **286** | **100%** |

Per-system breakdown:

| System | TRs | Covered | Partial | Gap | Primary ADR(s) |
|---|---|---|---|---|---|
| game-concept | 12 | 7 | 1 | 4 | ADR-0001, ADR-0004 |
| systems-index | 10 | 5 | 1 | 4 | ADR-0001/0002/0006 |
| crowd-state-manager | 24 | 13 | 4 | 7 | ADR-0001, ADR-0004 |
| match-state-machine | 20 | 4 | 4 | 12 | ADR-0002 (gaps → ADR-0005) |
| round-lifecycle | 16 | 1 | 4 | 11 | gaps → ADR-0005 |
| crowd-replication-strategy | 27 | 25 | 2 | 0 | ADR-0001, ADR-0003 |
| follower-entity | 20 | 3 | 2 | 15 | ADR-0001 (gaps → ADR-0007) |
| follower-lod-manager | 13 | 4 | 2 | 7 | ADR-0001 (gaps → ADR-0007) |
| npc-spawner | 16 | 0 | 2 | 14 | gaps → ADR-0008 |
| absorb-system | 12 | 4 | 3 | 5 | ADR-0002, ADR-0004 |
| crowd-collision-resolution | 20 | 8 | 4 | 8 | ADR-0002, ADR-0003, ADR-0004 |
| chest-system | 21 | 4 | 6 | 11 | ADR-0002, ADR-0004 |
| relic-system | 21 | 7 | 2 | 12 | ADR-0001, ADR-0004 |
| hud | 20 | 3 | 2 | 15 | ADR-0001 (gaps → design-internal) |
| player-nameplate | 15 | 4 | 4 | 7 | ADR-0001, ADR-0006 |
| vfx-manager | 19 | 3 | 5 | 11 | ADR-0003 (gaps → ADR-0009) |

Full per-TR mapping in `docs/architecture/requirements-traceability.md`.

---

## 2. Coverage Gaps — Required ADRs

131 gap TRs cluster on 6 unwritten ADRs (4 should-have + 2 deferrable):

| Required ADR | Gap TRs | Priority | Notes |
|---|---|---|---|
| **ADR-0005** MSM / RoundLifecycle Split | ~35 | should-have | Covers F4 tiebreak, peakCount tracking, T9 ordering, participation snapshot, placement F3 sort, MSM 7-state contract, T6/T7 phase consumer |
| **ADR-0008** NPC Spawner Authority | ~14 | should-have | Pool=300, Uniform[5,10]s respawn, min-distance gate via CSM.getAllCrowdPositions, **NPC replication channel** (see Conflict C2), 15 Hz tick piggyback |
| **ADR-0007** Client Rendering Strategy | ~22 | deferrable | 2-Part rig spec (Body+Hat) + WeldConstraint, pool prealloc 460/100/60, max 4 spawns/frame, walk bob F8, hue-flip threshold latch, peel selection N closest, micro-sway, teleport snap, hat continuity |
| **ADR-0009** VFX Suppression Tier Assignments | ~6 | deferrable | Priority table [0,10] per effect, AbsorbSnap 6/frame cap, anchoring modes, Intermission reset |
| **ADR-0010** Server-Auth Validation Policy | ~10 | should-have | 4-check guard (identity/state/parameters/rate), reliable-vs-unreliable selection rule, payload size limits |
| **ADR-0011** Persistence Schema + Pillar 3 Exclusions | ~5 | should-have | ProfileStore key list, no-round-state lock, schema migration policy |

Remaining ~39 Gap TRs are **design-internal** formulas/contracts not requiring ADR (e.g. nameplate font-step F2, chest draft re-roll cap, HUD widget visibility table) — captured in their owning GDD.

---

## 3. Cross-ADR Conflicts

### 🔴 CONFLICT C1: Follower rig part count

- **Type**: Architecture-vs-GDD (ADR amendment needed)
- **ADR-0001 §Decision (line 57)**: "Followers use a custom 4-6-part CFrame rig (no Humanoid)."
- **Follower Entity GDD §C.1 + TR-follower-entity-002**: "2-Part rig (Body MeshPart + Hat MeshPart) with WeldConstraint."
- **Impact**: ADR text stale post-Follower-Entity GDD design lock. Stories citing ADR-0001 for rig spec would over-allocate.
- **Resolution options**:
  1. Amend ADR-0001 §Decision: "4-6-part" → "2-Part (Body + Hat MeshPart with WeldConstraint)"
  2. Defer rig spec to ADR-0007 (Client Rendering); strip from ADR-0001
- **Recommended**: Option 2 — ADR-0001 owns networking; rig is rendering domain.

### 🔴 CONFLICT C2: NPC replication channel undefined

- **Type**: Coverage gap with bandwidth-budget under-count
- **NPC Spawner GDD §C.1 + TR-npc-spawner-015/016**: "NPC replication via UnreliableRemoteEvent NpcStateBroadcast (position + transparency deltas); 300 Parts client-mirror replicated locally."
- **ADR-0001 §Key Interfaces**: only crowd state broadcasts named (CrowdStateBroadcast UnreliableRemoteEvent). No NPC remote.
- **ADR-0003 §Network bandwidth table**: 5.4 KB/s CrowdStateBroadcast + 0.5 KB/s reliable + 1.0 KB/s VFX + ... = 10.0 KB/s. **No line item for NPC traffic.**
- **Impact**: 60 visible NPCs × position update at any cadence will breach 10 KB/s budget unless properly counted.
- **Resolution options**:
  1. ADR-0008 specifies NPC channel + amends ADR-0003 §Network table to add line item
  2. NPC Spawner GDD revised — NPCs use `Part` native replication (no UnreliableRemoteEvent) — bandwidth absorbed by Roblox baseline
- **Recommended**: Option 1 — explicit lock in ADR-0008 with ADR-0003 amendment.

### ⚠️ DRIFT D1: ADR-0004 ↔ ADR-0006 reciprocal reference

- **ADR-0004 §Module Placement Firewall (line 102-115)**: "depends on ADR-0006 codification"
- **ADR-0004 ADR Dependencies table**: lists 0001/0002/0003 only — does NOT list 0006
- **ADR-0006 ADR Dependencies table**: lists 0001/0004 — formally depends on 0004
- **Impact**: Soft circular reference. Both can be Accepted together (no hard cycle since formal Depends On graph is acyclic). But documentation has drift.
- **Resolution**: Either add ADR-0006 to ADR-0004's Depends On (preferred — matches narrative) OR strip "depends on ADR-0006 codification" wording from ADR-0004 §Module Placement Firewall.

### ⚠️ DRIFT D2: HUD frame-budget peak vs steady-state mismatch

- **HUD GDD AC-22**: "<1.5ms per RenderStepped (worst case); average <0.3ms"
- **ADR-0003 §Client Per-Frame CPU Budget**: "HUD render + widget updates — Mobile budget 1.0 ms"
- **Impact**: Different framings (peak vs steady) but reconcilable. ADR-0003 0.5 ms desktop / 1.0 ms mobile is steady-state allocation; HUD GDD 1.5 ms is worst-case peak. Reserve (5.37 ms desktop / 6.5 ms mobile) absorbs peaks.
- **Resolution**: HUD GDD AC-22 should cite ADR-0003 budget + clarify peak-vs-steady framing.

### ⚠️ DRIFT D3: systems-index tier-2 cap stale

- **systems-index.md row #11 (TR-systems-index-004)**: "Follower LOD Manager render caps 80/30/15/4 per tier"
- **ADR-0001 §Decision Architecture Diagram (Batch 3 amend)**: "40-100m: max 1 billboard impostor per crowd"
- **Follower LOD Manager GDD AC-LOD-07**: "1 billboard impostor per crowd" (sole owner)
- **Impact**: systems-index has stale text; not a code-affecting drift but reads wrong for new contributors.
- **Resolution**: systems-index.md row #11 description "80/30/15/4" → "80/30/15/1 billboard" sync.

---

## 4. ADR Dependency Order (topologically sorted)

**Foundation (no dependencies):**
1. ADR-0001 Crowd Replication Strategy

**Depends on Foundation:**
2. ADR-0002 TickOrchestrator (requires ADR-0001)

**Depends on Foundation + ADR-0002:**
3. ADR-0003 Performance Budget (requires ADR-0001, ADR-0002)

**Depends on Foundation + ADR-0002 + ADR-0003:**
4. ADR-0004 CSM Authority (requires ADR-0001, ADR-0002, ADR-0003)

**Depends on Foundation + ADR-0004:**
5. ADR-0006 Module Placement Rules (requires ADR-0001, ADR-0004)

**No dependency cycles detected.** Linear ordering clean. Recommended Accept order: 0001 → 0002 → 0003 → 0004 → 0006.

---

## 5. Engine Compatibility Audit

**Engine**: Roblox (continuously-updated live service; engine-ref pinned 2026-04-20).

| ADR | Engine Compat Section | Knowledge Risk | Post-Cutoff APIs | Verification Status |
|---|---|---|---|---|
| ADR-0001 | ✅ present | MEDIUM | `UnreliableRemoteEvent` (GA post-cutoff), `buffer.*` (post-cutoff, MVP-mandatory) | Mobile + multi-client deferred to MVP integration |
| ADR-0002 | ✅ present | LOW | None | Mobile Heartbeat jitter ≤5 ms deferred to MVP integration |
| ADR-0003 | ✅ present | MEDIUM | `buffer.*` + `UnreliableRemoteEvent` (via ADR-0001) | Mobile + multi-client + 60-min soak deferred |
| ADR-0004 | ✅ present | LOW | None | Module placement audit at MVP integration |
| ADR-0006 | ✅ present | LOW | None | Static grep audit at MVP integration; Selene rules deferred |

**Findings**:
- All 5 ADRs have Engine Compatibility section ✅
- All ADRs reference `docs/engine-reference/roblox/VERSION.md` consistently ✅
- Post-cutoff APIs (`UnreliableRemoteEvent`, `buffer.*`) flow consistently via ADR-0001 chain ✅
- No ADR references any deprecated API per VERSION.md (deprecations: `v1/avatar-fetch` removed, `Player:PlayerOwnsAsset` privacy-enforcement, `BadgeService` privacy, various Async-suffix replacements) ✅
- Engine specialist consultation skipped consistently (Roblox has none in `.claude/docs/technical-preferences.md`) ✅

**Engine Specialist Findings**: skipped per project policy (no Roblox specialist).

**Engine audit verdict: CLEAN.**

---

## 6. GDD Revision Flags (Architecture → Design Feedback)

No GDD revision flags — no HIGH RISK engine findings contradict GDD assumptions. All MEDIUM/LOW risk items are validation deferrals (mobile FPS, multi-client bandwidth, BillboardGui scale) tracked under ADR-0003 Risk + ADR-0001 Risk, not contradictions of verified engine reality.

---

## 7. Architecture Document Coverage

`docs/architecture/architecture.md` v1.0:

- §2 Layer Map — all 16 MVP systems placed ✅
- §3 Module Ownership — every module has owns/exposes/consumes/engine-APIs row ✅
- §4 Data Flow — 5 scenarios + init order cover all major patterns ✅
- §5 API Boundaries — 6 Core + 1 Feature module exported types ✅
- §6 ADR Audit — 10 required ADRs enumerated, matches reality (4 done, 6 outstanding)
- §7 Required ADRs — priority + session ordering correct
- §8 Architecture Principles — 5 principles ✅
- §9 Open Questions — **DUPLICATE HEADING** (lines 939 + 956) — minor doc bug

**Recommendation**: remove duplicate `## 9. Open Questions` at line 956.

---

## 8. Status Transitions Required

All 5 ADRs currently `Proposed`. Stories cannot reference until `Accepted` (per `/story-readiness`).

| ADR | Current | Required | Blocker |
|---|---|---|---|
| ADR-0001 | Proposed | Accepted | C1 rig amendment first |
| ADR-0002 | Proposed | Accepted | None — ready |
| ADR-0003 | Proposed | Accepted | None — ready (mobile validation deferred is acceptable) |
| ADR-0004 | Proposed | Accepted | D1 narrative or Depends-On fix first |
| ADR-0006 | Proposed | Accepted | None — ready |

---

## 9. Blocking Issues (must resolve before PASS)

None. Conflicts C1+C2 are amendable; D1-D3 are documentation drift. Verdict CONCERNS reflects:
- 5 ADRs need Proposed → Accepted (workflow artifact)
- 6 ADRs missing (intentional next-phase work, named in §6.3 architecture audit)
- 2 amendable conflicts (C1 follower rig, C2 NPC bandwidth)
- 3 documentation drifts (D1 ADR-0004 reciprocal ref, D2 HUD budget framing, D3 systems-index tier 2 stale)

---

## 10. Required ADRs (priority order)

1. **ADR-0001 amendment** — fix C1 (rig spec defer to ADR-0007 OR amend in place) → then transition to Accepted.
2. **ADR-0008 NPC Spawner Authority** — locks C2 NPC replication channel + amends ADR-0003 §Network bandwidth table. Unblocks 14 Gap TRs.
3. **ADR-0005 MSM / RoundLifecycle Split** — closes ~35 Gap TRs (the largest gap cluster).
4. **ADR-0010 Server-Auth Validation Policy** — closes ~10 Gap TRs (Absorb/Chest/CCR/relic remote handlers).
5. **ADR-0011 Persistence Schema + Pillar 3 Exclusions** — closes ~5 Gap TRs; locks ProfileStore key list.
6. **ADR-0007 Client Rendering Strategy** *(deferrable)* — closes ~22 Gap TRs (rig + boids + LOD detail).
7. **ADR-0009 VFX Suppression Tier Assignments** *(deferrable)* — closes ~6 Gap TRs.

---

## 11. Handoff

**Immediate actions** (top 3):
1. Amend ADR-0001 to fix rig spec (C1) — small surgical edit + Accept
2. Author ADR-0008 NPC Spawner Authority (C2 + 14 Gap TRs + amend ADR-0003 bandwidth table)
3. Author ADR-0005 MSM/RoundLifecycle Split (largest Gap cluster — 35 TRs)

**Gate guidance**: Re-run `/architecture-review` after each new ADR. When ADR-0001 → 0006 are Accepted AND ADR-0005/0008/0010/0011 are Proposed, run `/gate-check pre-production` to advance from technical-setup to pre-production-complete.

**Followup skills**:
- `/architecture-decision crowd-replication-strategy-amend` — for C1 fix
- `/architecture-decision npc-spawner-authority` — for C2 + ADR-0008
- `/architecture-decision msm-roundlifecycle-split` — for ADR-0005
- `/create-control-manifest` — only after all must-have ADRs Accepted
- `/gate-check pre-production` — final gate after should-have ADRs land

---

## 12. Files Written This Pass

- `docs/architecture/architecture-review-2026-04-26.md` — this report
- `docs/architecture/tr-registry.yaml` — populated with 286 entries (was empty placeholder)
- `docs/architecture/requirements-traceability.md` — full traceability index

No GDDs flagged for revision in `systems-index.md` (no Architecture-feedback HIGH-risk findings).

`docs/consistency-failures.md` does not exist — no log append performed (skill only appends if file already exists; do not create).
