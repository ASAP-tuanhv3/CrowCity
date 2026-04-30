# Story 001: Module skeleton + 7-state enum + Lobby boot + participation flag table + asymmetric Snap freeze

> **Epic**: match-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §Core Rules + §States/Transitions table
**Requirement**: `TR-msm-001` (7-state enum), `TR-msm-006` (participation flag table), `TR-msm-008` (driver set), `TR-msm-002` (transitionTo internal-only), `TR-msm-010` (read-only external consumers)
**ADR Governing Implementation**: ADR-0005 (MSM/RoundLifecycle Split) §Decision (state machine + authority matrix); ADR-0006 §Source Tree Map.
**ADR Decision Summary**: 7-state enum exposed as Luau union type. `Lobby` is boot default. PlayerAdded auto-sets `participation=TRUE`. In `Countdown:Snap` state, asymmetric freeze: TRUE→FALSE rejected; FALSE→TRUE allowed. `transitionTo` is module-private — only internal driver loops mutate state.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `Players.PlayerAdded` / `PlayerRemoving` (LOW); module-level state singleton (LOW).

**Control Manifest Rules (Core layer)**:
- Required: MatchStateServer at `ServerStorage/Source/MatchStateServer/init.luau` owns 7-state machine + participation flags (manifest L93); MIN_PLAYERS_TO_START=2 (L105).
- Forbidden: external `transitionTo` callers (manifest §Required L93 implies internal-only).

---

## Acceptance Criteria

- [ ] **AC-1 (Boot invariant)** — Server starts; `MatchStateServer.get()` returns `"Lobby"` within first heartbeat.
- [ ] **AC-2 (Flag on join)** — Any state; `PlayerAdded` fires; `getParticipation(player) == true` immediately.
- [ ] **AC-3 (Asymmetric Snap freeze)** — In `Countdown:Snap`, player A attempts TRUE→FALSE → REJECTED, flag stays TRUE. Player B attempts FALSE→TRUE → SUCCEEDS, flag becomes TRUE.
- [ ] `MatchState` type exported per arch §5.2 L578: `"Lobby" | "Countdown:Ready" | "Countdown:Snap" | "Active" | "Result" | "Intermission" | "ServerClosing"`.
- [ ] `Placement` type exported per arch §5.2 L581: `{crowdId, userId, placement, crowdCount, eliminationTime?}`.
- [ ] Public API per arch §5.2: `get(): MatchState`, `getParticipation(player): boolean`, `getStateEndsAt(): number?`. No public `transitionTo`.
- [ ] Module-private `_transitionTo(newState)` (story-002+ owns transition driver wiring).
- [ ] Module-private `_setParticipation(player, flag)` honors Snap-freeze rule.
- [ ] `Players.PlayerAdded` handler sets `_participation[userId] = true` immediately, in any state (per AC-2).
- [ ] `Players.PlayerRemoving` handler clears `_participation[userId] = nil` (frees memory; effect on state machine handled by transition story).
- [ ] AFK RemoteEvent handler signature defined here as a stub (`AFKToggle` reliable RemoteEvent connect) — full validation logic per ADR-0010 4-check guard lives in story-007.

---

## Implementation Notes

- Module: singleton pattern. Module-private state: `_state: MatchState = "Lobby"`, `_participation: {[number]: boolean} = {}`, `_stateEndsAt: number? = nil`, `_stateStartTime: number? = nil`.
- `_setParticipation(player, flag)`: if `_state == "Countdown:Snap"` AND `flag == false` AND `_participation[player.UserId] == true` → reject (return without write). Otherwise write.
- `getStateEndsAt` returns `_stateEndsAt` (set by `_transitionTo` when entering a timed state, e.g. Countdown:Ready ends at start+10s). Story-002 owns this writer.
- DO NOT fire `MatchStateChanged` here — broadcast wiring lives in story-007. This story's `_transitionTo` only writes `_state` + `_stateStartTime` + `_stateEndsAt`.

---

## Out of Scope

- story-002..006: state transitions + timer + drivers
- story-007: MatchStateChanged broadcast, ParticipationChanged broadcast, GetParticipation RemoteFunction, AFK validation
- story-008: perf evidence

---

## QA Test Cases

