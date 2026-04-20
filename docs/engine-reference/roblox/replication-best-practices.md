# Replication Best Practices

*Last verified: 2026-04-20*

Project-specific replication guidance. Aligned with the `Network` module wrapper enforced by `CLAUDE.md` and `ANATOMY.md §5`. Directly relevant to the Crowdsmith concept's crowd-sync risk.

## Remote Types — When to Use Which

| Remote type | Direction | Yields? | Delivery | Use for |
|-------------|-----------|---------|----------|---------|
| `RemoteEvent` | C→S or S→C | No | Reliable, ordered | Commands, state changes, events that must arrive |
| `UnreliableRemoteEvent` | C→S or S→C | No | Unreliable, possibly out-of-order | High-frequency non-critical updates (positions, rotations) |
| `RemoteFunction` | C↔S | Yes (caller blocks) | Reliable | Query-response where caller needs the result; use sparingly |

**Project rule**: prefer `RemoteEvent` for almost everything. Use `RemoteFunction` only for genuinely request-response semantics (e.g., validate a purchase and return result). `UnreliableRemoteEvent` is for continuous replication only.

## Project Wrapper — `Network` Module

All remotes are accessed through `src/ReplicatedStorage/Source/Network/init.luau`. Never reference `RemoteEvent` instances by path or string literal.

```lua
-- Correct
Network.fireServer(RemoteEventName.AbsorbRequest, payload)
Network.connectEvent(RemoteEventName.AbsorbRequest, function(player, payload) end)

-- Never
game.ReplicatedStorage.RemoteEvents.AbsorbRequest:FireServer(payload)
```

New remotes: add to `Network/RemoteName/RemoteEventName.luau`. Auto-created at startup.

## Placement Rules

- Remotes created by the `Network` module live under `ReplicatedStorage` so both client and server can see them
- Values passed across the boundary must be replicable — a `ServerStorage` descendant becomes `nil` on the client
- Do not pass `Instance` references that do not exist on the receiver's side
- Tables pass by value (deep-copied across the boundary); avoid passing mutable shared state expecting reference semantics

## Security — Server Is Authoritative

Every remote handler on the server must validate:

1. **Identity** — `player` argument is trustworthy (Roblox sets it); any `userId` inside the payload is not
2. **State** — player is in a valid state for this action (e.g., alive, in correct zone, not on cooldown)
3. **Parameters** — values are in expected types and ranges; reject anything suspect
4. **Rate** — throttle per-player request rate; drop floods

```lua
-- Server handler pattern
Network.connectEvent(RemoteEventName.OpenChest, function(player: Player, chestId: string)
    if typeof(chestId) ~= "string" then return end
    local chest = ChestRegistry.get(chestId)
    if not chest then return end
    if not ChestValidator.canPlayerOpen(player, chest) then return end
    ChestHandler.open(player, chest)
end)
```

Never trust client-sent values for anything that affects player data, currency, or game state. The client can send anything.

## Crowdsmith-Relevant Patterns

### Follower position replication (HIGH-RISK system)

- **Do NOT replicate every follower's transform** across `RemoteEvent`. At 100-300 followers × 8-12 players, bandwidth collapses.
- **Preferred**: server authoritative only for crowd-count, crowd-center, crowd-radius. Client-side flocking simulates individual followers visually.
- **If per-follower desync matters for gameplay** (it shouldn't — crushing is crowd-vs-crowd): use `UnreliableRemoteEvent` batched at 10-20 Hz, sending sparse deltas, not full state.
- **Prototype this before committing** — this is risk #1 in the concept doc.

### Chest open (medium-traffic discrete event)

- `RemoteEvent` from client ("I want to open chest X")
- Server validates (player size ≥ toll, chest not already opened, cooldown)
- Server fires back `RemoteEvent` with relic result → updates `PlayerData`
- Do NOT use `RemoteFunction` — chest open can complete asynchronously; blocking the client adds latency without benefit

### Round state (broadcast)

- Server fires `RemoteEvent` to all players for round start/end/timer
- Uses existing `PlayerDataUpdated` pattern for per-player state (size, relics)

## Data Size Limits

- Roblox default remote argument size cap: ~1 MB per call (practically should stay well below for latency reasons)
- Target per-call payload: < 4 KB for gameplay remotes
- Large payloads (> 16 KB) should be chunked via multiple events or compressed via `buffer` type (post-cutoff)

## `buffer` Type for Binary Replication (post-cutoff)

New Luau `buffer` type can replicate efficiently:

```lua
local buf = buffer.create(64)
buffer.writeu32(buf, 0, crowdCount)
buffer.writef32(buf, 4, crowdCenterX)
buffer.writef32(buf, 8, crowdCenterY)
buffer.writef32(buf, 12, crowdCenterZ)
Network.fireAllClients(RemoteEventName.CrowdUpdate, buf)
```

Buffers are replicated as binary blobs — much more compact than tables of numbers. Use for high-frequency continuous data.

## Flow Through Player Data

For anything that must persist or survive refresh, route through `PlayerData`:

```
client fires Network.fireServer(...)
  → server validates
  → server calls PlayerDataServer.updateValue(player, key, fn)
  → ProfileStore persists
  → server fires PlayerDataUpdated
  → client cache refreshes via PlayerDataClient
```

Never skip the server validation step. Never mutate client cache directly.

## Sources

- [Roblox Remote Events docs](https://create.roblox.com/docs/scripting/events/remote)
- [In-Depth RemoteEvents + Replication](https://devforum.roblox.com/t/in-depth-information-about-robloxs-remoteevents-instance-replication-and-physics-replication-w-sources/1847340)
- [Securing RemoteEvent and RemoteFunction](https://devforum.roblox.com/t/how-to-secure-your-remoteevent-and-remotefunction/3345363)
- [Luau buffer type announcement](https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894)
