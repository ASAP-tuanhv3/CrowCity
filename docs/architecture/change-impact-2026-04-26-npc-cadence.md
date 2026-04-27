# Change Impact Report — 2026-04-26 NPC Spawner GDD Cadence Sync

**Anchor GDD**: `design/gdd/npc-spawner.md`
**Trigger**: ADR-0008 NPC Spawner Authority (Proposed 2026-04-26) locked NPCSpawner cadence as own `RunService.Heartbeat:Connect`; GDD R5 + §Interactions + §Dependencies + AC-05 + §DI requirements still referenced obsolete "shared `ServerTickAccumulator`" terminology.
**Review mode**: lean (TD-CHANGE-IMPACT skipped)

---

## Change Summary

NPC Spawner GDD authored 2026-04-22 referenced a hypothetical "shared `ServerTickAccumulator`" module with `:subscribe(fn)` API as the cadence source. ADR-0002 (Proposed 2026-04-24, Accepted 2026-04-26) introduced `TickOrchestrator` as the sole gameplay-tick accumulator AND explicitly excluded NPCSpawner from its 9-phase sequence (§Related Decisions L289). ADR-0008 (Proposed 2026-04-26) locked NPCSpawner with its own `RunService.Heartbeat:Connect` per the non-gameplay-tick exemption.

GDD text needed sync to remove all ServerTickAccumulator references.

---

## Impact Analysis

### ADRs (6 reviewed)

| ADR | Status | Reason |
|---|---|---|
| ADR-0001 Crowd Replication | ✅ Still Valid | No NPC cadence refs |
| ADR-0002 TickOrchestrator | ✅ Still Valid | Already excluded NPCSpawner from Phase 1-9 (§Related Decisions L289); NPC sync confirms intent |
| ADR-0003 Performance Budget | ✅ Still Valid | Network table amendment landed via ADR-0008 pass; cadence not affected |
| ADR-0004 CSM Authority | ✅ Still Valid | NPCSpawner read-only consumer rule confirmed |
| ADR-0006 Module Placement | ✅ Still Valid | Source Tree Map already lists `ServerStorage/Source/NPCSpawner` |
| ADR-0008 NPC Spawner Authority | ✅ **Source of Truth** | Drives this GDD sync — flagged sync in own Status header |

**No ADR superseded.** Sync is GDD-side: 5 text locations + 1 status-header bump.

---

## Resolution — 6 GDD edits applied

| # | Location | Action |
|---|---|---|
| 1 | L3 Status header | Appended 2026-04-26 ADR-0008 sync note + cited change-impact doc + bumped Last Updated to 2026-04-26 |
| 2 | L27 Core Rule R5 | Rewrote: "shared 15 Hz Heartbeat accumulator owned by ServerTickAccumulator" → "own dedicated `RunService.Heartbeat:Connect` connection per ADR-0008 §Cadence Exemption + ADR-0002 §Related Decisions non-gameplay-tick exemption"; appended stale-terminology note explaining what was superseded |
| 3 | L70 §Interactions table | Replaced "ServerTickAccumulator (new shared module) — Subscribe — `Accumulator:subscribe(fn)`" row with "RunService.Heartbeat (Roblox) — Direct connect — own connection per ADR-0008 §Cadence Exemption" row |
| 4 | L243 §Dependencies §Upstream | Replaced "ServerTickAccumulator (new shared module) — Not yet designed" row with two rows: ADR-0008 NPC Spawner Authority (Proposed 2026-04-26) + ADR-0002 TickOrchestrator (Accepted 2026-04-26 — excludes NPCSpawner from Phase 1-9) |
| 5 | AC-05 (L321) | Renamed "Shared accumulator usage (no independent tick)" → "Own Heartbeat connection (no competing accumulator)"; rewrote test logic: injected mock `Accumulator:subscribe` → injected mock `RunServiceShim.Heartbeat:Connect` with 4 verification clauses (1 connect after createAll, 1 disconnect at destroyAll, 0 sleep loops, NOT subscribed to TickOrchestrator) |
| 6 | §DI requirements (L375) | Replaced "`Accumulator` with method `subscribe(fn) → disconnect`" → "`RunServiceShim` exposing `Heartbeat:Connect(fn) -> { Disconnect: () -> () }`"; revision note inline |

---

## Files Modified

1. `design/gdd/npc-spawner.md` (6 edits — status header + R5 + §Interactions + §Dependencies + AC-05 + §DI requirements)
2. `docs/architecture/change-impact-2026-04-26-npc-cadence.md` (this doc, new)

---

## Validation

```bash
$ rg 'ServerTickAccumulator|Accumulator:subscribe|injected mock.*Accumulator' design/gdd/npc-spawner.md
# Only intentional historical-context refs remain:
#   L27: "Stale terminology note: prior text referenced..."
#   L243: "Replaces prior 'ServerTickAccumulator (new shared module)' placeholder"
```

Live functional refs to "ServerTickAccumulator" / "Accumulator:subscribe": **0**.
Historical context refs (intentional, framed as "stale" / "replaces prior"): **2**.

---

## Verdict: COMPLETE

Sync clean. NPC Spawner GDD now consistent with ADR-0008 §Cadence Exemption + ADR-0002 §Related Decisions L289. ADR-0008 ready for Proposed → Accepted transition.

---

## Follow-Up Actions

1. **Flip ADR-0008 Proposed → Accepted** — surgical Status-header edit (this GDD sync was the only outstanding amendment dependency)
2. **Re-run `/architecture-review`** in fresh session to verify C2 conflict status moves from 🔴 → ✅ (resolved)
3. **`/architecture-decision msm-roundlifecycle-split`** — ADR-0005 (largest gap cluster, 35 TRs)

---

## Related Decisions

- ADR-0008 NPC Spawner Authority — drove this sync
- ADR-0002 TickOrchestrator — established the non-gameplay-tick exemption pattern
- `/architecture-review` 2026-04-26 — surfaced the C2 conflict that motivated ADR-0008 + this sync
- Earlier change-impact `docs/architecture/change-impact-2026-04-26-rig-defer.md` — sibling propagation pass for ADR-0001 amendment
