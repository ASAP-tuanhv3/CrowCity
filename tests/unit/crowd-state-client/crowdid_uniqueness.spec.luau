--!strict

--[[
	CrowdStateClient — crowdId uniqueness lookup determinism tests.
	Path: tests/unit/crowd-state-client/crowdid_uniqueness.spec.luau

	Implements:
	  AC-22 (crowdId uniqueness per round — read-side)
	    - crowdId == tostring(player.UserId) shape invariant (read-path lookup)
	    - 12-player fixture: _crowds has 12 distinct keys, all matching tostring(UserId) shape
	    - get("u1") returns the exact same record reference until cache is cleared
	    - No second entry under alternate key forms (e.g. numeric key, prefixed key)
	    - Overwriting same crowdId via _debugSetRecord replaces the record (single entry)
	    - crowdId lookup determinism: two broadcasts for same crowdId → one entry

	Write-path enforcement (crowdId == tostring(payload.userId) assertion in broadcast)
	is owned by story-002. This spec covers the read-side invariants only.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)

	--- Constructs a CrowdRecord that simulates what story-002 will write into the
	--- mirror after decoding a broadcast from a player with the given userId.
	--- crowdId is always tostring(userId) per AC-22 invariant (ADR-0001 §crowdId stability).
	local function makeRecordForUser(userId: number, tick: number?): CrowdStateClient.CrowdRecord
		return {
			crowdId = tostring(userId),
			tick = tick or 1,
			position = Vector3.new(0, 0, 0),
			radius = 5.0,
			count = 10,
			hue = (userId % 12) + 1,  -- 1-12 safe palette
			state = "Active" :: "Active" | "GraceWindow" | "Eliminated",
			activeRelics = {} :: { string },
		}
	end

	describe("CrowdStateClient crowdId uniqueness — read-side (AC-22)", function()

		beforeEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-22: crowdId key is always tostring(userId); seeding with tostring produces
		-- exactly one entry, retrievable by the same key.
		it("get(tostring(userId)) retrieves the correct record by identity (AC-22)", function()
			local userId = 100001
			local rec = makeRecordForUser(userId)
			CrowdStateClient._debugSetRecord(tostring(userId), rec)
			local result = CrowdStateClient.get(tostring(userId))
			expect(result).to.equal(rec)
		end)

		-- AC-22: crowdId as numeric string is distinct from numeric key.
		-- Only the string key form is valid. Numeric lookup must return nil.
		it("numeric key lookup returns nil — only string crowdId is valid (AC-22)", function()
			local userId = 100001
			CrowdStateClient._debugSetRecord(tostring(userId), makeRecordForUser(userId))
			-- Attempt lookup with a different string form — must not find the record.
			-- tostring(userId) == "100001"; any other key shape is absent.
			expect(CrowdStateClient.get("00100001")).to.equal(nil)  -- zero-padded
			expect(CrowdStateClient.get("u100001")).to.equal(nil)   -- prefixed
			expect(CrowdStateClient.get("100001")).to.be.ok()        -- exact match
		end)

		-- AC-22: Two seedings for same crowdId → only one entry (second overwrites first).
		-- Simulates two broadcasts for same crowd; write path must not create duplicate keys.
		it("two seedings for same crowdId result in one cache entry (AC-22)", function()
			local crowdId = "100001"
			local rec1 = makeRecordForUser(100001, 1)
			local rec2 = makeRecordForUser(100001, 2)

			CrowdStateClient._debugSetRecord(crowdId, rec1)
			CrowdStateClient._debugSetRecord(crowdId, rec2)

			-- Only one record under this key.
			local result = CrowdStateClient.get(crowdId)
			expect(result).to.equal(rec2)  -- second write wins
			expect(result ~= rec1).to.equal(true)

			-- getAllActive should contain exactly one record (no duplicates).
			local all = CrowdStateClient.getAllActive()
			local count = 0
			for _, r in all do
				if r.crowdId == crowdId then
					count += 1
				end
			end
			expect(count).to.equal(1)
		end)

		-- AC-22: get returns the EXACT same reference on repeated calls until cleared.
		-- Lookup determinism: same crowdId → same record until a destroy event clears it.
		it("get returns the same record reference on repeated calls (lookup determinism)", function()
			local rec = makeRecordForUser(200001)
			CrowdStateClient._debugSetRecord("200001", rec)

			local r1 = CrowdStateClient.get("200001")
			local r2 = CrowdStateClient.get("200001")
			local r3 = CrowdStateClient.get("200001")

			expect(r1).to.equal(rec)
			expect(r2).to.equal(rec)
			expect(r3).to.equal(rec)
			-- All three are the same reference.
			expect(r1).to.equal(r2)
			expect(r2).to.equal(r3)
		end)

		-- AC-22: 12-player fixture. All 12 crowdIds are distinct; all match tostring(UserId) form.
		-- Verifies _crowds holds exactly 12 entries with no key collisions.
		it("12-player fixture: 12 distinct crowdId entries with no collisions (AC-22)", function()
			-- Simulate 12 players with distinct UserIds.
			local userIds = {
				100001, 100002, 100003, 100004,
				100005, 100006, 100007, 100008,
				100009, 100010, 100011, 100012,
			}

			for _, userId in userIds do
				CrowdStateClient._debugSetRecord(tostring(userId), makeRecordForUser(userId))
			end

			-- All 12 must be retrievable by their exact crowdId.
			for _, userId in userIds do
				local crowdId = tostring(userId)
				local result = CrowdStateClient.get(crowdId)
				expect(result).to.be.ok()
				expect(result ~= nil and result.crowdId).to.equal(crowdId)
			end

			-- getAllActive must contain exactly 12 entries.
			local all = CrowdStateClient.getAllActive()
			expect(#all).to.equal(12)

			-- All 12 entries have distinct crowdIds (no key collision / no entry shared).
			local seen: { [string]: boolean } = {}
			for _, record in all do
				expect(seen[record.crowdId]).to.equal(nil)  -- not yet seen
				seen[record.crowdId] = true
			end

			-- All keys match tostring(UserId) shape (numeric string, no prefix/suffix).
			for _, record in all do
				local asNumber = tonumber(record.crowdId)
				-- tonumber succeeds on a valid UserId string.
				expect(asNumber ~= nil).to.equal(true)
				-- Roundtrip: tostring(tonumber(crowdId)) == crowdId (no leading zeros, etc.)
				expect(tostring(asNumber)).to.equal(record.crowdId)
			end
		end)

		-- AC-22 edge: after _debugClearAll, all 12 entries are gone (destroy-event analog).
		it("12-player fixture entries absent after debugClearAll (destroy-event analog)", function()
			local userIds = { 100001, 100002, 100003, 100004, 100005, 100006,
				100007, 100008, 100009, 100010, 100011, 100012 }
			for _, userId in userIds do
				CrowdStateClient._debugSetRecord(tostring(userId), makeRecordForUser(userId))
			end

			CrowdStateClient._debugClearAll()

			for _, userId in userIds do
				expect(CrowdStateClient.get(tostring(userId))).to.equal(nil)
			end
			expect(#CrowdStateClient.getAllActive()).to.equal(0)
		end)

		-- AC-22: _debugGetLastReceivedTick tracks the tick of the seeded record.
		-- (Used by story-002 stale-defense tests; validated here to confirm the seam works.)
		it("_debugGetLastReceivedTick returns the seeded record's tick (stale-defense seam)", function()
			local rec = makeRecordForUser(300001, 42)
			CrowdStateClient._debugSetRecord("300001", rec)
			local lastTick = CrowdStateClient._debugGetLastReceivedTick("300001")
			expect(lastTick).to.equal(42)
		end)

		-- AC-22: _debugGetLastReceivedTick returns nil for absent crowdId.
		it("_debugGetLastReceivedTick returns nil for absent crowdId", function()
			local lastTick = CrowdStateClient._debugGetLastReceivedTick("999999")
			expect(lastTick).to.equal(nil)
		end)

	end)

end
