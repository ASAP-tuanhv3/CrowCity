# Story 002: Schema migration handler scaffold + OnProfileVersionUpgrade wiring

> **Epic**: player-data-schema
> **Status**: Obsolete (2026-04-27 — closed unimplemented per architectural review)
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: ~~3–4 hours~~ (closed — see Closure Note)

## Context

**GDD**: N/A — migration policy locked by ADR-0011 §Schema versioning + migration policy
**Requirement**: TR-game-concept-008 (ProfileStore persistence — meta only)

**ADR Governing Implementation**: ADR-0011 — Persistence Schema + Pillar 3 Exclusions
**ADR Decision Summary**: Schema migrations go through ProfileStore `OnProfileVersionUpgrade` callback with handlers under `PlayerDataServer/migrations/`. `_schemaVersion` field at top of every profile; bumps are versioned and reviewed. This story scaffolds the dispatcher infrastructure even though MVP ships at v1 (no actual migration runs yet) — landing the seam now means VS+ schema bump is a single-handler addition rather than an architecture change.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: ProfileStore `OnProfileVersionUpgrade` is the documented vendored API surface. Reference: `docs/engine-reference/roblox/profilestore-reference.md`.

**Control Manifest Rules (Foundation layer)**:
- Required: All persistent writes via `PlayerDataServer` (ADR-0006)
- Required: Schema migrations via `OnProfileVersionUpgrade` + `MigrationHandlers/` dir (ADR-0011)
- Forbidden: Schema bump without matching migration handler (ADR-0011)
- Forbidden: Direct `DataStoreService` calls (ADR-0006)

---

## Acceptance Criteria

*Derived from ADR-0011 §Schema versioning + migration policy + §Verification Required (C):*

