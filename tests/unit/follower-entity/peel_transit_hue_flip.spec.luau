--!strict

--[[
	peel_transit_hue_flip.spec.luau — TestEZ unit tests for PeelTransit.luau
	Implements verification of: TR-follower-entity-007, TR-follower-entity-014,
	                            TR-follower-entity-018
	Story: production/epics/follower-entity/story-008-peel-transit-hue-flip.md
	GDD:   design/gdd/follower-entity.md §F7 + §AC-5/12/22

	NAMING DEVIATION (precedent: stories 4-1..4-7):
	  Story §Test Evidence specifies `peel_transit_hue_flip_test.luau`.
	  Actual filename uses `.spec.luau` (TestEZ runner convention).

	TEST NAMING:
	  `test_peel_<scenario>_<expected_outcome>` per coding-standards.md.

	DETERMINISM:
	  - elapsed values are passed as literal scalars (no os.clock reads)
	  - Latch state passed as literal boolean
	  - No mocks of CrowdStateClient — the pure module accepts position params
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PeelTransit = require(ReplicatedStorage.Source.FollowerEntity.PeelTransit)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)

local PEEL_SPEED = FollowerVisualConfig.PEEL_SPEED
local PEEL_MAX_DURATION = FollowerVisualConfig.PEEL_MAX_DURATION

local FLOAT_EPSILON = 0.001

local function approxEqual(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or FLOAT_EPSILON)
end

local function approxEqualVector(a: Vector3, b: Vector3): boolean
	return approxEqual(a.X, b.X)
		and approxEqual(a.Y, b.Y)
		and approxEqual(a.Z, b.Z)
end

return function()
	-- ===========================================================================
	-- AC-12a: T_peel uncapped formula
	-- ===========================================================================

	describe("PeelTransit.computeTransitParams — F7 timing math", function()
		it("test_peel_AC12a_d40_speed20_T_peel_2s_T_hue_1s", function()
			-- Given d_peel=40, PEEL_SPEED=20, PEEL_MAX_DURATION=3.0
			-- Then T_peel = min(40/20, 3.0) = 2.0; T_hue_flip = 1.0
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(40, 0, 0),
				20,
				3.0
			)
			expect(approxEqual(params.dPeel, 40)).to.equal(true)
			expect(approxEqual(params.tPeel, 2.0)).to.equal(true)
			expect(approxEqual(params.tHueFlip, 1.0)).to.equal(true)
			expect(params.isCapped).to.equal(false)
		end)

		it("test_peel_AC12b_d120_speed20_max3_T_peel_capped_at_3s", function()
			-- d_peel=120, PEEL_SPEED=20, PEEL_MAX_DURATION=3.0
			-- Uncapped T = 6.0; capped at 3.0; T_hue_flip = 1.5; isCapped = true
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(120, 0, 0),
				20,
				3.0
			)
			expect(approxEqual(params.dPeel, 120)).to.equal(true)
			expect(approxEqual(params.tPeel, 3.0)).to.equal(true)
			expect(approxEqual(params.tHueFlip, 1.5)).to.equal(true)
			expect(params.isCapped).to.equal(true)
		end)

		it("test_peel_AC12b_boundary_exactly_at_max_distance", function()
			-- d_peel = PEEL_SPEED * PEEL_MAX_DURATION = 60 → uncapped T = 3.0; not capped
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(60, 0, 0),
				20,
				3.0
			)
			expect(approxEqual(params.tPeel, 3.0)).to.equal(true)
			expect(params.isCapped).to.equal(false) -- ratio 3.0 == 3.0, not strictly greater
		end)

		it("test_peel_AC12_dpeel_zero_instant_arrival", function()
			-- d_peel = 0 → T_peel = 0; T_hue_flip = 0; isArrived returns true on frame 1
			local params = PeelTransit.computeTransitParams(
				Vector3.new(5, 0, 5),
				Vector3.new(5, 0, 5),
				20,
				3.0
			)
			expect(params.dPeel).to.equal(0)
			expect(params.tPeel).to.equal(0)
			expect(params.tHueFlip).to.equal(0)
			expect(params.isCapped).to.equal(false)
			-- Arrival predicate at elapsed=0 with tPeel=0 → true (instant)
			expect(PeelTransit.isArrived(0, params.tPeel)).to.equal(true)
			-- Hue-flip predicate at elapsed=0 with tHueFlip=0, latch false → true
			expect(PeelTransit.shouldFlipHue(0, params.tHueFlip, false)).to.equal(true)
		end)

		it("test_peel_AC12_3D_distance_uses_full_magnitude", function()
			-- Y component contributes to distance — guard against X-only computation
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(0, 30, 40),  -- magnitude = 50
				20,
				3.0
			)
			expect(approxEqual(params.dPeel, 50)).to.equal(true)
			expect(approxEqual(params.tPeel, 2.5)).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- AC-5 + TR-007: hue flip threshold-crossing with latch (no float equality)
	-- ===========================================================================

	describe("PeelTransit.shouldFlipHue — AC-5 latch + threshold crossing", function()
		it("test_peel_hueflip_below_threshold_returns_false", function()
			expect(PeelTransit.shouldFlipHue(0.5, 1.0, false)).to.equal(false)
		end)

		it("test_peel_hueflip_at_exact_threshold_returns_true", function()
			-- TR-007: >= threshold-crossing (exact equal triggers)
			expect(PeelTransit.shouldFlipHue(1.0, 1.0, false)).to.equal(true)
		end)

		it("test_peel_hueflip_above_threshold_returns_true_first_call", function()
			expect(PeelTransit.shouldFlipHue(1.5, 1.0, false)).to.equal(true)
		end)

		it("test_peel_hueflip_latch_blocks_second_call_after_applied", function()
			-- AC-5b: _hueFlipApplied true → no second flip fires before arrival
			expect(PeelTransit.shouldFlipHue(2.0, 1.0, true)).to.equal(false)
		end)

		it("test_peel_hueflip_TR007_60hz_simulation_fires_exactly_once", function()
			-- Simulate 120 frames @ 60 Hz from peelStart with T_hue_flip = 1.0
			-- Verify flip fires exactly once across all frames
			local flipCount = 0
			local latch = false
			for frame = 1, 120 do
				local elapsed = frame / 60
				if PeelTransit.shouldFlipHue(elapsed, 1.0, latch) then
					flipCount += 1
					latch = true
				end
			end
			expect(flipCount).to.equal(1)
		end)

		it("test_peel_hueflip_frame_straddling_threshold_one_frame_trigger", function()
			-- Frame at elapsed = 60/60 = 1.0 (exact). Frame 59 at 0.9833. Frame 60 at 1.0.
			-- >= ensures flip fires on frame 60 (one-frame trigger).
			local frame59 = PeelTransit.shouldFlipHue(59 / 60, 1.0, false)
			local frame60 = PeelTransit.shouldFlipHue(60 / 60, 1.0, false)
			expect(frame59).to.equal(false)
			expect(frame60).to.equal(true)
		end)

		it("test_peel_hueflip_clock_jump_backward_latch_persists", function()
			-- QA edge: simulated os.clock jump backward — latch already true
			-- prevents a spurious second flip
			expect(PeelTransit.shouldFlipHue(0.0, 1.0, true)).to.equal(false)
		end)
	end)

	-- ===========================================================================
	-- isArrived — terminal predicate
	-- ===========================================================================

	describe("PeelTransit.isArrived — terminal predicate", function()
		it("test_peel_isArrived_below_T_returns_false", function()
			expect(PeelTransit.isArrived(1.99, 2.0)).to.equal(false)
		end)

		it("test_peel_isArrived_at_exact_T_returns_true", function()
			expect(PeelTransit.isArrived(2.0, 2.0)).to.equal(true)
		end)

		it("test_peel_isArrived_above_T_returns_true", function()
			expect(PeelTransit.isArrived(2.5, 2.0)).to.equal(true)
		end)

		it("test_peel_isArrived_120_frame_simulation_at_2s_arrives_on_frame_120", function()
			local arrivedFrame = 0
			for frame = 1, 200 do
				local elapsed = frame / 60
				if arrivedFrame == 0 and PeelTransit.isArrived(elapsed, 2.0) then
					arrivedFrame = frame
				end
			end
			-- Frame 120 is exactly elapsed = 2.0
			expect(arrivedFrame).to.equal(120)
		end)
	end)

	-- ===========================================================================
	-- AC-22: rival nil abort path
	-- ===========================================================================

	describe("PeelTransit.computeFLeadTarget — AC-22 rival nil abort", function()
		local cached = Vector3.new(50, 0, 0)
		local ownCenter = Vector3.new(0, 0, 0)

		it("test_peel_fLead_normal_returns_rivalRecord_position", function()
			local target, aborted = PeelTransit.computeFLeadTarget(
				Vector3.new(60, 0, 0), cached, ownCenter
			)
			expect(approxEqualVector(target, Vector3.new(60, 0, 0))).to.equal(true)
			expect(aborted).to.equal(false)
		end)

		it("test_peel_fLead_rival_nil_returns_own_center_aborted_true", function()
			-- AC-22: rival nil → switch boids target back to own crowd
			local target, aborted = PeelTransit.computeFLeadTarget(
				nil, cached, ownCenter
			)
			expect(approxEqualVector(target, ownCenter)).to.equal(true)
			expect(aborted).to.equal(true)
		end)
	end)

	describe("PeelTransit.resolveAbortArrivalState — AC-22 terminal state", function()
		it("test_peel_arrival_no_abort_returns_nil", function()
			-- Normal transit completes → caller uses standard Despawning + rival-side FadeIn path
			expect(PeelTransit.resolveAbortArrivalState(false, false)).to.equal(nil)
		end)

		it("test_peel_arrival_aborted_own_crowd_present_returns_Active", function()
			-- AC-22: rival nil mid-peel → on arrival at own center, state → Active (NOT Despawning)
			expect(PeelTransit.resolveAbortArrivalState(true, false)).to.equal("Active")
		end)

		it("test_peel_arrival_aborted_own_crowd_also_nil_returns_Despawning", function()
			-- Edge case from Story §Implementation Notes: own crowd ALSO nil at abort time
			-- → state → Despawning (Story 002 nil-check path)
			expect(PeelTransit.resolveAbortArrivalState(true, true)).to.equal("Despawning")
		end)
	end)

	-- ===========================================================================
	-- FollowerVisualConfig peel constants
	-- ===========================================================================

	describe("FollowerVisualConfig peel constants match story values", function()
		it("test_config_peel_speed_equals_20", function()
			expect(FollowerVisualConfig.PEEL_SPEED).to.equal(20)
		end)

		it("test_config_peel_max_duration_equals_3", function()
			expect(FollowerVisualConfig.PEEL_MAX_DURATION).to.equal(3.0)
		end)
	end)

	-- ===========================================================================
	-- Integration scenarios — story-level AC end-to-end with config values
	-- ===========================================================================

	describe("Integration scenarios (AC-5 + AC-12 with FollowerVisualConfig)", function()
		it("test_peel_AC5_full_transit_simulation_hue_flip_at_60_arrival_at_120", function()
			-- AC-5: follower at (0,0,0), rival_center=(40,0,0), startPeel
			-- Mock advances elapsed by 1/60 per frame for 2.0s
			-- Frame 60 (elapsed=1.0, T_hue_flip=1.0): flip fires
			-- Frame 120 (elapsed=2.0, T_peel=2.0): arrival
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(40, 0, 0),
				PEEL_SPEED,
				PEEL_MAX_DURATION
			)

			local flipFrame = 0
			local arrivalFrame = 0
			local flipCount = 0
			local latch = false

			for frame = 1, 200 do
				local elapsed = frame / 60
				if PeelTransit.shouldFlipHue(elapsed, params.tHueFlip, latch) then
					flipFrame = frame
					flipCount += 1
					latch = true
				end
				if arrivalFrame == 0 and PeelTransit.isArrived(elapsed, params.tPeel) then
					arrivalFrame = frame
				end
			end

			expect(flipCount).to.equal(1)
			expect(flipFrame).to.equal(60)
			expect(arrivalFrame).to.equal(120)
		end)

		it("test_peel_AC12b_long_distance_transit_capped_at_180_frames", function()
			-- d_peel=120, PEEL_SPEED=20 → uncapped 6s, capped at 3s = 180 frames
			local params = PeelTransit.computeTransitParams(
				Vector3.new(0, 0, 0),
				Vector3.new(120, 0, 0),
				PEEL_SPEED,
				PEEL_MAX_DURATION
			)
			expect(params.isCapped).to.equal(true)

			local arrivalFrame = 0
			for frame = 1, 400 do
				local elapsed = frame / 60
				if arrivalFrame == 0 and PeelTransit.isArrived(elapsed, params.tPeel) then
					arrivalFrame = frame
					break
				end
			end
			-- Frame 180 = elapsed 3.0
			expect(arrivalFrame).to.equal(180)
		end)
	end)
end
