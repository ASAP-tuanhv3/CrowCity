--!strict

--[[
	MSMEliminationConsumerStub — TickOrchestrator Phase 7 boot-wiring stub.
	Replaced in-place by MatchStateServer.eliminationConsumer when match-state-server — `eliminationConsumer` epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local MSMEliminationConsumerStub = {}

function MSMEliminationConsumerStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in MatchStateServer (epic: match-state-server — `eliminationConsumer`).
end

return MSMEliminationConsumerStub
