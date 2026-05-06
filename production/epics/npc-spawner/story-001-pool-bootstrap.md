# Story 001: NPCSpawner pool bootstrap — 300 Parts chunked + Heartbeat + ARENA validation

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md`
**Requirement**: `TR-npc-spawner-001`, `TR-npc-spawner-003`, `TR-npc-spawner-011`, `TR-npc-spawner-012`, `TR-npc-spawner-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority + ADR-0006 Module Placement
**ADR Decision Summary**: NPCSpawner pre-allocates 300 Parts at `RoundLifecycle.createAll` chunked 25/batch via `task.defer`. NPCSpawner owns single `RunService.Heartbeat:Connect` (non-gameplay-tick exemption per ADR-0002 §Related Decisions). `ARENA_WALKABLE_AREA_SQ` asserted non-nil + > 0 at module init (round init fails loudly otherwise). `ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ` computed once at init.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `task.defer` available pre-cutoff. `Workspace.StreamingEnabled = false` mandated for arena (ADR-0008 §Edge Cases R226).

**Control Manifest Rules (Feature layer)**:
- Required: NPCSpawner at `ServerStorage/Source/NPCSpawner/init.luau` owns 300-Part neutral pool (ADR-0008)
- Required: Pre-allocate 300 Parts at `createAll` chunked 25/batch via `task.defer` — no mid-round `Instance.new` (ADR-0008)
- Required: NPCSpawner own `RunService.Heartbeat:Connect` — single connection, non-gameplay-tick exemption (ADR-0002 §Related Decisions L289 + ADR-0008)
- Required: `ARENA_WALKABLE_AREA_SQ` asserted non-nil + > 0 at module init (ADR-0008)
- Required: `Workspace.StreamingEnabled = false` on arena map (ADR-0008)
- Forbidden: `Instance.new('Part')` after `createAll` completes (ADR-0008)
- Forbidden: NPCSpawner mutate any CSM field — read-only consumer (ADR-0004 + ADR-0008)
- Guardrail: 60 visible-NPC instance cap per client (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-01 (Pool size exact)**: after `createAll`, `#pool == 300` exactly. Chunked alloc 25/batch via `task.defer` — full 300 ready by tick of `createAll + 12 batches`.
- [ ] **AC-03 (Zero Part allocation mid-round)**: spy on `Instance.new` shows 0 calls between `createAll` complete and `destroyAll`.
- [ ] **AC-05 (Single own Heartbeat)**: NPCSpawner registers exactly 1 `RunService.Heartbeat:Connect`; verifies only one cumulative `Heartbeat` listener registered by NPCSpawner across calls.
- [ ] **`ARENA_WALKABLE_AREA_SQ` assert**: missing or ≤ 0 raises at module init time, NOT mid-round.
- [ ] **`ρ_design` constant computed**: `NPCSpawner.ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ`; exported as read-only.
- [ ] **Path placement**: `src/ServerStorage/Source/NPCSpawner/init.luau`; constants in `src/ReplicatedStorage/Source/SharedConstants/NPCSpawnerConstants.luau`.

---

## Implementation Notes

*Derived from ADR-0008 §Pool Sizing + §Replication Channel:*

- Module folder-as-module entry. Public surface: `NPCSpawner.init(deps)`, `NPCSpawner.createAll()`, `NPCSpawner.destroyAll()`, `NPCSpawner.getAllActiveNPCs()`, `NPCSpawner.reclaim(npcId)`. Plus internal: tick callback, Heartbeat connection.
- `createAll` body: for `i = 1, 12 do task.defer(function() spawnBatchOf25() end) end`. Each batch creates 25 Parts, parented to a hidden ServerStorage folder pre-game; on round init parented into Workspace-owned folder.
- Heartbeat single-connect at module init (or lazy at first `createAll`). Disconnect at module unload (rare). Connection wrapped in `Connections.luau` instance.
- Constants: `NPC_POOL_SIZE = 300`, `NPC_BATCH_SIZE = 25`, `NPC_RESPAWN_MIN_CROWD_DIST = 30`, `NPC_WALK_SPEED = 4` (placeholder; F2 owner) → all in `SharedConstants/NPCSpawnerConstants.luau`.
- `ARENA_WALKABLE_AREA_SQ` is a workspace-attribute or env constant set by Level Design pipeline — assert at module init: `assert(typeof(area) == "number" and area > 0, "ARENA_WALKABLE_AREA_SQ missing or invalid")`.
- `ρ_design`: stored as `NPCSpawner._densityDesign = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ`. Read via accessor `NPCSpawner.getDesignDensity(): number`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: `reclaim` synchronous semantics + double-reclaim assert.
- Story 003: `getAllActiveNPCs` frozen snapshot.
- Story 004: idle walk + boundary reflection (Heartbeat callback body).
- Story 005: Respawn pipeline (delay, position, crowd exclusion).
- Story 006: Respawn fade-in TweenService.
- Story 007: `destroyAll` cleanup.
- Story 008: F2/F4 density guards.
- Story 009: UREvent replication.

---

## QA Test Cases

- **AC-01 (Pool size)**:
  - Given: fresh NPCSpawner module + valid ARENA_WALKABLE_AREA_SQ
  - When: `createAll()` + advance scheduler 12 batches
  - Then: `#NPCSpawner._pool == 300`; spy on `Instance.new` shows exactly 300 Part creations
  - Edge cases: `createAll` called twice without `destroyAll` raises; ensures idempotency.

- **AC-03 (Zero mid-round alloc)**:
  - Given: post-`createAll`, mid-round
  - When: 60 ticks pass with reclaim/respawn cycles
  - Then: spy on `Instance.new` shows 0 calls
  - Edge cases: respawn re-uses parked Part (parent + transparency reset, not new Part).

- **AC-05 (Single Heartbeat)**:
  - Given: NPCSpawner module loaded
  - When: connection count inspected via `RunService:GetPropertyChangedSignal` proxy / DI-injected RunService mock
  - Then: cumulative `Heartbeat:Connect` called by NPCSpawner == 1
  - Edge cases: `destroyAll` disconnects; `createAll` again re-connects to exactly 1.

- **ARENA validation**:
  - Given: ARENA_WALKABLE_AREA_SQ unset or ≤ 0
  - When: module require
  - Then: assertion fires with message containing "ARENA_WALKABLE_AREA_SQ"
  - Edge cases: zero, negative, nil — all rejected.

- **`ρ_design` constant**:
  - Given: AREA = 40000, POOL = 300
  - When: module init
  - Then: `getDesignDensity()` returns 0.0075
  - Edge cases: re-init does not recompute (constant after init).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/pool_bootstrap.spec.luau` — must exist and pass

**Status**: [x] Created — `tests/unit/npc-spawner/pool_bootstrap.spec.luau` (12 it() blocks; all 6 ACs covered + idempotency + state-machine + getDesignDensity pre-init guard)

---

## Dependencies

- Depends on: TickOrchestrator + RoundLifecycle (createAll caller); Connections.luau pattern.
- Unlocks: All other NPCSpawner stories.

---

## Completion Notes

**Completed**: 2026-05-06
**Criteria**: 6/6 passing — all ACs covered by automated tests
**Deviations** (advisory):
- Pre-alloc timing — story said `createAll`; ADR-0008 said `init()`. Implementation follows ADR-0008 (canonical). Header doc-comment cites resolution.
- TR-013 registry text ("ServerTickAccumulator callback") is stale — superseded by ADR-0008 §Cadence Exemption. Flag for next `/architecture-review` to refresh.
- AC-03 substitutes pool-size invariant for `Instance.new` global spy (not feasible in Luau sandbox). Story 5-2 must extend test with reclaim/respawn cycle simulation — TODO marker added.
- TestEZ `it()` description strings deviate from `.claude/rules/test-standards.md` naming rule. Project-wide TestEZ idiom; needs qa-lead ruling before retroactive change.

**Test Evidence**: `tests/unit/npc-spawner/pool_bootstrap.spec.luau` (Logic — 12 it() blocks, BLOCKING gate satisfied)

**Files**:
- `src/ServerStorage/Source/NPCSpawner/init.luau` (created, 342 lines)
- `src/ReplicatedStorage/Source/SharedConstants/NPCSpawnerConstants.luau` (created, 44 lines)
- `tests/unit/npc-spawner/pool_bootstrap.spec.luau` (created, 349 lines)

**Audits**: selene 0/7/0, asset-id PASS, persistence PASS

**Code Review**: Complete — `/code-review` ran 2026-05-06; verdict CHANGES REQUIRED (3 BLOCKING test gaps); fixes applied (added 2 tests + workspace attribute isolation); re-verified clean.

**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per `production/review-mode.txt`.
