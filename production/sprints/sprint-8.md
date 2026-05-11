# Sprint 8 — 2026-05-12 to 2026-05-25 (Chest + Relic MVP Framework)

> **Status**: Draft
> **Review Mode**: lean
> **Milestone**: Production phase blocker #1 — close 2 of 7 missing MVP gameplay systems
> **Previous Sprint**: Sprint 7 — APPROVED (Sprint 6 carry-forwards closed, BUG-001 + BUG-002 closed)
> **Gate Status**: Production → Polish gate FAIL 2026-05-11; this sprint addresses blocker #1 (MVP gameplay impl) partially

## Sprint Goal

Land end-to-end first chest interaction in `src/`: chest spawns from CollectionService tag, proximity prompt fires guarded by 4-Check, atomic claim resolves contention, toll deducts from CSM count, relic registry grants a reference relic to the player slot state, hook dispatcher fires the relic's onAbsorb / onTick / onChestOpen callbacks. Drive Surge (first runnable reference relic) live. Close 2 of 7 missing MVP gameplay systems flagged in 2026-05-11 gate check.

## Capacity

- Sprint length: 10 working days (2 weeks, solo dev)
- Buffer (20%): 2 days for unplanned work / blockers
- Available: 8 days (64h)

## Tasks

### Must Have (Critical Path — 4.1d / 33h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 8-1 | **Chest story-001** — spawn from CollectionService tag + ProximityPrompt component | gameplay-programmer | 3h | chest-system epic | story-001 ACs pass; chest Parts tagged `ChestT1`/`ChestT2` spawn with `ChestComponent` attached |
| 8-2 | **Chest story-002** — RemoteValidator 4-Check guard pipeline (Identity / State Active / Parameters chestId+tier / Rate) | gameplay-programmer | 3h | 8-1, ADR-0010 | story-002 ACs pass; malformed payloads silently rejected via RemoteValidator |
| 8-3 | **Chest story-003** — open exclusivity (one chest per player per round; chest exclusive to one opener at a time) | gameplay-programmer | 2h | 8-2 | story-003 ACs pass |
| 8-4 | **Chest story-004** — F1 base toll formula `base_toll_scaled(tier, count) = max(T_FLAT, ceil(count × T_PCT))` | gameplay-programmer | 2h | 8-3 | story-004 ACs pass; toll values match GDD F1 table |
| 8-5 | **Chest story-006** — atomic claim TickOrchestrator Phase 4 (drains Pillar 3 race) | gameplay-programmer | 3h | 8-3 | story-006 ACs pass; single-tick contention resolves to one opener; rest receive silent reject |
| 8-6 | **Chest story-009** — destroyAll cleanup + Janitor disposal in Round teardown | gameplay-programmer | 3h | 8-1 | story-009 ACs pass; T9 round-end clears all chest components |
| 8-7 | **Relic story-001** — registry + 3 reference relics (TollBreaker / Surge / Wingspan) authoring | gameplay-programmer | 3h | relic-system epic | story-001 ACs pass; registry exposes `getRelicById` + 3 entries |
| 8-8 | **Relic story-002** — grant atomic + per-player slot state (max 3 slots MVP) | gameplay-programmer | 4h | 8-7 | story-002 ACs pass; grant idempotent, slot-full reject path covered |
| 8-9 | **Relic story-003** — hook dispatch (onAbsorb / onTick / onChestOpen / onRoundEnd) | gameplay-programmer | 3h | 8-8 | story-003 ACs pass; hooks fire in TickOrchestrator Phase 2 ordering |
| 8-10 | **Relic story-008** — clearAll + DC flush on PlayerRemoving + Round teardown | gameplay-programmer | 3h | 8-8 | story-008 ACs pass; relic state cleared on DC + T9 |
| 8-11 | **Relic story-011** — Sounds.luau template stub deletion + Selene rule for relic ID magic strings | gameplay-programmer | 1h | 8-7 | story-011 ACs pass; selene src/ clean |
| 8-12 | **Relic story-004** — Surge count relic (first runnable reference; +N count/tick) | gameplay-programmer | 3h | 8-9 | story-004 ACs pass; Surge granted → CSM count grows at relic tick rate |

**Must Have total: 33h ≈ 4.1d**

### Should Have (2.0d / 16h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 8-13 | Absorb story-007 — Perf soak 3600 overlap p99 ≤ 1.5ms (Sprint 5/6/7 carry — 4th carry) | gameplay-programmer | 3h | 7-1 | story-007 ACs pass; evidence doc with timing histogram |
| 8-14 | TickOrch story-005 — per-phase os.clock instrumentation (Sprint 4/5/6/7 carry — 5th carry; PROMOTE to must-have if slipping again) | gameplay-programmer | 4h | TickOrch | story-005 ACs pass; disabled-mode overhead < 0.05ms |
| 8-15 | Sprint 7 retrospective (Sprint 7 should-have carry → 8) | producer | 3h | none | doc covers: 11/11 must-have closeout velocity; BUG-001/002 closure approach; carry-forward pattern persisting 4 sprints |
| 8-16 | Chest story-007 — draft roll RNG + entropy seed (relic candidates per chest open) | gameplay-programmer | 3h | 8-12 | story-007 ACs pass; same seed produces same roll (determinism for replay) |
| 8-17 | Chest story-008 — DraftOpened/DraftSelected/DraftTimeout remotes + 10s server-side timeout | gameplay-programmer | 3h | 8-16 | story-008 ACs pass; client UX gracefully handles timeout |

