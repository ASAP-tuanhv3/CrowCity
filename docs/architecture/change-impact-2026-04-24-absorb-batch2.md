# Change Impact Report — Absorb System Batch 2 Propagation

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/absorb-system.md`
**Trigger:** `/propagate-design-change design/gdd/absorb-system.md` — Batch 2 radius-range + ρ rename + F4 Pillar 5 recalibration cascade per `/review-all-gdds` 2026-04-24 report.
**Related docs:** `docs/architecture/change-impact-2026-04-24-csm-batch1.md`, `docs/architecture/change-impact-2026-04-24-relic-csm-sync.md`

---

## 1. Change Summary

### Edits to `absorb-system.md` (10 total)

| # | Site | Before | After |
|---|---|---|---|
| 1 | Status header | "Designed (pending /design-review)" | Batch 2 amendment note |
| 2 | F1 `radius_sq` var range | `[9.30, 144.72]` (baseline r²) | `[2.34, 325.44]` full composed; notes MVP [9.30, 263.74] at Wingspan max |
| 3 | F3 formula | `N_max = floor(π × radius² × ρ_neutral)` | `... × ρ_design` |
| 4 | F3 `radius` var range | `[3.05, 12.03]` (baseline) | `[1.53, 18.04]` composed; MVP note [3.05, 16.24] |
| 5 | F3 `ρ_neutral` → `ρ_design` + example values | count=10→~3; count=100→~10; count=300→~22 (at ρ=0.05) | count=10→~4; count=100→~15; count=300→~34 (at ρ_design=0.075) |
| 6 | F4 formula + ρ rename | `R_absorb = ... × ρ_neutral` | `... × ρ_design` |
| 7 | F4 `radius` var range | `[3.05, 12.03]` | `[1.53, 18.04]` composed; MVP note |
| 8 | F4 Pillar 5 table | 3 rows (count=10/100/300) at ρ=0.05 | 4 rows (count=1/10/100/300) at ρ_design=0.075; added count=1 rescue ceiling row |
| 9 | F4 DSN-B-MATH advisory | not present | Advisory block surfacing late-round rescue math collapse (ρ_effective≈0.011 → 1.07/s); resolution deferred Batch 5 |
| 10 | AC-17 perf budget | "12 × 100 = 1,200 overlap tests; p99 ≤ 0.5ms" | "12 × 300 = 3,600 overlap tests; p99 ≤ 1.5ms" (scaled 3× proportional to NPC_POOL_SIZE 200→300) |

Plus 3 internal tuning-table updates (2 within Formulas section, 1 in dedicated Tuning Knobs section) aligning knob names and values with registry.

### New formulas/values introduced

| F4 count=1 row | `R_absorb = (3.05 × 2 × 16) × 0.075 = 7.32/s` | Floor-rescue ceiling at CROWD_START ceiling; establishes Pillar 5 rescue math baseline |

### Unchanged
- F1 overlap test formula (`(dx² + dz²) ≤ radius²`)
- F2 contention winner (argmin distance, lex tiebreak)
- F4 formula structure (`R_absorb = radius × 2 × v_npc × ρ`)
- All states, transitions, interactions, edge cases (pure numerical/symbol propagation)
- AC-1 through AC-16 semantics (numeric examples within new ranges)
- V/A section (VFX + Audio specs, AbsorbSnap, streak escalation)

---

## 2. Architecture Impact

### ADR-0001 Crowd Replication Strategy — ✅ Still Valid

ADR-0001 Key Interfaces block already updated 2026-04-24 (CSM Batch 1) with composed radius derivation and [0.5, 1.5] multiplier range. Absorb System's F1/F3/F4 range updates are downstream consequences of that already-registered change. No ADR content edits triggered.

### Registry — ✅ Still Valid

`radius_from_count` formula entry already has `output_range: [1.53, 18.04]` (set during Relic System 2026-04-23 + CSM Batch 1 updates). `ρ_design` implicitly tracked via `NPC_POOL_SIZE=300` and `ARENA_WALKABLE_AREA_SQ=4000` constants. No new registry entries needed; existing entries aligned.

### `/consistency-check` follow-up

Recommended after Batch 2 completes for all target GDDs (Absorb + CCR). Expect clean pass given registry baselines are already aligned.

---

## 3. Surfaced (not resolved) Design Decision — DSN-B-MATH

F4 amendment now explicitly documents the late-round rescue math collapse:
- Round-start rescue: 7.32/s (ρ=0.075, 3-sec grace → ~22 absorbs available)
- Late-round rescue: ~1.07/s (ρ_effective≈0.011, 3-sec grace → ~3 absorbs available)
- Pillar 5 floor-rescue may fail at late-round; Grace Window too short to recover count=1

**Not resolved by this propagation.** Resolution options (deferred to Batch 5 design pass):
1. Scale `GRACE_WINDOW_SEC` dynamically by `ρ_effective`
2. Elevate NPC density floor when any crowd hits count=1 (burst respawn)
3. Re-derive Pillar 5 calibration at realistic late-round density

---

## 4. Remaining Absorb GDD Blockers (post-Batch-2)

From `/review-all-gdds` 2026-04-24:
- **DSN-B-MATH grace-window rescue math** — surfaced above; design decision Batch 5
- **FLAG-1 Wingspan oppression** — not owned by Absorb; relic-system.md target
- **FLAG-2 T1 toll trivialization** — Chest target, not Absorb
- **AbsorbSnap VFX per-tick particle cap math (RC-B-NEW-6)** — VFX Manager target, not Absorb (Absorb signals cadence only)

All Absorb-specific consistency items from the review report now resolved.

---

## 5. Follow-Up Actions

1. **Run `/propagate-design-change design/gdd/crowd-collision-resolution.md`** next — same Batch 2 scope: F1 radius range update, AC-17 perf budget 1200→3600, Follower Entity stale `collision_transfer_per_tick = 2` reference.
2. **`/consistency-check`** after CCR completes to verify Batch 2 clean.
3. **Batch 3** (LOD tier 2 cap 3-way reconciliation, tuning ownership).
4. **Re-run `/review-all-gdds`** after Batches 1-4 clear.

---

## 6. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, third invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — no ADR edits triggered.
