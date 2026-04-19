--!strict

--[[
	Example HeadsUpDisplay layer. Shows a simple label on screen to demonstrate
	the UIHandler registration pattern with setup/teardown visibility.

	How to use this as a reference for your own HUD layers:
	  1. Copy this file and rename it (e.g. UIMyHud.luau)
	  2. Add your layer's ID to SharedConstants/UILayerId.luau
	  3. Replace the label creation with your own GUI elements (or clone a prefab)
	  4. Call UIHandler.show(layerId) from wherever your gameplay logic needs it

	This layer auto-shows on setup. Menus will automatically hide all HUD layers
	while they are open — UIHandler manages that for you.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)

local LAYER_ID: UILayerId.EnumType = UILayerId.ExampleHud

local UIExampleHud = {}
UIExampleHud._screenGui = nil :: ScreenGui?

function UIExampleHud.setup(parent: Instance)
	-- Create a simple ScreenGui with a label.
	-- In a real layer you would clone a prefab from ReplicatedStorage/Instances/GuiPrefabs/.
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ExampleHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true

	local label = Instance.new("TextLabel")
	label.Name = "ExampleLabel"
	label.Size = UDim2.new(0, 200, 0, 40)
	label.Position = UDim2.new(0.5, -100, 0, 12)
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Text = "Example HUD"
	label.Parent = screenGui

	screenGui.Parent = parent
	UIExampleHud._screenGui = screenGui

	-- Register with UIHandler so visibility is managed automatically.
	local visibilityChanged = UIHandler.registerLayer(LAYER_ID, UILayerType.HeadsUpDisplay, UIExampleHud)

	visibilityChanged:Connect(function(isVisible: any)
		if UIExampleHud._screenGui then
			UIExampleHud._screenGui.Enabled = isVisible :: boolean
		end
	end)

	-- Show immediately — UIHandler will hide this when a Menu layer opens.
	UIHandler.show(LAYER_ID)
end

function UIExampleHud.getLayerId(): UILayerId.EnumType
	return LAYER_ID
end

return UIExampleHud
