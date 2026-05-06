# Story 002: reclaim() synchronous + double-reclaim assert

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md`
**Requirement**: `TR-npc-spawner-005`, `TR-npc-spawner-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Lifecycle Contract
**ADR Decision Summary**: `reclaim(npcId)` is synchronous; postconditions before return: `active=false`, removed from snapshot, parked, `Transparency=1`, cached snapshot invalidated. Double-reclaim asserts (defect surface). AbsorbSystem (Phase 3) is sole authorized caller.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: `reclaim(npcId)` synchronous — postconditions before return (ADR-0008)
- Required: AbsorbSystem (Phase 3) is sole caller of `reclaim` (ADR-0008)
- Forbidden: `task.wait` / yield inside reclaim (ADR-0002 — sync contract)
- Forbidden: Mid-round `Instance.new` (ADR-0008 — reuse parked Part)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md`, scoped to this story:*

- [ ] **AC-07 (reclaim synchronous postconditions)**: After `reclaim(npcId)` returns, observable: NPC `active=false`, removed from `getAllActiveNPCs()` return, parked at sentinel position (e.g., `(0, -10000, 0)`), `Transparency=1`. Verified via state inspection immediately after `reclaim` returns.
- [ ] **AC-08 (Double-reclaim raises)**: `reclaim(npcId)` on already-inactive NPC raises with descriptive error (defect surface).

---

## Implementation Notes

*Derived from ADR-0008 §Lifecycle Contract:*

- `reclaim(npcId: string)`:
  1. assert NPC exists in pool (raise if unknown id);
  2. assert NPC currently `active==true` (raise if double-reclaim);
  3. set `npc.active = false`;
  4. remove from active-list (table swap-pop for O(1));
  5. set `npc.Part.CFrame = CFrame.new(0, -10000, 0)`;
  6. set `npc.Part.Transparency = 1`;
  7. invalidate `_cachedSnapshot = nil` (Story 003 consumes);
  8. schedule respawn (Story 005 owner) — out of scope here, just the post-cleanup hook.
- No `task.wait`/`task.defer` inside reclaim body. The respawn scheduling itself is async (uses internal scheduler), but reclaim returns immediately after step 7.
- Internal NPC record `{npcId, Part, active, lastPos, _respawnTimer}` — keyed by npcId in `_pool` dict; active list is parallel array `{npcId, ...}` for O(n) iteration.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: `getAllActiveNPCs` frozen snapshot + cache invalidation observable.
- Story 005: Respawn pipeline (delay/position/exclusion).
- Story 007: destroyAll cancels pending timers.

---

## QA Test Cases

- **AC-07 (Synchronous postconditions)**:
  - Given: NPC `n42` active in pool at world `(5, 0, 5)`
  - When: `reclaim("n42")` returns
  - Then: state inspection shows `n42.active==false`, `Part.Transparency==1`, `Part.CFrame.Y < -1000`; `getAllActiveNPCs()` no longer contains `n42`
  - Edge cases: reclaim called from inside Phase 3 callback — no yield observed.

- **AC-08 (Double-reclaim raises)**:
  - Given: NPC `n42` already inactive (single reclaim done)
  - When: `reclaim("n42")` called again
  - Then: error raised with message containing "double-reclaim" or "already inactive"
  - Edge cases: unknown npcId raises distinct error ("unknown npcId"); reclaim on never-spawned id rejected.

- **No yield**:
  - Given: reclaim wrapped in coroutine resume + spy on `task.wait`/`task.defer`
  - When: reclaim runs
  - Then: zero yield calls observed
  - Edge cases: respawn scheduling step uses `task.delay` (out of body, post-return) — counted separately and OK.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/npc-spawner/reclaim_synchronous.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool exists).
- Unlocks: Story 003 (snapshot cache observes invalidation), Story 005 (reclaim hooks respawn schedule).


## Completion Notes
**Completed**: 2026-05-06 (Sprint 5 batch close)
**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per production/review-mode.txt
**Audits**: selene 0/7/0, asset-id PASS, persistence PASS
**Test Evidence**: see story Test Evidence section — file at expected path
