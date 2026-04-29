# Story 007: Read accessors + setStillOverlapping + getAllActive Eliminated exclusion

> **Epic**: crowd-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Server API (read accessors + overlap state write)
**Requirement**: `TR-csm-009` (Read-vs-Write authority), `TR-csm-014` (Write-Access Matrix), `TR-csm-027` (getAllActive Eliminated exclusion)... actual TR mapping per registry
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 §Read-vs-Write Matrix (`get`/`getAllActive`/`getAllCrowdPositions` unrestricted reads; `setStillOverlapping` sole caller CollisionResolver); ADR-0001 §Eliminated-state semantics (excluded from `getAllActive` per GDD §States table).
**ADR Decision Summary**: Read accessors return references to records — callers MUST NOT mutate (read-only contract). `getAllActive` returns Active ∪ GraceWindow (excludes Eliminated). `getAllCrowdPositions` returns a snapshot map keyed by crowdId for NPCSpawner. `setStillOverlapping` is the CCR-only writer for the per-tick overlap flag; last-write-wins within tick.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Pure Luau iteration / table allocation; no engine API risk.

**Control Manifest Rules (Core layer)**:
- Required: Read APIs unrestricted server-side (manifest L76); `setStillOverlapping` sole caller CollisionResolver, last-write-wins (L73); `getAllActive` excludes Eliminated (GDD §States L83 + L94).
- Forbidden: Never read or mutate the table returned by `get`/`getAllActive`/`getAllCrowdPositions` (manifest L155).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-27 (getAllActive excludes Eliminated)** — 3 crowds: A (Active), B (GraceWindow), C (Eliminated). `CollisionResolver` calls `getAllActive()`; returned list contains exactly {A, B} in some order, excludes C. A crowd transitioning to Eliminated mid-tick is excluded from the NEXT tick's `getAllActive()` (current-tick inclusion tolerated — the eliminated crowd cannot gain or lose count per the state table, so harmless).
- [ ] **AC-28 (setStillOverlapping semantics)** — CollisionResolver observes rival overlap on B during tick N; `setStillOverlapping(B.crowdId, true)`; `get(B.crowdId).stillOverlapping == true` for tick N. Tick N+1: CCR observes no overlap → `setStillOverlapping(B.crowdId, false)`; if B is in GraceWindow, F7 grace-timer evaluation on tick N+1 returns `should_eliminate = false` (overlap cleared — covered in story-006 AC-13 tie-break).
- [ ] `get(crowdId: string): CrowdRecord?` exposed per arch §5.1 L540.
- [ ] `getAllActive(): { CrowdRecord }` exposed per arch §5.1 L541. Returns array of references to records where `state ∈ {"Active", "GraceWindow"}` (NOT "Eliminated"). Iteration order is insertion order or arbitrary; do NOT sort here.
- [ ] `getAllCrowdPositions(): { [string]: Vector3 }` exposed per arch §5.1 L542. Returns a fresh map (not a reference to internal storage) keyed by crowdId; values are `record.position` Vector3. Excludes Eliminated records (their position is stale per GDD §Server API L179).
- [ ] `setStillOverlapping(crowdId: string, flag: boolean): ()` exposed per arch §5.1 L545. Writes `record.stillOverlapping = flag`. Last-write-wins within a tick. No-op if record absent.
- [ ] `getAllActive` returns FRESH array each call (not module-level scratch) — callers may discard or hold; no shared mutable state.
- [ ] All read accessors return references — callers must not mutate. Rule enforced by code review (not runtime guards).
- [ ] `getAllCrowdPositions` allocates a new table per call — defensive copy of position snapshot. Acceptable cost given ≤12 crowds.
- [ ] Read accessors run in O(N) where N = active crowd count ≤12 (manifest §Performance L160 worst-case context).

---

## Implementation Notes

*Derived from ADR-0004 §Read-vs-Write Matrix + GDD §Server API:*

