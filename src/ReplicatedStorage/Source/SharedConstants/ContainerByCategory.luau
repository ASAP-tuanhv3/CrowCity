--!strict

--[[
	Maps ItemCategory values to their Instances/ subfolder in ReplicatedStorage.
	Used by Market.luau to look up item prefabs by category + itemId.

	When you add a new ItemCategory, add a corresponding folder under
	ReplicatedStorage/Instances/ and add an entry here.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(script.Parent.ItemCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local ContainerByCategory: { [string]: Folder } = {
	[ItemCategory.CoinBundles] = getInstance(ReplicatedStorage, "Instances", "CoinBundles"),
	-- TODO: Add entries for your game-specific item categories here.
	-- [ItemCategory.MyItemCategory] = getInstance(ReplicatedStorage, "Instances", "MyItemCategory"),
}

return ContainerByCategory
