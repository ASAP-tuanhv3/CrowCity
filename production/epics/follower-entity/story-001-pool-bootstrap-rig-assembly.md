# Story 001: Pool bootstrap + 2-Part rig assembly

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 6h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-002`, `TR-follower-entity-003`, `TR-follower-entity-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Pool pre-allocated at boot via `task.defer` 25/batch. 460 LOD-0 Body + 460 Hat + 100 LOD-1 + 60 LOD-2 billboard slots parented to hidden `Workspace._FollowerPool` Folder. Each LOD-0 entry = Body MeshPart + Hat MeshPart + WeldConstraint(Part0=Body) parented under Body. No mid-round `Instance.new`.

**Engine**: Roblox (continuously-updated; pinned 2026-04-20) | **Risk**: MEDIUM
**Engine Notes**: `task.defer` chunked allocation pattern (matches NPC Spawner per ADR-0008); `Anchored=true`, `CanCollide=false`, `CanQuery=false`, `CanTouch=false`, `CastShadow=false` on pool entries (mobile thermal). All pre-cutoff stable APIs.

**Control Manifest Rules (Presentation layer)**:
- Required: Custom non-Humanoid CFrame rig per `design/gdd/follower-entity.md` §C.1 (2-Part Body + Hat MeshPart with WeldConstraint)
- Forbidden: Humanoid on followers (performance-killing at 800+ instances)
- Guardrail: ≤150 rendered follower Parts per client view (ADR-0003 instance cap)

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-1 (Rig assembly)**: Pool grant produces exactly 1 `Body` MeshPart + 1 `Hat` MeshPart, NO `Humanoid`; `Body.Anchored == true`; `WeldConstraint` exists with `Part0=Body, Part1=Hat`, parented **under Body** (not crowd Folder); `Hat.CFrame` offset `(0, headOffsetY, 0)` relative to Body; follower's `d` initialized to `math.random() * (1 / WALK_FREQ_HZ)` ∈ `[0, 0.667)`, NOT 0.
- [ ] **AC-6 (Hat template missing)**: When `SkinSystem.getHatTemplate(skin_id) == nil`, follower has Body only (no Hat, no WeldConstraint); warning logged once with `{crowdId, skin_id}`; no error thrown.
- [ ] **AC-7 (Pool exhaustion)**: When `pool.grant() == nil`, spawn silently dropped (no Part, no error); crowd continues rendering with fewer followers; warning logged exactly once per session.
- [ ] Pool sizes match `POOL_PREALLOC_LOD0_BODY = 460`, `POOL_PREALLOC_LOD0_HAT = 460`, `POOL_PREALLOC_LOD1 = 100`, `POOL_PREALLOC_LOD2_BILLBOARD = 60`.
- [ ] Boot allocation via `task.defer` chunked batches of 25 (matches NPC Spawner).
- [ ] Pool entries parented to single hidden Folder `Workspace._FollowerPool`; flags set: `Anchored=true`, `CanCollide=false`, `CanQuery=false`, `CanTouch=false`, `CastShadow=false`.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines + GDD §Pool architecture:*

- Pool prealloc lives in module `ReplicatedStorage/Source/FollowerEntity/Pool.luau` (or sibling under `FollowerEntity/`). Owned by `CrowdManagerClient` singleton.
- Pool sizes from `SharedConstants/FollowerPoolConfig.luau` (create this file). Constants: `POOL_PREALLOC_LOD0_BODY = 460`, `POOL_PREALLOC_LOD0_HAT = 460`, `POOL_PREALLOC_LOD1 = 100`, `POOL_PREALLOC_LOD2_BILLBOARD = 60`.
- `init()` on `CrowdManagerClient` runs `task.defer` chunks of 25 — ~37 batches Body + ~37 Hat + 4 LOD-1 + ~3 LOD-2 ≈ 80 deferred slots, distributed across `Loading` UI screen.
- LOD-0 composite: clone Body MeshPart from `ReplicatedStorage/Instances/...` per `SharedConstants/AssetId.luau`; clone Hat from `SkinSystem.getHatTemplate(skin_id)` (MVP fallback: `SharedConstants/DefaultSkin.luau` per hue index).
- `WeldConstraint`: parent under `Body` — Roblox requires constraint to be parented under one of its constrained Parts to be active.
- Hat offset `(0, headOffsetY, 0)` relative to Body — `headOffsetY` from rig spec; treat as compile-time constant.
- `d_init = math.random() * (1 / WALK_FREQ_HZ)` per follower at spawn (range `[0, 0.667)`); per-follower state.
- Pool exhaustion: `pool.grant()` returns `nil` → caller logs once-per-session warning (use a session-scoped flag), no error.
- Hat template missing: `SkinSystem.getHatTemplate(skin_id) == nil` → spawn Body-only rig; once-per-`{crowdId, skin_id}` warning.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: CrowdManagerClient orchestrator + per-crowd FollowerEntityClient lifecycle.
- Story 003: Boids math (F1-F4) — pool entries do not yet move.
- Story 005: Spawn states (FadeIn / SlideIn) + 4/frame throttle.
- Story 006: Hue Color3 write + dirty flag.

