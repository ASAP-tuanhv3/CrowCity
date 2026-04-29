# Epic: PlayerData Schema (ADR-0011)

> **Layer**: Foundation
> **GDD**: N/A — schema locked by ADR-0011 Persistence Schema + Pillar 3 Exclusions
> **Architecture Module**: PlayerDataServer + PlayerDataClient (architecture.md §3.1 rows 2–3)
> **Status**: Complete (2026-04-27 — 2/3 effective; story 002 closed obsolete)
> **Stories**: 2 effective deliverables shipped + 1 closed obsolete

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [MVP 7-key schema + DefaultPlayerData lock + Pillar 3 audit](story-001-mvp-schema-lock.md) | Logic | Complete | ADR-0011 (Amended 2026-04-27), ADR-0006 |
| 002 | [Schema migration handler scaffold + OnProfileVersionUpgrade wiring](story-002-migration-scaffold.md) | Logic | Obsolete (unimplemented) | ADR-0011 |
| 003 | [Persistence audit script (DataStoreService + forbidden-keys grep)](story-003-persistence-audit-script.md) | Config/Data | Complete | ADR-0011 §Verification (A)(B) |

Order: 001 → 003. Story 002 closed unimplemented — see Story 002 §Closure Note.

## Overview

This epic locks the MVP persistence schema per ADR-0011 (Amended 2026-04-27): a **7-key** data shape on top of the template-provided `ProfileStore` integration, plus a static-audit gate (DataStoreService confinement + Pillar 3 forbidden-keys grep) enforcing the schema at pre-commit time. Round state never touches the profile.

The MVP schema is `{Coins, OwnedSkins, SelectedSkin, LifetimeAbsorbs, LifetimeWins, FtueStage, Inventory}` + `_schemaVersion` meta. **Inventory** added per ADR-0011 Amendment 1 (2026-04-27) as the 7th key — categorised cosmetic, contents constrained to cosmetic ItemCategories only via `ContainerByCategory` registration. VS+ adds `DailyQuestState`/`LastDailyResetTime`; Alpha+ preliminary adds `AnalyticsOptIn`/`AccessibilitySettings`/`LastShopRefreshTime`. This epic ships the MVP keys only.

### Story 002 — Closed Obsolete (2026-04-27)

Story 002 (migration handler scaffold + `OnProfileVersionUpgrade` wiring) was authored against assumptions that didn't hold against the shipped template:
1. Template's `PlayerData/Server.luau:198` already calls `profile:Reconcile()` post-load — ProfileStore reconciliation handles default-fill for legacy profiles automatically (the v0 → v1 case story 002 was specified to verify).
2. Story 002 referenced `PlayerDataServer.loadProfileAsync` which does not exist; actual entry is `_onPlayerAddedAsync` (private).
3. MVP ships at `_schemaVersion = 1` with no schema bumps — building dispatcher infrastructure for a delta that does not occur in MVP is dead-code-on-arrival. The migration seam should land in the FIRST story that actually bumps `_schemaVersion` (VS+ Daily Quest System), with concrete v2 schema in hand.

Same architectural-redundancy reasoning that closed ui-handler-layer-reg story-002. Foundation deliverable preserved by story 001 (v1 baseline) + template's `Reconcile()`. Full rationale in story 002 §Closure Note.

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
- Story 001 implemented, reviewed, and closed via `/story-done` ✓ (2026-04-27)
- Story 003 implemented, reviewed, and closed via `/story-done` ✓ (2026-04-27)
- `src/ServerStorage/Source/DefaultPlayerData.luau` contains exactly **7 MVP keys** + `_schemaVersion = 1` meta (Amendment 1 — Inventory added; no Pillar-3 round-scope keys present) ✓
- `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau` updated with: `Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`, `Inventory` (template ships Coins / FtueStage / Inventory; story 001 added the 4 missing) ✓
- ~~`PlayerDataServer/MigrationHandlers/` directory exists~~ — STORY 002 CLOSED OBSOLETE; template's `profile:Reconcile()` covers v0 → v1 default-fill natively. Migration seam to land alongside FIRST real schema bump (VS+ Daily Quest epic).
- ~~`PlayerDataServer.OnProfileVersionUpgrade` wired~~ — same; deferred to first-bump story.
- Pillar 3 forbidden-keys grep gate green (no round-state keys present in schema or default template) ✓ (story 003 audit script + smoke evidence)
- Logic stories (schema validation) have passing test file at `tests/unit/player-data/schema-lock.spec.luau` ✓
- Config/Data story (audit script) has smoke evidence at `production/qa/evidence/persistence-audit-evidence.md` ✓

**Status**: Epic Complete (2/3 effective deliverables shipped 2026-04-27).

## Next Step

Foundation deliverable shipped. Next: network-layer-ext epic (Foundation, 5 stories, HIGH risk on story 001 — UnreliableRemoteEvent post-cutoff API).
