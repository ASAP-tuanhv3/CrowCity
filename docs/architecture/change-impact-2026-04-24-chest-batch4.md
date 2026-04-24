# Change Impact Report — Chest System Batch 4 Amendments

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/chest-system.md`
**Trigger:** `/propagate-design-change design/gdd/chest-system.md` — Batch 4 chest + relic contract tightening per `/review-all-gdds` 2026-04-24 RC-B-NEW-1 + S4-B1 + pre-existing minimap-vs-HUD mismatch.
**Related docs:** `change-impact-2026-04-24-csm-batch1.md`, `change-impact-2026-04-24-relic-csm-sync.md`, `change-impact-2026-04-24-lod-batch3.md`

---

## 1. Change Summary

### Blockers resolved (from /review-all-gdds 2026-04-24)

| ID | Issue | Resolution |
|---|---|---|
| RC-B-NEW-1 | Chest guard 3c rejects only `Eliminated`; CSM state table requires GraceWindow rejected too | Guard 3c tightened: `crowdState != "Eliminated"` → `crowdState == "Active"` (strict) |
| S4-B1 | Chest draft modal does not close when opener eliminated — UX dead-end | Client-side `CrowdEliminated` subscription added; modal closes within 1 broadcast interval; "opener eliminated" toast shown; new AC-23 |
| Pre-existing | Chest §G minimap references vs HUD §C no-minimap-MVP decision | 7 minimap references across chest-system.md annotated "DEFERRED to VS+"; broadcast stays wired for post-MVP consumption |

### Edits applied (11 total)

| # | Site | Change |
|---|---|---|
| 1 | L3 Status header | 2026-04-24 Batch 4 amendment note |
| 2 | L36 Core Rule 3 guard c | `crowdState != "Eliminated"` → `crowdState == "Active"` (strict) |
| 3 | L158 CSM integration contract | Split `CrowdDestroyed` (server modifier flush) + `CrowdEliminated` (client modal close) semantics |
| 4 | L166 `ChestStateChanged` consumer | Minimap consumer deferred VS+ |
| 5 | L167 HUD integration | No-MVP-minimap annotation |
| 6 | L288 Edge case (GraceWindow chest trigger) | Double-protection note (guard 3c primary reject, 3f secondary) |
| 7 | L297 Edge case (rival eliminates opener mid-DraftOpen) | Client modal close-on-elim via `CrowdEliminated` subscription explicit |
| 8 | L338 Dependencies — HUD row | Minimap deferred VS+ |
| 9 | L351 Provisional #4 | Minimap deferred VS+ |
| 10 | L453 Signal table `ChestStateChanged` | Consumer list updated (billboard MVP, minimap VS+) |
| 11 | L519 Data flow diagram | Added `CrowdEliminated → modal close`; minimap annotated VS+ |
| 12 | L527 UX Flag | Minimap UX spec deferred |
| 13 | L537 AC-4 | Added GraceWindow as reject path (c-ii); now 6 reject paths |
| 14 | L539 AC-5 | `crowdState != Eliminated` → `crowdState == Active` (strict) |
| 15 | New AC-23 | Draft modal close-on-opener-elim integration test |
| 16 | L589 Open Question #4 | Minimap MVP-critical → VS+ deferred |

### Unchanged

- All other guards (a, b, d, e, f) — semantically unchanged
- Toll economy (T1=10, T2=40, T3=120)
- Draft roll logic, rarity weights, re-roll attempts
- State machine (7 states + 13 transitions)
- ChestPeelOff, ChestOpenBurst VFX contracts
- Billboard UI (MVP) + Relic Card UI (VS) visual specs
- Performance + bandwidth ACs

---

## 2. Architecture Impact

### ADR-0001 Crowd Replication Strategy — ✅ Still Valid

No ADR edits triggered. Chest is gameplay-layer concern; ADR covers transport + hit-detection only. `CrowdEliminated` + `CrowdDestroyed` reliable events were both already declared in ADR-0001's Key Interfaces block (post-Batch-1 amendment), so Chest's subscription to these events uses already-established contracts.

---

## 3. Cross-GDD Alignment Verified

| Consumer GDD | Alignment check |
|---|---|
| CSM §States table | ✓ Chest column `no` for GraceWindow + Eliminated now reflected in Chest guard 3c |
| CSM §Network event contract | ✓ `CrowdEliminated` (reliable) + `CrowdDestroyed` (reliable) distinct semantics honored by Chest |
| Relic System §L355 | ✓ Chest consumes `CrowdDestroyed` for `_crowdModifiers` flush (already correct pre-Batch 4) |
| HUD §C no-minimap-MVP | ✓ 7 minimap refs in Chest now deferred to VS+ |
| HUD GDD (art bible §7 locked) | ✓ No action needed — Chest defers to HUD's decision |
| Relic Card UI (VS) | ⚠ Needs to implement `CrowdEliminated` subscription + close-on-elim handler per AC-23 — flagged for VS author |

---

## 4. Remaining Chest GDD Blockers (post-Batch-4)

From `/review-all-gdds` 2026-04-24:
- **DSN-B-2 T1 toll late-game trivialization** — design decision, Batch 5. Resolution options: toll-as-percentage-of-count, or round-time-tiered toll escalation. Not a propagation.

All Chest-specific consistency items resolved.

---

## 5. Batch 4 Scope — Partial Progress

| Item | Owner GDD | Status |
|---|---|---|
| RC-B-NEW-1 Chest Active-strict guard | chest-system.md | ✓ this pass |
| S4-B1 Chest draft modal close-on-elim | chest-system.md | ✓ this pass |
| Chest minimap vs HUD no-minimap-MVP | chest-system.md | ✓ this pass |
| RC-B-NEW-4 MSM/CCR/CSM same-tick handler order | match-state-machine.md | ⏳ next pass |

---

## 6. Follow-Up Actions

1. **Run `/propagate-design-change design/gdd/match-state-machine.md`** — RC-B-NEW-4 handler-order lock (CCR → CSM elim → MSM timer → T7 winner) + elimination ordering guards.
2. **Run `/consistency-check`** after MSM pass completes.
3. **Batch 5** — design decisions FLAG-1/2/3 + DSN-B-MATH grace rescue math.
4. **Re-run `/review-all-gdds`** after Batches 1-4 complete.

---

## 7. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, sixth invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — no ADR edits triggered this pass.
