--!strict

--[[
	CSMStateEvaluateStub — TickOrchestrator Phase 5 boot-wiring stub.
	Replaced in-place by CrowdStateServer.stateEvaluate when crowd-state-server (CSM) — `stateEvaluate` epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local CSMStateEvaluateStub = {}

function CSMStateEvaluateStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in CrowdStateServer (epic: crowd-state-server (CSM) — `stateEvaluate`).
end

return CSMStateEvaluateStub
