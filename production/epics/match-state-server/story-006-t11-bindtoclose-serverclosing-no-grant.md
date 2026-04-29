# Story 006: T11 BindToClose + ServerClosing broadcast + no-grant during shutdown

> **Epic**: match-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §States/T11 + §Edge Cases/Server lifecycle
**Requirement**: `TR-msm-014` (BindToClose persistence interaction), `TR-msm-008` (BindToClose driver)
**ADR**: ADR-0005 §BindToClose 30s grace; ADR-0011 §BindToClose path; architecture.md §4.5 Scenario E.
**ADR Decision Summary**: At server shutdown, after `TickOrchestrator.stop()` (TickOrch story-004), MSM transitions to `ServerClosing` and broadcasts `MatchStateChanged("ServerClosing")` to all clients within 2s of BindToClose entry. ProfileStore handles its own per-player save retry within the 28s remaining grace. **NO `Currency.grantMatchRewards` during shutdown** — even if the game is in Active state at shutdown, players don't get end-of-round payout.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `game:BindToClose(callback)` (LOW); reliable RemoteEvent (LOW); ProfileStore (vendored; manages own BindToClose).

**Control Manifest Rules (Core layer)**:
- Required: BindToClose 30s grace — MSM owns T11 (manifest L106); NO currency grant during shutdown (L106 + L142).

---

## Acceptance Criteria

- [ ] **AC-16 (BindToClose)** — `Active` with live round; `game:BindToClose` fires; within 2s all clients receive broadcast `state: "ServerClosing"`; `PlayerDataServer.onPlayerRemovingAsync` called per player over 28s (this is ProfileStore's internal handling — MSM does not invoke directly); `grantMatchRewards` NOT called; no second `MatchStateChanged` broadcast during shutdown.
- [ ] MSM exposes `requestServerClosing(): ()` per arch §4.5 — invoked by the BindToClose handler in `start.server.luau` AFTER `TickOrchestrator.stop()` (per tick-orchestrator story-004 chain).
- [ ] `requestServerClosing` body:
  1. If `_state == "ServerClosing"` → return (idempotent — already shutting down).
  2. `_state = "ServerClosing"`, `_stateEndsAt = nil`.
  3. Fire `MatchStateChanged` broadcast with `{state="ServerClosing", serverTimestamp=os.clock(), stateEndsAt=nil, meta={}}`.
  4. Return immediately. Do NOT call `RoundLifecycle.destroyAll`, `RelicSystem.clearAll`, or `Currency.grantMatchRewards`.
- [ ] `requestServerClosing` is the only path that writes `_state = "ServerClosing"` — no `_transitionTo` call (avoids passing through Result-entry grant chain).
- [ ] BindToClose-specific implementation: `requestServerClosing` does NOT use the standard `_transitionTo("Result")` body (which would call grantMatchRewards). It is a parallel transition path — explicit shutdown-only.
- [ ] tick-orchestrator story-004's BindToClose handler in `start.server.luau` invokes `MatchStateServer.requestServerClosing()` after `TickOrchestrator.stop()`. This story replaces the `MatchStateServerStub.requestServerClosing` stub (per stub-replacement contract).
- [ ] Phase 6 timerCheck adds: `if _state == "ServerClosing" then return end` — no further state transitions during shutdown.
- [ ] Phase 7 eliminationConsumer adds: `if _state == "ServerClosing" then return end` — drop any queued elims silently during shutdown.

---

## Implementation Notes

- The BindToClose chain order (per arch §4.5):
  1. `TickOrchestrator.stop()` (tick-orchestrator story-004)
  2. `MatchStateServer.requestServerClosing()` (THIS STORY)
  3. ProfileStore's internal BindToClose handler (vendored — runs concurrently per Roblox's BindToClose semantics)
- `requestServerClosing` is intentionally NOT named `_transitionTo("ServerClosing")` to make it visually distinct — code-review will catch any attempt to invoke the standard `_transitionTo` body during shutdown.
- 2-second AC-16 budget: trivially met by reliable `MatchStateChanged:FireAllClients` (story-007 broadcast adapter); typical < 100ms end-to-end.
- Roblox's BindToClose grants 30s for ALL registered handlers concurrently; ProfileStore registers its own; this story does NOT block on ProfileStore.

---

## Out of Scope

- tick-orchestrator story-004: BindToClose body wiring + chain order assertion + `TickOrchestrator.stop` invocation.
- story-007: actual `MatchStateChanged` broadcast wire fire (this story calls the adapter).
- ProfileStore (vendored): per-player save retry; not modified by this story.
- story-001..005: prereqs.
- Currency epic: `Currency.grantMatchRewards` is NOT invoked here — code-review enforced.

---

## QA Test Cases

- **AC-16 (broadcast within 2s)**: Force `_state = "Active"`. Invoke `requestServerClosing()`. Assert broadcast spy receives `MatchStateChanged("ServerClosing", ...)` with elapsed < 2s. Edge: invoke from any state — Lobby/Ready/Snap/Active/Result/Intermission — all transition to ServerClosing.
- **AC-16 (no second broadcast during shutdown)**: Invoke `requestServerClosing()` twice in sequence. Spy records exactly ONE broadcast. Subsequent invokes are no-ops (idempotent guard).
- **AC-16 (no grant during shutdown)**: Force Active state with mock CSM crowds. Invoke `requestServerClosing()`. Spy on `Currency.grantMatchRewards` records ZERO calls.
- **Phase 6 / Phase 7 inert during ServerClosing**: Force `_state = "ServerClosing"`. Invoke `timerCheck()` and `eliminationConsumer()`. Assert no state mutations, no broadcasts, no grants.
- **Stub replacement**: After this story ships, grep `MatchStateServerStub.requestServerClosing` in `start.server.luau` BindToClose body — replaced with `MatchStateServer.requestServerClosing`. Stub file `_PhaseStubs/MatchStateServerStub.luau` may remain for unit tests of TickOrch story-004 isolation.
- **Audit grep**: `grep -rn "_state = \"ServerClosing\"" src/ServerStorage/Source/MatchStateServer/` → exactly one match (inside `requestServerClosing`).

---

## Test Evidence

`tests/integration/match-state-server/bindtoclose.spec.luau` (broadcast within 2s, no second broadcast, no grant) + `tests/unit/match-state-server/serverclosing_inert.spec.luau` (Phase 6/7 no-op).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..005; tick-orchestrator story-004 (chain wires `TickOrchestrator.stop` → `requestServerClosing`)
- Unlocks: TickOrch story-004 stub replacement; ProfileStore session-release coordination ready
