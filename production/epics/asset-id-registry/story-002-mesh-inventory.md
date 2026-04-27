# Story 002: Populate Mesh inventory (Char/Prop/Env)

> **Epic**: asset-id-registry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 2–3 hours
> **Completed**: 2026-04-27

## Context

**GDD**: N/A — inventory locked by `design/art/art-bible.md` §8.8 (file naming) + cross-ref Follower Entity GDD §C.1 (2-Part rig) + Chest GDD §C (T1/T2/T3 instances) + arena-layout (level design pending — env props placeholder)
**Requirement**: TR-asset-id-??? (Foundation infra — no TR registered; cite ADR-0006 §Source Tree Map + art bible §8.8 directly)

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: All mesh references resolve through `SharedConstants/AssetId.Mesh`. Story 001 created the empty sub-table; this story populates it.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Roblox MeshPart asset references via `rbxassetid://N`. Real upload via Studio Asset Manager (out of scope here — placeholder ids used).

**Control Manifest Rules (Foundation layer)**:
- Required: `AssetId enum for every mesh reference` (control-manifest.md L29)
- Required: `--!strict` (global)
- Forbidden: `Magic strings cross-module` (control-manifest.md L47)

---

## Acceptance Criteria

*Derived from art bible §8.8 inventory examples + downstream system needs (Follower Entity GDD §C.1, Chest GDD §C, NPC Spawner GDD):*

- [ ] AC-1: `AssetId.Mesh` populated with character mesh slots: `CharFollowerBody`, `CharFollowerHat`, `CharPlayerAvatar`, `CharNpcNeutral` (4 entries — Follower Entity 2-Part rig + player + neutral NPC mesh)
- [ ] AC-2: `AssetId.Mesh` populated with prop slots: `PropChestT1`, `PropChestT2Car`, `PropChestT3Building` (3 entries — T3 reserved even though gameplay deferred to Alpha)
- [ ] AC-3: `AssetId.Mesh` populated with environment slots: `EnvBuildingBlockA`, `EnvBuildingBlockB`, `EnvFloor`, `EnvBoundaryWall` (4 entries — placeholder until level design lands)
- [ ] AC-4: All values are non-empty strings of form `rbxassetid://N` (placeholder `rbxassetid://0` allowed)
- [ ] AC-5: All keys follow PascalCase + `[Category][AssetName]` convention per art bible §8.8 L361
- [ ] AC-6: No duplicate values across all populated `Mesh` keys (placeholder `rbxassetid://0` exempted from uniqueness check)

---

## Implementation Notes

*Derived from ADR-0006 + art bible §8.8 + consumer GDDs:*

- Add entries directly into `AssetId.Mesh = { ... }` table populated in story 001. Do not create a separate sub-module.
- Naming convention is canonical and not negotiable here — matches art bible §8.8 prefix table:
  - `Char*` — characters (followers, players, NPCs)
  - `Prop*` — interactive props (chests)
  - `Env*` — environment (buildings, ground)
- Architecture cross-ref: Follower Entity GDD §C.1 specifies "2-Part Body+Hat" — `CharFollowerBody` + `CharFollowerHat` are the two Parts. `CharNpcNeutral` is shared NPC body (no hat per game-concept "oblivious drifter" fantasy).
- T3 building mesh slot reserved despite Alpha-tier gameplay — registry shape stays stable across milestones.
- Top-of-file comment block: list MVP scope vs reserved-for-VS+ slots so future readers know which placeholders are intentionally unfilled.

---

## Out of Scope

*Handled elsewhere — do not implement here:*

- Real asset upload via Studio Asset Manager (art-pipeline task; not a code story)
- Story 003: Particle + Sound inventory + Sounds.luau retirement
- Story 004: Static-audit gate
- Skin entries (story 001 owns `AssetId.Skin`)
- Per-mesh import settings (LOD, collision fidelity) — owned by Studio import workflow, not the registry

---

## QA Test Cases

- **AC-1 / AC-2 / AC-3**: inventory completeness
  - Given: `AssetId.luau` loaded
  - When: read `AssetId.Mesh`
  - Then: every required key from each AC is present and is a string
  - Edge cases: missing key → fail with named key in error; key spelled wrong → fail (test uses literal string list)

- **AC-4**: value format
  - Given: `AssetId.Mesh` table
  - When: iterate all entries
  - Then: each value matches `^rbxassetid://%d+$`
  - Edge cases: empty string fail; missing `rbxassetid://` prefix fail; non-numeric tail fail

- **AC-5**: naming convention
  - Given: `AssetId.Mesh` table
  - When: iterate keys
  - Then: each key matches `^[A-Z][a-z]+[A-Z]` (Category-prefixed PascalCase)
  - Edge cases: `chestT1` fail; `CHEST_T1` fail; `Chest-T1` fail

- **AC-6**: uniqueness
  - Given: populated `AssetId.Mesh`
  - When: collect all values, filter out `rbxassetid://0` placeholders, build a Set
  - Then: Set size == filtered count (no real duplicates)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/asset-id/mesh-inventory_test.luau` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (AssetId module skeleton must exist with `Mesh = {}` sub-table present)
- Unlocks: any story that requires mesh references (Follower Entity client-sim epic, Chest System epic, NPC Spawner epic, level-design epics)

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 6/6 passing
**Deviations**: None
**Test Evidence**: Logic story — unit test at `tests/unit/asset-id/mesh-inventory_test.luau` (6 test functions, all ACs covered)
**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` (41 L) — Mesh table populated with 11 entries (4 char, 3 prop, 4 env); all placeholder `rbxassetid://0` per MVP timeline
- `tests/unit/asset-id/mesh-inventory_test.luau` (88 L, 6 test fns) — TestEZ unit test covering AC-1 through AC-6 with advisory annotations on TestEZ limitations

**Manifest Version**: 2026-04-27 (current ✓ no staleness)

**Unblocks**: Story 003 (Particle + Sound inventory + Sounds.luau migration). `AssetId.Mesh` now populated with all MVP character/prop/environment slots reserved.
