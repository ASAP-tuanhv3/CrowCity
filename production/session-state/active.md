# Active Session State

*Last updated: 2026-04-22*

## Current Task

Pre-production — Concept phase complete, moving into per-system GDD authoring.

## Progress

- [x] `/start` — onboarding (2026-04-20)
- [x] `/brainstorm crowd city clone` — concept locked (2026-04-20)
- [x] `/setup-engine` — Roblox config + reference docs (2026-04-20)
- [x] `/art-bible` — visual identity + 9 sections (2026-04-20)
- [x] `/map-systems` — 41 systems enumerated, prioritized, design-ordered (2026-04-20)
- [x] Prototype Crowd Replication Strategy (`/prototype crowd-sync`) — **PROCEED verdict**. 5-min desktop sustained 60 FPS @ 8 crowds × 300 followers. Memory plateau, no leak. Mobile + multi-client deferred to production.
- [x] ADR-0001 Crowd Replication Strategy — Proposed. Registry updated (6 stances). Validate via `/architecture-review` in fresh session.
- [x] AssetId Registry — skipped GDD (convention only; locked by art bible §8.9 — no mechanics to design)
- [x] Crowd State Manager GDD — Designed 2026-04-21 (8 sections, 19 ACs, registry updated w/ 4 formulas + 10 constants). Run `/design-review design/gdd/crowd-state-manager.md` in fresh session to validate.
- [x] Match State Machine GDD — Designed 2026-04-21 (8 sections, 7-state machine incl. ServerClosing, 11 transitions, 19 ACs, registry +8 constants + 3 cross-refs). Run `/design-review design/gdd/match-state-machine.md` in fresh session.
- [x] Round Lifecycle GDD — Designed 2026-04-22 (8 sections, 3 formulas, 16 ACs, registry +1 constant + 2 cross-refs). Run `/design-review design/gdd/round-lifecycle.md` in fresh session.
- [x] Follower Entity GDD — Designed 2026-04-22 (8 sections + V/A, 8 formulas, 19 tuning knobs, 20 ACs, 4-specialist synthesis). Run `/design-review design/gdd/follower-entity.md` in fresh session.
- [x] Follower LOD Manager GDD — Designed 2026-04-22 (8 sections, 4 formulas, 3 knobs, 15 ACs, closes `getPeelingCount` contract with Follower Entity). Run `/design-review` in fresh session.
- [x] Absorb System GDD — Designed 2026-04-22 (8 sections + V/A, 4 formulas, 17 ACs, 6 cross-GDD contracts flagged — NPC Spawner, VFX Manager, Audio, Relic radius). Run `/design-review` in fresh session.
- [x] NPC Spawner GDD — Designed 2026-04-22 (8 sections, 4 formulas, 11 edge cases, 9 tuning knobs, 17 ACs, 5 registry entries). Run `/design-review design/gdd/npc-spawner.md` in fresh session.
- [x] Crowd Collision Resolution GDD — Designed 2026-04-22 (10 sections incl. V/A + Open Questions, 564 lines, 4 new formulas, 16 edge cases, 21 ACs, 5 cross-GDD amendments flagged, TickOrchestrator spin-off added to systems index, 10 registry `referenced_by` updates). Run `/design-review design/gdd/crowd-collision-resolution.md` in fresh session.
- [x] Relic System GDD — Designed 2026-04-23 (scope C: framework + 3 reference relics TollBreaker/Surge/Wingspan). 10 sections, 12 Core Rules, 2 formulas, 23 ACs. Registry +10 entries (3 relic items + 7 constants + 1 formula + 5 referenced_by updates + radius_from_count notes amendment for multiplier composition). CSM GDD amendment flagged (new `radiusMultiplier` field). Run `/design-review design/gdd/relic-system.md` in fresh session.
- [x] CSM GDD Batch 1 amendment 2026-04-24 — `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (`CrowdCreated`, `CrowdDestroyed`, `CrowdCountClamped`, `CountChanged`) + 3 APIs (`getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`) + 8 new ACs (AC-21 through AC-28). ADR-0001 refreshed (5 edits: status, diagram, GameplayEvent → 5 named events, CrowdState type + API surface, GDD Requirements table). Change impact: `docs/architecture/change-impact-2026-04-24-csm-batch1.md`. Unblocks 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- [x] VFX Manager GDD — Designed 2026-04-23. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules, 4 formulas (F1 particle_count_estimator / F2 suppression_tier / F3 relic_scatter_radius / F4 peel_vanish_particles), 4-state manager + 5-state pool SM, 14 edge cases, 13 deps + 4 amendments flagged (Follower Entity §V/A, CSM §Dep, Relic §Dep scope lock, Art bible §8.4 Neon permit), 16 tuning knobs, 12-row per-beat V/A catalog, 29 ACs (28 BLOCKING + 1 ADVISORY perf), 10 Open Questions. Priority contradiction flagged by qa-lead resolved: RelicExpireVFX 5→3. Registry: 3 referenced_by appends (radius_from_count + STALE_THRESHOLD_SEC + effective_toll_chain). Systems index: row updated Designed (pending review). Run `/design-review design/gdd/vfx-manager.md` in fresh session to validate.
- [x] /consistency-check 2026-04-23 — Scanned 13 GDDs vs registry (0 entities, 3 items, 6 formulas, 52 constants). VFX Manager clean (zero new conflicts introduced). 2 pre-existing conflicts surfaced, deferred to /propagate-design-change: (1) CROWD_START_COUNT 10 vs NPC Spawner's proposed 20 patch — design decision needed (block/accept); (2) radius_from_count output range stale in CCR §F1 variable table + Absorb §D variable tables [3.05, 12.03] should be composed [1.53, 18.04] after Relic System's 2026-04-23 amendment. 49/52 constants, 3/3 items, 5/6 formulas verified consistent.
- [x] Crowd Replication Strategy GDD — Designed 2026-04-24. Final MVP GDD. 11 sections (8 required + V/A + UI + Open Questions). 15 Core Rules (design-facing contract over ADR-0001), 4 formulas (F1 bandwidth / F2 stale / F3 render-cap / F4 uint16 tick wrap), 3-phase transport machine (Dormant → Active → Closing), 20 edges, 16-row dependency map, 12 tuning knobs, 27 ACs (25 BLOCKING + 2 ADVISORY), 10 Open Questions. 3 ADR-0001 amendments flagged (payload `tick` + `state` fields, `buffer` encoding MVP mandate); 1 CSM amendment (tick write + lastReceivedTick enforcement). Registry: 5 referenced_by appends (radius_from_count + MAX_CROWD_COUNT + SERVER_TICK_HZ + MAX_PARTICIPANTS_PER_ROUND + STALE_THRESHOLD_SEC). Systems index updated: 14/16 MVP GDDs designed. Run `/design-review design/gdd/crowd-replication-strategy.md` in fresh session.
- [x] /consistency-check 2026-04-24 — Scanned 14 GDDs vs registry. 1 new internal inconsistency in Crowd Replication Strategy §A Overview (stale ~40B/~7KB figures vs Rule 9/10's ~30B/~5.4KB buffer-mandate) — FIXED this pass. 2 pre-existing conflicts unchanged (CROWD_START_COUNT patch pending; radius_from_count range stale CCR + Absorb). 14/14 GDDs checked, 65/66 registry entries verified consistent.
- [x] /propagate-design-change 2026-04-24 — Applied 8 edits across ADR-0001 + CSM GDD: (1) ADR-0001 payload spec added `tick: uint16` + `state: uint8 enum incl. Eliminated` + buffer encoding mandate; (2) ADR-0001 architecture diagram + performance figures refreshed (~40B/~7KB → ~30B/~5.4KB); (3) ADR-0001 late-join gap acknowledged in Negative consequences; (4) ADR-0001 Risk 3+4 updated; (5) ADR-0001 GDD Requirements Addressed table +4 rows; (6) ADR-0001 Status header marked amended; (7) CSM GDD §G L118 rewritten (buffer mandate, hue in broadcast, state enum extended, tick write); (8) CSM status header bumped. 2 new conflicts found during propagation (hue broadcast scope + state enum scope) — both resolved CRS-wins per user decision. Change impact doc: docs/architecture/change-impact-2026-04-24-crowd-replication.md.
- [x] Chest System GDD — Designed 2026-04-23 (MVP scope: T1 chest + T2 car; T3 deferred Alpha). 10 sections, 13 Core Rules, 7-state machine + 13 transitions, 2 formulas, 30+ edge cases, 22 ACs, 5 Open Questions. Registry +9 new constants (CHEST_RESPAWN_SEC_T1/T2/T3, CHEST_PROMPT_DISTANCE/HOLD_SEC, DRAFT_TIMEOUT_SEC, T1/T2/T3_CHEST_COUNT) + 11 referenced_by appends. Resolves Relic/CSM/MSM provisionals. Flags Level Design GDD needed for spawn-point tagging. Run `/design-review design/gdd/chest-system.md` in fresh session.
- [x] HUD GDD — Designed 2026-04-23 (MVP scope: count/timer/relic-shelf/leaderboard/3-2-1/AFK/flash/eliminated/solo-wait). No minimap MVP per art bible §7. 10 sections, 14 Core Rules, widget visibility state table (11 widgets × 7 states), 2 formulas (pop-trigger, timer-display), 22 ACs, 7 Open Questions. Registry +7 new constants (COUNT_POP_SCALE_DURATION/MAX, MAX_CROWD_FLASH_DURATION, TIMER_URGENT_THRESHOLD_SEC, LEADERBOARD_ROW_COUNT, ELIM_LINGER_SEC, HUD_FRAME_BUDGET_MS) + 9 referenced_by appends. Flags CSM amendment for CrowdCountClamped signal + Chest System amendment for minimap removal. Run `/design-review design/gdd/hud.md` in fresh session.
- [x] Player Nameplate GDD — Designed 2026-04-23 (MVP scope: diegetic BillboardGui per character, count + hue + double-outline + offset-tier). 10 sections, 15 Core Rules, 5-state machine + 7 transitions, 2 formulas (offset-tier, font-step), 25+ edge cases, 18 ACs, 6 Open Questions. Registry +5 new constants (NAMEPLATE_BASE_OFFSET_STUDS, _MAX_DISTANCE, _ELIM_FADE_SEC, _TEXT_SIZE, _TIER_HYSTERESIS) + 4 referenced_by appends (STALE_THRESHOLD, hue formula, MAX_CROWD_COUNT, HUE_PALETTE_SIZE). Flags CSM CrowdCreated signal amendment. Run `/design-review design/gdd/player-nameplate.md` in fresh session.
- [x] `/review-all-gdds` 2026-04-24 — FAIL verdict. 14 GDDs reviewed, 8 flagged Blocking + 6 Warning. Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md. Blockers: 7 consistency (CSM signal/field hub amendment, LOD tier 2 cap 3-way, tuning ownership, MSM tick order, CrowdDestroyed signal, VFX AbsorbSnap cap math, HUD flash debounce), 3 design-theory (Wingspan oppression, T1 toll late-game trivial, turtle-beats-snowball), 1 math (grace-window rescue at late-round density). 11 pre-existing items still tracked.
- [x] /consistency-check 2026-04-24 post-Batch-1 — Scanned 14 GDDs vs 66 registry entries. 2 🔴 conflicts (self-introduced): radiusMultiplier range [0.5, 2.0] → [0.5, 1.5] alignment w/ registry RADIUS_MULTIPLIER_MAX hard ceiling; composed radius range [1.53, 24.06] → [1.53, 18.04]. 2 ⚠️ stale registry entries refreshed: CROWD_START_COUNT (10→20 patch rejected; locked decision) + radius_from_count (CSM Batch 1 amendment marked complete). 1 ℹ️ info: CSM F1 section title restored to include `radius_from_count` name. All fixed. 61/66 clean.
- [x] /propagate-design-change design/gdd/relic-system.md 2026-04-24 (CSM-sync pass) — 10 edits: status header note, §Core Rules L49 radius routing (direct write → recomputeRadius API), §Core Rules L61 clearAll (direct reset → API call), §Core Rules L180 (Requires amendment → ✓ complete), Wingspan hooks L215 (two-arg recomputeRadius signature), §F2 recomputation trigger L266 (two-arg + validation), §Dependencies L355 + L372 (status "In Review" → "Batch 1 Applied"), §Provisional L376 (RESOLVED marker), §Bidirectional L387 (REQUIRES → ✓ landed). ADR-0001 impact: ✅ Still Valid (no edits). Change impact: docs/architecture/change-impact-2026-04-24-relic-csm-sync.md. Remaining Relic blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/absorb-system.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, F1 radius_sq range [9.30, 144.72] → composed [2.34, 325.44], F3 formula ρ_neutral → ρ_design, F3 radius range [3.05, 12.03] → [1.53, 18.04] composed + MVP [3.05, 16.24], F3 N_max examples recomputed at ρ_design=0.075 (count=10→~4, count=100→~15, count=300→~34), F4 formula ρ rename, F4 radius range update, F4 Pillar 5 table recalibrated at ρ=0.075 with new count=1 rescue row (7.32/s), F4 DSN-B-MATH advisory block added (late-round ρ_effective≈0.011 → 1.07/s rescue fails — deferred Batch 5), AC-17 perf 1200→3600 overlap tests + 0.5ms→1.5ms budget. 3 tuning-knob table refreshes. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-absorb-batch2.md. Remaining Absorb blocker: DSN-B-MATH surfaced but not resolved (design decision, Batch 5).
- [x] /propagate-design-change design/gdd/crowd-collision-resolution.md 2026-04-24 (Batch 2 pass) — 10 edits: status header, §System inputs L163 radius range composed, F1 var table L174 radius composed, §Core Rules L33 `getAllActive` flag cleared, §Dependencies L136+L138 status "New API — CSM amendment" → "✓ CSM Batch 1 Applied", §Design tensions L149 RESOLVED marker, §Dependencies Upstream L299 status updated, §Bidirectional L318 "amendment required" → "✓ landed 2026-04-24", §Open Questions OQ-1 L549 RESOLVED marker. Review report "CCR AC-17 1200→3600" confirmed MIS-ATTRIBUTED (belonged to Absorb AC-17). CCR AC-20 perf at 66 pairs correct as-is. ADR-0001 impact: ✅ Still Valid. Registry impact: ✅ Already aligned. Change impact: docs/architecture/change-impact-2026-04-24-ccr-batch2.md. All CCR consistency blockers resolved.
- [x] /consistency-check 2026-04-24 post-Batch-2 — 5 🔴 conflicts found + 1 ⚠️ historical. All fixed: (A) CSM L171 validation range [0.5, 2.0] → [0.5, 1.5] (Fix A follow-up miss); (B) NPC Spawner L123 radius range updated to composed [1.53, 18.04]; (C) NPC Spawner L51 "200 NPCs managed" → "300 NPCs managed"; (D) Follower Entity L492 `collision_transfer_per_tick = 2` → `∈ [1, 4]` dynamic; (E) NPC Spawner 10-site sync pass — 10→20 patch rejection reflected throughout (status header, L90, L122 + L125-138 F2 table recalibrated at CROWD_START=10, L240, L259, L394-402 patches resolved, AC-16 L353 defaults updated); (F) change-impact-2026-04-24-csm-batch1.md L27 annotated with consistency-check correction. Registry clean at 66/66. NPC Spawner status changed from "In Revision (blockers pending)" → "Consistency-sync 2026-04-24 (all cross-doc patches landed)".
- [x] /propagate-design-change design/gdd/follower-lod-manager.md 2026-04-24 (Batch 3 pass — LOD tier 2 cap 3-way reconciliation) — 9 edits across 4 docs: (A) Follower LOD Manager (anchor, 3 edits): status header, L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1 billboard", §Tuning Knobs §Locked constants block renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3)"; (B) CRS (consumer, 3 edits): status header, L197-203 F3 var table `FAR_RANGE_MAX=4` → `1 billboard/crowd` + all 7 LOD constants annotated "Owned by Follower LOD Manager", L311-317 Tuning Knobs same; (C) Follower Entity (consumer, 2 edits): status header + L10 Overview "4 on a distant one" → "single billboard impostor per crowd"; (D) ADR-0001 (architecture, 2 edits): status header + L90 diagram cap "max 4 rendered" → "max 1 billboard impostor per crowd". ADR-0001 impact: ⚠️ Needs Review → ✅ Updated in place. RC-B-NEW-2 + RC-B-NEW-3 resolved. Change impact: docs/architecture/change-impact-2026-04-24-lod-batch3.md.
- [x] /propagate-design-change design/gdd/chest-system.md 2026-04-24 (Batch 4 partial pass — chest contracts) — 16 edits: status header, L36 guard 3c `!= "Eliminated"` → `== "Active"` strict (RC-B-NEW-1), L158 CSM integration contract split CrowdDestroyed/CrowdEliminated semantics with client-side modal subscription, L166-167 + L338 + L351 + L453 + L519 + L527 + L589 — 7 minimap references marked DEFERRED to VS+ per HUD §C no-minimap-MVP decision (pre-existing blocker resolved), L288 + L297 edge cases expanded (double-protection + CrowdEliminated modal-close hook S4-B1), L537 AC-4 added GraceWindow reject path c-ii (now 6 paths), L539 AC-5 Active-strict, new AC-23 integration test for draft-modal close-on-opener-elim. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-chest-batch4.md. Remaining Chest blocker: DSN-B-2 T1 toll trivialization (design decision, Batch 5). RC-B-NEW-4 (MSM handler order) still pending — next target match-state-machine.md.
- [x] /propagate-design-change design/gdd/match-state-machine.md 2026-04-24 (Batch 4 CLOSE — RC-B-NEW-4 handler order lock) — 4 edits: status header, new §Core Rules "Same-tick handler order (TickOrchestrator phase table)" subsection with 9 phases (CCR → Relic → Absorb → Chest → CSM state eval → **MSM timer check** → **MSM elim consumer** → Broadcast → PeelDispatch) + rationale + simultaneity resolution (T6/T7, double-elim) + caller enforcement, L223 edge case updated to reference explicit Phase 6/7 order, new AC-21 integration test verifying Phase 6 fires T7 first + Phase 7 drops queued elim + single broadcast. ADR-0001 impact: ✅ Still Valid. Change impact: docs/architecture/change-impact-2026-04-24-msm-batch4-close.md. **Batch 4 COMPLETE** — all consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
- [x] /consistency-check 2026-04-24 post-Batch-4 — 3 🔴 GDD-wide sync-back issues + 1 ⚠️ soft flag. All fixed: (H) HUD 7-site sync (status, L250 Dependencies row, L272 Chest row, L276 OQ #1, L277 OQ #2, L288-289 Bidirectional, L383 Event table) — CrowdCountClamped LANDED CSM Batch 1, Chest minimap LANDED Chest Batch 4; (N) Player Nameplate 3-site sync (status, L274 Provisional, L280 Bidirectional, L454 OQ #1) — CrowdCreated LANDED CSM Batch 1; (R) Round Lifecycle 4-site sync (status, L85 Interactions row, L94 bidirectional, L100 OQ, L251/L257 patches, L234 Dependencies table) — CountChanged LANDED CSM Batch 1 as server-side BindableEvent `(crowdId, oldCount, newCount, deltaSource)`; (V) VFX Manager L282 soft flag annotated "informational, no contract action needed". Registry still clean 66/66. systems-index updated: HUD, Player Nameplate, Round Lifecycle, VFX Manager all marked "Consistency-sync 2026-04-24".
- [x] `/gate-check systems-design-to-technical-setup` 2026-04-24 — Verdict CONCERNS. All 4 PHASE-GATE directors CONCERNS (CD Pillar 2+5 compromise / TD aggregate-budget ADR needed / PR Design-Lock Sprint recommendation / AD modal philosophy + cel-shading amendment). Report: production/gate-checks/2026-04-24-systems-design-to-technical-setup.md. Stage not advanced. Path A selected: land 5 pre-architecture text fixes before /create-architecture.
- [x] Pre-architecture text fixes (Path A) landed 2026-04-24:
  - SCE-NEW-1: `relic-system.md` §8 renamed "GraceWindow + Eliminated Interaction" — onTick on Eliminated tolerates no-op via CSM F5 clamp; no early-unregister for MVP
  - SCE-NEW-2: `absorb-system.md` L277 rewritten to cite VFX `ABSORB_PER_FRAME_CAP = 6` (60 particles/frame)
  - SCE-NEW-3: `absorb-system.md` L78/80/207/214/215/254 status refreshed — NPC Spawner Designed, VFX Manager Designed; Audio (undesigned) correct
  - DSN-NEW-1: `hud.md` L25 scope clarification — "HUD never modal" applies to HUD layer; Chest draft is Chest-owned `RelicDraft` Menu-type layer (intentional pause). Full UX spec deferred to `/ux-design design/ux/relic-card.md`
  - DSN-NEW-2: `crowd-state-manager.md` L195 anti-P2W contract — cosmetic systems MUST NOT mutate crowd record fields; presentation-only flow via CrowdStateClient read-side
  - (bonus) AD concern 2: `design/art/art-bible.md` L12 cel-shading mechanism clarified — outline Part geometry + flat BrickColor, NOT a shader pass
- [x] Batch 5 partial landed 2026-04-24:
  - DSN-B-2 T1 toll scaling — `chest-system.md` F1 new `base_toll_scaled(tier, count) = max(T_FLAT, ceil(count × T_PCT))`. Registry: T1/T2/T3_TOLL repurposed as FLOORS; +3 constants T1_TOLL_PCT=0.08, T2_TOLL_PCT=0.20, T3_TOLL_PCT=0. At count=300: T1=24, T2=60, T3=120 (flat). Pre-relic pipeline step e1/e2 updated; F2 renumbered. T3 flat (already 40% of MAX). Guard 3f unchanged.
  - DSN-B-3 turtle placement — `round-lifecycle.md` §F3 rewritten. Old "survivor-always-beats-eliminated" invariant removed; Rank 2..N single unified sort by composite key (peakCount desc, survived desc, finalCount desc, eliminationTime desc, UserId asc). Turtler@peak=10 now ranks below aggressive-eliminated@peak=299. Downstream refs updated (L34/35/209/224/275/339). Broadcast schema unchanged — clients derive survived from `eliminationTime == nil`.
- [ ] Batch 5 deferred (need playtest data — revisit post-VS):
  - DSN-B-1 Wingspan μ-cap vs `NPC_RESPAWN_MIN_CROWD_DIST > r_max × μ_max` gate — μ=1.35 sit-still feel needs hands; revisit at VS playtest
  - DSN-B-MATH grace-rescue math (late-round ρ≈0.011 collapse) — dynamic timer by ρ_effective vs density floor at count=1; needs late-round density telemetry from VS
- [x] /consistency-check post-Batch-5 2026-04-24 — 9 🔴 conflicts fixed across CSM L70/Tuning, chest-system ChestSpec/§Tuning/§UI/AC-7-8, relic-system L181/L196/L235. Registry 66→69 (T_TOLL_PCT constants added; T_TOLL notes refreshed as FLOORs). All DSN-B-2 stale flat-toll refs propagated. All DSN-B-3 Group 2/3 → Rank 2..N refs updated. Verdict PASS.
- [x] `/create-architecture` 2026-04-24 — 9 sections authored (Engine Knowledge Gap, 4-layer System Map, Module Ownership, Data Flow 5 scenarios + init order, API Boundaries for 6 Core/Feature modules, ADR Audit, Required ADR list, Architecture Principles, Open Questions). TD-ARCHITECTURE self-review: APPROVED WITH CONCERNS (4 concerns, non-blocking). LP-FEASIBILITY skipped (lean). Doc: `docs/architecture/architecture.md` v1.0.
- [x] ADR-0002 TickOrchestrator — Proposed 2026-04-24. 15 Hz accumulator, static 9-phase sequence, synchronous dispatch, no-yield-in-phase lock, single Heartbeat connection. 4 alternatives rejected (per-system Heartbeat, EventEmitter queue, split fast/slow rates, Stepped hook). Registry: +1 interface (tick_orchestration), +1 api_decision (server_gameplay_cadence via Heartbeat+accumulator), +3 forbidden patterns (competing_heartbeat_accumulators, yielding_inside_tick_phase, runtime_phase_registration), +3 referenced_by appends (crowd_state, crowd_state_broadcast, crowd_state_replication). TD-ADR skipped (lean). File: `docs/architecture/adr-0002-tick-orchestrator.md`.
- [x] ADR-0003 Performance Budget — Proposed 2026-04-25. Consolidates piecewise GDD AC perf into one budget: 60 FPS desktop / 45 FPS mobile (binding) / 60 FPS console; 3 ms/tick server (9-phase sub-allocations summing to 2.1 ms + 0.9 ms Reserve); per-frame client (16.67 ms desktop / 22.2 ms mobile) with 8 sub-system allocations + 5.37/6.5 ms Reserve; 10 KB/s/client network with 5.4 KB/s broadcast + 4 categories + 2.75 KB/s Reserve; 36 KB Crowdsmith server memory + 100 MB leak guard; instance caps (150 rendered Parts / 12 billboards / 2000 particles soft / 60 NPCs / 9 prompts / 21 BillboardGui). 4 validation sprints named (MVP-Integration-1/2/3 + Polish-Soak-1). Risk 1+2 from ADR-0001 owned here. Registry: populated `performance_budgets:` for first time (3 platform targets + tick + 6 client subsystem + 6 network + 1 memory + 7 instance caps = 23 entries); +4 referenced_by appends (tick_orchestration, crowd_state_broadcast, crowd_state_replication, server_gameplay_cadence). TD-ADR skipped (lean). File: `docs/architecture/adr-0003-performance-budget.md`.
- [x] ADR-0004 CSM Authority + Write-Access Contract — Proposed 2026-04-25. Locks 4-caller `updateCount` rule + per-API single-caller restrictions (create/destroy → RoundLifecycle; recomputeRadius → RelicEffectHandler; setStillOverlapping → CollisionResolver; stateEvaluate/broadcastAll → TickOrchestrator). Pillar 4 anti-P2W escalated to architectural invariant (cosmetic systems FORBIDDEN as CSM callers; cannot amend without superseding). 5-layer defense-in-depth (module placement / code review / control manifest / architecture review / story readiness). 4 alternatives rejected (convention-only, runtime traceback validation, capability tokens, per-caller submodule split). Registry: +1 interface (csm_write_api with per-method authorised_callers map), +3 forbidden patterns (cosmetic_system_writes_csm, unauthorised_csm_caller, runtime_caller_validation_via_traceback), +3 referenced_by appends (crowd_state, tick_orchestration, client_authoritative_crowd_state). TD-ADR + engine specialist skipped (lean). File: `docs/architecture/adr-0004-csm-authority.md`.
- [x] ADR-0006 Module Placement Rules + Layer Boundary Enforcement — Proposed 2026-04-26. Closes must-have ADR set (0002/0003/0004/0006 all Proposed). Locks: §Source Tree Map (9 placement classes — server-only / shared / entry-point ×2 / vendored / Wally / SharedConstants / Network / GUI prefabs); §Layer Hierarchy (Foundation → Core → Feature → Presentation, no upward imports); §Forbidden Patterns Matrix (13 rows consolidating CLAUDE.md §Forbidden Patterns + architectural justification); §Two-Entry-Point Invariant; §Vendored vs Wally Policy; §Rojo Project File Constraints; 6-layer defense-in-depth (Roblox engine / code review / Selene rules planned / control manifest / architecture review / story readiness). 4 alternatives rejected (convention-only via CLAUDE.md, per-system placement ADRs, manifest-only patterns, Selene-only). Registry: +9 forbidden patterns (client_requires_server_storage, direct_remote_event_path_access, direct_datastoreservice_call, direct_humanoid_walkspeed_write, magic_strings_cross_module, scripts_beyond_two_entry_points, wally_package_modified, nonstrict_in_project_src, upward_layer_import); +2 api_decisions (source_tree_mapping via Rojo, persistent_data_layer via ProfileStore); +2 referenced_by appends (crowd_state, client_authoritative_crowd_state). TD-ADR + engine specialist skipped (lean). File: `docs/architecture/adr-0006-module-placement-rules.md`. **Must-have ADR batch COMPLETE — `/architecture-review` in fresh session unlocked.**
- [ ] Write 4 should-have ADRs before relevant systems: ADR-0005 MSM/RoundLifecycle Split, ADR-0008 NPC Spawner Authority, ADR-0010 Server-Authoritative Validation, ADR-0011 Persistence Schema + Pillar 3 Exclusions
- [ ] `/architecture-review` — populate `tr-registry.yaml`, move ADR-0001 Proposed → Accepted, produce full traceability matrix
- [ ] `/create-control-manifest` — generate flat programmer rules sheet from Accepted ADRs + technical prefs
- [x] `/create-epics layer: foundation` 2026-04-27 — Path A scope (4 of 8 architecture rows, lean mode). Created: `asset-id-registry`, `network-layer-ext`, `player-data-schema`, `ui-handler-layer-reg`. Skipped: Currency / Zone Handler / ComponentCreator / Collision Groups (template plumbing, fold into consuming-system stories per architecture §2.1). Files: `production/epics/[slug]/EPIC.md` ×4 + `production/epics/index.md`. PR-EPIC gate skipped (lean). Each epic notes 0 TR coverage (Foundation is ADR + architecture-traced; stories cite ADRs directly).
- [x] `/create-stories asset-id-registry` 2026-04-27 — 4 stories authored (lean; QL-STORY-READY skipped). 001 skeleton+Skin (Logic), 002 Mesh inventory (Logic), 003 Particle+Sound inventory + Sounds.luau retirement (Logic), 004 grep audit gate (Config/Data). All cite ADR-0006 (Accepted). Sounds.luau template stub deletion landed in story 003 scope. Selene rule (ADR-0006 §L3) explicitly deferred to Production phase per active.md note.
- [x] `/create-stories network-layer-ext` 2026-04-27 — 5 stories authored (lean; QL-STORY-READY skipped). 001 UnreliableRemoteEvent wrapper + UREventName enum (Logic, ADR-0001 HIGH-risk post-cutoff), 002 RemoteEventName + RemoteFunctionName extensions per arch §5.7 (Logic, 22 entries + GetParticipation), 003 buffer codec for CrowdStateBroadcast 30 B/crowd (Logic, ADR-0001 buffer mandate, HIGH-risk Luau buffer API), 004 RemoteValidator 4-check guard (Logic, ADR-0010), 005 RateLimitConfig SharedConstants (Config/Data, ADR-0010). Order: 001+002 parallel; 003 after both; 004+005 paired. Multi-client bandwidth verification deferred to MVP-Integration-1 sprint per ADR-0003.
- [x] `/create-stories player-data-schema` 2026-04-27 — 3 stories authored (lean). 001 MVP 6-key schema + DefaultPlayerData lock + Pillar 3 forbidden-keys audit (Logic, ADR-0011), 002 schema migration scaffold + OnProfileVersionUpgrade wiring + Freeze.merge for v0→v1 default-fill (Logic, ADR-0011), 003 persistence audit script — DataStoreService grep + Pillar 3 forbidden-class regex (Config/Data, ADR-0011 §Verification A+B). VS+ keys (DailyQuestState/LastDailyResetTime) explicitly out-of-scope per epic; Alpha+ keys deferred. Linear order 001 → 002 → 003.
- [x] `/create-stories ui-handler-layer-reg` 2026-04-27 — 2 stories authored (lean). 001 UILayerId enum + UILayerType mapping for HUD/RelicDraft/MainMenu/PauseMenu (Logic, ADR-0006), 002 boot-time registration scaffold with no-op setup/teardown stubs in `start.server.luau` per two-entry-point invariant (Integration, ADR-0006 + ANATOMY §8). Nameplate + Chest Billboard explicitly NOT registered as UI layers (BillboardGui-attached components per arch §3.4 + ANATOMY §9). Consumer Presentation epics replace no-op stubs at their own time. Linear order 001 → 002.
- Foundation story authoring COMPLETE — 14 stories total across 4 epics (4 + 5 + 3 + 2).
- [x] `/story-readiness all` 2026-04-27 — All 14 Foundation stories READY. Estimates added to all 14 stories (post-NEEDS-WORK fix). All ADR refs Accepted (0001/0006/0011); Manifest v2026-04-27 current; ≥3 testable ACs each; Out-of-Scope + Test Evidence + Dependencies declared.
- [x] `/dev-story story-001-asset-id-skeleton` 2026-04-27 — Implemented. Files: `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` (24 L, 4 cats × Skin 5 entries) + `tests/unit/asset-id/skeleton_test.luau` (88 L, 6 test fns covering AC-1..6). Tabs indent, --!strict, AssetIdValue type exported, Skin populated `FollowerDefault/City1/City2/Neon/Event1` all `rbxassetid://0` placeholders, Mesh/Particle/Sound left `{}` per out-of-scope. Routed to gameplay-programmer (Roblox engine, no engine specialist per technical-preferences).
- [x] `/code-review` 2026-04-27 — APPROVED. lead-programmer CLEAN (style suggestion only: pairs() over generalized iter); qa-tester GAPS: 1 real fix (count assertion for "exactly 4 categories" — patched inline) + 3 compile-time/cross-context limitations annotated as ADVISORY (--!strict / cross-context require / type-export). Verdict: APPROVED.
- [x] `/story-done story-001-asset-id-skeleton` 2026-04-27 — COMPLETE WITH NOTES. 6/6 ACs passing. Test execution DEFERRED — no headless TestEZ runner configured (Production-phase task). LSP flags `describe`/`it`/`expect` as undefined globals (TestEZ runtime injection — known, not a bug). Story file Status: Complete + Completion Notes appended. Unblocks story 002 (Mesh inventory), 003 (Particle+Sound inventory).

