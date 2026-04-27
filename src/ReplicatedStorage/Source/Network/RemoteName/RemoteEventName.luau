--!strict

--[[
	Names of all RemoteEvents. One RemoteEvent is created per entry at startup.
	Never reference remote names as raw strings — always use this enum.

	To add a new event:
	  1. Add a value to the EnumType union and the table below
	  2. Fire from client: Network.fireServer(RemoteEventName.MyEvent, ...)
	     Fire from server: Network.fireClient(player, RemoteEventName.MyEvent, ...)
	  3. Listen on server: Network.connectEvent(RemoteEventName.MyEvent, handler)

	Project remote inventory is enumerated by `docs/architecture/architecture.md`
	§5.7 (Wire contracts). New entries here MUST trace to that section. Story 002
	(network-layer-ext epic) lands the §5.7 baseline. Story 001 sibling lives in
	`UnreliableRemoteEventName.luau` for high-frequency state broadcast.
--]]

export type EnumType =
	-- Template / player-data infra
	"PlayerDataLoaded"
	| "PlayerDataUpdated"
	| "PlayerDataSaved"
	| "ResetData"
	-- MSM (Match State Machine)
	| "MatchStateChanged"
	| "ParticipationChanged"
	-- CSM (Crowd State Manager)
	| "CrowdCreated"
	| "CrowdDestroyed"
	| "CrowdEliminated"
	| "CrowdCountClamped"
	| "CrowdRelicChanged"
	-- Chest System
	| "ChestInteract"
	| "ChestDraftOffer"
	| "ChestDraftPick"
	| "ChestStateChanged"
	| "ChestPeelOff"
	| "ChestDraftOpenFX"
	| "ChestOpenBurst"
	-- Absorb + Collision
	| "Absorbed"
	| "HueShift"
	| "CollisionContactEvent"
	-- Relic System
	| "RelicGrantVFX"
	| "RelicExpireVFX"
	| "RelicDraftPick"
	-- Player + NPC infra
	| "AFKToggle"
	| "NpcPoolBootstrap"

local RemoteEventName = {
	-- Template / player-data infra (template-shipped)
	PlayerDataLoaded = "PlayerDataLoaded" :: "PlayerDataLoaded",
	PlayerDataUpdated = "PlayerDataUpdated" :: "PlayerDataUpdated",
	PlayerDataSaved = "PlayerDataSaved" :: "PlayerDataSaved",
	ResetData = "ResetData" :: "ResetData",

	-- Implements: Story 002 (network-layer-ext epic) — architecture.md §5.7 entries

	-- MSM (Match State Machine)
	MatchStateChanged = "MatchStateChanged" :: "MatchStateChanged",
	ParticipationChanged = "ParticipationChanged" :: "ParticipationChanged",

	-- CSM (Crowd State Manager)
	CrowdCreated = "CrowdCreated" :: "CrowdCreated",
	CrowdDestroyed = "CrowdDestroyed" :: "CrowdDestroyed",
	CrowdEliminated = "CrowdEliminated" :: "CrowdEliminated",
	CrowdCountClamped = "CrowdCountClamped" :: "CrowdCountClamped",
	CrowdRelicChanged = "CrowdRelicChanged" :: "CrowdRelicChanged",

	-- Chest System
	ChestInteract = "ChestInteract" :: "ChestInteract",
	ChestDraftOffer = "ChestDraftOffer" :: "ChestDraftOffer",
	ChestDraftPick = "ChestDraftPick" :: "ChestDraftPick",
	ChestStateChanged = "ChestStateChanged" :: "ChestStateChanged",
	ChestPeelOff = "ChestPeelOff" :: "ChestPeelOff",
	ChestDraftOpenFX = "ChestDraftOpenFX" :: "ChestDraftOpenFX",
	ChestOpenBurst = "ChestOpenBurst" :: "ChestOpenBurst",

	-- Absorb + Collision
	Absorbed = "Absorbed" :: "Absorbed",
	HueShift = "HueShift" :: "HueShift",
	CollisionContactEvent = "CollisionContactEvent" :: "CollisionContactEvent",

	-- Relic System
	RelicGrantVFX = "RelicGrantVFX" :: "RelicGrantVFX",
	RelicExpireVFX = "RelicExpireVFX" :: "RelicExpireVFX",
	RelicDraftPick = "RelicDraftPick" :: "RelicDraftPick",

	-- Player + NPC infra
	AFKToggle = "AFKToggle" :: "AFKToggle",
	NpcPoolBootstrap = "NpcPoolBootstrap" :: "NpcPoolBootstrap",
}

return RemoteEventName
