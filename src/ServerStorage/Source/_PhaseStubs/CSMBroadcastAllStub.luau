--!strict

--[[
	CSMBroadcastAllStub — TickOrchestrator Phase 8 boot-wiring stub.
	Replaced in-place by CrowdStateServer.broadcastAll when crowd-state-server — `broadcastAll` epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local CSMBroadcastAllStub = {}

function CSMBroadcastAllStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in CrowdStateServer (epic: crowd-state-server — `broadcastAll`).
end

return CSMBroadcastAllStub
