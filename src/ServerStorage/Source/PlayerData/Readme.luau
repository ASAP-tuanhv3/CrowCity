--[[
	Player Data System

	*Background*

	Although Roblox provides low-level APIs to interface with DataStores via DataStoreService, the most
	common use case is for saving and loading player 'profile' data. That is, data associated with the
	player's progress, purchases, and play session data to allow persistence between individual sessions.

	This system is backed by ProfileStore (https://madstudioroblox.github.io/ProfileStore/), which handles:

	- Session Locking: Ensures only one server can write to a player's data at a time
	- Auto-Saving: Automatically saves profile data periodically (default 300s)
	- Retry Logic: Automatically retries failed DataStore operations with exponential backoff
	- BindToClose: Automatically saves and releases all profiles on server shutdown

	On top of ProfileStore, the PlayerData system provides:

	- In-Memory API: Key/value based get/set/update API for working with player data in memory
	- Replication: Automatic replication of data changes to the client via remotes
	- Private Values: Ability to mark certain values as private (not replicated to client)
	- Error Handling: Graceful fallback to default data when loading fails

	*Key Files*

	- PlayerData/Server.lua: The server-side entry point, wraps ProfileStore with the public API
	- PlayerData/Client.lua: The client-side entry point, provides read-only access and change events
	- PlayerData/DefaultPlayerData.lua: The default player data template

	*Overview*

	- Player data is represented as a dictionary of top level values.
	- Player data will be loaded when the player joins the game, and a fallback
	- Each value can be accessed by its valueName using the get / getValue functions on PlayerDataServer / PlayerDataClient (see below)
	- Values can be updated using PlayerDataServer, and the changes will replicate to PlayerDataClient

	*Usage*

	- The service is started with a default data object and the name of the DataStore to save to
		PlayerDataServer.start({coins = 0}, "PlayerData_v2")

	- Before the first use for a given player, always ensure the data has loaded

		-- Server:
		if not PlayerDataServer.hasLoaded(player) then
			PlayerDataServer.waitForDataLoadAsync(player)
		end
		-- Client:
		if not PlayerDataClient.hasLoaded() then
			PlayerDataClient.loaded:Wait()
		end

	- Values can be read, set or updated on the server

		local value = PlayerDataServer.getValue(player, "valueName)
		PlayerDataServer.setValue(player, "valueName", value)
		PlayerDataServer.updateValue(player, "valueName, function(oldValue)
			return oldValue + 1
		end)
		PlayerDataServer.removeValue(player, "valueName")

	- Values can be read on the client, but not set or updated

		PlayerDataClient.get("valueName")

	- Changes to values on both the client and the server can be subscribed to via events

		-- Server:
		PlayerDataServer.playerDataUpdated:Connect(function(player, valueName, value) end)
		-- Client:
		PlayerDataClient.updated:Connect(function(valueName, value) end)

		- Values can be set as private on the server when PlayerDataServer is started. For example:
		PlayerDataServer.start(defaultData, dataStoreName, {"purchaseHistory", "banHistory"})

	- Saving is done automatically by ProfileStore, and when the player leaves, but can also be
	  triggered and waited for manually

		PlayerDataServer.saveDataAsync(player)

	- Whether a player's data has loaded correctly (or is using a default fallback) can be queried
	  on the client and the server (useful for showing error messages)

		-- Server:
		local hasErrored = PlayerDataServer.hasErrored(player)
		-- Client:
		local hasErrored = PlayerDataClient.hasLoadingErrored(player)
		local loadErrorType = hasErrored and PlayerDataClient.getLoadError()

	- The client can query whether its last save was successful (useful for showing error messages)
		local hasSavingErrored = PlayerDataClient.hasSavingErrored(player)
		local saveErrorType = hasSavingErrored and PlayerDataClient.getSaveError()
		-- OR
		PlayerDataClient.saved:Connect(function(success, errorType) end)
--]]
