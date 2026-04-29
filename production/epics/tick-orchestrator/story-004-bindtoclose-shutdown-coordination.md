# Story 004: BindToClose stop() coordination

> **Epic**: tick-orchestrator
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` (T11 ServerClosing transition); architecture.md §4.5 (Scenario E — BindToClose path)
**Requirement**: `TR-msm-014` (BindToClose schema interaction); cross-cutting `TR-msm-008` (BindToClose driver of `transitionTo`); `TR-systems-index-005` (orchestration cadence)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (TickOrchestrator) §Migration Plan + §Validation L8 + Risks L240 (insertion via amendment); ADR-0005 (MSM/RoundLifecycle Split) §BindToClose ownership; ADR-0011 (Persistence Schema) §BindToClose 30 s grace.
**ADR Decision Summary**: At server shutdown, `game:BindToClose` first stops the TickOrchestrator (no further phase dispatch), then triggers MSM's T11 transition to `ServerClosing` which broadcasts `MatchStateChanged("ServerClosing")` to clients, then ProfileStore release/save runs within the 30-second grace window. **NO currency grant** during shutdown (manifest L106; ADR-0011).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `game:BindToClose(callback)` is template-proven (LOW); `BindToClose` callback yields the shutdown for up to 30 s while the body runs synchronously (callback runs as a coroutine; engine waits for it to return or times out). ProfileStore (vendored, see `docs/engine-reference/roblox/profilestore-reference.md`) handles its own session-release on `BindToClose` independently — this story does NOT call ProfileStore directly.

**Control Manifest Rules (Core layer)**:
- Required: BindToClose 30 s grace — MSM owns T11 transition; ProfileStore handles per-player save retry; **NO currency grant** during shutdown (manifest L106).
- Required: TickOrchestrator `stop()` halts within ≤ 5 ms of call (story-001 contract; backed by ADR-0002 §Validation L8).
- Forbidden: Never grant currency mid-shutdown (manifest L142).

---

## Acceptance Criteria

*From architecture.md §4.5 + ADR-0002 §Migration L4 + ADR-0005 §BindToClose + ADR-0011 §BindToClose grace, scoped to this story:*

- [ ] `src/ServerScriptService/start.server.luau` registers a `game:BindToClose(callback)` handler in a marked block (`-- BindToClose shutdown coordination (architecture.md §4.5)`) AFTER the TickOrchestrator boot wiring block from story-003
- [ ] BindToClose callback's first action is `TickOrchestrator.stop()` — NO statements between the callback's entry and `stop()` other than initial debug log line `print("[BindToClose] Server shutdown initiated")`
- [ ] `stop()` is invoked exactly once per BindToClose firing (idempotent re-entry-safe per story-001)
- [ ] AFTER `stop()` returns, the callback invokes the MSM `ServerClosing` transition path. Until MSM epic ships, this story uses a stub `MatchStateServerStub.requestServerClosing()` that fires `MatchStateChanged` reliable RemoteEvent with `state = "ServerClosing"`. Stub lives at `ServerStorage/Source/_PhaseStubs/MatchStateServerStub.luau`
- [ ] Callback completes within 5 seconds of entry on the happy path (well below the 30 s engine grace; allows ProfileStore retry headroom). Long-running ProfileStore release is NOT awaited in this story — ProfileStore registers its own `BindToClose` handler internally
- [ ] After `stop()` runs: NO further `_runTick` dispatches occur even if Roblox fires further `Heartbeat` events (verified via instrumented stub that throws if invoked post-stop)
- [ ] No currency grant code path runs during shutdown — verified via grep audit (`Currency.grantMatchRewards` and `grantCoins` calls must not be reachable from the BindToClose body or any function it calls)
- [ ] BindToClose registration is idempotent across hot-reloads in dev (Studio reload). Use a local `_bindToCloseRegistered` flag to prevent double-registration if the script loads twice (defensive guard)

---

## Implementation Notes

*Derived from architecture.md §4.5 (Scenario E — BindToClose) + ADR-0002 §Migration L4 + ADR-0005 §BindToClose + ADR-0011 §BindToClose grace:*

- The shutdown chain order, per architecture.md §4.5, is:
  1. `TickOrchestrator.stop()` — halt all gameplay-tick work
  2. MSM `transitionTo("ServerClosing")` — broadcast `MatchStateChanged` reliable to all clients (so the client UI can display "Server restarting")
  3. ProfileStore session-release runs in its own internal `BindToClose` handler (vendored library; not invoked from this story)
- This story owns step (1) explicitly and the wiring contract for step (2). When MSM epic lands its `ServerClosing` transition handler, the stub call site is replaced with the real `MatchStateServer.requestServerClosing()` (or whatever the MSM epic names the public BindToClose entry).
- ADR-0005 keeps MSM as sole owner of any `transitionTo("ServerClosing")` invocation. This story does NOT directly mutate any MSM state — it calls a documented entry point.
- `BindToClose` callback runs in a single coroutine; `stop()` is synchronous (story-001 contract); the broadcast is reliable RemoteEvent and returns immediately. ProfileStore's internal `BindToClose` is a separate registration — Roblox runs ALL registered `BindToClose` callbacks concurrently (each in its own coroutine) and waits for all to return or 30 s.
- The "5 second completion" target gives ProfileStore the bulk of the 30 s grace for save retries on its own coroutine. Don't `task.wait` arbitrarily inside this callback — only do work needed for ServerClosing broadcast.
- `_bindToCloseRegistered` is module-level state on the boot script. In Studio with auto-reload, a second require may attempt to re-register; defensive guard prevents double-broadcast.

---

## Out of Scope

*Handled by neighbouring stories or epics — do not implement here:*

- **MSM epic**: Real `MatchStateServer.requestServerClosing()` implementation + `transitionTo("ServerClosing")` transition entry + `MatchStateChanged` broadcast adapter. This story uses the stub.
- **ProfileStore session release**: ProfileStore registers its own `BindToClose` handler (vendored library); not within scope.
- **PlayerData epic**: Per-player save retry on shutdown is ProfileStore's responsibility per ADR-0011; not implemented here.
- **Currency epic**: Match-reward grants happen at MSM Result entry per ADR-0011 + manifest L106 — explicitly NOT during BindToClose. This story audits the negative.
- **Network epic / story-001-005 of network-layer-ext**: Already complete; reliable RemoteEvent path used here.

---

## QA Test Cases

*Integration story — automated integration test + audit grep.*

- **AC: BindToClose handler registered in start.server.luau**
  - Given: fresh checkout
  - When: `grep -n "game:BindToClose" src/ServerScriptService/start.server.luau`
  - Then: exactly one match; comment "shutdown coordination" present on adjacent line; block AFTER TickOrchestrator boot wiring
  - Edge cases: no other `BindToClose` registration in `src/ServerScriptService` or `src/ServerStorage/Source/start*` (ProfileStore's internal BindToClose is in `Dependencies/ProfileStore.luau` — that's vendored, not project code; OK)

- **AC: Shutdown chain order — `stop()` before MSM stub call**
  - Given: instrumented BindToClose body that records call order via `os.clock` timestamps in a list
  - When: `game:BindToClose` fires (test fixture invokes the callback directly)
  - Then: list = `[entry log, TickOrchestrator.stop, MatchStateServerStub.requestServerClosing]` (timestamps strictly ascending)
  - Edge cases: `stop()` raises → MSM stub call still attempts (next-tier resilience) OR does NOT (decision: this story chooses NOT to attempt — `stop()` must succeed before broadcast); pick policy: stop() failure halts shutdown chain, fixture asserts the failure is logged via `warn`

- **AC: No phase dispatch after `stop()`**
  - Given: stubs (story-003) instrumented to record invocation
  - When: BindToClose fixture fires; afterwards real `RunService.Heartbeat` runs for 200 ms
  - Then: stub recorder count after BindToClose = stub recorder count from before + 0 (no phases ran post-stop)
  - Edge cases: even if `_accumulator` was high pre-stop, no `_runTick` fires post-stop (story-001 ensures `_heartbeatConnection = nil`)

- **AC: Callback completes within 5 s**
  - Given: instrumented `os.clock` capture at callback entry and exit
  - When: BindToClose fixture fires
  - Then: exit_time - entry_time ≤ 5 s (typical < 100 ms)
  - Edge cases: stub broadcast is fast; ProfileStore not awaited

- **AC: No currency grant during BindToClose**
  - Given: BindToClose body code path (transitively via `TickOrchestrator.stop` and `MatchStateServerStub.requestServerClosing`)
  - When: AST-walk audit grep: `grep -rn "grantMatchRewards\|grantCoins\|Currency\." [BindToClose callback file + transitive deps]`
  - Then: zero matches in BindToClose-reachable code; `Currency.grantMatchRewards` is reachable ONLY from MSM Result entry (separate epic)
  - Edge cases: confirm `MatchStateServerStub.requestServerClosing` does NOT call grant; the real MSM `requestServerClosing` (when shipped) MUST also NOT — code review enforces

- **AC: `_bindToCloseRegistered` idempotence**
  - Given: `start.server.luau` is required twice (Studio auto-reload simulation)
  - When: each require's body runs
  - Then: only one `game:BindToClose` registration exists (verified via fixture-injected counter on `BindToClose` registration call)
  - Edge cases: `_bindToCloseRegistered = false` initial; first require sets to `true`; second require skips

- **AC: Reliable RemoteEvent fires `MatchStateChanged("ServerClosing")` exactly once per shutdown**
  - Given: client-side recorder subscribed to `RemoteEventName.MatchStateChanged`
  - When: BindToClose fixture fires
  - Then: client recorder receives one event with `state = "ServerClosing"` payload
  - Edge cases: payload also includes `serverTimestamp` per arch §5.7; the stub need only set `state` correctly — full payload schema lands in MSM epic

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tick-orchestrator/bindtoclose_shutdown.spec.luau` (chain order, no-phase-post-stop, 5s budget, single broadcast) + `tests/integration/tick-orchestrator/audit_no_currency_in_shutdown.sh` (grep audit script) — both must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (`stop()` API + idempotence), story-003 (boot wiring + stub directory pattern)
- Unlocks: MSM epic story replacing `MatchStateServerStub.requestServerClosing` with real `MatchStateServer.requestServerClosing`
