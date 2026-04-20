# Luau Type System — Strict Mode + New Type Solver

*Last verified: 2026-04-20*

Reference for type-safe Luau in this project. All `.luau` files must start with `--!strict`. This document covers post-May-2025 type system features that may not be in the LLM's training data.

## Mode Pragmas

```lua
--!strict       -- Required for all project files. Full type checking, all inferred types flow, errors on mismatch.
--!nonstrict    -- Historical default. Permissive — missing annotations become `any`. Do NOT use in this project.
--!nocheck      -- Skip type analysis entirely. Only acceptable in vendored dependencies.
```

Project policy: every `.luau` file in `src/` begins with `--!strict`. Enforced in code review.

## New Type Solver (GA November 2025)

The new type solver shipped out of beta in November 2025. It is the default for new projects. Core improvements:

- Flow-sensitive type narrowing across branches
- Type functions (user-defined compile-time type logic)
- `read` keyword marks table properties read-only
- Better generic inference for higher-order functions
- Improved error messages with source-level context

## Core Type Annotations

```lua
--!strict

-- Primitive annotations
local health: number = 100
local name: string = "Player"
local isAlive: boolean = true
local data: { [string]: number } = {}

-- Function types
local function heal(player: Player, amount: number): ()
    -- return type `()` = no return value
end

-- Optional types
local target: Player? = nil  -- equivalent to `Player | nil`

-- Union types
local result: number | string = ...

-- Intersection types
type Serializable = { serialize: (self: any) -> string }
type HasId = { id: string }
type Saveable = Serializable & HasId
```

## Type Aliases and Exports

```lua
--!strict
local Connections = require(...)

export type ClassType = typeof(setmetatable({} :: {
    _connections: Connections.ClassType,
    _instance: Instance,
}, MyClass))
```

Pattern used throughout this project — see `CLAUDE.md` OOP class pattern. The `typeof(setmetatable(...))` idiom produces a type that includes both the table fields and the metatable methods.

## Read-Only Table Properties (`read` keyword)

Post-cutoff feature. Marks specific fields as immutable through a given type:

```lua
type ReadOnlyProfile = {
    read id: string,
    read createdAt: number,
    coins: number,  -- mutable
}

local function displayProfile(p: ReadOnlyProfile)
    p.coins = 10        -- OK
    p.id = "new-id"     -- TYPE ERROR: id is read-only through ReadOnlyProfile
end
```

Use case: pass shared state to subsystems that should read but not mutate.

## Type Functions

Post-cutoff feature. User-defined compile-time type logic:

```lua
type function Readonly(T)
    -- Runs at type-check time. Transforms T into a fully read-only version.
    -- Full API documented at luau.org
end

type ImmutableProfile = Readonly<{ id: string, coins: number }>
```

Most project code will not need type functions. Reach for them only when writing shared utility types. Document any use with a comment explaining what the function returns.

## Generic Functions

```lua
-- Single type parameter
local function identity<T>(value: T): T
    return value
end

-- Multi-parameter with constraints via intersection
type Hashable = { hash: (self: any) -> string }

local function memoize<T, R>(fn: (T) -> R): (T) -> R
    local cache: { [T]: R } = {}
    return function(arg: T): R
        if cache[arg] == nil then
            cache[arg] = fn(arg)
        end
        return cache[arg]
    end
end
```

## Class Pattern — Project Canonical Form

```lua
--!strict
local Connections = require(script.Parent.Connections)

local MyClass = {}
MyClass.__index = MyClass

export type ClassType = typeof(setmetatable({} :: {
    _connections: Connections.ClassType,
    _instance: Instance,
}, MyClass))

function MyClass.new(instance: Instance): ClassType
    local self = setmetatable({} :: any, MyClass)
    self._connections = Connections.new()
    self._instance = instance
    return self
end

function MyClass.destroy(self: ClassType)
    self._connections:disconnect()
end

return MyClass
```

The `:: any` cast in `.new` is a deliberate escape hatch — it would otherwise require listing every field twice. Every `RBXScriptConnection` must be added to `self._connections` and cleaned up in `destroy()`.

## Common Pitfalls

### `Instance:FindFirstChild` narrows to `Instance?`

```lua
local model: Model? = workspace:FindFirstChild("Hero") :: Model?  -- OK
if model then
    -- inside this block, model is narrowed to `Model` (non-nil)
    model.PrimaryPart.Position = ...
end
```

Always guard or `assert` before accessing fields on a `FindFirst*` result.

### `Instance:WaitForChild` returns non-nil but untyped

```lua
local remote = ReplicatedStorage:WaitForChild("MyRemote") :: RemoteEvent
```

Cast required — the return type is `Instance`, not the specific class.

### Attribute types are `any`

```lua
local zoneId: string = part:GetAttribute("ZoneId") :: string
```

Cast required and validate (attributes can be any primitive). Enforce in `SharedConstants/Attribute.luau` lookups.

### Tables with no declared fields become `{ [string]: unknown }` under new solver

Annotate containers explicitly:

```lua
-- Bad — inferred type is permissive
local players = {}

-- Good
local players: { [number]: Player } = {}
```

## Sources

- [Luau type-checking docs](https://create.roblox.com/docs/luau/type-checking)
- [New Type Solver general release](https://devforum.roblox.com/t/general-release-luau%E2%80%99s-new-type-solver/4084991)
- [Luau Type System Guide 2026](https://www.oflight.co.jp/en/columns/luau-type-system-strict-mode-guide-2026)
- [Luau intro to types](https://luau.org/types/)
