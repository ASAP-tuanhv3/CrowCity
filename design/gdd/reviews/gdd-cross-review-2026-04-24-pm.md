# Cross-GDD Review Report — Post Batch 1-4

**Date:** 2026-04-24 (afternoon re-run)
**GDDs Reviewed:** 14 MVP
**Systems Covered:** absorb-system, chest-system, crowd-collision-resolution, crowd-replication-strategy, crowd-state-manager, follower-entity, follower-lod-manager, hud, match-state-machine, npc-spawner, player-nameplate, relic-system, round-lifecycle, vfx-manager
**Baseline:** prior review `design/gdd/reviews/gdd-cross-review-2026-04-24.md` (10:44, FAIL) + registry 66/66 clean + 7 change-impact docs (`docs/architecture/change-impact-2026-04-24-*.md`)
**Reviewer:** `/review-all-gdds` — 3 parallel agents (consistency / design-theory / scenario walkthrough)

---

## Verdict: **CONCERNS** (was FAIL this morning)

All blocking consistency issues + pre-existing tracked items from the 10:44 review **resolved in GDD text** by Batches 1-4 + 3 `/consistency-check` passes. No new consistency blockers introduced. 4 prior design-theory blockers remain open **by explicit deferral to Batch 5** (design decisions, not propagations). 3 minor scenario hygiene items + 2 new coherence warnings surfaced.

Safe to proceed to architecture pending creative-director sign-off on Batch 5 deferrals.

---

## 1. Consistency — **ALL RESOLVED** ✅

### 1.1 Prior Blockers (RC-B-NEW-1..7) — 7/7 Resolved

| ID | Description | Evidence |
|---|---|---|
| RC-B-NEW-1 | Chest GraceWindow guard | `chest-system.md:36` — `crowdState == "Active"` strict; AC-4 expanded to 6 reject paths |
| RC-B-NEW-2 | LOD tier 2 cap 3-way mismatch | `follower-lod-manager.md:233` + `crowd-replication-strategy.md:197-203` + `follower-entity.md:10` all aligned on 1 billboard impostor per crowd |
| RC-B-NEW-3 | Render-cap ownership | `follower-lod-manager.md:347-358` declared SOLE OWNER; CRS annotated "referenced-only" |
| RC-B-NEW-4 | MSM tick order | `match-state-machine.md:65-90` 9-phase TickOrchestrator table + new AC-21 |
| RC-B-NEW-5 | `CrowdDestroyed` signal | `crowd-state-manager.md:144` defined + split from `CrowdEliminated` semantics |
| RC-B-NEW-6 | VFX AbsorbSnap cap math | `vfx-manager.md:61,321` `ABSORB_PER_FRAME_CAP = 6` global (60 particles/frame ceiling) |
| RC-B-NEW-7 | HUD flash debounce | `hud.md:115-117` + `crowd-state-manager.md:145` — HUD-side debounce contract locked |

### 1.2 Pre-existing (Section 1.2 of prior report) — 11/11 Propagated

- ✅ `CROWD_START_COUNT = 10` locked; `npc-spawner.md` F2 recalibrated
- ✅ Radius range `[3.05, 12.03]` → composed `[1.53, 18.04]` propagated to `absorb-system.md:126`, `crowd-collision-resolution.md:163,174`
- ✅ CSM signals/fields/APIs: `radiusMultiplier`, `recomputeRadius`, `CrowdCountClamped`, `CrowdCreated`, `CountChanged`, `CrowdDestroyed`, `getAllActive`, `setStillOverlapping`, `getAllCrowdPositions`
- ✅ Follower Entity HueShift Rule 14 — `vfx-manager.md:78,297,365` + `follower-entity.md:508` aligned (Follower Entity-owned, no VFX pulse ring)
- ✅ Chest §G minimap refs (7 sites) marked DEFERRED to VS+ per HUD no-minimap-MVP
- ✅ `ρ_neutral` → `ρ_design` rename — `absorb-system.md:127,141`, `npc-spawner.md:10,37`
- ✅ NPC pool text "200" → "300" — `npc-spawner.md:10,32,68,203`
- ✅ Follower Entity L492 `collision_transfer_per_tick` static `= 2` → dynamic `∈ [1, 4]`
- ✅ Absorb F4 Pillar 5 table recalibrated at ρ=0.075
- ✅ CCR AC-17 `1200 → 3600` correction applied (mis-attributed — belonged to Absorb AC-17, fixed)

### 1.3 Dependency Asymmetries (DA-1..12) — All Cleared

### 1.4 Registry

66/66 entries consistent. No self-introduced conflicts during Batch 1-4.

---

## 2. Game Design Issues

