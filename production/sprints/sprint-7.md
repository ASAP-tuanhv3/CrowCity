# Sprint 7 — 2026-05-23 to 2026-06-05 (Sprint 6 Bug Triage + Tech Debt Burn-Down)

> **Status**: Draft
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (Sprint 6 close gate blocked on BUG-001 + BUG-002)
> **Previous Sprint**: Sprint 6 — APPROVED WITH CONDITIONS, 6 conditions open

## Sprint Goal

Close the 6 conditions from Sprint 6 sign-off. Confirm visual absorb loop working in Studio (BUG-001). Fix follower clump (BUG-002). Burn down 3rd-carry-forward tech debt (11 follower-entity integration failures). Prevent BUG-001 recurrence via end-to-end integration smoke. Ship Sprint 5/6 should-have carry-forwards.

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Buffer (20%): 2 days for unplanned work / blockers
- Available: 8 days (64h)

## Tasks

### Must Have (Critical Path — 5.0d / 40h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 7-1 | **BUG-001 fix** — visual absorb loop server-side updateCount | gameplay-programmer | 6h | BUG-001 doc | Studio Local Server: walk into NPC → `[CSM] updateCount` log fires; absorbed NPC despawns; +1 follower fades in within 0.2s |
| 7-2 | **AbsorbSystem diagnostic logging** (BUG-001 prereq + Sprint 7+ aid) | gameplay-programmer | 1h | none | tick log: `crowds=N npcs=M` once/sec when Active. Disabled by config flag in production |
| 7-3 | **BUG-002 root-cause + fix** — follower clump despite boid wired | gameplay-programmer | 4h | none | Studio: 10 followers visibly spread to ≥ SEPARATION_RADIUS (2.5 studs) at standstill; arc/trail in motion |
| 7-4 | **E2E integration smoke** — synthetic absorb → broadcast count delta | gameplay-programmer | 4h | none | headless TestEZ: fires synthetic NPC overlap, asserts broadcast payload count delta reaches mock client. Locks BUG-001 class regression |
| 7-5 | **11 follower-entity integration failures** — fix or document ceiling | gameplay-programmer | 5h | none | tests/integration/follower-entity/{crowd_manager_orchestrator,wire_in_end_to_end,wire_in_pool_integration}.spec.luau pass OR ceiling story documents acceptable defer with rationale |
| 7-6 | **ADR-0008 amendment** — NPCSpawner caller authority (start.server.luau drift) | gameplay-programmer | 3h | ADR-0008 | new ADR-0008-A1 amendment doc; control-manifest updated; existing bridge code annotated with §reference |
| 7-7 | **Refresh tests/smoke/critical-paths.md** — Sprint 3-6 mechanics | gameplay-programmer | 2h | none | smoke doc reflects MSM driver, AbsorbSystem chain, CCR Phase 1, NPCSpawner UREvent, CRB transport phase |
| 7-8 | **Sprint 7 smoke + manual playtest** — re-validate visual absorb loop | qa | 3h | 7-1, 7-3 | TC-S1-03 / TC-S1-04 PASS in Studio; sprint goal MET; sign-off APPROVED (no conditions) |
| 7-9 | **Absorb story-006** — V/A consumers VFX AbsorbSnap + audio batching (5/6 carry) | gameplay-programmer | 4h | 7-1 | story-006 ACs pass |
| 7-10 | **MSM story-007** — broadcast Participation + AFKToggle 4-Check (5/6 carry) | gameplay-programmer | 4h | 6-2 | story-007 ACs pass; resolves Selene Cond 2 |
| 7-11 | **RL story-003** — Eliminated subscription + DC freeze (5/6 carry) | gameplay-programmer | 4h | RL existing | story-003 ACs pass |

**Must Have total: 40h ≈ 5.0d**

### Should Have (1.5d / 12h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 7-12 | Absorb story-007 — Perf soak 3600 overlap p99 ≤ 1.5ms (5/6 carry) | gameplay-programmer | 3h | 7-1 | story-007 ACs pass; evidence doc |
| 7-13 | TickOrch story-005 — per-phase os.clock instrumentation (4/5/6 carry) | gameplay-programmer | 4h | TickOrch | story-005 ACs pass; disabled-mode overhead < 0.05ms |
| 7-14 | follower-entity integration test isolation pattern doc | gameplay-programmer | 2h | 7-5 | docs/testing-patterns.md section: NPCSpawner/CSM mock setup for end-to-end follower path |
| 7-15 | Sprint 6 retrospective | producer | 3h | 7-8 | doc covers: BUG-001 detection gap, 12/12 must-have velocity, conditions that ran into Sprint 7 |

