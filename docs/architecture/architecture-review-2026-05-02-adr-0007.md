# Architecture Review — ADR-0007 Client Rendering Strategy

> **Date**: 2026-05-02
> **Mode**: focused single-ADR validation (`/architecture-review @docs/architecture/adr-0007-client-rendering-strategy.md`)
> **Engine**: Roblox (engine-ref pinned 2026-04-20)
> **Verdict**: 🔴 **FAIL** — six blocking conflicts with referenced GDDs and ADR-0003 instance cap; cannot promote to Accepted as written.

---

## Inputs Loaded

- ADR-0007 Client Rendering Strategy (Proposed 2026-05-02)
- ADR-0001 Crowd Replication Strategy (Accepted 2026-04-26, amended ×3)
- ADR-0003 Performance Budget (Proposed)
- ADR-0006 Module Placement Rules (Proposed)
- ADR-0008 NPC Spawner Authority (Proposed) — pool pre-alloc pattern reference
- GDD `design/gdd/follower-entity.md` (In Review, 26 ACs)
- GDD `design/gdd/follower-lod-manager.md` (In Review, 21 ACs)
- `docs/architecture/tr-registry.yaml` — TR-fe-001..020 + TR-lod-001..013
- `docs/architecture/requirements-traceability.md` (2026-04-26 baseline)

---

## Coverage Delta

| System | Pre-A7 Status | A7 closes | Net after A7 |
|---|---|---|---|
| follower-entity | 3 ✅ / 2 ⚠️ / 15 ❌ | up to 11 (4 are design-internal — TR-fe-005/007/010/017) | ~14 ✅ / 2 ⚠️ / 4 ❌ |
| follower-lod-manager | 4 ✅ / 2 ⚠️ / 7 ❌ | up to 5 (TR-lod-002/003/005/010/011/013) | ~9 ✅ / 2 ⚠️ / 2 ❌ |

ADR-0007 §Status claim "closes 15 ADR-gap TRs on follower-entity epic" is overstated by 4. Net coverage gain is real but not blocking.

---

## Cross-ADR / GDD Conflicts

### 🔴 C1. Tier numbering scheme (BLOCKING)

| Source | Numbering |
|---|---|
| ADR-0007 §Key Interfaces, §Tier table | `1 / 2 / 3` |
| GDD follower-entity §F5 | `0 / 1 / 2 / CULL` |
| GDD follower-lod-manager §F2 + AC-LOD-04/06/17 | `0 / 1 / 2 / CULL` (CULL=3) |
| TR-fe-015, TR-lod-008 | `Tier 0 / 1 / 2 boundaries: 20/40/100m` |

**Impact**: LOD Manager (sole `setLOD` caller) dispatches `0..2 + CULL`; FollowerEntity expects `1|2|3`. Type-check failure on every close-tier dispatch.

**Resolution**: change ADR-0007 to `setLOD(crowdId, tier: 0 | 1 | 2)`. Treat CULL as `setPoolSize(crowdId, 0)` (matches LOD GDD §F4 + AC-LOD-10).

### 🔴 C2. Medium-tier render cap merge (BLOCKING)

| Source | Tier 1 (20-40m) cap |
|---|---|
| ADR-0007 §Tier table | "15 (own + rival merged)" |
| LOD GDD §F3 cap table | `[1] = { own=15, rival=15 }` (separate) |
| LOD GDD AC-LOD-06 | verifies tier-1 own=15, rival=15 |
| TR-fe-015, TR-lod-009 | `15/15` per side |

**Impact**: ADR-0007 halves tier-1 visual density (15 total vs 30 total). Rival-readability AC-LOD-20 jeopardised (Pillar 4).

**Resolution**: rewrite cap to "15 own + 15 rival per crowd; LOD GDD §F3 is sole owner".

### 🔴 C3. Pool pre-alloc size + counting unit (BLOCKING)

| Source | Pool size |
|---|---|
| ADR-0007 §Pool Allocation | `MAX_TOTAL_PARTS = 12 × (80+30+15) = 1500` Parts via 60×25 batches |
| GDD follower-entity §Pool tuning | 460 LOD-0 Body + 460 Hat + 100 LOD-1 + 60 LOD-2 billboard; rationale `1×80 + 7×30 + 120 peel + 50 overlap = 460`; ceiling `8×80 = 640` |
| TR-fe-003 | codifies GDD value |

**Compounds with C4**: ADR-0007 counts entities-as-Parts; each entity = 2 Parts (Body+Hat). 1500 entities = 3000 actual Parts. Memory calc `1500 × 30 KB = 45 MB` understates ~2× → ~90 MB → blows ADR-0003 50 MB client envelope.

