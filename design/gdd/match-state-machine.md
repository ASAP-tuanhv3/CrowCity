# Match State Machine

> **Status**: In Revision — 7 blockers resolved 2026-04-21; 2026-04-24 Batch 4 closure — RC-B-NEW-4 same-tick handler order locked (9-phase TickOrchestrator table added under §Core Rules). MSM timer check (Phase 6) runs BEFORE MSM elimination consumer (Phase 7) to resolve T7/T6 simultaneity deterministically. L223 edge + new AC-13 formalize.
> **Author**: user + game-designer + gameplay-programmer + systems-designer + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 3 (5-Minute Clean Rounds) primary; 1 (Snowball) + 5 (Comeback) via pacing

## Overview

The **Match State Machine** is the server-authoritative state owner for the match lifecycle — the single source of truth for whether a server is waiting for players, counting down, running a round, showing results, or preparing the next round. One state at a time, for all players on the server. Every system that reacts to "is the round running yet / is it over / should the HUD show the timer" reads this state via a single `MatchStateClient.get()` call. State transitions broadcast over a reliable `RemoteEvent` so clients pick them up once and only once. The machine is the pacing engine — it enforces the 5-minute round pillar (Pillar 3), kicks Round Lifecycle into gear (`createAll` / `destroyAll` hooks for Crowd State), and frames every "one more round" loop that the game's session psychology rests on. Without it, rounds can't start cleanly, can't end cleanly, and the hypercasual rhythm falls apart. State is strictly ephemeral — no round outcome survives to the next match; restart each round from `Lobby`.

## Player Fantasy

You queue up, hear thumbs tapping in the lobby as the server fills, and then the 3-2-1 snaps you into place — thumb hovering, hype pre-loaded. Minute one is quiet hunting: pick off neutrals, watch your crowd click up one-by-one, feel the snowball warming. By minute three the music swells and the rooftops start flashing — you can see a rival's mob cresting the hill and you have to choose, swerve or slam. The final minute is pure klaxon: timer pulsing red, one T3 building left, a desperate last absorb as the horn cuts everything to silence. Results tick your coins up, your placement flashes, and before your brain catches up your thumb has already tapped Play Again.

## Detailed Design

### Core Rules

**Server-wide single-state invariant**
- One state at a time, applies to all connected players. No per-player state. Transitions are instantaneous.
- Server crash/restart → boots to `Lobby` unconditionally. No state recovery.

**Participation flag rules (per-player, asymmetric freeze)**

| Event | Effect on flag |
|---|---|
| `PlayerAdded` | `TRUE` |
| AFK toggle in `Lobby` or `Countdown:Ready` | toggles (either direction) |
| `Countdown:Snap` entry | `TRUE → FALSE` locked; `FALSE → TRUE` still allowed |
| `Countdown:Snap` exit (= Active entry) | all flags frozen |
| `Intermission → Lobby` transition | all flags reset to `TRUE` |

Participation snapshot for `RoundLifecycle.createAll` is captured at `Countdown:Snap` EXIT (t=10s), not Snap entry — gives late-cancellers 3s grace.

**Win-condition evaluation**
- Event-driven via `Signal` from `CrowdStateServer` on every elimination. No polling.
- Timer expiry checked against `tick()` at `SERVER_TICK_HZ = 15` during Active.
- Tiebreak on equal `count` at timer expiry:
  1. Earliest `peak_count_timestamp` (server records per crowd on every new peak via `updateCount`)
  2. Lower `UserId` (numeric sort) — deterministic fallback

**State broadcast rule**
- Single reliable `RemoteEvent` `MatchStateChanged` fires on every transition.
- Payload: `{ state, serverTimestamp, stateEndsAt, meta }`. Clients interpolate timer locally from timestamp + endsAt, no polling.
- Per-player participation flags NOT in broadcast; client derives own `isParticipating` via `RemoteEventName.ParticipationChanged`.

**Participation signal spec**
- Remote: `RemoteEventName.ParticipationChanged` (new entry in `SharedConstants/Network/RemoteEventName.luau`).
- Payload: `{ isParticipating: boolean }`.
- Direction: `FireClient` (server → specific player only). Never `FireAllClients`.
- Reliability: reliable (same priority as `MatchStateChanged`).
- Fires: immediately after any participation flag change, before any state-transition logic that reads the updated flag.
- Lag-spike recovery: reliable remote guarantees eventual delivery; client may also call `RemoteFunction` `GetParticipation` (stateless — server reads flag table) to reconcile on reconnect.

**Write-access contract**
- Only `MatchStateServer` module (`ServerStorage/Source/MatchStateServer/init.luau`, plain table singleton) calls `transitionTo(newState)`.
- External callers may READ via `MatchStateServer.get()` / `MatchStateClient.get()`.
- Machine's only inputs: `PlayerAdded` / `PlayerRemoving`, `CrowdStateServer.Eliminated` signal, internal timer, AFK toggle events.

