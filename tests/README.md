# Test Infrastructure

**Engine**: Roblox (Luau strict mode; engine-ref pinned 2026-04-20)
**Test Framework**: TestEZ 0.4.1 (Wally, `Packages.testez`)
**Headless Runner**: [run-in-roblox](https://github.com/rojo-rbx/run-in-roblox) via aftman
**Linter**: Selene 0.26.1 (`selene src/`)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-04-28

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic) — TestEZ specs
  integration/    # Cross-system tests (multi-module fixtures, mock services)
  smoke/          # Critical path test list (15-minute manual gate per /smoke-check)
  evidence/       # Screenshot logs and manual test sign-off records
  runner.server.luau  # TestEZ entry script — RunContext: Server. Executes all unit + integration specs.
```

## Running Tests

### In Studio (interactive)
1. `rojo serve test.project.json` (test project — adds tests/ → ServerStorage.Tests)
2. Connect Studio to the Rojo server via the Rojo plugin
3. Press F5 to play; `ServerScriptService.TestRunner` (= `tests/runner.server.luau`) auto-runs on server boot
4. Output appears in Studio's Output window — failures print stack traces

### Headless (CI / local)

```bash
# One-time install (uses aftman.toml)
aftman install

# Install Wally packages
wally install

# Build a place file with the test runner included
rojo build test.project.json -o test-place.rbxl

# Execute headlessly via run-in-roblox (requires Studio installed locally)
run-in-roblox --place test-place.rbxl --script tests/runner.server.luau
```

Exit code 0 = all tests pass; non-zero = at least one failure.

### Production build (no tests)

```bash
# Default project file ships only src/ — tests excluded from production place
rojo build -o Game.rbxl
```

### Local lint gate

```bash
selene src/
```

Selene must pass before commit (matches CI gate).

## Test Naming Convention

- **Files**: `[system]_[feature]_test.luau`
- **`describe` block**: name the system under test (`describe("CrowdStateServer.updateCount", ...)`)
- **`it` block**: state the scenario + expected outcome (`it("clamps positive delta at 300 ceiling", ...)`)
- **Examples**:
  - `tests/unit/crowd-state-server/updatecount_clamp_test.luau`
  - `tests/unit/tick-orchestrator/cadence_test.luau`
  - `tests/integration/match-state-server/snap_to_active_call_order_test.luau`

## Story Type → Test Evidence

Per `.claude/docs/coding-standards.md` §Testing Standards:

| Story Type | Required Evidence | Location | Gate Level |
|---|---|---|---|
| Logic | Automated unit test (TestEZ) — must pass | `tests/unit/[system]/` | BLOCKING |
| Integration | Integration test OR documented playtest | `tests/integration/[system]/` | BLOCKING |
| Visual/Feel | Screenshot + lead sign-off | `tests/evidence/` OR `production/qa/evidence/` | ADVISORY |
| UI | Manual walkthrough doc OR interaction test | `tests/evidence/` OR `production/qa/evidence/` | ADVISORY |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` | ADVISORY |

## Test Determinism Rules

Per `.claude/docs/coding-standards.md`:
- No `math.random` without a seeded `Random.new(seed)` instance
- No `os.clock()` / `tick()` in assertions — inject `clockFn: () -> number` via DI per ANATOMY.md §16
- No `task.wait` / `RunService.Heartbeat:Wait` without a deterministic step harness
- Tests run independent of each other — set up + tear down own state per `describe` block

## CI

Tests run automatically on:
- Every push to `main`
- Every pull request

A failed test suite blocks merging. The CI also runs `selene src/` as a parallel lint gate.

## Authoring a New Test

1. Identify the system + feature: e.g. CSM updateCount F5 clamp
2. File path: `tests/unit/crowd-state-server/updatecount_clamp_test.luau`
3. Skeleton:
   ```lua
   --!strict
   return function()
       local ServerStorage = game:GetService("ServerStorage")
       local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

       describe("CrowdStateServer.updateCount", function()
           it("clamps positive delta at 300 ceiling", function()
               -- AC-04: count=250 + delta=+100 → 300
               CrowdStateServer.create("u1", { ... })
               local count = CrowdStateServer.updateCount("u1", 100, "Absorb")
               expect(count).to.equal(300)
           end)
       end)
   end
   ```
4. Run via `run-in-roblox` headless OR Studio + Rojo to verify pass
5. Commit alongside the implementation in the same `/dev-story` pass

## Related Reference

- `Packages.testez` — TestEZ 0.4.1 spec API
- `docs/engine-reference/roblox/VERSION.md` — engine + toolchain pins
- `.claude/docs/coding-standards.md` — full test rules
- `.claude/skills/dev-story/SKILL.md` — `/dev-story` workflow that runs tests during implementation
