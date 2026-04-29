# Coding Standards

- `--!strict` at the top of every Luau file
- Every `RBXScriptConnection` must be tracked in `self._connections` and cleaned up in `destroy()`
- All game code must include doc comments on public APIs
- Every system must have a corresponding architecture decision record in `docs/architecture/`
- Gameplay values must be data-driven (external config or attributes), never hardcoded magic numbers
- All public methods must be unit-testable (dependency injection over singletons where practical)
- All enum values accessed by module, never as raw strings (see `SharedConstants/`)
- Commits must reference the relevant design document or task ID
- **Verification-driven development**: Write tests first when adding gameplay systems. For UI changes, verify with screenshots in Roblox Studio. Compare expected output to actual output before marking work complete. Every implementation should have a way to prove it works.

# Design Document Standards

- All design docs use Markdown
- Each mechanic has a dedicated document in `design/gdd/`
- Documents must include these 8 required sections:
  1. **Overview** — one-paragraph summary
  2. **Player Fantasy** — intended feeling and experience
  3. **Detailed Rules** — unambiguous mechanics
  4. **Formulas** — all math defined with variables
  5. **Edge Cases** — unusual situations handled
  6. **Dependencies** — other systems listed
  7. **Tuning Knobs** — configurable values identified
  8. **Acceptance Criteria** — testable success conditions
- Balance values must link to their source formula or rationale

# Testing Standards

## Test Evidence by Story Type

All stories must have appropriate test evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Gate Level |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test (TestEZ) — must pass | `tests/unit/[system]/` | BLOCKING |
| **Integration** (multi-system) | Integration test OR documented playtest | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel** (animation, VFX, feel) | Screenshot + lead sign-off | `production/qa/evidence/` | ADVISORY |
| **UI** (menus, HUD, screens) | Manual walkthrough doc OR interaction test | `production/qa/evidence/` | ADVISORY |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

## Automated Test Rules

- **Naming**: `[system]_[feature].spec.luau` for files; `test_[scenario]_[expected]` for functions
- **Determinism**: Tests must produce the same result every run — no random seeds, no time-dependent assertions
- **Isolation**: Each test sets up and tears down its own state; tests must not depend on execution order
- **No hardcoded data**: Test fixtures use constant files or factory functions, not inline magic numbers
  (exception: boundary value tests where the exact number IS the point)
- **Independence**: Unit tests do not call external APIs, DataStores, or HttpService — use dependency injection or mocks

## Running Tests

- **TestEZ** is available via Wally (`Packages.testez`)
- Run tests in Roblox Studio: require the test runner script, or use Rojo + a test place
- Test files live in `tests/unit/[system]/` and `tests/integration/[system]/`

## CI/CD Rules

- Automated test suite runs on every push to main and every PR (when CI is configured)
- No merge if tests fail — tests are a blocking gate in CI
- Never disable or skip failing tests to make CI pass — fix the underlying issue
- Engine-specific CI commands:
  - **Roblox**: `rojo build -o test-place.rbxl && run-in-roblox --place test-place.rbxl --script tests/runner.luau` (requires [run-in-roblox](https://github.com/rojo-rbx/run-in-roblox) or equivalent headless runner)
  - **Linting**: `selene src/` (runs on every PR as a blocking gate)

## What NOT to Automate

- Visual fidelity (shader output, VFX appearance, animation curves)
- "Feel" qualities (input responsiveness, perceived weight, timing)
- Platform-specific rendering (test on target hardware — mobile vs PC vs console)
- Full gameplay sessions (covered by playtesting, not automation)
