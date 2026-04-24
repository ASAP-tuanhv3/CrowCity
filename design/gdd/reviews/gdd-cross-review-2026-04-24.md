# Cross-GDD Review Report

**Date:** 2026-04-24
**GDDs Reviewed:** 14 MVP
**Systems Covered:** absorb-system, chest-system, crowd-collision-resolution, crowd-replication-strategy, crowd-state-manager, follower-entity, follower-lod-manager, hud, match-state-machine, npc-spawner, player-nameplate, relic-system, round-lifecycle, vfx-manager
**Baseline:** game-concept.md, systems-index.md, entities.yaml registry, ADR-0001 (amended 2026-04-24)
**Reviewer:** /review-all-gdds skill (Phase 2 consistency + Phase 3 holism + Phase 4 scenario walkthrough, parallel)

---

## Verdict: **FAIL**

11 new blocking issues (7 consistency + 3 design theory + 1 math) + 11 pre-existing consistency items tracked. Must resolve before `/create-architecture`.

---

## 1. Consistency Issues

### 1.1 Blocking 🔴 (new — must fix)

#### RC-B-NEW-1 — Chest guard vs CSM state table mismatch
- chest-system.md §AC-4 does not reject `crowdState == GraceWindow` — only `Eliminated`.
- crowd-state-manager.md §states table L66 says `chest: no` for GraceWindow.
- **Resolution:** Chest System add `crowdState == Active` guard (not just `!= Eliminated`), OR update CSM states table.

#### RC-B-NEW-2 — LOD tier 2 cap 3-way mismatch
- follower-entity.md L247–249: tier 2 cap = **4 Parts**.
- follower-lod-manager.md L213, 233, 357: tier 2 cap = **1 billboard impostor** ("ADR-0001 discrepancy — this GDD previously listed 4 real follower rigs which was incorrect").
- crowd-replication-strategy.md L200, 314: `FAR_RANGE_MAX = 4`.
- **Resolution:** Reconcile. Follower LOD Manager's 1-billboard correction should propagate; Follower Entity LOD table + CRS render cap name must align.

#### RC-B-NEW-3 — Render-cap / LOD-distance tuning ownership
- crowd-replication-strategy.md L311–317 lists `OWN_CLOSE_MAX`, `RIVAL_CLOSE_MAX`, `MID_RANGE_MAX`, `FAR_RANGE_MAX`, `LOD_TIER_NEAR/MID/FAR` as tunable.
- follower-lod-manager.md L350–357 lists same values as "ADR-0001 locked."
- **Resolution:** Declare single owner. Recommend Follower LOD Manager owns distances; CRS owns broadcast contract only.

#### RC-B-NEW-4 — MSM timer-expiry vs CSM elimination same-tick order
- match-state-machine.md §Edge "timer-expiry evaluates FIRST" at conceptual level.
- No GDD specifies whether MSM's timer handler or CCR's `CrowdEliminated` fires first inside one Heartbeat callback.
- **Resolution:** TickOrchestrator or MSM GDD must lock explicit order: CCR drains → CSM elimination check → MSM timer check → T7 winner broadcast.

#### RC-B-NEW-5 — `CrowdDestroyed` signal undefined
- chest-system.md L158 + relic-system.md L355, L587 subscribe to `CrowdDestroyed`.
- CSM does not define this signal. Only `CrowdEliminated` exists.
- **Resolution:** CSM define `CrowdDestroyed` as fire-on-record-destroy (at `destroy()` T9 OR PlayerRemoving), OR rename references to `CrowdEliminated`.

#### RC-B-NEW-6 — VFX AbsorbSnap per-tick particle cap arithmetic wrong
- vfx-manager.md §V/A F1: "10 particles per AbsorbSnap × 4 absorb events same tick still within 40-cap (10 per event × 4/frame throttle = 40)."
- 4/frame throttle is on Follower Entity spawn, not AbsorbSnap VFX.
- Absorb F3 `N_max` at count=100 ≈ 15; at count=300 ≈ 22. 22 × 10 = 220 particles per tick.
- **Resolution:** VFX Manager add AbsorbSnap-specific per-tick batching OR reduce per-event particles OR throttle AbsorbSnap dispatch.

