# Gate Check: Systems Design → Technical Setup

**Date:** 2026-04-24
**Review mode:** lean (4 PHASE-GATE directors in parallel)
**Checked by:** `/gate-check` skill

## Verdict: **CONCERNS**

All 4 directors returned CONCERNS; none NOT READY. Gate passes conditionally. Safe to begin Technical Setup provided 5 pre-architecture text fixes land (~2-3 hr) and Batch 5 design decisions commit to explicit revisit dates before final architecture lock.

Stage not advanced. `production/stage.txt` unset.

---

## Required Artifacts: 3/3

- ✅ `design/gdd/systems-index.md` — 31 systems, 14 MVP enumerated, bidirectional deps
- ✅ 14 MVP GDDs in `design/gdd/` — all 8 required sections present
- ✅ Cross-GDD review report: `design/gdd/reviews/gdd-cross-review-2026-04-24-pm.md` verdict CONCERNS

## Quality Checks: 5/7 passing, 2 partial

- ✅ Individual GDD reviews clean (no MAJOR REVISION NEEDED)
- ✅ `/review-all-gdds` verdict CONCERNS (not FAIL)
- ✅ All 7 RC-B-NEW + 11 pre-existing + 12 DA consistency issues resolved (registry 66/66 clean)
- ✅ Dependencies bidirectional
- ✅ MVP priority tier defined (14 MVP + 6 VS + 7 Alpha + 5 Full Vision)
- 🟡 Stale references — 3 hygiene items (SCE-NEW-1 Relic onTick rule, SCE-NEW-2 absorb L277 "4/frame", SCE-NEW-3 absorb dep-table status)
- 🟡 Deferred design-theory issues accepted — 4 Batch 5 items (DSN-B-1/2/3 + DSN-B-MATH); CD sign-off with revisit dates pending

---

## Director Panel Assessment

### Creative Director — CONCERNS

- **Pillar 2 (Risky Chests)** compromised by DSN-B-2 flat toll (10 = 3.3% of MAX_CROWD 300)
- **Pillar 5 (Comeback Always Possible)** most compromised — DSN-B-MATH grace-rescue fails in exact late-round scenario it's written for (1.07/s vs needed 3.2 absorbs in 3s window). Combined with DSN-B-3 turtle placement, pillar inverts: passivity rewarded over snowball recovery
- **Core verb inversion** — DSN-B-1 Wingspan μ=1.35 makes optimal play "stand still" not "walk"
- **Conditions for advancement:** land DSN-B-2 toll scaling + DSN-NEW-2 skin-field guard as text edits pre-architecture; Batch 5 commit with revisit dates before architecture locks absorb-throttle values
- Full: see Director Panel Appendix §CD

### Technical Director — CONCERNS (Technical Setup may begin)

- GDDs architecturally tractable; no spec forces engine-level rewrite
- TickOrchestrator 9-phase pipeline mergeable as single `RunService.Heartbeat` — explicit in ADR
- Performance budgets individually realistic but not aggregated — author performance-budget ADR first
- Mobile iPhone SE + 4-client LAN validation deferred from prototype; schedule as first VS milestone story
- Low-risk gaps: `PlayerOwnsAsset` (Jan 2026) + `BadgeService` (Mar 2026) privacy changes not referenced (risk register only); Luau new-type-solver stance undecided (coding-standards ADR)
- Recommended ADR sequence: TickOrchestrator → Perf Budget → Absorb spatial-hash → CCR overlap-scan → CSM authority → MSM/Round Lifecycle
- Full: see Director Panel Appendix §TD

### Producer — CONCERNS (prefers Design-Lock Sprint first)

- 14 MVP scope realistic with caveats; Crowd State Manager is single-point-of-failure
- DSN-B-3 turtle placement + DSN-B-MATH grace-rescue have medium ADR back-propagation risk — resolve before adjacent ADRs written
- DSN-B-1 Wingspan + DSN-B-2 T1 toll are balance-tier, safe to defer
- Single ADR-0001 insufficient scaffolding; draft ADR-0002 CSM Authority + ADR-0003 MSM/Round Lifecycle before Technical Setup kickoff
- 7 change-impact docs in one day = design not locked (0h stability vs 48h target)
- **Recommends 2-3 day Design-Lock Sprint** to resolve DSN-B-3/MATH/NEW-1/NEW-2 + draft ADR-0002/0003 before advance
- Full: see Director Panel Appendix §PR

