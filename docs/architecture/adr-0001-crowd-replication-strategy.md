# ADR-0001: Crowd Replication Strategy

## Status

Proposed (amended 2026-04-24 per design/gdd/crowd-replication-strategy.md — payload tick+state fields, buffer mandate, late-join gap acknowledged; amended 2026-04-24 per design/gdd/crowd-state-manager.md Batch 1 — Key Interfaces refreshed: `radiusMultiplier` + `state`/`tick`/`stillOverlapping`/`timer_start` fields, `recomputeRadius`/`getAllActive`/`getAllCrowdPositions`/`setStillOverlapping` APIs, 5 named reliable events replacing `GameplayEvent` discriminator; amended 2026-04-24 Batch 3 — architecture diagram tier 2 cap corrected from "4 rendered" to "1 billboard impostor per crowd" per Follower LOD Manager sole-owner declaration)

## Date

2026-04-20 (initial), 2026-04-24 (amendment)

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Networking |
| **Knowledge Risk** | MEDIUM — Roblox ships API changes monthly; LLM cutoff May 2025 |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md` |
| **Post-Cutoff APIs Used** | `UnreliableRemoteEvent` (GA'd post-cutoff), Luau `buffer` type (planned for production — optional optimization path) |
| **Verification Required** | Mobile (iPhone SE emu ≥45 FPS) + multi-client bandwidth test on deployed server. Both deferred to MVP integration per prototype findings. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Crowd State Manager GDD, Follower Entity GDD, Follower LOD Manager GDD, Absorb System GDD, Crowd Collision Resolution GDD |
| **Blocks** | MVP Epic — cannot start any crowd-related story until this ADR is Accepted |
| **Ordering Note** | This is the foundational networking architecture. All downstream crowd systems consume the interfaces it defines. Must be Accepted before `/create-stories` runs for any MVP crowd feature. |

## Context

### Problem Statement

Crowdsmith gameplay requires 8-12 players per server, each commanding 100-300 follower entities. Worst case: 3,600 simultaneously visible character entities at 60 FPS across PC and mobile. Naive per-follower server-authoritative replication would saturate Roblox bandwidth and destroy mobile frame budget. A decision is required before any crowd-adjacent GDD is authored.

### Constraints

- **Platform**: Roblox cross-platform (PC / mobile / console). Mobile (iPhone SE tier) is the binding device.
- **Bandwidth**: Roblox imposes no hard per-player bandwidth cap but practical target is < 50 KBps per client for smooth mobile 3G/4G.
- **Frame budget**: 16.67 ms @ 60 FPS. Rendering + replication ingestion combined must stay well under.
- **Engine**: no custom shaders, no GPU instancing, no Humanoid for followers (performance-killing at 800+), manual LOD required.
- **Authority model**: server is source of truth per Roblox best practice — clients must not influence gameplay state.
- **Art direction**: chunky silhouette-first followers (art bible §1, §3). Pure-billboard crowds violate visual identity at close range.

### Requirements

- Must support 8-12 players × 100-300 followers at 60 FPS desktop, ≥45 FPS mobile
- Must keep bandwidth per client under 10 KBps steady-state
- Must support Absorb mechanic (neutral NPCs → player crowd)
- Must support Crowd Collision Resolution (crowd-vs-crowd elimination)
- Must preserve snowball-dopamine feel (Pillar 1 — the mass has to feel like a mass)
- Must not require per-follower persistence (Pillar 3 — round purity, no single-follower identity)

## Decision

**Server tracks per-player crowd aggregate state only. Individual follower positions are purely client-side visual decoration. Rendered follower count is decoupled from gameplay follower count via distance-based render caps. Followers use a custom 4-6-part CFrame rig (no Humanoid). Client-side boids flocking drives visual motion. LOD swap occurs in three tiers. All broadcasts use `UnreliableRemoteEvent` at 15 Hz.**

### Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│ SERVER (authoritative)                                         │
│                                                                │
│  per-player crowd state: { position, hitboxRadius (composed),  │
│                            followerCount, radiusMultiplier,    │
│                            hue, activeRelics, state, tick }    │
│                                                                │
│  Hit detection @ 15 Hz:                                        │
│    - Player hitbox vs. Neutral NPC position  → Absorb event    │
│    - Player hitbox vs. Rival player hitbox   → Collision event │
│                                                                │
│  Broadcast @ 15 Hz (amended 2026-04-24):                       │
│    RemoteEvents.CrowdStateBroadcast (UnreliableRemoteEvent)    │
│    Encoding: Luau `buffer` type (MANDATORY for MVP)            │
│    Payload: { crowdId uint64 | tick uint16 | pos Vec3          │
│               | radius f32 | count uint16 | hue u8 | state u8 }│
│    Target: 30 bytes per crowd × 12 × 15 Hz ≈ 5.4 KB/s per client│
└───────────────────────────────┬────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────┐
│ CLIENT (visual only)                                           │
│                                                                │
│  Receives crowd states @ 15 Hz                                 │
│  Computes render cap per crowd per frame-tier:                 │
│    - Own close (≤20m):    max 80 rendered                      │
│    - Rival close (≤20m):  max 30 rendered                      │
│    - Any 20-40m:          max 15 rendered                      │
│    - Any 40-100m:         max 1 billboard impostor per crowd   │
│    - > 100m:              culled                               │
│                                                                │
│  Follower simulation: boids flocking                           │
│    - Separation + cohesion + move-toward-leader                │
│    - O(n²) within crowd (safe: n ≤ 80 by cap)                  │
│  LOD swap every 0.1s (not every frame)                         │
│  FPS self-monitor; adaptive downscale deferred (not MVP)       │
└────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```lua
-- RemoteEvents contract (Roblox ReplicatedStorage.CrowdSyncRemotes.*)

