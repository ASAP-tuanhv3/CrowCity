--!strict

--[[
	RelicSystemStub — TickOrchestrator Phase 2 boot-wiring stub.
	Replaced in-place by RelicSystem.tick when relic-system epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local RelicSystemStub = {}

function RelicSystemStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in RelicSystem (epic: relic-system).
end

--- Clears all in-flight relic effects for round teardown. Sole caller: MSM
--- T9 path (Intermission entry). Real impl will iterate active relics and
--- run their onExpire callbacks; stub is no-op.
--- Per ADR-0005 T9 ordering invariant: destroyAll → clearAll → broadcast.
function RelicSystemStub.clearAll(): ()
	-- No-op — real implementation lives in RelicSystem (epic: relic-system).
end

return RelicSystemStub
