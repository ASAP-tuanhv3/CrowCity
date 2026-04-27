# Epic: UIHandler Layer Registration

> **Layer**: Foundation
> **GDD**: N/A — UI layer prereq; per-layer setup() lives in consuming Presentation epics (HUD, RelicDraft, MainMenu, PauseMenu)
> **Architecture Module**: UIHandler (architecture.md §3.1 row 4)
> **Status**: Ready
> **Stories**: 2 created 2026-04-27 (see table below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [UILayerId enum + UILayerType mapping](story-001-ui-layer-id-enum.md) | Logic | Ready | ADR-0006 |
| 002 | [Boot-time layer registration scaffold (no-op setup stubs)](story-002-boot-registration-scaffold.md) | Integration | Ready | ADR-0006 + ANATOMY §8 |

Order: 001 → 002 (linear).

## Overview

This epic forward-declares the UILayerId enum entries that every Presentation-layer screen needs to be addressable through `UIHandler.openLayer()` / `closeLayer()`. The template-provided `UIHandler` is reused as-is; the work is purely registry population + boot-time wiring in the client entry point. Each consuming system (HUD, Relic Draft Modal, Main Menu, Pause Menu) brings its own `setup()` + `teardown()` in its own Presentation epic.

Note: `Player Nameplate` and `Chest Billboard` are BillboardGui-attached components (per architecture.md §3.4 + ANATOMY §9), NOT UIHandler layers — they do not consume layer IDs and are out of scope for this epic.

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
- All stories are implemented, reviewed, and closed via `/story-done`
- `src/ReplicatedStorage/Source/SharedConstants/UILayerId.luau` updated with entries: `HUD`, `RelicDraft`, `MainMenu`, `PauseMenu`
- `UILayerType` mapping correct: `HUD` → `HeadsUpDisplay`; `RelicDraft` / `MainMenu` / `PauseMenu` → `Menu` (modal, hides HUD)
- Client entry point (`src/ReplicatedFirst/Source/start.server.luau`) registers each layer ID via `UIHandler.registerLayer()` AFTER consuming epics' setup() functions exist (or with no-op stubs documented per ID)
- Per-layer `setup()` / `teardown()` for each ID is explicitly OUT OF SCOPE — handled in HUD epic, RelicDraft epic, etc.
- All Logic stories (enum integrity + boot-time registration order) have passing test files in `tests/unit/ui-handler/`
- UI story (manual smoke-check that no two layer IDs collide; closeLayer reverts to prior layer) has evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories ui-handler-layer-reg` to break this epic into implementable stories.
