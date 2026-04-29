--!strict

--[[
	CollisionResolverStub — TickOrchestrator Phase 1 boot-wiring stub.
	Replaced in-place by CollisionResolver.tick when crowd-collision-resolution (CCR) epic ships.
	ADR-0002 §Phase Registration requires a callable here at boot.
	Story-003 boot-wiring integration.
--]]

local CollisionResolverStub = {}

function CollisionResolverStub.tick(_tickCount: number, _ctx: any): ()
	-- No-op — real implementation lives in CollisionResolver (epic: crowd-collision-resolution (CCR)).
end

return CollisionResolverStub
