# Story 006: Hue Color3 write + dirty flag + reconciliation timer

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-011` (Color3 write, dirty flag gates steady-state writes)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Hue is single-frame `Color3` discontinuity (no lerp). Crowd-wide hue stored as `_currentHue`; per-follower writes gated by dirty flag. Force-reconcile after `HUE_RECONCILE_FRAMES = 4` consecutive mismatch frames (≈66 ms, one broadcast interval).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `Color3.new` (or `Color3.fromRGB`) preferred over `BrickColor` — faster C++ property write, no string palette lookup. Pre-cutoff stable.

**Control Manifest Rules (Presentation layer)**:
- Required: Read-only mirror of `CrowdStateClient.get(crowdId).hue` — no write back to server
- Forbidden: cosmetic systems (Skin / Banner) subscribing CountChanged for gameplay decisions
- Guardrail: per-frame budget; hue dirty-flag protects against unnecessary `Body.Color` writes at 80 followers

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-4 (Hue Color3 + dirty flag)**: Given spawn with hue `h`, when `Body.Color` assigned, then value is `Color3` (not `BrickColor`). AND on subsequent frames with unchanged crowd hue, no `Body.Color` write fires (verify via spy on the property setter).
- [ ] **`_currentHue` per-crowd cache**: stored on `FollowerEntityClient`. On per-frame update, compare to `CrowdStateClient.get(crowdId).hue`. If equal → skip per-follower writes. If different → write to all Active+Peeling followers in this crowd, then update `_currentHue`.
- [ ] **Hue reconciliation timer**: `_hueMismatchFrames: number` counter. Each frame, if `_currentHue ~= CrowdStateClient.get(crowdId).hue`, increment; if matched after a write, reset to 0. When counter reaches `HUE_RECONCILE_FRAMES = 4` without an intervening write (e.g., dirty-flag short-circuited erroneously), force-write hue regardless of flag and reset counter.
- [ ] **Hat color**: skin-defined, NEVER hue-tinted. `Hat.Color` set once on spawn from `SkinSystem.getHatTemplate` and not touched again by hue logic.
- [ ] **`HUE_COLORS` palette**: lookup table `{[hueIndex]: Color3}` lives in `SharedConstants/HueColors.luau` (or shared with Crowd State Manager).
- [ ] **Constants in `SharedConstants/FollowerVisualConfig.luau`**: `HUE_RECONCILE_FRAMES = 4`.

---

## Implementation Notes

*Derived from GDD §Hue application + §Cross-system constraints:*

- `_currentHue: number?` field on `FollowerEntityClient` (nil at construction; assigned on first hue write).
- Update flow each frame:
  1. Read `targetHue = CrowdStateClient.get(crowdId).hue`.
  2. If `targetHue ~= _currentHue` (steady-state mismatch OR uninitialised): iterate Active+Peeling followers, set `Body.Color = HUE_COLORS[targetHue]`. (Peeling followers have already-flipped hue from Story 008's hue-flip — exclude `_state == Peeling AND _hueFlipApplied == true`. See Story 008.) Set `_currentHue = targetHue`. Reset `_hueMismatchFrames = 0`.
  3. Else if `targetHue == _currentHue`: skip per-follower writes. Reset `_hueMismatchFrames = 0`.
- Reconciliation timer guard: if a bug allowed `_currentHue` to diverge silently from server hue without triggering a write (e.g., dropped hue-change event), the 4-frame counter forces a re-write.
- Hue write is a `Color3` value, not `BrickColor`. Use `Color3.fromRGB(r, g, b)` or `Color3.new(r, g, b)` for the palette table.
- `Hat.Color` is set ONCE on spawn (Story 005) by reading `SkinSystem.getHatTemplate(...).Color` (or equivalent) — Story 006 must NOT touch Hat.Color.
- Spy harness for AC-4 verification: wrap `Body.Color` assignment via dependency injection or property-write counter; assert count over N frames.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 005: initial hue write on spawn (frame-2 of SlideIn) — this story formalises the dirty-flag for steady-state.
- Story 008: hue-flip at 50% peel transit — single-frame discontinuity write that bypasses the dirty flag (peeling follower has its own hue, not crowd hue).

---

## QA Test Cases

- **AC-4a (Color3 type)**:
  - Given: spawn with `hue = blue`
  - When: hue write fires
  - Then: assigned value is `Color3` (typeof `Color3`, not `BrickColor`); RGB matches `HUE_COLORS[blue]`
  - Edge cases: hue index 0 / max — still returns valid `Color3`.

- **AC-4b (Dirty flag steady-state)**:
  - Given: 80 Active followers in a crowd, `_currentHue == targetHue`
  - When: 60 RenderStepped frames pass with unchanged crowd hue
  - Then: spy on `Body.Color` setter records 0 writes across all 80 followers × 60 frames (zero writes expected)
  - Edge cases: a single frame where `targetHue` changes — exactly 80 writes that frame, zero writes on subsequent steady-state frames.

- **`_currentHue` cache update**:
  - Given: `_currentHue = red`, `targetHue` changes to blue
  - When: per-frame update runs
  - Then: 80 `Body.Color = HUE_COLORS[blue]` writes fire; `_currentHue == blue` after; on next frame with still-blue `targetHue`, zero writes
  - Edge cases: hue change during a SlideIn spawn — Story 005 frame-2 hue write may overlap; both should converge to blue without double-write within same frame.

- **Reconciliation timer**:
  - Given: simulated bug where `_currentHue` is out of sync with `targetHue` but the comparison short-circuits incorrectly (mock the comparator to return equal for first 3 frames despite differing values)
  - When: 4+ frames pass with `_hueMismatchFrames` incrementing each frame
  - Then: on frame 4 (or first frame at counter == HUE_RECONCILE_FRAMES), force-write fires for all followers; `_currentHue` resync'd; counter resets
  - Edge cases: counter resets correctly after a normal dirty-flag write; never overflows past `HUE_RECONCILE_FRAMES + 1`.

- **Hat color invariance**:
  - Given: 80 followers, hat skin-defined color = orange, crowd hue cycles red→blue→green over 30 frames
  - When: observed each frame
  - Then: every follower's `Hat.Color == orange` on every frame; `Body.Color` follows hue cycle
  - Edge cases: skin change mid-round (out of MVP scope; documented assumption).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/hue_dirty_flag_test.luau` — must exist and pass under TestEZ (mock `CrowdStateClient.get`, spy on `Body.Color` setter via wrapper)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator + per-frame loop), Story 005 (spawn writes initial hue)
- Unlocks: Story 008 (peel hue-flip composes with dirty flag)
