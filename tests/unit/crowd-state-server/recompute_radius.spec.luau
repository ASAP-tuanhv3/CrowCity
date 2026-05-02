--!strict

--[[
	CrowdStateServer — recomputeRadius write contract unit tests.
	Path: tests/unit/crowd-state-server/recompute_radius.spec.luau
	Implements: CSM story-004 ACs:
	  AC-22 happy path — recomputeRadius(id, 1.35) writes multiplier + radius.
	  AC-22 idempotence — same-value call is a no-op.
	  AC-22 range gate — multiplier outside [0.5, 1.5] rejected with warn.
	  Boundary acceptance — 0.5 and 1.5 (inclusive) accepted.
	  Absent record — assert loud-fails (caller bug).

	Pillar 4 caller-restriction (RelicEffectHandler-only) is code-review
	enforced — no runtime guard. Not tested here.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(
		crowdId: string,
		count: number?,
		multiplier: number?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = multiplier or 1.0,
			radius = 0.0,
			count = count or 100,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	local function near(a: number, b: number, tol: number?): boolean
		return math.abs(a - b) <= (tol or 0.001)
	end

	describe("CrowdStateServer.recomputeRadius — happy path", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1", 100, 1.0))
		end)

		it("AC-22: 1.0 → 1.35 writes multiplier + recomposes radius ≈ 10.80", function()
			local newRadius = CrowdStateServer.recomputeRadius("u1", 1.35)
			expect(near(newRadius, 10.80, 0.001)).to.equal(true)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.radiusMultiplier).to.equal(1.35)
			expect(near(rec.radius, 10.80, 0.001)).to.equal(true)
		end)

		it("returns post-composition radius (number)", function()
			local r = CrowdStateServer.recomputeRadius("u1", 1.2)
			expect(type(r)).to.equal("number")
			expect(near(r, (2.5 + 10 * 0.55) * 1.2, 0.001)).to.equal(true)
		end)
	end)

	describe("CrowdStateServer.recomputeRadius — idempotence", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1", 100, 1.0))
		end)

		it("AC-22: same-value call is a no-op (no field write)", function()
			CrowdStateServer.recomputeRadius("u1", 1.35)
			local before = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			local muxBefore = before.radiusMultiplier
			local radBefore = before.radius

			local result = CrowdStateServer.recomputeRadius("u1", 1.35)
			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.radiusMultiplier).to.equal(muxBefore)
			expect(after.radius).to.equal(radBefore)
			expect(result).to.equal(radBefore)
		end)
	end)

	describe("CrowdStateServer.recomputeRadius — range gate", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1", 100, 1.35))
		end)

		it("rejects 1.8 (above 1.5), preserves prior multiplier + radius", function()
			local before = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			local muxBefore = before.radiusMultiplier
			local radBefore = before.radius

			local result = CrowdStateServer.recomputeRadius("u1", 1.8)
			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.radiusMultiplier).to.equal(muxBefore)
			expect(after.radius).to.equal(radBefore)
			expect(result).to.equal(radBefore)
		end)

		it("rejects 0.4 (below 0.5)", function()
			local before = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			local muxBefore = before.radiusMultiplier
			CrowdStateServer.recomputeRadius("u1", 0.4)
			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.radiusMultiplier).to.equal(muxBefore)
		end)

		it("accepts 0.5 (inclusive lower boundary)", function()
			CrowdStateServer.recomputeRadius("u1", 0.5)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.radiusMultiplier).to.equal(0.5)
		end)

		it("accepts 1.5 (inclusive upper boundary)", function()
			CrowdStateServer.recomputeRadius("u1", 1.5)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.radiusMultiplier).to.equal(1.5)
		end)

		it("rejects negative multiplier", function()
			local muxBefore = (CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord).radiusMultiplier
			CrowdStateServer.recomputeRadius("u1", -1.0)
			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.radiusMultiplier).to.equal(muxBefore)
		end)
	end)

	describe("CrowdStateServer.recomputeRadius — absent record", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("asserts loud on absent crowdId (caller bug)", function()
			local ok, err = pcall(function()
				CrowdStateServer.recomputeRadius("ghost", 1.0)
			end)
			expect(ok).to.equal(false)
			expect(string.find(tostring(err), "record absent")).to.be.ok()
		end)
	end)
end
