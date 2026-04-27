--!strict

--[[
	Specifies the names of the RemoteEvent, RemoteFunction, and UnreliableRemoteEvent
	folders used by createRemotesFolders and waitForAllRemotesAsync.

	UnreliableRemoteEvents folder added by Story 001 (network-layer-ext epic) per
	ADR-0001 §Decision (CrowdStateBroadcast at 15 Hz).
--]]

export type EnumType = "RemoteEvents" | "RemoteFunctions" | "UnreliableRemoteEvents"

local RemoteFolderName = {
	RemoteEvents = "RemoteEvents" :: "RemoteEvents",
	RemoteFunctions = "RemoteFunctions" :: "RemoteFunctions",
	UnreliableRemoteEvents = "UnreliableRemoteEvents" :: "UnreliableRemoteEvents",
}

return RemoteFolderName