## Session Extract — /review-all-gdds 2026-04-24
- Verdict: FAIL
- GDDs reviewed: 14
- Flagged for revision (Blocking): crowd-state-manager.md, chest-system.md, relic-system.md, round-lifecycle.md, absorb-system.md, crowd-collision-resolution.md, follower-entity.md, match-state-machine.md
- Flagged for revision (Warning, unchanged in index): crowd-replication-strategy.md, hud.md, follower-lod-manager.md, npc-spawner.md, vfx-manager.md, player-nameplate.md
- Blocking issues: 11 new (7 consistency + 3 design + 1 math) + 11 pre-existing tracked
- Recommended next: /propagate-design-change anchored on crowd-state-manager.md to land Batch 1 CSM amendment hub (radiusMultiplier, recomputeRadius, CrowdCountClamped, CrowdCreated, CountChanged, CrowdDestroyed, getAllActive, setStillOverlapping, getAllCrowdPositions) — unblocks 7 downstream GDDs
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24.md

## Session Extract — /review-all-gdds 2026-04-24 (PM re-run)
- Verdict: CONCERNS (upgraded from FAIL)
- GDDs reviewed: 14
- Prior blockers resolved: 7 RC-B-NEW + 11 pre-existing + 12 DA asymmetries — all propagated in GDD text (registry 66/66 clean)
- Flagged for revision (Warning, hygiene): relic-system.md (onTick Eliminated rule), absorb-system.md (L277 4/frame stale + dep-table status), chest-system.md (modal philosophy via /ux-design), crowd-state-manager.md OR game-concept.md (anti-P2W skin guard)
- Flagged for revision (Open — deferred Batch 5): relic-system.md (DSN-B-1 Wingspan), chest-system.md (DSN-B-2 T1 toll), round-lifecycle.md (DSN-B-3 turtle), absorb-system.md (DSN-B-MATH grace rescue)
- Blocking issues: 0 consistency + 0 scenario; 4 design-theory items deferred Batch 5 by explicit creative-director-sign-off path
- Systems-index status: unchanged (labels accurate; no Needs Revision flags added per user)
- Recommended next: /gate-check pre-production (with Batch 5 deferral acknowledgement) OR land 5 minor text fixes first (items 1-5 of report §5.1)
- Report: design/gdd/reviews/gdd-cross-review-2026-04-24-pm.md

