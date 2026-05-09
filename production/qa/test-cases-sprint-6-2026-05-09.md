# Sprint 6 Manual QA Test Cases — 2026-05-09

**Sprint**: Sprint 6
**Close date**: 2026-05-09
**QA Plan**: `production/qa/qa-plan-sprint-6-2026-05-09.md`
**Smoke baseline**: `production/qa/smoke-2026-05-08-sprint-6.md` — PASS WITH WARNINGS (891 passed, 11 carry-forward failures, no new regressions)
**Tester**: _[fill in]_
**Studio build**: _[commit hash at test time]_

Gate levels per story type:
- Session 1 tests: BLOCKING (Integration + Visual/Feel — 6-1, 6-12)
- Session 2 tests: ADVISORY (Logic regression observation, Config/Data)

---

## Session 1 — Visual Absorb Loop (~1.5h) — BLOCKING

Stories covered: 6-1 (cap-grow on broadcast count delta), 6-12 (smoke + manual playtest),
6-2 (MSM driver — prerequisite for round to reach Active state).

Studio setup for all Session 1 tests:
- Rojo: `rojo serve` in terminal, confirm "Connected" in Studio
- Open Test > Local Server; set Players to 2; click Start
- Confirm two client viewports open
- Use Client 1 as the "absorbing player" (the one who walks into NPCs)
- Keep the Server output console open (filter: All)

---

### TC-S1-01 — MSM Lobby → Countdown → Active fires with 2 players
- **Story**: 6-2
- **Type**: Integration (prerequisite gate for all Session 1 tests)
- **Gate**: BLOCKING
- **Preconditions**: Studio Local Server running with exactly 2 player clients. `rojo serve` connected. Output console visible on Server tab.
- **Steps**:
  1. Click Start in Test > Local Server. Wait for both client viewports to finish loading (~10s).
  2. On the Server output console, filter to "All".
  3. Observe console output. Confirm `[MSM] State → Lobby` prints within 3s of server start.
  4. Wait up to 15s. Confirm `[MSM] State → Countdown` prints (triggered when MIN_PLAYERS_TO_START=2 is met).
  5. Wait 7s. Confirm `[MSM] State → Active` prints.
  6. Confirm no `[MSM]` error lines appear between state transitions.
- **Expected**: Three sequential log lines — Lobby, Countdown, Active — appear within ~20s of server start. No errors.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S1-02 — NPCSpawner spawns N NPCs at Active state
- **Story**: 6-2, 6-11
- **Type**: Integration
- **Gate**: BLOCKING
- **Preconditions**: TC-S1-01 passed. Server is in Active state. Output console visible on Server tab.
- **Steps**:
  1. Immediately after `[MSM] State → Active` prints, observe Server console for NPC spawn logs.
  2. Confirm a log line matching `[NPCSpawner] createAll` or equivalent spawn confirmation prints.
  3. In Client 1 viewport, pan camera to observe the Workspace. Confirm NPC character models are visible in the game world (they should appear near configured spawn positions).
  4. Count the visible NPC models. Confirm the count matches the configured `NPC_COUNT` constant (check `SharedConstants` or relevant config if unsure of exact value — note it in the Actual Result).
  5. Confirm no `[NPCSpawner] ERROR` lines in Server console.
