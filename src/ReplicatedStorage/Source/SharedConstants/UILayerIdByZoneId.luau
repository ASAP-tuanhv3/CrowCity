--!strict

--[[
	Maps ZoneIds to UILayerIds. When a player enters a zone, UIZoneHandler automatically
	opens the mapped UI layer. When they leave, it closes.

	To connect a zone to a UI panel:
	  1. Add a zone ID to ZoneIdTag.luau
	  2. Tag a part in Workspace with ZonePartTag and set its ZoneId attribute
	  3. Add an entry here: [ZoneIdTag.MyZone] = UILayerId.MyPanel
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)

local UILayerIdByZoneId: { [ZoneIdTag.EnumType]: UILayerId.EnumType } = {
	-- TODO: Connect your zones to UI layers here.
	-- Example: [ZoneIdTag.InShop] = UILayerId.BuyCoins,
}

return UILayerIdByZoneId
