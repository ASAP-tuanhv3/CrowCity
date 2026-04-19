--!strict

--[[
	Template for tracking custom gameplay events via AnalyticsService.
	These populate charts in Creator Hub's analytics pages.

	To add a new event:
	  1. Add a constant string for the event name below
	  2. Create a log function that calls AnalyticsService:LogCustomEvent()
	  3. Call the log function from your gameplay code

	See also: EconomyAnalytics pattern in ANATOMY.md §13 for economy-specific events.
--]]

local AnalyticsService = game:GetService("AnalyticsService")

-- TODO: Define your custom event name constants here.
-- local EVENT_EXAMPLE = "ExampleEvent"

local CustomAnalytics = {}

-- TODO: Add your custom analytics functions here. Example:
--
-- function CustomAnalytics.logExampleEvent(player: Player, value: number)
-- 	task.spawn(function()
-- 		AnalyticsService:LogCustomEvent(player, EVENT_EXAMPLE, value, {
-- 			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "exampleField",
-- 		})
-- 	end)
-- end

return CustomAnalytics
