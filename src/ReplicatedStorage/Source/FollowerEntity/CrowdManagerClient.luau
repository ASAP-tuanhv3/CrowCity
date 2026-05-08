--!strict

--[[
	FollowerEntity/CrowdManagerClient.luau  — singleton orchestrator
	Path: ReplicatedStorage/Source/FollowerEntity/CrowdManagerClient.luau

	Implements:
	  - design/gdd/follower-entity.md §Orchestrator
	  - ADR-0007 §Three-Module Split (CrowdManagerClient singleton orchestrator)
	  - ADR-0002 §audit-no-competing-heartbeat (only RenderStepped; no Heartbeat:Connect)
	  - TR-follower-entity-001 (no Humanoid; CFrame authority via pool parts)
	  - TR-follower-entity-020 (read-only consumer; never writes to CrowdStateClient/Server)
	  - Sprint 4 / Story 4-2 (follower-entity/story-002)

	Responsibilities:
	  - Singleton lifecycle: init() → start() → stop()
	  - Owns { [crowdId]: FollowerEntityClient } map + per-crowd Janitor instances
	  - Subscribes to CrowdStateClient.CrowdCreated → constructs FollowerEntityClient
	  - Subscribes to CrowdStateClient.CrowdEliminated → destroys FollowerEntityClient
	  - Drives a SINGLE RenderStepped connection iterating all active crowds:
	      • Per-frame nil-check on CrowdStateClient.get(crowdId)
	      • If nil: calls _markAllDespawning() and skips boids update
	      • If present: calls _update(dt) [stub in story-002; boids lands in story-003]

	ADR-0002 §Forbidden inside RenderStepped (verbatim):
	  - Instance.new() — pool is pre-allocated
	  - WaitForChild — all dependencies cached at init
	  - Player.Character traversal
	  - Yields (task.wait, :Wait())
	  - Distance math against camera (lives in FollowerLODManager)
	  - Direct subscription to CrowdStateBroadcast (read via CrowdStateClient.get)
	  - Heartbeat:Connect (use RenderStepped only)

	READ-ONLY CONTRACT (TR-follower-entity-020):
	  This module never writes to CrowdStateClient, CrowdStateServer, or any
	  server state. No :set, :update, or server RemoteEvent fires appear here.
	  Enforcement: code review per ADR-0006 §Forbidden Patterns.

	Bootstrap:
	  Called from src/ReplicatedFirst/Source/start.server.luau §startClientGameplay:
	    local CrowdManagerClient = require(ReplicatedStorage.Source.FollowerEntity.CrowdManagerClient)
	    CrowdManagerClient:init()
	    CrowdManagerClient:start()
--]]

-- ---------------------------------------------------------------------------
-- Services + dependencies
-- ---------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local JanitorModule = require(Packages.janitor)
type Janitor = typeof(JanitorModule.new())

local Connections    = require(ReplicatedStorage.Source.Connections)
local CrowdStateClient  = require(ReplicatedStorage.Source.CrowdStateClient)
local FollowerEntityClient = require(ReplicatedStorage.Source.FollowerEntity.Client)
local SpawnThrottleQueue = require(ReplicatedStorage.Source.FollowerEntity.SpawnThrottleQueue)
local Pool                 = require(ReplicatedStorage.Source.FollowerEntity.Pool)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)
type PoolType = Pool.ClassType

-- ---------------------------------------------------------------------------
-- Module-level singleton state
-- ---------------------------------------------------------------------------

--- Map from crowdId to its per-crowd FollowerEntityClient instance.
local _crowds: { [string]: FollowerEntityClient.ClassType } = {}

--- Map from crowdId to its per-crowd Janitor instance.
--- The Janitor is injected into FollowerEntityClient at construction.
--- Stored here separately so stop() can destroy each without double-destroying.
local _crowdJanitors: { [string]: Janitor } = {}

--- Single RenderStepped connection managed by start() / stop().
local _renderStepConn: RBXScriptConnection? = nil

--- Connections for CrowdCreated / CrowdEliminated subscriptions.
--- Disconnected by stop() via _connections:disconnect().
local _connections: Connections.ClassType = Connections.new()

--- Guards against double-init and double-start.
local _initialized: boolean = false
local _started: boolean = false

