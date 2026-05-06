# Story 004: Surge — count relic via updateCount + GraceWindow up/down rules

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §G Surge + §AC-8/11/12
**Requirement**: `TR-relic-004`, `TR-relic-012`, `TR-relic-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority
**ADR Decision Summary**: Surge handler routes count delta exclusively through `csm.updateCount(crowdId, +40, "Relic")`. CSM clamps `[1, 300]`. GraceWindow rule: up-deltas allowed (can trigger GraceWindow → Active); down-deltas rejected at CSM write guard. Surge has `onAcquire` only — fires +40 once at grant.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: `updateCount(crowdId, delta, "Relic")` 4-caller rule (ADR-0004)
- Required: CSM clamps `[1, 300]` — Relic does not pre-clamp
- Required: GraceWindow up-delta allowed, down-delta rejected (CSM owns guard)
- Forbidden: Direct write to `crowd.count` (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **AC-8 (Count relic routes through updateCount)**: Surge Active + onAcquire → `CrowdStateServer.updateCount(crowdId, +40, "Relic")` called exactly once; no direct write to `CrowdState.count` from Relic handler (code grep verifies).
- [ ] **AC-11 (GraceWindow up-delta applies + transition trigger)**: GraceWindow at count=1 + Surge granted → updateCount(+40) → count becomes 41; `GraceWindow → Active` transition fires (CSM-owned); crowd continues round.
- [ ] **AC-12 (GraceWindow down-delta rejected)**: synthetic down-delta count relic with -10 in GraceWindow → CSM rejects; count remains 1; state unchanged.
- [ ] **TR-016 specifics**: Surge `+40` clamped at 300 (already-near-cap edge); CSM F5 enforces.

---

## Implementation Notes

*Derived from GDD §G Surge + ADR-0004:*

- `SurgeHandler.luau`:
  ```luau
  local SurgeHandler = {}

  function SurgeHandler.onAcquire(crowdId, slot)
      local delta = slot.privateState.countDelta -- 40 from registry
      csm.updateCount(crowdId, delta, "Relic")
  end

  -- onExpire / onTick / onChestOpen unused for Surge

  RelicHooks.register("Surge", { onAcquire = SurgeHandler.onAcquire })

  return SurgeHandler
  ```
- AC-12 down-delta scenario: tested via synthetic count relic spec with `countDelta = -10` registered for test only. CSM's `updateCount(crowdId, -10, "Relic")` checked at write guard: if `crowd.state == "GraceWindow"` and `delta < 0` → reject, return without applying. (CSM owns; Relic story tests via spy on CSM behavior.)
- Code-review grep gate: `grep -rn "crowd\.count\s*=" src/ServerStorage/Source/RelicSystem/` returns zero matches. Only via `csm.updateCount`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-003: registry, grant, hook dispatch.
- Story 005: Wingspan radius.
- Story 006: TollBreaker non-state.
- CSM clamp/transition logic — already implemented (Sprint 3 closed).

---

## QA Test Cases

- **AC-8 (Surge routes via updateCount)**:
  - Given: crowd Active count=100; Surge granted
  - When: onAcquire fires
  - Then: spy on csm.updateCount shows `(crowdId, +40, "Relic")` exactly once; spy on direct count writes shows 0
  - Edge cases: re-grant blocked by AC-2 distinct-from-held (covered Story 002); separate Surge instance forbidden by per-spec uniqueness.

- **AC-11 (GraceWindow up-delta + transition)** [Integration]:
  - Given: crowd state=GraceWindow count=1
  - When: Surge grant fires updateCount(+40)
  - Then: CSM applies → count=41, state transitions to Active (CSM-owned trigger via count > floor); CrowdStateBroadcast next tick reflects new state
  - Edge cases: count=300 already-cap → updateCount(+40) clamped to 0 effective; no transition fired (already Active).

- **AC-12 (GraceWindow down-delta rejected)**:
  - Given: crowd state=GraceWindow count=1; synthetic count relic with countDelta=-10
  - When: relic granted; onAcquire fires updateCount(-10)
  - Then: CSM write guard rejects; count remains 1; state unchanged
  - Edge cases: down-delta in Active state → applies normally (no rejection — only GraceWindow guards downs).

- **No direct count write**:
  - Given: full source under `src/ServerStorage/Source/RelicSystem/`
  - When: grep `crowd\.count\s*=`
  - Then: zero matches
  - Edge cases: comments containing the string — anchored regex.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/surge_count_relic.spec.luau` — must exist and pass
- `tests/integration/relic/surge_gracewindow_recovery.spec.luau` — AC-11 integration

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-003; CSM updateCount + GraceWindow guard (Sprint 3 closed).
- Unlocks: Vertical Slice playtest with comeback scenario.
