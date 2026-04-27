--!strict

--[[
	Unique IDs for each UILayer singleton. Register a new ID here when you create
	a new UILayer, then call UIHandler.registerLayer() in the layer's setup().
--]]

export type EnumType =
	"DataErrorNotice"
	| "ExampleHud"
	| "ResetDataButton"
	| "HUD"
	| "RelicDraft"
	| "MainMenu"
	| "PauseMenu"

local UILayerId = {
	DataErrorNotice = "DataErrorNotice" :: "DataErrorNotice",
	ExampleHud = "ExampleHud" :: "ExampleHud",
	ResetDataButton = "ResetDataButton" :: "ResetDataButton",
	-- Implements: Story 001 (ui-handler-layer-reg epic)
	-- Project layer IDs per architecture.md §3.1 + ANATOMY §8.
	-- HeadsUpDisplay-typed: HUD (coexists w/ gameplay)
	-- Menu-typed: RelicDraft, MainMenu, PauseMenu (mutex — opening one closes any other Menu)
	HUD = "HUD" :: "HUD",
	RelicDraft = "RelicDraft" :: "RelicDraft",
	MainMenu = "MainMenu" :: "MainMenu",
	PauseMenu = "PauseMenu" :: "PauseMenu",
}

return UILayerId
