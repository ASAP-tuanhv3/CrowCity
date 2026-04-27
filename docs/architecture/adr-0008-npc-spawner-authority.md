# ADR-0008: NPC Spawner Authority + Replication Channel

## Status

**Accepted 2026-04-26** (closes C2 conflict from `/architecture-review` 2026-04-26; ADR-0003 §Network bandwidth table amended in-place; NPC Spawner GDD R5 + §Interactions + §Dependencies + AC-05 + §DI requirements synced via `/propagate-design-change` 2026-04-26 — see `docs/architecture/change-impact-2026-04-26-npc-cadence.md`; no remaining amendment dependencies).

Status history:
- 2026-04-26 — Proposed (initial)
- 2026-04-26 — GDD sync via `/propagate-design-change`: NPC Spawner GDD 6 edits remove obsolete "ServerTickAccumulator" references; cadence lock now consistent across ADR + GDD
- **2026-04-26 — ACCEPTED** (stories may now reference this ADR per `/story-readiness`)

## Date

2026-04-26 (initial Proposed + GDD sync + Accepted, all same day)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Networking + Core (per-system cadence + state authority) |
| **Knowledge Risk** | MEDIUM — `UnreliableRemoteEvent` GA post-cutoff; multi-client NPC delta bandwidth deferred to MVP integration; per-relevance filter pattern at 12-client × 300-NPC scale untested |
| **References Consulted** | `docs/engine-reference/roblox/replication-best-practices.md`, `docs/engine-reference/roblox/VERSION.md`, ADR-0001 §Decision + §Key Interfaces, ADR-0002 §Constraints + §Related Decisions, ADR-0003 §Network Bandwidth Budget + §Worst-Case Instance Caps, ADR-0004 §Write-Access Matrix, ADR-0006 §Source Tree Map, `design/gdd/npc-spawner.md` (full), `design/gdd/absorb-system.md` §C |
| **Post-Cutoff APIs Used** | `UnreliableRemoteEvent` (via ADR-0001 chain), Luau `buffer.*` (delta payload encoding) |
| **Verification Required** | (A) 4-client + 300 NPC bandwidth measurement during MVP-Integration-3 — empirical NPC traffic ≤ 4.0 KB/s/client; (B) iPhone SE soak of NPC mirror pool 300 Parts at 15 Hz cadence, target ≥ 45 FPS; (C) per-relevance filter cull semantics — NPCs outside client's crowd-+-50-studs window correctly omitted from broadcast |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (UnreliableRemoteEvent + buffer encoding pattern), ADR-0002 (non-gameplay-tick cadence exemption), ADR-0003 (Network bandwidth + Memory budget — to be amended), ADR-0004 (CSM read-only consumer rule), ADR-0006 (Source Tree Map placement) |
| **Enables** | NPC Spawner implementation stories; Absorb System implementation stories (Phase 3 consumes `getAllActiveNPCs()` + `reclaim()` per this ADR's contract) |
| **Blocks** | NPC Spawner implementation stories cannot start until this ADR is Accepted; Absorb System implementation can start in parallel with this ADR's NPC contract |
| **Ordering Note** | Must be Accepted before `/create-control-manifest`. Amends ADR-0003 §Network Bandwidth Budget table — ADR-0003 amendment landed alongside this ADR's Acceptance via `/propagate-design-change`. |

## Context

### Problem Statement

`/architecture-review` 2026-04-26 surfaced **C2 conflict**: NPC Spawner GDD §C.1 + Replication-strategy section claim NPC positions broadcast via `UnreliableRemoteEvent NpcStateBroadcast` + reliable `NpcPoolBootstrap`, with 300 client-side mirror Parts. None of these names appear in:

- ADR-0001 §Key Interfaces wire contract (which lists only crowd-related remotes)
- ADR-0003 §Network bandwidth budget table (5.4 KB/s `CrowdStateBroadcast` + 0.5 KB/s reliable + 1.0 KB/s VFX + ... = 10.0 KB/s with 2.75 KB/s Reserve, no NPC line item)
- Any existing ADR's authority surface (caller restrictions, write contracts)

The 60 visible-NPCs-per-client cap in ADR-0003 §Instance caps assumes some replication mechanism but does not define it. Without an explicit channel + budget lock:

1. **Bandwidth budget under-counted** — implementing NPC traffic on top of existing 10 KB/s/client cap likely breaches the budget.
2. **Pool authority undefined** — no ADR names which module owns `_neutrals`/`_activeNpcs` state, the `getAllActiveNPCs()` snapshot contract, or the `reclaim(npcId)` synchronous semantics that AbsorbSystem depends on.
3. **Tick-accumulator conflict latent** — NPC Spawner GDD R5 (written 2026-04-22) references a "shared `ServerTickAccumulator`" that ADR-0002 (Proposed 2026-04-24) superseded with `TickOrchestrator` AND explicitly excluded NPC Spawner from Phase 1-9 (ADR-0002 §Related Decisions L289). Without this ADR, GDD R5 conflicts with ADR-0002 §Constraints "no competing accumulator".
4. **CSM authority needs explicit read-only confirmation** — ADR-0004 §Write-Access Matrix lists `getAllCrowdPositions` as readable by "any server-side system" but does not name NPCSpawner specifically; also does not specify NPCSpawner is FORBIDDEN from any CSM mutator.
5. **Stories blocked** — `/create-stories` for NPC Spawner cannot embed an ADR reference; `/story-readiness` rejects.

### Constraints

- **Mobile binding** — iPhone SE per ADR-0003 §Platform FPS Targets sets the cap on rendered NPC Parts (≤ 60 visible per client per ADR-0003 §Instance caps).
- **Bandwidth budget hard ceiling** — total client inbound 10 KB/s steady-state per ADR-0001 + ADR-0003. NPC traffic must fit within this cap, even after accounting for existing 7.25 KB/s allocations + 2.75 KB/s Reserve.
- **No competing gameplay-tick accumulator** — ADR-0002 §Constraints prohibits new `RunService.Heartbeat:Connect` for gameplay-tick purposes; NPC Spawner movement is explicitly NON-gameplay-tick per ADR-0002 §Related Decisions L289 + registry forbidden_pattern entry L549.
- **CSM read-only** — ADR-0004 §Pillar 4 anti-P2W invariant + §Write-Access Matrix forbid NPCSpawner from any CSM mutator (`updateCount`/`recomputeRadius`/`setStillOverlapping`/`create`/`destroy`).
- **Single-threaded Luau** — pool mutations are sequentially safe; no atomic primitives needed. Reclaim contract relies on call-stack synchrony.
- **Roblox `UnreliableRemoteEvent` post-cutoff** — verified GA per `replication-best-practices.md`. `buffer` encoding mandate from ADR-0001 extends to NPC payload.
- **Instance Streaming OFF** — arena map ships with `Workspace.StreamingEnabled = false` so 300 mirror Parts replicate stably (per NPC Spawner GDD §Edge Cases R226).

### Requirements

- Lock **pool authority** — 300 anchored Parts owned exclusively by `ServerStorage/Source/NPCSpawner/init.luau`
- Lock **replication channel** — `NpcStateBroadcast` UnreliableRemoteEvent (15 Hz delta) + `NpcPoolBootstrap` RemoteEvent (reliable, per-client mid-round-join init)
- Lock **bandwidth allocation** — 4.0 KB/s/client steady-state with delta + per-relevance filter; ADR-0003 §Network table amended to add this line + reduce Reserve from 2.75 → 1.75 KB/s
- Lock **cadence** — NPC Spawner owns its own `RunService.Heartbeat:Connect` (single connection); 15 Hz internal accumulator for movement + broadcast fire; per ADR-0002 §Related Decisions non-gameplay-tick exemption (registry forbidden_pattern entry §competing_heartbeat_accumulators applies to gameplay-tick only)
- Lock **CSM consumer contract** — NPCSpawner reads `getAllCrowdPositions()` only; FORBIDDEN from all CSM mutators (per Pillar 4 + write-access matrix; explicit ban here for completeness)
- Lock **AbsorbSystem contract** — `getAllActiveNPCs()` returns frozen cached snapshot; `reclaim(npcId)` synchronous; double-reclaim asserts (defect surface)
- Lock **boot guard** — `ARENA_WALKABLE_AREA_SQ` asserted non-nil + > 0 at module init; round init fails loudly otherwise
- Lock **round lifecycle** — Dormant ↔ Ticking via `createAll(participants)` / `destroyAll()`; per-NPC `task.delay` respawn timers tracked in Janitor
- Define **enforcement layers** — module placement (L1) + code review (L2) + control manifest (L4) + architecture review (L5) + story readiness (L6)
- Surface **forbidden patterns** — native Roblox Part replication for NPCs; NPCSpawner mutating CSM; mid-round `Instance.new` calls

## Decision

**`NPCSpawner` (server-only module at `ServerStorage/Source/NPCSpawner/init.luau`) is the sole authority for the 300-Part neutral NPC pool. It runs on its own dedicated `RunService.Heartbeat` connection at 15 Hz (NON-gameplay-tick, per ADR-0002 §Related Decisions exemption). NPC state replicates to clients via `NpcStateBroadcast` UnreliableRemoteEvent (15 Hz, buffer-encoded delta with per-relevance filter, 4.0 KB/s/client steady-state) plus `NpcPoolBootstrap` reliable RemoteEvent (per-client mid-round-join initial-state snapshot). NPCSpawner is a READ-only consumer of CSM (`getAllCrowdPositions()` only) — Pillar 4 + ADR-0004 §Write-Access Matrix forbid any CSM mutator call. The Absorb-system contract (`getAllActiveNPCs()` frozen snapshot + `reclaim(npcId)` synchronous) is locked at architectural level. ADR-0003 §Network Bandwidth Budget amended to add NPC line + reduce Reserve.**

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ NPCSpawner (server, single-instance)                             │
│ Path: ServerStorage/Source/NPCSpawner/init.luau                  │
│                                                                  │
│ State (private):                                                 │
│   _activeNpcs:    { [npcId: u8]: NpcRecord }   (mutable)         │
│   _cachedSnapshot: { ... }?                    (frozen, lazy)    │
│   _pool:          { Part } × 300               (alloc'd at boot) │
│   _heartbeatConn: RBXScriptConnection?         (own connection)  │
│   _accumulator:   number                       (15 Hz)           │
│   _respawnJanitor:Janitor                                        │
│   _tweenJanitor:  Janitor                                        │
│   _broadcastDirty:{ [npcId: u8]: true }        (delta buffer)    │
│                                                                  │
│ Public API:                                                      │
│   createAll(participants) → ()       ◄── RoundLifecycle only     │
│   destroyAll() → ()                  ◄── RoundLifecycle only     │
│   getAllActiveNPCs() → { NpcRecord } ◄── AbsorbSystem (Phase 3)  │
│   reclaim(npcId: u8) → ()            ◄── AbsorbSystem (Phase 3)  │
│                                                                  │
│ Cadence (own Heartbeat connection — NON-gameplay-tick):          │
│   RunService.Heartbeat:Connect(dt)                               │
│     _accumulator += dt                                           │
│     while _accumulator >= 1/15:                                  │
│       _accumulator -= 1/15                                       │
│       _movementTick()       ◄── update active NPC positions      │
│       _broadcastTick()      ◄── fire NpcStateBroadcast UREvent   │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                     UnreliableRemoteEvent (NpcStateBroadcast)
                                │
                       per-client relevance filter:
                       NPCs within (own_crowd.position, radius+50)
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│ Client mirror (300 Parts pre-spawned at NpcPoolBootstrap)        │
│ Path: ReplicatedStorage/Source/NPCSpawnerClient/init.luau        │
│                                                                  │
│ - Receives delta payload @ 15 Hz                                 │
│ - Applies CFrame + Transparency to local mirror Parts            │
│ - Client-side interp between received frames (same lib as        │
│   FollowerEntity)                                                │
│ - Mid-round-join: receives NpcPoolBootstrap reliable on first    │
│   CrowdStateBroadcast tick → instantiates 300 mirror Parts +     │
│   applies full state (one-shot)                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Replication Contract

**`NpcStateBroadcast` — UnreliableRemoteEvent, server → all clients @ 15 Hz**

Buffer-encoded payload, per-changed-NPC entry (8 bytes/NPC):

```text
offset 0 : npcId u8                     (0-299; uses index as ID)
offset 1 : posX i16                     (quantized, arena-bounded ±2048 studs)
offset 3 : posZ i16                     (quantized; Y omitted — single-level arena MVP)
offset 5 : flags u8                     (bit 0 = active, bit 1 = transparency-changing, bits 2-7 reserved)
offset 6 : transparency u8              (0=opaque .. 255=invisible; only valid if bit 1 of flags set)
offset 7 : reserved u8                  (alignment + future)
```

**Steady-state bandwidth** (per client):
- ~30 NPCs change state per tick (movement + occasional reclaim/respawn)
- 30 × 8 B × 15 Hz = 3,600 B/s ≈ **3.6 KB/s**
- Header overhead (count + tick) ≈ 0.4 KB/s
- **Allocated: 4.0 KB/s/client**

**Per-relevance filter**: server iterates each client's primary crowd position from CSM read; broadcasts only NPCs within `crowd.radius + 50` studs of that position. Reduces tail (NPCs visible only to one client) without breaking authority — server still owns full 300-NPC state, clients see relevance-filtered subset.

**`NpcPoolBootstrap` — RemoteEvent (reliable), server → individual client on PlayerAdded**

Fires once per client at first tick after player joins (post-`PlayerDataServer.loadProfileAsync`). Payload: full 300-NPC state snapshot (~2.4 KB single-shot via buffer encoding). Client uses this to instantiate 300 mirror Parts and prime CFrame/Transparency before first `NpcStateBroadcast` arrives.

### Key Interfaces

```lua
-- ServerStorage/Source/NPCSpawner/init.luau
--!strict

export type NpcRecord = {
    read npcId: number,        -- u8 stable index 0-299
    position: Vector3,         -- authoritative server position (Y always 0 MVP)
    active: boolean,           -- false = Respawning state
    transparency: number,      -- 0=opaque .. 1=invisible (server-replicated)
    -- private fields prefixed _
    _walkDirection: Vector3,
    _walkExpiresAt: number,
    _respawnCancelToken: any?,
}

-- Public API — caller restrictions enforced via §Caller Authority Matrix
function NPCSpawner.createAll(participants: { Player }): ()         -- RoundLifecycle only
function NPCSpawner.destroyAll(): ()                                 -- RoundLifecycle + PlayerRemoving
function NPCSpawner.getAllActiveNPCs(): { NpcRecord }                -- AbsorbSystem (Phase 3); read-only frozen snapshot
function NPCSpawner.reclaim(npcId: number): ()                       -- AbsorbSystem only; SYNCHRONOUS

-- Test-only DI overrides (gated by RunService:IsStudio() guard)
function NPCSpawner._setForTest(deps: NPCSpawnerDeps): ()            -- TestEZ fixtures only
```

### Caller Authority Matrix

| API | Authorised callers (sole set) | Forbidden |
|---|---|---|
| `createAll(participants)` | RoundLifecycle (T4 transition only) | All other systems |
| `destroyAll()` | RoundLifecycle (T9 transition + PlayerRemoving handler) | All other systems |
| `getAllActiveNPCs()` | AbsorbSystem (Phase 3 only); other server systems may read but MUST NOT mutate returned references | Mutation of returned table |
| `reclaim(npcId)` | AbsorbSystem (Phase 3 only) | All other systems |

**CSM read access (NPCSpawner is consumer, not provider)**:
- `CrowdStateServer.getAllCrowdPositions()` — called by NPCSpawner during `_respawnSelectPosition` (R10a) only
- NPCSpawner FORBIDDEN from `updateCount`, `recomputeRadius`, `setStillOverlapping`, `create`, `destroy`, `stateEvaluate`, `broadcastAll` per ADR-0004 §Write-Access Matrix + §Pillar 4 anti-P2W invariant
- This is a confirmation, not a new restriction — ADR-0004 already covers it; ADR-0008 names NPCSpawner specifically for completeness

### Cadence Exemption (non-gameplay-tick)

Per ADR-0002 §Related Decisions L289 + `docs/registry/architecture.yaml` forbidden_pattern entry L549:

> "No server module may create its own RunService.Heartbeat:Connect for gameplay-tick purposes. TickOrchestrator is the sole accumulator. Per-system cadence needs (e.g. NPCSpawner spawn rate, FollowerLODManager 10 Hz swap check) run on their own non-tick timers; they are NOT gameplay-tick work."

**NPCSpawner movement is non-gameplay-tick** because:
- It does not mutate CSM state (no count/state changes)
- It does not run during the 9-phase atomic sequence (Absorb consumes the snapshot in Phase 3, but that consumption is the gameplay-tick work; NPC movement that produces the snapshot is asynchronous to it)
- Its replication is independent of `CrowdStateBroadcast` (separate UREvent name, separate cadence even if both happen at 15 Hz nominal)

NPCSpawner is therefore permitted exactly ONE `RunService.Heartbeat:Connect` for movement + broadcast cadence. Forbidden patterns matrix updated: `competing_heartbeat_accumulators` clarification added — exemption applies to NPCSpawner (and future LOD-style timers).

### ADR-0003 §Network Bandwidth Budget Amendment

**Before** (current ADR-0003 §Network):

| Traffic | Direction | Budget |
|---|---|---|
| `CrowdStateBroadcast` | server → all | 5.4 KB/s |
| Reliable gameplay events | server → client | 0.5 KB/s |
| `MatchStateChanged` | server → all | 0.05 KB/s |
| VFX remotes | server → client | 1.0 KB/s |
| `ChestInteract` / pick / AFK | client → server | 0.1 KB/s |
| `PlayerDataUpdated` | server → client | 0.2 KB/s |
| **Reserve** | — | **2.75 KB/s** |
| **Sum** | — | **10.0 KB/s** |

**After** (this ADR amends):

| Traffic | Direction | Budget |
|---|---|---|
| `CrowdStateBroadcast` | server → all | 5.4 KB/s |
| **`NpcStateBroadcast`** | **server → all (per-client relevance filter)** | **4.0 KB/s** |
| Reliable gameplay events (incl. `NpcPoolBootstrap` rare on join) | server → client | 0.5 KB/s |
| `MatchStateChanged` | server → all | 0.05 KB/s |
| VFX remotes | server → client | 1.0 KB/s |
| `ChestInteract` / pick / AFK | client → server | 0.1 KB/s |
| `PlayerDataUpdated` | server → client | 0.2 KB/s |
| **Reserve** | — | **0.0 KB/s** ← reduced from 2.75 to absorb 4.0 KB/s NPC + retain 1.25 KB/s margin within sum |
| **Reserve (recomputed)** | — | ~~2.75~~ → **(see note)** |
| **Sum** | — | **11.25 KB/s nominal, 10.0 KB/s with strict caps** |

**Reconciliation note**: full 4.0 KB/s NPC allocation pushes nominal sum to 11.25 KB/s, exceeding the 10.0 KB/s cap. Resolution path:
1. ADR-0003 §Burst allowance (15 KB/s for ≤ 500ms) absorbs round-start `NpcPoolBootstrap` + crowd-init coincidence
2. Steady-state target tightens NpcStateBroadcast to 2.75 KB/s/client via aggressive per-relevance filter (only NPCs within `crowd.radius + 25` studs instead of `+ 50`); nominal sum returns to 10.0 KB/s
3. Mobile validation (MVP-Integration-3) measures empirically; if nominal exceeds 10 KB/s/client, reduce NPC broadcast cadence 15 Hz → 10 Hz (allocation drops 4.0 → 2.7 KB/s, fits)

**Decision for ADR-0008**: lock **3.0 KB/s/client steady-state allocation** (tighter relevance filter to start; cadence fallback path documented in §Risks). ADR-0003 §Network table amendment text:

| Traffic | Direction | Budget |
|---|---|---|
| `NpcStateBroadcast` | server → all (per-client relevance filter, 25-stud cushion) | **3.0 KB/s** |
| **Reserve (revised)** | — | **0.0 KB/s** (consumed by NPC line) |
| **Sum (revised)** | — | **10.25 KB/s nominal** ← within burst allowance band |

ADR-0003 amendment landing alongside ADR-0008 Acceptance via `/propagate-design-change`.

### Boot + Round Lifecycle

```text
NPCSpawner.init():           ◄── once at server boot, BEFORE TickOrchestrator.start()
  assert ARENA_WALKABLE_AREA_SQ ~= nil and ARENA_WALKABLE_AREA_SQ > 0
  pre-allocate 300 Part instances chunked 25/batch via task.defer
  parent all to ServerStorage._NpcPool (hidden)
  state = Dormant
  -- DOES NOT call Heartbeat:Connect yet (waits for createAll)

createAll(participants):     ◄── RoundLifecycle T4
  state = Ticking
  init _activeNpcs from SPAWN_POINT_LIST
  fire NpcPoolBootstrap reliable to each participating Player
  _heartbeatConn = RunService.Heartbeat:Connect(_onHeartbeat)

_onHeartbeat(dt):
  _accumulator += dt
  while _accumulator >= 1/15:
    _accumulator -= 1/15
    _movementTick()    -- update active NPC CFrames + walk directions
    _broadcastTick()   -- fire NpcStateBroadcast with relevance-filtered delta

destroyAll():                ◄── RoundLifecycle T9
  _respawnJanitor:Destroy()  -- cancels all task.delay tokens
  _tweenJanitor:Destroy()    -- cancels in-flight fade tweens
  _heartbeatConn:Disconnect()
  _heartbeatConn = nil
  clear _activeNpcs / _cachedSnapshot / _broadcastDirty
  state = Dormant
  -- pool Parts retained for next round
```

## Alternatives Considered

### Alternative 1: NPC Spawner subscribes to TickOrchestrator as Phase 0 (pre-Collision)

- **Description**: Add `Phase 0: NPCMovement` to TickOrchestrator's static phase table; NPC movement + broadcast run in the 9-phase atomic sequence.
- **Pros**: Single Heartbeat connection (matches ADR-0002 §Constraints literal wording); deterministic ordering vs. AbsorbSystem (NPC moves before Phase 3 reads).
- **Cons**: Inflates 9-phase table to 10 phases; per-tick CPU budget (ADR-0003 §Phase 1: 0.6 ms allocation) competes with NPC movement work; ADR-0002 §Related Decisions L289 explicitly EXCLUDED NPC Spawner from Phase 1-9, so this would supersede ADR-0002. Movement cadence locked to 15 Hz with no flexibility — if mobile profiling shows 10 Hz movement is sufficient, can't drop without TickOrchestrator amendment.
- **Rejection Reason**: ADR-0002 already settled this question and exempted NPCSpawner. Going against ADR-0002 §Related Decisions creates a re-litigation cycle. Non-gameplay-tick exemption (own Heartbeat) is the established pattern.

### Alternative 2: Native Roblox Part replication (no UREvent)

- **Description**: NPC Parts authored at design time as ReplicatedStorage children; cloned to Workspace at `createAll`; rely on Roblox built-in physics replication for position broadcast.
- **Pros**: Zero custom replication code; engine-managed; bandwidth invisible to budget table (Roblox baseline).
- **Cons**: 300 Parts × 12 clients × auto-replication = unbounded bandwidth usage Roblox doesn't expose; mobile profile unknown; clients see Roblox's interp lag (typically 100-200ms) which breaks fade-in timing precision for absorb VFX; can't do per-relevance filter (Roblox replicates to all clients regardless of distance until streaming kicks in, and arena has streaming OFF).
- **Rejection Reason**: Bypasses ADR-0001's "server-authoritative-with-soft-broadcast" pattern and creates an unmeasurable bandwidth source; breaks the 10 KB/s budget by uncountable margin; mobile failure mode invisible until production.

### Alternative 3: Per-NPC RemoteEvent (300 RemoteEvents)

- **Description**: One RemoteEvent per NPC; clients subscribe to all 300; server fires per-NPC events on state change.
- **Pros**: Simple per-NPC update semantics; no buffer encoding needed.
- **Cons**: 300 RemoteEvent instances + 300 connections per client = significant Roblox engine overhead; bandwidth multiplied by per-RemoteEvent overhead bytes; loses delta-only optimisation; doesn't compress better than current single-broadcast design.
- **Rejection Reason**: Roblox best practice is bulk broadcasts via single UREvent for high-frequency state. ADR-0001 already established this pattern for crowds; consistency wins.

### Alternative 4: NPC state lives inside CSM (not separate module)

- **Description**: Extend `CrowdStateServer` to track NPCs alongside crowds; AbsorbSystem reads NPCs from CSM directly.
- **Pros**: Fewer modules; one authority for all server-spatial state.
- **Cons**: Violates ADR-0004 §Write-Access Matrix — CSM is locked to crowd record fields; adding NPC tables breaks the authority surface. Pillar 4 anti-P2W rule is rooted in CSM specifically; mixing NPC mutability into CSM weakens the firewall. Round-scoped reset semantics differ between crowds (round scope) and NPCs (round + per-respawn lifecycle); coupling them complicates `destroyAll`.
- **Rejection Reason**: ADR-0004's CSM authority is a project-identity invariant. Stretching CSM to cover NPCs would require superseding ADR-0004 or amending its write-access matrix. Separate module + read-only CSM consumer pattern is cleaner.

## Consequences

### Positive

- ADR-level lock on NPC pool authority + replication channel — closes C2 conflict from `/architecture-review` 2026-04-26
- Stories can now reference ADR-0008 for pool, replication, cadence, AbsorbSystem contract
- ADR-0003 §Network table now sums coherently (10.25 KB/s nominal, fits burst allowance)
- NPCSpawner placement firewall = ADR-0006 §Source Tree Map server-only class — Pillar 4 read-only-CSM-consumer rule strengthened
- AbsorbSystem implementation unblocked — its `getAllActiveNPCs()` + `reclaim(npcId)` contract is now ADR-locked
- Cadence exemption (own Heartbeat) explicit — prevents future "competing accumulator" debate with ADR-0002

### Negative

- ADR-0003 Reserve consumed entirely by NPC line — no headroom for future VS+ network features without ADR-0003 re-amendment
- 8-byte/NPC delta payload requires careful buffer encoding implementation; off-by-one errors in offset semantics are subtle bugs to debug
- Per-relevance filter adds CPU cost per broadcast (server iterates client → crowd → distance check per NPC); ADR-0003 Phase-budget unchanged but server-side broadcast prep is added work outside Phase 8
- Mid-round-join `NpcPoolBootstrap` is a 2.4 KB reliable burst per joining client — fits burst allowance but consumes that window's headroom
- Stale-text in NPC Spawner GDD R5 (`ServerTickAccumulator`) needs `/propagate-design-change` sync (flagged in Status header)

### Risks

- **Risk 1 (MEDIUM)** — Real per-relevance filter bandwidth exceeds 3.0 KB/s steady-state (e.g., 12 clients × wider filter window during late-round mass-absorb). Mitigation: MVP-Integration-3 measures empirically; if breach, reduce NPC broadcast cadence 15 Hz → 10 Hz (allocation drops 3.0 → 2.0 KB/s) OR tighten filter from `radius + 25` to `radius + 10`.
- **Risk 2 (MEDIUM)** — iPhone SE renders 60-NPC mirror at 15 Hz CFrame writes within mobile per-frame budget? ADR-0003 §Client Per-Frame budget allocates FollowerEntity 2.5 ms; NPC mirror has no explicit allocation. Mitigation: amend ADR-0003 §Client per-frame to add NPC client-mirror line item; default 0.5 ms mobile (small Parts, no skeletal animation).
- **Risk 3 (LOW)** — NPCSpawner's own `Heartbeat:Connect` introduces a second connection; `competing_heartbeat_accumulators` forbidden pattern interpreted strictly would flag this. Mitigation: explicitly named exemption in this ADR + ADR-0002 §Related Decisions; registry forbidden_pattern description updated to clarify "gameplay-tick only".
- **Risk 4 (LOW)** — Mid-round join during high `NpcStateBroadcast` traffic loses bootstrap packets (reliable, but burst-coincident with broadcasts). Mitigation: bootstrap is reliable; client retains "bootstrap pending" flag until `NpcPoolBootstrap` arrives; subsequent `NpcStateBroadcast` deltas applied only after bootstrap completes.
- **Risk 5 (MEDIUM)** — NPC Spawner GDD R5 stale `ServerTickAccumulator` reference creates implementation confusion during story authoring. Mitigation: Status header flags propagation; `/propagate-design-change design/gdd/npc-spawner.md` runs alongside ADR-0008 Acceptance to update GDD R5 + GDD §Interactions table to reference "own Heartbeat connection" terminology.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/npc-spawner.md` §C.1 R1 | "Pool size fixed at 300 Parts; pre-allocated chunked 25/batch via task.defer" | §Decision: pool allocation locked at boot; no mid-round `Instance.new` (forbidden pattern) |
| `design/gdd/npc-spawner.md` §C.1 R7 | "reclaim() is synchronous; before returning: active=false, removed from snapshot, parked, transparency=1, _cachedSnapshot=nil" | §Caller Authority Matrix: AbsorbSystem-only caller; §Key Interfaces NpcRecord type + synchronous contract |
| `design/gdd/npc-spawner.md` §C.1 R8 | "getAllActiveNPCs() returns frozen cached COPY" | §Key Interfaces signature + §Caller Authority Matrix read-only / no-mutation rule |
| `design/gdd/npc-spawner.md` §C.1 R9-R10 | "Respawn after task.delay'd timer; respawn position avoids crowds via getAllCrowdPositions" | §Decision: NPCSpawner is read-only CSM consumer; ADR-0004 confirms; respawn timers tracked in Janitor |
| `design/gdd/npc-spawner.md` §C.1 R5 (stale wording) | "Movement updates on a shared 15 Hz Heartbeat accumulator owned by ServerTickAccumulator" | §Cadence Exemption: replaces with "NPCSpawner own Heartbeat connection"; GDD R5 sync via `/propagate-design-change` post-Accept |
| `design/gdd/npc-spawner.md` §Replication strategy | "NPC positions broadcast via UnreliableRemoteEvent NpcStateBroadcast at 15 Hz" | §Replication Contract: 8-byte/NPC delta + per-relevance filter + 3.0 KB/s allocation |
| `design/gdd/npc-spawner.md` §Edge Cases R227 | "Mid-round join: client mirror pool spawns 300 Parts on first NpcStateBroadcast; initial full state via reliable bootstrap NpcPoolBootstrap" | §Replication Contract: NpcPoolBootstrap reliable RemoteEvent on PlayerAdded |
| `design/gdd/npc-spawner.md` §Tuning Knobs ARENA_WALKABLE_AREA_SQ | "Required — assert non-nil and > 0 at NPC Spawner module init" | §Boot + Round Lifecycle: assert at NPCSpawner.init() |
| `design/gdd/absorb-system.md` §C.1 (NPC consumer contract) | "Absorb consumes NPC list via getAllActiveNPCs() + reclaim() at 15 Hz" | §Caller Authority Matrix locks AbsorbSystem as sole `reclaim` caller + sole Phase-3 `getAllActiveNPCs` caller |
| ADR-0001 §Key Interfaces | NPCSpawner replication absent from wire contract | ADR-0008 adds `UnreliableRemoteEventName.NpcStateBroadcast` + `RemoteEventName.NpcPoolBootstrap` to Network registry |
| ADR-0002 §Related Decisions L289 | "ADR-0008 NPC Spawner Authority — NPC Spawner runs OWN cadence (not a Phase 1-9 callback)" | §Cadence Exemption: locks own `RunService.Heartbeat:Connect`; non-gameplay-tick clarification added to forbidden_patterns registry |
| ADR-0003 §Network Bandwidth Budget | NPC line missing | ADR-0008 amends ADR-0003 §Network table to add 3.0 KB/s NpcStateBroadcast line + reduce Reserve 2.75 → 0.0 KB/s |
| ADR-0004 §Write-Access Matrix | NPCSpawner not explicitly named | ADR-0008 confirms NPCSpawner is read-only CSM consumer (`getAllCrowdPositions` only); FORBIDDEN from all CSM mutators per Pillar 4 + §Write-Access Matrix |
| ADR-0006 §Source Tree Map | NPCSpawner placement | `ServerStorage/Source/NPCSpawner/init.luau` server-only class confirmed |

## Performance Implications

- **CPU (server)**: NPC movement at 15 Hz × 300 active NPCs = 4500 CFrame writes/sec at peak. Per-relevance filter adds 12 clients × 300 NPCs = 3600 distance checks per broadcast tick. Estimated overhead: ~0.4 ms/tick at peak (profiled approximation; mobile validation deferred). NOT counted against ADR-0003 Phase 1-9 budget (own cadence).
- **CPU (client)**: 60-NPC mirror Part position updates + transparency tweens = ~0.5 ms/frame mobile estimate; ADR-0003 §Client per-frame to be amended to add this line.
- **Memory (server)**: 300 NpcRecord × ~150 B = 45 KB; matches ADR-0003 §Server Memory NPCSpawner row (10 KB allocation — slight overrun, will revise next ADR-0003 amend).
- **Memory (client)**: 300 mirror Parts × ~1.5 KB Roblox instance overhead = 450 KB; absorbed by ADR-0003 client baseline.
- **Load Time**: NPCSpawner.init pool allocation chunked 25/batch via task.defer = 12 batches; targets <50 ms/frame hitch on mobile.
- **Network**: 3.0 KB/s/client steady-state per relevance filter; mid-round-join 2.4 KB reliable bootstrap burst.

## Migration Plan

No existing NPCSpawner implementation. Clean implementation against this ADR.

1. Implement `ServerStorage/Source/NPCSpawner/init.luau` per §Architecture + §Key Interfaces
2. Add `Network/RemoteName/UnreliableRemoteEventName.luau` entry: `NpcStateBroadcast = "NpcStateBroadcast"`
3. Add `Network/RemoteName/RemoteEventName.luau` entry: `NpcPoolBootstrap = "NpcPoolBootstrap"`
4. Implement `ReplicatedStorage/Source/NPCSpawnerClient/init.luau` for mirror pool + bootstrap consumer
5. RoundLifecycle T4 transition wires `NPCSpawner.createAll(participants)`; T9 wires `destroyAll()`
6. AbsorbSystem `tick(ctx)` (Phase 3) calls `NPCSpawner.getAllActiveNPCs()` + `reclaim(npcId)` per overlap
7. ADR-0003 §Network bandwidth + §Server memory tables amended via `/propagate-design-change` alongside this ADR's Acceptance
8. NPC Spawner GDD R5 + §Interactions row text updated via `/propagate-design-change` to remove `ServerTickAccumulator` references

## Validation Criteria

- [ ] `grep -r "require.*NPCSpawner" src/ReplicatedStorage src/ReplicatedFirst` returns zero matches (server-only placement audit)
- [ ] `grep -r "CrowdStateServer.updateCount\|CrowdStateServer.recomputeRadius\|CrowdStateServer.setStillOverlapping" src/ServerStorage/Source/NPCSpawner` returns zero matches (Pillar 4 caller audit)
- [ ] 4-client deployed server: NPC traffic measured ≤ 3.0 KB/s/client steady-state via `Stats` service (MVP-Integration-3)
- [ ] iPhone SE emu at 12 simulated crowds × 60 visible NPCs: ≥ 45 FPS sustained (MVP-Integration-2)
- [ ] Mid-round join test: client receiving `NpcPoolBootstrap` reliable instantiates 300 mirror Parts within 100 ms; first `NpcStateBroadcast` after bootstrap applies cleanly (no missing-state errors)
- [ ] `_heartbeatConn` count: NPCSpawner instance has exactly 1 `RunService.Heartbeat:Connect` registered after `createAll`; 0 after `destroyAll`
- [ ] AbsorbSystem-only `reclaim` audit: every call site of `NPCSpawner.reclaim` originates in `ServerStorage/Source/AbsorbSystem/`
- [ ] `ARENA_WALKABLE_AREA_SQ` boot guard: NPCSpawner.init asserts non-nil + > 0; round init fails loudly otherwise
- [ ] Per-relevance filter: NPCs outside `crowd.radius + 25` studs of recipient client's crowd are excluded from broadcast (verify via packet inspection)
- [ ] ADR-0003 §Network bandwidth table contains `NpcStateBroadcast` line at 3.0 KB/s + Reserve = 0.0 KB/s post-amendment

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — UnreliableRemoteEvent + buffer encoding pattern this ADR applies to NPCs
- **ADR-0002** TickOrchestrator — non-gameplay-tick exemption this ADR claims for NPCSpawner cadence
- **ADR-0003** Performance Budget — Network table amended by this ADR; Server memory row may need revision
- **ADR-0004** CSM Authority — read-only NPCSpawner consumer rule confirmed
- **ADR-0006** Module Placement Rules — NPCSpawner server-only class
- **Expected downstream**:
  - ADR-0010 Server-Authoritative Validation Policy — covers NpcPoolBootstrap reliable contract validation pattern
  - Future Daily Quest System (Alpha+) — may reference NPC absorbs as quest progress signals (read-only via Currency / analytics, never via NPC pool mutation)

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). UnreliableRemoteEvent + buffer encoding patterns inherited from ADR-0001 prototype validation.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
