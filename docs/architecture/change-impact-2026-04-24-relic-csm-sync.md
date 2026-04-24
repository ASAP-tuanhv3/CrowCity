# Change Impact Report — Relic System CSM-Sync Pass

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/relic-system.md`
**Trigger:** `/propagate-design-change design/gdd/relic-system.md` — sync Relic GDD against CSM Batch 1 amendment (applied earlier same day).
**Related docs:** `docs/architecture/change-impact-2026-04-24-csm-batch1.md`

---

## 1. Change Summary

This pass is a **sync-back**, not a new propagation. Relic System already specified `radiusMultiplier` + `recomputeRadius` as its assumed CSM contract. CSM Batch 1 landed those APIs 2026-04-24 earlier in this session. This pass updates Relic GDD to reflect that the assumed contract is now realized, fixes a signature drift (one-arg vs two-arg `recomputeRadius`), and replaces direct-field-write language with API calls per CSM Batch 1's write-access contract.

### Edits to `relic-system.md` (10 total)

1. **L3 Status header** — amendment note added
2. **§Core Rules L49 (radius routing)** — "writes `crowd.radiusMultiplier`" → "calls `CrowdStateServer.recomputeRadius(crowdId, newMultiplier)`"
3. **§Core Rules L61 (`clearAll()`)** — direct field reset → API call
4. **§Core Rules L180 (CSM integration contract)** — "Requires CSM amendment" → "✓ CSM Batch 1 complete"
5. **§Content — Wingspan L215 (hooks)** — `recomputeRadius(crowdId, 1.35)` / `(crowdId, 1.0)` signature
6. **§F2 Radius Composition L266 (recomputation trigger)** — two-arg signature + validation note
7. **§Dependencies L355 (CSM upstream row)** — status "In Review" → "Batch 1 Applied 2026-04-24"; remove amendment flag
8. **§Dependencies L372 (CSM downstream row)** — same status + API update
9. **§Provisional L376** — provisional #1 marked RESOLVED
10. **§Bidirectional L387** — "REQUIRES CSM amendment" → "✓ Batch 1 landed"

### Unchanged
- Wingspan magnitude (μ=1.35), registry `WINGSPAN_RADIUS_MULTIPLIER=1.35` unchanged
- F1 `effective_toll_chain` formula + `TollBreaker` relic
- F2 Radius composition math: `r = radius_from_count(count) × μ`
- `RADIUS_MULTIPLIER_MIN=0.5` / `RADIUS_MULTIPLIER_MAX=1.5` tuning knobs
- Non-state relic routing (Follower Entity modifier API, Chest System toll chain)
- Same-tick ordering (Collision → Relic → Absorb → Chest)
- All ACs (AC-9, AC-16, AC-22 continue to reference post-multiplied `crowd.radius`)

---

## 2. Architecture Impact

### ADR-0001 Crowd Replication Strategy — ✅ Still Valid

ADR-0001 already updated 2026-04-24 (Batch 1 + consistency-check Fix A) with:
- `radiusMultiplier` field in `CrowdState` type
- `recomputeRadius(crowdId, newMultiplier)` in API block
- `[0.5, 1.5]` range per registry hard ceiling
- `RemoteEvents.CrowdCountClamped`, `CrowdCreated`, `CrowdDestroyed` signals

Relic GDD's sync pass references these by name only — no ADR-0001 content change needed.

**No other ADRs exist yet.** No further ADR impact.

---

## 3. Remaining Relic GDD Blockers (not resolved by this sync pass)

From `/review-all-gdds` 2026-04-24:

- **DSN-B-1 Wingspan oppression (FLAG-1)** — design decision. Options: cap μ below sit-still threshold, gate Wingspan to T3-only, or NPC spawn-distance gate (`NPC_RESPAWN_MIN_CROWD_DIST`). Escalate to creative-director or resolve at Batch 5 design pass.
- **Pillar 4 Cosmetic Expression coverage gap** — Relic System uses `skins`/hue field indirectly; not in scope here.

---

## 4. Follow-Up Actions

1. **Batch 2 (radius-range cascade)** — natural next. Anchor GDDs: `absorb-system.md` + `crowd-collision-resolution.md`. Propagate composed range `[1.53, 18.04]` into their F1 variable tables + radius references (currently stale at `[3.05, 12.03]`).
2. **Batch 3-5** — LOD ownership, Chest/Relic/MSM contracts, design decisions. Parallelizable.
3. **Re-run `/consistency-check`** after each batch to verify no new conflicts.
4. **Re-run `/review-all-gdds`** after Batches 1-4 to clear consistency blockers.

---

## 5. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, second invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — no ADR edits triggered.
