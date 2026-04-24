# Change Impact Report — MSM Same-Tick Handler Order (Batch 4 Close)

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/match-state-machine.md`
**Trigger:** `/propagate-design-change design/gdd/match-state-machine.md` — RC-B-NEW-4 closure per `/review-all-gdds` 2026-04-24.
**Related docs:** `change-impact-2026-04-24-csm-batch1.md`, `change-impact-2026-04-24-chest-batch4.md`, prior Batch 2/3 change-impact docs

---

## 1. Change Summary

### Blocker resolved

| ID | Issue | Resolution |
|---|---|---|
| RC-B-NEW-4 | MSM timer-expiry vs CSM elimination same-tick handler order — no GDD specifies whether MSM's timer handler or CCR's `CrowdEliminated` fires first inside one Heartbeat callback | Explicit 9-phase TickOrchestrator table added to MSM §Core Rules. Phase 6 (MSM timer check) runs BEFORE Phase 7 (MSM elim consumer). T6/T7 simultaneity resolves deterministically: T7 wins, Phase 7 double-signal guard drops queued elim. |

### Edits applied (4 total)

| # | Site | Change |
|---|---|---|
| 1 | L3 Status header | 2026-04-24 Batch 4 closure note: 9-phase handler order locked |
| 2 | New §Core Rules block (after Write-access contract ~L60) | "Same-tick handler order (TickOrchestrator phase table)" — 9 phases with sources, rationale, simultaneity resolution, caller enforcement |
| 3 | L223 Edge case (T6/T7 simultaneity) | Conceptual "timer-expiry evaluates FIRST" → explicit Phase 6 / Phase 7 reference |
| 4 | New AC-21 | Phase-order integration test; deterministic tick stepper; verifies T7 wins, elim signal dropped, single broadcast |

### 9-Phase TickOrchestrator order (authoritative)

| Phase | System | Action |
|---|---|---|
| 1 | CollisionResolver | Drip `updateCount(±delta, "Collision")` per overlapping pair |
| 2 | RelicEffectHandler | `onTick` hooks |
| 3 | AbsorbSystem | Overlap detection + `updateCount(+1, "Absorb")` |
| 4 | ChestSystem | Process queued proximity triggers; guard pipeline |
| 5 | CSM state evaluation | Grace timer check (F7); fire state transitions; dispatch `CrowdEliminated` |
| 6 | **MSM timer check** | T7 if `elapsed >= 300s` — **fires BEFORE Phase 7** |
| 7 | **MSM elimination consumer** | T6 if last-standing — double-signal guard drops if Phase 6 already transitioned |
| 8 | CSMBroadcast | 15 Hz broadcast dispatch |
| 9 | PeelDispatch | Batched `FireClient` per player |

### Simultaneity resolution

- **T6 vs T7 same-tick**: Phase 6 fires T7 first → `matchState = Result`. Phase 7 double-signal guard drops queued elim. Winner via F4 tiebreak using Phase 6 counts.
- **Two crowds eliminate same-tick**: Phase 5 dispatches both `CrowdEliminated`. Phase 7 drains queue; first triggers T6, second sees `matchState != Active` and silently drops.
- **Counts for F4 tiebreak**: Phase 6 reads counts AT Phase 6 eval time (post-Phase 1-4 drains, post-Phase 5 transitions). Eliminated crowds' pre-elim count preserved via Round Lifecycle peak tracking.

### Unchanged

- All state transitions T1-T11 (semantic unchanged)
- F1-F6 formulas
- Double-signal guard semantics (F2) — now explicitly referenced from Phase 7
- Broadcast payload, participation flags, timer interp
- All ACs 1-20 (unchanged)

---

## 2. Architecture Impact

### ADR-0001 Crowd Replication Strategy — ✅ Still Valid

No ADR edits. ADR-0001 owns:
- SERVER_TICK_HZ = 15 (cadence) — unchanged
- Server-authoritative model — unchanged
- Broadcast contract — unchanged

Tick-phase ordering is gameplay-layer concern (above the transport layer). TickOrchestrator module (CCR §15a spin-off) implements the phase dispatch loop per MSM's authoritative spec.

---

## 3. Cross-GDD Alignment Verified

| Consumer GDD | Alignment check |
|---|---|
| CCR §C Rule 8 (existing 6-phase order: Collision → Relic → Absorb → Chest → Broadcast → PeelDispatch) | ✓ MSM's 9-phase table EXTENDS CCR's phases 1-4 + 8-9 with new phases 5-7 (CSM eval + MSM timer/elim). No conflict — CCR's broadcast phase = MSM's Phase 8. |
| CSM §F7 grace timer evaluation | ✓ Now explicitly at Phase 5 |
| Relic §C Rule 7 | ✓ `onTick` hooks at Phase 2 (unchanged) |
| Absorb §C.1 | ✓ Overlap detection at Phase 3 (unchanged) |
| Chest §C Rule 9 | ✓ Proximity triggers at Phase 4 (unchanged) |
| Round Lifecycle F1 peak tracking | ✓ Peak timestamp captured on every `updateCount` write — available for F4 tiebreak at Phase 6 |

---

## 4. Batch 4 Scope — ✅ COMPLETE

| Item | Status |
|---|---|
| RC-B-NEW-1 Chest Active-strict guard | ✓ chest-system.md (prior pass) |
| S4-B1 Chest draft modal close-on-elim | ✓ chest-system.md (prior pass) |
| Chest minimap vs HUD no-minimap-MVP | ✓ chest-system.md (prior pass) |
| **RC-B-NEW-4 MSM/CCR/CSM same-tick handler order** | ✓ **this pass** |

All Batch 4 blockers resolved.

---

## 5. Remaining Blockers (pre-`/review-all-gdds` re-run)

From `/review-all-gdds` 2026-04-24:

- **Batch 5 design decisions** (not propagations):
  - FLAG-1 Wingspan leader oppression (DSN-B-1) — Relic GDD
  - FLAG-2 T1 toll late-game trivialization (DSN-B-2) — Chest GDD
  - FLAG-3 Turtle-beats-snowball placement rule (DSN-B-3) — Round Lifecycle GDD
  - DSN-B-MATH Grace-window rescue late-round math — Absorb GDD (surfaced, unresolved)
- **Batch 7 coverage gap** — Pillar 4 Cosmetic Expression primary owner (Skin System)

---

## 6. Follow-Up Actions

1. **Run `/consistency-check`** — verify final Batch 4 close has no cascades.
2. **Re-run `/review-all-gdds`** — Batches 1-4 now complete; re-verify consistency blockers cleared.
3. **Batch 5 design decisions** — convene design discussion for FLAG-1/2/3 + DSN-B-MATH.
4. Pre-production gate blocked on Batch 5 resolution.

---

## 7. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, seventh invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — no ADR edits triggered this pass.
**Batches 1-4 close:** ✅ All consistency + contract blockers from /review-all-gdds 2026-04-24 resolved.