---

## QA Test Cases

*Derived from acceptance criteria. Developer implements tests against these — covers AC-1, AC-6, AC-7 plus pool prealloc invariants.*

- **AC-1a (Rig parts)**:
  - Given: empty pool, `Pool.grant()` invoked
  - When: rig assembled
  - Then: returned bundle has exactly 1 Body MeshPart, 1 Hat MeshPart, 0 Humanoid; `Body.Anchored == true`; `WeldConstraint.Part0 == Body and Part1 == Hat`; `WeldConstraint.Parent == Body`; `Hat.CFrame == Body.CFrame * CFrame.new(0, headOffsetY, 0)`
  - Edge cases: rig assembled twice in same frame — both should be independent instances, no shared WeldConstraint.

- **AC-1b (d_init range)**:
  - Given: 1000 spawn-grants over the test session
  - When: each follower's `d` is read post-spawn
  - Then: every value lies in `[0, 1/WALK_FREQ_HZ) = [0, 0.667)`; no value is exactly 0; standard deviation > 0 (i.e. randomized, not constant)

- **AC-6 (Hat template nil)**:
  - Given: `SkinSystem.getHatTemplate(skin_id)` mocked to return `nil`
  - When: spawn invoked with that `skin_id`
  - Then: returned bundle has Body, no Hat, no WeldConstraint; warning logged exactly once (second call with same `skin_id` does not re-log); no error raised
  - Edge cases: subsequent spawn with valid `skin_id` succeeds normally.

- **AC-7 (Pool exhaustion)**:
  - Given: pool drained to 0 free Body slots
  - When: `Pool.grant()` invoked
  - Then: returns `nil`; warning logged once per session (subsequent `grant()` returning nil does not re-log); no error raised
  - Edge cases: returning a Part to the pool then re-granting succeeds and does not re-arm the warning.

- **Pool prealloc**:
  - Given: `CrowdManagerClient:init()` + flush deferred work
  - When: pool sizes inspected
  - Then: free counts equal `460 / 460 / 100 / 60` for Body/Hat/LOD1/LOD2 respectively; all parents == `Workspace._FollowerPool`; per-Part flags `Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false, CastShadow=false`
  - Edge cases: `init()` called twice should be idempotent (no duplicate alloc).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/follower-entity/pool_bootstrap_rig_assembly.spec.luau` — must exist and pass under TestEZ (mock `SkinSystem`, `Workspace`, deferred work scheduler). Uses repo `.spec.luau` convention (TestEZ runner discovery via `tests/runner.server.luau`).

**Status**: [x] Complete — 765 LOC, 34 it across 6 describe blocks. Headless run via `rojo build test.project.json -o test-place.rbxl && run-in-roblox --place test-place.rbxl --script tests/runner.server.luau` on 2026-05-04: **312 passed / 0 failed / 0 skipped** (full suite); all 34 Story 001 tests green.

---

## Dependencies

- Depends on: None (first story in epic)
- Unlocks: Story 002 (orchestrator), Story 005 (spawn flows)

---

## Completion Notes

**Completed**: 2026-05-04
**Criteria**: 6/6 passing — all ACs covered by automated tests (34 it / 6 describe)
**Deviations**:
- ADVISORY: body-only grant slots intentionally drift `getFreeCount` per Story 001 known MVP limitation; Story 006 / Skin System addresses re-templating on return.
- TestEZ run executed headless via run-in-roblox 2026-05-04 — full suite 312 passed / 0 failed / 0 skipped; all 34 Story 001 tests green.
**Test Evidence**: Integration test at `tests/integration/follower-entity/pool_bootstrap_rig_assembly.spec.luau` (765 LOC).
**Code Review**: Complete — 1 BLOCKING issue (Pool.luau `hatForHue` clone leak, line 210) patched; 5 advisory test-coverage gaps addressed (per-hueIndex dedup, hat flag assertions, hat parent-under-body assertions, FollowerHadHat attribute assertion, concurrent initAsync test, FollowerPoolConfig constants).

**Files delivered**:
- `src/ReplicatedStorage/Source/SharedConstants/FollowerPoolConfig.luau` (62 LOC)
- `src/ReplicatedStorage/Source/SharedConstants/DefaultSkin.luau` (117 LOC)
- `src/ReplicatedStorage/Source/FollowerEntity/Pool.luau` (336 LOC, post-patch)
- `src/ReplicatedStorage/Source/FollowerEntity/Rig.luau` (144 LOC)
- `tests/integration/follower-entity/pool_bootstrap_rig_assembly.spec.luau` (765 LOC)
