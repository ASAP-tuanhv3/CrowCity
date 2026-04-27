# Crowdsmith — Master Architecture

## Document Status

- **Version**: 1.0 (initial draft complete)
- **Last Updated**: 2026-04-24
- **Engine**: Roblox (Luau --!strict); engine ref pinned 2026-04-20
- **Scope**: MVP only (16 MVP systems — 7 template-provided + 9 new). VS/Alpha/V1.5 deferred.
- **GDDs Covered**: game-concept, systems-index, crowd-state-manager, match-state-machine, round-lifecycle, crowd-replication-strategy, follower-entity, follower-lod-manager, npc-spawner, absorb-system, crowd-collision-resolution, chest-system, relic-system, hud, player-nameplate, vfx-manager
- **ADRs Referenced**: ADR-0001 (Crowd Replication Strategy — Proposed)
- **Review Mode**: lean — TD self-review only; LP-FEASIBILITY skipped
- **Technical Director Sign-Off (TD-ARCHITECTURE)**: APPROVED WITH CONCERNS — 2026-04-24. Concerns: (C1) TR registry deferred to `/architecture-review`; (C2) ADR-0001 Proposed → Accepted pending review pass; (C3) OQ-1 mobile Heartbeat + OQ-2 multi-client bandwidth empirical validation deferred to first MVP integration; (C4) 4 must-have ADRs (0002, 0003, 0004, 0006) must land before any MVP coding story.
- **Lead Programmer Feasibility (LP-FEASIBILITY)**: skipped — lean mode

---

## 1. Engine Knowledge Gap Summary

**Engine**: Roblox (live-service, no version number). Pinned 2026-04-20 per `docs/engine-reference/roblox/VERSION.md`.
**LLM cutoff**: May 2025 — ~12 months of Roblox + Luau API drift post-cutoff.
**Overall risk**: MEDIUM. Specific high-risk APIs are flagged inline in §3 Module Ownership.

### HIGH RISK domains — verify against engine reference before committing code

| Domain | Why HIGH | Post-cutoff anchors | Systems affected |
|---|---|---|---|
| Networking replication | `UnreliableRemoteEvent` GA post-cutoff; `buffer` type replication semantics post-cutoff; MVP mandates buffer encoding per ADR-0001 amend 2026-04-24 | `docs/engine-reference/roblox/replication-best-practices.md` | Crowd Replication Strategy, Crowd State Manager (broadcast), all client mirrors |
| Luau type system | New Type Solver GA Nov 2025; `read` keyword; type functions; inferred-table behavior change | `docs/engine-reference/roblox/luau-type-system.md` | Every `.luau` file (all systems) |

### MEDIUM RISK domains — verify key APIs

| Domain | Why MEDIUM | Systems affected |
|---|---|---|
| Heartbeat jitter on mobile | Prototype desktop-only; iPhone SE scheduling untested at 15 Hz × 9-phase TickOrchestrator | TickOrchestrator (spin-off), CSM broadcast, all server-tick systems |
| BillboardGui + SurfaceGui render cost at scale | Unknown per-instance cost at 8-12 simultaneous Nameplates + 6-11 chest billboards | Player Nameplate, Chest Billboard, HUD |
| CollectionService tag-scan cost | Tag scan on Add/Remove at MVP entity count (~60 NPCs + 9 chests + 8 zones + 2400 followers) untested | NPC Spawner, Chest System, Zone Handler, ComponentCreator |
| ParticleEmitter pooling semantics | 2000-particle ceiling untested; pool reset on round-end cross-checked against Debris service | VFX Manager |
| ProfileStore on round-scoped ephemeral state | Correctly bypassed — flagged so no one regresses | CSM (must NOT persist), Round Lifecycle (must NOT persist), Chest (must NOT persist) |

### LOW RISK domains — in training data, template-proven

- ProfileStore (vendored; session-lock + BindToClose proven)
- PlayerData server/client split (template-provided)
- ComponentCreator (template-provided)
- Zone Handler (template-provided)
- Collision Groups (template-provided)
- `RunService.Heartbeat` accumulator pattern (documented in CSM §E implementation note)

### Per-system HIGH/MEDIUM risk cross-reference

| System | Risk | Primary domain |
|---|---|---|
| Crowd Replication Strategy | HIGH | Networking |
| Crowd State Manager | HIGH | Networking (broadcast path) + Core (state machine authority) |
| Follower Entity | MEDIUM | Rendering (non-Humanoid rig scale) |
| Follower LOD Manager | MEDIUM | Rendering (swap cost + cull timing) |
| NPC Spawner | MEDIUM | Core (CollectionService scan) |
| Absorb System | LOW | Core (proximity query) |
| Crowd Collision Resolution | MEDIUM | Core (O(p²) pair iteration + tick authority) |
| Chest System | MEDIUM | Core (7-state machine + 6-guard pipeline + ProximityPrompt at scale) |
| Relic System | LOW | Core (framework; 3 reference relics MVP) |
| Match State Machine | MEDIUM | Core (9-phase TickOrchestrator dispatch) |
| Round Lifecycle | LOW | Core (coordinator) |
| VFX Manager | MEDIUM | Rendering (2000-particle ceiling) |
| HUD | MEDIUM | UI (11 widgets × 7 states) |
| Player Nameplate | MEDIUM | UI (BillboardGui at scale) |
| Chest Billboard | MEDIUM | UI (BillboardGui per chest) |

All HIGH-risk decisions in this document are flagged inline with an engine reference citation.

---

## 2. System Layer Map

Four-layer cut. Platform folded into Foundation (Roblox owns the platform; no app-level platform concerns). Follower Entity is intentionally bi-layer: server owns roster (count/hue — part of CSM record, not a separate server entity), client owns visual simulation.

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION — UI, VFX, client render, audio               │
│  HUD, Player Nameplate, Chest Billboard, VFX Manager,       │
│  Follower LOD Manager, CrowdStateClient, MatchStateClient   │
├─────────────────────────────────────────────────────────────┤
│  FEATURE — gameplay systems (per-round, per-player logic)   │
│  NPC Spawner, Follower Entity (client-sim side),            │
│  Absorb System, Crowd Collision Resolution,                 │
│  Chest System, Relic System                                 │
├─────────────────────────────────────────────────────────────┤
│  CORE — authority, state, orchestration, replication        │
│  TickOrchestrator, Crowd State Manager (server),            │
│  Match State Machine, Round Lifecycle,                      │
│  Crowd Replication (broadcast path), Network wrapper        │
├─────────────────────────────────────────────────────────────┤
│  FOUNDATION — engine integration, persistence, primitives   │
│  PlayerData/ProfileStore, Network remote registry,          │
│  UIHandler, ComponentCreator, Zone Handler,                 │
│  Collision Groups, AssetId Registry, SharedConstants        │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Foundation Layer

| System | Side | Source | Engine-risk | Notes |
|---|---|---|---|---|
| Network Layer (template) | shared | `ReplicatedStorage/Source/Network/init.luau` | LOW | **Prereq**: add `UnreliableRemoteEvent` wrapper + `UnreliableRemoteEventName` enum (CSM §E implementation note) |
| PlayerData / ProfileStore (template) | server write + client read | `ReplicatedStorage/Dependencies/ProfileStore.luau` + `PlayerDataServer` + `PlayerDataClient` | LOW | Bypass for ephemeral round state (Pillar 3) |
| UIHandler (template) | client | `ReplicatedStorage/Source/UIHandler` | LOW | Layer registration for HUD, Nameplate, Chest Billboard, Draft Modal |
| Currency — Coins (template) | server write + client read | template-provided | LOW | Sink: `grantMatchRewards` at MSM T6/T7/T8 |
| Zone Handler (template) | shared | template-provided | MEDIUM | CollectionService scale: 8 zones MVP |
| ComponentCreator (template) | client (primary) | `ReplicatedStorage/Source/ComponentCreator.luau` | LOW | Attach path for Chest, Follower (client), NPC |
| Collision Groups (template) | server | template-provided | LOW | Follower-NPC-Chest-Player group matrix |
| AssetId Registry | shared | `SharedConstants/AssetId.luau` (new enum) | LOW | Gates all model/texture/particle refs; art bible §8.9 locked |