-- Broadcast: server -> all clients, 15 Hz, unreliable
-- AMENDED 2026-04-24 per design/gdd/crowd-replication-strategy.md Rules 6, 9, 10:
--   (1) encoding: Luau `buffer` type MANDATORY for MVP (not table serialization)
--   (2) added `tick: uint16` for out-of-order defense (uint16 wraps at ~72 min @ 15 Hz)
--   (3) added `state: uint8 enum {Active=1, GraceWindow=2, Eliminated=3}` — eliminated
--       crowds continue broadcasting with state=Eliminated until RoundLifecycle.destroyAll
-- Per-entry layout (buffer-encoded, 30 bytes/crowd):
--   crowdId uint64 | tick uint16 | pos Vec3[3×f32] | radius f32 | count uint16 | hue uint8 | state uint8
-- Steady-state bandwidth: ~30 bytes × 12 crowds × 15 Hz ≈ 5.4 KB/s per client
RemoteEvents.CrowdStateBroadcast: UnreliableRemoteEvent

-- Gameplay events: server -> all clients, reliable (per-event RemoteEvents)
-- AMENDED 2026-04-24 (Batch 1) per design/gdd/crowd-state-manager.md §Network event contract:
--   replaced single GameplayEvent discriminator with 5 distinct named reliable events.
--   CSM §Network event contract is authoritative source; below is ADR summary only.
RemoteEvents.CrowdCreated: RemoteEvent        -- {crowdId, hue, initialCount} on create()
RemoteEvents.CrowdDestroyed: RemoteEvent      -- {crowdId} on destroy() (DC or round-end)
RemoteEvents.CrowdEliminated: RemoteEvent     -- {crowdId} on state → Eliminated (record persists until destroy)
RemoteEvents.CrowdCountClamped: RemoteEvent   -- {crowdId, attemptedDelta, clampedCount} local-filtered to owning player
RemoteEvents.CrowdRelicChanged: RemoteEvent   -- full activeRelics snapshot on relic acquire/expire

