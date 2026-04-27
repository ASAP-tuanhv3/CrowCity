# Control Manifest

> **Engine**: Roblox (continuously-updated live service; engine-ref pinned 2026-04-20)
> **Last Updated**: 2026-04-27
> **Manifest Version**: 2026-04-27
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0008, ADR-0010, ADR-0011 (9 Accepted; ADR-0007 + ADR-0009 deferrable)
> **Status**: Active — regenerate with `/create-control-manifest` when ADRs change

`Manifest Version` = generation date. Story files embed this date when created. `/story-readiness` compares story embedded version to this field — stale stories flagged for re-validation.

This manifest = programmer quick-reference. Why behind each rule = referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, network registry, ProfileStore, UIHandler, ComponentCreator, ZoneHandler, CollisionGroups, AssetId, SharedConstants*

### Required Patterns

- **All Luau files start with `--!strict`** — source: ADR-0006
- **Two entry points only**: `src/ReplicatedFirst/Source/start.server.luau` (RunContext: Client) + `src/ServerScriptService/start.server.luau` (RunContext: Server). All other logic in ModuleScripts required from these two — source: ADR-0006
- **Server modules under `src/ServerStorage/Source/`** — Roblox engine enforces server-only — source: ADR-0006
- **Shared modules under `src/ReplicatedStorage/Source/`** — both sides may require — source: ADR-0006
- **Vendored libraries under `src/ReplicatedStorage/Dependencies/`** (ProfileStore, Freeze) — manual update only — source: ADR-0006
- **Wally packages under `Packages/`** (Promise, Janitor, TestEZ) — pinned via `wally.toml`; never edit `Packages/` directly — source: ADR-0006
- **Cross-module identifiers via `SharedConstants/` enums** — `RemoteEventName`, `UnreliableRemoteEventName`, `PlayerDataKey`, `ItemCategory`, `UILayerId`, `AssetId`, `CollectionServiceTag/*`, `MatchState`, `DeltaSource`, `VFXEffectId` — source: ADR-0006
- **All remotes via Network wrapper** at `ReplicatedStorage/Source/Network/init.luau` — `Network.fireServer` / `fireAllClients` / `fireClient` / `connectEvent` / `connectUnreliableEvent` — source: ADR-0006
- **AssetId enum** at `SharedConstants/AssetId.luau` for every model/texture/particle/sound reference — source: ADR-0006
- **Persistent data via ProfileStore wrapper** — `PlayerDataServer.updateValue(player, PlayerDataKey, mutator)` — source: ADR-0006, ADR-0011
- **Default player data sole source**: `src/ServerStorage/Source/DefaultPlayerData.luau` — ProfileStore reconciliation auto-fills missing keys — source: ADR-0011
- **Schema migrations under `src/ServerStorage/Source/PlayerDataServer/migrations/v[N]_to_v[N+1].luau`** — registered via `ProfileStore:OnProfileVersionUpgrade(N, handler)` — additive only — source: ADR-0011
- **`_schemaVersion` field on every profile** — increment when field shape changes; not when adding optional field with default — source: ADR-0011
- **Layer hierarchy enforced**: Foundation → Core → Feature → Presentation. No upward imports. Foundation never requires Core/Feature/Presentation; Core never requires Feature/Presentation; Feature never requires Presentation. Sole exception: Presentation systems may require `CrowdStateClient` cache (read-only mirror) — source: ADR-0006
- **CrowdStateClient is shared** at `ReplicatedStorage/Source/CrowdStateClient/init.luau` — read-only mirror; no write API — source: ADR-0004, ADR-0006
- **Wally package upgrade**: update `wally.toml` pin → `wally install` → commit `Packages/_Index/...` + version-changed package folder — source: ADR-0006
- **Vendored library upgrade**: replace file contents in `Dependencies/`; commit with `vendored update: [name] [old-version] → [new-version]` — source: ADR-0006

### Forbidden Approaches

- **Never call `DataStoreService` directly** — bypasses ProfileStore session-lock; corrupts data on duplicate-load. Use `PlayerDataServer.updateValue` → ProfileStore — source: ADR-0006, ADR-0011
- **Never add Scripts or LocalScripts beyond the two entry points** — two-entry-point invariant; deterministic init order — source: ADR-0006
- **Never edit `Packages/` files directly** — Wally regenerates on `wally install`; edits lost — source: ADR-0006
- **Never modify vendored libraries without explicit `VENDORED PATCH` comment block + tracking issue** — breaks upgrade reproducibility — source: ADR-0006
- **Never use folder-as-module without `init.luau`** — Roblox engine fails to resolve — source: ADR-0006
- **Never use `--!nonstrict` or `--!nocheck` in `src/`** — vendored libs may use looser modes — source: ADR-0006
- **Never use magic strings for cross-module identifiers** — use enum modules in `SharedConstants/` — source: ADR-0006
- **Never reference RemoteEvent instances by path or string literal** — go through Network wrapper — source: ADR-0006
- **Never use MessagingService for player data** — ProfileStore session lock is sole cross-server mechanism — source: ADR-0011