--- Global throttle queue (Story 4-5): single FIFO across all crowds.
--- Drains at SPAWN_THROTTLE_PER_FRAME requests/frame in onRenderStepped.
--- Payload shape: `{ kind: "Absorb"|"FadeIn", crowdId: string, npcLastPosition: Vector3?, hueIndex: number? }`
local _spawnQueue: SpawnThrottleQueue.ClassType = SpawnThrottleQueue.new()

--- Shared Pool instance (optional). When set via setPool(), every newly-constructed
--- FollowerEntityClient receives a reference. nil → tests / unit-test mode.
local _pool: PoolType? = nil

--- CrowdState getter — wraps CrowdStateClient.get for FollowerEntityClient injection.
--- Defined as a closure so each FollowerEntityClient can call without re-importing.
local _getCrowdState = function(crowdId: string): FollowerEntityClient.CrowdStateRecord?
	return CrowdStateClient.get(crowdId) :: any
end

-- ---------------------------------------------------------------------------
-- Singleton module table
-- ---------------------------------------------------------------------------

local CrowdManagerClient = {}

-- ---------------------------------------------------------------------------
-- Private helpers
-- ---------------------------------------------------------------------------

--- Constructs a FollowerEntityClient for `crowdId` and registers it.
--- Idempotent: if a crowd with this id already exists, logs a warning and no-ops.
---
--- @param crowdId  string  — crowd identifier (tostring(player.UserId))
local function constructCrowd(crowdId: string): ()
	if _crowds[crowdId] ~= nil then
		-- Idempotent: CrowdCreated fired twice for same id — retain original instance.
		warn("[CrowdManagerClient] CrowdCreated fired twice for crowdId=" .. crowdId
			.. ". Retaining original FollowerEntityClient. (story-002 idempotency guard)")
		return
	end
	local janitor: Janitor = JanitorModule.new()
	_crowdJanitors[crowdId] = janitor
	local client = FollowerEntityClient.new(crowdId, janitor)
	-- Wire-in (stories 4-5..4-10): inject cross-crowd state getter + cap-grow callback.
	client:setCrowdStateGetter(_getCrowdState)
	client:setCapGrowCallback(function(growCount: number)
		-- Enqueue N FadeIn cap-grow spawn requests; throttle queue drains 4/frame.
		for _ = 1, growCount do
			_spawnQueue:enqueue({ kind = "FadeIn", crowdId = crowdId })
		end
	end)
	-- Optional Pool injection — only when CrowdManagerClient:setPool was called.
	if _pool ~= nil then
		client:setPool(_pool)
	end
	_crowds[crowdId] = client

	-- Initial spawn: seed crowd center + read record's count + grow to that size via
	-- setPoolSize. setPoolSize internally fires _onCapGrowRequest(growCount); cap-grow
	-- callback enqueues N FadeIn requests through SpawnThrottleQueue. onRenderStepped
	-- drains 4/frame, calling spawnFadeInAtCenter → Pool.grantBundle → bundle CFrame'd
	-- at _lastCrowdCenter. Without seeding, first-frame spawns land at Vector3.zero
	-- (under any baseplate). Per-tick _update overwrites _lastCrowdCenter from
	-- ownState.position on subsequent frames, but initial spawn fires before _update.
	-- Source: bridges CRB story-003 reliable CrowdCreated → FE Sprint 4 Pool grant path.
	local record = CrowdStateClient.get(crowdId)
	if record ~= nil then
		(client :: any)._lastCrowdCenter = record.position
		if record.count and record.count > 0 then
			local ok, err = pcall(function()
				(client :: any):setPoolSize(record.count)
			end)
			if not ok then
				warn("[CrowdManagerClient] setPoolSize failed for crowdId=" .. crowdId
					.. " count=" .. tostring(record.count) .. ": " .. tostring(err))
			end
		end
	end
end

--- Destroys the FollowerEntityClient for `crowdId` and removes it from the map.
--- No-op (safe) when crowdId is unknown.
---
--- @param crowdId  string  — crowd identifier to destroy
local function destroyCrowd(crowdId: string): ()
	local crowdClient = _crowds[crowdId]
	if crowdClient == nil then
		-- No-op: Eliminated for unknown crowdId — silent, no error.
		return
	end
	-- destroy() calls janitor:Destroy() internally.
	crowdClient:destroy()
	_crowds[crowdId] = nil
	_crowdJanitors[crowdId] = nil
