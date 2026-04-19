--!strict

--[[
	Tracks in-game economy events via AnalyticsService.
	This populates economy charts in Creator Hub's analytics pages.

	To enable: uncomment the EconomyAnalytics import and calls in Market.luau.

	Common economy events to track:
	  - Item purchases (Coins spent)
	  - Item sales (Coins earned)
	  - Robux bundle purchases (Coins granted from IAP)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local EconomyAnalytics = {}

-- TODO: Add your economy tracking functions. Example:

function EconomyAnalytics.logItemPurchased(
	player: Player,
	itemId: string,
	itemCategory: string,
	endingBalance: number,
	amount: number
)
	AnalyticsService:LogEconomyEvent(
		player,
		Enum.AnalyticsEconomyFlowType.Sink,
		PlayerDataKey.Coins,
		amount,
		endingBalance,
		Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
		itemId,
		{
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = itemCategory,
		}
	)
end

-- function EconomyAnalytics.logItemSold(player, itemId, endingBalance, amount)
-- 	AnalyticsService:LogEconomyEvent(
-- 		player,
-- 		Enum.AnalyticsEconomyFlowType.Source,
-- 		PlayerDataKey.Coins,
-- 		amount,
-- 		endingBalance,
-- 		Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
-- 		itemId
-- 	)
-- end

return EconomyAnalytics
