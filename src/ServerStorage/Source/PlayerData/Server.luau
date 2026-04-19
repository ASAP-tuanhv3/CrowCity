--!strict

--[[
	Server-side component of the PlayerData system, which handles key/value based persistent player data.

	Backed by ProfileStore for session locking, auto-saving, and retry logic.

	For more information and wider context, please see PlayerData/Readme.lua
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local ProfileStore = require(ReplicatedStorage.Dependencies.ProfileStore)
local Network = require(ReplicatedStorage.Source.Network)
local Signal = require(ReplicatedStorage.Source.Signal)
local PlayerDataErrorType = require(ReplicatedStorage.Source.PlayerData.PlayerDataErrorType)
local noYield = require(ReplicatedStorage.Source.Utility.noYield)
local safePlayerAdded = require(ReplicatedStorage.Source.Utility.safePlayerAdded)
local copyDeep = require(ReplicatedStorage.Source.Utility.copyDeep)

local DEFAULT_DATA_STORE_NAME = "PlayerData_v2"

export type PlayerData = { [string]: any }

local PlayerDataServer = {}
PlayerDataServer.playerDataUpdated = Signal.new()
PlayerDataServer._playerDataLoadErrors = {} :: { [Player]: string }
PlayerDataServer._threadsPendingPlayerDataLoad = {} :: { [Player]: { thread } }
PlayerDataServer._profiles = {} :: { [Player]: any } -- ProfileStore Profile objects
PlayerDataServer._defaultData = {} :: PlayerData
PlayerDataServer._privateValueNames = {} :: { [string]: boolean }
PlayerDataServer._profileStore = nil :: any
PlayerDataServer._started = false

function PlayerDataServer.start(defaultValue: PlayerData, dataStoreName: string?, privateValueNames: { string }?)
	assert(not PlayerDataServer._started, "PlayerDataServer has already been started")

	dataStoreName = dataStoreName or DEFAULT_DATA_STORE_NAME

	PlayerDataServer._started = true
	PlayerDataServer._defaultData = defaultValue
	PlayerDataServer._profileStore = ProfileStore.New(dataStoreName :: string, defaultValue)

	-- Values defined in privateValueNames will not replicate to the client.
	-- This is useful for sensitive information such as purchase history.
	-- This is passed in when the service is started to prevent these from being declared too late.
	PlayerDataServer._privateValueNames = Freeze.List.toSet(privateValueNames or {})

	PlayerDataServer._listenForPlayers()
end

-- Returns true if the server has finished loading the player's data. This should be called before reading or writing
-- to a player's data. If this returns false, waitForDataLoadAsync can be used to yield until the data has loaded
function PlayerDataServer.hasLoaded(player: Player)
	local hasProfile = PlayerDataServer._profiles[player] and true or false

	return hasProfile
end

-- Returns true if the server is currently loading the player's data
function PlayerDataServer.isLoading(player: Player)
	local threadsPendingLoad = PlayerDataServer._threadsPendingPlayerDataLoad[player]

	if threadsPendingLoad then
		return true
	end

	return false
end

-- Returns true if PlayerDataServer was unable to load the player's data (typically due to a DataStoreService or session lock error)
function PlayerDataServer.hasErrored(player: Player)
	return PlayerDataServer._playerDataLoadErrors[player] and true or false
end

function PlayerDataServer.setValueAsPrivate(valueName: string, isPrivate: boolean)
	PlayerDataServer._privateValueNames[valueName] = isPrivate
end

-- Yields until the Player's data has loaded
-- If the player leaves before their data has loaded, the thread will be discarded
function PlayerDataServer.waitForDataLoadAsync(player: Player)
	PlayerDataServer._threadsPendingPlayerDataLoad[player] = PlayerDataServer._threadsPendingPlayerDataLoad[player]
		or {}

	-- We'll store the thread and resume it in _resumeThreadsPendingLoad when the data loads
	table.insert(PlayerDataServer._threadsPendingPlayerDataLoad[player], coroutine.running())

	coroutine.yield()
end

-- Returns the value of the given valueName in the given player's data
function PlayerDataServer.getValue(player: Player, valueName: string, syncedValueOnly: boolean?): any
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local profile = PlayerDataServer._profiles[player]
	local value

	-- If syncedValue only is passed, the value last loaded or saved to a DataStore successfully will be returned
	-- rather than the latest value loaded in memory. One use case of this is verifying if a purchase has been
	-- recorded _and_ saved to a DataStore in ProcessReceipt implementations
	if syncedValueOnly then
		value = profile.LastSavedData[valueName]
	else
		value = profile.Data[valueName]
	end

	-- Deep copy tables before returning them so the actual value can not be modified from outside of this module
	value = copyDeep(value)

	return value
end

-- Updates the value of the given valueName in the given player's data for the given value
function PlayerDataServer.setValue(player: Player, valueName: string, value: any)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	-- Deep copy tables before saving them so the actual value can not be modified from outside of this module
	if typeof(value) == "table" then
		value = table.freeze(copyDeep(value))
	end

	local profile = PlayerDataServer._profiles[player]
	profile.Data[valueName] = value

	-- We only want to fire an update to the client if this valueName has not been marked as private
	-- with PlayerDataServer.setValueAsPrivate
	if not PlayerDataServer._privateValueNames[valueName] then
		Network.fireClient(Network.RemoteEvents.PlayerDataUpdated, player, valueName, value)
	end

	PlayerDataServer.playerDataUpdated:Fire(player, valueName, value)
end

-- Transforms the value of the given valueName for the given player with a callback, similar to
-- DataStore:UpdateAsync
function PlayerDataServer.updateValue(player: Player, valueName: string, transformFunction: (any) -> any)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local oldValue = PlayerDataServer.getValue(player, valueName)

	-- This is not an async function, so we need to prohibit yielding here
	local newValue = noYield(transformFunction, oldValue)

	-- For consistency with DataStore:UpdateAsync, we will treat a nil return as an update abort
	if newValue then
		PlayerDataServer.setValue(player, valueName, newValue)
	end
end

-- Removes the given valueName from the given player's data
function PlayerDataServer.removeValue(player: Player, valueName: string)
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local oldValue = PlayerDataServer.getValue(player, valueName)
	PlayerDataServer.setValue(player, valueName, nil)

	return oldValue
end

-- Sets the metadata for the given player that will be applied to the DataStore key associated with this player's data
function PlayerDataServer.setMetaData(player: Player, metadata: { [string]: any })
	assert(PlayerDataServer.hasLoaded(player), "The player's data has not loaded")

	local profile = PlayerDataServer._profiles[player]
	for key, value in pairs(metadata) do
		profile.RobloxMetaData[key] = value
	end
end

function PlayerDataServer._listenForPlayers()
	safePlayerAdded(function(newPlayer: Player)
		PlayerDataServer._onPlayerAddedAsync(newPlayer)
	end)
end

function PlayerDataServer._onPlayerAddedAsync(player: Player)
	local profile = PlayerDataServer._profileStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- StartSessionAsync returned nil — the server is shutting down, the player left, or there was an error
		-- Allow the player to play with default data but mark as errored so saving is disabled
		PlayerDataServer._playerDataLoadErrors[player] = PlayerDataErrorType.SessionLocked
		PlayerDataServer._sendLoadedData(player)
		return
	end

	-- GDPR compliance: associate UserId with profile
	profile:AddUserId(player.UserId)

	-- Fill in missing keys from the template
	profile:Reconcile()

	-- If another server steals the session or the server shuts down, kick the player
	profile.OnSessionEnd:Connect(function()
		-- Only kick if we haven't already cleaned up (e.g. during PlayerRemoving)
		if PlayerDataServer._profiles[player] then
			PlayerDataServer._profiles[player] = nil
			player:Kick("Profile session ended — please rejoin")
		end
	end)

	-- The player may have left while we were yielding for StartSessionAsync
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	PlayerDataServer._profiles[player] = profile

	PlayerDataServer._sendLoadedData(player)
end

-- Sends a payload to PlayerDataClient including the data loaded and the error type (if there was a failure to load)
function PlayerDataServer._sendLoadedData(player: Player)
	-- We don't want to do anything further if the player has already left
	if not player:IsDescendantOf(Players) then
		return
	end

	local errorType = PlayerDataServer._playerDataLoadErrors[player]
	local data

	if PlayerDataServer._profiles[player] then
		-- We want to filter out any values that we have marked as private so they are not replicated to the client
		data = Freeze.Dictionary.filter(
			copyDeep(PlayerDataServer._profiles[player].Data),
			function(_: boolean, valueName: string)
				return not PlayerDataServer._privateValueNames[valueName]
			end
		) :: PlayerData
	else
		-- Errored load — send default data filtered by private values
		data = Freeze.Dictionary.filter(
			copyDeep(PlayerDataServer._defaultData),
			function(_: boolean, valueName: string)
				return not PlayerDataServer._privateValueNames[valueName]
			end
		) :: PlayerData
	end

	local success = errorType == nil

	-- Now the data has loaded, we want to resume any threads that were yielded by PlayerDataServer.waitForDataLoadAsync
	PlayerDataServer._resumeThreadsPendingLoad(player)

	Network.fireClient(Network.RemoteEvents.PlayerDataLoaded, player, data, success, errorType)
end

-- Resumes any threads that were yielded by PlayerData:waitForDataLoadAsync()
function PlayerDataServer._resumeThreadsPendingLoad(player: Player)
	if PlayerDataServer._threadsPendingPlayerDataLoad[player] then
		for _, thread in ipairs(PlayerDataServer._threadsPendingPlayerDataLoad[player]) do
			task.spawn(thread)
		end
	end

	PlayerDataServer._threadsPendingPlayerDataLoad[player] = nil
end

-- Performs a final save and removes session data for the player from PlayerDataServer
function PlayerDataServer.onPlayerRemovingAsync(player: Player)
	local profile = PlayerDataServer._profiles[player]

	-- Clear out saved values for this player to avoid memory leaks and prevent OnSessionEnd from double-kicking
	PlayerDataServer._profiles[player] = nil
	PlayerDataServer._playerDataLoadErrors[player] = nil
	PlayerDataServer._threadsPendingPlayerDataLoad[player] = nil

	if profile then
		-- EndSession triggers a final save and releases the session lock
		profile:EndSession()
	end
end

-- In some cases, we may wish to prompt a save from outside of the auto-save loop
-- For example, after a purchase we may wish to save straight away
-- Returns success, result
function PlayerDataServer.saveDataAsync(player: Player): (boolean, string?)
	assert(PlayerDataServer.canSave(player), "Player data cannot currently be saved")

	local profile = PlayerDataServer._profiles[player]

	-- Use OnAfterSave to detect when the save completes, with a timeout fallback
	local saved = false
	local connection
	connection = profile.OnAfterSave:Connect(function()
		saved = true
		connection:Disconnect()
	end)

	-- Trigger an immediate save
	profile:Save()

	-- Wait for the save to complete or for the profile to become inactive
	local MAX_WAIT = 30
	local startTime = os.clock()

	while not saved and os.clock() - startTime < MAX_WAIT do
		if not profile:IsActive() then
			connection:Disconnect()

			if player:IsDescendantOf(Players) then
				Network.fireClient(Network.RemoteEvents.PlayerDataSaved, player, false, PlayerDataErrorType.DataStoreError)
			end
			return false, "Profile became inactive during save"
		end

		task.wait(0.5)
	end

	connection:Disconnect()

	if saved then
		if player:IsDescendantOf(Players) then
			Network.fireClient(Network.RemoteEvents.PlayerDataSaved, player, true, nil)
		end
		return true, nil
	end

	-- Timed out waiting for save confirmation
	if player:IsDescendantOf(Players) then
		Network.fireClient(Network.RemoteEvents.PlayerDataSaved, player, false, PlayerDataErrorType.DataStoreError)
	end
	return false, "Save timed out"
end

-- Returns if it is safe to save the player's data
function PlayerDataServer.canSave(player: Player)
	local profile = PlayerDataServer._profiles[player]

	if not profile then
		return false
	end

	if not profile:IsActive() then
		return false
	end

	if PlayerDataServer.hasErrored(player) then
		return false
	end

	return true
end

return PlayerDataServer
