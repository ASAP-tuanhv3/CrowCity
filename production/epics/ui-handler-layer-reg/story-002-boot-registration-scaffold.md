# Story 002: Boot-time layer registration scaffold (no-op setup stubs)

> **Epic**: ui-handler-layer-reg
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-27
> **Estimate**: 2–3 hours (boot-time registration, no-op stubs)

## Context

**GDD**: ANATOMY §8 (UI system contract) + HUD GDD (HUD layer setup), RelicDraft modal contract from Chest System GDD §C
**Requirement**: TR-hud-???, TR-chest-??? (consumed indirectly)

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: Client entry point (`ReplicatedFirst/Source/start.server.luau`) is one of two RunContext-bearing scripts in the project; all client orchestration begins here. This story extends the entry point's UI-init block with `UIHandler.registerLayer` calls for the 4 new layer IDs.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Standard `ScreenGui` / `UIHandler` template surface. Pattern reference: `ANATOMY.md` §8 + existing `UIExampleHud.luau` (a minimal working example shipped with the template).

**Control Manifest Rules (Foundation layer)**:
- Required: Cross-module identifiers via `SharedConstants/UILayerId` (ADR-0006)
- Required: Two-entry-point invariant — all client orchestration begins from `ReplicatedFirst/Source/start.server.luau` (ADR-0006)
- Forbidden: Magic strings cross-module (ADR-0006)
- Forbidden: Scripts beyond two entry points (ADR-0006)

---

## Acceptance Criteria

*Derived from ANATOMY §8 (UIHandler.registerLayer contract) + architecture.md §3.1 (UIHandler responsibilities):*

