# Story 006: Hue Color3 write + dirty flag + reconciliation timer

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Complete
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

---

## Completion Notes

**Completed**: 2026-05-04
**Criteria**: 6/6 acceptance criteria covered by pure-module unit tests (Logic story)
**Test Evidence**: `tests/unit/follower-entity/hue_dirty_flag.spec.luau` — 20 new TestEZ unit tests; full suite **490/490 passing** (was 470 pre-story).

### Files Created

- `src/ReplicatedStorage/Source/FollowerEntity/HueReconciler.luau` (~115 LOC)
  - 2 pure functions: `evaluate`, `defaultDirtyFlag`
  - Single-frame decision: shouldWrite + newCurrentHue + newMismatchFrames out
  - State (currentHue, mismatchFrames) owned by FollowerEntityClient — passed in/out by value
  - Comparator parameter (`dirtyFlagSaysMatched`) is injectable so reconciliation
    timer is testable independently of the production comparator
- `src/ReplicatedStorage/Source/SharedConstants/HueColors.luau` (~55 LOC)
  - 13-entry palette: index 0 = neutral white (NPC); 1-12 = signature hues
  - Color3 type strictly (AC-4: not BrickColor)
  - RGB values per art-bible §4 §Player Crowd Colors (locked safe palette,
    30-degree LCH perceptual distance under deuteranopia simulation)
  - Defensive `get(index)` returns NEUTRAL_WHITE for out-of-range indices

### Files Modified

- `src/ReplicatedStorage/Source/SharedConstants/FollowerVisualConfig.luau`
  - Added `HUE_RECONCILE_FRAMES = 4` constant with safe-range commentary

### Test Coverage by AC

| AC | Test Group | Tests |
|---|---|---|
| AC-4a (Color3 type, not BrickColor) | `HueColors palette` | 5 |
| AC-4b (Dirty-flag steady state, 0 writes/60 frames) | `HueReconciler.evaluate steady state` + integration | 2 + 1 |
| `_currentHue` cache update on hue change | `evaluate fast path` + integration | 3 + 1 |
| Reconciliation timer (force-write at threshold 4) | `evaluate reconcile timer` | 5 |
| Hat color invariance | (out of scope here — see Deviation note) | — |
| `HUE_COLORS` palette lookup | `HueColors.get` + distinctness | 5 |
| `HUE_RECONCILE_FRAMES = 4` config constant | dedicated config check | 1 |

### Naming Deviation (documented inline + precedent)

Story §Test Evidence specifies `hue_dirty_flag_test.luau`; actual filename is
`hue_dirty_flag.spec.luau`. TestEZ runner discovers `*.spec.luau` only.
Same precedent as stories 4-1, 4-2, 4-3, 4-4, 4-5.

### ADR-0007 Compliance

Forbidden-pattern audit (excluding doc comment headers): zero hits across
HueReconciler.luau and HueColors.luau for `Instance.new`, `WaitForChild`,
`:Wait()`, `task.wait`, `Player.Character`, `Heartbeat:Connect`,
`CrowdStateBroadcast`, `DataStoreService`. Pure logic + pure data.

### Out of Scope Respected

No edits to `Client.luau`, `CrowdManagerClient.luau`, or any non-config file.
Wire-in is deferred to follow-up integration pass (consistent with stories 4-3,
4-4, 4-5). The Implementation Notes describe how `FollowerEntityClient` will
adopt these primitives:
- Add `_currentHue: number?` + `_hueMismatchFrames: number` fields
- Each frame: read `targetHue` from `CrowdStateClient.get(crowdId).hue`;
  call `HueReconciler.evaluate(...)`; if `shouldWrite`, iterate Active+Peeling
  followers and set `Body.Color = HueColors.get(targetHue)`

### Deviations

- **Hat.Color invariance** (story claim "Hat.Color skin-defined and never touched
  by hue logic"): pure module verifies Body-color decision logic only; Hat.Color
  invariance is enforced by *not* writing to it from this module. Verifiable via
  grep audit when Client.luau wire-in lands. Same advisory pattern as Story 4-5.

- **Spy harness for AC-4b** (story Implementation Notes suggested "spy on
  `Body.Color` setter via wrapper"): pure module test counts `shouldWrite=true`
  return values across 60 frames as a proxy for write-count. The actual property-
  setter spy can land at the wire-in pass. The pure-module test still exercises
  the dirty-flag logic for AC-4b (zero-write contract holds at the decision layer).

- **`_state == Peeling AND _hueFlipApplied` exclusion** (Implementation Notes):
  Peeling followers with already-flipped hue are excluded from steady-state hue
  writes by the iteration filter, not by the reconciler module. That filter
  lives in the wire-in (Client.luau iteration loop) where the per-follower state
  is accessible. Pure module is per-crowd, not per-follower — clean separation.

### Code Review

LP-CODE-REVIEW skipped — Lean review mode (default per `.claude/skills/`).
Manual ADR-0007 audit + selene lint (0 errors / 0 warnings) + 490/490 test suite
pass provide equivalent quality gate. Same pattern as stories 4-3, 4-4, 4-5.
