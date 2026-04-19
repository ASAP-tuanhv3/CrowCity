--!strict

--[[
	Client-side FTUE manager. Listens to FtueStage changes in PlayerData and
	activates/deactivates the corresponding stage handler.

	Each handler has:
	  setup()    -- called when the player enters the stage; show hints, highlights, paths
	  teardown() -- called when the player leaves the stage; clean up everything from setup

	To add a new FTUE stage:
	  1. Add a value to FtueStage.luau
	  2. Create StageHandlers/<StageName>FtueStage.luau with setup() and teardown()
	  3. Register it in handlerByStage below
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local Stage1FtueStage = require(script.StageHandlers.Stage1FtueStage)
local Stage2FtueStage = require(script.StageHandlers.Stage2FtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

type Stage = {
	setup: () -> (),
	teardown: () -> (),
}

local handlerByStage: { [string]: Stage } = {
	[FtueStage.Stage1] = Stage1FtueStage,
	[FtueStage.Stage2] = Stage2FtueStage,
	-- TODO: Register additional stage handlers here.
}

local FtueManagerClient = {}
FtueManagerClient.activeStage = nil :: Stage?

function FtueManagerClient.start()
	local ftueStage = PlayerDataClient.get(PlayerDataKey.FtueStage)
	FtueManagerClient._onFtueStageUpdated(ftueStage)

	PlayerDataClient.updated:Connect(function(valueName: any, value: any)
		if valueName :: string ~= PlayerDataKey.FtueStage then
			return
		end
		FtueManagerClient._onFtueStageUpdated(value)
	end)
end

function FtueManagerClient._onFtueStageUpdated(ftueStage: FtueStage.EnumType?)
	if FtueManagerClient.activeStage then
		FtueManagerClient.activeStage.teardown()
	end

	FtueManagerClient.activeStage = ftueStage and handlerByStage[ftueStage]

	if FtueManagerClient.activeStage then
		FtueManagerClient.activeStage.setup()
	end
end

return FtueManagerClient
