# Story 005: F2 position lag + nil HumanoidRootPart guard

> **Epic**: crowd-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Formulas/F2 + §Edge Cases/Position-character
**Requirement**: `TR-csm-003` (CSM internal lag formula — design-internal, no ADR; this story implements per the GDD)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 §Read-vs-Write (CSM owns position field; only CSM writes); architecture.md §3.2 Engine APIs (`Character.HumanoidRootPart` read).
**ADR Decision Summary**: Per-tick CSM updates `record.position` by lerping toward the player's `Character.HumanoidRootPart.Position` with `CROWD_POS_LAG = 0.15`. nil HumanoidRootPart (void fall, respawn transition) → position retained, no error, collision state NOT cleared.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `Character.HumanoidRootPart` access is template-proven (LOW). The character may be nil during respawn; defensive nil-check pattern is canonical Roblox idiom. `Players:GetPlayerByUserId` (LOW).

**Control Manifest Rules (Core layer)**:
- Required: CSM record field `position: Vector3` (manifest L78).
- Forbidden: cosmetic systems must not mutate any CSM field including position (manifest L135).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-07 (Position Lag, F2)** — `position_old = Vector3(0,0,0)`, `char_pos = Vector3(100,0,0)`, `CROWD_POS_LAG = 0.15`, one tick elapses; `position_new = Vector3(15, 0, 0)` exactly (no float drift in this single-tick case — `0 + (100 - 0) * 0.15 = 15`).
- [ ] **AC-19 (nil HumanoidRootPart)** — `Character.HumanoidRootPart` is nil on a position-lag tick (void fall, respawn transition); `position` retains `position_old`, no Luau error, `record.stillOverlapping` and other collision state NOT cleared.
- [ ] CSM exposes a private `_updatePositions(): ()` per-tick helper that iterates all `_crowds` records (excluding `Eliminated`? — per GDD §States table L83 Eliminated keeps `position mutable: yes (character still moves)` — so include Eliminated in position updates) and applies F2.
- [ ] `_updatePositions` runs as a phase-prelude inside Phase 5 `stateEvaluate` (story-006 owns Phase 5 hook; this story exposes the helper and story-006 calls it first thing inside `stateEvaluate`).
- [ ] `CROWD_POS_LAG` constant exposed at module top with value `0.15` per GDD F2 default.
- [ ] nil-HRP path: when `Players:GetPlayerByUserId(tonumber(crowdId))` returns nil OR `player.Character` is nil OR `player.Character:FindFirstChild("HumanoidRootPart")` is nil, leave `record.position` unchanged. Do NOT mutate `record.stillOverlapping`, `record.state`, or any other field. This is graceful degrade; do NOT log per-tick (would flood logs).

---

## Implementation Notes

*Derived from GDD F2 + §Edge Cases/Position-character:*

- F2 implementation:
  ```lua
  local CROWD_POS_LAG = 0.15
  
  local function _updatePositions(): ()
      for crowdId, record in pairs(_crowds) do
          local userId = tonumber(crowdId)
          if userId == nil then continue end
          local player = Players:GetPlayerByUserId(userId)
          if player == nil then continue end
          local character = player.Character
          if character == nil then continue end
          local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
          if root == nil then continue end
          
          local charPos = root.Position
          record.position = record.position + (charPos - record.position) * CROWD_POS_LAG
      end
  end
  ```
- The `:: BasePart?` cast is for strict-mode satisfaction; `FindFirstChild` returns `Instance?`. If found, it should be a `BasePart` (HumanoidRootPart inherits from `BasePart`).
- Eliminated crowds DO continue position updates (per GDD §States table L83). The position broadcast keeps client-side render reasonable until `RoundLifecycle.destroyAll`.
- Performance: 12 crowds × ~5 µs per crowd = ~60 µs per tick. Well within ADR-0003 Phase 5 budget (0.2 ms allocated).
- `Players` is required at module top: `local Players = game:GetService("Players")`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-006**: Phase 5 `stateEvaluate` orchestration — calls `_updatePositions` first, then F7 grace-timer evaluation.
- **story-008**: `broadcastAll` reads `record.position` to pack into broadcast payload (`pos Vec3 f32[3]` at offset 10 per arch §5.7).
- **CCR epic**: position read by CollisionResolver is via CSM `getAllActive()` (story-007); this story does not couple to CCR.
- **NPCSpawner epic**: `getAllCrowdPositions()` (story-007) snapshot; not a write-path concern.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-07**: Fixture creates a mock `Player` w/ `Character.HumanoidRootPart.Position = Vector3.new(100, 0, 0)`. CSM record initialized w/ `position = Vector3.new(0, 0, 0)`. Invoke `_updatePositions()` once. Assert `record.position == Vector3.new(15, 0, 0)` (exact). Edge cases: second tick from `Vector3(15, 0, 0)` toward `Vector3(100, 0, 0)` → `Vector3(15 + 85*0.15, 0, 0) = Vector3(27.75, 0, 0)`; convergence within 0.5 studs of `(100, 0, 0)` after ~30 ticks.

- **AC-19 (nil HRP)**: Fixture creates mock Player with `Character = nil`. Pre-call `record.position = Vector3(50, 0, 0)`, `record.stillOverlapping = true`, `record.state = "Active"`. Invoke `_updatePositions()`. Assert `record.position == Vector3(50, 0, 0)` unchanged; `record.stillOverlapping == true` unchanged; `record.state == "Active"` unchanged; no error thrown. Edge cases: `Character ~= nil` but `HumanoidRootPart` not present → same graceful fallback; `Players:GetPlayerByUserId(...)` returns nil (player DC mid-iteration) → same fallback.

- **`CROWD_POS_LAG` constant**: assert `CROWD_POS_LAG == 0.15` (boundary value test — change requires GDD amendment).

- **All-crowds iteration**: fixture creates 8 records with distinct positions and characters; `_updatePositions()` invoked once; assert each record's position lerped correctly toward its OWN character. Edge cases: Eliminated state does not skip position update (still moves per GDD §States L83).

- **Performance**: 12-record fixture; `_updatePositions()` invocation timed via `os.clock`; assert `< 0.5 ms` (ample headroom for the 0.2 ms Phase 5 budget). This is a soft assertion — not strict CI gate, but flag if regresses.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/position_lag_test.luau` (F2 math + nil HRP guard + iteration).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (record schema with `position` field)
- Unlocks: story-006 (Phase 5 stateEvaluate calls `_updatePositions` first), story-008 (broadcast reads `position`)