- **Expected**: NPCSpawner fires on Active transition, NPC models appear in Workspace, count matches configured value, no spawn errors.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S1-03 — Player absorbs NPC — visible follower count grows by 1
- **Story**: 6-1, 6-12 (centerpiece)
- **Type**: Integration + Visual/Feel
- **Gate**: BLOCKING
- **Preconditions**: TC-S1-02 passed. NPCs visible in Workspace. Client 1 character has spawned and is controllable. Active state confirmed. Server console open.
- **Steps**:
  1. In Client 1 viewport, note the current visible follower bundle size around the player character (expected: 0 or baseline count from prior round data).
  2. Walk Client 1 character directly into the nearest NPC model. Use WASD. Character HRP must enter within the NPC overlap radius (visually: character center ≤ ~8 studs from NPC HRP).
  3. Wait up to 1s (≈15 CSM broadcast cycles at 15 Hz).
  4. Observe Server console for `[AbsorbSystem]` or `[CSM] updateCount` log confirming count incremented by 1.
  5. Observe Client 1 viewport. Confirm one additional follower model fades in around the player character (new follower visible near crowd center).
  6. Note the timestamp between step 2 contact and step 5 fade-in. Confirm elapsed time is ≤ 3 server ticks (~0.2s at 15 Hz broadcast).
  7. Repeat steps 2–6 for a second NPC. Confirm follower count increases by 1 again (cumulative: +2).
- **Expected**: Each NPC absorbed produces exactly +1 visible follower within ~0.2s. Server logs confirm `updateCount` fired. No extra followers appear (no double-count).
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S1-04 — Crowd radius visibly expands as follower count grows
- **Story**: 6-1, 6-12
- **Type**: Visual/Feel
- **Gate**: BLOCKING
- **Preconditions**: TC-S1-03 passed. Player has absorbed at least 2 NPCs (follower count ≥ 2 above baseline). Client 1 viewport visible.
- **Steps**:
  1. Before absorbing additional NPCs, take note of the approximate spread of the visible follower bundle in Client 1 (estimate in studs — "roughly X character-widths").
  2. Walk Client 1 character into 3 more NPCs consecutively (total absorbed ≥ 5 above baseline).
  3. After each absorption, observe the follower bundle spread in Client 1 viewport.
  4. After 5 absorbs, compare current spread to the spread noted in step 1.
  5. Confirm the follower bundle occupies a visibly larger screen area — followers are not tightly stacked in the same point; the cluster has spread outward.
  6. On Server console, check for any log output from `radius_from_count` or the CSM radius field update (if instrumented). Note actual values if available.
- **Expected**: Follower bundle spread visibly increases with count. Followers are distributed across a larger radius, not clumped at a single point. No followers appear to teleport or jitter during expansion.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S1-05 — No frame drops during 5+ consecutive absorbs
- **Story**: 6-1, 6-12
- **Type**: Visual/Feel (performance)
- **Gate**: BLOCKING
- **Preconditions**: TC-S1-03 passed. Studio Local Server running with 2 clients. Client 1 has absorbed at least 2 NPCs (pool is warm, throttle queue is active).
- **Steps**:
  1. In Client 1 viewport, open Microprofiler: press Ctrl+F6 (Windows) or Cmd+F6 (Mac).
  2. Observe baseline frame time. Confirm frames are rendering at or near 16.67ms (60 FPS target).
  3. Close Microprofiler (Ctrl+F6 again). Walk Client 1 character rapidly through a cluster of 5 NPCs in under 3s, triggering 5 absorb events in quick succession.
  4. Immediately re-open Microprofiler (Ctrl+F6). Observe peak frame time during the absorb burst.
  5. Check Server console for any `[TickOrch]` or server-side budget warnings during the absorb burst.
  6. Confirm Client 1 viewport did not visually freeze or stutter (no frame where motion paused for >0.5s).
- **Expected**: Peak frame time stays below 33ms (2x budget — sustained 60 FPS, momentary dip to 30 FPS acceptable). No server budget warnings. No visible freeze in Client 1.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S1-06 — Follower models render with FollowerDefault skin (no missing-mesh errors)
- **Story**: 6-12
- **Type**: Visual/Feel
- **Gate**: BLOCKING
- **Preconditions**: TC-S1-03 passed. At least 1 follower is visible in Client 1 viewport.
- **Steps**:
  1. In Client 1 viewport, zoom in on the follower bundle using the scroll wheel or camera controls.
  2. Visually inspect 3–5 individual follower models. Confirm each renders with a visible mesh (humanoid body parts visible, not invisible or a "missing model" placeholder box).
  3. Check Client 1 output console (Output window, filter: Errors). Confirm no errors matching `Unable to load asset`, `rbxassetid`, or `MeshPart failed` for follower instances.
  4. Check Server console output for any asset-load errors tied to follower spawning.
  5. In Workspace (via Studio Explorer, server-side), expand one follower instance. Confirm it contains expected child parts (HumanoidRootPart, Humanoid, at minimum) without error icons.
