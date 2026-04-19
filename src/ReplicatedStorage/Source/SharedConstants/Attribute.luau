--!strict

--[[
	All instance attribute names used by scripts. Reference attributes through this enum
	to avoid typo-prone raw strings. Add entries here for any new attributes your gameplay needs.
--]]

export type EnumType =
	"OwnerId"
	| "ZoneId"
	| "DisplayName"
	| "DescriptionLong"
	| "DescriptionShort"
	| "PurchaseCost"
	| "DeveloperProductId"
	| "CoinBundleSize"
-- TODO: Add your gameplay-specific attribute names here.
-- | "MyAttribute"

local Attribute = {
	OwnerId = "OwnerId" :: "OwnerId",
	ZoneId = "ZoneId" :: "ZoneId",
	DisplayName = "DisplayName" :: "DisplayName",
	DescriptionLong = "DescriptionLong" :: "DescriptionLong",
	DescriptionShort = "DescriptionShort" :: "DescriptionShort",
	PurchaseCost = "PurchaseCost" :: "PurchaseCost",
	DeveloperProductId = "DeveloperProductId" :: "DeveloperProductId",
	CoinBundleSize = "CoinBundleSize" :: "CoinBundleSize",
	-- TODO: Add your gameplay-specific attribute names here.
	-- MyAttribute = "MyAttribute" :: "MyAttribute",
}

return Attribute