## Key Decisions

- **Game**: Crowdsmith — Crowd City + roguelike chest/relic layer
- **Engine**: Roblox (Luau --!strict), cross-platform
- **Review mode**: lean (directors at phase gates only)
- **Visual anchor**: Roblox Default Stylized — chunky low-poly, cel-shaded, silhouette-first, no gradients
- **Crowd signature hue system**: 12 pre-validated safe palette, each player = one hue, black 2-unit outline for colorblind shape discrimination
- **Follower rigging**: custom 4-6-part CFrame rig, NO Humanoid (performance-binding at 800+ instances)
- **Meta progression**: cosmetic-only (skins), no persistent power

## Files in Flight

- `design/gdd/game-concept.md` — Approved
- `design/art/art-bible.md` — Draft, lean sign-off skipped
- `design/gdd/systems-index.md` — Draft

## Open Questions

- Q1 (concept): Can Roblox replicate 100-300 follower entities per player smoothly at 8-12 players/server? → Resolve via `/prototype crowd-sync`
- Q2 (concept): Starting T1 chest toll value for first-raid-at-minute-1 target? → Playtest iteration after prototype
- Q3 (concept): Daily quest completion time target? → Resolve during Daily Quest System GDD

## Next Step (recommended)

1. Run the crowd-sync prototype per `prototypes/crowd-sync/README.md` — sweep test matrix in Studio + mobile emulator
2. Fill in `prototypes/crowd-sync/REPORT.md` metrics
3. If PROCEED → `/architecture-decision` to record crowd-sync ADR, then resume GDD authoring
4. If PIVOT → `/prototype` with revised architecture
5. Parallel track (low-risk while prototype runs): `/design-system AssetId Registry` — unblocks MVP Foundation

