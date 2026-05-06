# Story 004: State guards — Active / GraceWindow allow, Eliminated skip

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md`
**Requirement**: `TR-absorb-006`, `TR-absorb-008`, `TR-absorb-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 CSM Authority
**ADR Decision Summary**: CSM owns the state machine. AbsorbSystem reads `state ∈ {Active, GraceWindow, Eliminated}` from `csm.getAllActive()` and skips Eliminated crowds. AbsorbSystem MUST NOT issue any state-transition writes — `GraceWindow → Active` is owned by CSM via its own `updateCount` observer.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Read-only consumer of CSM state (ADR-0004)
- Forbidden: Issue any state-transition call from AbsorbSystem (ADR-0004 — CSM is sole state authority)
- Forbidden: Mutate the table returned by `csm.getAllActive` (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md`, scoped to this story:*

- [ ] **AC-7 (Skip Eliminated)**: crowd state == `Eliminated` AND NPC in radius → Absorbed NOT fired; reclaim NOT called.
- [ ] **AC-8 (Active + GraceWindow allowed)**: crowd A Active + crowd B GraceWindow both with NPC in radius → both fire Absorbed + reclaim normally.
- [ ] **AC-13 (No state transitions issued)**: GIVEN crowd in GraceWindow + NPC in radius, WHEN tick fires with Absorbed + updateCount(+1) THEN AbsorbSystem issues NO state-transition calls. CSM owns `GraceWindow → Active`.

---

## Implementation Notes

*Derived from GDD §States and Transitions + ADR-0004 §Write-Access Matrix:*

- At cache-build step in `tickPhase3` (Story 002 cached array), filter `csm.getAllActive()` rows by `state ~= "Eliminated"`. Eliminated rows excluded from overlap test entirely.
- `GraceWindow` rows kept in pass — overlap can still fire (Pillar 5 comeback math relies on rescue absorbs).
- AbsorbSystem code MUST NOT contain `csm.transitionToActive` / similar. Code-review grep gate: `grep -n "transitionTo\|setState" src/ServerStorage/Source/AbsorbSystem/` returns zero matches.
- Use `MatchState` enum from `SharedConstants/MatchState.luau` for state-string comparisons (no magic strings).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001-003: skeleton, overlap, sequence.
- Story 005: count clamp (CSM owns the 300 ceiling).

---

## QA Test Cases

- **AC-7 (Skip Eliminated)**:
  - Given: crowd state = `Eliminated`, NPC in radius
  - When: 1 tick fires
  - Then: spy shows zero Absorbed fires for that crowd; zero reclaim calls
  - Edge cases: mixed Active+Eliminated in same tick → only Active processed.

- **AC-8 (Active + GraceWindow allowed)**:
  - Given: crowd A Active + crowd B GraceWindow, each with 1 NPC in own radius
  - When: 1 tick fires
  - Then: 2 Absorbed fires, 2 reclaims; both crowds' updateCount(+1) called
  - Edge cases: GraceWindow crowd at count=1 still attempts absorb (CSM clamp owns ceiling).

- **AC-13 (No state transitions issued)**:
  - Given: GraceWindow crowd + NPC absorbed
  - When: tick completes
  - Then: zero calls to `csm.transitionTo*` or any state-write API; only `updateCount` mutator fired
  - Edge cases: count exactly at recovery threshold — AbsorbSystem still issues no transition.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/absorb/state_guards.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-003 (skeleton + overlap + sequence).
- Unlocks: Story 005, 006.
