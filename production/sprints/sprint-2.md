# Sprint 2 — 2026-04-29 to 2026-05-12 (Vertical Slice Build — Core Spine)

> **Status**: Active
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (gate-check Pre-Production → Production blocker)
> **Previous Sprint**: Sprint 1 Design-Lock (commits 7ad9232 / 5b59a15 / af4a825 — UX specs + characters + asset specs + AD APPROVE)

## Sprint Goal

Stand up the Core gameplay spine end-to-end: TickOrchestrator + CrowdStateServer skeleton + MatchStateServer skeleton + RoundLifecycle createAll/destroyAll + Crowd Replication client mirror. By sprint end, a server tick fires 9 phases, CSM holds crowd records keyed on player UserId, MSM transitions Lobby → Active → Result, and the client mirrors broadcast state. Lays the foundation for Sprint 3 (Phase 5/6/7 state-machine logic) and Sprint 4 (perf integration + Vertical Slice playtest).

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work / blockers
- Available: 8 days

## Tasks

### Must Have (Critical Path — 7 days)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|--------------------|
| 2-1 | TickOrch story-001 — module skeleton + accumulator + cadence + start/stop API | gameplay-programmer | 1.0 | none (epic dep-root) | story-001 ACs all pass; `tests/unit/tick-orchestrator/cadence_test.luau` + `lifecycle_test.luau` + `registerphases_test.luau` pass |
| 2-2 | TickOrch story-002 — phase dispatch + pcall isolation + ctx assembly | gameplay-programmer | 1.0 | 2-1 | story-002 ACs pass; `tests/unit/tick-orchestrator/phase_dispatch_test.luau` + `error_isolation_test.luau` pass |
| 2-3 | TickOrch story-003 — boot wiring + 9-phase stub registration in `start.server.luau` | gameplay-programmer | 1.0 | 2-1, 2-2 | story-003 ACs pass; `tests/integration/tick-orchestrator/boot_wiring_test.luau` pass; 9 stub modules under `_PhaseStubs/` |
| 2-4 | CSM story-001 — module skeleton + record schema + create/destroy + DC handler | gameplay-programmer | 1.0 | 2-3 | story-001 ACs (AC-1/2/16/23/26) pass; `tests/unit/crowd-state-server/lifecycle_test.luau` + `dc_cleanup_test.luau` + `signal_fanout_test.luau` pass |
| 2-5 | CSM story-002 — updateCount + DeltaSource + F5 clamp + CountChanged + CrowdCountClamped | gameplay-programmer | 1.0 | 2-4 | story-002 ACs (AC-3/4/15/24/25) pass; corresponding unit tests pass; manifest L71 4-caller rule code-review enforced |
| 2-6 | CSM story-007 — read accessors + setStillOverlapping + Eliminated exclusion | gameplay-programmer | 0.5 | 2-4 | story-007 ACs (AC-27/28) pass; `tests/unit/crowd-state-server/read_accessors_test.luau` pass |
| 2-7 | RL story-001 — module skeleton + Janitor + createAll + destroyAll | gameplay-programmer | 1.0 | 2-4 | story-001 ACs (AC-1/2/3/4) pass; `tests/unit/round-lifecycle/createall_test.luau` + `destroyall_test.luau` + `double_createall_assert_test.luau` pass |
| 2-8 | MSM story-001 — module skeleton + 7-state enum + Lobby boot + participation flags + Snap freeze | gameplay-programmer | 0.5 | 2-3 | story-001 ACs (AC-1/2/3) pass; `tests/unit/match-state-server/skeleton_test.luau` + `participation_flag_test.luau` + `snap_freeze_test.luau` pass |

**Must Have total: 7.0 days**

### Should Have (1.5 days)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|--------------------|
| 2-9 | CSM story-003 — hue F6 + activeRelics cap + CrowdRelicChanged | gameplay-programmer | 0.5 | 2-4 | story-003 ACs (AC-5/6/16-hue) pass; relevant unit tests pass |
| 2-10 | CSM story-004 — F1 composed radius + recomputeRadius write contract | gameplay-programmer | 0.5 | 2-5 | story-004 ACs (AC-21/22/16-radius) pass; range assertion enforced |
| 2-11 | TickOrch story-004 — BindToClose stop() coordination | gameplay-programmer | 0.5 | 2-3 | story-004 ACs pass; chain order `[stop → MSM stub → ProfileStore]` verified |

**Should Have total: 1.5 days**

### Nice to Have (1 day)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|--------------------|
| 2-12 | CSM story-005 — F2 position lag + nil HRP guard | gameplay-programmer | 0.5 | 2-4 | story-005 ACs (AC-7/19) pass |
| 2-13 | TickOrch story-005 — per-phase instrumentation hook | gameplay-programmer | 0.5 | 2-3 | story-005 ACs pass; disabled-mode overhead <0.05ms |

**Nice to Have total: 1.0 days**