---

## Core Layer Rules

*Applies to: TickOrchestrator, CrowdStateServer, MatchStateServer, RoundLifecycle, Crowd Replication broadcast path, server-side validation, persistence authority, currency authority*

### Required Patterns — TickOrchestrator (ADR-0002)

- **TickOrchestrator at `ServerStorage/Source/TickOrchestrator/init.luau`** is sole 15 Hz `RunService.Heartbeat:Connect` accumulator for gameplay tick — source: ADR-0002
- **Static 9-phase sequence locked**: 1.Collision → 2.Relic → 3.Absorb → 4.Chest → 5.CSM:Eval → 6.MSM:Timer → 7.MSM:Elim → 8.CSM:Cast → 9.PeelDispatch — source: ADR-0002
- **Phases statically wired at boot** in `ServerScriptService/start.server.luau` after all module requires — source: ADR-0002
- **Phase callbacks synchronous**; no `task.wait` / `task.defer` / yields inside any phase callback — source: ADR-0002
- **`pcall` wrapper per phase** — exception logs + continues remaining phases; next tick recovers — source: ADR-0002
- **Cadence: 1/15 s = 66.67 ms tick period** — `_tickPeriod = 1/15` — source: ADR-0001, ADR-0002
- **Tick counter exposed**: `TickOrchestrator.getCurrentTick(): number` — source: ADR-0002
- **Test hook**: `TickOrchestrator.setTickDelegate(fn)` — integration tests only; production must NOT call — source: ADR-0002

### Required Patterns — CSM Authority (ADR-0001, ADR-0004)

- **CrowdStateServer at `ServerStorage/Source/CrowdStateServer/init.luau`** is sole crowd-state authority — source: ADR-0001, ADR-0004
- **`updateCount(crowdId, delta, source)` 4-caller rule** — `source: DeltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}`; called only by AbsorbSystem / CollisionResolver / ChestSystem / RelicEffectHandler — source: ADR-0004
- **`recomputeRadius(crowdId, newMultiplier)` sole caller**: RelicEffectHandler — `newMultiplier ∈ [0.5, 1.5]` asserted — source: ADR-0004
- **`setStillOverlapping(crowdId, flag)` sole caller**: CollisionResolver — last-write-wins within tick — source: ADR-0004
- **`create(crowdId, initial)` + `destroy(crowdId)` sole caller**: RoundLifecycle (createAll T4 / destroyAll T9 / PlayerRemoving handler) — source: ADR-0004
- **`stateEvaluate(tickCount)` (Phase 5) + `broadcastAll(tickCount)` (Phase 8) sole caller**: TickOrchestrator — source: ADR-0004
- **Read APIs unrestricted server-side**: `get(crowdId)` / `getAllActive()` / `getAllCrowdPositions()` — but callers MUST NOT mutate returned references — source: ADR-0004
- **`CountChanged` BindableEvent server-only, NOT replicated** — production subscriber: RoundLifecycle (peakCount tracking); analytics stubs Alpha+; never cosmetic systems — source: ADR-0004, ADR-0005
- **Crowd record fields**: `crowdId, position, radiusMultiplier ∈ [0.5, 1.5], radius (composed), count ∈ [1, 300], hue ∈ [1, 12] immutable, activeRelics (max 4), state ∈ {Active, GraceWindow, Eliminated}, tick uint16, stillOverlapping, timer_start?` — source: ADR-0001
- **Composed radius formula**: `radius = (2.5 + sqrt(count) * 0.55) * radiusMultiplier` — source: ADR-0001 §Key Interfaces

### Required Patterns — Crowd Replication (ADR-0001)

- **Server tracks per-player crowd aggregate state only**; individual follower positions are purely client-side visual decoration — source: ADR-0001
- **`UnreliableRemoteEvent CrowdStateBroadcast` at 15 Hz** — buffer-encoded 30 B/crowd × 12 crowds × 15 Hz ≈ 5.4 KB/s/client — source: ADR-0001
- **Buffer encoding mandatory** for MVP (not table serialization) — payload `{crowdId u64 | tick u16 | pos Vec3[3xf32] | radius f32 | count u16 | hue u8 | state u8}` — source: ADR-0001
- **5 reliable named gameplay events**: `CrowdCreated`, `CrowdDestroyed`, `CrowdEliminated`, `CrowdCountClamped` (local-filtered), `CrowdRelicChanged` — source: ADR-0001 §Key Interfaces
- **`tick: uint16` monotonic counter** — out-of-order defense; client drops stale packets via tick comparison — source: ADR-0001
- **Eliminated crowds continue broadcasting with `state=Eliminated`** until `RoundLifecycle.destroyAll` — source: ADR-0001
- **Mid-round game late-join blocked MVP** (Lobby-only) — source: ADR-0001 §Negative Consequences

