# BUG-001 — Visual Absorb Loop: Server-Side updateCount Not Firing

**Severity**: S1 (BLOCKING — Sprint 6 goal not met)
**Status**: In Progress (Sprint 7 story 7-1) — headless chain locked, Studio repro pending
**Reported**: 2026-05-09 by tuanhv3 (manual QA in Studio Local Server, 2 clients)
**Sprint**: 6 (filed) / 7 (fix)
**Story refs**: 6-1 (Client cap-grow on broadcast count delta), 6-12 (Smoke + manual playtest), 7-1 (fix)
**Test case**: TC-S1-03 in `production/qa/test-cases-sprint-6-2026-05-09.md`

## 2026-05-10 Update — Sprint 7 Story 7-1 Investigation

**Headless chain proven correct.** Integration test
`tests/integration/absorb-system/visual_absorb_loop_e2e.spec.luau` exercises
the full server-side chain (CSM.create → NPCSpawner._activeList populated →
AbsorbSystem.tick fires updateCount on overlap). All 8 it() blocks PASS:
- AC-1 happy path: NPC inside radius → count grows by 1
- AC-2 negative: NPC outside radius → count unchanged
- AC-3 empty pool: silent no-op
- AC-4 empty crowds: AC-10 preserved (getAllActiveNPCs not called)
- AC-5 multi-NPC: count grows by 3 in one tick
- AC-6 GraceWindow allowed (5-13 AC-8)
- AC-7 Eliminated skipped (5-13 AC-7)
- AC-8 diagnostic log captures live state (7-2 integration)

**Conclusion**: BUG-001 is NOT a wiring defect in core logic. Bug lives in
Studio-only path (character HRP timing, real workspace instantiation, or
something else only observable in live Studio playtest).

**Diagnostic surface added** (Story 7-1 deliverable):
- `AbsorbSystem.setDiagnosticLogging(enabled: boolean)` — production-safe API
- Workspace attribute boot toggle: set `AbsorbDiagnosticLogging = true` in
  Studio workspace properties → server enables diagnostic at boot, logs
  `[AbsorbSystem] tick N crowds=M npcs=K` once/sec

## Studio Repro Recipe (post Story 7-1)

1. Open Studio. In Explorer, select Workspace.
2. In Properties pane, click "Add Attribute". Name: `AbsorbDiagnosticLogging`,
   Type: `bool`, Value: `true`.
3. Run Test → Local Server → 2 players.
4. Wait for `[start] AbsorbSystem diagnostic logging ENABLED via workspace attribute`.
5. Walk Client 1 character into a white NPC. Watch server output for:
   - `[AbsorbSystem] tick N crowds=1 npcs=300` (or similar) — confirms
     both pools populated. If `crowds=0` or `npcs=0` appear once Active
     state reached, root cause matches BUG-001 hypothesis #1 or #4.
   - `[CSM] updateCount` log — confirms absorb fired. If absent despite
     non-zero crowds + npcs, the F1 overlap geometry is failing (player
     character not actually within crowd.radius — see Studio command-bar
     repro below).
6. To verify CLIENT-side cap-grow chain works in isolation (proves Story
   6-1 implementation is correct independent of upstream), run in Studio
   command bar (server-side):

   ```luau
   local CSM = require(game.ServerStorage.Source.CrowdStateServer)
   for _, c in ipairs(CSM.getAllActive()) do
       print("crowd", c.crowdId, "pos:", c.position, "radius:", c.radius, "count:", c.count)
       CSM.updateCount(c.crowdId, 1, "Absorb")
   end
   ```

   Expected: each Active crowd's count grows by 1, broadcast fires, client
   FollowerEntityClient calls setPoolSize(newCount), one new follower fades
   in around each player. If THIS works, Story 6-1 is correct and BUG-001
   is upstream.

## Summary

In Studio Local Server playtest, walking the player character into a visible NPC ("white part") does NOT trigger server-side `[CSM] updateCount` or `[AbsorbSystem]` log output. The absorbed NPC remains in place visually, and no follower fade-in is observed on the client. The visual absorb loop — Sprint 6's stated goal — is not working end-to-end despite all unit and integration tests passing.

## Steps to Reproduce

1. `rojo serve` connect Studio
2. Test → Local Server → 2 players → Start
3. Confirm `[MSM] State → Active` log line in Server output (TC-S1-01 PASS)
4. Confirm NPC models visible in Workspace (TC-S1-02 PASS)
5. Walk Client 1 character into the nearest white NPC part using WASD
6. Observe Server output console for absorb-related log lines

## Expected (per TC-S1-03)

- `[CSM] updateCount` or `[AbsorbSystem]` log line fires on Server within ~0.2s of overlap
- Absorbed NPC visually despawns (or is reclaimed by NPCSpawner)
- One additional follower fades in around the player character on Client 1

## Actual

- No `[CSM] updateCount` log line appears in Server console
- White NPC part remains in place after contact
- User reports being unable to tell whether follower count increased visually

User verbatim: "When I touch a white part, the white part still there, I do not know if the follower is increase or [not]." Server-console follow-up confirmed: "no log appeared".

## Impact

- Sprint 6 visual absorb loop (the sprint goal) NOT verified end-to-end in Studio playtest
- Client-side cap-grow path (Story 6-1) cannot be confirmed working because no upstream count delta arrives — the unit test passes in isolation but the live integration is unobservable
- TC-S1-04 (radius expand with count) and TC-S1-05 (frame drops during absorb burst) cannot execute (depend on TC-S1-03 success)
- Sprint sign-off verdict downgraded from APPROVED → APPROVED WITH CONDITIONS

## Investigation Pointers

