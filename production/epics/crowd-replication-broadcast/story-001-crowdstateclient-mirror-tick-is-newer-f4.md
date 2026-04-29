# Story 001: CrowdStateClient module skeleton + mirror cache + lastReceivedTick + tick_is_newer (F4)

> **Epic**: crowd-replication-broadcast
> **Status**: Ready
> **Layer**: Presentation (client-side mirror module)
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-replication-strategy.md` §Core Rules + §Formulas/F4 + §AC-7 + §AC-18 + §AC-22
**Requirement**: `TR-crs-022` (lastReceivedTick stale defense), `TR-crs-027` (authority + replication boundary)
**ADR**: ADR-0001 (Crowd Replication Strategy) §Key Interfaces (`CrowdStateClient` mirror; `tick: uint16` monotonic + lastReceivedTick stale defense); ADR-0006 (Module Placement Rules — client-side module under `ReplicatedStorage`).
**ADR Decision Summary**: CrowdStateClient mirror is the client-side read-only cache. `lastReceivedTick` per crowd defends against stale-packet reordering using F4 `tick_is_newer(new, old)` wrap-aware comparator (uint16 wrap at 65536; "newer" = within front-half window).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: HIGH
**Engine Notes**: `buffer.readu*/readf32` post-cutoff (HIGH; Foundation network-layer-ext story-003 codec consumed); pure Luau math elsewhere (LOW).

**Control Manifest Rules (Presentation Layer):**
- Required (manifest L226-L238): client modules MUST NOT `require` from `ServerStorage`; CrowdStateClient lives under `ReplicatedStorage/Source/CrowdStateClient/init.luau`; read-only mirror cache.
- Forbidden (manifest L239-L247): never write to client cache from any code path other than the broadcast subscriber; never expose write API to other client modules.

---

## Acceptance Criteria

- [ ] **AC-7 (F4 tick_is_newer uint16 wrap)** — `tickCounter = 65535`; server increments to 0; `tick_is_newer(0, 65535) = true` (wrap-aware); `tick_is_newer(65534, 65535) = false`; `tick_is_newer(32767, 0) = false` (≥ half-window, treat stale).
- [ ] **AC-18 (Nil crowdId lookup)** — No record for `crowdId="999999"`; `get("999999")` returns `nil` (not empty table, not default struct, not error).
- [ ] **AC-22 (crowdId uniqueness per round)** — 5-min round w/ 12 players; client cache insertion log assertion: no two different `crowdId` entries for same `player.UserId`; every entry's `crowdId == tostring(player.UserId)`.
- [ ] `ReplicatedStorage/Source/CrowdStateClient/init.luau` exists w/ `--!strict` header.
- [ ] Public API per arch §3.4 row 1:
  - `get(crowdId: string): CrowdRecord?` — read-only mirror lookup
  - `getAllActive(): { CrowdRecord }` — array of current cache records
  - `tick_is_newer(new: number, old: number): boolean` — F4 helper exposed standalone for AC-7 + DI per CRS §DI Requirements
- [ ] Module-private state: `_crowds: {[string]: CrowdRecord} = {}`, `_lastReceivedTick: {[string]: number} = {}`.
- [ ] F4 implementation:
  ```lua
  local UINT16_HALF = 32768
  local UINT16_MOD  = 65536
  
  local function tick_is_newer(new: number, old: number): boolean
      local diff = (new - old) % UINT16_MOD
      return diff > 0 AND diff < UINT16_HALF
  end
  ```
- [ ] `tick_is_newer(N, N) == false` (equal is NOT newer; broadcast for same tick treated as duplicate).
- [ ] Cache write path is exclusive to story-002 broadcast subscriber + story-003 reliable subscribers. This story exposes only the read API + F4 helper.
- [ ] `CrowdRecord` exported type matches CSM record schema (post-broadcast — server-pre-composed `radius` field carried directly):
  ```lua
  type CrowdRecord = {
      crowdId: string,
      tick: number,
      position: Vector3,
      radius: number,
      count: number,
      hue: number,
      state: "Active" | "GraceWindow" | "Eliminated",
      activeRelics: { string },  -- populated by CrowdRelicChanged reliable; story-003 owns
  }
  ```

---

## Implementation Notes

- F4 wrap-aware comparator: the modular arithmetic handles 0-vs-65535 wrap (`(0 - 65535) % 65536 = 1` → `1 < 32768 = true` → newer). Ambiguity threshold at half-window (32768) — values further apart treated as stale (defensive against very-old packets).
- `tick_is_newer` is exported standalone (per CRS §DI Requirements L457) so unit tests can drive it without instantiating the module.
- `getAllActive` returns array of references — read-only contract documented (manifest L155 same rule applies to client-side reads).
- Underlying mirror cache `_crowds` is populated by story-002 broadcast subscriber; this story creates the table and lookup APIs but no writers.
- AC-22: enforced at write-path in story-002 (broadcast subscriber asserts `crowdId == payload.crowdId == tostring(payload.userId)` shape from CSM record). This story validates lookup determinism: same `crowdId` always returns the same `CrowdRecord` reference until a destroy event clears it.

---

## Out of Scope

- story-002: Broadcast subscriber + decode + stale-defense write path
- story-003: Reliable subscribers (CrowdCreated/Destroyed/Eliminated/RelicChanged) + late-reliable handling
- story-004: Server-side broadcast loop transport phase machine
- story-005: F1 bandwidth estimator + static gates + perf integration
- FollowerLODManager epic: F3 render cap (CRS AC-6, AC-16, AC-24)

---

## QA Test Cases

- **AC-7 (F4 happy)**: `tick_is_newer(5, 4) == true`; `tick_is_newer(4, 5) == false`; `tick_is_newer(0, 65535) == true` (wrap); `tick_is_newer(65534, 65535) == false` (older); `tick_is_newer(32767, 0) == false` (half-window stale); `tick_is_newer(N, N) == false`.
- **AC-7 boundary**: `tick_is_newer(32768, 0) == false` (exactly half — defensive); `tick_is_newer(32767, 65535) == true` (wraps + within half); `tick_is_newer(0, 32768) == false` (other side).
- **AC-18**: Empty `_crowds`; `get("999999")` returns nil. `_crowds` populated w/ "u1"; `get("u1") ~= nil`; `get("u2") == nil`.
- **AC-22**: Inject (via story-002 path mocked) two broadcasts for `crowdId="u1"` w/ different ticks. `_crowds["u1"]` exists w/ exactly one entry. No second entry under `tostring(u1.UserId)` or related key. Edge: 12-player fixture with all 12 ids — `_crowds` size = 12, all keys distinct.
- **`tick_is_newer` standalone export**: `local f = require(ReplicatedStorage.Source.CrowdStateClient).tick_is_newer; f(5, 4) == true`. Confirms DI shape per CRS §DI requirements.
- **Read-only contract**: grep `_crowds[` writes outside this module → only story-002 + story-003 subscribers (post-shipping).

---

## Test Evidence

`tests/unit/crowd-state-client/tick_is_newer_f4.spec.luau` + `tests/unit/crowd-state-client/get_lookup.spec.luau` + `tests/unit/crowd-state-client/crowdid_uniqueness.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Foundation `network-layer-ext` (RemoteEventName + buffer codec — already shipped)
- Unlocks: story-002 (subscriber writes via this module's mirror cache); story-003 (reliable subscribers); HUD / Player Nameplate / Follower Entity (consume `get` / `getAllActive`)
