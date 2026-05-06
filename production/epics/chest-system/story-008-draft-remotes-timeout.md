# Story 008: ChestDraftOffer/Pick remotes + 8s timeout auto-pick + grant + destroy

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 5h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-009`, `TR-chest-013`, `TR-chest-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 + ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: After Phase 4 deduction + draft roll (Stories 006-007), server fires `ChestDraftOffer` reliable RemoteEvent to claimer only with `(chestId, tier, candidates: [specId × 3])`; chest state → `DraftOpen`. Client picks via `ChestDraftPick` with chosen `specId`; server validates `specId ∈ candidates` and `player == _claimedBy`. Server then: `RelicEffectHandler.grant` → state → `Opened` → `ChestComponent:destroy()` → respawn timer (Story 011). Timeout `DRAFT_TIMEOUT_SEC = 8` auto-picks highest-rarity (ties by array index).

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: Reliable RemoteEvent + RemoteFunction (or RemoteEvent for pick — not query/response). Use RemoteEvent reliable per ADR-0010.

**Control Manifest Rules:**
- Required: All remotes via Network wrapper (ADR-0006)
- Required: Reliable RemoteEvent for must-arrive (ADR-0010)
- Required: 4-check guard on ChestDraftPick handler (ADR-0010)
- Required: Server `os.clock` for timer authority (ADR-0010)
- Forbidden: Trust client-asserted `payload.timestamp` (ADR-0010)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-12 (Draft UI delivery — single-client)**: chest → DraftOpen + ChestDraftOffer reliable RemoteEvent fired to claimer only with `{chestId, tier, candidates: [3 specIds]}`. Other clients see prompt disabled (handled by chest._state).
- [ ] **AC-13 (Pick → grant → destroy → respawn)**: claimer fires `ChestDraftPick` with valid specId within 8s → server validates `specId ∈ candidates` AND `player == _claimedBy` → in order: (a) `RelicEffectHandler.grant(crowdId, specId)`; (b) state → `Opened`; (c) `ChestComponent:destroy()`; (d) respawn timer scheduled per tier; (e) Part re-materializes + Available after timer (Story 011).
- [ ] **AC-14 (Auto-pick on timeout)**: 8s elapses without ChestDraftPick → server timeout fires; highest-rarity candidate auto-picked; ties by lowest array index. Grant + destroy + respawn schedule fire. No toll refund.
- [ ] **AC-22 (8-player simultaneous, advisory)**: 8 players trigger 8 different chests same frame → all 8 resolve via guards + claims + draft serially with no cross-chest interference.

---

## Implementation Notes

*Derived from GDD §C + §D state machine:*

- Add to `RemoteName/RemoteEventName.luau`: `ChestDraftOffer`, `ChestDraftPick`. (Story 006 added ChestPeelOff.)
- Post-Story-007 in Phase 4 callback (after successful roll):
  ```
  chest._state = "DraftOpen"
  chest._candidates = candidates
  chest._draftDeadline = os.clock() + DRAFT_TIMEOUT_SEC
  Network.fireClient(claimer, RemoteEventName.ChestDraftOffer, {
      chestId = chestId, tier = chest.tier, candidates = candidates
  })
  ```
- Per-tick (Phase 4 head): scan `_chests` for `_state == "DraftOpen"` AND `os.clock() > _draftDeadline` → auto-pick:
  ```
  local pick = pickHighestRarity(chest._candidates) -- ties by array index
  _completeDraft(chest, pick)
  ```
- ChestDraftPick handler (server, registered in `start.server.luau`):
  - 4-check guard: identity (engine player); state (chest._state == "DraftOpen" + player == _claimedBy); parameters (`typeof(payload.chestId) == "string"`, `typeof(payload.specId) == "string"`, `payload.specId ∈ chest._candidates`); rate.
  - On pass: `_completeDraft(chest, payload.specId)`.
- `_completeDraft(chest, specId)`:
  ```
  RelicEffectHandler.grant(chest._claimedBy.crowdId, specId)
  chest._state = "Opened"
  chest:destroy() -- removes prompt, billboard, sets state Cooldown via internal
  scheduleRespawn(chest, RESPAWN_SEC[chest.tier])  -- Story 011
  ```
- Constants: `DRAFT_TIMEOUT_SEC = 8`. `CHEST_RESPAWN_SEC_T1 = 30`, `_T2 = 60`, `_T3 = 120` (registry-locked).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Phase 4 deduction.
- Story 007: Draft roll.
- Story 010: DC mid-DraftOpen + draft modal close.
- Story 011: Respawn pipeline materialize tween.
- RelicEffectHandler.grant — Relic epic provides.

---

## QA Test Cases

- **AC-12 (Single-client routing)** [Integration]:
  - Given: 2 connected players; P1 claims chest
  - When: Phase 4 completes draft roll
  - Then: ChestDraftOffer FireClient spy shows 1 call to P1, payload `{chestId, tier, candidates}`; zero calls to P2; chest._state == "DraftOpen"
  - Edge cases: P1 already disconnected by Phase 4 — ChestDraftOffer skipped (FireClient on dead Player is silent error or no-op; verify).

- **AC-13 (Pick → grant → destroy → respawn)** [Integration]:
  - Given: chest DraftOpen; P1 fires ChestDraftPick({chestId, specId="TollBreaker"})
  - When: server handler runs
  - Then: ordered call spy shows: RelicEffectHandler.grant(crowdId, "TollBreaker"), chest._state="Opened", chest:destroy(), respawn timer scheduled with correct tier
  - Edge cases: invalid specId → guard 3 rejects; wrong player → guard 2 rejects; chestId mismatch → reject.

- **AC-14 (Timeout auto-pick)** [Integration]:
  - Given: chest DraftOpen; injected clock 8.1s elapse
  - When: Phase 4 head scan runs
  - Then: highest-rarity candidate picked; grant + destroy + respawn fire identically to AC-13
  - Edge cases: ties (3 same-rarity) → lowest array index (index 1).

- **AC-22 (8-player simul, advisory)** [Integration]:
  - Given: 8 chests + 8 players (one each); all trigger same frame
  - When: Phase 4 fires
  - Then: all 8 deduct + DraftOpen serially within ≤1ms
  - Edge cases: requires `run-in-roblox` headless runner — DOC as deferred until CI runner available; mark advisory.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/chest/draft_remotes_timeout.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-007; RelicEffectHandler.grant (Relic system epic).
- Unlocks: Stories 010, 011.
