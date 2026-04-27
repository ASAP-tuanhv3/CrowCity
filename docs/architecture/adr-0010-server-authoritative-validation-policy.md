# ADR-0010: Server-Authoritative Validation Policy

## Status

**Accepted 2026-04-26** (closes ~10 gap TRs from `/architecture-review` 2026-04-26; no remaining amendment dependencies; all GDDs already aligned with 4-check structure).

Status history:
- 2026-04-26 — Proposed (initial)
- **2026-04-26 — ACCEPTED** (stories may now reference this ADR per `/story-readiness`)

## Date

2026-04-26 (initial Proposed + Accepted, same day)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Networking + Security (input validation + anti-cheat posture) |
| **Knowledge Risk** | LOW — `RemoteEvent`, `RemoteFunction`, `UnreliableRemoteEvent`, `typeof`, `os.clock`, `tick`, table-bounds checks all stable; `replication-best-practices.md` §Security pattern is the canonical 4-check guard |
| **References Consulted** | `docs/engine-reference/roblox/replication-best-practices.md` §Security — Server Is Authoritative + §Crowdsmith-Relevant Patterns + §Data Size Limits, ADR-0001 §Key Interfaces, ADR-0004 §Write-Access Matrix, ADR-0005 §Round-End Ordering Invariants, ADR-0006 §Forbidden Patterns Matrix, ADR-0008 §Replication Contract, `design/gdd/chest-system.md` §C 6-guard pipeline, `design/gdd/absorb-system.md` §C, `design/gdd/crowd-collision-resolution.md` §C PairEntered + peel, `design/gdd/relic-system.md` §C draft-pick validation, `design/gdd/match-state-machine.md` AFKToggle, `docs/architecture/architecture.md` §5.7 wire contracts |
| **Post-Cutoff APIs Used** | `UnreliableRemoteEvent` + `buffer.*` (via ADR-0001 chain) |
| **Verification Required** | (A) Static grep audit on first MVP integration — every `Network.connectEvent` handler that takes client-sent payload contains all 4 guard checks (identity / state / parameters / rate); (B) Selene custom rule (planned, Production phase) flags missing guards; (C) PenTest pass at MVP-Integration-3 — synthetic malicious client sends out-of-spec payloads; server rejects all without crash + without state mutation |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (RemoteEvent / UnreliableRemoteEvent infrastructure + Network wrapper), ADR-0004 (CSM authority — server-only mutation per Pillar 4), ADR-0005 (MSM authority — read-only consumer rule), ADR-0006 (Forbidden Patterns Matrix — magic-strings + direct-RemoteEvent-access already forbidden), ADR-0008 (NpcPoolBootstrap reliable contract — example consumer of this policy) |
| **Enables** | Every client→server remote handler implementation (Absorb / Collision / Chest / Relic / MSM AFK / NpcPool / Currency); future Daily Quest System (Alpha+) handlers; future Shop System (Alpha+) handlers; PenTest validation playbook |
| **Blocks** | Any story implementing a client→server `connectEvent` handler — must cite this ADR for guard pattern; Currency System grant-flow story when authored |
| **Ordering Note** | Should be Accepted before `/create-control-manifest` (manifest extracts 4-check pattern verbatim). Should be Accepted before any Phase 1-9 implementation story that consumes a client-sent payload. No GDD amendment dependencies. |

## Context

### Problem Statement

Crowdsmith has 5+ client→server reliable remotes (`ChestInteract`, `ChestDraftPick`, `AFKToggle`, future `ShopPurchase` Alpha+, future `DailyQuestClaim` Alpha+) plus several server→client reliables that consume context derived from client-side state (peel target, draft modal, chest-billboard tooltip). Without an architectural policy on validation:

