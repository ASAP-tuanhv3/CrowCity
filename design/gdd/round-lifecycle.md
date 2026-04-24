# Round Lifecycle

> **Status**: In Revision (2026-04-22 review — 5 blockers resolved; 2026-04-24 consistency-check sync — 4 stale "CountChanged amendment required" flags cleared; CSM Batch 1 LANDED `CountChanged(crowdId, oldCount, newCount, deltaSource)` as server-side BindableEvent consumed by Round Lifecycle peak tracking. Signal NOT replicated to clients — server-only per Batch 1 contract.)
> **Author**: user + systems-designer + gameplay-programmer + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 3 (5-Minute Clean Rounds) primary; 5 (Comeback Always Possible) via placement tracking

## Overview

The **Round Lifecycle** is the server-authoritative coordinator between the **Match State Machine** (state transitions) and the **Crowd State Manager** (per-player crowd records). It owns exactly three per-round responsibilities: creating Crowd State records for every participating player at round start (`createAll`), destroying all records at round end (`destroyAll`), and tracking round-scoped auxiliary data that the machine's tiebreak + result systems need — elimination order, peak counts per crowd, and the final placement array. It does NOT own the round timer (Match State §F1) or the win conditions (Match State §F2-F4); it is the bridge that keeps per-player data aligned with server-wide state transitions. Every round, its state is wiped — no record survives to the next match (Pillar 3). Downstream systems consume one public hook: `RoundLifecycle.getPlacements()` is the source of truth for end-round ranking (Result screen, Currency grant, Leaderboard all read from here).

## Player Fantasy

Round Lifecycle itself never touches the player — but the moments it bookends are the ones they feel most. It's the breath before the match, when eight characters plus their starting ten followers pop into the arena and the timer ticks from 00:00. It's the result-screen flash at the horn — *"You placed #3 of 8"* — the single number that crowns five minutes of snowballing. And it's the clean wipe a beat later, lobby restored, slate blank, ready to do it again.

## Detailed Design

### Core Rules

**Per-round auxiliary state** (server-side, cleared each round)

| Table | Key | Value | Set by |
|---|---|---|---|
| `_crowds[crowdId]` | crowdId | `{crowdId, userId, peakCount, peakTimestamp, finalCount, eliminationTime?}` | `createAll` (init) + CountChanged + Eliminated handlers |
| `_participants` | snapshot | `{Player}` captured at `createAll` | `createAll` parameter; immutable after capture |
| `_winnerId` | scalar | `crowdId | nil` | `setWinner(crowdId)` called by Match State at Active exit |

**Subscription lifecycle**
- `createAll(participatingPlayers)`: assert no prior Janitor active. Create new `Janitor`. Subscribe `CrowdStateServer.Eliminated` + `CrowdStateServer.CountChanged` + `Players.PlayerRemoving` via janitor. For each player: `pcall(CrowdStateServer.create, crowdId, {count = CROWD_START_COUNT})`. On pcall success: init `_crowds[crowdId]` with `peakCount = CROWD_START_COUNT, peakTimestamp = os.clock()`. On failure: log warning; player is an **excluded participant** — present in `_participants` but NOT in `_crowds`, absent from all placement logic (treated identically to a never-joined spectator for all purposes).
- `destroyAll()`: `janitor:Destroy()` (disconnects all signals). Iterate `_crowds` calling `CrowdStateServer.destroy(crowdId)` each. `table.clear` all tables. Set `_winnerId = nil`.

