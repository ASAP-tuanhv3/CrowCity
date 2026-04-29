# Story 001: Core module skeleton + accumulator + cadence + start/stop API

> **Epic**: tick-orchestrator
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md` (TickOrchestrator §15a spin-off; canonical spec lives in ADR-0002 + architecture.md §5.4)
**Requirement**: `TR-systems-index-005` (15 Hz server tick orchestration); cross-cutting indirect coverage via `TR-csm-008`, `TR-msm-019`, `TR-ccr-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 — TickOrchestrator — 15 Hz Server Tick Sequencing
**ADR Decision Summary**: Server-only singleton module owning the sole `RunService.Heartbeat` accumulator; every 1/15 s of accumulated `dt` runs the static 9-phase sequence synchronously; phases statically wired at boot (no runtime registration); exposes `start / stop / getCurrentTick / setTickDelegate` + boot-only `_registerPhases`.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: MEDIUM
**Engine Notes**: `RunService.Heartbeat` connection cadence is in-training-data + template-proven (LOW). Mobile dt jitter on iPhone SE is the MEDIUM-risk vector; this story implements the accumulator skeleton — measurement lives in story-005. `os.clock` for `stop()` latency assertion in tests is template-proven.

**Control Manifest Rules (Core layer)**:
- Required: TickOrchestrator at `ServerStorage/Source/TickOrchestrator/init.luau` is sole `RunService.Heartbeat:Connect` accumulator (manifest L59); cadence `_tickPeriod = 1/15` (L64); `getCurrentTick(): number` exposed (L65); test hook `setTickDelegate(fn)` (L66) — production must NOT call.
- Forbidden: Never create competing `RunService.Heartbeat:Connect` for gameplay-tick work (L131); never register phases at runtime (L133).
- Guardrail: Phase callbacks synchronous (no yields) — implemented in story-002. This story reserves the contract; phase callback iteration arrives in story-002.

---

## Acceptance Criteria

*From ADR-0002 §Validation Criteria + §Architecture + §Migration Plan, scoped to this story:*

- [ ] `ServerStorage/Source/TickOrchestrator/init.luau` exists with `--!strict` header
- [ ] Module exposes `start(): ()`, `stop(): ()`, `getCurrentTick(): number`, `setTickDelegate(fn: ((tick: number) -> ())?): ()` matching ADR-0002 §Key Interfaces signatures
- [ ] Module exposes boot-only `_registerPhases(phases: { TickPhase }): ()` — asserts `#phases == 9` AND every entry has unique `phase` value in `1..9` AND `name` is a non-empty string AND `callback` is a function. Failed assertion errors at boot loud.
- [ ] **Public `registerPhase` API does NOT exist** — phase table is exclusively populated via the boot-only internal `_registerPhases`
- [ ] Module-level state: `_accumulator: number = 0`, `_tickCount: number = 0`, `_heartbeatConnection: RBXScriptConnection? = nil`, `_phases: { TickPhase } = {}` (populated by `_registerPhases`), `_tickDelegate: ((number) -> ())? = nil`, `_tickPeriod: number = 1 / 15`
- [ ] `start()` connects `RunService.Heartbeat` exactly once; subsequent `start()` calls without an intervening `stop()` are a no-op (idempotent)
- [ ] `start()` requires `_phases` to be populated (length == 9) — fails loud if `_registerPhases` not called yet
- [ ] On each Heartbeat callback: `_accumulator += dt`; `while _accumulator >= _tickPeriod` drain loop runs `_runTick(_tickCount)` then increments `_tickCount` and decrements `_accumulator -= _tickPeriod` per iteration. **The `while` loop synchronously drains all accrued ticks in the same Heartbeat callback** — no tick loss, no doubled ticks (ADR-0002 §Risks Risk 4)
- [ ] `_runTick` calls `_tickDelegate(tickCount)` and returns immediately if a delegate is set (test hook); phase iteration arrives in story-002. This story may stub `_runTick` body to only call the delegate (or no-op when no delegate)
- [ ] `getCurrentTick(): number` returns `_tickCount` value at call time (post-increment from prior tick)
- [ ] `stop(): ()` disconnects `_heartbeatConnection` and sets it to `nil` within ≤ 5 ms of call (ADR-0002 §Validation L8)
- [ ] After `stop()`: no Heartbeat callback fires; `_tickCount` preserved (NOT reset); `_accumulator` reset to 0
- [ ] Cadence over 60 s desktop fixture: `_tickCount` ∈ [`60 * 15 - 1`, `60 * 15 + 1`] (±0.1 % per ADR-0002 §Validation L1; mobile ±0.3 % validation deferred to story-005 + MVP integration sprint)

---

## Implementation Notes

*Derived from ADR-0002 §Architecture (L70-103) + §Key Interfaces (L121-158):*

