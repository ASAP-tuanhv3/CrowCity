# Story 008: F2/F4 density guards — R_absorb EPSILON guard + steady-state equilibrium

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md` §F2 + §F4 + AC-16 / AC-17
**Requirement**: `TR-npc-spawner-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Density Cross-Reference
**ADR Decision Summary**: F2 R_absorb (cross-referenced with Absorb GDD F4) and F4 steady-state population formula are evaluated by NPCSpawner. Defensive guard: when `R_absorb_total <= EPSILON = 1e-6`, return `NPC_POOL_SIZE` directly (stay full — avoid divide-by-zero in steady-state math).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: F4 EPSILON guard prevents divide-by-zero (ADR-0008 + GDD F4)
- Required: F2 cross-reference matches AbsorbSystem F4 (consistency invariant per `/consistency-check`)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-16 (Absorb rate cross-reference guard, F2)**: `NPCSpawner.getAbsorbRate(crowdRadius)` matches Absorb GDD F4: `R_absorb = (radius × 2 × NPC_WALK_SPEED) × ρ_design`. Identical formula across modules (consistency).
- [ ] **AC-17 (Steady-state equilibrium F4) — deterministic mock-clock**: at saturation `R_absorb_total = R_respawn_total`, active NPC count converges to F4-derived equilibrium ± 5% over 5-min injected-clock simulation.
- [ ] **F4 EPSILON guard**: `R_absorb_total <= 1e-6` → `getSteadyStateActive()` returns `NPC_POOL_SIZE` (300) directly; no division attempted.

---

## Implementation Notes

*Derived from GDD §F2 + §F4:*

- `NPCSpawner.getAbsorbRate(crowdRadius: number): number` returns `crowdRadius * 2 * NPC_WALK_SPEED * _densityDesign`. Identity mirror of Absorb F4.
- `NPCSpawner.getSteadyStateActive(R_absorb_total: number): number`:
  - if `R_absorb_total <= EPSILON` (1e-6) return `NPC_POOL_SIZE`.
  - else return `NPC_POOL_SIZE * (R_respawn_avg / (R_absorb_total + R_respawn_avg))` per F4. (`R_respawn_avg = 1 / mean(T_respawn) = 1 / 7.5 ≈ 0.133`/s.)
- Add to `SharedConstants/NPCSpawnerConstants.luau`: `EPSILON_DENSITY = 1e-6`, `R_RESPAWN_AVG = 1 / ((NPC_RESPAWN_MIN_DELAY + NPC_RESPAWN_MAX_DELAY) / 2)` = 0.1333.
- Cross-reference test: import Absorb F4 implementation (when Absorb story-007 lands) and assert identical result for sample inputs. If Absorb not yet implemented, story remains green via NPC-side formula assertion only; full cross-test added when both land.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-007: pool/walk/respawn implementation (this story is pure formula + guard).
- Story 009: UREvent replication.
- Real F4 soak validation — covered by Story 9 + AbsorbSystem story-007 (perf soak) cross-reference.

---

## QA Test Cases

- **AC-16 (Cross-reference parity)**:
  - Given: radius=10, NPC_WALK_SPEED=4, ρ_design=0.0075
  - When: `NPCSpawner.getAbsorbRate(10)` called
  - Then: returns 10 * 2 * 4 * 0.0075 = 0.6 NPC/s; matches Absorb GDD F4 worked example
  - Edge cases: radius=0 → 0; radius=1 → 0.06.

- **AC-17 (Steady-state mock-clock)** [Logic — DI scheduler]:
  - Given: 12 crowds × radius=10, R_absorb_total = 12 × 0.6 = 7.2 NPC/s; mock clock; observe over 5 sim-minutes
  - When: simulation iterates absorb + respawn cycles
  - Then: active NPC count converges to F4 = 300 × 0.133/(7.2+0.133) ≈ 5.4 ± 5%
  - Edge cases: zero crowds → R_absorb=0; population stays at 300 (full).

- **F4 EPSILON guard**:
  - Given: `R_absorb_total = 0` (zero crowds)
  - When: `getSteadyStateActive(0)` called
  - Then: returns 300 directly; no division
  - Edge cases: `R_absorb_total = 1e-7` (below EPSILON) → returns 300; `R_absorb_total = 1e-5` → goes through formula.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/density_guards.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (`ρ_design` available); Story 005 (respawn delay constants).
- Cross-ref to: AbsorbSystem story-007 (F4 same formula); validated via `/consistency-check`.
- Unlocks: Story 009 perf soak + AbsorbSystem perf soak.
