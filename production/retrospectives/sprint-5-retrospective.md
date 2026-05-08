# Sprint 5 Retrospective

**Sprint**: NPC + Absorb Vertical Slice Spine
**Dates**: 2026-05-04 .. 2026-05-08 (5 days, planned 10)
**Verdict**: APPROVED WITH CONDITIONS — vertical slice playable, mid-sprint scope additions absorbed

---

## What landed

- 14/14 must-have stories closed (NPCSpawner full epic + Absorb Logic core)
- 3 of 5 should-have closed (CRB-002 + CRB-003 scope-adds + minimal F2 lag)
- ~117 new tests, 99.2% pass rate
- Visualization works in Studio Play (followers + NPCs render, position tracks player)

## What slipped

- 4 should-have stories not started: Absorb V/A consumers, Absorb perf soak, MSM Participation broadcast, RL DC freeze
- 6 test infra failures unfixed (pool accumulation in tests)
- Story 5-9 UREvent integration test has DI gap (deferred test coverage)

## What went well

- **Batch story implementation via subagents** — NPCSpawner 9 stories + Absorb 5 stories landed in 2 agent runs. Saved sequential plan/code/review overhead per story.
- **Lean mode** — skipping QL-STORY-READY + LP-CODE-REVIEW gates per story let the team move 4× faster than full-mode would have. No critical regressions caught later.
- **Audit-driven verification** — selene + asset-id + persistence audits caught structural issues at edit time. Zero bugs reached commits with broken audits.
- **Test-with-Studio MCP integration** — `run-in-roblox` + screen capture + execute_luau IPC let me drive validation without context-switching.

## What went poorly

### Planning gap: missed end-to-end visualization dependency chain

Sprint 5 plan focused on server-spine + Absorb Logic core. Sprint planning didn't ask "what makes followers visible to the player?". When user opened Studio + saw nothing, ~6 hours of debugging revealed 8+ unwired dependencies:

- Phase 5 + Phase 8 stub→real wiring
- NPCSpawner.createAll never wired to RoundLifecycle T4
- NPCSpawnerClient.start never called
- CrowdCreated reliable lacked initialPosition
- Count→setPoolSize bridge missing
- Auto-round driver missing (MSM Lobby→Round)
- F2 position lag a no-op shim
- Client-side player tracking missing

Each individually a "Sprint 6 work item" — together a vertical slice blocker.

**Lesson**: For Sprint N+1 onward, sprint plan should include a "demo path" — explicit end-to-end "what should the user see when they open the build?". Each step in that demo needs an owner story OR explicit "deferred to Sprint M" annotation.

### Studio cmd-bar `require()` cache confusion

Wasted 1+ hour treating cmd-bar `require()` as authoritative state. Studio's cmd bar uses fresh require cache — every `require(Network)` returned `_remoteFolder = nil` even though running game had it set. Same trap on `_started` flag for CrowdStateClient.

**Lesson**: For Roblox runtime state inspection, never trust cmd bar. Use a real Script (Server) or LocalScript (Client) and write workspace attributes for IPC. `mcp__Roblox_Studio__execute_luau` has same trap.

### Race-condition catch-up complexity

The CrowdCreated reliable arrives between `CrowdStateClient.start()` (early in client boot) and `CrowdManagerClient:init()` (later in startClientGameplay). BindableEvent fires with no listener → event lost. Required catch-up logic in CMC:start to iterate cached crowds.

**Lesson**: Pure event-driven systems should pair with idempotent catch-up. Anywhere a subscriber connects to a BindableEvent, audit "what if event fired before subscribe?". Either re-fire on subscribe OR iterate current state at subscribe-time.

### Test infrastructure rough edges

- Spy helper attached fields to functions (Luau forbids; 50 tests failed initially)
- Pool of 460 bodies accumulates across test runs because `_resetForTests` doesn't clear `_NpcPool` folder children
- TestEZ specs have undefined-globals warnings for `describe`/`it`/`expect` per LSP (cosmetic, expected)

**Lesson**: Test helpers need same scrutiny as production code. Spy pattern bug should've been caught at story-readiness stage. Add to test-standards.md: callable-table pattern when spy needs both `:Fire()` and `.calls` access.

## Action items for Sprint 6

1. **Sprint plan must include "demo path"** — each visible feature traced through every layer (server origin → network → client render). Gaps surface at plan time, not at "open Studio + see nothing" time.
2. **Fix 6 NPC test failures** — clean baseline before adding more stories.
3. **Story 5-9 follow-up** — add `deps.network/players` to NPCSpawner.init for full UREvent integration test coverage.
4. **Replace dev hacks with production paths**:
   - MSM Lobby→Round timer (replaces auto-round on PlayerAdded)
   - Server-driven CSM position update (replaces client-side HRP prediction; or accept client-prediction as Sprint 6 design)
   - Client cap-grow on broadcast count delta (replaces missing absorb-visualization trigger)
5. **Update test-standards.md** with Luau callable-table spy pattern.
6. **Re-review TR-013 stale text** at next /architecture-review (ServerTickAccumulator wording).

## Velocity

- Planned: 19 stories, 7.6 capacity-days, 8d available
- Closed: 14 must-have + 3 should-have + ~8 mid-sprint scope-add wirings = ~25 distinct deliverables
- Calendar elapsed: ~5 working days (under-spent)
- Net throughput: above plan when scope-add work is counted

## Mood

Frustration peak during Studio cmd-bar debugging session (~1h). Fixed by switching to LocalScript IPC. Otherwise smooth.

End state: vertical slice playable for the first time. Next sprint can iterate on actual gameplay (collision, chest, relic) instead of plumbing.