**Resolution**: rewrite §Pool Allocation Strategy to TR-fe-003 numbers (460 Body + 460 Hat + 100 LOD-1 + 60 LOD-2 billboard) with 8-crowd ceiling. Adjust batch math accordingly (~37 batches × 25 Body + matching Hat batches).

### 🔴 C4. Worst-case rendered Parts violates ADR-0003 instance cap (BLOCKING)

| Source | Worst-case rendered Parts |
|---|---|
| ADR-0007 §Verification A | "12 crowds = 1×80 + 11×30 + 12×15 + 0 = ~590 Parts" |
| ADR-0003 §Worst-Case Instance Caps | `≤ 150 Parts` rendered follower (own-close 80 + rival-close 30 + 20-40m 15 + billboards) |
| ADR-0001 §Decision | "Rival close (≤20m): max 30 rendered" — single cap, not per-rival |

**Impact**: ADR-0007 silently re-interprets ADR-0001 rival-close 30 as per-rival, blowing ADR-0003 instance cap by ~4×. Budget breach.

**Resolution**: correct §Verification A to `80 own-close + 30 rival-close (across all rivals) + 15 medium-own + 15 medium-rival + 1 billboard/crowd ≈ 150 Parts` matching ADR-0003. If true intent is per-rival, raise via ADR-0003 amendment first.

### 🔴 C5. Peel trigger source — new reliable RE vs broadcast-delta (BLOCKING)

| Source | Peel trigger |
|---|---|
| ADR-0007 §Architecture Diagram + §Key Interfaces | CCR server fires reliable RemoteEvent → FollowerEntity client subscribes → dispatches `startPeel` |
| GDD follower-entity §CCR + F6 | Client observes 15 Hz broadcast count delta; CCR-client calls `FollowerEntity.startPeel` directly. "n is observed directly from broadcast count delta, NOT derived" |
| ADR-0001 §Key Interfaces | 5 named reliable events; no peel-buffer event |

**Impact**: ADR-0007 introduces a reliable RE that ADR-0001 schema does not authorise. Conflicts with broadcast-delta-driven peel that GDD locks.

**Resolution (preferred)**: drop the reliable-RE path; document `startPeel` as called by CCR-client on broadcast-delta detection (matches GDD).
**Resolution (alternate)**: amend ADR-0001 §Key Interfaces to add a 6th named reliable event + amend ADR-0003 network row + amend GDD F6 simultaneously.

### 🔴 C6. Eviction-protection mechanism contradicts LOD GDD F4 (BLOCKING)

| Source | Mechanism |
|---|---|
| ADR-0007 §Eviction-protection | "shrink **deferred for one LOD tick** if `getPeelingCount > 0`" |
| LOD GDD §F4 + AC-LOD-09 | `n_effective = max(cap, getPeelingCount(crowdId))` — fires immediately, clamped upward |
| follower-entity GDD AC-25 | "eviction applies to Active + Despawning only; Peeling untouched" |
| TR-lod-005 | shrink-gated via `getPeelingCount` (clamp, not defer) |

**Impact**: ADR-0007 deferral contradicts canonical clamp formula in LOD GDD §F4. Two competing mechanisms cannot coexist.

**Resolution**: rewrite §Eviction-protection to `n_effective = max(newN, getPeelingCount(crowdId))`. Peeling subset stays untouched within same tick.

### 🟡 C7. API name drift — `snapIn` vs `spawnFromAbsorb`

ADR-0007 `snapIn(crowdId, npcLastPosition)` → GDD `spawnFromAbsorb(crowdId, worldPos)`. Rename ADR.

### 🟡 C8. Singleton-vs-orchestrator structure

| Source | Pattern |
|---|---|
| ADR-0007 | FollowerEntity = singleton; `_activePools` keyed by `crowdId`; one RenderStepped |
| GDD §Implementation Note (L134) | `CrowdManagerClient` singleton owns `{[string]: FollowerEntityClient}` map; per-crowd class instances (`FollowerEntityClient.new(crowdId, janitor)`); CrowdManagerClient drives one RenderStepped |

**Resolution**: ADR-0007 must honor per-crowd class pattern (CrowdManagerClient orchestrator + per-crowd FollowerEntityClient). Per-crowd Janitor lifecycle is essential for `CrowdEliminated` cleanup.

### 🟡 C9. Undocumented API addition — `fadeOutCrowd`

ADR-0007 adds public `fadeOutCrowd(crowdId)`. GDD §write-access-contract has no such mutator (per-frame nil-check despawn path is sufficient). Drop from ADR.

---

## ADR Dependency Order

```
Foundation (Accepted):
  1. ADR-0001 Crowd Replication Strategy (Accepted 2026-04-26)

Proposed deps (must Accept before A7):
  2. ADR-0003 Performance Budget — A7 cites budget allocation
  3. ADR-0006 Module Placement Rules — A7 cites Source Tree path
  4. ADR-0008 NPC Spawner Authority — A7 cites task.defer pool pattern + StreamingEnabled rule

Then:
  5. ADR-0007 Client Rendering Strategy — blocked on 0003 + 0006 reaching Accepted
```

