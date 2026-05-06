# Story 003: getAllActiveNPCs frozen snapshot + cache invalidation

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md`
**Requirement**: `TR-npc-spawner-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Snapshot Contract
**ADR Decision Summary**: `getAllActiveNPCs()` returns a frozen cached snapshot table. Cache invalidated on every reclaim/respawn so subsequent calls rebuild fresh. Callers (AbsorbSystem) MUST NOT mutate the returned table — `table.freeze` enforces.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `table.freeze` available pre-cutoff and stable.

**Control Manifest Rules (Feature layer)**:
- Required: `getAllActiveNPCs` returns frozen cached snapshot (ADR-0008)
- Required: Cache invalidated on every reclaim/respawn (ADR-0008)
- Forbidden: Mutate the table returned by `getAllActiveNPCs` (ADR-0008 — read-only contract)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-09 (Frozen cached copy)**: `getAllActiveNPCs()` returns a `table.isfrozen` table; attempt to mutate raises.
- [ ] **AC-13 (Empty pool returns empty frozen table)**: post-`destroyAll`, `getAllActiveNPCs()` returns `{}` frozen — not nil.
- [ ] **AC-15 (Snapshot point-in-time)**: snapshot captured at call time; mid-tick reclaim/respawn does not appear in already-returned snapshot. New snapshot rebuilt only on next `getAllActiveNPCs()` call (cache miss after invalidation).
- [ ] **Cache invalidation**: after `reclaim(npcId)` in Story 002, `_cachedSnapshot == nil`; next `getAllActiveNPCs()` rebuilds.

---

## Implementation Notes

*Derived from ADR-0008 §Snapshot Contract + Story 002 cache-invalidation hook:*

- Internal field `_cachedSnapshot: {NPCRecord}? = nil`.
- `getAllActiveNPCs()` body: if `_cachedSnapshot ~= nil` return it; else build by iterating active list, freeze with `table.freeze`, store, return.
- Each NPCRecord in snapshot is `{npcId: string, position: Vector3, lastPos: Vector3}` — `lastPos` for AbsorbSystem to use as last-known npc position for VFX. Frozen at outer level; record sub-tables not necessarily frozen (callers MUST NOT mutate either by convention).
- Reclaim (Story 002) and respawn (Story 005) MUST set `_cachedSnapshot = nil` as last step.
- Empty case: when no active NPCs, build `{}` once, freeze, cache. Return same frozen empty.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: reclaim invalidates cache (sets nil).
- Story 005: respawn invalidates cache.

---

## QA Test Cases

- **AC-09 (Frozen)**:
  - Given: snapshot returned
  - When: caller does `snapshot[1] = newRecord` or `snapshot.foo = "bar"`
  - Then: assertion / Lua error fires (table is frozen)
  - Edge cases: nested record mutation — frozen at top-level only; documented as call-site discipline.

- **AC-13 (Empty frozen)**:
  - Given: post-destroyAll
  - When: `getAllActiveNPCs()` called
  - Then: returns `{}`; `table.isfrozen(snapshot) == true`; `#snapshot == 0`
  - Edge cases: never-initialized state — same behavior.

- **AC-15 (Point-in-time)**:
  - Given: 5 active NPCs; snapshot captured into `local s = getAllActiveNPCs()`
  - When: `reclaim("n3")` runs after capture
  - Then: `s` still contains 5 records; new snapshot via second `getAllActiveNPCs()` returns 4 records
  - Edge cases: multiple concurrent callers — same instance shared; `_cachedSnapshot == nil` after reclaim ensures next caller rebuilds.

- **Cache invalidation**:
  - Given: snapshot built (cache populated)
  - When: `reclaim` runs
  - Then: `NPCSpawner._cachedSnapshot == nil` (inspected via test seam)
  - Edge cases: respawn (Story 005) also invalidates — cross-story integration test.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/frozen_snapshot.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool), Story 002 (reclaim hook).
- Unlocks: AbsorbSystem stories that consume snapshot.


## Completion Notes
**Completed**: 2026-05-06 (Sprint 5 batch close)
**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per production/review-mode.txt
**Audits**: selene 0/7/0, asset-id PASS, persistence PASS
**Test Evidence**: see story Test Evidence section — file at expected path
