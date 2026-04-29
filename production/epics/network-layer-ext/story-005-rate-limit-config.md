# Story 005: RateLimitConfig SharedConstants table

> **Epic**: network-layer-ext
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Manifest Version**: 2026-04-27
> **Estimate**: 1–2 hours
> **Completed**: 2026-04-27

## Context

**GDD**: N/A — config sourced from ADR-0010 §Per-Player Rate Limit Policy
**Requirement**: TR-network-??? (no TR registered)

**ADR Governing Implementation**: ADR-0010 — Server-Authoritative Validation Policy
**ADR Decision Summary**: Per-remote rate limits live in `SharedConstants/RateLimitConfig.luau`. Each entry specifies `rate` (tokens per second steady) and `burst` (initial bucket capacity). `RemoteValidator.checkRate` (story 004) reads this config keyed by `RemoteEventName`.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Pure config table; no engine API surface.

**Control Manifest Rules (Foundation layer)**:
- Required: Per-player rate limits via `SharedConstants/RateLimitConfig.luau` keyed `(player, remoteName)` — token-bucket (control-manifest.md L113)

---

## Acceptance Criteria

*Derived from ADR-0010 §Per-Player Rate Limit Policy + the client→server remote inventory in arch §5.7:*

- [ ] AC-1: New `src/ReplicatedStorage/Source/SharedConstants/RateLimitConfig.luau` module exists with `--!strict`
- [ ] AC-2: Module returns a single table keyed by `RemoteEventName` string values; each entry is a record `{rate: number, burst: number}` where `rate > 0` and `burst >= 1`
- [ ] AC-3: Required entries cover every client→server remote in arch §5.7: `ChestInteract`, `ChestDraftPick`, `AFKToggle` (plus `GetParticipation` if RemoteFunction routes through same config — confirm in Implementation Notes; if not, omit)
- [ ] AC-4: Each entry's `rate` and `burst` values match ADR-0010 §Per-Player Rate Limit Policy table (canonical source)
- [ ] AC-5: Type export: `export type RateLimitEntry = {rate: number, burst: number}` so `RemoteValidator` (story 004) can type-annotate against it
- [ ] AC-6: A `default` fallback entry exists for any remote not explicitly keyed (conservative: `{rate = 1, burst = 2}` — enforces SHOULD-NOT-be-spammable on any forgotten registration)
- [ ] AC-7: `--!strict` type checks pass

---

## Implementation Notes

*Derived from ADR-0010 §Per-Player Rate Limit Policy:*

- Placement is fixed by control-manifest.md L113 + ADR-0010 line 90: `ReplicatedStorage/Source/SharedConstants/RateLimitConfig.luau`. Shared (not server-only) so the type definition can be referenced from client-side test fixtures even though the table itself is read only on the server.
- Pull canonical `rate` / `burst` numbers from ADR-0010 — DO NOT invent. If a remote is in arch §5.7 but ADR-0010 has no entry, flag it for ADR amendment rather than guessing.
- Default fallback `{rate=1, burst=2}` is explicitly conservative. It exists to make forgotten registrations safe-by-default. Story 004 `RemoteValidator.checkRate` returns the default when the lookup misses — document this contract in both modules.
- `RemoteFunctionName.GetParticipation` is a stateless reconcile per arch §5.7 — typically called once on client boot or reconnect. ADR-0010 may exempt RemoteFunctions from rate-limiting; check ADR text and confirm in PR description. If exempted, do not add an entry; if not, add a generous one (e.g. `{rate=2, burst=4}`).
- Document the rate-limit decision in a top-of-file comment block — what the rate / burst means in caller-facing terms (e.g. "ChestInteract: 1 attempt/sec, burst 3 — covers triple-tap intent without enabling chest-spam").

Reference shape:
```luau
--!strict
-- Per-remote token-bucket rate limits per ADR-0010 §Per-Player Rate Limit Policy.
-- Read by ServerStorage/Source/RemoteValidator/init.luau::checkRate.

export type RateLimitEntry = {rate: number, burst: number}

local RateLimitConfig: {[string]: RateLimitEntry} = {
    -- ChestInteract = {rate = 1, burst = 3},
    -- ChestDraftPick = {rate = 2, burst = 4},
    -- AFKToggle = {rate = 1, burst = 2},
    default = {rate = 1, burst = 2},
}

return RateLimitConfig
```

