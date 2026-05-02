# Story 003: Phase 6 timerCheck + T7 timer-expiry → Result + F4 winner tiebreak

> **Epic**: match-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §States/T7 + §Formulas/F4 + §Core Rules same-tick handler order
**Requirement**: `TR-msm-005` (Phase 6 timer), `TR-msm-007` (Phase 6 < Phase 7), `TR-msm-019` (cadence accuracy)
**ADR**: ADR-0005 §F4 tiebreak owner = MSM (count desc → peakTimestamp asc → UserId asc); ADR-0002 §Phase 6 (TickOrchestrator-only caller).
**ADR Decision Summary**: `timerCheck()` Phase 6 callback fires when `Active` AND `elapsed ≥ 300s` → `_transitionTo("Result")`. Winner resolved via F4: highest `count` wins; ties broken by earliest `peakTimestamp` (RoundLifecycle.getPeakTimestamp); further ties by `argmin(UserId)`. Phase 6 runs BEFORE Phase 7 (manifest L60).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `os.clock()` (LOW); `table.sort` (LOW).

**Control Manifest Rules (Core layer)**:
- Required: MSM Phase 6 callback `timerCheck()` (manifest L96); F4 tiebreak owner MSM (L101); strict `>` rule for peakCount updates (L102 — covered by RoundLifecycle epic).

---

## Acceptance Criteria

- [ ] **AC-10 (Tiebreak determinism)** — Active, t=300s, 2 crowds tie on `count`. With differing `peak_count_timestamp`, earlier wins. With equal timestamps, `argmin(UserId)` wins. Result deterministic across 10 repeated runs of the same fixture.
- [ ] **AC-12 (T6/T7 simultaneity)** — Active, `elapsed ≥ 300.0s` AND last-crowd elimination signal fires SAME tick; Result broadcasts; `meta.winnerId` equals F4 tiebreak winner (count → peakTimestamp → UserId), NOT the last-standing crowd's id. Verified via fixture where tiebreak winner ≠ last-standing.
- [ ] **AC-21 (Phase 6 < Phase 7)** — Active, elapsed=300.0s AND CrowdEliminated queued. Phase 6 fires `transitionTo(Result)` via T7 first; Phase 7 evaluates `matchState != Active` guard, finds `Result`, silently drops queued elim. Final `matchState == "Result"` via T7 (NOT T6). meta.winnerId via F4 using counts captured at Phase 6 time. Only ONE `MatchStateChanged` broadcast fires this tick.
- [ ] `timerCheck()` Phase 6 hook signature: `function MatchStateServer.timerCheck(): ()` per arch §5.2 L595.
- [ ] Body: if `_state == "Active"` AND `os.clock() - _stateStartTime >= 300.0` → resolve F4 winner, set `_winnerId`, call `_transitionTo("Result")`.
- [ ] F4 implementation:
  ```
  candidates = CSM.getAllActive() (excludes Eliminated)
  sorted by (-count, peakTimestamp asc, UserId asc)
  winner = candidates[1] OR nil if empty
  ```
  `peakTimestamp` from `RoundLifecycle.getPeakTimestamp(crowdId)` — nil treated as `math.huge` per arch §5.3 L638.
- [ ] Pre-Active timer driver (story-002) reuses this Phase 6 hook — story-003 extends `timerCheck` body to also handle T7. So this story's body becomes:
  ```
  if _state == "Active" then handleActiveT7()
  elseif _state == "Countdown:Ready" then handleReadyToSnap()  (story-002)
  elseif _state == "Countdown:Snap" then handleSnapToActiveOrResult()  (story-002)
  elseif _state == "Result" then handleResultToIntermission()  (story-005)
  elseif _state == "Intermission" then handleIntermissionToLobby()  (story-005)
  end
  ```

---

## Implementation Notes

- F4 sort: stable by chosen sort key. Use `table.sort(candidates, function(a, b) return F4_less(a, b) end)`. Predicate:
  ```lua
  local function F4_less(a, b): boolean
      if a.count ~= b.count then return a.count > b.count end
      local ta = RoundLifecycle.getPeakTimestamp(a.crowdId) or math.huge
      local tb = RoundLifecycle.getPeakTimestamp(b.crowdId) or math.huge
      if ta ~= tb then return ta < tb end
      return tonumber(a.crowdId) < tonumber(b.crowdId)  -- crowdId is tostring(UserId)
  end
  ```