**Same-tick handler order (TickOrchestrator phase table)** — RC-B-NEW-4 lock 2026-04-24

TickOrchestrator runs these phases sequentially each 15 Hz tick. Extends CCR §C Rule 8 with explicit CSM state-eval + MSM timer/elim phases to resolve simultaneity deterministically. Every same-tick ordering question in this GDD (T6/T7 arbitration, double-signal guard) resolves by reading this table.

| Phase | System | Action | Source GDD |
|---|---|---|---|
| 1 | CollisionResolver | Drip `updateCount(±delta, "Collision")` per overlapping pair | CCR §C Rule 5 |
| 2 | RelicEffectHandler | `onTick` hooks; count-mutating relics fire `updateCount(delta, "Relic")` | Relic §C Rule 7 |
| 3 | AbsorbSystem | Overlap detection + `updateCount(+1, "Absorb")` per absorbed NPC | Absorb §C.1 |
| 4 | ChestSystem | Process queued proximity triggers; guard pipeline; `updateCount(-toll, "Chest")` on claim | Chest §C Rule 9 |
| 5 | **CSM state evaluation** | Grace timer check (F7 `should_eliminate`); fire `Active → GraceWindow` + `GraceWindow → Eliminated` transitions; dispatch `CrowdEliminated` reliable event for transitions this tick | CSM §F7 + §States table |
| 6 | **MSM timer check** | If `matchState == Active` AND `elapsed >= ROUND_DURATION_SEC (300s)` → `transitionTo(Result)` via T7; winner resolved by F4 tiebreak. **Evaluates BEFORE Phase 7** — this is the simultaneity resolver for T6 vs T7. | MSM §T7 + §F4 |
| 7 | **MSM elimination consumer** | Dequeue `CrowdEliminated` signals queued by Phase 5; evaluate F2 `should_end_active`; if triggered AND `matchState == Active` → `transitionTo(Result)` via T6. Double-signal guard (F2) blocks transition if Phase 6 already moved state out of Active. | MSM §T6 + §F2 |
| 8 | CSMBroadcast | 15 Hz `CrowdStateBroadcast` dispatch — carries count/radius/state/hue for all crowds | CSM §G |
| 9 | PeelDispatch | Batched `FireClient` per player (buffered peel entries from Phase 1 drains) | CCR §C Rule 8 |

**Why this order:**
- Phases 1-4 mutate count → state machine must evaluate AFTER all count writes settle
- Phase 5 runs state transitions AFTER count writes → `getAllActive()` result at Phase 5 end is the authoritative eliminated set for this tick
- Phase 6 (MSM timer) BEFORE Phase 7 (MSM elim) → timer-expiry takes priority over same-tick last-standing; T7 fires first; Phase 7 double-signal guard (`matchState != Active`) silently drops queued elim signal
- Phase 8 broadcast AFTER all state mutations → clients receive internally consistent snapshot; no half-applied tick
- Phase 9 peel dispatch AFTER broadcast → peel-visual animations synchronize with broadcast-count deltas observed client-side

**Simultaneity resolution (formalizing §Edge L223):**
- **T6 (last-standing) vs T7 (timer) same-tick**: Phase 6 fires T7 first → `matchState = Result`. Phase 7 evaluates, finds `matchState != Active`, silently drops. Final state = Result via T7. Winner resolved by F4 tiebreak (earliest peak count timestamp, then lowest UserId).
- **Two crowds eliminate same tick (double T6)**: Phase 5 fires both `CrowdEliminated` signals. Phase 7 drains both. First signal triggers `transitionTo(Result)` via T6; second signal's `matchState == Active` guard returns false → silently dropped. Only ONE T6 transition fires.
- **Winner F4 counts captured WHEN**: Phase 6 uses counts AT Phase 6 evaluation time (post-Phase 1-4 drains, post-Phase 5 state transitions). Crowds eliminated this tick have their last pre-elimination count preserved in the F4 comparator via `getPeakTimestamp(crowdId)` lookup (Round Lifecycle tracks peak before elimination).

**Caller enforcement:** TickOrchestrator module (CCR spin-off §15a) owns the phase dispatch loop. Inserting a new phase or reordering existing phases requires amendment to this GDD + CCR §C Rule 8 + `/propagate-design-change` pass. No other system may register a phase unilaterally.

### States and Transitions

**State Table (7 states)**

| State | Duration | Timer type | Participation mutable | Gameplay | Broadcast `meta` | Enters by |
|---|---|---|---|---|---|---|
| `Lobby` | variable | conditional | yes (both ways) | no | `{}` | server boot; Intermission exit |
| `Countdown:Ready` | 7s | fixed | yes (both ways) | no | `{countdownTotal: 10}` | Lobby eligibility met |
| `Countdown:Snap` | 3s | fixed | FALSE→TRUE only | no | `{}` | Countdown:Ready timer |
| `Active` | 300s | fixed + conditional early-end | frozen | **yes** | `{roundDuration: 300}` | Countdown:Snap timer + createAll |
| `Result` | 10s | fixed | frozen | no | `{winnerId, winnerCount, placements[]}` | Active end condition |
| `Intermission` | 10s | fixed | frozen | no | `{}` (grants fired internally) | Result timer |
| `ServerClosing` | ≤30s | fixed | frozen | no | `{}` | `game:BindToClose` from any state |

