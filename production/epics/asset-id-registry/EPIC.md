# Epic: AssetId Registry

> **Layer**: Foundation
> **GDD**: N/A — locked by `design/art/art-bible.md` §8.8–8.9 (convention-only, no mechanics)
> **Architecture Module**: AssetId (architecture.md §3.1 row 9)
> **Status**: Complete (2026-04-27)
> **Stories**: 4/4 Complete

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [AssetId module skeleton + Skin category](story-001-asset-id-skeleton.md) | Logic | Complete | ADR-0006 |
| 002 | [Populate Mesh inventory (Char/Prop/Env)](story-002-mesh-inventory.md) | Logic | Complete | ADR-0006 |
| 003 | [Populate Particle + Sound inventory + retire Sounds.luau](story-003-particle-sound-inventory.md) | Logic | Complete | ADR-0006 |
| 004 | [Asset ID static-audit gate (grep script)](story-004-asset-id-audit-gate.md) | Config/Data | Complete | ADR-0006 §Verification (A) |

Order: 001 → 002 → 003 → 004. Stories 002–003 may run in parallel after 001 lands; 004 last (consumer of 001+002+003).

## Overview

The AssetId Registry is a shared SharedConstants enum module that maps logical asset names (skin, particle, mesh, sound) to Roblox `rbxassetid://` strings. It is the gating module for every model, texture, particle, and sound reference across all gameplay and presentation systems — once locked, no system references a raw asset id by string. Lives under `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau`.

Per art bible §8.9, the registry is convention-only — no mechanical decisions to design. All asset slots are pre-enumerated by art-bible inventory; this epic creates the enum module and populates it with MVP-scope asset references.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Module Placement Rules + Layer Boundary Enforcement | Locks `SharedConstants/` placement class; no magic strings cross-module | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| (none) | Convention-only — no GDD requirements registered. Asset slot inventory is owned by `design/art/art-bible.md` §8.8–8.9. | N/A |

⚠️ **Untraced by TR registry** — Foundation infrastructure work, traced by ADR-0006 + art bible §8.8–8.9. Stories cite art-bible section + ADR-0006 §Source Tree Map directly.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` exists with `--!strict` header
- Enum categories present: `Skin`, `Particle`, `Mesh`, `Sound` (per art bible §8.9 inventory)
- All MVP-scope asset slots populated with placeholder or real `rbxassetid://` strings
- No raw asset id string literals remain in `src/` outside this module (Selene rule or grep gate)
- All Logic stories have passing test files in `tests/unit/asset-id/`
- Visual/Feel stories (asset preview verification) have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories asset-id-registry` to break this epic into implementable stories.
