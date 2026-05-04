# Story 004: Walk bob F8 + standstill freeze + micro-sway F9

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-005` (F8 walk-bob), `TR-follower-entity-006` (d continuity across LOD), `TR-follower-entity-017` (F9 micro-sway)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: F8 walk-bob composes on Y axis after F4 produces translation. Per-follower `d` carries across LOD swaps. F9 applies only at standstill at LOD 0; suppressed at LOD 1/2. All bob/sway constants pre-cutoff `math.sin` / `os.clock` only.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `os.clock()`, `math.sin`, `math.abs`, `CFrame.new(x, y, z)` — pre-cutoff stable. Native Luau math intrinsics post-cutoff (Dec 2025) speed up `math.sin`.

**Control Manifest Rules (Presentation layer)**:
- Required: Custom non-Humanoid CFrame rig (animation is procedural CFrame, not Humanoid AnimationTrack)
- Guardrail: 1.5 ms desktop / 2.5 ms mobile per-frame budget

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-2 (Walk bob F8)**: Given Active follower with `|d_delta| >= 0.01`, when `RenderStepped` fires, then `Body.CFrame.Y == Root_target.Y + abs(sin(d * 2π * 1.5)) * 0.15` within ±0.001 studs.
- [ ] **AC-3 (Standstill freeze)**: Given stationary `|d_delta| < 0.01` for 3 consecutive frames, when `RenderStepped` fires, then `d` does not increase (skip accumulation); `y_bob` frozen at last non-idle value.
- [ ] **AC-21 (F9 micro-sway, standstill, LOD 0)**: Given Active follower at standstill (`|d_delta| < 0.01`) for 5 consecutive frames at LOD 0, when `RenderStepped` fires, then `Body.CFrame.X` oscillates as `sin(t × 2π × 0.4 + sway_phase_offset) × 0.03` within ±0.001 studs; `sway_phase_offset` is per-follower (verify two simultaneously standstill followers in the same crowd have differing phase). At LOD 1 or LOD 2: `micro_sway_x == 0`.
- [ ] **AC-26 (Bob suppression at LOD 1/2)**: Given Active follower at LOD 1 or LOD 2 with `|d_delta| >= 0.01`, when `RenderStepped` fires, then F8 bob NOT applied to `Body.CFrame`; `d` continues accumulating (for LOD-0 re-entry phase continuity); F9 micro-sway also NOT applied at LOD 1/2.
- [ ] **`d` continuity**: `d` accumulates across LOD swaps (NOT reset). Only resets on follower despawn (pool reclaim) — re-initialised to random phase offset on next spawn (Story 005).
- [ ] **`sway_phase_offset` per-follower**: initialised at spawn to `math.random() * 2π` ∈ `[0, 2π)`; persists for follower lifetime; never zero across all followers in a crowd.
- [ ] **Composite CFrame**: `Body.CFrame = Root_target * CFrame.new(micro_sway_x, y_bob, 0)` where during movement `micro_sway_x = 0` (only F8 applies) and during standstill `y_bob` is frozen at `last_y_bob` (only F9 applies horizontally).
- [ ] **Constants in `SharedConstants/FollowerVisualConfig.luau`**: `WALK_FREQ_HZ = 1.5`, `WALK_BOB_AMP = 0.15`, `STANDSTILL_THRESHOLD = 0.01`, `MICRO_SWAY_AMP = 0.03`, `MICRO_SWAY_FREQ_HZ = 0.4`.

---

## Implementation Notes

*Derived from GDD §Formulas F8-F9 + §Animation style reinforcements:*

- Pure functions in `ReplicatedStorage/Source/FollowerEntity/Animation.luau` (or compose into the per-frame update path for cache locality).
- Per-follower state extends parallel arrays: `_d: {number}`, `_lastYBob: {number}`, `_swayPhaseOffset: {number}`, `_isStandstill: {boolean}`.
- Each frame, after F4 produces `Root_target`:
  1. Compute `d_delta = (P_new - P_prev).Magnitude`.
  2. If `d_delta >= STANDSTILL_THRESHOLD` (`= 0.01`): accumulate `_d[i] += d_delta`, set `_isStandstill[i] = false`, compute `y_bob = abs(sin(_d[i] * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP`, store `_lastYBob[i] = y_bob`, `micro_sway_x = 0`.
  3. Else (`|d_delta| < STANDSTILL_THRESHOLD`): set `_isStandstill[i] = true`, do NOT accumulate `_d[i]`, `y_bob = _lastYBob[i]`. If LOD == 0: `micro_sway_x = sin(os.clock() * 2π * MICRO_SWAY_FREQ_HZ + _swayPhaseOffset[i]) * MICRO_SWAY_AMP`. Else: `micro_sway_x = 0`.
  4. Apply only at LOD 0 OR continue `_d` accumulation only at LOD 0+1+2 (the bob output is used only at LOD 0). At LOD 1/2: `Body.CFrame = Root_target` (no F8 / F9 offset) but `_d` MUST still accumulate for phase continuity on LOD-0 re-entry.
  5. At LOD 0: `Body.CFrame = Root_target * CFrame.new(micro_sway_x, y_bob, 0)`.
- `_swayPhaseOffset[i]` initialised at spawn (Story 005) — `math.random() * 2π`. Document in spawn path that this MUST be per-follower; all-zero produces metronome lockstep.
- Bob frequency is **distance-based** (`d` = travel distance in studs), not time-based — faster movement yields faster bob. Only F9 sway is time-based (`os.clock()`).
- Performance: `math.sin` ~10 ns on Luau native VM. 80 followers × 2 calls (sin for bob + sin for sway) ≈ 1.6 µs — well within budget.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: F1-F4 boids; this story consumes the F4 `Root_target` output.
- Story 005: spawn path initialises `_d[i]` and `_swayPhaseOffset[i]` (random per-follower).
- Story 010: LOD tier value (`0/1/2`) is set by `setLOD(tier)` — this story reads the current tier per follower.

---

## QA Test Cases

- **AC-2 (Walk bob output)**:
  - Given: follower at `Root_target=(0,5,0)`, `d=0.167` (quarter period), LOD 0
  - When: per-frame compute runs with `d_delta = 0.5`
  - Then: `_d` increments to `0.667`; `y_bob = abs(sin(0.667 * 2π * 1.5)) * 0.15`; `Body.CFrame.Y == 5 + y_bob` within ±0.001
  - Edge cases: `d=0` exactly → `y_bob=0`. `d` at peak (`d * 2π * 1.5 = π/2`) → `y_bob = 0.15`.

- **AC-3 (Standstill freeze)**:
  - Given: follower with last `_d = 1.234`, `_lastYBob = 0.12`
  - When: 3 consecutive frames each with `d_delta = 0.005` (below threshold)
  - Then: `_d` unchanged (still `1.234`); `Body.CFrame.Y == Root_target.Y + 0.12` (frozen at `_lastYBob`); `_isStandstill` flips to true
  - Edge cases: a single frame above threshold mixed with standstill — `_d` increments only on the moving frame.

- **AC-21 (F9 micro-sway per-follower phase)**:
  - Given: 2 followers in same crowd, both standstill ≥5 frames, LOD 0
  - When: per-frame compute runs
  - Then: `Body.CFrame.X` of each follower equals `Root_target.X + sin(os.clock() * 2π * 0.4 + phase_i) * 0.03`; `phase_A ~= phase_B`; values within ±0.001 of formula
  - Edge cases: `os.clock()` advancing by `1/60` produces continuous oscillation, no discontinuity. At LOD 1: `Body.CFrame.X == Root_target.X` (no sway).

- **AC-26 (Bob/sway suppression at LOD 1/2)**:
  - Given: follower at LOD 1, `d_delta = 1.0` per frame (moving) for 10 frames; second follower at LOD 2
  - When: per-frame compute runs each frame
  - Then: at LOD 1 → `Body.CFrame == Root_target` exactly (no Y bob, no X sway); `_d` still accumulates `+1.0/frame`; at LOD 2 → same; on LOD-0 re-entry, `_d` retains the accumulated `10.0` value and bob resumes at the corresponding phase
  - Edge cases: LOD 0 → 1 → 0 swap mid-run preserves `_d` continuity (no reset).

- **`d` continuity across LOD swap**:
  - Given: `_d[i] = 5.5` at LOD 0, follower swaps to LOD 1 for 30 frames at `d_delta=0.5/frame`, then swaps back to LOD 0
  - When: state inspected
  - Then: `_d[i] == 5.5 + 30 * 0.5 == 20.5`; on LOD 0 re-entry, F8 bob computed against `_d=20.5` (not 0)
  - Edge cases: despawn during LOD 1 → re-spawn re-initialises `_d` to a fresh random phase offset.

- **`sway_phase_offset` per-follower**:
  - Given: 100 freshly spawned followers
  - When: their `_swayPhaseOffset` values inspected
  - Then: all values lie in `[0, 2π)`; standard deviation > 0; no two followers in the same crowd have an exactly equal value (statistically permitted but vanishingly likely with `math.random`)
  - Edge cases: post-spawn the value is immutable for the follower's lifetime (verify by reading on frames 1, 100, 1000).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/animation_walkbob_microsway_test.luau` — must exist and pass under TestEZ (mock `os.clock`, deterministic `math.random` seed, fixed `_d` inputs)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator), Story 003 (F4 produces Root_target)
- Unlocks: Story 010 (LOD swap path reads `_d` for continuity test), Story 011 (perf soak runs full F1-F4-F8-F9 pipeline)
