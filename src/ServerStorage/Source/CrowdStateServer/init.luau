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

	Story-002 scope: updateCount + DeltaSource enum (already exported in story-001)
	+ F5 clamp + CountChanged BindableEvent + CrowdCountClamped reliable to local
	player.

	Story-007 scope: getAllActive (Eliminated-excluded) + getAllCrowdPositions (snapshot
	map) + setStillOverlapping (CCR-only writer, last-write-wins, absent-record no-op).

	Public API (story-001):
	  create(crowdId, initial) -> CrowdRecord  -- RoundLifecycle-only caller
	  destroy(crowdId) -> ()                   -- RoundLifecycle-only + DC handler
	  get(crowdId) -> CrowdRecord?             -- any server module (read-only)
	  start() -> ()                            -- boot wiring; connect PlayerRemoving

	Public API (story-002):
	  updateCount(crowdId, delta, source) -> number  -- 4 callers: Absorb / Collision / Chest / Relic
	  CountChanged (BindableEvent module field)       -- subscribe: CrowdStateServer.CountChanged.Event:Connect(...)

	Public API (story-007):
	  getAllActive() -> { CrowdRecord }                  -- excludes Eliminated; fresh array
	  getAllCrowdPositions() -> { [string]: Vector3 }    -- snapshot; excludes Eliminated
	  setStillOverlapping(crowdId, flag) -> ()           -- CCR-only writer

	Caller restrictions (ADR-0004 §Write-Access Matrix):
	  create()                — RoundLifecycle.createAll only
	  destroy()               — RoundLifecycle (destroyAll + Players.PlayerRemoving handler)
	  get()                   — any server-side system (read-only; caller MUST NOT mutate)
	  start()                 — ServerScriptService/start.server.luau boot only
	  updateCount()           — AbsorbSystem / CollisionResolver / ChestSystem / RelicEffectHandler ONLY
	                            (Pillar 4: cosmetic systems FORBIDDEN)
	  getAllActive()           — any server module (CCR Phase 1 hot path)
	  getAllCrowdPositions()   — NPCSpawner; any server module (read-only)
	  setStillOverlapping()    — CollisionResolver ONLY (ADR-0004 §Write-Access Matrix)

	Pillar 4 anti-P2W invariant (ADR-0004 §Pillar 4):
	  Cosmetic systems FORBIDDEN as callers. Skin System, Avatar System, Banner
	  System, Trail System and any future visual-identity system MUST NOT mutate
	  any field of a crowd record.

	Test-only API (_-prefixed, never call from production code):
	  _resetForTests()                      — zeros _crowds, disconnects DC handler, clears interceptors
	  _getCrowdsCount()                     — size of internal _crowds map
	  _getPlayerRemovingConnection()        — RBXScriptConnection? identity check
	  _setTestFanoutInterceptor(fn)         — intercepts Network calls for tests (3-arg: eventName, payload, target)
	  _setTestOwnerResolver(fn)             — overrides Players:GetPlayerByUserId for tests
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

--- Test-only interceptor. When set, fanout() calls this instead of the Network
--- layer. Receives all 3 args (eventName, payload, target) so countclamped.spec
--- can assert per-player routing. Cleared by _resetForTests().
--- Existing 2-arg interceptors in story-001 tests silently ignore the extra arg.
local _testFanoutInterceptor: ((eventName: string, payload: { [string]: any }, target: Player?) -> ())? = nil

--- Test-only owner resolver override. When set, resolveOwner() calls this
--- instead of Players:GetPlayerByUserId. Cleared by _resetForTests().
local _testOwnerResolver: ((crowdId: string) -> Player?)? = nil

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

-- Per ADR-0001 §Key Interfaces; F5 clamp range.
local COUNT_FLOOR = 1
local COUNT_CEILING = 300

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Resolves a Player from a crowdId. Production: Players:GetPlayerByUserId(tonumber(crowdId)).
--- Returns nil if the player has disconnected mid-tick (CrowdCountClamped fire is
--- skipped for that frame; client-side broadcast handles the eliminated state).
--- Test override available via _setTestOwnerResolver.
local function resolveOwner(crowdId: string): Player?
	if _testOwnerResolver ~= nil then
		return _testOwnerResolver(crowdId)
	end
	local userId = tonumber(crowdId)
	if userId == nil then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