No dependency cycle.

---

## Engine Compatibility Audit

✅ **Post-cutoff APIs**: ADR-0007 declares "None" — verified. `RunService.RenderStepped`, `CFrame`, `WeldConstraint`, `BillboardGui`, `task.defer` are all pre-cutoff stable.
✅ **Deprecated APIs**: none referenced.
⚠️ **`Workspace.StreamingEnabled = false`**: cited "per ADR-0008 §Edge Cases" — verify ADR-0008 actually states this (not done in this review).
✅ **`BillboardGui.MaxDistance = 105`** buffer past LOD CULL boundary — sound.

---

## Design Revision Flags (Architecture → GDD Feedback)

**GDD follower-entity §134 (Implementation Note path)**: states `Crowd/FollowerEntityClient.luau`. Stale per ADR-0006 §Source Tree Map L152 = `FollowerEntity/`. Same line locks the CrowdManagerClient orchestrator pattern (relevant to C8).

→ **Action after C8 resolves toward CrowdManagerClient orchestrator**: update GDD §134 path string `Crowd/` → `FollowerEntity/`. No structure change required.

LOD GDD status `In Review` despite Batch 3 amend — cosmetic; no flag.

---

## Blocking Issues (must resolve before PASS)

1. **C1** — fix tier numbering to 0/1/2 (CULL via setPoolSize(0))
2. **C2** — fix tier-1 cap to "15 own + 15 rival per crowd"
3. **C3** — rewrite §Pool Allocation Strategy to TR-fe-003 (460/460/100/60; 8-crowd ceiling)
4. **C4** — correct §Verification A worst-case Parts arithmetic to ≈150 (matches ADR-0003)
5. **C5** — drop new reliable peel-buffer RE OR amend ADR-0001 schema
6. **C6** — rewrite eviction-protection to `n_effective = max(cap, peelCount)`

## Non-blocking Drift (fix in same revision)

7. **C7** — rename `snapIn` → `spawnFromAbsorb`
8. **C8** — adopt CrowdManagerClient orchestrator + per-crowd FollowerEntityClient pattern
9. **C9** — drop `fadeOutCrowd` mutator

---

## Required Follow-ups

- Patch ADR-0007 with C1-C9 fixes; re-run `/architecture-review @docs/architecture/adr-0007-client-rendering-strategy.md` to confirm PASS
- After ADR-0003 + ADR-0006 reach Accepted, ADR-0007 may promote
- `requirements-traceability.md` does not need a registry edit; coverage delta is computed at next full review
- ADR-0001 Batch 3 already locks tier-2 = 1 billboard per crowd; no further amend

---

## History

| Date | Verdict | Notes |
|---|---|---|
| 2026-05-02 | FAIL | 6 blocking + 3 drift conflicts; ADR-0007 amendment required |
| 2026-05-03 | PASS | Second pass — all 9 conflicts resolved; one non-blocking GDD path-string flag remains |

---

## Second Pass — 2026-05-03 — ✅ PASS

**Mode**: re-validate ADR-0007 against the 9 conflicts logged 2026-05-02 (`/architecture-review @docs/architecture/adr-0007-client-rendering-strategy.md`).

### Conflict Resolution Verification

| ID | Prior finding | Resolution in current ADR | Verified at |
|---|---|---|---|
| C1 | tier numbering 1/2/3 vs GDD 0/1/2/CULL | `setLOD(self, tier: 0 \| 1 \| 2)`; CULL via `setPoolSize(crowdId, 0)`; tier table re-numbered | ADR-0007 lines 149-151, 180-187 |
| C2 | tier-1 cap "15 (own+rival merged)" | "15 / 15 (own + rival counted **separately** per LOD GDD §F3)" | line 185 |
| C3 | pool prealloc 1500 entities (entities-as-Parts) | 460 Body + 460 Hat + 100 LOD-1 + 60 LOD-2 per TR-fe-003; 8-crowd ceiling 640; ~33 MB total | lines 60, 238-247 |
| C4 | worst-case 590 Parts (per-rival 30) | "≈ **150 rendered Parts** client-side worst case (matches ADR-0003 §Worst-Case Instance Caps row "≤ 150 Parts")" | line 25 |
| C5 | new reliable peel-buffer RE | broadcast-delta path: `CrowdCollisionResolutionClient` observes 15 Hz `CrowdStateClient.CountChanged` → calls `startPeel` directly. "No new server reliable RemoteEvent introduced" | lines 33, 77, 158-160, 327 |
| C6 | eviction `defer 0.1s` if peelCount>0 | `n_effective = max(rawCap, getPeelingCount(crowdId))` clamp formula per LOD GDD §F4; defensive re-clamp on `setPoolSize` entry; Peeling subset immune within same tick | lines 152, 171-176 |
| C7 | `snapIn` API name | `spawnFromAbsorb(self, npcLastPosition: Vector3)` | line 164 |
| C8 | flat singleton + `_activePools` | `CrowdManagerClient` singleton orchestrator owns `{[crowdId]: FollowerEntityClient}` per-crowd class instances + per-crowd Janitor; single RenderStepped iterates all | lines 132-144, 198-213 |
| C9 | public `fadeOutCrowd` mutator | dropped — per-frame nil-check on `CrowdStateClient.get(crowdId)` is sole despawn path | lines 140, 318 |

