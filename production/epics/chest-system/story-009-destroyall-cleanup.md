# Story 009: destroyAll cleanup — DraftOpen auto-pick first + state cleanup

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-015`, `TR-chest-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 MSM/RoundLifecycle Split + ADR-0002 §Phase 9
**ADR Decision Summary**: `RoundLifecycle.destroyAll()` (T9) calls `ChestSystem.destroyAll()`. Per GDD: chests in DraftOpen state auto-pick FIRST (grant fires, CrowdRelicChanged broadcasts) before any chest destroys. All chests → Dormant. All respawn timers cancelled. All prompts + billboards removed. `_crowdModifiers` flushed.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: T9 ordering invariant — RoundLifecycle.destroyAll → RelicSystem.clearAll → broadcast (ADR-0005)
- Required: ChestSystem.destroyAll auto-picks DraftOpen first (GDD)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-15 (destroyAll during DraftOpen — auto-pick first)**: ≥1 chest DraftOpen → destroyAll triggers auto-pick (highest-rarity, ties by index) for each DraftOpen chest BEFORE any component destroys. Grant fires; CrowdRelicChanged broadcasts; THEN all chests transition to Dormant; `_crowdModifiers` cleared.
- [ ] **AC-16 (destroyAll across all states)**: chests in Available, Cooldown, Respawning when destroyAll → all → Dormant; respawn timers cancelled; prompts + billboards removed; no relic side-effects for non-DraftOpen chests.
- [ ] **Idempotent**: destroyAll called twice — no error; second call no-op.

---

## Implementation Notes

*Derived from GDD §C Rule 10 + ADR-0005 §T9:*

- `ChestSystem.destroyAll()` body:
  ```
  if self._destroyed then return end
  -- Phase 1: drain DraftOpen chests via auto-pick (BEFORE any destroy)
  for chestId, chest in pairs(_chests) do
      if chest._state == "DraftOpen" then
          local pick = pickHighestRarity(chest._candidates) -- ties: lowest index
          RelicEffectHandler.grant(chest._claimedBy.crowdId, pick)
          chest._state = "Opened"
          -- grant fires CrowdRelicChanged through normal Relic flow
      end
  end
  -- Phase 2: destroy all chest components
  for chestId, chest in pairs(_chests) do
      if chest._respawnTimer then task.cancel(chest._respawnTimer) end
      chest:destroy() -- removes prompt + billboard
      chest._state = "Dormant"
  end
  table.clear(_chests)
  table.clear(_crowdModifiers)
  self._destroyed = true
  ```
- Idempotency: top-level guard.
- Order matters: grant before destroy — grant calls into RelicEffectHandler which may write to CSM (`updateCount("Relic")`, `recomputeRadius`); CSM still alive at destroyAll start (RoundLifecycle's T9 chain destroys CSM AFTER RelicSystem.clearAll per ADR-0005 ordering).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: draft-modal close-on-DC (different concern, post-DC modal close on client).
- Story 011: respawn timers (cancel handles).

---

## QA Test Cases

- **AC-15 (Auto-pick first)** [Integration]:
  - Given: 2 chests DraftOpen, 1 chest Available, 1 chest Respawning
  - When: destroyAll
  - Then: ordered spy shows 2 grants fire BEFORE any chest:destroy(); CrowdRelicChanged broadcasts × 2; then 4 chest:destroy() calls; then `_chests` empty + `_crowdModifiers` empty
  - Edge cases: claimer DC'd at destroyAll time → grant silent-rejects (Relic §E); chest still destroyed.

- **AC-16 (All states cleanup)**:
  - Given: 4 chests in {Available, Cooldown, Respawning, DraftOpen}
  - When: destroyAll
  - Then: all → Dormant; `task.cancel` spy shows 1 cancel for Respawning chest's timer; prompts/billboards count == 0 post-destroy
  - Edge cases: Respawning + cancel during fade tween → tween cancelled also (Story 011).

- **Idempotent**:
  - Given: destroyAll called once
  - When: called again
  - Then: no error; no double-destroy
  - Edge cases: re-createAll after destroyAll → resets `_destroyed = false`.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/destroyall_cleanup.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001 (component), 008 (DraftOpen), 011 (respawn timer cancel hook); RelicEffectHandler.grant.
- Unlocks: T9 round lifecycle integration.
