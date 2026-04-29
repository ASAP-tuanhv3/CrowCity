# Epic: UIHandler Layer Registration

> **Layer**: Foundation
> **GDD**: N/A — UI layer prereq; per-layer setup() lives in consuming Presentation epics (HUD, RelicDraft, MainMenu, PauseMenu)
> **Architecture Module**: UIHandler (architecture.md §3.1 row 4)
> **Status**: Complete (2026-04-27 — 1/1 effective; story 002 closed obsolete)
> **Stories**: 1 effective deliverable + 1 closed obsolete (see table below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [UILayerId enum + UILayerType mapping](story-001-ui-layer-id-enum.md) | Logic | Complete | ADR-0006 |
| 002 | [Boot-time layer registration scaffold](story-002-boot-registration-scaffold.md) | Integration | Obsolete (unimplemented) | ADR-0006 + ANATOMY §8 |

Order: 001 only. Story 002 closed unimplemented — see Story 002 §Closure Note.

## Overview

This epic forward-declares the UILayerId enum entries that every Presentation-layer screen needs to be addressable through `UIHandler.show()` / `UIHandler.hide()`. The template-provided `UIHandler` is reused as-is; the work is purely registry population. Each consuming system (HUD, Relic Draft Modal, Main Menu, Pause Menu) brings its own layer module that self-registers via `UIHandler.registerLayer(id, type, self)` from inside its own `setup(parent)`, mirroring the canonical pattern in `src/ReplicatedStorage/Source/UI/UILayers/UIExampleHud.luau`.

Note: `Player Nameplate` and `Chest Billboard` are BillboardGui-attached components (per architecture.md §3.4 + ANATOMY §9), NOT UIHandler layers — they do not consume layer IDs and are out of scope for this epic.

### Story 002 — Closed Obsolete (2026-04-27)

Story 002 was authored against a callback-based `UIHandler.registerLayer(id, type, setupCB, teardownCB)` API plus `openLayer` / `closeLayer` methods. The shipped UIHandler API is structurally different: 3 args (`registerLayer(id, type, classInstance)` returning a `visibilityChangedSignal`), and show/hide is `show(id)` / `hide(id)`. Layer registration is layer-driven (each layer registers itself in its own `setup()` per `UIExampleHud.luau:53-59`), not centrally scaffolded. Boot-time stub registrations would be dead code replaced 1:1 by consumer Presentation epics. Story preserved for documentation; full rationale in story 002 §Closure Note. Foundation deliverable (UILayerId enum + UILayerTypeByLayerId) is fully covered by story 001.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Module Placement + Layer Boundary | UIHandler stays under `ReplicatedStorage/Source/UIHandler` (template-provided); UI layer IDs centralised in `SharedConstants/UILayerId.luau`; no magic strings | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| (none direct) | Layer ID registry is consumed by HUD, Relic Draft Modal, Main Menu, Pause Menu — TR-IDs land in those epics. | Indirect — covered by ADR-0006 |

⚠️ **Untraced by TR registry** — Foundation prereq. Stories cite ADR-0006 §Source Tree Map + ANATOMY §8 (UI system contract).

## Definition of Done

This epic is complete when:
- Story 001 implemented, reviewed, and closed via `/story-done` ✓ (2026-04-27)
- `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau` updated with entries: `HUD`, `RelicDraft`, `MainMenu`, `PauseMenu` ✓
- `UILayerType` mapping correct: `HUD` → `HeadsUpDisplay`; `RelicDraft` / `MainMenu` / `PauseMenu` → `Menu` ✓
- `UILayerTypeByLayerId.luau` mapping module created mirroring `UILayerIdByZoneId.luau` precedent ✓
- Per-layer `setup()` / `teardown()` for each ID is explicitly OUT OF SCOPE — handled in HUD epic, RelicDraft epic, etc. (each consumer Presentation epic self-registers per `UIExampleHud.luau` pattern)
- Logic story (enum integrity) has passing test file at `tests/unit/ui-handler/layer-id-enum.spec.luau` ✓
- ~~Boot-time central registration scaffold~~ — STORY 002 CLOSED OBSOLETE; see EPIC §Story 002 — Closed Obsolete

**Status**: Epic Complete (1/1 effective deliverable shipped 2026-04-27).

## Next Step

Foundation deliverable shipped. Consumer Presentation epics (HUD, RelicDraft, MainMenu, PauseMenu) own their own UIHandler.registerLayer calls per `UIExampleHud.luau` template pattern — no further work in this epic.
