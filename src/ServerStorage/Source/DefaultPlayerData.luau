--!strict

--[[
	Default data for a brand-new player. Every key in PlayerDataKey must have an entry here.
	This is also used as the reset target when a developer wipes data in Studio.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local DefaultPlayerData: { [string]: any } = {
	[PlayerDataKey.Coins] = 0,
	[PlayerDataKey.FtueStage] = FtueStage.Stage1,
	[PlayerDataKey.Inventory] = {} :: {
		[string]: { -- [category]: countByItemId
			[string]: number, -- [itemId]: count
		},
	},
	-- TODO: Add default values for your gameplay data keys here.
	-- [PlayerDataKey.MyGameplayData] = {},
}

return DefaultPlayerData
