--!strict
-- Tests: CrowdStateServer.setStillOverlapping
-- Story: story-007-read-accessors-set-still-overlapping
-- AC mapping: AC-28 (write true/false, last-write-wins, absent-record no-op,
--             unconditional write on Eliminated).
-- Type: Logic — automated TestEZ spec (blocking gate).

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string, state: CrowdStateServer.CrowdState): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = 10,
			hue = 1,
			activeRelics = {} :: { string },
			state = state,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.setStillOverlapping", function()
		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("AC-28: write true → flag becomes true", function()
			CrowdStateServer.create("B", makeRecord("B", "GraceWindow"))
			CrowdStateServer.setStillOverlapping("B", true)
			local rec = CrowdStateServer.get("B") :: CrowdStateServer.CrowdRecord
			expect(rec.stillOverlapping).to.equal(true)
		end)

		it("AC-28: write false → flag becomes false", function()
			CrowdStateServer.create("B", makeRecord("B", "GraceWindow"))
			CrowdStateServer.setStillOverlapping("B", true)
			CrowdStateServer.setStillOverlapping("B", false)
			local rec = CrowdStateServer.get("B") :: CrowdStateServer.CrowdRecord
			expect(rec.stillOverlapping).to.equal(false)
		end)

		it("absent-record no-op (no error)", function()
			local ok = pcall(CrowdStateServer.setStillOverlapping, "nonexistent", true)
			expect(ok).to.equal(true)
		end)

		it("last-write-wins within same tick (true → false)", function()
			CrowdStateServer.create("B", makeRecord("B", "GraceWindow"))
			CrowdStateServer.setStillOverlapping("B", true)
			CrowdStateServer.setStillOverlapping("B", false)
			local rec = CrowdStateServer.get("B") :: CrowdStateServer.CrowdRecord
			expect(rec.stillOverlapping).to.equal(false)
		end)

		it("write on Eliminated record is unconditional (CCR is responsible for not calling)", function()
			-- CSM does NOT gate on state — write is unconditional. Caller (CCR)
			-- is responsible for filtering Eliminated via getAllActive.
			CrowdStateServer.create("C", makeRecord("C", "Eliminated"))
			CrowdStateServer.setStillOverlapping("C", true)
			local rec = CrowdStateServer.get("C") :: CrowdStateServer.CrowdRecord
			expect(rec.stillOverlapping).to.equal(true)
		end)
	end)
end
