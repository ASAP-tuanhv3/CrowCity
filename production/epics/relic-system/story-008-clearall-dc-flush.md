# Story 008: clearAll T9 + DC flush via CrowdDestroyed + idempotency

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §AC-16/17/19
**Requirement**: `TR-relic-009`, `TR-relic-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 MSM/RoundLifecycle Split (T9 ordering)
**ADR Decision Summary**: `RelicSystem.clearAll()` fires at T9 (Intermission entry) AFTER `RoundLifecycle.destroyAll()`. Per-slot `onExpire` fires in ascending `slotIndex`; resets `radiusMultiplier` to 1.0; `activeRelics` empty; `CrowdRelicChanged` NOT broadcast (clients learn from MatchStateChanged Intermission). Idempotent. DC flush via `CrowdDestroyed` signal also fires onExpire per slot.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: T9 ordering: `RoundLifecycle.destroyAll → RelicSystem.clearAll → MatchStateChanged broadcast` (ADR-0005)
- Required: clearAll calls onExpire per slot in ascending slotIndex order (GDD)
- Required: clearAll does NOT broadcast CrowdRelicChanged (GDD)
- Forbidden: clearAll skip onExpire (TR-021 onExpire always fires when declared)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-16 (clearAll fires onExpire per slot, no broadcast)**: crowd with 3 Active relics (incl. Wingspan radiusMultiplier=1.35) → `clearAll()` → onExpire fires for each in ascending slotIndex order; `crowd.radiusMultiplier` resets to 1.0 (Wingspan's onExpire); `activeRelics` empty; CrowdRelicChanged NOT broadcast.
- [ ] **AC-17 (clearAll idempotent)**: clearAll called twice — no errors; onExpire not called second time; activeRelics remains empty.
- [ ] **AC-19 (DC flush via CrowdDestroyed)**: player with 2 Active relics DCs mid-round → CSM fires `CrowdDestroyed(crowdId)` signal → Relic handler fires onExpire per slot + clears to Empty; CrowdRelicChanged NOT broadcast to disconnected player (DC routing — n/a anyway).

---

## Implementation Notes

*Derived from GDD §C + ADR-0005 §T9:*

- `RelicSystem.clearAll()`:
  ```luau
  if self._cleared then return end -- idempotent
  for crowdId, slots in pairs(_slotState) do
      -- ascending slotIndex order
      local sortedKeys = {}
      for k in pairs(slots) do table.insert(sortedKeys, k) end
      table.sort(sortedKeys)
      for _, slotIndex in sortedKeys do
          local slot = slots[slotIndex]
          local spec = RelicRegistry.getById(slot.specId)
          if spec.hookSet.onExpire then RelicHooks.onExpire(spec, crowdId, slot) end
      end
  end
  -- After all onExpire fire (Wingspan resets radiusMult to 1.0 etc.):
  for crowdId in pairs(_slotState) do
      csm.clearActiveRelics(crowdId)  -- CSM API; clears activeRelics array
  end
  table.clear(_slotState)
  self._cleared = true
  -- Intentionally NO CrowdRelicChanged broadcast (GDD AC-16)
  ```
- DC flush: subscribe to `CrowdDestroyed` BindableEvent at module init:
  ```luau
  csm.CrowdDestroyed:Connect(function(crowdId)
      local slots = _slotState[crowdId]
      if not slots then return end
      local sortedKeys = {}; for k in pairs(slots) do table.insert(sortedKeys, k) end
      table.sort(sortedKeys)
      for _, slotIndex in sortedKeys do
          local slot = slots[slotIndex]
          local spec = RelicRegistry.getById(slot.specId)
          if spec.hookSet.onExpire then RelicHooks.onExpire(spec, crowdId, slot) end
      end
      _slotState[crowdId] = nil
      -- No CrowdRelicChanged broadcast (player disconnected)
  end)
  ```
- T9 wiring: `RoundLifecycle.destroyAll` chain in `start.server.luau` calls `RelicSystem.clearAll()` after `RoundLifecycle.destroyAll()` returns.
- Idempotent reset: `RelicSystem.createAll()` (or first grant) sets `self._cleared = false`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-007.
- RoundLifecycle.destroyAll T9 chain wiring (RoundLifecycle epic).
- CSM CrowdDestroyed signal (Sprint 3 closed).

---

## QA Test Cases

- **AC-16 (clearAll fires onExpire per slot)**:
  - Given: 3 Active relics on 1 crowd: TollBreaker (slot 1), Surge (slot 2), Wingspan (slot 3, radiusMult=1.35)
  - When: clearAll fires
  - Then: ordered call spy on RelicHooks.onExpire shows: TollBreakerHandler.onExpire(slot 1), SurgeHandler — but Surge has onExpire=false so skip, WingspanHandler.onExpire(slot 3); ascending slotIndex order maintained; csm.recomputeRadius(crowdId, 1.0) fires (Wingspan onExpire); CrowdRelicChanged spy shows zero calls
  - Edge cases: 0 active relics → no onExpire calls; no error.

- **AC-17 (Idempotent)**:
  - Given: clearAll called once
  - When: called second time
  - Then: zero new onExpire calls; no error
  - Edge cases: clearAll → grant → clearAll → grant works (re-init flag).

- **AC-19 (DC flush)** [Integration]:
  - Given: player with 2 active relics (TollBreaker + Wingspan); player DCs
  - When: CSM fires CrowdDestroyed
  - Then: onExpire fires for both slots in ascending order; ChestSystem.clearRelicModifier fired for TollDiscount; csm.recomputeRadius(crowdId, 1.0) fires; _slotState[crowdId] == nil
  - Edge cases: DC of player without relics → no error; CrowdDestroyed of unknown crowdId → no-op.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/clearall_dc_flush.spec.luau` — must exist and pass
- `tests/integration/relic/dc_relic_flush.spec.luau` — AC-19

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-007; CSM CrowdDestroyed signal (Sprint 3); RoundLifecycle.destroyAll T9 chain.
- Unlocks: Round lifecycle integration end-to-end.