<!-- STATUS -->
Epic: Pre-production (gate FAILED — work continues)
Feature: Sprint 0 pipeline + design-completion phase
Task: **`/gate-check pre-production` 2026-04-27 verdict FAIL.** Director panel: CD NOT READY / TD CONCERNS / PR NOT READY / AD CONCERNS. Architecture is sufficient (9 ADRs Accepted; control-manifest written; ADR DAG acyclic; crowd-sync prototype PROCEED). Vertical Slice Validation 0/4 → automatic FAIL per skill. Stage remains Pre-Production. Tier-1 Sprint-0 blockers (pipeline + design completion, ~1 session): `/create-epics layer: foundation` + `/create-epics layer: core` + `/test-setup` + `/ux-design hud` + `/ux-design draft-modal` + `/ux-design main-menu` + `/ux-design pause-menu` + author `design/accessibility-requirements.md` (recommend Basic tier MVP) + author 5 character profiles in `design/characters/` (follower-default / player-avatar-default / npc-neutral / chest-t1 / chest-t2) + record AD-ART-BIBLE APPROVE verdict in art bible + resolve D2 drift (HUD AC-22 vs ADR-0003 1.0 ms steady — amend HUD GDD to cite ADR-0003 peak/steady framing). Tier-2 (multi-sprint): build Vertical Slice (1-player + ~30 NPCs + 1 chest + 1 relic + 90s timer + Result) per Sprint 1 (Foundation: TickOrchestrator + CSM + RoundLifecycle + MSM) → Sprint 2 (Feature: Absorb + Chest + Relic) → Sprint 3 (Presentation: HUD + Nameplate + FollowerEntity client sim) + ≥3 playtest sessions documented. Re-run `/gate-check pre-production` after Sprint 0 completes. Report: `production/gate-checks/2026-04-27-pre-production-to-production.md`.