### 2.2 Core Layer

| System | Side | Source | Engine-risk | Notes |
|---|---|---|---|---|
| TickOrchestrator | server | `ServerStorage/Source/TickOrchestrator/init.luau` (new) | MEDIUM | Single Heartbeat accumulator, 9-phase dispatch. Jitter on mobile flagged. |
| Crowd State Manager (server) | server | `ServerStorage/Source/CrowdStateServer/init.luau` (new) | HIGH | Authoritative hub. 4-caller write contract. Pillar 4 anti-P2W contract. |
| Match State Machine | server | `ServerStorage/Source/MatchStateServer/init.luau` (new) | MEDIUM | 7 states + T11 BindToClose. Phase 6 + Phase 7 consumer. |
| Round Lifecycle | server | `ServerStorage/Source/RoundLifecycle/init.luau` (new) | LOW | Janitor-scoped signal subs. Peak-dominance placement (F3). |
| Crowd Replication (broadcast path) | server send + shared wire | lives inside CSM server (`broadcastAll`) + CrowdStateClient mirror | HIGH | 15 Hz UnreliableRemoteEvent + `buffer` encoding MANDATORY per ADR-0001 amend 2026-04-24 |
| Network wrapper | shared | Foundation layer, repeated here since it's the sole wire path | LOW | All remotes go through `Network.fireServer` / `connectEvent` |

### 2.3 Feature Layer

| System | Side | Source | Engine-risk | Notes |
|---|---|---|---|---|
| NPC Spawner | server | `ServerStorage/Source/NPCSpawner/init.luau` (new) | MEDIUM | CollectionService scan; min-distance gate via CSM.getAllCrowdPositions |
| Follower Entity (server roster) | server | No new module — lives as CSM record fields (count/hue/activeRelics) | N/A | Per ADR-0001: no per-follower server entity |
| Follower Entity (client simulation) | client | `ReplicatedStorage/Source/FollowerEntity/Client.luau` (new) | MEDIUM | Boids flock @ RenderStepped; non-Humanoid CFrame rig (2-Part Body+Hat per FE GDD §C.1) |
| Absorb System | server | `ServerStorage/Source/AbsorbSystem/init.luau` (new) | LOW | Phase 3; overlap query @ 15 Hz; `updateCount(+1)` per NPC |
| Crowd Collision Resolution | server | `ServerStorage/Source/CollisionResolver/init.luau` (new) | MEDIUM | Phase 1; O(p²)=66 pairs; F3/F4 drip; emits peel buffer |
| Chest System | server (authority) + client (draft modal) | `ServerStorage/Source/ChestSystem/init.luau` + `ReplicatedStorage/Source/ChestDraftClient.luau` (new) | MEDIUM | 7-state per-chest; 6-guard pipeline; ProximityPrompt at 9 MVP chests |
| Relic System | server | `ServerStorage/Source/RelicSystem/init.luau` (new) | LOW | Framework + 3 reference relics (TollBreaker, Surge, Wingspan) |

### 2.4 Presentation Layer

| System | Side | Source | Engine-risk | Notes |
|---|---|---|---|---|
| CrowdStateClient | client | `ReplicatedStorage/Source/CrowdStateClient/init.luau` (new) | HIGH | Read-only mirror; lastReceivedTick stale-packet defense (CRS F4) |
| MatchStateClient | client | `ReplicatedStorage/Source/MatchStateClient/init.luau` (new) | LOW | F6 timer interp with clock-offset + RTT correction |
| Follower LOD Manager | client | `ReplicatedStorage/Source/FollowerLODManager/init.luau` (new) | MEDIUM | 10 Hz swap; 4-tier distance cap (80/30/15/1 billboard) |
| VFX Manager | client singleton | `ReplicatedStorage/Source/VFXManager/init.luau` (new) | MEDIUM | 2000-particle ceiling; 2-tier suppression with hysteresis; 4-state machine |
| HUD | client | `ReplicatedStorage/Source/UI/UILayers/HUD/` (new) | MEDIUM | 11 widgets × 7 states; MAX CROWD debounce owned here |
| Player Nameplate | client | `ReplicatedStorage/Source/PlayerNameplate/Client.luau` (new) | MEDIUM | BillboardGui per character; 5-state; offset-tier + font-step formulas |
| Chest Billboard | client | `ReplicatedStorage/Source/ChestBillboard/Client.luau` (new) | MEDIUM | BillboardGui per chest; effectiveToll display |

### 2.5 Layer-boundary rules

- **No upward imports**: Foundation never requires Core/Feature/Presentation; Core never requires Feature/Presentation; Feature never requires Presentation.
- **Side rule**: client modules (Presentation + client-side Feature) MUST NOT `require` from `ServerStorage`.
- **Broadcast path crosses layers**: Core (CSM server broadcast) → wire → Presentation (CrowdStateClient). Direction is strictly server-to-client.
- **Phase rule**: server-tick authority lives only in Core (TickOrchestrator). Feature systems expose `tick(ctx)` callbacks; they never register their own Heartbeat.
- **Pillar 4 anti-P2W contract** (CSM §Core Rules): cosmetic systems (Skin System, VS+) MUST NOT appear in Core as CSM write-callers. Enforced as architecture-level invariant.

---

## 3. Module Ownership

For each module: owns (exclusive data/state), exposes (public API), consumes (upstream deps), engine APIs (with risk flag).

### 3.1 Foundation

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| Network | RemoteEvent + UnreliableRemoteEvent instance registry | `fireServer`, `fireAllClients`, `fireClient`, `connectEvent`, `connectUnreliableEvent` | — | `ReplicatedStorage`, `RemoteEvent`, `UnreliableRemoteEvent` ⚠️ post-cutoff |
| PlayerDataServer | ProfileStore store handle + per-player profile cache | `loadProfileAsync`, `getValue`, `updateValue`, `setValue`, `onPlayerRemovingAsync` | Network (`PlayerDataUpdated`) | ProfileStore (vendored), `BindToClose` |
| PlayerDataClient | read-only client cache | `getValue`, `PlayerDataUpdated:Connect` | Network | — |
| UIHandler | layer stack + current Menu layer | `registerLayer`, `openLayer`, `closeLayer` | — | `StarterGui`, `ScreenGui` |
| Currency (Coins) | coin balance in PlayerData | `grantCoins`, `deductCoins`, `grantMatchRewards(placements)` | PlayerDataServer | — |
| ZoneHandler | zone-tag set per player | `getZone`, `ZoneEntered/Exited` signals | CollectionService | `CollectionService`, `Part.Touched`, attributes |
| ComponentCreator | tag→component-class registry | `ComponentCreator.new(tag, ComponentClass):listen()` | CollectionService | `CollectionService.GetInstanceAddedSignal` |
| CollisionGroups | group-name registry + pair matrix | `setGroup`, `setPairRule` | — | `PhysicsService` |
| AssetId | enum {skin, particle, mesh, sound} → `rbxassetid://...` | lookup map | — | — |

