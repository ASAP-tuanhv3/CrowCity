# Story 001: MVP 6-key PlayerDataKey schema + DefaultPlayerData lock + Pillar 3 audit

> **Epic**: player-data-schema
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 3–4 hours (schema lock, audit, bidirectional consistency)

## Context

**GDD**: `design/gdd/game-concept.md` Pillar 3 (5-min clean rounds; no power persistence) + Pillar 4 (cosmetic-only meta) + anti-pillar L179 ("NOT pay-to-win")
**Requirement**: TR-game-concept-006 (no power progression carry-over), TR-game-concept-007 (cosmetic-only shop), TR-game-concept-008 (ProfileStore meta-only persistence)

**ADR Governing Implementation**: ADR-0011 — Persistence Schema + Pillar 3 Exclusions
**ADR Decision Summary**: MVP schema is exactly 6 keys (`Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`) plus `_schemaVersion` meta. Pillar 3 forbidden-keys catalog is explicit (round-scope state never persists). Pillar 4 anti-P2W: every persisted key is cosmetic, lifetime-statistic, or FTUE-progress only — no key may affect gameplay outcome.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: ProfileStore vendored at `src/ReplicatedStorage/Dependencies/ProfileStore.luau`; `BindToClose` 30 s grace handles in-flight saves on shutdown without data loss (per ADR-0011 §Verification D). No post-cutoff API surface in this story.

**Control Manifest Rules (Foundation layer)**:
- Required: All persistent writes via `PlayerDataServer` (ADR-0006)
- Required: Cross-module identifiers via `SharedConstants/PlayerDataKey.luau` enum (ADR-0006)
- Forbidden: Direct `DataStoreService` calls outside `Dependencies/ProfileStore.luau` (ADR-0006)
- Forbidden: Persisting per-round state — Pillar 3 (ADR-0011)
- Forbidden: Persisting Pillar-4-violating keys (gameplay-outcome modifiers) (ADR-0011)

---

## Acceptance Criteria

*Derived from ADR-0011 §MVP PlayerDataKey Schema (LOCKED — 6 keys + 1 meta) + §Pillar 3 Forbidden Keys (LOCKED — never persist):*

- [ ] AC-1: `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau` contains exactly these 6 keys for MVP scope: `Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`. (Template-provided `FtueStage` already present — verify; do not duplicate.)
- [ ] AC-2: `src/ServerStorage/Source/DefaultPlayerData.luau` returns a table with the same 6 keys plus `_schemaVersion = 1` meta. Defaults match ADR-0011 §MVP Schema table: `Coins = 0`, `OwnedSkins = {default = true}`, `SelectedSkin = "default"`, `LifetimeAbsorbs = 0`, `LifetimeWins = 0`, `FtueStage = FtueStage.Stage1` (or current template equivalent).
- [ ] AC-3: No keys from ADR-0011 §Pillar 3 Forbidden Keys catalog appear in either `PlayerDataKey.luau` or `DefaultPlayerData.luau` (verified by grep against the forbidden-class catalog: round-scope counts, round-scope radii, round-scope relics, round-scope crowd state, round-scope chest state, round-scope NPC state, round-scope match state, gameplay-outcome modifiers, draft-rarity weights, absorb bonus multipliers).
- [ ] AC-4: Each persisted key falls into exactly one of three Pillar 4 categories per ADR-0011: `cosmetic` (OwnedSkins, SelectedSkin), `lifetime-statistic` (LifetimeAbsorbs, LifetimeWins, Coins as soft-currency-stat), or `FTUE-progress` (FtueStage). Top-of-file comment in `PlayerDataKey.luau` documents the category for each entry.
- [ ] AC-5: `--!strict` type checks pass. Type export: `export type PlayerDataKeyValue = string` for consumer typing.
- [ ] AC-6: Default-template integrity: every key declared in `PlayerDataKey.luau` has a corresponding default value in `DefaultPlayerData.luau`, AND no key in `DefaultPlayerData.luau` is missing from `PlayerDataKey.luau` (bidirectional consistency).
- [ ] AC-7: VS+ keys (`DailyQuestState`, `LastDailyResetTime`) and Alpha+ keys (`AnalyticsOptIn`, `AccessibilitySettings`, `LastShopRefreshTime`) MUST NOT appear in MVP-scope schema. Add a top-of-file comment listing the deferred keys + their planned `_schemaVersion` bump path so future maintainers know.

---

## Implementation Notes

*Derived from ADR-0011 §Decision + §MVP PlayerDataKey Schema:*

