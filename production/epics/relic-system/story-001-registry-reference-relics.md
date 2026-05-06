# Story 001: RelicRegistry static load + 3 reference relic specs

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §C + §G Reference Relics
**Requirement**: `TR-relic-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006 Module Placement + ADR-0011 Persistence Schema (Pillar 3)
**ADR Decision Summary**: `RelicRegistry` static array loaded at module boot — typed specs `{specId, tier, rarity, hookSet, durationTicks, privateStateInit}`. MVP scope: 3 reference relics — TollBreaker (Common, non-state modifier), Surge (Rare, count mutation), Wingspan (Epic, radius multiplier). Registry forbidden from any persistence (Pillar 3).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs. Module-level frozen tables.

**Control Manifest Rules:**
- Required: Server module under `ServerStorage/Source/RelicSystem/init.luau` (ADR-0006)
- Required: Pillar 3 — no relic persistence (ADR-0011 — audit-persistence enforces)
- Required: All Luau files start with `--!strict` (ADR-0006)

---

## Acceptance Criteria

*From GDD `design/gdd/relic-system.md`, scoped to this story:*

- [ ] **Registry loads at boot**: `RelicRegistry` exposes `getAll() -> {RelicSpec}` and `getById(specId) -> RelicSpec?`. Returns frozen tables.
- [ ] **3 reference specs present**: TollBreaker (id="TollBreaker", tier=1, rarity=Common, multiplier=0.70 in privateStateInit), Surge (id="Surge", tier=2, rarity=Rare, countDelta=+40), Wingspan (id="Wingspan", tier=3, rarity=Epic, radiusMultiplier=1.35).
- [ ] **Hook set per spec**: each spec declares `hookSet = {onAcquire: bool, onExpire: bool, onTick: bool, onChestOpen: bool}`.
- [ ] **Pillar 3 audit-persistence pass**: `bash tools/audit-persistence.sh` returns exit 0 — no relic data class appears in `PlayerDataKey.luau` or `DefaultPlayerData.luau`.
- [ ] **Type export**: `RelicSpec` type exported for cross-module consumption.

---

## Implementation Notes

*Derived from GDD §G + ADR-0011 §Pillar 3:*

- Module: `src/ServerStorage/Source/RelicSystem/RelicRegistry.luau` (sibling of init.luau).
- Type definition:
  ```luau
  export type RelicSpec = {
      specId: string,
      tier: number,             -- 1, 2, 3
      rarity: string,           -- "Common", "Rare", "Epic"
      hookSet: { onAcquire: boolean, onExpire: boolean, onTick: boolean, onChestOpen: boolean },
      durationTicks: number?,   -- nil = round-permanent; integer = countdown
      privateStateInit: { [string]: any }?,  -- per-slot init state
  }
  ```
- TollBreaker spec:
  ```luau
  { specId = "TollBreaker", tier = 1, rarity = "Common",
    hookSet = { onAcquire = true, onExpire = true, onTick = false, onChestOpen = true },
    durationTicks = nil,
    privateStateInit = { multiplier = 0.70, modKey = "TollDiscount" } }
  ```
- Surge spec:
  ```luau
  { specId = "Surge", tier = 2, rarity = "Rare",
    hookSet = { onAcquire = true, onExpire = false, onTick = false, onChestOpen = false },
    durationTicks = nil,
    privateStateInit = { countDelta = 40 } }
  ```
- Wingspan spec:
  ```luau
  { specId = "Wingspan", tier = 3, rarity = "Epic",
    hookSet = { onAcquire = true, onExpire = true, onTick = false, onChestOpen = false },
    durationTicks = nil,
    privateStateInit = { radiusMultiplier = 1.35 } }
  ```
- Public API: `RelicRegistry.getAll(): {RelicSpec}` returns `table.freeze`'d list. `RelicRegistry.getById(specId: string): RelicSpec?` returns frozen spec or nil.
- Pillar 3 audit-persistence: existing `tools/audit-persistence.sh` covers `RelicState`, `RelicInventory`, etc. Verify spec class names not in PlayerDataKey enum.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: slot state machine + grant atomic.
- Story 003: hook dispatch.
- Stories 004-006: per-relic effect routing.

---

## QA Test Cases

- **Registry loads**:
  - Given: module require
  - When: `RelicRegistry.getAll()`
  - Then: returns frozen array length 3; all 3 specs match GDD declarations
  - Edge cases: re-require returns same instance (no double-load).

- **3 reference specs**:
  - Given: `RelicRegistry.getById("TollBreaker")`
  - When: inspected
  - Then: tier=1, rarity="Common", privateStateInit.multiplier=0.70
  - Edge cases: getById("Unknown") → nil; case-sensitive ids.

- **Hook set typed**:
  - Given: each spec
  - When: hookSet inspected
  - Then: 4 boolean fields present
  - Edge cases: fields default to false if not declared (defensive — but explicit declaration required by GDD).

- **Pillar 3 audit**:
  - Given: post-implementation
  - When: `bash tools/audit-persistence.sh`
  - Then: exit 0
  - Edge cases: introducing `RelicInventory` to PlayerDataKey → exit 1 (caught).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/relic/registry.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ADR-0011 audit-persistence script (Sprint 3 closed).
- Unlocks: All other Relic stories.