#### RC-B-NEW-7 — HUD CrowdCountClamped flash has no debounce
- hud.md §Core Rule 5 fires MAX CROWD flash on `CrowdCountClamped` signal.
- At count=300 with ongoing overlap, CSM fires clamp signal every tick (15 Hz). `MAX_CROWD_FLASH_DURATION = 1.0s`.
- 15 flashes queued/sec → visual thrash or solid white label.
- **Resolution:** HUD add cooldown gate (fire once per cap-entry, suppress until count dropped below 300 then re-entered).

### 1.2 Blocking — Pre-existing (tracked from /consistency-check 2026-04-24)

- CROWD_START_COUNT 10 (CSM) vs 20 (NPC Spawner F2)
- radius_from_count range [3.05, 12.03] stale in absorb §F1-F4 + CCR §F1 var tables; composed range [1.53, 18.04]
- CSM missing signals/fields/APIs: `radiusMultiplier`, `recomputeRadius()`, `CrowdCountClamped`, `CrowdCreated`, `CountChanged`, `CrowdDestroyed`, `getAllActive()`, `setStillOverlapping()`, `getAllCrowdPositions()`
- Follower Entity HueShift Rule 14 amendment (VFX owns no visual for HueShift; Follower Entity still states "VFX Manager MAY add pulse ring")
- Chest §G minimap subscription vs HUD §C (no minimap MVP)
- ρ_neutral (Absorb) vs ρ_design (NPC Spawner) rename not propagated
- NPC Spawner L52 "All 200 NPCs managed" stale (pool = 300)
- Follower Entity L492 `collision_transfer_per_tick = 2` stale (formula range [1,4])
- Absorb F4 Pillar 5 table stale (calibrated at ρ=0.05 vs current 0.075)
- CCR AC-17 perf budget 1200 tests stale (NPC Spawner recalibration → 3600)

### 1.3 Warnings ⚠️

- Absorb `ρ_neutral` name vs NPC Spawner `ρ_design` (same value, different name)
- Chest GraceWindow guard semantic mismatch (see Blocking 1)
- NPC pool text "200" vs actual 300 (stale)
- Round Lifecycle duplicates CROWD_START_COUNT reference
- Absorb §F tables document BASE radius but post-composition reaches 16.24+
- Follower MAX_SPEED = NPC_WALK_SPEED = 16 — boids overhead means followers can't keep up; playtest flag
- Chest CHEST_PROMPT_DISTANCE = 20 has ~1.96 stud margin at μ=1.5 (registry floor tolerance)

### 1.4 Dependency Asymmetries (12 total)

- DA-1 Absorb → VFX: `VFXEffect.AbsorbSnap` vs `AbsorbSnap` enum path
- DA-2 Follower Entity → VFX: HueShift pulse ring claim superseded
- DA-3 NPC Spawner → CSM: `getAllCrowdPositions()` method missing
- DA-4 CCR → CSM: `getAllActive()`, `setStillOverlapping()` missing
- DA-5 HUD → CSM: `CrowdCountClamped` signal missing
- DA-6 Nameplate → CSM: `CrowdCreated` signal missing
- DA-7 Round Lifecycle → CSM: `CountChanged` signal not declared
- DA-8 Relic → CSM: `CrowdDestroyed` signal missing
- DA-9 CCR → Follower Entity: Follower Entity AC-22 covers; CCR flag stale
- DA-10 CCR → Round Lifecycle: 8.48-stud spawn separation unenforced
- DA-11 Relic → CSM: `radiusMultiplier` field + `recomputeRadius()` missing
- DA-12 CRS ↔ CSM: hue broadcast — resolved 2026-04-24

### 1.5 Stale References (13)

(See section 4 of this report; consolidated with pre-existing.)

### 1.6 Tuning Knob Ownership Conflicts

- TK-6 Render caps: CRS vs Follower LOD Manager (see RC-B-NEW-3)
- TK-7 LOD distances: CRS vs Follower LOD Manager (see RC-B-NEW-3)
- TK-1 STALE_THRESHOLD_SEC: CSM owns; CRS lists in Tuning table → annotate as consumed
- TK-2 CROWD_POS_LAG: correctly annotated as "owned by CSM, referenced here"

### 1.7 Formula Compatibility Issues

