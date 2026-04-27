# Gate Check: Pre-Production → Production

**Date**: 2026-04-27
**Checked by**: `/gate-check pre-production`
**Review mode**: lean (4 directors run on phase gates)
**Engine**: Roblox (Luau strict; engine-ref pinned 2026-04-20)

---

## Verdict: **FAIL**

Architecture foundation is solid (9 Accepted ADRs + control manifest + crowd-sync prototype PROCEED). Production-management pipeline + Vertical Slice + UX/accessibility specs + test scaffold all missing. Project is mid-Pre-Production, not gate-ready.

**Critical-path rule triggered**: All 4 §Vertical Slice Validation items = NO → automatic FAIL per skill.

**Director panel**: 2 NOT READY (CD + PR) + 2 CONCERNS (TD + AD) → panel-rule FAIL.

---

## Required Artifacts: 5/14 present

| Artifact | Status | Notes |
|---|---|---|
| ≥1 prototype with README in `prototypes/` | ✅ | `prototypes/crowd-sync/` (README.md + REPORT.md PROCEED verdict) |
| First sprint plan in `production/sprints/` | ❌ | Directory does not exist |
| Art bible 9 sections complete + AD-ART-BIBLE sign-off recorded | ⚠️ | 9 sections present; sign-off field reads "SKIPPED — Lean review mode" (no explicit APPROVE verdict) |
| Character visual profiles | ❌ | No `design/characters/` directory |
| All MVP-tier GDDs complete | ✅ | 16 GDDs in `design/gdd/`; cross-reviewed twice |
| `docs/architecture/architecture.md` | ✅ | v1.0; 4-layer system map + module ownership + data flow + API boundaries + ADR audit |
| ≥3 Foundation-layer ADRs | ✅ | 9 Accepted: 0001/0002/0003/0004/0005/0006/0008/0010/0011 |
| `docs/architecture/control-manifest.md` | ✅ | Manifest Version 2026-04-27 (just generated) |
| Epics in `production/epics/` (Foundation + Core) | ❌ | Directory does not exist |
| Vertical Slice build playable | ❌ | `src/` has only template code; zero Crowdsmith systems implemented |
| ≥3 Vertical Slice playtest sessions | ❌ | `production/playtests/` does not exist |
| Vertical Slice playtest report | ❌ | None |
| UX specs (main menu / HUD / pause menu) | ❌ | `design/ux/` directory does not exist |
| `design/ux/hud.md` | ❌ | None |

## Quality Checks: 5/13 passing

| Check | Status | Notes |
|---|---|---|
| Core loop fun validated | ❌ | No playtest data — Pillars 1/2/5 are felt pillars (dopamine/anxiety/comeback) — cannot validate from GDDs alone |
| UX specs cover all UI Requirements sections | ❌ | No UX specs at all |
| Interaction pattern library | ❌ | None |
| Accessibility tier addressed in key screen UX specs | ❌ | No `design/accessibility-requirements.md`; no UX specs |
| Sprint plan references real story file paths | ❌ | No sprint plan, no stories |
| Vertical Slice COMPLETE end-to-end (start→challenge→resolution) | ❌ | VS not built |
| Architecture doc no unresolved Foundation/Core open questions | ⚠️ | OQ-1 (mobile Heartbeat) + OQ-2 (multi-client bandwidth) deferred to MVP-Integration; ADR-0001 Risk 1 + ADR-0003 Risk 1 own resolution |
| All ADRs have Engine Compatibility section | ✅ | All 9 Accepted ADRs have engine compat |
| All ADRs have ADR Dependencies section | ✅ | All 9 |
| `/review-all-gdds` + `/architecture-review` recent | ✅ | Both run 2026-04-26; architecture-review verdict CONCERNS resolved by 9-ADR Accept batch |
| Core fantasy delivered (playtester-described match) | ❌ | No playtest data |
| Test framework scaffold | ❌ | No `tests/` directory; no CI workflow at `.github/workflows/tests.yml` |
| ADR circular dependency check | ✅ | DAG acyclic: 0001→0002→0003→0004→0006 chain + 0005/0008/0010/0011 leaves; no cycles (TD verified) |

## Vertical Slice Validation: 0/4 PASS — automatic FAIL trigger

| Item | Status |
|---|---|
| Human played core loop without dev guidance | ❌ NO — VS not built |
| Game communicates what to do within 2 min | ❌ NO — no build |
| No critical fun-blocker bugs in VS | ❌ NO (vacuously) — no build to test |
| Core mechanic feels good (subjective check) | ❌ NO — no build to evaluate |

> Per skill rule: any Vertical Slice Validation item FAIL = automatic FAIL regardless of other checks.

## Director Panel Assessment

### Creative Director — **NOT READY**

Vision strong; 9-ADR Accept locks Pillar 4 architecturally; visual identity coherent across art-bible + ADRs + 16 GDDs. **But Pillars 1/2/5 are felt pillars — cannot validate without VS playtest.** Missing `design/ux/hud.md`, `design/accessibility-requirements.md`, `design/characters/` directory.

### Technical Director — **CONCERNS**

