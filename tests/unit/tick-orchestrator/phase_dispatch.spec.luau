--!strict

--[[
	phase_dispatch.spec.luau — TickOrchestrator phase iteration + ctx contract
	Implements: ADR-0002 §Architecture L93-103 + §Validation Criteria
	  AC-01 — iteration order is by .phase field, not insertion order
	  AC-02 — fresh ctx.outPairs + ctx.outPeel per tick
	  AC-03 — same ctx ref propagates 1..9 within one tick
	  AC-05 — _tickDelegate short-circuits phase iteration
	  AC-10 — deterministic phase order across 1000 ticks
	Partial AC-04 — recorder happy path (error path covered in error_isolation.spec)

	Uses _tick(dt = 1/15) directly to drive single ticks; no live Heartbeat.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)

	-- Helper: build phases that record their .phase value into a shared list
	-- when invoked. Returns (phases, recorderList).
	local function recordingPhases(): ({ TickOrchestrator.TickPhase }, { number })
		local list: { number } = {}
		local phases: { TickOrchestrator.TickPhase } = {}
		for i = 1, 9 do
			local pid = i  -- capture for closure
			table.insert(phases, {
				phase = pid,
				name = "P" .. pid,
				callback = function(_: number, _: TickOrchestrator.TickContext)
					table.insert(list, pid)
				end,
			})
		end
		return phases, list
	end

	-- ---------------------------------------------------------------------------
	-- Iteration order (AC-01)
	-- ---------------------------------------------------------------------------

	describe("TickOrchestrator phase iteration order", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("iterates 1..9 even when input table was sorted ascending", function()
			-- Arrange
			local phases, list = recordingPhases()
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert
			expect(#list).to.equal(9)
			for i = 1, 9 do
				expect(list[i]).to.equal(i)
			end
		end)

		it("iterates 1..9 even when input table was scrambled", function()
			-- Arrange: phases added in scrambled .phase order
			local order = { 5, 1, 9, 3, 7, 2, 8, 4, 6 }
			local list: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			for _, pid in order do
				local capturedPid = pid
				table.insert(phases, {
					phase = capturedPid,
					name = "P" .. capturedPid,
					callback = function(_: number, _: TickOrchestrator.TickContext)
						table.insert(list, capturedPid)
					end,
				})
			end
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert: _registerPhases sort should have reordered 1..9
			expect(#list).to.equal(9)
			for i = 1, 9 do
				expect(list[i]).to.equal(i)
			end
		end)

		it("iterates 1..9 even when input was reversed 9..1", function()
			-- Arrange: phases inserted in descending order
			local list: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			for pid = 9, 1, -1 do
				local capturedPid = pid
				table.insert(phases, {
					phase = capturedPid,
					name = "P" .. capturedPid,
					callback = function(_: number, _: TickOrchestrator.TickContext)
						table.insert(list, capturedPid)
					end,
				})
			end
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert
			expect(#list).to.equal(9)
			for i = 1, 9 do
				expect(list[i]).to.equal(i)
			end
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- ctx propagation (AC-02, AC-03)
	-- ---------------------------------------------------------------------------

	describe("TickOrchestrator ctx propagation", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("ctx.outPairs is fresh empty table every tick (no cross-tick bleed)", function()
			-- Arrange
			local p2Counts: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			-- Phase 1: append one entry to outPairs
			table.insert(phases, {
				phase = 1,
				name = "P1",
				callback = function(tick: number, ctx: TickOrchestrator.TickContext)
					table.insert(ctx.outPairs, { tick = tick })
				end,
			})
			-- Phase 2: record how many entries are in outPairs this tick
			table.insert(phases, {
				phase = 2,
				name = "P2",
				callback = function(_: number, ctx: TickOrchestrator.TickContext)
					table.insert(p2Counts, #ctx.outPairs)
				end,
			})
			-- Pad phases 3-9 with no-ops
			for i = 3, 9 do
				local capturedI = i
				table.insert(phases, {
					phase = capturedI,
					name = "P" .. capturedI,
					callback = function(_: number, _: TickOrchestrator.TickContext) end,
				})
			end
			TickOrchestrator._registerPhases(phases)
			-- Act: drive 5 ticks
			for _ = 1, 5 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: Phase 2 should see exactly 1 entry every tick (fresh table each tick)
			expect(#p2Counts).to.equal(5)
			for i = 1, 5 do
				expect(p2Counts[i]).to.equal(1)
			end
		end)

		it("ctx.outPeel is fresh empty table every tick", function()
			-- Arrange
			local p9Counts: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			-- Phase 1: append to outPeel
			table.insert(phases, {
				phase = 1,
				name = "P1",
				callback = function(_: number, ctx: TickOrchestrator.TickContext)
					table.insert(ctx.outPeel, "x")
				end,
			})
			-- Phases 2-8: no-ops
			for i = 2, 8 do
				local capturedI = i
				table.insert(phases, {
					phase = capturedI,
					name = "P" .. capturedI,
					callback = function(_: number, _: TickOrchestrator.TickContext) end,
				})
			end
			-- Phase 9: record outPeel length
			table.insert(phases, {
				phase = 9,
				name = "P9",
				callback = function(_: number, ctx: TickOrchestrator.TickContext)
					table.insert(p9Counts, #ctx.outPeel)
				end,
			})
			TickOrchestrator._registerPhases(phases)
			-- Act
			for _ = 1, 3 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: Phase 9 sees exactly 1 entry every tick (fresh table each tick)
			expect(#p9Counts).to.equal(3)
			for i = 1, 3 do
				expect(p9Counts[i]).to.equal(1)
			end
		end)

		it("Phase 9 sees what Phase 1 wrote in same tick (cross-phase ctx ref)", function()
			-- Arrange: AC-03 — same ctx reference propagates through all phases
			local p9Saw: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			-- Phase 1 writes tickCount into outPairs
			table.insert(phases, {
				phase = 1,
				name = "P1",
				callback = function(tick: number, ctx: TickOrchestrator.TickContext)
					table.insert(ctx.outPairs, { tickValue = tick })
				end,
			})
			-- Phases 2-8: no-ops
			for i = 2, 8 do
				local capturedI = i
				table.insert(phases, {
					phase = capturedI,
					name = "P" .. capturedI,
					callback = function(_: number, _: TickOrchestrator.TickContext) end,
				})
			end
			-- Phase 9 reads what Phase 1 wrote
			table.insert(phases, {
				phase = 9,
				name = "P9",
				callback = function(_: number, ctx: TickOrchestrator.TickContext)
					local entry = ctx.outPairs[1] :: { tickValue: number }
					table.insert(p9Saw, entry.tickValue)
				end,
			})
			TickOrchestrator._registerPhases(phases)
			-- Act: two ticks → tickCount 0 then 1
			TickOrchestrator._tick(1 / 15)
			TickOrchestrator._tick(1 / 15)
			-- Assert: Phase 9 in tick 0 saw tickCount 0; tick 1 saw tickCount 1
			expect(#p9Saw).to.equal(2)
			expect(p9Saw[1]).to.equal(0)
			expect(p9Saw[2]).to.equal(1)
		end)

		it("tickCount arg equals ctx.tickCount and matches getCurrentTick post-tick", function()
			-- Arrange: AC-03 — tickCount argument and ctx.tickCount are identical
			local lastCapturedArg: number? = nil
			local lastCapturedCtx: number? = nil
			local phases: { TickOrchestrator.TickPhase } = {}
			table.insert(phases, {
				phase = 1,
				name = "P1",
				callback = function(tick: number, ctx: TickOrchestrator.TickContext)
					lastCapturedArg = tick
					lastCapturedCtx = ctx.tickCount
				end,
			})
			for i = 2, 9 do
				local capturedI = i
				table.insert(phases, {
					phase = capturedI,
					name = "P" .. capturedI,
					callback = function(_: number, _: TickOrchestrator.TickContext) end,
				})
			end
			TickOrchestrator._registerPhases(phases)
			-- Act: drive 10 ticks (tickCounts 0..9)
			for _ = 1, 10 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: last capture was from tickCount=9; getCurrentTick advanced to 10
			expect(lastCapturedArg).to.equal(9)
			expect(lastCapturedCtx).to.equal(9)
			expect(TickOrchestrator.getCurrentTick()).to.equal(10)
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- Delegate short-circuit (AC-05)
	-- ---------------------------------------------------------------------------

	describe("TickOrchestrator delegate short-circuit", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("phase callbacks do NOT fire when delegate is set", function()
			-- Arrange
			local phases, list = recordingPhases()
			TickOrchestrator._registerPhases(phases)
			TickOrchestrator.setTickDelegate(function(_: number) end)
			-- Act: 5 ticks with delegate active
			for _ = 1, 5 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: phase recorder list stays empty
			expect(#list).to.equal(0)
		end)

		it("setTickDelegate(nil) resumes phase iteration on next tick", function()
			-- Arrange
			local phases, list = recordingPhases()
			TickOrchestrator._registerPhases(phases)
			TickOrchestrator.setTickDelegate(function(_: number) end)
			-- Act: one tick with delegate → zero phase calls
			TickOrchestrator._tick(1 / 15)
			expect(#list).to.equal(0)
			-- Clear delegate then fire one more tick
			TickOrchestrator.setTickDelegate(nil)
			TickOrchestrator._tick(1 / 15)
			-- Assert: one full tick of phase iteration ran (9 invocations)
			expect(#list).to.equal(9)
		end)
	end)

	-- ---------------------------------------------------------------------------
	-- Deterministic 1000-tick fixture (AC-10)
	-- ---------------------------------------------------------------------------

	describe("TickOrchestrator deterministic 1000-tick fixture (AC-10)", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("1000 ticks produces 9000 phase invocations in strict 1..9 order", function()
			-- Arrange
			local phases, list = recordingPhases()
			TickOrchestrator._registerPhases(phases)
			-- Act
			for _ = 1, 1000 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: 1000 ticks × 9 phases = 9000 total invocations
			expect(#list).to.equal(9000)
			-- Every consecutive 9-element slice must be exactly {1,2,3,4,5,6,7,8,9}
			for sliceStart = 1, 9000, 9 do
				for offset = 0, 8 do
					expect(list[sliceStart + offset]).to.equal(offset + 1)
				end
			end
		end)
	end)
end