## Session Extract — /create-control-manifest 2026-04-27
- Output: docs/architecture/control-manifest.md (1 file, 9-ADR rules consolidation)
- ADRs covered: 9 Accepted (0001/0002/0003/0004/0005/0006/0008/0010/0011)
- Sources: 9 ADRs + .claude/docs/technical-preferences.md + docs/engine-reference/roblox/VERSION.md
- Sections: Foundation/Core/Feature/Presentation layer rules + Global Rules + Defense-in-Depth + Source Trace
- Manifest Version: 2026-04-27 (stories embed this date for staleness detection)
- TD-MANIFEST skipped (lean mode)
- Deferrable: ADR-0007 Client Rendering + ADR-0009 VFX Suppression noted for future regen
- Verdict: COMPLETE

## Session Extract — /gate-check pre-production 2026-04-27
- Verdict: FAIL
- Director panel: CD NOT READY / TD CONCERNS / PR NOT READY / AD CONCERNS (2 NOT READY → panel-rule FAIL)
- Vertical Slice Validation: 0/4 PASS → automatic FAIL trigger per skill
- Required artifacts present: 5/14; Quality checks passing: 5/13
- ADR DAG acyclic confirmed by TD; architecture sufficient
- Tier 1 blockers (Sprint 0 pipeline): no epics, no test framework, no UX specs, no accessibility tier, no character profiles, AD-ART-BIBLE not recorded
- Tier 2 blockers (multi-sprint build): Vertical Slice not built; ≥3 playtests not run
- Tier 3 drift: D2 HUD AC-22 1.5 ms peak vs ADR-0003 1.0 ms steady — small fix
- Report: production/gate-checks/2026-04-27-pre-production-to-production.md
- production/stage.txt NOT updated (stage remains Pre-Production)
- Sprint 0 next steps named: /create-epics foundation+core / /test-setup / /ux-design × 4 screens / accessibility doc / character profiles × 5 / AD-ART-BIBLE APPROVE / D2 drift fix

