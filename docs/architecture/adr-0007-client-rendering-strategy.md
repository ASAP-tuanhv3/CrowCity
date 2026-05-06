# ADR-0007: Client Rendering Strategy (FollowerEntity execution + LOD authority split)

## Status

**Accepted 2026-05-04** — closes ~11 ADR-gap TRs on `follower-entity` epic + ~5 on `follower-lod-manager` epic per `requirements-traceability.md` 2026-04-26 (after excluding design-internal TRs). Promoted after `/architecture-review` second pass returned PASS (all 9 prior conflicts resolved); dependencies ADR-0003 + ADR-0006 already Accepted 2026-04-26.

Status history:
- 2026-05-02 — Proposed (initial)
- 2026-05-02 — amended per `/architecture-review` 2026-05-02-adr-0007 (FAIL → revised): C1 tier numbering 1/2/3 → 0/1/2 (CULL via `setPoolSize(0)`); C2 tier-1 cap merge → 15 own + 15 rival per crowd; C3 pool prealloc 1500 → 460/460/100/60 (TR-fe-003); C4 worst-case Parts 590 → 150 matching ADR-0003 instance cap; C5 peel-buffer reliable RE dropped, broadcast-delta path retained; C6 eviction-protection `defer 0.1s` → `n_effective = max(newN, peelCount)` (LOD GDD §F4 canonical); C7 `snapIn` → `spawnFromAbsorb`; C8 singleton structure → `CrowdManagerClient` orchestrator + per-crowd `FollowerEntityClient.new(crowdId, janitor)`; C9 `fadeOutCrowd` dropped (per-frame nil-check is sole despawn path)
- **2026-05-04 — ACCEPTED** (`/architecture-review @adr-0007` second pass = PASS; ADR-0003 + ADR-0006 already Accepted 2026-04-26; GDD `follower-entity.md:134` path-string drift patched same day)

## Date

