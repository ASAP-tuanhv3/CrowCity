--!strict

--[[
	CrowdStateServer — F1 composed radius unit tests.
	Path: tests/unit/crowd-state-server/radius_compose.spec.luau
	Implements: CSM story-004 ACs:
	  AC-21 (radiusMultiplier composition) — radius = (2.5 + sqrt(count) * 0.55)
	    * radiusMultiplier; example count=100, μ=1.35 → ≈10.80.
	  AC-16 radius portion — fresh createAll: count=10, μ=1.0 → ≈4.24.
	  Integration with updateCount — count change re-composes radius post-clamp.
	  Boundary cases — count=1 / count=300 across μ=0.5 / 1.0 / 1.5.

	Pure F1 math + side-effect verification. Range-gate + idempotence in
	recompute_radius.spec.luau.
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
			radius = 0.0,  -- create() recomposes; callers may pass any value
			count = count or 10,
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

	describe("CrowdStateServer F1 — create-time radius composition", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("AC-16: count=10, μ=1.0 yields radius ≈ 4.24 (4.239)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 10, 1.0))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(near(rec.radius, 2.5 + math.sqrt(10) * 0.55, 0.001)).to.equal(true)
		end)

		it("count=100, μ=1.0 yields radius ≈ 8.00", function()
			CrowdStateServer.create("u1", makeRecord("u1", 100, 1.0))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(near(rec.radius, 8.00, 0.001)).to.equal(true)
		end)

		it("AC-21: count=100, μ=1.35 (Wingspan) yields radius ≈ 10.80", function()
			CrowdStateServer.create("u1", makeRecord("u1", 100, 1.35))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(near(rec.radius, 10.80, 0.001)).to.equal(true)
		end)

		it("count=300, μ=1.5 yields composed-ceiling ≈ 18.04", function()
			CrowdStateServer.create("u1", makeRecord("u1", 300, 1.5))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(near(rec.radius, (2.5 + math.sqrt(300) * 0.55) * 1.5, 0.005)).to.equal(true)
		end)

		it("count=1, μ=0.5 yields composed-floor ≈ 1.525", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, 0.5))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(near(rec.radius, (2.5 + 1.0 * 0.55) * 0.5, 0.001)).to.equal(true)
		end)

		it("create overwrites caller-supplied stale radius", function()
			-- Caller passes radius=999; CSM must overwrite with composed value.
			local stale = makeRecord("u1", 10, 1.0)
			stale.radius = 999.0
			CrowdStateServer.create("u1", stale)
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.radius < 100).to.equal(true)
			expect(near(rec.radius, 2.5 + math.sqrt(10) * 0.55, 0.001)).to.equal(true)
		end)
	end)

	describe("CrowdStateServer F1 — updateCount triggers radius recomposition", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			CrowdStateServer.create("u1", makeRecord("u1", 10, 1.0))
		end)

		it("count 10 → 100 via Absorb deltas recomposes radius ≈ 8.00", function()
			CrowdStateServer.updateCount("u1", 90, "Absorb")
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(100)
			expect(near(rec.radius, 8.00, 0.001)).to.equal(true)
		end)

		it("count saturates at 300 via overflow → radius ≈ 12.03", function()
			CrowdStateServer.updateCount("u1", 500, "Absorb")
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(300)
			expect(near(rec.radius, 2.5 + math.sqrt(300) * 0.55, 0.005)).to.equal(true)
		end)

		it("zero-effective-delta (already at ceiling) does NOT alter radius", function()
			CrowdStateServer.updateCount("u1", 500, "Absorb")  -- saturate to 300
			local before = (CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord).radius
			CrowdStateServer.updateCount("u1", 50, "Absorb")  -- already at 300; no-op
			local after = (CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord).radius
			expect(after).to.equal(before)
		end)

		it("count drain recomposes downward", function()
			CrowdStateServer.updateCount("u1", 90, "Absorb")  -- 10 → 100, radius ≈ 8.00
			CrowdStateServer.updateCount("u1", -50, "Collision")  -- 100 → 50
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(50)
			expect(near(rec.radius, 2.5 + math.sqrt(50) * 0.55, 0.001)).to.equal(true)
		end)
	end)
end
