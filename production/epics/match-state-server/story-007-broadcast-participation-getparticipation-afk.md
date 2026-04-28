# Story 007: MatchStateChanged + ParticipationChanged broadcast + GetParticipation RemoteFunction + AFK toggle validation

> **Epic**: match-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/match-state-machine.md` §Server API + §Network event contract
**Requirement**: `TR-msm-009` (MatchStateChanged wire format), `TR-msm-011` (GetParticipation RemoteFunction), `TR-msm-013` (payload schema), `TR-msm-020` (clock consistency invariant)
**ADR**: ADR-0005 §Decision (broadcast payload schema); ADR-0010 §4-check guard (AFK toggle + GetParticipation validation); arch §5.7 (wire contracts).
**ADR Decision Summary**: `MatchStateChanged` reliable RemoteEvent fires on every transition with `{state, serverTimestamp, stateEndsAt, meta}`. `ParticipationChanged` reliable fires per-player on flag change. `GetParticipation` RemoteFunction is stateless reconcile (mid-state-join client). `AFKToggle` reliable RemoteEvent processes client-requested participation flips through ADR-0010 4-check guard (silent rejection on validation failure).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Reliable RemoteEvent / RemoteFunction template-proven (LOW). 4-check guard via Foundation `RemoteValidator` (network-layer-ext story-004 — already shipped).

**Control Manifest Rules (Core layer)**:
- Required: 4-check guard pattern mandatory on every server-side handler consuming client payload (manifest L111); RemoteValidator at `ServerStorage/Source/RemoteValidator/init.luau` (L112); silent rejection on validation failure (L114); Server-side `os.clock`/`tick` is sole timing authority (L117); RemoteFunction only for genuine query-response (L118).
- Forbidden: never accept oversized client payload (L149); never honour client-asserted timestamps (L146).

---

## Acceptance Criteria

- [ ] **AC-17 (Reliable broadcast completeness)** — Client joining mid-state; per-player `MatchStateChanged` fires; client receives `{state, serverTimestamp, stateEndsAt, meta}` all non-nil; `MatchStateClient.reconcile()` sets state + clockOffset without error.
- [ ] `MatchStateChanged` payload schema per arch §5.7:
  - `state: MatchState`
  - `serverTimestamp: number` — `os.clock()` at broadcast time
  - `stateEndsAt: number?` — absolute server epoch (e.g. `_stateStartTime + countdownTotal`); nil when no timer (ServerClosing, Lobby pre-Ready)
  - `meta: {[string]: any}` — state-specific payload (e.g. `{countdownTotal=10}` for Countdown:Ready, `{winnerId, placements, rivalDisconnected?}` for Result)
- [ ] `ParticipationChanged` reliable RemoteEvent fires per-player on flag change with `{participating: boolean}`. Filtered to the OWNING player (`Network.fireClient(player, ...)`).
- [ ] `GetParticipation` RemoteFunction returns `_participation[player.UserId] == true` (default false if absent). Stateless — pure read; no state mutation.
- [ ] `AFKToggle` RemoteEvent handler:
  1. **Identity check**: use engine `player` arg; never read `payload.userId`.
  2. **State check**: server-side check `_state` allows toggle (Snap-freeze rule from story-001 enforced here at the validation layer too).
  3. **Parameters check**: `payload.participating` is boolean; nothing else accepted.
  4. **Rate check**: `RemoteValidator.checkRate(player, "AFKToggle")` — uses Foundation rate config from `network-layer-ext` story-005.
  Failed validation → silent reject (no client-visible error; server logs first-of-kind per `(player, remote)` per round at info level).
- [ ] On successful AFKToggle: invoke `_setParticipation(player, payload.participating)` (story-001 helper); fire `ParticipationChanged` to that player.
- [ ] Add `AFKToggle` and `GetParticipation` to `RateLimitConfig` if not already present. Defaults: 10 toggles/sec/player tokens, 5 GetParticipation/sec/player tokens. Rate config entries managed in Foundation `network-layer-ext` story-005.
- [ ] Broadcast wire connector: `_fireMatchStateChanged(state, meta)` private helper composes `{state, serverTimestamp=os.clock(), stateEndsAt=_stateEndsAt, meta=meta or {}}` and calls `Network.fireAllClients(RemoteEventName.MatchStateChanged, payload)`. ALL `_transitionTo` and `requestServerClosing` paths (story-001..006) call this helper — single broadcast code path.

---

## Implementation Notes

- `_fireMatchStateChanged` is the single chokepoint — story-002..006 collectively call it from inside their state-write paths.
- AC-17 client-side `MatchStateClient.reconcile` is in the Replication Broadcast / Presentation epic (`MatchStateClient` module). This story validates server-side payload completeness; client-side wiring tested in that epic.
- `serverTimestamp` is `os.clock()` at broadcast time — gives client a reference for clock-skew correction (F6 in MSM GDD; lives in MatchStateClient epic).
- `stateEndsAt` is the absolute server epoch when the current timed state will end (e.g. `os.clock() + 10` at Countdown:Ready entry). Nil for un-timed states.
- AFKToggle `RateLimitConfig` extension belongs in `network-layer-ext` story-005's table; if missing, this story coordinates the addition (cross-epic edit) — log via change-impact doc.

---

## Out of Scope

- Replication Broadcast / Presentation epic: `MatchStateClient.reconcile` + F6 client timer interp (AC-18 client-side).
- Foundation `RemoteValidator` + `RateLimitConfig` modules: already shipped (network-layer-ext story-004 + story-005).
- story-001..006: state machine logic; this story wires the broadcast and AFK input edge.

---

## QA Test Cases

- **AC-17**: Multiple state transitions trigger broadcast. Spy on `Network.fireAllClients(RemoteEventName.MatchStateChanged, ...)`; payload assertion: all 4 fields non-nil (`state`, `serverTimestamp`, `stateEndsAt nil for Lobby`, `meta` always table). Edge: ServerClosing → `stateEndsAt = nil`; Result → `meta` includes `winnerId` (or nil) + `placements`.
- **`ParticipationChanged` per-player fanout**: 2 players A+B. `_setParticipation(A, false)` → spy records `ParticipationChanged` to A only with `{participating=false}`; B's spy receives nothing.
- **`GetParticipation`**: client invokes RemoteFunction; server returns boolean. Edge: `_participation[user] == nil` → returns false.
- **AFKToggle 4-check happy path**: client fires `AFKToggle` with `{participating=false}`; server validates; `_setParticipation` invoked; `ParticipationChanged` broadcast.
- **AFKToggle 4-check rejection paths**:
  - Identity: payload tries to spoof `payload.userId` → server uses `player` arg (no path to spoof).
  - State: in Snap, TRUE→FALSE rejected silently (story-001 freeze rule).
  - Parameters: `payload.participating = "yes"` (string) → reject.
  - Rate: 11+ toggles in 1s by same player → reject after 10.
  All rejections silent — no client-side error; server logs first-of-kind per `(player, remote)` per round.
- **Single broadcast path**: grep `Network.fireAllClients.*MatchStateChanged` → exactly one match (inside `_fireMatchStateChanged`).

---

## Test Evidence

`tests/integration/match-state-server/broadcast_completeness_test.luau` + `tests/unit/match-state-server/getparticipation_test.luau` + `tests/unit/match-state-server/afktoggle_validation_test.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..006; Foundation `network-layer-ext` story-001 (Network module), story-002 (RemoteEventName + RemoteFunctionName), story-004 (RemoteValidator), story-005 (RateLimitConfig)
- Unlocks: Replication Broadcast / Presentation epic (MatchStateClient consumes)
