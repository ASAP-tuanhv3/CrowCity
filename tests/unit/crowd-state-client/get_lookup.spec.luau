--!strict

--[[
	CrowdStateClient — get() and getAllActive() lookup unit tests.
	Path: tests/unit/crowd-state-client/get_lookup.spec.luau

	Implements:
	  AC-18 (Nil crowdId lookup) — get("999999") returns nil when cache empty;
	                               get("u1") returns record when seeded;
	                               get("u2") returns nil when only u1 cached.
	  getAllActive() shape — fresh array each call; records inside are live refs.

	Cache write path (story-002) is not available here. Tests use _debugSetRecord
	to seed the cache directly per story-001 §Implementation Notes "seam for tests".
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	--- Only crowdId and tick are varied; other fields are defaults.
	local function makeRecord(crowdId: string, tick: number?): CrowdStateClient.CrowdRecord
		return {
			crowdId = crowdId,
			tick = tick or 1,
			position = Vector3.new(0, 0, 0),
			radius = 5.0,
			count = 10,
			hue = 1,
			state = "Active" :: "Active" | "GraceWindow" | "Eliminated",
			activeRelics = {} :: { string },
		}
	end

	describe("CrowdStateClient get() — nil lookup (AC-18)", function()

		beforeEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-18: empty cache, unknown id → nil (not empty table, not error, not default struct).
		it("get returns nil for unknown crowdId on empty cache (AC-18)", function()
			local result = CrowdStateClient.get("999999")
			expect(result).to.equal(nil)
		end)

		-- AC-18: seeded u1; get("u1") returns a non-nil record.
		it("get returns non-nil when crowdId is present in cache (AC-18)", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			local result = CrowdStateClient.get("u1")
			expect(result).to.be.ok()
		end)

		-- AC-18: seeded u1 only; get("u2") still returns nil.
		it("get returns nil for absent crowdId when another record exists (AC-18 mixed)", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			local result = CrowdStateClient.get("u2")
			expect(result).to.equal(nil)
		end)

		-- get returns the exact same reference that was seeded (no copy on read).
		it("get returns the seeded record by reference (same table)", function()
			local rec = makeRecord("u1")
			CrowdStateClient._debugSetRecord("u1", rec)
			local result = CrowdStateClient.get("u1")
			expect(result).to.equal(rec)
		end)

		-- Multiple absent lookups all return nil (no cross-contamination).
		it("multiple absent lookups all return nil (no state leakage)", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			expect(CrowdStateClient.get("u2")).to.equal(nil)
			expect(CrowdStateClient.get("u3")).to.equal(nil)
			expect(CrowdStateClient.get("999999")).to.equal(nil)
		end)

		-- get after _debugClearAll returns nil even for previously seeded records.
		it("get returns nil after debugClearAll clears the cache", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			CrowdStateClient._debugClearAll()
			expect(CrowdStateClient.get("u1")).to.equal(nil)
		end)

	end)

	describe("CrowdStateClient getAllActive() — shape + freshness", function()

		beforeEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- Empty cache: getAllActive returns an empty array (not nil, not error).
		it("getAllActive returns empty array when cache is empty", function()
			local result = CrowdStateClient.getAllActive()
			expect(type(result)).to.equal("table")
			expect(#result).to.equal(0)
		end)

		-- One record seeded: getAllActive returns array of length 1.
		it("getAllActive returns array of length 1 with one record seeded", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			local result = CrowdStateClient.getAllActive()
			expect(#result).to.equal(1)
		end)

		-- Three records: getAllActive returns all three.
		it("getAllActive returns all seeded records", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			CrowdStateClient._debugSetRecord("u2", makeRecord("u2"))
			CrowdStateClient._debugSetRecord("u3", makeRecord("u3"))
			local result = CrowdStateClient.getAllActive()
			expect(#result).to.equal(3)
		end)

		-- getAllActive returns a FRESH array each call (distinct table refs).
		-- Records inside still point to the same live cache entries.
		it("getAllActive returns a fresh array each call (distinct array refs)", function()
			CrowdStateClient._debugSetRecord("u1", makeRecord("u1"))
			local arr1 = CrowdStateClient.getAllActive()
			local arr2 = CrowdStateClient.getAllActive()
			expect(arr1 ~= arr2).to.equal(true)
			-- Records inside are same refs (live cache entries).
			expect(arr1[1]).to.equal(arr2[1])
		end)

		-- getAllActive includes records in all states (client mirror tracks everything
		-- including Eliminated until a reliable destroy event clears it — story-003).
		it("getAllActive includes records of all states (Active, GraceWindow, Eliminated)", function()
			local recA: CrowdStateClient.CrowdRecord = {
				crowdId = "u1", tick = 1, position = Vector3.new(0,0,0),
				radius = 5.0, count = 10, hue = 1,
				state = "Active" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			}
			local recG: CrowdStateClient.CrowdRecord = {
				crowdId = "u2", tick = 1, position = Vector3.new(0,0,0),
				radius = 5.0, count = 1, hue = 2,
				state = "GraceWindow" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			}
			local recE: CrowdStateClient.CrowdRecord = {
				crowdId = "u3", tick = 1, position = Vector3.new(0,0,0),
				radius = 5.0, count = 0, hue = 3,
				state = "Eliminated" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			}
			CrowdStateClient._debugSetRecord("u1", recA)
			CrowdStateClient._debugSetRecord("u2", recG)
			CrowdStateClient._debugSetRecord("u3", recE)

			local result = CrowdStateClient.getAllActive()
			expect(#result).to.equal(3)
		end)

	end)

end