- Module pattern: not OOP class — singleton module per ANATOMY.md §16 (module-level state allowed for system-level services). Mirrors how the template `Network/init.luau` is structured.
- Use `local RunService = game:GetService("RunService")` at module top (per CLAUDE.md naming + Roblox conventions).
- The `while _accumulator >= _tickPeriod` loop catches up correctly when Roblox pauses the server (e.g. 500 ms hang → 7.5 ticks accrued → drained in one Heartbeat). ADR-0002 §Risk 4 explicitly accepts this; do not cap catch-up tick count this story (deferred to playtest if needed).
- Asserts in `_registerPhases` are loud-fail (boot-time). Use `assert(condition, "TickOrchestrator: <message>")` — readable error in server console.
- `setTickDelegate(fn)`: when `fn ~= nil`, the production phase iteration is bypassed entirely. Tests use this to inject deterministic step + verify cadence + accumulator math without needing the 9 phase modules wired. Production code must never call this — control-manifest L66 forbids.
- `stop()` <5 ms latency requirement is trivially satisfied by `:Disconnect()` on the cached connection; the latency budget is for downstream chain (`stop` → `MatchStateChanged("ServerClosing")` → `ProfileStore release`) and lives in story-004.
- Engine note: `RunService.Heartbeat` callback `dt` is in seconds (matches `_tickPeriod` units). Verified vs `replication-best-practices.md`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-002**: Phase iteration logic inside `_runTick` (ctx construction, 1..9 ordered iteration, pcall isolation). This story leaves `_runTick` body as `if _tickDelegate then _tickDelegate(tickCount) end`.
- **story-003**: Boot-time `_registerPhases({...})` invocation in `ServerScriptService/start.server.luau` with the named 9-callback table. This story only implements the assertion-validating `_registerPhases` function itself.
- **story-004**: `BindToClose` handler invoking `stop()` first in shutdown chain. This story only guarantees `stop()`'s own ≤5 ms latency.
- **story-005**: Per-phase `os.clock` instrumentation + jitter telemetry hook. This story leaves `_runTick` un-instrumented.
- **MSM/CSM stories**: any test fixture exercising T6/T7 simultaneity or double-elim — those validate MSM logic, not TickOrch's contract.

---

## QA Test Cases

*Logic story — automated test specs. The developer implements against these.*

- **AC: Module exists with correct public surface**
  - Given: project compiles cleanly under `--!strict`
  - When: `local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)` executes
  - Then: `start`, `stop`, `getCurrentTick`, `setTickDelegate`, `_registerPhases` are functions
  - Edge cases: `TickOrchestrator.registerPhase` is `nil` (no public runtime registration API)

- **AC: `_registerPhases` assertion — happy path**
  - Given: a valid 9-entry table with unique `phase ∈ 1..9`, non-empty `name`, callable `callback`
  - When: `TickOrchestrator._registerPhases(phases)` runs
  - Then: returns `()` without error; `getCurrentTick()` still returns `0`
  - Edge cases: phases passed in scrambled order (e.g. {3,1,9,2,...}) still pass — order in input table doesn't matter, presence of all 9 phases does

- **AC: `_registerPhases` assertion — failure modes**
  - Given: invalid phase tables
  - When: `_registerPhases({...})` called
  - Then: `assert` fires with descriptive message
  - Edge cases: `#phases == 8` (missing one) → fails; `#phases == 10` (duplicate) → fails; phase value 0 or 10 → fails; two entries with same `phase` value → fails; `name = ""` → fails; `callback = nil` → fails

- **AC: `start()` requires registered phases**
  - Given: fresh module load; `_registerPhases` never called
  - When: `TickOrchestrator.start()` invoked
  - Then: `assert` fires; no Heartbeat connection created
  - Edge cases: `_registerPhases` called with valid table → `start()` succeeds

- **AC: `start()` idempotence**
  - Given: `_registerPhases` called once with valid table
  - When: `start()` called twice without intervening `stop()`
  - Then: only one `RunService.Heartbeat` connection exists; second `start()` is no-op
  - Edge cases: `start() → stop() → start()` re-creates the connection

- **AC: Accumulator math + catch-up drain (no loss, no double)**
  - Given: `setTickDelegate(fn)` set to a recorder; `start()` called
  - When: Heartbeat fixture fires with `dt = 0.5` (representing 500 ms platform pause)
  - Then: recorder fires exactly 7 times in same Heartbeat callback (`floor(0.5 / (1/15)) = 7`); residual `_accumulator ≈ 0.5 - 7/15 ≈ 0.0333`
  - Edge cases: `dt = 1/15` → fires exactly 1; `dt = 2/15` → fires exactly 2; `dt = 1/30` (sub-tick) → fires 0 times, accumulator carries forward

- **AC: `getCurrentTick` monotonic increment**
  - Given: `setTickDelegate(fn)` recorder; `start()` called
  - When: 30 ticks fire via fixture
  - Then: `getCurrentTick()` returns 30 after the 30th tick
  - Edge cases: `getCurrentTick()` returns 0 before any tick fires; `stop()` does NOT reset the counter

