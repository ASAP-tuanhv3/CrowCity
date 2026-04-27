--!strict

--[[
	Names of all UnreliableRemoteEvents. One UnreliableRemoteEvent is created per
	entry at server boot. Never reference unreliable remote names as raw strings —
	always use this enum.

	UnreliableRemoteEvents are best-effort, no-ordering, no-retransmit (per
	docs/engine-reference/roblox/replication-best-practices.md). Use ONLY for
	high-frequency non-critical updates (crowd state broadcast, NPC state
	broadcast). For everything else, prefer the reliable `RemoteEventName` enum.

	To add a new unreliable event:
	  1. Add a value to the EnumType union and the table below
	  2. Fire from server: Network.fireAllClientsUnreliable(name, ...) /
	     Network.fireClientUnreliable(player, name, ...)
	  3. Listen on client: Network.connectUnreliableEvent(name, handler)

	Implements: Story 001 (network-layer-ext epic)
	Mandated by: ADR-0001 §Decision (CrowdStateBroadcast),
	             ADR-0008 §Replication Contract (NpcStateBroadcast)
--]]

export type EnumType =
	"CrowdStateBroadcast"
	| "NpcStateBroadcast"

local UnreliableRemoteEventName = {
	CrowdStateBroadcast = "CrowdStateBroadcast" :: "CrowdStateBroadcast",
	NpcStateBroadcast   = "NpcStateBroadcast" :: "NpcStateBroadcast",
}

return UnreliableRemoteEventName