### 3.2 Core

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| TickOrchestrator | 15 Hz accumulator + 9-phase callback table + tickCount | `start`, `stop`, `getCurrentTick`, `registerPhase` (boot-only) | Phase 1-9 modules | `RunService.Heartbeat` ⚠️ MEDIUM (mobile jitter) |
| CrowdStateServer | `_crowds: {[crowdId]: CrowdRecord}` + per-crowd state/tick/timer_start/stillOverlapping | `create`, `destroy`, `updateCount(delta, source)`, `recomputeRadius`, `get`, `getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`, `stateEvaluate()` (Phase 5), `broadcastAll()` (Phase 8), `CountChanged` BindableEvent | Network (`CrowdStateBroadcast` + 5 reliable remotes), Character.HumanoidRootPart read | `UnreliableRemoteEvent` ⚠️ HIGH, `buffer.*` ⚠️ HIGH, `BindableEvent`, `os.clock` |
| MatchStateServer | match state enum + per-state timer + participationFlag table | `get`, `getParticipation`, `transitionTo`, `timerCheck` (Phase 6), `eliminationConsumer` (Phase 7), `GetParticipation` RemoteFunction | Network (`MatchStateChanged`, `ParticipationChanged`), `Players.PlayerAdded/PlayerRemoving`, `game:BindToClose`, CSM `CrowdEliminated`, RoundLifecycle, RelicSystem.clearAll, Currency.grantMatchRewards | `RemoteEvent`, `RemoteFunction`, `game:BindToClose`, `tick()` |
| RoundLifecycle | `_crowds[crowdId]` aux (peakCount/peakTimestamp/finalCount/eliminationTime) + `_participants` snapshot + `_winnerId` + Janitor | `createAll(players)`, `setWinner(crowdId?)`, `getPlacements()`, `getPeakTimestamp(crowdId)`, `destroyAll()` | CSM.create/destroy + `CrowdEliminated` RemoteEvent + `CountChanged` BindableEvent; `Players.PlayerRemoving` | `Packages.janitor`, `os.clock`, `table.sort` |
| Crowd Replication (broadcast path) | 15 Hz buffer-encoded wire format (lives inside CSM.broadcastAll) | `CrowdStateBroadcast` UnreliableRemoteEvent instance + encoder/decoder helpers | CSM `_crowds` | `UnreliableRemoteEvent` ⚠️ HIGH, `buffer.create/writeu*/writef32` ⚠️ HIGH |

### 3.3 Feature

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| NPCSpawner | `_neutrals: {[NPCId]: NPCRecord}` + spawn-point table | `spawnOne`, `despawnOne`, `getAllNeutrals()`, `tick(ctx)` (own cadence, not 15 Hz phase) | CSM.getAllCrowdPositions (min-distance gate), Level Design spawn tags | `CollectionService`, `Vector3`, `Random` |
| FollowerEntity (server roster) | — (no module; roster lives as CSM record fields) | — | — | — |
| FollowerEntity (client sim) | per-crowd flock state (per-follower CFrame array + rendered Part subset + billboard impostor) | `FollowerEntity.new(crowdId)`, `update(dt)`, `destroy` | CrowdStateClient.get, FollowerLODManager render cap, VFX peel dispatch | `RunService.RenderStepped`, `Instance.new("Part")`, `CFrame`, pooled Part cloning |
| AbsorbSystem | per-tick NPC candidate list | `tick(ctx)` (Phase 3) | NPCSpawner.getAllNeutrals, CSM.getAllActive, CSM.updateCount(+1) | distance math |
| CollisionResolver | per-tick overlap pair list + peel buffer | `tick(ctx, outPairs, outPeel)` (Phase 1) | CSM.getAllActive (read refs), CSM.updateCount (±drip), CSM.setStillOverlapping | pure math |
| ChestSystem | `_chests: {[chestId]: ChestComponent}` + `_crowdModifiers: {[crowdId]: {modifierKey: {value, type}}}` | `createAll`, `destroyAll`, `queryChestToll`, `setRelicModifier`, `clearRelicModifier`, `tick(ctx)` (Phase 4) | CSM.get, CSM.updateCount(-toll), RelicSystem.grant, MatchStateServer.get | `CollectionService` (ChestTag), `ProximityPrompt`, attributes |
| RelicSystem | `RelicRegistry` (static) + per-crowd active relics + RelicEffectHandler | `grant(crowdId, specId)`, `expire(crowdId, specId)`, `clearAll`, `queryTollMultiplier`, `tick(ctx)` (Phase 2) | CSM.recomputeRadius, CSM.updateCount, ChestSystem.setRelicModifier | `Packages.janitor` per-relic |

### 3.4 Presentation

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| CrowdStateClient | client `_crowds` mirror + `lastReceivedTick` per crowd | `get(crowdId)`, `CrowdCreated/Destroyed/Eliminated/RelicChanged` signals | Network (CrowdStateBroadcast unreliable + 5 reliable) | `buffer.readu*/readf32` ⚠️ HIGH |
| MatchStateClient | local state + clockOffset cache | `get()`, `displayedSeconds()` (F6), `reconcile(payload)` | Network (`MatchStateChanged`), `Players.LocalPlayer.Ping` | `tick()`, `math.clamp` |
| FollowerLODManager | per-crowd render-tier decision + swap timestamps | `getRenderCap(crowdId, distance)`, 10 Hz swap loop | CrowdStateClient, Camera.CFrame | `RunService.Heartbeat` (10 Hz subdivided) |
| VFXManager | `_particleCount` + 4 pools + `_recentPickEvents` + `_lastContactFX` | `playEffect(effectId, context)` sole entry | Network (9 reliable VFX remotes), AssetId, CrowdStateClient (crowd-relative anchor) | `ParticleEmitter`, `Debris:AddItem`, `TweenService`, `task.delay` |
| HUD | 11 widget instances + MAX-CROWD debounce state | UILayer setup/teardown, widget visibility per match state | CrowdStateClient, MatchStateClient, RelicSystem client mirror | `ScreenGui`, `UIStroke`, `UIListLayout`, `TextLabel` |
| PlayerNameplate | per-character BillboardGui + 5-state | `new(character)`, `destroy` | CrowdStateClient (count/hue), `CrowdCreated`, camera distance | `BillboardGui`, `UIStroke` |
| ChestBillboard | per-chest BillboardGui | `new(chestPart)`, `destroy` | ChestSystem.queryChestToll + `ChestStateChanged`, CrowdStateClient | `BillboardGui`, attributes |

### 3.5 Dependency diagram

```text
                   TickOrchestrator (server, Phase 1..9)
                          │
        ┌──────┬──────────┼──────────┬───────────┬───────────┐
        ▼      ▼          ▼          ▼           ▼           ▼
    Collision Relic    Absorb     Chest      CSM eval    CSM broadcast
    Resolver  System   System     System     (Phase 5)    (Phase 8)
        │      │         │          │           │             │
        └──────┴─────────┴──────────┴───────────┘             │
               ▼ writes                                       │
           CrowdStateServer (Core authority)                  │
               │ CrowdEliminated signal                       │
               ▼                                              │
           RoundLifecycle ──── MatchStateServer (Phase 6/7)   │
                                     │ MatchStateChanged      │
                                     ▼                        │
               ════════════ wire (Network) ═════════════      │
                                     │                        │
                                     ▼                        ▼
                            MatchStateClient         CrowdStateClient
                                     │                        │
              ┌──────┬────────┬──────┼─────┬─────────┬────────┤
              ▼      ▼        ▼      ▼     ▼         ▼        ▼
             HUD  Nameplate Chest  Follower Follower VFX     (Audio VS+)
                           Billboard Entity   LOD    Manager
```

### 3.6 Engine-API risk register

