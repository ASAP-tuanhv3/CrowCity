# Story 002: F1 overlap test + F2 contention resolution

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md`
**Requirement**: `TR-absorb-002`, `TR-absorb-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 Server-Authoritative Validation (overlap server-only)
**ADR Decision Summary**: F1 + F2 are GDD-internal formulas. ADR-0010 ensures overlap and contention run server-side only — no client-asserted absorb claims. CSM positions/radii are read via `getAllActive()` read-only API (ADR-0004).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Server-authoritative overlap (ADR-0010)
- Required: Read-only consumer of CSM `getAllActive()` / `getAllCrowdPositions()` (ADR-0004)
- Forbidden: Mutate the table returned by `csm.getAllActive` (ADR-0004 read-only contract)
- Forbidden: Use `payload.timestamp` / `payload.tick` for gameplay decisions — server clock authoritative (ADR-0010)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md`, scoped to this story:*

- [ ] **AC-1 (F1 overlap, Y ignored)**: GIVEN crowd at `(0,10,0)`, radius=5, NPC at `(3,0,4)` THEN `dx² + dz² = 25 ≤ 25` TRUE → absorbed; NPC at `(4,0,4)` → `32 > 25` FALSE → not absorbed. Y-component never enters formula.
- [ ] **AC-2 (F2 lex tiebreak)**: GIVEN crowds `"alpha"` + `"beta"` both at distance 4.9 from same NPC THEN `"alpha"` wins (lex compare on crowdId); `"beta"` does not fire Absorbed.
- [ ] **AC-3 (F2 distance)**: GIVEN `"zulu"` at dist 3.0 + `"alpha"` at dist 4.0 THEN `"zulu"` wins regardless of lex order.
- [ ] **F1 squared-distance**: implementation MUST use squared distance against radius² (no `math.sqrt` per overlap test).

---

## Implementation Notes

*Derived from GDD §F1/F2 + ADR-0010 §Server-Authoritative Reads:*

- F1 form: `function isOverlap(cx, cz, npcX, npcZ, radiusSq) return ((npcX - cx)^2 + (npcZ - cz)^2) <= radiusSq end` — pre-square radius once per crowd per tick.
- For each NPC in snapshot, build `{crowdId, distSq}` candidate list of every crowd whose 2D bbox contains it, then resolve via F2.
- F2 contention: `argmin(distSq)` then lex `crowdId` tiebreak. Implement as single linear pass tracking `(bestCrowdId, bestDistSq)`; on `distSq == bestDistSq` compare `crowdId < bestCrowdId`.
- Cache per-tick `{crowdId, posX, posZ, radiusSq}` array at top of `tickPhase3` from `csm.getAllActive()` — avoid per-NPC table indexing.
- Y-axis explicitly dropped: read `position.X` and `position.Z` only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Phase 3 callback registration / DI scaffold.
- Story 003: Per-overlap sequence (Absorbed → updateCount → reclaim).
- Story 004: State guards (Active/GraceWindow/Eliminated skip).

---

## QA Test Cases

- **AC-1 (F1 overlap, Y ignored)**:
  - Given: 1 crowd `(0,10,0)` radius=5; 2 NPCs at `(3,0,4)` + `(4,0,4)`
  - When: `tickPhase3(1)` fires
  - Then: NPC1 absorbed, NPC2 not absorbed
  - Edge cases: NPC at exact boundary `dx²+dz² = radiusSq` → absorbed (≤ inclusive); negative deltas; NPC.Y far from crowd.Y → still absorbed.

- **AC-2 (F2 lex tiebreak)**:
  - Given: crowds `"alpha"` `"beta"` at equal distSq from same NPC
  - When: contention resolves
  - Then: `"alpha"` fires Absorbed exactly once; `"beta"` does not
  - Edge cases: 3-way tie picks lowest lex; identical crowdId case impossible (CSM rejects duplicates).

- **AC-3 (F2 distance dominates lex)**:
  - Given: `"zulu"` distSq=9.0; `"alpha"` distSq=16.0 from same NPC
  - When: contention resolves
  - Then: `"zulu"` wins
  - Edge cases: distSq difference of ε (1e-9) still resolves deterministically by `<` semantics.

- **F1 perf shape**:
  - Given: 12 crowds × 300 NPCs (3600 tests)
  - When: 1 tick
  - Then: zero `math.sqrt` calls in absorb path (verify via spy on math)
  - Edge cases: radius=0 crowd produces zero overlaps (defensive only — CSM clamps count≥1 → radius≥3.05).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/absorb/overlap_contention.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Phase 3 skeleton + DI).
- Unlocks: Story 003 (sequence consumes overlap result).


## Completion Notes
**Completed**: 2026-05-06 (Sprint 5 batch close)
**Lean mode**: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per production/review-mode.txt
**Audits**: selene 0/7/0, asset-id PASS, persistence PASS
**Test Evidence**: see story Test Evidence section — file at expected path
