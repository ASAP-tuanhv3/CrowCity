--!strict

--[[
	CrowdStateServer — updateCount F5 clamp [1, 300] unit tests.
	Path: tests/unit/crowd-state-server/updatecount_clamp.spec.luau
	Implements: CSM story-002 ACs:
	  AC-03 (Count Floor via Relic — count=3, delta=-50 → count=1, state Active)
	  AC-04 (Count Ceiling — count=250, delta=+100 → count=300)
	  AC-15 (Same-tick delta ordering — deltas apply in call order)
	  Returns post-clamp count (architecture.md §5.1 L534)
	  Absent record → assert error (caller bug per ADR-0004)
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string, count: number): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = count,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.updateCount F5 clamp [1, 300]", function()
		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		-- AC-03: floor clamp — count=3, delta=-50 → count=1, state remains Active,
		-- no GraceWindow timer starts (state transition is story-006).
		it("AC-03: count=3, delta=-50, source='Relic' → count=1 (floor clamp)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 3))
			local result = CrowdStateServer.updateCount("u1", -50, "Relic")
			expect(result).to.equal(1)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(1)
			expect(rec.state).to.equal("Active")
			expect(rec.timer_start).to.equal(nil)
		end)

		-- AC-04: ceiling clamp — count=250, delta=+100 → count=300, excess discarded.
		it("AC-04: count=250, delta=+100, source='Absorb' → count=300 (ceiling clamp)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 250))
			local result = CrowdStateServer.updateCount("u1", 100, "Absorb")
			expect(result).to.equal(300)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(300)
		end)

		-- Ceiling no-op: count=300, delta=+1 → count stays at 300, effective_delta==0.
		it("count=300, delta=+1 → count stays at 300 (ceiling no-op)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 300))
			local result = CrowdStateServer.updateCount("u1", 1, "Absorb")
			expect(result).to.equal(300)
		end)

		-- Floor no-op: count=1, delta=-1 → count stays at 1, effective_delta==0.
		it("count=1, delta=-1 → count stays at 1 (floor no-op)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1))
			local result = CrowdStateServer.updateCount("u1", -1, "Relic")
			expect(result).to.equal(1)
		end)

		-- Return value: returns post-clamp count per architecture.md §5.1 L534.
		it("returns post-clamp count (architecture.md §5.1 L534)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 50))
			local result = CrowdStateServer.updateCount("u1", 5, "Absorb")
			expect(result).to.equal(55)
		end)

		-- AC-15: same-tick deltas apply in call order. CSM applies each delta
		-- sequentially as received; TickOrchestrator phase order determines which
		-- caller fires first (story-002 of tick-orchestrator epic).
		it("AC-15 same-tick deltas apply in call order", function()
			CrowdStateServer.create("u1", makeRecord("u1", 3))
			-- 3 - 2 = 1 (floor, but exact)
			expect(CrowdStateServer.updateCount("u1", -2, "Collision")).to.equal(1)
			-- 1 + 5 = 6
			expect(CrowdStateServer.updateCount("u1", 5, "Relic")).to.equal(6)
			-- 6 + 1 = 7
			expect(CrowdStateServer.updateCount("u1", 1, "Absorb")).to.equal(7)
			-- Chest's guard would reject from here per spec; CSM doesn't see that.
		end)

		-- Absent record → assert error (caller bug per ADR-0004 §Decision tone).
		it("absent record → assert error (caller bug per ADR-0004)", function()
			local ok, err = pcall(CrowdStateServer.updateCount, "nonexistent", 1, "Absorb")
			expect(ok).to.equal(false)
			expect(typeof(err)).to.equal("string")
		end)
	end)
end
