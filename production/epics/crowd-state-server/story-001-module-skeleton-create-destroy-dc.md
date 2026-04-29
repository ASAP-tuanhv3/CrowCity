# Story 001: Module skeleton + record schema + create/destroy lifecycle + DC handler

> **Epic**: crowd-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Server API (lifecycle table) + §Interactions/Round Lifecycle + §Edge Cases/Lifecycle
**Requirement**: `TR-csm-001` (CrowdId helper), `TR-csm-014` (Write-Access Matrix create/destroy = RoundLifecycle-only), `TR-csm-016` (module placement), `TR-csm-022` (write-access matrix), `TR-csm-009` (Read-vs-Write authority)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (CSM Authority) §Write-Access Matrix; ADR-0001 (Crowd Replication Strategy) §Key Interfaces (record schema + 5 reliable named events); ADR-0006 (Module Placement) §Source Tree Map; ADR-0011 (Persistence Schema) §Pillar 3 Exclusions.
**ADR Decision Summary**: `create` + `destroy` callers are exclusively RoundLifecycle (createAll T4 / destroyAll T9 / PlayerRemoving handler); destroy is idempotent; both fire reliable RemoteEvents (`CrowdCreated` / `CrowdDestroyed`) before returning. Records live in `_crowds: {[crowdId]: CrowdRecord}` server-only — never persisted.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: HIGH (post-cutoff UREvent + buffer eventually consumed by S8 broadcastAll; this story stays on stable APIs)
**Engine Notes**: Reliable `RemoteEvent` (template-proven, LOW). `Players.PlayerRemoving` (LOW). The HIGH risk vector is the broadcast path — out of scope here.

**Control Manifest Rules (Core layer)**:
- Required: CrowdStateServer at `ServerStorage/Source/CrowdStateServer/init.luau` is sole authority (manifest L70); `create` + `destroy` sole caller is RoundLifecycle (L74); `CrowdCreated` + `CrowdDestroyed` reliable named events (L86); record schema fields enumerated (L78).
- Forbidden: Never persist per-round crowd state in ProfileStore (L150); never read or mutate the table returned by `get` / `getAllActive` (L155).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-01 (Identity)** — Match starts with two players; `RoundLifecycle.createAll()` invokes `CrowdStateServer.create(crowdId, initial)` for each. Each player has exactly one record keyed by `tostring(player.UserId)`. No two records share a key.
- [ ] **AC-02 (DC Cleanup)** — Player P has an active crowd record with at least one collision pair; `Players.PlayerRemoving` fires for P. (a) `CrowdStateServer.get(P.crowdId)` returns `nil` by start of next tick; (b) collision overlap set for that tick contains no pair where either entry == `P.crowdId`; (c) no Luau error during tick processing.
- [ ] **AC-16 (Round Lifecycle, F1 — record presence portion)** — Fresh match with 8 players; after `createAll()`, all 8 records exist. After `destroyAll()`, all 8 records absent from the store. (Initial `count = CROWD_START_COUNT (10)` + initial `radius` are validated in story-003 + story-004; this story validates record presence/absence only.)
- [ ] **AC-23 (CrowdCreated fires)** — Fresh match with 8 players; `RoundLifecycle.createAll()` runs. Every client receives exactly 8 `CrowdCreated` reliable events with payload `{crowdId, hue, initialCount=10}`. No duplicate `CrowdCreated` for same `crowdId` within a match.
- [ ] **AC-26 (CrowdDestroyed fires)** — Crowd in any state; `RoundLifecycle.destroyAll()` runs → `CrowdDestroyed` fires `{crowdId}` for every client. After destroy, `get(crowdId)` returns nil. Mid-round `Players.PlayerRemoving` → `CrowdDestroyed` fires immediately, record absent from next tick's `getAllActive()`.
- [ ] `create(crowdId, initial)` errors loudly if record already exists (per GDD §Server API "Fails if record exists")
- [ ] `destroy(crowdId)` is idempotent — no-op if record absent (per GDD §Server API "Idempotent (no-op if absent)")
- [ ] CSM record fields written by `create`: `crowdId, position, radiusMultiplier=1.0, radius (computed), count, hue, activeRelics={}, state="Active", tick=0, stillOverlapping=false, timer_start=nil` per manifest L78. `count`, `hue`, `position`, `radius` are sourced from the `initial` argument (caller — RoundLifecycle — provides them); this story does NOT compute hue/radius (those are story-003/-004)
- [ ] `_crowds` table is module-private (`local _crowds: {[string]: CrowdRecord} = {}`); no exported reference
- [ ] `tools/audit-persistence.sh` exits 0 — no CSM record fields appear in `PlayerDataKey.luau` or `DefaultPlayerData.luau`
- [ ] `tools/audit-asset-ids.sh` exits 0 — no `rbxassetid://` literals in CSM module

---

## Implementation Notes

*Derived from ADR-0004 §Write-Access Matrix + ADR-0001 §Key Interfaces + GDD §Server API:*

