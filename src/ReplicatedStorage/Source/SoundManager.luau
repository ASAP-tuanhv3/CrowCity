--!strict

-- SoundManager — template wire-up; full AudioManager epic (VS+) will replace this.
-- Migrated from SharedConstants/Sounds.luau (story 003 retirement) to AssetId.Sound
-- per ADR-0006 Module Placement Rules.
--
-- Per AssetId contract: registry holds string SoundId only. Per-cue Volume / Looped
-- defaults live here as consumer-owned config until AudioManager epic lands.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetId = require(ReplicatedStorage.Source.SharedConstants.AssetId)

local SoundController = {}

local Sounds = workspace:WaitForChild("Sounds")

local DEFAULT_SFX_VOLUME = 0.7
local DEFAULT_MUSIC_VOLUME = 0.5

local function applySound(instance: Sound, name: string, volume: number, looped: boolean)
	local soundId = AssetId.Sound[name]
	if not soundId then
		warn(`[SoundManager] Unknown sound name '{name}' — not in AssetId.Sound registry.`)
		return false
	end
	instance.SoundId = soundId
	instance.Volume = volume
	instance.Looped = looped
	return true
end

function SoundController:PlaySFX1(name: string)
	local SFX1 = Sounds:WaitForChild("SFXGroup"):WaitForChild("SFX1") :: Sound
	if applySound(SFX1, name, DEFAULT_SFX_VOLUME, false) then
		SFX1:Play()
	end
end

function SoundController:PlayLocalSound(name: string, parent: Instance)
	for _, child in pairs(parent:GetChildren()) do
		if child:IsA("Sound") then
			return
		end
	end
	local localSound = Sounds:WaitForChild("SFXGroup"):WaitForChild("LocalSound"):Clone() :: Sound
	localSound.Parent = parent

	if not applySound(localSound, name, DEFAULT_SFX_VOLUME, false) then
		localSound:Destroy()
		return
	end

	localSound:Play()
	localSound.Ended:Wait()
	localSound:Destroy()
end

function SoundController:PlayMainSound(name: string)
	local MainSound = Sounds:WaitForChild("BackgroundGroup"):WaitForChild("MainSound") :: Sound
	if applySound(MainSound, name, DEFAULT_MUSIC_VOLUME, true) then
		MainSound.TimePosition = 0
		MainSound:Play()
	end
end

function SoundController:CustomSound(soundname: string, customname: string, soundgroup: string)
	if not AssetId.Sound[soundname] then
		warn(`[SoundManager] Unknown sound name '{soundname}' — not in AssetId.Sound registry.`)
		return
	end
	if not Sounds:FindFirstChild(soundgroup) then
		warn(`[SoundManager] SoundGroup '{soundgroup}' not found.`)
		return
	end

	local groupInstance = Sounds:WaitForChild(soundgroup)
	local mainsound: Sound

	if groupInstance:FindFirstChild(customname) then
		mainsound = groupInstance:WaitForChild(customname) :: Sound
	else
		mainsound = Instance.new("Sound")
		mainsound.Name = customname
		mainsound.Parent = groupInstance
		mainsound.SoundGroup = groupInstance :: SoundGroup
	end

	if applySound(mainsound, soundname, DEFAULT_SFX_VOLUME, false) then
		mainsound.TimePosition = 0
		mainsound:Play()
	end
end

function SoundController:CustomSoundGroup(properties: { [string]: any }?)
	if not properties then
		warn("[SoundManager] Properties were not provided.")
		return
	end
	local newgroup = Instance.new("SoundGroup")
	newgroup.Parent = Sounds
	for propName, value in pairs(properties) do
		(newgroup :: any)[propName] = value
	end
end

function SoundController:RemoveCustom(name: string, parent: string)
	if parent == "Sounds" then
		Sounds:WaitForChild(name):Destroy()
	else
		Sounds:WaitForChild(parent):WaitForChild(name):Destroy()
	end
end

function SoundController:SetUp()
	local BackgroundGroup = Instance.new("SoundGroup")
	BackgroundGroup.Parent = Sounds
	BackgroundGroup.Name = "BackgroundGroup"
	BackgroundGroup.Volume = 0.4

	local SFXGroup = Instance.new("SoundGroup")
	SFXGroup.Parent = Sounds
	SFXGroup.Name = "SFXGroup"
	SFXGroup.Volume = 0.2

	local MainSound = Instance.new("Sound")
	MainSound.Parent = BackgroundGroup
	MainSound.SoundGroup = BackgroundGroup
	MainSound.Name = "MainSound"
	MainSound.Volume = 0.3

	local SFX1 = Instance.new("Sound")
	SFX1.Name = "SFX1"
	SFX1.SoundGroup = SFXGroup
	SFX1.Parent = SFXGroup

	local localSound = Instance.new("Sound")
	localSound.Name = "LocalSound"
	localSound.SoundGroup = SFXGroup
	localSound.Parent = SFXGroup
	localSound.RollOffMaxDistance = 30
end

return SoundController
