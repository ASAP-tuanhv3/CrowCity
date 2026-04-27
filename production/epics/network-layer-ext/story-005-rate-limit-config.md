# Story 005: RateLimitConfig SharedConstants table

> **Epic**: network-layer-ext
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Manifest Version**: 2026-04-27
> **Estimate**: 1–2 hours

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
**Required evidence**: `tests/unit/remote-validator/rate-limit-config_test.luau` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (parallel-safe with story 004; can be developed first if 004 needs the stub)
- Unlocks: Story 004 `RemoteValidator.checkRate` implementation; consumer-system stories that bind a client→server remote
