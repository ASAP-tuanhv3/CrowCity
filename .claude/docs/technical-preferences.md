# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Roblox
- **Language**: Luau (strict mode — `--!strict` at top of every file)
- **Rendering**: Roblox rendering engine (not configurable)
- **Physics**: Roblox physics engine (not configurable)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC, Mobile, Console (Xbox)
- **Input Methods**: Keyboard/Mouse, Touch, Gamepad
- **Primary Input**: Mixed (Roblox cross-platform)
- **Gamepad Support**: Full (Roblox handles natively)
- **Touch Support**: Full (Roblox handles natively)
- **Platform Notes**: Roblox manages cross-platform input abstraction. Use `UserInputService` and `ContextActionService` for custom input handling.

## Naming Conventions

- **Classes**: `PascalCase` (e.g., `MyClass`)
- **Variables**: `camelCase` (e.g., `playerData`)
- **Signals/Events**: `PascalCase` enum keys (e.g., `RemoteEventName.PlayerDied`)
- **Files**: `PascalCase.luau` (e.g., `PlayerDataServer.luau`)
- **Scenes/Prefabs**: N/A — Roblox uses Instances in `ReplicatedStorage/Instances/`
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.67ms
- **Draw Calls**: Managed by Roblox engine
- **Memory Ceiling**: Managed by Roblox engine (watch for memory leaks via Developer Console)

## Testing

- **Framework**: Manual verification in Roblox Studio (TestEZ available via Wally for unit tests)
- **Minimum Coverage**: N/A — no automated CI pipeline
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->

- Magic strings (use enum modules — see `SharedConstants/`)
- Direct `DataStoreService` calls (use `PlayerDataServer` via ProfileStore)
- Direct `RemoteEvent` access by path (use `Network` module)
- Direct `Humanoid.WalkSpeed` writes (use `ValueManager`)
- Client-side data mutation (all writes go through server)
- `require` from `ServerStorage` on client

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->

- **ProfileStore** — `ReplicatedStorage/Dependencies/ProfileStore.luau` (player data persistence)
- **Freeze** — `ReplicatedStorage/Dependencies/Freeze/` (immutable data operations)
- **Promise** — `Packages.promise` (async control flow)
- **Janitor** — `Packages.janitor` (lifecycle cleanup)
- **TestEZ** — `Packages.testez` (unit testing)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->

- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: No engine-specific specialist — Roblox is not Godot/Unity/Unreal. Use `gameplay-programmer` or `lead-programmer`.
- **Language/Code Specialist**: N/A (Luau is Roblox-specific; use `gameplay-programmer`)
- **Shader Specialist**: N/A (Roblox doesn't expose custom shaders)
- **UI Specialist**: `ui-programmer` (for UI system work)
- **Additional Specialists**: None
- **Routing Notes**: Route all engine questions to `gameplay-programmer` or `lead-programmer`. For UI, use `ui-programmer`.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.luau` (game code) | `gameplay-programmer` |
| Shader / material files | N/A (Roblox manages rendering) |
| UI / screen files | `ui-programmer` |
| `.rbxl` / `.rbxlx` (place files) | N/A (binary, managed by Studio) |
| Native extension / plugin files | N/A |
| General architecture review | `lead-programmer` |