-- Server-only BindableEvent (NOT replicated to clients):
-- CrowdStateServer.CountChanged(crowdId, oldCount, newCount, deltaSource)
--   deltaSource ∈ { "Absorb", "Collision", "Chest", "Relic" }. Round Lifecycle + analytics consume.
```

```lua
-- CrowdStateServer module (server-only)
-- AMENDED 2026-04-24 (Batch 1) per design/gdd/crowd-state-manager.md:
--   + radiusMultiplier, state, tick, stillOverlapping, timer_start fields
--   + F1 radius now composed: radius_base(count) * radiusMultiplier
--   + expanded API surface; removed updatePosition (never existed — position is
--     internal position-lag tick per CSM §F2, not an external write)
type CrowdState = {
    id: string,
    position: Vector3,                                              -- authoritative, position-lag tick (CSM §F2)
    radiusMultiplier: number,                                       -- relic-composed, default 1.0, range [0.5, 1.5] per registry RADIUS_MULTIPLIER_MAX hard ceiling
    radius: number,                                                 -- composed: (2.5 + sqrt(count) * 0.55) * radiusMultiplier
    count: number,                                                  -- authoritative follower count [1, 300]
    hue: number,                                                    -- 1-12 per art bible §4 safe palette
    activeRelics: { string },                                       -- max 4 slots
    state: "Active" | "GraceWindow" | "Eliminated",
    tick: number,                                                   -- uint16 monotonic broadcast counter
    stillOverlapping: boolean,                                      -- set by CollisionResolver, read by grace-timer
    timer_start: number?,                                           -- os.clock() on GraceWindow entry; nil otherwise
}

