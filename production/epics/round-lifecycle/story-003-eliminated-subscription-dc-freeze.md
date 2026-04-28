# Story 003: Eliminated subscription + eliminationTime idempotent + DC freeze-at-disconnect

> **Epic**: round-lifecycle
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/round-lifecycle.md` §Formulas/F2 + §Edge Cases/Player-lifecycle
**Requirement**: `TR-round-lifecycle-006` (Phase 7 elim consumer interaction), `TR-round-lifecycle-012` (PlayerRemoving lifecycle)
**ADR**: ADR-0005 §Decision (RoundLifecycle owns eliminationTime + DC freeze-at-disconnect path).
**ADR Decision Summary**: RoundLifecycle subscribes CSM's `CrowdEliminatedServer` BindableEvent (server-only — see CSM story-006 contract note about parallel BindableEvent + reliable RemoteEvent). Records `eliminationTime = os.clock()` ONCE per crowd (idempotent — second fire is no-op). On `Players.PlayerRemoving` mid-round, freezes the player's record: writes `eliminationTime` and keeps the record present in `_crowds` so it appears in `getPlacements` as a Rank 2..N entry with `survived=false`.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: BindableEvent (LOW); `Players.PlayerRemoving` (LOW); `os.clock` (LOW).

**Control Manifest Rules (Core layer)**:
- Required: F2 elimination idempotent — first-fire wins (manifest L103); MSM is sole caller of all 5 RL methods (L95) — but PlayerRemoving subscription is a Players-engine signal, NOT an MSM call.

---

## Acceptance Criteria

- [ ] **AC-9 (eliminationTime — idempotent)** — Record w/ `eliminationTime=nil`; `onEliminated(id)` fires; `record.eliminationTime` is a number ≥ `tBefore = os.clock()` captured before fire. Second `onEliminated(id)` fire → `eliminationTime` UNCHANGED from first firing (idempotent guard).
- [ ] **AC-17 (DC freeze-at-disconnect)** — Active module w/ player A having `_crowds[A.crowdId]` record `finalCount=150`, `eliminationTime=nil`. `onPlayerRemoving(A)` fires (handler called directly w/ player A). `_crowds[A.crowdId]` STILL exists (record NOT removed). `record.eliminationTime` ≥ `tBefore`. Subsequent `getPlacements()` (after `setWinner`) includes A as Rank 2..N entry w/ `crowdCount=150, survived=false, eliminationTime=` frozen value.
- [ ] CSM `CrowdEliminatedServer` BindableEvent subscription added to `_janitor` in `createAll`. Disposed in `destroyAll`.
- [ ] `Players.PlayerRemoving` subscription added to `_janitor` in `createAll`. Disposed in `destroyAll`.
- [ ] `_onEliminated(crowdId)` body:
  ```lua
  local record = _crowds[crowdId]
  if record == nil then return end  -- AC-8 guard (silent)
  if record.eliminationTime ~= nil then return end  -- AC-9 idempotent
  record.eliminationTime = os.clock()
  record.survived = false
  ```
- [ ] `_onPlayerRemoving(player)` body:
  ```lua
  local crowdId = tostring(player.UserId)
  local record = _crowds[crowdId]
  if record == nil then return end
  if record.eliminationTime ~= nil then return end  -- already eliminated; no-op
  record.eliminationTime = os.clock()  -- freeze at disconnect
  record.survived = false
  -- record stays in _crowds for getPlacements ranking
  ```
- [ ] Both handlers idempotent — subsequent fires for same crowd are no-op.
- [ ] DC handler does NOT call `CrowdStateServer.destroy` — that's CSM's own PlayerRemoving handler responsibility (per CSM story-001). RoundLifecycle keeps its aux record alive for placement ranking even after CSM destroy fires `CrowdDestroyed` and removes the CSM record.

---

## Implementation Notes

- The handler ordering between CSM PlayerRemoving and RL PlayerRemoving is: BOTH subscribe to `Players.PlayerRemoving` independently. Roblox fires both subscribers synchronously on the same event, in undefined order. To handle race:
  - CSM destroys its own record (CSM story-001).
  - RL freezes its own aux (this story).
  - Neither depends on the other's order.
- Subscription wire-up inside `createAll` body extension (story-001):
  ```lua
  _janitor:Add(CrowdStateServer.CrowdEliminatedServer.Event:Connect(_onEliminated), "Disconnect")
  _janitor:Add(Players.PlayerRemoving:Connect(_onPlayerRemoving), "Disconnect")
  ```
- Handler ordering: `CrowdEliminatedServer` fires from CSM Phase 5 (story-006 of CSM epic) when state Active→Eliminated. `PlayerRemoving` fires from Roblox engine on disconnect. Both can fire independently for the same crowd; idempotent guards handle.
- `CrowdEliminatedServer` BindableEvent is the SERVER-ONLY companion to the client-facing reliable `CrowdEliminated` RemoteEvent — see CSM story-006 contract note. CSM fires both in tandem.

---

## Out of Scope

- story-001: createAll Janitor (this story extends body)
- story-002: CountChanged subscription
- story-004: setWinner / getPeakTimestamp
- story-005: getPlacements consumes eliminationTime + survived
- CSM story-001: CSM's own PlayerRemoving destroy handler
- CSM story-006: `CrowdEliminatedServer` BindableEvent fire side

---

## QA Test Cases

- **AC-9 (first fire)**: Record w/ `eliminationTime=nil`. Capture `tBefore = os.clock()`. Fire `_onEliminated(id)`. Assert `record.eliminationTime >= tBefore` AND `record.eliminationTime <= os.clock()` (sandwich). `record.survived == false`.
- **AC-9 (idempotent)**: After first fire captures `firstValue = record.eliminationTime`. Second `_onEliminated(id)` fire. Assert `record.eliminationTime == firstValue` (UNCHANGED).
- **AC-17 (DC freeze)**: Record `finalCount=150, eliminationTime=nil, survived=true`. Capture `tBefore`. Fire `_onPlayerRemoving(playerA)`. Assert `_crowds[A.crowdId] ~= nil` (record present); `record.eliminationTime >= tBefore`; `record.survived == false`; `record.finalCount == 150` (unchanged).
- **AC-17 (placements include DC'd player)**: After AC-17 setup, call `setWinner(B.crowdId)` then `getPlacements()` (story-005). Assert A is in output array as Rank 2..N w/ `crowdCount=150, eliminationTime=` frozen.
- **AC-8 silent guard**: `_onEliminated("nonexistent")` → no error, no mutation. `_onPlayerRemoving(player_with_no_record)` → no error.
- **DC then later Eliminated for same crowd**: Fire `_onPlayerRemoving(A)` first (sets eliminationTime). Then fire `_onEliminated(A)`. Second fire is no-op (eliminationTime already set).
- **Eliminated then DC**: reverse order. `_onPlayerRemoving` second fire is no-op.

---

## Test Evidence

`tests/unit/round-lifecycle/eliminated_subscription_test.luau` + `tests/unit/round-lifecycle/dc_freeze_test.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001; CSM story-006 (CrowdEliminatedServer BindableEvent fires server-side)
- Unlocks: story-005 (getPlacements consumes eliminationTime); MSM story-004 (T8 instant-win path uses RL's PlayerRemoving freeze indirectly — RL freezes; MSM separately checks `#CSM.getAllActive() == 1`)