- ⚠️ **`UnreliableRemoteEvent`** — Network wrapper prereq + CSM broadcast + CrowdStateClient. GA post-cutoff per `replication-best-practices.md`. Verified.
- ⚠️ **`buffer.create / readu8|u16|u64 / readf32 / writef32 / writeu*`** — MVP mandate per ADR-0001 (amend 2026-04-24). Source: `luau-type-system.md` + `replication-best-practices.md` §buffer. Multi-client bandwidth verification deferred to first MVP integration.
- ⚠️ **`RunService.Heartbeat` 15 Hz accumulator on mobile** — iPhone SE scheduling untested. Risk mitigation: measure in first mobile integration; fallback to fixed-rate scheduler if jitter >5ms.
- ⚠️ **`ProximityPrompt.MaxActivationDistance = 20`** — clears count=300 Wingspan crowd radius 16.24 studs. Validate Chest integration.
- ⚠️ **`CollectionService` tag-scan** — NPC Spawner + Chest System + Zone Handler. Expected entity counts: ~60 NPCs + 9 chests + 8 zones. LOW at this scale, but flagged for benchmark.
- ⚠️ **`BillboardGui` render at scale** — 8-12 Nameplates + 6-11 Chest Billboards simultaneously. LOW-MEDIUM.
- ⚠️ **`ParticleEmitter` with pooling** — VFX Manager 2000-particle ceiling + 4-pool strategy. MEDIUM.

---

## 4. Data Flow

Five scenarios cover every data-transfer pattern in MVP. All cross-module communication is either (a) direct function call within a layer, (b) Roblox signal (`BindableEvent` server-only or `RemoteEvent` across wire), or (c) read from a cached record.

### 4.1 Scenario A — Server 15 Hz Gameplay Tick (heartbeat of the game)

```text
RunService.Heartbeat (dt) ──► TickOrchestrator (_accumulator += dt)
  │ while _accumulator >= 1/15:
  │   _accumulator -= 1/15; tickCount++
  │
  ├─[P1] CollisionResolver.tick(ctx, outPairs, outPeel)
  │         ├ reads  CSM.getAllActive()           (snapshot refs)
  │         ├ writes CSM.setStillOverlapping(id, bool)
  │         └ writes CSM.updateCount(id, ±drip, "Collision")
  │
  ├─[P2] RelicEffectHandler.tick(ctx)
  │         ├ iterates per-crowd activeRelics
  │         ├ writes CSM.updateCount(id, delta, "Relic")
  │         └ writes CSM.recomputeRadius(id, mult)   (Wingspan)
  │
  ├─[P3] AbsorbSystem.tick(ctx)
  │         ├ reads  NPCSpawner.getAllNeutrals()
  │         ├ reads  CSM.getAllActive()
  │         ├ writes CSM.updateCount(id, +1, "Absorb")
  │         └ writes NPCSpawner.despawnOne(npcId)
  │
  ├─[P4] ChestSystem.tick(ctx)
  │         ├ reads  CSM.get(id)                    (guard 3c state==Active)
  │         ├ evaluates 6-guard pipeline
  │         ├ writes CSM.updateCount(id, -effectiveToll, "Chest")
  │         └ fires RelicEffectHandler.grant(id, specId) on pick
  │
  ├─[P5] CSM.stateEvaluate()
  │         ├ F7 grace-timer check on GraceWindow crowds
  │         ├ Active → GraceWindow (count hit 1 + overlap)
  │         ├ GraceWindow → Active (overlap cleared)
  │         ├ GraceWindow → Eliminated (timer expired + still overlapping)
  │         └ fires CrowdEliminated reliable RemoteEvent per transition
  │
  ├─[P6] MatchStateServer.timerCheck()
  │         └ T7 if elapsed >= 300s and Active → transitionTo("Result")
  │             (winner via F4: count → peakTimestamp → UserId)
  │
  ├─[P7] MatchStateServer.eliminationConsumer()
  │         ├ drains CrowdEliminated signals queued in P5
  │         └ T6 if numActiveNonEliminated <= 1 and matchState==Active
  │             (double-signal guard — matchState!=Active silently drops)
  │
  ├─[P8] CSM.broadcastAll()
  │         ├ builds buffer payload (30 B/crowd × #active)
  │         │   crowdId u64 | tick u16 | pos f32[3] | radius f32
  │         │   | count u16 | hue u8 | state u8
  │         └ Network.fireAllClients(CrowdStateBroadcast, buf)
  │             via UnreliableRemoteEvent ⚠️
  │
  └─[P9] PeelDispatcher.flush(outPeel)
           └ Network.fireClient(ChestPeelOff, player, {...}) batched
```

- **Thread boundary**: none within server tick. Single Luau coroutine resume per Heartbeat.
- **Synchronisation**: purely sequential per-phase; no locks, no futures, no yields.
- **Atomicity guarantee**: all 9 phases run before next Heartbeat. Clients never observe mid-tick state.

### 4.2 Scenario B — Absorb Round-Trip (server-initiated, no client request)

```text
Client                                Wire                Server
──────────────────────────────────────────────────────────────────────
(npc visible within radius)                               NPCSpawner owns NPC at pos P
                                                          AbsorbSystem.tick (Phase 3):
                                                            candidate = proximity check
                                                            CSM.updateCount(+1, "Absorb")
                                                            NPCSpawner.despawnOne
                                                            CSM.CountChanged signal
                                                          CSM.broadcastAll (Phase 8):
                                                            buffer payload count+1
                             ◄──UnreliableRemoteEvent──
CrowdStateClient:readBuffer
  _crowds[ownId].count = 51
  fires local CountUpdated
    ├► HUD reads count, renders pop + "51"
    ├► Nameplate updates text
    └► FollowerEntity (client sim) adds visual follower
       (tweens toward crowd center)
VFXManager plays AbsorbSnap
```

- **Latency budget**: 0-67 ms next 15 Hz tick + wire ping (typically <100 ms client-perceived).
- **No client request** — proximity detection is server-authoritative (anti-cheat).
- **Broadcast fan-out** — HUD / Nameplate / FollowerEntity / VFX all subscribe passively to CrowdStateClient.

### 4.3 Scenario C — Chest Open (explicit request/response)

```text
Client                          Wire                        Server
────────────────────────────────────────────────────────────────────
(hold ProximityPrompt 0.8s)
  ProximityPrompt.Triggered
                          ──RemoteEvent(ChestInteract)──►
                                                        ChestSystem.tick (Phase 4):
                                                          6-guard pipeline:
                                                          (a) Active? (b) participating?
                                                          (c) crowd Active-strict?
                                                          (d) #relics<4? (e) toll F1+F2?
                                                          (f) count > effectiveToll?
                                                          first-come wins chest;
                                                          CSM.updateCount(-toll, "Chest")
                                                          chest state → DraftOpen
                                                          roll 3 candidates (weighted rarity)
                          ◄──RemoteEvent(ChestDraftOffer)──(owner client only)
modal opens, 3 cards
(user picks OR 8s auto-pick)
                          ──RemoteEvent(ChestDraftPick)──►
                                                        ChestSystem validates specId ∈ candidates
                                                        RelicEffectHandler.grant(id, specId)
                                                          fires onAcquire
                                                          activeRelics appended (≤4)
                                                        CSM fires CrowdRelicChanged reliable
                                                        chest → Opened → destroy component
                                                        schedule respawn timer
                          ◄──reliable CrowdRelicChanged───
CrowdStateClient updates activeRelics
  HUD relic shelf shows new icon
  VFXManager plays RelicGrantVFX
  (P8 broadcast next tick
   carries new composed radius)
```

- **Two reliable remotes, one unreliable broadcast** — all via Network wrapper.
- **Server-authoritative draft roll** — client never sees non-candidate relics (anti-cheat + anti-spoil).
- **Atomicity** — 6-guard pipeline + Phase 4 ordering guarantees no partial-spend (count reflects Phase 1-3 drains).

