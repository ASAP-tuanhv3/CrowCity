--!strict

--[[
	Server-side handler for FTUE Stage 1.

	handleAsync() should yield until the player completes the stage's objective,
	then return the next FtueStage value (or FtueStage.Complete for the final stage).

	Common completion condition patterns:

	  Wait for a market purchase:
	    repeat
	      local buyer, itemId, itemCategory = Market.itemsPurchased:Wait()
	    until buyer == player and itemCategory == ItemCategory.MyCategory

	  Wait for a custom gameplay event:
	    repeat
	      local eventPlayer = MyGameplayServer.objectCollected:Wait()
	    until eventPlayer == player

	  Wait for zone entry (via ZoneHandler tagging):
	    local CollectionService = game:GetService("CollectionService")
	    repeat
	      local instance = CollectionService:GetInstanceAddedSignal(ZoneIdTag.MyZone):Wait()
	    until instance == player.Character
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

local Stage1FtueStage = {}

function Stage1FtueStage.handleAsync(player: Player): FtueStage.EnumType?
	-- TODO: Yield here until the player completes Stage 1's objective.
	-- Return the next stage when done.

	return FtueStage.Stage2
end

return Stage1FtueStage