- **Expected**: All visible followers render correctly with FollowerDefault mesh. No asset-load errors in Client or Server output. Follower instances in Explorer are structurally complete.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

## Session 2 — Regression + CCR Observation (~1h) — ADVISORY

Stories covered: 6-2 (MSM countdown HUD observation), 6-3 (NPC idle-walk regression),
6-5 through 6-9 (CCR Phase 1 console cleanliness), 6-10 (CSM F2 position lag).

Studio setup for all Session 2 tests:
- Continue from Session 1 Local Server, or restart: Test > Local Server, 2 players.
- Keep Server output console open. Keep Client 1 viewport as primary observation pane.

---

### TC-S2-01 — 7s Countdown timer observable via server log (HUD timer TBD)
- **Story**: 6-2
- **Type**: Config/Data (regression)
- **Gate**: ADVISORY
- **Preconditions**: Studio Local Server running with 2 players. Server output console visible.
- **Steps**:
  1. At server start, watch Server output console for `[MSM] State → Countdown` log line. Note the timestamp.
  2. Wait and watch for `[MSM] State → Active` log line. Note the timestamp.
  3. Calculate elapsed seconds between Countdown and Active log lines.
  4. Confirm elapsed time is between 6.5s and 7.5s (±0.5s tolerance for log timing jitter).
  5. In Client 1 viewport, observe any HUD elements. If a countdown timer UI is visible, confirm it counts from 7 to 0 and disappears at Active. If no timer UI is present, note "HUD timer not yet implemented" — this is NOT a fail for this TC (HUD timer is backlog item 6-14 area).
  6. Confirm no `[MSM] ERROR` or unhandled Luau error in Server console during countdown phase.
- **Expected**: Countdown-to-Active elapsed time is 7s ±0.5s. No MSM errors. HUD timer: PASS if present and correct; NOTE if absent (not a fail at this sprint stage).
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S2-02 — NPC idle-walk animation visible on spawned NPCs
- **Story**: 6-3
- **Type**: Integration (regression)
- **Gate**: ADVISORY
- **Preconditions**: TC-S1-02 pattern: Active state reached, NPCs spawned in Workspace. Client 1 viewport visible.
- **Steps**:
  1. In Client 1 viewport, locate a spawned NPC that has not been absorbed by any player.
  2. Observe the NPC for 5s. Confirm the NPC model is visually animated — it should idle in place or walk along a short path (not frozen in T-pose or unanimated).
  3. Move Client 1 character away from all NPCs (>20 studs). Observe NPC again for 5s. Confirm animation continues.
  4. Check Server console for any `[NPCSpawner]` or `[IdleWalk]` error lines that appeared since Active state.
  5. In Studio Explorer (server-side), locate one NPC instance. Confirm it contains an `Animator` or `Animation` child that is not errored.
