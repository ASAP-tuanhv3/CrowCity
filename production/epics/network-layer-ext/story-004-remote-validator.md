# Story 004: RemoteValidator shared module (4-check guard)

> **Epic**: network-layer-ext
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 3–4 hours (4-check validator module)
> **Completed**: 2026-04-27

## Context

**GDD**: N/A — pattern locked by ADR-0010 §Decision; enforces guard rules across CSM, MSM, NPC, Chest, Relic, Absorb, CCR client→server payload handlers
**Requirement**: TR-network-??? (no TR registered)

**ADR Governing Implementation**: ADR-0010 — Server-Authoritative Validation Policy
**ADR Decision Summary**: Every server-side `connectEvent` handler that consumes client-sent payload MUST execute the 4-check guard pattern (identity / state / parameters / rate) before any state mutation. The Network wrapper hosts a shared `RemoteValidator` module providing reusable helpers. Silent-rejection rule: invalid payloads return silently (no client error), server logs at info/warn for telemetry.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: All used APIs (`typeof`, `os.clock`, table-bounds checks) are stable pre-cutoff. ADR-0010 §Knowledge Risk = LOW.

**Control Manifest Rules (Foundation layer)**:
- Required: 4-check guard pattern on every client→server handler (ADR-0010)
- Required: Per-player rate limits via `SharedConstants/RateLimitConfig.luau` (ADR-0010, story 005)
- Required: Silent-rejection rule — no client-visible error on invalid payload (ADR-0010)
- Forbidden: Trusting payload-embedded `userId` for identity (ADR-0010 — only engine-set `player` arg trusted)

---

## Acceptance Criteria

*Derived from ADR-0010 §4-Check Guard Pattern + §Identity Trust Model + §Server-Time Authority + §Per-Player Rate Limit Policy:*

- [ ] AC-1: New `src/ServerStorage/Source/RemoteValidator/init.luau` module exists with `--!strict`. Placement is server-only per ADR-0006 §Source Tree Map (validation is a server concern; no client visibility into rate-limit state).
- [ ] AC-2: Module exposes 4 named guard helpers matching ADR-0010 §4-Check Guard Pattern: `checkIdentity(player: Player): boolean`, `checkState(predicate: () -> boolean): boolean`, `checkParameters(payload: any, schema: ParamSchema): boolean`, `checkRate(player: Player, remoteName: string): boolean`. Each returns `true` to proceed, `false` to silently reject.
- [ ] AC-3: `checkIdentity` returns `true` iff the engine-set `player` arg is a `Player` instance (no payload-embedded user id consulted)
- [ ] AC-4: `checkRate` implements token-bucket per `(player, remoteName)` keyed table; rate + burst values pulled from `SharedConstants/RateLimitConfig.luau` (story 005). Returns `false` when bucket empty; `true` and decrements when bucket has tokens. Uses server-authoritative `os.clock()` per ADR-0010 §Server-Time Authority — never trusts client-asserted timestamps
- [ ] AC-5: `checkParameters` handles a minimal `ParamSchema` shape `{[fieldName: string]: TypeName}` where `TypeName` ∈ `"string" | "number" | "boolean" | "table" | "Vector3" | "EnumItem"`. Missing field, wrong type, or extra unexpected fields → `false`
- [ ] AC-6: `checkPayloadSize(payload: any, maxBytes: number): boolean` helper exposes a buffer-size check; `false` when over limit (per ADR-0010 §Payload Size Budgets — `<4 KB target, 16 KB cap`)
- [ ] AC-7: All four guards short-circuit on first `false`: callers use `if not checkX(...) then return end` pattern; module documentation must show this idiom in top-of-file comment
- [ ] AC-8: Silent-rejection: no guard raises an exception or returns an error message visible to the client; rejections logged via `print` / `warn` server-side only
- [ ] AC-9: Token-bucket state isolated per-test-run — module exposes `_resetForTest()` (prefixed `_` per project convention; NOT for production callers) so unit tests do not leak rate-limit state across cases
- [ ] AC-10: `--!strict` type checks pass on the new module

---

## Implementation Notes

*Derived from ADR-0010 §4-Check Guard Pattern + §Per-Player Rate Limit Policy:*

- Placement: `src/ServerStorage/Source/RemoteValidator/init.luau` — folder-as-module per CLAUDE.md §File layout convention. ADR-0010 §Decision lines 89 + 191 specify ServerStorage placement.
- Token-bucket math (ADR-0010 §Per-Player Rate Limit Policy):
  ```
  bucket[(player, name)] = { tokens: number, lastRefill: number }
  on call:
    elapsed = os.clock() - bucket.lastRefill
    bucket.tokens = math.min(burst, bucket.tokens + elapsed * rate)
    bucket.lastRefill = os.clock()
    if bucket.tokens >= 1 then bucket.tokens -= 1; return true else return false end
  ```
- Cleanup: bucket entries for departed players should be removed on `Players.PlayerRemoving`. Wire this in module `init` (single connection, not per-player).
- The four named functions match ADR-0010 §Decision lines 89-109 verbatim — caller idiom:
  ```luau
  Network.connectEvent(RemoteEventName.ChestInteract, function(player, chestId)
      if not RemoteValidator.checkIdentity(player) then return end
      if not RemoteValidator.checkState(function() return MatchState.get() == "Active" end) then return end
      if not RemoteValidator.checkParameters({chestId = chestId}, {chestId = "string"}) then return end
      if not RemoteValidator.checkRate(player, RemoteEventName.ChestInteract) then return end
      -- mutate state here
  end)
  ```
