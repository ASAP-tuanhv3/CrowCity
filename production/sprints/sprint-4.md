# Sprint 4 — 2026-05-04 to 2026-05-15 (FollowerEntity Client Simulation Complete)

> **Status**: Active
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (gate-check Production → Polish blocker)
> **Previous Sprint**: Sprint 3 Core Spine (10/10 must-have closed, 312/312 tests, APPROVED WITH CONDITIONS, commits 083437d → 95d134d)

## Sprint Goal

Land complete FollowerEntity client simulation MVP. By sprint end, 80 LOD-0 followers per crowd render at ≤2.5ms p99 RenderStepped on min-spec mobile (per ADR-0007 + ADR-0003), with boids flocking, peel transitions, walk bob, hue tint, and pool-hide LOD swap functional. Closes 11 of 12 epic stories (001 already done) plus 5 Sprint 3 backlog carryovers.

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Buffer (20%): 2 days reserved for unplanned work / blockers
- Available: 8 days

## Tasks

### Must Have (Critical Path — 5.9d / 47h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 4-1 | CRB story-001 — CrowdStateClient mirror + tickIsNewer F4 (Sprint 3 backlog promoted) | gameplay-programmer | 4h | 3-5 done | story-001 ACs pass; client mirror dictionary keyed by crowdId; uint16 tick wrap handled. **Gate for FE 002.** |
| 4-2 | FE story-002 — CrowdManagerClient orchestrator + per-crowd lifecycle | gameplay-programmer | 5h | 4-1 | story-002 ACs pass; per-crowd FollowerEntityClient instance per crowdId; mount/dismount on CrowdCreated/CrowdDestroyed |
| 4-3 | FE story-003 — Boids F1-F4 (separation + cohesion + leader + zero-vector guards) | gameplay-programmer | 4h | 4-2 | story-003 ACs pass; boids math passes deterministic fixture tests; zero-vector neighborhoods do not NaN |
| 4-4 | FE story-004 — Walk bob F8 + standstill freeze + micro-sway F9 | gameplay-programmer | 4h | 4-2 | story-004 ACs pass; bob amplitude/period within GDD spec; standstill threshold detected; micro-sway phase-offset randomized |
| 4-5 | FE story-005 — Spawn states (FadeIn / SlideIn) + 4/frame throttle + d_init random | gameplay-programmer | 5h | 4-2, 4-3 | story-005 ACs pass; 4 spawns per frame max; FadeIn transparency curve hits target; SlideIn lerp duration matches spec |
| 4-6 | FE story-006 — Hue Color3 write + dirty flag + reconciliation timer | gameplay-programmer | 3h | 4-2 | story-006 ACs pass; hue write-on-dirty-only; reconciliation timer prevents missed hue update; no per-frame Color3 alloc |
| 4-7 | FE story-007 — Peel selection F6 (closest-to-rival) + concurrent dual-rival peel | gameplay-programmer | 3h | 4-3, 4-4 | story-007 ACs pass; F6 deterministic; dual-rival case picks 2 distinct followers |
| 4-8 | FE story-008 — Peel transit F7 + hue-flip latch + rival-nil abort | gameplay-programmer | 5h | 4-7 | story-008 ACs pass; F7 transit completes within 0.5s; hue flips at midpoint latch; rival-nil aborts cleanly back to flock |
| 4-9 | FE story-009 — setPoolSize + Peeling immunity + getPeelingCount accessor | gameplay-programmer | 4h | 4-8 | story-009 ACs pass; mid-peel followers immune to pool shrink; getPeelingCount accurate per crowd |
| 4-10 | FE story-010 — LOD tier swap F5 + d preservation + teleport snap | gameplay-programmer | 4h | 4-3, 4-9 | story-010 ACs pass; tier swap preserves d phase; no visual pop on teleport snap |
| 4-11 | FE story-011 — Perf soak validation 80 LOD-0 ≤ 2.5ms p99 | gameplay-programmer | 3h | 4-10 | story-011 ACs pass; RenderStepped p99 ≤ 2.5ms @ 80 LOD-0; soak doc at `production/qa/evidence/follower-entity-perf-soak-evidence.md` |
| 4-12 | FE story-012 — Pool hide/unhide LOD swap — no Instance.new on swap | gameplay-programmer | 3h | 4-10 | story-012 ACs pass; LOD swap reuses pool slots; zero `Instance.new` calls during swap (assertion) |

**Must Have total: 47h ≈ 5.9d**