**Should Have total: 12h ≈ 1.5d**

### Nice to Have (1.0d / 8h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 7-16 | Chest System epic kickoff — story-001 skeleton + DI scaffold | gameplay-programmer | 4h | chest-system epic | story-001 ACs pass |
| 7-17 | Relic System epic kickoff — story-001 skeleton + DI scaffold | gameplay-programmer | 4h | relic-system epic | story-001 ACs pass |

**Nice to Have total: 8h ≈ 1.0d**

**Sprint planned total: 7.5d** (within 8-day capacity, 0.5d slack)

## Carryover from Previous Sprints

| Task | Reason | New Estimate |
|------|--------|--------------|
| 6-13 Absorb V/A consumers | Sprint 6 should-have backlog → 7-9 must-have | 4h |
| 6-14 MSM Participation broadcast | Sprint 6 should-have backlog → 7-10 must-have | 4h |
| 6-15 RL Eliminated + DC freeze | Sprint 6 should-have backlog → 7-11 must-have | 4h |
| 6-16 Absorb perf soak | Sprint 6 nice-to-have → 7-12 should-have | 3h |
| 6-17 TickOrch instrumentation | Sprint 4/5/6 nice-to-have → 7-13 should-have | 4h |

5/6 carry-forwards promoted: 3 to must-have (5/6 should-haves all wear out their welcome), 2 to should-have (3rd carry).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| BUG-001 root cause is deeper than wiring (e.g. AbsorbSystem.tick contract mismatch) | Medium | High | 7-2 diagnostic logging lands first → narrows scope. Time-box 7-1 to 6h; if blocked, file BUG-001a + slip to Sprint 8 |
| BUG-002 fix requires CFrame composition rewrite (LOD path entanglement) | Medium | Medium | 7-3 time-boxed to 4h. Acceptable downgrade: visible separation at LOD 0 only; LOD 1+ tracked as known visual quality gap |
| 11 follower-entity failures rooted in abandoned Sprint 4 design — not fixable in 5h | High | Medium | 7-5 acceptance allows "ceiling story" documenting defer. 3rd consecutive carry — accept defer is OK if rationale solid |
| Sprint 5/6 carry-forwards are all blocked on broken visual loop (7-1) | Low | High | 7-9 (V/A consumers) + 7-12 (perf soak) gated on 7-1 PASS. If 7-1 slips to Sprint 8, defer 7-9/7-12 too |
| E2E smoke harness more complex than 4h (mock NPCSpawner + mock CSM + mock client) | Medium | Medium | 7-4 narrowed to single-crowd single-NPC happy path; multi-crowd cases deferred to Sprint 8 |

## Dependencies on External Factors

- BUG-001 + BUG-002 documented at `production/qa/bugs/` ✓
- Sprint 6 sign-off conditions documented ✓
- ADR-0008 + control-manifest authoritative ✓

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (11 tasks)
- [ ] BUG-001 closed (visual absorb loop working in Studio)
- [ ] BUG-002 closed or downgraded with documented rationale
- [ ] 11 follower-entity integration failures resolved or ceiling story committed
- [ ] E2E integration smoke harness running in CI / headless gate
- [ ] ADR-0008 amendment Accepted
- [ ] tests/smoke/critical-paths.md current to Sprint 6
- [ ] Sprint 7 smoke check passed
- [ ] QA sign-off APPROVED (Sprint 6 conditions all clear)
- [ ] No S1/S2 bugs
- [ ] Sprint 6 retrospective documented

## Notes

- Sprint 6 retrospective candidate insights for 7-15:
  - Test gap: every component unit-tested but full server-to-client chain never auto-validated. BUG-001 only surfaceable in Studio.
  - Velocity: 12 must-have done same-day as sprint start (5/9 → 5/9 close) — fast solo burn but quality validation lagged.
  - Carry-forwards: 5/6 Sprint 5/6 should-haves promoted to 7 must-have. Pattern: stretch should-haves get pushed by must-have growth.
- After Sprint 7 closes BUG-001, Sprint 8 candidates: Chest + Relic full epic build (11+11 stories), Presentation epic creation (HUD/Nameplate/Billboard).
- `/qa-plan sprint` MUST run before implementation begins — Sprint 6 lacked one until retroactive close-out exposed BUG-001 / BUG-002. Don't repeat.

QA Plan: NOT YET CREATED — run `/qa-plan sprint` before starting 7-1.
