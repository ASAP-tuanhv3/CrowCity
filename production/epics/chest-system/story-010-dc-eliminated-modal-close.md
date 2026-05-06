# Story 010: DC mid-DraftOpen + Eliminated draft modal close (S4-B1 fix)

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature + Presentation
> **Type**: Integration
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md` §AC-19 + AC-23
**Requirement**: covered by `TR-chest-013` + `TR-chest-020` (atomicity + grant silent-reject contract)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 + ADR-0001 (CrowdEliminated subscription)
**ADR Decision Summary**: When opener DC's mid-DraftOpen, the 8s timeout auto-pick still fires; `RelicEffectHandler.grant` silent-rejects on Eliminated crowd (per Relic §E). No toll refund (already deducted at claim per Story 006). When opener's crowd is Eliminated (signal `CrowdEliminated`), client subscribed to `CrowdStateClient.CrowdEliminated` closes draft modal within ≤67 ms; server still proceeds with auto-pick path.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `Players.PlayerRemoving` for DC; reliable `CrowdEliminated` event.

**Control Manifest Rules (Presentation):**
- Required: Client subscribes to `CrowdStateClient.CrowdEliminated` (read-only mirror)
- Forbidden: Client mutate `CrowdStateClient` (ADR-0004)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md` §AC-19 + AC-23:*

- [ ] **AC-19 (Player DC mid-DraftOpen — toll forfeit)**: chest DraftOpen + opener disconnects → 8s timeout fires + auto-pick calls `RelicEffectHandler.grant` → grant silent-rejects on DC'd Eliminated crowd; chest destroys + schedules respawn; no toll refund.
- [ ] **AC-23 (Draft modal close-on-opener-eliminated)**: client has open chest draft modal for opener crowdId B + subscribed to `CrowdStateClient.CrowdEliminated`; WHEN server fires `CrowdEliminated({crowdId = B.crowdId})`, THEN within one broadcast interval (≤67 ms): (a) draft modal closes client-side; (b) brief "opener eliminated" toast displays for 1.0 s; (c) further `ChestDraftPick` input on that modal not accepted. Server-side auto-pick (AC-14 / AC-19) still fires after 8 s; grant silent-rejects on Eliminated crowd. Toll already deducted; no refund.

---

## Implementation Notes

*Derived from GDD §AC-23 + ADR-0001 CrowdEliminated reliable:*

- Server side (no new code beyond Story 008 + 009 — auto-pick path already runs on timeout regardless of opener DC). Verify in test that grant is called (AC-19) and silent-rejects gracefully (Relic system handles).
- Server side DC handling: `Players.PlayerRemoving:Connect(function(player) ... end)` already in template (ANATOMY §3). On DC: opener's crowd transitions to Eliminated via MSM/RoundLifecycle DC freeze (separate epic story). ChestSystem doesn't actively close anything — DraftOpen chest sits until 8s timeout, then auto-picks.
- Client side (`ReplicatedStorage/Source/ChestDraftClient/init.luau`):
  - Holds reference to currently-open draft modal `_currentModal: { chestId, crowdId, candidates, modalGui } ?`.
  - Subscribe to `CrowdStateClient.CrowdEliminated` BindableEvent: handler:
    ```
    if _currentModal and _currentModal.crowdId == eliminatedCrowdId then
        _currentModal.modalGui:hide()
        showToast("Opener eliminated", 1.0)
        _currentModal = nil
        -- Disable any pending ChestDraftPick input
    end
    ```
  - Modal close path also in normal-pick flow (sends ChestDraftPick + dismisses on server confirmation).

---

## Out of Scope

*Handled by neighbouring stories or epics — do not implement here:*

- Story 008: ChestDraftOffer/Pick remotes; auto-pick timeout.
- Story 009: destroyAll auto-pick (different trigger).
- Relic system: grant silent-reject on Eliminated (separate epic story).
- MSM/RoundLifecycle DC freeze (separate epic).

---

## QA Test Cases

- **AC-19 (DC mid-DraftOpen)** [Integration — manual]:
  - Setup: 2-player Studio test; P1 opens chest (DraftOpen); P1 disconnects mid-modal
  - Verify: 8s server timer fires auto-pick; RelicEffectHandler.grant called on (now-Eliminated) crowd; grant silent-rejects (verified via spy or log); chest destroys; respawn schedules; no toll refund
  - Pass condition: documented in `production/qa/evidence/chest-dc-mid-draftopen-evidence.md`

- **AC-23 (Modal close-on-elim)** [Integration]:
  - Given: 2-client mock; client has draft modal open for crowdId="B"
  - When: server fires `CrowdEliminated({crowdId="B"})` reliable RemoteEvent
  - Then: within ≤67 ms client receives + closes modal; toast shown 1.0 s; subsequent input on dismissed modal silently dropped
  - Edge cases: modal already closed (server-confirmed pick fired first) — Eliminated event no-op; modal open for OTHER crowdId — Eliminated event no-op (mismatch).

- **No toll refund**:
  - Given: opener DC + 8s auto-pick + grant silent-reject
  - When: tick after destroyAll
  - Then: spy on csm.updateCount shows zero `+effectiveToll` calls (no refund)
  - Edge cases: Pool-exhausted refund path (Story 007) is different — that fires before DraftOpen even begins.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/chest/dc_eliminated_modal_close.spec.luau` — must exist and pass (AC-23 client-side)
- `production/qa/evidence/chest-dc-mid-draftopen-evidence.md` — manual playtest doc + sign-off (AC-19 DC sim)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 008 (draft remotes + timeout auto-pick); CrowdStateClient.CrowdEliminated signal (CRB epic story-002 or earlier); Relic system grant silent-reject contract.
- Unlocks: End-to-end DC scenarios in Vertical Slice playtest.
