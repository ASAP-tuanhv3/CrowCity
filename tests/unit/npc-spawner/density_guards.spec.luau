--!strict

--[[
	NPCSpawner density guards — unit tests (Story 5-8).
	Path: tests/unit/npc-spawner/density_guards.spec.luau
	Implements:
	  F2 R_absorb formula — NPCSpawner.getAbsorbRate(crowdRadius)
	  F4 steady-state formula — NPCSpawner.getSteadyStateActive(R_absorb_total)
	  EPSILON_DENSITY guard — R_absorb ≤ EPSILON returns NPC_POOL_SIZE directly
	  Boundary cases — count=1 (min radius) and count=300 (max radius)

	Pure functions — no state mutation. Tests use NPCSpawner.init({arenaArea=40000})
	to bootstrap ρ_design + drain pre-alloc batches. Mirror style of pool_bootstrap.spec.luau.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)

	local function buildMockRunService()
		local fakeHeartbeat = {
			Connect = function(_self: any, _cb: (number) -> ()): any
				return { Disconnect = function() end }
			end,
		}
		return { Heartbeat = fakeHeartbeat } :: any
	end

	describe("NPCSpawner density guards (F2/F4)", function()
		afterEach(function()
			NPCSpawner._resetForTests()
		end)

		-- F2: getAbsorbRate(radius) — formula: radius * 2 * NPC_WALK_SPEED * ρ_design.
		-- ρ_design = 300 / 40000 = 0.0075; NPC_WALK_SPEED = 4.
		it("F2 — getAbsorbRate returns radius * 2 * walk_speed * rho_design", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert: radius=10 → 10 * 2 * 4 * 0.0075 = 0.6
			local rate = NPCSpawner.getAbsorbRate(10)
			local expected = 10 * 2 * 4 * (300 / 40000)
			expect(math.abs(rate - expected) < 1e-9).to.equal(true)
		end)

		-- F2 EPSILON guard: zero or near-zero radius → finite (no NaN, no inf).
		it("F2 — getAbsorbRate near-zero radius does not divide by zero", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert: radius=0 → rate=0; finite, no NaN
			local rate0 = NPCSpawner.getAbsorbRate(0)
			expect(rate0).to.equal(0)
			expect(rate0 == rate0).to.equal(true) -- NaN check (NaN ≠ NaN)

			local rateTiny = NPCSpawner.getAbsorbRate(1e-9)
			expect(rateTiny == rateTiny).to.equal(true)
			expect(rateTiny >= 0).to.equal(true)
		end)

		-- F2 boundary: count=1 → small radius → low absorb rate.
		-- Use small radius (e.g., 5 studs ≈ smallest crowd radius from CSM clamp).
		it("F2 — boundary count=1 produces minimum absorb rate", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert
			local rateMin = NPCSpawner.getAbsorbRate(5)
			local rateLarger = NPCSpawner.getAbsorbRate(20)
			expect(rateMin < rateLarger).to.equal(true)
			expect(rateMin > 0).to.equal(true)
		end)

		-- F2 boundary: count=300 → large radius → high absorb rate (capped by physics, not formula).
		it("F2 — boundary count=300 (large radius) returns scaled rate", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert: radius=30 (CSM max for count=300) → rate = 30 * 2 * 4 * 0.0075 = 1.8
			local rateMax = NPCSpawner.getAbsorbRate(30)
			local expected = 30 * 2 * 4 * (300 / 40000)
			expect(math.abs(rateMax - expected) < 1e-9).to.equal(true)
		end)

		-- F4 EPSILON guard: R_absorb_total ≤ EPSILON_DENSITY → returns NPC_POOL_SIZE.
		-- This is the zero-crowd lobby case: no absorbs happening, pool is full.
		it("F4 — EPSILON_DENSITY guard returns NPC_POOL_SIZE at zero absorb", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert: zero absorb rate → all 300 NPCs steady-state
			local steadyZero = NPCSpawner.getSteadyStateActive(0)
			expect(steadyZero).to.equal(300)

			local steadyTiny = NPCSpawner.getSteadyStateActive(1e-9)
			expect(steadyTiny).to.equal(300)
		end)

		-- F4 typical: R_absorb_total = 1.0 → steady-state per formula.
		-- N_steady = 300 × (R_respawn_avg / (1.0 + R_respawn_avg))
		-- R_respawn_avg = 1 / 7.5 ≈ 0.1333
		-- N_steady ≈ 300 × (0.1333 / 1.1333) ≈ 300 × 0.1176 ≈ 35.3
		it("F4 — steady-state under load returns reduced active count", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act
			local steady = NPCSpawner.getSteadyStateActive(1.0)

			-- Assert: count drops well below pool size at moderate absorb rate
			expect(steady < 300).to.equal(true)
			expect(steady > 0).to.equal(true)

			-- Verify formula: N = 300 * R_respawn_avg / (R_absorb + R_respawn_avg)
			local R_respawn_avg = 1.0 / 7.5
			local expected = 300 * R_respawn_avg / (1.0 + R_respawn_avg)
			expect(math.abs(steady - expected) < 1e-6).to.equal(true)
		end)

		-- F4 monotonicity: higher R_absorb_total → fewer active NPCs steady-state.
		it("F4 — steady-state monotonically decreases as R_absorb_total grows", function()
			-- Arrange
			NPCSpawner.init({ runService = buildMockRunService(), arenaArea = 40000 })
			task.wait()

			-- Act + Assert
			local low = NPCSpawner.getSteadyStateActive(0.1)
			local mid = NPCSpawner.getSteadyStateActive(1.0)
			local high = NPCSpawner.getSteadyStateActive(10.0)

			expect(low > mid).to.equal(true)
			expect(mid > high).to.equal(true)
			expect(high > 0).to.equal(true)
		end)

		-- Pre-init guard: getAbsorbRate raises before init().
		it("getAbsorbRate raises before init", function()
			-- Arrange: no init

			-- Act + Assert
			local ok = pcall(function()
				NPCSpawner.getAbsorbRate(10)
			end)
			expect(ok).to.equal(false)
		end)

		-- Pre-init guard: getSteadyStateActive raises before init().
		it("getSteadyStateActive raises before init", function()
			-- Arrange: no init

			-- Act + Assert
			local ok = pcall(function()
				NPCSpawner.getSteadyStateActive(1.0)
			end)
			expect(ok).to.equal(false)
		end)
	end)
end
