--!strict

--[[
	AbsorbSystemStub — TickOrchestrator Phase 3 boot-wiring stub.
	Replaced in-place by AbsorbSystem.tick when absorb-system epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local AbsorbSystemStub = {}

function AbsorbSystemStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in AbsorbSystem (epic: absorb-system).
end

return AbsorbSystemStub
