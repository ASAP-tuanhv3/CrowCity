--!strict

--[[
	Unique IDs for each UILayer singleton. Register a new ID here when you create
	a new UILayer, then call UIHandler.registerLayer() in the layer's setup().
--]]

export type EnumType =
	"DataErrorNotice"
	| "ExampleHud"
	| "ResetDataButton"
-- TODO: Add your gameplay UI layer IDs here.
-- | "MyGameplayPanel"

local UILayerId = {
	DataErrorNotice = "DataErrorNotice" :: "DataErrorNotice",
	ExampleHud = "ExampleHud" :: "ExampleHud",
	ResetDataButton = "ResetDataButton" :: "ResetDataButton",
	-- TODO: Add your gameplay UI layer IDs here.
	-- MyGameplayPanel = "MyGameplayPanel" :: "MyGameplayPanel",
}

return UILayerId
