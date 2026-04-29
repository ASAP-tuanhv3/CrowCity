--!strict

--[[
	CrowdStateServer — authoritative crowd-state hub.
	Path: ServerStorage/Source/CrowdStateServer/init.luau
	Implements: ADR-0001 §Key Interfaces (record schema + 5 reliable events)
	            ADR-0004 §Write-Access Matrix (caller authority)
	            GDD design/gdd/crowd-state-manager.md

	Story-001 scope: module skeleton + record schema types + create/destroy
	lifecycle + Players.PlayerRemoving handler + CrowdCreated + CrowdDestroyed
	reliable fanout. updateCount / recomputeRadius / stateEvaluate / broadcastAll
	deferred to follow-up stories.

	Public API (story-001):
	  create(crowdId, initial) -> CrowdRecord  -- RoundLifecycle-only caller
	  destroy(crowdId) -> ()                   -- RoundLifecycle-only + DC handler
	  get(crowdId) -> CrowdRecord?             -- any server module (read-only)
	  start() -> ()                            -- boot wiring; connect PlayerRemoving

	Caller restrictions (ADR-0004 §Write-Access Matrix):
	  create()  — RoundLifecycle.createAll only
	  destroy() — RoundLifecycle (destroyAll + Players.PlayerRemoving handler)
	  get()     — any server-side system (read-only; caller MUST NOT mutate)
	  start()   — ServerScriptService/start.server.luau boot only

	Pillar 4 anti-P2W invariant (ADR-0004 §Pillar 4):
	  Cosmetic systems FORBIDDEN as callers. Skin System, Avatar System, Banner
	  System, Trail System and any future visual-identity system MUST NOT mutate
	  any field of a crowd record.

	Test-only API (_-prefixed, never call from production code):
	  _resetForTests()                      — zeros _crowds, disconnects DC handler, clears interceptor
	  _getCrowdsCount()                     — size of internal _crowds map
	  _getPlayerRemovingConnection()        — RBXScriptConnection? identity check
	  _setTestFanoutInterceptor(fn)         — intercepts Network.fireAllClients for tests
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

-- ---------------------------------------------------------------------------
-- Exported types (per architecture.md §5.1 L512-527)
-- ---------------------------------------------------------------------------

--- Crowd lifecycle state. GraceWindow is transient: ~0.5s overlap grace before
--- Eliminated is assigned. ADR-0001 §Key Interfaces; ADR-0004 §Write-Access Matrix.
export type CrowdState = "Active" | "GraceWindow" | "Eliminated"

--- Source of a count mutation. Used as runtime caller fingerprint on updateCount.
--- Enforced by code review: each call site passes a value matching its module identity.
--- ADR-0004 §Write-Access Matrix (4 authorised callers for updateCount).
export type DeltaSource = "Absorb" | "Collision" | "Chest" | "Relic"

--- Authoritative server-side crowd record.
--- Fields must not use `read` qualifier — plain types; immutability enforced by
--- convention + control-manifest L155 (callers MUST NOT mutate returned references).
--- ADR-0001 §Key Interfaces; architecture.md §5.1 L515-527.
export type CrowdRecord = {
	crowdId: string,
	position: Vector3,
	radiusMultiplier: number,          -- [0.5, 1.5]
	radius: number,                    -- composed: radius_base(count) * mult
	count: number,                     -- [1, 300]
	hue: number,                       -- [1, 12] immutable post-create
	activeRelics: { string },          -- max 4
	state: CrowdState,
	tick: number,                      -- uint16 monotonic broadcast counter
	stillOverlapping: boolean,
	timer_start: number?,              -- os.clock() on GraceWindow entry; nil otherwise
}

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

local _crowds: { [string]: CrowdRecord } = {}
local _playerRemovingConnection: RBXScriptConnection? = nil

--- Test-only interceptor. When set, fanout() calls this instead of Network.fireAllClients.
--- Cleared by _resetForTests(). Production path: nil → direct Network call.
local _testFanoutInterceptor: ((eventName: string, payload: { [string]: any }) -> ())? = nil

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Routes reliable fanout through the test interceptor when set; otherwise
--- delegates to Network.fireAllClients. This seam enables signal_fanout.spec to
--- verify CrowdCreated/CrowdDestroyed payloads without a connected client.
local function fanout(eventName: RemoteEventName.EnumType, payload: { [string]: any }): ()
	if _testFanoutInterceptor ~= nil then
		_testFanoutInterceptor(eventName, payload)
	else
		Network.fireAllClients(eventName, payload)
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local CrowdStateServer = {}

--- Creates an authoritative crowd record. Sole caller: RoundLifecycle.createAll
--- (round start). Errors loudly if a record already exists for crowdId (per GDD
--- §Server API "Fails if record exists"). Fires CrowdCreated reliable event with
--- payload {crowdId, hue, initialCount} before returning the stored reference.
--- ADR-0004 §Write-Access Matrix; ADR-0001 §Key Interfaces.
function CrowdStateServer.create(crowdId: string, initial: CrowdRecord): CrowdRecord
	assert(
		_crowds[crowdId] == nil,
		"CrowdStateServer.create: record already exists for crowdId=" .. crowdId
	)
	_crowds[crowdId] = initial
	fanout(RemoteEventName.CrowdCreated, {
		crowdId = initial.crowdId,
		hue = initial.hue,
		initialCount = initial.count,
	})
	return initial
end

--- Destroys a crowd record. Callers: RoundLifecycle.destroyAll (round end) and the
--- Players.PlayerRemoving handler below (mid-round disconnect). Idempotent — no-op
--- and no event if the record is absent (per GDD §Server API "Idempotent (no-op if
--- absent)"). Fires CrowdDestroyed reliable event {crowdId} only when a record was
--- actually removed.
--- ADR-0004 §Write-Access Matrix.
function CrowdStateServer.destroy(crowdId: string): ()
	if _crowds[crowdId] == nil then
		return  -- idempotent: no event fired
	end
	_crowds[crowdId] = nil
	fanout(RemoteEventName.CrowdDestroyed, { crowdId = crowdId })
end

--- Returns the crowd record for crowdId, or nil if absent. Read-only access —
--- caller MUST NOT mutate the returned table (control-manifest L155; ADR-0004
--- §Read-vs-Write Split). Full read surface (getAllActive, getAllCrowdPositions,
--- setStillOverlapping) ships in story-007; this basic accessor lands here so
--- create/destroy ACs can be verified.
--- ADR-0004 §Write-Access Matrix (unrestricted server-side read).
function CrowdStateServer.get(crowdId: string): CrowdRecord?
	return _crowds[crowdId]
end

--- Connects the Players.PlayerRemoving handler. Called once at boot from
--- ServerScriptService/start.server.luau. Idempotent — second call returns early
--- without replacing the existing connection. The handler invokes
--- destroy(tostring(player.UserId)) on disconnect, satisfying AC-02 (record absent
--- by next tick; no error during tick processing). RoundLifecycle also subscribes to
--- PlayerRemoving for its own peakCount cleanup — both subscribers run independently.
--- ADR-0004 §Write-Access Matrix (destroy caller: RoundLifecycle + PlayerRemoving).
function CrowdStateServer.start(): ()
	if _playerRemovingConnection ~= nil then
		return  -- idempotent
	end
	_playerRemovingConnection = Players.PlayerRemoving:Connect(function(player: Player)
		local crowdId = tostring(player.UserId)
		CrowdStateServer.destroy(crowdId)
	end)
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module state for test isolation. Disconnects the PlayerRemoving
--- handler if connected; clears the _crowds map; clears the fanout interceptor.
--- Must be called in beforeEach() for every CrowdStateServer spec.
function CrowdStateServer._resetForTests(): ()
	if _playerRemovingConnection ~= nil then
		_playerRemovingConnection:Disconnect()
		_playerRemovingConnection = nil
	end
	_crowds = {}
	_testFanoutInterceptor = nil
end

--- **TEST ONLY** — never call from production code.
--- Returns the count of records in the private _crowds map. Used to verify
--- AC-16 (record presence/absence after createAll/destroyAll) without exposing
--- _crowds directly (control-manifest L155 forbids direct export).
function CrowdStateServer._getCrowdsCount(): number
	local count = 0
	for _ in _crowds do
		count += 1
	end
	return count
end

--- **TEST ONLY** — never call from production code.
--- Returns the current RBXScriptConnection for identity comparison in
--- idempotence tests (dc_cleanup.spec AC-start-idempotence).
function CrowdStateServer._getPlayerRemovingConnection(): RBXScriptConnection?
	return _playerRemovingConnection
end

--- **TEST ONLY** — never call from production code.
--- Sets an interceptor called by fanout() instead of Network.fireAllClients.
--- Pass nil to clear (also cleared by _resetForTests). Used by signal_fanout.spec
--- to capture CrowdCreated/CrowdDestroyed payloads without a connected client.
function CrowdStateServer._setTestFanoutInterceptor(
	fn: ((eventName: string, payload: { [string]: any }) -> ())?
): ()
	_testFanoutInterceptor = fn
end

return CrowdStateServer
