# Story 004: Skip conditions — nil/Eliminated state guards + GraceWindow handling

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-007`, `TR-ccr-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 TickOrchestrator §Phase 1 state-skip + ADR-0004 CSM Authority
**ADR Decision Summary**: Skip pairs where either crowd is nil or `state == "Eliminated"`. Drip restricted to both Active. GraceWindow crowd's overlap-bit STILL reported (`setStillOverlapping(true)`) — CSM's GraceWindow timer expires next tick if overlap persists.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Eliminated crowds skip per ADR-0002 Phase 1 state-skip rule
- Required: GraceWindow overlap-bit still reported (ADR-0004 CSM consumer)
- Forbidden: Issue state-transition calls from CCR (ADR-0004 — CSM owns transitions)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-06 (Skip conditions)**: GIVEN pair where `csm.get(A.id) == nil` OR `B.state == "Eliminated"`, WHEN tick runs, THEN: (a) no `updateCount` for either pair side; (b) `setStillOverlapping(_, true)` NOT set from these pairs; (c) no Luau error thrown.
- [ ] **GraceWindow drip suspended**: GraceWindow ↔ Active overlapping pair → no drip (drip restricted to both-Active per Rule 5); but overlap-bit STILL reported for both.
- [ ] **GraceWindow ↔ GraceWindow**: no drip; overlap-bit reported for both.
- [ ] **No state writes**: code grep verifies CCR module never calls `csm.transitionTo*` or any state mutator other than `updateCount` + `setStillOverlapping`.

---

## Implementation Notes

*Derived from GDD §C Rule 4 + §States and Transitions:*

- After Story 002's pair pass, before drip (Story 003): for each overlap pair `{a, b}`:
  - Look up `csm.get(a.id)` and `csm.get(b.id)`. If either nil → skip pair entirely (no drip, no overlap-bit contribution from this pair to those crowds).
  - If `a.state == "Eliminated"` or `b.state == "Eliminated"` → skip drip; continue to overlap-bit (still reported for non-Eliminated side).
  - If `a.state == "Active"` and `b.state == "Active"` → run drip (Story 003).
  - If at least one is `GraceWindow` → no drip, but overlap-bit reported for both (Story 005 consumes).
- Code-review grep gate: `grep -rn "transitionTo\|setState" src/ServerStorage/Source/CollisionResolver/` returns zero matches.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: skeleton.
- Story 002: pair iteration.
- Story 003: drip math (this story gates which pairs reach drip).
- Story 005: overlap-bit set call (this story decides which crowds eligible).

---

## QA Test Cases

- **AC-06 (Skip nil/Eliminated)**:
  - Given: pair (A, B) where csm.get("A") nil; pair (C, D) where C state==Eliminated
  - When: tick
  - Then: `csm.updateCount` spy zero calls for these pairs; no setStillOverlapping(true) from these pairs
  - Edge cases: both nil → skip silently; one Eliminated + one Active → drip skipped, overlap-bit reported only for the Active side (Story 005).

- **GraceWindow drip suspended**:
  - Given: A state=GraceWindow, B state=Active, overlap
  - When: tick
  - Then: zero updateCount calls for this pair; setStillOverlapping(A, true) AND setStillOverlapping(B, true) deferred to Story 005 (this story marks pair as "skip drip, report overlap-bit")
  - Edge cases: both GraceWindow → same behavior.

