--!strict

--[[
	Default data for a brand-new player. Every key in PlayerDataKey must have an entry here.
	This is also used as the reset target when a developer wipes data in Studio.

	MVP schema LOCKED at 7 keys + _schemaVersion meta per ADR-0011 (Amended 2026-04-27).
	Bidirectional consistency with PlayerDataKey.luau enforced at /story-done.

	`_schemaVersion` is the meta key — present here for ProfileStore migration dispatch
	but intentionally NOT enumerated in PlayerDataKey.luau (it's not a player-data key
	consumers read; it's profile metadata).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local DefaultPlayerData: { [string]: any } = {
	-- Schema metadata (ProfileStore migration dispatch reads this on profile load).
	_schemaVersion = 1,

	-- MVP schema (7 keys per ADR-0011 §MVP PlayerDataKey Schema):
	[PlayerDataKey.Coins] = 0,
	[PlayerDataKey.OwnedSkins] = {} :: { [string]: true }, -- set-style: [skinId] = true
	[PlayerDataKey.SelectedSkin] = "Default",
	[PlayerDataKey.LifetimeAbsorbs] = 0,
	[PlayerDataKey.LifetimeWins] = 0,
	[PlayerDataKey.FtueStage] = FtueStage.Stage1,
	[PlayerDataKey.Inventory] = {} :: {
		[string]: { -- [category]: countByItemId (cosmetic categories ONLY per Amendment 1)
			[string]: number, -- [itemId]: count
		},
	},
}

return DefaultPlayerData