--- Routes reliable fanout through the test interceptor when set; otherwise
--- delegates to Network.fireClient(eventName, target, ...) when target is non-nil, or
--- Network.fireAllClients(eventName, ...) when target is nil. Test interceptor receives
--- all three args so countclamped.spec can assert per-player routing.
local function fanout(
	eventName: RemoteEventName.EnumType,
	payload: { [string]: any },
	target: Player?
): ()
	if _testFanoutInterceptor ~= nil then
		_testFanoutInterceptor(eventName, payload, target)
	elseif target ~= nil then
		Network.fireClient(eventName, target, payload)
	else
		Network.fireAllClients(eventName, payload)
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local CrowdStateServer = {}

--- Server-only BindableEvent fired after every successful updateCount with
--- effective_delta != 0. Payload: (crowdId, oldCount, newCount, deltaSource).
--- Subscribers: RoundLifecycle (peakCount tracking, story-002 of RL), state
--- evaluator (story-006). NEVER replicated to clients (manifest L77).
--- ADR-0004 §Read-vs-Write Split.
local _countChanged: BindableEvent = Instance.new("BindableEvent")
_countChanged.Name = "CrowdStateServer_CountChanged"

-- Public BindableEvent reference. Subscribe via:
--   CrowdStateServer.CountChanged.Event:Connect(function(crowdId, oldCount, newCount, deltaSource) ... end)
-- Architecture.md §5.1 L552 — exposed as module field.
CrowdStateServer.CountChanged = _countChanged

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
	}, nil)
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
	fanout(RemoteEventName.CrowdDestroyed, { crowdId = crowdId }, nil)
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

--- Returns an array of all crowd records EXCEPT those in state "Eliminated".
--- Iteration order is arbitrary (pairs traversal). Caller MUST NOT mutate
--- returned records — read-only contract per control-manifest L155 (enforced
--- by code review; no runtime guard per manifest L137).
--- Hot path: CollisionResolver.tick (Phase 1) calls per-tick to enumerate
--- overlap-pair candidates. Returns a FRESH array each call — callers may
--- discard or hold; no shared mutable state.
--- ADR-0004 §Read-vs-Write Matrix; arch §5.1 L541; GDD §States table
--- ("Eliminated" = excluded from active set).
function CrowdStateServer.getAllActive(): { CrowdRecord }
	local result: { CrowdRecord } = {}
	for _, record in _crowds do
		if record.state ~= "Eliminated" then
			table.insert(result, record)
		end
	end
	return result
end

--- Returns a snapshot map of crowdId → position Vector3 for all crowds NOT
--- in state "Eliminated". Eliminated records' positions are stale per GDD
--- §Server API L179 — exclude from snapshot. Returns a FRESH table each
--- call — defensive copy. Acceptable cost given ≤12 crowds (manifest §Performance).
--- Hot consumer: NPCSpawner min-distance gate.
--- ADR-0004 §Read-vs-Write Matrix; arch §5.1 L542.
function CrowdStateServer.getAllCrowdPositions(): { [string]: Vector3 }
	local result: { [string]: Vector3 } = {}
	for crowdId, record in _crowds do
		if record.state ~= "Eliminated" then
			result[crowdId] = record.position
		end
	end
	return result
end

--- Sets the per-tick overlap flag on a crowd record. Sole caller:
--- CollisionResolver. Last-write-wins within a tick (race tolerated — CCR
--- iterates pairs once per Phase 1 with no internal contention). No-op if
--- the record is absent (handles the rare race where CCR's snapshot
--- includes a crowd that destroys mid-tick e.g. via PlayerRemoving).
--- Writes unconditionally on state — CSM does NOT gate on state="Eliminated"
--- (CCR is responsible for not calling on Eliminated crowds; if it does,
--- the write is harmless because Eliminated records are scheduled for
--- destroy by RoundLifecycle).
--- ADR-0004 §Write-Access Matrix (CollisionResolver-only writer); arch §5.1 L545.
function CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()
	local record = _crowds[crowdId]
	if record == nil then
		return  -- silent no-op per race-tolerance contract
	end
	record.stillOverlapping = flag
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

