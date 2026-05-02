--!strict

--[[
	CrowdStateServer — F7 grace timer math unit tests.
	Path: tests/unit/crowd-state-server/grace_timer.spec.luau
	Implements: CSM story-006 ACs:
	  F7 timer threshold — exactly 3.0s elapsed AND still overlapping → Eliminated.
	  Just below 3.0s elapsed → still GraceWindow.
	  Just above 3.0s elapsed → Eliminated.
	  Timer cleared on Active transition.

	Per AC-13 tie-break the comparison is `>= GRACE_WINDOW_SEC` so 3.0 exactly
	is the elimination threshold. Sub-3.0 stays in Grace.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 4.24,
			count = 1,
			hue = 1,
			activeRelics = {} :: { string },
			state = "GraceWindow" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer F7 — grace timer threshold", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("2.9s elapsed + still overlapping → state stays GraceWindow", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 2.9
			rec.stillOverlapping = true

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("GraceWindow")
			expect(after.timer_start).never.to.equal(nil)
		end)

		it("3.0s elapsed + still overlapping → Eliminated (>= threshold)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 3.0
			rec.stillOverlapping = true

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Eliminated")
		end)

		it("4.0s elapsed + still overlapping → Eliminated", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 4.0
			rec.stillOverlapping = true

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Eliminated")
		end)

		it("3.5s elapsed + NOT overlapping → exits Grace via overlap-clear (Active)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 3.5
			rec.stillOverlapping = false

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Active")
			expect(after.timer_start).to.equal(nil)
		end)

		it("0.5s elapsed + NOT overlapping → Active immediately", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 0.5
			rec.stillOverlapping = false

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Active")
			expect(after.timer_start).to.equal(nil)
		end)
	end)
end
