# Sprint 5 — 2026-05-07 to 2026-05-20 (NPC + Absorb Vertical Slice Spine)

> **Status**: Active
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (gate-check Production → Polish blocker)
> **Previous Sprint**: Sprint 4 FollowerEntity Client Simulation (12/12 must-have closed, 600/600 tests, APPROVED, FE epic complete; gate-check Production → Polish FAIL — vertical slice still unplayable)

## Sprint Goal

Land NPC Spawner full epic + Absorb System Logic core. By sprint end, neutral NPCs spawn into arena, idle-walk, and feed crowd growth via Phase 3 overlap testing — proving the Pillar 1 growth loop end-to-end on server (count ticks up on player overlap with neutral NPCs).

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Buffer (20%): 2 days reserved for unplanned work / blockers
- Available: 8 days (64h)

## Tasks

### Must Have (Critical Path — 5.3d / 42h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 5-1 | NPC story-001 — Pool bootstrap 300 Parts chunked + Heartbeat + ARENA validation | gameplay-programmer | 4h | RL.createAll done | story-001 ACs pass; 300 Parts allocated 25/batch via task.defer; no boot-tick spike; ARENA bounds validated |
| 5-2 | NPC story-002 — reclaim() synchronous + double-reclaim assert | gameplay-programmer | 2h | 5-1 | story-002 ACs pass; reclaim returns synchronously; double-reclaim throws; pool partition flips |
| 5-3 | NPC story-003 — getAllActiveNPCs frozen snapshot + cache invalidation | gameplay-programmer | 2h | 5-2 | story-003 ACs pass; frozen table; cache invalidates on add/reclaim |
| 5-4 | NPC story-004 — Idle walk + boundary reflection (Heartbeat tick) | gameplay-programmer | 3h | 5-1 | story-004 ACs pass; F4 walk speed honoured; reflects at ARENA bounds; no NaN |
| 5-5 | NPC story-005 — Respawn pipeline — delay, position, crowd exclusion, fallback | gameplay-programmer | 4h | 5-2, CSM.getAllCrowdPositions | story-005 ACs pass; respawn delay configurable; min-distance gate consults CSM; fallback if no valid spot |
| 5-6 | NPC story-006 — Respawn fade-in (TweenService 1→0 over 0.3s) | gameplay-programmer | 2h | 5-5 | story-006 ACs pass; transparency tween hits 0 within 0.3s; evidence doc |
| 5-7 | NPC story-007 — destroyAll() cleanup — cancel pending timers + tweens | gameplay-programmer | 2h | 5-5, 5-6 | story-007 ACs pass; T9 destroyAll cancels timers + tweens; no leaked connections |
| 5-8 | NPC story-008 — F2/F4 density guards — R_absorb EPSILON guard + steady-state | gameplay-programmer | 3h | 5-1 | story-008 ACs pass; EPSILON guard prevents zero-radius div; steady-state population matches ρ_design |
| 5-9 | NPC story-009 — UREvent NpcStateBroadcast + client mirror pool | gameplay-programmer | 4h | 5-3, 5-4 | story-009 ACs pass; UREvent payload per ADR-0008 §Replication Channel; client mirror interpolates positions |
| 5-10 | Absorb story-001 — Phase 3 callback skeleton + DI scaffold | gameplay-programmer | 2h | TickOrch Phase 3 done | story-001 ACs pass; Phase 3 callback registered; DI accepts CSM + NPCSpawner deps |
| 5-11 | Absorb story-002 — F1 overlap test + F2 contention resolution | gameplay-programmer | 4h | 5-10, 5-3 | story-002 ACs pass; circle 2D dist² overlap deterministic; same-tick crowd-vs-crowd contention resolves per F2 |
| 5-12 | Absorb story-003 — Per-overlap sequence + reclaim contract + snapshot atomicity | gameplay-programmer | 3h | 5-11, 5-2 | story-003 ACs pass; reclaim called once per absorb; snapshot atomic across tick |
| 5-13 | Absorb story-004 — State guards — Active / GraceWindow allow, Eliminated skip | gameplay-programmer | 2h | 5-12 | story-004 ACs pass; Active + GraceWindow absorb; Eliminated skip silent; CSM floor clamp respected |
| 5-14 | Absorb story-005 — Count clamp passthrough + Absorbed reliable RemoteEvent | gameplay-programmer | 3h | 5-13 | story-005 ACs pass; updateCount(+1, "Absorb") writes; clamp [1, 300]; Absorbed reliable signal payload matches schema |

