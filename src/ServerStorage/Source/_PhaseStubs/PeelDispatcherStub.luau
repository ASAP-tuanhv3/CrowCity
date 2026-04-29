--!strict

--[[
	PeelDispatcherStub — TickOrchestrator Phase 9 boot-wiring stub.
	Replaced in-place by PeelDispatcher.flush when crowd-collision-resolution (PeelDispatcher) epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local PeelDispatcherStub = {}

function PeelDispatcherStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in PeelDispatcher (epic: crowd-collision-resolution (PeelDispatcher)).
end

return PeelDispatcherStub