- **AC-1**: fresh module load; assert `MatchStateServer.get() == "Lobby"` immediately. Edge: `_state` private (no external write).
- **AC-2**: PlayerAdded fixture; assert `getParticipation(player) == true`. Edge: in any of 7 states.
- **AC-3**: force `_state = "Countdown:Snap"`; A's flag TRUE; `_setParticipation(A, false)` → flag stays TRUE. B's flag FALSE; `_setParticipation(B, true)` → flag becomes TRUE.
- **PlayerRemoving**: fires; `_participation[userId] == nil`.
- **MatchState type compile-check**: `local x: MatchState = "Foo"` → strict-mode error.
- **No public transitionTo**: `MatchStateServer.transitionTo` is `nil`.

---

## Test Evidence

`tests/unit/match-state-server/skeleton.spec.luau` + `tests/unit/match-state-server/participation_flag.spec.luau` + `tests/unit/match-state-server/snap_freeze.spec.luau`.

**Status**: [x] Executed headless 2026-04-30 — 137/0/0 pass via `run-in-roblox` (16 new MSM + 121 prior)

---

## Dependencies

- Depends on: Foundation `network-layer-ext` (RemoteEventName entries) — already complete
- Unlocks: story-002..008

---

## Completion Notes

**Completed**: 2026-04-30
**Criteria**: 8/8 covered (AC-1, AC-2, AC-3 + MatchState type export + Placement type export + public API surface + no-public-transitionTo + PlayerAdded/Removing wiring)

**Files**:
- `src/ServerStorage/Source/MatchStateServer/init.luau` (~210 L) — singleton module
  - Exported types: `MatchState` (7-string union per arch §5.2 L577) + `Placement` (per arch §5.2 L581)
  - Module-private state: `_state` (boots to "Lobby"), `_participation`, `_stateStartTime`, `_stateEndsAt`, 3 connection refs
  - Public surface (story-001): `get`, `getParticipation`, `getStateEndsAt`, `start`
  - Module-private (file-local) helpers: `_transitionTo`, `_setParticipation` (Snap-freeze rule)
  - Test-only surface: `_resetForTests`, `_getState`, `_setStateForTests`, `_setParticipation` (re-exposed for testing), 3 connection getters
  - PlayerAdded handler auto-sets `_participation[uid] = true`; PlayerRemoving clears entry
  - Snap-freeze rule: in `Countdown:Snap`, TRUE→FALSE write rejected (early return); FALSE→TRUE allowed; outside Snap, both directions allowed
  - AFKToggle wiring DEFERRED to story-007 (`_afkToggleConnection` stays nil) — see deviations below
- `tests/unit/match-state-server/skeleton.spec.luau` (~75 L, 5 it blocks)
- `tests/unit/match-state-server/participation_flag.spec.luau` (~80 L, 5 it blocks)
- `tests/unit/match-state-server/snap_freeze.spec.luau` (87 L, 6 it blocks)

**Test Evidence**: 3 TestEZ spec files. **Executed 2026-04-30** via `run-in-roblox` → **137/0/0 pass** (16 new MSM + 121 prior).

**Audit gates ALL PASS**: selene + audit-asset-ids + audit-persistence + audit-no-competing-heartbeat.

**Code Review**: Standalone `/code-review` skipped — Lean mode + impl matches spec.

**Deviations** (ADVISORY only, non-blocking):
- **AFKToggle wiring deferred to story-007** (was originally planned as story-001 stub). Reason 1: `Network.connectEvent` requires `Network.startServer()` to have created the RemoteEvent instance, which fails in headless TestEZ context where Network isn't booted. Reason 2: ADR-0010 §4-Check Guard validation must wrap the handler before it accepts traffic; wiring without validation here would create a security gap during the story-001 → 007 window. Story-001 keeps the `_afkToggleConnection` field + `_getAFKToggleConnection` getter as scaffolding; story-007 wires the validated handler. Inline TODO marker in code documents the swap.

**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW + QL-STORY-READY skipped — Lean mode.

**Unblocks**: MSM stories 002 (Lobby↔Countdown:Ready transition driver via PlayerAdded count check), 003-006 (timer drivers + state transitions + simultaneity rules per ADR-0002 phase order), 007 (broadcast wiring + GetParticipation RemoteFunction + AFKToggle full ADR-0010 4-check guard), 008 (perf evidence). Sprint 2 must-have set now 7/8 done — only CSM 2-6 read accessors remaining.