### 2.1 Prior Blockers — 4 STILL OPEN (deferred Batch 5)

| ID | Status | Evidence |
|---|---|---|
| DSN-B-1 Wingspan oppression (FLAG-1) | STILL OPEN | `relic-system.md:213-220` sit-still flagged; `npc-spawner.md:37,274` `NPC_RESPAWN_MIN_CROWD_DIST = 30` numeric value exists but no μ-to-dist ratio rule (needs `> r_max × μ_max`) |
| DSN-B-2 T1 toll trivial (FLAG-2) | STILL OPEN | `T1_TOLL = 10` flat (3.33% of MAX_CROWD); no round-time scaling or %-of-count toll |
| DSN-B-3 Turtle-beats-snowball (FLAG-3) | STILL OPEN | `round-lifecycle.md:42-43,148` invariant locked; no peakCount weight in Group-3 sort; no passivity penalty; Shop counter-pressure deferred Alpha |
| DSN-B-MATH Grace-rescue late-round | STILL OPEN | `absorb-system.md:155-156` — explicit "DSN-B-MATH advisory ... resolution deferred Batch 5". Late-round ρ≈0.011 → 1.07/s rescue vs 3s window |

**Deferral rationale.** Prior report §5 explicitly states "Batches 5-7 (design + polish) can be deferred into Vertical Slice without blocking architecture, provided the blocking items are explicitly acknowledged by the creative-director as deferred with revisit-date." Architecture can proceed on CONCERNS once that sign-off exists.

### 2.2 NEW Design-Theory Issues from Batch 1-4

#### 🟡 DSN-NEW-1 — Modal Philosophy Conflict (Warning)

- **GDDs:** `hud.md`, `chest-system.md`
- **Evidence:** `hud.md:23` — "**The HUD never interrupts input — it never pops a modal, never pauses, never demands confirmation.**" vs `chest-system.md:11,169` — Chest broadcasts "draft to the opening client's **modal UI**" with 8s DRAFT_TIMEOUT_SEC pause.
- **Resolution path:** Per `chest-system.md:528` — reframe via `/ux-design design/ux/relic-card.md` as non-modal overlay OR amend HUD philosophy. Text-only fix, ~30 min.

#### 🟡 DSN-NEW-2 — Pillar 4 No Primary Owner + Anti-P2W Guard Missing (Warning)

- **GDDs:** all 14 MVP; Skin System deferred VS
- **Evidence:** Game Concept Pillar 4 (Cosmetic Expression) referenced by CRS, Follower Entity, Nameplate, CSM hue — **owned by none**. `game-concept.md:179` states "Purchases grant zero in-round advantage" but no MVP system enforces the contract.
- **Resolution path:** One-line contract addition to `crowd-state-manager.md` — "skin data MUST NOT mutate count/radius/state/relic fields" — OR document guard in `game-concept.md` Pillar 4.

### 2.3 Warnings (unchanged from prior)

- FLAG-4 low-UserId tiebreak reused in 3 systems (Absorb F2, CCR Rule 5, MSM F4)
- FLAG-5 emergent "never engage until X count" avoidance-phase behavior
- FLAG-7 Wingspan sit-still exploit — numeric counter unspecified
- Coherence #1 — turtle reward vs "walking stampede" fantasy (absorb-system.md Player Fantasy)

### 2.4 Anti-Pillar Violations: None

All 4 anti-pillars still hold per prior review: no pay-to-win (conditional on DSN-NEW-2 guard), no persistent power, no combat, no single-player.

---

## 3. Cross-System Scenario Issues

Scenarios re-walked: **6** (same set as morning review).

### 3.1 Resolved ✅ (5 prior blockers)

- **S1** Chest open while rammed — RC-B-NEW-1 Active-strict guard ✓
- **S2-B2** HUD CrowdCountClamped flash loop — debounce contract ✓
- **S3-B1** MSM timer vs CSM elim tick order — 9-phase table ✓
- **S4-B1** Draft modal close-on-opener-elim — `chest-system.md:158,297` AC-23 ✓
- **S4-B2** CrowdDestroyed vs CrowdEliminated semantics — CSM Batch 1 split ✓

### 3.2 Still Open (minor hygiene — info-level)