### Required Patterns — MSM/RoundLifecycle (ADR-0005)

- **MatchStateServer at `ServerStorage/Source/MatchStateServer/init.luau`** owns 7-state machine + participation flags + F4 tiebreak + Phase 6/7 callbacks + BindToClose — source: ADR-0005
- **RoundLifecycle at `ServerStorage/Source/RoundLifecycle/init.luau`** owns `_crowds` aux + `_participants` snapshot + `_winnerId` + F3 placement sort + DC freeze-at-disconnect — source: ADR-0005
- **MSM is sole caller of all 5 RoundLifecycle methods**: `createAll(participants)` (T4) / `setWinner(crowdId)` (Active exit) / `getPlacements()` (Result entry — must follow `setWinner`) / `getPeakTimestamp(crowdId)` (F4 tiebreak) / `destroyAll()` (T9) — source: ADR-0005
- **MSM Phase 6 callback**: `MatchStateServer.timerCheck()` — T7 timer-expiry transition — TickOrchestrator-only caller — source: ADR-0002, ADR-0005
- **MSM Phase 7 callback**: `MatchStateServer.eliminationConsumer()` — T6 last-standing transition + double-signal guard — TickOrchestrator-only caller — source: ADR-0002, ADR-0005
- **T9 ordering invariant**: `RoundLifecycle.destroyAll() → RelicSystem.clearAll() → MatchStateChanged("Intermission") broadcast` — clients must not observe Intermission before server cleanup — source: ADR-0005
- **Result-entry ordering invariant**: `_winnerId resolved → RoundLifecycle.setWinner → getPlacements → Currency.grantMatchRewards → MatchStateChanged("Result", meta) broadcast` — grants atomic with state transition — source: ADR-0005
- **InternalPlacement strip rule**: MSM broadcast adapter MUST strip `peakCount`/`isWinner`/`wasEliminated` before `MatchStateChanged:FireAllClients(meta)` — source: ADR-0005
- **F4 tiebreak owner**: MSM. **F3 placement composite sort owner**: RoundLifecycle (5-key composite: peakCount desc → survived desc → finalCount desc → eliminationTime desc → UserId asc) — source: ADR-0005
- **F1 peakCount strict `>` rule**: equal counts do NOT update `peakCount` or `peakTimestamp` — source: ADR-0005
- **F2 elimination idempotent**: first-fire wins; subsequent fires no-op — source: ADR-0005
- **MAX_PARTICIPANTS_PER_ROUND = 12** asserted at `createAll` — source: ADR-0005
- **MIN_PLAYERS_TO_START = 2** soft threshold; Countdown:Ready ↔ Lobby revert — source: ADR-0005
- **BindToClose 30 s grace** — MSM owns T11 transition; ProfileStore handles per-player save retry; **NO currency grant** during shutdown — source: ADR-0005, ADR-0011
- **Spectator mode**: AFK / mid-round-join / Eliminated-during-Active all enter spectator state (no participation flag) — source: ADR-0005

### Required Patterns — Server-Auth Validation (ADR-0010)

- **4-check guard pattern mandatory** on every server-side handler consuming client-sent payload, in order: (1) Identity (engine `player` arg only) → (2) State (server-authoritative read) → (3) Parameters (`typeof` + range) → (4) Rate (`RemoteValidator.checkRate(player, remoteName)`) — source: ADR-0010
- **RemoteValidator at `ServerStorage/Source/RemoteValidator/init.luau`** — shared 4-check helper; called by every client→server handler — source: ADR-0010
- **Per-player rate limits via `SharedConstants/RateLimitConfig.luau`** keyed `(player, remoteName)` — token-bucket — source: ADR-0010
- **Silent rejection on validation failure** — no client-visible error; server logs at info level for first-of-kind per (player, remote) per round — source: ADR-0010
- **`RemoteValidator.resetForRound()` called from RoundLifecycle.destroyAll T9 chain** — clears per-player rate state — source: ADR-0010
- **Identity from engine `player: Player` argument**; `tostring(player.UserId)` derived server-side is acceptable — source: ADR-0010
- **Server-side `os.clock` / `tick` is sole timing authority** for gameplay decisions; client timestamps advisory only — source: ADR-0010
- **Reliable-vs-unreliable selection**: UnreliableRemoteEvent for high-frequency continuous (CrowdStateBroadcast / NpcStateBroadcast); RemoteEvent reliable for discrete must-arrive events; RemoteFunction only for genuine query-response (e.g., GetParticipation) — source: ADR-0010
- **Payload size targets**: <4 KB/gameplay remote steady-state; <8 KB mid-round-join bootstrap; hard cap 16 KB; chunk via buffer if larger — source: ADR-0010

