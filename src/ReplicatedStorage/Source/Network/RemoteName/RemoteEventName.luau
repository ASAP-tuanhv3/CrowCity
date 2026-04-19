--!strict

--[[
	Names of all RemoteEvents. One RemoteEvent is created per entry at startup.
	Never reference remote names as raw strings — always use this enum.

	To add a new event:
	  1. Add a value to the EnumType union and the table below
	  2. Fire from client: Network.fireServer(RemoteEventName.MyEvent, ...)
	     Fire from server: Network.fireClient(player, RemoteEventName.MyEvent, ...)
	  3. Listen on server: Network.connectEvent(RemoteEventName.MyEvent, handler)
--]]

export type EnumType =
	"PlayerDataLoaded"
	| "PlayerDataUpdated"
	| "PlayerDataSaved"
	| "ResetData"
-- TODO: Add your gameplay remote event names here.
-- | "MyGameplayEvent"

local RemoteEventName = {
	PlayerDataLoaded = "PlayerDataLoaded" :: "PlayerDataLoaded",
	PlayerDataUpdated = "PlayerDataUpdated" :: "PlayerDataUpdated",
	PlayerDataSaved = "PlayerDataSaved" :: "PlayerDataSaved",
	ResetData = "ResetData" :: "ResetData",
	-- TODO: Add your gameplay remote event names here.
	-- MyGameplayEvent = "MyGameplayEvent" :: "MyGameplayEvent",
}

return RemoteEventName