### Art Director — CONCERNS (2)

- Visual identity substantively coherent; art bible §1/§4/§7/§8.3-8.7 cover all categories needed during ADR authoring
- 3-LOD tier visually coherent at all render caps (80/30/15/1 billboard)
- Pillar 4 gap is data-contract not art concern — belongs in CSM/game-concept, no art bible amendment
- **Concern 1 (blocking UI ADR):** DSN-NEW-1 modal philosophy conflict — relic card §7 spec assumes non-modal; must resolve via `/ux-design design/ux/relic-card.md` OR HUD amendment before UI ADR
- **Concern 2 (minor, ~15 min):** Art bible §1/§8.4 one-line amendment clarifying "cel-shaded = outline-Part geometry, not a shader pass" to prevent ADR misread
- Full: see Director Panel Appendix §AD

---

## Blockers — None

All items are CONCERN-level; verdict is CONCERNS not FAIL.

## Recommendations (prioritised)

### Path A — Minimal (~2-3 hr) — RECOMMENDED by user choice

1. **Pre-architecture text fixes (land all 5):**
   - `relic-system.md` §8 — onTick behavior on Eliminated crowd (SCE-NEW-1)
   - `absorb-system.md` L277 — cite VFX `ABSORB_PER_FRAME_CAP = 6` (SCE-NEW-2)
   - `absorb-system.md` L78/80/215/254 — status refresh NPC Spawner/VFX Manager (SCE-NEW-3)
   - `chest-system.md` OR `hud.md` — DSN-NEW-1 modal reconcile via `/ux-design design/ux/relic-card.md`
   - `crowd-state-manager.md` OR `game-concept.md` — DSN-NEW-2 anti-P2W skin-field guard one-liner
   - (bonus) `design/art/art-bible.md` §1/§8.4 — cel-shading mechanism one-liner (AD concern 2)

2. **Commit Batch 5 with revisit dates** (non-blocking; creative-director sign-off)

3. **Start `/create-architecture`** once items 1 land; expect first 4-5 ADRs: TickOrchestrator, Perf Budget, CSM Authority, MSM/Round Lifecycle, Absorb spatial-hash

### Path B — Producer-preferred (2-3 days)

1. Design-Lock Sprint resolving DSN-B-3 + DSN-B-MATH + DSN-NEW-1 + DSN-NEW-2 (Batch 5 partial)
2. Draft ADR-0002 TickOrchestrator + ADR-0003 CSM Authority + ADR-0004 MSM/Round Lifecycle
3. 48-hour stability window (no new change-impact docs) before Technical Setup gate
4. Re-run `/gate-check pre-production-technical-setup` for PASS verdict

---

## Chain-of-Verification

5 questions checked against CONCERNS draft — verdict unchanged.

- Q1 Elevate any CONCERN to blocker? — No; PR's "not safe" is Design-Lock recommendation, not NOT READY
- Q2 Resolvable in Technical Setup phase? — Yes, all items TSetup-scoped
- Q3 Softened FAIL into CONCERN? — No; no missing required artifacts, registry clean, no contract violations
- Q4 Unchecked artifacts? — accessibility/UX patterns/tests/CI are next-gate (Technical Setup → Pre-Production) requirements
- Q5 CONCERNS aggregate to block? — No; items split into 5 text fixes + ADR drafting (= Technical Setup) + parallel Batch 5 creative decisions

---

## Next Action

Path A selected: land 5 pre-architecture text fixes. Recommended sequence:
1. Three hygiene fixes (SCE-NEW-1/2/3) — ~30 min
2. DSN-NEW-2 skin-field guard — ~15 min
3. DSN-NEW-1 modal reconcile via `/ux-design design/ux/relic-card.md` — ~1-2 hr (UX authoring)
4. (bonus) Art bible cel-shading clarification — ~15 min

After completion, ready for `/create-architecture`.
