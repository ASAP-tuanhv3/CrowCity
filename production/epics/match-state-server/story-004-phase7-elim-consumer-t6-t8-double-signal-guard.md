# Story 004: Phase 7 eliminationConsumer + T6 last-standing + double-signal guard + T8 instant win

> **Epic**: match-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §States/T6+T8 + §Edge Cases/State transition races
**Requirement**: `TR-msm-004` (Phase 7), `TR-msm-015` (double-signal guard)
**ADR**: ADR-0005 §Decision (T6/T8 + double-signal guard); ADR-0002 §Phase 7 (TickOrchestrator-only caller).
**ADR Decision Summary**: `eliminationConsumer()` Phase 7 callback drains queued `CrowdEliminated` reliable RemoteEvents (queued by CSM Phase 5). On `numActiveNonEliminated ≤ 1` AND `_state == Active` → resolve F4 winner from F3 active set, `_transitionTo("Result")`. Double-signal guard: if `_state ~= Active` (e.g. Phase 6 already transitioned to Result), silently drop queued signals. T8 instant-win: when sole survivor remains (other crowds Eliminated/DC'd), F8 detection fires `transitionTo("Result")` with `meta.rivalDisconnected=true`.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: BindableEvent / signal queue (LOW); subscribe to CSM `CrowdEliminated` reliable RemoteEvent (LOW).

**Control Manifest Rules (Core layer)**:
- Required: MSM Phase 7 callback `eliminationConsumer()` (manifest L97); double-signal guard (L97); F2 elimination idempotent (L103).

---

## Acceptance Criteria

- [ ] **AC-9 (Last-crowd end T6)** — Active with 2 crowds; `CrowdEliminated` fires for A (1 active remaining); state → `Result` within one tick; `_winnerId` = remaining crowd via F4.
- [ ] **AC-11 (Double-signal guard)** — Active, 2 crowds eliminated SAME tick; both `CrowdEliminated` signals queued for Phase 7. `_transitionTo(Result)` called exactly ONCE; broadcast count = 1. Second signal silently dropped via `_state ~= Active` check.
- [ ] **AC-13 (T8 instant win)** — Active with sole remaining crowd (others Eliminated or DC'd via PlayerRemoving). MSM detects sole-survivor condition. Order: `grantMatchRewards` fires → `_transitionTo(Result)` broadcasts within one tick; `meta.rivalDisconnected = true`; `meta.winnerId` = sole survivor's crowdId; no delay between detection and broadcast.
- [ ] `eliminationConsumer()` Phase 7 hook signature: `function MatchStateServer.eliminationConsumer(): ()` per arch §5.2 L596.
- [ ] Body:
  1. `if _state ~= "Active" then return end` (double-signal guard).
  2. Drain queued `CrowdEliminated` reliable signals from internal queue (subscribed at module init via `Network.connectEvent(RemoteEventName.CrowdEliminated, ...)`).
  3. After draining, query `CSM.getAllActive()` count.
  4. If `#active ≤ 1` → resolve F4 winner (sole survivor or empty), call grant chain (story-005 owns grant order; this story queues), then `_transitionTo("Result")`.
- [ ] T8 detection: in addition to Phase 7 driven by elimination signals, `Players.PlayerRemoving` handler also checks `if _state == "Active" AND #remaining_active_crowds == 1`. If yes, fires same path as Phase 7 (with `meta.rivalDisconnected = true`).
- [ ] CrowdEliminated subscription: `Network.connectEvent(RemoteEventName.CrowdEliminated, function(payload) end)` connected at module init; queues `crowdId` into a tick-local list `_pendingElims: {string}`.
- [ ] `_pendingElims` cleared at top of each `eliminationConsumer` call.
- [ ] T6 winner resolution path: when `#active == 1` after drain → `_winnerId = active[1].crowdId` (single survivor); when `#active == 0` (rare double-elim) → `_winnerId = nil`.
- [ ] T8 path uses `meta = {rivalDisconnected = true, winnerId = soleSurvivorCrowdId}` per AC-13.

---

## Implementation Notes

- Subscribe to `CrowdEliminated` reliable RemoteEvent ONCE at module init. Server-side handler queues into `_pendingElims`. Phase 7 drains.
  ```lua
  local _pendingElims: { string } = {}
  Network.connectEvent(RemoteEventName.CrowdEliminated, function(_player, payload)
      table.insert(_pendingElims, payload.crowdId)
  end)
  ```
  *Note*: `CrowdEliminated` is server→client reliable per arch §5.7 L752. CSM fires it on Active→Eliminated transition (story-006 of CSM epic). MSM subscribes server-side via the SAME event name — this is acceptable because Roblox lets server scripts subscribe to RemoteEvents fired by other server scripts (BindableEvent semantics emerge from server-server reliable RemoteEvent self-fire). Alternative pattern: CSM exposes a server-only BindableEvent `CrowdEliminatedServer` that MSM subscribes to. **Decision**: Use a server-only BindableEvent named `CSM.CrowdEliminatedServer` for MSM consumption (same pattern as `CSM.CountChanged` BindableEvent per CSM story-002). Cross-machine `CrowdEliminated` reliable RemoteEvent is for CLIENT consumption (HUD kill feed). The two are colocated semantically but technically separate signals — fired in tandem from CSM Phase 5.
- This means CSM story-006 must fire BOTH `CSM.CrowdEliminatedServer` BindableEvent (for MSM) AND `CrowdEliminated` reliable RemoteEvent (for clients). Add this to CSM story-006 implementation note. Action: do NOT modify CSM story-006 directly here — instead this story documents the contract requirement; CSM story-006's "fires CrowdEliminated reliable" line implicitly extends to "fires both server BindableEvent + client reliable RemoteEvent". Code-review enforces.
- `Players.PlayerRemoving` handler in MSM module: also check sole-survivor condition for T8. PlayerRemoving fires CSM destroy (CSM story-001 handler) which removes the crowd from `getAllActive`. After CSM has destroyed the crowd, MSM's PlayerRemoving handler checks `_state == "Active"` + `#CSM.getAllActive() == 1` → triggers T8 path.
- T8 path order (per AC-13): grant first, then transition + broadcast. Grant-before-broadcast invariant lives in story-005's `_transitionTo("Result")` body, so this story just calls `_transitionTo("Result", {rivalDisconnected=true, winnerId=...})` and story-005 ensures the grant chain runs.

---

## Out of Scope

- story-001..003: prereqs.
- story-005: grant-before-broadcast invariant inside `_transitionTo("Result")`; T9 destroyAll → Intermission ordering.
- story-007: actual MatchStateChanged broadcast wire fire.
- CSM story-006: fires `CrowdEliminatedServer` BindableEvent (this story documents the contract).
- RoundLifecycle epic: peakTimestamp for F4 (covered in story-003 contract).

---

## QA Test Cases

- **AC-9**: Active state, 2 crowds A+B in CSM. Fire `CrowdEliminatedServer` BindableEvent for A. Phase 7 invokes `eliminationConsumer`. Assert `_state == "Result"`, `_winnerId == B.crowdId`. Edge: A is also the F4 winner if survived — but in this case A is eliminated so B is sole survivor.
- **AC-11**: Active state, 3 crowds A+B+C. Fire `CrowdEliminatedServer` for A AND B SAME tick (queue both before Phase 7). Phase 7 drains; `#active == 1` (C) → transition. Spy: `_transitionTo` called ONCE; broadcast count 1. Edge: drain order doesn't affect outcome (winner is C either way).
- **AC-13**: Active state, 2 crowds A+B. `Players.PlayerRemoving` fires for A's owner. CSM destroy fires (CSM story-001 handler). MSM PlayerRemoving handler runs after, sees `#active == 1` (B). Spy: `[grantMatchRewards, broadcast("Result", meta={rivalDisconnected=true, winnerId=B.crowdId})]` in order. Edge: rapid double-DC (both players) → `#active == 0` → `_winnerId = nil`, transition still fires once.
- **Double-signal guard via Phase 6 first**: setup AC-21 fixture (Phase 6 transitions to Result). Phase 7 `eliminationConsumer` runs with queued elim. Body sees `_state == "Result"` → returns immediately. No second transition. Pending queue cleared at top of next call.
- **`_pendingElims` clear-at-top**: 2 ticks of fixture; verify `_pendingElims` is empty at end of each `eliminationConsumer` call.

---

## Test Evidence

`tests/unit/match-state-server/elim_consumer_t6_test.luau` + `tests/unit/match-state-server/double_signal_guard_test.luau` + `tests/integration/match-state-server/t8_instant_win_test.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..003; CSM story-006 (CrowdEliminatedServer BindableEvent contract); RoundLifecycle epic stub (`destroyAll`/`getPeakTimestamp`)
- Unlocks: story-005 (Result transition body uses `_winnerId` set here)
