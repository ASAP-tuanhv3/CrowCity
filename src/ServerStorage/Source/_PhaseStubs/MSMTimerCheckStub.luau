--!strict

--[[
	MSMTimerCheckStub — TickOrchestrator Phase 6 boot-wiring stub.
	Replaced in-place by MatchStateServer.timerCheck when match-state-server (MSM) — `timerCheck` epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local MSMTimerCheckStub = {}

function MSMTimerCheckStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in MatchStateServer (epic: match-state-server (MSM) — `timerCheck`).
end

return MSMTimerCheckStub