### Required Patterns — Persistence (ADR-0011)

- **MVP PlayerDataKey schema (6 keys + meta)**: `_schemaVersion` (number=1), `Coins` (number=0), `OwnedSkins` (`{[skinId]:true}`={}), `SelectedSkin` (string?="Default"), `LifetimeAbsorbs` (number=0), `LifetimeWins` (number=0), `FtueStage` (string="Stage1") — source: ADR-0011
- **VS+ schema additions** (lands when Daily Quest System lands; bumps `_schemaVersion` 1 → 2): `DailyQuestState`, `LastDailyResetTime` — source: ADR-0011
- **Pillar 4 boundary** — every persisted key fits exactly one of: cosmetic / lifetime-stat / onboarding-meta. No power modifiers — source: ADR-0011
- **Coins grant only at MSM Result entry** (T6/T7/T8) via `Currency.grantMatchRewards(placements)` — source: ADR-0005, ADR-0011
- **Robux purchases through ReceiptProcessor template**: dev products registered in `Utility/registerDevProducts.luau`; duplicate-prevention + save-before-confirm — source: ADR-0011

### Forbidden Approaches — Core

- **Never create competing `RunService.Heartbeat:Connect` for gameplay-tick work** — TickOrchestrator is sole accumulator. (Exemption: NPCSpawner own Heartbeat per non-gameplay-tick exemption — see Feature layer) — source: ADR-0002
- **Never yield inside TickOrchestrator phase callback** — `task.wait` / `task.defer` / async yields break tick atomicity (count writes vs broadcast on different frames) — source: ADR-0002
- **Never register phases at runtime** — phase table is static; reorder requires ADR amendment + GDD amendment + `/propagate-design-change` — source: ADR-0002
- **Never call CSM mutators from outside §Write-Access Matrix caller set** — `updateCount` exactly 4 callers; `recomputeRadius` 1; `setStillOverlapping` 1; `create`/`destroy` 1 (RoundLifecycle); `stateEvaluate`/`broadcastAll` 1 (TickOrchestrator). HUD / Nameplate / FollowerEntity / FollowerLODManager / VFXManager / NPCSpawner / Skin (VS+) / Daily Quest / Shop are READ-only — source: ADR-0004
- **Never let cosmetic systems (Skin / Avatar / Banner / Trail) mutate any CSM field** — Pillar 4 anti-P2W invariant — source: ADR-0004
- **Never let cosmetic systems subscribe `CountChanged` BindableEvent for gameplay decisions** — count display via CrowdStateClient is presentation-only and acceptable; gating gameplay decisions is forbidden — source: ADR-0004, ADR-0005
- **Never use `debug.traceback` for runtime caller validation** — ~100 µs per call; brittle; consumes Phase 1-4 budget — source: ADR-0004
- **Never call any RoundLifecycle method from outside MatchStateServer** — MSM is sole caller of all 5 RL methods — source: ADR-0005
- **Never call `RoundLifecycle.getPlacements()` before `setWinner`** when participants non-empty — assertion fires — source: ADR-0005
- **Never let MSM/RL call CSM mutators** — MSM/RL are read-only consumers; RL only calls CSM lifecycle (`create`/`destroy`) — source: ADR-0004, ADR-0005
- **Never leak `InternalPlacement` (peakCount/isWinner/wasEliminated) to client broadcast** — broadcast adapter must strip — source: ADR-0005
- **Never grant currency mid-round** — only at MSM Result entry; never on shutdown (BindToClose) — source: ADR-0005, ADR-0011
- **Never skip any of the 4 guard categories** on a client→server handler — identity / state / parameters / rate all required — source: ADR-0010
- **Never read `payload.userId` / `payload.playerId` / `payload.accountId`** for any decision — engine `player` argument is sole trusted identity — source: ADR-0010
- **Never use RemoteFunction for fire-and-forget actions** — yields the calling client; use RemoteEvent reliable instead — source: ADR-0010
- **Never honour client-asserted timestamps** (`payload.timestamp` / `payload.holdDuration` / `payload.tick`) for gameplay decisions — server `os.clock` / `tick` is sole authority — source: ADR-0010
- **Never use UnreliableRemoteEvent for must-arrive discrete events** — data loss; use RemoteEvent reliable — source: ADR-0010
- **Never use per-server rate limits for client→server remotes** — must be per-player; per-server caps reward attackers — source: ADR-0010
- **Never accept oversized client payload** (>16 KB) without explicit chunking via buffer encoding — source: ADR-0010
- **Never persist per-round state in ProfileStore** — Forbidden Keys catalog: per-round crowd state, per-round relic inventory, per-round chest state, per-round elimination state, per-round peak/placement (use `LifetimeAbsorbs`/`LifetimeWins` aggregates), in-flight VFX state, NPC pool state, MSM state mirror, pillar-4-violating modifiers, cross-player social state, replay buffers — source: ADR-0011
- **Never persist Pillar-4-violating gameplay modifiers** — `OwnedAbsorbBonusMultiplier`, `BoughtRadiusBoost`, `RareDraftRollChance`, `PrestigePoints` etc. — source: ADR-0011
- **Never use inline defaults in `PlayerDataServer.updateValue` mutator** (e.g., `function(c) return c or 0 end`) — `DefaultPlayerData.luau` is sole source — source: ADR-0011
- **Never bump `_schemaVersion` without migration handler + test fixture** — code-review reject — source: ADR-0011
- **Never bypass `ReceiptProcessor` for Robux dev products** — duplicate-prevention + save-before-confirm guarantees broken — source: ADR-0011
- **Never read or mutate the table returned by `get` / `getAllActive` / `getAllCrowdPositions`** — read-only contract — source: ADR-0004

