--!strict

--[[
	Stores per-player objects that need to be shared across server modules.
	Register objects here so any server module can retrieve them without tight coupling
	between systems.

	To add a new per-player object:
	  1. Add the field to the PlayerObjects type
	  2. Create it in registerPlayer()
	  3. Destroy it in unregisterPlayer()
	  4. Add a getter function below
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)

-- TODO: Add your gameplay-specific per-player object types here.
-- local MyGameplayObject = require(ServerStorage.Source.MyGameplay.MyGameplayObject)

type PlayerObjects = {
	characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
	-- TODO: Add your gameplay-specific per-player object fields here.
	-- myGameplayObject: MyGameplayObject.ClassType,
}

local PlayerObjectsContainer = {}

local _objectsByPlayer: { [Player]: PlayerObjects } = {}

function PlayerObjectsContainer.registerPlayer(player: Player)
	_objectsByPlayer[player] = {
		characterLoadedWrapper = CharacterLoadedWrapper.new(player),
		-- TODO: Create your gameplay-specific per-player objects here.
		-- myGameplayObject = MyGameplayObject.new(player),
	}
end

function PlayerObjectsContainer.unregisterPlayer(player: Player)
	local objects = _objectsByPlayer[player]
	if not objects then
		return
	end

	objects.characterLoadedWrapper:destroy()
	-- TODO: Destroy your gameplay-specific per-player objects here.
	-- objects.myGameplayObject:destroy()

	_objectsByPlayer[player] = nil
end

function PlayerObjectsContainer.getCharacterLoadedWrapper(player: Player): CharacterLoadedWrapper.ClassType
	return _objectsByPlayer[player].characterLoadedWrapper
end

-- TODO: Add getter methods for your gameplay-specific per-player objects here.

return PlayerObjectsContainer