**Transition Table**

| # | From | To | Trigger |
|---|---|---|---|
| T1 | `Lobby` | `Countdown:Ready` | `#participating >= MIN_PLAYERS_TO_START (2)` |
| T2 | `Countdown:Ready` | `Lobby` | `#participating < 2` (revert; show "Waiting for players...") |
| T3 | `Countdown:Ready` | `Countdown:Snap` | timer t=7s |
| T4 | `Countdown:Snap` | `Active` | timer t=10s AND `#participating >= 1` → call `RoundLifecycle.createAll(participatingPlayers)` synchronously, then broadcast |
| T5 | `Countdown:Snap` | `Result` | timer t=10s AND `#participating == 0` → skip Active entirely, broadcast Result with `winnerId=nil` |
| T6 | `Active` | `Result` | last-crowd: `numActiveNonEliminatedCrowds <= 1` via elimination signal |
| T7 | `Active` | `Result` | timer expiry t=300s; winner resolved by tiebreak rules |
| T8 | `Active` | `Result` | sole survivor: all other crowds `Eliminated` or DC'd; `Result` broadcasts immediately; `meta.rivalDisconnected = true`; `meta.winnerId` = sole survivor's `crowdId` |
| T9 | `Result` | `Intermission` | timer t=10s → call `RoundLifecycle.destroyAll()`, call `RelicEffectHandler.clearAll()`, broadcast |
| T10 | `Intermission` | `Lobby` | timer t=10s → reset all participation flags to `TRUE` |
| T11 | any state | `ServerClosing` | `game:BindToClose` → broadcast, iterate `ProfileStore:onPlayerRemovingAsync(p)` for all players over 28s, no partial currency grants |

**Note on Result entry ordering**: On `Active` → `Result` transition (T6, T7, T8): `CurrencySystem.grantMatchRewards(placementsSnapshot)` fires first, then `MatchStateChanged` broadcasts `"Result"`. Clients see the result screen after grants are committed — coin-tick animation can begin immediately on `Result` receipt. `placements[]` element schema: `{ crowdId: string, userId: number, placement: number, crowdCount: number, eliminationTime: number | nil }`.

**Note on T9 ordering**: Grace timers resolve within 3s max after Active exit. Since `Result` lasts 10s before `Intermission` fires `destroyAll()`, graces are guaranteed exhausted. No explicit wait needed. T9 sequence: `destroyAll()` → `clearAll()` → broadcast `"Intermission"`.

### Interactions with Other Systems

**Round Lifecycle**
- `Active` entry (T4): `RoundLifecycle.createAll(participatingPlayers: {Player})` called synchronously before broadcast. Snapshot = players with flag `TRUE` at Countdown:Snap exit.
- `Intermission` entry (T9): `RoundLifecycle.destroyAll()` first action. Calls `CrowdStateServer.destroyAll()`.
- Errors from `createAll` for individual player → silently skip that player's crowd, log server-side. Round continues.

**Relic System**
- Relic System exposes `clearAll()`. Match State calls it at T9 (Intermission entry) after `destroyAll()` completes.
- No cross-round relic persistence in MVP.

**FTUE (FtueManagerServer)**
- Tutorial UI gated on `MatchStateServer.get() == "Lobby"`. Never opens during Countdown/Active/Result/Intermission.
- FTUE stage handlers must listen to `MatchStateChanged` and yield/resume accordingly. No polling.
- Tutorial completion status never gates the match state machine.

**HUD**
- Client HUD consumes `MatchStateClient.get()` for timer display (interpolated from `serverTimestamp + stateEndsAt`) and state-gated UI visibility.
- Timer display: `stateEndsAt - tick()` clamped to `[0, state_duration]`.
- AFK button visible only in Lobby + Countdown:Ready.
- 3-2-1 overlay shown only in Countdown:Snap.
- Result panel shown only in Result (with winner/placements from broadcast `meta`).

**Currency System**
- `CurrencySystem.grantMatchRewards(placementsSnapshot)` called at `Active` → `Result` transition (T6/T7/T8 entry), before `MatchStateChanged` broadcasts `"Result"`. Coin-tick animation plays during the Result screen.
- Grant amount per placement = provisional (owned by Economy/Shop GDD).
- Writes via `PlayerDataServer` → ProfileStore. Standard data flow.
- Disconnected players do NOT receive rewards for that round.