### Performance Guardrails — Server Per-Tick CPU (ADR-0003)

- **Total per-tick budget**: **3.0 ms** (4.5% of 66.67 ms tick period) — source: ADR-0003
- **Phase 1 CollisionResolver**: 0.6 ms (66 pairs × 9 µs/pair)
- **Phase 2 RelicSystem**: 0.2 ms (12 crowds × 4 relics × <5 µs)
- **Phase 3 AbsorbSystem**: 0.4 ms typical; 1.5 ms worst-case (3600 overlap tests)
- **Phase 4 ChestSystem**: 0.1 ms
- **Phase 5 CSM stateEvaluate**: 0.2 ms
- **Phase 6 MSM timerCheck**: 0.05 ms
- **Phase 7 MSM eliminationConsumer**: 0.05 ms
- **Phase 8 CSM broadcastAll**: 0.4 ms
- **Phase 9 PeelDispatcher**: 0.1 ms
- **Reserve**: 0.9 ms (unallocated; future systems must amend ADR-0003 to claim)

### Performance Guardrails — Network Per-Client (ADR-0003 + ADR-0008)

- **Total bandwidth**: 10 KB/s/client steady-state; 10.25 KB/s nominal post-NPC amend; 20 KB/s burst allowance for ≤500 ms windows
- **CrowdStateBroadcast**: 5.4 KB/s
- **NpcStateBroadcast**: 3.0 KB/s (per-relevance-filtered, crowd.radius + 25 studs cushion)
- **Reliable gameplay events** (`CrowdCreated`/`Destroyed`/`Eliminated`/`RelicChanged`/`CountClamped` + `NpcPoolBootstrap` rare on join): 0.5 KB/s
- **VFX remotes** (9 reliable): 1.0 KB/s
- **MatchStateChanged + ParticipationChanged**: 0.05 KB/s
- **ChestInteract + ChestDraftPick + AFKToggle**: 0.1 KB/s
- **PlayerDataUpdated**: 0.2 KB/s
- **Reserve**: 0.0 KB/s (consumed by NpcStateBroadcast post-2026-04-26 amend)

### Performance Guardrails — Server Memory (ADR-0003)

- **Crowdsmith systems total**: ~36 KB (CSM 2 KB + RoundLifecycle 2 KB + MSM 1 KB + ChestSystem 4 KB + RelicSystem 2 KB + NPCSpawner 10 KB + TickOrchestrator scratch 2 KB + Network registry 1 KB + ProfileStore 12 KB)
- **Leak guard**: <100 MB growth over 10-minute soak

---

## Feature Layer Rules

*Applies to: NPCSpawner, AbsorbSystem, CollisionResolver, ChestSystem, RelicSystem, FollowerEntity (server roster lives as CSM record fields)*

### Required Patterns

