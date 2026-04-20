# ProfileStore Reference

*Last verified: 2026-04-20*

Project-specific ProfileStore guidance. The library is vendored at `src/ReplicatedStorage/Dependencies/ProfileStore.luau` and wrapped by `PlayerDataServer`.

## Why ProfileStore

Roblox's raw `DataStoreService` is low-level: no session locking, no automatic retry, no `BindToClose` integration, and easy to corrupt with duplicate loads. ProfileStore handles all of this.

Project rule (`CLAUDE.md`): **never call `DataStoreService` directly**. All persistent data flows through `PlayerDataServer` → ProfileStore.

## Core Guarantees

- **Session locking** — only one server can hold a profile at a time; rejoin elsewhere waits for the lock to release
- **Automatic retry** with exponential backoff on transient DataStore failures
- **Automatic save-on-close** via `BindToClose` integration
- **Reconciliation** — missing keys auto-populate from template on load
- **Schema migration hooks** — `ProfileStore:OnProfileVersionUpgrade` for data format changes

## Project Pattern

```lua
-- On PlayerAdded (server entry script)
local profile = PlayerDataServer.loadProfileAsync(player)
if not profile then
    player:Kick("Data load failed — please rejoin")
    return
end

-- Read
local coins: number = PlayerDataClient.getValue(player, PlayerDataKey.Coins)

-- Write (server-only)
PlayerDataServer.updateValue(player, PlayerDataKey.Coins, function(current)
    return current + 100
end)

-- PlayerDataUpdated remote fires automatically after server mutation
```

Client reads come from `PlayerDataClient` (read-only cache populated via `PlayerDataUpdated`). Never mutate client cache directly.

## Default Template

Project template defined in `src/ServerStorage/Source/DefaultPlayerData.luau`. Adding a new persistent field:

1. Add key enum to `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau`
2. Add default value + type to `DefaultPlayerData.luau`
3. (Optional) Add migration handler if upgrading existing saves

ProfileStore reconciles missing keys on load — existing players get the default when they next join.

## Immutability via Freeze

Never mutate the table returned by `PlayerDataClient.getValue()`. Use `Freeze.Dictionary.set` to produce a new table:

```lua
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)

-- Bad — mutates cached state
local inventory = PlayerDataClient.getValue(player, PlayerDataKey.Inventory)
inventory.relics[relicId] = true  -- DON'T

-- Good — produce new state, send through server
local current = PlayerDataClient.getValue(player, PlayerDataKey.Inventory)
local next = Freeze.Dictionary.setIn(current, { "relics", relicId }, true)
-- Fire remote to server, which validates and calls PlayerDataServer.setValue
```

## Failure Modes

| Failure | Handler behavior | What you do |
|---------|------------------|-------------|
| DataStore throttled | Auto-retry with backoff | Nothing — transparent |
| Session lock held by another server | Wait configured timeout, then take lock | If profile is `nil` after timeout → kick player |
| Profile load returns `nil` | Studio play, or DataStore is down | Kick player with clear message; do not spawn |
| Corrupted schema | Reconcile from template | Loss of corrupted fields; log for review |

## Crowdsmith-Relevant Keys

Planned for concept (add during `/design-system`):

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `Coins` | `number` | 0 | Soft currency — already present in template |
| `OwnedSkins` | `{ [string]: true }` | `{}` | Unlocked skin IDs |
| `SelectedSkin` | `string` | `"default"` | Currently equipped skin |
| `LifetimeAbsorbs` | `number` | 0 | Statistic for leaderboards/achievements |
| `LifetimeWins` | `number` | 0 | Statistic |
| `DailyQuestState` | `table` | `{}` | Per-day quest progress, reset at midnight UTC |
| `LastDailyResetTime` | `number` | 0 | `os.time()` of last reset for quest expiry |

Relics do NOT persist (Pillar 3 — round purity). No `OwnedRelics` key ever.

## What NOT to Store

- Per-round state (relics, chest-open history, in-round size) — lives in memory on the server, never saved
- Computed/derived values (total power, rank tier) — compute on read from persisted primitives
- Large binary blobs — DataStore has per-key size limits (~4 MB, practically keep under 256 KB); use keys across multiple fields

## Sources

- Vendored library: `src/ReplicatedStorage/Dependencies/ProfileStore.luau` (read source for authoritative API)
- [ProfileStore README on creator forum](https://devforum.roblox.com/t/save-your-player-data-with-profilestore/2825719)
- [DataStoreService limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
