## QA Sign-Off Report: Sprint 6
**Date**: 2026-05-09
**QA Lead sign-off**: APPROVED WITH CONDITIONS (sign-off pending condition resolution in Sprint 7)

---

### Test Coverage Summary

| Story | Title | Type | Auto Test Result | Manual QA Result | Overall |
|---|---|---|---|---|---|
| 6-1 | Client cap-grow on broadcast count delta | Integration + Visual/Feel | PASS (7 it) | FAIL — BUG-001 filed | BLOCKED |
| 6-2 | MSM Lobby → Round timer (replace dev hack) | Logic + Integration | PASS (12 it) | PASS — TC-S1-01 | PASS |
| 6-3 | NPC test infra cleanup | Logic (infra) | PASS (new specs clean; 11 carry-forward failures unchanged) | No manual required | PASS |
| 6-4 | CRB story-004 server transport phase | Integration | PASS | No manual required | PASS |
| 6-5 | CCR story-001 Phase 1 skeleton + DI | Logic | PASS (15 it) | No manual required | PASS |
| 6-6 | CCR story-002 pair iteration + overlap | Logic | PASS (18 it) | No manual required | PASS |
| 6-7 | CCR story-003 drip math | Logic | PASS (19 it) | No manual required | PASS |
| 6-8 | CCR story-004 skip conditions | Logic | PASS (16 it) | No manual required | PASS |
| 6-9 | CCR story-005 overlap-bit feed | Logic | PASS (17 it) | No manual required | PASS |
| 6-10 | CSM story-005 follow-up F2 position lag | Logic | PASS (12 it) | No manual required | PASS |
| 6-11 | NPCSpawner story-009 follow-up DI | Integration | PASS (21 it) | No manual required | PASS |
| 6-12 | Smoke check + manual playtest | Config/Data + Visual/Feel | See re-smoke below | FAIL — BUG-001, BUG-002 filed | BLOCKED |

All 10 Logic/Integration story specs exist at their declared paths. Zero gaps in automated test evidence for blocking story types. Visual/Feel stories (6-1, 6-12) require manual confirmation of end-to-end loop — that confirmation is NOT achieved this cycle.

---

### Manual QA Session Results

| TC | Title | Session | Gate | Result | Notes |
|---|---|---|---|---|---|
| TC-S1-01 | MSM Lobby → Countdown → Active fires | 1 | BLOCKING | PASS | All 3 transitions log correctly, no errors |
| TC-S1-02 | NPCSpawner spawns N NPCs at Active | 1 | BLOCKING | PASS | NPC models visible in Workspace; count matches config |
| TC-S1-03 | Player absorbs NPC — follower count +1 (CENTERPIECE) | 1 | BLOCKING | FAIL | No `[CSM] updateCount` log fires; absorbed NPC remains in place; no follower fade-in observed — BUG-001 filed |
| TC-S1-04 | Crowd radius expands with count | 1 | BLOCKING | BLOCKED + BUG-002 | Cannot run — depends on TC-S1-03. User observed followers "stuck like a ball"; boid separation not visibly working at baseline count=10 — BUG-002 filed |
| TC-S1-05 | No frame drops during 5+ absorbs | 1 | BLOCKING | BLOCKED | Cannot run — depends on TC-S1-03 |
| TC-S1-06 | Followers render with FollowerDefault skin | 1 | BLOCKING | SKIPPED | User chose to stop Session 1 after S1 failure |
| TC-S2-01 through TC-S2-04 | Session 2 (regression + CCR observation) | 2 | ADVISORY | NOT RUN | Session 1 cut short due to BUG-001 |

Session 1 terminated after TC-S1-03 failure. Only TC-S1-01 and TC-S1-02 produced confirmed PASS verdicts from live playtest.

---

### Bugs Found

| ID | Severity | Status | Story Refs | Summary |
|---|---|---|---|---|
| BUG-001 | S1 — Critical | Open | 6-1, 6-12 | Server-side `updateCount` never fires on NPC overlap in Studio Local Server playtest; visual absorb loop is broken end-to-end despite all unit/integration tests passing |
| BUG-002 | S2 — Major | Open | 6-1 (visual) | Followers clump at a single point ("stuck like a ball") regardless of player movement; boid separation forces are wired in code but produce no visible effect at runtime |

Bug files at:
- `production/qa/bugs/BUG-001-visual-absorb-loop-server-side-not-firing.md`
- `production/qa/bugs/BUG-002-followers-clumped-no-spread-despite-boid-forces-wired.md`

---

### Re-Smoke Results

