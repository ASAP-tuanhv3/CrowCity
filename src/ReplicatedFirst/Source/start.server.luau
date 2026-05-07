--!strict

--[[
	The client-side entry point for all code in the experience.

	Boot sequence:
	  1. Show loading screen
	  2. Wait for all game content to load
	  3. Start network, load player data, wait for character
	  4. TODO: Start your gameplay systems here
	  5. Start UI and FTUE
	  6. Hide loading screen
--]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LoadingScreen = require(ReplicatedFirst.Source.LoadingScreen)
local waitForGameLoadedAsync = require(ReplicatedFirst.Source.Utility.waitForGameLoadedAsync)

local localPlayer = Players.LocalPlayer :: Player

local function preGameLoadTasksAsync()
	LoadingScreen.enableAsync()
	LoadingScreen.updateDetailText("Loading...")
end

local function startClientGameplay()
	-- CrowdStateClient.start() wired earlier in postGameLoadTasksAsync (immediately
	-- after Network.startClientAsync) so subscribers are live before character/data wait.

	-- FollowerEntity client simulation orchestrator (Sprint 4 / Stories 4-2..4-12).
	-- Singleton: init() subscribes to CrowdStateClient.CrowdCreated/Eliminated;
	-- start() begins the single RenderStepped loop iterating all active crowds.
	-- Per ADR-0007 §Three-Module Split + ADR-0002 §audit-no-competing-heartbeat.
	local CrowdManagerClient = require(ReplicatedStorage.Source.FollowerEntity.CrowdManagerClient)
	local Pool               = require(ReplicatedStorage.Source.FollowerEntity.Pool)
	local DefaultSkin        = require(ReplicatedStorage.Source.SharedConstants.DefaultSkin)
	local FollowerPoolConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerPoolConfig)

	-- Pool folder hosts inactive (parked) follower bundles per ADR-0007 §Pool
	-- Allocation Strategy. Hidden under workspace; pool grants/returns reparent
	-- bundles between this folder and the active crowd folder.
	local poolFolder = workspace:FindFirstChild(FollowerPoolConfig.POOL_FOLDER_NAME)
	if poolFolder == nil then
		poolFolder = Instance.new("Folder")
		poolFolder.Name = FollowerPoolConfig.POOL_FOLDER_NAME
		poolFolder.Parent = workspace
	end

	-- Pre-allocate the Pool. initAsync yields task.wait per batch; runs ~25 Parts/frame
	-- so the load doesn't spike. Skin System (VS-tier) will replace DefaultSkin
	-- providers — same Pool API, different templateProviders.
	local pool = Pool.new({
		bodyCapacity         = FollowerPoolConfig.POOL_PREALLOC_LOD0_BODY,
		hatCapacity          = FollowerPoolConfig.POOL_PREALLOC_LOD0_HAT,
		parent               = poolFolder,
		bodyTemplateProvider = DefaultSkin.getBodyTemplate,
		hatTemplateProvider  = DefaultSkin.getHatTemplate,
		headOffsetY          = FollowerPoolConfig.HEAD_OFFSET_Y,
		batchSize            = FollowerPoolConfig.POOL_BATCH_SIZE,
		logger               = nil,
	})
	pool:initAsync()

	CrowdManagerClient:init()
	CrowdManagerClient:setPool(pool)
	CrowdManagerClient:start()

	-- Optional: AC-17 perf-soak fixture. Guarded by FollowerPerfFixtureEnabled
	-- Workspace attribute. No-op in normal builds. Must run AFTER
	-- CrowdManagerClient:start() so signal subscriptions are live.
	local PerfFixture = require(ReplicatedFirst.Source.PerfFixture)
	PerfFixture.start()
end

local function startPostLoadingSystem()
	-- TODO: Start any systems that should run after the loading screen is hidden.
	-- Example:
	--   local MyPostLoadSystem = require(ReplicatedStorage.Source.MyPostLoadSystem)
	--   MyPostLoadSystem.start()
end

local function postGameLoadTasksAsync()
	-- In-line requires are intentional here: we are in ReplicatedFirst and cannot
	-- guarantee these modules exist until waitForGameLoadedAsync has returned.
	local Network = require(ReplicatedStorage.Source.Network)
	local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
	local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
	local FtueManagerClient = require(ReplicatedStorage.Source.FtueManagerClient)
	local DevProductPriceList = require(ReplicatedStorage.Source.DevProductPriceList)

	LoadingScreen.updateDetailText("Waiting for network...")
	Network.startClientAsync()

	-- CRB story-002+003: wire CrowdStateClient subscribers immediately after Network is up.
	-- Must NOT wait for PlayerData / character loaded — broadcast can arrive at any time
	-- post-Network.startClientAsync, and missing the first CrowdCreated reliable would
	-- leave FollowerEntity inert. Idempotent — safe to call before startClientGameplay.
	require(ReplicatedStorage.Source.CrowdStateClient).start()

	PlayerDataClient.start()

	if not PlayerDataClient.hasLoaded() then
		LoadingScreen.updateDetailText("Finding your data...")
		PlayerDataClient.loaded:Wait()
	end

	LoadingScreen.updateDetailText("Fetching products...")
	DevProductPriceList.setupAsync()

	local characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)
	if not characterLoadedWrapper:isLoaded() then
		LoadingScreen.updateDetailText("Spawning character...")
		characterLoadedWrapper.loaded:Wait()
	end

	startClientGameplay()
	FtueManagerClient.start()

	LoadingScreen.updateDetailText("Finishing up...")
	LoadingScreen.disableAsync()

	startPostLoadingSystem()
end

preGameLoadTasksAsync()
waitForGameLoadedAsync()
postGameLoadTasksAsync()