- [ ] AC-1: New directory `src/ServerStorage/Source/PlayerDataServer/migrations/` exists with an `init.luau` dispatcher module (`--!strict`)
- [ ] AC-2: Dispatcher exposes `dispatch(profile: ProfileType, fromVersion: number, toVersion: number): boolean` that walks per-version handlers in order from `fromVersion` to `toVersion`, returning `true` on success and `false` on missing handler (with warn log)
- [ ] AC-3: At least one stub handler `migrations/v0_to_v1.luau` exists as a no-op reference template (`--!strict`); exposes `migrate(profile: any): any` returning the profile unchanged. Documents the handler contract for future authors via top-of-file comment.
- [ ] AC-4: `PlayerDataServer.loadProfileAsync` (or template equivalent) is wired so that on profile load: read `profile._schemaVersion` (default `0` if missing for legacy profiles) and call `migrations.dispatch(profile, currentVersion, MVP_VERSION)` where `MVP_VERSION = 1` (matches story 001's `_schemaVersion = 1` baseline)
- [ ] AC-5: After successful migration, `profile._schemaVersion` is set to `MVP_VERSION` BEFORE the profile-load returns to caller
- [ ] AC-6: Missing-handler path: when `dispatch` returns `false`, profile load fails closed — caller gets a typed error; player kicked with friendly message (per CLAUDE.md FTUE pattern of fail-closed UX)
- [ ] AC-7: Migration round-trip test fixture: simulate a v0 legacy profile (no `_schemaVersion` field, only `Coins`); load via wired path; verify post-load profile has `_schemaVersion = 1` + all 6 MVP keys + correct defaults filled (per ADR-0011 §MVP Schema table)
- [ ] AC-8: `--!strict` type checks pass on dispatcher + handler + `PlayerDataServer.loadProfileAsync` modifications
- [ ] AC-9: BindToClose flush smoke (per ADR-0011 §Verification D): no special handling needed in this story (ProfileStore platform-level handles it); document in evidence doc that this AC is handled by vendored ProfileStore, not by this code

---

## Implementation Notes

*Derived from ADR-0011 §Decision + ProfileStore vendored API:*

- Folder layout per CLAUDE.md §File layout: folder-as-module with `init.luau` dispatcher.
- Per-version handler naming: `v[from]_to_[to].luau` (e.g. `v0_to_v1.luau`, `v1_to_v2.luau`). The dispatcher infers handler module name from the version delta — single-step migrations only (no version skipping).
- Dispatcher logic:
  ```luau
  local function dispatch(profile, fromVersion, toVersion)
      for v = fromVersion, toVersion - 1 do
          local handlerName = string.format("v%d_to_v%d", v, v + 1)
          local ok, handler = pcall(require, script.Parent[handlerName])
          if not ok or type(handler.migrate) ~= "function" then
              warn(string.format("[PlayerDataServer] missing migration handler: %s", handlerName))
              return false
          end
          handler.migrate(profile)
      end
      return true
  end
  ```
- v0 → v1 stub handler responsibilities: profile may be either (a) `nil`-equivalent (brand new, no fields), or (b) legacy with bare `Coins`. The handler should populate any missing field with the default from `DefaultPlayerData` rather than overwriting present values. Use `Freeze` library (vendored at `ReplicatedStorage/Dependencies/Freeze`) for safe field-merge: `Freeze.Dictionary.merge(DefaultPlayerData.get(), profile)`.
- The MVP_VERSION constant lives in `PlayerDataServer/migrations/init.luau` (single source of truth). When VS+ Daily Quest lands and bumps to v2, that constant + a new `v1_to_v2.luau` handler are the only changes needed.
- Test fixture (AC-7): use a stub ProfileStore mock that returns a hand-constructed legacy profile rather than hitting real DataStore. Pattern matches how vendored ProfileStore tests work.
- Logging: prefix all migration log lines with `[PlayerDataServer migration]` for grep-ability. Include `from → to` versions + player UserId.

---

## Out of Scope

- Story 001: MVP schema lock (story 001 owns the v1 baseline)
- Story 003: Persistence audit script
- Real v1 → v2 migration logic (no schema bump in MVP scope; v0_to_v1 stub handles the load-time-default-fill case only)
- Currency grant logic (MSM Core epic)
- Cross-server profile migration via MessagingService — explicitly forbidden per ADR-0011 §Forbidden patterns

---

## QA Test Cases

- **AC-1 / AC-2 / AC-3 / AC-8**: structural + strict
  - Given: working tree post-implementation
  - When: introspect `migrations/` dir
  - Then: `init.luau` + `v0_to_v1.luau` present; `dispatch` and `migrate` functions exposed; `--!strict` clean
  - Edge cases: missing init → fail; handler `migrate` not a function → fail

- **AC-4 / AC-5**: load-path wiring
  - Given: stub ProfileStore returning a v0 legacy profile (`{Coins = 50}`)
  - When: `PlayerDataServer.loadProfileAsync(player)` invoked
  - Then: returned profile has `_schemaVersion = 1` AND all 6 MVP keys present with correct defaults (Coins preserved at 50, others defaulted)
  - Edge cases: profile already at v1 → no migration runs (idempotent); profile at v2 (future) → fail closed via missing handler

- **AC-6**: missing-handler fail-closed
  - Given: stub profile at `_schemaVersion = 99` (no v99→v1 handler exists)
  - When: load
  - Then: caller receives typed error; warn log emitted with version mismatch
  - Edge cases: player kicked with friendly message — verify by spy on `Player:Kick` call (or whichever fail-closed mechanism PlayerDataServer uses)

- **AC-7**: round-trip integration
  - Given: hand-constructed v0 legacy profile (only `Coins = 100`, no `_schemaVersion`, no other fields)
  - When: full load path: ProfileStore mock → migrations.dispatch → caller
  - Then: post-load profile equals `{_schemaVersion = 1, Coins = 100, OwnedSkins = {default = true}, SelectedSkin = "default", LifetimeAbsorbs = 0, LifetimeWins = 0, FtueStage = <Stage1 default>}`
  - Edge cases: profile with EXTRA legacy fields (e.g. `OldRoundState = ...`) — confirm they're stripped (Pillar 3 enforcement at migration time) OR explicitly preserved + flagged for cleanup; document the chosen behavior

- **AC-9**: BindToClose flush
  - Given: vendored ProfileStore behavior
  - When: `game:BindToClose` triggers
  - Then: ProfileStore handles flush per platform 30 s grace
  - Pass condition: documented in evidence doc that no story code is needed; vendored library owns this contract

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-data/migration-roundtrip.spec.luau` — must exist and pass via TestEZ.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (MVP schema lock — `_schemaVersion = 1` baseline + 7-key default per Amendment 1)
- Unlocks: ~~Story 003 (audit script verifies migration handler dir exists)~~ — story 003 audit refactored to drop the migration-dir check; future VS+ schema bump (single-handler addition); MSM Currency grant story (consumer)

---

## Closure Note (2026-04-27 — Obsolete, Unimplemented)

**Decision**: Story closed without implementation. Premise overlaps with shipped template behaviour and would produce dead-code-on-arrival.

**Discovered during /dev-story spec inspection of `src/ServerStorage/Source/PlayerData/Server.luau`**:

1. **Template already implements default-fill on load** — `Server.luau:198` calls `profile:Reconcile()` immediately after `_profileStore:StartSessionAsync(userId)`. ProfileStore's `Reconcile()` walks the default template (passed at `start(defaultValue)`) and fills any missing fields on the loaded profile. For a v0 legacy profile (no `_schemaVersion`, only `Coins`), Reconcile fills the 6 missing MVP keys + `_schemaVersion = 1` automatically. This is exactly what story 002 AC-7 round-trip test was specified to verify.

2. **Story 002 spec referenced a non-existent function** — AC-4 says "wire `PlayerDataServer.loadProfileAsync`" but that function does not exist in the template. Actual entry point is `_onPlayerAddedAsync` (private, called via `safePlayerAdded`). Story spec also assumed `OnProfileVersionUpgrade` callback is wired; it is not — vendored ProfileStore exposes the API but the template's PlayerDataServer never registers a handler.

3. **MVP ships at `_schemaVersion = 1` with no bumps** — Story 002 builds dispatcher infrastructure for a delta that does not occur in MVP. The first real schema bump (v1 → v2) lands when VS+ Daily Quest System lands; that's the appropriate time to add a `v1_to_v2.luau` handler + the dispatcher seam, with full context of what the v2 schema actually changes. Building a v0_to_v1 stub now means writing a no-op handler for a transition that ProfileStore's `Reconcile()` already handles correctly.

4. **AC-7 spec was stale** — referenced "6 MVP keys" pre-Amendment 1; would have needed revision to 7 keys before any implementation.

**Why this story doesn't ship**:
- The Foundation contract this story was meant to provide — "legacy profiles upgrade cleanly to MVP v1 schema" — is already satisfied by template's `profile:Reconcile()` call. No additional code needed.
- Building dispatcher + mock-ProfileStore round-trip test for a v0_to_v1 transition that ProfileStore handles natively is dead-code-on-arrival pattern (same architectural-redundancy reasoning that closed ui-handler-layer-reg story-002).
- The seam this story would land — `migrations/init.luau` dispatcher + `OnProfileVersionUpgrade` registration — is appropriate to land in the FIRST story that actually bumps `_schemaVersion`. That's a VS+ epic concern (Daily Quest System story).

**Foundation deliverable preserved**: Story 001 ships the v1 baseline schema; template's `profile:Reconcile()` ensures any future profile loads (including any pre-existing test profiles) reconcile against this baseline. player-data-schema epic re-scoped to **2/3 effective** (stories 001 + 003).

**Future work**: When VS+ Daily Quest System lands, that epic's first story will:
1. Bump `_schemaVersion` constant 1 → 2 in `DefaultPlayerData.luau` (or wherever it ends up)
2. Add `src/ServerStorage/Source/PlayerData/migrations/v1_to_v2.luau` handler module
3. Add a small dispatch hook to `Server.luau:_onPlayerAddedAsync` between `StartSessionAsync` and `Reconcile()` — read `profile.Data._schemaVersion`, run incremental handlers, then let Reconcile fill any remaining fields
4. Migration round-trip test against the actual v1 → v2 delta

That work is best done with concrete v2 schema requirements in hand, not against a hypothetical v0 → v1 stub.

**No code shipped. No artifacts created.** Story preserved as documentation of the architectural review that closed it.

**Consequence for story 003**: AC-2 of story 003 will reference the audit script's migration-dir check — that check is dropped; story 003 to be revised at /dev-story time.
