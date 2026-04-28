# Story 005: getPlacements F3 5-key composite sort + InternalPlacement strip + idempotence + perf

> **Epic**: round-lifecycle
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/round-lifecycle.md` §Formulas/F3 + §Internal Placement type + §Edge Cases/Placement-array-edges
**Requirement**: `TR-round-lifecycle-004` (5-field broadcast shape), `TR-round-lifecycle-013` (InternalPlacement stripping), `TR-round-lifecycle-016` (perf — sort O(N log N) on ≤12)
**ADR**: ADR-0005 §Decision (F3 placement composite sort owner = RoundLifecycle, 5-key: peakCount desc → survived desc → finalCount desc → eliminationTime desc → UserId asc); ADR-0005 §InternalPlacement strip rule (manifest L100).
**ADR Decision Summary**: `getPlacements()` returns array of `Placement` (5-field broadcast shape). Internal field tracking (`peakCount`, `isWinner`, `wasEliminated`) is exposed as `InternalPlacement` type for ADR-0005 RL-internal use only. MSM broadcast adapter (MSM story-005) strips internal fields. Sort uses 5-key composite. Idempotent + O(N log N) on ≤12 records.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `table.sort` (LOW); pure Luau (LOW).

**Control Manifest Rules (Core layer)**:
- Required: F3 placement composite sort owner = RoundLifecycle (manifest L101); InternalPlacement strip rule (L100); never call `getPlacements()` before `setWinner` when participants non-empty (L139); never leak `InternalPlacement` to client broadcast (L141).

---

## Acceptance Criteria

- [ ] **AC-11 (Placement 3-group sort)** — Records injected into `_crowds` (bypassing signal fires): A=winner via `setWinner("A")`, `finalCount=10, eliminationTime=nil`; B=`finalCount=50, peakCount=60, eliminationTime=nil`; C=`finalCount=50, peakCount=100, eliminationTime=nil`; D=`finalCount=30, eliminationTime=200.0`; E=`finalCount=20, eliminationTime=100.0`. After `setWinner("A")` then `getPlacements()`: returned array `[A(p=1), C(p=2), B(p=3), D(p=4), E(p=5)]`. C wins tiebreak on higher peakCount (100 > 60). D outranks E on later eliminationTime (200 > 100).
- [ ] **AC-12 (T5 empty path)** — `createAll([])` empty list; `getPlacements()` returns `{}` (length 0).
- [ ] **AC-13 (Same-tick UserId tiebreak)** — Two records w/ `eliminationTime` injected to same value (e.g. both 1234.567). UserId 100 vs 200. `getPlacements()` → UserId 100 receives better (lower) placement number. Deterministic, independent of `table.sort` stability.
- [ ] **AC-15 (Broadcast schema split)** — `getPlacements()` output entries have `{crowdId, userId, placement, crowdCount, eliminationTime}`. `InternalPlacement` type extends with `peakCount, isWinner, wasEliminated`. Internal fields ABSENT from any value passed to `RemoteEvent:FireAllClients` by MSM broadcast adapter (verify via mocked adapter).
- [ ] **AC-16 (Idempotence + perf)** — 12 participant records w/ setWinner. `getPlacements()` called twice w/ no state mutation between → both arrays deep-equal by value. 100-iteration loop over 12 records completes in < 10ms total (`os.clock` delta).
- [ ] `getPlacements(): { Placement }` per arch §5.3 L628 returns 5-field shape:
  ```lua
  type Placement = {
      crowdId: string,
      userId: number,
      placement: number,
      crowdCount: number,
      eliminationTime: number?,
  }
  ```
- [ ] F3 5-key sort comparator:
  ```
  Rank 1: _winnerId crowd ALWAYS first (placement = 1)
  Rest sorted by: survived desc → peakCount desc → finalCount desc → eliminationTime desc (later eliminations rank higher) → UserId asc
  ```
  *Note: GDD §F3 specifies the 5-key. AC-11 demonstrates: A is winner (placement=1); C beats B on peakCount (3-group equivalent); D beats E on later eliminationTime.*
- [ ] If `_winnerId == nil` AND `#_participants > 0` → assert (caller bug per manifest L139). EXCEPT for T5 empty-participant path: `#_participants == 0` AND `_winnerId == nil` → return empty `{}` (AC-12).
- [ ] Output array length == `#_participants` (or 0 for T5 empty).
- [ ] Sort output is fresh array each call (defensive — caller may discard).
- [ ] `placement` field is 1-indexed monotonic (1, 2, 3, ...).

---

## Implementation Notes