- Module pattern: singleton module per ANATOMY.md §16 (mirrors template `Network/init.luau` style).
- `--!strict` header. Export `CrowdState`, `DeltaSource`, `CrowdRecord`, `ClassType` types per architecture.md §5.1 L512-527.
- `crowdId` is `tostring(player.UserId)` — the convention is owned by RoundLifecycle (`createAll(participatingPlayers)`); CSM only uses the string opaquely.
- `create` signature: `create(crowdId: string, initial: CrowdRecord): CrowdRecord` per arch §5.1. Caller passes the fully-constructed record (RoundLifecycle composes from player + hue counter + initial count). This story validates uniqueness, stores, fires `CrowdCreated`, returns the stored reference.
- `destroy` signature: `destroy(crowdId: string): ()`. Removes from `_crowds`, fires `CrowdDestroyed` reliable. Idempotent.
- `Players.PlayerRemoving` handler: connect once at module init or via boot wiring in `start.server.luau`. Handler calls `CrowdStateServer.destroy(tostring(player.UserId))` if record exists. The exact wire-up (handler in CSM module vs in RoundLifecycle) — **this story places the handler INSIDE CSM** to satisfy the AC-02 "no error during tick processing" guarantee directly. RoundLifecycle (story-001 of round-lifecycle epic) also subscribes for its own peakCount cleanup; both subscribers run independently.
- Reliable RemoteEvent fanout uses Foundation `Network.fireAllClients(RemoteEventName.CrowdCreated, {crowdId, hue, initialCount})`. Names must match `RemoteEventName.luau` enum extended in `network-layer-ext` story-002 (already shipped).
- `CrowdCreated` payload per GDD §Network event contract (L143): `{crowdId, hue, initialCount}`.
- `CrowdDestroyed` payload per GDD §Network event contract (L144): `{crowdId}`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-002**: `updateCount` API + `DeltaSource` enum + F5 clamp + `CountChanged` BindableEvent + `CrowdCountClamped`.
- **story-003**: Hue F6 computation + activeRelics cap.
- **story-004**: F1 composed radius + `recomputeRadius`.
- **story-005**: F2 position lag + nil HRP guard.
- **story-006**: Phase 5 state evaluator + F7 grace timer + state transitions + `CrowdEliminated` reliable.
- **story-007**: Read accessors `get / getAllActive / getAllCrowdPositions` + `setStillOverlapping`.
- **story-008**: Phase 8 `broadcastAll` + buffer codec + perf evidence.
- **RoundLifecycle epic**: `createAll(players)` builds `initial: CrowdRecord` table — caller composition, not CSM concern.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-01**: 2-player match fixture; `create` invoked with `crowdId = "u1"`, `crowdId = "u2"`; assert `get("u1")` and `get("u2")` non-nil and distinct; assert `_crowds` size = 2. Edge cases: `create("u1", ...)` twice → second errors loudly via `assert(_crowds[crowdId] == nil, ...)`.

- **AC-02**: Set up record + simulate active overlap; fire `Players.PlayerRemoving` for P; verify `get(P.crowdId) == nil` after 1 tick; verify next-tick collision overlap set excludes P; no error logs. Edge cases: PlayerRemoving for player without a record → no-op (idempotent destroy).

- **AC-16 (record presence portion)**: 8-player fixture; `createAll` invoked; assert all 8 records present in `_crowds`. `destroyAll` invoked; assert `_crowds` empty. Edge cases: `createAll` then `destroyAll` then `createAll` again — second `createAll` succeeds (idempotent destroyed state).

- **AC-23**: Network mock subscribed to `RemoteEventName.CrowdCreated`; `createAll` for 8 players; mock recorder count == 8; payload check: `{crowdId, hue, initialCount=10}` (initialCount field from the `initial` argument). Edge cases: same `crowdId` twice → first call fires event + stores record; second call errors before fire (no duplicate fire). Verify via mock that no second event for same `crowdId` ever observed.

- **AC-26**: Network mock subscribed to `CrowdDestroyed`. (a) Create record then `destroy(crowdId)` → mock receives one event with `{crowdId}`; `get(crowdId) == nil`. (b) Mid-round `Players.PlayerRemoving` → mock receives event immediately; `getAllActive()` next tick excludes that crowd. Edge cases: `destroy` on absent record → no event fired, no error.

- **`create` failure on duplicate**: `create("u1", ...)` then `create("u1", ...)` → second call errors with descriptive message (fixture asserts `pcall(...)` returns false).

- **`destroy` idempotence**: `destroy("u1")` on absent record → returns `()` without error; no `CrowdDestroyed` event fired (record never existed).

- **Audit gates**: `bash tools/audit-asset-ids.sh` exit 0; `bash tools/audit-persistence.sh` exit 0 after this module is added.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/lifecycle.spec.luau` (create/destroy/identity/idempotence) + `tests/unit/crowd-state-server/dc_cleanup.spec.luau` (PlayerRemoving handler) + `tests/unit/crowd-state-server/signal_fanout.spec.luau` (CrowdCreated + CrowdDestroyed events).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Foundation `network-layer-ext` (CrowdCreated + CrowdDestroyed entries in `RemoteEventName.luau`) — already complete
- Unlocks: ALL other CSM stories (record schema + lifecycle is the foundation)