1. **Inconsistent guard depth** — every story author implements their own validation logic; some skip rate-limiting; some accept untrusted state from payload; some forget typeof checks. Drift compounds across systems.
2. **Anti-cheat posture undefined** — `replication-best-practices.md` §Security names a 4-check pattern (identity / state / parameters / rate) but no ADR locks it as mandatory. Code review has no checklist.
3. **Reliable-vs-unreliable selection ad-hoc** — story authors may pick `RemoteFunction` for fire-and-forget actions (introducing yields), pick `UnreliableRemoteEvent` for must-arrive events (data loss), or use raw `RemoteEvent` for high-frequency state (bandwidth blowup). ADR-0001 establishes the pattern for crowd state but does not generalise.
4. **Payload size unspecified** — `replication-best-practices.md` §Data Size Limits says target <4 KB per gameplay remote; no ADR locks it. Roblox 1 MB platform cap leaves room for accidental megabyte-scale payloads.
5. **Per-remote rate limit policy undefined** — no story-readiness check; no control-manifest entry. ChestInteract spammed at full client frame rate (60 Hz) would breach `/architecture-review` bandwidth budget.
6. **Identity-trust model implicit** — Roblox sets the `player` argument trustworthily; any `userId` field inside a payload is forgeable. Without ADR lock, a story might accidentally trust `payload.userId` for permission decisions.
7. **Server-side time authority** — clients can lie about timestamps. `os.clock` / `tick` are server-authoritative; story authors must not honour client-asserted timing for gameplay decisions (e.g. "I held the prompt for 0.8 s" must be measured server-side).
8. **PenTest playbook missing** — when MVP-Integration-3 runs, no validation reference exists for "what should a malicious client be unable to do?".
9. **Stories blocked** — `/create-stories` for Chest open (`ChestInteract` handler), Chest draft pick (`ChestDraftPick` handler), AFK toggle (`AFKToggle` handler), Currency grant (server-driven, but RemoteFunction case TBD) cannot embed a validation-policy ADR ref; `/story-readiness` rejects.

### Constraints

- **Roblox engine semantics** — `player: Player` argument is set by the engine on `RemoteEvent.OnServerEvent` connection callbacks. The engine guarantees identity. Client-sent `userId` fields are untrusted.
- **Single-threaded Luau** — handlers are sequential; rate-limit state is per-player table without locks.
- **Network wrapper required** — every remote goes through `ReplicatedStorage/Source/Network/init.luau` per ADR-0006 §Forbidden Patterns Matrix (direct `RemoteEvent` path access is banned).
- **No magic strings** — every `RemoteEventName` is enum-keyed via `SharedConstants/Network/RemoteName/RemoteEventName.luau` per ADR-0006.
- **ADR-0001 cadence + budget** — UnreliableRemoteEvent reserved for high-frequency continuous state (CrowdStateBroadcast 15 Hz, NpcStateBroadcast 15 Hz). ADR-0010 codifies the selection rule for the rest.
- **ADR-0003 §Burst allowance** — 20 KB/s for ≤500 ms windows absorbs round-start fan-out + chest-open stack + NpcPoolBootstrap; no tightening needed.
- **Pillar 3** — no per-round persistence; rate-limit state is round-scoped, not ProfileStore-backed.
- **Pillar 4** — anti-pay-to-win invariant; client cannot influence currency grant timing or amount; server is sole authority.
- **`game:BindToClose` 30 s grace** — handlers must be lock-free + idempotent; in-flight remotes during shutdown drop silently (acceptable per Pillar 3).

### Requirements

- Lock **mandatory 4-check guard pattern** on every server-side `connectEvent` handler that consumes client-sent payload (identity / state / parameters / rate)
- Lock **reliable-vs-unreliable selection rule** with explicit decision table per remote pattern
- Lock **payload size budgets** — target <4 KB per gameplay remote; hard cap 16 KB; chunked via `buffer` for larger
- Lock **identity-trust model** — `player` argument is trustworthy (engine-set); any payload `userId` field is untrusted
- Lock **server-time-authority rule** — `os.clock` / `tick` server-side authoritative; client-asserted timestamps advisory only (used for client-side prediction, never gameplay decisions)
- Lock **per-player rate limit policy** — discrete client→server remotes throttled per `SharedConstants/RateLimitConfig.luau`
- Lock **silent-rejection rule** — invalid client payload returns silently (no error message, no exception leak); server logs at `info` / `warn` level for telemetry
- Lock **shared validator module** — `ServerStorage/Source/RemoteValidator/init.luau` provides reusable 4-check helper used by every handler
- Define **PenTest playbook** — list of malicious-client behaviours every server handler must reject
- Surface **forbidden patterns** — trusting payload-userId; skipping any of 4 checks; using RemoteFunction for fire-and-forget; bouncing client state back without re-validation; honouring client-asserted time for gameplay
- Do NOT require runtime cryptographic signing of payloads (out of scope for Roblox; engine handles wire-level integrity)

## Decision

**Every server-side handler that consumes a client-sent payload MUST execute the 4-check guard pattern (identity / state / parameters / rate) before any state mutation. The Network wrapper hosts a shared `RemoteValidator` module providing reusable helpers. Reliable-vs-unreliable channel selection follows a fixed decision table. Per-remote rate limits live in `SharedConstants/RateLimitConfig.luau`. Invalid payloads are silently rejected (no client-visible error). Server-side `os.clock` / `tick` is the sole authority on timing for gameplay decisions; client-asserted timestamps are advisory only. Identity is trusted only from the engine-set `player` argument, never from payload-embedded `userId`.**

