# Story 006: Respawn fade-in (TweenService 1→0 over 0.3s)

> **Epic**: NPCSpawner (NPC Spawner)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/npc-spawner.md` §V/A + AC-18
**Requirement**: `TR-npc-spawner-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 NPC Spawner Authority §Visual Contract (fade-in owned here)
**ADR Decision Summary**: NPC respawn visual is a Transparency 1→0 tween over 0.3 s using TweenService. NPC is gameplay-active immediately on respawn (transparency does NOT gate Absorb tests) — fade is purely cosmetic.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: TweenService stable pre-cutoff.

**Control Manifest Rules (Feature layer)**:
- Required: Visual fade owned by NPCSpawner (ADR-0008)
- Forbidden: Use TweenService to gate gameplay logic — Absorb sees NPC immediately on respawn (ADR-0010 server-authoritative)

---

## Acceptance Criteria

*From GDD `design/gdd/npc-spawner.md` §V/A + AC-18:*

- [ ] **AC-18 (Respawn fade-in)**: respawned NPC `Part.Transparency` tweens 1 → 0 over 0.3 s linearly via TweenService. Visible on client mirror via UREvent transparency delta (Story 009 wires).
- [ ] **Gameplay-immediate**: NPC is `active=true` and present in `getAllActiveNPCs()` snapshot the same tick as `_doRespawn`; fade is cosmetic only, does not delay overlap eligibility.
- [ ] **Cleanup on destroy**: in-flight tween cancelled by `destroyAll` (Story 007).

---

## Implementation Notes

*Derived from ADR-0008 §Visual Contract:*

- At end of `_doRespawn` (Story 005): `local tween = TweenService:Create(npc.Part, TweenInfo.new(NPC_FADE_IN_DURATION, Enum.EasingStyle.Linear), {Transparency = 0}); tween:Play()`.
- Store `npc._fadeTween = tween` for cancellation by `destroyAll`.
- Constant: `NPC_FADE_IN_DURATION = 0.3`.
- DI: tween service injected via `deps.tweenService` (default `TweenService`) for test mocking.
- Order in `_doRespawn`:
  1. Set CFrame + active=true + push to active list (gameplay-live);
  2. Set `Part.Transparency = 1` (instant — kicks fade off from full transparent);
  3. Start fade tween 1→0;
  4. Invalidate snapshot cache.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: Respawn position selection + delay (this story plugs into the end).
- Story 007: destroyAll tween cancel (this story exposes `_fadeTween` for cancel).
- Story 009: UREvent transparency delta (this story sets local; replication delivers to clients).

---

## QA Test Cases

- **AC-18 (Fade transparency timeline)** [Logic — DI'd TweenService mock]:
  - Given: NPC respawns at t=0
  - When: 0.3 s elapse via injected scheduler
  - Then: TweenService:Create called once with `(npc.Part, TweenInfo.new(0.3, Linear), {Transparency=0})`; tween:Play() invoked once; at t=0.3 transparency==0
  - Edge cases: respawn during prior in-flight fade — cancel old, start new.

- **Gameplay-immediate**:
  - Given: NPC respawned at t=0 (with fade in-flight)
  - When: AbsorbSystem queries `getAllActiveNPCs()` at t=0.05 (mid-fade)
  - Then: NPC present in snapshot; eligible for absorb tests
  - Edge cases: absorb during fade — Absorbed signal fires normally; reclaim cancels fade tween.

- **Tween cancel on destroy** [Integration with Story 007]:
  - Given: respawn fade in-flight
  - When: `destroyAll()` runs
  - Then: `_fadeTween:Cancel()` called for each NPC
  - Edge cases: tween already complete — Cancel is safe no-op.

- **Visual evidence** [Visual/Feel — manual]:
  - Setup: open Studio with perf-fixture; spawn 8 NPCs visible to camera
  - Verify: each respawned NPC fades in smoothly over 0.3 s; no pop-in flash
  - Pass condition: video clip in `production/qa/evidence/npc-fade-in-evidence.md` shows smooth 1→0 fade.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- `tests/unit/npc-spawner/respawn_fade_in.spec.luau` — Logic part (AC-18 DI'd TweenService spy)
- `production/qa/evidence/npc-fade-in-evidence.md` — manual screenshot/video + lead sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005 (`_doRespawn` site).
- Unlocks: Story 007 (cancel handle), Story 009 (transparency delta replication).