**Run date**: 2026-05-09 (post 6-1/6-3/6-10/6-11 commits)

| Gate | Result |
|---|---|
| `selene src/` | PASS — 0 errors, 5 warnings (baseline), 0 parse errors |
| `bash tools/audit-asset-ids.sh` | PASS |
| `bash tools/audit-persistence.sh` | PASS |
| TestEZ headless | 891 passed, 11 failed, 0 skipped |

TestEZ failure surface: all 11 failures are carry-forward from Sprint 5 — same three follower-entity integration spec files (`crowd_manager_orchestrator.spec.luau` ×3, `wire_in_end_to_end.spec.luau` ×4, `wire_in_pool_integration.spec.luau` ×4). No new regressions introduced by Sprint 6 implementation commits. This is consistent with Sprint 5 close-out precedent (APPROVED WITH CONDITIONS, Sprint 7 tech-debt story committed).

Overall smoke verdict: **PASS WITH WARNINGS**

---

### Verdict: APPROVED WITH CONDITIONS

**Rationale**: 12/12 must-have stories are Status: Done in `production/sprint-status.yaml`. All 10 Logic/Integration stories have automated test evidence at their declared paths, and those tests pass (zero new regressions from Sprint 6 commits). The two blocking failures — BUG-001 and the BUG-002 visual observation — surface only in Studio Local Server playtest. They reveal a server-to-client end-to-end integration gap, not a defect within any individual Sprint 6 story's implementation scope. Story 6-1's client cap-grow unit tests (7 it) pass cleanly; the upstream count delta that feeds it never arrives in the live session. The S1 bug lives in the wiring between AbsorbSystem, the NPCSpawner active-pool registry, and the CSM broadcast chain — a chain that was first exercisable end-to-end only once Story 6-1 and the production MSM driver (6-2) both landed. BUG-002's boid clump is a pre-existing visual quality gap: the boid computation is wired and unit-tested (Story 4-3) but CFrame composition in the LOD render path has not been verified against boid output in-Studio. Neither bug is a regression from a previously-working state in this sprint.

This treatment is consistent with Sprint 5 precedent: APPROVED WITH CONDITIONS, not NOT APPROVED. The sprint goal ("NPC absorb visibly grows crowd") is NOT confirmed working in Studio. Sprint 7's first story must be reproducing and fixing BUG-001.

---

### Conditions (must clear before next phase gate)

1. **BUG-001 [S1 — Sprint 7 P1]**: Fix the visual absorb loop — identify and close the gap in the AbsorbSystem → NPCSpawner → CSM → broadcast → cap-grow chain. Start with the `AbsorbSystem.tick` diagnostic logging recommended in the bug file. Sprint 7 first story.
2. **BUG-002 [S2 — Sprint 7 visual triage]**: Root-cause follower clump. Verify boid `_positions[i]` is the actual source of rendered CFrame vs. `_spawnOffsets[i] + _lastCrowdCenter`. Check LOD tier forcing impostor path. Confirm scatter in `Pool.computeSpawnPositions`. If not fixable in Sprint 7 scope, add as explicit tech-debt story.
3. **Follower-entity integration failures [tech-debt story — Sprint 7]**: Create a dedicated tech-debt story to clear the 11 carry-forward `crowd_manager_orchestrator`, `wire_in_end_to_end`, and `wire_in_pool_integration` failures. Third consecutive sprint these have carried; Sprint 7 must resolve or explicitly defer with a documented ceiling.
4. **ADR-0008 amendment [Sprint 7 story]**: `start.server.luau` NPCSpawner caller drift noted in Sprint 6 scope — must be formalized as a story before the next architecture review.
5. **Smoke recipe refresh [Sprint 7 story]**: `tests/smoke/critical-paths.md` is Sprint 2-stale. Refresh to reflect Sprint 3–6 mechanics (MSM production driver, absorb chain, CCR Phase 1).
6. **End-to-end integration smoke [Sprint 7 story — prevents recurrence]**: Add an automated headless test that fires a synthetic NPC overlap event and verifies a broadcast count delta reaches the client. Every Sprint 6 component is individually unit-tested, but the full chain has no automated gate. BUG-001's class of bug — all components green, integration silent — will recur without this.

---

### Next Step

Sprint 6 is gated for advancement. Conditions 1 and 2 are open bugs; conditions 3–6 are Sprint 7 story commitments. Resolve all six before running `/gate-check`. Sprint 7's opening story is BUG-001 reproduction and fix in Studio — the visual absorb loop (Sprint 6's stated goal) remains unconfirmed working.
