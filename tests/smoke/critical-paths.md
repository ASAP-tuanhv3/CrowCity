# Smoke Test: Critical Paths

> **Purpose**: Run these checks in under 15 minutes before any QA hand-off OR sprint review.
> **Run via**: `/smoke-check` (which reads this file)
> **Update**: Add new entries when new core systems are implemented per sprint.
> **Last refreshed**: 2026-05-11 (Sprint 7 story 7-7) — Sprint 3-6 mechanics added.

## Core Stability (always run)

1. Game place launches in Studio without crash; loading screen hides cleanly within 5 s
2. Server boot order completes without `warn`/`error` output: Network → ProfileStore → CSM → MSM → RoundLifecycle → TickOrchestrator → AbsorbSystem → CollisionResolver → NPCSpawner (per architecture.md §4.6 Initialisation Order)
3. Client boot order completes: Network → PlayerData → CrowdStateClient → NPCSpawnerClient → CrowdManagerClient → Pool → UIHandler
4. `selene src/` exits 0 (lint gate)
5. `tools/audit-asset-ids.sh` exits 0 (no rbxassetid magic strings outside SharedConstants/AssetId)
6. `tools/audit-persistence.sh` exits 0 (no DataStoreService outside ProfileStore; no Pillar 3 forbidden keys)
7. Headless TestEZ baseline: 918+ passed, 0 failed (`rojo build test.project.json -o test-place.rbxl && run-in-roblox --place test-place.rbxl --script tests/runner.server.luau`)

## Core Mechanic — Sprint 2 (Core Spine)

8. TickOrchestrator fires 9 phases in order at 15 Hz; `TickOrchestrator.getCurrentTick()` advances monotonically over 30 s of play
9. CSM record created on `RoundLifecycle.createAll([player])`; `CrowdStateServer.get(crowdId)` returns valid record with `count = 10`
10. CSM `updateCount` clamps `[1, 300]`; `CountChanged` BindableEvent fires once per write
11. MSM boots to `Lobby` state; `MatchStateServer.get() == "Lobby"` within first heartbeat
12. RoundLifecycle `createAll` allocates Janitor + per-crowd aux records; `destroyAll` cleans up

## Sprint 3 — Network Layer Extension + CRS Buffer Codec

13. `UnreliableRemoteEvent CrowdStateBroadcast` fires at 15 Hz post Active state; client `CrowdStateClient.getAllActive()` returns non-empty after first broadcast
14. Buffer codec `BufferCodec/CrowdState.encode/decode` round-trips negative UserIds correctly (Studio Local Server uses -1, -2 — verified by ADR-0008-A1 fix)
15. `RemoteValidator` 4-Check (RunService:IsServer() / state / rate-limit / Snap-freeze) rejects malformed RemoteEvent payloads silently

## Sprint 4 — FollowerEntity + Boids + Pool

16. Round Active → 10 followers visible around player (CROWD_START_COUNT = 10 via CrowdManagerClient.constructCrowd auto setPoolSize)
17. Followers boid-spread to ≥ 4 stud gaps (MIN_OVERLAP_DIST hard constraint per BUG-002 fix); cluster on same Y plane
18. Player walks → followers follow at up to MAX_SPEED=16 stud/sec with per-follower speed variance (raw F_lead × FOLLOW_LEADER_WEIGHT per BUG-002 fix)
19. Pool prealloc 460 follower bundles in `Workspace._FollowerPool` parked at Y=-1000 (Transparency=1)
20. Round end → all granted bundles returned to pool via `FollowerEntityClient.destroy` (BUG-002 fix); no orphan follower visuals across rounds

## Sprint 5 — NPC Spawner + Absorb System

