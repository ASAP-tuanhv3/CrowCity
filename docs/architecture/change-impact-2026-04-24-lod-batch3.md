# Change Impact Report — LOD Tier 2 Cap Reconciliation (Batch 3)

**Date:** 2026-04-24
**Anchor GDD:** `design/gdd/follower-lod-manager.md` (declared sole owner of render caps + LOD distances)
**Trigger:** `/propagate-design-change design/gdd/follower-lod-manager.md` — Batch 3 per `/review-all-gdds` 2026-04-24 RC-B-NEW-2 + RC-B-NEW-3.
**Related docs:** `change-impact-2026-04-24-csm-batch1.md`, `change-impact-2026-04-24-absorb-batch2.md`, `change-impact-2026-04-24-ccr-batch2.md`

---

## 1. Conflict Summary

Three documents disagreed on tier 2 render cap:

| Doc | Prior statement | Source of truth? |
|---|---|---|
| `follower-lod-manager.md` L213, L233, L241 | 1 billboard impostor per crowd (authoritative; explicit "4 rigs" correction note) | ✓ YES — spec authority |
| `crowd-replication-strategy.md` L200, L314 | `FAR_RANGE_MAX = 4` Parts per crowd | ✗ stale |
| `follower-entity.md` L10 Overview | "4 on a distant one" | ✗ stale |
| `follower-lod-manager.md` L388 AC-LOD-07 | "Tier 2 → unchanged 4" | ✗ internal self-inconsistency |
| `adr-0001-crowd-replication-strategy.md` L90 diagram | "max 4 rendered (billboard impostor)" | ✗ stale |

Plus `/review-all-gdds` RC-B-NEW-3: tuning-knob ownership collision on 7 LOD constants (OWN_CLOSE_MAX, RIVAL_CLOSE_MAX, MID_RANGE_MAX, FAR_RANGE_MAX, LOD_TIER_NEAR/MID/FAR) — both CRS (§F3 + Tuning Knobs) and LOD Manager (§Locked constants) claimed these.

---

## 2. Resolution — Ownership Declaration

**Follower LOD Manager (`design/gdd/follower-lod-manager.md`) is declared sole owner of:**
- All 4 render cap VALUES (OWN_CLOSE_MAX=80, RIVAL_CLOSE_MAX=30, MID_RANGE_MAX=15, FAR_RANGE_MAX=1)
- All 3 LOD distance thresholds (LOD_TIER_NEAR=20, LOD_TIER_MID=40, LOD_TIER_FAR=100)
- CULL cap (0)

**Consumers:**
- CRS — broadcast transport contract only; references LOD constants but does not define them
- Follower Entity — consumer; renders per LOD Manager spec
- ADR-0001 — architectural foundation; diagram shows LOD Manager spec values

---

## 3. Edits Applied (9 across 4 docs)

### A. `follower-lod-manager.md` (anchor — 3 edits)

| # | Site | Change |
|---|---|---|
| A1 | Status header | 2026-04-24 Batch 3 note: sole-owner declaration |
| A2 | L388 AC-LOD-07 | "Tier 2 → unchanged 4" → "Tier 2 → unchanged 1 (billboard per crowd; platform-invariant)" |
| A3 | §Tuning Knobs "Locked constants" block (L347-358) | Renamed to "Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3 declaration)"; marked all 8 constants (7 LOD + CULL) as **owned here**; added tunability note |

### B. `crowd-replication-strategy.md` (consumer — 3 edits)

| # | Site | Change |
|---|---|---|
| B1 | Status header | 2026-04-24 Batch 3 note: render-cap ownership transferred to LOD Manager |
| B2 | L197-203 F3 var table | `FAR_RANGE_MAX = 4` → `1 billboard per crowd`; all 7 LOD constants annotated **Owned by Follower LOD Manager** |
| B3 | L311-317 Tuning Knobs | Header note added ("referenced-only; authoritative owner: LOD Manager"); `FAR_RANGE_MAX 4` → `1 billboard/crowd`, range locked; all 7 rows pointer-annotated |

### C. `follower-entity.md` (consumer — 2 edits)

| # | Site | Change |
|---|---|---|
| C1 | Status header | 2026-04-24 Batch 3 note + prior consistency-check note |
| C2 | L10 Overview | "4 on a distant one" → "a single billboard impostor on a distant one"; "40-100m, 2-tri billboard impostor" → "40-100m, one billboard impostor per crowd — tier 2 cap owned by Follower LOD Manager §F3" |

### D. `adr-0001-crowd-replication-strategy.md` (architecture consumer — 2 edits)

| # | Site | Change |
|---|---|---|
| D1 | Status header | 2026-04-24 Batch 3 note: diagram cap corrected to LOD Manager spec |
| D2 | L90 diagram | "max 4 rendered (billboard impostor)" → "max 1 billboard impostor per crowd" |

---

## 4. ADR-0001 Impact

**Classification:** ⚠️ Needs Review → ✅ Updated in place (D1 + D2 edits)

Core architectural decision unchanged:
- Server-authoritative hitbox-only model ✓
- 15 Hz broadcast cadence ✓
- 3-tier LOD structure (near / mid / far / cull) ✓
- Client-side boids flocking ✓

Only the diagram's tier 2 cap illustration was stale. Value aligned to LOD Manager's authoritative spec (1 billboard per crowd). No Decision/Alternatives/Consequences/Risks sections touched.

---

## 5. Unchanged (verified correct)

- LOD Manager's §F3 cap table (already had tier 2 = 1 billboard; that was always correct)
- LOD Manager's billboard-mode implementation spec (L213, L233, L241)
- LOD Manager's mobile multiplier spec (L235, L241 — tier 0 only)
- Follower Entity's pool prealloc (60 × LOD 2 billboard slots — 12 crowds × 1 + overhead headroom is fine; not a conflict since pool ≥ max used)
- All distance thresholds (20 / 40 / 100) — art bible §5 alignment
- All tier 0/1 caps (80 / 30 / 15) — unchanged

---

## 6. Batch 3 Scope Complete

All RC-B-NEW-2 + RC-B-NEW-3 items from `/review-all-gdds` 2026-04-24 resolved:
- ✓ Tier 2 cap 3-way mismatch (4 vs 1 vs 4) → locked at 1 billboard per crowd
- ✓ Tuning-knob ownership conflict → LOD Manager sole owner, 7 constants pointer-referenced from CRS

---

## 7. Follow-Up Actions

1. **Re-run `/consistency-check`** — verify Batch 3 changes have no downstream cascades.
2. **Batch 4** — Chest + Relic + MSM contracts:
   - Chest `crowdState == Active` guard (RC-B-NEW-1)
   - Chest draft modal close-on-opener-elimination hook (S4-B1)
   - MSM / TickOrchestrator explicit handler order (RC-B-NEW-4: CCR → CSM elim → MSM timer → T7 winner)
3. **Batch 5** — Design decisions (FLAG-1 Wingspan oppression / FLAG-2 T1 toll / FLAG-3 placement / DSN-B-MATH grace rescue)
4. **Re-run `/review-all-gdds`** after Batches 1-4 complete.

---

## 8. Sign-off

**Applied by:** `/propagate-design-change` skill (2026-04-24, fifth invocation this session)
**Reviewed by:** user (batch approval)
**ADR-0001 status:** unchanged (Proposed) — 3rd in-place amendment this session (Batch 1 + consistency-check Fix A + Batch 3 diagram); core decision still valid.