- FC-1 radius_from_count composed [1.53, 18.04] vs stale [3.05, 12.03] in Absorb + CCR
- FC-2 collision_transfer_per_tick [1,4] vs stale constant "= 2" in Follower Entity L492
- FC-4 NPC population equilibrium ρ=0.075 vs Absorb F4 table ρ=0.05
- FC-7 ρ_neutral vs ρ_design variable name inconsistency

### 1.8 AC Cross-Check Issues

- AC-X1 Chest AC-4 guards permit GraceWindow; CSM state table forbids
- AC-X4 HUD AC-7 MAX CROWD flash depends on missing `CrowdCountClamped` signal

---

## 2. Game Design Issues

### 2.1 Blocking 🔴

#### DSN-B-1 — Wingspan leader oppression (FLAG-1)
At count=300 + Wingspan (μ=1.35): r = 16.24 studs. Absorb rate +35% (count=100: 12.8→17.3/s). Passive chest-camping viable at T2 respawn (registry L130 Wingspan red flag). Collision drip caps at 4/tick → 3-way coordinated pin drains 300→floor in ~25s. No hard counter. Pillar 5 comeback math (Absorb F4) assumes clean absorb windows that a camping Wingspan leader denies.

**Resolution path:** relic-system.md must either cap μ below sit-still threshold, gate Wingspan to T3-only, or NPC Spawner must set `NPC_RESPAWN_MIN_CROWD_DIST > r_max × μ_max` with explicit value.

#### DSN-B-2 — T1 toll late-game trivialization (FLAG-2)
T1 = 10 is 3.33% of MAX_CROWD = 300. Flat toll vs sqrt-compressed radius. At Vertical Slice (5-8 relics), T1 spam becomes dominant strategy. chest-system.md §C rationale: "Rarity weights mechanically inert at MVP — full effect emerges at Vertical Slice pool size." Recognized but unresolved.

**Resolution path:** Toll-as-percentage-of-count for T1 OR round-time-tiered toll escalation.

#### DSN-B-3 — Turtle-beats-snowball placement rule (FLAG-3)
round-lifecycle.md §F3: "survivor at count=1 outranks eliminated at count=299." Counter-pressure cited is "lower currency earnings" — Shop deferred to Alpha; no actual counter-pressure in MVP. Directly contradicts Pillar 1 (Snowball Dopamine) + absorb Player Fantasy ("walking stampede").

**Resolution path:** Either weight placement by peakCount in Group 3 sort (already tracked), introduce passivity penalty, or rewrite placement rule.

### 2.2 Blocking — Math 🔴

#### DSN-B-MATH — Grace-window rescue fails at late-round density
Absorb F4 count=1 row = 7.3/s assumes ρ=0.075 (round-start). Late-round ρ_effective ≈ 0.011 (12 players × count=100 steady-state from NPC Spawner F2). Rescue rate: 7.3 × (0.011/0.075) = 1.07/s → 3.2 absorbs in 3s grace. GraceWindow timer expires before rescue possible. Pillar 5 floor-rescue math fails in exactly the late-round scenario it's designed for.

**Resolution path:** Scale GraceWindow timer by current ρ_effective, OR elevate NPC density floor when a crowd hits count=1, OR re-derive Pillar 5 calibration at realistic late-round density.

### 2.3 Warnings ⚠️

- FLAG-4 Low-UserId tiebreak reused in 3 systems (absorb F2 argmin, CCR Rule 5, MSM F4) — compounded unfairness for early-account players
- FLAG-5 Emergent "never engage until X count" rule pre-clash — first 2-3 min = avoidance phase
- FLAG-7 Wingspan sit-still exploit — `NPC_RESPAWN_MIN_CROWD_DIST` unspecified numerically in npc-spawner.md
- Coherence #1 — Turtle reward contradicts "walking stampede" fantasy
- Coherence #2 — hud.md "HUD never pops a modal" vs chest-system.md draft modal (8s input pause)

### 2.4 Pillar Alignment Gap

**Pillar 4 Cosmetic Expression has no PRIMARY owner in the 14-system MVP.** Referenced by 4 systems, owned by none. Skin System is VS tier. Pillar 4 lives in asset conventions (art bible §4 hue palette + follower-entity.md skin hat hook). No architectural guard for "skins must not alter stats" (anti-pay-to-win).

### 2.5 Anti-Pillar Violations: None