Architecture sufficient. ADR DAG acyclic. Foundation→Core→Feature chain clean. Deferrable ADRs (0007/0009) acceptable to defer (TR sources from Follower Entity GDD §C.1). **Sprint 0 mitigations required**:
1. Test framework BLOCKING per `coding-standards.md` Logic-story rule — `/test-setup` before any formula/state-machine story
2. Post-cutoff API empirical validation milestone (UnreliableRemoteEvent + buffer.* mobile + multi-client) before Feature-tier work
3. D2 doc drift (HUD AC-22 1.5 ms peak vs ADR-0003 1.0 ms steady) — resolve before HUD story enters sprint

### Producer — **NOT READY**

No epics → no stories → no sprint backlog. UX specs missing. Test/CI scaffold missing. Recommended next 3 invocations:
1. `/create-epics layer: foundation` (control-manifest now ready)
2. `/ux-design draft-modal` (parallel: HUD + Result screen)
3. `/test-setup` (scaffold tests/ + CI)

VS scope (lean): 1-player solo arena + ~30 NPCs + 1 chest + 1 relic + 90s timer + Result screen.

### Art Director — **CONCERNS**

Art bible structurally complete; rig spec locked (2-Part Body+Hat WeldConstraint sole-owner FE GDD §C.1); cel-shading mechanism clarified. **Concerns**:
1. AD-ART-BIBLE sign-off field reads "SKIPPED" — no timestamped visual-decision lock; production amendments would not be detectable as drift
2. No `design/characters/` (highest-leverage gap; modelers have no unambiguous reference for proportions/parts/colors/silhouette acceptance)
3. No `design/ux/` per-screen specs
4. No `/asset-spec` outputs

Two highest-leverage next steps: record AD-ART-BIBLE APPROVE verdict; author minimal character profiles for VS priority set (follower-default + player-avatar-default + npc-neutral + chest-t1 + chest-t2).

---

## Blockers (must resolve before PASS)

### Tier 1 — Pipeline (one session each; unblocks all subsequent work)

1. **No epics** — run `/create-epics layer: foundation` then `/create-epics layer: core` (control-manifest is ready). Without epics, `/create-stories` + `/sprint-plan` cannot run.
2. **No test framework** — run `/test-setup`. BLOCKING for any Logic-story merge per `coding-standards.md`.
3. **No UX specs** — run `/ux-design hud` + `/ux-design draft-modal` + `/ux-design main-menu` + `/ux-design pause-menu`. UX-spec-less stories will block waiting on UX clarification mid-implementation.
4. **No accessibility tier committed** — author `design/accessibility-requirements.md` (skill offers `Basic` / `Standard` / `Comprehensive` / `Exemplary` tiers). Pillar 2 (Squash Anxiety) has motion-sensitivity implications at 300 followers that lock VFX implementation.
5. **No character visual profiles** — author 5 minimal one-page profiles in `design/characters/`: follower-default, player-avatar-default, npc-neutral, chest-t1, chest-t2.
6. **AD-ART-BIBLE sign-off** — record explicit APPROVE verdict in art bible (not "SKIPPED").

### Tier 2 — Build (multi-sprint)

7. **Vertical Slice not built** — implement minimal arena cycle (1-player + ~30 NPCs absorbable + 1 chest + 1 relic + 90s timer + Result). Requires Sprint 0 (pipeline) + Sprint 1 (Foundation: TickOrchestrator + CSM + RoundLifecycle + MSM) + Sprint 2 (Feature: AbsorbSystem + ChestSystem + RelicSystem) + Sprint 3 (Presentation: HUD + Nameplate + FollowerEntity client sim).
8. **Vertical Slice playtests** — ≥3 distinct sessions documented in `production/playtests/`. Pillars 1/2/5 validation depends on this.

### Tier 3 — Drift fixes (small)

9. **D2 doc drift** — HUD GDD AC-22 (1.5 ms peak) vs ADR-0003 (1.0 ms steady mobile). Either amend ADR-0003 to permit peak/steady split OR amend HUD GDD AC-22.

---

## Recommendations

**Sprint 0 (this week — pipeline + design completion)**:
- `/create-epics layer: foundation`
- `/create-epics layer: core`
- `/test-setup`
- `/ux-design hud`
- `/ux-design draft-modal`
- `/ux-design main-menu`
- `/ux-design pause-menu`
- Author `design/accessibility-requirements.md` (recommend Basic tier for MVP)
- Author 5 character profiles in `design/characters/`
- Record AD-ART-BIBLE APPROVE in art bible
- Resolve D2 drift (recommend amend HUD AC-22 to cite ADR-0003 + clarify peak vs steady)

**Sprint 1+** (Vertical Slice build per Producer's scope):
- Foundation modules (TickOrchestrator + CSM + RoundLifecycle + MSM)
- Feature modules (AbsorbSystem + ChestSystem + RelicSystem)
- Presentation (HUD + Nameplate + FollowerEntity client sim)
- 3 playtest sessions documented

**Re-run** `/gate-check pre-production` after Sprint 0 completes.

---

## Stage Update

**`production/stage.txt` NOT updated.** Stage remains Pre-Production.

---

Chain-of-Verification: 5 questions checked — verdict unchanged (FAIL confirmed).
