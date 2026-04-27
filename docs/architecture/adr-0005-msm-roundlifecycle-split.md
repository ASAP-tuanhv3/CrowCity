# ADR-0005: Match State Machine / RoundLifecycle Split + Authority Matrix

## Status

**Accepted 2026-04-26** (closes ~35 gap TRs from `/architecture-review` 2026-04-26 — largest single-cluster gap; no remaining amendment dependencies; RL + MSM GDDs already aligned with this ADR's authority matrix).

Status history:
- 2026-04-26 — Proposed (initial)
- **2026-04-26 — ACCEPTED** (stories may now reference this ADR per `/story-readiness`)

## Date

2026-04-26 (initial Proposed + Accepted, same day)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Core (state machine authority + lifecycle coordination) |
| **Knowledge Risk** | LOW — `BindableEvent`, `RemoteEvent`, `game:BindToClose`, `Players.PlayerRemoving`, `os.clock`, `table.sort` all stable APIs predating LLM cutoff; `Packages.janitor` template-vendored stable lib |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md`, ADR-0001 §Decision + §Key Interfaces, ADR-0002 §Phase Sequence + §Decision (Phase 6/7), ADR-0003 §Server Per-Tick CPU Budget (Phase 6/7 = 0.05 ms each), ADR-0004 §Write-Access Matrix (MSM read-only on CSM count/state), ADR-0006 §Source Tree Map, `design/gdd/match-state-machine.md` (full), `design/gdd/round-lifecycle.md` (full), `design/gdd/crowd-state-manager.md` §Network event contract + §Server-side signals, `docs/architecture/architecture.md` §5.2 + §5.3 + §4.4 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (A) Phase 6/7 dispatch verification — `setTickDelegate` integration test confirms timerCheck before eliminationConsumer; (B) BindToClose grace timing — 30 s ProfileStore flush completes within Roblox platform 30 s grace; (C) DC freeze-at-disconnect contract — `Players.PlayerRemoving` handler runs before CSM `destroy(crowdId)` cascades; (D) InternalPlacement strip — broadcast adapter audit confirms `peakCount`/`isWinner`/`wasEliminated` absent from `FireAllClients` payload |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (CSM record shape + CrowdEliminated reliable RemoteEvent + CountChanged BindableEvent), ADR-0002 (Phase 6/7 callback structure + simultaneity rules), ADR-0003 (Phase 6/7 = 0.05 ms each CPU budget), ADR-0004 (MSM read-only on CSM count/state per Write-Access Matrix; RL is sole CountChanged production subscriber), ADR-0006 (Source Tree Map server-only placement) |
| **Enables** | MSM implementation stories (`MatchStateServer/init.luau`); RoundLifecycle implementation stories (`RoundLifecycle/init.luau`); Currency System implementation (consumes `placements: { Placement }` via `grantMatchRewards`); Round Result Screen + Leaderboard (consume broadcast `meta.placements[]`); future Daily Quest System (subscribes `MatchStateChanged` for round-completion signal) |
| **Blocks** | MSM + RoundLifecycle implementation stories cannot start until this ADR is Accepted; Currency grant + Result-screen + Leaderboard stories blocked transitively |
| **Ordering Note** | Must be Accepted before `/create-control-manifest`. No GDD amendment dependencies (RoundLifecycle GDD + MSM GDD already aligned with this ADR's authority matrix; this ADR codifies what the GDDs already specify). |

## Context

### Problem Statement

`/architecture-review` 2026-04-26 surfaced ~35 gap TRs concentrated in two GDDs: `match-state-machine.md` (12 gap TRs) + `round-lifecycle.md` (11 gap TRs) + cross-system gaps (~12 TRs spanning CSM/Currency/HUD/Spectator). Both GDDs are individually complete + design-reviewed, but their authority surface and module split have no ADR-level lock. Implications:

1. **Authority overlap risk** — without an ADR, MSM and RoundLifecycle could plausibly both claim ownership of placement formula F3 (RL GDD locks RL ownership, MSM GDD references it but does not constrain) or peakCount tracking (RL claims it; CSM Batch 1 made `CountChanged` server-only consumable by anyone). Stories citing only one GDD might wire mutators incorrectly.
2. **Phase 6/7 callback contract scattered** — ADR-0002 names `MSM.timerCheck` (Phase 6) + `MSM.eliminationConsumer` (Phase 7) but does not specify their semantics; MSM GDD specifies semantics but does not formally name MSM as the sole TickOrchestrator-callable owner.
3. **T9 ordering invariant not architecturally locked** — architecture.md §4.4 + MSM AC-14 specify `RoundLifecycle.destroyAll → RelicSystem.clearAll → MatchStateChanged broadcast`, but the order is convention-only without an ADR. A future story could plausibly broadcast first and clean up later, breaking client-state-consistency invariants.
4. **Result-entry grants-before-broadcast invariant scattered** — MSM AC-20 specifies "grants fire BEFORE MatchStateChanged('Result')" but no ADR locks it. Currency grant code could be wired post-broadcast, creating a 1-tick race where clients see Result-state but currency-balance not yet updated.
5. **InternalPlacement leak risk** — RoundLifecycle GDD §F3 specifies `InternalPlacement` (5-field broadcast schema + 3 internal fields: `peakCount`/`isWinner`/`wasEliminated`); both GDDs flag the broadcast adapter as a guard point. No ADR enforces.
6. **CountChanged subscriber matrix unspecified at ADR level** — ADR-0004 §Write-Access Matrix lists CountChanged subscribers ("RoundLifecycle peakCount tracking, analytics stubs Alpha+, future in-session scoring") but does not lock RL as the sole production subscriber, nor formally forbid cosmetic systems from gating gameplay decisions on CountChanged for Pillar 4.
7. **MIN_PLAYERS_TO_START soft threshold** — MSM GDD T2 (`MIN_PLAYERS_TO_START = 2`) drives Countdown:Ready ↔ Lobby revert; no ADR. Matchmaker stories may not honour the threshold.
8. **Spectator mode (AFK / mid-round join / Eliminated during Active)** — MSM GDD describes participation flag semantics but stories cannot cite an ADR for the spectator-state contract.
9. **BindToClose 30 s grace + no-currency-grant rule** — MSM GDD §T11 + architecture.md §4.5 specify the rule; ADR lock missing.
10. **Stories blocked** — `/create-stories` for MSM + RoundLifecycle + Currency grant cannot embed ADR refs; `/story-readiness` rejects.

### Constraints

- **Single-server, single-threaded Luau** — no concurrent tick dispatch; MSM + RL run sequentially within Phase 6/7 of TickOrchestrator (15 Hz cadence per ADR-0001/0002).
- **CSM authority** — ADR-0004 §Pillar 4 + §Write-Access Matrix already lock CSM mutators away from MSM. MSM/RL are **read-only consumers** of CSM (`get`/`getAllActive`/`getAllCrowdPositions` for read; `CrowdEliminated` reliable + `CountChanged` BindableEvent for signal subscribe). MSM/RL must not regress this.
- **Phase 6 + Phase 7 atomicity** — per ADR-0002 §simultaneity rules, MSM.timerCheck (Phase 6) runs BEFORE MSM.eliminationConsumer (Phase 7); both run within one Heartbeat callback before Phase 8 broadcast.
- **`game:BindToClose` 30 s platform grace** — ProfileStore handles per-player save retry; mid-round currency-grant on shutdown is **forbidden** (anti-exploit per MSM AC-perf invariant + Pillar 3).
- **Pillar 3 (5-min clean rounds, no per-round persistence)** — neither MSM nor RL writes to ProfileStore; all state is ephemeral; `destroyAll` clean-wipe is a hard invariant.
- **Pillar 4 (anti-P2W)** — cosmetic systems must not subscribe to CountChanged for gameplay decisions (count display via CrowdStateClient is presentation-only and acceptable; gating gameplay decisions on CountChanged is forbidden).
- **`MAX_PARTICIPANTS_PER_ROUND = 12`** — design cap; ADR-0001 bandwidth budget assumes; assertion enforced.
- **Network budget** — ADR-0003 §Network table already allocates `MatchStateChanged` 0.05 KB/s + `ParticipationChanged` (rolled into reliable gameplay events 0.5 KB/s budget). This ADR adds no traffic.

### Requirements

- Lock **module split** — MatchStateServer + RoundLifecycle as two separate modules at `ServerStorage/Source/MatchStateServer/init.luau` + `ServerStorage/Source/RoundLifecycle/init.luau` per ADR-0006 §Source Tree Map
- Lock **MSM-only caller rule** — MSM is the sole caller of all five RoundLifecycle methods (`createAll`/`setWinner`/`getPlacements`/`getPeakTimestamp`/`destroyAll`)
- Lock **authority matrix** — F4 tiebreak owner (MSM); F3 placement sort owner (RL); peakCount tracker (RL via CountChanged); eliminationTime tracker (RL via CrowdEliminated + PlayerRemoving, idempotent); participation flags owner (MSM, frozen Countdown:Snap exit)
- Lock **Phase 6/7 callback contract** — `MatchStateServer.timerCheck()` (Phase 6 — T7 timer expiry transition) + `MatchStateServer.eliminationConsumer()` (Phase 7 — T6 last-standing transition + double-signal guard); both TickOrchestrator-only callers per ADR-0002 §Decision
- Lock **T9 ordering invariant** — `RoundLifecycle.destroyAll() → RelicSystem.clearAll() → MatchStateChanged("Intermission") broadcast`. Locked at architecture level — stories must obey.
- Lock **Result entry ordering** — `Currency.grantMatchRewards(placements: { Placement }) → MatchStateChanged("Result", meta) broadcast`. Grants atomic with state transition; broadcast is post-grant.
- Lock **InternalPlacement strip rule** — broadcast adapter MUST strip `peakCount`/`isWinner`/`wasEliminated` before `RemoteEvent:FireAllClients`; MSM owns the strip
- Lock **CountChanged subscriber matrix** — RL is sole production subscriber (peakCount tracking); analytics stubs Alpha+ may subscribe; future in-session scoring may subscribe; **cosmetic systems FORBIDDEN from subscribing for gameplay decisions** per Pillar 4
- Lock **MIN_PLAYERS_TO_START = 2 soft threshold** — Countdown:Ready ↔ Lobby revert when participation drops below threshold
- Lock **BindToClose 30 s grace + no-currency-grant rule** — MSM owns T11 transition; ProfileStore per-player save retry; mid-round currency forbidden (anti-exploit + Pillar 3)
- Lock **Spectator mode contract** — AFK / mid-round-join / Eliminated-during-Active all enter spectator state (no participation flag); MSM owns transitions
- Define **enforcement layers** — module placement (L1 — Roblox engine) + code review (L2) + control manifest (L3) + architecture review (L4) + story readiness (L5)
- Surface **forbidden patterns** — non-MSM caller of RL methods; getPlacements before setWinner (with non-empty participants); InternalPlacement leak to client broadcast; cosmetic-system CountChanged subscription for gameplay; ProfileStore writes during round (non-cosmetic data); cross-server state via MessagingService

## Decision

**`MatchStateServer` (server-only at `ServerStorage/Source/MatchStateServer/init.luau`) owns the 7-state match machine + per-player participation flags + win-condition resolution + BindToClose handler. `RoundLifecycle` (server-only at `ServerStorage/Source/RoundLifecycle/init.luau`) owns per-round auxiliary state (`_crowds` aux + `_participants` snapshot + `_winnerId`) + placement F3 sort + DC freeze-at-disconnect. MSM is the sole caller of all five RoundLifecycle public methods. The two modules' authority surfaces are disjoint by design — MSM never mutates `_crowds` aux fields; RL never resolves win conditions or fires `MatchStateChanged`. TickOrchestrator dispatches `MSM.timerCheck` (Phase 6) before `MSM.eliminationConsumer` (Phase 7), enforcing T6/T7 simultaneity resolution. Round-end ordering invariants — `destroyAll → clearAll → broadcast` (T9) and `grantRewards → broadcast` (Result entry) — are architectural-level locks, not GDD conventions.**

### Module Split — Disjoint Authority Surfaces

```text
┌──────────────────────────────────────────────────────────────────────┐
│ MatchStateServer (server-only)                                       │
│ Path: ServerStorage/Source/MatchStateServer/init.luau                │
│                                                                      │
│ OWNS:                                                                │
│   _state: MatchState                  (7-state enum)                 │
│   _stateEndsAt: number?               (os.clock epoch — Active end)  │
│   _participation: { [Player]: bool }  (frozen Countdown:Snap exit)   │
│                                                                      │
│ EXPOSES (read-only to other systems + RemoteFunction):               │
│   get(): MatchState                                                  │
│   getParticipation(player: Player): boolean                          │
│   getStateEndsAt(): number?                                          │
│                                                                      │
│ EXPOSES (TickOrchestrator-only — Phase 6 + Phase 7):                 │
│   timerCheck()              ◄── Phase 6: T7 transition               │
│   eliminationConsumer()     ◄── Phase 7: T6 + double-signal guard    │
│                                                                      │
│ INTERNAL (called only by MSM itself — never external):               │
│   _transitionTo(newState, meta)       (drives all 7 states)          │
│                                                                      │
│ CALLS (sole-caller of RoundLifecycle):                               │
│   RoundLifecycle.createAll(participants)    (T4)                     │
│   RoundLifecycle.setWinner(crowdId)         (Active exit)            │
│   RoundLifecycle.getPlacements()            (Result entry)           │
│   RoundLifecycle.getPeakTimestamp(crowdId)  (F4 tiebreak)            │
│   RoundLifecycle.destroyAll()               (T9)                     │
│                                                                      │
│ READS (per ADR-0004 — MSM is read-only on CSM):                      │
│   CrowdStateServer.get(crowdId)                                      │
│   CrowdStateServer.getAllActive()                                    │
│ SUBSCRIBES (per ADR-0001 — MSM consumes CSM signals):                │
│   CrowdEliminated reliable RemoteEvent     (drained Phase 7)         │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                │ MSM is sole caller
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ RoundLifecycle (server-only)                                         │
│ Path: ServerStorage/Source/RoundLifecycle/init.luau                  │
│                                                                      │
│ OWNS:                                                                │
│   _crowds: { [crowdId]: AuxRecord }                                  │
│     where AuxRecord = {                                              │
│       crowdId, userId, peakCount, peakTimestamp,                     │
│       finalCount, eliminationTime?, isWinner                         │
│     }                                                                │
│   _participants: { Player }            (frozen snapshot at createAll)│
│   _winnerId: string?                                                 │
│   _janitor: Janitor                    (per-round signal cleanup)    │
│                                                                      │
│ EXPOSES (MSM-only callers — locked):                                 │
│   createAll(participants: { Player }): ()                            │
│   setWinner(crowdId: string?): ()                                    │
│   getPlacements(): { Placement }   (5-field broadcast schema)        │
│   getPeakTimestamp(crowdId: string): number?                         │
│   destroyAll(): ()                                                   │
│                                                                      │
│ SUBSCRIBES (per ADR-0001/0004 — RL consumes CSM signals):            │
│   CrowdEliminated reliable RemoteEvent  (idempotent eliminationTime) │
│   CountChanged BindableEvent (server-only)  (peakCount + finalCount) │
│   Players.PlayerRemoving                 (DC freeze-at-disconnect)   │
│                                                                      │
│ CALLS (per ADR-0004 — RL is RoundLifecycle-only CSM caller):         │
│   CrowdStateServer.create(crowdId, initial)  (per-participant T4)    │
│   CrowdStateServer.destroy(crowdId)          (per-crowd T9)          │
└──────────────────────────────────────────────────────────────────────┘
```

### Authority Matrix (LOCKED)

| Concern | Owner | Consumer (read) | Notes |
|---|---|---|---|
| 7-state match enum + transitions | MSM | All client systems via `MatchStateChanged` reliable | Only MSM may call `_transitionTo` |
| `_stateEndsAt` (Active end timestamp) | MSM | MatchStateClient (F6 timer interp) | Read-only to other server systems |
| Participation flags | MSM | All systems via `getParticipation(player)` + `ParticipationChanged` reliable | Frozen at Countdown:Snap exit; released at Intermission entry |
| F4 win-condition tiebreak | MSM | — | Calls `RoundLifecycle.getPeakTimestamp` for input; never RL-internal |
| Phase 6 callback (T7 timer expiry) | MSM | TickOrchestrator (Phase 6 dispatcher) | Sole TickOrchestrator-callable owner |
| Phase 7 callback (T6 last-standing + double-signal guard) | MSM | TickOrchestrator (Phase 7 dispatcher) | Sole TickOrchestrator-callable owner; drains CSM CrowdEliminated reliable signals queued during Phase 5 |
| `_crowds` auxiliary records | RL | MSM via `getPlacements`/`getPeakTimestamp` | MSM never mutates `_crowds` directly |
| `peakCount` + `peakTimestamp` tracking | RL (CountChanged subscriber) | MSM (`getPeakTimestamp`); Currency / Leaderboard (via Placement) | Strict `>` rule per RL F1 |
| `eliminationTime` tracking | RL (CrowdEliminated + PlayerRemoving subscriber, idempotent) | MSM (`getPlacements`); Currency / Leaderboard (via Placement) | First-fire wins; subsequent fires no-op |
| `_participants` snapshot | RL (set at `createAll`) | MSM (read via `getPlacements`) | Frozen for round; immutable |
| `_winnerId` | RL (set via `setWinner` from MSM) | MSM (validation in `getPlacements`) | MSM resolves winner identity via F4; RL stores |
| F3 placement composite sort | RL | MSM via `getPlacements` | 5-key composite: peakCount desc → survived desc → finalCount desc → eliminationTime desc → UserId asc |
| Broadcast adapter (InternalPlacement strip) | MSM | — | MSM strips `peakCount`/`isWinner`/`wasEliminated` before `MatchStateChanged:FireAllClients(meta)` |
| `MatchStateChanged` reliable RemoteEvent | MSM | All clients | Fires once per transition; payload `{state, serverTimestamp, stateEndsAt, meta}` |
| `ParticipationChanged` reliable RemoteEvent | MSM | Owning client only | Per-player; fires on flag flip |
| BindToClose handler (T11 ServerClosing transition) | MSM | — | 30 s platform grace; ProfileStore per-player save retry; **NO currency grant** (anti-exploit + Pillar 3) |
| MIN_PLAYERS_TO_START = 2 threshold | MSM | — | Countdown:Ready ↔ Lobby revert; matchmaker stories must obey |
| Spectator mode contract | MSM | All client UI systems via participation flag | AFK / mid-round-join / Eliminated-during-Active all enter spectator |

### Round-End Ordering Invariants (LOCKED)

**T9 — Active → Intermission via Result exit:**
```text
1. RoundLifecycle.destroyAll()
   ├─ janitor:Destroy()                  -- disconnects all signal subs
   ├─ for each crowd in _crowds:
   │     CrowdStateServer.destroy(crowdId)  -- fires CrowdDestroyed reliable
   └─ table.clear all RL state
2. RelicSystem.clearAll()                 -- per-crowd onExpire ascending; resets radiusMultiplier 1.0
3. MatchStateServer:_transitionTo("Intermission", {})
   └─ FireAllClients(MatchStateChanged, "Intermission", meta)
```

**Rationale**: clients must not observe Intermission state before server cleanup completes. Broadcast last; cleanup first. Order is enforced by MSM `_transitionTo` calling `destroyAll → clearAll` in sequence before firing the broadcast.

**Result entry — T6 / T7 / T8 → Result:**
```text
1. _winnerId resolved by MSM (F4 tiebreak for T7; last-standing for T6/T8)
2. RoundLifecycle.setWinner(_winnerId)
3. placements = RoundLifecycle.getPlacements()
4. Currency.grantMatchRewards(placements)   -- ATOMIC with state transition
5. MatchStateServer:_transitionTo("Result", meta = {placements_stripped, ...})
   └─ FireAllClients(MatchStateChanged, "Result", meta)
```

**Rationale**: client receives Result-state broadcast AFTER currency balance is updated server-side. Coin-tick animation on Result-screen receipt has guaranteed-fresh PlayerData. No 1-tick race where client sees Result but balance not yet bumped.

### Phase 6/7 Simultaneity (per ADR-0002, codified here)

Per ADR-0002 §simultaneity rules:
- **T6 vs T7 same tick**: Phase 6 runs first. If timer expiry triggers T7, `matchState == "Result"`. Phase 7's double-signal guard (`if matchState ~= "Active" then return end`) drops queued `CrowdEliminated` signals. Winner resolved by F4 tiebreak using counts at Phase 6 evaluation time (post-Phase 1-4 drains).
- **Double-elim same tick**: Phase 5 (CSM eval) fires both `CrowdEliminated` reliable signals. Phase 7 drains. First signal triggers T6 → `_transitionTo("Result")`. Second signal's `matchState ~= "Active"` check fails → silently dropped.
- **Grace entry + overlap-clear same tick**: handled by CSM Phase 5 internally; MSM observes only the final `CrowdEliminated` if grace timer expires with overlap-still-true; no MSM responsibility.

ADR-0005 confirms these as MSM contract guarantees, not just ADR-0002 phase ordering.

### Key Interfaces

```lua
-- ServerStorage/Source/MatchStateServer/init.luau
--!strict

export type MatchState =
    "Lobby" | "Countdown:Ready" | "Countdown:Snap" |
    "Active" | "Result" | "Intermission" | "ServerClosing"

export type Placement = {
    crowdId: string,
    userId: number,
    placement: number,        -- 1-indexed
    crowdCount: number,       -- = record.finalCount
    eliminationTime: number?, -- nil for survivors
}

-- Read accessors (any server system + exposed to client via RemoteFunction)
function MatchStateServer.get(): MatchState
function MatchStateServer.getParticipation(player: Player): boolean
function MatchStateServer.getStateEndsAt(): number?

-- TickOrchestrator-only phase hooks
function MatchStateServer.timerCheck(): ()                       -- Phase 6
function MatchStateServer.eliminationConsumer(): ()              -- Phase 7

-- BindToClose handler (registered at boot in ServerScriptService/start.server.luau)
-- Internal — fires T11 transition; calls ProfileStore save loop; NO currency grant.

-- ServerStorage/Source/RoundLifecycle/init.luau
--!strict

export type AuxRecord = {
    crowdId: string,
    userId: number,
    peakCount: number,        -- [CROWD_START_COUNT, 300]
    peakTimestamp: number,    -- os.clock() of last strict-> peak update
    finalCount: number,       -- [1, 300]
    eliminationTime: number?, -- nil = survived
    isWinner: boolean,        -- internal — set by setWinner
}

export type InternalPlacement = Placement & {
    peakCount: number,        -- internal
    isWinner: boolean,        -- internal
    wasEliminated: boolean,   -- internal
}

-- MSM-only callers (locked)
function RoundLifecycle.createAll(participants: { Player }): ()
function RoundLifecycle.setWinner(crowdId: string?): ()
function RoundLifecycle.getPlacements(): { Placement }            -- broadcast schema (5-field)
function RoundLifecycle.getPeakTimestamp(crowdId: string): number?
function RoundLifecycle.destroyAll(): ()
```

### Caller Authority Matrix

| Method | Authorised callers (sole set) | Forbidden |
|---|---|---|
| `RoundLifecycle.createAll(participants)` | MatchStateServer (T4 transition only) | All other systems |
| `RoundLifecycle.setWinner(crowdId)` | MatchStateServer (Active exit only) | All other systems |
| `RoundLifecycle.getPlacements()` | MatchStateServer (Result entry only — must follow `setWinner`) | All other systems |
| `RoundLifecycle.getPeakTimestamp(crowdId)` | MatchStateServer (F4 tiebreak during Active only) | All other systems |
| `RoundLifecycle.destroyAll()` | MatchStateServer (T9 transition only) | All other systems |
| `MatchStateServer.timerCheck()` | TickOrchestrator (Phase 6 dispatcher) | All other systems |
| `MatchStateServer.eliminationConsumer()` | TickOrchestrator (Phase 7 dispatcher) | All other systems |
| `MatchStateServer.get()` / `getParticipation()` / `getStateEndsAt()` | Any server-side system + exposed to client via RemoteFunction (`GetParticipation`) | — (no caller restriction) |
| Internal `_transitionTo` (MSM private) | MSM only | Anything outside MSM |

### CountChanged Subscriber Matrix (LOCKED)

`CrowdStateServer.CountChanged` is a server-only `BindableEvent`, **NOT replicated**. Subscriber set:

| Subscriber | Status | Purpose |
|---|---|---|
| RoundLifecycle | MVP — production | peakCount + finalCount tracking via F1 strict `>` rule |
| Analytics stubs (CustomAnalytics / EconomyAnalytics) | Alpha+ | source-aware delta logging (deltaSource ∈ {Absorb, Collision, Chest, Relic}) |
| In-session scoring | Future (post-Alpha) | leaderboard updates if added |
| **Cosmetic systems (Skin / Avatar / Banner / Trail)** | **PERMANENTLY FORBIDDEN** | Pillar 4 anti-P2W invariant per ADR-0004 — count display via CrowdStateClient is presentation-only and acceptable; gating gameplay decisions on CountChanged is forbidden |
| Clients | **PERMANENTLY FORBIDDEN** | Clients use 15 Hz `CrowdStateBroadcast` UnreliableRemoteEvent for count display; CountChanged is server-internal |

Enforcement: defense-in-depth via L1 (BindableEvent is server-side instance — clients cannot subscribe by Roblox semantics; that's the Roblox engine semantics firewall) + L2 code review + L3 control manifest extraction.

### Defense-in-Depth Enforcement Layers

| Layer | Mechanism | What it catches |
|---|---|---|
| **L1** Roblox engine semantics | `BindableEvent` is server-side; `ServerStorage` placement | All client-side mutation attempts (impossible by engine); cosmetic-system runtime CountChanged subscribe (impossible — server-only) |
| **L2** Code review | PR reviewer checks every call site against §Caller Authority Matrix + §CountChanged Subscriber Matrix | Same-server caller mismatches (e.g. HUD calling `getPlacements`); broadcast adapter missing InternalPlacement strip |
| **L3** Control manifest | `/create-control-manifest` extracts Authority Matrix + Subscriber Matrix verbatim | Daily implementation reference for programmers |
| **L4** Architecture review | `/architecture-review` cross-checks each ADR/GDD's claimed callers vs the matrix | New systems silently adding themselves as callers |
| **L5** Story readiness | `/story-readiness` validates story embeds correct caller + ordering | Story-level violations before code is written |

## Alternatives Considered

### Alternative 1: Combine MSM and RoundLifecycle into single module

- **Description**: One `MatchSystem` module that owns 7-state machine + per-round aux state + placement sort + Phase 6/7 callbacks + BindToClose. No split.
- **Pros**: One module, fewer cross-module calls, simpler module diagram.
- **Cons**: Authority surface bloats — placement sort + state machine + DC handling + ProfileStore-on-shutdown all in one file. Testing harder (cannot fixture aux state without state machine running). Authority matrix collapses — the "MSM is sole caller of RL" rule disappears, replaced by no rule. Future Currency / Leaderboard would have to subscribe to a single fat module rather than reading a clean Placement array. Round-end ordering invariants harder to verify when both lifecycle cleanup and broadcast live in the same module.
- **Rejection Reason**: Architecture.md §5.2 + §5.3 already split them as Core authorities; both GDDs already authored against the split. RL is the round-scope coordinator (Pillar 3 clean-wipe); MSM is the state machine. Mixing them re-couples concerns the design has already separated.

### Alternative 2: RoundLifecycle owns Phase 6/7 callbacks instead of MSM

- **Description**: TickOrchestrator dispatches Phase 6/7 to RoundLifecycle, which then queries MSM for state and triggers transitions via callback.
- **Pros**: RL is closer to the data (`_crowds` aux); Phase 7 elimination consumer is naturally near the elimination signal subscription.
- **Cons**: RL becomes a state-machine driver (writes state by triggering MSM transitions), violating disjoint-authority. The `_transitionTo` API would have to be exposed externally to RL; doing so breaks MSM's "internal-only" guard. Win-condition resolution (F4) lives in MSM today; moving Phase 6/7 to RL forces RL to also call MSM's tiebreak logic, creating circular dependency. Tests for RL would need a state machine to assert against. `/story-readiness` becomes harder — every transition story would cite both RL and MSM.
- **Rejection Reason**: ADR-0002 already names `MSM.timerCheck` + `MSM.eliminationConsumer`; that decision is locked. Reverting it would supersede ADR-0002 with no benefit.

### Alternative 3: Per-state submodule split (one module per state)

- **Description**: `LobbyState.luau` / `CountdownReadyState.luau` / `ActiveState.luau` etc. — 7 modules, each with its own enter/exit/tick. MSM is a thin dispatcher.
- **Pros**: Each state is small and testable in isolation. Adding new states (e.g. spectator-only state for VS+) is a single-file change.
- **Cons**: 7+ files for what is currently a 7-row state table. Cross-state shared concerns (participation flags, BindToClose) have no clear owner; either replicated across files or hoisted into a shared utility, neither clean. State enum + transition table no longer co-located. Tests must mock cross-state transitions, harder to fixture. RoundLifecycle integration touches all 7 files instead of just MSM.
- **Rejection Reason**: 7 states is small enough to keep in one module without complexity; MSM GDD has it codified inline; no design-time benefit from splitting. MVP scope.

### Alternative 4: Currency grant fires AFTER MatchStateChanged broadcast (post-Result)

- **Description**: Move `Currency.grantMatchRewards(placements)` to after `MatchStateChanged("Result", meta)` instead of before. Client shows Result screen first, then receives `PlayerDataUpdated` with new balance.
- **Pros**: Snappier "Result reveal" — clients see scoreboard instantly; balance update animates in slightly later.
- **Cons**: 1-tick race where clients see Result-state but balance still pre-grant. Coin-tick animation on Result-screen mounting fires with stale balance; new balance arrives 1-3 frames later, requiring re-tween. Currency-grant-on-broadcast-fail edge case — if `FireAllClients` succeeds but `grantMatchRewards` errors, players see Result screen with no rewards (looks like a grant skip). MSM AC-20 explicitly specifies grants-before-broadcast for this reason.
- **Rejection Reason**: GDD-locked invariant exists for a reason. Aesthetic snappiness loss is small; race condition correctness gain is large.

## Consequences

### Positive

- ADR-level lock on module split + authority matrix — closes ~35 gap TRs from `/architecture-review` 2026-04-26 (largest single cluster)
- MSM + RoundLifecycle implementation stories now unblocked once this ADR is Accepted
- Currency grant + Result-screen + Leaderboard implementations can cite this ADR for grant-before-broadcast invariant
- Round-end ordering invariants (T9 + Result entry) locked at architecture level — code review has explicit checklist
- InternalPlacement strip rule has architectural-level enforcement — broadcast adapter audit becomes a checked item
- CountChanged subscriber matrix explicit — Pillar 4 anti-P2W invariant strengthened (cosmetic systems forbidden from gameplay-gating subscriptions)
- T6/T7 simultaneity rules from ADR-0002 codified as MSM contract — story authors don't need to cross-read two ADRs
- BindToClose 30 s + no-currency-grant rule locked — anti-exploit posture explicit at architecture level

### Negative

- 5-method MSM-only-caller restriction on RoundLifecycle adds code-review burden — every RL call site must be verified
- Documentation duplication — RL GDD §F3 + MSM GDD §F4 + this ADR + future control manifest all describe the placement/tiebreak logic; drift risk if any updates without others
- T9 + Result-entry ordering invariants are convention-enforced (no runtime guard); a future story could violate by reordering calls in `_transitionTo`. Mitigation: code review + control manifest + integration test
- Phase 6/7 callbacks are tightly coupled to ADR-0002 phase table — any future need to reorder phases requires ADR-0002 amend + this ADR amend + propagate
- Currency System still unauthored — `grantMatchRewards(placements)` signature is a forward declaration; future Currency ADR must adopt it

### Risks

- **Risk 1 (LOW)** — RoundLifecycle GDD F3 5-key composite sort + `MAX_PARTICIPANTS_PER_ROUND = 12` → table.sort cost. Mitigation: ADR-0003 §Phase budget already covers; RL AC-16 specifies `<10ms` for 12 records 100 calls (well within Phase 7 0.05 ms budget over 1 call).
- **Risk 2 (LOW)** — Documentation drift between RL GDD + MSM GDD + this ADR + control manifest. Mitigation: `/architecture-review` consistency check; `/propagate-design-change` runs on any GDD or ADR edit affecting the authority matrix.
- **Risk 3 (LOW)** — A future Skin / Avatar / Banner system might propose subscribing to CountChanged for "skin-tier-by-peak" cosmetic feature. Mitigation: §CountChanged Subscriber Matrix forbids it at ADR-level + ADR-0004 §Pillar 4 confirms; any future feature proposing this must supersede both ADRs with explicit creative-director sign-off.
- **Risk 4 (MEDIUM)** — `Players.PlayerRemoving` handler racing with CSM `destroy(crowdId)` — if RL's PlayerRemoving handler runs after CSM destroy, the `_crowds[crowdId]` lookup hits CSM-already-destroyed state. Mitigation: RL stores its OWN aux record keyed on `tostring(player.UserId)`, separate from CSM's `_crowds`; CSM destroy doesn't touch RL aux. RL's PlayerRemoving handler reads RL aux only. Cross-module race avoided by disjoint authority surfaces.
- **Risk 5 (LOW)** — BindToClose 30 s grace overruns Roblox platform's hard 30 s ServerClose timeout. Mitigation: ProfileStore handles per-player save retry with exponential backoff; if 30 s insufficient, ProfileStore drops save (data loss). MSM does not retry beyond 30 s — Roblox forces shutdown. Acceptable per Pillar 3 (no per-round persistence; only cosmetic data is at risk, and that's already retried by ProfileStore on next session).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/match-state-machine.md` §C 7 states | "Single server-wide state, all players shared, transitions instant" | §Module Split + §Authority Matrix: MSM owns 7-state enum + transitions |
| `design/gdd/match-state-machine.md` §C participation flags | "Per-player asymmetric, frozen on Countdown:Snap exit" | §Authority Matrix MSM owner; §CountChanged Subscriber Matrix forbids cosmetic-system gating |
| `design/gdd/match-state-machine.md` F4 tiebreak | "peak_count > survived > finalCount > eliminationTime > UserId" | §Module Split: MSM owns F4; calls `RL.getPeakTimestamp` for input |
| `design/gdd/match-state-machine.md` AC-7 createAll synchronous | "createAll synchronous before Active broadcast" | §Round-End Ordering Invariants implied + §Authority Matrix MSM-only-caller |
| `design/gdd/match-state-machine.md` AC-11 double-signal guard | "Second Eliminated → Result transition blocked" | §Phase 6/7 Simultaneity codified |
| `design/gdd/match-state-machine.md` AC-14 T9 ordering | "destroyAll → clearAll → broadcast Intermission" | §Round-End Ordering Invariants T9 locked architecturally |
| `design/gdd/match-state-machine.md` AC-19 perf | "<0.1 ms per tick MSM logic" | §ADR-0003 dependency; Phase 6/7 = 0.05 ms each = 0.1 ms total |
| `design/gdd/match-state-machine.md` AC-20 Result entry ordering | "grants fire BEFORE MatchStateChanged('Result')" | §Round-End Ordering Invariants Result entry locked |
| `design/gdd/match-state-machine.md` T11 BindToClose | "30 s grace ProfileStore flush; no partial currency" | §Authority Matrix BindToClose row + §Constraints Pillar 3 |
| `design/gdd/match-state-machine.md` MIN_PLAYERS_TO_START | "Soft threshold = 2; revert Countdown:Ready ↔ Lobby" | §Authority Matrix MSM owner |
| `design/gdd/round-lifecycle.md` §C per-round aux state | "_crowds, _participants, _winnerId" | §Module Split: RL owner; §Authority Matrix |
| `design/gdd/round-lifecycle.md` §C subscription lifecycle | "createAll: subscribe via Janitor; destroyAll: janitor:Destroy" | §Module Split RL diagram; §Round-End Ordering Invariants T9 |
| `design/gdd/round-lifecycle.md` F1 peak update strict `>` | "newCount > peakCount → update peak + timestamp" | §Authority Matrix peakCount tracker = RL |
| `design/gdd/round-lifecycle.md` F2 elimination time idempotent | "First-fire wins; subsequent fires no-op" | §Authority Matrix eliminationTime tracker = RL (idempotent) |
| `design/gdd/round-lifecycle.md` F3 placement composite sort | "5-key composite: peakCount → survived → finalCount → eliminationTime → UserId" | §Authority Matrix F3 placement sort owner = RL |
| `design/gdd/round-lifecycle.md` F4 getPeakTimestamp | "nil → math.huge in MSM tiebreak" | §Module Split + §Authority Matrix MSM consumer of RL.getPeakTimestamp |
| `design/gdd/round-lifecycle.md` §C clean-wipe invariant | "after destroyAll: #_crowds == 0, no live RBXScriptConnection" | §Round-End Ordering Invariants T9 + Pillar 3 constraint |
| `design/gdd/round-lifecycle.md` AC-2 createAll pcall failure | "pcall per player; failed = excluded participant (spectator)" | §Module Split RL diagram + §Authority Matrix |
| `design/gdd/round-lifecycle.md` AC-15 broadcast schema split | "Internal fields stripped before FireAllClients" | §Authority Matrix Broadcast adapter row + §Round-End Ordering Invariants |
| `design/gdd/round-lifecycle.md` AC-17 DC freeze-at-disconnect | "PlayerRemoving sets eliminationTime; record kept until destroyAll" | §Authority Matrix RL eliminationTime tracker + Risk 4 mitigation |
| `design/gdd/crowd-state-manager.md` §G CountChanged | "Server-only BindableEvent; NOT replicated" | §CountChanged Subscriber Matrix locks production subscriber set |
| `design/gdd/game-concept.md:179` Pillar 4 anti-P2W | "NOT pay-to-win" | §CountChanged Subscriber Matrix forbids cosmetic-system gameplay gating |
| ADR-0001 §Key Interfaces CrowdEliminated reliable | "Server → all clients reliable on Active→Eliminated" | §Module Split: MSM + RL both subscribe; Phase 7 drains queued in Phase 5 |
| ADR-0002 §Phase Sequence Phase 6/7 | "MSM.timerCheck (P6) before MSM.eliminationConsumer (P7)" | §Phase 6/7 Simultaneity codified as MSM contract |
| ADR-0002 §simultaneity T6/T7 | "Timer wins same-tick; double-signal guard drops second elim" | §Phase 6/7 Simultaneity locked |
| ADR-0003 §Phase Budget Phase 6/7 | "0.05 ms each = 0.1 ms total MSM" | §Performance Implications confirms |
| ADR-0004 §Write-Access Matrix | "MSM/RL is read-only on CSM count/state mutators" | §Module Split MSM/RL only call CSM.create/destroy + read APIs; never mutators |
| ADR-0006 §Source Tree Map | "ServerStorage/Source/MatchStateServer + RoundLifecycle" | §Module Split confirms placement |

## Performance Implications

- **CPU (server)**: Phase 6 MSM.timerCheck = 0.05 ms (single `os.clock()` comparison + per-tick branch); Phase 7 MSM.eliminationConsumer = 0.05 ms (drains ≤12 queued reliable signals + transitions or no-op). RL `getPlacements` called once per round on Result entry — `table.sort` on ≤12 records, O(N log N) ≈ <1 ms one-shot, NOT in tick budget. Total per-tick: 0.1 ms (matches ADR-0003 allocation).
- **CPU (client)**: zero — MSM + RL are server-only. Client receives `MatchStateChanged` reliable + `ParticipationChanged` reliable rare events.
- **Memory (server)**: MSM ~1 KB (state enum + 12 participation flags + stateEndsAt); RL ~2 KB (12 AuxRecord × ~150 B + Janitor + winner ID). Matches ADR-0003 §Server Memory rows.
- **Memory (client)**: MatchStateClient ~0.5 KB (local state + clockOffset cache).
- **Load Time**: MSM + RL module init at server boot; one BindToClose registration; no DataStore I/O. Negligible.
- **Network**: zero new traffic. ADR-0003 §Network table unchanged — `MatchStateChanged` 0.05 KB/s + `ParticipationChanged` rolled into reliable gameplay events 0.5 KB/s already covered.

## Migration Plan

No existing MSM or RoundLifecycle implementation. Clean implementation against this ADR.

1. Implement `ServerStorage/Source/MatchStateServer/init.luau` per §Module Split MSM diagram + §Key Interfaces
2. Implement `ServerStorage/Source/RoundLifecycle/init.luau` per §Module Split RL diagram + §Key Interfaces
3. Wire MSM `_transitionTo` to call `RL.createAll → RL.setWinner → RL.getPlacements → RL.destroyAll` per §Round-End Ordering Invariants
4. Register MSM Phase 6/7 callbacks in `ServerScriptService/start.server.luau` after all module requires per ADR-0002 §Phase registration
5. Register MSM BindToClose handler in `ServerScriptService/start.server.luau` after MSM module require
6. RL `createAll` subscribes to CSM `CrowdEliminated` reliable + `CountChanged` BindableEvent + `Players.PlayerRemoving` via Janitor
7. Code-review template for any MSM/RL PR includes "Verify caller authority + ordering invariants per ADR-0005" checklist
8. Currency System (when authored) cites this ADR for `grantMatchRewards(placements)` signature + grants-before-broadcast invariant

## Validation Criteria

- [ ] `grep -r "RoundLifecycle\." src/ServerStorage/Source --include="*.luau"` — every match originates in `MatchStateServer/` or `RoundLifecycle/` itself; ZERO matches from other directories (caller-restriction audit)
- [ ] `grep -r "MatchStateServer.timerCheck\|MatchStateServer.eliminationConsumer" src/` — every match originates in `start.server.luau` boot wiring (TickOrchestrator-only callers)
- [ ] `grep -r "_transitionTo" src/ServerStorage/Source` — every match is internal to `MatchStateServer/init.luau` (no external callers)
- [ ] Integration test: T6/T7 same-tick simultaneity — fixture where round expires at exact same tick as last-standing elim → confirm winner via F4 tiebreak, not last-standing (Phase 6 wins)
- [ ] Integration test: Double-elim same tick — only one T6 transition fires; `MatchStateChanged("Result")` broadcast exactly once (double-signal guard)
- [ ] Integration test: T9 ordering — `destroyAll` completes (verify via Janitor mock spy `:Destroy()` call) before `clearAll` (verify RelicSystem mock spy) before `MatchStateChanged("Intermission")` broadcast (verify FireAllClients mock spy)
- [ ] Integration test: Result entry ordering — `Currency.grantMatchRewards` mock spy invoked BEFORE `MatchStateChanged("Result")` mock spy
- [ ] Integration test: BindToClose — `MatchStateChanged("ServerClosing")` fires; ProfileStore `OnPlayerRemoving` per player; NO `Currency.grantMatchRewards` invocation (anti-exploit)
- [ ] Integration test: InternalPlacement strip — broadcast adapter mock asserts `peakCount` / `isWinner` / `wasEliminated` ABSENT from FireAllClients payload
- [ ] CountChanged subscriber audit: `grep -r "CrowdStateServer.CountChanged" src/` returns matches only in `RoundLifecycle/` (production) and `Analytics/` (Alpha+ stubs); ZERO matches in cosmetic-system directories (`SkinSystem/`, `AvatarSystem/`, etc.)
- [ ] MSM ↔ CSM read-only audit: `grep -r "CrowdStateServer.updateCount\|recomputeRadius\|setStillOverlapping" src/ServerStorage/Source/MatchStateServer src/ServerStorage/Source/RoundLifecycle` returns zero matches (confirms ADR-0004 read-only consumer rule)
- [ ] `MatchStateServer.get()` returns same value within one tick (no mid-tick transitions; transitions only via Phase 6/7 or PlayerAdded/Removing/AFK handlers)

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — `CrowdEliminated` reliable RemoteEvent + `CountChanged` BindableEvent that MSM/RL consume; record shape locked
- **ADR-0002** TickOrchestrator — Phase 6/7 callback structure this ADR codifies as MSM contract
- **ADR-0003** Performance Budget — Phase 6/7 = 0.05 ms each CPU allocation
- **ADR-0004** CSM Authority — MSM/RL is read-only consumer per Write-Access Matrix; this ADR confirms via §Authority Matrix MSM/RL never call CSM mutators
- **ADR-0006** Module Placement Rules — Source Tree Map locks server-only placement
- **Expected downstream**:
  - ADR-0010 Server-Authoritative Validation Policy — `ChestInteract` / `AFKToggle` / `ChestDraftPick` remote handler validation pattern (MSM consumes some of these)
  - ADR-0011 Persistence Schema + Pillar 3 Exclusions — locks ProfileStore key list (MSM does NOT write any key during round)
  - Future Currency System ADR — `grantMatchRewards(placements: { Placement })` signature + grants-before-broadcast invariant
  - Future Leaderboard System ADR (Alpha+) — consumes `meta.placements[]` from broadcast
  - Future Daily Quest System ADR (Alpha+) — subscribes to MSM `MatchStateChanged` reliable for round-completion signal

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). All APIs used (`BindableEvent`, `RemoteEvent`, `game:BindToClose`, `Players.PlayerRemoving`, `os.clock`, `table.sort`, `Packages.janitor`) are stable Roblox primitives predating LLM cutoff. No post-cutoff API risk.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