All 4 anti-pillars hold:
- NOT pay-to-win: no Robux-gated stats
- NOT persistent-power: relic-system.md explicitly rejects DataStore
- NOT combat: CCR is overlap-only, no damage
- NOT single-player: MIN_PLAYERS_TO_START = 2

---

## 3. Cross-System Scenario Issues

Scenarios walked: 6

1. Chest open while being rammed
2. Crowd reaches MAX_CROWD_COUNT=300 mid-absorb
3. Elimination at Active→Result transition tick
4. Chest draft open while rival drains opener to elimination
5. Mass-absorb pulse (8 NPCs respawn same tick into one radius)
6. Surge relic acquired at count=260 / 261 / 259

### 3.1 Blockers 🔴 (7)

- **S2-B1** Follower Entity mesh spawn at count-clamped crowd — no `count >= MAX_CROWD_COUNT` guard documented. Client follower mesh count can exceed authoritative 300; visual drift.
- **S2-B2** HUD `CrowdCountClamped` flash replay loop (15 Hz at 300-cap) — see RC-B-NEW-7.
- **S3-B1** MSM timer-expiry vs CSM elimination same-tick handler order undefined — see RC-B-NEW-4. Placement correctness race.
- **S4-B1** Chest draft modal does not cancel on opener `Eliminated` — UX dead-end. Relic GDD assumes close-hook Chest GDD lacks.
- **S4-B2** `CrowdDestroyed` vs `CrowdEliminated` signal ambiguity — see RC-B-NEW-5.
- **S5-B1** NPC Spawner respawn-callback vs Absorb `getAllActiveNPCs` order within one Heartbeat tick — unspecified; non-deterministic mass-absorb.
- **S5-B2** VFX AbsorbSnap particle-per-tick cap arithmetic wrong — see RC-B-NEW-6.

### 3.2 Warnings ⚠️ (9)

- S1-W1 No mid-hold feedback when count drops below effective toll during 0.8s ProximityPrompt HoldDuration
- S2-W1 Reward loss at 300-cap consumes NPCs (NPC pool drain) with zero count gain → trailing crowds starved for neutrals
- S2-W2 Absorb audio batch + streak mode additive pitch (+0.15 batch + +0.3 streak = +0.45) unspec'd interaction
- S3-W1 VFX `CrowdEliminated` ordering vs Result horn/overlay — no ordering guard
- S3-W2 Relic `onTick` hooks during Result state (10s window) — pause vs run unspec'd
- S4-W1 Toll already deducted + modal locked + grace mid-modal = no player-recoverable loss
- S5-W1 HUD count pop misses on non-decade-crossing multi-absorb (100→108 = no pop; 98→106 = one pop)
- S5-W2 Audio batch + streak compound during mass-absorb pulse
- S6-W1 Surge at count=295 clamps to +5 delta; consumed fully; no refund (intentional but player-surprise potential)

### 3.3 Info ℹ️ (7)

- S1-I1 Edge paragraph mentions "CSM Eliminated signal between guard and updateCount" — same-tick ordering prevents this; edge description misleading
- S1-I2 Grace window + T1 toll floor math consistent
- S3-I1 round-lifecycle AC-14 MSM non-nil winner contract consistent
- S4-I1 Relic §Edge assumes chest UI close via CrowdEliminated hook not documented in Chest GDD — aligns with S4-B1
- S5-I1 NPC Spawner concurrent tween budget (25) not exceeded at 8 respawns
- S6-I1 Dual-beat RelicGrantVFX + MAX CROWD flash non-conflicting (owned by different layers)
- S6-I2 count=260→300 via Surge correctly skips MAX CROWD flash (not a clamp event)

---

