# Plant — Roblox Farming Simulator: Complete Game Anatomy

> **Genre:** Farming Simulator
> **Engine:** Roblox (Rojo 7.5.1, Wally 0.3.2, Selene 0.26.1)
> **Total Luau Files:** ~414 | **Entry Points:** 2 (one client, one server)
>
> This document describes the architecture, patterns, and conventions of a production
> Roblox game. It is intended as a reference for understanding best practices.

---

## Table of Contents

1. [Project Configuration](#1-project-configuration)
2. [Folder Structure](#2-folder-structure)
3. [Entry Points & Boot Sequence](#3-entry-points--boot-sequence)
4. [Core Utilities](#4-core-utilities)
5. [Network System](#5-network-system)
6. [Farm System](#6-farm-system)
7. [Player Data System](#7-player-data-system)
8. [UI System](#8-ui-system)
9. [Component System](#9-component-system)
10. [Market & Economy](#10-market--economy)
11. [Character & Movement](#11-character--movement)
12. [FTUE (Tutorial) System](#12-ftue-tutorial-system)
13. [Analytics System](#13-analytics-system)
14. [Zone Detection](#14-zone-detection)
15. [Naming Conventions](#15-naming-conventions)
16. [Code Patterns Reference](#16-code-patterns-reference)
17. [Key Files Quick Reference](#17-key-files-quick-reference)

---

## 1. Project Configuration

### `default.project.json`
- **Project Name**: "Platformer" (internal name, game-facing name differs)
- **Lighting**: Future technology, Soft style, 14:30 time-of-day
- **Physics**: Gravity 160, walk speed 22, jump height 8, camera zoom 8–128
- **Streaming**: Enabled with `Opportunistic` behavior, `PauseOutsideLoadedArea` integrity
- **Luau**: New type solver enabled (`UseNewLuauTypeSolver`)
- **Character**: `CharacterAutoLoads = false` (manual spawn control)

### `aftman.toml`
| Tool | Version | Purpose |
|------|---------|---------|
| `rojo` | 7.5.1-uplift.syncback.rc.21 | Project build & Roblox Studio sync |
| `selene` | 0.26.1 | Static Lua linter |
| `wally` | 0.3.2 | Package manager |

---

## 2. Folder Structure

### `src/` Top-Level Services

```
src/
├── Lighting/                   # Post-processing effect instances
│   ├── Atmosphere.model.json
│   ├── Bloom.model.json
│   ├── ColorGrading.rbxm
│   ├── DepthOfField.model.json
│   ├── Sky.model.json
│   └── SunRays.model.json
├── MaterialService/            # Material overrides
├── SoundService/
│   └── SoundEffects/           # Named sound instances (model.json)
│       ├── Button, Coins, Harvest, Plant
│       ├── Purchase, RemoveObject, Water
│       ├── WagonPlace, WagonPull
├── ReplicatedFirst/            # Runs before any other script
├── ReplicatedStorage/          # Shared client+server code & prefabs
├── ServerScriptService/        # Server-only entry point
├── ServerStorage/              # Server-only code
├── StarterGui/                 # GUI containers
├── StarterPack/                # Starting items
├── StarterPlayer/              # Character & player scripts
└── Workspace/
    ├── Farms/
    └── World/
        ├── MarketArea/Vendors/
        └── Environment/GreenHouseRef1-4/
```

### `ReplicatedFirst/`

```
ReplicatedFirst/
├── Source/
│   ├── start.server.luau          ← CLIENT LocalScript entry point
│   ├── LoadingScreen.luau         ← Loading screen controller
│   └── Utility/
│       └── waitForGameLoadedAsync.luau
└── Instances/
    └── LoadingScreenPrefab        ← GUI prefab for loading screen
```

### `ReplicatedStorage/` (Full Tree)

```
ReplicatedStorage/
├── Instances/                     # Asset prefabs (cloned at runtime)
│   ├── CoinBundles/
│   ├── GuiPrefabs/
│   ├── Particles/
│   ├── Plants/
│   ├── Pots/
│   ├── Seeds/
│   ├── Tables/
│   ├── Wagons/
│   └── MenuBlurPrefab.model.json
│
├── Dependencies/
│   ├── Freeze/                    # Functional programming library
│   │   ├── Dictionary/            # Immutable dict operations
│   │   └── List/                  # Immutable list operations
│   └── t/                         # Runtime type-checking library
│
└── Source/
    ├── Signal.luau
    ├── ValueManager.luau
    ├── Connections.luau
    ├── ThreadQueue.luau
    ├── TweenGroup.luau            ← NEW
    ├── CallToAction.luau
    ├── ComponentCreator.luau
    ├── CharacterLoadedWrapper.luau
    ├── CharacterPath.luau
    ├── CharacterSprint.luau
    ├── LocalWalkJumpManager.luau
    ├── MarketClient.luau          ← NEW
    ├── InputCategorizer.luau
    ├── BeamBetween.luau
    ├── ViewingMenuEffect.luau
    ├── DevProductPriceList.luau
    │
    ├── Network/
    │   ├── init.luau
    │   ├── RemoteFolderName.luau
    │   └── RemoteName/
    │       ├── RemoteEventName.luau
    │       └── RemoteFunctionName.luau
    │
    ├── Farm/
    │   ├── FarmConstants.luau
    │   ├── CtaDataType.luau
    │   ├── FarmManagerClient.luau
    │   ├── Components/
    │   │   ├── LocalCta.luau
    │   │   ├── PlantStageTimer.luau
    │   │   ├── PullingWagon.luau
    │   │   ├── Holding.luau
    │   │   ├── AnimatedShopSymbol.luau
    │   │   └── AnimatedRoosterNPC.luau
    │   └── CtaDataModules/
    │       ├── CanHarvest/
    │       ├── CanPlant/
    │       ├── CanPlace/
    │       ├── CanPlacePot/
    │       ├── CanPlaceTable/
    │       ├── CanRemove/
    │       └── NeedsWater/
    │           (each: init.luau + shouldEnable.luau + promptDataFunctions.luau)
    │
    ├── UI/
    │   ├── UIHandler.luau
    │   ├── UISetup.luau
    │   ├── UIZoneHandler.luau
    │   ├── GamepadMouseDisabler.luau
    │   ├── InventoryAnimator.luau
    │   ├── CoinAnimator.luau
    │   ├── ProjectileIconQueue.luau
    │   ├── UIComponents/
    │   │   ├── Button.luau
    │   │   ├── CloseButton.luau
    │   │   ├── ListSelector.luau
    │   │   ├── InventoryListSelector.luau
    │   │   ├── ShopListSelector.luau
    │   │   ├── ListItem.luau
    │   │   ├── Sidebar.luau
    │   │   ├── SidebarActionButton.luau
    │   │   ├── GamepadButtonPrompt.luau
    │   │   ├── ProjectileIcon.luau
    │   │   ├── ModelViewport.luau
    │   │   └── UIHighlight.luau
    │   └── UILayers/
    │       ├── UISeedMarket.luau
    │       ├── UIPlantSeed.luau
    │       ├── UIPlacePot.luau
    │       ├── UIGardenStore.luau
    │       ├── UIBuyCoins.luau
    │       ├── UIInventory.luau
    │       ├── UIInventoryButton.luau
    │       ├── UICoinIndicator.luau
    │       ├── UIDataErrorNotice.luau
    │       └── UIResetDataButton.luau
    │
    ├── SharedConstants/
    │   ├── Attribute.luau
    │   ├── PlayerDataKey.luau
    │   ├── ItemCategory.luau
    │   ├── UILayerType.luau
    │   ├── UILayerId.luau
    │   ├── UILayerIdByZoneId.luau
    │   ├── ColorTheme.luau
    │   ├── ImageId.luau
    │   ├── Keybind.luau
    │   ├── InputCategory.luau
    │   ├── PlayerFacingString.luau
    │   ├── OperationOrder.luau
    │   ├── FtueStage.luau
    │   ├── ContainerByCategory.luau
    │   ├── RequestFailureReason/
    │   │   └── ItemPurchaseFailureReason.luau
    │   └── CollectionServiceTag/
    │       ├── TagEnumType.luau
    │       ├── PlantTag.luau
    │       ├── PotTag.luau
    │       ├── WagonTag.luau
    │       ├── CharacterTag.luau
    │       ├── PlayerTag.luau
    │       ├── AnimationTag.luau
    │       ├── ZoneIdTag.luau
    │       ├── PlacementTag.luau
    │       ├── ZonePartTag.luau
    │       ├── DoNotWeldTag.luau
    │       └── VisibleWhenVendorEnabledTag.luau
    │
    ├── FtueManagerClient/
    │   ├── init.luau
    │   └── StageHandlers/
    │       ├── InFarmFtueStage.luau
    │       ├── PurchasingPotFtueStage.luau
    │       ├── PurchasingSeedFtueStage.luau
    │       ├── ReturningToFarmFtueStage.luau
    │       └── SellingPlantFtueStage.luau
    │
    ├── PlayerData/
    │   ├── Client.luau
    │   └── PlayerDataErrorType.luau  ← NEW
    │
    └── Utility/
        ├── getInstance.luau
        ├── getAttribute.luau
        ├── formatTime.luau
        ├── setInterval.luau
        ├── connectAll.luau
        ├── waitForChildOfClassAsync.luau
        ├── waitForChildWithAttributeAsync.luau
        ├── safePlayerAdded.luau
        ├── Farm/
        │   ├── getFarmOwnerIdFromInstance.luau
        │   └── getWagonModelFromOwnerId.luau
        ├── PlayerData/
        │   └── countInventoryItemsInCategory.luau
        ├── Network/
        │   ├── createRemotesFolders.luau
        │   └── waitForAllRemotesAsync.luau
        └── UI/
```

### `ServerStorage/Source/` (Full Tree)

```
ServerStorage/Source/
├── Farm/
│   ├── FarmManagerServer.luau
│   ├── Farm.luau
│   ├── Table.luau
│   ├── Pot.luau
│   ├── Plant.luau
│   ├── PlaceableArea.luau
│   ├── DefaultFarmData.luau
│   ├── PlayerPickupHandler.luau
│   ├── createHarvestedPlantModel.luau
│   └── Wagon/
│       ├── init.luau
│       ├── ContentsManager.luau
│       ├── PullingManager.luau
│       └── FollowingAttachment.luau
│
├── FtueManagerServer/
│   ├── init.luau
│   └── StageHandlers/
│       ├── InFarmFtueStage.luau
│       ├── PurchasingPotFtueStage.luau
│       ├── PurchasingSeedFtueStage.luau
│       ├── ReturningToFarmFtueStage.luau
│       └── SellingPlantFtueStage.luau
│
├── PlayerData/
│   ├── Server.luau
│   ├── DefaultPlayerData.luau
│   ├── DataStoreWrapper.luau
│   ├── SessionLockedDataStoreWrapper.luau
│   ├── PlayerDataErrorType.luau
│   └── Readme.luau
│
├── Analytics/
│   ├── CustomAnalytics.luau
│   ├── CustomAnalyticsEvent.luau
│   ├── EconomyAnalytics.luau
│   └── FtueAnalytics.luau
│
├── Market.luau
├── ZoneHandler.luau
├── CharacterSpawner.luau
├── TagPlayers.luau
├── PlayerObjectsContainer.luau
├── CollisionGroupManager.luau
├── CollisionGroup.luau
├── DescendantsCollisionGroup.luau
├── ReceiptProcessor.luau
├── PickupPrefabsById.luau
│
└── Utility/
    ├── registerDevProducts.luau
    ├── getMaxRequestTime.luau
    ├── Particles/
    │   ├── playSparklingStar.luau
    │   └── playWaterDropletsAsync.luau
    └── PlayerData/
```

---

## 3. Entry Points & Boot Sequence

### Client Boot (`ReplicatedFirst/Source/start.server.luau`)

> Type: LocalScript (runs in ReplicatedFirst — before any other script)

```
1. LoadingScreen.show()
2. waitForGameLoadedAsync()         -- wait for ContentProvider
3. Network.startClientAsync()       -- wait for all RemoteEvents/Functions to exist
4. PlayerData.Client.loadAsync()    -- wait for PlayerDataLoaded event from server
5. CharacterLoadedWrapper.init()    -- robust character state tracking
6. LocalWalkJumpManager.init()      -- movement control setup
7. FarmManagerClient.init()         -- register all component listeners
8. UISetup.init()                   -- instantiate all UI layers
9. FtueManagerClient.init()         -- activate current tutorial stage
10. CharacterSprint.init()          -- sprint mechanics
11. DevProductPriceList.init()      -- fetch dev product prices
12. LoadingScreen.hide()
```

### Server Boot (`ServerScriptService/start.server.luau`)

> Type: Script (runs in ServerScriptService)

```
1. Network.startServer()            -- create RemoteEvents/Functions folders
2. CollisionGroupManager.init()     -- register PhysicsService groups
3. registerDevProducts()            -- bind ReceiptProcessor callbacks
4. PlayerData.Server.init()         -- setup DataStore, auto-save timer (180s)
5. FarmManagerServer.init()         -- prepare farm slot allocations
6. CharacterSpawner.init()          -- override default respawn behavior
7. TagPlayers.init()                -- tag new/existing players with CollectionService
8. ZoneHandler.init()               -- start zone spatial queries

-- Per-player on PlayerAdded:
9.  PlayerObjectsContainer.register(player)
10. FarmManagerServer.createFarm(player)
11. PlayerData.Server.loadAsync(player)  -- load DataStore, fire PlayerDataLoaded
12. CharacterSpawner.spawnInFarm(player)
```

---

## 4. Core Utilities

### `Signal.luau`

Custom event system that replaces `BindableEvent`. Yield-safe via coroutine scheduling.

```lua
local signal = Signal.new()
local conn = signal:Connect(function(value) print(value) end)
signal:Fire("hello")        -- fires all listeners
local result = signal:Wait() -- yields until next Fire
conn:Disconnect()
signal:DisconnectAll()
```

**Key design choices:**
- Uses coroutine.wrap instead of coroutine.resume to propagate errors correctly
- Connections stored as linked list for O(1) disconnect
- `Wait()` creates a one-shot connection internally
- Does not use `BindableEvent` (avoids serialization cost and memory overhead)

---

### `ValueManager.luau`

Manages a numeric value that can have multiple independent multipliers and offsets stacked on it. Used for character stats, economy multipliers, and any value that multiple systems modify simultaneously.

```lua
local speed = ValueManager.new(baseValue, operationOrder)
speed:setMultiplier("sprint", 1.5)
speed:setMultiplier("slowDebuff", 0.8)
speed:setOffset("boots", 5)
local final = speed:getValue()
-- result: baseValue * 1.5 * 0.8 + 5   (OffsetThenMultiply order)
```

**Operation orders:**
- `OperationOrder.OffsetThenMultiply`: `(base + offsets) × multipliers`
- `OperationOrder.MultiplyThenOffset`: `(base × multipliers) + offsets`

**Key feature:** Can be bound to a Roblox instance property — when the computed value changes, the property is updated automatically. Used to drive `Humanoid.WalkSpeed` and `Humanoid.JumpHeight`.

---

### `Connections.luau`

Maid pattern — collects RBXScriptConnections (and any object with a `Disconnect` or `destroy` method) for bulk cleanup.

```lua
local conns = Connections.new()
conns:add(RunService.Heartbeat:Connect(onHeartbeat))
conns:add(Players.PlayerAdded:Connect(onPlayerAdded))
conns:add(someSignal:Connect(onEvent))

-- On cleanup:
conns:disconnect()   -- disconnects all at once
```

**Why this matters:** Every class that connects to events stores those connections in a `Connections` instance. `destroy()` calls `conns:disconnect()`, guaranteeing no memory leaks regardless of how many listeners were registered.

---

### `ThreadQueue.luau`

Task queue and rate limiter. Prevents concurrent execution of operations that must be serialized (e.g. DataStore writes, purchase processing).

```lua
local queue = ThreadQueue.new(maxConcurrent, maxLength)
queue:submitAsync(function()
  -- this runs when it reaches the front of the queue
  DataStore:SetAsync(key, value)
end)
queue:skipToLastEnqueued()  -- drops intermediate tasks (for UI debounce)
```

**Key uses:**
- `DataStoreWrapper`: one queue per DataStore key, prevents concurrent writes
- UI interactions: debounce rapid button clicks
- Purchase processing: serialize per-player purchases

---

### `TweenGroup.luau`

Lightweight wrapper that treats multiple `Tween` objects as one unit.

```lua
local group = TweenGroup.new(tweenA, tweenB, tweenC)
group:play()    -- plays all tweens simultaneously
group:pause()   -- pauses all
group:cancel()  -- cancels all
```

**When to use:** When animating multiple properties of different instances that should start, pause, and cancel together — e.g. a UI panel that slides in while a backdrop fades in. Avoids tracking separate tween references across a class.

**Limitation by design:** No `PlaybackState` or `Completed` event. Callers that need completion callbacks should use `task.delay` or `Tween.Completed` on one of the tweens directly.

---

### `BeamBetween.luau`

Creates a visual `Beam` between two world positions by placing `Attachment` instances at each end. Used for VFX like water streams or energy connections.

---

### `ViewingMenuEffect.luau`

Applies a blur/darken effect to the viewport when a menu is open. Controlled by `UIHandler` visibility signals.

---

## 5. Network System

### Architecture

All remote communication is routed through `Network/init.luau`. Raw `RemoteEvent`/`RemoteFunction` instances are **never** required directly — all access goes through this module with enum-keyed names.

```
Network (init.luau)
├── Server API: startServer, connectEvent, bindFunction, fireClient, fireAllClients
└── Client API: startClientAsync, fireServer, invokeServerAsync
```

### Remote Name Enums

```lua
-- RemoteEventName.luau
return {
  PlayerDataLoaded    = "PlayerDataLoaded",
  PlayerDataUpdated   = "PlayerDataUpdated",
  PlayerDataSaved     = "PlayerDataSaved",
  PlantWatered        = "PlantWatered",
  PlantHarvested      = "PlantHarvested",
  PlantPlaced         = "PlantPlaced",
  RequestPlaceObject  = "RequestPlaceObject",
  RequestRemoveObject = "RequestRemoveObject",
  RequestPullWagon    = "RequestPullWagon",
  RequestPlantSeed    = "RequestPlantSeed",
  ResetData           = "ResetData",   -- Studio-only
}

-- RemoteFunctionName.luau
return {
  RequestItemPurchase = "RequestItemPurchase",
}
```

### Usage Pattern

```lua
-- Server: register
Network.connectEvent(RemoteEventName.PlantHarvested, function(player, plantId: string)
  -- t library validates args before this runs
  FarmManagerServer.harvestPlant(player, plantId)
end)

Network.bindFunction(RemoteFunctionName.RequestItemPurchase,
  function(player, itemId, category, amount)
    return Market.requestPurchase(player, itemId, category, amount)
    -- returns: success: boolean, failureReason: string?
  end
)

-- Client: fire event
Network.fireServer(RemoteEventName.RequestPlantSeed, seedId, potId)

-- Client: invoke function (yields)
local success, failureReason = Network.invokeServerAsync(
  RemoteFunctionName.RequestItemPurchase,
  itemId, itemCategory, amount
)
```

### Remote Event Reference

| Name | Direction | Trigger | Payload |
|------|-----------|---------|---------|
| `PlayerDataLoaded` | S → C | Data loaded from DataStore | `playerData` |
| `PlayerDataUpdated` | S → C | Any data mutation | `newData` |
| `PlayerDataSaved` | S → C | DataStore write confirmed | — |
| `PlantWatered` | C → S | Player waters plant | `plantId` |
| `PlantHarvested` | C → S | Player harvests plant | `plantId` |
| `PlantPlaced` | C → S | Plant dropped into wagon | `plantId` |
| `RequestPlaceObject` | C → S | Place pot/table in farm | `itemId, category, position` |
| `RequestRemoveObject` | C → S | Remove pot/table | `objectId` |
| `RequestPullWagon` | C → S | Start/stop pulling wagon | `pulling: boolean` |
| `RequestPlantSeed` | C → S | Plant seed into pot | `seedId, potId` |
| `ResetData` | C → S | Wipe player data (Studio) | — |

| Name | Returns | Purpose |
|------|---------|---------|
| `RequestItemPurchase` | `success, failureReason?` | Buy seeds/pots/tables from market |

---

## 6. Farm System

### Object Hierarchy

```
Farm (Farm.luau)
├── Wagon (Wagon/init.luau)
│   ├── ContentsManager (ContentsManager.luau)   -- plant storage
│   └── PullingManager (PullingManager.luau)     -- physics attachment
│       └── FollowingAttachment (FollowingAttachment.luau)
├── Table × N (Table.luau)
│   └── Pot × 3 (Pot.luau)
│       └── Plant (Plant.luau)               -- lifecycle: seed → growing → harvestable
└── PlaceableArea × N (PlaceableArea.luau)   -- empty slot overlays
```

### `Farm.luau`

Owns the data lifecycle for one player's farm. Deserializes `FarmData` into live instances, and serializes live state back to `FarmData` for persistence.

```lua
local farm = Farm.new(farmData, farmModel, player)
farm.changed:Connect(function(newFarmData) ... end)  -- fires on any mutation
farm:destroy()  -- cleans up all child instances
```

**Responsibilities:**
- Clone table/pot/wagon models from `ReplicatedStorage.Instances`
- Position objects based on attachment points in the farm model
- Open/close farm entrance doors (used in FTUE)
- Fire `changed` signal whenever state mutates (triggers DataStore save)

### `FarmManagerServer.luau`

Allocates one `Farm` per player. Maintains `userId → Farm` and `userId → farmIndex` maps. Handles farm positioning (farms are arranged in a grid using slot attachments in Workspace).

```lua
FarmManagerServer.createFarm(player)      -- on PlayerAdded
FarmManagerServer.destroyFarm(player)     -- on PlayerRemoving
FarmManagerServer.getFarm(player): Farm   -- getter for other systems
```

**Character spawning:** Teleports character to the farm's spawn point, not the default Roblox spawn location.

### `Plant.luau`

Core growth state machine. A plant cycles through numbered stages (`CurrentStage` attribute), each with a configurable growth duration.

```
Stage 0 (just planted)
  → [timer or watering]
Stage 1 (sprouting)
  → [timer or watering]
...
Stage N (harvestable) → CollectionService: CanHarvest tag added
```

**Watering mechanic:** Watering pauses the growth timer for the current stage. The plant advances to the next stage only after it has been watered once per stage. After watering, the normal timer resumes.

**Time persistence:** Stores `FinishesGrowingAt` (server timestamp) in data. On load, calculates `timeRemaining = FinishesGrowingAt - Workspace:GetServerTimeNow()` to resume the correct position in the timer — accurate across server restarts.

**CollectionService tags applied by Plant:**
- `PlantTag.Growing` — plant is actively growing (shows timer UI)
- `PlantTag.NeedsWater` — awaiting water before advancing stage
- `PlantTag.CanHarvest` — plant is fully grown, ready to pick

### `Pot.luau`

Container that holds one `Plant`. Handles:
- `plantSeed(seedId, player)` — validates player has seed in inventory, creates Plant
- `harvest(player)` — calls `PlayerPickupHandler` to give plant to player, or grants seed if player can't hold
- `remove(player)` — returns pot to player inventory, fires `removeRequested`

**CollectionService tags applied by Pot:**
- `PotTag.CanPlant` — pot is empty, player can plant a seed
- `PotTag.CanRemove` — pot can be removed from table

### `Table.luau`

Holds up to 3 `Pot` instances at named attachment points. Manages `PlaceableArea` overlays for empty spots. Fires `changed` signal when any pot is added/removed.

### `DefaultFarmData.luau`

Initial state for a new player's farm:
- 3 table spots (only spot 3 is pre-populated with a table and pot)
- `BasicWagon` in the wagon slot
- No held items, no inventory

### `PlaceableArea.luau`

Semi-transparent overlay shown on empty placement spots (table slots or pot slots). When triggered:
1. Validates player ownership
2. Validates item is in player inventory
3. Deducts item from inventory
4. Fires `placeRequested` signal → `Table` / `Farm` creates the object

### `PlayerPickupHandler.luau`

Manages the one item a player can hold at a time (harvested plants). Attaches the held item model to the character's hand `Attachment` via a `WeldConstraint`. Persists the `HeldItemId` in `FarmData` so the item survives respawns.

```lua
handler:setHeldItem(plantId)    -- attach model to hand
handler:clearHeldItem()         -- remove model, clear data
handler:getHeldItemId(): string? -- query current held item
```

**Network ownership:** Sets `BasePart:SetNetworkOwner(player)` on the held model so the client has authority over its physics.

### `createHarvestedPlantModel.luau`

Factory function that produces a "pickup" model from a plant prefab:
1. Clone the full plant prefab from `ReplicatedStorage.Instances.Plants`
2. Remove the growth stages folder (only final appearance needed)
3. Extract the `Harvested` model and weld all parts together
4. Attach to `PickupAttachment` on the plant's primary part

### `Wagon/init.luau`, `ContentsManager.luau`, `PullingManager.luau`

The wagon is a dual-mode object:

**Storage mode (in farm):** Anchored, accepts harvested plants dropped into it. `ContentsManager` stores an array of `plantId` strings. Tags `WagonFull` when capacity is reached.

**Pull mode (portable):** `PullingManager` attaches the wagon behind the player using `AlignPosition` + `AlignOrientation` constraints. The `FollowingAttachment` raycasts to the ground each heartbeat to keep the wagon level on terrain.

**Selling:** When the wagon enters the `MarketArea` zone (detected by `ZoneHandler`), `ContentsManager` automatically fires a remote to trigger server-side selling.

### `FollowingAttachment.luau`

Attachment that follows a character at a fixed distance, snapping to the ground via raycasting. Updates every `Heartbeat`. Used to position the wagon behind the player while pulling.

---

## 7. Player Data System

### Schema

```lua
-- PlayerDataKey.luau
{
  Coins      = "Coins",        -- number: current currency
  FtueStage  = "FtueStage",    -- number: 1–5 tutorial progress
  Farm       = "Farm",         -- FarmData: serialized farm state
  Inventory  = "Inventory",    -- { [itemId: string]: count: number }
}
```

### `Server.luau` (439 lines)

The authoritative data store. Loaded once per player, kept in memory, auto-saved every 180 seconds and on `PlayerRemoving`.

```lua
Server.getValue(player, key)
Server.setValue(player, key, value)
Server.updateValue(player, key, updater: (old) -> new)
Server.removeValue(player, key)
```

**Private values:** Some keys are marked private (not replicated). Public keys are included in the `PlayerDataUpdated` remote payload.

**Error states:** If DataStore load fails or the session is locked, sets an error flag and fires `PlayerDataLoaded` with an error type. The client shows `UIDataErrorNotice` instead of the game.

### `DataStoreWrapper.luau`

Low-level retry layer over Roblox's `DataStoreService`.

```lua
wrapper:getAsync(key)
wrapper:setAsync(key, value)
wrapper:updateAsync(key, transformer)
```

**Retry logic:** Exponential backoff via `ThreadQueue`. Per-key request queuing — two concurrent `setAsync` calls on the same key are serialized, not raced. Returns `(success, result, keyInfo)` tuples.

### `SessionLockedDataStoreWrapper.luau`

Adds pessimistic locking on top of `DataStoreWrapper`. Prevents two servers from writing the same player's data simultaneously (e.g. when a player rapidly rejoins).

```lua
-- On load:
-- 1. Read current lock (UUID + expiry)
-- 2. If lock exists and not expired: abort with SessionLocked error
-- 3. If no lock or expired: write our UUID as new lock
-- 4. Proceed to read data

-- On save/release:
-- 1. Verify lock UUID still matches ours
-- 2. If match: write data and clear lock atomically
-- 3. If mismatch: our session was evicted, abort save
```

**Lock expiry:** Locks have a configurable TTL. If the server crashes, the lock expires and the next server can take over.

### `PlayerDataErrorType.luau`

```lua
{
  DataStoreError  = "DataStoreError",   -- DataStore request failed after retries
  SessionLocked   = "SessionLocked",    -- Another server holds the lock
}
```

Used by `UIDataErrorNotice` to show different messages to the player depending on what went wrong.

### `DefaultPlayerData.luau`

```lua
{
  Coins     = 0,
  FtueStage = 1,           -- starts at first tutorial step
  Farm      = DefaultFarmData,
  Inventory = {},
}
```

### Client Cache (`PlayerData/Client.luau`)

Read-only mirror of server data on the client. Updated by `PlayerDataUpdated` events. Exposes a `changed` signal.

```lua
PlayerDataClient.getValue(key)          -- read cached value
PlayerDataClient.changed:Connect(...)   -- subscribe to any change
```

Clients **never** write to this directly — all mutations go through remotes to the server.

---

## 8. UI System

### Layer Architecture

```
UIHandler (state machine)
├── Tracks one active Menu layer at a time (queue-based)
├── HUD layers auto-hide when any Menu is visible
├── Fires visibilityChanged signal for animation callbacks
└── registerLayer(id, type, guiInstance)

UISetup (bootstrap)
└── Constructs all UILayer singletons, connects zone triggers

UILayers/ (singleton screens)
└── Composed from UIComponents/ (reusable building blocks)
```

### `UIHandler.luau`

```lua
UIHandler.registerLayer(UILayerId.SeedMarket, UILayerType.Menu, screenGui)
UIHandler.show(UILayerId.SeedMarket)   -- pushes to menu queue
UIHandler.hide(UILayerId.SeedMarket)   -- pops from queue
UIHandler.isVisible(UILayerId.SeedMarket): boolean
UIHandler.visibilityChanged:Connect(function(layerId, visible) end)
```

**Layer types:**
- `Menu` — fullscreen panels; only one visible at a time, HUD hides when any menu is open
- `HeadsUpDisplay` — overlays that coexist with gameplay; hidden while menus are open

### `UIZoneHandler.luau`

Listens to `ZoneIdTag` additions/removals on the local player and automatically shows/hides UI layers mapped in `UILayerIdByZoneId`. For example, entering the `MarketArea` zone automatically opens the market panel.

### UILayer Catalogue

| Module | Type | Opens When |
|--------|------|-----------|
| `UICoinIndicator` | HUD | Always visible |
| `UIInventoryButton` | HUD | Always visible |
| `UIInventory` | Menu | Inventory button pressed |
| `UISeedMarket` | Menu | Player enters market zone |
| `UIPlantSeed` | Menu | Player triggers CanPlant CTA |
| `UIPlacePot` | Menu | Player triggers CanPlacePot CTA |
| `UIGardenStore` | Menu | Player enters store zone |
| `UIBuyCoins` | Menu | Buy coins button pressed |
| `UIDataErrorNotice` | Menu | PlayerData load error |
| `UIResetDataButton` | HUD | Studio only |

### UIComponent Catalogue

| Module | Purpose |
|--------|---------|
| `Button` | Standard button with hover/press states |
| `CloseButton` | Dedicated close button (X icon) |
| `ListSelector` | Scrolling list with selection state |
| `InventoryListSelector` | ListSelector variant showing item counts |
| `ShopListSelector` | ListSelector variant showing prices |
| `ListItem` | Single row in a list |
| `Sidebar` | Side panel with action buttons |
| `SidebarActionButton` | Individual button within Sidebar |
| `GamepadButtonPrompt` | Gamepad button icon (e.g. A, B, X, Y) |
| `ProjectileIcon` | Animated icon that flies from world to HUD |
| `ModelViewport` | Renders a 3D model inside a ScreenGui |
| `UIHighlight` | SelectionBox-style highlight on a BasePart |

### `CoinAnimator.luau` & `ProjectileIconQueue.luau`

When coins are earned, a `ProjectileIcon` flies from the world position of the sale to the coin indicator in the HUD. `ProjectileIconQueue` batches rapid coin grants and staggers the animations to prevent visual overload.

---

## 9. Component System

### How It Works

`ComponentCreator` watches CollectionService for tagged instances and attaches behavior classes to them. This decouples behavior from instance hierarchy — any system can tag/untag an instance to add/remove functionality.

```lua
-- Register: "for every instance tagged PlantTag.Growing, create a PlantStageTimer"
ComponentCreator.new(PlantTag.Growing, PlantStageTimer):listen()

-- PlantStageTimer receives the instance in its constructor
-- PlantStageTimer:destroy() is called when the tag is removed
```

### Component Lifecycle

```
CollectionService adds tag
        ↓
ComponentCreator calls Component.new(instance, ...extraParams)
        ↓
Component sets up its behavior (UI, tweens, connections)
        ↓
Tag removed or instance destroyed
        ↓
ComponentCreator calls component:destroy()
        ↓
Component cleans up all connections, tweens, instances
```

### Active Components

| Tag | Component | Behavior Added |
|-----|-----------|----------------|
| `PlantTag.Growing` | `PlantStageTimer` | Countdown timer BillboardGui on plant |
| `CharacterTag.PullingWagon` | `PullingWagon` | Disables jump while pulling |
| `CharacterTag.Holding` | `Holding` | (TODO: holding animation) |
| `AnimationTag.AnimatedShopSymbol` | `AnimatedShopSymbol` | Floating up/down sine animation |
| `AnimationTag.AnimatedRoosterNPC` | `AnimatedRoosterNPC` | Squash/stretch idle animation |
| Each CTA tag | `LocalCta` | Proximity prompt + BillboardGui icon |

### `PlantStageTimer.luau`

Creates a BillboardGui countdown timer above a growing plant. Uses `Workspace:GetServerTimeNow()` (not `os.time()`) so the display is accurate across server migration and latency.

```lua
-- Updates every second:
local remaining = plant:GetAttribute(Attribute.FinishesGrowingAt)
                  - Workspace:GetServerTimeNow()
timerLabel.Text = formatTime(remaining)
progressBar:TweenSize(...)
```

### `AnimatedRoosterNPC.luau`

Animates rooster NPCs using `TweenService` on `Motor6D` CFrames rather than `AnimationTrack`. This is necessary because Roblox animation tracks only play for animations uploaded by the place owner. Each rooster instance gets slightly randomized loop timing to avoid synchronized movement.

### CTA (Call-to-Action) System

Every player-facing interaction is a plug-and-play data module with three lifecycle hooks:

```
CtaDataModules/CanHarvest/
├── init.luau               → { icon, keybind, debounceTime, promptText, highlightColor }
├── shouldEnable.luau       → function(player, instance): boolean
└── promptDataFunctions.luau → { onTriggered = function(player, instance) ... end }
```

**`shouldEnable` for CanHarvest checks:**
1. Plant has `CanHarvest` tag
2. Player is not already holding something
3. Wagon is not full
4. No menus currently open
5. Character is alive

**`onTriggered` for CanHarvest:**
1. Play harvest sound
2. Disable prompt (1 second debounce)
3. `Network.fireServer(RemoteEventName.PlantHarvested, plantId)`

`LocalCta` wraps `CallToAction` with an ownership check — only creates CTAs for instances that belong to the local player's farm.

`CallToAction` creates the visual UI:
- `BillboardGui` with animated icon (size pulse tween)
- `ProximityPrompt` with configurable keybind
- `SelectionBox` highlight on hover
- 1-second debounce after trigger

---

## 10. Market & Economy

### `Market.luau` (Server)

Authoritative economy handler. Two operations:

**Selling plants:**
```lua
Market.sellWagonContents(player, plantIds: {string})
-- Reads HarvestValue attribute from each plant model
-- Sums total, adds to player Coins
-- Logs to EconomyAnalytics
-- Fires plantsSold signal (used by FTUE)
```

**Buying items:**
```lua
Market.requestPurchase(player, itemId, category, amount)
  → success: boolean, failureReason: ItemPurchaseFailureReason?
-- Validates: itemId exists, player has enough coins, inventory not full
-- Deducts cost from Coins, adds item to Inventory
-- Logs to EconomyAnalytics
-- Fires itemsPurchased signal (used by FTUE)
```

**Failure reasons (`ItemPurchaseFailureReason`):**
- `NotEnoughCoins`
- `ItemNotFound`
- `InventoryFull`
- `InvalidCategory`

### `MarketClient.luau`

Client-side gateway that wraps the network call and normalizes the dual-layer success/failure result:

```lua
-- invokeServerAsync returns: (pcallSuccess, serverSuccess, serverFailureReason)
-- MarketClient normalizes this to: (overallSuccess, anyFailureReason)

local success, failureReason = MarketClient.requestItemPurchaseAsync(
  itemId, itemCategory, amount
)
-- overallSuccess = pcallSuccess AND serverSuccess
-- failureReason = pcall error message OR server rejection reason
```

**Why this matters:** Without this wrapper, every call site would need to handle two separate failure modes (network failure vs. server rejection). `MarketClient` collapses them into one `(success, reason)` pair, matching idiomatic Roblox async patterns.

### `ReceiptProcessor.luau`

Handles Robux developer product purchases (`ProcessReceipt` callback).

**Duplicate prevention:**
- Stores last 100 receipt IDs per player in their DataStore
- If receipt ID already exists → return `PurchaseGranted` immediately (idempotent)

**Safety guarantee:**
- Only returns `PurchaseGranted` after the DataStore save is confirmed
- If data fails to load before timeout → return `NotProcessedYet` (retry next session)

**Coin bundle flow:**
1. `ReceiptProcessor` receives callback
2. Looks up product ID in `registerDevProducts` callback table
3. Callback adds `CoinBundleSize` attribute value to `Coins`
4. Logs to `EconomyAnalytics` as IAP source
5. DataStore saves
6. Returns `PurchaseGranted`

### `DevProductPriceList.luau` (Client)

Fetches current Robux prices for all registered dev products from `MarketplaceService` on client init. Used by `UIBuyCoins` to display accurate prices without hardcoding them.

### `PickupPrefabsById.luau` (Server)

Generates a runtime cache mapping `plantId → harvested pickup model` at server start. Clones each plant prefab from `ReplicatedStorage.Instances.Plants` and calls `createHarvestedPlantModel`. Avoids per-harvest model creation overhead.

---

## 11. Character & Movement

### `CharacterLoadedWrapper.luau`

Robust character state tracking that waits for all required character parts before signaling "loaded". Guards against Roblox's non-atomic character loading.

**"Loaded" conditions (all must be true):**
1. Character is in `Workspace`
2. `PrimaryPart` is set
3. `Humanoid` exists
4. `Humanoid.RootPart` is set
5. `Humanoid.Health > 0`

```lua
local wrapper = CharacterLoadedWrapper.new(player)
wrapper.loaded:Connect(function(character) ... end)
wrapper.died:Connect(function() ... end)
wrapper:isLoaded(): boolean
wrapper:destroy()
```

### `LocalWalkJumpManager.luau`

Manages `Humanoid.WalkSpeed` and `Humanoid.JumpHeight` via `ValueManager` instances. Allows multiple systems to apply modifiers without conflict:

```lua
LocalWalkJumpManager.getSpeedValueManager():setMultiplier("sprint", 1.6)
LocalWalkJumpManager.getJumpValueManager():setMultiplier("pullingWagon", 0)
-- WalkSpeed = base * 1.6, JumpHeight = base * 0 = 0
```

### `CharacterSprint.luau`

Detects sprint input (hold key) and sets a multiplier on the speed `ValueManager`. Removes multiplier on key release or character death.

### `CharacterPath.luau`

Client-side character position utility. Provides helpers for getting character root position, direction, and distance checks used by the CTA system.

### `PullingWagon` component

When `CharacterTag.PullingWagon` is added to the character, sets jump `ValueManager` multiplier to 0 (disables jumping). Removes multiplier on `destroy`.

### `CollisionGroupManager.luau` & `DescendantsCollisionGroup.luau`

Registers two `PhysicsService` collision groups:

| Group | Collides With |
|-------|-------------|
| `Character` | World, Wagons: NO |
| `Wagon` | World, Characters: NO |

`DescendantsCollisionGroup` applies a group to all `BasePart` descendants of an instance and keeps it synchronized as parts are added/removed. Stores the original group in `Attribute.OriginalCollisionGroup` for restoration on cleanup.

**Why wagons don't collide with characters:** Allows the player to walk through their wagon while pulling it, preventing physics jitter.

### `CharacterSpawner.luau`

Since `Players.CharacterAutoLoads = false`, this module handles all spawning:
- On `PlayerAdded`: stores a "died" connection that triggers respawn after `Players.RespawnTime`
- `spawnInFarm(player)`: teleports spawned character to the player's farm spawn attachment
- On `PlayerRemoving`: cleans up the died connection

---

## 12. FTUE (Tutorial) System

The tutorial is a persistent state machine stored in `PlayerDataKey.FtueStage`. It survives disconnects and is resumable.

### Stage Enum (`FtueStage.luau`)

```lua
{
  InFarm            = 1,  -- initial stage, guides to farm
  PurchasingSeed    = 2,  -- buy a seed from market
  PurchasingPot     = 3,  -- buy a pot from store
  SellingPlant      = 4,  -- sell first harvest
  ReturningToFarm   = 5,  -- bring wagon back to farm
}
```

### Server Orchestration (`FtueManagerServer/init.luau`)

```lua
-- On player data loaded:
local currentStage = Server.getValue(player, PlayerDataKey.FtueStage)
StageHandlers[currentStage]:handleAsync(player)
-- Each handler awaits its completion condition, then increments FtueStage
```

### Stage Handler Pattern

Each stage handler is a module with one async function:

```lua
-- Example: SellingPlantFtueStage.luau
function SellingPlantFtueStage.handleAsync(player)
  -- Wait for market sale
  repeat
    local seller, _ = Market.plantsSold:Wait()
  until seller == player

  -- Advance to next stage
  Server.setValue(player, PlayerDataKey.FtueStage, FtueStage.PurchasingSeed)
end
```

**Stage completion conditions:**

| Stage | Server waits for... |
|-------|-------------------|
| `InFarm` | Wagon has contents (full loop: plant → water → grow → harvest → wagon) |
| `SellingPlant` | `Market.plantsSold` fires for this player |
| `PurchasingSeed` | `Market.itemsPurchased` fires with `ItemCategory.Seeds` |
| `PurchasingPot` | `Market.itemsPurchased` fires with `ItemCategory.Pots` |
| `ReturningToFarm` | `CharacterTag.PullingWagon` removed while character is in farm zone |

### Client FTUE (`FtueManagerClient/init.luau`)

Mirrors the server stages on the client. Stage handlers show highlight effects, arrows, and UI callouts to guide the player. Client stage handlers listen to `PlayerDataClient.changed` to activate/deactivate alongside server progression.

---

## 13. Analytics System

### `CustomAnalytics.luau`

Logs core gameplay loop events via `AnalyticsService` (Creator Hub dashboard). All calls use `task.spawn` to never block gameplay.

```lua
CustomAnalytics.logEvent(player, CustomAnalyticsEvent.PlantHarvested)
CustomAnalytics.logEvent(player, CustomAnalyticsEvent.HarvestSold)
```

### `CustomAnalyticsEvent.luau`

```lua
{
  HarvestSold    = "HarvestSold",
  SeedPlanted    = "SeedPlanted",
  PlantWatered   = "PlantWatered",
  PlantHarvested = "PlantHarvested",
}
```

### `EconomyAnalytics.luau`

Tracks money flow using Roblox's economy analytics API:

```lua
-- Sources (coins in):
EconomyAnalytics.logSource(player, amount, "HarvestSale")
EconomyAnalytics.logSource(player, amount, "DevProductBundle")

-- Sinks (coins out):
EconomyAnalytics.logSink(player, amount, "ItemPurchase")
```

Used by `Market.luau` and `ReceiptProcessor.luau` to record every transaction.

### `FtueAnalytics.luau`

Tracks tutorial funnel with numeric stage IDs for drop-off analysis.

---

## 14. Zone Detection

### `ZoneHandler.luau` (Server)

Detects when players enter/exit named zones using spatial queries.

```lua
-- Every 0.5 seconds per player:
local partsInZone = Workspace:GetPartsInPart(zonePart, overlapParams)
-- If player's HumanoidRootPart is in result:
CollectionService:AddTag(character, ZoneIdTag[zonePart:GetAttribute(Attribute.ZoneId)])
-- Else:
CollectionService:RemoveTag(character, ...)
```

**Zones in the game:**
- `MarketArea` — triggers wagon auto-sell, opens market UI
- Farm zone (per-player) — affects wagon pulling behavior, FTUE

### `UIZoneHandler.luau` (Client)

Listens to `ZoneIdTag` changes on the local character and triggers UI layer changes:

```lua
-- ZoneIdTag.MarketArea added → UIHandler.show(UILayerIdByZoneId.MarketArea)
-- ZoneIdTag.MarketArea removed → UIHandler.hide(UILayerIdByZoneId.MarketArea)
```

---

## 15. Naming Conventions

### File Naming

| Pattern | Convention | Examples |
|---------|-----------|---------|
| Module files | `PascalCase.luau` | `CallToAction.luau`, `ValueManager.luau` |
| Entry scripts | `start.server.luau` | (exactly this name, always) |
| Script type suffix | `.server.luau` = Script, `.client.luau` = LocalScript | — |
| Folder-modules | `init.luau` inside folder | `Network/init.luau`, `Wagon/init.luau` |
| Type definition files | `SomethingType.luau` | `CtaDataType.luau`, `TagEnumType.luau` |
| Enum/constant files | `SomethingName.luau` | `RemoteEventName.luau`, `PlayerDataKey.luau` |
| Error type files | `SomethingErrorType.luau` | `PlayerDataErrorType.luau` |
| Default data files | `DefaultSomething.luau` | `DefaultPlayerData.luau`, `DefaultFarmData.luau` |

### Variable Naming

| Convention | Scope | Example |
|-----------|-------|---------|
| `PascalCase` | Required modules, class names | `local Signal = require(...)` |
| `camelCase` | Local variables, parameters | `local farmContainer, plantId` |
| `self._camelCase` | Private instance fields | `self._instance`, `self._connections` |
| `UPPER_SNAKE_CASE` | Module-level constants | `MAX_INTERACTION_DISTANCE = 15` |

### Function Naming

| Convention | Usage | Examples |
|-----------|-------|---------|
| `camelCase` | All functions and methods | `getValue()`, `fireServer()` |
| `_camelCase` | Private methods (convention only) | `_onChanged()`, `_listenForDeath()` |
| `Verb + Noun` | Standard pattern | `getWagonModelFromOwnerId()`, `setHeldItem()` |
| `Async` suffix | Yielding functions | `startClientAsync()`, `requestItemPurchaseAsync()` |
| `create` prefix | Factory functions | `createHarvestedPlantModel()` |
| `get` prefix | Pure getters | `getFarm()`, `getHeldItemId()` |
| `on` prefix | Event callbacks | `_onPlayerAdded()`, `_onDied()` |

### Enum / Constant Modules

All enums are plain tables returning string values. Never inline strings where an enum exists.

```lua
-- Correct:
Network.fireServer(RemoteEventName.PlantHarvested, plantId)
plant:SetAttribute(Attribute.CurrentStage, 2)
CollectionService:AddTag(instance, PlantTag.Growing)

-- Never:
Network.fireServer("PlantHarvested", plantId)
plant:SetAttribute("CurrentStage", 2)
CollectionService:AddTag(instance, "Growing")
```

### UI Naming

| Pattern | Convention | Examples |
|---------|-----------|---------|
| Layer modules | `UI` prefix | `UISeedMarket`, `UIInventory` |
| Component modules | Descriptive noun | `Button`, `ListSelector`, `Sidebar` |
| Layer IDs | `UILayerId.Name` | `UILayerId.SeedMarket` |
| Layer types | `UILayerType.Menu` or `.HeadsUpDisplay` | — |

---

## 16. Code Patterns Reference

### OOP Class Pattern

All classes follow this exact structure:

```lua
--!strict

local MyClass = {}
MyClass.__index = MyClass

export type ClassType = typeof(setmetatable(
  {} :: {
    _instance: Instance,
    _connections: Connections.ClassType,
    _value: number,
  },
  MyClass
))

function MyClass.new(instance: Instance): ClassType
  local self = setmetatable({} :: any, MyClass)
  self._instance = instance
  self._connections = Connections.new()
  self._value = 0
  return self
end

function MyClass.doSomething(self: ClassType)
  -- method body
end

function MyClass.destroy(self: ClassType)
  self._connections:disconnect()
end

return MyClass
```

**Key rules:**
- `export type ClassType` on every class for autocomplete and type safety
- Private fields always `_prefixed`
- `destroy()` always calls `self._connections:disconnect()`
- Methods use explicit `self: ClassType` parameter (not `:` syntax at definition)
- `--!strict` at top of every file

### Singleton / Service Pattern

```lua
--!strict

local MyService = {}

local _initialized = false
local _someState: string

function MyService.init()
  assert(not _initialized, "MyService already initialized")
  _initialized = true
  _someState = "ready"
end

function MyService.getSomeState(): string
  return _someState
end

return MyService
```

### Signal-Based Communication

Prefer `Signal` over `BindableEvent` for internal communication:

```lua
-- In a class:
self.changed = Signal.new()
self.changed:Fire(newData)

-- Consumer:
local conn = farm.changed:Connect(function(data)
  PlayerData.setValue(player, PlayerDataKey.Farm, data)
end)
conns:add(conn)
```

### Network Request with Error Handling

```lua
-- Client side (MarketClient pattern):
function MarketClient.requestItemPurchaseAsync(itemId, category, amount)
  local networkSuccess, serverSuccess, failureReason =
    Network.invokeServerAsync(RemoteFunctionName.RequestItemPurchase, itemId, category, amount)

  local overallSuccess = networkSuccess and serverSuccess :: boolean
  local eitherFailureReason = if networkSuccess
    then failureReason
    else tostring(serverSuccess) :: string?

  return overallSuccess, eitherFailureReason
end
```

### Tag-Based Component Registration

```lua
-- FarmManagerClient.init():
ComponentCreator.new(PlantTag.Growing, PlantStageTimer):listen()
ComponentCreator.new(WagonTag.PullingWagon, PullingWagon):listen()
ComponentCreator.new(AnimationTag.AnimatedRoosterNPC, AnimatedRoosterNPC):listen()

-- Each CtaDataModule:
for _, ctaModule in ipairs(CtaDataModules) do
  ComponentCreator.new(ctaModule.tag, LocalCta, ctaModule.ctaData):listen()
end
```

### Server-Time Countdown

```lua
-- On plant created (server):
local finishTime = Workspace:GetServerTimeNow() + growthDuration
plant:SetAttribute(Attribute.FinishesGrowingAt, finishTime)

-- On timer display (client, PlantStageTimer):
RunService.Heartbeat:Connect(function()
  local remaining = plant:GetAttribute(Attribute.FinishesGrowingAt)
                    - Workspace:GetServerTimeNow()
  label.Text = formatTime(math.max(0, remaining))
end)
```

### DataStore with Session Locking

```lua
-- Load sequence:
local locked = SessionLockedDataStoreWrapper.tryAcquireLock(userId)
if not locked then
  return nil, PlayerDataErrorType.SessionLocked
end

local success, data = DataStoreWrapper.getAsync(userId)
if not success then
  return nil, PlayerDataErrorType.DataStoreError
end

return data or DefaultPlayerData, nil
```

### Physics-Based Particle Lifetime

```lua
-- playWaterDropletsAsync.luau: calculate particle lifetime from plant height
-- Using projectile motion: h = v0*t + 0.5*g*t^2
local height = topAttachment.WorldPosition.Y - bottomAttachment.WorldPosition.Y
local lifetime = math.sqrt(2 * height / workspace.Gravity)
particles.Lifetime = NumberRange.new(lifetime)
particles:Emit(count)
task.wait(lifetime + 0.1)
particles.Enabled = false
```

---

## 17. Key Files Quick Reference

| Purpose | Path |
|---------|------|
| **Client entry point** | `ReplicatedFirst/Source/start.server.luau` |
| **Server entry point** | `ServerScriptService/start.server.luau` |
| **Network hub** | `ReplicatedStorage/Source/Network/init.luau` |
| **Remote event names** | `Network/RemoteName/RemoteEventName.luau` |
| **Remote function names** | `Network/RemoteName/RemoteFunctionName.luau` |
| **Custom signal** | `ReplicatedStorage/Source/Signal.luau` |
| **Value with multipliers** | `ReplicatedStorage/Source/ValueManager.luau` |
| **Connection cleanup** | `ReplicatedStorage/Source/Connections.luau` |
| **Task queue** | `ReplicatedStorage/Source/ThreadQueue.luau` |
| **Multi-tween control** | `ReplicatedStorage/Source/TweenGroup.luau` |
| **Component lifecycle** | `ReplicatedStorage/Source/ComponentCreator.luau` |
| **CTA prompt+billboard** | `ReplicatedStorage/Source/CallToAction.luau` |
| **CTA with ownership** | `ReplicatedStorage/Source/Farm/Components/LocalCta.luau` |
| **Character state** | `ReplicatedStorage/Source/CharacterLoadedWrapper.luau` |
| **Speed/jump stats** | `ReplicatedStorage/Source/LocalWalkJumpManager.luau` |
| **Market (client)** | `ReplicatedStorage/Source/MarketClient.luau` |
| **UI state machine** | `ReplicatedStorage/Source/UI/UIHandler.luau` |
| **UI bootstrap** | `ReplicatedStorage/Source/UI/UISetup.luau` |
| **Zone → UI triggers** | `ReplicatedStorage/Source/UI/UIZoneHandler.luau` |
| **All attribute names** | `ReplicatedStorage/Source/SharedConstants/Attribute.luau` |
| **All tag names** | `ReplicatedStorage/Source/SharedConstants/CollectionServiceTag/` |
| **Player data keys** | `ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau` |
| **Item categories** | `ReplicatedStorage/Source/SharedConstants/ItemCategory.luau` |
| **Tutorial stages** | `ReplicatedStorage/Source/SharedConstants/FtueStage.luau` |
| **Player data (client)** | `ReplicatedStorage/Source/PlayerData/Client.luau` |
| **Player data errors** | `ReplicatedStorage/Source/PlayerData/PlayerDataErrorType.luau` |
| **Farm hierarchy root** | `ServerStorage/Source/Farm/Farm.luau` |
| **Plant growth logic** | `ServerStorage/Source/Farm/Plant.luau` |
| **Pot container** | `ServerStorage/Source/Farm/Pot.luau` |
| **Table container** | `ServerStorage/Source/Farm/Table.luau` |
| **Wagon main** | `ServerStorage/Source/Farm/Wagon/init.luau` |
| **Wagon physics** | `ServerStorage/Source/Farm/Wagon/PullingManager.luau` |
| **Wagon storage** | `ServerStorage/Source/Farm/Wagon/ContentsManager.luau` |
| **Ground-following** | `ServerStorage/Source/Farm/Wagon/FollowingAttachment.luau` |
| **Pickup item model** | `ServerStorage/Source/Farm/PlayerPickupHandler.luau` |
| **Plant pickup factory** | `ServerStorage/Source/Farm/createHarvestedPlantModel.luau` |
| **Player data (server)** | `ServerStorage/Source/PlayerData/Server.luau` |
| **DataStore retries** | `ServerStorage/Source/PlayerData/DataStoreWrapper.luau` |
| **Session locking** | `ServerStorage/Source/PlayerData/SessionLockedDataStoreWrapper.luau` |
| **Default player data** | `ServerStorage/Source/PlayerData/DefaultPlayerData.luau` |
| **Default farm data** | `ServerStorage/Source/Farm/DefaultFarmData.luau` |
| **Market (server)** | `ServerStorage/Source/Market.luau` |
| **Receipt processing** | `ServerStorage/Source/ReceiptProcessor.luau` |
| **Zone detection** | `ServerStorage/Source/ZoneHandler.luau` |
| **Collision setup** | `ServerStorage/Source/CollisionGroupManager.luau` |
| **Collision per-instance** | `ServerStorage/Source/DescendantsCollisionGroup.luau` |
| **Character respawn** | `ServerStorage/Source/CharacterSpawner.luau` |
| **Player object cache** | `ServerStorage/Source/PlayerObjectsContainer.luau` |
| **Economy analytics** | `ServerStorage/Source/Analytics/EconomyAnalytics.luau` |
| **Gameplay analytics** | `ServerStorage/Source/Analytics/CustomAnalytics.luau` |
| **FTUE analytics** | `ServerStorage/Source/Analytics/FtueAnalytics.luau` |
| **Water VFX** | `ServerStorage/Source/Utility/Particles/playWaterDropletsAsync.luau` |
| **Sparkle VFX** | `ServerStorage/Source/Utility/Particles/playSparklingStar.luau` |