- **No state writes**:
  - Given: full source under `src/ServerStorage/Source/CollisionResolver/`
  - When: grep for `transitionTo\|setState\|setStateAsync`
  - Then: zero matches
  - Edge cases: comments containing the strings — handle with anchored regex.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/skip_conditions.spec.luau` — must exist and pass

**Status**: [x] Created 2026-05-08 — 16 it() blocks (AC-06 ×5, GraceWindow ×3, Active+Active regression ×1, Mixed scenarios ×3, No-state-writes tripwire ×1, dual-nil edge ×1, single-nil non-poisoning ×1, with `_setStillOverlappingSpy` tripwire); static grep `transitionTo|setState` call-sites: 0 matches in source.

---

## Dependencies

- Depends on: Stories 001-002.
- Unlocks: Stories 003 (gated drip), 005 (overlap-bit consumer).

---

## Completion Notes

**Completed**: 2026-05-08 (Sprint 6 task 6-8)
**Criteria**: 4/4 covered (AC-06 / GraceWindow drip suspended / GraceWindow ↔ GraceWindow / No state writes) via `tests/unit/collision/skip_conditions.spec.luau` — 16 it() blocks. Implementation note: Story 003's drip pass extended in-place rather than as separate skip-pass module — single drip loop now runs (a) csm.get nil-guard re-fetch, (b) state filter (Active+Active only), (c) drip math. Cleaner than two separate passes; pair entries remain in `_overlapPairs` regardless of skip outcome (Story 005 overlap-bit feed consumes the unfiltered set).
**Approach**: Added re-fetch via `_csm.get(entry.a.crowdId)` / `_csm.get(entry.b.crowdId)` at top of drip loop. Nil-guard `continue` skips the pair. State-filter `continue` (positive-list `recA.state ~= "Active" or recB.state ~= "Active"`) skips drip while preserving the pair entry. Tripwire spy on mock CSM (`transitionTo` + `setState` + `setStillOverlapping`) closes the runtime surface; static grep audits the source surface.
**Audit gates**: `selene src/` 0/7/0 baseline maintained; `audit-asset-ids.sh` PASS; `audit-persistence.sh` PASS; static grep `(transitionTo|setState)[A-Za-z_]*\s*\(` call-sites: 0 matches in CollisionResolver source (only doc-comment annotation at line 54 flagged — expected).
**Code Review**: Skipped (lean mode). gameplay-programmer + qa-tester ad-hoc reviews CHANGES REQUIRED → APPROVED after fixes; 1 BLOCKING defect + 4 advisory suggestions all applied in-loop:
1. **Defect fix**: scratch-clear test inline mock at `pair_iteration_overlap.spec.luau` lines 387-397 was missing `get` + `updateCount` — Story 004 drip pass would have errored at runtime. Added both methods (lookup-in-crowdList for `get`, no-op for `updateCount`).
2. `_setStillOverlappingSpy` tripwire assertion added to no-state-writes test (closes full ADR-0004 §Write-Access Matrix surface for Story 004 scope; Story 005 owns the actual fire).
3. Positive-list state filter comment added documenting design intent for Story 010+ state-machine extensions.
4. `_getOverlapPairsLength == 3` assertion added to Mixed Active/Eliminated/Active test (locks Story 005 prerequisite — drip-skip must NOT remove pair entries).
5. Dual-nil + 1-valid-pair test added (4 crowds, 2 simultaneous nil overrides, validates `continue` interaction across sequential skips before reaching valid pair).
**Mock back-compat fixes** (so Story 002 / Story 003 tests still run after Story 004 introduces csm.get re-fetch):
- `pair_iteration_overlap.spec.luau`: `buildMockCsm` extended with `get` (id-indexed lookup) + `updateCount` (no-op); `buildCrowd` adds `count = 50` field; inline mock at scratch-clear test fixed (defect above).
- `drip_math.spec.luau`: `buildMockCsm` extended with `get` (id-indexed lookup); existing assertions preserved.
**Deviations**:
- ADVISORY — Static grep AC ("zero matches") not implementable as TestEZ unit test (no FS access). Runtime tripwire spy substitutes; grep gate run separately during audits.
- ADVISORY (carried from Story 001) — `getClock()` discard each tick. AbsorbSystem precedent.
**Files changed**:
- `src/ServerStorage/Source/CollisionResolver/init.luau` (drip pass extended: csm.get nil-guard + state filter + positive-list comment)
- `tests/unit/collision/skip_conditions.spec.luau` (new, 16 it() blocks)
- `tests/unit/collision/pair_iteration_overlap.spec.luau` (mock CSM back-compat extension + scratch-clear inline mock fix + buildCrowd count field)
- `tests/unit/collision/drip_math.spec.luau` (mock CSM back-compat extension)
