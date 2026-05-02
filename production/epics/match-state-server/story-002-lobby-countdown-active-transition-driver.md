# Story 002: Lobby → Countdown:Ready → Countdown:Snap → Active transition driver + countdown timer

> **Epic**: match-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §States/Transitions T1-T5 + §Formulas/F1+F5
**Requirement**: `TR-msm-001`, `TR-msm-002`, `TR-msm-003` (per-state timer), `TR-msm-008` (driver set)
**ADR**: ADR-0005 §Decision (T1-T5 transitions + 7-second countdown:Ready + 3-second countdown:Snap = 10s total); ADR-0002 §Phase 6 (timer check is Phase 6, but only T7 from Active; pre-Active timer driver runs on a non-tick-phase code path or is folded into a polling check).
**ADR Decision Summary**: Lobby → Ready when participation count ≥ 2. Ready → Lobby revert when participation count drops to 1 (F5). Ready → Snap when 7.0s elapsed (countdownTotal=10, snapAt=3). Snap → Active when timer fires (10.0s elapsed total) AND ≥1 participating. Snap → Result when timer fires AND zero participating (everyone AFK'd out).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: timer polling via `os.clock()` in Phase 6 hook OR via dedicated `RunService.Heartbeat` listener (decision: fold into Phase 6 timerCheck for unified ownership; manifest L96 already lists Phase 6 as MSM `timerCheck`).

**Control Manifest Rules (Core layer)**:
- Required: MIN_PLAYERS_TO_START=2 (L105); ADR-0005 timer durations.

---

## Acceptance Criteria

- [ ] **AC-4 (Lobby → Ready)** — Lobby with 1 participant; second player sets flag TRUE; transition to `Countdown:Ready` in ≤67ms; broadcast `{state: "Countdown:Ready", meta: {countdownTotal: 10}}`.
- [ ] **AC-5 (Ready → Lobby revert)** — `Countdown:Ready` elapsed <7s; participation count drops to 1 (player DC or AFK toggle); state reverts to `Lobby` within one tick.
- [ ] **AC-6 (Ready → Snap)** — `Countdown:Ready` with `#participating ≥ 2`; elapsed ≥ 7.0s; transitions to `Countdown:Snap`. Max observed elapsed ≤ 7.067s at 15 Hz.
- [ ] **AC-7 (Snap → Active with participants)** — `Countdown:Snap`, t=10s total, `#participating ≥ 1`; timer fires; mock call-order log records `[createAll, MatchStateChanged_broadcast]` in that sequence with no intervening entries. Infrastructure: gameplay-programmer provides `TestMatchStateBroadcastSpy` (spy-wraps `MatchStateChanged:FireAllClients` and `RoundLifecycle.createAll`).
- [ ] **AC-8 (Snap → Result zero)** — `Countdown:Snap` with all flags FALSE before t=10s; timer fires; `RoundLifecycle.createAll` NOT called; state → `Result`; broadcast `meta.winnerId == nil`.
- [ ] `_transitionTo` honors per-state `_stateEndsAt` writes:
  - Lobby → Ready: `_stateEndsAt = now + 10.0` (countdownTotal)
  - Ready → Snap: `_stateEndsAt = now + 3.0` (snapDuration)
  - Snap → Active: `_stateEndsAt = now + 300.0` (round duration)
  - Snap → Result (zero participants): `_stateEndsAt = now + RESULT_DURATION_SEC`
- [ ] Pre-Active timer driver (Lobby/Ready/Snap timers) folded into Phase 6 `timerCheck` callback so single timer code path. Phase 6 in pre-Active states checks elapsed against `_stateEndsAt` and triggers the appropriate transition. Phase 7 elimination consumer is no-op in pre-Active states.

---

## Implementation Notes

- Lobby → Ready trigger: detect via `_setParticipation` (story-001) post-write — when count ≥ 2 AND `_state == "Lobby"` → `_transitionTo("Countdown:Ready")`.
- Ready → Lobby revert: similar — on `_setParticipation` post-write (or PlayerRemoving) — if count < 2 AND `_state == "Countdown:Ready"` → `_transitionTo("Lobby")`. Also explicit check on tick for robustness.
- F5 revert formula: `should_revert = (_state == "Countdown:Ready") AND (#_participating < MIN_PLAYERS_TO_START)`.
- Timer firings via Phase 6 `timerCheck`: `if _state == "Countdown:Ready" AND elapsed >= 7.0 → _transitionTo("Countdown:Snap")`; `if _state == "Countdown:Snap" AND elapsed >= 3.0 → handleSnapToActiveOrResult()`.
- `handleSnapToActiveOrResult()`:
  - count `_participating == 0` → `_transitionTo("Result")` with `_winnerId = nil` (RoundLifecycle.createAll skipped per AC-8)
  - count ≥ 1 → call `RoundLifecycle.createAll(participatingPlayers)` SYNCHRONOUSLY THEN `_transitionTo("Active")` (per AC-7 ordering log)
- ≤67 ms transition latency for AC-4: trigger fires inside `_setParticipation`'s same-frame call path (synchronous transition); broadcast happens inside `_transitionTo` body in story-007.
- Until story-007 ships, `_transitionTo` only writes state/timestamps. Tests in this story drive transitions and assert state field, not broadcasts.

---

## Out of Scope

- story-001: state field, participation table.
- story-003..006: timer T7 / T8 / T6 / T9 / BindToClose paths.
- story-007: actual MatchStateChanged broadcast (this story's tests spy on a stubbed broadcast hook OR use `TestMatchStateBroadcastSpy` interface).
- RoundLifecycle epic: `RoundLifecycle.createAll` real implementation. Use stub `RoundLifecycleStub.createAll` here.

---

## QA Test Cases

- **AC-4**: Lobby with 1 participant. `_setParticipation(playerB, true)` (count → 2). Assert `_state == "Countdown:Ready"` within 67ms (single synchronous call path). Spy: `MatchStateChanged_broadcast` called with `{state="Countdown:Ready", meta={countdownTotal=10}}`.
- **AC-5**: Force state `Countdown:Ready` w/ 2 participants. `_setParticipation(playerA, false)` (count → 1). Assert state reverts to `"Lobby"` within one tick. Edge: PlayerRemoving on B mid-Ready → revert.
- **AC-6**: Force state `Countdown:Ready` w/ 2 participants. Mock clock advance 7.0s. Phase 6 timerCheck fires. Assert state `Countdown:Snap`. Edge: 7.067s (one Heartbeat past) acceptable.
- **AC-7**: Force state `Countdown:Snap` w/ 1 participant. Mock clock advance 3.0s (10.0s total). Phase 6 timerCheck. `TestMatchStateBroadcastSpy` log shows `[createAll, broadcast("Active")]` in order, no other entries. Edge: 2 participants → `createAll` called once with both.
- **AC-8**: Force state `Countdown:Snap` w/ 0 participants (all AFK'd out post-Ready→Snap freeze loophole? — actually Snap freezes flags but FALSE→TRUE allowed; flags can also start FALSE if joined late). Mock clock advance 10s total. Phase 6 timerCheck. `RoundLifecycle.createAll` NOT called; spy log shows only `[broadcast("Result", meta={winnerId=nil})]`.
- **Timer determinism**: `os.clock` mocked; replay 10 runs of Lobby→Ready→Snap→Active deterministic.

---

## Test Evidence

`tests/unit/match-state-server/transition_lobby_ready.spec.luau` + `tests/unit/match-state-server/transition_ready_snap.spec.luau` + `tests/integration/match-state-server/snap_to_active_call_order.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (state + participation), tick-orchestrator story-001 (Phase 6 hook stub at boot)
- Unlocks: story-003 (Phase 6 timerCheck T7 reuses same hook), story-005 (T9 destroyAll → Intermission ordering uses _transitionTo), story-007 (broadcast wiring)

---

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: AC-4 (Lobby→Ready), AC-5 (F5 revert via flag drop + PlayerRemoving), AC-6 (Ready→Snap @ 7s), AC-7 (Snap→Active createAll-before-state-write), AC-8 (Snap→Result zero participants) all covered (13 it blocks across 3 specs).
**Test result**: 245/0/0 headless (+13 from 3-6)
**Files modified**: src/ServerStorage/Source/MatchStateServer/init.luau (+RoundLifecycle import + MIN_PLAYERS_TO_START/COUNTDOWN_*/ROUND_DURATION/RESULT_DURATION constants + _participatingPlayers helper + T1/F5 driver in _setParticipation + PlayerRemoving F5 mirror + timerCheck Phase 6 public API + _setRoundLifecycleOverride + _setPlayerResolverForTests + _setStateEndsAtForTests test hooks)
**Test files created**: tests/unit/match-state-server/transition_lobby_ready.spec.luau + transition_ready_snap.spec.luau + tests/integration/match-state-server/snap_to_active_call_order.spec.luau
**Deviations**: ADVISORY — `_stateEndsAt` test hook (`_setStateEndsAtForTests`) added to enable mocking timer expiry without real-time waits (TestEZ blocks task.wait). Required for AC-6/7/8 timerCheck verification.
**Lint**: pre-existing 2 selene warnings on `Network` + `RemoteEventName` imports (story-001 reserved these for story-007 AFKToggle wiring; not regression). MSM init currently selene 0 errors / 2 pre-existing warnings.
