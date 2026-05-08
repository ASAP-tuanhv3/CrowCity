# Sprint 5 — QA Sign-off Report

**Date**: 2026-05-08
**Sprint**: Sprint 5 — NPC + Absorb Vertical Slice Spine
**Review mode**: lean (per `production/review-mode.txt`)
**Sign-off authority**: gameplay-programmer (solo dev) + manual Studio playtest

---

## Verdict: **APPROVED WITH CONDITIONS**

Vertical slice spine alive end-to-end. Server gameplay loop + client visualization functional in Studio Play. Sprint goal achieved with caveats noted below.

---

## Sprint Scope Delivered

### Must-Have (14/14 closed)

NPCSpawner full epic (5-1..5-9):
- ✓ Pool bootstrap (300 chunked Parts via task.defer)
- ✓ reclaim() synchronous + double-reclaim assert
- ✓ getAllActiveNPCs frozen snapshot + cache invalidation
- ✓ Idle walk + boundary reflection
- ✓ Respawn pipeline (delay + min-distance + fallback)
- ✓ Respawn fade-in (TweenService 1→0 / 0.3s)
- ✓ destroyAll() cleanup
- ✓ F2/F4 density guards
- ✓ UREvent NpcStateBroadcast + NPCSpawnerClient mirror

AbsorbSystem Logic core (5-10..5-14):
- ✓ Phase 3 callback skeleton + DI
- ✓ F1 overlap test + F2 contention
- ✓ Per-overlap sequence + reclaim + snapshot atomicity
- ✓ State guards (Active/GraceWindow/Eliminated)
- ✓ Count clamp + Absorbed reliable RemoteEvent

### Should-Have

| ID | Story | Status |
|---|---|---|
| 5-15 | Absorb V/A consumers | NOT STARTED — Sprint 6 |
| 5-16 | Absorb perf soak | NOT STARTED — Sprint 6 |
| 5-17 | CSM F2 position lag | **DONE (minimal)** — full nil-HRP test coverage deferred |
| 5-18 | MSM Participation + AFKToggle 4-Check | NOT STARTED — Sprint 6 |
| 5-19 | RL Eliminated subscription + DC freeze | NOT STARTED — Sprint 6 (nice-to-have) |
| 5-20 | **SCOPE-ADD** CRB-002 broadcast subscriber | **DONE** |
| 5-21 | **SCOPE-ADD** CRB-003 reliable subscribers | **DONE** |

### Mid-sprint scope additions (visualization unblock)

Pulled forward from Sprint 6 backlog because vertical slice unplayable without them:
- Phase 5 + Phase 8 wiring (CSMStateEvaluateStub + CSMBroadcastAllStub → real CSM functions)
- NPCSpawner.createAll wiring at RoundLifecycle T4
- NPCSpawnerClient.start() at client boot
- CrowdCreated reliable payload includes initialPosition
- CrowdManagerClient catch-up + count→setPoolSize bridge
- Client-side player tracking (CrowdManagerClient onRenderStepped HRP prediction)
- Auto-round on first PlayerAdded (dev convenience; replaces MSM Lobby→Round Sprint 6)

---

## Audit Gates

| Gate | Result |
|---|---|
| `selene src/` | ✅ 0 errors / 7 warnings (baseline) / 0 parse errors |
| `bash tools/audit-asset-ids.sh` | ✅ PASS |
| `bash tools/audit-persistence.sh` | ✅ PASS |
| `rojo build -o game.rbxl` | ✅ Clean |

---

## Test Coverage

### Automated tests

