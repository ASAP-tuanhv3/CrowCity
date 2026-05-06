# Story 007: F3 draft roll — distinct + re-roll + rarity fallback + pool-exhausted refund

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md` §F3
**Requirement**: `TR-chest-008`, `TR-chest-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: GDD-internal F3 + ADR-0001 (CrowdRelicChanged broadcast on grant)
**ADR Decision Summary**: F3 rolls 3 distinct candidate `specId` values from `RelicRegistry` filtered by tier + excluding held relics. Initial rarity pool from per-tier rarity table; re-roll up to 3× before stepping to lower rarity. Pool exhausted (all 3 slots resolve nil) → refund toll via `updateCount(+effectiveToll)` + chest → Cooldown.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Deterministic test seeds for RNG (DI'd random)
- Forbidden: Persistent rarity progression — rolls round-scoped (Pillar 3)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-11 (Draft roll: distinct + re-roll + fallback)**: 3 candidates with distinct `specId`; none equals held; initial rarity roll empty → re-roll up to 3× then step to next lower rarity; deterministic with seeded RNG.
- [ ] **AC-12 (Draft candidates exclude held + same-draft re-rolls)**: candidates exclude relics already in `crowd.activeRelics`; within a single draft, no specId appears twice.
- [ ] **AC-20 (Pool-exhausted refund path)**: GIVEN all relics eligible for tier already held by opening player (MVP 3-relic edge), WHEN draft produces 3 nil slots, THEN server refunds toll via `csm.updateCount(crowdId, +effectiveToll, "Chest")`, chest → `Cooldown`, log "pool exhausted refund". No grant, no destroy.

---

## Implementation Notes

*Derived from GDD §F3:*

- `RelicRegistry` (placeholder; full registry built in Relic system epic): static array of `{specId, tier, rarity}` records. MVP: 3 reference relics (TollBreaker rare, Surge common, Wingspan epic) — enough to test AC mechanics.
- `rollDraft(tier: number, held: {string}): {string}?` returns array of 3 specIds OR nil if pool exhausted:
  ```
  local function tryRollOne(rarity, exclude)
      local pool = filter(RelicRegistry, t -> t.tier == tier and t.rarity == rarity and not exclude[t.specId])
      if #pool == 0 then return nil end
      return pool[random(#pool)].specId
  end

  local results = {}
  local exclude = setOf(held)
  for slot = 1, 3 do
      local rarity = T_RARITY_PER_SLOT[tier][slot] -- per-tier rarity table
      local pick
      for retry = 1, 3 do
          pick = tryRollOne(rarity, exclude)
          if pick then break end
      end
      if not pick then
          -- Step to lower rarity
          for r = rarity-1, 1, -1 do
              pick = tryRollOne(r, exclude)
              if pick then break end
          end
      end
      if not pick then return nil end -- pool exhausted
      results[slot] = pick
      exclude[pick] = true -- prevent same-draft duplicate
  end
  return results
  ```
- Post-Phase 4 deduction (Story 006): `local candidates = rollDraft(tier, crowd.activeRelics)`. If nil → refund + Cooldown.
- Refund path: `csm.updateCount(crowdId, +effectiveToll, "Chest"); chest._state = "Cooldown"; log "pool exhausted refund"`. Schedule respawn (Story 011) immediately.
- Constants: `T1_RARITY_PER_SLOT = {Common, Common, Common}`, `T2_RARITY_PER_SLOT = {Common, Common, Rare}`, `T3_RARITY_PER_SLOT = {Rare, Rare, Epic}` — placeholder until Relic registry locks rarity table.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: Draft remotes + timeout + auto-pick + grant.
- Relic system epic: full RelicRegistry definition (this story uses interface only).

---

## QA Test Cases

- **AC-11 (Distinct + re-roll + fallback)**:
  - Given: registry with 5 T2 relics; held = {}; seeded RNG
  - When: rollDraft(2, {})
  - Then: 3 distinct specIds; none in held; deterministic given seed
  - Edge cases: re-roll path — synthetic registry with 1 relic at target rarity → re-rolls 3× → steps down rarity → picks lower rarity successfully.

- **AC-12 (Exclude held + same-draft uniqueness)**:
  - Given: held={"R1"}; registry has 4 T2 relics
  - When: rollDraft(2, held)
  - Then: 3 distinct candidates not including "R1"
  - Edge cases: held = full pool minus 3 → exactly 3 specific candidates; held = full pool minus 2 → can roll only 2 → pool exhausted → returns nil.

- **AC-20 (Pool exhausted refund)**:
  - Given: held = full T2 pool (3 relics in MVP minus none == all 3 held edge case)
  - When: rollDraft returns nil; Story 006 refund path triggered
  - Then: csm.updateCount(crowdId, +40, "Chest") fires; chest._state == "Cooldown"; log entry "pool exhausted refund"
  - Edge cases: held=4 relics (impossible — MAX=4 caps slot population, guard 3d should reject earlier) — defensive — still cleanly handles.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/draft_roll.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 006 (Phase 4 callback hosts roll); RelicRegistry stub (Relic system epic story-001 builds full).
- Unlocks: Story 008 (remotes consume rolled candidates).