- ℹ️ **SCE-NEW-1 Relic `onTick` on Eliminated crowd (S3 follow-up).** `relic-system.md:41,149` registers `onTick` on grant; T6/T7 unregister only fires on `clearAll()` + `CrowdDestroyed`, **not `CrowdEliminated`**. `onTick` continues firing against Eliminated crowd each tick until round end; CSM F5 clamp absorbs the no-op mutations but spec doesn't explicitly document this. One-line rule addition to Relic §8 GraceWindow Interaction extending to Eliminated state.
- ℹ️ **SCE-NEW-2 Absorb §V/A stale 4/frame cite.** `absorb-system.md:277` cites Follower Entity `4/frame throttle` as VFX budget justification, but VFX Manager owns its own `ABSORB_PER_FRAME_CAP = 6` (`vfx-manager.md:61,321`) = 60 particles/frame. Rewrite absorb L277 to reference VFX's cap. Cosmetic doc fix.
- ℹ️ **SCE-NEW-3 Absorb dep-table status staleness.** `absorb-system.md:78,80,215,254` lists NPC Spawner / VFX Manager as "(undesigned)" / "Not Started"; both were authored 2026-04-22 and 2026-04-23. Status refresh only.

### 3.3 False Positive (Dismissed)

- **S2-B1 dismissed.** Scenario agent flagged "Follower Entity visual count can exceed authoritative 300 at clamp." Render cap at own-close is 80, always well below MAX_CROWD_COUNT=300. `setPoolSize(n)` is LOD-derived not count-derived — no drift possible.

### 3.4 Warnings (unchanged from prior)

- S1-W1 no mid-hold toll-affordability feedback during 0.8s hold
- S2-W1 NPC pool drain at 300-cap starves trailing crowds
- S2-W2 absorb audio batch+streak pitch additive unspec
- S3-W1 VFX `CrowdEliminated` order vs Result horn
- S3-W2 Relic `onTick` during Result state window
- S5-W1 HUD count-pop misses on non-decade multi-absorb
- S5-W2 Audio batch+streak compound during mass-absorb
- S6-W1 Surge at count=295 consumes full +40 with no refund

---

## 4. GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|---|---|---|---|
| `relic-system.md` | SCE-NEW-1: `onTick` unregister on CrowdEliminated rule absent | Scenario hygiene | Warning |
| `absorb-system.md` | SCE-NEW-2 L277 stale "4/frame"; SCE-NEW-3 dep-table status refresh L78/80/215/254 | Consistency hygiene | Warning |
| `chest-system.md` | DSN-NEW-1 Modal philosophy — reconcile via `/ux-design design/ux/relic-card.md` | Design coherence | Warning |
| `crowd-state-manager.md` *or* `game-concept.md` | DSN-NEW-2 anti-P2W skin-field guard contract | Design coverage | Warning |
| `relic-system.md` | DSN-B-1 Wingspan oppression | Design (Batch 5) | Open — deferred |
| `chest-system.md` | DSN-B-2 T1 toll late-game trivial | Design (Batch 5) | Open — deferred |
| `round-lifecycle.md` | DSN-B-3 turtle placement rule | Design (Batch 5) | Open — deferred |
| `absorb-system.md` | DSN-B-MATH grace-rescue late-round | Design (Batch 5) | Open — deferred |

Systems-index status labels unchanged per user decision — current "Consistency-sync 2026-04-24" / "Batch N Applied" labels remain accurate; none of the new items warrant a "Needs Revision" status change.

---

## 5. Required Actions Before `/create-architecture`

### 5.1 Must resolve (minor — ~30 min each)

1. Relic §8 rule addition — `onTick` behavior on Eliminated crowds (SCE-NEW-1)
2. `absorb-system.md:277` rewrite "4/frame" → reference VFX `ABSORB_PER_FRAME_CAP = 6` (SCE-NEW-2)
3. `absorb-system.md` dep-table status refresh L78/80/215/254 (SCE-NEW-3)
4. Modal-philosophy resolution — either HUD edit or `/ux-design design/ux/relic-card.md` framing (DSN-NEW-1)
5. Anti-P2W skin-field guard contract — CSM or game-concept (DSN-NEW-2)

### 5.2 Creative-director sign-off required (deferred Batch 5)

6. DSN-B-1 Wingspan oppression — specify μ-to-spawn-dist ratio OR μ cap
7. DSN-B-2 T1 toll scaling — %-of-count or round-time tier
8. DSN-B-3 turtle placement — peakCount in Group-3 OR passivity penalty
9. DSN-B-MATH grace-rescue — dynamic timer by ρ_effective, density floor at count=1, or recalibration

Architecture can proceed on CONCERNS once Batch 5 deferrals are CD-acknowledged with revisit date. Items 1-5 should land pre-architecture but do not individually block.

---

## 6. Sign-off

Next recommended run: `/gate-check pre-production` (produces go/no-go verdict with full blocker list for pre→production gate), OR direct propagation of items 1-5 above.

Generated by `/review-all-gdds` (Opus 4.7, 3 parallel Explore agents: consistency, design-theory, scenario-walkthrough).
