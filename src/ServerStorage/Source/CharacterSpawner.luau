--!strict

--[[
	Manages character spawning and respawning.
	Players.CharacterAutoLoads is false, so all spawning is handled here.

	Customize spawnCharacter() to place the character at your game's desired spawn point.
	For example, spawn at a per-player spawn location, a lobby, or inside a gameplay area.
--]]

local Players = game:GetService("Players")

local CharacterSpawner = {}

local _respawnConnections: { [Player]: RBXScriptConnection } = {}

function CharacterSpawner.startRespawnLoop(player: Player)
	CharacterSpawner.spawnCharacter(player)

	_respawnConnections[player] = player.CharacterRemoving:Connect(function()
		task.wait(Players.RespawnTime)
		if player.Parent then -- Guard: player may have left during the wait
			CharacterSpawner.spawnCharacter(player)
		end
	end)
end

function CharacterSpawner.stopRespawnLoop(player: Player)
	if _respawnConnections[player] then
		_respawnConnections[player]:Disconnect()
		_respawnConnections[player] = nil
	end
end

function CharacterSpawner.spawnCharacter(player: Player)
	-- TODO: Customize the spawn location here.
	-- Example: teleport to a named SpawnPart in Workspace
	--   player:LoadCharacter()
	--   local spawnPart = workspace:FindFirstChild("SpawnLocation")
	--   if spawnPart and player.Character then
	--     player.Character:PivotTo(spawnPart.CFrame * CFrame.new(0, 3, 0))
	--   end
	player:LoadCharacter()
end

return CharacterSpawner
