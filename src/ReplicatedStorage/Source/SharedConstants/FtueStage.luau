--!strict

--[[
	Stages for the First Time User Experience (FTUE).
	Stored in PlayerDataKey.FtueStage and persisted across sessions.

	Replace Stage1/Stage2 with descriptive names matching your game's onboarding steps.
	The server FtueManagerServer advances stages by awaiting completion conditions.
	The client FtueManagerClient reacts to stage changes to show hints and highlights.

	To add a stage:
	  1. Add a value to the EnumType union and table below
	  2. Create StageHandlers/<MyStageName>FtueStage.luau in both FtueManagerServer and FtueManagerClient
	  3. Register the handler in both managers' init.luau
--]]

export type EnumType = "Stage1" | "Stage2" | "Complete"

local FtueStage = {
	Stage1 = "Stage1" :: "Stage1",
	Stage2 = "Stage2" :: "Stage2",
	Complete = "Complete" :: "Complete",
}

return FtueStage
