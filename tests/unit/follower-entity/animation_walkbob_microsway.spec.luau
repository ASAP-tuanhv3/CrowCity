--!strict

--[[
	animation_walkbob_microsway.spec.luau — TestEZ unit tests for Animation.luau
	Implements verification of: TR-follower-entity-005, TR-follower-entity-006, TR-follower-entity-017
	Story: production/epics/follower-entity/story-004-walk-bob-microsway.md
	GDD:   design/gdd/follower-entity.md §F8-F9 Formulas

	NAMING DEVIATION (precedent: stories 4-1, 4-2, 4-3):
	  Story §Test Evidence specifies `animation_walkbob_microsway_test.luau`.
	  Actual filename uses `.spec.luau` because TestEZ's discovery harness in
	  `tests/runner.server.luau` matches `*.spec.luau` only. Renaming to `_test.luau`
	  would silently exclude the file from the suite. Documented for /story-readiness.

	TEST NAMING:
	  Functions follow `test_animation_<system>_<scenario>_<expected_outcome>`
	  per `.claude/docs/coding-standards.md`.

	DETERMINISM:
	  - No `os.clock()` reads (passed as argument)
	  - No `math.random()` calls (phase offsets passed as literals)
	  - No `RunService` / `task.wait()`
	  - Fixed `dt = 1/60` simulated by literal d_delta values
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animation = require(ReplicatedStorage.Source.FollowerEntity.Animation)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)

-- Float tolerance for sin-based assertions. Story AC explicit ±0.001 studs.
local FLOAT_EPSILON = 0.001

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function approxEqual(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or FLOAT_EPSILON)
end

local function approxEqualCFrame(a: CFrame, b: CFrame, eps: number?): boolean
	local e = eps or FLOAT_EPSILON
	return approxEqual(a.X, b.X, e)
		and approxEqual(a.Y, b.Y, e)
		and approxEqual(a.Z, b.Z, e)
end

return function()
	describe("Animation.updateD (F8 distance accumulator + standstill flag)", function()
		it("test_animation_updateD_above_threshold_accumulates_d", function()
			local newD, isStandstill = Animation.updateD(1.0, 0.5, 0.01)
			expect(approxEqual(newD, 1.5)).to.equal(true)
			expect(isStandstill).to.equal(false)
		end)

		it("test_animation_updateD_below_threshold_freezes_d", function()
			-- AC-3: |d_delta| < THRESHOLD → d unchanged, isStandstill = true
			local startD = 1.234
			local newD, isStandstill = Animation.updateD(startD, 0.005, 0.01)
			expect(newD).to.equal(startD)
			expect(isStandstill).to.equal(true)
		end)

		it("test_animation_updateD_negative_delta_below_threshold_freezes", function()
			-- |d_delta| guards both directions (math.abs)
			local newD, isStandstill = Animation.updateD(2.0, -0.005, 0.01)
			expect(newD).to.equal(2.0)
			expect(isStandstill).to.equal(true)
		end)

		it("test_animation_updateD_exact_threshold_accumulates", function()
			-- |d_delta| < THRESHOLD is strict less-than → exact threshold accumulates
			local newD, isStandstill = Animation.updateD(0, 0.01, 0.01)
			expect(newD).to.equal(0.01)
			expect(isStandstill).to.equal(false)
		end)

		it("test_animation_updateD_three_consecutive_standstill_frames_d_unchanged", function()
			-- AC-3: 3 consecutive frames below threshold → d frozen
			local d = 1.234
			local isStill: boolean
			d, isStill = Animation.updateD(d, 0.005, 0.01)
			expect(isStill).to.equal(true)
			d, isStill = Animation.updateD(d, 0.003, 0.01)
			expect(isStill).to.equal(true)
			d, isStill = Animation.updateD(d, 0.008, 0.01)
			expect(isStill).to.equal(true)
			expect(d).to.equal(1.234)
		end)
	end)

	describe("Animation.computeWalkBobY (F8 walk-bob Y offset)", function()
		it("test_animation_walkbob_d_zero_returns_zero", function()
			-- sin(0) = 0 → y_bob = 0
			local y = Animation.computeWalkBobY(0, 1.5, 0.15)
			expect(approxEqual(y, 0)).to.equal(true)
		end)

		it("test_animation_walkbob_quarter_period_peaks_at_amp", function()
			-- d such that d * 2π * 1.5 = π/2 → sin = 1 → y = WALK_BOB_AMP
			-- d = π/2 / (2π * 1.5) = 1/6 ≈ 0.16667
			local d = 1 / 6
			local y = Animation.computeWalkBobY(d, 1.5, 0.15)
			expect(approxEqual(y, 0.15)).to.equal(true)
		end)

		it("test_animation_walkbob_half_period_returns_zero_via_abs", function()
			-- d such that d * 2π * 1.5 = π → sin = 0 → y = 0
			local d = 1 / 3
			local y = Animation.computeWalkBobY(d, 1.5, 0.15)
			expect(approxEqual(y, 0)).to.equal(true)
		end)

		it("test_animation_walkbob_three_quarter_period_abs_makes_positive", function()
			-- d such that d * 2π * 1.5 = 3π/2 → sin = -1 → abs(-1) * 0.15 = 0.15
			-- d = 3π/2 / (2π * 1.5) = 1/2
			local d = 1 / 2
			local y = Animation.computeWalkBobY(d, 1.5, 0.15)
			expect(approxEqual(y, 0.15)).to.equal(true)
		end)

		it("test_animation_walkbob_AC2_explicit_d_0p667_matches_formula", function()
			-- Story AC-2 example: d = 0.667 (after d_delta = 0.5 from d = 0.167)
			-- y = abs(sin(0.667 * 2π * 1.5)) * 0.15
			local d = 0.667
			local y = Animation.computeWalkBobY(d, 1.5, 0.15)
			local expected = math.abs(math.sin(d * 2 * math.pi * 1.5)) * 0.15
			expect(approxEqual(y, expected)).to.equal(true)
		end)

		it("test_animation_walkbob_always_non_negative", function()
			-- abs(sin(...)) is always >= 0 — AC-2 implicit invariant
			-- Sample 100 d values across multiple periods
			for i = 1, 100 do
				local d = i * 0.07
				local y = Animation.computeWalkBobY(d, 1.5, 0.15)
				expect(y >= 0).to.equal(true)
				expect(y <= 0.15 + FLOAT_EPSILON).to.equal(true)
			end
		end)
	end)

	describe("Animation.computeMicroSwayX (F9 standstill sway)", function()
		it("test_animation_microsway_LOD0_standstill_phase_zero_t_zero_returns_zero", function()
			-- sin(0 * 2π * 0.4 + 0) = 0 → x = 0
			local x = Animation.computeMicroSwayX(true, 0, 0, 0, 0.4, 0.03)
			expect(approxEqual(x, 0)).to.equal(true)
		end)

		it("test_animation_microsway_LOD0_standstill_quarter_phase_peaks_at_amp", function()
			-- t * 2π * 0.4 + π/2 = π/2 → sin = 1 → x = MICRO_SWAY_AMP
			-- t = 0, phase = π/2
			local x = Animation.computeMicroSwayX(true, 0, 0, math.pi / 2, 0.4, 0.03)
			expect(approxEqual(x, 0.03)).to.equal(true)
		end)

		it("test_animation_microsway_LOD1_standstill_returns_zero", function()
			-- AC-26 / AC-21: at LOD 1 the sway is suppressed regardless of standstill
			local x = Animation.computeMicroSwayX(true, 1, 1.0, 0, 0.4, 0.03)
			expect(x).to.equal(0)
		end)

		it("test_animation_microsway_LOD2_standstill_returns_zero", function()
			local x = Animation.computeMicroSwayX(true, 2, 1.0, 0, 0.4, 0.03)
			expect(x).to.equal(0)
		end)

		it("test_animation_microsway_LOD0_moving_returns_zero", function()
			-- AC-21: F9 only applies at standstill (movement uses F8 instead)
			local x = Animation.computeMicroSwayX(false, 0, 1.0, 0, 0.4, 0.03)
			expect(x).to.equal(0)
		end)

		it("test_animation_microsway_two_followers_different_phase_yield_different_x", function()
			-- AC-21: per-follower phase prevents lockstep
			local t = 0.5
			local x_a = Animation.computeMicroSwayX(true, 0, t, 0.7, 0.4, 0.03)
			local x_b = Animation.computeMicroSwayX(true, 0, t, 2.3, 0.4, 0.03)
			expect(x_a == x_b).to.equal(false)
		end)

		it("test_animation_microsway_AC21_explicit_formula_match", function()
			-- AC-21: x = sin(t * 2π * 0.4 + phase) * 0.03
			local t = 1.5
			local phase = 1.234
			local x = Animation.computeMicroSwayX(true, 0, t, phase, 0.4, 0.03)
			local expected = math.sin(t * 2 * math.pi * 0.4 + phase) * 0.03
			expect(approxEqual(x, expected)).to.equal(true)
		end)
	end)

	describe("Animation.composeBodyCFrame (composite CFrame at LOD 0/1/2)", function()
		local rootTarget = CFrame.new(10, 5, 20)

		it("test_animation_compose_LOD0_applies_y_bob_and_micro_sway", function()
			-- Story §Composite CFrame: Body.CFrame = Root_target * CFrame.new(sway, bob, 0)
			local result = Animation.composeBodyCFrame(rootTarget, 0.12, 0.025, 0)
			local expected = rootTarget * CFrame.new(0.025, 0.12, 0)
			expect(approxEqualCFrame(result, expected)).to.equal(true)
		end)

		it("test_animation_compose_LOD1_returns_root_target_unchanged", function()
			-- AC-26: bob/sway suppressed at LOD 1
			local result = Animation.composeBodyCFrame(rootTarget, 0.12, 0.025, 1)
			expect(approxEqualCFrame(result, rootTarget)).to.equal(true)
		end)

		it("test_animation_compose_LOD2_returns_root_target_unchanged", function()
			-- AC-26: bob/sway suppressed at LOD 2
			local result = Animation.composeBodyCFrame(rootTarget, 0.12, 0.025, 2)
			expect(approxEqualCFrame(result, rootTarget)).to.equal(true)
		end)

		it("test_animation_compose_LOD0_zero_offsets_returns_root_target", function()
			-- y_bob = 0 + sway = 0 → CFrame.new(0,0,0) is identity → result == rootTarget
			local result = Animation.composeBodyCFrame(rootTarget, 0, 0, 0)
			expect(approxEqualCFrame(result, rootTarget)).to.equal(true)
		end)
	end)

	describe("d continuity across LOD swap (AC §`d` continuity)", function()
		it("test_animation_d_continuity_LOD_swap_preserves_d", function()
			-- Story §`d` continuity: _d[i] = 5.5 at LOD 0;
			-- swaps to LOD 1 for 30 frames at d_delta=0.5/frame; back to LOD 0.
			-- Expected: _d[i] = 5.5 + 30 * 0.5 = 20.5
			local d = 5.5
			-- Simulate 30 frames at LOD 1 (d still accumulates per TR-006)
			for _ = 1, 30 do
				d = Animation.updateD(d, 0.5, 0.01)
			end
			expect(approxEqual(d, 20.5)).to.equal(true)
			-- F8 bob computed at LOD 0 re-entry uses d=20.5 (not 0)
			local y = Animation.computeWalkBobY(d, 1.5, 0.15)
			local expected = math.abs(math.sin(20.5 * 2 * math.pi * 1.5)) * 0.15
			expect(approxEqual(y, expected)).to.equal(true)
		end)

		it("test_animation_d_continuity_pure_function_does_not_reset_on_LOD_change", function()
			-- updateD has no LOD parameter — purely a math accumulator;
			-- caller (Client.luau) is responsible for LOD-suppressing the OUTPUT,
			-- not the input. This test guards against accidental refactor that
			-- adds LOD-aware reset logic to updateD.
			local d = 100.0
			d = Animation.updateD(d, 1.0, 0.01)  -- caller might be at any LOD
			expect(approxEqual(d, 101.0)).to.equal(true)
		end)
	end)

	describe("FollowerVisualConfig constants match story acceptance values", function()
		-- Story §Constants section explicit numeric values
		it("test_config_walk_freq_hz_equals_1_5", function()
			expect(FollowerVisualConfig.WALK_FREQ_HZ).to.equal(1.5)
		end)

		it("test_config_walk_bob_amp_equals_0", function()
			-- BUG-002 tune 2026-05-10: bob disabled (was 0.15). User feedback —
			-- varying heights in cluster looked broken. All followers same Y plane.
			expect(FollowerVisualConfig.WALK_BOB_AMP).to.equal(0.0)
		end)

		it("test_config_standstill_threshold_equals_0_01", function()
			expect(FollowerVisualConfig.STANDSTILL_THRESHOLD).to.equal(0.01)
		end)

		it("test_config_micro_sway_amp_equals_0_03", function()
			expect(FollowerVisualConfig.MICRO_SWAY_AMP).to.equal(0.03)
		end)

		it("test_config_micro_sway_freq_hz_equals_0_4", function()
			expect(FollowerVisualConfig.MICRO_SWAY_FREQ_HZ).to.equal(0.4)
		end)
	end)

	describe("Story scenario integration (AC-2, AC-3, AC-21, AC-26 end-to-end)", function()
		it("test_animation_AC2_scenario_d_increments_and_y_bob_matches_formula", function()
			-- AC-2: Root_target=(0,5,0), d=0.167, d_delta=0.5, LOD 0
			-- Then: _d → 0.667; y_bob = abs(sin(0.667 * 2π * 1.5)) * 0.15
			--       Body.CFrame.Y == 5 + y_bob
			local rootTarget = CFrame.new(0, 5, 0)
			local d = 0.167
			local newD = Animation.updateD(d, 0.5, 0.01)
			expect(approxEqual(newD, 0.667)).to.equal(true)
			local yBob = Animation.computeWalkBobY(newD, 1.5, 0.15)
			-- Movement → micro_sway_x = 0
			local result = Animation.composeBodyCFrame(rootTarget, yBob, 0, 0)
			expect(approxEqual(result.Y, 5 + yBob)).to.equal(true)
		end)

		it("test_animation_AC3_scenario_three_standstill_frames_y_bob_frozen", function()
			-- AC-3: lastD=1.234, lastYBob=0.12; 3 frames below threshold
			-- Then: d unchanged; Body.CFrame.Y == Root_target.Y + 0.12
			local rootTarget = CFrame.new(0, 5, 0)
			local d = 1.234
			local lastYBob = 0.12
			local isStill: boolean
			for _ = 1, 3 do
				d, isStill = Animation.updateD(d, 0.005, 0.01)
				expect(isStill).to.equal(true)
			end
			expect(d).to.equal(1.234)
			-- Caller passes lastYBob (frozen) and microSwayX = 0 (LOD 0 standstill below)
			-- For AC-3 specifically the outcome is Y == Root.Y + lastYBob
			-- isStandstill = true; LOD 0 sway also active but for this AC we test bob-only path
			local result = Animation.composeBodyCFrame(rootTarget, lastYBob, 0, 0)
			expect(approxEqual(result.Y, 5 + 0.12)).to.equal(true)
		end)

		it("test_animation_AC26_scenario_LOD1_moving_no_offset_d_still_accumulates", function()
			-- AC-26: at LOD 1 with d_delta=1.0/frame for 10 frames:
			--   Body.CFrame == Root_target exactly; _d accumulates +1.0/frame
			local rootTarget = CFrame.new(0, 5, 0)
			local d = 0
			local dDeltaPerFrame = 1.0
			for _ = 1, 10 do
				d = Animation.updateD(d, dDeltaPerFrame, 0.01)
			end
			expect(approxEqual(d, 10.0)).to.equal(true)
			-- Compose at LOD 1 — bob/sway suppressed
			local yBob = Animation.computeWalkBobY(d, 1.5, 0.15)
			local result = Animation.composeBodyCFrame(rootTarget, yBob, 0, 1)
			expect(approxEqualCFrame(result, rootTarget)).to.equal(true)
		end)

		it("test_animation_AC21_scenario_LOD0_standstill_two_followers_phase_differ", function()
			-- AC-21: 2 followers same crowd, both standstill ≥5 frames, LOD 0
			-- Body.CFrame.X = Root.X + sin(t * 2π * 0.4 + phase_i) * 0.03
			-- phase_A != phase_B  -- enforced by spawn (Story 005);
			-- here we test the math composes correctly given distinct phases.
			local rootTarget = CFrame.new(0, 5, 0)
			local t = 1.5
			local phaseA = 0.7
			local phaseB = 4.1
			local swayA = Animation.computeMicroSwayX(true, 0, t, phaseA, 0.4, 0.03)
			local swayB = Animation.computeMicroSwayX(true, 0, t, phaseB, 0.4, 0.03)
			expect(swayA == swayB).to.equal(false)
			local resultA = Animation.composeBodyCFrame(rootTarget, 0, swayA, 0)
			local resultB = Animation.composeBodyCFrame(rootTarget, 0, swayB, 0)
			expect(approxEqual(resultA.X, swayA)).to.equal(true)
			expect(approxEqual(resultB.X, swayB)).to.equal(true)
			expect(resultA.X == resultB.X).to.equal(false)
		end)
	end)
end