2026-05-02 (initial), 2026-05-04 (Accepted)

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Roblox (continuously-updated live service; engine-ref pinned 2026-04-20) |
| **Domain** | Rendering (client-side) |
| **Knowledge Risk** | MEDIUM — Roblox ships API changes monthly; LLM cutoff May 2025 |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md`, ADR-0001, ADR-0003, ADR-0006, art-bible §5 + §8.6, follower-entity GDD §C/F1-F9, follower-lod-manager GDD §F1-F3 |
| **Post-Cutoff APIs Used** | None — `RunService.RenderStepped`, `CFrame`, `WeldConstraint`, `BillboardGui`, `task.defer` are all pre-cutoff stable surfaces. `Workspace.StreamingEnabled = false` per ADR-0008 §Edge Cases applies. |
| **Verification Required** | (A) RenderStepped per-frame budget ≤1.5 ms desktop / ≤2.5 ms mobile @ ADR-0003 worst-case rendered count: 80 own-close + 30 rival-close (across all rivals per ADR-0001 single cap) + 15 medium-own + 15 medium-rival + 1 billboard/crowd ≈ **150 rendered Parts** client-side worst case (matches ADR-0003 §Worst-Case Instance Caps row "≤ 150 Parts"). Real-device soak deferred to MVP-Integration-1 sprint per ADR-0003 §Validation Sprint Plan. (B) Eviction protection: integration test confirms `setPoolSize(crowdId, newN)` clamps `n_effective = max(newN, getPeelingCount(crowdId))` per LOD GDD §F4 — Peeling subset never evicted within same tick. (C) Billboard impostor swap-in completes within 1 LOD-tick of distance crossing 40 m threshold (no flicker). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Crowd Replication Strategy — establishes UREvent broadcast schema, no-Humanoid rule, 80/30/15/1 LOD caps), ADR-0003 (Performance Budget — locks 1.5/2.5 ms desktop/mobile per-frame budget for `follower-entity-client-sim`), ADR-0006 (Module Placement — locks `ReplicatedStorage/Source/FollowerEntity/Client.luau` path) |
| **Enables** | `production/epics/follower-entity` epic stories (closes 15/20 TR ADR gap); `production/epics/crowd-collision-resolution` peel-buffer consumer contract; future `production/epics/follower-lod-manager` (Presentation epic, deferred) |
| **Blocks** | Cannot start FollowerEntity stories beyond TR-fe-001/015/020 until this ADR is Accepted. CrowdCollisionResolution-client peel detection (broadcast-delta-driven) is the producer; FollowerEntityClient peel consumption is the blocked half. No new server reliable RemoteEvent introduced. |
| **Ordering Note** | This ADR formalises sibling-system contracts already implied by ADR-0001 (FollowerEntity = execution; FollowerLODManager = decisions). Both client modules ship together; FollowerEntity epic implements first, FollowerLODManager epic implements second (consumer). |

---

## Context

### Problem Statement

`design/gdd/follower-entity.md` and `design/gdd/follower-lod-manager.md` describe the client-side visual layer that turns CSM's per-crowd `count` into the "thousands of cheerful civilians" that make the snowball visible. ADR-0001 locked the broadcast contract (UREvent, 30 B/crowd, 15 Hz) and the policy decisions (no Humanoid, LOD tiers 0-20/20-40/40-100 m, render caps 80/30 close + 15 medium + 1 billboard impostor far). However, **15 of 20 follower-entity TRs and 20 of 22 follower-lod-manager TRs remain ADR-untraced** (per `requirements-traceability.md` 2026-04-26):

- Boids flocking integration with `RunService.RenderStepped`
- LOD authority split (decisions vs execution) between two sibling modules
- Pool ownership + creation/destruction lifecycle
- Eviction priority during pool shrink (mid-peel protection contract)
- Billboard impostor render path (BillboardGui vs simplified Part)
- Per-frame budget allocation between boids math + CFrame writes + LOD swap
- Engine-API discipline (which Roblox APIs are permitted; which are forbidden — e.g., no `Humanoid:MoveTo`, no `BodyMovers`, no per-frame `Instance.new()`)

Without an architectural lock on these contracts, two independent client modules (FollowerEntity + FollowerLODManager) will be implemented with overlapping concerns, contradictory pool ownership, and likely violation of the per-frame budget.

### Constraints

- **Engine**: Roblox — no custom shaders. Renderer is fixed; performance comes from instance count + Part topology + render-step CPU.
- **Platform reach**: PC (desktop Studio + Player), Mobile (iOS / Android), Console (Xbox). Min-spec mobile (iPhone SE 2020-class) is the binding budget per ADR-0003 §Mobile Targets.
- **Per-frame budget**: ADR-0003 allocates 1.5 ms desktop / 2.5 ms mobile to `follower-entity-client-sim` (registry: `system: follower-entity-client-sim`). Boids math + CFrame writes + LOD-tier swaps must all fit within this budget.
- **Anti-P2W (Pillar 4 + ADR-0004)**: Cosmetic systems must not influence gameplay state. FollowerEntity is permitted to read CSM via `CrowdStateClient` mirror, NEVER write back to server.
- **Pool memory**: pre-allocated pool sized per `design/gdd/follower-entity.md` §Pool Tuning + TR-fe-003: 460 LOD-0 Body + 460 Hat + 100 LOD-1 simplified + 60 LOD-2 billboard slots (rationale: `1×80 own-close + 7×30 rival-close + 120 concurrent peeling + 50 despawn overlap = 460`; 8-crowd × 80-own ceiling = 640 absolute upper bound). 2-Part rig (Body MeshPart + Hat MeshPart with WeldConstraint per `humanoid_on_followers` registry entry). Memory: 460 Body + 460 Hat ≈ 920 active Parts × ~30 KB ≈ 28 MB; 100 LOD-1 + 60 LOD-2 ≈ 5 MB. Total ≈ 33 MB — within ADR-0003 §Reserve 50 MB client envelope.

### Requirements

- Must integrate with `CrowdStateClient` mirror (consumes broadcast at 15 Hz; no direct UREvent subscription in FollowerEntity)
- Must split LOD decisions (10 Hz, FollowerLODManager) from LOD execution (per-frame, FollowerEntity)
- Must protect mid-peel followers from eviction during pool shrink
- Must support billboard impostor swap-in for Tier 2 (40-100 m) without flicker
- Must use `RenderStepped` (not `Heartbeat`) for boids + CFrame writes — visual smoothness requires per-frame cadence, not 15 Hz
- Must NOT use Humanoid, BodyMovers, MoveTo, AlignPosition, AlignOrientation, Tween-on-CFrame, or any physics-driven movement
- Must NOT register a `Heartbeat:Connect` (audit-no-competing-heartbeat gate; only TickOrchestrator + ProfileStore + BeamBetween allowed)
- Must NOT call `Instance.new()` per frame (use pre-allocated pool with `task.defer` chunked allocation per follow-the-NPC-Spawner pattern from ADR-0008)

---

## Decision

**Three-module split with strict authority separation.** FollowerEntity owns execution (per-frame boids + CFrame writes + pool granting). FollowerLODManager owns decisions (10 Hz distance check + tier selection + cap arbitration). CrowdStateClient owns data (broadcast mirror; both other modules consume read-only). Tier numbering is `0 / 1 / 2 / CULL` per LOD GDD §F2 + GDD follower-entity §F5 (CULL handled via `setPoolSize(crowdId, 0)`, not a fourth tier value). Boids loop runs at `RenderStepped` cadence; LOD decisions run at 0.1 s `task.delay`-based ticker (NOT `Heartbeat:Connect` per ADR-0002). Pool is pre-allocated at boot via `task.defer` chunked batches (25 Parts/batch). Per-frame `Instance.new` is forbidden. Billboard impostor (Tier 2 = 40-100 m) is a single `BillboardGui` per crowd with image-based hue tint; transitions to/from impostor via cross-fade on `Transparency`. **Orchestrator pattern**: `CrowdManagerClient` singleton owns `{[crowdId]: FollowerEntityClient}` per-crowd class instances + drives a single `RenderStepped` connection iterating all active crowds (matches `design/gdd/follower-entity.md` §Implementation Note); per-crowd `Janitor` enables clean teardown on `CrowdEliminated`. **Peel trigger**: client-side broadcast-delta detection — `CrowdCollisionResolutionClient` observes 15 Hz `CrowdStateClient.CountChanged` and calls `FollowerEntityClient.startPeel` directly per follower-entity GDD §CCR + §F6. No new server reliable RemoteEvent introduced (ADR-0001 §Key Interfaces 5-event schema preserved).

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│ CLIENT (rendering pipeline)                                      │
│                                                                  │
│  ┌─────────────────────────┐                                     │
│  │ CrowdStateClient        │ ← UREvent CrowdStateBroadcast       │
│  │   (mirror, ADR-0001)    │ ← reliable CrowdCreated/Destroyed   │
│  │                         │ ← reliable CrowdEliminated          │
│  │  per-crowd record       │ ← reliable CrowdCountClamped        │
│  │                         │ ← reliable CrowdRelicChanged        │
│  │                         │   { tick, position, radius, count,  │
│  │                         │     hue, state, activeRelics }      │
│  │  CountChanged           │  signal → CCR-client peel detect    │
│  └─────┬───────┬───────────┘                                     │
│        │       │      (read-only)                                │
│        ▼       ▼                                                 │
│  ┌─────────────┐  ┌──────────────────────────────────┐           │
│  │ FollowerLOD │  │ CrowdManagerClient (orchestrator) │           │
│  │  Manager    │  │   ┌─────────────────────────────┐ │           │
│  │             │  │   │ FollowerEntityClient[crowd] │ │           │
│  │  10 Hz      │  │   │   per-crowd class +Janitor  │ │           │
│  │  decision   │  │   │   Tier 0 (≤20m): 80/30      │ │           │
│  │  loop       │  │   │   Tier 1 (20-40m): 15 own + │ │           │
│  │ (task.delay │  │   │      15 rival per crowd     │ │           │
│  │  ticker)    │  │   │   Tier 2 (40-100m): 1 GUI   │ │           │
│  │             │  │   │      billboard impostor     │ │           │
│  │             │  │   │   CULL: setPoolSize(0)      │ │           │
│  │ →setLOD(0|1│2)─►   getPeelingCount()             │ │           │
│  │ →setPoolSize ─►│   startPeel(ownId,rivId,n)      │ ◄─CCR-client│
│  │   (clamps   │  │   spawnFromAbsorb(crowdId,pos)  │ ◄─Absorb-cli│
│  │    via      │  │ └────────────────────────────┘  │           │
│  │    max(n,   │  │ Single RenderStepped iterates    │           │
│  │    peelN))  │  │   all crowds: F1-F4 boids,       │           │
│  │             │  │   CFrame writes, F8 bob, F9 sway │           │
│  │             │  │ Pool boot: task.defer 25/batch   │           │
│  │             │  │   460 Body + 460 Hat + 100 LOD-1 │           │
│  │             │  │   + 60 LOD-2 billboard slots     │           │
│  └─────────────┘  └──────────────────────────────────┘           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```lua
-- Orchestrator path: ReplicatedStorage/Source/FollowerEntity/CrowdManagerClient.luau
-- Per-crowd class: ReplicatedStorage/Source/FollowerEntity/Client.luau (FollowerEntityClient)
-- (per ADR-0006 §Source Tree Map; module placement Proposed)
--!strict

