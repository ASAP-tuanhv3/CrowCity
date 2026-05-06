# Story 011: Respawn pipeline + Part materialize tween + Toll billboard

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature + Presentation
> **Type**: Visual/Feel
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-014`, `TR-chest-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: GDD §C Rule 9 + ADR-0003 (9-cap ProximityPrompt budget)
**ADR Decision Summary**: After grant + destroy (Story 008), respawn scheduled per-tier: T1=30s, T2=60s, T3=120s. Part re-materializes via opacity TweenService 1→0 over 0.5s + ChestComponent re-attaches → state Available. Toll billboard (BillboardGui above chest) shows `effectiveToll` (post-queryChestToll), not baseToll — updates on relic modifier changes.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: TweenService stable; BillboardGui stable.

**Control Manifest Rules (Feature + Presentation):**
- Required: Per-tier respawn constants (CHEST_RESPAWN_SEC_T1/T2/T3)
- Required: Toll billboard updates on `setRelicModifier`/`clearRelicModifier`/`CountChanged` events (consumer side — billboard reads queryChestToll)
- Guardrail: ≤21 BillboardGui (12 Nameplate + 9 Chest billboards) (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-13(d-e) (Respawn schedule + materialize)**: After grant + destroy, respawn timer scheduled per tier; Part re-materializes via Transparency 1→0 tween over 0.5s; ChestComponent re-attached; state → Available.
- [ ] **AC-18 (Toll billboard shows effective)**: BillboardGui above chest shows `queryChestToll(crowdId, tier, baseToll(tier, crowd.count))` in real-time; updates on relic modifier register/clear and on count changes (subscribes via `CountChanged` server-side BindableEvent through CrowdStateClient cache for client display).
- [ ] **9-billboard cap respected**: ≤9 simultaneous Chest BillboardGui across the round (6 T1 + 3 T2).

---

## Implementation Notes

*Derived from GDD §C Rule 9 + §UI Requirements:*

- `ChestSystem._scheduleRespawn(chest)`:
  ```
  local respawnSec = CHEST_RESPAWN_SEC_BY_TIER[chest.tier]
  chest._respawnTimer = task.delay(respawnSec, function()
      -- Re-materialize Part
      chest.instance.Transparency = 1
      chest.instance.CanCollide = true
      local tween = TweenService:Create(chest.instance, TweenInfo.new(0.5, Linear), {Transparency = 0})
      tween:Play()
      chest._fadeTween = tween
      -- Re-attach component
      ChestComponent.attach(chest.instance, chest.tier, _sysContext)
      chest._state = "Available"
  end)
  ```
- Toll billboard (per-chest `BillboardGui`): contains `TextLabel` showing `tostring(currentEffectiveToll)`. Update triggers:
  - On chest creation (Story 001): bind initial value.
  - Subscribe to `CountChanged` BindableEvent through CrowdStateClient (presentation-layer read-only): on each crowd-count change for any active crowd within prompt radius, recompute and update billboard text. Cheaper alternative: poll on `RunService.Heartbeat` at 5 Hz client-side (per-chest update — 9 chests × 5 Hz = 45 ops/s, negligible).
  - Subscribe to `setRelicModifier`/`clearRelicModifier` server-side: server updates a server-side authoritative `_billboardEffectiveToll` per chest then broadcasts to clients via reliable RemoteEvent (or use `Attribute` change which auto-replicates). MVP simplest: chest billboard shows tier flat baseToll only; relic discount visualized via PlayerNameplate or HUD relic icon (not on chest billboard). Defer relic-aware billboard to VS+.
  - **MVP scope**: billboard shows `baseToll(tier, crowd.count)` for the prompting player's crowd (when they're close enough — within prompt distance 20 studs). Relic discount visualized via "TollBreaker" relic icon on HUD. This story implements baseToll-only billboard; relic-aware billboard deferred to VS+ as documented in GDD.
- BillboardGui created from prefab in `ReplicatedStorage/Instances/GuiPrefabs/ChestBillboard.gui` (Level Design + UI handoff).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 008 + 009: grant + destroy + destroyAll (this story plugs into post-destroy respawn).
- Story 010: DC modal close.
- Relic-aware billboard discount visualization — deferred to VS+ scope.

---

## QA Test Cases

- **AC-13(d-e) (Respawn schedule + materialize)** [Visual/Feel — Logic part automated]:
  - Given: chest just destroyed via Story 008 grant flow
  - When: respawn timer fires (T1=30s injected clock)
  - Then: Part Transparency starts at 1; tween 1→0 over 0.5s; ChestComponent re-attached; state == "Available"
  - Edge cases: destroyAll during respawn timer → cancel + don't re-attach.

- **AC-18 (Toll billboard shows effective)** [Logic — MVP scope]:
  - Given: chest BillboardGui rendered; crowd count=200, T2 baseToll=40
  - When: count changes to 300 (count change broadcast)
  - Then: billboard text updates to "60" (scaled toll)
  - Edge cases: count changes to 1 → "40" (FLOOR); player not in own crowd radius → billboard hidden (visibility owned by UI epic).

- **9-billboard cap** [Visual/Feel — manual]:
  - Setup: spawn 6 T1 + 3 T2 chests (max MVP); count BillboardGui instances
  - Verify: count == 9
  - Pass condition: instance count documented in `production/qa/evidence/chest-billboard-instance-cap-evidence.md`.

- **Materialize visual** [Visual/Feel — manual]:
  - Setup: T1 chest just destroyed; wait 30s
  - Verify: Part fades in 1→0 over ~0.5s; ChestComponent state == Available; ProximityPrompt active
  - Pass condition: video clip in evidence doc.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- `tests/unit/chest/respawn_materialize.spec.luau` — must exist and pass (AC-13 Logic part)
- `production/qa/evidence/chest-respawn-materialize-evidence.md` — manual screenshot/video + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 008 (destroy schedules respawn); ChestBillboard prefab (Level Design / UI handoff).
- Unlocks: End-to-end chest loop in Vertical Slice playtest.