### 4.4 Scenario D — Round Lifecycle Boundary (state transition fan-out)

```text
MSM: Countdown:Snap t=10s expires
  participationFlags frozen → list of N participating players
  ┌─ RoundLifecycle.createAll(players)   ◄── synchronous, before broadcast
  │    ├ new Janitor
  │    ├ subscribe CSM.CrowdEliminated reliable RemoteEvent +
  │    │              CSM.CountChanged BindableEvent (server-only)
  │    ├ subscribe Players.PlayerRemoving
  │    └ for each player: CSM.create(crowdId, {count=10})
  │        └ fires CrowdCreated reliable RemoteEvent per client
  │
  └─ MatchStateServer.transitionTo("Active")
       └ fires MatchStateChanged reliable (all clients)

──reliable wire fan-out──►
Clients (per-client side in parallel):
  CrowdStateClient: onCrowdCreated → init _crowds[id]; fires local CrowdCreated
    ├► HUD leaderboard row init
    └► PlayerNameplate.new(character) per crowd
  MatchStateClient: reconcile("Active", stateEndsAt=t+300s)
    ├► HUD shows timer + hides AFK + hides 3-2-1
    ├► FollowerEntity.new(crowdId) per crowd
    └► ChestBillboard.new per chest becomes visible

──── Active runs for ≤300s ────

Winner determined in P6/P7/T8:
  MatchStateServer.transitionTo("Result"):
    Currency.grantMatchRewards(placements)               ◄── FIRST
    fires MatchStateChanged("Result", meta={...})         ◄── SECOND

                          10 s later (Result elapsed):
  MSM T9:
    RoundLifecycle.destroyAll()
      janitor:Destroy()  ◄── disconnects all signal subs
      for each crowd: CSM.destroy(id)  ◄── fires CrowdDestroyed
      table.clear all tables
    RelicEffectHandler.clearAll()
    fires MatchStateChanged("Intermission")

──reliable fan-out──►
Clients:
  onCrowdDestroyed: Nameplate:destroy, FollowerEntity:destroy
  VFXManager: Subscribed → Shutdown → Subscribed (pool reset)
  HUD shows Result panel (10s) then lobby
```

- **Ordering invariant** (MSM T9): `destroyAll → clearAll → broadcast`. Broadcast is the last step; clients cannot observe Intermission before server cleanup.
- **Grants before broadcast** at T6/T7/T8 per MSM AC-20 (coin-tick animation plays on Result receipt).

### 4.5 Scenario E — BindToClose (server shutdown, any state)

```text
Roblox platform: game:BindToClose(callback) fires
  MatchStateServer.transitionTo("ServerClosing")
    fires MatchStateChanged reliable
                          ──reliable wire──►
                          clients show "Server closing" UI
  t=0-2s: grace for client UI
  t=2-28s: for each player in Players:GetPlayers()
    PlayerDataServer.onPlayerRemovingAsync(player)
      ProfileStore session-unlock + save
  t=28-30s: Roblox platform buffer for ProfileStore's own BindToClose
  NO currency grant (anti-exploit per MSM §Core)
```

- **Single synchronous iterator** — ProfileStore handles per-player save retry.
- **Strict no-grant rule** — mid-round economy transactions forbidden.

### 4.6 Initialisation Order

**Server boot sequence:**

```text
1. require SharedConstants/AssetId + all enums          (Foundation — shared)
2. Network wrapper boot
   ├ auto-create all RemoteEvents from RemoteEventName enum
   └ auto-create all UnreliableRemoteEvents from UnreliableRemoteEventName enum
3. PlayerDataServer init (ProfileStore store handle)
4. Collision group matrix setup
5. Zone Handler listen (CollectionService subscriptions)
6. CSM module boot (empty _crowds, no tick running yet)
7. MatchStateServer init → state="Lobby"; participationFlag table empty
8. RoundLifecycle init → Dormant
9. Relic / Absorb / Chest / CollisionResolver module init (no ticks yet)
10. NPCSpawner init → no neutrals yet (MSM gates spawn on Active entry)
11. TickOrchestrator.start()                            ◄── BEGINS 15 Hz Heartbeat
12. Players.PlayerAdded handlers attach
```

**Client boot sequence** (via `ReplicatedFirst/Source/start.server.luau`):

```text
1. Loading screen shown
2. Network wrapper available (remote instances already created server-side)
3. PlayerDataClient subscribes PlayerDataUpdated
4. CrowdStateClient subscribes CrowdStateBroadcast (unreliable) +
   CrowdCreated/Destroyed/Eliminated/RelicChanged/CountClamped (reliable)
5. MatchStateClient subscribes MatchStateChanged + ParticipationChanged
6. VFXManager boot (Booting → Subscribed)
   ├ subscribes 9 reliable VFX remotes
   └ inits 4 pools (Emitters 24 / Flash 12 / Ring 10 / Column 4)
7. UIHandler + HUD + layer registration
8. FollowerLODManager 10 Hz loop start
9. Character loaded + ComponentCreator listeners for ChestTag etc.
10. Loading screen hide
```

### 4.7 Cross-thread / cross-process concerns

- **No Actors / Parallel Luau in MVP** — single-threaded per server and per client. Future optimisation deferred; not needed at prototype-validated 60 FPS desktop.
- **No cross-server state** — every server is a self-contained match instance. No `MessagingService`, no DataStore keys for match state. PlayerData is the sole cross-server surface, routed through ProfileStore's session lock.
- **Heartbeat vs RenderStepped split** — server uses `Heartbeat` (post-physics, pre-replication). Client FollowerEntity uses `RenderStepped` (per-frame visual interp). Client FollowerLODManager uses `Heartbeat` at 10 Hz subdivide (LOD swap, not per-frame).

---

## 5. API Boundaries

Public contracts per Core + key Feature module. All types in Luau `--!strict` (project language). Private instance fields `_prefixed`, yielding functions `Async`-suffixed (`CLAUDE.md` conventions).

### 5.1 `CrowdStateServer` (Core authority)

```lua
-- Path: ServerStorage/Source/CrowdStateServer/init.luau
--!strict

export type CrowdState = "Active" | "GraceWindow" | "Eliminated"
export type DeltaSource = "Absorb" | "Collision" | "Chest" | "Relic"

export type CrowdRecord = {
    read crowdId: string,
    position: Vector3,
    radiusMultiplier: number,          -- [0.5, 1.5]
    radius: number,                    -- composed: radius_base(count) * mult
    count: number,                     -- [1, 300]
    read hue: number,                  -- [1, 12] immutable post-create
    activeRelics: { string },          -- max 4
    state: CrowdState,
    tick: number,                      -- uint16 monotonic
    stillOverlapping: boolean,
    timer_start: number?,              -- os.clock() on GraceWindow entry
}

-- Lifecycle (RoundLifecycle-only callers)
function CrowdStateServer.create(crowdId: string, initial: CrowdRecord): CrowdRecord
function CrowdStateServer.destroy(crowdId: string): ()

-- Count mutation (4 authorised callers: Absorb / Collision / Chest / Relic)
function CrowdStateServer.updateCount(crowdId: string, delta: number, source: DeltaSource): number

-- Radius composition (RelicEffectHandler only)
function CrowdStateServer.recomputeRadius(crowdId: string, newMultiplier: number): number

-- Read accessors (any server system)
function CrowdStateServer.get(crowdId: string): CrowdRecord?
function CrowdStateServer.getAllActive(): { CrowdRecord }           -- excludes Eliminated
function CrowdStateServer.getAllCrowdPositions(): { [string]: Vector3 }

-- CollisionResolver-only overlap flag
function CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()

-- TickOrchestrator-only phase hooks
function CrowdStateServer.stateEvaluate(tickCount: number): ()      -- Phase 5
function CrowdStateServer.broadcastAll(tickCount: number): ()       -- Phase 8

-- Server-only BindableEvent (NOT replicated)
CrowdStateServer.CountChanged: BindableEvent  -- (crowdId, oldCount, newCount, deltaSource)
```

