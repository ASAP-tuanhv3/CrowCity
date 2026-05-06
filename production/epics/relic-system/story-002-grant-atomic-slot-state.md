# Story 002: Slot state machine + grant atomic + slot-cap defensive late-check

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §C
**Requirement**: `TR-relic-001`, `TR-relic-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority + ADR-0001 (CrowdRelicChanged broadcast)
**ADR Decision Summary**: `RelicEffectHandler.grant(crowdId, specId)` runs atomic sequence: late-check `#activeRelics < 4` → write slot to `crowd.activeRelics` (CSM API addActiveRelic) → fire `onAcquire` hook → broadcast `CrowdRelicChanged`. All steps inside one synchronous call; partial state never observable.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: `addActiveRelic`/`removeActiveRelic` per ADR-0004 Write-Access Matrix amendment
- Required: All remotes via Network wrapper (ADR-0006)
- Required: CrowdRelicChanged reliable RemoteEvent (ADR-0001)
- Forbidden: Direct write to `crowd.activeRelics` (ADR-0004 — CSM owns)
- Forbidden: Yield inside grant body (atomicity)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-1 (Lifecycle Empty → Offered → Active on grant)**: empty slot + #activeRelics < 4 → `RelicEffectHandler.grant(crowdId, specId)` → slot transitions to Active; activeRelics count +1; `CrowdRelicChanged` fires exactly once with new slot.
- [ ] **AC-3 (Slot cap primary guard — chest UI greyed)**: crowd has #activeRelics == 4 → ChestComponent's prompt grey + non-interactable; no toll deducted; grant never called. (Manual playtest — co-owned with Chest 002 guard 3d.)
- [ ] **AC-4 (Slot cap defensive late-check)**: race scenario — crowd already 4 relics between Chest UI resolve and grant → `grant()` returns silently; no `activeRelics` mutation; logs server-side; no `CrowdRelicChanged` broadcast.
- [ ] **AC-5 (Atomic grant sequence)**: per spec with `onAcquire`, ordered call spy shows: (1) late-check pass → (2) CSM addActiveRelic → (3) onAcquire hook completes → (4) CrowdRelicChanged broadcast. No partial state observable mid-sequence.

---

## Implementation Notes

*Derived from GDD §C + ADR-0004:*

- Internal slot state: `_slotState: {[crowdId: string]: { [slotIndex: number]: RelicSlot }}`. RelicSlot record: `{specId, slotIndex, ticksRemaining: number?, privateState: any}`.
- `RelicEffectHandler.grant(crowdId, specId)`:
  ```luau
  -- (1) Defensive late-check
  local crowd = csm.get(crowdId)
  if not crowd then return end -- silent reject AC-18 (Eliminated/destroyed)
  if crowd.state == "Eliminated" then return end -- AC-18 covered Story 009
  if #crowd.activeRelics >= 4 then logServerSide("slot cap race"); return end
  local spec = RelicRegistry.getById(specId)
  if not spec then logServerSide("unknown specId"); return end
  -- (2) Build slot
  local slotIndex = #crowd.activeRelics + 1
  local slot = { specId = specId, slotIndex = slotIndex, ticksRemaining = spec.durationTicks, privateState = clone(spec.privateStateInit) }
  -- (3) Write through CSM (sole authorized: addActiveRelic)
  csm.addActiveRelic(crowdId, slot)
  _slotState[crowdId] = _slotState[crowdId] or {}
  _slotState[crowdId][slotIndex] = slot
  -- (4) Fire onAcquire hook (Story 003 owns dispatch)
  if spec.hookSet.onAcquire then RelicHooks.onAcquire(spec, crowdId, slot) end
  -- (5) Broadcast
  Network.fireAllClients(RemoteEventName.CrowdRelicChanged, { crowdId = crowdId, slots = csm.get(crowdId).activeRelics })
  ```
- AC-3 manual playtest cross-link: Chest System Story 002 implements primary guard `#activeRelics >= 4`. This story implements DEFENSIVE late-check inside grant.
- AC-5 atomicity: code-review check that no `task.wait/defer/yield` between steps 3-5.
- Add to `RemoteName/RemoteEventName.luau`: `CrowdRelicChanged = "CrowdRelicChanged"`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: registry.
- Story 003: Hook dispatch (RelicHooks.onAcquire).
- Stories 004-006: per-relic effect routing.
- Story 008: clearAll + DC flush.
- Story 009: Eliminated grant reject (Story refines this story's silent return).

---

## QA Test Cases

- **AC-1 (Lifecycle Empty → Active)** [Integration]:
  - Given: crowd with empty activeRelics
  - When: grant(crowdId, "Surge")
  - Then: ordered spy: csm.addActiveRelic ×1; CrowdRelicChanged broadcast ×1; activeRelics has 1 slot {specId="Surge"}
  - Edge cases: grant 2nd unique relic → 2 slots, 2 broadcasts.

- **AC-4 (Slot cap defensive late-check)**:
  - Given: crowd already 4 relics (race scenario)
  - When: grant(crowdId, "Wingspan")
  - Then: spy shows zero csm.addActiveRelic calls; zero CrowdRelicChanged; log entry "slot cap race"
  - Edge cases: count exactly 4 → reject; count 3 → accept (1 free slot).

- **AC-5 (Atomic sequence)**:
  - Given: spec with onAcquire=true; ordered-call spy across addActiveRelic + onAcquire + broadcast
  - When: grant fires
  - Then: log shows: addActiveRelic → onAcquire → broadcast in this order; no broadcast before onAcquire completes
  - Edge cases: spec with onAcquire=false → addActiveRelic → broadcast (skip hook); still atomic.

- **AC-3 (Manual — chest UI)** [Visual/Feel — manual]:
  - Setup: crowd with 4 relics; approach chest
  - Verify: prompt greyed, non-interactable, no toll
  - Pass condition: documented in `production/qa/evidence/relic-slot-cap-evidence.md`.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/grant_atomic_slot_state.spec.luau` — must exist and pass
- `production/qa/evidence/relic-slot-cap-evidence.md` — manual screenshot/video for AC-3

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (registry); CSM addActiveRelic API (Sprint 3+ amendment via ADR-0004 Write-Access Matrix).
- Unlocks: Stories 003, 004, 005, 006, 007.
