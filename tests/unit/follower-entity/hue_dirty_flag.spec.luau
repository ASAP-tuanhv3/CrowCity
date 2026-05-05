--!strict

--[[
	hue_dirty_flag.spec.luau — TestEZ unit tests for HueReconciler + HueColors
	Implements verification of: TR-follower-entity-011
	Story: production/epics/follower-entity/story-006-hue-dirty-flag.md
	GDD:   design/gdd/follower-entity.md §AC-4 + §Hue Reconciliation Timer

	NAMING DEVIATION (precedent: stories 4-1, 4-2, 4-3, 4-4, 4-5):
	  Story §Test Evidence specifies `hue_dirty_flag_test.luau`.
	  Actual filename is `hue_dirty_flag.spec.luau` because TestEZ's discovery
	  harness in `tests/runner.server.luau` matches `*.spec.luau` only.

	TEST NAMING:
	  `test_hue_<system>_<scenario>_<expected_outcome>` per coding-standards.md.

	DETERMINISM:
	  - All inputs are literal scalars (currentHue, targetHue, mismatchFrames)
	  - No `os.clock()` / `task.wait()` / `RunService` reads
	  - No mocks of CrowdStateClient — the pure module accepts targetHue directly
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HueReconciler = require(ReplicatedStorage.Source.FollowerEntity.HueReconciler)
local HueColors     = require(ReplicatedStorage.Source.SharedConstants.HueColors)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)

return function()
	-- ===========================================================================
	-- HueColors — palette lookup correctness (AC-4 secondary: Color3 type)
	-- ===========================================================================

	describe("HueColors palette (12 signature hues + neutral)", function()
		it("test_hue_palette_index_0_is_neutral_white", function()
			-- Index 0 = unassigned/NPC default
			expect(HueColors.HUE_COLORS[0]).to.equal(HueColors.NEUTRAL_WHITE)
		end)

		it("test_hue_palette_indices_1_through_12_are_color3_type", function()
			-- AC-4: Color3 (not BrickColor)
			for i = 1, 12 do
				local color = HueColors.HUE_COLORS[i]
				expect(typeof(color)).to.equal("Color3")
			end
		end)

		it("test_hue_palette_get_returns_color3_for_index_8_red", function()
			-- Art-bible §4: index 8 = Red #FF2222
			local red = HueColors.get(8)
			expect(typeof(red)).to.equal("Color3")
			expect(red.R).to.equal(255 / 255)
			-- Allow 1/255 float imprecision per Color3.fromRGB rounding
			expect(math.abs(red.G - 34 / 255) < 0.005).to.equal(true)
			expect(math.abs(red.B - 34 / 255) < 0.005).to.equal(true)
		end)

		it("test_hue_palette_get_returns_neutral_for_out_of_range_index", function()
			-- Indices >= 13 are reserved/unused → defensive fallback to neutral
			expect(HueColors.get(13)).to.equal(HueColors.NEUTRAL_WHITE)
			expect(HueColors.get(99)).to.equal(HueColors.NEUTRAL_WHITE)
			expect(HueColors.get(255)).to.equal(HueColors.NEUTRAL_WHITE)
		end)

		it("test_hue_palette_all_12_hues_are_distinct", function()
			-- Art-bible: minimum 30-degree LCH perceptual distance — implies all distinct
			local seen: { [string]: boolean } = {}
			for i = 1, 12 do
				local c = HueColors.HUE_COLORS[i]
				local key = string.format("%d_%d_%d", c.R * 255, c.G * 255, c.B * 255)
				expect(seen[key]).to.equal(nil)
				seen[key] = true
			end
		end)
	end)

	-- ===========================================================================
	-- HueReconciler.defaultDirtyFlag — the standard comparator helper
	-- ===========================================================================

	describe("HueReconciler.defaultDirtyFlag (standard comparator)", function()
		it("test_hue_dirty_flag_nil_current_returns_false", function()
			-- nil currentHue → not matched → first-frame write fires
			expect(HueReconciler.defaultDirtyFlag(nil, 8)).to.equal(false)
		end)

		it("test_hue_dirty_flag_equal_returns_true", function()
			expect(HueReconciler.defaultDirtyFlag(8, 8)).to.equal(true)
		end)

		it("test_hue_dirty_flag_different_returns_false", function()
			expect(HueReconciler.defaultDirtyFlag(5, 8)).to.equal(false)
		end)
	end)

	-- ===========================================================================
	-- HueReconciler.evaluate — fast-path mismatch (write fires immediately)
	-- ===========================================================================

	describe("HueReconciler.evaluate — fast path (mismatch detected)", function()
		it("test_hue_eval_first_frame_nil_current_writes_target", function()
			-- Initial spawn: _currentHue = nil; targetHue = 8 (Red)
			-- Comparator: nil ~= 8 → false → write fires
			local shouldWrite, newCH, newMF = HueReconciler.evaluate(
				nil, 8, 0, 4, false
			)
			expect(shouldWrite).to.equal(true)
			expect(newCH).to.equal(8)
			expect(newMF).to.equal(0)
		end)

		it("test_hue_eval_steady_state_change_writes_new_hue", function()
			-- _currentHue = 5 (Electric Blue), targetHue changes to 8 (Red)
			local shouldWrite, newCH, newMF = HueReconciler.evaluate(
				5, 8, 0, 4, false
			)
			expect(shouldWrite).to.equal(true)
			expect(newCH).to.equal(8)
			expect(newMF).to.equal(0)
		end)

		it("test_hue_eval_change_resets_mismatch_counter_even_if_nonzero", function()
			-- If counter had been incrementing (buggy state) and a real mismatch
			-- arrives, the counter resets after the write.
			local shouldWrite, newCH, newMF = HueReconciler.evaluate(
				5, 8, 3, 4, false
			)
			expect(shouldWrite).to.equal(true)
			expect(newCH).to.equal(8)
			expect(newMF).to.equal(0)
		end)
	end)

	-- ===========================================================================
	-- HueReconciler.evaluate — steady state (no write, counter stays 0)
	-- ===========================================================================

	describe("HueReconciler.evaluate — steady state (matched)", function()
		it("test_hue_eval_AC4b_steady_state_60_frames_zero_writes", function()
			-- AC-4b: 80 followers × 60 frames with unchanged hue → 0 writes
			-- Pure-module level: 60 calls all return shouldWrite=false
			local writes = 0
			local currentHue: number? = 8
			local mismatchFrames = 0
			for _ = 1, 60 do
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true
				)
				if shouldWrite then
					writes += 1
				end
				currentHue = newCH
				mismatchFrames = newMF
			end
			expect(writes).to.equal(0)
		end)

		it("test_hue_eval_steady_state_preserves_currentHue_and_zero_counter", function()
			local shouldWrite, newCH, newMF = HueReconciler.evaluate(
				8, 8, 0, 4, true
			)
			expect(shouldWrite).to.equal(false)
			expect(newCH).to.equal(8)
			expect(newMF).to.equal(0)
		end)
	end)

	-- ===========================================================================
	-- HueReconciler.evaluate — reconciliation force-write
	-- ===========================================================================

	describe("HueReconciler.evaluate — reconciliation timer (buggy state)", function()
		it("test_hue_eval_reconcile_threshold_4_force_writes_on_frame_4", function()
			-- QA scenario: comparator returns matched (true) but actual values differ
			-- for 4 frames in a row → force write on frame 4 per HUE_RECONCILE_FRAMES.
			local currentHue: number? = 5
			local mismatchFrames = 0
			local writes = 0
			local writeFrame = 0
			for frame = 1, 4 do
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true -- buggy: says matched while values differ
				)
				if shouldWrite then
					writes += 1
					writeFrame = frame
				end
				currentHue = newCH
				mismatchFrames = newMF
			end
			expect(writes).to.equal(1)
			expect(writeFrame).to.equal(4)
			expect(currentHue).to.equal(8) -- resync'd
			expect(mismatchFrames).to.equal(0) -- counter reset
		end)

		it("test_hue_eval_reconcile_no_force_at_threshold_minus_one", function()
			-- Frames 1, 2, 3 of buggy state → counter increments but no write yet
			local currentHue: number? = 5
			local mismatchFrames = 0
			for frame = 1, 3 do
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true
				)
				expect(shouldWrite).to.equal(false)
				currentHue = newCH
				mismatchFrames = newMF
				expect(mismatchFrames).to.equal(frame)
			end
		end)

		it("test_hue_eval_reconcile_resync_after_force_writes_resets_counter", function()
			-- After force-write at threshold, currentHue == targetHue. Subsequent
			-- frames in non-buggy state should stay at counter 0 with no writes.
			local currentHue: number? = 5
			local mismatchFrames = 0
			-- Drive counter to threshold + force-write
			for _ = 1, 4 do
				local _, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true
				)
				currentHue = newCH
				mismatchFrames = newMF
			end
			expect(currentHue).to.equal(8)
			expect(mismatchFrames).to.equal(0)
			-- Now non-buggy, matched state — should stay 0 writes
			for _ = 1, 10 do
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true
				)
				expect(shouldWrite).to.equal(false)
				expect(newMF).to.equal(0)
				currentHue = newCH
				mismatchFrames = newMF
			end
		end)

		it("test_hue_eval_reconcile_counter_never_overflows_past_threshold", function()
			-- Story §QA reconciliation timer edge: "never overflows past HUE_RECONCILE_FRAMES + 1"
			-- Run buggy state for 20 frames; counter should never exceed threshold-1
			-- (since reaching threshold triggers force-write + reset)
			local currentHue: number? = 5
			local mismatchFrames = 0
			local maxCounter = 0
			for _ = 1, 20 do
				local _, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, true
				)
				currentHue = newCH
				mismatchFrames = newMF
				if newMF > maxCounter then
					maxCounter = newMF
				end
				-- After force-write (frames 4, 8, 12, ... if bug persists), values
				-- get resync'd; but our test passes targetHue=8 unchanged, so after
				-- first force-write the comparator-true matches actual-equality and
				-- the counter stays at 0.
			end
			-- Counter never reaches threshold (reset before reaching it)
			expect(maxCounter < 4).to.equal(true)
		end)

		it("test_hue_eval_reconcile_uses_FollowerVisualConfig_threshold", function()
			-- Threshold parameter is passed in; verify config exposes the right value
			expect(FollowerVisualConfig.HUE_RECONCILE_FRAMES).to.equal(4)
			-- And the function honours the configured threshold
			local currentHue: number? = 5
			local mismatchFrames = 0
			local writes = 0
			for _ = 1, FollowerVisualConfig.HUE_RECONCILE_FRAMES do
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue,
					8,
					mismatchFrames,
					FollowerVisualConfig.HUE_RECONCILE_FRAMES,
					true
				)
				if shouldWrite then writes += 1 end
				currentHue = newCH
				mismatchFrames = newMF
			end
			expect(writes).to.equal(1)
		end)
	end)

	-- ===========================================================================
	-- Integration scenarios — story-level AC end-to-end
	-- ===========================================================================

	describe("Integration scenarios (AC-4 + currentHue cache + reconcile)", function()
		it("test_hue_AC4b_80_followers_60_frames_zero_writes_with_real_comparator", function()
			-- Production caller pattern: dirtyFlag = (currentHue == targetHue)
			-- After initial write, no further writes for 60 frames.
			local currentHue: number? = nil
			local mismatchFrames = 0
			local writes = 0
			for _ = 1, 60 do
				local dirty = HueReconciler.defaultDirtyFlag(currentHue, 8)
				local shouldWrite, newCH, newMF = HueReconciler.evaluate(
					currentHue, 8, mismatchFrames, 4, dirty
				)
				if shouldWrite then writes += 1 end
				currentHue = newCH
				mismatchFrames = newMF
			end
			-- Exactly 1 write across 60 frames (the initial spawn write)
			expect(writes).to.equal(1)
		end)

		it("test_hue_currentHue_cache_change_red_to_blue_one_write_then_steady", function()
			-- Story §QA `_currentHue` cache update: targetHue changes red→blue;
			-- single write fires; subsequent frames have zero writes.
			local currentHue: number? = 8 -- red
			local mismatchFrames = 0
			-- Frame 1: targetHue changes to 5 (blue)
			local dirty = HueReconciler.defaultDirtyFlag(currentHue, 5)
			local shouldWrite, newCH, newMF = HueReconciler.evaluate(
				currentHue, 5, mismatchFrames, 4, dirty
			)
			expect(shouldWrite).to.equal(true)
			expect(newCH).to.equal(5)
			currentHue = newCH
			mismatchFrames = newMF
			-- Frames 2-30: targetHue stays at 5
			local subsequentWrites = 0
			for _ = 2, 30 do
				dirty = HueReconciler.defaultDirtyFlag(currentHue, 5)
				local sw, ch, mf = HueReconciler.evaluate(
					currentHue, 5, mismatchFrames, 4, dirty
				)
				if sw then subsequentWrites += 1 end
				currentHue = ch
				mismatchFrames = mf
			end
			expect(subsequentWrites).to.equal(0)
		end)
	end)
end