end

--- Per-frame RenderStepped callback.
--- Called by the single _renderStepConn connection.
--- No yields, no Instance.new(), no WaitForChild per ADR-0002.
---
--- Pipeline (in order):
---   1. Drain SpawnThrottleQueue up to SPAWN_THROTTLE_PER_FRAME requests
---      (Story 4-5 §AC-8: 4/frame across all crowds)
---   2. Per-crowd nil-check + _update / _markAllDespawning dispatch
---
--- The body is wrapped in `debug.profilebegin("FollowerEntityClient_Update")` /
--- `debug.profileend()` per Story 4-11 AC-17 to expose the per-frame time
--- to Roblox Micro Profiler.
---
--- @param dt  number  — elapsed time since last frame (seconds)
local function onRenderStepped(dt: number): ()
	debug.profilebegin("FollowerEntityClient_Update")

	-- Sprint 5 dev unblock: client-side prediction of crowd center to LocalPlayer HRP.
	-- Phase 8 broadcastAll is stubbed so server never sends per-tick position. Without
	-- this, crowd would stay at initial spawn forever. Production: broadcast smooths
	-- this client-prediction; with broadcast stubbed, client owns prediction entirely.
	local localPlayer = Players.LocalPlayer
	if localPlayer ~= nil then
		local char = localPlayer.Character
		if char ~= nil then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp ~= nil and hrp:IsA("BasePart") then
				local ownCrowdId = tostring(localPlayer.UserId)
				local rec = CrowdStateClient.get(ownCrowdId) :: any
				if rec ~= nil then
					rec.position = hrp.Position
				end
			end
		end
	end

	-- 1. Throttle queue drain (Story 4-5 §AC-8)
	local dispatched = _spawnQueue:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
	for _, req in dispatched do
		local target = _crowds[req.crowdId]
		if target ~= nil then
			if req.kind == "Absorb" then
				target:spawnFromAbsorb(req.npcLastPosition, req.hueIndex)
			else
				target:spawnFadeInAtCenter()
			end
		end
		-- If target crowd was Eliminated between enqueue and dequeue, drop the
		-- request silently (no spawn into a destroyed crowd).
	end

	-- 2. Per-frame update for each active crowd
	local now = os.clock()
	for crowdId, crowdClient in _crowds do
		local record = CrowdStateClient.get(crowdId)
		if record == nil then
			-- Per-frame nil-check: sole despawn path per ADR-0007 §Despawn Path.
			crowdClient:_markAllDespawning()
		else
			-- Crowd present: drive per-frame simulation update.
			-- _update is no-op for legacy-seeded clients (only _followerParts populated);
			-- real pipeline activates when _positions array is populated via spawnFromAbsorb
			-- / spawnFadeInAtCenter (production wire-in, sprint 4 stories 4-3..4-10).
			crowdClient:_update(dt, now)
		end
	end
	debug.profileend()
end

--- Public wrapper for sibling systems (e.g., AbsorbClient) to enqueue spawn
--- requests through the global throttle queue. Idempotent: enqueueing for a
--- non-existent crowdId is allowed (request silently dropped at dispatch time).
function CrowdManagerClient.enqueueAbsorbSpawn(
	_self: any,
	crowdId: string,
	npcLastPosition: Vector3,
	hueIndex: number?
): ()
	_spawnQueue:enqueue({
		kind = "Absorb",
		crowdId = crowdId,
		npcLastPosition = npcLastPosition,
		hueIndex = hueIndex,
	})
end

--- Sets the shared Pool instance. Must be called BEFORE start() so that
--- every FollowerEntityClient constructed via CrowdCreated receives the Pool.
--- Caller is responsible for Pool:initAsync() — that yields and must complete
--- before the first spawn request fires.
function CrowdManagerClient.setPool(_self: any, pool: PoolType): ()
	_pool = pool
	-- Inject into any already-constructed crowd clients (idempotent).
	for _, client in _crowds do
		client:setPool(pool)
	end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Initializes the CrowdManagerClient singleton.