--- Mutates the count of crowdId by `delta`, applying F5 clamp [1, 300].
--- Returns post-clamp count. Sole callers (ADR-0004 §Write-Access Matrix):
--- AbsorbSystem.tick (delta > 0), CollisionResolver.tick (delta < 0),
--- ChestSystem.tick (delta < 0), RelicEffectHandler.tick (delta any).
--- Asserts loud if record absent — caller bug per ADR-0004 §Decision tone.
---
--- Side effects:
---   1. Mutates record.count to clamp(count_old + delta, 1, 300).
---   2. Fires CountChanged BindableEvent with (crowdId, oldCount, newCount,
---      deltaSource) ONLY IF effective_delta != 0 (post-clamp difference).
---   3. Fires CrowdCountClamped reliable to LOCAL PLAYER ONLY when positive
---      overflow truncated (count_old + delta > 300). Lower-bound clamp does
---      NOT fire CrowdCountClamped (different signal scope per GDD L145).
---   4. Per-call semantic — same-tick repeat calls at ceiling each fire
---      CrowdCountClamped (HUD-side debounce per GDD L145).
---
--- Pillar 4 anti-P2W invariant: cosmetic systems FORBIDDEN as callers
--- (control-manifest L135). Enforced by code review (manifest L137 forbids
--- runtime traceback validation in hot loop).
function CrowdStateServer.updateCount(crowdId: string, delta: number, source: DeltaSource): number
	local record = _crowds[crowdId]
	assert(
		record ~= nil,
		"CrowdStateServer.updateCount: record absent for crowdId=" .. crowdId
	)

	local oldCount = record.count
	local proposed = oldCount + delta
	local newCount = math.clamp(proposed, COUNT_FLOOR, COUNT_CEILING)

	-- F5 clamp ceiling: positive overflow → CrowdCountClamped reliable to owner.
	-- Floor clamp does NOT fire this signal (different scope per GDD L145).
	if proposed > COUNT_CEILING then
		local owner = resolveOwner(crowdId)
		if owner ~= nil then
			fanout(RemoteEventName.CrowdCountClamped, {
				crowdId = crowdId,
				attemptedDelta = delta,
				clampedCount = newCount,
			}, owner)
		end
	end

	-- Effective delta: post-clamp difference. When count is already at floor or
	-- ceiling and the proposed delta would push past, effective_delta == 0 →
	-- skip CountChanged per AC-24.
	local effectiveDelta = newCount - oldCount
	if effectiveDelta ~= 0 then
		record.count = newCount
		_countChanged:Fire(crowdId, oldCount, newCount, source)
	end

	return newCount
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module state for test isolation. Disconnects the PlayerRemoving
--- handler if connected; clears the _crowds map; clears the fanout interceptor
--- and owner resolver.
--- Must be called in beforeEach() for every CrowdStateServer spec.
function CrowdStateServer._resetForTests(): ()
	if _playerRemovingConnection ~= nil then
		_playerRemovingConnection:Disconnect()
		_playerRemovingConnection = nil
	end
	_crowds = {}
	_testFanoutInterceptor = nil
	_testOwnerResolver = nil
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
--- Sets an interceptor called by fanout() instead of the Network layer.
--- Interceptor signature: (eventName: string, payload: {[string]: any}, target: Player?) -> ()
--- Existing 2-arg interceptors silently ignore the third arg (Lua semantics).
--- Pass nil to clear (also cleared by _resetForTests). Used by signal_fanout.spec
--- and countclamped.spec to capture network events without a connected client.
function CrowdStateServer._setTestFanoutInterceptor(
	fn: ((eventName: string, payload: { [string]: any }, target: Player?) -> ())?
): ()
	_testFanoutInterceptor = fn
end

--- **TEST ONLY** — never call from production code.
--- Overrides resolveOwner to return a mock Player for the given crowdId.
--- Used by countclamped.spec to verify per-player routing without a connected
--- Roblox client. Cleared by _resetForTests.
function CrowdStateServer._setTestOwnerResolver(
	fn: ((crowdId: string) -> Player?)?
): ()
	_testOwnerResolver = fn
end

return CrowdStateServer
