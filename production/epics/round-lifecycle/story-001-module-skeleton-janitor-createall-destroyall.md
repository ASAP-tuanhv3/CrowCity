# Story 001: Module skeleton + Janitor lifecycle + createAll + destroyAll

> **Epic**: round-lifecycle
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/round-lifecycle.md` §Server API + §States/Transitions + §Edge Cases/createAll-destroyAll-idempotence
**Requirement**: `TR-round-lifecycle-001` (round-scoped aux), `TR-round-lifecycle-007` (no-prior-Janitor assertion), `TR-round-lifecycle-008` (Janitor scope), `TR-round-lifecycle-014` (destroyAll Janitor disconnect), `TR-round-lifecycle-015` (stray-signal no-op post-destroy), `TR-round-lifecycle-010` (memory budget ≤12)
**ADR**: ADR-0005 §Decision (RoundLifecycle owns aux + Janitor + freeze-at-disconnect); ADR-0006 §Source Tree Map; ADR-0003 §Memory.
**ADR Decision Summary**: RoundLifecycle is sub-coordinator of MSM. Per round, it allocates a fresh Janitor, creates a CSM record per participant, tracks per-crowd aux fields. `destroyAll` cleans up Janitor first, then iterates CSM destroys; subsequent stray signals are silently no-op.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Wally `Packages.janitor` (vendored, LOW); `pcall` (LOW); `os.clock` (LOW).

**Control Manifest Rules (Core layer)**:
- Required: RoundLifecycle at `ServerStorage/Source/RoundLifecycle/init.luau` owns `_crowds` aux + `_participants` + `_winnerId` + Janitor (manifest L94); MSM is sole caller of all 5 methods (L95); MAX_PARTICIPANTS_PER_ROUND=12 (L104).
- Forbidden: never call any RoundLifecycle method from outside MSM (L138); never persist per-round state (L150).

---

## Acceptance Criteria

- [ ] **AC-1 (createAll success)** — `createAll([A, B])` on a Dormant instance; `CrowdStateServer.create` succeeds for both. `_crowds` contains 2 records: `peakCount=10`, `peakTimestamp != 0`, `finalCount=10`, `eliminationTime=nil`.
- [ ] **AC-2 (createAll pcall failure)** — `create` throws for A and succeeds for B. `_crowds` has 1 record (B); `warn` log cites A's UserId + error; A is absent from any subsequent `getPlacements()` output.
- [ ] **AC-3 (Double createAll assert)** — Module is Active; `createAll` called again without `destroyAll`; assertion fires BEFORE any mutation; `_crowds` + `_participants` unchanged.
- [ ] **AC-4 (destroyAll clean-wipe)** — Active state w/ 2 crowds; `destroyAll()`; `janitor:Destroy()` runs FIRST; `CrowdStateServer.destroy` called per crowd; `#_crowds == 0`; `#_participants == 0`; `_winnerId == nil`. Subsequent mocked `CountChanged` / `Eliminated` signal fires without error and mutates no state.
- [ ] Module-private state: `_crowds: {[string]: InternalAuxRecord} = {}`, `_participants: {Player} = {}`, `_winnerId: string? = nil`, `_janitor: Janitor? = nil`.
- [ ] `InternalAuxRecord` type:
  ```lua
  type InternalAuxRecord = {
      crowdId: string,
      userId: number,
      peakCount: number,
      peakTimestamp: number,
      finalCount: number,
      eliminationTime: number?,
      survived: boolean,  -- updated at setWinner / freeze
  }
  ```
- [ ] `createAll(participatingPlayers: {Player})` body:
  1. `assert(_janitor == nil, "RoundLifecycle: createAll called without prior destroyAll")`
  2. `assert(#participatingPlayers <= 12, "RoundLifecycle: MAX_PARTICIPANTS exceeded")`
  3. Allocate `_janitor = Janitor.new()`.
  4. Initialize `_participants = {}` snapshot, `_winnerId = nil`, `_crowds = {}`.
  5. For each player: pcall `CrowdStateServer.create(crowdId, initial)`. On success, insert into `_participants`, allocate `InternalAuxRecord` w/ `peakCount=10, peakTimestamp=os.clock(), finalCount=10`. On pcall failure, `warn` + skip (do not abort entire call).
- [ ] `destroyAll(): ()` body:
  1. If `_janitor` non-nil: `_janitor:Destroy()`, `_janitor = nil` (FIRST — disconnects all subscriptions).
  2. For each crowdId in `_crowds`: `CrowdStateServer.destroy(crowdId)` (idempotent on CSM side).
  3. `_crowds = {}`, `_participants = {}`, `_winnerId = nil`.
- [ ] Stray-signal no-op post-destroy: subscribers (added in story-002, story-003) are stored in `_janitor` so `_janitor:Destroy()` removes them. Any post-destroy signal fire passes through without mutation because the connection is gone.
- [ ] Empty `participatingPlayers` (T5 path) → `_janitor` allocated but `_crowds`/`_participants` empty; `getPlacements()` (story-005) returns empty array.

---

## Implementation Notes

- Janitor pattern per Wally `Packages.janitor`: `local Janitor = require(Packages.janitor)`; `_janitor:Add(connection, "Disconnect")` for `RBXScriptConnection`; `_janitor:Destroy()` cleans all.
- AC-2 partial-failure: `pcall` wraps each `CrowdStateServer.create`. On failure, the player skipped is NOT in `_participants`. Subsequent `getPlacements` (story-005) iterates `_crowds` keys → missing player naturally absent.
- Initial `peakCount = 10` matches `CROWD_START_COUNT` (registry constant). Initial `peakTimestamp = os.clock()` so even crowds that never grow have a valid timestamp for F4 tiebreak.

