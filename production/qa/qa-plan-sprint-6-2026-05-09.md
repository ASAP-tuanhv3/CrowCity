# Sprint 6 QA Plan — 2026-05-09

> Authored as part of `/team-qa sprint` retroactive close-out. Sprint ran without
> a leading QA plan; this doc captures classification + entry/exit criteria so
> the sign-off has a recorded scope contract.

## Scope

- **Sprint**: sprint-6
- **Sprint window**: 2026-05-09 → 2026-05-22 (closed early — all must-haves done 2026-05-09)
- **Goal**: Close visualization → gameplay loop in vertical slice (NPC absorb visibly grows crowd). Open CrowdCollisionResolution epic for crowd-vs-crowd peel. Replace Sprint 5 dev hacks with production drivers. Fix Sprint 5 test infra gaps.
- **Stories in scope**: 12 must-have (6-1 through 6-12) — all `done` per `production/sprint-status.yaml`
- **Stories out of scope**: 6-13 → 6-17 (5 should-have / nice-to-have, all `backlog`, carry-forward)

## Story Classification

| Story | Title | Type | Auto Test Required | Manual QA Required | Test Evidence Path | Blocker? |
|-------|-------|------|--------------------|--------------------|--------------------|----------|
| 6-1 | Client cap-grow on broadcast count delta | Integration + Visual/Feel | Yes | Yes (visual loop) | `tests/unit/follower-entity/cap_grow_on_count_delta.spec.luau` (7 it) | None |
| 6-2 | MSM Lobby→Round timer (replace dev hack) | Logic + Integration | Yes | No | `tests/unit/match-state-server/match_state_changed_server.spec.luau` (12 it) | None |
| 6-3 | NPC test infra cleanup | Logic (infra) | Yes | No | `tests/unit/npc-spawner/{respawn_pipeline,respawn_fade_in,idle_walk_boundary}.spec.luau` | Advisory: 11 follower-entity failures unchanged (out of 6-3 scope) |
| 6-4 | CRB story-004 server transport phase | Integration | Yes | No | `tests/integration/crowd-replication-broadcast/transport_phase_machine.spec.luau` | None |
| 6-5 | CCR story-001 Phase 1 skeleton + DI | Logic | Yes | No | `tests/unit/collision/phase1_skeleton.spec.luau` (15 it) | None |
| 6-6 | CCR story-002 pair iteration + overlap | Logic | Yes | No | `tests/unit/collision/pair_iteration_overlap.spec.luau` (18 it) | None |
| 6-7 | CCR story-003 drip math | Logic | Yes | No | `tests/unit/collision/drip_math.spec.luau` (19 it) | None |
| 6-8 | CCR story-004 skip conditions | Logic | Yes | No | `tests/unit/collision/skip_conditions.spec.luau` (16 it) | None |
| 6-9 | CCR story-005 overlap-bit feed | Logic | Yes | No | `tests/unit/collision/overlap_bit_feed.spec.luau` (17 it) | None |
| 6-10 | CSM story-005 follow-up F2 lag | Logic | Yes | No | `tests/unit/crowd-state-server/position_lag.spec.luau` (12 it) | None |
| 6-11 | NPCSpawner story-009 follow-up DI | Integration | Yes | No | `tests/integration/npc-spawner/urevent_replication.spec.luau` (21 it) | None — file rename `_test.luau` → `.spec.luau` enables TestEZ discovery |
| 6-12 | Smoke check + manual playtest | Config/Data + Visual/Feel | No | Yes | `production/qa/smoke-2026-05-08-sprint-6.md` + this re-smoke | None |

**Test evidence**: zero gaps for Logic/Integration types — all 10 specs exist at the expected paths.

## Automated Test Requirements

All Logic + Integration stories have automated `.spec.luau` evidence committed before sprint close. TestEZ headless runner: `rojo build test.project.json -o test-place.rbxl && run-in-roblox --place test-place.rbxl --script tests/runner.server.luau`.

## Manual QA Scope

**Session 1 — Visual absorb loop (BLOCKING for 6-1 + 6-12)**: ~1.5h. Studio Local Server, 2 clients. Verify: walk player into NPC cluster → server overlap → `updateCount` write → CSM Phase 8 broadcast → client `setPoolSize` → new follower fades in at crowd center → bundle visibly larger. Acceptance: no frame drops; crowd radius expands; ≥1 fade-in within 3 ticks of absorb.

**Session 2 — Regression + CCR observation (ADVISORY)**: ~1h. Verify: MSM Lobby → Countdown(7s) → Active timer fires correctly with 2 players (6-2 production driver). CCR Phase 1 runs without Luau warns during pair iteration / drip. NPC idle-walk + respawn intact post 6-3 infra cleanup.

## Out of Scope (Carry-Forward)

- 5 should-have / nice-to-have backlog items (6-13 Absorb V/A consumers, 6-14 MSM Participation broadcast, 6-15 RL Eliminated subscription + DC freeze, 6-16 Absorb perf soak 3600 overlap, 6-17 TickOrch per-phase os.clock)
- 11 pre-existing follower-entity integration failures (carry-forward tech debt — Sprint 7 candidate story)
- ADR-0008 amendment for `start.server.luau` NPCSpawner caller drift (tracked, deferred Sprint 7)
- `tests/smoke/critical-paths.md` Sprint 2-stale (refresh Sprint 7)

## Entry Criteria

- All must-have stories Status: Complete in story files + sprint-status.yaml ✓
- Re-smoke executed against current HEAD (post 6-1/6-3/6-10/6-11 commits) ✓
- All audit gates clean (selene, asset-id, persistence) ✓

## Exit Criteria

- All in-scope stories report PASS / PASS WITH NOTES / FAIL with bug filed
- QA sign-off doc authored at `production/qa/qa-signoff-sprint-6-2026-05-09.md`
- Verdict: APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED
- Conditions list (if any) tracked for Sprint 7 pickup

## Smoke Check Verdict

**Re-smoke 2026-05-09**: PASS WITH WARNINGS

Audits clean. TestEZ: 891 passed, 11 failed, 0 skipped — same 11 pre-existing follower-entity failures from baseline; **no new regressions** from 6-1 / 6-3 / 6-10 / 6-11 implementation commits.

Failure surface (all carry-forward, NOT Sprint 6 introductions):
- `tests/integration/follower-entity/crowd_manager_orchestrator.spec.luau` (3 failures)
- `tests/integration/follower-entity/wire_in_end_to_end.spec.luau` (4 failures)
- `tests/integration/follower-entity/wire_in_pool_integration.spec.luau` (4 failures)

Per Sprint 5 close-out precedent (APPROVED WITH CONDITIONS), the 11 carry-forward failures are eligible for the same treatment in Sprint 6 if a Sprint 7 tech-debt story is committed before close.