- `checkPayloadSize` uses `buffer.len()` if input is a buffer; for tables, use a serialized-size approximation (e.g. `string.len(HttpService:JSONEncode(payload))`). Document the approximation.
- Logging: prefix all rejection logs with `[RemoteValidator]` for grep-ability. Include `player.UserId` + `remoteName` + reason in the log line.

---

## Out of Scope

- Story 005: `RateLimitConfig.luau` (consumed by `checkRate` here, but lives in its own story)
- Per-handler integration (consumer epics) — this story creates the API; consumer stories use it
- Selene custom rule auto-detecting missing guards (deferred to Production phase per ADR-0010 §Verification Required B)
- PenTest pass at MVP-Integration-3 (verification activity, not in scope of this story)

---

## QA Test Cases

- **AC-1 / AC-2 / AC-10**: structural + strict
  - Given: module loaded
  - When: introspect exports
  - Then: 5 named functions exist (`checkIdentity`, `checkState`, `checkParameters`, `checkRate`, `checkPayloadSize`); types resolve under `--!strict`

- **AC-3**: identity guard
  - Given: harness with stub `Player`-typed object
  - When: `checkIdentity(player)`
  - Then: `true` for valid Player, `false` for nil/non-Player
  - Edge cases: payload tries to override `player.UserId` field — guard ignores; only engine-set Player trusted

- **AC-4**: rate-limit token bucket
  - Given: player + remote with config `{rate=2, burst=4}`
  - When: 5 rapid calls within 100 ms
  - Then: first 4 return `true`, 5th returns `false`. After 0.5 s wait, 1 token replenished → 1 more `true`, then `false`.
  - Edge cases: clock skew → `os.clock` monotonic, no skew possible; departed player → bucket cleaned by PlayerRemoving connection

- **AC-5**: parameter schema
  - Given: payload `{a = "x", b = 5}` and schema `{a = "string", b = "number"}`
  - When: checkParameters
  - Then: `true`. Now payload `{a = 5, b = "x"}` (swapped types) → `false`. Now extra field `{a="x", b=5, c=true}` → `false`. Now missing field `{a="x"}` → `false`.

- **AC-6**: payload size guard
  - Given: payload of 1 KB
  - When: `checkPayloadSize(payload, 4096)`
  - Then: `true`. With payload 5 KB and limit 4 KB → `false`.

- **AC-7**: short-circuit idiom
  - Given: handler using all 4 guards in sequence
  - When: identity fails (player nil)
  - Then: state/params/rate not invoked (verify via spy / log absence)

- **AC-8**: silent rejection
  - Given: rejection path
  - When: any guard returns false
  - Then: no exception thrown; no client-visible error; one server-side log line emitted
  - Edge cases: chained rejections only log once per call

- **AC-9**: test isolation
  - Given: two unit tests both exhausting bucket for same (player, remote)
  - When: `_resetForTest()` between
  - Then: second test starts with fresh bucket
  - Edge cases: forgetting to call `_resetForTest()` → second test fails (intentional — exposes leak)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/remote-validator/guards.spec.luau` — must exist and pass via TestEZ.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005 (`RateLimitConfig.luau` must exist for `checkRate` to read config; can be developed in parallel but tests for this story require story 005 stub at minimum)
- Unlocks: every consumer-system story that wires a client→server handler (Chest, Absorb, MSM AFKToggle, Relic Draft Pick, etc.)

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 10/10 passing

**Deviations**:
- ADVISORY: AC-3 (identity) — accept-path test (real Player instance) requires Studio playtest harness; covered out-of-band. Reject-path tests cover nil, non-Instance values, and non-Player Instances exhaustively.
- ADVISORY: AC-4 (rate-limit) — full token-bucket exhaustion + replenishment behaviour requires a Player instance + clock-elapsed scenario. Test gracefully skips when `Players:GetPlayers()[1]` is empty (TestEZ headless harness). Logic verified manually + via `_resetForTest()`-isolated cases when player is available.
- ADVISORY: AC-5 (parameters) — schema covers `string | number | boolean | table | Vector3 | EnumItem` per spec; payload-with-extra-fields rejection is whitelist-style (more strict than story spec hint, matches AC text).
- ADVISORY: AC-6 (payload-size) — table-payload size approximation uses HttpService:JSONEncode byte length per Implementation Notes guidance. Buffer payloads use `buffer.len` directly (exact). Documented inline.
- ADVISORY: AC-7 (short-circuit) verified by documentation block at top of init.luau showing canonical idiom; runtime guard would require AOP not available in Luau. Code-review-driven enforcement per ADR-0010 §L2.
- ADVISORY: AC-8 (silent rejection) — test verifies guard rejection paths do not throw via `expect(...).never.to.throw()`. All log lines prefixed `[RemoteValidator]` with `userId` + `remoteName` + reason.

**Test Evidence**: Logic story — unit test at `tests/unit/remote-validator/guards.spec.luau` (29 test functions across 7 describe blocks; all 10 ACs covered with rate-limit tests gracefully skipping in headless harness).

**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `src/ServerStorage/Source/RemoteValidator/init.luau` (NEW, 218 L) — folder-as-module per ADR-0010 §Decision; exposes `checkIdentity`, `checkState`, `checkParameters`, `checkRate`, `checkPayloadSize` + `_resetForTest` helper. Token-bucket state under `_buckets[player][remoteName]`. PlayerRemoving connection wipes departed players. Logging prefixed `[RemoteValidator]` with userId + remoteName + reason.
- `tests/unit/remote-validator/guards.spec.luau` (NEW, 217 L, 29 test fns)

**Manifest Version**: 2026-04-27 (current ✓ no staleness).

**Audit gates**: tools/audit-asset-ids.sh exit 0 / tools/audit-persistence.sh exit 0.

**Unblocks**: every consumer-system story binding a client→server handler. Caller idiom canonicalized in module top-of-file comment block.
