# Story 005: Wingspan — radius multiplier via recomputeRadius

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §G Wingspan + §AC-9/22 + §F2
**Requirement**: `TR-relic-005`, `TR-relic-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority §recomputeRadius
**ADR Decision Summary**: Wingspan handler writes `radiusMultiplier` via sole-caller API `csm.recomputeRadius(crowdId, multiplier)` with multiplier ∈ `[0.5, 1.5]` validated. CSM stores radiusMultiplier and recomputes composed `crowd.radius = (2.5 + sqrt(count) × 0.55) × radiusMultiplier`. Absorb + Collision read post-multiplied radius — relic-unaware.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: `recomputeRadius(crowdId, multiplier)` sole caller — RelicEffectHandler (ADR-0004)
- Required: multiplier validated `[0.5, 1.5]` (ADR-0004)
- Required: composed radius = `(2.5 + sqrt(count) * 0.55) * radiusMultiplier` (manifest)
- Forbidden: Direct write to `crowd.radius` or `crowd.radiusMultiplier` outside CSM API

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-9 (Wingspan radius multiplier write)**: Wingspan granted to crowd count=100 → onAcquire fires `recomputeRadius(crowdId, 1.35)`; CSM stores multiplier=1.35 and computes radius = `radius_from_count(100) × 1.35 = 8.00 × 1.35 = 10.80` ± 0.01.
- [ ] **AC-22 (Multiplier persists; Absorb + Collision read post-multiplied)**: Wingspan Active on crowd count=300 → `crowd.radius = 12.03 × 1.35 = 16.24` ± 0.01; Absorb F1 + Collision F1 use this value with no relic awareness; no stale pre-multiplied value cached anywhere.
- [ ] **onExpire resets multiplier**: when slot expires (clearAll or duration end), `recomputeRadius(crowdId, 1.0)` fires; radius returns to `radius_from_count(count) × 1.0`.

---

## Implementation Notes

*Derived from GDD §G Wingspan + §F2:*

- `WingspanHandler.luau`:
  ```luau
  local WingspanHandler = {}

  function WingspanHandler.onAcquire(crowdId, slot)
      local mult = slot.privateState.radiusMultiplier -- 1.35 from registry
      csm.recomputeRadius(crowdId, mult)
  end

  function WingspanHandler.onExpire(crowdId, slot)
      csm.recomputeRadius(crowdId, 1.0)
  end

  RelicHooks.register("Wingspan", {
      onAcquire = WingspanHandler.onAcquire,
      onExpire = WingspanHandler.onExpire,
  })

  return WingspanHandler
  ```
- AC-22 verification: integration test instantiates a CSM mock that exposes the actual `radius_from_count + multiplier` composition path; reads `crowd.radius` post-onAcquire; spot-checks Absorb F1 (Story 002 of Absorb epic) consumes the post-multiplied value.
- onExpire path: reset to 1.0 (no-op if multiplier was already 1.0). CSM does not auto-reset on slot remove — handler MUST.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-003.
- Story 004: Surge.
- Story 006: TollBreaker.
- CSM `recomputeRadius` impl (already in CSM Sprint 3 — Batch 1 amendment).

---

## QA Test Cases

- **AC-9 (Wingspan applies multiplier)**:
  - Given: crowd count=100
  - When: grant("Wingspan")
  - Then: csm.recomputeRadius spy called `(crowdId, 1.35)`; crowd.radius == 10.80 ± 0.01
  - Edge cases: count=1 → radius_from_count(1)=2.5+0.55=3.05 × 1.35 = 4.118; count=300 → 12.03 × 1.35 = 16.24.

- **AC-22 (Post-multiplied radius read by Absorb + Collision)** [Integration]:
  - Given: Wingspan Active on crowd count=300
  - When: Absorb Phase 3 reads crowd.radius
  - Then: reads 16.24 (not 12.03); F1 overlap test uses radiusSq=263.7
  - Edge cases: simultaneously Surge + Wingspan — both apply (count up + radius mult); recomputeRadius fires once per relic onAcquire.

- **onExpire resets**:
  - Given: Wingspan Active; crowd.radiusMultiplier=1.35
  - When: clearAll fires onExpire
  - Then: csm.recomputeRadius spy called `(crowdId, 1.0)`; crowd.radiusMultiplier == 1.0
  - Edge cases: re-grant Wingspan after expire → multiplier back to 1.35.

- **Multiplier validation [0.5, 1.5]**:
  - Given: synthetic relic with multiplier=2.0 (out of range)
  - When: onAcquire calls csm.recomputeRadius(_, 2.0)
  - Then: CSM assertion fires (per ADR-0004 §multiplier validated)
  - Edge cases: 0.5 + 1.5 boundaries inclusive; 0.49 / 1.51 reject.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/wingspan_radius_multiplier.spec.luau` — must exist and pass
- `tests/integration/relic/wingspan_post_multiplied_read.spec.luau` — AC-22

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-003; CSM recomputeRadius API (Sprint 3 closed via CSM Batch 1).
- Unlocks: Vertical Slice playtest with radius-relic gameplay.
