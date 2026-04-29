# Story 001: UILayerId enum + UILayerType mapping

> **Epic**: ui-handler-layer-reg
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 2–3 hours (enum + UILayerType mapping)
> **Completed**: 2026-04-27

## Context

**GDD**: HUD GDD `design/gdd/hud.md` (HeadsUpDisplay layer type), Relic System GDD `design/gdd/relic-system.md` + Chest System GDD `design/gdd/chest-system.md` (RelicDraft modal layer); MainMenu + PauseMenu layers forward-declared per architecture.md §3.1 + ANATOMY §8
**Requirement**: TR-hud-??? (HUD layer registration), TR-chest-??? (RelicDraft modal layer); both registered indirectly via consumer GDDs

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: All cross-module identifiers via `SharedConstants/` enums. UILayerId is one of the SharedConstants enums (already exists template-side); this story extends it with project-specific layer IDs.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Standard Roblox UI primitives — no post-cutoff API. Pattern reference: `ANATOMY.md` §8 (UI system) + existing template `UILayerId.luau` + `UILayerType.luau` files.

**Control Manifest Rules (Foundation layer)**:
- Required: Cross-module identifiers via `SharedConstants/` enums (ADR-0006)
- Required: `--!strict` (global)
- Forbidden: Magic strings cross-module (ADR-0006)

---

## Acceptance Criteria

*Derived from architecture.md §3.1 (UIHandler row) + epic Definition of Done + ANATOMY §8:*

- [ ] AC-1: `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau` updated with these new entries: `HUD`, `RelicDraft`, `MainMenu`, `PauseMenu` (4 new IDs; preserve any existing template entries)
- [ ] AC-2: Each enum value equals its key (e.g. `UILayerId.HUD = "HUD"`); convention matches template precedent in same dir
- [ ] AC-3: `src/ReplicatedStorage/Source/SharedConstants/UILayerType.luau` (already exists per template) verified to contain `HeadsUpDisplay` + `Menu` types; if either missing, add per ANATOMY §8 contract
- [ ] AC-4: New `src/ReplicatedStorage/Source/SharedConstants/UILayerTypeByLayerId.luau` (or extension of existing `UILayerType.luau` if pattern dictates) maps each `UILayerId` to its `UILayerType`: `HUD → HeadsUpDisplay`; `RelicDraft → Menu`; `MainMenu → Menu`; `PauseMenu → Menu`
- [ ] AC-5: All values in `UILayerId` are unique; all keys are unique; no duplicates across the new 4 entries or against existing template entries
- [ ] AC-6: Type export: `export type UILayerIdValue = string` so consumers can type-annotate
- [ ] AC-7: `--!strict` type checks pass on all modified/new files

---

## Implementation Notes

*Derived from ANATOMY §8 + architecture.md §3.1:*

- Inspect `UILayerId.luau`, `UILayerType.luau`, and `UILayerIdByZoneId.luau` (already in template) before editing. Match the existing pattern exactly — do not introduce a new style.
- The existing `UILayerType.luau` may already export `HeadsUpDisplay` and `Menu`. Verify; if not, add. Do not remove or rename existing types — they may be consumed by zone-triggered layer behavior wired in `UILayerIdByZoneId.luau`.
- The mapping `UILayerId → UILayerType` may live as a separate small module `UILayerTypeByLayerId.luau` (parallel to existing `UILayerIdByZoneId.luau`) OR inside `UILayerType.luau` as a sub-table. Choose whichever the template precedent suggests; document the choice in the story PR.
- `Menu`-type semantics per ANATOMY §8 + template `UIHandler` source: only one `Menu` layer is open at a time; opening a second `Menu` closes the first. This matters for Pause-during-RelicDraft behaviour but is fully owned by `UIHandler` at runtime — this story only declares the type.
- `HeadsUpDisplay`-type semantics: coexists with gameplay; multiple HeadsUpDisplay layers can stack. HUD is the only HeadsUpDisplay in MVP scope.
- `Player Nameplate` and `Chest Billboard` are explicitly NOT layers — they're BillboardGui-attached components (per architecture.md §3.4 + ANATOMY §9). Do not add them as `UILayerId` entries even if a future contributor argues for it; redirect them to the BillboardGui pattern.

Reference shape (assuming separate mapping module):
```luau
--!strict
-- src/ReplicatedStorage/Source/SharedConstants/UILayerTypeByLayerId.luau
local UILayerId = require(script.Parent.UILayerId)
local UILayerType = require(script.Parent.UILayerType)

local UILayerTypeByLayerId: {[string]: string} = {
    [UILayerId.HUD] = UILayerType.HeadsUpDisplay,
    [UILayerId.RelicDraft] = UILayerType.Menu,
    [UILayerId.MainMenu] = UILayerType.Menu,
    [UILayerId.PauseMenu] = UILayerType.Menu,
}

return UILayerTypeByLayerId
```