**Must Have total: 42h ≈ 5.3d**

### Should Have (2.8d / 22h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 5-15 | Absorb story-006 — V/A consumers — VFX AbsorbSnap + audio batching + streak escalation | gameplay-programmer | 4h | 5-14 | story-006 ACs pass; VFX snap fires on Absorbed; audio batches per tick; streak timer escalates SFX |
| 5-16 | Absorb story-007 — Perf soak 3600 overlap tests p99 ≤ 1.5ms | gameplay-programmer | 3h | 5-14 | story-007 ACs pass; synthetic 8 crowds × 60 NPCs over 60 ticks; p99 ≤ 1.5ms (manifest 0.5ms advisory); evidence doc |
| 5-17 | CSM story-005 — F2 position lag + nil HRP guard (Sprint 4 backlog) | gameplay-programmer | 4h | 3-2 done | story-005 ACs (AC-7/19) pass; nil HRP does not crash position pull |
| 5-18 | MSM story-007 — broadcast Participation + GetParticipation + AFKToggle 4-Check (Sprint 4 backlog) | gameplay-programmer | 4h | 3-9 done | story-007 ACs pass; resolves Selene Condition 2 from Sprint 3 sign-off; ADR-0010 4-Check Guard validated |
| 5-20 | **SCOPE-ADD** CRB story-002 — Broadcast subscriber + decode + idempotent overwrite + stale freeze (F2) + Eliminated defensive | gameplay-programmer | 3h | 4-1 done (CRB 001) | story-002 ACs pass; client UREvent CrowdStateBroadcast decode populates CrowdStateClient cache; tick_is_newer rejects stale; Eliminated state defensive freeze |
| 5-21 | **SCOPE-ADD** CRB story-003 — Reliable subscribers + 4 client BindableEvent signals + late-reliable handling | gameplay-programmer | 4h | 4-1 done, 5-20 (decode shape) | story-003 ACs pass; CrowdCreated/CrowdDestroyed/CrowdEliminated/CrowdRelicChanged reliable subscribers wire CrowdStateClient BindableEvents; late-reliable handled |

**Should Have total: 22h ≈ 2.8d**

> **Scope addition rationale (2026-05-07)**: CRB 002+003 added mid-sprint after Sprint 5 batch-close revealed FollowerEntity client cannot spawn followers without Network → CrowdStateClient bridge. CRB 001 (mirror cache) closed Sprint 4 but 002-005 never scheduled. 002+003 are minimum unblock for visual confirmation. CRB 004 (server transport phase machine) + 005 (bandwidth perf) deferred to Sprint 6.

### Nice to Have (0.5d / 4h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 5-19 | RL story-003 — Eliminated subscription + DC freeze (Sprint 4 backlog) | gameplay-programmer | 4h | 3-10 done, 3-8 done | story-003 ACs pass; freeze-on-DC matches MSM Snap-freeze contract |

**Nice to Have total: 4h ≈ 0.5d**

**Sprint planned total: 8.6d** (with CRB 002+003 scope-add; 0.6d over nominal 8d; absorbs into 2d buffer — net 1.4d buffer remaining)

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| 4-13 CSM story-005 | Promoted Sprint 4 should-have → Sprint 5 should-have (5-17) | 4h |
| 4-14 MSM story-007 | Promoted Sprint 4 should-have → Sprint 5 should-have (5-18) — Selene Condition 2 still open | 4h |
| 4-15 RL story-003 | Promoted Sprint 4 should-have → Sprint 5 nice-to-have (5-19) | 4h |
| 4-16 TickOrch story-005 | **Dropped from Sprint 5** — disabled-mode instrumentation hook deferred to Sprint 6+ (no MVP gameplay impact) | — |

