# Change Impact Report — Crowd Collision Resolution Batch 2 Propagation

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/crowd-collision-resolution.md`
**Trigger:** `/propagate-design-change design/gdd/crowd-collision-resolution.md` — Batch 2 radius-range propagation + CSM Batch 1 sync-back per `/review-all-gdds` 2026-04-24.
**Related docs:** `change-impact-2026-04-24-csm-batch1.md`, `change-impact-2026-04-24-absorb-batch2.md`

---

## 1. Change Summary

### Edits to `crowd-collision-resolution.md` (10 total)

| # | Site | Before | After |
|---|---|---|---|
| 1 | Status header | "In Design" | Batch 2 amendment note |
| 2 | §System inputs L163 | `[3.05, 12.03] studs` (baseline only) | Composed `[1.53, 18.04]` + MVP `[3.05, 16.24]` annotation |
| 3 | F1 var table L174 | `[3.05, 12.03]` for `A.radius, B.radius` | Composed range + baseline/MVP context |
| 4 | §Core Rules L33 | "**new API requirement** on CSM" | "✓ CSM Batch 1 landed this API" |
| 5 | §Dependencies L136 | `getAllActive()` marked "New API — CSM amendment" | "✓ CSM Batch 1 Applied" |
| 6 | §Dependencies L138 | `setStillOverlapping()` marked "New API — CSM amendment" | "✓ CSM Batch 1 Applied" |
| 7 | §Design tensions L149 flag #1 | "Flag as CSM amendment when approved" | ✓ **RESOLVED 2026-04-24** marker |
| 8 | §Dependencies Upstream L299 | "In Revision (designed); new API amendment required" | "Batch 1 Applied 2026-04-24" |
| 9 | §Bidirectional L318 | "Crowd State Manager GDD amendment required" | ✓ "Batch 1 landed 2026-04-24" |
| 10 | §Open Questions OQ-1 L549 | "Target: next Crowd State revision after this GDD is approved" | ✓ **RESOLVED 2026-04-24** marker |

### Review report "CCR AC-17 perf 1200 → 3600" — MIS-ATTRIBUTED

The `/review-all-gdds` report listed "CCR AC-17 perf budget 1200 tests stale (NPC Spawner recalibration → 3600)" as a CCR blocker. Analysis during this pass confirmed the 1200 number never lived in CCR. CCR's AC-17 is about equal-count peel emission (Edge, Logic). CCR's actual perf AC is AC-20 at 66 pairs (correct O(p²) for 12 crowds), which is not a function of NPC_POOL_SIZE. The 1200 → 3600 belonged to Absorb's AC-17 (12 crowds × 100 NPCs each pre-recalibration), which was fixed in the prior Absorb Batch 2 pass.

**No CCR AC-20 edit needed.** Documented here for future-proof clarity.

### Unchanged
- F1 overlap test formula (`|A.pos - B.pos|² ≤ (A.radius + B.radius)²`)
- F2 drip assignment (lex-ordered attacker selection, equal-count symmetry)
- F3 `collision_transfer_per_tick` invocation (delegated to CSM §F3)
- F4 triple_overlap_drain (additive stacking)
- All edge cases + all ACs (AC-01 through AC-21)
- Spawn-separation constraint math (`2 × radius_from_count(10) = 8.48 studs` at baseline μ=1.0 — correct because no relics at spawn)
- AC-20 perf budget (66 pairs × ~6 overlapping, p99 ≤ 0.15ms — stays)

---

## 2. Architecture Impact

### ADR-0001 Crowd Replication Strategy — ✅ Still Valid

No ADR edits. CSM Batch 1 (earlier same session) already refreshed ADR-0001 Key Interfaces with `getAllActive()`, `setStillOverlapping()`, composed radius derivation, and [0.5, 1.5] multiplier range.

### Registry — ✅ Still Valid

`radius_from_count` output_range `[1.53, 18.04]` already set during Relic System 2026-04-23 + CSM Batch 1 2026-04-24. No entries need update.

---

## 3. Post-Batch-2 CCR Blockers

From `/review-all-gdds` 2026-04-24:

- **All consistency items resolved by this pass.**
- **No design-theory blockers owned by CCR.**
- DSN-B-MATH grace-window math is **surfaced** here (CCR feeds overlap bit to CSM F7 grace evaluation) but **resolution owned by Absorb/CSM** (density scaling). CCR is the contract consumer, not the decision site.

CCR Batch 2 scope is fully resolved.

---

## 4. Cumulative Session Progress

| Pass | GDD | Status | Change-impact doc |
|---|---|---|---|
| Batch 1 | `crowd-state-manager.md` + `adr-0001-crowd-replication-strategy.md` | ✓ Applied | `change-impact-2026-04-24-csm-batch1.md` |
| Consistency | CSM + ADR-0001 + registry | ✓ Fixed 2 conflicts, 2 registry notes | (logged in session state) |
| Sync | `relic-system.md` | ✓ Applied (10 edits, two-arg `recomputeRadius` signature) | `change-impact-2026-04-24-relic-csm-sync.md` |
| Batch 2 | `absorb-system.md` | ✓ Applied (radius + ρ + F4 recalibrate + DSN-B-MATH advisory) | `change-impact-2026-04-24-absorb-batch2.md` |
| Batch 2 | `crowd-collision-resolution.md` | ✓ Applied (this pass) | `change-impact-2026-04-24-ccr-batch2.md` |

---

## 5. Follow-Up Actions

1. **Run `/consistency-check`** — verify all Batch 2 changes align with registry.
2. **Batch 3 — LOD tier reconciliation** — follower-entity.md / follower-lod-manager.md / crowd-replication-strategy.md 3-way mismatch (tier 2 cap: 4 Parts vs 1 billboard vs FAR_RANGE_MAX=4). Declare Follower LOD Manager as sole owner.
3. **Batch 4 — Chest + Relic + MSM contracts** — Chest `crowdState == Active` guard, Chest draft modal close-on-elim hook, MSM/CCR/CSM same-tick handler order lock.
4. **Batch 5 — Design decisions** — FLAG-1 Wingspan oppression, FLAG-2 T1 toll scaling, FLAG-3 placement rule, DSN-B-MATH grace rescue.
5. **Re-run `/review-all-gdds`** after Batches 1-4 clear.

---

## 6. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, fourth invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — no ADR edits triggered.