### 4-Check Guard Pattern (LOCKED — mandatory on every client-sent handler)

Every `Network.connectEvent` handler that takes a client-sent payload MUST execute these checks in order, short-circuiting on the first failure (silent return):

```lua
-- Path: ServerStorage/Source/[System]/init.luau (e.g. ChestSystem, AbsorbSystem)
--!strict

local RemoteValidator = require(ServerStorage.Source.RemoteValidator)
local RateLimitConfig = require(ReplicatedStorage.Source.SharedConstants.RateLimitConfig)

Network.connectEvent(RemoteEventName.ChestInteract, function(player: Player, chestId: string)
    -- (1) IDENTITY — trust only the engine-set player argument; never payload userId
    --     (no explicit check needed — Roblox sets player; we never read payload.userId)

    -- (2) STATE — server reads authoritative state, never trusts client-asserted state
    if MatchStateServer.get() ~= "Active" then return end           -- match must be Active
    if not MatchStateServer.getParticipation(player) then return end  -- player must be participating
    local crowd = CrowdStateServer.get(tostring(player.UserId))
    if crowd == nil or crowd.state ~= "Active" then return end       -- crowd must exist + be Active

    -- (3) PARAMETERS — typeof + range checks on every payload field
    if typeof(chestId) ~= "string" then return end
    if #chestId == 0 or #chestId > 32 then return end                -- arbitrary string-length cap
    local chest = ChestSystem._getChest(chestId)
    if chest == nil then return end                                  -- chestId must resolve

    -- (4) RATE — throttle per-player, per-remote
    if not RemoteValidator.checkRate(player, RemoteEventName.ChestInteract) then return end

    -- All 4 checks passed — proceed to handler logic
    ChestSystem._handleInteract(player, chest)
end)
```

**Order matters**: identity (free, engine-set) → state (server-authoritative read) → parameters (cheap typeof checks) → rate (table lookup + tick-counter compare). Cheapest check first; rate-limit last so attackers cannot exhaust state-read budget by flooding handler entry.

### Reliable-vs-Unreliable Selection Rule (LOCKED)

| Remote pattern | Selected channel | Rationale |
|---|---|---|
| High-frequency continuous state, must-arrive | **UnreliableRemoteEvent** | Per ADR-0001 §Decision: cosmetic desync acceptable; bandwidth is the binding constraint |
| Discrete event, must arrive, no return value | **RemoteEvent (reliable)** | Standard pattern; ordered + delivered |
| Discrete event, gameplay-affecting, must arrive | **RemoteEvent (reliable)** | ChestInteract / ChestDraftPick / AFKToggle |
| Mid-round-join initial state burst | **RemoteEvent (reliable)** | NpcPoolBootstrap; absorb burst once-per-join |
| Query-response (caller blocks for result) | **RemoteFunction** (sparingly) | GetParticipation — client needs synchronous answer |
| Fire-and-forget action with implicit ack | **RemoteEvent (reliable)** — never RemoteFunction | RemoteFunction yields; client UI shouldn't block on server |
| Server→client replicated visual / audio state | **RemoteEvent (reliable)** | VFX events (Absorbed, ChestPeelOff, etc.); ordered + delivered |
| Server→client crowd-relative bulk state | **UnreliableRemoteEvent** with buffer encoding | CrowdStateBroadcast / NpcStateBroadcast |

**Forbidden**: using RemoteFunction for fire-and-forget actions (introduces unnecessary client-side yield); using UnreliableRemoteEvent for must-arrive discrete events (data loss); using raw RemoteEvent path access bypassing Network wrapper (per ADR-0006).

### Payload Size Budgets (LOCKED)

| Tier | Target | Hard cap | Action on breach |
|---|---|---|---|
| Per gameplay remote (steady-state) | <4 KB | 16 KB | Server validator rejects; logs warning |
| Mid-round-join bootstrap (one-shot) | <8 KB | 32 KB | Chunked via buffer if approaching cap |
| Round-start fan-out (burst window) | <16 KB combined | 64 KB combined | ADR-0003 §Burst allowance absorbs |

**Implementation**: `RemoteValidator.checkPayloadSize(payload, maxBytes)` helper exposes a buffer-size check; called at start of any handler accepting variable-length client data. Roblox's platform 1 MB cap is the absolute hard limit but never approached in design.

### Identity Trust Model (LOCKED)

