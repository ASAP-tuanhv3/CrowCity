# Epic: PlayerData Schema (ADR-0011)

> **Layer**: Foundation
> **GDD**: N/A — schema locked by ADR-0011 Persistence Schema + Pillar 3 Exclusions
> **Architecture Module**: PlayerDataServer + PlayerDataClient (architecture.md §3.1 rows 2–3)
> **Status**: Ready
> **Stories**: 3 created 2026-04-27 (see table below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [MVP 6-key schema + DefaultPlayerData lock + Pillar 3 audit](story-001-mvp-schema-lock.md) | Logic | Ready | ADR-0011, ADR-0006 |
| 002 | [Schema migration handler scaffold + OnProfileVersionUpgrade wiring](story-002-migration-scaffold.md) | Logic | Ready | ADR-0011 |
| 003 | [Persistence audit script (DataStoreService + forbidden-keys grep)](story-003-persistence-audit-script.md) | Config/Data | Ready | ADR-0011 §Verification (A)(B) |

Order: 001 → 002 → 003 (linear).

## Overview

This epic locks the MVP persistence schema per ADR-0011: a 6-key data shape on top of the template-provided `ProfileStore` integration, plus the schema-migration scaffolding (`OnProfileVersionUpgrade` + handler dir + test fixture) that lets future schema changes ship without data loss. It also enforces the Pillar 3 round-scope exclusion catalog (10-class forbidden-keys list) at the schema-default level — round state never touches the profile.

The MVP schema is `{Coins, OwnedSkins, SelectedSkin, LifetimeAbsorbs, LifetimeWins, FtueStage}` + `_schemaVersion` meta. VS+ adds `DailyQuestState`/`LastDailyResetTime`; Alpha+ preliminary adds `AnalyticsOptIn`/`AccessibilitySettings`/`LastShopRefreshTime`. This epic ships the MVP keys only — VS+ keys are deferred to their own epics in their own milestones.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: Persistence Schema + Pillar 3 Exclusions | 6-key MVP schema locked; Pillar 4 anti-P2W 3-category boundary (cosmetic / lifetime-stat / onboarding); ProfileStore-only rule reinforces ADR-0006; schema migration via `OnProfileVersionUpgrade` + `MigrationHandlers/` dir + test fixture; default template sole ownership; Coins server-only grant at MSM Result entry; Robux via ReceiptProcessor template | LOW |
| ADR-0006: Module Placement + Layer Boundary | All persistent writes via `PlayerDataServer`; client never writes; no direct `DataStoreService` calls | LOW |
| ADR-0005: MSM/RoundLifecycle Split | Currency grant timing locked at T6/T7/T8 (Result entry); BindToClose 30 s no-grant policy | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-game-concept-006 | No power progression carry-over between rounds (Pillar 3 anti-pillar) | ADR-0011 ✅ |
| TR-game-concept-007 | Cosmetic-only shop; skins apply to player AND whole crowd | ADR-0011 ✅ |
| TR-game-concept-008 | Roblox client-server with ProfileStore persistence (meta only) | ADR-0011 ✅ |

⚠️ **TR registry has no `player-data` system entries** — schema requirements are traced via ADR-0011 §Decision and game-concept TRs. Stories cite ADR-0011 directly + game-concept TR-IDs above.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- `src/ServerStorage/Source/DefaultPlayerData.luau` contains exactly 6 MVP keys + `_schemaVersion` meta (no Pillar-3 round-scope keys present)
- `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau` updated with: `Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage` (template `FtueStage` already present — verify)
- `PlayerDataServer/MigrationHandlers/` directory exists with `init.luau` + at least one no-op v0→v1 stub handler + matching test fixture
- `PlayerDataServer.OnProfileVersionUpgrade` wired in profile-load path
- Pillar 3 forbidden-keys grep gate green (no round-state keys present in schema or default template)
- All Logic stories (schema validation, migration round-trip, default-template integrity) have passing test files in `tests/unit/player-data/`
- Integration story (multi-session write/read + version upgrade) has evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories player-data-schema` to break this epic into implementable stories.
