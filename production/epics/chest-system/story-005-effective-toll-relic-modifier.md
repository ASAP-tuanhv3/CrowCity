# Story 005: F2 effective_toll + queryChestToll API + Relic modifier register

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md` §F2 + §C non-state modifiers
**Requirement**: `TR-chest-005`, `TR-chest-017`, `TR-chest-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority + GDD F2
**ADR Decision Summary**: `queryChestToll(crowdId, tier, baseToll)` chains F1 output through Relic modifiers stored in `_crowdModifiers` (per-crowd, not per-chest, registered via `setRelicModifier`/`clearRelicModifier`). Floor clamped to 1 (no zero or negative toll). `CrowdDestroyed` flushes `_crowdModifiers[crowdId]`. Toll billboard shows effective (post-query), not base.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Non-state Relic modifier API published per-system (Relic system epic story)
- Required: `setRelicModifier`/`clearRelicModifier` callable by RelicEffectHandler only (architecture §5.5)
- Forbidden: Cosmetic systems mutate toll modifier (anti-P2W per ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-8 (TollBreaker discount at FLOOR)**: GIVEN crowdId holds TollBreaker (multiplier 0.70) and opens T2 chest at count ≤ 200 (F1 returns FLOOR 40), WHEN `queryChestToll(crowdId, 2, 40)` called, THEN returns 28 (`floor(40 × 0.70)`).
- [ ] **AC-8b (TollBreaker at SCALED peak)**: count=300, F1 returns 60, queryChestToll returns 42 (`floor(60 × 0.70)`).
- [ ] **AC-17 (Non-state modifier API)**: `setRelicModifier(crowdId, "TollBreaker", 0.70, "multiply")` registers modifier. `queryChestToll(crowdId, 2, 40)` returns 28. After `clearRelicModifier(crowdId, "TollBreaker")`, returns 40. Modifiers live in `_crowdModifiers[crowdId]`, NOT per-chest.
- [ ] **AC-18 (CrowdDestroyed flush)**: `CrowdDestroyed(crowdId)` signal fires → `_crowdModifiers[crowdId] = nil`; subsequent queryChestToll uses base.
- [ ] **Floor clamp 1**: queryChestToll never returns < 1, even with multipliers ≤ 0.

---

## Implementation Notes

*Derived from GDD §F2:*

- Internal: `_crowdModifiers: {[crowdId: string]: {[modKey: string]: {factor: number, op: "multiply"|"add"}}}`.
- `setRelicModifier(crowdId, modKey, factor, op)`: assert `op == "multiply" or op == "add"`; assert factor is number; `_crowdModifiers[crowdId] = _crowdModifiers[crowdId] or {}; _crowdModifiers[crowdId][modKey] = {factor, op}`.
- `clearRelicModifier(crowdId, modKey)`: `if _crowdModifiers[crowdId] then _crowdModifiers[crowdId][modKey] = nil end`.
- `queryChestToll(crowdId, tier, baseToll)`:
  ```
  local toll = baseToll
  local mods = _crowdModifiers[crowdId]
  if mods then
      for _, mod in mods do
          if mod.op == "multiply" then toll = toll * mod.factor
          elseif mod.op == "add" then toll = toll + mod.factor end
      end
  end
  toll = math.max(1, math.floor(toll))
  return toll
  ```
- Subscribe to `CrowdDestroyed` reliable event (or BindableEvent if intra-server) at module init: handler clears `_crowdModifiers[crowdId]`.
- Toll billboard (Story 011 owner) reads via `queryChestToll(crowdId, tier, baseToll(tier, crowd.count))` — always shows current effective.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: F1 baseToll (consumed here).
- Story 006: Atomic deduction uses queryChestToll output.
- Story 011: Toll billboard rendering.
- Relic system itself (separate epic) — this story exposes the API for Relic to call.

---

## QA Test Cases

- **AC-8 (TollBreaker discount FLOOR)**:
  - Given: setRelicModifier("c1", "TollBreaker", 0.70, "multiply"); count=100
  - When: queryChestToll("c1", 2, 40)
  - Then: returns 28
  - Edge cases: factor 1.0 → returns 40; factor 0.0 → returns 1 (floor clamp); negative factor → returns 1.

- **AC-8b (Scaled peak)**:
  - Given: same modifier, count=300, F1 returns 60
  - When: queryChestToll("c1", 2, 60)
  - Then: returns 42
  - Edge cases: 300 × 0.20 = 60 → × 0.70 = 42 floored.

- **AC-17 (Modifier register/clear)**:
  - Given: register, query, clear, re-query
  - When: sequence
  - Then: 28 / 40 across the cycle
  - Edge cases: clear non-existent modifier — no error; multiple modifiers stack (multiply: 0.70 then 0.50 → 0.35 effective).

- **AC-18 (CrowdDestroyed flush)**:
  - Given: modifier set; CrowdDestroyed("c1") fires
  - When: queryChestToll("c1", 2, 40)
  - Then: returns 40 (modifier flushed)
  - Edge cases: re-set after flush works; subsequent `CrowdDestroyed` for unknown crowdId is no-op.

- **Floor clamp**:
  - Given: factor=0.001, count=100
  - When: queryChestToll
  - Then: returns 1 (clamped)
  - Edge cases: integer arithmetic — `math.floor(0.04) = 0` → clamped to 1.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/effective_toll_relic_modifier.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (baseToll); Story 002 guard 3f calls queryChestToll; CrowdDestroyed signal (CSM Sprint 3 — assumed present).
- Unlocks: Story 006 (uses effective toll for deduction); Relic system stories (consumers of setRelicModifier).
