# Story 003: Reliable signal subscribers + 4 client signals + late-reliable handling

> **Epic**: crowd-replication-broadcast
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-replication-strategy.md` §Core Rules + §AC-13/19/21
**Requirement**: `TR-crs-011` (5 reliable named events client subscribers), `TR-crs-012` (signal fanout to consumers), `TR-crs-021` (cross-channel ordering advisory)
**ADR**: ADR-0001 §Key Interfaces (5 reliable named events: CrowdCreated/Destroyed/Eliminated/CountClamped/RelicChanged); arch §5.7.
**ADR Decision Summary**: Client subscribes 5 reliable RemoteEvents (`CrowdCreated`, `CrowdDestroyed`, `CrowdEliminated`, `CrowdCountClamped`, `CrowdRelicChanged`). Each writes to the shared `_crowds` cache established in story-001/002. CrowdStateClient exposes 4 BindableEvent-style signals (`CrowdCreated / CrowdDestroyed / CrowdEliminated / CrowdRelicChanged` — internal client signals; `CrowdCountClamped` is owner-only HUD signal not re-fanned-out) that downstream consumers (HUD, Nameplate, Follower Entity, VFX Manager) subscribe to.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Reliable RemoteEvent (LOW); BindableEvent for client-internal signals (LOW).

**Control Manifest Rules (Presentation):**
- Required (manifest L226-L238): client modules subscribe via `Network.connectEvent`; never reach to RemoteEvent instance directly.

---

## Acceptance Criteria

- [ ] **AC-13 (Relic-grant + count ordering)** — `CrowdRelicChanged` reliable + `CrowdStateBroadcast` arrive in either order; client cache correctly reflects relics from `CrowdRelicChanged` AND count/radius/pos from broadcast regardless of order; relic state never overwritten by broadcast (broadcast does NOT carry `activeRelics`).
- [ ] **AC-19 (Reliable arrives first before broadcast)** — Cache has no entry for `crowdId="A"`. Reliable `CrowdCreated` arrives carrying `{crowdId="A", hue=3, initialCount=10}` BEFORE any broadcast for A. `get("A")` returns partial record w/ `hue=3` + count=10 + other fields zero/default; no error. First broadcast for A completes the record w/ live values.
- [ ] **AC-21 (Reliable exactly-once)** — Server fires N=100 reliable events over 10s; client-side receipt counter == 100 (no drops, no duplicates).
- [ ] Client subscribes 5 reliable RemoteEvents at module init via `Network.connectEvent(RemoteEventName.X, handler)`:
  - `CrowdCreated` → handler creates partial record with `hue, count=initialCount, state="Active"` (or merges into existing if broadcast pre-populated it)
  - `CrowdDestroyed` → handler removes `_crowds[crowdId]` and `_lastReceivedTick[crowdId]`; fires client `CrowdDestroyed` BindableEvent
  - `CrowdEliminated` → handler sets `_crowds[crowdId].state = "Eliminated"` (terminal flag set; story-002's broadcast subscriber respects via AC-11); fires client `CrowdEliminated` BindableEvent
  - `CrowdCountClamped` → handler fires client `CrowdCountClamped` BindableEvent (HUD-only; does NOT mutate cache — `count` already reflected in broadcast)
  - `CrowdRelicChanged` → handler updates `_crowds[crowdId].activeRelics = payload.activeRelics` (full snapshot per CSM story-003); fires client `CrowdRelicChanged` BindableEvent
- [ ] CrowdStateClient exposes 4 BindableEvent-style signals as module fields:
  - `CrowdCreated: BindableEvent` — fires `(crowdId)` after cache population
  - `CrowdDestroyed: BindableEvent` — fires `(crowdId)` after cache removal
  - `CrowdEliminated: BindableEvent` — fires `(crowdId)` after state-set
  - `CrowdRelicChanged: BindableEvent` — fires `(crowdId, activeRelics)` after relic-update
- [ ] AC-19 partial-record initialization on reliable-first: `CrowdCreated` handler populates `{crowdId, hue, count=initialCount, state="Active", position=Vector3.zero, radius=2.5, tick=0, activeRelics={}}` if no cache entry exists.
- [ ] On `CrowdDestroyed`, also clear `_lastReceivedTick[crowdId]` so a re-creation later can accept tick=0 broadcasts.
- [ ] Late-arriving reliable AFTER `CrowdDestroyed` (cache miss): subscriber handlers gracefully no-op when `_crowds[crowdId] == nil` (except `CrowdCreated` which populates).

---

## Implementation Notes

- All 4 BindableEvents allocated at module init: `CrowdStateClient.CrowdCreated = Instance.new("BindableEvent")`, etc. Pattern matches CSM `CountChanged` BindableEvent (CSM story-002).
- `CrowdRelicChanged` payload from CSM story-003 = `{crowdId, activeRelics: {string}}` full snapshot. Client overwrite is total replacement — no diff math.
- AC-13 ordering tolerance: broadcast carries `count/pos/radius/hue/state/tick`. Reliable `CrowdRelicChanged` carries `activeRelics`. Different fields, no overwrite conflict. Broadcast-first → cache populated except activeRelics; reliable arrives → activeRelics field added. Reliable-first → activeRelics + minimal fields; broadcast arrives → broadcast fields fill in. Either order → cache eventually consistent.
- AC-21 exactly-once: Roblox reliable RemoteEvent guarantees in-order delivery + no drops + no duplicates within a single connection lifetime. Client counter just tallies handler invocations. The AC is mostly an integration validation that no double-subscription or handler bug introduces drops.

---

## Out of Scope

- story-001: module skeleton + tick_is_newer
- story-002: broadcast subscriber (handles broadcast-side updates; this story handles reliable-side)
- story-004: server-side broadcast loop transport phase
- HUD / Nameplate / Follower Entity / VFX Manager: those subscribe to this module's BindableEvents — their epic owns subscription.

---

## QA Test Cases

- **AC-13 (broadcast-then-reliable)**: Inject broadcast for A w/ count=50. Then inject `CrowdRelicChanged(A, {"Wingspan"})`. `_crowds["A"]` has `count=50, activeRelics={"Wingspan"}`. Edge: subsequent broadcast for A — `count` updates, `activeRelics` preserved.
- **AC-13 (reliable-then-broadcast)**: Inject `CrowdRelicChanged(A, {"TollBreaker"})`. Cache miss; cache initialized via reliable handler? — actually `CrowdRelicChanged` SHOULD only fire after `CrowdCreated`. For test fixture, manually pre-populate via CrowdCreated. Then inject `CrowdRelicChanged(A, {"TollBreaker"})`. Then inject broadcast for A w/ count=75. Final: count=75, activeRelics={"TollBreaker"}.
- **AC-19 (reliable-first)**: Empty cache. Inject `CrowdCreated(A, hue=3, initialCount=10)`. `get("A") ~= nil`; `get("A").hue == 3`, `get("A").count == 10`. Then inject broadcast for A. Cache fields updated from broadcast; `hue` overwritten by broadcast (also hue=3 on server side per AC-22).
- **AC-21 (exactly-once)**: Fire 100 `CrowdRelicChanged` events with deterministic payloads server-side over 10s. Client-side counter increments per handler call. Final = 100. No drops, no duplicates. (This is engine-guarantee verification; integration test.)
- **CrowdDestroyed clears tick**: Populate `_lastReceivedTick["A"] = 50`. Inject `CrowdDestroyed(A)`. `_crowds["A"] == nil`, `_lastReceivedTick["A"] == nil`. Subsequent `CrowdCreated(A)` succeeds.
- **Late reliable after destroy**: After AC-CrowdDestroyed test, inject `CrowdRelicChanged(A, {})` — cache miss, handler no-ops (does NOT recreate cache entry).
- **BindableEvent fanout**: subscribe spy to `CrowdStateClient.CrowdCreated.Event`. Inject `CrowdCreated` reliable. Spy fires once with crowdId.

---

## Test Evidence

`tests/unit/crowd-state-client/reliable_subscribers_test.luau` (5 reliable handlers) + `tests/unit/crowd-state-client/cross_channel_ordering_test.luau` (AC-13/19) + `tests/integration/crowd-state-client/exactly_once_loopback_test.luau` (AC-21).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (cache + lookup); story-002 (cache merge respects Eliminated terminal); CSM story-001 (CrowdCreated/Destroyed fire), story-003 (CrowdRelicChanged fire), story-002 (CrowdCountClamped fire), story-006 (CrowdEliminated fire)
- Unlocks: HUD / Nameplate / Follower Entity / VFX Manager epic stories (subscribe to client BindableEvents)