## 4. GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| crowd-state-manager.md | Missing 6+ signals/fields/APIs required by 7 downstream GDDs | Consistency | Blocking |
| chest-system.md | GraceWindow guard mismatch + modal close-on-elim hook + minimap ref + toll-scaling design gap | Consistency + Design | Blocking |
| relic-system.md | Wingspan oppression; sit-still exploit ceiling | Design | Blocking |
| round-lifecycle.md | Survivor-beats-eliminated placement rule violates Pillar 1 | Design | Blocking |
| absorb-system.md | F4 Pillar 5 table stale density; radius range stale; ρ name; GraceWindow rescue math | Consistency + Math | Blocking |
| crowd-collision-resolution.md | radius range stale F1; AC-17 perf budget; getAllActive API missing | Consistency | Blocking |
| follower-entity.md | LOD tier 2 cap; HueShift Rule 14; transfer_rate=2 stale | Consistency | Blocking |
| match-state-machine.md | Timer-expiry vs elimination tick ordering unspec | Consistency | Blocking |
| crowd-replication-strategy.md | Tuning knob ownership conflict w/ Follower LOD Manager | Consistency | Warning |
| hud.md | CrowdCountClamped debounce; chest minimap ref; modal philosophy vs Chest | Consistency | Warning |
| follower-lod-manager.md | Tuning ownership overlap | Consistency | Warning |
| npc-spawner.md | ρ rename; NPC_POOL text "200"; MIN_CROWD_DIST unspec | Consistency | Warning |
| vfx-manager.md | AbsorbSnap cap arithmetic + HueShift contradiction in overview | Consistency | Warning |
| player-nameplate.md | CrowdCreated signal dep missing | Consistency | Warning |

---

## 5. Required Actions Before Re-Run

### Batch 1 — CSM amendment hub (unblocks 7 GDDs)
1. Add `radiusMultiplier: f32` field to crowd record + `recomputeRadius(crowdId)` method
2. Define signals: `CrowdCountClamped`, `CrowdCreated`, `CountChanged`, `CrowdDestroyed`
3. Add APIs: `getAllActive()`, `setStillOverlapping()`, `getAllCrowdPositions()`
4. Decide CROWD_START_COUNT (10 vs 20 per NPC Spawner F2 calibration)

### Batch 2 — Propagate radius range + calibration
5. Propagate radius_from_count composed range [1.53, 18.04] to Absorb F1-F4 + CCR F1 var tables
6. Propagate ρ rename (ρ_neutral → ρ_design) to Absorb + repair F4 Pillar 5 table density ρ=0.075
7. Propagate NPC pool text 200 → 300; fix Follower Entity `collision_transfer_per_tick = 2` → [1,4]
8. Propagate CCR AC-17 perf budget 1200 → 3600

### Batch 3 — LOD tier / tuning ownership
9. Reconcile LOD tier 2 cap (1 vs 4) across Follower Entity + Follower LOD Manager + CRS
10. Declare Follower LOD Manager sole owner of render caps + LOD distances; CRS references only

### Batch 4 — Chest + Relic + MSM contracts
11. Chest add `crowdState == Active` guard (not just ≠ Eliminated)
12. Chest draft modal close-on-opener-elimination client hook
13. Chest owns `CrowdDestroyed` subscription or CSM renames to `CrowdEliminated`
14. MSM or TickOrchestrator: lock same-tick handler order (CCR → CSM elim → MSM timer → T7 winner)

### Batch 5 — Design resolutions
15. T1 toll scaling (FLAG-2): proportional-to-count or round-time tier
16. Turtle placement rule (FLAG-3): peakCount weighting in Group 3 OR passivity penalty
17. Wingspan counter (FLAG-1): μ cap vs spawn-distance gate — specify `NPC_RESPAWN_MIN_CROWD_DIST`
18. Grace-window rescue math (DSN-B-MATH): scale timer by ρ_effective OR density floor at count=1

### Batch 6 — UI + VFX polish
19. HUD CrowdCountClamped flash debounce (once per cap-entry)
20. VFX AbsorbSnap per-tick particle cap arithmetic — scale with actual N_max

### Batch 7 — Coverage gap
21. Pillar 4 Cosmetic Expression — promote Skin System to MVP OR document architectural guard against pay-to-win skins elsewhere

### Pre-existing (already tracked)
22. Remaining items from /consistency-check 2026-04-24 pre-existing list (Section 1.2)

---

## 6. Sign-off

Re-run `/review-all-gdds` after Batches 1–4 (consistency + contracts) to re-verify. Batches 5–7 (design + polish) can be deferred into Vertical Slice without blocking architecture, provided the blocking items are explicitly acknowledged by the creative-director as deferred with revisit-date.

Generated by /review-all-gdds (Opus 4.7, 3 parallel sub-agents: consistency, design-theory, scenario-walkthrough).