21. Round Active → NPCSpawner.createAll fires via boot wiring bridge in `start.server.luau` (ADR-0008-A1 caller authority); 300 NPCs scattered in arena
22. NPC mirror parts in `Workspace.NpcMirrorPool` visible to client at ≤ ~104 stud range (RELEVANCE_CUSHION=100 + crowd radius) — BUG-002 fix
23. Player walks INTO NPC → AbsorbSystem.tick fires `csm.updateCount(crowdId, 1, "Absorb")` + `npcSpawner.reclaim(npcId)`; NPC mirror despawns same tick (BUG-001 fix layers 1+2+3)
24. NPC absorbed by Player 2 while Player 1 far away → Player 1 still receives despawn signal (unconditional despawn broadcast per BUG-001 fix layer 4); no ghost mirrors

## Sprint 6 — Visual Absorb Loop Closure

25. Absorbed NPC count delta reaches client via 15 Hz broadcast; `FollowerEntityClient._update` detects count change → `setPoolSize(newCount)` → cap-grow throttle enqueues N FadeIn spawns (story 6-1)
26. CSM Phase 5 `_updatePositions` lerps `record.position` toward player HRP at `CROWD_POS_LAG = 0.15` per tick (story 6-10)
27. Cross-client visibility: Player 2's client sees Player 1's followers move with Player 1 (BufferCodec splitU64 negative-UserId fix — was BUG-001 root cause)

## Sprint 7 — Bug Triage + Tech Debt

28. AbsorbSystem diagnostic logging toggle via workspace `AbsorbDiagnosticLogging` boolean attribute (story 7-2 / 7-1): server logs `[AbsorbSystem] tick N crowds=M npcs=K` once/sec when enabled; suppressed in production (default off)
29. E2E integration smoke: `tests/integration/absorb-system/visual_absorb_loop_e2e.spec.luau` passes 8 it() blocks covering full server-side chain (CSM.create → NPCSpawner._activeList → AbsorbSystem.tick → updateCount + reclaim) — story 7-4 locks BUG-001 class regression headlessly

## Data Integrity

30. ProfileStore loads existing profile cleanly (warm boot)
31. Save game completes without error on `BindToClose` (template-shipped; verify intact)
32. Load game restores `Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`, `Inventory` (ADR-0011 7-key schema)

## Performance — Sprint 6+ baseline

33. Sustained ≥30 FPS on desktop in 2-player Active round with 300 NPCs + 20 followers visible (10 own + 10 other)
34. Server tick ≤3.0 ms total over 60 s soak with 2 player crowds + 300 NPCs active (per ADR-0003 §Per-Tick CPU budget)
35. No memory growth over 5 minutes of Active play (server `script.MemoryUsage` flat — pool reuse verified by BUG-002 destroy fix)
36. CrowdStateBroadcast bandwidth ≤ 5.4 KB/s/client steady-state (ADR-0001 §Decision); NpcStateBroadcast ≤ 30 KB/s/client (current dev cushion; ADR-0008 budget revisits at MVP-Integration sprint)

## Multiplayer

37. Studio Local Server 2 players → both clients see both crowds via CrowdStateBroadcast (broadcast round-trip works for negative UserIds per Sprint 7 fix)
38. MSM auto-transitions Lobby → Countdown:Ready (7s) → Countdown:Snap (3s) → Active when 2 players join (MIN_PLAYERS_TO_START=2)
39. Bridge fires NPCSpawner.createAll on Active transition (ADR-0008-A1 caller authority); NPCs spawn within 1 tick

## Notes

- Items 8-12 (Sprint 2) are now also covered by automated `tests/unit/...` + `tests/integration/...` specs — smoke check confirms no regression at integration boundary.
- Item 34 transitions from manual Studio profile → automated TickOrch instrumentation hook + log scrape after story 7-13 ships (Sprint 7 should-have).
- ADR-0008-A1 amendment (Sprint 7 7-6) re-documents NPCSpawner caller authority — Boot wiring bridge replaces RoundLifecycle as sole caller per ADR-0006 Layer Hierarchy.
- BUG-001 + BUG-002 closure tracked in `production/qa/bugs/`. Both bugs verified fixed in Studio playtest 2026-05-10 + 2026-05-11.
