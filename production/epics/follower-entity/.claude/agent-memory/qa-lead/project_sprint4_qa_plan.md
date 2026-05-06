---
name: Sprint 4 QA Plan Context
description: Key decisions and stats from the Sprint 4 QA plan written 2026-05-04 — 16 stories, FollowerEntity MVP close
type: project
---

QA plan written to `production/qa/qa-plan-sprint-4-2026-05-04.md` on 2026-05-04.

**Why:** Sprint 4 closes the FollowerEntity client simulation epic (stories 002-012) plus 5 Sprint 3 backlog carryovers (CRB 001, CSM 005, MSM 007, RL 003, TickOrch 005).

**Key stats:**
- 16 stories total; 12 Logic, 2 Integration with test files, 2 Integration with manual-only evidence
- ~162 new tests estimated → ~474 total by sprint end (312 baseline)
- 2 manual evidence files required (BLOCKING): perf-soak + lod-swap in `production/qa/evidence/`
- Stories 4-11 and 4-12 have NO automated tests — manual Micro Profiler soak and instance-count check respectively

**Blocking gates:**
- Logic stories 4-1, 4-3 through 4-10, 4-13, 4-15, 4-16: test files in `tests/unit/` BLOCKING
- Integration stories 4-2, 4-14: test files in `tests/integration/` BLOCKING
- 4-11 evidence: `production/qa/evidence/perf-soak-[date].txt` with p99 ≤ 2.5ms PASS
- 4-12 evidence: `production/qa/evidence/lod-swap-[date].txt` with before/after count match PASS

**How to apply:** When reviewing sprint completion, check these specific evidence paths before marking 4-11 or 4-12 Done. The perf budget is 1.5ms desktop / 2.5ms mobile — if desktop p99 exceeds 2.5ms, do not proceed to mobile soak; re-profile first.