**Sprint planned total: 9.5 days** (within 10-day capacity, 0.5d slack on top of 2d buffer)

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| (none) | Sprint 1 (Design-Lock) closed clean per session-state 2026-04-27 — UX specs + characters + asset specs + AD APPROVE all delivered | — |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Test framework not yet scaffolded — Logic stories require `tests/unit/...` to exist | HIGH | BLOCKING (Logic story acceptance criteria untestable) | Run `/test-setup` BEFORE story-001 implementation begins (queued as Sprint 2 prerequisite) |
| `RunService.Heartbeat` mobile jitter on iPhone SE untested (ADR-0002 Risk 1 MEDIUM) | MEDIUM | MEDIUM (cadence assertion may fail on mobile) | Story-001 cadence AC measures desktop ±0.1%; mobile validation deferred to Sprint 4 multi-client soak per ADR-0003 §Validation Sprint Plan |
| Stub-replacement contract drift (TickOrch story-003 stubs replaced by consuming epic stories landing in this sprint) | LOW | LOW (test fixture confusion if stubs and real modules co-exist) | Story-003 names stub files explicitly; consuming stories (CSM/MSM) edit `_registerPhases` table in-place per documented contract |
| 9.5d planned total vs 8d available after buffer — modest over-allocation | LOW | LOW (1.5d over budgets sliding into Should Have / Nice to Have if Must Have slips) | Defer Should Have stories to Sprint 3 if Must Have runs long; Nice to Have already at floor |
| Cross-epic BindableEvent contract (CSM `CrowdEliminatedServer`) requires CSM story-006 wiring — but story-006 is NOT in this sprint | MEDIUM | LOW (MSM story-004 + RL story-003 not in sprint either; contract docs land in story-006 sprint) | Story-002 docs the contract requirement; sprint 3 lands story-006 + consumers atomically |

## Dependencies on External Factors

- **Test framework scaffolding** — `tests/unit/` + `tests/integration/` + TestEZ runner + GitHub Actions CI workflow do NOT exist yet. `/test-setup` must run before story-001 implementation. Treat as Sprint 2 day-0 prerequisite (not counted against story estimates above).
- **Foundation epics** — Already Complete (commits per gate-check 2026-04-27). `Network` module + `RemoteValidator` + `RateLimitConfig` + buffer codec + ProfileStore schema all available.
- **No external collaborators** — solo dev sprint.

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria (each story's QA Test Cases section)
- [ ] QA plan exists (`production/qa/qa-plan-sprint-2.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests in `tests/unit/...` / `tests/integration/...`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] Audit gates green: `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` exit 0
- [ ] `selene src/` lint clean

## Out of Scope (this sprint)

- CSM story-006 Phase 5 state evaluator + F7 grace timer + CrowdEliminated → **Sprint 3**
- CSM story-008 Phase 8 broadcastAll + buffer codec wiring + perf integration → **Sprint 3**
- MSM stories 002-008 (transitions, Phase 6/7, T9, T11, broadcasts, perf) → **Sprint 3 + 4**
- RL stories 002-005 (CountChanged peak tracking, Eliminated/DC, setWinner, getPlacements) → **Sprint 3**
- Crowd Replication Broadcast stories 001-005 (client mirror + subscribers + transport) → **Sprint 3 + 4**
- Feature layer epics (NPC Spawner, Absorb, CCR, Chest, Relic, Follower Entity) — not yet created (`/create-epics layer: feature` after Core stories begin landing)
- Vertical Slice playtest (≥3 sessions documented) → **Sprint 4** post-Feature-layer integration
- Multi-client bandwidth soak (AC-14/15) → **Sprint 4** per ADR-0003 §Validation Sprint Plan

## Producer Feasibility Gate

PR-SPRINT skipped — lean review mode.

## QA Plan Status

⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
before the last story is implemented. The Production → Polish gate requires a QA
sign-off report, which requires a QA plan. Since each story already embeds QA Test
Cases per `/create-stories` Phase 4b protocol, the QA plan can largely auto-generate
from the story files — but the consolidated test plan + manual test cases + smoke
test scope still need to be authored.

## Next Steps

1. Run `/test-setup` (Sprint 2 day-0 prerequisite — scaffolds `tests/`, TestEZ runner, GitHub Actions CI)
2. Run `/qa-plan sprint` (consolidates story-embedded QA Test Cases + manual cases + smoke scope)
3. Run `/story-readiness production/epics/tick-orchestrator/story-001-core-module-skeleton-cadence.md` (validate story 2-1 ready)
4. Run `/dev-story production/epics/tick-orchestrator/story-001-core-module-skeleton-cadence.md` (begin implementation)
5. Use `/sprint-status` mid-sprint for progress checks
6. Run `/scope-check tick-orchestrator` + `/scope-check crowd-state-server` etc. to detect scope creep before each epic's stories are implemented
