# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Game Studio Agent Architecture

Indie game development managed through coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

### Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no game concept, run `/start` to begin the guided onboarding flow.

### Coordination Rules

@.claude/docs/coordination-rules.md

### Context Management

@.claude/docs/context-management.md

### Project Structure

@.claude/docs/directory-structure.md

### Technical Preferences

@.claude/docs/technical-preferences.md

## Technology Stack

- **Engine**: Roblox
- **Language**: Luau (`--!strict` at the top of every file)
- **Version Control**: Git with trunk-based development
- **Toolchain**: [aftman](https://github.com/LPGhatguy/aftman) — run `aftman install` to set up
- **Sync**: Rojo (`rojo serve` for live sync into Studio, `rojo build -o Game.rbxl` for place files)
- **Linting**: Selene (`selene src/`)
- **Packages**: Wally (`wally install` → installs to `Packages/`)
- **Testing**: Manual verification in Roblox Studio via `rojo serve` (no automated CI tests)
- **Asset-ID audit**: `bash tools/audit-asset-ids.sh` — fails with exit 1 if any `rbxassetid://N` magic string lives in a `.luau` module outside `SharedConstants/AssetId.luau` (ADR-0006 §Verification Required A). Run before every commit that touches asset references.

## Engine Version Reference

@docs/engine-reference/roblox/VERSION.md

## What This Template Provides

This is a Roblox game built on a genre-agnostic starter template. It ships ready-to-use infrastructure and leaves gameplay intentionally empty. Search for `-- TODO:` across the codebase to find every integration point.

**Included systems:**
- Session-locked player data persistence (ProfileStore)
- Soft currency (Coins) and hard currency (Robux dev products) purchases
- UI layer management (menus, HUD, zone-triggered panels)
- Client-server networking with enum-keyed remotes
- FTUE (tutorial) state machine
- Zone detection and character spawning

**Not included — integrate your own:**
- Gameplay loop and world objects
- Character abilities or movement
- Collision groups (`CollisionGroupManager` + `DescendantsCollisionGroup` pattern — see `ANATOMY.md` §11)
- `CallToAction.luau` proximity prompt + billboard system (`ComponentCreator` is included; the CTA layer on top is not — see `ANATOMY.md` §9)
- Analytics (stub files in `Analytics/` — fill in `CustomAnalytics`, `EconomyAnalytics`, `FtueAnalytics` — see `ANATOMY.md` §13)
- `TagPlayers` (tags characters with CollectionService on spawn — see `ANATOMY.md` §3)
- `CharacterPath` (character position/distance helpers — see `ANATOMY.md` §11)

## Pattern Reference — ANATOMY.md

`ANATOMY.md` in the repo root is the canonical reference for every pattern used in this codebase. It documents a complete, production-shipped Roblox game built on top of this exact template. **Always consult it before inventing a new pattern.**

Key sections to check before building anything:

| What you're building | ANATOMY.md section |
|---|---|
| Any new class or service | §16 — OOP & singleton patterns |
| Any interaction (proximity prompt, pickup, equip) | §9 — Component system & CTA |
| Any new remote event or function | §5 — Network system |
| Any new persistent data field | §7 — Player data system |
| Any new UI screen or HUD element | §8 — UI system |
| Tutorial / onboarding flow | §12 — FTUE system |
| Area-triggered behavior | §14 — Zone detection |
| Character stat (speed, jump, damage) | §4 — ValueManager |
| Economy transaction | §10 — Market & economy |
| Analytics event | §13 — Analytics system |
| Collision between player and world objects | §11 — CollisionGroupManager |

### FTUE handler contract

Each server stage handler must export `handleAsync(player: Player)`. It yields until the completion condition is met, then writes the next stage to player data and returns. Do not return anything — the stage advance is the side-effect.

```lua
-- FtueManagerServer/StageHandlers/MyStage.luau
function MyStage.handleAsync(player: Player)
    -- yield until the player completes this step
    repeat
        local who = SomeSignal:Wait()
    until who == player

    PlayerDataServer.setValue(player, PlayerDataKey.FtueStage, FtueStage.NextStage)
end
```

Each client stage handler must export `setup(player)` and `teardown(player)`. These are called by `FtueManagerClient` when `PlayerDataUpdated` fires with a matching stage value.

### ComponentCreator usage

`ComponentCreator` (in `ReplicatedStorage/Source/ComponentCreator.luau`) watches CollectionService for a tag and attaches a behavior class to every tagged instance. Call `component.new(instance)` on add, `component:destroy()` on remove. Register all listeners during your gameplay manager's `init()`/`start()`.

```lua
-- In your gameplay client init:
ComponentCreator.new(MyTag.Interactive, MyInteractiveComponent):listen()
```

The component class receives the instance in `.new()` and must implement `:destroy()`. All connections go in `self._connections`.

### Wally packages (`Packages/`)

Wally-managed dependencies live in `Packages/` (installed via `wally install`). **Prefer these over hand-rolled alternatives:**

| Package | Require path | Use for |
|---------|-------------|---------|
| Promise | `Packages.promise` | Async control flow — use instead of raw coroutines/spawn for chaining, cancellation, and error handling |
| Janitor | `Packages.janitor` | Lifecycle cleanup — manages connections, instances, and callbacks; destroy once to clean up everything |
| TestEZ | `Packages.testez` | Unit/integration testing framework |

When writing new modules, use `Promise` for any async operation and `Janitor` for managing cleanup of connections and instances. These are already available — do not reimplement their functionality.

```lua
local Janitor = require(Packages.janitor)
local Promise = require(Packages.promise)
```

### Freeze library

`ReplicatedStorage/Dependencies/Freeze` is an immutable data library (Dictionary + List modules). Use it when transforming player data or any shared state to avoid accidental mutation. Never mutate a table returned from `PlayerDataClient.getValue()` directly — use `Freeze.Dictionary.set(...)` to produce a new table and send it through the normal remote → server → `PlayerDataUpdated` flow.

## Source Layout

All source lives under `src/`. Rojo maps each subfolder to its Roblox service:

- `src/ReplicatedStorage/Source/` — shared ModuleScripts (client + server)
- `src/ServerStorage/Source/` — server-only ModuleScripts
- `src/ReplicatedFirst/Source/start.server.luau` — **client entry point** (`RunContext: Client`)
- `src/ServerScriptService/start.server.luau` — **server entry point** (`RunContext: Server`)

The `.meta.json` next to each entry script sets `RunContext` explicitly. All other logic lives in ModuleScripts required from those two files. There are no other Scripts or LocalScripts.

## Integrating Your Gameplay

### Step 1 — Add your data keys

In `SharedConstants/PlayerDataKey.luau`, add a key for each top-level value you need to persist. Then add a default value for it in `ServerStorage/Source/DefaultPlayerData.luau`.

### Step 2 — Add your item categories

If your game has purchasable items, add categories to `SharedConstants/ItemCategory.luau`, create matching folders under `ReplicatedStorage/Instances/`, and register them in `SharedConstants/ContainerByCategory.luau`. The `Market` module handles purchase validation automatically for any registered category.

### Step 3 — Hook into the entry points

Both entry scripts have clearly marked `-- TODO:` blocks:

- **Client** (`ReplicatedFirst/Source/start.server.luau`): one block after character loads for gameplay init, one after the loading screen hides for post-load systems.
- **Server** (`ServerScriptService/start.server.luau`): one block for global systems, one inside `onPlayerAdded` for per-player setup, one inside `PlayerRemoving` for per-player cleanup.

### Step 4 — Add remote events

Add new event names to `Network/RemoteName/RemoteEventName.luau`. They are automatically created as `RemoteEvent` instances at startup — no other wiring needed.

### Step 5 — Add per-player server objects

Add fields to `PlayerObjectsContainer` (`ServerStorage/Source/PlayerObjectsContainer.luau`) for any server-side objects you need to share across modules (e.g. a per-player gameplay manager instance). The file has TODO comments showing the exact pattern.

### Step 6 — Configure FTUE stages

Rename `Stage1`/`Stage2` in `SharedConstants/FtueStage.luau` to match your onboarding steps. Fill in `handleAsync(player)` in each `FtueManagerServer/StageHandlers/` file — yield until the player completes the step, then call `PlayerDataServer.setValue(player, PlayerDataKey.FtueStage, FtueStage.NextStage)`. Fill in `setup(player)`/`teardown(player)` in the matching `FtueManagerClient/StageHandlers/` files with any hints or highlights. See `ANATOMY.md` §12 for the full handler contract and real stage examples.

### Step 7 — Configure zones

Place a `Part` in Workspace and tag it with `ZonePartTag`. Set its `ZoneId` attribute to a value from `ZoneIdTag.luau`. The server-side `ZoneHandler` will automatically apply that tag to players inside the part. To auto-open a UI panel when entering a zone, add a mapping to `UILayerIdByZoneId.luau`.

### Step 8 — Add UI layers

Create a module in `UI/UILayers/`, add its ID to `UILayerId.luau`, and call `UIHandler.registerLayer()` in the layer's `setup()` method. Use `UILayerType.Menu` (one at a time, hides HUD) or `UILayerType.HeadsUpDisplay` (coexists with gameplay). See `UIExampleHud.luau` for a minimal working example. Build the panel from components in `UI/UIComponents/` or clone prefabs from `ReplicatedStorage/Instances/GuiPrefabs/`.

### Step 9 — Customize character spawning

Edit `CharacterSpawner.spawnCharacter()` in `ServerStorage/Source/CharacterSpawner.luau` to teleport new characters to your desired spawn location after `player:LoadCharacter()`.

## Architecture

### Two-entry-point model

Everything boots from exactly two scripts. The client orchestrates: loading screen → network → player data → character → **your gameplay** → UI → FTUE → hide loading screen. The server orchestrates: network → DataStore → **your global systems** → per-`PlayerAdded`: load data → **your per-player systems** → FTUE → spawn character.

### Shared vs server-only code

`ReplicatedStorage/Source/` is accessible to both client and server. `ServerStorage/Source/` is server-only. The client must never `require` from `ServerStorage`. All shared enums, constants, network definitions, and utilities live in `ReplicatedStorage/Source/`.

### Network layer

All remotes go through `Network/init.luau` — never reference RemoteEvent instances directly by path or string literal.

```lua
-- Correct
Network.fireServer(RemoteEventName.MyEvent, payload)
Network.connectEvent(RemoteEventName.MyEvent, function(player, payload) end)

-- Never
game.ReplicatedStorage.RemoteEvents.MyEvent:FireServer(payload)
```

### Player data flow

Server is the source of truth. Client holds a read-only cache in `PlayerData/Client.luau`, updated via the `PlayerDataUpdated` remote. All mutations flow: client fires remote → server validates and mutates → server fires `PlayerDataUpdated` → client cache refreshes. Never write to the client cache directly.

DataStore access goes through ProfileStore (`ReplicatedStorage/Dependencies/ProfileStore.luau`) via `PlayerDataServer`. ProfileStore handles session locking, auto-saving, retry logic, and `BindToClose` automatically. Never call `DataStoreService` directly.

### Currency

- **Soft currency (Coins):** granted/deducted via `PlayerDataServer.updateValue(player, PlayerDataKey.Coins, ...)` on the server. The `Market` module handles all purchase deductions automatically.
- **Hard currency (Robux):** dev products are registered in `Utility/registerDevProducts.luau`. `ReceiptProcessor` handles the `ProcessReceipt` callback with duplicate-prevention and save-before-confirm guarantees. Grant coins (or items) inside the product callback registered there.

### FTUE system

`FtueStage` is a string stored in `PlayerDataKey.FtueStage`. On `PlayerAdded`, `FtueManagerServer` reads the current stage and runs its handler's `handleAsync(player)` which yields until the stage completion condition is met, then returns the next stage. The client `FtueManagerClient` watches `PlayerDataUpdated` for stage changes and calls `setup()`/`teardown()` on the matching client handler.

### ValueManager for numeric stats

Character stats modified by multiple systems simultaneously (walk speed, jump height) use `ValueManager`. Each system applies its own named multiplier or offset; the composed value is computed automatically. Never set `Humanoid.WalkSpeed` directly — use `LocalWalkJumpManager.getSpeedValueManager():setMultiplier(key, value)`.

## Conventions

### Naming

- Yielding functions are suffixed `Async`: `startClientAsync()`, `requestItemPurchaseAsync()`
- Private instance fields are `_prefixed`: `self._connections`, `self._instance`
- Module-level constants are `UPPER_SNAKE_CASE`
- All enum values accessed by module, never as raw strings

### No magic strings — ever

| What | Where |
|------|-------|
| Instance attribute names | `SharedConstants/Attribute.luau` |
| CollectionService tags | `SharedConstants/CollectionServiceTag/` |
| Player data keys | `SharedConstants/PlayerDataKey.luau` |
| Remote names | `Network/RemoteName/` |
| Item categories | `SharedConstants/ItemCategory.luau` |
| UI layer IDs | `SharedConstants/UILayerId.luau` |
| Zone IDs | `SharedConstants/CollectionServiceTag/ZoneIdTag.luau` |

### OOP class pattern

```lua
--!strict
local MyClass = {}
MyClass.__index = MyClass

export type ClassType = typeof(setmetatable({} :: { _connections: Connections.ClassType }, MyClass))

function MyClass.new(): ClassType
    local self = setmetatable({} :: any, MyClass)
    self._connections = Connections.new()
    return self
end

function MyClass.destroy(self: ClassType)
    self._connections:disconnect()
end

return MyClass
```

Every `RBXScriptConnection` must be added to `self._connections`. `destroy()` must call `self._connections:disconnect()`. Export `ClassType` on every class.

### File layout

- `--!strict` at the top of every Luau file
- Folder-as-module uses `init.luau` as entry (e.g. `Network/init.luau`, `FtueManagerServer/init.luau`)
- Side-specific variants named `Server.luau` / `Client.luau` in their respective service directories

## Coding & Design Standards

@.claude/docs/coding-standards.md