## Session Extract — ADR-0010 Status Flip 2026-04-26
- Action: ADR-0010 Server-Authoritative Validation Policy `Proposed` → `Accepted`
- Surgical Status header edit + Date field bump
- No GDD amendment needed (chest 6-guard / Absorb / CCR / Relic / MSM AFKToggle GDDs already aligned with 4-check structure)
- 8 ADRs now Accepted: 0001 / 0002 / 0003 / 0004 / 0005 / 0006 / 0008 / 0010
- Verdict: COMPLETE

## Session Extract — ADR-0011 Persistence Schema 2026-04-26/27
- Status: Proposed
- File: docs/architecture/adr-0011-persistence-schema.md
- Closes ~5 gap TRs (Pillar 3 round-scope exclusions + Pillar 4 anti-P2W persistence + schema policy)
- Decisions: MVP 6-key schema locked (Coins/OwnedSkins/SelectedSkin/LifetimeAbsorbs/LifetimeWins/FtueStage + _schemaVersion meta); VS+ +2 (DailyQuestState/LastDailyResetTime); Alpha+ preliminary +2-4 (AnalyticsOptIn/AccessibilitySettings/LastShopRefreshTime); Pillar 3 Forbidden Keys explicit 10-class catalog; Pillar 4 3-category boundary (cosmetic/lifetime-stat/onboarding); ProfileStore-only rule reinforces ADR-0006; schema migration via OnProfileVersionUpgrade + handlers dir + test fixture; default template sole ownership; currency authority Coins server-only grant at Result entry; Robux via ReceiptProcessor template
- Alternatives rejected: no schema lock / centralised broker / per-key versioning / no forbidden catalog
- Registry: +1 interface (persistence_schema) + 6 new forbidden_patterns
- TD-ADR + engine specialist skipped (lean mode)
- No GDD amendment needed (game-concept Pillar 3+4 + ADR-0001/0004/0005 already aligned)
- Verdict: ready for Proposed → Accepted (no remaining dependencies)
- Must-have ADR set complete (0001-0011) when ADR-0011 flips Accepted

