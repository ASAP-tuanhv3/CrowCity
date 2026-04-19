--!strict

--[[
	Client-side handler for FTUE Stage 1.

	setup()    is called when the player enters this stage.
	teardown() is called when the player leaves (stage advances or data resets).

	Use this to guide the player toward completing Stage 1's objective. Examples:
	  - UIHighlight.new(someGuiElement)  -- highlight a button
	  - CharacterPath.new(attachment)   -- draw a beam path to a world location
	  - UIHandler.show(UILayerId.X)     -- force-open a specific panel
--]]

local Stage1FtueStage = {}

function Stage1FtueStage.setup()
	-- TODO: Add client-side guidance for Stage 1.
end

function Stage1FtueStage.teardown()
	-- TODO: Clean up anything created in setup().
end

return Stage1FtueStage
