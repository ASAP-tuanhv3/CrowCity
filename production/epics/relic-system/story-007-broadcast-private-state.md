# Story 007: CrowdRelicChanged broadcast on grant/expire only + privateState exclusion + duration countdown

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §C + §AC-13/14/15
**Requirement**: `TR-relic-010`, `TR-relic-013`, `TR-relic-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy
**ADR Decision Summary**: `CrowdRelicChanged` reliable RemoteEvent fires on grant/expire only — never per-tick. Payload `{ crowdId, slots: [{specId, slotIndex, ticksRemaining}] }`. `privateState` field per slot is server-only — never replicated. Duration policy: nil = round-permanent; integer countdown decremented at Phase 2 tick; expiry scan after full relic pass; `onExpire` fires + slot cleared.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Reliable RemoteEvent through Network wrapper.

**Control Manifest Rules:**
- Required: Reliable RemoteEvent for CrowdRelicChanged (ADR-0001)
- Required: privateState NEVER in broadcast payload (security/replication boundary)
- Required: Duration countdown decrement at Phase 2 (not Phase 1 / Phase 3 / etc.)
- Forbidden: Per-tick CrowdRelicChanged broadcast (bandwidth)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-13 (Duration countdown + end-of-tick expiry)**: relic with `durationTicks=5` Active → 5 server ticks complete → slot transitions to Expiring within tick 5; onExpire fires during post-tick expiry scan (after full relic pass that tick); slot cleared to Empty; CrowdRelicChanged broadcasts updated snapshot.
- [ ] **AC-14 (privateState excluded from broadcast)**: relic with `privateState = { charges = 3 }` Active → CrowdRelicChanged payload contains only `{ specId, slotIndex, ticksRemaining }` per slot; no privateState field present.
- [ ] **AC-15 (Broadcast on grant/expire only — never per-tick)**: crowd with 2 Active relics (one with onTick) → 10 ticks pass with no grant/expiry → `CrowdRelicChanged` fires 0 times during those ticks.

---

## Implementation Notes

*Derived from GDD §C + ADR-0001:*

- Duration countdown: at Phase 2 tail (after onTick dispatch loop), iterate active slots:
  ```
  local toExpire = {}
  for crowdId, slots in pairs(_slotState) do
      for slotIndex, slot in pairs(slots) do
          if slot.ticksRemaining ~= nil then
              slot.ticksRemaining -= 1
              if slot.ticksRemaining <= 0 then
                  table.insert(toExpire, {crowdId, slotIndex})
              end
          end
      end
  end
  for _, pair in toExpire do
      _expireSlot(pair[1], pair[2])  -- fires onExpire + removes slot + broadcasts
  end
  ```
- `_expireSlot(crowdId, slotIndex)`:
  ```
  local slot = _slotState[crowdId][slotIndex]
  local spec = RelicRegistry.getById(slot.specId)
  if spec.hookSet.onExpire then RelicHooks.onExpire(spec, crowdId, slot) end
  csm.removeActiveRelic(crowdId, slotIndex)
  _slotState[crowdId][slotIndex] = nil
  Network.fireAllClients(RemoteEventName.CrowdRelicChanged, _broadcastSnapshot(crowdId))
  ```
- `_broadcastSnapshot(crowdId)`:
  ```
  local crowd = csm.get(crowdId); if not crowd then return nil end
  local slots = {}
  for _, slot in crowd.activeRelics do
      table.insert(slots, { specId = slot.specId, slotIndex = slot.slotIndex, ticksRemaining = slot.ticksRemaining })
      -- privateState INTENTIONALLY excluded
  end
  return { crowdId = crowdId, slots = slots }
  ```
- AC-15 verification: blanket spy on `Network.fireAllClients(RemoteEventName.CrowdRelicChanged, ...)` over 10 ticks of no-grant/no-expire — assert zero calls.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-006: registry, grant, hook dispatch, per-relic handlers.
- Story 008: clearAll bulk expire.
- Story 010: client subscription to CrowdRelicChanged (HUD epic owns).

---

## QA Test Cases

- **AC-13 (Duration countdown)**:
  - Given: synthetic relic with durationTicks=5 Active on crowd
  - When: 5 ticks fire
  - Then: at tick 5 Phase 2 tail, slot expires; onExpire fires; CrowdRelicChanged broadcasts new snapshot (now empty for that slot)
  - Edge cases: duration=1 → expires next tick; duration=0 → expires immediately at first tick; duration=nil → never expires.

- **AC-14 (privateState excluded)**:
  - Given: relic with privateState={charges=3} active
  - When: broadcast fires (on grant)
  - Then: payload spy shows slots[i] has only {specId, slotIndex, ticksRemaining}; no `charges` / no `privateState`
  - Edge cases: empty privateState → still excluded (no field).

- **AC-15 (Broadcast on grant/expire only)**:
  - Given: 2 Active relics (one onTick); injected clock; spy on CrowdRelicChanged broadcast
  - When: 10 ticks pass with no grant or expiry
  - Then: spy shows 0 calls
  - Edge cases: grant on tick 5 → 1 broadcast; expire on tick 10 → 1 broadcast; total 2 over 10 ticks.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/broadcast_private_state.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002 (grant + broadcast), 003 (hook dispatch site).
- Unlocks: HUD slot bar (HUD epic consumes broadcast).
