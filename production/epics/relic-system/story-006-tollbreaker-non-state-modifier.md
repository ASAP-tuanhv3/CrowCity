# Story 006: TollBreaker — non-state modifier publish to Chest System

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §G TollBreaker + §AC-10/20/21 + §F1
**Requirement**: `TR-relic-006`, `TR-relic-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority (Pillar 4 anti-P2W) + Chest System integration
**ADR Decision Summary**: TollBreaker is a non-state modifier — publishes effect to ChestSystem via `setRelicModifier(crowdId, "TollDiscount", 0.70, "multiply")` on acquire and `clearRelicModifier(crowdId, "TollDiscount")` on expire. ChestSystem queryChestToll consumes (Chest story 005). F1 effective_toll_chain: floor clamp ≥ 1; nil onChestOpen returns treated as identity (1.0).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Non-state modifier published to consumer (Chest) per architecture §5.5
- Required: ChestSystem.setRelicModifier/clearRelicModifier sole callers — RelicEffectHandler (architecture §5.5)
- Forbidden: Mutate any CSM field for cosmetic non-state modifier (ADR-0004 — Pillar 4)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-10 (Non-state modifier publishes)**: TollBreaker granted → onAcquire fires `ChestSystem.setRelicModifier(crowdId, "TollDiscount", 0.70, "multiply")` once; onExpire fires `ChestSystem.clearRelicModifier(crowdId, "TollDiscount")`.
- [ ] **AC-20 (F1 TollBreaker T2 toll chain)**: TollBreaker M=0.70 Active → `RelicEffectHandler.queryChestToll(crowdId, 2, 40)` returns `floor(40 × 0.70) = 28`. (Or alternate path: ChestSystem.queryChestToll directly via Story 005 Chest module — depending on which side owns the wrapper.)
- [ ] **AC-21 (nil onChestOpen treated as 1.0)**: synthetic relic whose onChestOpen returns nil → handler substitutes 1.0 identity; logs warning; toll unchanged by that slot; no error propagates.
- [ ] **TR-015 (TollBreaker formula)**: `F1 toll = floor(baseToll × M); floor >= 1` — implementation tests boundary cases.

---

## Implementation Notes

*Derived from GDD §G TollBreaker + §F1 + Chest Story 005:*

- `TollBreakerHandler.luau`:
  ```luau
  local TollBreakerHandler = {}

  function TollBreakerHandler.onAcquire(crowdId, slot)
      local mult = slot.privateState.multiplier -- 0.70
      local key = slot.privateState.modKey -- "TollDiscount"
      ChestSystem.setRelicModifier(crowdId, key, mult, "multiply")
  end

  function TollBreakerHandler.onExpire(crowdId, slot)
      local key = slot.privateState.modKey
      ChestSystem.clearRelicModifier(crowdId, key)
  end

  function TollBreakerHandler.onChestOpen(crowdId, slot, tier, baseToll)
      -- Per F1 onChestOpen contract: returns multiplier or nil for identity
      return slot.privateState.multiplier
  end

  RelicHooks.register("TollBreaker", {
      onAcquire = TollBreakerHandler.onAcquire,
      onExpire = TollBreakerHandler.onExpire,
      onChestOpen = TollBreakerHandler.onChestOpen,
  })

  return TollBreakerHandler
  ```
- F1 wrapper option (decide impl): either use ChestSystem.queryChestToll directly (Chest Story 005) OR add `RelicEffectHandler.queryChestToll(crowdId, tier, baseToll)` that iterates Active relics calling onChestOpen and chains multipliers. AC-20 mentions `RelicEffectHandler.queryChestToll` — implement that wrapper:
  ```luau
  function RelicEffectHandler.queryChestToll(crowdId, tier, baseToll)
      local crowd = csm.get(crowdId); if not crowd then return baseToll end
      local toll = baseToll
      for _, slot in crowd.activeRelics do
          local spec = RelicRegistry.getById(slot.specId)
          if spec.hookSet.onChestOpen then
              local mult = RelicHooks.onChestOpen(spec, crowdId, slot, tier, baseToll)
              if mult == nil then
                  warn(("nil onChestOpen for slot %s; using identity"):format(slot.specId))
                  mult = 1.0
              end
              toll = toll * mult
          end
      end
      return math.max(1, math.floor(toll))
  end
  ```
- This wrapper is parallel to Chest's `queryChestToll` (Chest Story 005 owns the modifier-table version) — pick which authority owns the chain. **Decision**: ChestSystem owns the modifier table per architecture §5.5; RelicEffectHandler.queryChestToll iterates onChestOpen hooks. The two paths converge on AC-20 result. **MVP simplification**: Use Chest's modifier-table path only (set/clear publish from this story); skip the onChestOpen iteration wrapper for MVP. AC-20 then verified via Chest Story 005 path. Mark AC-21 (nil onChestOpen) as DEFERRED to VS+ — onChestOpen iteration not needed for MVP TollBreaker.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-005.
- Chest Story 005: queryChestToll modifier-table path (consumer of setRelicModifier from this story).
- AC-21 nil-onChestOpen handling — DEFERRED to VS+ (no relic uses onChestOpen-iteration MVP).

---

## QA Test Cases

- **AC-10 (Publish to Chest)**:
  - Given: crowd Active; ChestSystem.setRelicModifier + clearRelicModifier spies
  - When: grant("TollBreaker"); later expire
  - Then: setRelicModifier called once `(crowdId, "TollDiscount", 0.70, "multiply")`; clearRelicModifier called once on expire
  - Edge cases: re-grant after clear → set again.

- **AC-20 (Effective toll T2 → 28)** [Integration with Chest Story 005]:
  - Given: TollBreaker Active; Chest queryChestToll(crowdId, 2, 40) called
  - When: chain through modifier table
  - Then: returns 28
  - Edge cases: floor clamp — multiplier 0.001 → floor(40*0.001)=0 → clamp to 1.

- **AC-21 (nil onChestOpen — DEFERRED)**:
  - Status: deferred to VS+ when relic uses onChestOpen iteration; not required MVP.

- **No CSM mutation**:
  - Given: TollBreakerHandler source
  - When: grep `csm\.update\|csm\.recompute`
  - Then: zero matches (TollBreaker only writes to ChestSystem modifier table)
  - Edge cases: defends Pillar 4 anti-P2W.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/tollbreaker_non_state.spec.luau` — must exist and pass
- `tests/integration/relic/tollbreaker_chest_chain.spec.luau` — AC-20 cross-system

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-003; Chest Story 005 (setRelicModifier/clearRelicModifier API).
- Unlocks: Vertical Slice playtest with toll-discount relic gameplay.
