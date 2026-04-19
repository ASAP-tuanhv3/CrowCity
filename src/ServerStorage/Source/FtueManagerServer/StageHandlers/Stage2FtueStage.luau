--!strict

--[[
	Server-side handler for FTUE Stage 2.

	handleAsync() should yield until the player completes the stage's objective,
	then return FtueStage.Complete (or nil) to end the tutorial.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

local Stage2FtueStage = {}

function Stage2FtueStage.handleAsync(player: Player): FtueStage.EnumType?
	-- TODO: Yield here until the player completes Stage 2's objective.
	-- Return FtueStage.Complete (or nil) to end the FTUE.

	return FtueStage.Complete
end

return Stage2FtueStage
