--!strict
-- Tests: CrowdStateServer read accessors (get, getAllActive, getAllCrowdPositions)
-- Story: story-007-read-accessors-set-still-overlapping
-- AC mapping: AC-27 (getAllActive excludes Eliminated), getAllCrowdPositions snapshot,
--             fresh-table guarantees, get nil on absent.
-- Type: Logic — automated TestEZ spec (blocking gate).

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string, state: CrowdStateServer.CrowdState, pos: Vector3?): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = pos or Vector3.new(0, 0, 0),
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

	describe("CrowdStateServer read accessors", function()
		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("get returns nil for absent record", function()
			expect(CrowdStateServer.get("nonexistent")).to.equal(nil)
		end)

		it("AC-27: getAllActive includes Active + GraceWindow, excludes Eliminated", function()
			CrowdStateServer.create("A", makeRecord("A", "Active"))
			CrowdStateServer.create("B", makeRecord("B", "GraceWindow"))
			CrowdStateServer.create("C", makeRecord("C", "Eliminated"))

			local active = CrowdStateServer.getAllActive()
			expect(#active).to.equal(2)

			-- Both A and B present; C absent.
			local seenA, seenB, seenC = false, false, false
			for _, rec in active do
				if rec.crowdId == "A" then seenA = true end
				if rec.crowdId == "B" then seenB = true end
				if rec.crowdId == "C" then seenC = true end
			end
			expect(seenA).to.equal(true)
			expect(seenB).to.equal(true)
			expect(seenC).to.equal(false)
		end)

		it("getAllActive returns empty array when all crowds Eliminated", function()
			CrowdStateServer.create("A", makeRecord("A", "Eliminated"))
			CrowdStateServer.create("B", makeRecord("B", "Eliminated"))
			expect(#CrowdStateServer.getAllActive()).to.equal(0)
		end)

		it("getAllActive returns fresh array each call (distinct table refs)", function()
			CrowdStateServer.create("A", makeRecord("A", "Active"))
			local arr1 = CrowdStateServer.getAllActive()
			local arr2 = CrowdStateServer.getAllActive()
			expect(arr1 ~= arr2).to.equal(true)  -- distinct refs
			expect(#arr1).to.equal(1)
			expect(#arr2).to.equal(1)
		end)

		it("getAllCrowdPositions snapshot map keyed by crowdId", function()
			CrowdStateServer.create("A", makeRecord("A", "Active", Vector3.new(1, 0, 0)))
			CrowdStateServer.create("B", makeRecord("B", "GraceWindow", Vector3.new(2, 0, 0)))

			local positions = CrowdStateServer.getAllCrowdPositions()
			expect(positions["A"]).to.equal(Vector3.new(1, 0, 0))
			expect(positions["B"]).to.equal(Vector3.new(2, 0, 0))
		end)

		it("getAllCrowdPositions excludes Eliminated records", function()
			CrowdStateServer.create("A", makeRecord("A", "Active", Vector3.new(1, 0, 0)))
			CrowdStateServer.create("C", makeRecord("C", "Eliminated", Vector3.new(99, 0, 0)))

			local positions = CrowdStateServer.getAllCrowdPositions()
			expect(positions["A"]).to.be.ok()
			expect(positions["C"]).to.equal(nil)

			-- Map size = 1
			local count = 0
			for _ in positions do count += 1 end
			expect(count).to.equal(1)
		end)

		it("getAllCrowdPositions returns fresh map each call (distinct table refs)", function()
			CrowdStateServer.create("A", makeRecord("A", "Active"))
			local m1 = CrowdStateServer.getAllCrowdPositions()
			local m2 = CrowdStateServer.getAllCrowdPositions()
			expect(m1 ~= m2).to.equal(true)
		end)
	end)
end
