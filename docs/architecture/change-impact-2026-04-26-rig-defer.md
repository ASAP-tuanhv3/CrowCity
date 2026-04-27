# Change Impact Report — 2026-04-26 Rig-Defer Sync

**Trigger**: ADR-0001 amend 2026-04-26 C1 (follower rig spec deferred to FE GDD §C.1)
**Anchor**: ADR-driven (not GDD-driven — skill arg-spec mismatch noted)
**Driving GDD**: `design/gdd/follower-entity.md` §C.1 (locked 2026-04-22, sole rig owner)
**Review mode**: lean (TD-CHANGE-IMPACT skipped)

---

## Change Summary

ADR-0001 §Decision rig spec was stale relative to Follower Entity GDD's locked 2-Part Body+Hat rig. C1 conflict surfaced by `/architecture-review` 2026-04-26. ADR-0001 amended this session to defer rig topology ownership to FE GDD §C.1.

Original spec across docs: "custom 4-6-part CFrame rig (root + torso + head + 2 arms + 2 legs)".
Locked spec (FE GDD §C.1, 2026-04-22): **2-Part — Body MeshPart + Hat MeshPart with WeldConstraint**.

Rationale for reduction: follower-pool memory budget (460 LOD-0 Body + 460 Hat slots = 920 Parts; 4-6-part spec would have been 1840-2760 Parts at same pool size, exceeding ADR-0003 instance caps).

---

## Impact Analysis

### ADRs (5 reviewed)

| ADR | Status | Rationale |
|---|---|---|
| ADR-0001 Crowd Replication Strategy | ✅ **Already Amended** | Source of truth — amended this session (Status header + §Decision L57 + GDD Reqs row L242) |
| ADR-0002 TickOrchestrator | ✅ Still Valid | No rig refs |
| ADR-0003 Performance Budget | ✅ Still Valid | No rig refs (instance caps are Parts-rendered, agnostic of rig topology) |
| ADR-0004 CSM Authority | ✅ Still Valid | No rig refs |
| ADR-0006 Module Placement | ✅ Still Valid | No rig refs |

**No ADRs superseded.** ADR-0001 amended in-place; remains Proposed (no other Accept blockers).

### Downstream stale-text sync (7 edits across 4 files)

| # | File | Line | Action |
|---|---|---|---|
| 1 | `design/gdd/systems-index.md` | 130 | Replaced "custom 4-6-part CFrame rig, NO Humanoid" → "custom non-Humanoid CFrame rig (2-Part Body+Hat per FE GDD §C.1)" |
| 2 | `design/art/art-bible.md` | 59 | Replaced "simplified 4-6-part custom rig" → "simplified non-Humanoid custom rig" + cite FE GDD §C.1 |
| 3 | `design/art/art-bible.md` | 148 | Replaced "simplified custom 4-6-part rig" → "simplified custom non-Humanoid rig" + cite FE GDD §C.1 |
| 4 | `design/art/art-bible.md` | 333-342 (§8.6) | Rewrote rig bullet: "root Part + 4-6 child Parts" → "2-Part Body MeshPart + Hat MeshPart with WeldConstraint"; preserved historical "reduced from earlier" note; updated movement bullet to cite Follower Entity §F8/F9 procedural walk-bob |
| 5 | `docs/architecture/architecture.md` | 130 | Replaced "non-Humanoid 4-6-part CFrame rig" → "non-Humanoid CFrame rig (2-Part Body+Hat per FE GDD §C.1)" |
| 6 | `docs/architecture/architecture.md` | 896 (ADR-0007 line) | Replaced "Non-Humanoid 4-6-part CFrame rig" → "Non-Humanoid CFrame rig (rig topology owned by FE GDD §C.1 — currently 2-Part Body+Hat with WeldConstraint)" |
| 7 | `docs/registry/architecture.yaml` | 530 | Rewrote `humanoid_on_followers` pattern description; added `revised: 2026-04-26` field; preserved historical "reduced from earlier 4-6-part spec" note |

### ADR-0001 status-header housekeeping (1 edit)

| File | Line | Action |
|---|---|---|
| `docs/architecture/adr-0001-crowd-replication-strategy.md` | 5 | Status header amend note: "stale-text sync flagged for `/propagate-design-change`" → "stale-text sync COMPLETE 2026-04-26"; lists 7 synced locations + cites this change-impact doc |
| `docs/architecture/adr-0001-crowd-replication-strategy.md` | 242 | GDD Reqs Addressed art-bible row: "stale text — pending sync" → "synced 2026-04-26 via /propagate-design-change"; corrected §8.5 → §8.6 (rigging-standards section number) |

---

## Resolution Decisions

All 7 sync edits applied per auto-mode + lean-review-mode policy. No ADR superseded; no new ADR required. Change is pure terminology sync downstream of an ADR amendment.

---

## Files Modified This Pass

1. `design/gdd/systems-index.md` (1 edit)
2. `design/art/art-bible.md` (3 edits — L59, L148, L333-342 §8.6)
3. `docs/architecture/architecture.md` (2 edits — L130, L896)
4. `docs/registry/architecture.yaml` (1 edit — humanoid_on_followers pattern)
5. `docs/architecture/adr-0001-crowd-replication-strategy.md` (2 housekeeping edits — Status header, GDD Reqs table)
6. `docs/architecture/change-impact-2026-04-26-rig-defer.md` (this doc, new)

**Verdict**: COMPLETE.

---

## Validation

```bash
$ rg "4-6-part|4-6 child" design/gdd/systems-index.md docs/architecture/architecture.md
# (no matches — clean)

$ rg "4-6-part|4-6 child" design/art/art-bible.md docs/registry/architecture.yaml docs/architecture/adr-0001-crowd-replication-strategy.md
# Only intentional historical context refs ("reduced from earlier 4-6-part spec")
```

Live (non-historical) "4-6-part" references: **0**. Historical context refs: 2 (intentional, preserved with explicit "reduced from earlier" framing).

---

## Follow-Up Actions

- ADR-0001 ready for Proposed → Accepted transition (no remaining blockers).
- Re-run `/architecture-review` after Accept transition to verify C1 status moves from 🔴 to ✅ (closed).
- C2 (NPC replication channel) remains open — addressed when ADR-0008 NPC Spawner Authority is written.

---

## Related Decisions

- ADR-0001 Crowd Replication Strategy — amended this session (rig-defer + sync)
- `/architecture-review` 2026-04-26 — surfaced the C1 conflict
- `/propagate-design-change` 2026-04-26 — this run, executed the downstream sync
- Follower Entity GDD §C.1 — sole rig-topology owner going forward
