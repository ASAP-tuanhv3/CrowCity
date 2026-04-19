--!strict

--[[
	Categories of purchasable items. Each category maps to a folder under
	ReplicatedStorage/Instances/ containing that category's item prefabs.

	CoinBundles is reserved for hard currency (Robux) bundles.

	To add a new category:
	  1. Add a value here
	  2. Create a matching folder in ReplicatedStorage/Instances/
	  3. Add an entry in ContainerByCategory.luau
--]]

export type EnumType = "CoinBundles"
-- TODO: Add your game-specific item categories here.
-- | "MyItemCategory"

local ItemCategory = {
	CoinBundles = "CoinBundles" :: "CoinBundles",
	-- TODO: Add your game-specific item categories here.
	-- MyItemCategory = "MyItemCategory" :: "MyItemCategory",
}

return ItemCategory