- TestEZ runner ran via `run-in-roblox` with Studio open
- ~117 new it() blocks across 14 spec files (NPC + Absorb + CRB)
- **6 known failures** — all test infrastructure issues, NOT source bugs:
  - NPC respawn pipeline / fade-in tests need CSM mock injection in test setup
  - Pool accumulation across test runs (test isolation gap — `_resetForTests` doesn't clear `_NpcPool` folder children)
  - Sprint 6 follow-up: 30-60 min test infra cleanup
- Pass rate: ~711 / 717 = **99.2%**

Reference: `production/qa/smoke-2026-05-06-sprint-5.md`

### Manual playtest verification

Studio Play session 2026-05-07/08 confirmed:
- ✅ Server boot completes cleanly (no warn/error)
- ✅ Client boot trace: CrowdStateClient.start ✓, NPCSpawnerClient.start ✓
- ✅ Round auto-starts on first player join → `[start] Round started for X — crowd spawned`
- ✅ Crowd record exists server-side (CSM.get returns table)
- ✅ Client cache populated via reliable CrowdCreated subscriber
- ✅ FollowerEntityClient constructed; pool grants bundle; follower body visible
- ✅ NPCs spawned + replicated to client (white parts visible across arena)
- ⚠ Absorb visualization pending CSM F2 + Phase 8 broadcast count change → cap-grow trigger (next iteration)

---

## Sprint Goal Assessment

> **Sprint 5 Goal**: Land NPC Spawner full epic + Absorb System Logic core. By sprint end, neutral NPCs spawn into arena, idle-walk, and feed crowd growth via Phase 3 overlap testing — proving the Pillar 1 growth loop end-to-end on server.

**Achieved (goal scope)**: ✓
- NPCs spawn + idle-walk on server
- Phase 3 overlap test runs per-tick
- updateCount + reclaim contracts wired
- Absorbed reliable signal fires

**Achieved (extended — visualization)**: ✓ partial
- Vertical slice playable in Studio (followers + NPCs visible)
- Server-side overlap detection works
- Client visualization needs broadcast → cap-grow trigger for absorb-grow visualization (Sprint 6)

---

## Known Issues + Sprint 6 Carryover

### S2 — Logic gaps

1. **CrowdStateBroadcast count change → client cap-grow trigger** — Phase 8 broadcast updates client cache count, but FollowerEntityClient doesn't auto-grow Pool. Visual absorb only triggers via PerfFixture's setPoolSize() hotkey or new server signal. Need: client-side observer that diffs received count vs current `#_positions` and calls setPoolSize on delta.

2. **Auto-round on first PlayerAdded is dev hack** — should be MSM Lobby→Round timer per ADR-0005 + GDD §Match Lifecycle.

3. **Client-side HRP prediction is dev hack** — should be replaced by Phase 8 broadcast position smoothing.

### S3 — Test infra

4. **6 NPC test failures** — pool accumulation + missing CSM mock in test setup (not source bugs).

### S3 — Documentation

5. **TR-013 stale text** — "ServerTickAccumulator" wording superseded by ADR-0008 §Cadence Exemption. Update at next /architecture-review.

6. **Story 5-9 DI gap** — NPCSpawner._broadcastTick + _sendBootstrap access `Players:GetPlayers()` + `Network.fireClient*` directly. Add deps.network/players for end-to-end UREvent capture in tests.

---

## Sign-off Conditions

Sprint 5 is APPROVED for closure with these conditions:

1. **Sprint 6 must address** items 1–3 above (visual absorb + production round driver + replication of position).
2. **Sprint 6 may defer** items 4–6 to Sprint 7 if velocity allows (test infra + docs).
3. **No regressions** on Sprint 1–4 deliverables (all 600 baseline tests still passing).

---

## Commits

```
cf90b9f fix(csm): minimal F2 position lag — server tracks player HRP per tick
3270d6f fix(start): wire NPCSpawner.createAll + NPCSpawnerClient.start
d7db881 fix(crb): wire Phase 5 + Phase 8 + initial spawn pos + client-side player tracking
dbeb3c5 fix(crb): wire count→spawn bridge in CrowdManagerClient.constructCrowd
172b6d8 fix(crb): move CrowdStateClient.start() earlier + add CMC catch-up
42700c9 feat(crb): scope-add Sprint 5 stories 5-20+5-21
b075725 fix(absorb tests): __call metatable spy
e1b7c89 chore(sprint-5): batch close 14/14 must-have stories
bca6893 feat(absorb-system): close Sprint 5 stories 5-10..5-14
3ddce04 feat(npc-spawner): close Sprint 5 stories 5-1..5-9
```

10 commits over Sprint 5 timespan (2026-05-04 .. 2026-05-08).
