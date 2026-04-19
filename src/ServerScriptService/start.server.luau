--!strict

--[[
	Server-side entry point. Initializes all server modules in the correct order.

	Boot sequence:
	  1. Start network and player data system
	  2. Register dev products (Robux purchases)
	  3. TODO: Start your global server-side gameplay systems here
	  4. Per PlayerAdded: load data, register objects, TODO start gameplay, spawn character
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local Market = require(ServerStorage.Source.Market)
local FtueManagerServer = require(ServerStorage.Source.FtueManagerServer)
local CharacterSpawner = require(ServerStorage.Source.CharacterSpawner)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local DefaultPlayerData = require(ServerStorage.Source.DefaultPlayerData)
local ReceiptProcessor = require(ServerStorage.Source.ReceiptProcessor)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local SoundManager = require(ReplicatedStorage.Source.SoundManager)
local safePlayerAdded = require(ReplicatedStorage.Source.Utility.safePlayerAdded)

print("To test, ensure this place is published and Enable Studio Access to API Services is enabled")

Network.startServer()
PlayerDataServer.start(DefaultPlayerData, "PlayerData_v2", { ReceiptProcessor.receiptHistoryValueName })

-- TODO: Initialize your global server-side gameplay systems here.
-- Example:
--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
--   MyGameplayServer.start()

local function onPlayerAdded(player: Player)
	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	PlayerObjectsContainer.registerPlayer(player)

	-- TODO: Initialize per-player server-side gameplay systems here.
	-- Example:
	--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
	--   MyGameplayServer.createPlayerData(player)

	FtueManagerServer.onPlayerAdded(player)
	CharacterSpawner.startRespawnLoop(player)
end

safePlayerAdded(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player)
	CharacterSpawner.stopRespawnLoop(player)

	-- TODO: Clean up per-player server-side gameplay systems here.
	-- Example:
	--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
	--   MyGameplayServer.destroyPlayerData(player)

	PlayerObjectsContainer.unregisterPlayer(player)
	PlayerDataServer.onPlayerRemovingAsync(player)
end)

Market.start()
SoundManager:SetUp()

-- Studio-only: allows a developer to wipe and reset their own data for testing
Network.connectEvent(Network.RemoteEvents.ResetData, function(player: Player)
	local character = player.Character
	if not character then
		return
	end

	CharacterSpawner.stopRespawnLoop(player)
	player.Character = nil;
	(character :: Model):Destroy()

	PlayerObjectsContainer.unregisterPlayer(player)

	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	for _, key in pairs(PlayerDataKey) do
		PlayerDataServer.setValue(player, key, DefaultPlayerData[key])
	end

	onPlayerAdded(player)
end, Network.t.instanceOf("Player"))