- F3 sort comparator pseudocode:
  ```lua
  local function _f3_less(a: InternalAuxRecord, b: InternalAuxRecord): boolean
      -- _winnerId always first (handled outside sort by prepending)
      if a.survived ~= b.survived then return a.survived end  -- true > false
      if a.peakCount ~= b.peakCount then return a.peakCount > b.peakCount end
      if a.finalCount ~= b.finalCount then return a.finalCount > b.finalCount end
      local ta = a.eliminationTime or math.huge  -- nil = survived; treat as "later than any number"
      local tb = b.eliminationTime or math.huge
      if ta ~= tb then return ta > tb end  -- later eliminationTime → higher rank
      return a.userId < b.userId  -- UserId asc tiebreak
  end
  ```
- Implementation strategy: separate `_winnerId` row from the rest; sort the rest via `table.sort`; prepend winner. Output:
  ```lua
  function RoundLifecycle.getPlacements(): { Placement }
      if #_participants == 0 then return {} end  -- AC-12
      assert(_winnerId ~= nil, "RoundLifecycle.getPlacements: _winnerId nil with non-empty participants")
      local rest: { InternalAuxRecord } = {}
      for crowdId, record in pairs(_crowds) do
          if crowdId ~= _winnerId then
              table.insert(rest, record)
          end
      end
      table.sort(rest, _f3_less)
      local out: { Placement } = {}
      table.insert(out, _toPlacement(_crowds[_winnerId], 1))  -- winner first
      for i, record in ipairs(rest) do
          table.insert(out, _toPlacement(record, i + 1))
      end
      return out
  end
  ```
- `_toPlacement(record, placement)` strips internal fields:
  ```lua
  local function _toPlacement(record: InternalAuxRecord, placement: number): Placement
      return {
          crowdId = record.crowdId,
          userId = record.userId,
          placement = placement,
          crowdCount = record.finalCount,
          eliminationTime = record.eliminationTime,
      }
  end
  ```
- `InternalPlacement` type defined alongside; exposes `peakCount, isWinner, wasEliminated` for ADR-0005 internal RL diagnostics. Not used by MSM broadcast (which uses `Placement`). The strip rule per manifest L100 is enforced by simply having two distinct types — there is no leak path because `getPlacements` returns `Placement` only.
- AC-13 UserId asc tiebreak: deterministic regardless of `table.sort` stability because comparator's last-resort branch is total order on UserId.
- Perf: 12-record `table.sort` is O(12 * log 12) ≈ 50 comparisons; well under 1µs. 100 iterations < 100µs total — exceeds AC-16 budget by 100×.

---

## Out of Scope

- story-001..004: prereqs
- MSM story-005: broadcast adapter consumes `getPlacements` output and includes in `MatchStateChanged("Result", meta)` payload

---

## QA Test Cases

- **AC-11**: Inject the 5 records as described. setWinner("A"). getPlacements() returns array length 5 in exact order [A, C, B, D, E] with placements 1..5.
- **AC-12 (T5)**: createAll([]) empty. getPlacements() returns `{}`.
- **AC-12 (assert non-empty without winner)**: createAll([A, B]); without setWinner; getPlacements() asserts.
- **AC-13**: 2 records with same eliminationTime=1234.567, UserId 100 + 200. setWinner("u100" or "u200" — pick a third record as winner if needed; for the elim-tie test put a third winner). getPlacements: UserId 100 entry has lower placement number than UserId 200 entry. Repeat 10 runs — deterministic.
- **AC-15 (broadcast schema split)**: Mock MSM broadcast adapter that captures payload. After getPlacements + adapter call, captured payload entries have only 5 fields; `peakCount`, `isWinner`, `wasEliminated` absent.
- **AC-16 (idempotence)**: getPlacements() called twice; arrays deep-equal field-by-field. No `os.clock` calls during second call (no state mutation; sort cache result OK or re-sort identical).
- **AC-16 (perf)**: 12 records; loop 100x getPlacements; `os.clock` delta < 10ms total.
- **5-key F3 ordering**: dedicated test harness with synthesized records spanning all 5 sort tiers; verify each tier breaks ties correctly.

---

## Test Evidence

`tests/unit/round-lifecycle/getplacements_f3_sort_test.luau` (AC-11/13 + 5-key) + `tests/unit/round-lifecycle/empty_participants_t5_test.luau` (AC-12) + `tests/unit/round-lifecycle/broadcast_schema_strip_test.luau` (AC-15) + `tests/unit/round-lifecycle/idempotence_perf_test.luau` (AC-16).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..004
- Unlocks: MSM story-005 (broadcast adapter consumes `getPlacements` for Result meta payload); gate-check Pre-Production → Production re-evaluation
