# Story 002: CrowdManagerClient orchestrator + per-crowd FollowerEntityClient lifecycle

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 5h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-001`, `TR-follower-entity-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: `CrowdManagerClient` singleton owns `{[crowdId]: FollowerEntityClient}` map + per-crowd `Janitor`. Subscribes to `CrowdStateClient.CrowdCreated/Eliminated` and constructs/destroys per-crowd class instances. Drives a single `RenderStepped` loop iterating all active crowds. Per-frame nil-check on `CrowdStateClient.get(crowdId)` is the sole despawn path (no public `fadeOutCrowd`).

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `RunService.RenderStepped` is the only permitted client cadence (no `Heartbeat:Connect` per ADR-0002 audit-no-competing-heartbeat). `Janitor` from `Packages.janitor`. All pre-cutoff stable APIs.

**Control Manifest Rules (Presentation layer)**:
- Required: Boids flocking on `RunService.RenderStepped` client-side (one connection, iterates crowds)
- Required: `CrowdStateClient` is read-only mirror — every mutation flows through server
- Forbidden: Direct subscription to `CrowdStateBroadcast` (read via `CrowdStateClient.get`)
- Forbidden: `Heartbeat:Connect` (TickOrchestrator + ProfileStore + BeamBetween only)
- Guardrail: 1.5 ms desktop / 2.5 ms mobile per-frame budget for `follower-entity-client-sim`

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-10 (Crowd destroyed)**: When per-frame update reads `CrowdStateClient.get(crowdId)` and gets `nil`, every follower in that crowd transitions to `Despawning` that frame; F1-F4 boids math is NOT evaluated for nil-crowd followers; Part returned to pool after the 0.2 s fade.
- [ ] **CrowdManagerClient is singleton**: bootstrapped once from client `start.server.luau`, exposes `init()`, `start()`, `stop()`, `getCrowdClient(crowdId)`.
- [ ] **Per-crowd lifecycle**: subscribes to `CrowdStateClient.CrowdCreated` → constructs `FollowerEntityClient.new(crowdId, janitor)`; subscribes to `CrowdStateClient.CrowdEliminated` → calls `:destroy()` on the matching client; per-crowd `Janitor` cleans up on destroy.
- [ ] **Single `RenderStepped` connection**: `start()` connects exactly one `RenderStepped` callback; `stop()` disconnects it.
- [ ] **Read-only contract**: FollowerEntity NEVER writes to `CrowdStateClient`, `CrowdStateServer`, or any server state (verified by code search — no `:set`/`:update`/server RemoteEvent fires from FollowerEntity modules).
- [ ] **Path placement**: `ReplicatedStorage/Source/FollowerEntity/CrowdManagerClient.luau` (singleton); `ReplicatedStorage/Source/FollowerEntity/Client.luau` (per-crowd class) — per ADR-0006 §Source Tree Map + ADR-0007.

---

## Implementation Notes

*Derived from ADR-0007 §Architecture Diagram + §Key Interfaces:*

- `CrowdManagerClient` singleton bootstrapped from `src/ReplicatedFirst/Source/start.server.luau` (client entry) — call `init()` (pool prealloc — Story 001), then `start()` (RenderStepped loop).
- `FollowerEntityClient` is a per-crowd class — `FollowerEntityClient.new(crowdId: string, janitor: Janitor) -> ClassType`. Per `humanoid_on_followers` registry pattern: parallel arrays for follower state (NOT per-instance tables) for Luau cache locality.
- `Janitor` injected at construction; `:destroy()` calls `janitor:Destroy()` cleaning all connections + pool returns.
- Subscribe to `CrowdStateClient.CrowdCreated` signal (provided by Crowd State Manager client cache); on signal: construct per-crowd client + store in `self._crowds[crowdId]`.
- Subscribe to `CrowdStateClient.CrowdEliminated`: call `self._crowds[crowdId]:destroy()`, then `self._crowds[crowdId] = nil`.
- `start()`: connect ONE `RenderStepped:Connect(function(dt) ... end)`. Inside the callback, iterate `self._crowds` map. For each: per-frame nil-check `CrowdStateClient.get(crowdId)`; if nil → mark all followers `Despawning` and skip boids math (they will fade out in their own update path).
- `stop()`: disconnect the RenderStepped connection, then `:destroy()` each per-crowd client.
- `getCrowdClient(crowdId)` accessor for sibling modules (LOD Manager, CCR-client, Absorb-client). Returns `FollowerEntityClient?`.
- Defensive: do NOT publish a `fadeOutCrowd` API. The nil-check IS the despawn path (per ADR-0007 §C9).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Pool prealloc + rig assembly.
- Story 003: F1-F4 boids math inside the loop (this story stubs the iteration; math comes next).
- Story 005: Spawn states (FadeIn/SlideIn) + 4/frame throttle.
- Story 010: LOD tier swap mechanics; setLOD/setPoolSize public APIs (this story exposes empty stubs).

---

## QA Test Cases

- **AC-10 (Crowd destroyed → Despawning)**:
  - Given: `CrowdStateClient.get(crowdId)` mocked to return non-nil with 5 followers Active
  - When: mock changes to return `nil` and one `RenderStepped` frame fires
  - Then: all 5 followers in that crowd transition to `Despawning`; F1-F4 boids functions are NOT called for any follower in that crowd (verify via spy); Part returned to pool exactly 0.2 s after the nil-detection frame
  - Edge cases: nil mid-frame (after some followers updated) — remaining followers should still detect nil and transition; no half-evaluated frames.

- **Singleton bootstrap**:
  - Given: `CrowdManagerClient:init()` + `:start()` invoked
  - When: state inspected
  - Then: exactly one `RenderStepped` connection on `RunService` (verify via signal connection count); `getCrowdClient(unknownId)` returns `nil`; calling `:start()` twice does not double-connect
  - Edge cases: `:stop()` followed by `:start()` re-connects exactly one connection.

- **Per-crowd lifecycle**:
  - Given: `CrowdStateClient.CrowdCreated` signal mocked
  - When: signal fires with `crowdId="C1"`, then `CrowdEliminated` fires with `"C1"`
  - Then: `getCrowdClient("C1")` returns non-nil after Created; returns `nil` after Eliminated; per-crowd `Janitor:Destroy()` was called exactly once
  - Edge cases: Eliminated for unknown crowdId — no error, no-op. Created twice for same crowdId — second call no-ops (idempotent), original instance retained.

- **Read-only contract**:
  - Given: full module source set under `ReplicatedStorage/Source/FollowerEntity/`
  - When: code-search runs for write paths (`CrowdStateClient.set`, `CrowdStateClient.update`, server RemoteEvent fires)
  - Then: zero matches in `FollowerEntity/`
  - Edge cases: matches in tests/ are acceptable (mocks/spies).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/follower-entity/crowd_manager_orchestrator_test.luau` — must exist and pass (mock `CrowdStateClient`, `RunService.RenderStepped`, `Janitor`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool must exist before per-crowd clients can grant Parts)
- Unlocks: Story 003 (boids math), Story 005 (spawn flows), Story 009 (setPoolSize), Story 010 (LOD swap)