| Source | Trust level | Use for |
|---|---|---|
| `player: Player` argument from `OnServerEvent` callback | **Trusted** (engine-set) | All identity decisions: ownership checks, rate-limit keying, ProfileStore lookup |
| `payload.userId` field | **NEVER trusted** | Forbidden — must not be read for any decision |
| `tostring(player.UserId)` derived server-side | Trusted (engine-derived) | crowdId composition per ADR-0001 + ADR-0004 |
| Client-asserted state ("I'm at position X", "I held for 0.8 s") | **NEVER trusted** | Re-derive from server state (Character.HumanoidRootPart, server-side tick counter) |

### Server-Time Authority (LOCKED)

| Time source | Authority | Use case |
|---|---|---|
| Server-side `os.clock()` / `tick()` | **Authoritative** | All gameplay timing decisions: ProximityPrompt hold-duration, GraceWindow timer, MSM ROUND_DURATION, chest cooldown, relic duration |
| Client-side `os.clock()` | Advisory only | Client-side prediction; client-side animation timing |
| Client-asserted timestamp in payload | **NEVER trusted** | Forbidden — server measures client→server latency itself; client cannot prove it held a prompt for N seconds |

**Note**: ProximityPrompt has a `HoldDuration` server-side property; the engine's hold-completion event fires server-authoritatively. Client cannot fake hold-completion — engine semantics enforce. ADR-0010 reinforces but does not duplicate.

### Per-Player Rate Limit Policy (LOCKED)

`SharedConstants/RateLimitConfig.luau` (new) defines per-remote rate caps:

```lua
-- ReplicatedStorage/Source/SharedConstants/RateLimitConfig.luau
--!strict

local RateLimitConfig = {
    -- max calls per window per player; window in seconds
    [RemoteEventName.ChestInteract]  = { max = 4,  windowSec = 1.0 },  -- ProximityPrompt holds — 4/s ceiling
    [RemoteEventName.ChestDraftPick] = { max = 1,  windowSec = 1.0 },  -- one pick per draft modal
    [RemoteEventName.AFKToggle]      = { max = 2,  windowSec = 5.0 },  -- toggle is rare
    -- VS+/Alpha+ remotes added when authored
}

return RateLimitConfig
```

`RemoteValidator.checkRate(player, remoteName)` implements a token-bucket per (player, remote) keyed table:
- On call: drop expired tokens, increment count if room, reject if at cap
- Per-player table cleared on `Players.PlayerRemoving` (memory bounded)
- Round-scoped reset: cleared at MSM T9 to prevent cross-round leak (Pillar 3)

**Forbidden patterns**:
- Setting `max` higher than the underlying gameplay constraint allows (e.g. ChestInteract `max = 60` would defeat the point — must reflect realistic ProximityPrompt-hold rate)
- Skipping rate check on any client→server discrete remote
- Per-server rate limit instead of per-player (a malicious client can scale unbounded if rate is global)

### Shared Validator Module (RemoteValidator)

```lua
-- ServerStorage/Source/RemoteValidator/init.luau
--!strict

export type ValidationResult = boolean  -- silent-rejection model — no error string

-- (1) IDENTITY — convenience for "is this player still in-server?"
function RemoteValidator.checkPlayerActive(player: Player): ValidationResult
    return player.Parent ~= nil
end

-- (2) STATE — generic helpers; system-specific state checks live in handlers
function RemoteValidator.checkMatchActive(): ValidationResult
    return MatchStateServer.get() == "Active"
end

function RemoteValidator.checkParticipating(player: Player): ValidationResult
    return MatchStateServer.getParticipation(player)
end

-- (3) PARAMETERS — generic typeof + size helpers
function RemoteValidator.checkType(value: any, expected: string): ValidationResult
    return typeof(value) == expected
end

function RemoteValidator.checkStringLength(s: string, maxLen: number): ValidationResult
    return typeof(s) == "string" and #s > 0 and #s <= maxLen
end

function RemoteValidator.checkPayloadSize(payload: any, maxBytes: number): ValidationResult
    -- size estimation per type — buffer.len() for buffers, table-walk for tables
    -- implementation detail; reject if exceeds maxBytes
end

-- (4) RATE — per (player, remoteName) token bucket
function RemoteValidator.checkRate(player: Player, remoteName: string): ValidationResult
    -- looks up RateLimitConfig[remoteName]; returns false if cap exceeded
end

function RemoteValidator.resetForRound(): ()
    -- called by RoundLifecycle.destroyAll at T9; clears all per-player rate state
end

return RemoteValidator
```

