# Sprint 3 — 2026-05-01 to 2026-05-14 (Core Spine — Round Mechanics Live)

> **Status**: Active
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (gate-check Pre-Production → Production blocker)
> **Previous Sprint**: Sprint 2 Core Spine Skeleton (149/149 tests, APPROVED, commits 5789d1b → c98efb3)

## Sprint Goal

Drive a full round end-to-end on the server: MSM transitions Lobby → Countdown → Active → Result → Intermission, CSM Phase 5 evaluator handles eliminations + grace timer, CSM Phase 8 broadcasts state to clients (CrowdStateClient mirror), RoundLifecycle tracks CountChanged + peakCount. By sprint end, the server simulates a legal round (no NPC spawns yet) with state machine + broadcasts wired through TickOrchestrator phases 5/6/7/8.

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work / blockers
- Available: 8 days

## Tasks

### Must Have (Critical Path — 7.0 days)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|--------------------|
| 3-1 | TickOrch story-004 — BindToClose stop() coordination | gameplay-programmer | 0.5 | none (Sprint 2 carryover) | story-004 ACs pass; chain order `[stop → MSM stub → ProfileStore]` verified |
| 3-2 | CSM story-003 — hue F6 + activeRelics cap + CrowdRelicChanged | gameplay-programmer | 0.5 | 2-5 done | story-003 ACs (AC-5/6/16-hue) pass |
| 3-3 | CSM story-004 — F1 composed radius + recomputeRadius write contract | gameplay-programmer | 0.5 | 2-5 done | story-004 ACs (AC-21/22/16-radius) pass; range [1.53, 18.04] enforced |
| 3-4 | CSM story-006 — Phase 5 state evaluator + F7 grace timer | gameplay-programmer | 1.0 | 2-5/2-6 done, 3-1 | story-006 ACs pass; `tests/unit/crowd-state-server/state_evaluator.spec.luau` + `grace_timer.spec.luau` pass |
| 3-5 | CSM story-008 — Phase 8 broadcastAll + perf + Eliminated broadcast | gameplay-programmer | 1.0 | 3-4 | story-008 ACs pass; broadcast budget ≤0.5ms/tick @ 12 crowds verified |
| 3-6 | MSM story-002 — Lobby→Countdown→Active driver + 5s/3-2-1 ladder | gameplay-programmer | 1.0 | 2-8 done, 3-1 | story-002 ACs pass; Phase 6 timercheck stub still no-op; `tests/unit/match-state-server/transition_driver.spec.luau` pass |
| 3-7 | MSM story-003 — Phase 6 timercheck + T7 + F4 tiebreak | gameplay-programmer | 0.5 | 3-6 | story-003 ACs pass; T7 fires on Active 5min timeout; F4 tiebreak deterministic |
| 3-8 | MSM story-004 — Phase 7 elim consumer + T6/T8 + double-signal guard | gameplay-programmer | 1.0 | 3-4, 3-7 | story-004 ACs pass; subscribes CrowdEliminated from CSM 3-4; T6 single elim + T8 last-survivor handled |
| 3-9 | MSM story-005 — Result + Intermission + T9 grant-before-broadcast | gameplay-programmer | 0.5 | 3-8 | story-005 ACs pass; coin grant before broadcast invariant verified |
| 3-10 | RL story-002 — CountChanged subscription + peak tracking F1 | gameplay-programmer | 0.5 | 2-7 done, 2-5 done | story-002 ACs pass; `tests/unit/round-lifecycle/peak_tracking.spec.luau` pass |

**Must Have total: 7.0 days**

### Should Have (1.5 days)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|--------------------|
| 3-11 | CRB story-001 — CrowdStateClient mirror + tickIsNewer F4 | gameplay-programmer | 0.5 | 3-5 | story-001 ACs pass; client mirror dictionary keyed by crowdId; uint16 tick wrap handled |
| 3-12 | RL story-003 — Eliminated subscription + DC freeze | gameplay-programmer | 0.5 | 3-10, 3-8 | story-003 ACs pass; freeze-on-DC matches MSM Snap-freeze contract |
| 3-13 | CSM story-005 — F2 position lag + nil HRP guard | gameplay-programmer | 0.5 | 2-5 done | story-005 ACs (AC-7/19) pass |

