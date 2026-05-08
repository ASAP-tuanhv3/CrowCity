# Sprint 6 — 2026-05-09 to 2026-05-22 (Vertical Slice Polish + CCR Open)

> **Status**: Draft
> **Review Mode**: lean
> **Milestone**: Vertical Slice Foundation (gate-check Production → Polish blocker)
> **Previous Sprint**: Sprint 5 NPC + Absorb Spine — APPROVED WITH CONDITIONS, vertical slice playable

## Sprint Goal

Close the visualization → gameplay loop in the vertical slice: walking into NPCs visibly grows the crowd. Open CrowdCollisionResolution epic for crowd-vs-crowd peel. Replace Sprint 5 dev hacks (auto-round, client HRP prediction) with production drivers. Fix Sprint 5 test infra gaps.

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Buffer (20%): 2 days reserved for unplanned work / blockers
- Available: 8 days (64h)

## Tasks

### Must Have (Critical Path — 5.4d / 43h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 6-1 | Client cap-grow on broadcast count delta — observe CSM count change → setPoolSize | gameplay-programmer | 4h | Sprint 5 5-14 | walking into NPC absorbs + new follower fades in (visible end-to-end loop) |
| 6-2 | MSM Lobby→Round timer — replace auto-round-on-first-PlayerAdded hack | gameplay-programmer | 4h | MSM existing state machine | Sprint 6 ADR-0005 §Timer canonical; auto-start removed from start.server.luau |
| 6-3 | Sprint 5 follow-up: NPC test infra cleanup (6 failures) — pool isolation + CSM mock injection | gameplay-programmer | 3h | tests/unit/npc-spawner/* | TestEZ runs pass at 717+/717+ (Sprint 5 baseline + Sprint 6 additions) |
| 6-4 | CRB story-004 — Server transport phase machine (Dormant → Active → Closing) | gameplay-programmer | 5h | Phase 8 wiring done Sprint 5 | broadcastAll skips during Lobby; flushes once on Round start; idempotent on Closing |
| 6-5 | CCR story-001 — Phase 1 callback skeleton + DI scaffold | gameplay-programmer | 3h | TickOrch Phase 1 done | story-001 ACs pass; callback registered; no-op when no active crowds |
| 6-6 | CCR story-002 — Pair iteration + overlap test (sweep-prune optional) | gameplay-programmer | 5h | 6-5 | story-002 ACs pass; O(n²) crowd pair iteration; overlap by sum of radii |
| 6-7 | CCR story-003 — Drip math (count delta per overlap) | gameplay-programmer | 4h | 6-6 | story-003 ACs pass; count change per tick within design bounds |
| 6-8 | CCR story-004 — Skip conditions (same hue, eliminated, grace) | gameplay-programmer | 3h | 6-6 | story-004 ACs pass; same-hue / Eliminated skips silent |
| 6-9 | CCR story-005 — Overlap bit feed + setStillOverlapping per crowd | gameplay-programmer | 3h | 6-6, CSM setStillOverlapping | story-005 ACs pass; per-crowd overlapping flag updates per tick |
| 6-10 | CSM story-005 follow-up — full F2 position lag + nil-HRP guard tests | gameplay-programmer | 3h | Sprint 5 minimal lag landed | story-005 AC-7/19 tests pass; configurable lag constant |
| 6-11 | NPCSpawner story-009 follow-up — DI hooks for Network/Players | gameplay-programmer | 3h | existing test gap | end-to-end UREvent integration test passes (was deferred Sprint 5) |
| 6-12 | Smoke check + manual playtest closing the visual loop | qa | 3h | 6-1 | crowd grows visibly on NPC absorb; followers + NPCs replicate; player movement smooth |

**Must Have total: 43h ≈ 5.4d**

### Should Have (1.5d / 12h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 6-13 | Absorb story-006 — V/A consumers VFX AbsorbSnap + audio batching (Sprint 5 carry) | gameplay-programmer | 4h | 6-1 | story-006 ACs pass |
| 6-14 | MSM story-007 — broadcast Participation + AFKToggle 4-Check (Sprint 5 carry) | gameplay-programmer | 4h | 3-9 done | story-007 ACs pass; resolves Selene Condition 2 |
| 6-15 | RL story-003 — Eliminated subscription + DC freeze (Sprint 5 carry) | gameplay-programmer | 4h | 3-10, 3-8 | story-003 ACs pass |

**Should Have total: 12h ≈ 1.5d**

### Nice to Have (1.0d / 8h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 6-16 | Absorb story-007 — Perf soak 3600 overlap p99 ≤ 1.5ms (Sprint 5 carry) | gameplay-programmer | 3h | 6-1 | story-007 ACs pass; evidence doc |
| 6-17 | TickOrch story-005 — per-phase os.clock instrumentation | gameplay-programmer | 4h | 3-1 done | story-005 ACs pass; disabled-mode overhead < 0.05ms |

**Nice to Have total: 7h ≈ 0.9d**

**Sprint planned total: 7.8d** (within 8-day capacity, 0.2d slack)

## Carryover from Sprint 5

| Task | Reason | New Estimate |
|------|--------|--------------|
| 5-15 Absorb V/A consumers | Promoted Sprint 5 should-have → Sprint 6 should-have (6-13) | 4h |
| 5-16 Absorb perf soak | Promoted Sprint 5 should-have → Sprint 6 nice-to-have (6-16) | 3h |
| 5-18 MSM Participation | Promoted Sprint 5 should-have → Sprint 6 should-have (6-14) | 4h |
| 5-19 RL DC freeze | Promoted Sprint 5 nice-to-have → Sprint 6 should-have (6-15) | 4h |
| 4-16 TickOrch instrumentation | Promoted Sprint 4 nice-to-have → Sprint 6 nice-to-have (6-17) | 4h |

Sprint 5 minimal F2 (5-17) closed in-sprint; full test coverage as 6-10.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| CCR + CSM coupling — setStillOverlapping write rules | Medium | High | 6-9 lands the contract early; pair-test 6-9 against Sprint 5 NPC overlap before 6-7 finalizes drip math |
| Visual cap-grow trigger may need new design (count change → setPoolSize doesn't account for active spawns in flight) | Medium | Medium | 6-1 spec includes draining pending FadeIn before re-computing delta. Fall back to PerfFixture pattern if design doesn't converge in 4h |
| MSM timer requires wiring participants, AFK detection, ServerClosing — bigger scope than 4h | Medium | High | 6-2 must remain MVP-only (no AFK detection — Sprint 7 covers via 6-14). Time-box MSM Lobby→Round to a fixed 30s lobby timer with no participant validation |
| 6 NPC test failures may reveal deeper isolation issues than expected | Low | Medium | Time-box 6-3 to 3h; if root cause requires source changes, defer to Sprint 7 + document as known-issue |

## Dependencies on External Factors

- ADR-0005 Match State Machine + ADR-0011 Persistence Schema both Accepted ✓
- CSM `setStillOverlapping` API live (Sprint 3) ✓
- TickOrch Phase 1 callback slot ✓
- Sprint 5 visualization unblock work all merged ✓

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (12 tasks)
- [ ] Visual absorb loop confirmed end-to-end in Studio Playtest (6-1 + 6-12)
- [ ] CCR epic 5 stories closed (6-5..6-9)
- [ ] CSM Story 005 full coverage (6-10)
- [ ] NPCSpawner Story 009 full coverage (6-11)
- [ ] Auto-round dev hack removed (6-2)
- [ ] All Sprint 5 test infra failures resolved (6-3)
- [ ] Smoke check passed
- [ ] QA sign-off APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1/S2 bugs

## Notes

- After Sprint 6 lands CCR + Visual absorb loop, Sprint 7 candidates: Chest System (11 stories) + Relic System (11 stories) + Presentation epic creation (HUD, PlayerNameplate, ChestBillboard).
- Per Sprint 5 retrospective action item: each visible feature in this sprint includes a "demo path" trace. 6-1 demo path: walk into NPC → server overlap → updateCount → broadcast → client setPoolSize → spawnFadeInAtCenter → bundle visible.
- Sprint 5 retrospective + sign-off: `production/retrospectives/sprint-5-retrospective.md` + `production/qa/qa-signoff-sprint-5-2026-05-08.md`