**Should Have total: 16h ≈ 2.0d**

### Nice to Have (1.1d / 9h)

| ID | Task | Owner | Est. | Deps | Acceptance Criteria |
|----|------|-------|------|------|---------------------|
| 8-18 | Relic story-005 — Wingspan radius multiplier composition (CSM Batch 1 recomputeRadius API consumer) | gameplay-programmer | 3h | 8-9 | story-005 ACs pass; μ_max=1.5 cap enforced; radius_from_count × μ composed |
| 8-19 | Relic story-006 — TollBreaker non-state modifier (toll discount, not CSM state) | gameplay-programmer | 3h | 8-9 | story-006 ACs pass; toll discount applies at chest open without touching CSM |
| 8-20 | Relic story-007 — broadcast private slot state (per-player relevance; no opponent leaks) | gameplay-programmer | 3h | 8-8 | story-007 ACs pass; relic slot state visible only to owning player client |

**Nice to Have total: 9h ≈ 1.1d**

**Sprint planned total: 7.2d** (within 8-day capacity, 0.8d slack)

## Carryover from Previous Sprints

| Task | Reason | New Estimate |
|------|--------|--------------|
| 7-12 Absorb perf soak | Sprint 5/6/7 should-have backlog → 8-13 should-have (4th carry) | 3h |
| 7-13 TickOrch instrumentation | Sprint 4/5/6/7 should-have backlog → 8-14 should-have (5th carry — PROMOTE if slips) | 4h |
| 7-15 Sprint 7 retrospective | Sprint 7 should-have backlog → 8-15 should-have | 3h |
| 7-16 Chest skeleton | Sprint 7 nice-to-have → promoted into 8-1..8-6 must-have critical path | full epic |
| 7-17 Relic skeleton | Sprint 7 nice-to-have → promoted into 8-7..8-12 must-have critical path | full epic |

3 of 5 carry-forwards are should-have items repeatedly deprioritized by must-have growth. 7-14 (TickOrch instrumentation) is the 5th carry — flagged in retrospective. If it slips Sprint 8, promote to must-have in Sprint 9.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Chest 4-Check + atomic claim more complex than 5h combined (RemoteValidator integration, TickOrch Phase 4 wiring, race resolution) | Medium | High | 8-2 + 8-5 time-boxed to 6h total. If 8-5 atomic claim blocked, ship per-tick single-claim simple-path; multi-claim Phase 4 contention deferred to Sprint 9 |
| Relic hook dispatch ordering conflicts with TickOrchestrator Phase 2 (ADR-0002 static sequence) | Medium | Medium | 8-9 ACs lock dispatch order before impl; if conflict, ADR-0002 amendment via /architecture-decision before proceeding |
| Surge relic + CSM count growth interferes with Absorb F4 grace rescue math (DSN-B-MATH deferred decision still open) | Low | Medium | 8-12 acceptance: Surge is bounded ≤ relic tick rate cap; F4 math interaction tracked as separate playtest finding next sprint |
| Sprint 5/6/7 carry-forwards (8-13/8-14) continue slipping | High | Low | Accept defer is OK; 5th carry of TickOrch → promote to must-have Sprint 9 |
| Relic slot UI not designed for MVP — relics granted but invisible to player | High | Medium | Relic slot HUD widget deferred to Sprint 9 with HUD impl; 8-20 broadcasts state but UI consumer is stub |

## Dependencies on External Factors

- Chest System GDD + epic stories Ready ✓
- Relic System GDD + epic stories Ready ✓
- ADR-0010 RemoteValidator Accepted ✓
- ADR-0002 TickOrchestrator Phase 4 contract Accepted ✓
- ADR-0011 PlayerData schema Accepted (Pillar 3 forbidden-keys audit) ✓
- CSM Batch 1 amendment landed (recomputeRadius API for 8-18) ✓
- HUD widget impl deferred to Sprint 9 — Sprint 8 relics granted but not rendered

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed (12 tasks)
- [ ] First end-to-end chest interaction works in Studio: spawn → prompt → guard → claim → toll → relic grant → Surge tick effect visible via CSM count growth
- [ ] Chest System + Relic System modules under `src/ServerStorage/Source/` with passing unit tests
- [ ] Selene clean, audit scripts clean
- [ ] Sprint 7 retrospective documented
- [ ] Sprint 8 smoke check PASS WITH WARNINGS or better
- [ ] QA sign-off APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1/S2 bugs open

## Notes

- After Sprint 8: 2 of 7 missing MVP gameplay systems closed (Chest + Relic). 5 remaining (HUD widgets, Player Nameplate, VFX Manager, Chest Billboard, Follower LOD Manager) sequence into Sprint 9.
- Sprint 9 candidate scope: HUD widget impl (count/timer/relic-shelf/leaderboard) + Player Nameplate diegetic BillboardGui + VFX Manager core (AbsorbSnap + chest open + relic pickup VFX).
- Sprint 10 candidate: Vertical Slice playtest cycle — set up `production/playtests/` template + run 3 structured sessions covering new-player / mid-game / difficulty curve. Validates fun hypothesis. First valid Production→Polish gate retry.
- /qa-plan sprint MUST run before implementation begins. Repeating Sprint 6 mistake of skipping QA plan would re-introduce BUG-001 class regression risk.
- Sprint 7 carried 5 forwards; Sprint 8 carries 3. Pattern: must-have always grows by ~40%. Acceptable while bug-triage debt is paying down, but watch for it.

QA Plan: NOT YET CREATED — run `/qa-plan sprint` before starting 8-1.
