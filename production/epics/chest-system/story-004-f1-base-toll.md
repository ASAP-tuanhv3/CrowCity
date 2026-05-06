# Story 004: F1 base_toll_scaled formula

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md` §F1
**Requirement**: `TR-chest-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: GDD-internal F1 (Batch 5 DSN-B-2 resolution 2026-04-24)
**ADR Decision Summary**: F1 `base_toll_scaled(tier, count) = max(T_FLAT[tier], ceil(count × T_PCT[tier]))`. T_FLAT = floor; scales with count when count grows large. Per-tier T_FLAT and T_PCT in registry. No relic input — Story 005 chains.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Per-tier ChestSpec constants from registry (T1_TOLL/T1_TOLL_PCT etc.)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-7 (Toll deduction at floor — T2 count=100)**: F1 `base_toll_scaled(2, 100) = max(40, ceil(100 × 0.20)) = 40` (FLOOR — count not yet large).
- [ ] **AC-7b (Scaled at peak — T2 count=300)**: F1 `base_toll_scaled(2, 300) = max(40, ceil(300 × 0.20)) = 60` (SCALED branch).
- [ ] **AC-9 (Count-at-floor reject — T1 count=10)**: F1 `base_toll_scaled(1, 10) = max(10, ceil(10 × 0.08)) = 10`; guard 3f rejects when `count <= effectiveToll` (10 <= 10 → reject).
- [ ] **Formula correct across all tiers**: T1_TOLL=10/PCT=0.08; T2_TOLL=40/PCT=0.20; T3_TOLL=120/PCT=0 (flat — already 40% of MAX 300).

---

## Implementation Notes

*Derived from GDD §F1 + registry:*

- Constants in `SharedConstants/ChestSystemConstants.luau` per registry post-Batch 5:
  - `T1_TOLL = 10`, `T1_TOLL_PCT = 0.08`
  - `T2_TOLL = 40`, `T2_TOLL_PCT = 0.20`
  - `T3_TOLL = 120`, `T3_TOLL_PCT = 0` (flat at peak — already 40% of 300)
- Implementation:
  ```luau
  local T_FLAT = { [1]=T1_TOLL, [2]=T2_TOLL, [3]=T3_TOLL }
  local T_PCT  = { [1]=T1_TOLL_PCT, [2]=T2_TOLL_PCT, [3]=T3_TOLL_PCT }
  function ChestSystem.baseToll(tier: number, count: number): number
      return math.max(T_FLAT[tier], math.ceil(count * T_PCT[tier]))
  end
  ```
- Pure function — no side effects. Story 005 wraps with `queryChestToll` adding relic chain.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: F2 + queryChestToll relic chain (consumes baseToll output).
- Story 006: Atomic claim using effective toll.

---

## QA Test Cases

- **AC-7 (T2 count=100, FLOOR)**:
  - Given: tier=2, count=100
  - When: baseToll(2, 100)
  - Then: returns 40
  - Edge cases: count=199 → max(40, ceil(39.8)=40) = 40; count=200 → max(40, ceil(40.0)=40) = 40; count=201 → max(40, 41) = 41 (transition to scaled).

- **AC-7b (T2 count=300, SCALED)**:
  - Given: tier=2, count=300
  - When: baseToll(2, 300)
  - Then: returns 60
  - Edge cases: count=250 → max(40, 50) = 50; count=300 → 60; count=1 → max(40, 1) = 40 (FLOOR).

- **AC-9 (T1 count=10 boundary)**:
  - Given: tier=1, count=10
  - When: baseToll(1, 10)
  - Then: returns 10
  - Edge cases: count=125 → max(10, ceil(10.0)=10) = 10; count=126 → max(10, 11) = 11.

- **All tiers cross-check**:
  - Given: tier ∈ {1, 2, 3}, count ∈ {1, 10, 100, 200, 300}
  - When: baseToll
  - Then: matches GDD §F1 worked examples
  - Edge cases: tier=4 (invalid) → assertion / nil index error documented.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/f1_base_toll.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (constants module exists).
- Unlocks: Story 005 (queryChestToll wraps baseToll), Story 002 guard 3f.