**Invariants callers must respect:**

- `updateCount` callers match `DeltaSource` exactly; other systems forbidden (code-review-only)
- `recomputeRadius` only from RelicEffectHandler; `newMultiplier ∈ [0.5, 1.5]` asserted
- `setStillOverlapping` only from CollisionResolver; last-write-wins within a tick
- Cosmetic systems (Skin System VS+) must NEVER appear in caller set — Pillar 4 anti-P2W contract
- Callers MUST NOT mutate records returned by `get` / `getAllActive`

**Guarantees to callers:**

- `create` fires `CrowdCreated` reliable RemoteEvent before returning
- `destroy` fires `CrowdDestroyed` reliable RemoteEvent; idempotent
- `updateCount` applies F5 clamp `[1, 300]`; returns post-clamp count
- `broadcastAll` sends one `CrowdStateBroadcast` unreliable per tick with all non-destroyed crowds
- Grace transitions fire `CrowdEliminated` reliable only on Active→Eliminated (via GraceWindow expiry)

### 5.2 `MatchStateServer` (Core)

```lua
-- Path: ServerStorage/Source/MatchStateServer/init.luau
--!strict

export type MatchState =
    "Lobby" | "Countdown:Ready" | "Countdown:Snap" |
    "Active" | "Result" | "Intermission" | "ServerClosing"

export type Placement = {
    crowdId: string,
    userId: number,
    placement: number,
    crowdCount: number,
    eliminationTime: number?,
}

-- Read accessors (any server system + exposed to client via RemoteFunction)
function MatchStateServer.get(): MatchState
function MatchStateServer.getParticipation(player: Player): boolean
function MatchStateServer.getStateEndsAt(): number?                 -- absolute tick() epoch

-- TickOrchestrator phase hooks
function MatchStateServer.timerCheck(): ()                           -- Phase 6
function MatchStateServer.eliminationConsumer(): ()                  -- Phase 7
```

**Invariants:**

- No external `transitionTo` — internal-only, driven by `PlayerAdded/Removing`, AFK RemoteEvent, `CrowdEliminated`, `game:BindToClose`
- Read-only for external consumers (HUD, FTUE, spectator camera, Currency)

**Guarantees:**

- `MatchStateChanged` reliable fires on every transition with `{state, serverTimestamp, stateEndsAt, meta}`
- Grants via Currency fire BEFORE `MatchStateChanged("Result")` (MSM AC-20)
- `createAll` synchronous before `Active` broadcast (MSM AC-7)
- `destroyAll → clearAll → broadcast` order at T9 (MSM AC-14)
- Double-signal guard prevents double-transition on same-tick elim (MSM AC-11)
- T6 vs T7 simultaneity: timer wins (Phase 6 before Phase 7)

### 5.3 `RoundLifecycle` (Core coordinator)

```lua
-- Path: ServerStorage/Source/RoundLifecycle/init.luau
--!strict

export type InternalPlacement = Placement & {
    peakCount: number,
    isWinner: boolean,
    wasEliminated: boolean,
}

-- MatchStateServer is sole caller of all five methods
function RoundLifecycle.createAll(participatingPlayers: { Player }): ()
function RoundLifecycle.setWinner(crowdId: string?): ()
function RoundLifecycle.getPlacements(): { Placement }               -- 5-field broadcast shape
function RoundLifecycle.getPeakTimestamp(crowdId: string): number?   -- used by MSM F4
function RoundLifecycle.destroyAll(): ()
```

**Invariants:**

- `createAll` asserts no prior Janitor active (double-call = code bug)
- `setWinner` must be called before `getPlacements` when participants non-empty
- `getPeakTimestamp` nil return treated as `math.huge` by MSM F4 tiebreak
- `#participatingPlayers <= MAX_PARTICIPANTS_PER_ROUND = 12`

**Guarantees:**

- `getPlacements` pure after `setWinner` — idempotent, O(N log N) on ≤12 records
- Internal `InternalPlacement` fields MUST be stripped by broadcast adapter before `FireAllClients`
- `destroyAll` disconnects all subscriptions via Janitor; subsequent stray signals no-op

### 5.4 `TickOrchestrator` (Core)

```lua
-- Path: ServerStorage/Source/TickOrchestrator/init.luau
--!strict

export type TickPhase = (tickCount: number, ctx: TickContext) -> ()
export type TickContext = {
    tickCount: number,
    outPairs: { CollisionPair },       -- Phase 1 fills, Phase 9 reads
    outPeel: { PeelEntry },            -- Phase 4 fills, Phase 9 reads
}

function TickOrchestrator.start(): ()                                -- once at server boot
function TickOrchestrator.stop(): ()                                 -- on BindToClose
function TickOrchestrator.getCurrentTick(): number

-- Test hook (integration tests only)
function TickOrchestrator.setTickDelegate(fn: ((tick: number) -> ())?): ()
```

**Invariants:**

- 9 phases statically wired at boot; no external `registerPhase`
- No `task.wait` / yielding inside any phase callback
- Phase sequence read-only post-ADR — changes require ADR amendment + `/propagate-design-change`

**Guarantees:**

- 15 Hz cadence (±0.1% on desktop, target ≤5ms jitter on mobile)
- Tick queuing on lag: fires sequentially in same Heartbeat callback (no loss, no double)
- Exception in phase X logs + halts tick; next Heartbeat resumes with fresh tickCount

### 5.5 `ChestSystem` (Feature boundary)

```lua
-- Path: ServerStorage/Source/ChestSystem/init.luau
--!strict

export type ChestTier = 1 | 2 | 3
export type ModifierType = "percent" | "flat"
export type ChestState =
    "Dormant" | "Available" | "Claimed" |
    "DraftOpen" | "Opened" | "Cooldown" | "Respawning"

function ChestSystem.createAll(): ()                                -- MSM T4
function ChestSystem.destroyAll(): ()                               -- MSM T9
function ChestSystem.tick(tickCount: number, ctx: TickContext): ()  -- Phase 4

-- Toll queries (read from anywhere)
function ChestSystem.queryChestToll(crowdId: string, tier: ChestTier): number

-- Relic → Chest modifier registration (RelicEffectHandler only)
function ChestSystem.setRelicModifier(crowdId: string, key: string, value: number, type: ModifierType): ()
function ChestSystem.clearRelicModifier(crowdId: string, key: string): ()
```

**Invariants:**

- 6-guard pipeline short-circuits — never computes effectiveToll or deducts on any prior-guard fail
- Tick order lock: Collision → Relic → Absorb → Chest (TickOrchestrator Phase 1-4)
- `_crowdModifiers[crowdId]` cleared on CSM `CrowdDestroyed`
- No DataStore / MessagingService — round-scoped (Pillar 3)

### 5.6 `RelicSystem` (Feature framework)

```lua
-- Path: ServerStorage/Source/RelicSystem/init.luau
--!strict

export type Rarity = "Common" | "Rare" | "Epic"
export type RelicSpec = {
    read specId: string,
    read displayName: string,
    read rarity: Rarity,
    read allowedTiers: { ChestTier },
    read duration: number?,            -- nil = permanent until round end
    onAcquire: ((crowdId: string) -> ())?,
    onTick: ((crowdId: string, tickCount: number) -> ())?,
    onExpire: ((crowdId: string) -> ())?,
    onChestOpen: ((crowdId: string, tier: ChestTier) -> number)?,   -- toll multiplier
    params: { [string]: any },
}

function RelicSystem.grant(crowdId: string, specId: string): ()
function RelicSystem.expire(crowdId: string, specId: string): ()
function RelicSystem.clearAll(): ()                                  -- MSM T9
function RelicSystem.tick(tickCount: number, ctx: TickContext): ()   -- Phase 2
function RelicSystem.queryTollMultiplier(crowdId: string, tier: ChestTier): number
```