- **NPCSpawner at `ServerStorage/Source/NPCSpawner/init.luau`** owns 300-Part neutral pool — source: ADR-0008
- **NPCSpawner own `RunService.Heartbeat:Connect`** — single connection — non-gameplay-tick exemption per ADR-0002 §Related Decisions L289 — source: ADR-0008
- **NPCSpawner read-only CSM consumer**: `getAllCrowdPositions()` only (during respawn position selection R10a) — source: ADR-0008
- **Pre-allocate 300 Parts at `createAll` chunked 25/batch via `task.defer`** — no mid-round `Instance.new` — source: ADR-0008
- **AbsorbSystem (Phase 3) is sole caller of `getAllActiveNPCs()` + `reclaim(npcId)`** — source: ADR-0008
- **`reclaim(npcId)` synchronous** — postconditions before return: `active=false`, removed from snapshot, parked, `Transparency=1`, `_cachedSnapshot=nil`. Double-reclaim asserts (defect surface) — source: ADR-0008
- **`getAllActiveNPCs()` returns frozen cached snapshot** — invalidated on every reclaim/respawn — source: ADR-0008
- **`ARENA_WALKABLE_AREA_SQ` asserted non-nil + > 0** at NPCSpawner module init — round init fails loudly otherwise — source: ADR-0008
- **NPC replication**: `UnreliableRemoteEvent NpcStateBroadcast` at 15 Hz (8 B/NPC delta, per-relevance filter) + reliable `NpcPoolBootstrap` per-client mid-round-join — source: ADR-0008
- **Workspace.StreamingEnabled = false** on arena map (per NPC GDD §Edge Cases R226) — 300 mirror Parts replicate stably — source: ADR-0008

### Forbidden Approaches

- **Never let NPCSpawner mutate any CSM field** — read-only consumer per ADR-0004 §Pillar 4 + §Write-Access Matrix — source: ADR-0008
- **Never use Roblox native Part replication for NPCs** — bandwidth uncountable; bypasses ADR-0001 server-authoritative-with-soft-broadcast pattern — source: ADR-0008
- **Never call `Instance.new('Part')` after NPCSpawner.createAll completes** — mid-round allocation introduces GC pressure + replication churn at peak load — source: ADR-0008
- **Never call `NPCSpawner.reclaim` from outside AbsorbSystem (Phase 3)** — sole authorised caller — source: ADR-0008

### Performance Guardrails — Instance Caps (ADR-0003)

- **NPC Parts visible per client**: ≤ 60
- **ProximityPrompts**: ≤ 9 (6 T1 + 3 T2 MVP; T3 deferred Alpha)
- **Chest Parts visible**: ≤ 9

---

## Presentation Layer Rules

*Applies to: CrowdStateClient, MatchStateClient, FollowerEntity (client sim), FollowerLODManager, VFXManager, HUD, PlayerNameplate, ChestBillboard, ChestDraftClient, NPCSpawnerClient*

### Required Patterns

- **CrowdStateClient (`ReplicatedStorage/Source/CrowdStateClient/init.luau`) is read-only mirror** — no write API; tracks `lastReceivedTick` per crowd for stale-packet defense — source: ADR-0001, ADR-0006
- **Client decodes `CrowdStateBroadcast` buffer** at 15 Hz; applies count/radius/state to local mirror; client interpolates between received frames — source: ADR-0001
- **Render caps per crowd per client**: own-close (≤20m) max 80 / rival-close (≤20m) max 30 / mid (20-40m) max 15 / far (40-100m) max 1 billboard impostor per crowd / >100m culled — source: ADR-0001
- **LOD swap at 10 Hz** (every 0.1 s); not per-frame — source: ADR-0001
- **Custom non-Humanoid CFrame rig** for followers — rig topology owned by `design/gdd/follower-entity.md` §C.1 (currently 2-Part Body + Hat MeshPart with WeldConstraint) — source: ADR-0001
- **Boids flocking on `RunService.RenderStepped`** client-side — separation + cohesion + move-toward-leader; O(n²) within crowd safe due to render cap n ≤ 80 — source: ADR-0001
- **Stale broadcast > 0.5 s freezes client widgets** at last value; no interpolate-to-zero — source: ADR-0001
- **VFXManager (`ReplicatedStorage/Source/VFXManager/init.luau`) is client-only singleton** — server require = fatal assertion — source: ADR-0011 §Source Tree Map
- **VFXManager single API**: `playEffect(effectId, context)` — all callers funnel through it — source: VFX GDD (deferrable ADR-0009 to come)
- **NPCSpawnerClient mirror pool**: 300 Parts spawned on `NpcPoolBootstrap` reliable receipt; subsequent `NpcStateBroadcast` deltas applied — source: ADR-0008

### Forbidden Approaches

