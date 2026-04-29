--!strict

--[[
	CrowdStateServer — create/destroy lifecycle unit tests.
	Path: tests/unit/crowd-state-server/lifecycle.spec.luau
	Implements: CSM story-001 ACs:
	  AC-01  (Identity — one record per crowdId, no shared keys)
	  AC-16  (Record presence/absence — partial; count/radius validated story-003/-004)
	  create errors loudly on duplicate crowdId
	  destroy is idempotent — no error on absent record
	  create after destroy succeeds (idempotent destroyed-state)
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal but valid CrowdRecord for test fixtures.
	--- count and hue default to 10 and 1 respectively so callers can override
	--- only the fields relevant to their test case.
	local function makeRecord(
		crowdId: string,
		count: number?,
		hue: number?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,  -- placeholder; story-004 computes composed radius
			count = count or 10,
			hue = hue or 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer create/destroy lifecycle", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- Suppress reliable RemoteEvent fanout — Network is not started in
			-- TestEZ context and would error on fireAllClients. CrowdCreated /
			-- CrowdDestroyed payload verification lives in signal_fanout.spec.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		-- AC-01: create stores a record that get() returns by identity.
		-- Verifies the stored reference is exactly what was passed to create,
		-- and that _getCrowdsCount reflects the addition.
		it("create stores a record retrievable via get (AC-01)", function()
			local rec = CrowdStateServer.create("u1", makeRecord("u1"))
			expect(CrowdStateServer.get("u1")).to.equal(rec)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(1)
		end)

		-- AC-01: Two distinct crowdIds produce two separate, non-identical records.
		-- Satisfies the "No two records share a key" constraint.
		it("two distinct crowdIds produce two records (AC-01)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			CrowdStateServer.create("u2", makeRecord("u2"))
			expect(CrowdStateServer._getCrowdsCount()).to.equal(2)
			expect(CrowdStateServer.get("u1")).to.be.ok()
			expect(CrowdStateServer.get("u2")).to.be.ok()
			expect(CrowdStateServer.get("u1") ~= CrowdStateServer.get("u2")).to.equal(true)
		end)

		-- AC-16 (partial): 8-player fixture mirrors the story QA scenario.
		-- Validates _getCrowdsCount == 8 after createAll-equivalent loop.
		it("8-player createAll equivalent — 8 records present (AC-16 partial)", function()
			for i = 1, 8 do
				local id = "u" .. i
				CrowdStateServer.create(id, makeRecord(id))
			end
			expect(CrowdStateServer._getCrowdsCount()).to.equal(8)
			for i = 1, 8 do
				expect(CrowdStateServer.get("u" .. i)).to.be.ok()
			end
		end)

		-- AC-16 (partial): destroyAll equivalent — all records absent after destroy loop.
		it("8-player destroyAll equivalent — 0 records remain (AC-16 partial)", function()
			for i = 1, 8 do
				local id = "u" .. i
				CrowdStateServer.create(id, makeRecord(id))
			end
			for i = 1, 8 do
				CrowdStateServer.destroy("u" .. i)
			end
			expect(CrowdStateServer._getCrowdsCount()).to.equal(0)
			for i = 1, 8 do
				expect(CrowdStateServer.get("u" .. i)).to.equal(nil)
			end
		end)

		-- GDD §Server API "Fails if record exists": duplicate create errors loudly.
		it("create errors loudly on duplicate crowdId", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			local ok, err = pcall(CrowdStateServer.create, "u1", makeRecord("u1"))
			expect(ok).to.equal(false)
			expect(typeof(err)).to.equal("string")
		end)

		-- GDD §Server API "Idempotent (no-op if absent)": destroy on absent record must not error.
		it("destroy is idempotent — no error on absent record", function()
			local ok = pcall(CrowdStateServer.destroy, "u1")
			expect(ok).to.equal(true)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(0)
		end)

		-- destroy removes the record and get returns nil afterward.
		it("destroy removes the record; get returns nil after", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			CrowdStateServer.destroy("u1")
			expect(CrowdStateServer.get("u1")).to.equal(nil)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(0)
		end)

		-- AC-16 idempotent destroyed-state: createAll → destroyAll → createAll again succeeds.
		it("create after destroy succeeds (AC-16 idempotent destroyed-state)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			CrowdStateServer.destroy("u1")
			local rec = CrowdStateServer.create("u1", makeRecord("u1"))
			expect(CrowdStateServer.get("u1")).to.equal(rec)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(1)
		end)

	end)
end