**Caller restrictions**: `RemoteValidator` is `ServerStorage`-placed; clients cannot require it. Every server-side handler that consumes a client payload MUST call all 4 categories of checks (identity, state, parameters, rate); the validator does not enforce the call (Luau has no "all checks called" runtime guard) — code review enforces.

### Silent-Rejection Model (LOCKED)

Invalid payloads return silently. Server does NOT:
- Throw an error visible to client
- Send a "rejected" RemoteEvent back to client
- Log at `error` level (would spam logs under floods)

Server DOES:
- Return early from handler (no state mutation)
- Log at `info` level for first-of-kind rejection per (player, remote) per round (telemetry signal)
- Increment per-player rejection counter for analytics (Alpha+)

**Rationale**: a malicious client gains no information from a "rejected" response — they cannot distinguish "wrong payload" from "rate limited" from "wrong state" by observing server behaviour. This is anti-cheat by ambiguity.

### PenTest Playbook (Validation Targets)

Every server handler must reject these synthetic-malicious-client behaviours:

| Attack | Handler must | Verifies |
|---|---|---|
| Send payload with `userId = victimUserId` | Reject (or ignore field — never read it) | Identity rule |
| Send payload during MSM `Lobby` / `Countdown:Snap` / `Result` / `Intermission` | Reject (state check) | State rule (match phase) |
| Send payload while not participating (mid-round join, AFK) | Reject (state check) | State rule (participation) |
| Send payload while crowd is `GraceWindow` or `Eliminated` | Reject (state check, where applicable) | State rule (crowd state) |
| Send `chestId = nil` / `chestId = 12345` (number) / `chestId = ""` / `chestId = string of 1MB` | Reject (parameter check) | Parameter rule (typeof + length) |
| Send `chestId = "valid-chest-id-but-not-near-player"` | Reject (server-side proximity re-check) | Parameter rule (range / proximity) |
| Send 60 ChestInteract calls per second | First 4 succeed (per RateLimitConfig); rest rejected | Rate rule |
| Send valid payload twice in same tick (replay) | Server's own state-machine prevents (chest goes to DraftOpen → can't re-trigger) | State rule (state-machine consistency) |
| Send asynchronously-arrived old payload (high latency) | Server's authoritative `tick()` rejects via state-machine check | Server-time authority |
| Connect to RemoteFunction directly with malformed payload | RemoteFunction yields client; server still validates; rejects safely | Network wrapper + validator |

### Defense-in-Depth Enforcement Layers

| Layer | Mechanism | What it catches |
|---|---|---|
| **L1** Roblox engine semantics | `player` argument is engine-set; clients cannot forge identity at the wire level | Identity attack at the engine layer |
| **L2** Code review | PR reviewer checks every `Network.connectEvent` handler for all 4 guard categories | Missing guards, wrong order, payload-userId reads |
| **L3** Selene custom rules (PLANNED — Production phase) | Lint rule flags `connectEvent` handlers missing `RemoteValidator.check*` calls | Pre-commit detection of missing guards |
| **L4** `/create-control-manifest` | Extracts §4-Check Guard Pattern + §Reliable-vs-Unreliable Selection Rule into flat sheet | Daily implementation reference |
| **L5** `/architecture-review` | Cross-checks new ADR/GDD remote contracts against this ADR's selection rule + payload budgets | New systems silently picking wrong channel |
| **L6** `/story-readiness` | Validates story embeds 4-check pattern + correct channel + rate limit entry in RateLimitConfig | Story-level violations before code |
| **L7** PenTest at MVP-Integration-3 | Synthetic malicious-client run against deployed server | Gaps that escaped L2-L6 |

## Alternatives Considered

### Alternative 1: Per-handler ad-hoc validation (status quo, no policy)

- **Description**: Each story author writes their own validation logic; no shared module, no fixed pattern, no rate-limit config.
- **Pros**: Zero ADR overhead. Each handler tailored to its specific context.
- **Cons**: Drift compounds — one handler skips rate; another forgets typeof; another reads payload-userId. PenTest playbook impossible to author. Code review checklist ad-hoc. New stories can quietly under-validate. Anti-cheat posture is the union of every author's discipline (lowest common denominator).
- **Rejection Reason**: Project has 5+ client→server reliables already designed; pattern repetition demands codification. ADR-level lock prevents drift; shared validator module reduces per-handler boilerplate.

### Alternative 2: Runtime cryptographic signing of client payloads