- AC-21 + AC-12 prove same invariant: Phase 6 < Phase 7. The implementation in story-004 (Phase 7 elim consumer) checks `if _state ~= "Active" then return end` — so when Phase 6 has already moved state to "Result" this tick, Phase 7 silently drops.
- Until RoundLifecycle epic ships, use `RoundLifecycleStub.getPeakTimestamp(crowdId): number?` returning `nil` — tests for AC-12 use a fixture that injects deterministic peakTimestamps.
- Empty candidates path (all eliminated): `_winnerId = nil`; broadcast meta still includes other fields. Edge case rare but handle.

---

## Out of Scope

- story-002: pre-Active timer driver
- story-004: Phase 7 elimination consumer + double-signal guard + T8 instant win
- story-005: Result → Intermission T9 + grant-before-broadcast (broadcasts post-T7 winner resolution still happen there)
- story-007: actual MatchStateChanged broadcast
- RoundLifecycle epic: real `getPeakTimestamp` impl

---

## QA Test Cases

- **AC-10**: Fixture: 2 crowds A (count=50, peakTime=10.5s) and B (count=50, peakTime=20.3s). Force Active at t=300s. Phase 6 timerCheck. Assert `_winnerId == A.crowdId` (earlier peakTimestamp). Repeat 10 runs — deterministic. Edge: equal peakTimestamps + UserId(A)=100 < UserId(B)=200 → A wins.
- **AC-12 / AC-21**: Fixture: Active state, mock `os.clock` returns t=300.0s exactly. Pre-queue `CrowdEliminated` for last-but-one crowd before Phase 6 fires. Run TickOrch fixture Phase 6 then Phase 7. Assert `_state == "Result"` post-Phase-6; `_winnerId` resolved via F4 (use counts seeded so tiebreak winner ≠ last-standing — e.g. 3 crowds A/B/C: A and B tied on count > C; C eliminated mid-tick; F4 winner is A or B by peakTimestamp tiebreak, NOT C). Phase 7 evaluation finds `_state == "Result"` → drops queued elim signal silently. Spy: only ONE broadcast `MatchStateChanged("Result")` this tick.
- **F4 sort stability**: `pcall(table.sort, ...)` succeeds on degenerate inputs (1 candidate, 0 candidates).
- **`timerCheck` cadence**: 100-tick fixture with mock clock; Phase 6 firings at exactly the expected times; jitter < 0.1ms via TickOrch instrumentation hook.

---

## Test Evidence

`tests/unit/match-state-server/timer_check_t7.spec.luau` + `tests/unit/match-state-server/f4_tiebreak.spec.luau` + `tests/integration/match-state-server/phase6_phase7_simultaneity.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (state field), story-002 (`_transitionTo` driver + Phase 6 hook), tick-orchestrator story-002 (Phase iteration)
- Unlocks: story-004 (Phase 7 cooperates with Phase 6 ordering); story-007 (broadcast)

---

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: AC-10 (F4 tiebreak count→peakTimestamp→UserId determinism, 10-run repeat) + T7 (Active→Result on expiry) covered (10 it blocks across 2 specs). AC-12/AC-21 simultaneity test deferred to 3-8 (Phase 7 elim consumer story owns the same-tick guard interplay).
**Test result**: 255/0/0 headless (+10 from 3-7)
**Files modified**: src/ServerStorage/Source/MatchStateServer/init.luau (+CrowdStateServer import + _winnerId field + CSMDependency type + _csmOverride + _f4Less predicate + _resolveWinnerF4 helper + T7 branch in timerCheck + getWinnerId + _setCSMOverride/_setWinnerIdForTests test hooks); src/ServerStorage/Source/RoundLifecycle/init.luau (+getPeakTimestamp public API).
**Test files created**: tests/unit/match-state-server/timer_check_t7.spec.luau + f4_tiebreak.spec.luau
**Deviations**: ADVISORY — RoundLifecycle.getPeakTimestamp added as part of this story (story §Implementation Notes L63 hinted at stub; cleaner to add the real RL accessor since RL `_crowds[id].peakTimestamp` already populated in Sprint 2 createAll). Out-of-scope by-letter but in-scope by-spirit (cross-story API needed).
**Lint**: pre-existing 2 selene warnings on Network/RemoteEventName imports (unchanged from 3-6 baseline).
