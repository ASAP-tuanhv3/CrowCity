--!strict

--[[
	cadence.spec.luau — TickOrchestrator accumulator drain math
	Implements: ADR-0002 §Validation Criteria AC-08 (drain math + catch-up)
	            ADR-0002 §Validation Criteria AC-13 (60 s ±0.1% via simulated steps)

	Tests _tick(dt) directly with synthetic dt values. No live Heartbeat needed.
	All tests use setTickDelegate to record fire count without real phase work.

	AC-13 note: Real-Heartbeat 60 s validation deferred to story-005 +
	integration sprint per ADR-0002 §Risk 1. This spec is a math proxy only.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)

	-- Helper: 9-entry valid phase table (callbacks are no-ops because
	-- setTickDelegate bypasses phase iteration in the story-001 stub).
	local function noop() end

	local function validPhases(): { TickOrchestrator.TickPhase }
		local phases = {}
		for i = 1, 9 do
			table.insert(phases, { phase = i, name = "Phase" .. i, callback = noop })
		end
		return phases
	end

	describe("TickOrchestrator cadence (accumulator drain)", function()
		local recorderCount: number

		beforeEach(function()
			TickOrchestrator._resetForTests()
			TickOrchestrator._registerPhases(validPhases())
			recorderCount = 0
			TickOrchestrator.setTickDelegate(function(_: number)
				recorderCount += 1
			end)
		end)

		it("dt = 0 fires 0 ticks; accumulator stays at 0", function()
			-- Boundary case: zero dt should be a complete no-op. Heartbeat
			-- shouldn't deliver dt=0 in practice but the drain loop must handle it.
			TickOrchestrator._tick(0)
			expect(recorderCount).to.equal(0)
			expect(TickOrchestrator.getCurrentTick()).to.equal(0)
			expect(TickOrchestrator._getAccumulator()).to.equal(0)
		end)

		it("dt = 1/15 fires exactly 1 tick", function()
			TickOrchestrator._tick(1 / 15)
			expect(recorderCount).to.equal(1)
			expect(TickOrchestrator.getCurrentTick()).to.equal(1)
		end)

		it("dt = 2/15 fires exactly 2 ticks back-to-back in same call", function()
			TickOrchestrator._tick(2 / 15)
			expect(recorderCount).to.equal(2)
			expect(TickOrchestrator.getCurrentTick()).to.equal(2)
		end)

		it("dt = 1/30 (sub-period) fires 0 ticks; accumulator carries", function()
			TickOrchestrator._tick(1 / 30)
			expect(recorderCount).to.equal(0)
			expect(TickOrchestrator.getCurrentTick()).to.equal(0)
			expect(TickOrchestrator._getAccumulator() > 0).to.equal(true)
		end)

		it("residual accumulator carries forward across two _tick calls", function()
			TickOrchestrator._tick(1 / 30)
			TickOrchestrator._tick(1 / 30)
			expect(recorderCount).to.equal(1)  -- 2/30 = 1/15 → exactly 1 tick
			expect(TickOrchestrator.getCurrentTick()).to.equal(1)
		end)

		it("dt = 0.5 (500ms platform pause) fires exactly 7 ticks (floor(0.5/(1/15)) = 7)", function()
			TickOrchestrator._tick(0.5)
			expect(recorderCount).to.equal(7)
			expect(TickOrchestrator.getCurrentTick()).to.equal(7)
			-- residual ≈ 0.5 - 7/15 ≈ 0.0333
			local residual = TickOrchestrator._getAccumulator()
			expect(residual > 0.03).to.equal(true)
			expect(residual < 0.04).to.equal(true)
		end)

		it("60 simulated seconds at dt=1/60 produces tick count ∈ [899, 901] (math proxy for AC-13)", function()
			-- Real-Heartbeat 60 s validation deferred to story-005 + integration
			-- sprint per ADR-0002 §Risk 1. This test is a math proxy only:
			-- 3600 frames × 1/60 s = 60 s simulated → expect ~900 ticks at 15 Hz.
			for _ = 1, 3600 do
				TickOrchestrator._tick(1 / 60)
			end
			local tickCount = TickOrchestrator.getCurrentTick()
			expect(tickCount >= 899).to.equal(true)
			expect(tickCount <= 901).to.equal(true)
		end)
	end)
end
