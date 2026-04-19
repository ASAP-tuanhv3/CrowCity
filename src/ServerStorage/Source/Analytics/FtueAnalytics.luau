--!strict

--[[
	Tracks FTUE (onboarding) funnel steps via AnalyticsService.
	This populates the onboarding funnel chart in Creator Hub's analytics pages.

	To enable: uncomment the FtueAnalytics import and call in FtueManagerServer/init.luau.

	Keep the FtueStageToStep map in sync with your FtueStage enum values.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

local FtueAnalytics = {}

-- TODO: Map each of your FTUE stages to a numeric step for the analytics funnel.
local FtueStageToStep: { [FtueStage.EnumType]: number } = {
	[FtueStage.Stage1] = 1,
	[FtueStage.Stage2] = 2,
}

function FtueAnalytics.logFtueStage(player: Player, ftueStage: FtueStage.EnumType)
	local step = FtueStageToStep[ftueStage]
	if not step then
		return
	end

	AnalyticsService:LogOnboardingFunnelStepEvent(player, step, ftueStage, {})
end

return FtueAnalytics