-- CrowdManagerClient: singleton orchestrator (one per client, bootstrapped from start.client.luau)
export type CrowdManagerClient = {
    -- Bootstrap (start.client.luau call site)
    init: (self: CrowdManagerClient) -> (),  -- pre-allocates pools via task.defer 25/batch
    start: (self: CrowdManagerClient) -> (), -- begins single RenderStepped loop iterating crowds
    stop: (self: CrowdManagerClient) -> (),  -- disconnects RenderStepped; defers per-crowd teardown

    -- Crowd lifecycle (CrowdStateClient.CrowdCreated / CrowdEliminated subscribers)
    --   Internal: constructs FollowerEntityClient.new(crowdId, janitor) on CrowdCreated;
    --   Per-frame nil-check on CrowdStateClient.get(crowdId) drives despawn (no public fadeOutCrowd).

    -- Read accessors for sibling modules:
    getCrowdClient: (self: CrowdManagerClient, crowdId: string) -> FollowerEntityClient?,
}

-- FollowerEntityClient: per-crowd class (constructed by CrowdManagerClient)
export type FollowerEntityClient = {
    -- LOD authority split: FollowerLODManager calls these (one-way per crowd)
    setLOD: (self: FollowerEntityClient, tier: 0 | 1 | 2) -> (),
        -- CULL handled by setPoolSize(0); not a separate tier value
    setPoolSize: (self: FollowerEntityClient, n: number) -> (),
        -- LOD Manager precomputes n_effective = max(rawCap, getPeelingCount()) per LOD GDD §F4
        -- Implementation MUST clamp n_effective on entry as a defence against missed precompute

    -- Read-only query (LOD Manager + CCR-client consume; FollowerEntity does not write)
    getPeelingCount: (self: FollowerEntityClient) -> number,

    -- Peel emission (CrowdCollisionResolutionClient observes 15 Hz CrowdStateClient.CountChanged
    -- and calls startPeel directly when own.count decreases ∧ rival.count increases by N;
    -- no server reliable RemoteEvent introduced — preserves ADR-0001 5-event schema)
    startPeel: (self: FollowerEntityClient, rivalCrowdId: string, n: number) -> (),

    -- Spawn on absorb (Absorb-client subscribes to reliable Absorbed RemoteEvent and calls this)
    spawnFromAbsorb: (self: FollowerEntityClient, npcLastPosition: Vector3) -> (),

    -- Internal teardown (CrowdManagerClient owns Janitor lifecycle; do not call externally)
    destroy: (self: FollowerEntityClient) -> (),
}
```

**Eviction-protection contract** (mandatory; sibling-module invariant per LOD GDD §F4 + AC-LOD-09):
- LOD Manager computes `n_effective = max(rawCap, getPeelingCount(crowdId))` BEFORE calling `setPoolSize` on shrink
- FollowerEntity `setPoolSize(n)` defensively re-clamps on entry: `actualN = max(n, getPeelingCount())` to guard against a buggy caller
- Eviction targets `Active` + `Despawning` followers only; `Peeling` subset is held immune (per `_peelingFollowers: {[Part]: PeelState}` internal set) within the same tick — no deferral, no retry
- Peel completion (transit reaches rival center) reduces `getPeelingCount` naturally; LOD Manager's next 0.1 s tick refines `n_effective` downward
- This is the **one contract the two sibling systems cannot break** (per `follower-lod-manager.md` Overview)

### LOD Tier Render Specs

Tier numbering matches `design/gdd/follower-entity.md` §F5 + `design/gdd/follower-lod-manager.md` §F2 (sole owner of cap table per Batch 3 declaration). CULL is signalled by `setPoolSize(crowdId, 0)`, not a fourth tier value.

| Tier | Camera Distance | Cap (own / rival, per crowd) | Rig | Per-Part Triangle Budget | Notes |
|---|---|---|---|---|---|
| 0 (close) | 0 - 20 m | 80 / 30 | 2-Part Body+Hat (per `humanoid_on_followers` registry) | ≤400 tri total | Full procedural walk-bob F8 + micro-sway F9 |
| 1 (medium) | 20 - 40 m | 15 / 15 (own + rival counted **separately** per LOD GDD §F3) | 1-Part simplified primitive (Body only; Hat fused) | ≤100 tri | Walk-bob suppressed; CFrame-only flock |
| 2 (far) | 40 - 100 m | 1 / 1 — single `BillboardGui` impostor per crowd | `BillboardGui` with `ImageLabel` (color-tinted to crowd hue) | N/A (image) | NO followers rendered; one impostor "stands in" for all of them. Sole owner of "1 billboard per crowd" rule: LOD GDD §F3. |
| CULL (signal via `setPoolSize(0)`) | > 100 m | 0 | none | none | Pool entries returned to inactive set |

Mobile cap multiplier (`MOBILE_CAP_MULTIPLIER = 0.5`) applies to Tier 0 only per LOD GDD §F3 + AC-LOD-07. Tier 1 (15/15) and Tier 2 (1 billboard) are platform-invariant.

LOD swaps are atomic per-Part (no half-tier states). FollowerLODManager pushes `setLOD(crowdId, tier)` once per crowd per 0.1 s tick when tier changes; `setLOD` is dispatched **before** `setPoolSize` on same-tick tier+cap change (per LOD GDD AC-LOD-18 + TR-lod-010). FollowerEntity executes the swap on next RenderStepped frame.

### Boids Loop Discipline (RenderStepped)

```lua
-- Pseudocode (not literal source — actual Luau implementation per /create-stories).
-- Owned by CrowdManagerClient (singleton), iterating its per-crowd FollowerEntityClient instances.
RunService.RenderStepped:Connect(function(deltaTime: number)
    local startClock = os.clock()  -- budget watchdog
    for crowdId, crowdClient in self._crowds do
        -- F1-F4 boids: separation + cohesion + follow-leader → final velocity
        for partIndex, part in crowdClient.activeParts do
            local v = boidsFinalVelocity(part, crowdClient, deltaTime, neighborhood)
            local newCFrame = part.CFrame + v * deltaTime
            -- F8 walk-bob offset on Y axis (Tier 0 only); F9 micro-sway X at standstill (Tier 0 only)
            if crowdClient.tier == 0 then newCFrame = newCFrame + walkBobOffset(part) end
            part.CFrame = newCFrame
        end
    end
    if (os.clock() - startClock) * 1000 > BUDGET_MS then
        -- soft warn rate-limited; do not abort frame
    end
end)
```

**Forbidden inside this loop**:
- `Instance.new()` — pool is pre-allocated; eviction returns to inactive set, not destroys
- `WaitForChild` — all dependencies cached at `init`
- `Player.Character` traversal — cache `RootPart` ref via subscription
- Yields (`task.wait`, `:Wait()`) — `RenderStepped` callback must return synchronously
- Distance math against camera — that lives in FollowerLODManager at 10 Hz
- Direct subscription to `CrowdStateBroadcast` — read via `CrowdStateClient.get(crowdId)`
- `Heartbeat:Connect` — only TickOrchestrator + ProfileStore + BeamBetween allowed (per ADR-0002 audit-no-competing-heartbeat)

### Billboard Impostor Render Path (Tier 2 = 40-100 m)

- One `BillboardGui` per crowd, parented to a single anchored Part at the crowd's authoritative position
- `BillboardGui.Size` scales with `count` (asymptotic curve to suggest crowd density without quantitative read)
- `BillboardGui.ImageLabel.ImageColor3` = crowd's signature hue (immutable, ADR-0001)
- `LightInfluence = 0` (UI element, not lit by world lighting)
- `MaxDistance = 105` — 5 stud buffer past 100 m CULL boundary so the GUI is invisible (post-Tier-2-out swap) before Roblox's distance-based cull engages, preventing visible pop at the tier edge
- Transition: Tier 1 → Tier 2 — tween Tier 1 Parts' `Transparency` 0 → 1 over 0.2 s; impostor `Transparency` tweens 1 → 0 simultaneously. Tier 2 → Tier 1 reverse. No flicker.

### Pool Allocation Strategy

Sizing is owned by `design/gdd/follower-entity.md` §Pool Tuning (TR-fe-003); ADR locks the allocation discipline only.

- **Pool sizes** (per TR-fe-003):
  - `POOL_PREALLOC_LOD0_BODY = 460` (LOD-0 Tier 0 Body MeshPart)
  - `POOL_PREALLOC_LOD0_HAT = 460` (Hat MeshPart, 1:1 with Body)
  - `POOL_PREALLOC_LOD1 = 100` (LOD-1 Tier 1 simplified primitive)
  - `POOL_PREALLOC_LOD2_BILLBOARD = 60` (Tier 2 BillboardGui impostors)
  - Rationale: `1 own × 80 + 7 rivals × 30 = 290 baseline + 120 concurrent peeling + ~50 despawn overlap = 460`. Absolute ceiling = `8 crowds × 80 own-cap = 640`.
- **Boot allocation**: `init()` runs `task.defer` chunked allocation in batches of 25 (matches NPC Spawner pattern per ADR-0008): ~37 batches Body + ~37 batches Hat + 4 batches LOD-1 + ~3 batches LOD-2 = ~80 deferred slots (~1.3 s on min-spec mobile, distributed across `Loading` UI screen). Each LOD-0 entry is a 2-Part composite (Body MeshPart + Hat MeshPart with WeldConstraint per `humanoid_on_followers` registry), parented to a hidden `Folder` in `Workspace` named `_FollowerPool`, `Anchored = true`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`, `CastShadow = false` (mobile thermal protection).
- **Active assignment**: per-crowd `setPoolSize(n)` pulls `n` entries from the inactive set, parents to the crowd's render group, applies hue + hat AssetId.
- **Active deactivation**: returns entries to the inactive set with `Transparency = 1` and `Position = Vector3.new(0, -1000, 0)` (out-of-frustum).
- **Billboard impostors**: 60-slot pool covers worst-case 8 crowds × 1 billboard (8 active) + ~50 churn headroom for tier 2 → tier 1 → tier 2 transitions; `MaxDistance = 105` per cull-buffer rule below.
- **No mid-round `Instance.new()`**. Audit-gate-eligible: `tools/audit-no-mid-round-instance-new.sh` (proposed; defer to Sprint 4 close-out).

