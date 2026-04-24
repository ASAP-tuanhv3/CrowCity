--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Date: 2026-04-20

-- Lazy-initialized Remotes under ReplicatedStorage.
-- Server creates, client waits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local FOLDER_NAME = "CrowdSyncRemotes"

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
end

local function getOrCreate(name: string, className: string): any
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	if RunService:IsServer() then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		return folder:WaitForChild(name)
	end
end

-- Broadcast crowd state from server to all clients (unreliable, 15Hz).
-- Payload: table mapping crowdId (string) -> { pos: Vector3, radius: number, count: number, hue: number }
function Remotes.getCrowdStateBroadcast(): UnreliableRemoteEvent
	return getOrCreate("CrowdStateBroadcast", "UnreliableRemoteEvent")
end

-- Broadcast absorb/elimination events (reliable, one-off).
-- Payload: { eventType: string, crowdId: string, amount: number }
function Remotes.getGameplayEvent(): RemoteEvent
	return getOrCreate("GameplayEvent", "RemoteEvent")
end

return Remotes