- **Never write `Humanoid.WalkSpeed` directly** — use `ValueManager` composed-stat layer — source: ADR-0006 (template), CLAUDE.md
- **Never replicate per-follower position via reliable RemoteEvent** — bandwidth collapses; use UnreliableRemoteEvent broadcast pattern — source: ADR-0001
- **Never let cosmetic systems (Skin / Avatar / Banner / Trail) subscribe CountChanged** for gameplay decisions — source: ADR-0004, ADR-0005
- **Never mutate the table returned by `CrowdStateClient.get`** — read-only mirror — source: ADR-0004
- **Never per-frame LOD swap** — 10 Hz cadence — source: ADR-0001
- **Never use Humanoid on followers** — performance-killing at 800+ instances — source: ADR-0001

### Performance Guardrails — Per-Frame Client (ADR-0003)

- **Frame budget**: 16.67 ms desktop / 22.2 ms mobile (iPhone SE binding)
- **Roblox platform overhead**: ≤8 ms desktop / ≤10 ms mobile
- **FollowerEntity client sim**: 1.5 ms desktop / 2.5 ms mobile
- **FollowerLODManager swap check**: 0.1 ms / 0.2 ms
- **CrowdStateClient broadcast ingest**: 0.3 ms / 0.5 ms
- **MatchStateClient reconcile**: 0.05 ms / 0.1 ms
- **VFXManager pool grants + emitter writes**: 0.5 ms / 0.8 ms
- **HUD render + widget updates**: 0.5 ms / 1.0 ms
- **PlayerNameplate + ChestBillboard**: 0.3 ms / 0.5 ms
- **UIHandler layer swaps**: 0.05 ms / 0.1 ms
- **Reserve**: 5.37 ms / 6.5 ms

### Performance Guardrails — Instance Caps (ADR-0003 — mobile-binding)

- **Rendered follower Parts (per client view)**: ≤ 150
- **Billboard impostors**: ≤ 12 (one per crowd beyond 40 m)
- **ParticleEmitters in flight**: ≤ 24 pool size
- **Active particles total**: ≤ 2000 soft / ≤ 1950 hard suppression
- **BillboardGui (Nameplates + Chest billboards)**: ≤ 21 (12 Nameplates + 9 Chest)

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Classes | PascalCase | `CrowdStateServer`, `TickOrchestrator` |
| Variables | camelCase | `playerData`, `crowdId`, `peakCount` |
| Signals/Events | PascalCase enum keys | `RemoteEventName.CrowdEliminated` |
| Files | PascalCase.luau | `PlayerDataServer.luau`, `CrowdStateClient.luau` |
| Constants | UPPER_SNAKE_CASE | `MAX_CROWD_COUNT`, `CROWD_START_COUNT` |
| Yielding functions | `Async` suffix | `loadProfileAsync`, `onPlayerRemovingAsync` |
| Private instance fields | `_prefixed` | `self._connections`, `self._instance` |
| Folder-as-module entry | `init.luau` | `Network/init.luau`, `CrowdStateServer/init.luau` |
| Side-specific variants | `Server.luau` / `Client.luau` | `PlayerNameplate/Client.luau` |

### Performance Budgets (consolidated from ADR-0003)

| Target | Value |
|---|---|
| Desktop FPS | 60 (floor 55) — 16.67 ms/frame |
| Mobile FPS (binding) | 45 (floor 40) — 22.2 ms/frame |
| Console FPS | 60 (floor 55) — 16.67 ms/frame |
| Server tick budget | 3 ms / 66.67 ms tick period (4.5%) |
| Client network total | 10 KB/s steady; 20 KB/s burst (≤500 ms) |
| Server memory (Crowdsmith) | 36 KB |
| Memory leak guard | <100 MB growth / 10-min soak |

### Approved Libraries

- **ProfileStore** (vendored, `src/ReplicatedStorage/Dependencies/ProfileStore.luau`) — session-locked DataStore wrapper; sole persistence path
- **Freeze** (vendored, `src/ReplicatedStorage/Dependencies/Freeze/`) — immutable Dictionary + List operations; use when transforming PlayerData
- **Promise** (`Packages.promise`) — async control flow; use instead of raw coroutines/spawn
- **Janitor** (`Packages.janitor`) — lifecycle cleanup; use for connections + instances + callbacks
- **TestEZ** (`Packages.testez`) — unit/integration testing framework

### Forbidden APIs (per `docs/engine-reference/roblox/VERSION.md`)

- **`Player:PlayerOwnsAsset` / `PlayerOwnsAssetAsync`** — privacy-enforced 2026-01-27 — returns may be `false` for private inventories — do not gate gameplay on asset ownership without fallback
- **`BadgeService` methods + badges web APIs** — privacy-enforced 2026-03-23
- **`v1/avatar-fetch` (web API)** — removed 2025-12-05 — use `v2/avatar-fetch`
- **Develop API asset endpoints** — deprecated 2025-07-01 (web API; minimal in-game script impact)
- **Developer Products + Game Passes endpoint changes** — verify Open Cloud / HTTP usage if any
- **Non-Async variants** of `AnimationClipProvider`, `AvatarEditorService`, `Players` methods — prefer Async variants in new code

