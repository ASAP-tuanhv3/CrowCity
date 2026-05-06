# Gate Check: Production → Polish

**Date**: 2026-05-02
**Checked by**: gate-check skill
**Review mode**: lean (director panel skipped per user direction; verdict mathematically determined by artifact gate)
**Argument**: `/gate-check production` → user chose forward-looking interpretation (Production → Polish)
**Current stage**: Production (per `production/stage.txt`)

---

## Required Artifacts: 6/11 present

| # | Artifact | Status | Notes |
|---|---|---|---|
| 1 | `src/` has active code organized into subsystems | ✅ PASS | 12 server subsystems present (`CrowdStateServer`, `MatchStateServer`, `RoundLifecycle`, `TickOrchestrator`, `ShutdownCoordinator`, `_PhaseStubs`, `RemoteValidator`, `Analytics`, `FtueManagerServer`, `PlayerData`, etc.) |
| 2 | All core mechanics from GDD implemented | ❌ **FAIL** | 13 MVP systems targeted; 6 implemented (TickOrch + CSM + MSM + RoundLifecycle + AssetId + server-side Crowd Replication). **Missing**: NPC Spawner (#9), Follower Entity (#10), Follower LOD Manager (#11), Absorb System (#14), Crowd Collision Resolution (#15), Chest System (#16), Relic System (#17 — stub only), HUD (#20), Player Nameplate (#21), Chest Billboard (#22), VFX Manager (#23) |
| 3 | Main gameplay path playable end-to-end | ❌ **FAIL** | No NPC spawning → no absorb → no follower growth → no chest payment → no relic draw → no player-vs-player crush. Server state machine runs end-to-end; gameplay does not. |
| 4 | Test files exist in `tests/unit/` and `tests/integration/` | ✅ PASS | 39 spec files across 9 system directories |
| 5 | Logic stories from current sprint have unit tests | ✅ PASS | Sprint 3 — 10/10 must-have stories COVERED (per smoke-2026-05-02.md) |
| 6 | Smoke check PASS or PASS WITH WARNINGS | ✅ PASS | `production/qa/smoke-2026-05-02.md` PASS (278/0/0 headless, 4 audit gates green) |
| 7 | QA plan exists | ✅ PASS | `production/qa/qa-plan-sprint-3-2026-05-02.md` |
| 8 | QA sign-off APPROVED or APPROVED WITH CONDITIONS | ✅ PASS | `production/qa/qa-signoff-sprint-3-2026-05-02.md` — APPROVED WITH CONDITIONS |
| 9 | ≥3 distinct playtest sessions documented | ❌ **FAIL** | `production/playtests/` is empty (0 sessions) |
| 10 | Playtest reports cover NPE / mid-game / difficulty curve | ❌ **FAIL** | No playtest reports exist |
| 11 | Fun hypothesis from Game Concept validated or revised | ❌ **FAIL** | No playtest data; fun hypothesis (5-min crowd-vs-crowd hypercasual loop) untested |

---

## Quality Checks: 3/9 passing

| Check | Status | Notes |
|---|---|---|
| Tests passing | ✅ PASS | 278/0/0 headless; CI selene + audit blocking on PR |
| No critical/blocker bugs | ✅ PASS | 0 bugs filed in `production/qa/bugs/` (dir does not yet exist) |
| Core loop plays as designed | ❌ **FAIL** | No playable core loop exists |
| Performance within budget | ⚠ DEFERRED | Story 3-5 perf soak (AC-17 60s @ 12 crowds) deferred to MVP-Integration-1 sprint per ADR-0003 §Validation Sprint Plan |
| Playtest findings reviewed | ❌ **FAIL** | No playtest data |
| No "confusion loops" | ❓ UNKNOWN | Cannot assess without playtest data |
| Difficulty curve matches doc | ⚠ N/A | `design/difficulty-curve.md` does not exist; not required for hypercasual genre but recommended |
| Implemented screens have UX specs | ✅ PASS | `design/ux/main-menu.md`, `design/ux/hud.md`, `design/ux/pause-menu.md` exist |
| Pattern library up-to-date | ❓ UNKNOWN | `design/ux/interaction-patterns.md` not verified this run |
| Accessibility compliance verified | ⚠ PARTIAL | Tier committed (`Standard` per `design/accessibility-requirements.md`); compliance not verified against implementation |

---

## Director Panel Assessment

**Skipped** per user direction. Verdict mathematically determined by artifact gate (5 hard FAILs in required artifacts; VS not playable). Director panel would not change FAIL outcome.

---

## Blockers (must resolve before re-running gate)

1. **Feature-layer epics not created** — `production/epics/feature/` does not exist. Run `/create-epics layer: feature` then `/create-stories [epic-slug]` per epic. MVP Feature systems: NPC Spawner, Follower Entity, Follower LOD, Absorb System, Crowd Collision Resolution, Chest System, Relic System.

2. **Presentation-layer epics not created** — `production/epics/presentation/` does not exist. Run `/create-epics layer: presentation`. MVP Presentation systems: HUD, Player Nameplate, Chest Billboard, VFX Manager.

3. **Core mechanics unimplemented** — 11 of 13 MVP gameplay/UI/Presentation systems have GDDs designed but no implementation. Estimated 4-6 sprints of Production work remaining before main gameplay path is playable end-to-end.

4. **Zero playtests** — `production/playtests/` is empty. Polish gate requires ≥3 sessions covering new player experience, mid-game systems, and difficulty curve. Playtests cannot begin until main gameplay path is playable (Blocker 3).

5. **Fun hypothesis unvalidated** — `design/gdd/game-concept.md` posits a 5-min crowd-vs-crowd hypercasual loop with relic draft. Hypothesis cannot be validated until playable VS exists + playtest data is collected.

---

## Strong Recommendations (not blocking but advised)

1. **Story 3-5 deferred evidence** (3 docs targeting MVP-Integration-1 sprint per ADR-0003 §Validation): perf-soak, replication-correctness, eliminated-replication. Track via `qa-signoff-sprint-3-2026-05-02.md` Conditions §1.
2. **Sprint 3 backlog stories** (3-11 CRB mirror, 3-12 RL Eliminated subscription, 3-13 CSM F2 lag, 3-14 TickOrch instrumentation, 3-15 MSM AFKToggle 4-Check) — pull into Sprint 3 if velocity allows or roll forward to Sprint 4.
3. **Selene 2 carry-forward warnings** — MSM `init.luau` `Network` + `RemoteEventName` reserved for 3-15. Resolve when 3-15 closes.
4. **Difficulty curve doc** — consider `design/difficulty-curve.md` before Polish entry. Not required for genre but supports balance review.
5. **CI TestEZ headless** — currently warn-only on Linux (Studio unavailable). Plan macOS self-hosted runner before Polish for blocking gate.

---

## Minimal Path to PASS

To re-run this gate with PASS verdict, the following work sequence is required (rough estimate: 4-6 sprints, 8-12 weeks at solo velocity):

| Sequence | Work | Sprint Estimate |
|---|---|---|
| 1 | `/create-epics layer: feature` + stories for NPC Spawner, Absorb, Follower Entity | Sprint 4 plan |
| 2 | Implement NPC Spawner + Absorb + Follower Entity (server + client) | Sprint 4-5 |
| 3 | Implement Follower LOD Manager + Crowd Collision Resolution | Sprint 5-6 |
| 4 | `/create-epics layer: feature` + stories for Chest System + Relic System | Sprint 6 plan |
| 5 | Implement Chest System (T1/T2 tiers) + Relic System (replace stub) | Sprint 6-7 |
| 6 | `/create-epics layer: presentation` + implement HUD + Nameplate + VFX Manager | Sprint 7-8 |
| 7 | First playable end-to-end Vertical Slice build | end Sprint 8 |
| 8 | ≥3 playtest sessions (NPE / mid-game / difficulty) — `/playtest-report` | Sprint 9 |
| 9 | Fun-hypothesis validation report; address critical findings | Sprint 9-10 |
| 10 | Re-run `/gate-check production` (forward-looking Production → Polish) | end Sprint 10 |

---

## Chain-of-Verification

5 challenge questions checked:

1. **"Have I accurately separated hard blockers from strong recommendations?"** — Yes. Blockers 1-5 are required-artifact failures; recommendations are advisory carry-forwards.
2. **"Are there any PASS items I was too lenient about?"** — No. PASS items verified by file read (`smoke-2026-05-02.md`, `qa-signoff-sprint-3-2026-05-02.md`, `tests/` directory listing, `src/ServerStorage/Source/` subdirs).
3. **"Am I missing any additional blockers?"** — One added during verification: Feature + Presentation epics not even created (`production/epics/feature/` and `/presentation/` directories absent). Now blockers 1 + 2.
4. **"Can I provide a minimal path to PASS?"** — Yes. 10-step sequence in §Minimal Path to PASS estimating 4-6 sprints.
5. **"Is the fail condition resolvable?"** — Yes. Natural Production progression. NOT a deep design problem; project is accurately mid-Production with most Feature/Presentation work ahead.

**Verdict**: unchanged from initial draft (FAIL).

---

## Verdict: **FAIL**

Production → Polish advancement is **not advised**. Project is correctly mid-Production with substantial Feature + Presentation layer work remaining before Polish entry criteria can be met.

**Stage.txt**: no change. Remain `Production`.

---

## Next Step

1. `/create-epics layer: feature` — create Feature-layer epics (NPC Spawner, Follower Entity, Absorb, Crowd Collision Resolution, Chest, Relic).
2. `/sprint-plan` for Sprint 4 — sequence Feature epics by dependency order. Roll Sprint 3 backlog stories (3-11..3-15) into Sprint 4 nice-to-have if not pulled before sprint end.
3. After Feature epics begin landing: `/create-epics layer: presentation` for HUD/Nameplate/VFX.
4. Track perf evidence + selene warnings + Sprint 3 backlog as carry-forwards.

**Do not re-run this gate until**: main gameplay path is playable end-to-end AND ≥3 playtest sessions are documented in `production/playtests/`.
