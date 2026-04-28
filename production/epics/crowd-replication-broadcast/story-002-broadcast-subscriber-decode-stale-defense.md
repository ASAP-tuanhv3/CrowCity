# Story 002: Broadcast subscriber + decode + idempotent overwrite + stale freeze (F2) + Eliminated defensive

> **Epic**: crowd-replication-broadcast
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-replication-strategy.md` §Core Rules + §Formulas/F2 + §AC-2/3/5/11/17/20
**Requirement**: `TR-crs-005..010` (decode + stale defense + idempotent overwrite), `TR-crs-013..016` (Eliminated defensive + ordering)
**ADR**: ADR-0001 §Decision (UREvent + buffer mandate; client-side decode + lastReceivedTick stale defense + Eliminated terminal flag).
**ADR Decision Summary**: Client subscribes `UnreliableRemoteEvent CrowdStateBroadcast`. Per packet, decode via Foundation buffer codec. For each crowd entry: F4 `tick_is_newer` check using `_lastReceivedTick`; if newer, idempotent-overwrite the cache entry. Eliminated state is TERMINAL — once cache entry is `state=Eliminated`, subsequent broadcasts asserting `Active`/`GraceWindow` are DISCARDED for that field (other fields may still update).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: HIGH
**Engine Notes**: `Network.connectUnreliableEvent` (Foundation network-layer-ext story-001 — shipped); `buffer.readu* / readf32 / readu8` post-cutoff (HIGH); decode via Foundation `BufferCodec.CrowdState.decode` (network-layer-ext story-003 — shipped).

**Control Manifest Rules (Presentation):**
- Required (manifest L226-L238): client-side broadcast subscriber via `Network` module; never reaches around to `RemoteEvent` instance directly.
- Forbidden (L239-L247): never write to cache outside this story's subscriber + story-003 subscribers.

---

## Acceptance Criteria

- [ ] **AC-2 (Buffer decode round-trip)** — 30-byte buffer from server; `BufferCodec.CrowdState.decode(buf)` called; decoded struct fields match original within f32 epsilon for floats and exactly for integers; no decode error.
- [ ] **AC-3 (Buffer decode failure graceful fallback)** — Malformed buffer (length < 30 bytes); decoder returns `nil`; client cache for that `crowdId` retains prior value unchanged; no Lua error propagates.
- [ ] **AC-5 (F2 stale broadcast threshold)** — `lastBroadcastTime = T` and `STALE_THRESHOLD_SEC = 0.5`; clockFn returns `T + 0.499` → `broadcast_stale()` returns `false`; `T + 0.500` → `true`. (DI: `clockFn` injected.)
- [ ] **AC-11 (Defensive: broadcast doesn't un-eliminate)** — Cache has `state=Eliminated` for `crowdId="A"`. Subsequent broadcast for A carries `state=Active` or `GraceWindow` (stale arrival). Client handler DISCARDS state update for that crowd's STATE field; cache remains `Eliminated`. Other fields (count/pos) may still update if tick newer.
- [ ] **AC-17 (Stale freeze last-known)** — Cache has `pos=(10,0,10), count=75`. No broadcast for `STALE_THRESHOLD_SEC + 0.1s = 0.6s`. `get(crowdId)` returns frozen `{pos=(10,0,10), count=75}` unchanged; cache does NOT return zero/nil/interpolated; no error.
- [ ] **AC-20 (Idempotent overwrite — no count accumulation)** — 50 broadcasts over 5s w/ varying counts. Final cache value = LAST received broadcast's count, NOT the sum.
- [ ] Subscribe at module init: `Network.connectUnreliableEvent(UnreliableRemoteEventName.CrowdStateBroadcast, _onBroadcast)`.
- [ ] `_onBroadcast(buf: buffer)` body:
  1. Walk buffer in 30-byte strides (length must be multiple of 30; otherwise log + return).
  2. Per stride: `BufferCodec.CrowdState.decode(buf, offset)` → record candidate. nil return → skip + log (AC-3 graceful fallback).
  3. Per candidate: `local oldTick = _lastReceivedTick[record.crowdId] or -1`. If `tick_is_newer(record.tick, oldTick) == false` → skip (stale or duplicate).
  4. Update `_lastReceivedTick[record.crowdId] = record.tick`.
  5. Cache merge: see Eliminated terminal rule below.
- [ ] Eliminated terminal rule (AC-11): `local cached = _crowds[record.crowdId]`. If `cached ~= nil AND cached.state == "Eliminated"` AND `record.state ~= "Eliminated"` → keep `state = Eliminated` in cache (still update count/pos/radius/hue/tick from new packet — only `state` field is sticky).
- [ ] On first reception of a `crowdId` (cache miss), store full record from packet.
- [ ] `broadcast_stale(crowdId): boolean` per F2: `(clockFn() - _lastBroadcastTime[crowdId]) >= STALE_THRESHOLD_SEC`. Helper exposed for HUD / Nameplate consumers (used by AC-17 stale-freeze test fixture).
- [ ] `STALE_THRESHOLD_SEC = 0.5` constant exposed at module top.
- [ ] DI: module accepts optional `clockFn` parameter; defaults to `os.clock`.

---

## Implementation Notes

- Buffer iteration:
  ```lua
  local function _onBroadcast(buf: buffer): ()
      local total = buffer.len(buf)
      if total % 30 ~= 0 then
          warn("CrowdStateClient: malformed broadcast buffer length " .. tostring(total))
          return
      end
      for offset = 0, total - 30, 30 do
          local record = BufferCodec.CrowdState.decode(buf, offset)
          if record == nil then continue end
          if not tick_is_newer(record.tick, _lastReceivedTick[record.crowdId] or -1) then continue end
          _lastReceivedTick[record.crowdId] = record.tick
          _lastBroadcastTime[record.crowdId] = clockFn()
          _mergeCache(record)
      end
  end
  ```
- `_mergeCache(record)` enforces Eliminated terminal:
  ```lua
  local cached = _crowds[record.crowdId]
  local stickState: CrowdState
  if cached ~= nil AND cached.state == "Eliminated" AND record.state ~= "Eliminated" then
      stickState = "Eliminated"  -- AC-11 terminal
  else
      stickState = record.state
  end
  _crowds[record.crowdId] = {
      crowdId = record.crowdId,
      tick = record.tick,
      position = record.position,
      radius = record.radius,
      count = record.count,
      hue = record.hue,
      state = stickState,
      activeRelics = (cached and cached.activeRelics) or {},  -- preserve from CrowdRelicChanged (story-003)
  }
  ```
- `activeRelics` is NOT in the broadcast payload (broadcast schema arch §5.7 doesn't include it). It's populated by `CrowdRelicChanged` reliable subscribed in story-003. The merge preserves whatever was last set there.
- If decode returns nil for a malformed entry inside an otherwise valid broadcast, skip just that entry (do not abort whole packet).
- `clockFn` DI per CRS §DI Requirements + ANATOMY §16; stories test stale-detection by injecting deterministic clock.

---

## Out of Scope

- story-001: module skeleton + `get` lookup + F4 helper
- story-003: reliable subscribers (CrowdCreated/Destroyed/Eliminated/RelicChanged) — those write to `_crowds` directly + populate `activeRelics`
- story-004: server-side transport phase machine (Dormant → Active → Closing)
- Foundation network-layer-ext story-003: buffer codec — already shipped

---

## QA Test Cases

- **AC-2**: Encode 30-byte buffer w/ known fields via Foundation codec; pass through `_onBroadcast`; verify `_crowds[crowdId]` reflects round-tripped values within f32 epsilon (0.001 studs for radius/pos; exact for count/hue/state/tick).
- **AC-3**: 29-byte malformed buffer; `_onBroadcast` invoked; cache unchanged; warn log emitted; no error.
- **AC-5 (F2 stale)**: clockFn injection. `_lastBroadcastTime["A"] = T`. clockFn returns `T+0.499` → `broadcast_stale("A") == false`. clockFn returns `T+0.5` → `broadcast_stale("A") == true`. clockFn returns `T+0.6` → still `true`.
- **AC-11 (defensive)**: Cache has `_crowds["A"].state = "Eliminated"`. Inject broadcast for A w/ `tick=newer, state=Active, count=100`. Post-call: `_crowds["A"].state == "Eliminated"` (sticky), `_crowds["A"].count == 100` (other field updated), `_lastReceivedTick["A"]` updated.
- **AC-17 (stale freeze)**: Inject broadcast at T=0 w/ `pos=(10,0,10), count=75`. clockFn advances to T+0.6. `get(crowdId)` returns the cached record unchanged. `broadcast_stale("A") == true`.
- **AC-20 (idempotent overwrite)**: 50 broadcasts in sequence with `count = i` for i=1..50, ticks 1..50. After all: `_crowds["A"].count == 50` (last value), not sum (1275). Edge: stale packet (older tick) in middle is ignored.
- **Multi-record packet**: 2-crowd broadcast (60-byte buffer). Both crowds updated; both in `_lastReceivedTick`.
- **First reception (cache miss)**: empty cache; broadcast for A; `_crowds["A"]` populated from full record. `activeRelics` defaults to `{}` (no prior CrowdRelicChanged for A).

---

## Test Evidence

`tests/unit/crowd-state-client/broadcast_subscriber_test.luau` (decode + idempotent + multi-record) + `tests/unit/crowd-state-client/eliminated_terminal_test.luau` (AC-11) + `tests/unit/crowd-state-client/stale_freeze_test.luau` (AC-5/17 + clockFn DI).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (mirror module + tick_is_newer); Foundation `network-layer-ext` story-001 (UREvent wrapper) + story-003 (BufferCodec.CrowdState.decode); CSM story-008 (server fires the broadcast)
- Unlocks: story-003 (reliable subscribers populate same cache); HUD/Nameplate/FollowerEntity consume cache
