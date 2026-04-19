--!strict

--[[
	Keys used by the PlayerData system. Every top-level value persisted per player
	needs an entry here. Add a new key here and a default value in DefaultPlayerData.luau.
--]]

export type EnumType = "Coins" | "FtueStage" | "Inventory"
-- TODO: Add your gameplay data keys here.
-- | "MyGameplayData"

local PlayerDataKey = {
	Coins = "Coins" :: "Coins",
	FtueStage = "FtueStage" :: "FtueStage",
	Inventory = "Inventory" :: "Inventory",
	-- TODO: Add your gameplay data keys here.
	-- MyGameplayData = "MyGameplayData" :: "MyGameplayData",
}

return PlayerDataKey