**Should Have total: 1.5 days**

### Nice to Have (1.0 days)

| ID | Task | Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|-------------|--------------------|
| 3-14 | TickOrch story-005 — per-phase os.clock instrumentation hook | gameplay-programmer | 0.5 | 2-3 done | story-005 ACs pass; disabled-mode overhead <0.05ms |
| 3-15 | MSM story-007 — broadcast Participation + GetParticipation + AFKToggle 4-Check | gameplay-programmer | 0.5 | 3-9 | story-007 ACs pass; resolves Sprint 2 advisory item 1 (AFKToggle deferred); ADR-0010 4-Check Guard validation enforced |

**Nice to Have total: 1.0 days**

**Sprint planned total: 9.5 days** (within 10-day capacity, 0.5d slack on top of 2d buffer)

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| TickOrch 004 (Sprint 2 should-have, 2-11) | Sprint 2 closed at 7.5d, 2.0d slack unused; promoted to Sprint 3 must | 0.5d |
| CSM 003 (Sprint 2 should-have, 2-9) | same | 0.5d |
| CSM 004 (Sprint 2 should-have, 2-10) | same | 0.5d |
| CSM 005 (Sprint 2 nice-to-have, 2-12) | promoted to Sprint 3 should | 0.5d |
| TickOrch 005 (Sprint 2 nice-to-have, 2-13) | promoted to Sprint 3 nice | 0.5d |

Total carryover: 2.5d (5 stories upgraded from deferred Sprint 2 should/nice tier).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| MSM transition driver scope creep (3-6 → coupled with 3-7/3-8) | Medium | High | Story 3-6 strictly scoped to Lobby→Countdown→Active; T6/T7/T8 are separate stories; pcall at phase boundary catches integration breakage |
| CSM Phase 5 evaluator F7 grace timer math edge cases | Medium | Medium | Story 3-4 includes deterministic unit test fixtures for 0/1/N grace seconds; Phase 5 stub kept under feature flag until 3-4 lands |
| Replication broadcast bandwidth budget exceeded at sprint end | Low | Medium | Story 3-5 unit-tests budget at 12 crowds × 30B = 4.32 KB/s ≤ ADR-0003 5.4 KB/s envelope; multi-client soak deferred to MVP-Integration-1 |
| AFKToggle 4-Check (3-15) interaction with MSM 005 grant logic | Low | Medium | Story 3-15 in nice-to-have tier; can defer to Sprint 4 if 3-9 grant invariant gets fragile |
| TestEZ headless CI still warn-only on Linux (Sprint 2 advisory item 2) | Low | Low | Local TestEZ + selene + 4 audit gates blocking; pre-commit + manual run remains process gate |

## Dependencies on External Factors

- None (solo dev, internal scope)
- ADR-0010 §4-Check Guard text must be locked before story 3-15 (currently Proposed; verify Accepted status before sprint end)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (10 stories)
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists at `production/qa/qa-plan-sprint-3-[date].md` (run `/qa-plan sprint` at sprint start per Sprint 2 advisory item 3)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations (none expected)
- [ ] Code reviewed and merged (lean mode: per-story review + sprint close-out aggregate)

## Notes

- 9-phase TickOrchestrator stub-replacement contract: Phase 5 (CSM:Eval), Phase 6 (MSM:Timer), Phase 7 (MSM:Elim), Phase 8 (CSM:Cast) get real callbacks during this sprint via single-line edits in `start.server.luau`. Phases 1-4 + Phase 9 remain stubs.
- AFKToggle wiring (3-15) closes Sprint 2 advisory item 1 — `_afkToggleConnection` scaffold in MSM init.luau gets activated via story-007 contract.
- CRB stories 002-005 deferred to Sprint 4 — Sprint 3 only lands client mirror skeleton (3-11). Full broadcast subscription path needs server transport phase machine (CRB 004) which rides on MSM 7-state.
- RL stories 004-005 (setWinner / placements F3 sort) deferred to Sprint 4 — depend on MSM 005 (3-9) Result transition firing + winner determination, which lands in Sprint 4 with NPC spawning.