## Session Extract — ADR-0011 Status Flip 2026-04-27
- Action: ADR-0011 Persistence Schema `Proposed` → `Accepted`
- Surgical Status header edit + Date field bump
- No GDD amendment needed (game-concept + ADR-0001/0004/0005/0006 already aligned)
- 9 ADRs now Accepted: 0001 / 0002 / 0003 / 0004 / 0005 / 0006 / 0008 / 0010 / 0011
- **Must-have ADR set COMPLETE**
- Verdict: COMPLETE
- Stories unblocked: Currency grant + Skin (VS+) + Daily Quest (VS+) + Shop (Alpha+) all satisfy `/story-readiness` Accepted-gate for ADR-0011 references

## Session Extract — ADR-0005 Status Flip 2026-04-26
- Action: ADR-0005 MSM/RL Split `Proposed` → `Accepted`
- Surgical Status header edit + Date field bump
- No GDD amendment needed (RL+MSM GDDs already aligned)
- 7 ADRs now Accepted: 0001 / 0002 / 0003 / 0004 / 0005 / 0006 / 0008
- Verdict: COMPLETE

## Session Extract — ADR-0010 Server-Authoritative Validation Policy 2026-04-26
- Status: Proposed
- File: docs/architecture/adr-0010-server-authoritative-validation-policy.md
- Closes ~10 gap TRs (Absorb / Chest 6-guard pipeline / CCR PairEntered+peel / Relic draft-pick validation / MSM AFKToggle)
- Decisions: 4-check guard pattern (identity/state/parameters/rate); reliable-vs-unreliable selection table; payload budgets (<4 KB target, 16 KB cap); identity model (engine player only); server-time authority; per-player rate limits via RateLimitConfig; silent-rejection model; shared RemoteValidator module; PenTest playbook; T9 chain extended with resetForRound
- Alternatives rejected: per-handler ad-hoc / runtime crypto signing / wrapper auto-validate / typed RemoteEvent schema
- Registry: +1 interface (remote_validator) + 6 new forbidden_patterns
- TD-ADR + engine specialist skipped (lean mode)
- No GDD amendment needed (chest GDD 6-guard already aligned with state-rule expansion; MSM/Absorb/CCR/Relic GDD validation rules consistent with 4-check structure)
- Verdict: ready for Proposed → Accepted (no remaining dependencies)

## Session Extract — ADR-0005 MSM/RL Split 2026-04-26
- Status: Proposed
- File: docs/architecture/adr-0005-msm-roundlifecycle-split.md
- Closes ~35 gap TRs (msm: 12 + round-lifecycle: 11 + cross-system: 12)
- Decisions: module split disjoint; MSM-only-caller of RL; T9/Result ordering invariants; InternalPlacement strip; CountChanged subscriber matrix; MIN_PLAYERS_TO_START; spectator contract; BindToClose 30s no-grant
- Alternatives rejected: combine modules; RL owns Phase 6/7; per-state submodule; post-broadcast grant
- Registry: +2 interfaces + 4 new forbidden_patterns + 1 cross-ADR pattern (msm_or_rl_calls_csm_mutator extends ADR-0004)
- No GDD amendment needed (RL GDD + MSM GDD already aligned)
- TD-ADR + engine specialist skipped (lean mode)
- Verdict: ready for Proposed → Accepted (no remaining dependencies)

## Session Extract — ADR-0008 Status Flip 2026-04-26
- Action: ADR-0008 NPC Spawner Authority `Proposed` → `Accepted`
- Rationale: GDD sync via /propagate-design-change cleared the only outstanding amendment dependency (NPC Spawner GDD R5 ServerTickAccumulator stale text)
- Status header rewritten: Proposed line + GDD-sync line + final ACCEPTED line
- Date field updated: "2026-04-26 (initial Proposed + GDD sync + Accepted, all same day)"
- Cross-doc: design/gdd/npc-spawner.md L243 §Dependencies row updated "Proposed 2026-04-26" → "Accepted 2026-04-26"
- Stories unblocked: NPCSpawner + AbsorbSystem implementation now satisfies `/story-readiness` Accepted-gate for ADR-0008 references
- 6 ADRs now Accepted: 0001 / 0002 / 0003 / 0004 / 0006 / 0008
- Verdict: COMPLETE

## Session Extract — ADR-0008 NPC Spawner Authority 2026-04-26
- Status: Proposed (closes C2 from /architecture-review 2026-04-26)
- File: docs/architecture/adr-0008-npc-spawner-authority.md
- Decisions locked: pool 300 anchored Parts; NpcStateBroadcast UREvent (8 B/NPC delta @ 15 Hz, per-relevance filter); NpcPoolBootstrap reliable; own Heartbeat:Connect (non-gameplay-tick exemption); CSM read-only consumer; AbsorbSystem-only reclaim()/getAllActiveNPCs(); ARENA_WALKABLE_AREA_SQ assert at boot
- Bandwidth: 3.0 KB/s/client allocation; ADR-0003 §Network table amended (Reserve 2.75→0; Sum 10.25 KB/s nominal; absorbed by burst_allowance)
- Registry: +3 forbidden_patterns (native_part_replication_for_npcs, npc_spawner_writes_csm, npc_instance_new_mid_round) + 2 interfaces (npc_state_broadcast, npc_pool_authority) + 1 performance_budget (npc-state-broadcast 3.0 KB/s); csm_write_api referenced_by + revised
- Alternatives rejected: Phase 0 in TickOrchestrator (ADR-0002 already excluded); native Part replication (unbounded bandwidth); per-NPC RemoteEvents (overhead); CSM-embedded NPC state (Pillar 4 violation)
- C2 status: 🔴 → ✅ (resolved pending Accept)
- D-graph: 0001/0002/0003/0004/0006 → 0008 (depends on all 5 must-haves)