Architectural pre-checks ruled out:
- MSM transition logic (TC-S1-01 PASS — Lobby → Countdown → Active fires)
- NPCSpawner DI / spawn pipeline (TC-S1-02 PASS — NPC models visible at Active)
- `RoundLifecycle.createAll` → `CSM.create` wiring exists (`src/ServerStorage/Source/RoundLifecycle/init.luau:148-176`)
- `AbsorbSystem.tick` registered as Phase 3 (`src/ServerScriptService/start.server.luau:97`)
- `AbsorbSystem.init` called with csm + npcSpawner deps (`src/ServerScriptService/start.server.luau:88`)
- CSM Phase 5 `_updatePositions` follows player HRP via `resolveOwner` (`src/ServerStorage/Source/CrowdStateServer/init.luau:224-240`)

Plausible remaining causes (most-likely first):

### 1. `NPCSpawner.getAllActiveNPCs()` returns empty
The visible "white parts" may not be in the spawner's active NPC registry. AbsorbSystem.tick lines 197-202 (`src/ServerStorage/Source/AbsorbSystem/init.luau`) early-return if `npcSnapshot == nil or #npcSnapshot == 0`. This is the silent no-op path that matches the user's observation (no absorb log because the inner loop body is never entered).

Story 6-11 added DI hooks for Network/Players to NPCSpawner. If the active-pool registry was inadvertently shadowed by a test-only branch when running with default DI, getAllActiveNPCs could return empty even though spawned visuals are still in Workspace.

### 2. Radius too small for player to reach overlap
`CROWD_START_COUNT = 10` and `radius_from_count` formula gives radius ≈ (2.5 + sqrt(10) × 0.55) × 1.0 ≈ 4.24 studs. Player must overlap WITHIN that radius (in XZ plane only — Y ignored). If the user walked their character "near" but not "into" an NPC, the F1 squared-distance check fails silently. Radius-only-on-server with no client visualization makes this hard to gauge.

### 3. Visible "white parts" are not NPCs
Roblox baseplate decorations and map geometry can also be plain white parts. Without distinct NPC visual styling, the user may have walked into a static prop. Cross-check: `NPCSpawner` should be tagging NPCs with a CollectionService tag or naming convention — verify the parts the user walked into are actually NPC instances (Studio Explorer right-click → Find).

### 4. Player crowd not in CSM `_crowds`
If `RoundLifecycle.createAll(participants)` was called with `participants = {}` (empty), no player crowd is registered with CSM. AbsorbSystem.tick lines 187-192 early-return with no log when `getAllActive()` is empty. Test: in Studio, run `print(#require(...).CrowdStateServer.getAllActive())` from the command bar after Active state.

`MatchStateServer.getParticipation` is gated on `_setParticipation(player, true)` which fires from the auto-PlayerAdded handler at `src/ServerStorage/Source/MatchStateServer/init.luau:597`. Should fire correctly with 2 clients, but worth verifying.

### 5. AbsorbSystem `_initialized` not set
Despite the wiring, AbsorbSystem.init must run before tick. If init() raises silently, `_initialized` stays false, tick asserts and never executes. Any pcall-wrapped boot path could mask this.

## Recommended Sprint 7 First Step

1. **Add INFO logging to AbsorbSystem.tick at the top:**
   ```luau
   if (tickCount % 15) == 0 then  -- once/sec at 15 Hz
       print("[AbsorbSystem] tick", tickCount, "crowds:", #_csm.getAllActive(), "npcs:", #_npcSpawner.getAllActiveNPCs())
   end
   ```
   This immediately disambiguates causes 1, 4, and 5.

2. **Add `[CSM] updateCount` debug log** on every call (not just write-access checks) so the absorb path is observable in Studio output.

3. **Verify NPC instances are tagged** correctly by NPCSpawner (Studio Explorer → expand a "white part" the user walks into → confirm it has the expected child structure of an NPC — HumanoidRootPart, Humanoid, etc.).

4. **Studio command-bar reproduction**: run
   ```luau
   local CSM = require(game.ServerStorage.Source.CrowdStateServer)
   print("crowds:", #CSM.getAllActive())
   for _, c in ipairs(CSM.getAllActive()) do
       print(c.crowdId, "pos:", c.position, "radius:", c.radius)
   end
   ```
   to confirm both player crowds exist with sensible positions/radius.

## Workaround

None for end-user. Developer can manually invoke `_csm.updateCount(crowdId, 1, "Absorb")` from the Studio command bar (server-side) to confirm the CLIENT-side cap-grow chain works in isolation. Doing so should produce the +1 follower visual reliably, proving Story 6-1 implementation is correct independent of the upstream issue.

## Related

- Story 6-1 (`tests/unit/follower-entity/cap_grow_on_count_delta.spec.luau`) — unit-tested in isolation; 7 it() blocks PASS
- Story 6-11 (`tests/integration/npc-spawner/urevent_replication.spec.luau`) — DI integration tested; 21 it() blocks PASS
- AbsorbSystem suite — last touched Sprint 5 stories 5-10..5-14; tests pass headless
- Sprint 5 carry-forward: 11 follower-entity integration test failures (separate tech debt — `crowd_manager_orchestrator`, `wire_in_end_to_end`, `wire_in_pool_integration`)

## Notes for Triage

This bug surfaces a gap in test strategy: every Sprint 6 component has unit/integration coverage, but the **server-to-client end-to-end loop in real Studio** was never automated and was only manually checked once (smoke 2026-05-08, BEFORE Story 6-1 implementation landed). Recommend Sprint 7 add either an automated headless integration that fires a synthetic NPC overlap and verifies broadcast count delta, OR a documented manual smoke recipe with a deterministic NPC spawn position the tester walks into.