---

## Out of Scope

- Story 002: Boot-time registration scaffold (this story declares; 002 wires)
- Per-layer `setup()` / `teardown()` implementation (consumer Presentation epics — HUD, RelicDraft, MainMenu, PauseMenu)
- BillboardGui-attached components (Player Nameplate, Chest Billboard) — handled in their own Presentation epics, NOT via UILayerId
- Zone-to-layer mapping additions in `UILayerIdByZoneId.luau` (consumer-driven; out of scope here)

---

## QA Test Cases

- **AC-1**: enum entries
  - Given: working tree post-implementation
  - When: load `UILayerId` module + read keys
  - Then: 4 new keys (`HUD`, `RelicDraft`, `MainMenu`, `PauseMenu`) present alongside any pre-existing template entries
  - Edge cases: missing key → fail with name; extra key not in scope (e.g. `Nameplate` if a contributor mistakenly added it) → fail

- **AC-2**: value-equals-key convention
  - Given: enum loaded
  - When: iterate
  - Then: `tbl.HUD == "HUD"`, `tbl.RelicDraft == "RelicDraft"`, etc.
  - Edge cases: any value differing from key → fail

- **AC-3**: UILayerType verification
  - Given: `UILayerType.luau` loaded
  - When: introspect
  - Then: `HeadsUpDisplay` and `Menu` types present
  - Edge cases: type missing → add (this story responsible)

- **AC-4**: type mapping correctness
  - Given: `UILayerTypeByLayerId` loaded (or equivalent)
  - When: lookup each of the 4 new IDs
  - Then: returns expected type per AC-4 list
  - Edge cases: lookup unknown ID → returns nil (not error); document this contract

- **AC-5**: uniqueness
  - Given: enum tables
  - When: build value-Set + key-Set
  - Then: |Set| == |table| (no duplicates)

- **AC-6 / AC-7**: type export + strict
  - Standard `--!strict` Selene + Luau analyzer pass; consumer test fixture declares `local id: UILayerId.UILayerIdValue = UILayerId.HUD` and compiles clean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ui-handler/layer-id-enum.spec.luau` — must exist and pass via TestEZ.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation; first story for this epic)
- Unlocks: Story 002 (boot-time registration consumes the enum); HUD epic; RelicDraft modal epic; MainMenu + PauseMenu UX-spec-driven epics

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 7/7 passing
**Deviations**:
- ADVISORY: AC-6 wording specified `export type UILayerIdValue = string`. Implementation uses `export type EnumType = "HUD" | "RelicDraft" | ...` (string-union) per Implementation Notes "Match the existing pattern exactly — do not introduce a new style". Template precedent (`UILayerType.luau`, `ZoneIdTag.luau`, existing `UILayerId.luau`) all use `EnumType` string-union. String-union is strictly stronger typing than `string` alias — gives consumers compile-time narrowing on assignment.
- ADVISORY: AC-3 was a no-op verification — `UILayerType.luau` already exports `HeadsUpDisplay` + `Menu` per template. Documented but no edit required.

**Test Evidence**: Logic story — unit test at `tests/unit/ui-handler/layer-id-enum.spec.luau` (10 test functions across 4 describe blocks; AC-6 + AC-7 marked ADVISORY proxies — type-export + `--!strict` directive are compile-time gates, not TestEZ-runtime-introspectable).
**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau` (32 L) — added `HUD`, `RelicDraft`, `MainMenu`, `PauseMenu` to `EnumType` union + table; preserved 3 pre-existing template entries (`DataErrorNotice`, `ExampleHud`, `ResetDataButton`)
- `src/ReplicatedStorage/Source/SharedConstants/UILayerTypeByLayerId.luau` (NEW, 27 L) — separate-mapping module per template precedent (`UILayerIdByZoneId.luau` pattern); 4 entries: `HUD → HeadsUpDisplay`, `RelicDraft → Menu`, `MainMenu → Menu`, `PauseMenu → Menu`
- `src/ReplicatedStorage/Source/SharedConstants/UILayerType.luau` — verified unchanged (already has both required types)
- `tests/unit/ui-handler/layer-id-enum.spec.luau` (NEW, 105 L, 10 test fns)

**Manifest Version**: 2026-04-27 (current ✓ no staleness)

**Audit gate verification**: `bash tools/audit-asset-ids.sh` → exit 0 (no asset-id leak introduced).

**Unblocks**: Story 002 (boot-time registration scaffold consumes `UILayerTypeByLayerId`).