---

## Out of Scope

- Story 004: `RemoteValidator` (consumer of this config)
- Per-handler wiring (consumer epics)
- Telemetry / observability of rate-limit-rejection rates (Production phase)

---

## QA Test Cases

- **AC-1 / AC-2 / AC-7**: structural + strict
  - Given: module loaded
  - When: introspect
  - Then: returns table; each entry is `{rate, burst}` with valid numerics
  - Edge cases: missing field → fail; rate <= 0 → fail; burst < 1 → fail

- **AC-3 / AC-4**: required entries + canonical values
  - Given: ADR-0010 §Per-Player Rate Limit Policy table
  - When: cross-reference module entries
  - Then: every ADR-0010 entry is in module with matching values; no module entry contradicts ADR-0010
  - Edge cases: ADR-0010 amendment not yet reflected → flag for re-sync, fail this AC

- **AC-5**: type export
  - Given: `RemoteValidator` module
  - When: declares `local entry: RateLimitConfig.RateLimitEntry = ...`
  - Then: zero `--!strict` errors

- **AC-6**: default fallback
  - Given: a remote name not in the table (e.g. `"NotARealRemote"`)
  - When: `RateLimitConfig[name] or RateLimitConfig.default`
  - Then: returns `{rate=1, burst=2}` (or whatever default value lands)
  - Edge cases: typo in remote name → falls through to default (intentional safe-by-default)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: `tests/unit/remote-validator/rate-limit-config.spec.luau` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (parallel-safe with story 004; can be developed first if 004 needs the stub)
- Unlocks: Story 004 `RemoteValidator.checkRate` implementation; consumer-system stories that bind a client→server remote

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 7/7 passing

**Deviations**:
- ADVISORY (model conversion): ADR-0010 §Per-Player Rate Limit Policy lines 172-174 specifies entries in windowed shape `{max, windowSec}`. Story 005 spec mandates token-bucket shape `{rate, burst}` (line 32 AC-2 + line 56 reference shape). The two stories (004 + 005) consistently use token-bucket which is strictly stronger (smooths sustained rate while still admitting bursts). Conversion: `{max=4, windowSec=1.0}` → `{rate=4, burst=4}`; `{max=1, windowSec=1.0}` → `{rate=1, burst=1}`; `{max=2, windowSec=5.0}` → `{rate=0.4, burst=2}`. Conversion preserves practical caller intent. Documented inline in RateLimitConfig.luau header block + caller-facing intent paragraph per Implementation Notes guidance.
- ADVISORY: `GetParticipation` (RemoteFunction) and `RelicDraftPick` (RemoteEvent) omitted from explicit entries. ADR-0010 lines 172-174 enumerate only ChestInteract / ChestDraftPick / AFKToggle. Default fallback `{rate=1, burst=2}` covers any unlisted remote per AC-6 safe-by-default contract. Decision documented inline in RateLimitConfig.luau §Out-of-scope comment block.

**Test Evidence**: Config/Data story — typically requires smoke check at production/qa/evidence/, but the story spec instead specified a unit test (line 108: `tests/unit/remote-validator/rate-limit-config.spec.luau`) — implemented as TestEZ unit test (more reliable for static config validation than smoke evidence). 9 test functions across 4 describe blocks covering all 7 ACs.

**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `src/ReplicatedStorage/Source/SharedConstants/RateLimitConfig.luau` (NEW, 47 L) — 4 entries (3 explicit + 1 default fallback); type export `RateLimitEntry`
- `tests/unit/remote-validator/rate-limit-config.spec.luau` (NEW, 80 L, 9 test fns)

**Manifest Version**: 2026-04-27 (current ✓ no staleness).

**Audit gates**: tools/audit-asset-ids.sh exit 0 / tools/audit-persistence.sh exit 0.

**Unblocks**: Story 004 `RemoteValidator.checkRate` consumes this config; consumer-system stories binding client→server remotes get safe-by-default rate limiting via fallback.