- File paths are fixed:
  - Enum: `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau` (template-provided; extend in place)
  - Defaults: `src/ServerStorage/Source/DefaultPlayerData.luau` (template-provided; extend in place)
- The template ships with `FtueStage` already in `PlayerDataKey.luau`. Read existing file before editing — do not delete or rename existing keys; check whether `Coins` is already present (template includes a coins example in some variants). Add only the missing keys.
- `OwnedSkins` default value: ADR-0011 §MVP schema shows `{default = true}` (set-style table where keys are skin IDs). Use `{[skinId] = true}` shape — single source of truth for "skin-is-owned" check across Skin System (VS+).
- `_schemaVersion = 1` is the meta key. Keep it as a top-level field of the profile, not nested. ProfileStore reads `_schemaVersion` on load to dispatch migrations (story 002 wires the dispatcher).
- Pillar 3 forbidden-keys grep gate (AC-3) — implement as a one-shot test that loads `PlayerDataKey.luau` and asserts no key matches a forbidden-class regex pattern. Catalog the patterns from ADR-0011 §Pillar 3 Forbidden Keys table.
- Pillar 4 category comment (AC-4) — document right next to each enum entry, e.g.:
  ```luau
  PlayerDataKey.Coins = "Coins"            -- lifetime-statistic (soft currency)
  PlayerDataKey.OwnedSkins = "OwnedSkins"  -- cosmetic
  ```
- Currency grant timing (when `Coins` is mutated) is out of scope for this story — locked at MSM T6/T7/T8 by ADR-0005, implemented in MSM/RoundLifecycle Core epic.

---

## Out of Scope

- Story 002: Schema migration handler scaffold + `OnProfileVersionUpgrade` wiring
- Story 003: Persistence audit script
- Currency grant logic (consumer epic — MSM/RoundLifecycle)
- Skin System read path (consumer epic — Skin System, VS+)
- VS+ keys (`DailyQuestState`, `LastDailyResetTime`) — separate epic when Daily Quest System lands
- Alpha+ keys (`AnalyticsOptIn`, etc.) — separate epic when Settings + Analytics GDDs land

---

## QA Test Cases

- **AC-1**: enum exact-match
  - Given: clean tree post-implementation
  - When: load `PlayerDataKey` module + extract keys
  - Then: key set equals `{Coins, OwnedSkins, SelectedSkin, LifetimeAbsorbs, LifetimeWins, FtueStage}` exactly
  - Edge cases: extra key (e.g. accidental VS+ leak) → fail; missing key → fail with name

- **AC-2**: defaults integrity
  - Given: `DefaultPlayerData` loaded
  - When: introspect returned table
  - Then: 6 keys + `_schemaVersion = 1` present; values match ADR-0011 §MVP Schema table
  - Edge cases: `OwnedSkins` not a table → fail; `Coins` non-zero → fail (must default zero per anti-P2W); `_schemaVersion` not 1 → fail

- **AC-3**: forbidden-keys grep
  - Given: forbidden-class catalog from ADR-0011 §Pillar 3
  - When: scan `PlayerDataKey.luau` source for any forbidden-class pattern
  - Then: zero matches
  - Edge cases: case-insensitive match → fail; partial match (e.g. `RoundCoins`) → fail

- **AC-4**: category comments
  - Given: `PlayerDataKey.luau` source
  - When: scan for `-- cosmetic`, `-- lifetime-statistic`, `-- FTUE-progress` comments per entry
  - Then: each enum entry has exactly one category comment
  - Edge cases: missing comment → ADVISORY (manual review at `/story-done`); ambiguous category → fail

- **AC-5**: strict type-check
  - Standard `--!strict` Selene + Luau analyzer pass

- **AC-6**: bidirectional consistency
  - Given: both modules loaded
  - When: build key sets from each
  - Then: enum-key-set == defaults-key-set (excluding `_schemaVersion` which is meta-only, present in defaults but not in `PlayerDataKey`)
  - Edge cases: key in enum without default → fail; key in defaults without enum entry → fail

- **AC-7**: VS+ / Alpha+ exclusion
  - Given: enum source
  - When: grep for `DailyQuestState`, `LastDailyResetTime`, `AnalyticsOptIn`, `AccessibilitySettings`, `LastShopRefreshTime`
  - Then: zero matches in enum body (matches inside top-of-file comment block are permitted — that's the deferred-keys note)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-data/schema-lock_test.luau` — must exist and pass via TestEZ.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation; first story for this epic)
- Unlocks: Story 002 (migration dispatcher needs the schema lock to define `_schemaVersion = 1` baseline), Story 003 (audit script grep targets); Currency grant story (MSM Core epic); Skin System epic (VS+)