- **Description**: Client signs each payload with a session token issued at connect; server verifies signature before processing.
- **Pros**: Hard wire-level identity proof.
- **Cons**: Roblox engine already provides identity via the `player` argument — signing duplicates engine work. Adds CPU cost per remote (signature verification). Token-management overhead (issue, rotate, revoke). Exotic by Roblox standards — `replication-best-practices.md` does not endorse. PenTest tools harder to build.
- **Rejection Reason**: Solves a problem Roblox engine already solves. Adds complexity for no gain.

### Alternative 3: Validation enforced via single chokepoint Network wrapper (auto-validate)

- **Description**: `Network.connectEvent` itself runs identity + rate checks before invoking the handler; per-handler logic only sees pre-validated calls.
- **Pros**: Impossible to forget identity / rate (wrapper enforces).
- **Cons**: State + parameter checks are handler-specific; can't centralise. Wrapper would still need handler to opt into state + param categories, leaving the same drift surface partially exposed. Mixing engine-trusted (identity) with handler-specific (state, params) at the wrapper layer obscures the 4-check structure. Story authors would still write 2 of 4 checks, with no enforcement of the other 2.
- **Rejection Reason**: Wrapper-level half-validation + handler-level half-validation is harder to reason about than full handler-level 4-check pattern. Code review can verify a single pattern repeated across handlers; verifying "wrapper does X + handler does Y" is harder.

### Alternative 4: Server-side allowlist of valid payload schemas (typed RemoteEvent)

- **Description**: Define a strict TypeScript-style type schema per remote; auto-reject any payload that doesn't match the type at the wrapper level.
- **Pros**: Compile-time-ish parameter validation (Luau type system).
- **Cons**: Luau types don't fully validate at runtime — `--!strict` is compile-time only, not wire-format-checking. Implementing a runtime schema validator (e.g. a JSON-schema-like) is non-trivial and adds CPU cost per call. State + rate checks still handler-specific.
- **Rejection Reason**: Marginal gain on parameter validation; doesn't solve identity/state/rate coverage. Code review of `typeof` checks is sufficient for MVP scope.

## Consequences

### Positive

- ADR-level lock on 4-check guard pattern + reliable-vs-unreliable selection rule + payload budgets — closes ~10 gap TRs
- PenTest playbook authored — MVP-Integration-3 has concrete validation targets
- Shared `RemoteValidator` module reduces boilerplate per handler; consistent 4-check structure
- Stories can now embed ADR-0010 ref + cite the shared validator
- `/create-control-manifest` extracts pattern verbatim — daily implementation reference
- Pillar 4 anti-P2W posture strengthened: cosmetic systems forbidden from acting as remote handlers period (per ADR-0004 + ADR-0005); ADR-0010 confirms via §Identity Trust Model
- Identity-trust model explicit — eliminates the "trust payload userId" anti-pattern at architectural level

### Negative

- Code-review burden grows: every client→server PR checked for 4 guard categories
- Per-player rate-limit table memory bounded at ~12 players × ~5 remotes = 60 buckets — trivial but adds Pillar 3 reset wiring
- Selene rule deferred to Production phase — interim L3 enforcement is code-review only
- Documentation duplication — RateLimitConfig + RemoteValidator + this ADR + control manifest = 4 sources; drift risk if any updates without others
- Forbids RemoteFunction for fire-and-forget — story authors familiar with traditional remote-procedure-call pattern must adapt
- Silent-rejection model means clients don't get useful error messages — debugging requires server-log inspection (acceptable trade-off vs anti-cheat)

### Risks