--- Subscribes to CrowdStateClient.CrowdCreated and CrowdStateClient.CrowdEliminated.
--- Idempotent: subsequent calls after the first are no-ops.
---
--- Must be called before start().
function CrowdManagerClient:init(): ()
	if _initialized then
		return
	end
	_initialized = true

	-- Subscribe to crowd lifecycle signals (defined in CrowdStateClient; wired in CRB story-003).
	_connections:add(
		CrowdStateClient.CrowdCreated.Event:Connect(function(crowdId: string)
			constructCrowd(crowdId)
		end)
	)

	_connections:add(
		CrowdStateClient.CrowdEliminated.Event:Connect(function(crowdId: string)
			destroyCrowd(crowdId)
		end)
	)
end

--- Starts the single RenderStepped loop.
--- Idempotent: calling start() twice does not create a second connection.
---
--- Requires init() to have been called first.
function CrowdManagerClient:start(): ()
	if _started then
		return
	end
	_started = true

	-- Connect exactly one RenderStepped callback per ADR-0007 §Boids Loop +
	-- ADR-0002 §audit-no-competing-heartbeat.
	_renderStepConn = RunService.RenderStepped:Connect(onRenderStepped)

	-- Catch-up: client boot order can race ahead of CrowdCreated reliable arrival.
	-- CrowdStateClient.start() wires before Pool is initialised, so any CrowdCreated
	-- BindableEvent fired pre-init was missed by our subscriber. Iterate the live
	-- cache and construct FollowerEntity for any crowds we don't already track.
	for _, record in ipairs(CrowdStateClient.getAllActive()) do
		if _crowds[record.crowdId] == nil then
			constructCrowd(record.crowdId)
		end
	end
end

--- Stops the RenderStepped loop and destroys all per-crowd clients.
--- Safe to call without a prior start() (no-op on missing connection).
--- After stop(), init() + start() may be called again to restart (e.g., in tests).
function CrowdManagerClient:stop(): ()
	-- Disconnect RenderStepped connection.
	if _renderStepConn ~= nil then
		_renderStepConn:Disconnect()
		_renderStepConn = nil
	end
	_started = false

	-- Destroy all per-crowd clients.
	-- Iterate a copy of crowdIds to avoid mid-iteration mutation issues.
	for crowdId in _crowds do
		destroyCrowd(crowdId)
	end
	-- _crowds and _crowdJanitors are emptied by destroyCrowd calls above.

	-- Disconnect CrowdCreated/CrowdEliminated subscriptions.
	_connections:disconnect()
	_initialized = false
end

--- Returns the FollowerEntityClient for `crowdId`, or nil if it does not exist.
--- Used by sibling modules (e.g., FollowerLODManager) to access per-crowd state.
---
--- READ-ONLY: do not mutate the returned object's internal parallel arrays.
---
--- @param crowdId  string  — crowd identifier
--- @return FollowerEntityClient?
function CrowdManagerClient:getCrowdClient(crowdId: string): FollowerEntityClient.ClassType?
	return _crowds[crowdId]
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — exposes the internal onRenderStepped callback for deterministic tests.
--- Calling this invokes exactly one frame of the crowd iteration loop.
--- Tests use this instead of task.wait() to avoid non-determinism.
---
--- @param dt  number  — simulated delta-time to pass to crowd clients
function CrowdManagerClient:_debugStepRenderFrame(dt: number): ()
	onRenderStepped(dt)
end

--- **TEST ONLY** — resets all singleton state to a clean baseline.
--- Calls stop() to disconnect connections + destroy all crowds, then clears
--- the init guard so init() + start() may be called fresh (mirrors story-001 test-seam pattern).
--- Call in beforeEach() of every CrowdManagerClient spec.
function CrowdManagerClient:_debugReset(): ()
	self:stop()
	-- stop() already resets _started = false and _initialized = false,
	-- disconnects _connections, and destroys all crowds.
	-- Re-create _connections so the singleton can be re-inited in the next test.
	_connections = Connections.new()
	_crowds = {}
	_crowdJanitors = {}
	_renderStepConn = nil
	_spawnQueue = SpawnThrottleQueue.new()
	_pool = nil
	_initialized = false
	_started = false
end

return CrowdManagerClient
