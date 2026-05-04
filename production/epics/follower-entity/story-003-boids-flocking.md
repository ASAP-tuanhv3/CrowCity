# Story 003: Boids F1-F4 flocking (separation + cohesion + leader + zero-vector guards)

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-001` (CFrame authority), implements F1-F4 boids math
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Boids loop runs at `RenderStepped` cadence inside the orchestrator's single connection. Forbidden inside loop: `Instance.new`, `WaitForChild`, yields, distance-against-camera math, direct broadcast subscription, `Heartbeat:Connect`. Per-follower state stored as parallel arrays (Luau cache locality).

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `Vector3.zero`, `Vector3.Unit`, `CFrame` — pre-cutoff stable. Native Luau VM optimisations for vector operations (Dec 2025) apply. No post-cutoff API.

**Control Manifest Rules (Presentation layer)**:
- Required: Boids flocking on `RunService.RenderStepped`; O(n²) within crowd safe due to render cap n ≤ 80
- Forbidden: `Instance.new`, yields, `Heartbeat:Connect` inside the loop
- Guardrail: 1.5 ms desktop / 2.5 ms mobile per-frame `follower-entity-client-sim` budget

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-15 (F1 EPSILON guard)**: When `P_i == P_j` exactly (overlap), denominator uses `max(‖P_i - P_j‖², 0.001)`; force magnitude finite and bounded; no NaN, no inf, no Luau error.
- [ ] **AC-20 (F4 boids final velocity)**: Given `F_sep=(-1,0,0), F_coh=(1,0,0), F_lead=(0.6,0,0.8)` with weights `(SEP=1.5, COH=1.0, LEAD=3.0)`, then `V_raw ≈ (1.3, 0, 2.4)`, `V_final = clamp(2.73, 0, 16) × V_raw.Unit ≈ (1.3, 0, 2.4)`, `P_new = P_i + V_final * dt`. Given all forces zero → `V_raw = Vector3.zero` → `P_new = P_i` (no movement, no NaN).
- [ ] **F1 separation**: per-follower sum `Σ (P_i - P_j) / max(‖P_i - P_j‖², ε)` for all `j` within `SEPARATION_RADIUS`; uses `EPSILON = 0.001` denominator floor.
- [ ] **F2 cohesion N=0 guard**: when zero neighbors within `NEIGHBOR_RADIUS`, return `Vector3.zero` BEFORE evaluating `(1/N)` (skip the divide entirely — Luau `1/0 = math.huge` and `math.huge * 0 = nan`).
- [ ] **F3 follow-leader**: `F_lead = CrowdStateClient.get(crowdId).position - P_i`. If `get` returns nil, follower transitions to Despawning (Story 002 path); F3 not evaluated.
- [ ] **F4 zero-vector guard per component**: each of `F_sep / F_coh / F_lead` is added to `V_raw` ONLY IF `.Magnitude > 0` (skip `.Unit` on zero-vectors). If `V_raw.Magnitude == 0`, hold position (`P_new = P_i`).
- [ ] **MAX_SPEED clamp**: `V_final = clamp(V_raw.Magnitude, 0, MAX_SPEED) * V_raw.Unit`, where `MAX_SPEED = 16` studs/s.
- [ ] **Constants in `SharedConstants/FollowerBoidsConfig.luau`**: `NEIGHBOR_RADIUS=6.0`, `SEPARATION_RADIUS=2.5`, `SEPARATION_WEIGHT=1.5`, `COHESION_WEIGHT=1.0`, `FOLLOW_LEADER_WEIGHT=3.0`, `MAX_SPEED=16`, `EPSILON=0.001`.
- [ ] **Startup assertion**: `SEPARATION_RADIUS < NEIGHBOR_RADIUS` (else separation never finds neighbors to flee).
- [ ] **Loop discipline**: no `Instance.new`, no yields, no `WaitForChild`, no distance-against-camera math, no Heartbeat connection inside the per-follower update.

---

## Implementation Notes

*Derived from GDD §Formulas F1-F4 + ADR-0007 §Boids Loop Discipline:*

- Implement as pure module functions in `ReplicatedStorage/Source/FollowerEntity/Boids.luau` for testability with dependency injection (mock `CrowdStateClient`).
- Per-follower state stored as parallel arrays on `FollowerEntityClient` (NOT per-Part tables): `_positions: {Vector3}`, `_indices: {number}`, etc., per ADR-0007 cache-locality requirement.
- Per-follower update sequence each frame: compute F1, F2, F3 → compose F4 → apply CFrame translate. F8 walk-bob (Story 004) composes ON TOP of F4 result on Y axis.
- Neighbor loop is O(n²) within a crowd — n ≤ 80 close-tier cap is the safety bound. Do not aggregate neighbors across crowds.
- F2 N=0 guard MUST short-circuit: `if N == 0 then return Vector3.zero end` before the `(1/N)` divide.
- F4 each-component guard MUST use `.Magnitude > 0` (NOT `~= Vector3.zero` — comparison may compile to per-component check; magnitude is the canonical check).
- F4 zero V_raw guard: if combined `V_raw.Magnitude == 0`, return `P_i` directly. Do NOT call `.Unit` on a zero vector.
- F1 EPSILON: `dist_sq_safe = math.max((P_i - P_j).Magnitude ^ 2, EPSILON)`; force is `(P_i - P_j) / dist_sq_safe`.
- Knobs are NOT registered in `tr-registry.yaml` (per GDD Tuning Knobs §Cross-system constraints) — file lives in `SharedConstants/` only.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: orchestrator owns the RenderStepped iteration; this story provides the math.
- Story 004: F8 walk-bob + F9 micro-sway compose on Y/X axis after F4 produces translation.
- Story 008: Peeling state retargets `F_lead` to rival center — boids primitive is shared, target source differs.
- Story 010: LOD swap effects (suppress boids at LOD 1/2? — per GDD: F4 still runs at LOD 1, suppressed at LOD 2).

---

## QA Test Cases

- **AC-15 (F1 overlap)**:
  - Given: two followers at exactly the same position `(0,0,0)`
  - When: F1 evaluated for follower A vs neighbor B
  - Then: result is finite (no NaN, no inf); magnitude ≤ `1/EPSILON = 1000` × any direction component; no Luau error raised
  - Edge cases: 3+ overlapping followers — sum stays finite; returned vector may be zero or arbitrary direction (acceptable).

- **AC-20a (F4 nominal)**:
  - Given: `F_sep=(-1,0,0), F_coh=(1,0,0), F_lead=(0.6,0,0.8)`, weights default, `dt=1/60`
  - When: F4 computes
  - Then: `V_raw ≈ (1.3, 0, 2.4)` within ±0.001 per component; `‖V_raw‖ ≈ 2.73` within ±0.01; `V_final ≈ (1.3, 0, 2.4)`; `P_new ≈ P_i + (1.3, 0, 2.4) * (1/60)`
  - Edge cases: weights at extremes (SEP=4.0, LEAD=8.0) — clamping at MAX_SPEED still produces finite result.

- **AC-20b (F4 zero-vector)**:
  - Given: `F_sep = F_coh = F_lead = Vector3.zero`
  - When: F4 computes
  - Then: `V_raw == Vector3.zero`; `P_new == P_i` (exact equality); no NaN; no `.Unit` call on zero vector (verify via spy or by absence of Luau error)
  - Edge cases: any single force zero, others non-zero — only that component skipped, others contribute normally.

- **F2 N=0**:
  - Given: follower with zero neighbors within NEIGHBOR_RADIUS
  - When: F2 computes
  - Then: returns exactly `Vector3.zero`; the `(1/N)` divide path NOT entered (verify via instrumented test)
  - Edge cases: N=1 — must NOT take the N=0 branch; computes centroid normally.

- **F3 nil-guard**:
  - Given: `CrowdStateClient.get(crowdId)` mocked to return `nil`
  - When: per-frame update runs for a follower in that crowd
  - Then: F3 not evaluated; follower transitions to Despawning (Story 002 path); no nil-deref error
  - Edge cases: mock returns nil on frame N+1 after returning a record on N — transition is one-frame.

- **MAX_SPEED clamp**:
  - Given: composed forces produce `‖V_raw‖ = 100` (far above MAX_SPEED=16)
  - When: F4 clamps
  - Then: `‖V_final‖ == 16` exactly; direction matches `V_raw.Unit`
  - Edge cases: `‖V_raw‖ < MAX_SPEED` — no clamping, magnitude unchanged.

- **Startup assertion**:
  - Given: `SharedConstants/FollowerBoidsConfig.luau` loaded
  - When: module evaluated
  - Then: `assert(SEPARATION_RADIUS < NEIGHBOR_RADIUS)` succeeds
  - Edge cases: if a future change inverts the relation, the assertion must fail at module load (verify with mutated test config).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/boids_test.luau` — must exist and pass under TestEZ (mock `CrowdStateClient` via dependency injection)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator drives the iteration; `CrowdStateClient` mirror is consumed here)
- Unlocks: Story 004 (bob composes on F4 result), Story 008 (peel retargets F_lead), Story 010 (LOD swap suppression)