**Spectator mode (AFK + mid-round joiners + Eliminated)**
- Any player without a crowd during Active: camera follows nearest participating crowd (reads `CrowdStateClient.get(nearestId).position`).
- No movement input. No interaction (chests, absorb, collision — all server-guard on `participationFlag AND state == Active`).
- Leaderboard UI in read-only.
- Receives all `MatchStateChanged` broadcasts normally.
- Transitions through Result/Intermission with everyone else; flag resets to TRUE at Lobby.

**BindToClose (ServerClosing)**
- Broadcast `ServerClosing` state immediately.
- Seconds 0-2: client shows "Server closing" UI.
- Seconds 2-28: iterate `Players:GetPlayers()`, call `PlayerDataServer.onPlayerRemovingAsync(p)` sequentially (ProfileStore session-unlock + save).
- Seconds 28-30: buffer for ProfileStore's own BindToClose.
- **No partial currency grant** — mid-round economy transactions without resolved winner = balance exploits.

## Formulas

Match State Machine is state logic, not balance math. Formulas below are predicates and timer arithmetic.

### F1. state_timer_elapsed

`elapsed = tick() - stateEnteredAt`
Exit condition: `elapsed >= state_duration`

| Variable | Type | Range | Description |
|---|---|---|---|
| `stateEnteredAt` | float | — | `tick()` captured on transition (wall-clock; consistent with F6 broadcast timestamps) |
| `state_duration` | float | fixed per state | Countdown:Ready 7s, Countdown:Snap 3s, Active 300s, Result 10s, Intermission 10s |

**Poll cadence:** `SERVER_TICK_HZ = 15` → max 66.7ms overshoot before exit detected. Negligible for long states (0.02% of Active); up to 2.2% of Countdown:Snap — acceptable jitter.

**Clock consistency**: `tick()` (wall-clock Unix epoch) used for both F1 and F6 broadcast timestamps. `stateEndsAt = stateEnteredAt + state_duration` — constant for the state's duration, sent unchanged in every broadcast for this state.

### F2. win_condition_last_standing

`should_end_active = (numActiveNonEliminatedCrowds <= 1) AND (matchState == Active)`

Event-driven via `CrowdStateServer.Eliminated` signal, not polled. On each eliminated signal, the handler recounts via `isActive` predicate (F3).

**Double-signal guard:** if two crowds eliminate each other same-tick, second signal MUST check `matchState == Active` before calling `transitionTo(Result)` — prevents double-transition (see Edge Cases).

### F3. is_active_crowd predicate

`isActive(crowdId) = (crowdState != Eliminated) AND (crowdState != nil) AND (matchState == Active)`

Spectators (late-joiners without crowd, AFK non-participants) satisfy `crowdState == nil` → not counted. Prevents mistakenly declaring a spectator the winner.

### F4. win_condition_timer_expiry_tiebreak

Three-step deterministic tiebreak at timer expiry:

1. `winner = argmax(count) at t=300s`. Unique → done.
2. Tie on count → `winner = argmin(peak_count_timestamp)` among tied.
3. Tie on same-moment peak → `winner = argmin(UserId)` — deterministic fallback.

**Peak tracking is owned by Round Lifecycle** (see `design/gdd/round-lifecycle.md` §F1). Match State reads via `RoundLifecycle.getPeakTimestamp(crowdId)`. Round Lifecycle maintains `peak_count[crowdId]` + `peak_count_timestamp[crowdId]` internally on every `CrowdStateServer.CountChanged` signal, writing `peak_count_timestamp = os.clock()` when `new_count > peak_count` (strict `>`).

**Granularity note:** `os.clock()` on Roblox server is sub-millisecond monotonic (not tick-bound). Step 3 rarely fires in practice — requires two `updateCount` calls to produce new peaks within the same microsecond, which requires `CountChanged` events to dispatch in the same Luau coroutine resume. `UserId` fallback guarantees determinism for this rare case without cross-account bias concerns.