All 9 conflicts resolved. Status history block on ADR-0007 (line 9) records the C1-C9 fix list inline.

### Cross-ADR Reverification

| Check | Result |
|---|---|
| ADR-0001 §Key Interfaces still 5 reliable events (CrowdCreated/Destroyed/Eliminated/CountClamped/RelicChanged) | ✅ schema preserved (no 6th event added per C5 resolution) |
| ADR-0008 §Edge Cases cites `Workspace.StreamingEnabled = false` | ✅ verified line 62 |
| ADR-0003 instance cap "≤ 150 Parts rendered follower" | ✅ ADR-0007 §Verification A worst-case now matches |
| ADR-0006 §Source Tree Map path `ReplicatedStorage/Source/FollowerEntity/Client.luau` | ✅ ADR-0007 §Key Interfaces honors path |

### Engine Compatibility

Unchanged from first pass.
- ✅ Post-cutoff APIs declared: None (all surfaces pre-May-2025)
- ✅ Deprecated APIs: none referenced
- ✅ `BillboardGui.MaxDistance = 105` cull-buffer rule retained

### Residual GDD Revision Flag (non-blocking)

`design/gdd/follower-entity.md:134` Implementation Note states:

> "...lives at `src/ReplicatedStorage/Source/Crowd/FollowerEntityClient.luau` as a per-crowd class. Coordinator singleton `CrowdManagerClient` owns `{[string]: FollowerEntityClient.ClassType}` map..."

Structure (per-crowd class + CrowdManagerClient orchestrator) is correct + matches ADR-0007 C8 resolution. Only the path string `Crowd/FollowerEntityClient.luau` is stale — ADR-0006 §Source Tree Map + ADR-0007 line 127-128 canonicalise as:

- `ReplicatedStorage/Source/FollowerEntity/CrowdManagerClient.luau` (orchestrator)
- `ReplicatedStorage/Source/FollowerEntity/Client.luau` (per-crowd `FollowerEntityClient`)

**Action**: GDD §134 path-string-only revision (no structural change). Apply alongside ADR-0006 promotion.

### Promotion Gate (acknowledged in ADR-0007 §Status)

ADR-0007 cannot promote `Proposed` → `Accepted` until **ADR-0003 + ADR-0006** reach Accepted. Both remain Proposed. Not a blocker for this review's verdict — ADR-0007 itself is internally + externally consistent.

### Coverage Delta (informational; full RTM rebuild deferred)

Pre-A7 baseline (per `requirements-traceability.md` 2026-04-26):
- `follower-entity`: 3 ✅ / 2 ⚠️ / 15 ❌
- `follower-lod-manager`: 4 ✅ / 2 ⚠️ / 7 ❌

ADR-0007 §Status claims "closes 15/20 follower-entity TRs" — net real coverage gain ~11 (4 are design-internal: TR-fe-005/007/010/017). Still material; matches first-pass calc.

---

## Verdict: ✅ **PASS**

All 9 conflicts resolved. ADR-0007 is internally consistent + aligned with ADR-0001 / ADR-0003 / ADR-0006 / ADR-0008 + with follower-entity / follower-lod-manager GDDs as written. Engine-compat clean.

## Required Follow-ups (non-blocking)

1. Patch GDD `design/gdd/follower-entity.md:134` path string `Crowd/FollowerEntityClient.luau` → `FollowerEntity/Client.luau` + add `CrowdManagerClient.luau` line per ADR-0006 §Source Tree Map (path-string-only, no structural change).
2. Promote ADR-0003 (Performance Budget) + ADR-0006 (Module Placement Rules) `Proposed` → `Accepted`. After both Accept, promote ADR-0007 → Accepted.
3. After ADR-0007 Accepts: `/create-stories follower-entity` may proceed (Sprint 4 implementation start).
4. Re-run `/architecture-review` (full mode) after ADR-0007 Accepts to refresh `requirements-traceability.md` coverage matrix + tr-registry coverage stats.