Total carryover: 1.5d (3 stories rolled forward; 2 should-have, 1 nice-to-have; 1 dropped).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| 14 must-have stories spanning 2 epics — throughput risk | Medium | High | NPC + Absorb are dependency-coupled (Absorb consumes `NPCSpawner.getAllActiveNPCs` + `reclaim`). Critical path is serial: 5-1 → 5-2/5-3 → 5-10..5-14. Stories 5-4 / 5-6 / 5-8 parallelizable after 5-1. Drop 5-15 (Absorb V/F) to nice-to-have if velocity slips at 5-12. |
| ADR-0008 Accepted but no implementation dry-run | Medium | High | Story 5-1 (pool bootstrap) is integration-test-heavy; failures surface design assumptions before stories 5-2..5-9 commit. Pivot 5-9 (UREvent broadcast) to should-have if A8 reveals replication-channel gaps. |
| Phase 3 Absorb couples with NPC + CSM simultaneously | Medium | Medium | Story 5-10 (callback skeleton) lands before any NPC consumer touches Phase 3. Mock-spawner fixture sufficient for 5-10/5-11 unit close; full integration via 5-12. |
| UREvent bandwidth ceiling untested at 60 NPCs × 8 crowds | Low | Medium | ADR-0001 ceiling reused per ADR-0008 amendment. Soak via 5-16 perf budget mid-sprint catches bandwidth blowup before Sprint 6 collision-resolution adds peel buffer to UREvent. |
| Vertical Slice still not playable post-Sprint 5 (chest/relic/collision deferred) | High | Low | Expected — Sprint 5 unblocks gameplay loop spine only. Sprint 6 picks up CCR + Chest + Relic to close vertical slice. |

## Dependencies on External Factors

- ADR-0008 Accepted (verified Sprint 4 close) ✓
- ADR-0002 Phase 3 hook live (Sprint 3 closed) ✓
- ADR-0010 4-Check Guard Accepted (story 5-18 prerequisite — re-verify if not yet Accepted)
- CSM `getAllCrowdPositions` API live (Sprint 3 closed) ✓
- RL `createAll`/`destroyAll` hooks live (Sprint 3 closed) ✓

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (14 stories — closes NPCSpawner epic + Absorb Logic core)
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists at `production/qa/qa-plan-sprint-5-[date].md` (run `/qa-plan sprint` at sprint start)
- [ ] All Logic stories have passing unit tests; Integration stories have passing integration tests
- [ ] Story 5-16 (if landed) produces perf evidence doc at `production/qa/evidence/absorb-perf-phase3-[date].md`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Selene Condition 2 (carry-forward warnings on `MSM/init.luau`) resolved via 5-18
- [ ] Code reviewed and merged (lean mode: per-story review + sprint close-out aggregate)

## Notes

- NPCSpawner epic closes this sprint pending all 9 stories. Absorb epic Logic core (stories 1-5) closes; V/F (6) and perf-soak (7) deferred to should-have buffer.
- Sprint 5 burns 3 of 4 Sprint 4 backlog stories (TickOrch instrumentation drops to Sprint 6+).
- Vertical Slice still not playable post-Sprint 5 — chest payment / relic grant / crowd-vs-crowd collision pending Sprint 6.
- Sprint 6 candidates: CrowdCollisionResolution (11 stories) + ChestSystem (11 stories) + RelicSystem (11 stories) — far exceeds single-sprint capacity. Sprint 6 plan likely splits into Sprint 6 (CCR + Chest core) + Sprint 7 (Relic + presentation layer scaffold).
- Lean mode: PR-SPRINT producer gate skipped; QL-STORY-READY skipped for stories already validated by `/story-readiness all`.

> **Scope check**: All 19 stories trace to existing epics + ADRs. Run `/scope-check npc-spawner` and `/scope-check absorb-system` mid-sprint to detect any drift before Sprint 6 plan.
