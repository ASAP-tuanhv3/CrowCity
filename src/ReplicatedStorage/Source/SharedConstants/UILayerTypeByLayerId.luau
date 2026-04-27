--!strict

--[[
	Maps UILayerIds to UILayerTypes. UIHandler reads this at registerLayer() time
	to determine show/hide behavior:
	  - HeadsUpDisplay: coexists with gameplay; multiple HUD layers may stack.
	  - Menu: only one Menu layer is open at a time; opening a second closes the first.

	Add a mapping here when you add a new UILayerId. A layer with no mapping
	defaults to Menu behavior at the UIHandler runtime (see ANATOMY §8).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)

local UILayerTypeByLayerId: { [UILayerId.EnumType]: UILayerType.EnumType } = {
	-- Implements: Story 001 (ui-handler-layer-reg epic)
	[UILayerId.HUD] = UILayerType.HeadsUpDisplay,
	[UILayerId.RelicDraft] = UILayerType.Menu,
	[UILayerId.MainMenu] = UILayerType.Menu,
	[UILayerId.PauseMenu] = UILayerType.Menu,
}

return UILayerTypeByLayerId
