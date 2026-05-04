# Story 012: Pool hide/unhide LOD swap — no Instance.new on swap

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: AC-18 — pool hide/unhide discipline. Touches `TR-follower-entity-003` (pool prealloc) and `TR-follower-entity-015` (LOD render caps).
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Pool entries are pre-allocated at boot. LOD swap hides one tier's Parts (returns to inactive set) and un-hides the new tier's Parts. No `Instance.new` on swap. Hide path: `Body.LocalTransparencyModifier = 1` or equivalent; deactivate flag; reposition out-of-frustum.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: `LocalTransparencyModifier` (BasePart) is pre-cutoff stable; alternative is parenting to a hidden Folder. Either path acceptable as long as net instance count under crowd Folder is unchanged.

**Control Manifest Rules (Presentation layer)**:
- Required: pool granted parts hidden via flag, NOT destroyed (Story 001)
- Forbidden: per-frame `Instance.new`
- Guardrail: ≤150 rendered Parts per client view

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-18 (Pool hide/unhide, no alloc)**: Given pre-allocated pools at startup (460 Body + 460 Hat + 100 LOD 1 + 60 LOD 2), when LOD tier swap occurs (0→1), then (a) LOD-0 Body hidden (NOT destroyed) — verify via `Body.LocalTransparencyModifier = 1` or equivalent hide path; (b) LOD-1 Part un-hidden from LOD-1 pool; (c) count of instances under the crowd Folder before and after swap is identical (no net alloc, no net destroy).
- [ ] Evidence file at `production/qa/evidence/lod-swap-[YYYY-MM-DD].txt` (or .md) — must include scenario summary, before/after instance counts under the crowd Folder, hide path used (LocalTransparencyModifier vs parent-swap), PASS/FAIL.
- [ ] No `Instance.new` calls fire during a `setLOD(0 → 1)` or `setLOD(1 → 0)` transition — verify by spying on `Instance.new` (if test framework permits) OR by counting Folder children before/after.
- [ ] `setLOD` produces atomic per-Part swap (no half-tier states) — verified by sampling between two RenderStepped frames during the swap; no Part left in tier-0 hidden state but tier-1 unfilled.
- [ ] Reverse swap (1 → 0) also no-alloc.

---

## Implementation Notes

*Derived from ADR-0007 §Pool Allocation Strategy + GDD §Pool architecture:*

- This is an **Integration test** validating the implementation completed in Story 010 (`setLOD`) + Story 001 (pool).
- Hide path options (pick one consistently):
  1. **`LocalTransparencyModifier = 1`** + `CanQuery=false`/`CanTouch=false` flags — keeps Part parented to crowd Folder; cheapest, most direct.
  2. **Parent-swap** — re-parent to `Workspace._FollowerPool` Folder. Slightly more expensive but fully removes from render-relevant queries.
  - GDD §Pool architecture §Active deactivation prefers `Transparency = 1` + `Position = Vector3.new(0, -1000, 0)` (out-of-frustum).
  - ADR-0007 §Pool Allocation Strategy aligns: Active deactivation uses `Transparency = 1`, position out-of-frustum.
  - Recommend: `Transparency = 1` (simpler than `LocalTransparencyModifier`) + `Position = Vector3.new(0, -1000, 0)` per ADR. Verification looks for `Transparency = 1` on hidden Parts.
- Test scenario:
  1. Build a perf-fixture: 1 crowd at LOD 0 with 80 followers (160 Parts active under crowd Folder + the LOD-1 inactive pool + LOD-2 inactive pool).
  2. Snapshot: count Parts in crowd Folder + count Parts in `_FollowerPool` Folder. Record total.
  3. Call `setLOD(1)` followed by `setPoolSize(15)`.
  4. Snapshot: count Parts in crowd Folder + count in `_FollowerPool`. Record total.
  5. Assert: total before == total after; LOD-0 Parts moved from crowd Folder to `_FollowerPool` (or hidden in place with `Transparency = 1`); LOD-1 Parts moved from `_FollowerPool` to crowd Folder (or un-hidden with `Transparency = 0`).
  6. No `Instance.new` calls fired (spy if framework permits; otherwise trust the count equality + git-grep for `Instance.new` in implementation).
- Reverse swap: same scenario, `setLOD(0)` and `setPoolSize(80)`. Same invariants.
- Capture evidence: instance counts before/after, the hide path chosen, any GC pauses observed.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 010: `setLOD` implementation.
- Story 001: pool pre-alloc.
- Story 011: per-frame perf budget validation.

---

## QA Test Cases

- **Manual check + scripted: AC-18 LOD 0 → 1 swap**:
  - Setup: rojo-built perf-fixture with 1 crowd at LOD 0, 80 followers active. Total Parts under crowd Folder = 160 (2 × 80) + LOD-1 pool 100 + LOD-2 pool 60 = 320 Parts in `Workspace._FollowerPool` (subtract the 160 currently in crowd folder if pool is pre-allocated under that folder; reconcile with chosen hide path).
  - Verify: snapshot before; `setLOD(1)` + `setPoolSize(15)` runs; snapshot after.
  - Pass condition: total instance count (sum of crowd folder + pool folder) IDENTICAL before vs after; 160 LOD-0 Parts now Transparency=1 (hidden) and 15 LOD-1 Parts now Transparency=0 (visible).
  - Edge cases: a peel in flight during the swap — Peeling Parts retain visibility (Story 009 immunity); count still matches.

- **Manual check: AC-18 LOD 1 → 0 reverse swap**:
  - Setup: starting from end-state of previous test (LOD 1, 15 followers visible).
  - Verify: snapshot before; `setLOD(0)` + `setPoolSize(80)` runs; snapshot after.
  - Pass condition: same count invariant; 80 LOD-0 Parts now Transparency=0; 15 LOD-1 Parts back to Transparency=1.

- **Manual / scripted check: no `Instance.new` during swap**:
  - Setup: instrument code with a counter that increments on every `Instance.new` call (TestEZ spy or runtime hook).
  - Verify: counter delta before vs after `setLOD(1)` + `setPoolSize(15)` is exactly 0.
  - Pass condition: 0 `Instance.new` calls.
  - Edge cases: the FIRST swap of the session may legitimately fire on a code path that pre-allocates — if so, document; subsequent swaps must be 0.

- **Manual check: evidence file present + valid**:
  - Setup: after both swap directions verified, write evidence file.
  - Verify: `production/qa/evidence/lod-swap-[date].txt` exists; contains before/after counts, hide path chosen, PASS/FAIL verdict.
  - Pass condition: file exists AND PASS verdict documented.

- **Manual check: atomic per-Part swap**:
  - Setup: instrument or pause execution between RenderStepped frames during the swap.
  - Verify: no intermediate state where some LOD-0 Parts are hidden and others still visible AND LOD-1 Parts still all hidden (i.e., no half-tier state).
  - Pass condition: swap completes within one frame; per-Part state is consistent at any sampled point.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/lod-swap-[YYYY-MM-DD].txt` — must exist with PASS verdict + before/after instance counts
- Sign-off: gameplay-programmer + qa-lead in evidence file footer

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (pool prealloc), Story 009 (setPoolSize), Story 010 (setLOD)
- Unlocks: epic gate (AC-18 closes)
