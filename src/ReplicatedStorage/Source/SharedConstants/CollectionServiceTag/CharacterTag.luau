--!strict

--[[
	CollectionService tags to identify characters and state about the character.
--]]

export type EnumType = "Character" | "Holding"
-- TODO: Add game-specific character state tags here.
-- | "MyCharacterState"

local CharacterTag = {
	Character = "Character" :: "Character",
	Holding = "Holding" :: "Holding",
	-- TODO: Add game-specific character state tags here.
	-- MyCharacterState = "MyCharacterState" :: "MyCharacterState",
}

return CharacterTag
