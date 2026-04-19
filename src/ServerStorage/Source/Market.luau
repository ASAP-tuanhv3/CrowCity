--!strict

--[[
	Server-side market. Handles soft currency (Coins) item purchases via the
	RequestItemPurchase RemoteFunction. Items must exist as prefabs under
	ReplicatedStorage/Instances/<category>/ with a PurchaseCost attribute.

	TODO: Customize this module for your game:
	  - Change the currency name/key if "Coins" doesn't fit your game
	  - Add item validation logic specific to your game rules
	  - Add selling mechanics: create Market.itemsSold = Signal.new() and a sell function
	  - Hook up EconomyAnalytics to track currency flow
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
-- TODO: Uncomment to track economy analytics:
-- local EconomyAnalytics = require(ServerStorage.Source.Analytics.EconomyAnalytics)
local Signal = require(ReplicatedStorage.Source.Signal)
local Network = require(ReplicatedStorage.Source.Network)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local ItemPurchaseFailureReason =
	require(ReplicatedStorage.Source.SharedConstants.RequestFailureReason.ItemPurchaseFailureReason)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local ContainerByCategory = require(ReplicatedStorage.Source.SharedConstants.ContainerByCategory)

local t = Network.t
local RemoteFunctions = Network.RemoteFunctions

local Market = {}

-- Fires when a player purchases an item: (player, itemId, itemCategory, amount)
Market.itemsPurchased = Signal.new()

-- TODO: Add your own signals here for selling mechanics.
-- Example: Market.itemsSold = Signal.new()  -- (player, itemId, amount, totalValue)

function Market.start()
	Network.bindFunction(RemoteFunctions.RequestItemPurchase, function(...)
		return Market._onRequestItemPurchase(...)
	end, t.tuple(t.instanceOf("Player"), t.string, t.string, t.intersection(t.integer, t.numberPositive)))
end

function Market._onRequestItemPurchase(
	player: Player,
	itemId: string,
	itemCategory: ItemCategory.EnumType,
	amount: number
): (boolean, ItemPurchaseFailureReason.EnumType?)
	assert(PlayerDataServer.hasLoaded(player), "Player attempted to purchase an item before data was loaded")

	if not ItemCategory[itemCategory] then
		return false, ItemPurchaseFailureReason.InvalidItemCategory
	end

	local container = ContainerByCategory[itemCategory]
	if not container then
		return false, ItemPurchaseFailureReason.InvalidItemCategory
	end

	local itemModel = container:FindFirstChild(itemId)
	if not itemModel then
		warn(string.format(
			"Purchase request from %s: item '%s' not found in category '%s'",
			player.Name, itemId, itemCategory
		))
		return false, ItemPurchaseFailureReason.InvalidItemId
	end

	local purchaseCost: number = getAttribute(itemModel, Attribute.PurchaseCost)
	local totalCost = purchaseCost * amount
	local withdrawSuccessful = false

	PlayerDataServer.updateValue(player, PlayerDataKey.Coins, function(numCurrencyMaybe: number?)
		local numCurrency = (numCurrencyMaybe or 0) - totalCost
		if numCurrency < 0 then
			return nil
		end
		withdrawSuccessful = true
		return numCurrency
	end)

	if not withdrawSuccessful then
		return false, ItemPurchaseFailureReason.InsufficientFunds
	end

	PlayerDataServer.updateValue(player, PlayerDataKey.Inventory, function(
		inventory: { [string]: { [string]: number } }
	)
		local itemCountById: { [string]: number } = inventory[itemCategory] or {}
		local itemCount = itemCountById[itemId] or 0
		itemCount += amount
		itemCountById[itemId] = itemCount
		inventory[itemCategory] = itemCountById
		return inventory
	end)

	-- TODO: Uncomment to track economy analytics:
	-- local endingBalance = PlayerDataServer.getValue(player, PlayerDataKey.Coins)
	-- EconomyAnalytics.logItemPurchased(player, itemId, itemCategory, endingBalance, totalCost)

	Market.itemsPurchased:Fire(player, itemId, itemCategory, amount)

	return true
end

return Market