**Invariants:**

- Mutating relics route exclusively through `CSM.updateCount(..., "Relic")` or `CSM.recomputeRadius`
- `activeRelics` cap 4 enforced at grant — 5th rejected
- Duration countdown owned by RelicSystem, not CSM
- `queryTollMultiplier` returns `∏(onChestOpen(...))` composed across active relics

### 5.7 Wire contracts (Network registry)

```lua
-- RemoteEventName additions (SharedConstants/Network/RemoteEventName.luau)
RemoteEventName.MatchStateChanged       -- server → all clients reliable
RemoteEventName.ParticipationChanged    -- server → single client reliable
RemoteEventName.CrowdCreated            -- server → all clients reliable
RemoteEventName.CrowdDestroyed          -- server → all clients reliable
RemoteEventName.CrowdEliminated         -- server → all clients reliable
RemoteEventName.CrowdCountClamped       -- server → owning client reliable
RemoteEventName.CrowdRelicChanged       -- server → all clients reliable
RemoteEventName.ChestInteract           -- client → server reliable
RemoteEventName.ChestDraftOffer         -- server → owner client reliable
RemoteEventName.ChestDraftPick          -- client → server reliable
RemoteEventName.ChestStateChanged       -- server → all clients reliable
RemoteEventName.ChestPeelOff            -- server → owner client reliable
RemoteEventName.ChestDraftOpenFX        -- server → all clients reliable
RemoteEventName.ChestOpenBurst          -- server → all clients reliable
RemoteEventName.Absorbed                -- server → owner client reliable (VFX)
RemoteEventName.HueShift                -- server → all clients reliable (VFX audio)
RemoteEventName.CollisionContactEvent   -- server → pair clients reliable (VFX)
RemoteEventName.RelicGrantVFX           -- server → all clients reliable
RemoteEventName.RelicExpireVFX          -- server → all clients reliable
RemoteEventName.RelicDraftPick          -- server → owner client reliable
RemoteEventName.AFKToggle               -- client → server reliable

-- UnreliableRemoteEventName (new for this project)
UnreliableRemoteEventName.CrowdStateBroadcast   -- server → all clients 15 Hz buffer

-- RemoteFunctionName
RemoteFunctionName.GetParticipation     -- client → server, stateless reconcile
```

**Buffer payload schema for `CrowdStateBroadcast`** (30 B per crowd × ≤12 crowds):

```text
offset 0  : crowdId u64  (UserId-encoded)
offset 8  : tick u16
offset 10 : pos Vec3 f32[3]   (12 bytes)
offset 22 : radius f32         (4 bytes)
offset 26 : count u16          (2 bytes)
offset 28 : hue u8
offset 29 : state u8           (1=Active, 2=GraceWindow, 3=Eliminated)
```

### 5.8 Phase registration (boot-time wiring)

```lua
-- Server boot (ServerScriptService/start.server.luau) after all module requires:
TickOrchestrator._registerPhases({
    { phase = 1, name = "Collision",    callback = CollisionResolver.tick },
    { phase = 2, name = "Relic",        callback = RelicSystem.tick },
    { phase = 3, name = "Absorb",       callback = AbsorbSystem.tick },
    { phase = 4, name = "Chest",        callback = ChestSystem.tick },
    { phase = 5, name = "CSM:Eval",     callback = CrowdStateServer.stateEvaluate },
    { phase = 6, name = "MSM:Timer",    callback = MatchStateServer.timerCheck },
    { phase = 7, name = "MSM:Elim",     callback = MatchStateServer.eliminationConsumer },
    { phase = 8, name = "CSM:Cast",     callback = CrowdStateServer.broadcastAll },
    { phase = 9, name = "PeelDispatch", callback = PeelDispatcher.flush },
})
TickOrchestrator.start()
```

---

## 6. ADR Audit

### 6.1 Existing ADR quality

Only one ADR in `docs/architecture/`:

| ADR | Title | Status | Engine Compat | Version | GDD linkage | Conflicts w/ §2-5 | Valid |
|---|---|---|---|---|---|---|---|
| ADR-0001 | Crowd Replication Strategy | Proposed (amended 2026-04-24 ×3) | ✅ present | ✅ Roblox + engine-ref cited | ✅ 13-row Requirements Addressed | None | ✅ |

**Findings:**

- ADR-0001 still Proposed — should move to Accepted after `/architecture-review` populates traceability matrix.
- `buffer` encoding MANDATORY + `tick`+`state` payload fields + tier 2 cap correction all present in amendment chain.
- Key Interfaces block matches CSM §G network event contract post-Batch-1.
- No upstream ADR dependencies (correct — ADR-0001 is foundational).

### 6.2 Traceability coverage (deferred)

`tr-registry.yaml` is empty. Per `docs/CLAUDE.md`, TR registry is owned by `/architecture-review` Phase 8, not this skill. Deferring TR-ID assignment to that skill.

Rather than build a registry here, §6.3 enumerates uncovered decision areas that require new ADRs.

### 6.3 Uncovered decision areas

| Area | GDD refs | Coverage | Required ADR |
|---|---|---|---|
| 15 Hz TickOrchestrator 9-phase dispatch | CCR §15a, MSM §Core TickOrchestrator table, CSM §E impl note | ❌ GAP | ADR-0002 |
| Aggregate per-tick CPU + per-frame + bandwidth budgets | CSM AC-17, MSM AC-19, CCR AC-20, Absorb AC-17, VFX perf AC | ❌ GAP (piecewise in GDDs; no consolidation) | ADR-0003 |
| CSM sole count authority + 4-caller write contract + Pillar 4 anti-P2W | CSM §Core Rules + §Server API + §Pillar 4 | Partial in ADR-0001; rationale missing | ADR-0004 |
| MSM / RoundLifecycle split | MSM §F4 + RL §F1-F4 + placement schema | ❌ GAP | ADR-0005 |
| Module placement + no-upward-import rules | `CLAUDE.md` §Shared vs server-only, CSM §Server API | ❌ GAP (convention not codified) | ADR-0006 |
| Client rendering: non-Humanoid rig + 4-tier LOD + boids | Follower Entity, Follower LOD (sole owner), ADR-0001 §Decision | Partial in ADR-0001; rationale scattered | ADR-0007 (recommended standalone) |
| NPC Spawner respawn + min-distance gate | NPC Spawner §Core + F2 | ❌ GAP | ADR-0008 |
| VFX particle budget + suppression strategy | VFX Manager §C + F2 | ❌ GAP | ADR-0009 |
| Anti-cheat server-authority validation pattern | replication-best-practices.md + CSM §Core + Chest 6-guard | ❌ GAP | ADR-0010 |
| Save schema + Pillar 3 no-round-persistence | ProfileStore ref + CSM §Dep | Partial — bypass documented, no locking ADR | ADR-0011 |

---

## 7. Required ADRs

---

### 7.1 Must have before coding starts (Foundation + Core)

1. **ADR-0002 TickOrchestrator — 15 Hz Server Tick Sequencing**
   - Locks 15 Hz accumulator, 9-phase sequence, simultaneity resolution (T6/T7, double-elim).
   - Covers: CCR §15a, MSM §Core TickOrchestrator, CSM §E impl note, all `tick(ctx)` callbacks.
   - Unblocks: every server gameplay story.

