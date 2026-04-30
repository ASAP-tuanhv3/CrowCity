--!strict

--[[
	MatchStateServer — server-authoritative match state machine.
	Path: ServerStorage/Source/MatchStateServer/init.luau
	Implements: ADR-0005 (MSM/RoundLifecycle Split) §Decision
	            ADR-0006 §Source Tree Map
	            GDD design/gdd/match-state-machine.md

	Story-001 (Sprint 2-8) scope:
	  - 7-state enum (MatchState type)
	  - Placement type export
	  - get() / getParticipation() / getStateEndsAt() read accessors
	  - module-private _transitionTo (driver wiring deferred to story-002+)
	  - module-private _setParticipation honoring Snap-freeze rule
	  - PlayerAdded handler: auto-set participation = true
	  - PlayerRemoving handler: clear participation entry
	  - AFKToggle reliable RemoteEvent stub connect (full validation per
	    ADR-0010 4-check guard lives in story-007)

	Public API (story-001):
	  get() -> MatchState
	  getParticipation(player) -> boolean
	  getStateEndsAt() -> number?
	  start() -> ()  -- boot wiring; connects PlayerAdded/Removing/AFKToggle

	Caller restrictions (ADR-0005 §Decision):
	  Read accessors  — any server module + exposed to client via RemoteFunction
	                    (story-007 wires GetParticipation RemoteFunction)
	  start()         — ServerScriptService/start.server.luau boot only
	  No external transitionTo (internal-only per ADR-0005 §Decision).

	Test-only API (_-prefixed, never call from production code):
	  _resetForTests()                       — zero state, disconnect handlers, restore Lobby
	  _getState() / _setStateForTests(state) — direct state probe + override
	  _setParticipation(player, flag)        — internal API exposed for testing
	  _getPlayerAddedConnection() / _getPlayerRemovingConnection() / _getAFKToggleConnection()
	    — identity checks for idempotence tests
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

-- ---------------------------------------------------------------------------
-- Exported types per architecture.md §5.2 L577-587
-- ---------------------------------------------------------------------------

--- The 7 canonical match states. Lobbying transitions to Countdown:Ready when
--- MIN_PLAYERS_TO_START threshold is met (story-002 wires the driver).
--- ADR-0005 §Decision; GDD design/gdd/match-state-machine.md §State Enum.
export type MatchState =
	"Lobby"
	| "Countdown:Ready"
	| "Countdown:Snap"
	| "Active"
	| "Result"
	| "Intermission"
	| "ServerClosing"

--- End-of-round placement record. Populated by RoundLifecycle and broadcast
--- via RemoteEvent at round end. Story-001 exports the type only; writer logic
--- lands in story-004+. ADR-0005 §Decision; architecture.md §5.2 L584-587.
export type Placement = {
	crowdId: string,
	userId: number,
	placement: number,
	crowdCount: number,
	eliminationTime: number?,
}

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

-- Boot default per AC-1 + control-manifest L105 (MIN_PLAYERS_TO_START).
local _state: MatchState = "Lobby"
local _participation: { [number]: boolean } = {}
local _stateStartTime: number? = nil
local _stateEndsAt: number? = nil

-- Boot connections — wired by start(); cleared by _resetForTests.
local _playerAddedConnection: RBXScriptConnection? = nil
local _playerRemovingConnection: RBXScriptConnection? = nil
local _afkToggleConnection: RBXScriptConnection? = nil

-- ---------------------------------------------------------------------------
-- Module-private helpers (local functions; exposed via test surface only)
-- ---------------------------------------------------------------------------

--- Module-private state transition. Called by internal driver loops only
--- (story-002+ wires the timer + signal subscribers). Story-001 only
--- writes _state + _stateStartTime + _stateEndsAt; MatchStateChanged
--- broadcast wiring lives in story-007.
local function _transitionTo(newState: MatchState, endsAt: number?): ()
	_state = newState
	_stateStartTime = os.clock()
	_stateEndsAt = endsAt
end

--- Module-private participation flag setter. Honors the Snap-freeze rule:
--- when in "Countdown:Snap", a TRUE→FALSE attempt is REJECTED (locked-in
--- participants cannot drop out mid-snap). FALSE→TRUE is always allowed.
--- Outside Snap, both directions are allowed.
--- ADR-0005 §Decision; GDD design/gdd/match-state-machine.md §Participation Rules.
local function _setParticipation(player: Player, flag: boolean): ()
	local userId = player.UserId
	local current = _participation[userId] == true

	-- Snap freeze: TRUE→FALSE rejected. Locked-in participants cannot opt out
	-- once the Countdown:Snap phase begins (GDD §Participation Rules).
	if _state == "Countdown:Snap" and current == true and flag == false then
		return
	end

	_participation[userId] = flag
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local MatchStateServer = {}

--- Returns the current match state. Read-only for external consumers.
--- Callers: HUD, FTUE, spectator camera, Currency system.
--- ADR-0005 §Decision — any server module may read.
function MatchStateServer.get(): MatchState
	return _state
end

--- Returns the participation flag for the given player. Defaults to false if
--- the player has no entry yet (e.g. PlayerAdded handler not fired). New
--- joiners auto-set to true on PlayerAdded.
--- ADR-0005 §Decision — any server module may read.
function MatchStateServer.getParticipation(player: Player): boolean
	return _participation[player.UserId] == true
end

--- Returns the absolute timestamp at which the current state's timer expires,
--- or nil for non-timed states (Lobby, Active, ServerClosing). Set by
--- _transitionTo when entering a timed state. Story-002 owns the writer logic.
function MatchStateServer.getStateEndsAt(): number?
	return _stateEndsAt
end

--- Connects PlayerAdded / PlayerRemoving / AFKToggle handlers. Called once
--- at boot from ServerScriptService/start.server.luau. Idempotent — second
--- call returns early without replacing existing connections.
---
--- PlayerAdded: auto-set participation = true (any state).
--- PlayerRemoving: clear participation entry (frees memory; transition
---                 effects handled by story-002+).
--- AFKToggle: stub — full validation per ADR-0010 4-check guard lives in
---            story-007. Story-001 wire accepts the flag verbatim via
---            _setParticipation (which honors Snap freeze).
function MatchStateServer.start(): ()
	if _playerAddedConnection ~= nil then
		return -- idempotent
	end

	_playerAddedConnection = Players.PlayerAdded:Connect(function(player: Player)
		_setParticipation(player, true)
	end)

	_playerRemovingConnection = Players.PlayerRemoving:Connect(function(player: Player)
		_participation[player.UserId] = nil
	end)

	-- AFKToggle handler wiring DEFERRED to story-007. Story-001 spec calls for
	-- a "stub" — interpreted here as field + getter present, full Network.
	-- connectEvent wiring deferred. Reasons: (1) story-007 owns the ADR-0010
	-- 4-check validation guard which must wrap the handler; wiring without
	-- validation here would create a security gap during the story-001 → 007
	-- window, (2) Network.connectEvent requires Network.startServer to have
	-- already created the RemoteEvent instance, which fails in headless
	-- TestEZ context where Network is not booted. _afkToggleConnection stays
	-- nil until story-007 wires the validated handler.
	-- TODO(story-007): wire Network.connectEvent(RemoteEventName.AFKToggle,
	-- afkValidatedHandler, Network.t.tuple(Network.t.instanceIsA("Player"),
	-- Network.t.boolean)) per ADR-0010 §4-Check Guard.
end

-- ---------------------------------------------------------------------------
-- Test-only surface — _-prefixed; NEVER call from production code
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module state for test isolation. Disconnects all event handlers;
--- clears participation map; resets state to Lobby.
--- Must be called in beforeEach() for every MatchStateServer spec.
function MatchStateServer._resetForTests(): ()
	if _playerAddedConnection ~= nil then
		_playerAddedConnection:Disconnect()
		_playerAddedConnection = nil
	end
	if _playerRemovingConnection ~= nil then
		_playerRemovingConnection:Disconnect()
		_playerRemovingConnection = nil
	end
	if _afkToggleConnection ~= nil then
		_afkToggleConnection:Disconnect()
		_afkToggleConnection = nil
	end
	_state = "Lobby"
	_participation = {}
	_stateStartTime = nil
	_stateEndsAt = nil
end

--- **TEST ONLY** — direct state probe. Avoids exposing _state via public API;
--- useful for verifying _transitionTo side-effects.
function MatchStateServer._getState(): MatchState
	return _state
end

--- **TEST ONLY** — bypass _transitionTo to set state directly for fixture
--- setup (e.g. force "Countdown:Snap" to test asymmetric freeze rule).
--- Production code MUST go through _transitionTo (story-002+).
function MatchStateServer._setStateForTests(newState: MatchState): ()
	_state = newState
end

--- **TEST ONLY** — exposes module-private _setParticipation for direct
--- invocation. Production callers wire via PlayerAdded handler + AFKToggle
--- RemoteEvent only.
function MatchStateServer._setParticipation(player: Player, flag: boolean): ()
	_setParticipation(player, flag)
end

--- **TEST ONLY** — returns the PlayerAdded connection for idempotence checks.
function MatchStateServer._getPlayerAddedConnection(): RBXScriptConnection?
	return _playerAddedConnection
end

--- **TEST ONLY** — returns the PlayerRemoving connection for idempotence checks.
function MatchStateServer._getPlayerRemovingConnection(): RBXScriptConnection?
	return _playerRemovingConnection
end

--- **TEST ONLY** — returns the AFKToggle connection for idempotence checks.
--- Type is RBXScriptConnection? — Network.connectEvent returns the underlying
--- OnServerEvent:Connect result (RBXScriptConnection).
function MatchStateServer._getAFKToggleConnection(): RBXScriptConnection?
	return _afkToggleConnection
end

return MatchStateServer
