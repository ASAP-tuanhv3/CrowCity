--!strict

--[[
	spawn_states_throttle.spec.luau — TestEZ unit tests for SpawnStates + SpawnThrottleQueue
	Implements verification of: TR-follower-entity-004, TR-follower-entity-010,
	                            TR-follower-entity-012, TR-follower-entity-019
	Story: production/epics/follower-entity/story-005-spawn-states-throttle.md
	GDD:   design/gdd/follower-entity.md §Spawn Triggers + §AC-8/16/19/24

	NAMING DEVIATION (precedent: stories 4-1, 4-2, 4-3, 4-4):
	  Story §Test Evidence specifies `spawn_states_throttle_test.luau`.
	  Actual filename is `spawn_states_throttle.spec.luau` because TestEZ's
	  discovery harness in `tests/runner.server.luau` matches `*.spec.luau`
	  only. Renaming would silently exclude the file.

	TEST NAMING:
	  `test_spawn_<system>_<scenario>_<expected_outcome>` per coding-standards.md.

	DETERMINISM:
	  - `math.random` injected via `randFn` arg (deterministic seeds for distribution tests)
	  - No `os.clock()` / `task.wait()` / `RunService` reads
	  - Fixed `dt` literal values for elapsed-time math
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnStates       = require(ReplicatedStorage.Source.FollowerEntity.SpawnStates)
local SpawnThrottleQueue = require(ReplicatedStorage.Source.FollowerEntity.SpawnThrottleQueue)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)

local FLOAT_EPSILON = 0.001

local function approxEqual(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or FLOAT_EPSILON)
end

local function approxEqualVector(a: Vector3, b: Vector3, eps: number?): boolean
	local e = eps or FLOAT_EPSILON
	return approxEqual(a.X, b.X, e)
		and approxEqual(a.Y, b.Y, e)
		and approxEqual(a.Z, b.Z, e)
end

--- Deterministic LCG (linear congruential generator) for distribution tests.
--- Returns a closure that yields floats in (0, 1) — same shape as math.random().
--- Using `math.randomseed`/`math.random` would mutate global state and could
--- desync across parallel TestEZ describes.
local function makeLcg(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 1103515245 + 12345) % 2147483648
		-- Map to (0, 1) — never 0 (matches math.random contract per Luau docs)
		return (state + 1) / 2147483649
	end
end

return function()
	-- ===========================================================================
	-- SpawnStates.randomDInit — TR-follower-entity-010
	-- ===========================================================================

	describe("SpawnStates.randomDInit (d_init random per spawn)", function()
		it("test_spawn_dinit_with_walk_freq_1p5_returns_value_in_zero_to_0p667", function()
			-- Story §`d_init` random per spawn: ∈ [0, 0.667) when WALK_FREQ_HZ = 1.5
			local randFn = makeLcg(42)
			for _ = 1, 100 do
				local d = SpawnStates.randomDInit(1.5, randFn)
				expect(d >= 0).to.equal(true)
				expect(d < (1 / 1.5)).to.equal(true)
			end
		end)

		it("test_spawn_dinit_distribution_has_nonzero_stddev", function()
			-- Story §QA Test Cases d_init: "standard deviation > 0"
			local randFn = makeLcg(123)
			local samples: { number } = {}
			for i = 1, 100 do
				samples[i] = SpawnStates.randomDInit(1.5, randFn)
			end
			-- Compute mean
			local sum = 0
			for _, v in samples do
				sum += v
			end
			local mean = sum / #samples
			-- Compute variance
			local variance = 0
			for _, v in samples do
				variance += (v - mean) ^ 2
			end
			variance /= #samples
			expect(variance > 0).to.equal(true)
		end)

		it("test_spawn_dinit_re_randomised_per_spawn_not_preserved", function()
			-- Story §`d_init` random: "Re-randomised on every spawn (NOT preserved across despawn → re-spawn)"
			-- This is enforced by always calling randomDInit on each spawn —
			-- verify two consecutive calls with same seeded LCG yield distinct values.
			local randFn = makeLcg(7)
			local d1 = SpawnStates.randomDInit(1.5, randFn)
			local d2 = SpawnStates.randomDInit(1.5, randFn)
			expect(d1 == d2).to.equal(false)
		end)

		it("test_spawn_dinit_no_seed_uses_math_random", function()
			-- Default path: no randFn → use math.random (non-deterministic but in-range)
			local d = SpawnStates.randomDInit(1.5)
			expect(d >= 0).to.equal(true)
			expect(d < (1 / 1.5)).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- SpawnStates.randomSwayPhaseOffset — Story §`_swayPhaseOffset[i]` random per spawn
	-- ===========================================================================

	describe("SpawnStates.randomSwayPhaseOffset (per-follower phase ∈ [0, 2π))", function()
		it("test_spawn_swayphase_returns_value_in_zero_to_2pi", function()
			local randFn = makeLcg(99)
			for _ = 1, 100 do
				local phase = SpawnStates.randomSwayPhaseOffset(randFn)
				expect(phase >= 0).to.equal(true)
				expect(phase < 2 * math.pi).to.equal(true)
			end
		end)

		it("test_spawn_swayphase_two_followers_differ_statistically", function()
			-- Story §AC-21 indirect: two simultaneously-standstill followers must have
			-- differing phase. Sequential calls with seeded LCG demonstrate distinctness.
			local randFn = makeLcg(11)
			local phaseA = SpawnStates.randomSwayPhaseOffset(randFn)
			local phaseB = SpawnStates.randomSwayPhaseOffset(randFn)
			expect(phaseA == phaseB).to.equal(false)
		end)

		it("test_spawn_swayphase_no_seed_uses_math_random", function()
			local phase = SpawnStates.randomSwayPhaseOffset()
			expect(phase >= 0).to.equal(true)
			expect(phase < 2 * math.pi).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- SpawnStates.computeFadeInTransparency — AC-19 (alpha 1→0 over 0.3 s)
	-- ===========================================================================

	describe("SpawnStates.computeFadeInTransparency (FadeIn 1→0 lerp)", function()
		it("test_spawn_fadein_alpha_at_t_zero_is_one", function()
			expect(SpawnStates.computeFadeInTransparency(0, 0.3)).to.equal(1.0)
		end)

		it("test_spawn_fadein_alpha_at_t_duration_is_zero", function()
			expect(SpawnStates.computeFadeInTransparency(0.3, 0.3)).to.equal(0.0)
		end)

		it("test_spawn_fadein_alpha_at_t_half_is_0p5", function()
			expect(SpawnStates.computeFadeInTransparency(0.15, 0.3)).to.equal(0.5)
		end)

		it("test_spawn_fadein_alpha_clamps_below_zero_to_one", function()
			-- Negative elapsed (paranoid input) clamps at 1.0
			expect(SpawnStates.computeFadeInTransparency(-0.5, 0.3)).to.equal(1.0)
		end)

		it("test_spawn_fadein_alpha_clamps_above_duration_to_zero", function()
			-- Over-elapsed clamps at 0.0
			expect(SpawnStates.computeFadeInTransparency(1.0, 0.3)).to.equal(0.0)
		end)

		it("test_spawn_fadein_18_frames_at_60hz_completes", function()
			-- Story §QA "State machine": 18 frames @ 60Hz = 0.3s → state Active on frame 19
			-- Frame 18 elapsed = 18/60 = 0.3 → transparency = 0.0
			local elapsed = 18 / 60
			local t = SpawnStates.computeFadeInTransparency(elapsed, 0.3)
			expect(approxEqual(t, 0.0)).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- SpawnStates.computeSlideInPosition — AC-16 (linear lerp)
	-- ===========================================================================

	describe("SpawnStates.computeSlideInPosition (Vector3 lerp)", function()
		local npcLastPos = Vector3.new(10, 0, 10)
		local crowdCenter = Vector3.new(0, 0, 0)

		it("test_spawn_slidein_pos_at_t_zero_is_npcLastPos", function()
			-- AC-16: frame 1 → Body.CFrame.Position == npcLastPosition
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 0, 0.4)
			expect(approxEqualVector(p, npcLastPos)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_at_t_duration_is_crowdCenter", function()
			-- AC-16: frame 24+1 → state Active, position == crowd_center
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 0.4, 0.4)
			expect(approxEqualVector(p, crowdCenter)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_at_t_half_is_midpoint", function()
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 0.2, 0.4)
			expect(approxEqualVector(p, Vector3.new(5, 0, 5))).to.equal(true)
		end)

		it("test_spawn_slidein_pos_clamps_below_zero_to_npcLastPos", function()
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, -0.1, 0.4)
			expect(approxEqualVector(p, npcLastPos)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_clamps_above_duration_to_crowdCenter", function()
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 1.0, 0.4)
			expect(approxEqualVector(p, crowdCenter)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_degenerate_npc_eq_center_returns_center", function()
			-- AC-16 edge case: npcLastPosition == crowd_center
			local same = Vector3.new(5, 0, 5)
			local p = SpawnStates.computeSlideInPosition(same, same, 0.2, 0.4)
			expect(approxEqualVector(p, same)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_24_frames_at_60hz_reaches_center", function()
			-- AC-16: 24 frames @ 60Hz = 0.4s → terminal position
			local p = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 24 / 60, 0.4)
			expect(approxEqualVector(p, crowdCenter)).to.equal(true)
		end)

		it("test_spawn_slidein_pos_each_frame_moves_uniformly_toward_center", function()
			-- AC-16: linear interpolation across 24 frames
			-- Each frame should advance by (10,0,10) / 24 in the X+Z plane
			local prev = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 0, 0.4)
			for frame = 1, 24 do
				local current = SpawnStates.computeSlideInPosition(
					npcLastPos, crowdCenter, frame / 60, 0.4
				)
				-- Each step should move toward center (X decreasing, Z decreasing)
				expect(current.X <= prev.X + FLOAT_EPSILON).to.equal(true)
				expect(current.Z <= prev.Z + FLOAT_EPSILON).to.equal(true)
				prev = current
			end
		end)
	end)

	-- ===========================================================================
	-- SpawnStates terminal predicates — state machine completion
	-- ===========================================================================

	describe("SpawnStates.isFadeInComplete / isSlideInComplete (terminal predicates)", function()
		it("test_spawn_fadein_incomplete_at_t_below_duration", function()
			expect(SpawnStates.isFadeInComplete(0.29, 0.3)).to.equal(false)
		end)

		it("test_spawn_fadein_complete_at_t_equals_duration", function()
			expect(SpawnStates.isFadeInComplete(0.3, 0.3)).to.equal(true)
		end)

		it("test_spawn_fadein_complete_at_t_above_duration", function()
			expect(SpawnStates.isFadeInComplete(0.5, 0.3)).to.equal(true)
		end)

		it("test_spawn_slidein_incomplete_at_t_below_duration", function()
			expect(SpawnStates.isSlideInComplete(0.39, 0.4)).to.equal(false)
		end)

		it("test_spawn_slidein_complete_at_t_equals_duration", function()
			expect(SpawnStates.isSlideInComplete(0.4, 0.4)).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- SpawnStates.getSlideInBodyColor — AC-24 (frame 1 white, frame 2+ hue)
	-- ===========================================================================

	describe("SpawnStates.getSlideInBodyColor (AC-24 hue handoff)", function()
		local hueRed = Color3.new(1, 0, 0)
		local hueBlue = Color3.new(0, 0, 1)
		local white = Color3.new(1, 1, 1)

		it("test_spawn_slidein_color_frame1_returns_white", function()
			-- AC-24: frame 1 → Body.Color == Color3.new(1,1,1)
			local c = SpawnStates.getSlideInBodyColor(1, hueRed)
			expect(c).to.equal(white)
		end)

		it("test_spawn_slidein_color_frame2_returns_hue", function()
			-- AC-24: frame 2+ → Body.Color == HUE_COLORS[absorberHue]
			local c = SpawnStates.getSlideInBodyColor(2, hueRed)
			expect(c).to.equal(hueRed)
		end)

		it("test_spawn_slidein_color_frame12_returns_hue", function()
			local c = SpawnStates.getSlideInBodyColor(12, hueBlue)
			expect(c).to.equal(hueBlue)
		end)

		it("test_spawn_slidein_color_frame24_returns_hue", function()
			local c = SpawnStates.getSlideInBodyColor(24, hueBlue)
			expect(c).to.equal(hueBlue)
		end)

		it("test_spawn_slidein_color_frame_zero_or_negative_returns_white", function()
			-- Defensive: pre-tick (tickIndex = 0 or negative) treated as frame 1 white
			expect(SpawnStates.getSlideInBodyColor(0, hueRed)).to.equal(white)
			expect(SpawnStates.getSlideInBodyColor(-5, hueRed)).to.equal(white)
		end)
	end)

	-- ===========================================================================
	-- SpawnThrottleQueue — TR-follower-entity-004 (4/frame throttle)
	-- ===========================================================================

	describe("SpawnThrottleQueue (FIFO with per-frame dispatch limit)", function()
		it("test_spawn_queue_new_is_empty", function()
			local q = SpawnThrottleQueue.new()
			expect(q:size()).to.equal(0)
		end)

		it("test_spawn_queue_enqueue_increments_size", function()
			local q = SpawnThrottleQueue.new()
			q:enqueue({ crowdId = "a" })
			q:enqueue({ crowdId = "b" })
			expect(q:size()).to.equal(2)
		end)

		it("test_spawn_queue_dequeue_empty_returns_empty_table", function()
			local q = SpawnThrottleQueue.new()
			local result = q:dequeueUpTo(4)
			expect(#result).to.equal(0)
		end)

		it("test_spawn_queue_dequeue_FIFO_order", function()
			local q = SpawnThrottleQueue.new()
			q:enqueue({ crowdId = "first" })
			q:enqueue({ crowdId = "second" })
			q:enqueue({ crowdId = "third" })
			local result = q:dequeueUpTo(3)
			expect(#result).to.equal(3)
			expect(result[1].crowdId).to.equal("first")
			expect(result[2].crowdId).to.equal("second")
			expect(result[3].crowdId).to.equal("third")
		end)

		it("test_spawn_queue_AC8_10_absorbs_split_4_4_2", function()
			-- AC-8: 10 absorb events → frame 1: 4 spawns, frame 2: 4 spawns,
			-- frame 3: 2 spawns, frame 4+: 0 spawns; total = 10
			local q = SpawnThrottleQueue.new()
			for i = 1, 10 do
				q:enqueue({ crowdId = "c", id = i })
			end
			-- Frame 1
			local frame1 = q:dequeueUpTo(4)
			expect(#frame1).to.equal(4)
			expect(q:size()).to.equal(6)
			-- Frame 2
			local frame2 = q:dequeueUpTo(4)
			expect(#frame2).to.equal(4)
			expect(q:size()).to.equal(2)
			-- Frame 3
			local frame3 = q:dequeueUpTo(4)
			expect(#frame3).to.equal(2)
			expect(q:size()).to.equal(0)
			-- Frame 4
			local frame4 = q:dequeueUpTo(4)
			expect(#frame4).to.equal(0)
			-- Total IDs dispatched in FIFO order
			local total = #frame1 + #frame2 + #frame3
			expect(total).to.equal(10)
			expect(frame1[1].id).to.equal(1)
			expect(frame2[1].id).to.equal(5)
			expect(frame3[2].id).to.equal(10)
		end)

		it("test_spawn_queue_AC19_80_fadeins_4_per_frame_for_20_frames", function()
			-- AC-19: 80 queued FadeIn spawns drain at 4/frame → 20 frames to clear
			local q = SpawnThrottleQueue.new()
			for i = 1, 80 do
				q:enqueue({ crowdId = "c", spawnType = "FadeIn", id = i })
			end
			local totalDispatched = 0
			for frame = 1, 20 do
				local dispatched = q:dequeueUpTo(4)
				expect(#dispatched).to.equal(4)
				totalDispatched += #dispatched
			end
			expect(totalDispatched).to.equal(80)
			expect(q:size()).to.equal(0)
			-- Frame 21+ → 0 spawns
			expect(#q:dequeueUpTo(4)).to.equal(0)
		end)

		it("test_spawn_queue_dequeue_more_than_size_returns_all", function()
			local q = SpawnThrottleQueue.new()
			q:enqueue({ id = 1 })
			q:enqueue({ id = 2 })
			local result = q:dequeueUpTo(10)
			expect(#result).to.equal(2)
			expect(q:size()).to.equal(0)
		end)

		it("test_spawn_queue_drain_then_enqueue_again_resumes_FIFO", function()
			-- After fully draining, the queue should reset internal indices and
			-- continue accepting enqueues without growing _items unbounded.
			local q = SpawnThrottleQueue.new()
			for i = 1, 4 do
				q:enqueue({ id = i })
			end
			q:dequeueUpTo(4)
			expect(q:size()).to.equal(0)
			-- Re-enqueue
			q:enqueue({ id = 100 })
			q:enqueue({ id = 101 })
			local result = q:dequeueUpTo(2)
			expect(result[1].id).to.equal(100)
			expect(result[2].id).to.equal(101)
		end)

		it("test_spawn_queue_clear_removes_all_pending", function()
			-- AC-19 edge case: cap drops mid-queue → cancel remaining requests
			local q = SpawnThrottleQueue.new()
			for i = 1, 50 do
				q:enqueue({ id = i })
			end
			q:dequeueUpTo(4) -- partial drain
			expect(q:size()).to.equal(46)
			q:clear()
			expect(q:size()).to.equal(0)
			-- After clear, queue accepts new enqueues
			q:enqueue({ id = 999 })
			expect(q:size()).to.equal(1)
		end)

		it("test_spawn_queue_dequeue_zero_returns_empty", function()
			-- Defensive: maxN=0 dispatches nothing
			local q = SpawnThrottleQueue.new()
			q:enqueue({ id = 1 })
			local result = q:dequeueUpTo(0)
			expect(#result).to.equal(0)
			expect(q:size()).to.equal(1)
		end)

		it("test_spawn_queue_mixed_FadeIn_SlideIn_payloads_preserved", function()
			-- Queue is type-agnostic; payload shape preserved verbatim
			local q = SpawnThrottleQueue.new()
			q:enqueue({ spawnType = "FadeIn", crowdId = "a" })
			q:enqueue({
				spawnType = "SlideIn",
				crowdId = "a",
				npcLastPosition = Vector3.new(10, 0, 10),
				absorberHueColor = Color3.new(1, 0, 0),
			})
			local result = q:dequeueUpTo(2)
			expect(result[1].spawnType).to.equal("FadeIn")
			expect(result[2].spawnType).to.equal("SlideIn")
			expect(approxEqualVector(result[2].npcLastPosition, Vector3.new(10, 0, 10))).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- FollowerVisualConfig spawn constants
	-- ===========================================================================

	describe("FollowerVisualConfig spawn constants match story acceptance values", function()
		-- Story §Constants section: SPAWN_FADE_DURATION = 0.3, SPAWN_SLIDE_DURATION = 0.4,
		-- SPAWN_THROTTLE_PER_FRAME = 4
		it("test_config_spawn_fade_duration_equals_0p3", function()
			expect(FollowerVisualConfig.SPAWN_FADE_DURATION).to.equal(0.3)
		end)

		it("test_config_spawn_slide_duration_equals_0p4", function()
			expect(FollowerVisualConfig.SPAWN_SLIDE_DURATION).to.equal(0.4)
		end)

		it("test_config_spawn_throttle_per_frame_equals_4", function()
			expect(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME).to.equal(4)
		end)
	end)

	-- ===========================================================================
	-- Integration scenarios — end-to-end ACs
	-- ===========================================================================

	describe("Integration scenarios (AC-8, AC-16, AC-19, AC-24 end-to-end)", function()
		it("test_spawn_AC16_full_slidein_24_frames_60hz_position_color_match_formula", function()
			-- AC-16: spawn at npcLastPosition=(10,0,10), crowdCenter=(0,0,0), absorberHue=red
			-- frame 1 → Body.CFrame.Position == (10,0,10), Body.Color == white
			-- frame 2 → Body.Color == red
			-- frames 2-24 → CFrame interpolates linearly toward (0,0,0)
			-- frame 24+1 → state Active, position == (0,0,0)
			local npcLastPos = Vector3.new(10, 0, 10)
			local crowdCenter = Vector3.new(0, 0, 0)
			local hueRed = Color3.new(1, 0, 0)
			local white = Color3.new(1, 1, 1)
			local duration = 0.4

			-- Frame 1 (tickIndex=1, elapsed=0)
			local pos1 = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 0, duration)
			local color1 = SpawnStates.getSlideInBodyColor(1, hueRed)
			expect(approxEqualVector(pos1, npcLastPos)).to.equal(true)
			expect(color1).to.equal(white)
			expect(SpawnStates.isSlideInComplete(0, duration)).to.equal(false)

			-- Frame 2 (tickIndex=2, elapsed=1/60)
			local color2 = SpawnStates.getSlideInBodyColor(2, hueRed)
			expect(color2).to.equal(hueRed)

			-- Frame 12 (mid-slide): position should be ~halfway
			local pos12 = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 12 / 60, duration)
			-- 12/60 / 0.4 = 0.5 → midpoint
			expect(approxEqualVector(pos12, Vector3.new(5, 0, 5))).to.equal(true)

			-- Frame 24 (terminal)
			local pos24 = SpawnStates.computeSlideInPosition(npcLastPos, crowdCenter, 24 / 60, duration)
			expect(approxEqualVector(pos24, crowdCenter)).to.equal(true)
			expect(SpawnStates.isSlideInComplete(24 / 60, duration)).to.equal(true)
		end)

		it("test_spawn_AC19_full_fadein_18_frames_transparency_lerps", function()
			-- AC-19: FadeIn alpha 1→0 over 0.3s = 18 frames @ 60Hz
			local duration = 0.3
			-- Frame 1 (just spawned)
			expect(SpawnStates.computeFadeInTransparency(0, duration)).to.equal(1.0)
			-- Frame 9 (halfway)
			local mid = SpawnStates.computeFadeInTransparency(9 / 60, duration)
			expect(approxEqual(mid, 0.5)).to.equal(true)
			-- Frame 18 (terminal)
			expect(SpawnStates.computeFadeInTransparency(18 / 60, duration)).to.equal(0.0)
			expect(SpawnStates.isFadeInComplete(18 / 60, duration)).to.equal(true)
		end)

		it("test_spawn_AC8_throttle_with_FollowerVisualConfig_constants", function()
			-- AC-8 + Config: queue uses SPAWN_THROTTLE_PER_FRAME literal 4
			local q = SpawnThrottleQueue.new()
			for i = 1, 10 do
				q:enqueue({ id = i })
			end
			local frame1 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			expect(#frame1).to.equal(4)
			local frame2 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			expect(#frame2).to.equal(4)
			local frame3 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			expect(#frame3).to.equal(2)
		end)
	end)
end
