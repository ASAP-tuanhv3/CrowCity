--!strict

--[[
	CrowdStateServer — activeRelics cap + addActiveRelic/removeActiveRelic API.
	Path: tests/unit/crowd-state-server/active_relics_cap.spec.luau
	Implements: CSM story-003 ACs:
	  AC-06 (activeRelics cap) — list capped at 4; 5th grant rejected.
	  Duplicate rejection — re-add of present specId returns false, no insert.
	  Remove + free slot — remove enables subsequent add up to cap.
	  Remove absent — returns false, no event, list unchanged.
	  Absent crowd — addActiveRelic / removeActiveRelic on missing record → false.
	  activeRelics initialized empty in create.

	No event-firing assertions live here — see relic_changed_signal.spec.luau
	for the CrowdRelicChanged fanout contract.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	local function makeRecord(crowdId: string): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = 10,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.addActiveRelic — happy path + cap enforcement", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- Suppress reliable RemoteEvent fanout — Network is not started in
			-- TestEZ context. CrowdRelicChanged payload assertions live in
			-- relic_changed_signal.spec.luau.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1"))
		end)

		it("AC-06: first add returns true and stores specId", function()
			local ok = CrowdStateServer.addActiveRelic("u1", "A")
			expect(ok).to.equal(true)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(1)
			expect(rec.activeRelics[1]).to.equal("A")
		end)

		it("AC-06: 4 distinct adds all succeed", function()
			expect(CrowdStateServer.addActiveRelic("u1", "A")).to.equal(true)
			expect(CrowdStateServer.addActiveRelic("u1", "B")).to.equal(true)
			expect(CrowdStateServer.addActiveRelic("u1", "C")).to.equal(true)
			expect(CrowdStateServer.addActiveRelic("u1", "D")).to.equal(true)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(4)
		end)

		it("AC-06: 5th add rejected, list unchanged at length 4", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			CrowdStateServer.addActiveRelic("u1", "B")
			CrowdStateServer.addActiveRelic("u1", "C")
			CrowdStateServer.addActiveRelic("u1", "D")
			local ok = CrowdStateServer.addActiveRelic("u1", "E")
			expect(ok).to.equal(false)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(4)
			-- Verify "E" was not appended.
			for _, id in rec.activeRelics do
				expect(id).never.to.equal("E")
			end
		end)
	end)

	describe("CrowdStateServer.addActiveRelic — duplicate rejection", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- Suppress reliable RemoteEvent fanout — Network is not started in
			-- TestEZ context. CrowdRelicChanged payload assertions live in
			-- relic_changed_signal.spec.luau.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1"))
		end)

		it("re-adding present specId returns false, no duplicate inserted", function()
			expect(CrowdStateServer.addActiveRelic("u1", "A")).to.equal(true)
			local ok = CrowdStateServer.addActiveRelic("u1", "A")
			expect(ok).to.equal(false)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(1)
			expect(rec.activeRelics[1]).to.equal("A")
		end)
	end)

	describe("CrowdStateServer.removeActiveRelic — basic + free-slot", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1"))
			CrowdStateServer.addActiveRelic("u1", "A")
			CrowdStateServer.addActiveRelic("u1", "B")
			CrowdStateServer.addActiveRelic("u1", "C")
			CrowdStateServer.addActiveRelic("u1", "D")
		end)

		it("removes present specId and returns true", function()
			local ok = CrowdStateServer.removeActiveRelic("u1", "A")
			expect(ok).to.equal(true)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(3)
			-- Confirm "A" gone; survivors B/C/D present (order-agnostic).
			local seen = {}
			for _, id in rec.activeRelics do
				seen[id] = true
			end
			expect(seen["A"]).to.equal(nil)
			expect(seen["B"]).to.equal(true)
			expect(seen["C"]).to.equal(true)
			expect(seen["D"]).to.equal(true)
		end)

		it("freed slot allows subsequent add up to cap", function()
			CrowdStateServer.removeActiveRelic("u1", "A")
			local ok = CrowdStateServer.addActiveRelic("u1", "E")
			expect(ok).to.equal(true)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(4)
			local seen = {}
			for _, id in rec.activeRelics do
				seen[id] = true
			end
			expect(seen["E"]).to.equal(true)
		end)

		it("returns false for absent specId, list unchanged", function()
			local ok = CrowdStateServer.removeActiveRelic("u1", "Z")
			expect(ok).to.equal(false)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(4)
		end)
	end)

	describe("CrowdStateServer relic helpers — absent crowd race-tolerance", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- No record created — every helper must return false silently.
		end)

		it("addActiveRelic on absent crowd returns false", function()
			local ok = CrowdStateServer.addActiveRelic("nonexistent", "A")
			expect(ok).to.equal(false)
		end)

		it("removeActiveRelic on absent crowd returns false", function()
			local ok = CrowdStateServer.removeActiveRelic("nonexistent", "A")
			expect(ok).to.equal(false)
		end)
	end)

	describe("CrowdStateServer.create — activeRelics initialized empty", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("post-create activeRelics has length 0", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(0)
		end)
	end)
end