## Session Extract — /propagate-design-change npc-cadence 2026-04-26
- Anchor: `design/gdd/npc-spawner.md`; trigger: ADR-0008 cadence lock
- 6 GDD edits: status header + R5 + §Interactions L70 + §Dependencies L243 + AC-05 + §DI requirements (Accumulator → RunServiceShim)
- Live ServerTickAccumulator refs after pass: 0; historical context refs: 2 (preserved with "stale terminology / replaces prior" framing)
- ADRs affected: only ADR-0008 (Proposed, drove sync) — 0001/0002/0003/0004/0006 ✅ Still Valid
- Change-impact doc: docs/architecture/change-impact-2026-04-26-npc-cadence.md
- Verdict: COMPLETE
- ADR-0008 status: ready for Proposed → Accepted (no remaining amendment dependencies)

## Session Extract — /architecture-review 2026-04-26
- Verdict: CONCERNS
- Requirements: 286 total — 95 covered, 60 partial, 131 gaps
- New TR-IDs registered: 286 (full first-pass population; registry was empty placeholder)
- GDD revision flags: None
- Top ADR gaps: ADR-0005 MSM/RL Split (~35 TRs), ADR-0007 Client Rendering (~22 TRs), ADR-0008 NPC Spawner (~14 TRs + C2)
- Report: docs/architecture/architecture-review-2026-04-26.md

## Session Extract — /propagate-design-change rig-defer 2026-04-26
- Anchor: ADR-0001 amend C1 (rig spec → FE GDD §C.1)
- 7 sync edits across 4 files: systems-index.md L130 + art-bible.md L59/L148/§8.6 + architecture.md L130/L896 + registry/architecture.yaml L530
- 2 housekeeping edits in ADR-0001 (Status header + GDD Reqs row): "pending sync" → "COMPLETE 2026-04-26"
- Live "4-6-part" refs after pass: 0 (historical context refs preserved with explicit "reduced from earlier" framing)
- Change-impact doc: docs/architecture/change-impact-2026-04-26-rig-defer.md
- ADRs affected: only ADR-0001 (already amended) — 0002/0003/0004/0006 ✅ Still Valid
- Verdict: COMPLETE
- ADR-0001 status: ready for Proposed → Accepted (no remaining blockers)

## Session Extract — ADR-0001 Status Flip 2026-04-26
- Action: ADR-0001 Crowd Replication Strategy `Proposed` → `Accepted`
- Rationale: `/architecture-review` 2026-04-26 verdict CONCERNS, but ADR-0001 specifically had no blocking issues post-C1-amend + downstream sync
- Status header rewritten: status-history list (5 amendments) + final ACCEPTED line
- Date field updated: "2026-04-20 (initial), 2026-04-24 (Batch 1/3 amendments), 2026-04-26 (C1 amend + Accepted)"
- Registry: no edit (registry references ADR via path, no per-ADR status field)
- Stories: now unblocked for ADR-0001 references per `/story-readiness` Accepted-status check
- Verdict: COMPLETE

## Session Extract — Batch ADR Flip + D1 Fix 2026-04-26
- Action: ADR-0002/0003/0004/0006 batch `Proposed` → `Accepted`
- ADR-0002 TickOrchestrator: clean flip, no edits beyond Status header
- ADR-0003 Performance Budget: clean flip + status note "Pending amendment expected: NPC replication line item when ADR-0008 lands (closes C2)"
- ADR-0004 CSM Authority: D1 fix applied — L102 §Module Placement Firewall heading "(depends on ADR-0006 codification)" → "(codified by ADR-0006 §Source Tree Map)"; L115 narrative "ADR-0006 will codify the no-upward-import rule for completeness" → "ADR-0006 §Layer Hierarchy + No-Upward-Import Rule codifies this for the project at large; ADR-0004 simply applies the rule to CSM specifically"; formal Depends On table (0001/0002/0003) unchanged → no cycle
- ADR-0006 Module Placement: clean flip + status note "Selene custom rules (L3) remain deferred to Production-phase task"
- Must-have ADR set ALL Accepted: 0001/0002/0003/0004/0006
- Verdict: COMPLETE
- D-graph remains acyclic: 0001 → 0002 → 0003 → 0004 → 0006 (linear)
- C2 conflict still open (ADR-0008 NOT YET WRITTEN); D2/D3 drifts not yet addressed (defer to next session pass)
<!-- /STATUS -->

## Session Extract — /story-done 2026-04-27 (story-002)
- Verdict: COMPLETE
- Story: production/epics/asset-id-registry/story-002-mesh-inventory.md — Populate Mesh inventory (Char/Prop/Env)
- Tech debt logged: None
- Next recommended: Story 003 (Particle + Sound inventory)

## Session Extract — /story-done 2026-04-27 (story-003)
- Verdict: COMPLETE WITH NOTES (1 ADVISORY: SoundManager.luau OOS edit, user-approved Path A)
- Story: production/epics/asset-id-registry/story-003-particle-sound-inventory.md — Particle + Sound inventory + Sounds.luau retirement
- Tech debt logged: None (SoundManager OOS edit documented in completion notes; full AudioManager rewrite owned by VS+ epic)
- Files: AssetId.luau (86L final, +Particle/+Sound), SoundManager.luau (143L migrated), Sounds.luau (deleted), particle-sound-inventory_test.luau (136L/7fns)
- Next recommended: Story 004 (Static-audit grep gate) — final story in asset-id-registry epic

## Session Extract — /story-done 2026-04-27 (story-004)
- Verdict: COMPLETE WITH NOTES (1 ADVISORY: AC-2 literal-wording deviation — .luau-only + tightened regex; rationale documented)
- Story: production/epics/asset-id-registry/story-004-asset-id-audit-gate.md — Asset ID static-audit gate (grep script)
- Tech debt logged: None
- Files: tools/audit-asset-ids.sh (new, mode 755), CLAUDE.md (+1 bullet AC-6), production/qa/evidence/asset-id-audit-evidence.md (new, smoke evidence)
- Verification: AC-4 clean PASS exit 0 / AC-5 plant detected file:line exit 1 / AC-7 idempotent
- **EPIC COMPLETE**: asset-id-registry 4/4 stories done. AssetId.Skin (story 001), Mesh (story 002), Particle+Sound + Sounds.luau retirement (story 003), audit gate (story 004).
- Next recommended: Foundation epics — network-layer-ext (5 stories), player-data-schema (3 stories), ui-handler-layer-reg (2 stories)