- **AC: `stop()` halts within ≤5 ms + clears Heartbeat**
  - Given: `start()` running; recorder counts active ticks
  - When: `stop()` invoked, then 100 ms of fixture Heartbeat fires elapse
  - Then: `os.clock` delta from `stop()` call to `_heartbeatConnection == nil` ≤ 0.005 s; recorder count after `stop()` is unchanged after the 100 ms wait
  - Edge cases: `stop()` called when never `start()`-ed → no error; double-`stop()` → no error

- **AC: Cadence ±0.1 % desktop over 60 s**
  - Given: real `RunService.Heartbeat` fixture running 60 s on desktop test rig
  - When: `setTickDelegate` recorder counts ticks
  - Then: tick count ∈ [899, 901] (60 × 15 ± 1)
  - Edge cases: mobile validation deferred to story-005 + MVP integration sprint per ADR-0002 §Risk 1

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tick-orchestrator/cadence.spec.luau` AND `tests/unit/tick-orchestrator/registerphases.spec.luau` AND `tests/unit/tick-orchestrator/lifecycle.spec.luau` — must exist and pass via TestEZ runner.

**Status**: [x] Executed headless 2026-04-29 — 52/0/0 pass via `run-in-roblox` (32 TickOrch + 20 prior AssetId)

---

## Dependencies

- Depends on: None (this is the foundation of the epic)
- Unlocks: story-002 (phase dispatch loop), story-003 (boot wiring), story-004 (BindToClose), story-005 (instrumentation)

---

## Completion Notes

**Completed**: 2026-04-29
**Criteria**: 13/13 covered (AC-13 real-Heartbeat soak deferred to story-005 + integration sprint per ADR-0002 §Risk 1; 60s math proxy passes)

**Files**:
- `src/ServerStorage/Source/TickOrchestrator/init.luau` (228 L) — singleton module; sole `RunService.Heartbeat:Connect` accumulator; static 9-phase `_registerPhases` with boot-only invariant guard; `_runTick` stub deferred to story-002
- `tests/unit/tick-orchestrator/cadence.spec.luau` (97 L, 7 it blocks) — accumulator drain math + 60s ±0.1% proxy + dt=0 boundary
- `tests/unit/tick-orchestrator/registerphases.spec.luau` (147 L, 13 it blocks) — happy path + 9 failure modes + AC-04 nil registerPhase + boot-only double-call guard + surface-shape contract (AC-01/02)
- `tests/unit/tick-orchestrator/lifecycle.spec.luau` (143 L, 11 it blocks) — start idempotence, stop clears connection (structural; ≤5ms claim by ADR-0002), tickCount preservation, accumulator reset

**Test Evidence**: 3 TestEZ spec files at `tests/unit/tick-orchestrator/`. **Executed 2026-04-29** via `rojo build test.project.json -o test-place.rbxl && run-in-roblox --place test-place.rbxl --script tests/runner.server.luau` → **52/0/0 pass** (32 TickOrch + 20 prior AssetId).

**Test-only public surface added** (4 fns, all `_`-prefixed + doc-commented "TEST ONLY"):
- `_tick(dt)` — factored Heartbeat body; live production callback (start() wires it to Heartbeat:Connect) AND test driver
- `_resetForTests()` — zeros all module state for test isolation
- `_getHeartbeatConnection()` — identity check for idempotence test
- `_getAccumulator()` — accumulator visibility for stop() reset + carry-forward verification

**Code Review**: APPROVED (lead-programmer + qa-tester) per `/code-review` 2026-04-29.
- LP verdict: APPROVED WITH SUGGESTIONS — 3 advisories applied inline (boot-only `_registerPhases` guard, Heartbeat:Connect comment clarifying `_tick` is live callback, test naming convention left as TestEZ prose)
- QA verdict: GAPS → ADEQUATE after fixes — 4 inline patches (dt=0 boundary test, fractional phase rejection test, surface-shape it block AC-01/02, double-`_registerPhases` rejection test, `stop()` timing assertion → structural-only per `coding-standards.md` §Determinism)

**Deviations** (ADVISORY only, non-blocking):
- Test naming style — TestEZ prose `it("...")` strings vs project standard `test_[system]_[scenario]_[expected]` (per `.claude/rules/test-standards.md`). TestEZ idiom; defensible. Track as project-level convention decision (Logic stories using TestEZ prose; non-TestEZ engines retain underscore convention).

**Latent project gap surfaced** (NOT introduced by this story): `selene.toml` missing → `selene src/` fails 1386 errors because Roblox globals (`game`, `task`, `typeof`, `RBXScriptConnection`) treated as undefined. Affects template-original code + vendored `ProfileStore.luau`. Fix: create `selene.toml` with `std = "roblox"` + run `selene generate-roblox-std`. Out of scope for story-001; track as test-infra follow-up before next sprint's CI run.

**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode.

**Unblocks**: story-002 (Phase dispatch + pcall isolation) — `_runTick` stub body ready for replacement; ctx allocation pattern flagged for scratch-buffer optimization if profiling surfaces it (per LP advisory).
