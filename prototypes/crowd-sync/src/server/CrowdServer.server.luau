--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Question: Can Roblox handle 800-3000 follower entities across 8-12 players at 60 FPS on mobile?
-- Date: 2026-04-20

-- Server-authoritative crowd state. Tracks per-crowd:
--   { position, hitboxRadius, followerCount, hue }
-- Does NOT track individual follower positions. Clients render followers locally.
--
-- Runs hit detection at 15 Hz (not 60). Broadcasts crowd state at 15 Hz via UnreliableRemoteEvent.
--
-- For this prototype, all crowds are bot-controlled (wander randomly). One slot reserved for the
-- logged-in player but treated the same way. No actual gameplay (absorb/collision) wired up —
-- this is a throughput test.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local Shared = ReplicatedStorage:WaitForChild("CrowdSyncShared")
local CrowdConfig = require(Shared:WaitForChild("CrowdConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- Force-create remotes on server start
Remotes.getCrowdStateBroadcast()
Remotes.getGameplayEvent()

type CrowdState = {
	id: string,
	position: Vector3,
	radius: number,
	count: number,
	hue: number,
	isBot: boolean,
	velocity: Vector3, -- bot only
	wanderTarget: Vector3, -- bot only
}

local crowds: { [string]: CrowdState } = {}

-- ==========================================================================
-- Crowd lifecycle
-- ==========================================================================

local function radiusForCount(count: number): number
	-- Crowd radius scales ~sqrt(count) to mimic area filling
	return 2.5 + math.sqrt(count) * 0.55
end

local function spawnBotCrowd(slot: number)
	local angle = (slot / CrowdConfig.BOT_CROWD_COUNT) * math.pi * 2
	local r = CrowdConfig.BOT_WANDER_RADIUS * 0.5
	local startPos = Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r)

	local id = `bot_{slot}`
	crowds[id] = {
		id = id,
		position = startPos,
		radius = radiusForCount(CrowdConfig.STARTING_FOLLOWERS_PER_CROWD),
		count = CrowdConfig.STARTING_FOLLOWERS_PER_CROWD,
		hue = ((slot - 1) % 12) + 1,
		isBot = true,
		velocity = Vector3.zero,
		wanderTarget = startPos,
	}
	print(`[CrowdServer] spawned bot crowd {id} at {startPos}`)
end

local function pickNewWanderTarget(state: CrowdState)
	local angle = math.random() * math.pi * 2
	local r = math.random() * CrowdConfig.BOT_WANDER_RADIUS
	state.wanderTarget = Vector3.new(math.cos(angle) * r, state.position.Y, math.sin(angle) * r)
end

-- ==========================================================================
-- Server tick (15 Hz hit detection + broadcast)
-- ==========================================================================

local TICK_INTERVAL = 1 / CrowdConfig.HIT_DETECTION_HZ
local GROWTH_INTERVAL = 1 / CrowdConfig.FOLLOWER_GROWTH_RATE

local lastTick = 0
local lastGrowth = 0
local lastMetricLog = 0

local function updateBotCrowd(state: CrowdState, dt: number)
	-- Wander: move toward wanderTarget, pick new when close
	local toTarget = state.wanderTarget - state.position
	toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
	local dist = toTarget.Magnitude
	if dist < 4 then
		pickNewWanderTarget(state)
		return
	end
	local moveDir = toTarget.Unit
	state.velocity = moveDir * CrowdConfig.BOT_MOVE_SPEED
	state.position = state.position + state.velocity * dt
	state.position = Vector3.new(state.position.X, 4, state.position.Z)
end

local function serverTick()
	local now = os.clock()
	local dt = now - lastTick
	lastTick = now

	-- Move bot crowds
	for _, state in crowds do
		if state.isBot then
			updateBotCrowd(state, dt)
		end
	end

	-- Grow crowds toward MAX
	if now - lastGrowth >= GROWTH_INTERVAL then
		lastGrowth = now
		for _, state in crowds do
			if state.count < CrowdConfig.MAX_FOLLOWERS_PER_CROWD then
				state.count = state.count + 1
				state.radius = radiusForCount(state.count)
			end
		end
	end

	-- Hit detection (not wired to gameplay in prototype — measured only)
	local overlaps = 0
	local ids = {}
	for id in crowds do
		table.insert(ids, id)
	end
	for i = 1, #ids do
		for j = i + 1, #ids do
			local a = crowds[ids[i]]
			local b = crowds[ids[j]]
			local d = (a.position - b.position).Magnitude
			if d < (a.radius + b.radius) then
				overlaps = overlaps + 1
			end
		end
	end

	-- Broadcast crowd state to all clients
	local payload: { [string]: { pos: Vector3, radius: number, count: number, hue: number } } = {}
	for id, state in crowds do
		payload[id] = {
			pos = state.position,
			radius = state.radius,
			count = state.count,
			hue = state.hue,
		}
	end
	Remotes.getCrowdStateBroadcast():FireAllClients(payload)

	-- Metric log
	if now - lastMetricLog >= CrowdConfig.METRIC_LOG_INTERVAL then
		lastMetricLog = now
		local totalCount = 0
		for _, state in crowds do
			totalCount = totalCount + state.count
		end
		print(string.format(
			"[CrowdServer] crowds=%d totalFollowers=%d hitOverlaps=%d memMB=%.1f",
			(function()
				local n = 0
				for _ in crowds do
					n = n + 1
				end
				return n
			end)(),
			totalCount,
			overlaps,
			Stats:GetTotalMemoryUsageMb()
		))
	end
end

-- ==========================================================================
-- Bootstrap
-- ==========================================================================

for i = 1, CrowdConfig.BOT_CROWD_COUNT do
	spawnBotCrowd(i)
end

lastTick = os.clock()
lastGrowth = os.clock()
lastMetricLog = os.clock()

-- Drive tick via Heartbeat but throttle to TICK_INTERVAL
local accumulator = 0
RunService.Heartbeat:Connect(function(dt: number)
	accumulator = accumulator + dt
	if accumulator >= TICK_INTERVAL then
		accumulator = accumulator - TICK_INTERVAL
		serverTick()
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	print(`[CrowdServer] player joined: {player.Name}`)
end)
