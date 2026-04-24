--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Question: Can Roblox handle 800-3000 follower entities across 8-12 players at 60 FPS on mobile?
-- Date: 2026-04-20

-- Client renders all crowds locally. Server state only tells us:
--   { crowdId -> { pos, radius, count, hue } }
--
-- For each crowd we maintain N local follower Parts where N = render cap (function of distance).
-- Flocking via BoidsFlock module. LOD swap by distance.
--
-- Measures FPS, heartbeat time, kbps, part counts. Logs every 2s.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("CrowdSyncShared")
local CrowdConfig = require(Shared:WaitForChild("CrowdConfig"))
local BoidsFlock = require(Shared:WaitForChild("BoidsFlock"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Pretty hues for the 12 signature colors (art bible §4)
local HUE_COLORS: { Color3 } = {
	Color3.fromRGB(255, 45, 120),  -- Hot Pink
	Color3.fromRGB(0, 207, 255),   -- Cyan
	Color3.fromRGB(127, 255, 0),   -- Lime
	Color3.fromRGB(255, 122, 0),   -- Orange
	Color3.fromRGB(0, 85, 255),    -- Electric Blue
	Color3.fromRGB(255, 229, 0),   -- Yellow
	Color3.fromRGB(155, 0, 255),   -- Purple
	Color3.fromRGB(255, 34, 34),   -- Red
	Color3.fromRGB(0, 229, 176),   -- Teal
	Color3.fromRGB(255, 95, 87),   -- Coral
	Color3.fromRGB(0, 255, 153),   -- Mint
	Color3.fromRGB(255, 170, 0),   -- Gold-Yellow
}

-- ==========================================================================
-- State
-- ==========================================================================

type ServerCrowd = {
	pos: Vector3,
	radius: number,
	count: number,
	hue: number,
}

type LocalFollower = {
	part: Part,
	position: Vector3,
	velocity: Vector3,
	currentLod: number, -- 0, 1, 2
}

type LocalCrowd = {
	id: string,
	serverState: ServerCrowd,
	followers: { LocalFollower },
	folder: Folder,
}

local serverCrowds: { [string]: ServerCrowd } = {}
local localCrowds: { [string]: LocalCrowd } = {}

local followerContainer = Instance.new("Folder")
followerContainer.Name = "CrowdSyncFollowers"
followerContainer.Parent = Workspace

-- ==========================================================================
-- Render cap calc
-- ==========================================================================

local function computeRenderCap(distance: number, isOwn: boolean, actualCount: number): number
	local cap: number
	if distance > CrowdConfig.CULL_DISTANCE then
		return 0
	elseif distance > CrowdConfig.LOD_1_MAX then
		cap = CrowdConfig.RENDER_CAP_FAR
	elseif distance > CrowdConfig.LOD_0_MAX then
		cap = CrowdConfig.RENDER_CAP_MEDIUM
	elseif isOwn then
		cap = CrowdConfig.RENDER_CAP_OWN_CLOSE
	else
		cap = CrowdConfig.RENDER_CAP_RIVAL_CLOSE
	end
	return math.min(cap, actualCount)
end

local function lodForDistance(distance: number): number
	if distance <= CrowdConfig.LOD_0_MAX then
		return 0
	elseif distance <= CrowdConfig.LOD_1_MAX then
		return 1
	else
		return 2
	end
end

-- ==========================================================================
-- Follower management
-- ==========================================================================

local function makeFollowerPart(color: Color3, lod: number): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	if lod == 0 then
		part.Size = CrowdConfig.FOLLOWER_SIZE_LOD0
	elseif lod == 1 then
		part.Size = CrowdConfig.FOLLOWER_SIZE_LOD1
	else
		part.Size = CrowdConfig.FOLLOWER_SIZE_LOD2
	end
	return part
end

local function ensureLocalCrowd(id: string, state: ServerCrowd): LocalCrowd
	local existing = localCrowds[id]
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = id
	folder.Parent = followerContainer

	local crowd: LocalCrowd = {
		id = id,
		serverState = state,
		followers = {},
		folder = folder,
	}
	localCrowds[id] = crowd
	return crowd
end

local function resizeCrowdTo(crowd: LocalCrowd, targetCount: number, hue: number, lod: number)
	local color = HUE_COLORS[((hue - 1) % #HUE_COLORS) + 1]
	-- Grow
	while #crowd.followers < targetCount do
		local part = makeFollowerPart(color, lod)
		part.Parent = crowd.folder
		-- Initial position: ring around crowd center
		local angle = math.random() * math.pi * 2
		local r = math.random() * crowd.serverState.radius
		local spawnPos = crowd.serverState.pos
			+ Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		part.CFrame = CFrame.new(spawnPos)
		table.insert(crowd.followers, {
			part = part,
			position = spawnPos,
			velocity = Vector3.zero,
			currentLod = lod,
		})
	end
	-- Shrink
	while #crowd.followers > targetCount do
		local last = table.remove(crowd.followers)
		if last then
			last.part:Destroy()
		end
	end
	-- Update color + LOD for all (may change per frame)
	for _, follower in crowd.followers do
		if follower.currentLod ~= lod then
			follower.part:Destroy()
			local newPart = makeFollowerPart(color, lod)
			newPart.CFrame = CFrame.new(follower.position)
			newPart.Parent = crowd.folder
			follower.part = newPart
			follower.currentLod = lod
		else
			follower.part.Color = color
		end
	end
end

-- ==========================================================================
-- Flocking update
-- ==========================================================================

local function updateCrowdFlock(crowd: LocalCrowd, dt: number)
	-- For each follower, compute boids velocity using crowd's local neighbors
	-- Optimization: only use up to N=8 nearest neighbors rather than full O(n^2)
	-- For prototype, allow O(n^2) within each crowd (expect n ≤ 80 so 6400 ops max per crowd)
	local centerPos = crowd.serverState.pos

	for _, follower in crowd.followers do
		local neighbors: { { position: Vector3, velocity: Vector3 } } = {}
		for _, other in crowd.followers do
			if other ~= follower then
				table.insert(neighbors, { position = other.position, velocity = other.velocity })
			end
		end
		local selfData = { position = follower.position, velocity = follower.velocity }
		follower.velocity = BoidsFlock.step(selfData, neighbors, centerPos, dt)
		follower.position = follower.position + follower.velocity * dt
		follower.position = Vector3.new(follower.position.X, centerPos.Y, follower.position.Z)

		-- Keep inside crowd radius (soft clamp)
		local toCenter = centerPos - follower.position
		local distFromCenter = toCenter.Magnitude
		if distFromCenter > crowd.serverState.radius * 1.2 then
			follower.position = centerPos - toCenter.Unit * crowd.serverState.radius
		end

		follower.part.CFrame = CFrame.new(follower.position)
	end
end

-- ==========================================================================
-- Frame update
-- ==========================================================================

local lastLodCheck = 0
local LOD_CHECK_INTERVAL = 1 / CrowdConfig.LOD_CHECK_HZ

local function updateAllCrowds(dt: number)
	local now = os.clock()
	local cameraPos = camera.CFrame.Position
	local doLodCheck = (now - lastLodCheck) >= LOD_CHECK_INTERVAL
	if doLodCheck then
		lastLodCheck = now
	end

	-- Remove local crowds that server no longer knows about
	for id, crowd in localCrowds do
		if not serverCrowds[id] then
			crowd.folder:Destroy()
			localCrowds[id] = nil
		end
	end

	for id, serverState in serverCrowds do
		local crowd = ensureLocalCrowd(id, serverState)
		crowd.serverState = serverState

		-- Only recompute render cap + LOD periodically (not every frame)
		if doLodCheck then
			local dist = (cameraPos - serverState.pos).Magnitude
			local isOwn = (id == `player_{player.UserId}`) -- prototype has no player crowd yet, always false
			local cap = computeRenderCap(dist, isOwn, serverState.count)
			local lod = lodForDistance(dist)
			resizeCrowdTo(crowd, cap, serverState.hue, lod)
		end

		updateCrowdFlock(crowd, dt)
	end
end

RunService.RenderStepped:Connect(updateAllCrowds)

-- ==========================================================================
-- Server state intake
-- ==========================================================================

Remotes.getCrowdStateBroadcast().OnClientEvent:Connect(function(payload: { [string]: ServerCrowd })
	serverCrowds = payload
end)

-- ==========================================================================
-- Metrics logging
-- ==========================================================================

local frameCount = 0
local frameTimeAccum = 0
local lastLog = os.clock()

RunService.RenderStepped:Connect(function(dt: number)
	frameCount = frameCount + 1
	frameTimeAccum = frameTimeAccum + dt

	local now = os.clock()
	if now - lastLog >= CrowdConfig.METRIC_LOG_INTERVAL then
		local avgFrame = frameTimeAccum / frameCount
		local fps = 1 / avgFrame

		-- Count all rendered Parts
		local partCount = 0
		for _, crowd in localCrowds do
			partCount = partCount + #crowd.followers
		end

		-- Network stats via Stats.DataReceiveKbps
		local kbps = 0
		local receiveStat = Stats:FindFirstChild("DataReceiveKbps")
		if receiveStat and receiveStat:IsA("NumberValue") then
			kbps = receiveStat.Value
		end

		print(string.format(
			"[CrowdClient] FPS=%.1f avgFrameMs=%.2f renderedParts=%d bandwidth=%.2fkbps crowds=%d",
			fps,
			avgFrame * 1000,
			partCount,
			kbps,
			(function()
				local n = 0
				for _ in localCrowds do
					n = n + 1
				end
				return n
			end)()
		))

		frameCount = 0
		frameTimeAccum = 0
		lastLog = now
	end
end)

print("[CrowdClient] started — waiting for server state")
