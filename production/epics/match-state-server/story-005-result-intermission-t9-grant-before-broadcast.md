# Story 005: Result → Intermission (T9) + grant-before-broadcast invariant + flag reset (T10)

> **Epic**: match-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §States/T9-T10 + §Edge Cases/Currency grant edges
**Requirement**: `TR-msm-017` (grant-before-broadcast invariant)
**ADR**: ADR-0005 §Result-entry ordering invariant + §T9 ordering invariant; ADR-0011 §Coins grant only at MSM Result entry.
**ADR Decision Summary**: Result entry ordering: `_winnerId resolved → RoundLifecycle.setWinner → getPlacements → Currency.grantMatchRewards → MatchStateChanged("Result", meta) broadcast` — grants commit BEFORE any client receives state. T9 (Result → Intermission) ordering: `RoundLifecycle.destroyAll() → RelicSystem.clearAll() → MatchStateChanged("Intermission") broadcast` — clients must not observe Intermission before server cleanup. T10 (Intermission → Lobby) at 10s: reset all participation flags to TRUE.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Reliable RemoteEvent + sequential calls (LOW).

**Control Manifest Rules (Core layer)**:
- Required: T9 ordering invariant (manifest L98); Result-entry ordering invariant (L99); InternalPlacement strip rule (L100); Coins grant only at MSM Result entry (L126).
- Forbidden: Never grant currency mid-round (L142); never grant during BindToClose (L142).

---

## Acceptance Criteria

- [ ] **AC-14 (T9 ordering)** — `Result`, 10s elapsed; timer fires; mocked sequence log records `[destroyAll, clearAll, broadcast_Intermission]` in that order with no inversions.
- [ ] **AC-15 (Flag reset T10)** — `Intermission` with some flags FALSE; 10s elapses; `getParticipation(p) == TRUE` for every connected player; state = `Lobby`.
- [ ] **AC-20 (Result-entry grant ordering)** — `Active` exits via T6, T7, or T8; `Active` → `Result` transition fires; `TestMatchStateBroadcastSpy` log records `[grantMatchRewards, MatchStateChanged_broadcast("Result")]` in sequence — grant commits before any client receives `Result`.
- [ ] `_transitionTo("Result", meta)` body order:
  1. `RoundLifecycle.setWinner(_winnerId)` (where `_winnerId` set by story-003 F4 or story-004 T6/T8 path)
  2. `local placements = RoundLifecycle.getPlacements()`
  3. Strip `InternalPlacement` fields (peakCount/isWinner/wasEliminated) before broadcast — adapter helper `_stripInternalPlacements(placements): {Placement}`
  4. `Currency.grantMatchRewards(strippedPlacements)`
  5. `_state = "Result"`, `_stateEndsAt = now + RESULT_DURATION_SEC`
  6. Fire `MatchStateChanged` broadcast (story-007 owns the actual fire; this story arranges the call order)
- [ ] `_transitionTo("Intermission")` body (T9):
  1. `RoundLifecycle.destroyAll()`
  2. `RelicSystem.clearAll()`
  3. `_state = "Intermission"`, `_stateEndsAt = now + INTERMISSION_DURATION_SEC` (10s per AC-15)
  4. Fire `MatchStateChanged` broadcast
- [ ] `_transitionTo("Lobby")` from Intermission (T10):
  1. Reset all participation flags: `for userId in connectedPlayers: _participation[userId] = true`
  2. `_state = "Lobby"`, `_stateEndsAt = nil`
  3. Fire `MatchStateChanged` broadcast
- [ ] Phase 6 `timerCheck` extended to handle:
  - `Result` elapsed ≥ 10s → `_transitionTo("Intermission")`
  - `Intermission` elapsed ≥ 10s → `_transitionTo("Lobby")` (T10)
- [ ] No `grantMatchRewards` called outside `_transitionTo("Result")` body — code-review audit.

---

## Implementation Notes

- T8 instant-win path (story-004) calls `_transitionTo("Result", {rivalDisconnected=true, winnerId=...})` — meta passed through to broadcast adapter.
- Strip helper:
  ```lua
  local function _stripInternalPlacements(placements): { Placement }
      local out: { Placement } = {}
      for _, p in ipairs(placements) do
          table.insert(out, {
              crowdId = p.crowdId,
              userId = p.userId,
              placement = p.placement,
              crowdCount = p.crowdCount,
              eliminationTime = p.eliminationTime,
          })
      end
      return out
  end
  ```
- Until RoundLifecycle epic + RelicSystem + Currency epics ship, use stubs `RoundLifecycleStub.setWinner / getPlacements / destroyAll`, `RelicSystemStub.clearAll`, `CurrencyStub.grantMatchRewards`. The grant-before-broadcast ordering is the integration assertion this story owns.
- `RESULT_DURATION_SEC = 10` per AC-14 (10s elapsed implicit from "10s elapsed" in AC); `INTERMISSION_DURATION_SEC = 10` per AC-15.
- Currency stub at `ServerStorage/Source/_PhaseStubs/CurrencyStub.luau` — exposes `grantMatchRewards(placements): ()` no-op (records call for spy testing).

---

## Out of Scope

- story-002: pre-Active timer driver
- story-003: F4 winner resolution at T7
- story-004: T6/T8 winner detection
- story-006: T11 BindToClose
- story-007: actual broadcast wire fire (this story arranges call order; broadcast adapter lives in story-007)
- RoundLifecycle epic / RelicSystem epic / Currency epic: real impls

---

## QA Test Cases

- **AC-14**: Force state Result, mock clock advance 10s. Phase 6 timerCheck. Spy log records `[destroyAll, clearAll, broadcast("Intermission")]` in that order. Edge: out-of-order fires fail the test.
- **AC-15**: Force state Intermission with `_participation[user1]=false`, `_participation[user2]=true`. Mock clock advance 10s. Phase 6 timerCheck. Assert all flags TRUE; state = "Lobby".
- **AC-20**: Force `_winnerId = "u1"` (story-003 path). Invoke `_transitionTo("Result", meta)`. Spy records `[setWinner, getPlacements, grantMatchRewards, broadcast("Result")]` in order. Stripped placements: no `peakCount`/`isWinner`/`wasEliminated` keys in broadcast meta payload. Edge: T8 path — `meta.rivalDisconnected=true` survives stripping.
- **No grant outside Result entry**: grep `grantMatchRewards` callers in MSM module — only inside `_transitionTo("Result")`. Edge: shutdown path (story-006) does NOT call grant.

---

## Test Evidence

`tests/integration/match-state-server/t9_ordering.spec.luau` + `tests/integration/match-state-server/grant_before_broadcast.spec.luau` + `tests/integration/match-state-server/t10_flag_reset.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..004; RoundLifecycle stub (setWinner/getPlacements/destroyAll); RelicSystem stub (clearAll); Currency stub (grantMatchRewards)
- Unlocks: story-007 (broadcast wire); story-006 (T11 BindToClose path uses `_transitionTo("ServerClosing")`)