---

## Out of Scope

- story-002: CountChanged subscription + peak tracking
- story-003: Eliminated subscription + DC freeze
- story-004: setWinner / getPeakTimestamp
- story-005: getPlacements F3 sort + broadcast schema strip

---

## QA Test Cases

- **AC-1**: Mock `CrowdStateServer.create` returning success. `createAll([A, B])`. Assert `_crowds[A.crowdId].peakCount == 10`, `peakTimestamp != 0`, `finalCount == 10`, `eliminationTime == nil`. Same for B.
- **AC-2**: Mock `CrowdStateServer.create` to throw for A. `createAll([A, B])`. Assert `_crowds[A.crowdId] == nil`, `_crowds[B.crowdId] ~= nil`. `warn` spy received message containing `tostring(A.UserId)`.
- **AC-3**: `createAll([A, B])` then `createAll([C, D])` without `destroyAll`. Second call fails via assert. `_crowds` and `_participants` unchanged from first call.
- **AC-4**: `createAll([A, B])`. Mock CSM destroy spy. `destroyAll()`. Spy log: `[janitor:Destroy, CSM.destroy(A), CSM.destroy(B)]` in order (Janitor first; CSM destroy order via pairs iteration arbitrary but both fire). Assert `_crowds`, `_participants`, `_janitor`, `_winnerId` all empty/nil. Edge: subsequent `CountChanged` signal fire after destroyAll — no error, no mutation (verified because Janitor disconnected the subscriber).
- **MAX_PARTICIPANTS=12**: `createAll(13 players)` → assertion fails. Edge: exactly 12 → succeeds.
- **Empty participants**: `createAll([])` → no assertions; `_janitor` allocated; `_crowds` empty.
- **Memory budget**: aux record per crowd ≈ 80 B (5 numeric fields + crowdId string); 12 crowds ≈ 1 KB. Well within ADR-0003 §Memory budget L185 (RoundLifecycle 2 KB allocation).

---

## Test Evidence

`tests/unit/round-lifecycle/createall.spec.luau` + `tests/unit/round-lifecycle/destroyall.spec.luau` + `tests/unit/round-lifecycle/double_createall_assert.spec.luau`.

**Status**: [x] Executed headless 2026-04-29 — 102/0/0 pass via `run-in-roblox` (13 new RL + 89 prior)

---

## Dependencies

- Depends on: CSM story-001 (create/destroy API)
- Unlocks: story-002..005

---

## Completion Notes

**Completed**: 2026-04-29
**Criteria**: 8/8 covered (AC-1, AC-2, AC-3, AC-4, MAX_PARTICIPANTS guard, empty participants, hue assignment, double-destroyAll idempotence)

**Files**:
- `src/ServerStorage/Source/RoundLifecycle/init.luau` (271 L) — singleton module
  - Imports: `Packages.janitor` (Wally), `CrowdStateServer` (CSM)
  - Constants: `MAX_PARTICIPANTS_PER_ROUND = 12`, `CROWD_START_COUNT = 10`
  - `hueForIndex(i): number` — round-robin 1..12 hue assignment per participant index (ADR-0001 §Key Interfaces palette)
  - Type `InternalAuxRecord` per spec (7 fields: crowdId, userId, peakCount, peakTimestamp, finalCount, eliminationTime, survived)
  - DI seam: `_setCSMOverride(csm)` test hook + `getCSM()` returns override or real CSM
  - Public surface (story-001): `createAll(participants)`, `destroyAll()`
  - Test-only surface: `_resetForTests`, `_getCrowdsCount`, `_getParticipantsCount`, `_getJanitor`, `_setCSMOverride`
  - `createAll`: assert no prior Janitor + assert ≤12 → allocate Janitor → init `_participants/_winnerId/_crowds` → for each player pcall CSM.create + on-success build aux record + insert participant; on failure warn + skip
  - `destroyAll`: Janitor:Destroy() FIRST → CSM.destroy(crowdId) for each tracked → zero local state
- `tests/unit/round-lifecycle/createall.spec.luau` (167 L, 6 it blocks)
- `tests/unit/round-lifecycle/destroyall.spec.luau` (121 L, 4 it blocks)
- `tests/unit/round-lifecycle/double_createall_assert.spec.luau` (83 L, 3 it blocks)

**Test Evidence**: 3 TestEZ spec files at `tests/unit/round-lifecycle/`. **Executed 2026-04-29** via `run-in-roblox` → **102/0/0 pass** (13 new RL + 89 prior).

**Audit gates ALL PASS**: selene + audit-asset-ids + audit-persistence + audit-no-competing-heartbeat.

**Code Review**: Standalone `/code-review` skipped — Lean mode + small scope + DI pattern mirrors CSM 2-4's interceptor approach + impl matches spec verbatim.

**Deviations**: None.

**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW + QL-STORY-READY skipped — Lean mode.

**Unblocks**: RL story-002 (CountChanged subscription + peak tracking — uses `_janitor:Add(connection, "Disconnect")` pattern), story-003 (Eliminated subscription + DC freeze), story-004 (setWinner + getPeakTimestamp), story-005 (getPlacements F3 sort).