- **Risk 1 (LOW)** — RateLimitConfig values mis-tuned; legitimate ProximityPrompt holds reject as rate-limited. Mitigation: MVP-Integration playtest tunes per-remote `max` to observed peak; conservative defaults err on permissive side; reject-counter telemetry surfaces over-tight limits.
- **Risk 2 (MEDIUM)** — Selene custom rule for L3 enforcement deferred to Production phase. Until then, L2 code review is sole same-server enforcement. Mitigation: control manifest cheat-sheet + `/story-readiness` validates at story-author time.
- **Risk 3 (LOW)** — Per-player rate-limit state leaks across rounds if `RemoteValidator.resetForRound` not wired. Mitigation: ADR-0005 §Round-End Ordering Invariants T9 includes `RemoteValidator.resetForRound` as part of `destroyAll → clearAll → broadcast` chain (this ADR adds the validator-reset step explicitly).
- **Risk 4 (LOW)** — Future high-frequency client→server remote (e.g. movement input) breaches 4 calls/sec rate. Mitigation: such remotes route to `UnreliableRemoteEvent` per §Selection Rule; rate-limit applies only to discrete reliable remotes.
- **Risk 5 (MEDIUM)** — Currency System (when authored) needs server→client `PlayerDataUpdated` reliable; ADR-0010 doesn't explicitly cover server→client validation (clients can't lie to themselves). Mitigation: ADR-0010 §4-Check Guard applies only to client-sent payloads; server→client traffic needs no validation. Future Currency ADR confirms.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/chest-system.md` §C 6-guard pipeline | "Active match? participating? crowd Active-strict? #relics<4? toll? count > effectiveToll?" | §4-Check Guard: state checks (1-3) + parameters checks (4-6); chest system's 6-guard pipeline is the state-rule expansion of ADR-0010's category 2 |
| `design/gdd/chest-system.md` §C ChestInteract | "Server validates ProximityPrompt hold completed" | §Server-Time Authority: ProximityPrompt engine semantics enforce server-side; ADR-0010 confirms server-time-only |
| `design/gdd/chest-system.md` §C ChestDraftPick | "Server validates specId ∈ candidates" | §4-Check Guard category 3 (parameters): typeof(specId) check + membership check against server-rolled candidates |
| `design/gdd/absorb-system.md` §C | "Proximity detection is server-authoritative (anti-cheat)" | §Identity-Trust Model + §Server-Time Authority: server runs proximity check from authoritative crowd position; client never asserts proximity |
| `design/gdd/crowd-collision-resolution.md` §C PairEntered | "Server fires PairEntered reliable; clients can't request" | §Selection Rule: server→client reliable; no client→server analog (clients cannot inject peel events) |
| `design/gdd/crowd-collision-resolution.md` §C peel buffer relevance filter | "Send only pairs involving player's crowdId" | §Selection Rule: server→client filtered RemoteEvent; client receives only their relevant peel context |
| `design/gdd/relic-system.md` §C grant atomic | "Late-check slots < 4, write slot, onAcquire, broadcast" | §4-Check Guard category 2 (state): server re-reads activeRelics count before grant — client can't pre-claim a slot |
| `design/gdd/match-state-machine.md` AFKToggle | "Client → server reliable; toggles participation flag" | §Selection Rule: discrete reliable; §RateLimitConfig 2 toggles per 5s |
| `design/gdd/match-state-machine.md` MIN_PLAYERS_TO_START | "Server-side participation count drives transition; client can't lie about being absent" | §Identity-Trust Model: participation flag is server-owned; AFKToggle handler validates per 4-check pattern |
| `design/gdd/crowd-replication-strategy.md` Rule 11 | "Server-only write authority; no client crowd state writes" | §Identity-Trust Model + §Server-Time Authority: clients have no write path to CSM by Roblox engine semantics + ADR-0004 + ADR-0010 confirms via "client-asserted state NEVER trusted" |
| `replication-best-practices.md` §Security 4-check | "Identity / State / Parameters / Rate" | §4-Check Guard Pattern is the architectural lock on this engine-reference policy |
| `replication-best-practices.md` §Data Size Limits | "Target <4 KB per gameplay remote; chunk via buffer for >16 KB" | §Payload Size Budgets locks |
| `replication-best-practices.md` §Crowdsmith chest open | "RemoteEvent (not RemoteFunction); server validates, fires reliable back" | §Selection Rule confirms; RemoteFunction forbidden for fire-and-forget |
| ADR-0001 §Risks 4 multi-client bandwidth | "Validate empirical bandwidth at MVP-Integration-3" | §PenTest Playbook: synthetic load test at MVP-Integration-3 verifies per-handler rate limits hold under flood |
| ADR-0004 §Pillar 4 anti-P2W | "Cosmetic systems FORBIDDEN as CSM write callers" | §Identity-Trust Model extends: cosmetic systems also forbidden as remote handlers for any state-mutating action |
| ADR-0005 §Round-End Ordering Invariants T9 | "destroyAll → clearAll → broadcast" | §Per-Player Rate Limit Policy: `RemoteValidator.resetForRound` added to T9 chain (between destroyAll and clearAll for clean ordering) |
| ADR-0006 §Forbidden Patterns Matrix | "Direct RemoteEvent path access forbidden; magic strings forbidden" | §4-Check Guard handlers must use Network wrapper + RemoteEventName enum — confirms ADR-0006 patterns |
| ADR-0008 §Replication Contract | "NpcStateBroadcast UREvent + NpcPoolBootstrap reliable" | §Selection Rule: NpcStateBroadcast = high-frequency continuous (UREvent); NpcPoolBootstrap = mid-round-join one-shot (reliable) |

## Performance Implications

- **CPU (server)**: per-handler 4-check overhead estimated <10 µs (typeof + table lookups + tick comparison). Across ~5 client→server remotes × 12 players × ~1 call/sec average = ~60 calls/sec × 10 µs = 0.6 ms/sec total. Negligible vs ADR-0003 §Phase budget (3 ms/tick).
- **CPU (client)**: zero — validation is server-side.
- **Memory (server)**: per-player rate-limit table ~5 buckets × 12 players × ~50 B = 3 KB. Trivial vs ADR-0003 §Server Memory budget (36 KB).
- **Load Time**: `RemoteValidator` module loaded at server boot; one-time. RateLimitConfig require'd once. Negligible.
- **Network**: zero new traffic; ADR-0010 enforces existing channel selection without adding remotes.

## Migration Plan

No existing handlers (clean implementation). For each client→server remote handler:

1. Implement `ServerStorage/Source/RemoteValidator/init.luau` with all 4-check helpers
2. Author `ReplicatedStorage/Source/SharedConstants/RateLimitConfig.luau` with per-remote caps
3. Each handler (ChestInteract / ChestDraftPick / AFKToggle / future) follows the 4-check template in §Decision
4. Wire `RemoteValidator.resetForRound()` into RoundLifecycle T9 destroyAll chain (per ADR-0005 §Round-End Ordering Invariants)
5. Code-review template adds "Verify ADR-0010 4-check guard pattern" checklist item
6. PenTest playbook executed at MVP-Integration-3 against deployed server
7. Selene custom rule (Production phase) flags missing guards in CI

## Validation Criteria

- [ ] `grep -rE "Network\\.connectEvent\\(RemoteEventName\\." src/ServerStorage/Source` — every match resolves to a handler containing all 4 guard categories (manual audit at MVP integration)
- [ ] PenTest pass at MVP-Integration-3: synthetic malicious client sends 10 attack patterns from §PenTest Playbook; server rejects all without crash, no state mutation, log entries present
- [ ] RateLimitConfig audit: every client→server `RemoteEventName` enum entry has a corresponding `RateLimitConfig` row
- [ ] `RemoteValidator.resetForRound` called from `RoundLifecycle.destroyAll` (verify by mock spy in integration test)
- [ ] No `payload.userId` reads in any server handler: `grep -rE "payload\\.userId|args\\.userId|p\\.userId" src/ServerStorage/Source` returns zero matches (anti-pattern audit)
- [ ] No client-asserted timestamps used in gameplay decisions: `grep -rE "payload\\.timestamp|payload\\.serverTime|payload\\.tick" src/ServerStorage/Source` returns zero matches
- [ ] No `RemoteFunction` for fire-and-forget: every `RemoteFunction` use case is justified as query-response (currently only `GetParticipation` per architecture.md §5.7)
- [ ] No raw `RemoteEvent` path access: `grep -rE "ReplicatedStorage\\.RemoteEvents\\." src/` returns zero matches (Network wrapper required per ADR-0006)
- [ ] Per-handler rate limit verified: send rate-cap × 2 calls in unit test; first half succeed, second half rejected; counters in mock validator confirm
- [ ] `typeof` check on every payload field: code review verifies; integration test sends `nil` / wrong-type / oversized payload per remote → server returns silently, no error log

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — Network wrapper + RemoteEvent infrastructure this ADR builds on
- **ADR-0004** CSM Authority — Pillar 4 anti-P2W posture this ADR reinforces via identity-trust model
- **ADR-0005** MSM/RoundLifecycle Split — T9 ordering invariant updated to include RemoteValidator.resetForRound
- **ADR-0006** Module Placement Rules + Forbidden Patterns Matrix — direct-RemoteEvent-access ban + magic-string ban that this ADR's handlers must obey
- **ADR-0008** NPC Spawner Authority — reliable-vs-unreliable selection rule example (NpcStateBroadcast UREvent + NpcPoolBootstrap reliable)
- **Expected downstream**:
  - ADR-0011 Persistence Schema — `PlayerDataUpdated` reliable server→client (no validation needed; server is authoritative)
  - Future Currency System ADR — `grantMatchRewards` server-driven; no client→server remote needed
  - Future Shop System ADR (Alpha+) — `ShopPurchase` client→server reliable; must adopt 4-check pattern + RateLimitConfig entry
  - Future Daily Quest System ADR (Alpha+) — `DailyQuestClaim` client→server reliable; must adopt pattern

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). All APIs (`RemoteEvent`, `RemoteFunction`, `UnreliableRemoteEvent`, `typeof`, `os.clock`, `tick`) are stable Roblox primitives predating LLM cutoff. `replication-best-practices.md` §Security pattern is the canonical reference adopted here.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
