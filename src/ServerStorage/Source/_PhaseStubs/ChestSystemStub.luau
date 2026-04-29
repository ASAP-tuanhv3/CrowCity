--!strict

--[[
	ChestSystemStub — TickOrchestrator Phase 4 boot-wiring stub.
	Replaced in-place by ChestSystem.tick when chest-system epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local ChestSystemStub = {}

function ChestSystemStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in ChestSystem (epic: chest-system).
end

return ChestSystemStub
