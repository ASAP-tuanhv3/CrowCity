# Story 007: Equal-count two-way peel emission

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy
**ADR Decision Summary**: Equal-count overlap → mutual drain (Story 003) AND two peel buffer entries (A→B and B→A) so each player sees followers peel toward their rival visually. Peel buffer entries consumed by PeelDispatcher (Story 008).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules (Feature layer)**:
- Required: Equal-count two-way peel emission per GDD Rule 5 (peel symmetric on equal-count drain)
- Required: Peel buffer entry schema `{attackId, defendId, n}`

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-17 (Equal-count two-way peel emission)**: GIVEN A (count=50) + B (count=50) overlap, WHEN one tick runs, THEN `_overlapPairs` contains EXACTLY two entries: `{attackId="A", defendId="B", delta=1}` AND `{attackId="B", defendId="A", delta=1}`. PeelDispatcher (Story 008) sends one entry to A's buffer (loser=B winner=A) and one to B's (loser=A winner=B).
- [ ] **Standard inequality case**: A (count=100) + B (count=50) → 1 entry `{attackId="A", defendId="B", delta=2}`. NOT two entries.

---

## Implementation Notes

*Derived from GDD §C Rule 5 + §F (peel buffer entry schema):*

- After drip math (Story 003) computes delta, append entry to `_peelBuffer` (separate scratch from `_overlapPairs`):
  - if `countA > countB`: `_peelBuffer:append({attackId=a.id, defendId=b.id, delta=delta})`.
  - if `countA < countB`: reverse direction.
  - if `countA == countB` (equal): append BOTH `{a→b, delta=1}` AND `{b→a, delta=1}`. Two entries.
- Schema fields: `attackId: string` (winning crowd id, follower destination), `defendId: string` (losing crowd id, follower origin), `delta: number` (count of followers peeling).
- `_peelBuffer` is a per-tick array; cleared at top of next tick. Story 008 reads it for batched FireClient dispatch.
- Equal-count visual: each side sees its own followers being added (visual peel arriving from rival) — symmetric. The mutual drain count change is -1 each from Story 003; peel visual count +1 each from this story's two-way emission. Net visual: count unchanged but follower-visual movement evident.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: drip math (this story consumes computed delta).
- Story 008: PeelDispatcher batching + relevance filter.
- Story 009: client peel observation.

---

## QA Test Cases

- **AC-17 (Equal-count two-way emission)**:
  - Given: A count=50, B count=50, overlap, both Active
  - When: tick fires
  - Then: `_peelBuffer` has 2 entries: `{attackId="A", defendId="B", delta=1}` + `{attackId="B", defendId="A", delta=1}`
  - Edge cases: equal at count=300 (max) — same two entries; equal at count=2 — two entries delta=1.

- **Standard inequality (single entry)**:
  - Given: A count=100, B count=50, overlap
  - When: tick fires
  - Then: `_peelBuffer` has 1 entry `{attackId="A", defendId="B", delta=2}`; no second entry
  - Edge cases: A count=300, B count=10 → delta=4 (clamp); single entry only.

- **Order in buffer**:
  - Given: 3 pairs producing 4 entries (1 standard + 1 equal-count)
  - When: tick
  - Then: order matches pair-iteration order (deterministic across runs)
  - Edge cases: useful for snapshot diffing in tests.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/equal_count_two_way_peel.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (drip math computes delta).
- Unlocks: Story 008 (PeelDispatcher consumes _peelBuffer).
