# Story 003: Per-overlap sequence + reclaim contract + snapshot atomicity

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md`
**Requirement**: `TR-absorb-004`, `TR-absorb-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority + ADR-0004 CSM Authority
**ADR Decision Summary**: AbsorbSystem (Phase 3) is the sole authorized caller of `NPCSpawner.reclaim(npcId)` and one of 4 callers of `CrowdStateServer.updateCount(crowdId, +1, "Absorb")`. `reclaim` is synchronous; `getAllActiveNPCs()` returns a frozen snapshot. Per-overlap order locked: signal → updateCount → reclaim.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `table.freeze` available; consume frozen snapshot read-only.

**Control Manifest Rules (Feature layer)**:
- Required: AbsorbSystem (Phase 3) is sole caller of `getAllActiveNPCs()` + `reclaim(npcId)` (ADR-0008)
- Required: `updateCount(crowdId, +1, "Absorb")` 4-caller rule (ADR-0004)
- Required: `reclaim(npcId)` synchronous, postconditions before return (ADR-0008)
- Forbidden: Yield inside Phase 3 callback (ADR-0002)
- Forbidden: Mutate frozen snapshot returned by `getAllActiveNPCs` (ADR-0008)
- Forbidden: Call CSM mutators outside §Write-Access Matrix (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md`, scoped to this story:*

- [ ] **AC-4 (Unlimited absorbs per tick)**: GIVEN crowd with 8 NPCs all in radius, 1 tick fires THEN 8 Absorbed events; `updateCount(+1)` called 8 times; `reclaim` called 8 times.
- [ ] **AC-6 (Per-overlap sequence)**: per overlap, order is `Absorbed:Fire(...)` → `csm.updateCount(crowdId, +1, "Absorb")` → `npcSpawner.reclaim(npcId)`. Verified via ordered-call spy.
- [ ] **AC-12 (Snapshot atomicity)**: `reclaim` called only on NPCs present in tick-start frozen snapshot; mid-tick-added NPCs never reclaimed in same tick.
- [ ] **`reclaim` synchronous-call assertion**: after `reclaim(npcId)` returns, NPC is `active=false`, transparency=1, removed from spawner snapshot, parked. (Mock validates postconditions before continuing.)

---

## Implementation Notes

*Derived from ADR-0008 §Lifecycle Contract + ADR-0004 §Write-Access Matrix:*

- At tick start: `local snapshot = npcSpawner.getAllActiveNPCs()` once; iterate this single snapshot. Do not re-query mid-tick.
- For each absorbed NPC: fire `Absorbed:Fire(crowdId, npcLastPosition)`, then `csm.updateCount(crowdId, +1, "Absorb")`, then `npcSpawner.reclaim(npcId)`. Order is contractual — code-review checkpoint.
- `Absorbed` is a server-side `BindableEvent` for VFX/audio consumers (intra-server) per Story 005. Reliable client RemoteEvent lives in Story 005.
- Use a local accumulator `{ {crowdId, npcId, npcPos}, ... }` filled during overlap pass, then run sequence loop after pass — keeps overlap-pass body branchless.
- Frozen snapshot: rely on NPCSpawner returning `table.freeze`'d table per ADR-0008. Mutating attempt at code-review reject.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: DI / phase registration.
- Story 002: F1/F2 (this story consumes overlap candidates).
- Story 004: State guards.
- Story 005: Absorbed reliable RemoteEvent broadcast.
- Story 006: V/A consumers of Absorbed signal.

---

## QA Test Cases

- **AC-4 (Unlimited absorbs per tick)**:
  - Given: 1 crowd radius covers 8 NPCs
  - When: 1 tick fires
  - Then: spy on `csm.updateCount` shows 8 calls all `(crowdId, +1, "Absorb")`; spy on `reclaim` shows 8 calls (1 per npcId, no duplicates)
  - Edge cases: 0 NPCs → 0 calls; 1 NPC → 1 call; large N=300.

- **AC-6 (Per-overlap order)**:
  - Given: ordered-call spy across `Absorbed:Fire`, `updateCount`, `reclaim`
  - When: 1 overlap fires
  - Then: spy log is `["Absorbed:Fire", "updateCount", "reclaim"]` exactly
  - Edge cases: 8 overlaps → 24 calls in 8 ordered triples (no interleaving).

- **AC-12 (Snapshot atomicity)**:
  - Given: snapshot returns 5 NPCs at tick start; mid-tick a 6th NPC added to spawner internal state
  - When: tick body iterates
  - Then: `reclaim` called on at-most the 5 from snapshot (the 6th never seen)
  - Edge cases: snapshot frozen — attempt to add to it raises (test asserts).

- **`reclaim` synchronous postconditions**:
  - Given: mock spawner whose `reclaim(npcId)` blocks until postconditions visible
  - When: AbsorbSystem calls reclaim
  - Then: control returns only after `active=false` set on NPC record
  - Edge cases: double-reclaim assertion fires (mocked spawner asserts).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/absorb/per_overlap_sequence.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (skeleton), Story 002 (overlap result feeds sequence).
- Unlocks: Story 005 (reliable RemoteEvent), Story 006 (V/A consumers).


## Completion Notes
**Completed**: 2026-05-06 (Sprint 5 batch close)
**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per production/review-mode.txt
**Audits**: selene 0/7/0, asset-id PASS, persistence PASS
**Test Evidence**: see story Test Evidence section — file at expected path
