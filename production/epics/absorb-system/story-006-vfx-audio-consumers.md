# Story 006: V/A consumers — VFX AbsorbSnap + audio batching + streak escalation

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Ready
> **Layer**: Presentation (consumer side, server signals only)
> **Type**: Visual/Feel
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md` §V/A Requirements + AC-14/15/16
**Requirement**: AC-14 / AC-15 / AC-16 (V/A subset of GDD; not separate TRs).
*(Requirement text lives in GDD §V/A; track via story id only.)*

**ADR Governing Implementation**: ADR-0004 CSM Authority (cosmetic systems read-only) + VFX GDD §C
**ADR Decision Summary**: VFX + Audio modules are PRESENTATION-layer cosmetic consumers — they MUST NOT mutate any CSM field. They subscribe to the in-process `Absorbed` BindableEvent server-side OR `RemoteEventName.Absorbed` client-side and play `VFXEffect.AbsorbSnap` + `sfx_absorb_snap` per overlap, with audio batching and streak escalation logic local to AudioManager.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: ParticleEmitter pool sized per ADR-0003 (≤24 emitters, ≤2000 active particles). Sound playback via SoundService.

**Control Manifest Rules (Presentation layer)**:
- Required: VFXManager single API `playEffect(effectId, context)` — all callers funnel through it (VFX GDD)
- Required: Cosmetic systems are read-only consumers of CSM (ADR-0004 — Pillar 4)
- Forbidden: VFX/Audio mutate any CSM field (ADR-0004)
- Forbidden: VFX/Audio subscribe `CountChanged` BindableEvent for gameplay decisions (ADR-0004 — display-only via CrowdStateClient is fine)
- Guardrail: VFX pool ≤24 ParticleEmitters in flight; ≤2000 active particles soft cap (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md` §V/A + ACs 14-16:*

- [ ] **AC-14 (V/A signal consumers)**: 1 NPC absorbed → `VFXEffect.AbsorbSnap` invoked once at NPC position; `sfx_absorb_snap` plays once.
- [ ] **AC-15 (Audio batching)**: 4 NPCs absorbed within same 66ms tick → exactly 1 sound plays (NOT 4); pitch +0.15 above baseline; volume +20% above baseline.
- [ ] **AC-16 (Streak escalation)**: 10 Absorbed events within 3-second window (injected clock) → 10th event audio pitch +0.3 above baseline; crowd nameplate scale tween reaches 1.4 peak.
- [ ] **VFX 6/frame cap**: AbsorbSnap respects `ABSORB_PER_FRAME_CAP = 6` per VFX GDD (suppression — extra absorbs that frame play sound but skip particles).

---

## Implementation Notes

*Derived from absorb-system.md §V/A + VFX GDD §F2 suppression tier:*

- VFX subscriber: `VFXManager` listens on the server-side intra-process `Absorbed` BindableEvent (or for client-side latency-zero, the `RemoteEventName.Absorbed` client mirror). On fire: `VFXManager.playEffect(VFXEffectId.AbsorbSnap, {position = npcLastPosition, crowdId = crowdId})`.
- AbsorbSnap respects per-frame cap = 6 per VFX GDD §F2; overflow tracked in counter, drops particles silently (sound still plays).
- AudioManager subscriber maintains per-tick batch list `{[crowdId] = {count, lastPos}}`; at end-of-tick (or per-tick `task.defer` flush), plays at most 1 sound per crowd, pitched/volumed by `count`:
  - 1 absorb baseline; 2-4 → pitch +0.15, vol +20%; 5+ → pitch +0.20, vol +30%.
- Streak escalation: AudioManager keeps per-crowd ring buffer `{ts ≤ clock() - 3.0 evicted}`. On Absorbed: append; if `#buffer >= 10` within 3 s window, escalate active sound to pitch +0.3 + trigger nameplate tween.
- Nameplate tween: PlayerNameplate consumes `StreakEscalation` BindableEvent emitted by AudioManager. PlayerNameplate already has tween infra (Sprint 4 backlog or earlier) — this story emits the signal only; nameplate visual tween implementation is owned by PlayerNameplate epic.
- `AudioManager` MUST NOT read CSM state — `count` is taken from Absorbed payload's batch counter, not from CSM.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Story 005: Absorbed RemoteEvent registration (this story consumes it).
- VFX pool internals + ParticleEmitter pre-allocation — owned by VFXManager (separate epic).
- Nameplate scale tween implementation — owned by PlayerNameplate epic; this story emits the trigger signal only.
- Story 007: perf soak.

---

## QA Test Cases

*Visual/Feel + Logic mix — automate audio-batching + streak math (Logic-tier mocks); manual evidence for VFX snap visual.*

- **AC-14 (Single absorb V/A)** [Logic — mock VFXManager + SoundService]:
  - Given: 1 NPC absorbed
  - When: tick fires Absorbed
  - Then: `VFXManager.playEffect` spy has 1 call with `AbsorbSnap` + position; SoundService spy has 1 sound play
  - Edge cases: zero listeners on BindableEvent → no error; subsequent identical fires play independently.

- **AC-15 (Audio batching)** [Logic — injected clock + spy]:
  - Given: 4 Absorbed within 66 ms (clock injected)
  - When: tick flushes
  - Then: SoundService.PlayLocalSound spy fires exactly 1; sound has pitch baseline+0.15 + vol baseline+0.20
  - Edge cases: 1 absorb still plays; 5+ → pitch +0.20 vol +0.30; tick boundary — 4 in tick A + 1 in tick B → 2 plays.

- **AC-16 (Streak escalation)** [Logic — injected clock]:
  - Given: 10 Absorbed within 3 s for crowd "alpha"
  - When: 10th fires
  - Then: pitch escalates +0.3; `StreakEscalation:Fire("alpha")` emits exactly once (not on each subsequent absorb)
  - Edge cases: 9 in 2.999 s + 10th at 3.001 s — 9 evicted, no escalation; reset after 3 s of silence.

- **AC AbsorbSnap visual** [Visual/Feel — manual]:
  - Setup: spawn perf-fixture + load 1 crowd of 50 followers; spawn 8 NPCs in radius
  - Verify: AbsorbSnap particles visible per absorb; capped at 6 simultaneous (no overload)
  - Pass condition: video clip in `production/qa/evidence/absorb-vfx-evidence.md` shows 8 NPCs absorbed in same tick, 6 particle bursts visible plus 2 silent-but-counted.

---

## Test Evidence

**Story Type**: Visual/Feel (with Logic-tier audio batch tests)
**Required evidence**:
- `tests/unit/absorb/audio_batching_streak.spec.luau` — must exist and pass (AC-15, AC-16 Logic part)
- `production/qa/evidence/absorb-vfx-evidence.md` — manual screenshot/video + lead sign-off (AC-14 visual + AC-16 nameplate tween hookup verification)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005 (Absorbed signal exists), VFXManager `playEffect` API (separate epic — assume present), AudioManager registered SFX bank.
- Unlocks: Story 007 (perf soak — V/A overhead must be in measured envelope).