2. **ADR-0003 Performance Budget — Per-Tick + Per-Frame + Bandwidth**
   - Concrete budgets: server 3 ms/tick across 9 phases; desktop 16.67 ms/frame @ 60 FPS; mobile 22.2 ms/frame @ 45 FPS target (iPhone SE); client 10 KB/s/client inbound; VFX 2000 particles ceiling + hysteresis; rendered Parts ≤ 150 worst case.
   - Covers: CSM AC-17 (<1 ms), MSM AC-19 (<0.1 ms), CCR AC-20 (66-pair O(p²)), Absorb AC-17 (1.5 ms @ 3600 overlap), VFX AC-perf.
   - Unblocks: all perf-driven optimisation decisions.

3. **ADR-0004 CSM Authority + Write-Access Contract**
   - Locks 4-caller rule (Absorb / Collision / Chest / Relic), `updateCount` ordering at Phase 1-4, Pillar 4 architectural invariant (cosmetic systems never mutate CSM).
   - Covers: CSM §Core + §Server API + §Pillar 4 anti-P2W.
   - Unblocks: Absorb / Collision / Chest / Relic implementation stories.

4. **ADR-0006 Module Placement Rules**
   - Codifies ServerStorage vs ReplicatedStorage matrix, no-upward-import rule, client-sim vs server-authority split, forbidden patterns (client requiring ServerStorage, direct DataStoreService, magic strings, direct `Humanoid.WalkSpeed` writes).
   - Covers: `CLAUDE.md` §Shared vs server-only + §Forbidden Patterns + §Allowed Libraries.
   - Unblocks: code review baseline + control manifest generation.

### 7.2 Should have before the relevant system is built

5. **ADR-0005 Match State / Round Lifecycle Split**
   - Locks who owns winner resolution (MSM F4), peakCount tracking (RL F1), placement ranking (RL F3), T9 ordering (`destroyAll → clearAll → broadcast`), T6/T7 phase dispatch.
   - Unblocks: MSM + RoundLifecycle implementation stories.

6. **ADR-0008 NPC Spawner Authority**
   - Spawn rate, respawn cadence, min-distance gate via `CSM.getAllCrowdPositions`, 300-NPCs-managed cap.
   - Unblocks: NPC Spawner story.

7. **ADR-0010 Server-Authoritative Validation Policy**
   - Standard 4-check guard pattern (identity / state / parameters / rate) for every server remote handler; payload size limits; reliable vs unreliable selection rule.
   - Unblocks: any story adding a new remote.

8. **ADR-0011 Persistence Schema + Pillar 3 Exclusions**
   - ProfileStore key list (Coins / OwnedSkins / SelectedSkin / LifetimeAbsorbs / LifetimeWins / DailyQuestState / LastDailyResetTime); explicit Pillar 3 exclusions (no per-round state, no OwnedRelics ever); schema migration policy.
   - Unblocks: Currency grant story + all future Shop / Skin / Daily Quest work.

### 7.3 Can defer to implementation

9. **ADR-0007 Client Rendering Strategy**
   - Non-Humanoid CFrame rig (rig topology owned by design/gdd/follower-entity.md §C.1 — currently 2-Part Body+Hat with WeldConstraint), boids flocking, 4-tier LOD (80/30/15/1 billboard), RenderStepped vs Heartbeat split.
   - Alternative: amend ADR-0001 with a rendering section. Recommend standalone to decouple networking from rendering.

10. **ADR-0009 VFX Budget + Suppression Tiers**
    - 2000-particle ceiling, 2-tier suppression (1800/1950) with 200-particle hysteresis, 4 pool types.
    - Can be authored inline with VFX Manager story if session time constrained.

### 7.4 Recommended session ordering

- **Session 1**: ADR-0002 + ADR-0003 + ADR-0004 (three foundational gates)
- **Session 2**: ADR-0006 + ADR-0010 + ADR-0011 (policy ADRs — shorter)
- **Session 3**: ADR-0005 + ADR-0007 + ADR-0008 + ADR-0009 (per-system)

Then `/architecture-review` to populate `tr-registry.yaml` + validate full coverage + `/create-control-manifest`.

---

## 8. Architecture Principles

Five principles that govern every technical decision in Crowdsmith. Derived from game-concept pillars + technical-preferences + empirical lessons from `/prototype crowd-sync`.

### 8.1 Server authority — always

Every gameplay mutation (count / state / position / toll / relic grant) is server-computed. Client is visual + input only. Anti-cheat by construction, not by validation. Direct consequence of `replication-best-practices.md` + Pillar 3 — a client that has no write path cannot breach the anti-pay-to-win contract.

### 8.2 Decouple gameplay count from rendered count

ADR-0001's core insight. Server tracks aggregate crowd state (count / radius / state); client decides how many Parts to render based on distance + FPS headroom. Keeps the 300-follower "big number" feel affordable on mobile at 8-12 players. Applies beyond crowds — any future mass system (super-crowd modes, seasonal events) inherits this split.

### 8.3 Deterministic 9-phase tick

All same-tick simultaneity resolved by TickOrchestrator phase order. No race conditions, no event-queue surprises, no per-system Heartbeat. Replayability + testability first-class. Every "does X happen before Y?" question resolves by reading the phase table in §5.8.

### 8.4 Round-scoped state is ephemeral; cosmetic state persists

No per-round state ever touches ProfileStore (Pillar 3). Only cosmetic + lifetime-statistics keys persist. CSM / RoundLifecycle / Chest / Relic explicitly bypass persistence. Architectural firewall against accidental P2W — if a designer asks to persist relic inventory, the answer is structurally "no", not a case-by-case discussion.

### 8.5 No magic strings

Every cross-module identifier flows through an enum module — `RemoteEventName`, `UnreliableRemoteEventName`, `CollectionServiceTag/*`, `PlayerDataKey`, `ItemCategory`, `UILayerId`, `ZoneIdTag`, `AssetId`. Type-safe boundaries, refactor-safe, search-able. Enforced in code review (`.claude/docs/technical-preferences.md` §Forbidden Patterns).

---

## 9. Open Questions

Decisions deferred — must be resolved before the relevant layer is built.

| # | Question | Blocks | Resolver |
|---|---|---|---|
| OQ-1 | Mobile Heartbeat jitter > 5 ms at 15 Hz? | TickOrchestrator cadence correctness | First MVP integration on iPhone SE emu |
| OQ-2 | `buffer` + `UnreliableRemoteEvent` bandwidth at 4 concurrent clients matches 5.4 KB/s estimate? | ADR-0001 validation → Accepted; ADR-0003 budget | Multi-client integration test (4-player Studio session) |
| OQ-3 | `CrowdStateSnapshot` reliable event needed for mid-round join? (ADR-0001 negative-consequence gap 2026-04-24) | Any post-MVP mid-round-join mechanic | Defer to Alpha when spectator / late-join story surfaces |
| OQ-4 | Actor / Parallel Luau needed? | Phase 1 CCR or Phase 3 Absorb if they exceed per-tick budget | MicroProfiler post-MVP integration |
| OQ-5 | `ProximityPrompt.MaxActivationDistance=20` vs Wingspan crowd radius 16.24 — prompt collisions? | Chest + Relic integration | First chest + Wingspan playtest |
| OQ-6 | DSN-B-1 Wingspan oppression — μ cap 1.35 vs sit-still feel (Batch 5 deferred) | Relic tuning lock | VS playtest (post-integration) |
| OQ-7 | DSN-B-MATH grace-rescue math at late-round ρ≈0.011? | Absorb F4 tuning | VS playtest telemetry |
| OQ-8 | T3 building system scope — MVP vs Alpha? | Level Design + Chest Billboard scale | Decide at VS milestone |

---

## 9. Open Questions

*Written in Phase 7 — to be filled.*