**Nil contract:** If `getPeakTimestamp(crowdId)` returns `nil` (crowdId never reached a tracked peak, or is not in Round Lifecycle's `_crowds`), treat as `math.huge` in the argmin comparator — equivalent to "worst possible timestamp, loses tiebreak."

### F5. should_revert_countdown

`should_revert = (#participating < MIN_PLAYERS_TO_START) AND (matchState == Countdown:Ready)`

| Variable | Type | Range | Description |
|---|---|---|---|
| `#participating` | int | [0, 12] | Count of players with flag=TRUE |
| `MIN_PLAYERS_TO_START` | int | locked **2** | Min threshold |

Evaluated on every AFK toggle + `PlayerRemoving` event during Countdown:Ready only. During Countdown:Snap, revert is disallowed (machine commits to T4 or T5 based on final participation at t=10s).

### F6. client_timer_interpolation (with clock-skew + RTT correction)

```
clockOffset = (tick() - serverTimestamp) - (Players.LocalPlayer.Ping / 2000)
                -- computed ONCE on broadcast receipt
                -- subtracts estimated one-way delay (Ping ms ÷ 2 → seconds)
displayedSeconds = math.clamp(
    stateEndsAt - (tick() - clockOffset),
    0,
    state_duration
)
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `tick()` | float | — | Client wall-clock (Unix epoch, same epoch as server `tick()`) |
| `serverTimestamp` | float | — | Server's `tick()` at broadcast send |
| `stateEndsAt` | float | — | `stateEnteredAt + state_duration` (absolute server epoch when state expires — constant for state duration; recomputed at each state entry, not per broadcast) |
| `clockOffset` | float | — | Cached per-broadcast: corrects for server/client clock skew AND one-way network delay |
| `Players.LocalPlayer.Ping` | int | ms | Roblox built-in latency estimate; divide by 2000 for one-way seconds |
| `state_duration` | float | fixed per state | Upper clamp prevents display exceeding state length on early-broadcast receipt |

**RTT correction rationale:** Without correction, `clockOffset` absorbs the full one-way transit time — the client timer runs OWD-seconds fast. At 500ms RTT (4G mobile), the 3s `Countdown:Snap` would appear to end 250ms early (8.3%). `Players.LocalPlayer.Ping / 2000` approximates OWD using Roblox's built-in latency measurement.

## Edge Cases

### State transition races
- **If same-tick dual elimination**: second `Eliminated` signal checks `matchState == Active` before `transitionTo(Result)`. Double-transition blocked by guard.
- **If simultaneous last-standing (T6) + timer-expiry (T7)**: resolved by TickOrchestrator phase table (§Core Rules — Same-tick handler order). Phase 6 (MSM timer check) fires `transitionTo(Result)` via T7 BEFORE Phase 7 (MSM elimination consumer) evaluates queued `CrowdEliminated` signals. Phase 7 double-signal guard (`matchState != Active`) silently drops queued elim. Final state = Result via T7. Winner resolved by F4 tiebreak using counts at Phase 6 evaluation time.
- **If elimination signal fires after `matchState != Active`**: discarded silently. Signal guard is the write-side; state check is the read-side.

### Countdown edges
- **If `#participating < 2` during Countdown:Ready**: revert to Lobby, show "Waiting for players..." message (F5).
- **If `#participating == 0` at Countdown:Snap exit (t=10s)**: skip `Active`, broadcast `Result` with `winnerId=nil`.
- **If AFK toggle `TRUE → FALSE` attempted during Countdown:Snap**: locked — UI button disabled. Asymmetric freeze.
- **If AFK toggle `FALSE → TRUE` during Countdown:Snap**: allowed until t=10s. Late-cancellers get 3s grace.

### Active edges
- **If T8 sole survivor detected**: `Result` broadcasts immediately; `meta.rivalDisconnected = true`; `meta.winnerId` = sole survivor's `crowdId`. No delay.
- **If sole survivor also DCs before T8 broadcast completes**: `Result` fires with `winnerId=nil`. No winner that round.
- **If player teleports or void-falls during Active**: Match State does not care. Character position irrelevant to machine. Collision/absorb/chest are server-guarded on `participationFlag AND state == Active`, not position.

### Join / rejoin edges
- **If `PlayerAdded` during Result or Intermission**: per-player fire of `MatchStateChanged` with current payload. New player sees current screen; flag TRUE; they enter next Lobby clean. UI never claims "YOUR results" — acceptable.
- **If `PlayerAdded` during Active**: spectator (no crowd). Camera follows nearest participating crowd. Flag TRUE for next round.
- **If player rejoins during Result (was in match, DC'd)**: per-player `MatchStateChanged` fires with current `Result` payload. DC'd player's crowd was destroyed at disconnect — they have no placement in `placements[]`. They see the result screen as a late-join spectator; flag resets to `TRUE` at next Lobby.

### Eliminated player behavior
- **If player's crowd is Eliminated during Active**: record survives until T9 (Intermission). HUD shows count=0 + "Eliminated" label during Result. Placement includes them (ordered by elimination time — last-eliminated = highest loser rank).

### Broadcast / network
- **If client misses N broadcasts during lag spike**: `MatchStateChanged` is reliable — next broadcast received carries full self-describing payload. Client calls `MatchStateClient.reconcile(payload)` unconditionally: sets state, recomputes clock offset (F6), re-renders. No broadcast history needed.
- **If T9 broadcast order race**: NOT OBSERVABLE by construction. T9 sequence is `destroyAll()` → `grantMatchRewards()` → `broadcast(Intermission)`. Broadcast is final step. Client cannot receive Intermission before destroyAll finishes. Do not reorder.
- **If client clock drifts during Active**: F6 `clockOffset` recomputed on every broadcast receipt. Timer display self-corrects within 1 state transition.

### Server lifecycle
- **If `game:BindToClose` fires during any state**: broadcast `ServerClosing`, iterate players calling `PlayerDataServer.onPlayerRemovingAsync(p)` over 28s, 2s buffer for ProfileStore's BindToClose. No partial currency grant.
- **If server has 0 players during Lobby**: Roblox platform idle-shutdown handles it. No custom logic. Do NOT implement empty-server shutdown — rely on native behavior.
- **If server crashes mid-Active**: all state lost. On restart, boots to `Lobby`. No recovery (state is ephemeral by design, Pillar 3).

### Currency grant edges
- **If `grantMatchRewards` fails for one player (ProfileStore error)**: wrap each per-player write in `pcall`. On failure: log `{UserId, placement, amount}` server-side for manual audit, skip that player, continue granting to remaining players. Intermission transition proceeds. One save failure must not block the loop.
- **If `createAll` fails for one player during T4**: silently skip that player's crowd, log server-side. Round continues for remaining players.

### Cross-server
- **If someone suggests cross-server match coordination**: REJECTED. Each server runs independent `MatchStateServer` singleton. No DataStore keys encode match state. No `MessagingService` dependency. Confirm via grep before implementation; document "no cross-server dependency" in Dependencies.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| Network Layer (template) | Approved | `RemoteEvent` for `MatchStateChanged` broadcast (reliable, one-shot per transition) | Broadcast dispatch |
| PlayerData / ProfileStore (template) | Approved | `PlayerDataServer.onPlayerRemovingAsync(p)` at `ServerClosing`; `PlayerDataServer` via Currency System for grant writes | Not for match state (ephemeral); only for ancillary save flows |
| Crowd State Manager (Designed) | Pending review | `CrowdStateServer.Eliminated` signal for F2 win-condition check; `CrowdStateServer.destroyAll()` called indirectly via Round Lifecycle at T9 | Read (signal subscribe) + indirect write |
| ADR-0001 Crowd Replication | Proposed | `SERVER_TICK_HZ = 15` for F1 timer poll cadence | Reused constant |
| Pillar 3 (5-Min Clean Rounds) | Approved | `ROUND_DURATION_SEC = 300` (this GDD enforces it) | Locks Active duration |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Round Lifecycle | Not Started | `createAll(participatingPlayers: {Player})` at T4 entry; `destroyAll()` at T9 entry (grace-safe) | Write (via function call) |
| Relic System | Not Started | `clearAll()` called at T9 entry after `destroyAll()` completes | Write (via function call) |
| FTUE / Tutorial | Template skeleton | `MatchStateServer.get() == "Lobby"` predicate gates tutorial UI open; stages listen to `MatchStateChanged` for pause/resume | Read |
| HUD | Not Started | `MatchStateClient.get()` + `MatchStateChanged` RemoteEvent → timer display (F6 client interp), state-gated UI visibility | Read-only |
| Round Result Screen | Not Started (VS) | `Result` state + `meta.{winnerId, winnerCount, placements[]}` | Read-only |
| Lobby / Main Menu UI | Not Started (VS) | `Lobby` state detection for menu open; AFK button toggle writes per-player flag via `RemoteEvent` | Read + AFK write |
| Currency System | Partial (template Coins + undesigned grant formulas) | `CurrencySystem.grantMatchRewards(placementsSnapshot)` called at T9 entry | Write (via function call) |
| Leaderboard System | Not Started (Alpha) | `Result` state entry fires leaderboard update via broadcast's `placements` array | Read-only |
| Spectator Mode | Not Started (component) | Reads `CrowdStateClient` + `MatchStateClient` to drive camera-follow-nearest-participating behavior when own flag = FALSE or crowd nil | Read-only |
| Friend Party / Invite | Not Started (V1.5) | `Lobby` state detection for party-sync timing | Read-only |

### Provisional assumptions (flagged for cross-check)
- `CurrencySystem.grantMatchRewards` signature + reward formula per placement are OWNED by Economy/Shop GDD (not yet authored). This GDD only declares the call site (T9) and the snapshot shape (`placements[]`).
- `RoundLifecycle.createAll` / `destroyAll` signatures assumed to accept `{Player}` list and return synchronously. Round Lifecycle GDD must match this shape.
- `RelicEffectHandler.clearAll` is the round-scoped relic teardown hook. Relic System GDD must expose this method.

### Bidirectional consistency notes
- **RESOLVES** Crowd State Manager §F provisional assumption ("Round Lifecycle exposes `createAll()` / `destroyAll()`") — the explicit T4 + T9 transitions in this GDD now anchor the contract. Round Lifecycle GDD when authored will implement the hooks defined here.
- When Round Lifecycle / Relic / HUD / FTUE / Lobby UI / Spectator / Leaderboard / Friend Party GDDs are authored, their Dependencies sections must list Match State Machine back-reference with matching interface shape.
- Systems Index update required: mark `Depended on by` column for this entry to reflect 10 downstream systems.

### No cross-server dependency
This GDD explicitly REJECTS cross-server match coordination. No `MessagingService` calls. No DataStore keys for match state. Each Roblox server runs independent `MatchStateServer`. Confirm via grep before implementation.

## Tuning Knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `MIN_PLAYERS_TO_START` | 2 | [2, 8] | Lobby → Countdown threshold | >8 = long lobby waits in low-CCU → player churn | <2 = solo rounds (no opponent) | Roblox server-fill setting |
| `COUNTDOWN_READY_SEC` | 7 | [3, 20] | Shop/AFK window duration | >20 = boring wait before each round | <3 = no time to shop or opt-out | Combined w/ SNAP = total countdown |
| `COUNTDOWN_SNAP_SEC` | 3 | [2, 5] | 3-2-1 snap phase (AFK freeze) | >5 = drags the hype moment flat | <2 = can't display 3-2-1 counter visibly | AFK freeze starts here |
| `ROUND_DURATION_SEC` | 300 | [285, 315] | `Active` state duration | >315 = round deviates >5% from Pillar 3 "5-minute" promise | <285 = absorb/chest arc feels rushed; minute 3-4 chest-raid window compresses | Pillar 3 locks this at ±5% — deviation beyond [285, 315] requires pillar amendment |
| `RESULT_DURATION_SEC` | 10 | [6, 15] | Winner reveal + placement display + coin tick | >15 = "one more round" impulse drains | <6 = coin-tick animation rushed, no emotional payoff | Total Result+Intermission = inter-round gap |
| `INTERMISSION_DURATION_SEC` | 10 | [5, 15] | Cleanup + back-to-lobby buffer | >15 = dead-time drag | <5 = destroyAll + ProfileStore may not flush before next Lobby | Must cover grace resolve + cleanup writes |
| `TARGET_PLAYERS_PER_SERVER` | 8-12 | [8, 12] | Roblox server-fill target | >12 = rendering budget strain (art bible §8 + ADR-0001) | <8 = under-populated arena feel | Roblox matchmaker setting, not per-round logic |

### Locked constants (NOT tuning knobs — changing requires ADR or Pillar amendment)
- `SERVER_TICK_HZ = 15` — locked by ADR-0001
- `SERVER_CLOSING_GRACE_SEC = 30` — Roblox platform constraint (`BindToClose` window)
- `MIN_CROWD_COUNT = 1` — inherited from Crowd State Manager GDD

### Provisional defaults (owned elsewhere)
- Grant amounts per placement (coins, XP) — owned by Economy/Shop GDD when authored
- AFK button visual/UX — owned by Lobby/Main Menu UI GDD
- 3-2-1 overlay timing — owned by HUD GDD (synced to `COUNTDOWN_SNAP_SEC`)

### Where knobs live (implementation guidance)
- All `COUNTDOWN_*` / `ROUND_DURATION_*` / `RESULT_*` / `INTERMISSION_*` → `SharedConstants/MatchConfig.luau` (new file)
- `MIN_PLAYERS_TO_START` → same `MatchConfig.luau`
- `TARGET_PLAYERS_PER_SERVER` → Roblox Place settings (not Luau constant — Studio GameConfig)
- `MatchState` enum string keys → `SharedConstants/MatchState.luau` (new file, per gameplay-programmer routing)

## Acceptance Criteria

**AC-1 (Boot invariant)** — GIVEN server starts, WHEN `MatchStateServer` initializes, THEN `MatchStateServer.get()` returns `"Lobby"` within the first heartbeat.

**AC-2 (Flag on join)** — GIVEN server in any state, WHEN `PlayerAdded` fires, THEN `getParticipation(player)` returns `true` immediately.

**AC-3 (Asymmetric freeze)** — GIVEN `Countdown:Snap`, WHEN player A attempts TRUE→FALSE, THEN rejected; flag stays `TRUE`. WHEN player B attempts FALSE→TRUE, THEN succeeds; flag becomes `TRUE`.

**AC-4 (Lobby → Ready)** — GIVEN `Lobby` with 1 participant, WHEN a second player sets flag `TRUE`, THEN transition to `Countdown:Ready` in ≤67ms; broadcast `{state: "Countdown:Ready", meta: {countdownTotal: 10}}`.

**AC-5 (Ready → Lobby revert)** — GIVEN `Countdown:Ready` elapsed <7s, WHEN `#participating` drops to 1, THEN state reverts to `Lobby` within one tick.

**AC-6 (Ready → Snap)** — GIVEN `Countdown:Ready` with `#participating >= 2`, WHEN `elapsed >= 7.0s`, THEN transitions to `Countdown:Snap`; max observed elapsed ≤7.067s at 15 Hz.

**AC-7 (Snap → Active with participants)** — GIVEN `Countdown:Snap`, t=10s, `#participating >= 1`, WHEN timer fires, THEN the mock call-order log records `[createAll, MatchStateChanged_broadcast]` in that sequence with no intervening entries. **Infrastructure owner:** gameplay-programmer provides `TestMatchStateBroadcastSpy` (spy-wraps `MatchStateChanged:FireAllClients` and `RoundLifecycle.createAll`) before story implementation begins.

**AC-8 (Snap → Result zero)** — GIVEN `Countdown:Snap` with all flags `FALSE` before t=10s, WHEN timer fires, THEN `createAll` NOT called; state → `Result`; broadcast `meta.winnerId == nil`.

**AC-9 (Last-crowd end)** — GIVEN `Active` with 2 crowds, WHEN `Eliminated` fires for A (leaving 1), THEN state → `Result` within one tick; `winnerId` = remaining crowd.

**AC-10 (Tiebreak determinism)** — GIVEN `Active`, t=300s, 2 crowds tie on `count`, WHEN `peak_count_timestamp` differ, THEN earlier timestamp wins. WHEN timestamps equal, THEN `argmin(UserId)` wins; result deterministic across repeated runs with the same fixture.

**AC-11 (Double-signal guard)** — GIVEN `Active`, 2 crowds eliminated same tick, WHEN both signals fire, THEN `transitionTo(Result)` called exactly once; broadcast count = 1.

**AC-12 (T6/T7 simultaneity)** — GIVEN `Active`, `elapsed >= 300.0s` AND a last-crowd elimination signal fires on the same tick, WHEN `Result` broadcasts, THEN `meta.winnerId` equals the crowd determined by the F4 tiebreak (count → `peak_count_timestamp` → `UserId`), NOT the last-standing crowd's id — verified via a fixture where the tiebreak winner and the last-standing crowd differ.

**AC-13 (T8 instant win)** — GIVEN `Active` with a sole remaining crowd (all other crowds `Eliminated` or DC'd), WHEN `MatchStateServer` detects the sole-survivor condition, THEN `grantMatchRewards` fires, then `Result` broadcasts within one tick; `meta.rivalDisconnected = true`; `meta.winnerId` = sole survivor's `crowdId`; no delay between detection and broadcast.

**AC-14 (T9 ordering)** — GIVEN `Result`, 10s elapsed, WHEN timer fires, THEN the mocked sequence log records `[destroyAll, clearAll, broadcast_Intermission]` in that order with no inversions — verified via server-side TestEZ fixture using injected spy functions.

**AC-15 (Flag reset)** — GIVEN `Intermission` with some flags `FALSE`, WHEN 10s elapses, THEN `getParticipation(p) == TRUE` for every connected player; state = `"Lobby"`.

**AC-16 (BindToClose)** — GIVEN `Active` with a live round, WHEN `game:BindToClose` fires, THEN within 2s all clients receive broadcast `state: "ServerClosing"`; `PlayerDataServer.onPlayerRemovingAsync` called per player over 28s; `grantMatchRewards` NOT called; no second `MatchStateChanged` broadcast during shutdown.

**AC-17 (Reliable broadcast completeness)** — GIVEN a client joining mid-state, WHEN per-player `MatchStateChanged` fires, THEN client receives `{state, serverTimestamp, stateEndsAt, meta}` all non-nil; `MatchStateClient.reconcile()` sets state + `clockOffset` without error.

**AC-18 (Timer interp clamp)** — GIVEN `clockOffset` cached and `stateEndsAt` known (Active=300s):
- WHEN `tick()` is 1s before `stateEndsAt`, THEN `displayedSeconds ≈ 1.0 ± 0.1s`.
- WHEN `tick()` is 5s after `stateEndsAt` (lag spike), THEN clamped to `0.0`, never negative.
- WHEN broadcast received at state entry, THEN clamped to `state_duration` (300.0), never exceeding.

**AC-19 (Performance budget)** — GIVEN `Active` at `SERVER_TICK_HZ = 15`, WHEN MatchState processes one tick with no transition, THEN tick handler CPU time < 0.1ms, verified via `tick()` delta over 100 consecutive ticks in TestEZ fixture.

**AC-20 (Result-entry grant ordering)** — GIVEN `Active` exits via T6, T7, or T8, WHEN the `Active` → `Result` transition fires, THEN the `TestMatchStateBroadcastSpy` log records `[grantMatchRewards, MatchStateChanged_broadcast("Result")]` in that sequence — grant commits before any client receives the `Result` state.

**AC-21 (Same-tick T6/T7 phase-order contract — RC-B-NEW-4)** — GIVEN `matchState == Active`, `elapsed = 300.0s` AND a pending `CrowdEliminated` signal for the second-to-last crowd queued AT phase start, WHEN TickOrchestrator runs phases 1-9 per §Core Rules Same-tick handler order, THEN: (a) Phase 6 MSM timer check fires `transitionTo(Result)` via T7 FIRST; (b) Phase 7 MSM elimination consumer evaluates double-signal guard `matchState != Active`, finds `matchState == Result`, silently drops queued elim; (c) final `matchState == "Result"` via T7 (NOT T6); (d) `meta.winnerId` resolved via F4 tiebreak using counts captured at Phase 6 evaluation time (post-Phase 1-4 drains); (e) only ONE `MatchStateChanged` broadcast fires this tick (T7's). *Evidence: integration test with deterministic tick stepper; mock CSM.getAllActive returning last-2 crowds at tick start.*