---

## Alternatives Considered

### Alternative 1: Single-module FollowerEntity owns both LOD decisions and execution

- **Description**: Collapse FollowerLODManager into FollowerEntity. Single client module runs both 10 Hz LOD decision loop and per-frame boids loop.
- **Pros**: One module to maintain; no inter-module API surface to lock; simpler boot ordering.
- **Cons**: Violates separation of concerns (decisions ≠ execution); makes per-frame budget enforcement harder (one module's budget hides two cost sources); breaks the established sibling pattern from `follower-lod-manager.md` Overview.
- **Rejection Reason**: GDD `follower-lod-manager.md` already commits to two-module split with explicit `setLOD`/`setPoolSize`/`getPeelingCount` contract. Reverting to one module would invalidate that GDD plus require GDD-rewrite for FollowerLODManager. Two-module split also lets FollowerLODManager swap policy (e.g., camera-cone-aware caps in V1) without touching FollowerEntity execution.

### Alternative 2: Heartbeat-driven boids loop (15 Hz)

- **Description**: Run boids math at server-tick cadence (15 Hz) via `RunService.Heartbeat`, interpolate Part CFrames between ticks for visual smoothness.
- **Pros**: Boids math runs 4× less often; interpolation is cheap.
- **Cons**: (a) Forbidden by `competing_heartbeat_accumulators` registry pattern — only TickOrchestrator + ProfileStore + BeamBetween may `Heartbeat:Connect` server-side; client-side boids @ Heartbeat would still violate audit-no-competing-heartbeat spirit. (b) Interpolation introduces 1-2 frame lag in flock direction reads; perceptible at high movement speed. (c) Boids math IS the cheap part — CFrame writes are the cost driver, and those still happen per-frame regardless. (d) RenderStepped is the canonical client cadence for visual systems in Roblox; deviating without strong reason adds confusion.
- **Rejection Reason**: No real budget win; risks visual artifacts; conflicts with existing audit pattern.

### Alternative 3: Per-follower client-side `Humanoid` with `:MoveTo`

- **Description**: Use Roblox's built-in Humanoid + `:MoveTo` for follower navigation. Native pathing handles obstacles. No custom boids math.
- **Pros**: Zero custom navigation code; Roblox handles nav-mesh.
- **Cons**: Forbidden by `humanoid_on_followers` registry pattern (ADR-0001) — Humanoid carries pathfinding + physics + health overhead unsupportable at 800+ followers. Performance benchmarks done during prototype phase (`prototypes/crowd-sync/REPORT.md`) confirmed Humanoid-based followers tank mobile FPS to <20 at 80 followers/crowd. Pillar 4 anti-P2W also forbids any per-follower stat read that could be skin-derived.
- **Rejection Reason**: Already vetoed in ADR-0001; this ADR re-affirms the ban explicitly for the rendering execution layer.

---

## Consequences

### Positive

- Closes 15 ADR-gap TRs on `follower-entity` epic; 20 on `follower-lod-manager` epic (33% → ~75% coverage on these two systems post-acceptance)
- Locks the boids/RenderStepped/CFrame discipline before stories begin, preventing rework
- Makes per-frame budget enforceable (single module owns the RenderStepped callback; budget watchdog can warn on overrun)
- Sibling-system contract (eviction protection) becomes a single integration test, not an emergent property of two implementations
- Audit gate `tools/audit-no-mid-round-instance-new.sh` (proposed) becomes mechanically enforceable

### Negative

- Two client modules to maintain (FollowerEntity + FollowerLODManager) — accepted per existing GDD commitment
- Pool pre-allocation cost @ boot ≈ 920 LOD-0 Parts (460 Body + 460 Hat) + 100 LOD-1 + 60 LOD-2 = ~1080 instances × 25/batch ≈ ~44 batches Body + ~44 batches Hat + 4 LOD-1 + ~3 LOD-2 ≈ ~95 `task.defer` slots ≈ ~1.6 s on min-spec mobile (distributed across `Loading` UI screen). No mid-round allocation cost.
- Billboard impostor render is a stylistic compromise (not the "thousands of civilians" feel at 40-100 m), but acceptable per art bible §5 LOD tiers + ADR-0001 cap of 1 impostor.

### Risks

| Risk | Mitigation |
|---|---|
| Per-frame budget overrun on min-spec mobile (>2.5 ms) | Budget watchdog warns rate-limited; soak deferred to MVP-Integration-1; if real-device soak exposes overrun, fallback is the existing `MOBILE_CAP_MULTIPLIER = 0.5` (LOD GDD §F3, Tier 0 only) plus follow-up reduction to Tier 0 own-cap 80 → 60 (registry update + ADR-0003 amend) |
| Pool starvation if max-overlap edge case exceeds prealloc | Caps + 460-slot Body pool sized for `1×80 + 7×30 + 120 peel + 50 overlap = 460`; absolute ceiling 8 crowds × 80 = 640; if exceeded, `pool.grant()` returns `nil` — marginal follower silently fails to render (warning logged once), no mid-round `Instance.new()` |
| Mid-peel eviction race (LOD shrinks pool while peel in flight) | LOD Manager precomputes `n_effective = max(rawCap, getPeelingCount())` per LOD GDD §F4; FollowerEntity defensively re-clamps on `setPoolSize` entry; Peeling subset held immune via `_peelingFollowers` set within same tick — no deferral. AC-LOD-09 + AC-25 verify. |
| Billboard impostor flicker on Tier 1↔2 boundary | Hysteresis: Tier 2 → Tier 1 requires sustained sub-40-m distance past `40 - HYSTERESIS = 39` m per LOD GDD §F2 (1-stud dead zone); Tier 1 → Tier 2 fires immediately at threshold-cross |
| `BillboardGui.MaxDistance` cull visible at the boundary | Set `MaxDistance = 105` (5 m beyond CULL threshold) so the `BillboardGui` is already invisible due to Tier-2 swap-out before Roblox engages the distance-based cull |

---

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `follower-entity.md` §C.1 | 2-Part rig (Body MeshPart + Hat MeshPart with WeldConstraint) | ADR re-affirms via `humanoid_on_followers` registry; Tier 1 spec locks 2-Part as canonical close-tier rig |
| `follower-entity.md` §F1-F4 (boids) | Separation + cohesion + follow-leader → final velocity | Locks RenderStepped cadence + budget watchdog + forbidden-API list inside boids loop |
| `follower-entity.md` §F5 (lod_tier_assignment) | tiers 0/1/2/CULL at 0-20 / 20-40 / 40-100 / >100 m | Authority split: FollowerLODManager owns F5 evaluation; FollowerEntity owns LOD execution via `setLOD(tier: 0|1|2)` (CULL = `setPoolSize(0)`) |
| `follower-entity.md` §F6-F7 (peel) | peel_N_selection + peel_transit_duration | `startPeel(rivalCrowdId, n)` API contract on per-crowd FollowerEntityClient; CCR-client observes 15 Hz broadcast count delta and is the caller (no new server reliable RE) |
| `follower-entity.md` §F8-F9 (walk-bob + sway) | Procedural Y-axis offset + standstill micro-sway X; Tier 0 only | RenderStepped boids loop applies F8 + F9 to Tier 0 Parts; Tier 1+ suppress |
| `follower-entity.md` §Pool knobs (TR-fe-003) | 460 Body + 460 Hat + 100 LOD-1 + 60 LOD-2; `task.defer` chunked alloc | Pool Allocation Strategy section adopts these sizes verbatim; 25/batch via `task.defer` at boot |
| `follower-lod-manager.md` §F1-F4 | Distance check 10 Hz; cap arbitration; eviction protection via `n_effective = max(cap, peelCount)` | Locks `setLOD` / `setPoolSize` / `getPeelingCount` contract as inter-module API; eviction-protection contract uses LOD GDD F4 clamp formula |
| `art-bible.md` §5 (LOD Tiers) | 80/30 close, 15/15 medium, 1 billboard far at 0-20/20-40/40-100 m | Locked in Tier table |
| `art-bible.md` §8.6 (Rigging Standards) | Custom non-Humanoid CFrame rig | Re-affirmed; rig topology owned by GDD §C.1 |
| `crowd-replication-strategy.md` Rule 9 | Eliminated state continues broadcasting | CrowdManagerClient subscribes to `CrowdEliminated` reliable RE and tears down per-crowd Janitor + FollowerEntityClient instance; per-frame nil-check on `CrowdStateClient.get(crowdId)` drives any remaining despawns. No public `fadeOutCrowd` mutator. |

---

## Performance Implications

- **CPU (client)**: 1.5 ms desktop / 2.5 ms mobile per frame budget (per ADR-0003, registry: `system: follower-entity-client-sim`). Worst case (per ADR-0003 §Worst-Case Instance Caps): ~150 rendered Parts × ~2 µs CFrame write ≈ 0.3 ms; boids math adds ~0.3 ms desktop / 1.0 ms mobile (Luau overhead). Comfortable headroom within budget.
- **Memory (client)**: 920 pooled LOD-0 Parts (460 Body + 460 Hat) × ~30 KB/Part ≈ 28 MB; 100 LOD-1 simplified ≈ 3 MB; 60 BillboardGui impostors × ~100 KB ≈ 6 MB. Total ≈ 37 MB. Within ADR-0003 §Reserve 50 MB client envelope.
- **Load Time**: Pool boot via `task.defer` 25/batch ≈ ~95 deferred slots ≈ ~1.6 s on min-spec mobile (distributed across `Loading` UI). No frame-spike during play.
- **Network**: None — FollowerEntity is a pure consumer of `CrowdStateClient` mirror + reliable `Absorbed` / `CrowdEliminated` RemoteEvents. Peel detection runs CCR-client-side via 15 Hz `CrowdStateClient.CountChanged` broadcast-delta observation; no new server reliable RE. Adds zero new client-server traffic.

## Migration Plan

This is a new module per ADR-0006 §Source Tree Map. No existing code to migrate. Implementation sequence:

1. Sprint 4 (after `/create-stories follower-entity`): boot pool allocation + Tier 1 render path + boids F1-F4 loop
2. Sprint 5: LOD execution (`setLOD` / `setPoolSize`) + eviction protection + Tier 2 swap
3. Sprint 6: Tier 2 billboard impostor + cross-fade transitions
4. Sprint 7: Peel consumer (`startPeel(rivalCrowdId, n)` called by CCR-client) + absorb spawn (`spawnFromAbsorb(npcLastPosition)`) + CrowdManagerClient `CrowdEliminated` teardown
5. MVP-Integration-1 sprint: real-device soak on min-spec mobile + budget verification

`RelicSystemStub` already in `_PhaseStubs/` is unrelated; no stub for FollowerEntity yet — implementation lands fresh.

## Validation Criteria

- TestEZ unit tests: boids F1-F4 produce expected velocity vectors for canonical inputs (deterministic; no `RunService` calls in test code) — see follower-entity GDD AC-2..AC-26
- TestEZ integration tests: `setPoolSize` shrink with `getPeelingCount > 0` clamps `n_effective = max(newN, peelCount)`; Peeling subset retained while Active subset evicts (matches LOD GDD AC-LOD-09 + follower-entity AC-25)
- TestEZ integration tests: tier 0↔1↔2 swaps + CULL via `setPoolSize(0)` produce expected pool state (cap counts match LOD GDD §F3 table)
- TestEZ integration tests: peel triggered by 15 Hz `CrowdStateClient.CountChanged` broadcast-delta (own-count down + rival-count up by N) calls `startPeel` exactly once per tick (matches follower-entity AC-11 + AC-23)
- Budget watchdog warning rate < 5% across 60-second synthetic load test (8 crowds at full overlap, ~150 rendered Parts worst case per ADR-0003 instance cap)
- Manual verification (deferred to MVP-Integration-1): 60 FPS sustained on min-spec mobile during max-overlap dense-fight scenario; no flicker on tier 1↔2 transition; eviction-protection clamp prevents mid-peel pop-out

## Related Decisions

- ADR-0001 Crowd Replication Strategy — locks broadcast contract + LOD caps + no-Humanoid + 2-Part rig deferral
- ADR-0003 Performance Budget — locks per-frame budget for `follower-entity-client-sim`
- ADR-0004 CSM Authority — Pillar 4 anti-P2W invariant (cosmetic systems read-only on CSM)
- ADR-0006 Module Placement Rules — `ReplicatedStorage/Source/FollowerEntity/Client.luau` path
- ADR-0008 NPC Spawner Authority — pool pre-allocation pattern (`task.defer` 25/batch) re-used here for follower pool
- `design/gdd/follower-entity.md` — F-formulas + state machine + edge cases + tuning knobs
- `design/gdd/follower-lod-manager.md` — F1-F3 LOD policy + cap arbitration
- `art-bible.md` §5 (LOD Tiers) + §8.6 (Rigging Standards)
- `prototypes/crowd-sync/REPORT.md` — prototype validation: 60 FPS sustained, 8 crowds × 300 followers, 5-min desktop Studio soak