**Signal handlers**
- `onCountChanged(crowdId, newCount, oldCount)`: if `_crowds[crowdId] == nil` return. If `newCount > record.peakCount` (strict `>`) → update `peakCount` + `peakTimestamp = os.clock()`. Always update `finalCount = newCount`.
- `onEliminated(crowdId)`: if `_crowds[crowdId] == nil` return. **Idempotent**: if `record.eliminationTime ~= nil` return (double-fire safety — prevents a later signal from advancing `eliminationTime` and shifting rank in the peak-dominance sort's quaternary tiebreak). Set `record.eliminationTime = os.clock()`.
- `onPlayerRemoving(player)`: if module is Dormant, return. Derive `crowdId = tostring(player.UserId)`. If `_crowds[crowdId] == nil` return. If `record.eliminationTime == nil` → set `record.eliminationTime = os.clock()`. `_crowds[crowdId]` record is **kept** until `destroyAll()` — DC'd player appears in `getPlacements()` Rank 2..N cohort with `survived = false`, their `finalCount` and `eliminationTime` frozen at disconnect; `peakCount` still drives primary rank position.

Strict `>` on peak update — equal counts do NOT reset `peakCount` or `peakTimestamp`.

**Placement ranking algorithm** (`getPlacements()` — pure, called once by Match State at Result entry). Peak-dominance model (Batch 5 DSN-B-3 resolution 2026-04-24 — replaces prior survivor-always-beats-eliminated model).

1. **Rank 1**: `_winnerId`. If `_participants` is empty (T5 zero-participant path), return `{}` immediately. Otherwise assert `_winnerId ~= nil` — Match State invariant guarantees a non-nil winner whenever participants exist (T6/T7/T8 all resolve a winner).
2. **Rank 2..N — everyone else (single unified sort, no Group 2/3 split)**: composite key descending: (`peakCount`, `survived`, `finalCount`, `eliminationTime`, `UserId` asc).
   - `survived = record.eliminationTime == nil` (Active/GraceWindow at round end)
   - Primary: `peakCount` — biggest snowball outranks smaller, survivor or eliminated
   - Secondary: `survived` — survival breaks ties at equal peak (survival-as-reward)
   - Tertiary: `finalCount` — held-high outranks bled-to-floor at equal peak+survived
   - Quaternary: `eliminationTime` — later-eliminated at equal peak+finalCount
   - Final: `UserId` ascending — deterministic tiebreak (15 Hz `os.clock()` collisions common)
3. **Excluded from array**: players not in `_crowds` (both never-joined spectators AND pcall-failed excluded participants).

Returns array aligned with Match State Machine's broadcast schema:
`{ crowdId, userId, placement, crowdCount, eliminationTime | nil }` (additional internal fields — `peakCount`, `isWinner`, `wasEliminated` — are available via `Placement` type for Currency System + Leaderboard downstream use but not carried in `meta` broadcast).

`getPlacements` is pure after `setWinner` — reads frozen snapshot, returns new array each call, mutates no state.

**Clean-wipe invariant**: after `destroyAll()`, `#_crowds == 0`, `_winnerId == nil`, no live `RBXScriptConnection` owned by this module.

**Error handling**
- `createAll` per-player wrapped in `pcall` — on failure, log `{UserId, Name, err}`, skip, player enters Active as spectator without crowd record.
- Signal handlers guard on `_crowds[crowdId] == nil` — tolerates `pcall`-skipped players.

### States and Transitions

Thin wrapper. 2 internal states.

| State | `_crowds` | Signals | `_participants` |
|---|---|---|---|
| `Dormant` | empty | disconnected | empty |
| `Active` | populated | `Eliminated` + `CountChanged` + `PlayerRemoving` connected via Janitor | frozen snapshot |

| # | From | To | Trigger | Action |
|---|---|---|---|---|
| RL1 | `Dormant` | `Active` | `createAll(participants)` by Match State T4 | Populate `_participants`, connect signals, `pcall` create per player |
| RL2 | `Active` | `Dormant` | `destroyAll()` by Match State T9 | `janitor:Destroy()`, destroy crowds, clear all tables |

No timer. No self-transition. Authority delegated entirely to Match State caller.

### Interactions with Other Systems

| Caller | Direction | Call | When |
|---|---|---|---|
| Match State Machine | → Round Lifecycle | `createAll(participatingPlayers: {Player})` | T4 synchronous |
| Match State Machine | → Round Lifecycle | `setWinner(crowdId: string?)` | Active exit (before Result entry) |
| Match State Machine | → Round Lifecycle | `getPlacements(): {Placement}` | Result entry (used for Currency grant at T6/T7/T8 + broadcast `meta.placements[]`) |
| Match State Machine | → Round Lifecycle | `getPeakTimestamp(crowdId: string): number?` | F4 tiebreak during Active |
| Match State Machine | → Round Lifecycle | `destroyAll()` | T9 first action |
| Round Lifecycle | → Crowd State Manager | `CrowdStateServer.create(crowdId, {count = CROWD_START_COUNT})` per player | Inside `createAll` |
| Round Lifecycle | → Crowd State Manager | `CrowdStateServer.destroy(crowdId)` per crowd | Inside `destroyAll` |
| Round Lifecycle | ← Crowd State Manager | `CrowdStateServer.Eliminated(crowdId: string)` signal | Throughout Active |
| Round Lifecycle | ← Crowd State Manager | `CrowdStateServer.CountChanged(crowdId, oldCount, newCount, deltaSource)` BindableEvent (server-only, NOT replicated; ✓ CSM Batch 1 2026-04-24) | Throughout Active |
| Round Lifecycle | ← `Players` service | `Players.PlayerRemoving(player: Player)` event | Throughout Active — DC freeze |
| HUD | — | (no access) | HUD reads `CrowdStateClient` directly for live counts |
| Round Result Screen | — | (no access) | Reads `meta.placements[]` from `MatchStateChanged` broadcast |
| Leaderboard System | — | (no access) | Reads `meta.placements[]` from broadcast |
| Currency System | — | (no access) | Receives `placements[]` passed into `grantMatchRewards` by Match State at T6/T7/T8 (Result entry, per Match State §C.2 Result entry ordering note) |

**UPDATES Match State Machine §F** — adds `setWinner`, `getPlacements`, `getPeakTimestamp` to Round Lifecycle's provided API (previously listed only `createAll` + `destroyAll`). Cross-reference patch required.

**✓ CONFIRMED 2026-04-24** — Round Lifecycle CONSUMES two CSM signals: `CrowdEliminated` (reliable RemoteEvent) and `CountChanged` (server-side BindableEvent, NOT replicated). Both declared in CSM §Network event contract + §Server-side signals block via CSM Batch 1. Signature: `CountChanged(crowdId, oldCount, newCount, deltaSource)` where `deltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}`.

### Design tensions flagged

1. **`setWinner` coupling** — Match State resolves winner (owns F4 tiebreak), must call `setWinner` before `getPlacements`. Mitigation: `getPlacements` asserts `_winnerId ~= nil` when `_participants` is non-empty, and warns loudly on violation. Match State broadcast ordering enforces correctness; assertion is defense-in-depth.

2. ✓ **RESOLVED 2026-04-24** — CSM Batch 1 declared `CountChanged(crowdId, oldCount, newCount, deltaSource)` as a server-only BindableEvent (NOT replicated) in §Server-side signals block. Round Lifecycle peak tracking consumes directly. Signature slightly differs from original ask (added `deltaSource` enum; arg order `(old, new)` → `(old, new, source)`).

## Formulas

Round Lifecycle is predicate + ordering logic, not balance math.

### F1. peak_count_update

```
if newCount > record.peakCount then
    record.peakCount = newCount
    record.peakTimestamp = os.clock()
end
record.finalCount = newCount  -- always updated
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `newCount` | int | [1, 300] | Current `count` from `CrowdStateServer.CountChanged` |
| `record.peakCount` | int | [`CROWD_START_COUNT`, 300] | Highest count observed this round |
| `record.peakTimestamp` | float | — | `os.clock()` when peak was last updated (used by `getPeakTimestamp` for Match State §F4 tiebreak) |
| `record.finalCount` | int | [1, 300] | Count at most recent `CountChanged` event; initialized to `CROWD_START_COUNT` at `createAll` |

**Strict `>`** — equal counts do NOT reset `peakCount` or `peakTimestamp`.

### F2. elimination_time_record

```
record.eliminationTime = os.clock()  -- on CrowdStateServer.Eliminated
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `record.eliminationTime` | float? | nil or `os.clock()` | Server-clock time of elimination; nil if still active |

**Idempotent**: `onEliminated` and `onPlayerRemoving` both guard `if record.eliminationTime ~= nil then return end` — whichever fires first wins; no overwrite. Guarded by `_crowds[crowdId] == nil` check — tolerates never-joined spectators and excluded participants.

### F3. placement_ranking (Batch 5 DSN-B-3 resolution — 2026-04-24)

Called once by Match State at Result entry after `setWinner`:

**Pre-condition**: if `_participants` is empty (T5 zero-participant path), return `{}` immediately. Otherwise assert `_winnerId ~= nil` — Match State guarantees a non-nil winner whenever participants exist.

1. **Rank 1** = `_winnerId`. Unchanged — winner is last-standing (T6) or F4 tiebreak champion (T7). Winner's `isWinner = true` stored on Placement record.
2. **Rank 2..N — everyone else**: **single unified sort** by composite key (`peakCount` descending, `survived` descending, `finalCount` descending, `eliminationTime` descending, `UserId` ascending).
   - `survived: bool` = `record.eliminationTime == nil` (true = still Active/GraceWindow at round end, false = eliminated or DC'd)
   - `peakCount` is primary: whoever built the biggest snowball outranks whoever didn't, survivor or not
   - `survived` is secondary tiebreak at equal peaks: a survivor at peak=150 outranks an eliminated player at peak=150 (survival as tie-break reward)
   - `finalCount` tertiary: among two eliminated crowds at peak=200, the one who held their count longer (higher `finalCount` near elim) ranks higher — incentivizes not bleeding to floor
   - `eliminationTime` quaternary: last-eliminated outranks earlier-eliminated at equal everything-else
   - `UserId` final tiebreak: `os.clock()` collisions at 15 Hz require deterministic final key
3. **Group E — excluded**: players not in `_crowds` (never-joined spectators AND pcall-failed excluded participants) absent entirely from output.

**Peak-dominance placement (DSN-B-3 resolution, replaces survivor-always-beats-eliminated invariant).** Prior invariant rewarded turtling at count=1 with a higher rank than aggressive-but-eliminated peak=299. That contradicted Pillar 1 (Snowball Dopamine) and Pillar 5 (Comeback Always Possible) — passivity was the dominant strategy for placement. Revised rule: **the biggest snowball places higher**, regardless of whether it survived the final clock or a final ram. Survival remains valued as a tiebreak at equal peak. Winner is still distinct (T6/T7 last-standing / timer-expiry tiebreak). Currency grant continues to weight winner > rank 2 > rank 3 …, so turtling is still monetarily inferior to aggressive play (see Currency System when authored).

**Examples:**
- Survivor A: peak=10, final=10 (turtled from start). Eliminated B: peak=299, eliminated at t=240s. → B ranks higher (299 > 10).
- Survivor A: peak=200, final=150. Eliminated B: peak=200, elim=t=270s. → A ranks higher (equal peak, survived).
- Both eliminated. C: peak=250, elim=280s. D: peak=250, elim=290s. → D ranks higher (equal peak + survived-flag, later elim).

Output shape per Match State Machine broadcast schema:
```
Placement = {
    crowdId: string,
    userId: number,
    placement: number,          -- 1-indexed; starts at 1 when participants exist
    crowdCount: number,         -- = record.finalCount
    eliminationTime: number?,   -- nil if non-eliminated; set for DC'd players
}
```

Array length: bounded at `min(#_crowds_records, 12)`, where `#_crowds_records ≤ #_participants` (pcall-failed excluded participants reduce the count). `assert(#_participants <= 12)` guards `createAll` inputs.

### Internal Placement type (richer than broadcast schema)

Round Lifecycle stores additional per-crowd data for Currency System + Leaderboard consumption:
```
InternalPlacement = Placement & {
    peakCount: number,         -- internal; NOT in broadcast
    isWinner: boolean,         -- internal
    wasEliminated: boolean,    -- internal
}
```

**Serialization boundary**: the broadcast adapter (Match State's `FireAllClients` call site) MUST strip internal fields before dispatch. Do NOT pass the full `InternalPlacement` type to `RemoteEvent:FireAllClients`. Tracked as implementation-side guard flag for Match State team.

### F4. getPeakTimestamp

```
return _crowds[crowdId] and _crowds[crowdId].peakTimestamp or nil
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `crowdId` | string | — | Caller-provided crowdId to look up |
| return | float? | `os.clock()` value or `nil` | `nil` if crowdId not in `_crowds` (excluded participant, spectator, or post-`destroyAll`) |

**Binding caller contract**: Match State §F4 tiebreak comparator MUST treat `nil` return as `math.huge` (worst tiebreak position — player with no peak record sorts to last). This is a formal interface requirement on Match State implementation, not advisory.

Called during Active state — safe because Luau is single-threaded; concurrent `CountChanged` mutations cannot race with this read.

## Edge Cases

### Player lifecycle
- **If player DCs mid-round**: `Players.PlayerRemoving` fires → `onPlayerRemoving` sets `record.eliminationTime = os.clock()` (idempotent — if `Eliminated` already fired, no overwrite). Round Lifecycle's internal `_crowds[crowdId]` record is **kept until `destroyAll()`**. Subsequent `CrowdStateServer.destroy(crowdId)` (Crowd State §E) destroys the Crowd State record; any in-flight signals after this find the idempotent guard or nil guard and return silently. DC'd player appears in `getPlacements()` Rank 2..N cohort with `survived = false`, `finalCount` and `eliminationTime` frozen at disconnect; `peakCount` drives rank position. **Pillar 5 rationale**: involuntary disconnect on Roblox mobile (primary target platform) should not zero out five minutes of gameplay — DC'd player receives placement by their peak-count achievement plus participation currency.
- **If player joins mid-round**: Not in `_participants` (snapshot frozen at Countdown:Snap exit). No crowd record created. Spectator. Excluded from `getPlacements()`. No Round Lifecycle action needed.

### API contract violations
- **If `createAll` called twice without `destroyAll` between**: `assert no prior Janitor active` at `createAll` entry fires. Log offending caller, halt. Silent overwrite would corrupt `_participants` + `_crowds`.
- **If `getPlacements` called before `setWinner` (non-nil-winner path)**: assertion failure, warn loudly. Match State T6/T7 must call `setWinner` before `getPlacements` — broadcast ordering enforces correctness.
- **If `getPlacements` called twice in the same round**: idempotent. Pure after `setWinner` — reads frozen snapshot, returns new array, mutates no state. O(N log N) on ≤12 records; no caching needed.
- **If `setWinner` called with `crowdId` not in `_crowds`**: Match State bug (covers both: crowdId absent from `_participants`, AND crowdId in `_participants` but pcall-failed as excluded participant). Assert + warn loudly. Log `{crowdId, _participants snapshot, _crowds keys}` for diagnostics. Do NOT set `_winnerId`. Guard checks `_crowds` (not `_participants`) — this prevents a nil-index crash in `getPlacements()` when the winner record does not exist.
- **If `getPeakTimestamp` called for non-existent `crowdId`**: return `nil`. Match State §F4 tiebreak comparator MUST treat `nil` as `math.huge` (latest timestamp = worst tiebreak position). Flag as contract requirement for Match State implementation.

### Placement array edges
- **If `_participants` is empty at `getPlacements` call** (T5 only — all players opted out before Countdown:Snap exit): `getPlacements()` returns `{}`. No placements, no currency grants. Match State handles the empty-result case. Note: T7 (timer expiry with multiple survivors) and T8 (sole survivor) always produce a non-nil `_winnerId` — the empty-array path is T5 only. There is no "placement starts at 2" scenario for rounds with active participants.
- **If same-tick elimination in group 3**: `UserId` ascending tiebreak (F3). Luau `table.sort` is not guaranteed stable on equal keys — `UserId` fallback is required for determinism.

### Peak tracking edges
- **If peak hits 300, drops to 250, re-peaks to 300**: strict `>` guard means second arrival at 300 does NOT update `peakCount` (stays 300) or `peakTimestamp`. First arrival stands. `peakCount` is unchanged — Rank 2..N composite sort's primary key unaffected (secondary `peakTimestamp` via `getPeakTimestamp()` also stable for Match State §F4 tiebreak).
- **If `CountChanged` fires for a `crowdId` not in `_crowds`**: `_crowds[crowdId] == nil` guard returns silently. Tolerates spectators / `pcall`-skipped players.
- **If `Eliminated` fires for a `crowdId` not in `_crowds`**: same guard as above, silent return.

### Concurrency / cleanup
- **If Relic `CountChanged` signal fires after `destroyAll`**: `janitor:Destroy()` disconnects all Crowd State signal connections at `destroyAll` entry. Any in-flight signal firing after Janitor destruction finds `_crowds` already `table.clear`'d — `_crowds[crowdId] == nil` guard returns silently. Janitor is primary firewall; nil guard is secondary.

### Broadcast schema
- **If broadcast adapter passes full `InternalPlacement` type to `FireAllClients`**: implementation bug. `peakCount` + `isWinner` + `wasEliminated` leak to clients. Match State must strip internal fields before dispatch. Flag as implementation-side guard for Match State team.

### Configuration extremes
- **If round starts with 1 participant** (`#participating == 1` at T4): Match State `MIN_PLAYERS_TO_START = 2` should prevent reaching T4 with fewer than 2. Round Lifecycle does NOT add its own guard — responsibility stays with Match State. If one-participant start somehow occurs, T6 fires immediately on Active entry (`numActiveNonEliminatedCrowds == 1`), resolves to instant-win Result. Technically correct, confirms Match State threshold holds.
- **If `#_participants > 12`** at `createAll`: `assert(#_participants <= 12)` fires. This is a **design cap**, not a Roblox platform constraint — Roblox's configurable `MaxPlayers` can exceed 12. The 12-player limit is set by `MAX_PARTICIPANTS_PER_ROUND` (design choice aligned with ADR-0001 bandwidth budget). Exceeding it indicates matchmaker misconfiguration. To raise the cap, amend both this GDD and ADR-0001.

### createAll / destroyAll idempotence
- **If `createAll` pcall fails for a player**: log `{UserId, Name, err}`, skip, player enters Active as spectator without crowd record.
- **If `destroyAll` called without prior `createAll`** (defensive): no-op. `janitor` is already `nil`, `table.clear` operates on empty tables. No error.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| Match State Machine | In Review | Calls `createAll`, `setWinner`, `getPlacements`, `getPeakTimestamp`, `destroyAll` | Orchestrator |
| Crowd State Manager | Batch 1 Applied 2026-04-24 | `CrowdStateServer.create(crowdId, initialState)`, `.destroy(crowdId)`, `CrowdEliminated` reliable RemoteEvent, `CountChanged(crowdId, oldCount, newCount, deltaSource)` server-only BindableEvent | Write + signal subscribe |
| ADR-0001 Crowd Replication | Proposed | `SERVER_TICK_HZ = 15` (inherited via Crowd State); `CROWD_START_COUNT = 10` | Reused constants |
| `Packages.janitor` (Wally) | Listed in `wally.toml`, not yet installed | `Janitor.new()`, `:Add(conn, "Disconnect")`, `:Destroy()` | Lifecycle cleanup |
| `Players` service (Roblox) | Always available | `Players.PlayerRemoving` event | DC freeze-at-disconnect |
| `ReplicatedStorage/Source/Signal.luau` or equivalent | Available (template) | `Signal.SignalConnection` type for Crowd State signals | Type reference |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Match State Machine | In Review | `createAll(participants)`, `setWinner(crowdId?)`, `getPlacements()`, `getPeakTimestamp(crowdId)`, `destroyAll()` | Function-call API |
| Currency System | Partial (template Coins + undesigned grants) | Receives `placements: {Placement}` via `grantMatchRewards(placements)` at Match State T6/T7/T8 | Indirect (via Match State) |
| Round Result Screen | Not Started (VS) | Reads `meta.placements[]` (5-field broadcast schema) from `MatchStateChanged` | Indirect (via broadcast) |
| Leaderboard System | Not Started (Alpha) | Reads `meta.placements[]` from broadcast | Indirect (via broadcast) |
| HUD | Not Started | **No direct access.** HUD reads live counts from `CrowdStateClient`, not Round Lifecycle. | No interaction |

### Provisional assumptions (flagged for cross-check)
- ✓ `CrowdStateServer.CountChanged(crowdId, oldCount, newCount, deltaSource)` — **LANDED 2026-04-24 via CSM Batch 1** as server-only BindableEvent (NOT replicated). Round Lifecycle peak tracking subscribes in `createAll()` via Janitor. `deltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}` enables source-aware analytics.
- `Placement` type + `InternalPlacement` split — Round Lifecycle defines the serialization boundary; Match State's broadcast adapter must strip internal fields.

### Bidirectional consistency notes
- **RESOLVES** Match State Machine §F provisional entries for `createAll`/`destroyAll`. Explicit contracts now match both sides.
- **EXTENDS** Match State Machine §F provided-by-Round-Lifecycle API with `setWinner`, `getPlacements`, `getPeakTimestamp`. Match State §F row must be patched to list all 5 Round Lifecycle methods it calls.
- ✓ **CSM Batch 1 2026-04-24 landed** `CountChanged(crowdId, oldCount, newCount, deltaSource)` server-only BindableEvent (Round Lifecycle + analytics consumers; not replicated to clients).
- **CREATES** cross-reference: Currency System grant timing (Match State T6/T7/T8, not T9 per latest Match State revision).
- **REQUIRES** Match State Machine confirmation: T7 (timer expiry) and T8 (sole survivor) ALWAYS produce a non-nil `_winnerId`. The T5 (zero participants) path is the only legal path where `getPlacements()` returns `{}`. Match State §F must be patched to document this invariant explicitly.
- **ADDS** `Players.PlayerRemoving` subscription during Active state — DC'd players now appear in Rank 2..N of `getPlacements()` with frozen `finalCount` and `peakCount` driving placement. Currency System and Leaderboard will receive DC'd player entries; neither system should filter them out.

### No cross-server dependency
Round Lifecycle is entirely server-local. No `MessagingService`, no DataStore access (state is ephemeral per Pillar 3). One `RoundLifecycle` instance per Roblox server.

## Tuning Knobs

Minimal surface — Round Lifecycle is a coordinator; most constants owned upstream.

### Round Lifecycle-owned knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `MAX_PARTICIPANTS_PER_ROUND` | 12 | [2, 12] | `createAll` assertion upper bound | >12 breaks `CrowdStateBroadcast` ~900-byte `UnreliableRemoteEvent` payload ceiling (ADR-0001) — NOT a Roblox platform hard cap (configurable to 700+); this is a design choice | <2 conflicts with Match State `MIN_PLAYERS_TO_START = 2` | Roblox Place settings `MaxPlayers` + ADR-0001 |

### Upstream-owned constants referenced (NOT owned here)
- `CROWD_START_COUNT = 10` — owned by Crowd State Manager (`createAll` passes it to `CrowdStateServer.create`)
- `MAX_CROWD_COUNT = 300` — owned by Crowd State Manager (`peakCount` upper bound implicit)
- `SERVER_TICK_HZ = 15` — owned by ADR-0001 (Round Lifecycle consumes signals, no polling; cadence irrelevant but referenced in docs)

### Implementation-side flags (NOT design knobs)
- `LOG_LEVEL_ON_CREATE_FAILURE` — `warn` / `error` / `silent`. Default: `warn`. Ops debug only, not gameplay feel.
- `ASSERT_SETWINNER_IN_PARTICIPANTS` — bool. Default: `true`. Dev-only safety; disable for stress tests if false-positives surface.

### Where knobs live (implementation guidance)
- `MAX_PARTICIPANTS_PER_ROUND` → `SharedConstants/MatchConfig.luau` (co-located with Match State's `TARGET_PLAYERS_PER_SERVER`)
- Log / assert flags → `SharedConstants/RoundLifecycleConfig.luau` (new, debug-only)

**Design note**: Round Lifecycle's thin scope means few knobs. The real tuning surface for round feel lives in Match State Machine (`ROUND_DURATION_SEC`, `RESULT_DURATION_SEC`, etc.) and Crowd State Manager (`GRACE_WINDOW_SEC`, `TRANSFER_RATE_BASE/SCALE/MAX`). Round Lifecycle adjusts nothing player-feel-facing.

## Acceptance Criteria

**AC-1 (createAll success)** — GIVEN `createAll([A, B])` on a Dormant instance, WHEN `CrowdStateServer.create` succeeds for both, THEN `_crowds` contains 2 records: `peakCount = 10`, `peakTimestamp != 0`, `finalCount = 10`, `eliminationTime = nil`.

**AC-2 (createAll pcall failure)** — GIVEN `create` throws for A and succeeds for B, WHEN the call completes, THEN `_crowds` has 1 record (B); a `warn` log cites A's `UserId` + error; A is absent from any subsequent `getPlacements()` output.

**AC-3 (Double createAll assert)** — GIVEN the module is Active, WHEN `createAll` is called again without `destroyAll`, THEN an assertion fires BEFORE any mutation; `_crowds` + `_participants` remain unchanged.

**AC-4 (destroyAll clean-wipe)** — GIVEN Active state with 2 crowds, WHEN `destroyAll()`, THEN `janitor:Destroy()` runs first, `CrowdStateServer.destroy` is called per crowd, `#_crowds == 0`, `#_participants == 0`, `_winnerId == nil`; a subsequent mocked `CountChanged` / `Eliminated` signal fires without error and mutates no state.

**AC-5 (Peak update on strict `>`)** — GIVEN a record with `peakCount = 10`, WHEN `onCountChanged(id, 15, 10)` fires, THEN `peakCount = 15`, `peakTimestamp` updated, `finalCount = 15`.

**AC-6 (Peak NOT updated on equal)** — GIVEN `peakCount = 300`, WHEN `onCountChanged(id, 300, 250)` (equal, not strictly greater), THEN `peakTimestamp` UNCHANGED; `finalCount = 300`. F1 strict `>` invariant.

**AC-7 (Peak NOT updated on below)** — GIVEN `peakCount = 300`, WHEN `onCountChanged(id, 250, 300)`, THEN `peakCount` remains `300`, `peakTimestamp` unchanged, `finalCount = 250`.

**AC-8 (Signal guard for non-record)** — GIVEN `CountChanged` or `Eliminated` fires for a `crowdId` not in `_crowds` (spectator, pcall-skipped, post-`destroyAll` relic event), WHEN the handler runs, THEN silent return, no mutation, no log output.

**AC-9 (Elimination time record — idempotent)** — GIVEN a record with `eliminationTime = nil`, WHEN `onEliminated(id)` fires, THEN `record.eliminationTime` is a number (verified by capturing `tBefore = os.clock()` before firing and asserting `record.eliminationTime >= tBefore`). WHEN `onEliminated(id)` fires a second time, THEN `record.eliminationTime` is UNCHANGED from the first firing (idempotent guard prevents overwrite — verify by asserting `record.eliminationTime == firstValue` after second call).

**AC-10 (setWinner invalid guard)** — GIVEN `setWinner(id)` with `id` not in `_crowds` (covers both: id absent from `_participants`, AND id in `_participants` but pcall-failed), WHEN the call runs (wrapped in `pcall`), THEN `_winnerId` stays `nil`, a `warn`-level log fires citing `{id, _crowds keys snapshot}` (verified via injected `warn` spy), no state mutation.

**AC-11 (Placement 3-group sort)** — GIVEN records injected directly into `_crowds` (bypassing signal fires) with: A = winner (via `setWinner("A")`), `finalCount=10`, `eliminationTime=nil`; B = `finalCount=50`, `peakCount=60`, `eliminationTime=nil`; C = `finalCount=50`, `peakCount=100` (higher peak than B), `eliminationTime=nil`; D = `finalCount=30`, `eliminationTime=200.0`; E = `finalCount=20`, `eliminationTime=100.0`; WHEN `getPlacements()` is called after `setWinner("A")`, THEN the returned array is `[A(p=1), C(p=2), B(p=3), D(p=4), E(p=5)]` — C wins the tiebreak on higher `peakCount` (100 > 60); D outranks E on later `eliminationTime` (200 > 100). All timestamps injected directly — no `os.clock()` dependency in test setup.

**AC-12 (T5 empty participants path)** — GIVEN `createAll([])` called with an empty participants list (T5 path), WHEN `getPlacements()` is called, THEN the returned array is `{}` — length 0, no placement entries emitted. (Match State invariant: when `_participants` is non-empty, `_winnerId` is always non-nil before `getPlacements()` is called.)

**AC-13 (Same-tick elimination UserId tiebreak)** — GIVEN two records with `eliminationTime` injected to the same value (e.g., both set to `1234.567` by direct table write), one with lower `UserId = 100`, one with higher `UserId = 200`, WHEN `getPlacements()` runs, THEN the crowd with `UserId = 100` receives the better (lower) placement number — deterministic, independent of Luau `table.sort` stability. (Direct injection avoids `os.clock()` non-determinism in test setup.)

**AC-14 (getPeakTimestamp)** — WHEN `getPeakTimestamp(id)` called for `id` present in `_crowds`: returns `record.peakTimestamp` number. WHEN called for `id` not in `_crowds`: returns `nil`.

**AC-15 (Broadcast schema split)** — GIVEN `getPlacements()` output, WHEN inspected, THEN each entry has `{crowdId, userId, placement, crowdCount, eliminationTime}`; internal `InternalPlacement` type extends with `peakCount` / `isWinner` / `wasEliminated`; internal fields confirmed ABSENT from any value passed to `RemoteEvent:FireAllClients` by the Match State broadcast adapter (verify via mocked adapter).

**AC-16 (Idempotence + performance)** — GIVEN 12 participant records with `setWinner` called, WHEN `getPlacements()` is called twice with no state mutation between calls, THEN both returned arrays are deep-equal by value (same crowdIds in same order, same placements — verified by iterating both arrays field-by-field). GIVEN `getPlacements()` called 100 times in a tight loop over 12 records, THEN the loop completes in < 10ms total (measured via `os.clock()` delta across the full loop, amortizing clock precision noise).

**AC-17 (DC freeze-at-disconnect)** — GIVEN an Active module with player A having `_crowds[A.crowdId]` record with `finalCount = 150` and `eliminationTime = nil`, WHEN `onPlayerRemoving(A)` fires (simulated by calling the handler directly with player A), THEN `_crowds[A.crowdId]` still exists (record not removed), `record.eliminationTime` is set to a number (verified via `tBefore = os.clock()` captured before call, asserting `record.eliminationTime >= tBefore`), and a subsequent call to `getPlacements()` (after `setWinner`) includes A in the output array as a Rank 2..N entry with `crowdCount = 150`, `survived = false`, and `eliminationTime` matching the frozen value.
