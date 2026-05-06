# Story 006: Atomic claim — Phase 4 toll deduction + state transition + ChestPeelOff

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-001`, `TR-chest-016`, `TR-chest-020`, `TR-chest-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 §Phase 4 + ADR-0004 CSM Authority
**ADR Decision Summary**: ChestSystem registers Phase 4 callback (after Collision/Relic/Absorb). Atomic claim sequence: `csm.updateCount(-effectiveToll, "Chest")` + chest state `Available → Claimed` happen in same Phase 4 callback (no yields, no inter-phase split). `ChestPeelOff` reliable RemoteEvent fires to opener-only client immediately after deduction.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Phase 4 ChestSystem (after CCR/Relic/Absorb) (ADR-0002)
- Required: `updateCount(crowdId, -effectiveToll, "Chest")` 4-caller rule (ADR-0004)
- Required: All remotes via Network wrapper (ADR-0006)
- Forbidden: Yield inside Phase 4 callback (ADR-0002)
- Forbidden: ChestSystem-side `if count > effectiveToll` clamp logic on deduction (CSM clamp F5 owns floor 1 — but guard 3f already rejected pre-deduction)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-7 (Toll deduction atomicity)**: T2 count=100, no relic mod, effectiveToll=40 → `csm.updateCount(crowdId, -40, "Chest")` + chest state `Available → Claimed` in same Phase 4 callback; no interleaving; count decreases by 40.
- [ ] **AC-7b (Scaled peak deduction)**: T2 count=300, no relic, effectiveToll=60 → `updateCount(-60, "Chest")` fires.
- [ ] **AC-10 (Peel-off opener-only)**: After successful deduction, `ChestPeelOff` reliable fires to opener client only with payload `{crowdId, chestId, followerCount: effectiveToll}`. No other client receives.
- [ ] **AC-20 (Invariant — no toll partial-spend)**: under no circumstance does `csm.updateCount(-X)` fire without a matching state transition `Available → Claimed`. Test: inject failure between steps and assert fire-then-fail rolls back? OR easier — assert atomicity by verifying both happen in same callback.
- [ ] **Phase 4 wiring**: callback registered exactly once at boot.

---

## Implementation Notes

*Derived from GDD §C Rules 1-2 + ADR-0002 §Phase 4:*

- Phase 4 wiring (in `start.server.luau`): `TickOrchestrator.registerPhase(4, ChestSystem.tickPhase4)`.
- Per-chest `_pendingClaim` populated by Story 003 frame-end winner. Phase 4 callback drains pending claims atomically:
  ```
  for chestId, claim in pairs(_pendingClaims) do
      local crowd = csm.get(claim.crowdId)
      local effectiveToll = queryChestToll(claim.crowdId, chest.tier, baseToll(chest.tier, crowd.count))
      -- Re-validate guards (state + count) since frame may have moved
      if crowd.state == "Active" and crowd.count > effectiveToll and chest._state == "Available" then
          csm.updateCount(claim.crowdId, -effectiveToll, "Chest")
          chest._state = "Claimed"
          chest._claimedBy = claim.player
          chest._effectiveToll = effectiveToll  -- store for downstream draft
          Network.fireClient(claim.player, RemoteEventName.ChestPeelOff, {
              crowdId = claim.crowdId,
              chestId = chestId,
              followerCount = effectiveToll
          })
      end
  end
  table.clear(_pendingClaims)
  ```
- Same callback continues to draft roll (Story 007) and sets state Claimed → DraftOpen after candidates resolve. (Or split: Phase 4 deducts, Story 008 promotes to DraftOpen on `ChestDraftOffer` send.) Pick: same Phase 4 — atomicity invariant requires deduction + state change + peel signal + draft offer all in one synchronous callback.
- AC-20 invariant: code-review checks deduction line and state-write line are both inside the SAME if-branch with no yields between.
- Add to `RemoteName/RemoteEventName.luau`: `ChestPeelOff = "ChestPeelOff"`, `ChestDraftOffer = "ChestDraftOffer"` (Story 008), `ChestDraftPick = "ChestDraftPick"` (Story 008).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 003 (winner pick), 004 (baseToll), 005 (queryChestToll) — consumed.
- Story 007: Draft roll.
- Story 008: Draft remotes + timeout + grant.
- Story 011: Respawn.

---

## QA Test Cases

- **AC-7 (Atomic deduction T2/100)**:
  - Given: chest T2 + crowd count=100, no modifier
  - When: Phase 4 fires with claim pending
  - Then: spy on csm.updateCount fires `(crowdId, -40, "Chest")`; chest._state == "Claimed"; ChestPeelOff fired to opener
  - Edge cases: count=41 → effectiveToll=40 → deduct → count=1 (allowed); count=40 → guard 3f rejected pre-Phase 4.

- **AC-7b (T2/300)**:
  - Given: count=300
  - When: Phase 4
  - Then: deduct -60, count=240
  - Edge cases: simultaneous claim on different chest by same player — both chests evaluated; both deduct sequentially; count tracking atomic.

- **AC-10 (PeelOff opener-only)** [Integration]:
  - Given: 2 connected players P1, P2; P1 claims chest
  - When: Phase 4 fires
  - Then: spy on FireClient shows exactly 1 call to P1; zero calls to P2
  - Edge cases: chest claimed by AFK player still routes to AFK player (not other players).

- **AC-20 (No partial spend)**:
  - Given: code source under `src/ServerStorage/Source/ChestSystem/`
  - When: grep for atomicity pattern
  - Then: deduction + state-write are not separated by `task.wait/defer/yield`
  - Edge cases: re-entrancy via ChestComponent — single chest cannot double-deduct (guard 3e checks state==Available).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/atomic_claim_phase4.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002, 003, 004, 005; TickOrchestrator (Sprint 3); CrowdStateServer.updateCount (Sprint 3).
- Unlocks: Story 007 (draft roll runs same Phase 4 post-deduction); Story 008 (draft remotes).