- **Expected**: Spawned NPCs visibly animate (idle or walk cycle). No NPC is frozen in T-pose. No animation errors in Server console.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S2-03 — CCR Phase 1 runs without Luau warnings during pair iteration
- **Story**: 6-5, 6-6, 6-7, 6-8, 6-9
- **Type**: Logic (regression observation)
- **Gate**: ADVISORY
- **Preconditions**: Active state reached. At least 2 player crowds active (both clients have crowds). Server output console visible, filtered to "Warnings" (click the Warning icon in the Output toolbar).
- **Steps**:
  1. Set Server output console filter to "Warnings" only.
  2. Allow the game to run for 30s in Active state with both player crowds overlapping (position Client 1 and Client 2 characters near each other so CCR Phase 1 overlap detection triggers).
  3. Observe the Warnings console for any new lines beginning with a Luau module name matching `CrowdCollisionResolution`, `CCR`, `PairIteration`, `DripMath`, `OverlapBit`, or `SkipConditions`.
  4. Switch console filter to "Errors". Repeat observation for 10s.
  5. Switch console filter to "All". Check for any `[CCR]` prefixed lines that indicate Phase 1 callbacks fired (confirming the system is running, not silently bypassed).
  6. Confirm at least one `[CCR]` or Phase 1 activity log appeared (system is live), AND zero warnings/errors from CCR modules.
- **Expected**: CCR Phase 1 runs during crowd overlap. Zero Luau warnings or errors from any CCR module. At least one Phase 1 activity log confirms the system executed (not silently no-op).
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

### TC-S2-04 — CSM F2 position lag — follower bundle smoothly trails player HRP
- **Story**: 6-10
- **Type**: Logic (regression observation — Visual/Feel)
- **Gate**: ADVISORY
- **Preconditions**: Active state. Client 1 has at least 3 visible followers. Client 1 character is controllable. Client 1 viewport visible.
- **Steps**:
  1. Move Client 1 character in a straight line (hold W) for 3s at normal walk speed.
  2. Observe the follower bundle in Client 1 viewport. Confirm the bundle does not teleport instantly to match the player's exact position each frame — it should trail behind the player's HRP by a visible but small gap.
  3. Stop Client 1 character (release W). Observe the follower bundle close the gap and settle around the player's stopped position within ~0.5s.
  4. Move Client 1 character in a sharp 90-degree turn. Confirm followers smoothly arc around the turn rather than snapping to the new direction instantly.
  5. On Server console, check for any `[CSM] HRP nil` or position-lag error lines.
  6. Confirm no follower model teleports more than ~3 studs in a single frame during any of the above movements (no visible "pop" artifact).
- **Expected**: Follower bundle trails the player HRP with ~0.15s lag during movement. Bundle smoothly closes gap when player stops. No teleport pops. No nil-HRP errors in Server console.
- **Actual**: _[fill in during QA]_
- **Pass/Fail**: _[fill in during QA]_
- **Notes**: _[fill in during QA]_

---

## Sign-Off Summary

| TC | Title | Session | Gate | Pass/Fail |
|---|---|---|---|---|
| TC-S1-01 | MSM Lobby → Countdown → Active fires | 1 | BLOCKING | _[fill in]_ |
| TC-S1-02 | NPCSpawner spawns N NPCs at Active | 1 | BLOCKING | _[fill in]_ |
| TC-S1-03 | Player absorbs NPC — follower count +1 | 1 | BLOCKING | _[fill in]_ |
| TC-S1-04 | Crowd radius expands with count | 1 | BLOCKING | _[fill in]_ |
| TC-S1-05 | No frame drops during 5+ absorbs | 1 | BLOCKING | _[fill in]_ |
| TC-S1-06 | Followers render with FollowerDefault skin | 1 | BLOCKING | _[fill in]_ |
| TC-S2-01 | 7s Countdown observable via server log | 2 | ADVISORY | _[fill in]_ |
| TC-S2-02 | NPC idle-walk animation visible | 2 | ADVISORY | _[fill in]_ |
| TC-S2-03 | CCR Phase 1 — zero Luau warnings | 2 | ADVISORY | _[fill in]_ |
| TC-S2-04 | CSM F2 lag — bundle smoothly trails HRP | 2 | ADVISORY | _[fill in]_ |

**Overall verdict**: _[APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED — fill in after all BLOCKING TCs complete]_

**Tester sign-off**: _[name + date]_

**Notes for QA lead**: Any BLOCKING TC that fails must have a bug report filed before sprint close-out. ADVISORY failures are noted as conditions and tracked to Sprint 7.
