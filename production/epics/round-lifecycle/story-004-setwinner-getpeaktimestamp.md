# Story 004: setWinner + getPeakTimestamp + invalid guards

> **Epic**: round-lifecycle
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/round-lifecycle.md` §Server API (setWinner, getPeakTimestamp) + §Edge Cases/API-contract-violations
**Requirement**: `TR-round-lifecycle-003` (sole setWinner caller MSM), `TR-round-lifecycle-005` (getPeakTimestamp F4 tiebreak), `TR-round-lifecycle-009` (_winnerId set before getPlacements)
**ADR**: ADR-0005 §Decision (MSM is sole setWinner caller; getPeakTimestamp returns nil → MSM F4 treats as math.huge per arch §5.3 L638).
**ADR Decision Summary**: `setWinner(crowdId)` records the winner crowdId. Invalid id (not in `_crowds`) is silently rejected w/ warn log (no exception — MSM may pass nil for T5 zero-participant path). `getPeakTimestamp(crowdId)` returns the recorded peakTimestamp or nil if absent.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Pure Luau (LOW).

**Control Manifest Rules (Core layer)**:
- Required: MSM is sole caller of all 5 RL methods (manifest L95).
- Forbidden: never call `getPlacements()` before `setWinner` when participants non-empty (L139).

---

## Acceptance Criteria

- [ ] **AC-10 (setWinner invalid guard)** — `setWinner(id)` w/ `id` not in `_crowds` (covers: id absent from `_participants`, AND id in `_participants` but pcall-failed in createAll). Call wrapped in `pcall`. `_winnerId` stays `nil`. `warn`-level log fires citing `{id, _crowds keys snapshot}`. No state mutation.
- [ ] **AC-14 (getPeakTimestamp)** — `getPeakTimestamp(id)` for `id` present in `_crowds` returns `record.peakTimestamp` number. For `id` not in `_crowds` returns `nil`.
- [ ] `setWinner(crowdId: string?): ()` per arch §5.3 L627 — accepts nil (T5 zero-participant) and valid string.
- [ ] `setWinner` body:
  ```lua
  function RoundLifecycle.setWinner(crowdId: string?): ()
      if crowdId == nil then
          _winnerId = nil  -- explicit nil = no winner (T5 path)
          return
      end
      if _crowds[crowdId] == nil then
          warn(string.format("RoundLifecycle.setWinner: crowdId %s not in _crowds (keys: %s)",
              tostring(crowdId), _formatCrowdsKeys()))
          return  -- _winnerId stays whatever it was
      end
      _winnerId = crowdId
      _crowds[crowdId].survived = true  -- mark winner as survived
  end
  ```
- [ ] `getPeakTimestamp(crowdId: string): number?` per arch §5.3 L629:
  ```lua
  function RoundLifecycle.getPeakTimestamp(crowdId: string): number?
      local record = _crowds[crowdId]
      if record == nil then return nil end
      return record.peakTimestamp
  end
  ```
- [ ] `_formatCrowdsKeys()` private helper — produces a readable string listing `_crowds` keys for the warn log.
- [ ] AC-10 path supports MSM's pcall-wrapping pattern: even if `setWinner` is wrapped in `pcall(setWinner, id)` and `id` is invalid, NO exception raised; fail mode is the warn log + no-op.

---

## Implementation Notes

- The `survived = true` write on winner is a convenience — story-005's getPlacements F3 sort uses `survived` (true → Rank 1) directly. Without this line, the winner's `survived` would still be false from initial state; the sort's "winner first" path uses `_winnerId` as the canonical signal anyway (see story-005). Setting `survived=true` here keeps the data internally consistent.
- `_formatCrowdsKeys` is a debug aid; do not include in hot path. `setWinner` is called once per round at MSM Result entry — not hot.
- `setWinner(nil)` is the T5 path explicitly per AC-12 (Round Lifecycle GDD; "MSM is sole caller" but MSM's T5 path explicitly passes nil for empty-participant Snap → Result).

---

## Out of Scope

- story-001..003: prereqs
- story-005: getPlacements consumes `_winnerId` and `getPeakTimestamp`

---

## QA Test Cases

- **AC-10 (id absent from _crowds)**: `_crowds = {}`. `setWinner("u_invalid")`. `_winnerId == nil`. `warn` spy logged with `"u_invalid"` substring + keys snapshot.
- **AC-10 (pcall-failed crowd)**: Setup w/ `_participants = {A, B}` but `_crowds = {B}` only (A's create pcall-failed in story-001 AC-2). `setWinner("A")` → `_winnerId == nil`, warn logged.
- **AC-10 (setWinner valid)**: `_crowds = {A}`. `setWinner("A")`. `_winnerId == "A"`, `_crowds["A"].survived == true`.
- **AC-10 (setWinner nil)**: `setWinner(nil)`. `_winnerId == nil` (explicit). No warn.
- **AC-14 (present)**: Record w/ `peakTimestamp=42.5`. `getPeakTimestamp(id)` returns 42.5.
- **AC-14 (absent)**: `getPeakTimestamp("nonexistent")` returns nil.
- **MSM F4 contract**: nil return treated as math.huge by MSM F4 (covered in MSM story-003 fixture); this story only validates RL side.

---

## Test Evidence

`tests/unit/round-lifecycle/setwinner.spec.luau` + `tests/unit/round-lifecycle/getpeaktimestamp.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (`_crowds` aux + `_winnerId` field)
- Unlocks: story-005 (getPlacements consumes); MSM story-003 (F4 tiebreak calls getPeakTimestamp)
