# Story 009: grant() guards — Eliminated reject + Pillar 3 audit + Eliminated onTick guard

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §AC-18 + §C Eliminated handling
**Requirement**: `TR-relic-011`, `TR-relic-018`, `TR-relic-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority + ADR-0011 Persistence Schema
**ADR Decision Summary**: `grant()` silently rejects on Eliminated crowd — no revival path MVP. Eliminated state: onTick continues firing (relics with onTick); count mutations land in CSM floor clamp (silent no-op since count clamped at 1). All relic state Pillar 3 round-scoped — no DataStore, no persistence — verified by `audit-persistence.sh`.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: grant(Eliminated) silent reject (GDD)
- Required: Pillar 3 — no relic persistence (ADR-0011)
- Forbidden: Revival path from relic effect (ADR-0011 — round state ephemeral)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-18 (grant() on Eliminated — silent reject)**: GIVEN crowd state == "Eliminated", WHEN `RelicEffectHandler.grant(crowdId, specId)` called, THEN grant silently rejected; `activeRelics` unchanged; no `CrowdRelicChanged` broadcast; no error.
- [ ] **TR-011 (Eliminated onTick continues; mutations no-op)**: relic with onTick Active on Eliminated crowd → onTick continues firing each Phase 2 tick; if onTick attempts updateCount → CSM floor clamp keeps count at 1 (silent no-op); no error.
- [ ] **TR-020 (Pillar 3 audit)**: `bash tools/audit-persistence.sh` returns exit 0 — no `RelicState`, `RelicInventory`, `RelicMultiplier` etc. found in `PlayerDataKey.luau` or `DefaultPlayerData.luau`.

---

## Implementation Notes

*Derived from GDD §C Eliminated + ADR-0011 Pillar 3:*

- `RelicEffectHandler.grant` head guard (already in Story 002 stub — promote to full):
  ```luau
  local crowd = csm.get(crowdId)
  if not crowd then return end
  if crowd.state == "Eliminated" then
      -- silent reject — no revival
      return
  end
  -- ... rest of grant flow (Story 002)
  ```
- Eliminated onTick: per Story 003 Phase 2 dispatch loop, iterate ALL active relics on ALL crowds (including Eliminated). The handler's onTick may attempt `csm.updateCount` — CSM clamps `[1, 300]` so attempts to mutate Eliminated crowd's count have no effect (count==1 floor). Verify via test.
- Audit-persistence: existing `tools/audit-persistence.sh` covers Pillar 3 forbidden classes. Verify Relic system additions don't introduce forbidden keys. List in audit script: `RelicState`, `RelicInventory`, `RelicMultiplier`, `RelicSlot`, `RelicCharges`, `RelicEffectiveTollMultiplier` (per ADR-0011 §Verification B).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: grant flow (this story enforces head guard).
- Story 003: Phase 2 onTick dispatch (this story tests behavior on Eliminated).
- Story 008: clearAll + DC flush.

---

## QA Test Cases

- **AC-18 (grant on Eliminated rejects silently)**:
  - Given: crowd state="Eliminated"
  - When: grant("Surge")
  - Then: spy on csm.addActiveRelic shows 0 calls; CrowdRelicChanged spy 0 calls; no error
  - Edge cases: grant of nonexistent specId on Eliminated → also silent reject (still hits early-return); grant of valid specId on Active → proceeds normally.

- **TR-011 (Eliminated onTick continues, mutations no-op)** [Integration]:
  - Given: synthetic count-relic onTick (`updateCount(_, +1, "Relic")`) Active on crowd; crowd transitions to Eliminated mid-round
  - When: 5 ticks pass post-Eliminated
  - Then: onTick fires 5 times; csm.updateCount called 5 times; crowd.count remains 1 (CSM floor clamp); no errors
  - Edge cases: down-delta onTick on Eliminated → also clamped at 1; relic without onTick → not iterated.

- **TR-020 (Audit-persistence)**:
  - Given: post-implementation
  - When: `bash tools/audit-persistence.sh`
  - Then: exit code 0
  - Edge cases: introducing PlayerDataKey.OwnedRelicMultiplier → exit 1 (audit catches).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/grant_guards.spec.luau` — must exist and pass
- `tests/integration/relic/eliminated_ontick_noop.spec.luau` — TR-011

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (grant flow); CSM Eliminated state + floor clamp (Sprint 3 closed); ADR-0011 audit-persistence script (Sprint 3 closed).
- Unlocks: Final integration test of all relic guards.
