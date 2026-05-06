# Gate Check Report — Production → Polish

**Date**: 2026-05-06
**Checked by**: gate-check skill
**Stage Before**: Production
**Verdict**: **FAIL**

Sprint 4 successfully closed (12/12 must-have stories COMPLETE, 600/600 tests
passing, qa-signoff APPROVED). However, Production → Polish phase advancement
requires the project as a whole to have a playable Vertical Slice with
playtest validation — Sprint 4 only completed one sub-system epic of many.

---

## Required Artifacts: 5/12 present

| # | Artifact | Status |
|---|----------|--------|
| 1 | `src/` organized into subsystems | ✓ |
| 2 | All core mechanics from GDD implemented | ✗ — only FollowerEntity client sim; absorb/chest/npc-spawner/crowd-collision-resolution/relic-system have no stories yet |
| 3 | Main gameplay path playable end-to-end | ✗ — perf-fixture only; no chest raid, no NPC, no win condition |
| 4 | Tests in `tests/unit/` + `tests/integration/` covering Logic + Integration | ✓ |
| 5 | All Logic stories this sprint have unit tests | ✓ |
| 6 | Smoke check PASS or PASS WITH WARNINGS | ✓ `production/qa/smoke-2026-05-06.md` PASS |
| 7 | QA plan exists | ✓ `production/qa/qa-plan-sprint-4-2026-05-04.md` |
| 8 | QA sign-off APPROVED or APPROVED WITH CONDITIONS | ✓ `production/qa/qa-signoff-sprint-4-2026-05-06.md` APPROVED |
| 9 | ≥3 distinct playtest sessions in `production/playtests/` | ✗ — directory does not exist |
| 10 | Playtest reports cover NPE / mid-game / difficulty curve | ✗ |
| 11 | Fun hypothesis from Game Concept validated or revised | ✗ — no playtest data |
| 12 | Vertical Slice playable | ✗ — only FE sub-system perf fixture |

## Quality Checks: 3/9 passing

| # | Check | Status |
|---|-------|--------|
| 1 | Tests passing | ✓ 600/600 |
| 2 | No critical/blocker bugs | ✓ |
| 3 | Core loop plays as designed | ✗ — no core loop yet |
| 4 | Performance within budget | ✓ 1.1 ms mean, 44% mobile budget |
| 5 | Playtest findings reviewed | ✗ — no playtests |
| 6 | No confusion loops | ✗ |
| 7 | Difficulty curve matches design doc | ✗ |
| 8 | All implemented screens have UX specs | ? — no UI implemented Sprint 4 |
| 9 | Accessibility compliance verified | ? — pending UI work |

## Epic Completion (cross-project)

| Epic | Stories Complete | Notes |
|------|-----------------|-------|
| follower-entity | 12/12 ✓ | Sprint 4 |
| asset-id-registry | 4/4 ✓ | |
| network-layer-ext | 5/5 ✓ | |
| crowd-state-server | 7/8 | 1 story remaining |
| match-state-server | 5/8 | 3 stories remaining |
| tick-orchestrator | 4/5 | 1 story remaining |
| ui-handler-layer-reg | 1/2 | |
| crowd-replication-broadcast | 1/5 | 4 stories remaining |
| round-lifecycle | 2/5 | 3 stories remaining |
| player-data-schema | 2/3 | |
| absorb-system | 0 stories drafted | EPIC.md only |
| chest-system | 0 stories drafted | EPIC.md only |
| crowd-collision-resolution | 0 stories drafted | EPIC.md only |
| npc-spawner | 0 stories drafted | EPIC.md only |
| relic-system | 0 stories drafted | EPIC.md only |

## Blockers (must resolve before Production → Polish PASS)

1. **No playable gameplay loop**. Sprint 4 implemented only FollowerEntity client
   simulation. Core gameplay (absorb NPCs → grow crowd → chest raids → win round)
   is not yet playable. Missing systems: absorb-system, chest-system, npc-spawner,
   crowd-collision-resolution, relic-system.

2. **No playtest evidence**. `production/playtests/` does not exist. Polish gate
   requires ≥3 playtest sessions covering NPE, mid-game, and difficulty curve.

3. **Fun hypothesis unvalidated**. Game Concept's snowball-dopamine + chest-raid
   risk/reward hypothesis cannot be validated without a playable loop + playtest.

4. **5 critical epics have ZERO stories drafted**. absorb/chest/npc-spawner/
   crowd-collision-resolution/relic-system. Run `/create-stories [epic-slug]`
   for each.

5. **5 partially-done epics** providing supporting infrastructure. crowd-replication-
   broadcast (1/5), round-lifecycle (2/5), match-state-server (5/8), crowd-state-
   server (7/8), tick-orchestrator (4/5). Sprint 4's client work depends on these
   for end-to-end gameplay.

## Recommendations (minimal path to PASS)

1. **Sprint 5+ scope**: ship absorb-system, chest-system, npc-spawner,
   crowd-collision-resolution. Drain round-lifecycle 2/5 → 5/5 to enable round
   start / end events.
2. **Vertical Slice build**: stitch FollowerEntity (done) + absorb + NPC spawn +
   chest raid + round timer into a ~3-minute playable session end-to-end.
3. **Playtest plan**: 3 sessions documented in `production/playtests/` covering
   NPE / mid-game / difficulty curve. Run `/playtest-report` per session.
4. **Re-run `/gate-check`** after the above lands.

## Chain-of-Verification

5 questions checked — verdict unchanged.

1. *Did I downgrade FAIL conditions to mere CONCERNS?* No — playable gameplay +
   playtests are hard prerequisites per gate spec.
2. *Are missing artifacts resolvable in Polish?* No — Polish phase polishes
   existing gameplay; cannot polish what does not exist.
3. *Could I be over-strict?* No — gate spec is explicit: "Vertical Slice playable"
   + "≥3 playtest sessions" are not optional.
4. *Is there a minimal path to PASS?* Yes — see Recommendations.
5. *Did I miss any blocker?* Possibly UX specs for HUD/menus — flagged for
   follow-up audit.

## Stage update

`production/stage.txt` stays at **Production**. **NOT advanced.**

## Sprint 4 status (separate from gate verdict)

Sprint 4 is COMPLETE and APPROVED for sprint close-out. The FAIL verdict here
is about *project-wide* readiness for Polish phase advancement, not Sprint 4
itself. Sprint 4's Sprint Goal — "Land complete FollowerEntity client simulation
MVP at 80 LOD-0 followers, ≤2.5ms p99" — was achieved (1.1 ms mean = 44% of
mobile budget; AC-18 zero-alloc invariant verified ×12 runs).

## Next steps

- Plan Sprint 5: `/sprint-plan new` — focus on absorb-system + npc-spawner +
  chest-system stories (start with `/create-stories` for those epics)
- Continue draining partially-done epics in parallel
- Build Vertical Slice incrementally as systems land
- After playable loop exists: run 3 playtest sessions + `/playtest-report`
- Re-run `/gate-check` when Vertical Slice + playtests complete