### Cross-Cutting Constraints

- **Server is source of truth** — every gameplay mutation server-computed; client visual + input only — source: ADR-0001, ADR-0010
- **Decouple gameplay count from rendered count** — server tracks aggregate; client decides Parts to render based on distance + FPS headroom — source: ADR-0001
- **Deterministic 9-phase tick** — all same-tick simultaneity resolved by TickOrchestrator phase order — source: ADR-0002
- **Round-scoped state ephemeral; cosmetic state persists** — no per-round state ever touches ProfileStore (Pillar 3) — source: ADR-0011
- **Anti-P2W invariant** — only cosmetic / lifetime-stat / onboarding may persist (Pillar 4) — source: ADR-0004, ADR-0011
- **No magic strings** — every cross-module identifier flows through `SharedConstants/` enum module — source: ADR-0006
- **Every `RBXScriptConnection` tracked in `self._connections`** and cleaned up in `destroy()` — Connections.luau pattern — source: CLAUDE.md
- **OOP class pattern** — `MyClass.new() → ClassType` returning `setmetatable({} :: any, MyClass)`; `destroy(self: ClassType)` calls `self._connections:disconnect()`; export `ClassType` on every class — source: CLAUDE.md
- **No cross-server state** — every server is self-contained match instance; no `MessagingService`; PlayerData is sole cross-server surface (via ProfileStore session lock) — source: ADR-0011

### Defense-in-Depth Enforcement Layers (referenced across ADRs)

| Layer | Mechanism | Catches |
|---|---|---|
| L1 | Roblox engine semantics | Client-from-server requires; client BindableEvent subscribe; identity at wire level |
| L2 | Code review | Same-server caller mismatches; magic strings; direct DataStore; direct WalkSpeed; missing 4-check guards; inline defaults; InternalPlacement leak |
| L3 | Selene custom rules (PLANNED — Production phase) | Direct RemoteEvent path access; magic-string CollectionService tags; `task.spawn` in phase callbacks; missing 4-check guards |
| L4 | `/create-control-manifest` | Daily implementation reference (this doc) |
| L5 | `/architecture-review` | Cross-checks new ADR/GDD against authority matrices + schema + budgets |
| L6 | `/story-readiness` | Validates story embeds correct caller + path + manifest version |
| L7 | PenTest at MVP-Integration-3 | Synthetic malicious-client run against deployed server (ADR-0010 §PenTest Playbook) |

---

## Manifest Source Trace

| Section | ADRs | Other Sources |
|---|---|---|
| Foundation Required Patterns | ADR-0006, ADR-0011 | technical-preferences §Naming + §Allowed Libraries; CLAUDE.md §Source Layout |
| Foundation Forbidden | ADR-0006, ADR-0011 | technical-preferences §Forbidden Patterns |
| Core TickOrchestrator | ADR-0002 | — |
| Core CSM Authority | ADR-0001, ADR-0004 | — |
| Core Crowd Replication | ADR-0001 | — |
| Core MSM/RL | ADR-0005 | — |
| Core Server-Auth Validation | ADR-0010 | engine-reference replication-best-practices.md §Security |
| Core Persistence | ADR-0011 | engine-reference profilestore-reference.md |
| Core Forbidden | ADR-0001/0002/0004/0005/0010/0011 | — |
| Core Performance Guardrails | ADR-0003 | — |
| Feature NPCSpawner | ADR-0008 | — |
| Feature Forbidden | ADR-0004, ADR-0008 | — |
| Presentation | ADR-0001 | follower-entity GDD §C.1 (rig topology owner) |
| Presentation Forbidden | ADR-0001, ADR-0004, ADR-0005, ADR-0006 | CLAUDE.md (Humanoid.WalkSpeed via ValueManager) |
| Global Naming + Budgets | ADR-0003 | technical-preferences §Naming Conventions + §Performance Budgets |
| Global Forbidden APIs | — | engine-reference VERSION.md §Post-Cutoff Highlights |
| Global Cross-Cutting | ADR-0001, ADR-0002, ADR-0004, ADR-0006, ADR-0010, ADR-0011 | CLAUDE.md §Conventions + §Coding Standards |

**Deferrable ADRs not yet covered**: ADR-0007 Client Rendering Strategy (rig pool sizes, hue-flip, walk-bob, peel selection — currently sourced from FE GDD §C.1 / FE LOD GDD), ADR-0009 VFX Suppression Tier Assignments (priority table per effect, AbsorbSnap 6/frame cap, anchoring modes — currently sourced from VFX GDD §C/F2). Manifest will be regenerated when these land.