-- See design/gdd/crowd-state-manager.md §Server API for caller restrictions + firing semantics.
CrowdStateServer.create(crowdId: string, initial: CrowdState): CrowdState                              -- RoundLifecycle only
CrowdStateServer.destroy(crowdId: string): ()                                                          -- RoundLifecycle + PlayerRemoving
CrowdStateServer.get(crowdId: string): CrowdState?                                                     -- any server system
CrowdStateServer.updateCount(crowdId: string, delta: number, source: DeltaSource): number              -- 4 callers: Absorb, Collision, Chest, Relic
CrowdStateServer.recomputeRadius(crowdId: string, newMultiplier: number): number                       -- RelicEffectHandler only
CrowdStateServer.getAllActive(): { CrowdState }                                                        -- CollisionResolver (overlap scan)
CrowdStateServer.getAllCrowdPositions(): { [string]: Vector3 }                                         -- NPCSpawner (min-distance gate)
CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()                               -- CollisionResolver only
```

### Tick rates

- Server hit detection: **15 Hz** (validated by prototype — O(p²) overlap check with 12 crowds = 66 pairs, trivial)
- Server broadcast: **15 Hz** (same cadence as hit detection, single send per tick)
- Client LOD swap check: **10 Hz** (every 0.1s per follower)
- Client boids step: **every frame** (RenderStepped, timed against dt)

### Prototype Validation

Prototype at `prototypes/crowd-sync/` ran target MVP scenario (8 crowds × 300 followers = 2,400 server-side entities) for 5 minutes continuous on desktop Studio:

- **FPS**: 60.0 steady, single 59.2 blip (GC pause) at 5-min mark
- **Frame time**: 16.66-16.68 ms
- **Rendered parts per client**: 35-124 (caps enforcing as designed)
- **Memory**: plateaued ~3579 MB after warm-up, no linear leak
- **Hit overlaps**: 0-6 per tick, confirming cheap O(p²)
- **Bandwidth**: not measured (in-process Studio solo-play does not populate `DataReceiveKbps`) — theoretical estimate ~7 KB/s

Full report: `prototypes/crowd-sync/REPORT.md`. Mobile and multi-client tests deferred to MVP integration.

## Alternatives Considered

### Alternative 1: Server-authoritative per-follower replication

- **Description**: Every follower is a server-owned entity. Server writes per-follower CFrame each Heartbeat. Roblox native replication carries state to clients.
- **Pros**: Cross-client position consistency (client A sees same follower layout as client B). Simple mental model.
- **Cons**: At 2,400 entities × 8-12 clients × 60 Hz, bandwidth + server CPU saturate. Mobile frame time collapses. No path to mobile 45 FPS.
- **Rejection Reason**: Would fail mobile target by >10× factor. Roblox bandwidth model does not permit this scale.

### Alternative 2: Deterministic shared-seed simulation

- **Description**: All clients share a round seed. Server broadcasts player hitbox + count at 15 Hz. Each client runs identical seeded flocking sim, producing byte-for-byte identical follower positions across all clients.
- **Pros**: Perfect cross-client visual consistency without per-follower replication bandwidth.
- **Cons**: Requires physics determinism in Luau — numerical drift accumulates over 5 minutes. Each client re-runs the full sim for all players' crowds → client CPU scales quadratically with player count. Significant engineering overhead for marginal benefit.
- **Rejection Reason**: Crowd City and similar games prove cosmetic desync is imperceptible during arena play. Determinism cost is not justified.

### Alternative 3: Billboard-only crowds (particle rendering)

- **Description**: Replace 3D follower models entirely with GPU particle billboards scaled by crowd size.
- **Pros**: Massive frame savings. Particles are the cheapest rendering primitive.
- **Cons**: Abandons art bible §1 (silhouette-first) and §3 (shape language) at close camera range. Absorb animation per-follower impossible. Cosmetic skin pillar (§4) cannot project on particle clouds.
- **Rejection Reason**: Violates art direction and breaks Pillar 4 (Cosmetic Expression — skin must apply to visible follower crowd).

## Consequences

### Positive

- Architecture scales to full design vision (8-12 players × 100-300 followers each) at 60 FPS desktop, with high confidence of meeting mobile target
- Bandwidth consumption is trivial (~7 KB/s per client estimated) — leaves headroom for gameplay event traffic
- Decoupling gameplay count from rendered count gives "big numbers" for free — any future high-count mechanic (super-crowd modes, seasonal events) gets this architecture at no additional cost
- Server CPU is cheap enough to leave room for other systems (Absorb, Chest, Relic) on main thread
- Pure client-side follower simulation means future Actor/Parallel-Luau optimization is straightforward if ever needed
- No Humanoid on followers removes a major per-instance cost source

### Negative

- Individual follower positions differ between clients — client A sees different micro-layout of player B's crowd than client C does. Accepted cosmetic desync.
- Render-cap swap creates Part churn — prototype showed GC handles it, but production should pool for safety
- Client CPU scales linearly with rendered follower count — caps must stay tight on low-end mobile
- Custom rig + manual LOD means more engineering than Humanoid-based followers — but this cost is already accepted by the art bible
- **No mid-round join state sync** *(gap acknowledged 2026-04-24 per design/gdd/crowd-replication-strategy.md OQ #4)* — first `CrowdStateBroadcast` after connect could be dropped (unreliable channel); no separate `CrowdStateSnapshot` reliable event is specified. Match State Machine locks mid-round join OFF for MVP so this gap is academic at launch; a `CrowdStateSnapshot` reliable event must be specified before any post-MVP mid-round-join mechanic ships.

### Risks

- **Risk 1 (medium)**: Mobile frame budget may require tighter caps than desktop shows. *Mitigation*: run iPhone SE emulator test at first MVP integration milestone. If <45 FPS, reduce own-close cap 80 → 50 and rival-close 30 → 20.
- **Risk 2 (low)**: Client Part pool management complexity creeps in production. *Mitigation*: ADR-N (Follower Entity Pooling) can defer until MicroProfiler flags GC stutters. Not a day-one concern.
- **Risk 3 (low)**: `UnreliableRemoteEvent` packet loss could cause crowd position "teleports" if loss clusters. *Mitigation*: 15 Hz is frequent enough that single-packet loss is invisible. Client interpolates between received positions; out-of-order reorder defended by `tick: uint16` counter (AMENDED 2026-04-24).
- **Risk 4 (medium → RESOLVED in design)**: Multi-client bandwidth test not yet run. Original ~7 KB/s estimate was underestimated ~1.75× for table format (~13.5 KB/s reality). *Resolution*: buffer encoding promoted from optional to MANDATORY for MVP (Rule 10 of design/gdd/crowd-replication-strategy.md); buffer-format bandwidth ~5.4 KB/s fits 10 KB/s budget. Test > Start 4 players during first MVP integration sprint to validate empirically.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md | "Each player commands 100-300 followers; 8-12 players per server" | Server hitbox-only model makes this feasible at 60 FPS |
| game-concept.md | Pillar 1 (Snowball Dopamine) — growth must feel great | Decoupled count lets server report 300 followers while client renders enough to feel like a mob |
| game-concept.md | Pillar 3 (5-Min Clean Rounds) — no persistent power | Follower identity is cosmetic only; no individual follower state persists |
| game-concept.md | Pillar 4 (Cosmetic Expression) — skin applies to whole crowd | Client-side rendering means skin swap is a single material update per crowd, not 300 per-entity updates |
| art-bible.md §5 (LOD Tiers) | 3-tier LOD: 0-20m full / 20-40m simple / 40-100m billboard / cull >100m | ADR specifies exact same tiers + 0.1s client re-check cadence |
| art-bible.md §8.5 (Rigging Standards) | Followers use custom 4-6-part CFrame rig, NO Humanoid | Incorporated as normative — no Humanoid on any follower |
| systems-index.md | Crowd Replication Strategy (high-risk system) | This ADR IS that system's formal architecture |
| design/gdd/crowd-replication-strategy.md Rule 6 | Out-of-order broadcast defense | Added `tick: uint16` counter to payload (amended 2026-04-24) |
| design/gdd/crowd-replication-strategy.md Rule 9 + Rule 13 | `state: uint8 enum` in broadcast payload incl. Eliminated | Added `state` field to payload; eliminated crowds broadcast until `destroyAll` (amended 2026-04-24) |
| design/gdd/crowd-replication-strategy.md Rule 10 | Buffer encoding MANDATORY for MVP | Promoted `buffer` from optional to required (amended 2026-04-24) |
| design/gdd/crowd-replication-strategy.md §C Consumer Contract | All 15 Core Rules codify design-facing contract for consumer GDDs (CSM, Absorb, CCR, Chest, Relic, HUD, Nameplate, VFX) | This ADR's Decision section is the architectural implementation of those rules |
| design/gdd/crowd-state-manager.md Batch 1 (2026-04-24) | `radiusMultiplier` field + F1 composition + `recomputeRadius`/`getAllActive`/`getAllCrowdPositions`/`setStillOverlapping` APIs + `CrowdCreated`/`CrowdDestroyed`/`CrowdCountClamped` reliable events + `CountChanged` server BindableEvent | Key Interfaces block refreshed to match; architectural decision (server-authoritative hitbox-only, 15 Hz, LOD tiers) unchanged |

## Performance Implications

- **CPU (server)**: Negligible. Hit detection at 15 Hz × O(p²=66) pairs per tick = ~1,000 distance checks/sec. Broadcast is one table serialization per tick.
- **CPU (client)**: Primary cost is boids flocking + CFrame writes for rendered followers. Prototype showed <1 ms/frame at ~80 rendered followers combined across crowds.
- **Memory (server)**: ~100 bytes per crowd state. Trivial.
- **Memory (client)**: Each rendered Part ≈ 1-2 KB Roblox instance overhead. At 150 max rendered parts worst case, ~300 KB. Dwarfed by baseline Roblox engine memory.
- **Load Time**: No asset preloading required for this ADR — the crowd Parts are spawned at runtime.
- **Network**: ~5.4 KB/s per client steady-state (buffer-encoded, 30 bytes × 12 crowds × 15 Hz). One broadcast every 66 ms. Previous ~7 KB/s figure assumed table serialization; amended 2026-04-24 per design/gdd/crowd-replication-strategy.md Rule 10 mandating buffer encoding for MVP.

## Migration Plan

No existing code. Clean implementation against this ADR.

## Validation Criteria

The architecture is proven correct if:

1. 8-12 players × 300 followers sustained 55+ FPS desktop (prototype: **60.0 FPS confirmed**)
2. Mobile iPhone SE emu sustains ≥45 FPS at target load (deferred — MVP integration)
3. Multi-client bandwidth <10 KB/s per client (deferred — MVP integration)
4. 10-minute continuous play shows no memory leak (prototype: 5-min plateau confirmed; 10-min recheck during integration)
5. Absorb feel test: at 300-follower crowd, absorbing a neutral produces one visible follower snap within 0.3s of proximity overlap

If any item 2-5 fails during MVP integration, revisit this ADR — likely outcome is tightening render caps (Risk 1 mitigation), not full redesign.

## Related Decisions

- Related: `prototypes/crowd-sync/REPORT.md` — empirical validation of this architecture
- Downstream (expected future ADRs, not yet written):
  - ADR-NNNN: Follower Entity Pooling (when Part churn becomes measurable cost)
  - ADR-NNNN: Crowd State Persistence Policy (clarifies what survives server restart — likely nothing per Pillar 3)
  - ADR-NNNN: Server Tick Rate for Hit Detection (can this ADR's 15 Hz choice be revised per system?)

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). Empirical validation via `prototypes/crowd-sync/` 5-min run provides stronger evidence than any API-level review would offer. If Roblox engine best practices drift post-Accepted, re-verify via `/setup-engine refresh`.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
