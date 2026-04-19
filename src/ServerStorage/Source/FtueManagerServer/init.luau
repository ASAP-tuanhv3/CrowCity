--!strict

--[[
	Server-side FTUE orchestrator. Runs stage handlers sequentially as a player
	progresses through onboarding. Each handler's handleAsync() yields until
	the stage completion condition is met, then returns the next FtueStage.

	To add a new FTUE stage:
	  1. Add a value to FtueStage.luau
	  2. Create StageHandlers/<StageName>FtueStage.luau with handleAsync(player) -> FtueStage.EnumType?
	  3. Register it in handlerByStage below
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
-- TODO: Uncomment to track FTUE funnel analytics:
-- local FtueAnalytics = require(ServerStorage.Source.Analytics.FtueAnalytics)
local Stage1FtueStage = require(script.StageHandlers.Stage1FtueStage)
local Stage2FtueStage = require(script.StageHandlers.Stage2FtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

type FtueStageHandler = {
	handleAsync: (Player) -> FtueStage.EnumType?,
}

local handlerByStage: { [FtueStage.EnumType]: FtueStageHandler } = {
	[FtueStage.Stage1] = Stage1FtueStage,
	[FtueStage.Stage2] = Stage2FtueStage,
	-- TODO: Register additional stage handlers here.
}

local FtueManagerServer = {}

function FtueManagerServer.onPlayerAdded(player: Player)
	local ftueStage = PlayerDataServer.getValue(player, PlayerDataKey.FtueStage)
	FtueManagerServer._updateFtueStage(player, ftueStage)
end

function FtueManagerServer._updateFtueStage(player: Player, ftueStage: FtueStage.EnumType?)
	PlayerDataServer.setValue(player, PlayerDataKey.FtueStage, ftueStage)

	if not ftueStage or ftueStage == FtueStage.Complete then
		return
	end

	-- TODO: Uncomment to track FTUE funnel analytics:
	-- FtueAnalytics.logFtueStage(player, ftueStage)

	task.spawn(function()
		local stageHandler = handlerByStage[ftueStage :: FtueStage.EnumType]
		if not stageHandler then
			warn(string.format("No FTUE handler registered for stage: %s", ftueStage))
			return
		end

		local nextStage: FtueStage.EnumType? = stageHandler.handleAsync(player)
		FtueManagerServer._updateFtueStage(player, nextStage)
	end)
end

return FtueManagerServer
