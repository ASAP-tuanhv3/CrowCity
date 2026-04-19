--!strict

--[[
	A table of strings to be used by client or server scripts. These are centralized
	in one place for easier tracking of what dynamic strings are in the game, which is useful
	for assembling a list of strings to translate. It also mitigates repeated string constant definition
	in multiple files.
--]]

local PlayerFacingString = {
	ImageAsset = {
		Prefix = "rbxassetid://", -- Scripts append an image asset ID for the Image property of guis
		None = "", -- Empty strings in a gui's Image property makes the image invisible
	},
	ValueManager = { -- Unique strings used as keys for ValueManager offsets and multipliers
		-- TODO: Add your ValueManager keys here.
		-- Example:
		-- Sprint = "sprint",
		-- ViewingMenu = "viewingMenu",
	},
	ResetDataButton = {
		Confirm = "Confirm?", -- Shows on the first button press, requiring a second because it's a dangerous action
		ConfirmSubText = "Wipes your progress. No undo", -- Clarification while the Confirm message is showing
	},
	-- TODO: Add your game-specific player-facing strings here.
	-- Example:
	-- CallToAction = {
	-- 	InteractWithObject = "Interact",
	-- },
	-- Formats = {
	-- 	ShopItem = "Buy %d",
	-- },
}

return PlayerFacingString