- Implementations:
  ```lua
  function CrowdStateServer.get(crowdId: string): CrowdRecord?
      return _crowds[crowdId]
  end
  
  function CrowdStateServer.getAllActive(): { CrowdRecord }
      local result: { CrowdRecord } = {}
      for _, record in pairs(_crowds) do
          if record.state ~= "Eliminated" then
              table.insert(result, record)
          end
      end
      return result
  end
  
  function CrowdStateServer.getAllCrowdPositions(): { [string]: Vector3 }
      local result: { [string]: Vector3 } = {}
      for crowdId, record in pairs(_crowds) do
          if record.state ~= "Eliminated" then
              result[crowdId] = record.position
          end
      end
      return result
  end
  
  function CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()
      local record = _crowds[crowdId]
      if record == nil then return end  -- silent no-op per "last-write-wins, race tolerated"
      record.stillOverlapping = flag
  end
  ```
- `getAllActive` is the hot-path read for CCR Phase 1 (66 pair overlap checks per tick at 12 crowds). The fresh-table allocation per call is acceptable at ≤12 entries; optimization to a reused-buffer only justified if ADR-0003 budget pressure requires.
- `setStillOverlapping`'s "no-op on absent record" handles the race where CCR snapshot includes a crowd that destroys mid-tick (e.g. PlayerRemoving fires between snapshot capture and CCR write). Gracefully tolerated.
- Read-only contract: documented via doc-comments on each public method (manifest L155 enforces via review). No runtime traceback (manifest L137 forbids).

---

## Out of Scope

*Handled by neighbouring stories or epics — do not implement here:*

- **story-006**: F7 grace-timer evaluation reads `stillOverlapping`; tie-break behavior in AC-13.
- **story-008**: `broadcastAll` reads all records (including Eliminated, which DO continue broadcasting until destroy).
- **CCR epic**: `setStillOverlapping` callers; iteration of `getAllActive` for pair generation.
- **NPCSpawner epic**: `getAllCrowdPositions` consumer for min-distance gate.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-27**: Fixture creates A (Active), B (GraceWindow), C (Eliminated). Invoke `getAllActive()`. Assert returned array length == 2; assert C not present (by `crowdId` check); assert A and B both present. Edge cases: all 3 crowds Eliminated → returns empty array; mid-tick a crowd transitions A→Eliminated then `getAllActive` returns A excluded immediately on next call (validates "next tick" tolerance per AC).

- **AC-28**: Fixture creates B at `state="GraceWindow", stillOverlapping=false`. `setStillOverlapping("B", true)` → `get("B").stillOverlapping == true`. `setStillOverlapping("B", false)` → `get("B").stillOverlapping == false`. (Last-write-wins.) Edge cases: `setStillOverlapping("nonexistent", true)` → no-op, no error; record at state="Eliminated" + `setStillOverlapping(true)` → flag updated (CSM doesn't gate on state — write is unconditional; CCR is responsible for not calling on Eliminated).

- **`get` on absent record**: `get("nonexistent")` returns `nil`.

- **`getAllCrowdPositions` excludes Eliminated**: 3 crowds (Active/Grace/Eliminated). Invoke; result map size == 2; no key for Eliminated crowdId.

- **`getAllActive` returns fresh array**: invoke twice; assert returned arrays are distinct table references (`array1 ~= array2`); modifying one does not affect the other.

- **`getAllCrowdPositions` returns fresh map**: invoke twice; distinct table references.

- **`setStillOverlapping` last-write-wins same-tick**: same tick, fixture invokes `setStillOverlapping("B", true)` then `setStillOverlapping("B", false)`. `get("B").stillOverlapping == false`.

- **Read-only contract (negative test)**: documented but not runtime-enforced. Code-review check: grep for `getAllActive()[i].count = ...` or similar mutations to returned references → zero matches in any caller code.

- **Performance**: 12-record fixture; 1000 invocations of `getAllActive` measured by `os.clock`; mean < 0.05 ms / call.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/read_accessors.spec.luau` (get/getAllActive/getAllCrowdPositions) + `tests/unit/crowd-state-server/set_still_overlapping.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (record schema), story-006 (state field "Eliminated" used for filtering)
- Unlocks: CCR epic (Phase 1 reads getAllActive); NPCSpawner epic (getAllCrowdPositions); story-006 reads stillOverlapping
