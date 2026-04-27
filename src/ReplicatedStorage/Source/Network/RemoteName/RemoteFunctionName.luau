--!strict

--[[
	Specifies the names of all RemoteFunctions. One RemoteFunction object gets generated for each name
	in this list, and these names are used as enums when interacting with Network to tell it
	which remote function to fire without typing out typo-prone string literals.

	Story 002 (network-layer-ext epic) adds GetParticipation per architecture.md §5.7
	(client requests its own participation flag at boot, before MSM events stream).
--]]

export type EnumType =
	"RequestItemPurchase"
	| "GetParticipation"

local RemoteFunctionName = {
	RequestItemPurchase = "RequestItemPurchase" :: "RequestItemPurchase",
	-- Implements: Story 002 (network-layer-ext epic)
	GetParticipation = "GetParticipation" :: "GetParticipation",
}

return RemoteFunctionName
