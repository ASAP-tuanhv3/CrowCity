# Smoke Test: Critical Paths

> **Purpose**: Run these checks in under 15 minutes before any QA hand-off OR sprint review.
> **Run via**: `/smoke-check` (which reads this file)
> **Update**: Add new entries when new core systems are implemented per sprint.

## Core Stability (always run)

1. Game place launches in Studio without crash; loading screen hides cleanly within 5 s
2. Server boot order completes without `warn`/`error` output: Network → ProfileStore → CSM → MSM → RoundLifecycle → TickOrchestrator (per architecture.md §4.6 Initialisation Order)
3. Client boot order completes: Network → PlayerData → CrowdStateClient → MatchStateClient → UIHandler
4. `selene src/` exits 0 (lint gate)
5. `tools/audit-asset-ids.sh` exits 0 (no rbxassetid magic strings outside SharedConstants/AssetId)
6. `tools/audit-persistence.sh` exits 0 (no DataStoreService outside ProfileStore; no Pillar 3 forbidden keys)

## Core Mechanic — Sprint 2 (Core Spine)

> *Update this section as Sprint 2 stories land. Each item links to the story whose acceptance closes the smoke check.*

7. TickOrchestrator fires 9 phases in order at 15 Hz; `TickOrchestrator.getCurrentTick()` advances monotonically over 30 s of play (story 2-1 + 2-2 + 2-3)
8. CSM record created on `RoundLifecycle.createAll([player])`; `CrowdStateServer.get(crowdId)` returns valid record with `count = 10` (story 2-4 + 2-7)
9. CSM `updateCount` clamps `[1, 300]`; `CountChanged` BindableEvent fires once per write (story 2-5)
10. MSM boots to `Lobby` state; `MatchStateServer.get() == "Lobby"` within first heartbeat (story 2-8)
11. RoundLifecycle `createAll` allocates Janitor + per-crowd aux records; `destroyAll` cleans up (story 2-7)

## Data Integrity

12. ProfileStore loads existing profile cleanly (warm boot)
13. Save game completes without error on `BindToClose` (template-shipped; verify intact)
14. Load game restores `Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`, `Inventory` (ADR-0011 7-key schema)

## Performance — Sprint 2 baseline

15. Sustained ≥30 FPS on desktop in empty Lobby (no crowds yet — Core spine only)
16. Server tick ≤3.0 ms total over 60 s soak with single-player + 0 crowds (per ADR-0003 §Per-Tick CPU budget; instrumented via TickOrch story-005 if shipped, else via `os.clock` in Studio profiler)
17. No memory growth over 5 minutes of idle Lobby play (server `script.MemoryUsage` flat)

## Notes

- Items 7-11 will be **automated** via `tests/unit/...` and `tests/integration/...` — smoke check confirms no regression at integration boundary.
- Item 16 transitions from manual Studio profile → automated TickOrch instrumentation hook + log scrape after Sprint 2 nice-to-have story ships.
- Add Vertical Slice mechanics (Absorb / Chest / Relic / FollowerEntity) to this list when Feature-layer epics ship in Sprint 3+.
