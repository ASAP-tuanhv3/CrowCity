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
	-- TODO: Initialize your client-side gameplay systems here.
	-- These run after the player's data is loaded and their character has spawned.
	-- Example:
	--   local MyGameplayClient = require(ReplicatedStorage.Source.MyGameplay.MyGameplayClient)
	--   MyGameplayClient.start(characterLoadedWrapper)
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