### Should Have (1.5d / 12h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 4-13 | CSM story-005 — F2 position lag + nil HRP guard (Sprint 3 backlog) | gameplay-programmer | 4h | 3-2 done | story-005 ACs (AC-7/19) pass; nil HRP does not crash position pull |
| 4-14 | MSM story-007 — broadcast Participation + GetParticipation + AFKToggle 4-Check (Sprint 3 backlog) | gameplay-programmer | 4h | 3-9 done | story-007 ACs pass; resolves Selene Condition 2 from Sprint 3 sign-off; ADR-0010 4-Check Guard validated |
| 4-15 | RL story-003 — Eliminated subscription + DC freeze (Sprint 3 backlog) | gameplay-programmer | 4h | 3-10 done, 3-8 done | story-003 ACs pass; freeze-on-DC matches MSM Snap-freeze contract |

**Should Have total: 12h ≈ 1.5d**

### Nice to Have (0.5d / 4h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 4-16 | TickOrch story-005 — per-phase os.clock instrumentation hook (Sprint 3 backlog) | gameplay-programmer | 4h | 3-1 done | story-005 ACs pass; disabled-mode overhead <0.05ms |

**Nice to Have total: 4h ≈ 0.5d**

**Sprint planned total: 7.9d** (within 8-day capacity, 0.1d slack on top of 2d buffer)

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| 3-11 CRB story-001 (Sprint 3 should-have) | Promoted to Sprint 4 must-have (4-1) — gating dependency for FE 002 client mirror | 4h |
| 3-12 RL story-003 (Sprint 3 should-have) | Promoted to Sprint 4 should-have (4-15) | 4h |
| 3-13 CSM story-005 (Sprint 3 should-have) | Promoted to Sprint 4 should-have (4-13) | 4h |
| 3-14 TickOrch story-005 (Sprint 3 nice-to-have) | Promoted to Sprint 4 nice-to-have (4-16) | 4h |
| 3-15 MSM story-007 (Sprint 3 nice-to-have) | Promoted to Sprint 4 should-have (4-14) — Selene Condition 2 resolution + ADR-0010 4-Check | 4h |

Total carryover: 2.5d (5 stories rolled forward; 1 promoted to must-have, 3 to should-have, 1 to nice-to-have).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ADR-0007 newly Accepted 2026-05-04 — no implementation dry-run | Medium | High | Story 4-2 (FE 002) is integration test heavy; failures surface boids/peel design assumptions before stories 4-3..4-12 commit. Pivot to Should Have if A7 reveals gaps. |
| Mobile thermal performance unproven at 800-1200 instance count (12 crowds × 80 followers + hats) | Medium | High | Story 4-11 perf soak mid-sprint not end-sprint to allow re-budgeting. Per-rig flag set (Anchored, CanCollide=false, CanQuery=false, CanTouch=false, CastShadow=false) already validated by story 001. Soak deferred to MVP-Integration-1 if 4-11 reveals platform headroom shortage. |
| Peel transit (4-8) couples with Crowd Collision Resolution which has no stories yet | Low | Medium | FE 008 stubs the rival-target API; CCR stories created next sprint plug concrete rival source. Mock-rival fixture in test sufficient for story close. |
| 11 FE stories in single sprint — throughput risk | Medium | Medium | Stories 4-3 / 4-4 / 4-6 parallelizable after 4-2 lands (per epic Implementation Order). Drop 4-12 (pool hide/unhide) to Sprint 5 if velocity slips at 4-10. |
| TestEZ headless CI still warn-only on Linux (Sprint 2+3 carry-forward) | Low | Low | Local TestEZ + selene + 4 audit gates remain blocking; macOS self-hosted runner deferred to Sprint 5+ |

## Dependencies on External Factors

- ADR-0007 Accepted 2026-05-04 ✓ (no longer blocking)
- ADR-0010 §4-Check Guard text — verify Accepted before story 4-14 (was Proposed during Sprint 3 — re-check status)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (12 stories — closes FollowerEntity epic + 1 CRB carryover)
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists at `production/qa/qa-plan-sprint-4-[date].md` (run `/qa-plan sprint` at sprint start)
- [ ] All Logic stories have passing unit tests; Integration stories have passing integration tests
- [ ] Story 4-11 produces perf evidence doc at `production/qa/evidence/follower-entity-perf-soak-evidence.md`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Selene Condition 2 (carry-forward warnings on `MSM/init.luau`) resolved via 4-14
- [ ] Code reviewed and merged (lean mode: per-story review + sprint close-out aggregate)

## Notes

- FE epic closes this sprint pending 4-12 — 12 of 12 stories implemented if all Must Haves land.
- Sprint 4 closes 5 of 5 Sprint 3 backlog stories — fully drains the Sprint 3 deferred queue.
- Presentation layer (HUD, FollowerLODManager, Player Nameplate, etc.) remains uncreated. Sprint 5 candidates: `/create-epics layer: presentation` + `/create-stories npc-spawner` + `/create-stories absorb-system` to begin gameplay loop wiring.
- Commit `95d134d` (FE Story 001 close) is Sprint 4 starting baseline; tests at 312/312.