- [ ] AC-1: Client entry point `src/ReplicatedFirst/Source/start.server.luau` extended with a new init block (placed AFTER the existing `UIHandler` import + BEFORE the loading-screen-hide step, per ANATOMY §8 lifecycle ordering) that registers all 4 new layer IDs
- [ ] AC-2: Each of the 4 layers (`HUD`, `RelicDraft`, `MainMenu`, `PauseMenu`) is registered via `UIHandler.registerLayer(id, layerType, setupCallback, teardownCallback)` where `setupCallback` and `teardownCallback` are no-op stubs (`function() end`) for now
- [ ] AC-3: Each registration call is wrapped in a top-of-block comment naming the consumer epic responsible for replacing the no-op stub (e.g. `-- HUD: stub setup/teardown — replaced by HUD Presentation epic`)
- [ ] AC-4: Boot completes without error: client startup proceeds past the registration block; no exception, no infinite yield
- [ ] AC-5: At post-boot, calling `UIHandler.openLayer(UILayerId.HUD)` succeeds (returns truthy / does not error). The no-op setup runs; HUD doesn't visually render anything yet (stub) but the layer is "open" per UIHandler internal state
- [ ] AC-6: `UIHandler.openLayer(UILayerId.RelicDraft)` while HUD is open: HUD remains open (it's `HeadsUpDisplay`-type; coexists). RelicDraft is now the active Menu layer per ANATOMY §8 single-Menu rule
- [ ] AC-7: `UIHandler.openLayer(UILayerId.PauseMenu)` while RelicDraft is open: RelicDraft auto-closes (single-Menu rule); PauseMenu opens
- [ ] AC-8: `UIHandler.closeLayer(UILayerId.PauseMenu)`: PauseMenu's no-op teardown runs; UIHandler reverts to no-active-Menu state
- [ ] AC-9: `--!strict` type checks pass on all modified files. Two-entry-point invariant holds (no new RunContext-bearing scripts added per ADR-0006)
- [ ] AC-10: Integration test `tests/integration/ui-handler/boot-registration_test.luau` exercises AC-4 through AC-8 end-to-end via TestEZ in-Studio harness

---

## Implementation Notes

*Derived from ANATOMY §8 + ADR-0006 §Two-Entry-Point Invariant + existing template `UIExampleHud.luau`:*

- File path is fixed by ADR-0006 §Source Tree Map: `src/ReplicatedFirst/Source/start.server.luau` — DO NOT add a new script. The two-entry-point invariant is non-negotiable.
- Locate the existing `-- TODO:` block in the entry script that comments "after loading screen hides for post-load systems" (per CLAUDE.md §Step 3 integration guide). The new init block goes there.
- Read existing template patterns first: `UIExampleHud.luau` shows the canonical `setup()` / `teardown()` shape. The no-op stubs in this story are intentionally minimal — consumer Presentation epics will replace them with real setups that mirror `UIExampleHud.luau` structure.
- `UIHandler.registerLayer` signature (per ANATOMY §8): `registerLayer(layerId: string, layerType: string, setup: (player: Player) -> (), teardown: (player: Player) -> ())`. If the template signature differs, match the template — do not introduce a new signature.
- Stub callbacks accept the `player` arg (matching ANATOMY §8 convention) but do nothing:
  ```luau
  local function noopSetup(_player: Player) end
  local function noopTeardown(_player: Player) end

  UIHandler.registerLayer(UILayerId.HUD,        UILayerType.HeadsUpDisplay, noopSetup, noopTeardown)
  UIHandler.registerLayer(UILayerId.RelicDraft, UILayerType.Menu,           noopSetup, noopTeardown)
  UIHandler.registerLayer(UILayerId.MainMenu,   UILayerType.Menu,           noopSetup, noopTeardown)
  UIHandler.registerLayer(UILayerId.PauseMenu,  UILayerType.Menu,           noopSetup, noopTeardown)
  ```
- Comment block naming consumer epics (AC-3) — exact text helps grep-replace at consumer-epic time:
  ```luau
  -- TODO: HUD epic replaces noopSetup/noopTeardown for UILayerId.HUD with real implementation per design/gdd/hud.md
  -- TODO: RelicDraft epic replaces stubs for UILayerId.RelicDraft per design/gdd/chest-system.md §C
  -- TODO: MainMenu epic replaces stubs for UILayerId.MainMenu per design/ux/main-menu.md (UX spec pending)
  -- TODO: PauseMenu epic replaces stubs for UILayerId.PauseMenu per design/ux/pause-menu.md (UX spec pending)
  ```
- Integration test (AC-10) lives under `tests/integration/` not `tests/unit/` because boot-order verification requires the full client-init sequence — not a pure unit boundary.

---

## Out of Scope

- Story 001: enum + type mapping (story 001 owns; this story consumes)
- Real `setup()` / `teardown()` implementations (HUD, RelicDraft, MainMenu, PauseMenu Presentation epics)
- UX specs for MainMenu / PauseMenu (separate Tier 1 Sprint 0 task per active.md)
- BillboardGui-attached components (Nameplate, Chest Billboard) — separate Presentation epics

---

## QA Test Cases

- **AC-1 / AC-2 / AC-3 / AC-9**: structural + strict
  - Given: working tree post-implementation
  - When: read entry script + grep for `UIHandler.registerLayer`
  - Then: 4 calls present, each followed by a `-- TODO: [epic] replaces ...` comment; `--!strict` clean; no new entry-point scripts
  - Edge cases: registration order matters? — UIHandler is order-tolerant per template; document if not

- **AC-4**: boot-completes
  - Given: full client boot (Studio play test or TestEZ in-Studio harness)
  - When: client init proceeds past registration block
  - Then: no exception, no infinite yield, client reaches post-init state
  - Edge cases: late-registered layer (after openLayer call) → expected to error per UIHandler contract; this story does not exercise that path

- **AC-5**: HUD open
  - Given: post-boot client
  - When: `UIHandler.openLayer(UILayerId.HUD)`
  - Then: returns without error; UIHandler internal state shows HUD as open
  - Edge cases: re-opening already-open HUD → idempotent (UIHandler convention); document

- **AC-6**: HUD + Menu coexist
  - Given: HUD open
  - When: open RelicDraft Menu
  - Then: HUD remains open; RelicDraft is active Menu (verify via UIHandler state introspection or test spy)
  - Edge cases: zone-triggered Menu via `UILayerIdByZoneId` not exercised here

- **AC-7**: Menu single-active rule
  - Given: RelicDraft open
  - When: open PauseMenu
  - Then: RelicDraft's no-op teardown runs; PauseMenu open; HUD still open in background
  - Edge cases: RelicDraft teardown spy fires once

- **AC-8**: closeLayer reverts
  - Given: PauseMenu open
  - When: `UIHandler.closeLayer(UILayerId.PauseMenu)`
  - Then: PauseMenu teardown runs; UIHandler internal state shows no active Menu
  - Edge cases: closing a layer that isn't open → idempotent (no-op per template convention)

- **AC-10**: integration coverage
  - Given: TestEZ in-Studio harness
  - When: run `boot-registration_test.luau`
  - Then: all of AC-4..AC-8 verified end-to-end in one test run
  - Edge cases: harness not yet set up via `/test-setup` → ADVISORY at this story; manual verification documented in evidence doc

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui-handler/boot-registration_test.luau` — must exist and pass via TestEZ in-Studio harness. If full harness not yet available, manual walkthrough doc at `production/qa/evidence/ui-handler-boot-registration-evidence.md` documenting Studio play-test of AC-4..AC-8 acceptable as fallback per CLAUDE.md Testing Standards.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (UILayerId enum + UILayerType mapping must exist)
- Unlocks: HUD epic (consumer replaces no-op stub for `UILayerId.HUD`); RelicDraft modal epic (replaces stub for `UILayerId.RelicDraft`); MainMenu + PauseMenu epics (UX-spec-driven; replace remaining stubs)
