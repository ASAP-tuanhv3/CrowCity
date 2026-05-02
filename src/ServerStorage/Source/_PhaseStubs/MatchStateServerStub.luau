--!strict

--[[
	MatchStateServerStub — BindToClose ServerClosing broadcast stub.
	Replaced in-place by MatchStateServer.requestServerClosing when MSM epic
	ships its real T11 transition entry point.

	Implements: story-004 AC-4 — fires MatchStateChanged reliable RemoteEvent
	with state = "ServerClosing" so the client UI can react before ProfileStore
	finishes its 30 s grace.

	Path: ServerStorage/Source/_PhaseStubs/MatchStateServerStub.luau

	NOT a TickOrchestrator phase callback. The other stubs in this directory
	are phase callbacks (.tick(tickCount, ctx)); this one is a state-machine
	entry point. Co-located here under the underscore-prefix temporary-stub
	convention until the MSM epic lands.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

-- Test-only state — see _-prefixed accessors below.
local _invocationCount: number = 0
local _lastBroadcastState: string? = nil

local MatchStateServerStub = {}

--- Stub — fires MatchStateChanged("ServerClosing") to all clients.
--- Replaced by MatchStateServer.requestServerClosing when MSM epic ships.
--- ADR-0005 §BindToClose ownership: MSM owns T11 transition.
--- Story-004 AC-4 + AC-7.
function MatchStateServerStub.requestServerClosing(): ()
	_invocationCount += 1
	_lastBroadcastState = "ServerClosing"

	-- pcall guards against Network not being initialised in unusual test
	-- contexts. In production start.server.luau calls Network.startServer()
	-- before this stub is reachable, so the success path always runs.
	local ok, err = pcall(function()
		Network.fireAllClients(RemoteEventName.MatchStateChanged, "ServerClosing")
	end)
	if not ok then
		warn("[MatchStateServerStub] MatchStateChanged broadcast failed: " .. tostring(err))
	end
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
function MatchStateServerStub._resetForTests(): ()
	_invocationCount = 0
	_lastBroadcastState = nil
end

--- **TEST ONLY** — never call from production code.
--- Returns the number of times requestServerClosing has been invoked.
function MatchStateServerStub._getInvocationCount(): number
	return _invocationCount
end

--- **TEST ONLY** — never call from production code.
--- Returns the state string of the last broadcast attempted, or nil.
function MatchStateServerStub._getLastBroadcastState(): string?
	return _lastBroadcastState
end

return MatchStateServerStub
