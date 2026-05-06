# Story 004: Idle walk + boundary reflection (Heartbeat tick callback)

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md` §Core Rules + §F (idle walk) + §AC-02 / AC-04 / AC-06
**Requirement**: `TR-npc-spawner-004`, `TR-npc-spawner-007`, `TR-npc-spawner-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Movement Loop
**ADR Decision Summary**: NPCs walk on a 15 Hz Heartbeat-driven tick. Per NPC: pick a uniform-random direction, walk for `T_walk ∈ [2s, 5s]`, then re-pick. Reflect off arena boundaries (no AABB hit; bounce to keep inside). MVP convex single-level assumption — NPCs phase through obstacles.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `os.clock` for time tracking; CFrame translation per dt.

**Control Manifest Rules (Feature layer)**:
- Required: NPCSpawner own Heartbeat — single connection at 15 Hz cadence (ADR-0002 exemption + ADR-0008)
- Required: Walk loop reads ARENA bounds from workspace attribute (ADR-0008)
- Forbidden: NPC mutate any CSM field (ADR-0004 + ADR-0008)
- Forbidden: NPC pathfinding / Humanoid usage — bare CFrame translation only (ADR-0001 + ADR-0008)
- Guardrail: 60 visible NPC instance cap per client (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-02 (Initial separation respected)**: at `createAll` complete, every NPC pair separated by ≥ `NPC_MIN_INITIAL_SEP = 2.5m` (defensive — no two NPCs spawned overlapping).
- [ ] **AC-04 (Walk timer in bounds)**: each NPC's `T_walk` sample is `Uniform[2.0, 5.0]` seconds (deterministic test using injected RNG).
- [ ] **AC-06 (Boundary reflection)**: NPC at arena edge with velocity heading out → next tick, position remains inside arena, velocity reflected component flipped.
- [ ] **15 Hz cadence**: tick callback fires at 15 Hz via own Heartbeat accumulator (not per-Heartbeat-frame).

---

## Implementation Notes

*Derived from ADR-0008 §Movement Loop:*

- Heartbeat callback (Story 001) accumulates `dt` until `≥ NPC_TICK_PERIOD = 1/15`; on tick, iterate active NPCs:
  - if `t_now - npc._walkStart >= npc._walkDur`, re-pick: `npc._heading = uniform(0, 2π)`, `npc._walkDur = uniform(T_WALK_MIN, T_WALK_MAX)`, `npc._walkStart = t_now`.
  - compute `dx = cos(heading) * NPC_WALK_SPEED * tickPeriod`; `dz = sin(heading) * NPC_WALK_SPEED * tickPeriod`.
  - if new pos `(x+dx, z+dz)` outside arena bounds, reflect: flip the component crossing boundary.
  - write `Part.CFrame = CFrame.new(newX, npc.lastY, newZ)`.
- Constants (extend `NPCSpawnerConstants.luau`): `T_WALK_MIN = 2.0`, `T_WALK_MAX = 5.0`, `NPC_MIN_INITIAL_SEP = 2.5`.
- Initial separation (`createAll` site): use halton-sequence or simple grid jitter to seed positions ≥ 2.5m apart. Cap retry count at 100 per NPC; if no valid pos found, raise (small enough cap that 300 NPCs in 40000 sq-m never fails).
- Inject `random()` at module init for deterministic tests (DI seed). Production uses `Random.new()`.
- MVP convex assumption: arena is rectangular bounds `(minX, maxX, minZ, maxZ)` from workspace attributes. No raycast against geometry; NPCs phase through walls (TR-007).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: respawn pipeline (Walk loop applies to active NPCs only).
- Story 006: respawn fade-in.
- Pathfinding / Humanoid integration — explicitly forbidden by ADR-0008 (MVP simplification).

---

## QA Test Cases

- **AC-02 (Initial separation)**:
  - Given: ARENA = 200x200; pool = 300; min sep = 2.5
  - When: `createAll()` complete
  - Then: pairwise distance min ≥ 2.5
  - Edge cases: tight arena (2.5x300² > area) → assertion at init that arena is large enough.

- **AC-04 (Walk timer)**:
  - Given: injected RNG with fixed seed
  - When: 1000 NPC walk re-picks observed
  - Then: all `_walkDur` ∈ [2.0, 5.0]; mean ≈ 3.5 ± 0.05
  - Edge cases: re-pick fires precisely at t == _walkStart + _walkDur.

- **AC-06 (Boundary reflection)**:
  - Given: NPC at `(199, 0, 0)`, ARENA maxX = 200, heading = 0 (positive X), speed = 4
  - When: 1 tick (dt = 1/15)
  - Then: new pos X stays ≤ 200; heading flipped to π; dz unchanged
  - Edge cases: corner case (both X and Z exceed) — both components flipped; NPC starts exactly on boundary — moves away on next tick.

- **15 Hz cadence**:
  - Given: Heartbeat fires 60 fps; spy on tick body
  - When: 1 second elapses
  - Then: tick body fires exactly 15 times
  - Edge cases: low-fps frames (e.g., dt=0.1s) → catches up correctly.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/idle_walk_boundary.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool + Heartbeat exists).
- Unlocks: Story 005 (active NPCs walk; respawned NPCs re-enter walk).


## Completion Notes
**Completed**: 2026-05-06 (Sprint 5 batch close)
**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per production/review-mode.txt
**Audits**: selene 0/7/0, asset-id PASS, persistence PASS
**Test Evidence**: see story Test Evidence section — file at expected path
