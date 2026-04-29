# Story 008: Performance budget evidence — Phase 6 + Phase 7 < 0.1ms over 100 ticks

> **Epic**: match-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic / Performance
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §AC-19
**Requirement**: `TR-msm-018` (Phase 6/7 budget 0.1ms total)
**ADR**: ADR-0003 §Per-Tick CPU (Phase 6 0.05ms + Phase 7 0.05ms = 0.1ms total).
**ADR Decision Summary**: MSM contributes 0.1ms total per tick (Phase 6 + Phase 7 combined). Validated via 100-tick `tick()` delta measurement in TestEZ fixture.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `tick()` and `os.clock()` (LOW). TickOrch story-005 instrumentation hook re-used.

**Control Manifest Rules (Core layer)**:
- Performance: Phase 6 0.05ms; Phase 7 0.05ms; total per-tick budget 3.0ms (manifest L165-L166).

---

## Acceptance Criteria

- [ ] **AC-19 (Performance budget)** — Active at SERVER_TICK_HZ=15. MatchState processes one tick with no transition. Tick handler CPU time < 0.1ms. Verified via `tick()` delta over 100 consecutive ticks in TestEZ fixture. Mean < 0.1ms; max < 0.3ms (3× headroom for spikes).
- [ ] Test fixture seeds 12 active crowds in CSM mock (max realistic load). MSM Phase 6 + Phase 7 invoked sequentially via TickOrch fixture.
- [ ] Measurement methodology: capture `os.clock()` immediately before Phase 6 invocation and immediately after Phase 7 returns. Delta = MSM total per-tick CPU.
- [ ] Test runs over 100 consecutive simulated ticks (mock clock); records min/mean/max/p95.
- [ ] Pass criteria: `mean < 0.1ms` AND `max < 0.3ms` AND `p95 < 0.15ms`.
- [ ] Evidence document: `production/qa/evidence/msm-perf-budget-evidence.md` records the test run output (date, fixture description, mean/max/p95 values).
- [ ] Integration with TickOrch story-005 instrumentation hook is OPTIONAL — this story's TestEZ fixture can capture timings directly. However if TickOrch instrumentation is enabled in the same fixture, validate the per-phase split aligns (Phase 6 < 0.05ms, Phase 7 < 0.05ms individually).

---

## Implementation Notes

- TestEZ fixture pseudocode:
  ```lua
  it("MSM Phase 6 + Phase 7 budget < 0.1ms over 100 ticks", function()
      seed12CrowdsInCSMMock()
      mockMSMState("Active", 100.0)  -- mid-round
      local timings: { number } = {}
      for i = 1, 100 do
          local t0 = os.clock()
          MatchStateServer.timerCheck()
          MatchStateServer.eliminationConsumer()
          local t1 = os.clock()
          table.insert(timings, t1 - t0)
      end
      local mean, max, p95 = computeStats(timings)
      expect(mean).to.be.lessThan(0.0001)  -- 0.1ms
      expect(max).to.be.lessThan(0.0003)
      expect(p95).to.be.lessThan(0.00015)
  end)
  ```
- 100 ticks at 15 Hz mock clock means ~6.67s of simulated time. No actual `task.wait` — pure synchronous fixture.
- Edge cases the fixture exercises: (a) no transition tick; (b) transition tick (T7 fires); (c) transition + drained elims (mixed Phase 6/7 work). All three should fit budget.
- If a measurement run fails, the failure mode is documented in the evidence doc with proposed optimization (e.g. `_pendingElims` table reuse, F4 sort allocation reduction) deferred to a follow-up perf story.

---

## Out of Scope

- TickOrch story-005: instrumentation hook itself.
- ADR-0003 §Validation Sprint Plan: full multi-client mobile soak — separate sprint task post-Core.
- story-001..007: implementation; this story validates the assembled module's performance.

---

## QA Test Cases

- **AC-19 happy path**: Active state, 12 crowds, no pending elim signals. 100 ticks. Pass criteria above.
- **AC-19 transition tick**: Same fixture but tick 50 forces T7 (mock clock at 300s). Phase 6 fires transitionTo("Result"); Phase 7 short-circuits via state-guard. Total tick CPU still < 0.3ms even on transition tick.
- **AC-19 drain tick**: Force 12 queued `_pendingElims` (extreme — should be impossible in real game; tests robustness). Phase 7 drains all 12. Tick CPU should still fit budget.
- **Edge case — F4 with 12 candidates**: Phase 6 T7 path with 12 active crowds; F4 sort over 12 candidates < 0.05ms (table.sort O(N log N) on ≤12 = trivial).

---

## Test Evidence

`tests/unit/match-state-server/perf_budget.spec.luau` + `production/qa/evidence/msm-perf-budget-evidence.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..007 (full module assembled); TickOrch story-005 (optional instrumentation cross-check)
- Unlocks: gate-check Pre-Production → Production re-evaluation
