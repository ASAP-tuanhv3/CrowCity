--!strict

--[[
	peel_selection_f6.spec.luau — TestEZ unit tests for PeelSelection.luau
	Implements verification of: TR-follower-entity-013
	Story: production/epics/follower-entity/story-007-peel-selection-f6.md
	GDD:   design/gdd/follower-entity.md §F6 + §AC-11 + §AC-23

	NAMING DEVIATION (precedent: stories 4-1, 4-2, 4-3, 4-4, 4-5, 4-6):
	  Story §Test Evidence specifies `peel_selection_f6_test.luau`.
	  Actual filename uses `.spec.luau` (TestEZ runner convention).

	TEST NAMING:
	  `test_peel_<system>_<scenario>_<expected_outcome>` per coding-standards.md.

	DETERMINISM:
	  - Fixed Vector3 positions (no random)
	  - States passed as literal arrays
	  - No `os.clock()` / `task.wait()` reads
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PeelSelection = require(ReplicatedStorage.Source.FollowerEntity.PeelSelection)

local STATE_ACTIVE  = "Active"
local STATE_PEELING = "Peeling"
local STATE_SPAWNING = "Spawning:FadeIn"

return function()
	-- ===========================================================================
	-- AC-11a — F6 selects closest-to-rival, NOT farthest-from-own-center
	-- ===========================================================================

	describe("PeelSelection.selectClosestToRival — AC-11a (closest to rival)", function()
		it("test_peel_AC11a_basic_4_followers_2_closest_to_rival_selected", function()
			-- AC-11a: positions (40,0,0)→dist 10, (38,0,0)→dist 12, (10,0,0)→dist 40, (5,0,0)→dist 45
			-- rival_center = (50,0,0); N=2 → indices 1, 2 (distances 10 and 12)
			local positions = {
				Vector3.new(40, 0, 0),
				Vector3.new(38, 0, 0),
				Vector3.new(10, 0, 0),
				Vector3.new(5, 0, 0),
			}
			local states = { STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE }
			local rivalCenter = Vector3.new(50, 0, 0)

			local selected = PeelSelection.selectClosestToRival(
				positions, states, rivalCenter, 2, STATE_ACTIVE
			)
			expect(#selected).to.equal(2)
			-- Closest first (ascending distance): index 1 (dist 10), then index 2 (dist 12)
			expect(selected[1]).to.equal(1)
			expect(selected[2]).to.equal(2)
		end)

		it("test_peel_AC11a_3D_distance_uses_full_magnitude_not_x_only", function()
			-- Verify Y and Z components contribute to distance — guard against
			-- accidental X-only sort.
			local positions = {
				Vector3.new(50, 100, 0),  -- dist from (50,0,0) = 100
				Vector3.new(60, 0, 0),    -- dist = 10
			}
			local states = { STATE_ACTIVE, STATE_ACTIVE }
			local rivalCenter = Vector3.new(50, 0, 0)

			local selected = PeelSelection.selectClosestToRival(
				positions, states, rivalCenter, 1, STATE_ACTIVE
			)
			expect(selected[1]).to.equal(2)
		end)
	end)

	-- ===========================================================================
	-- AC-11b / AC-23 — concurrent peel exclusion (already-Peeling skipped)
	-- ===========================================================================

	describe("PeelSelection — concurrent peel exclusion", function()
		it("test_peel_AC11b_already_peeling_followers_excluded", function()
			-- After first call mutates states[1]=Peeling, states[2]=Peeling,
			-- second call sees only indices 3, 4 as candidates.
			local positions = {
				Vector3.new(40, 0, 0),
				Vector3.new(38, 0, 0),
				Vector3.new(10, 0, 0),
				Vector3.new(5, 0, 0),
			}
			-- Simulating post-first-call state
			local states = { STATE_PEELING, STATE_PEELING, STATE_ACTIVE, STATE_ACTIVE }
			local rivalCenter = Vector3.new(50, 0, 0)

			local selected = PeelSelection.selectClosestToRival(
				positions, states, rivalCenter, 2, STATE_ACTIVE
			)
			expect(#selected).to.equal(2)
			-- Now closest available are index 3 (dist 40) and index 4 (dist 45)
			expect(selected[1]).to.equal(3)
			expect(selected[2]).to.equal(4)
		end)

		it("test_peel_AC23_dual_rival_independent_sorts_no_overlap", function()
			-- AC-23: 80 Active at varied positions; rival B = (+100,0,0), rival C = (-100,0,0)
			-- B picks 2 highest-X; C picks 2 lowest-X (excluding B's).
			-- Use 6 followers spaced along X axis for clarity.
			local positions = {
				Vector3.new(-50, 0, 0),  -- closest to C
				Vector3.new(-40, 0, 0),  -- 2nd closest to C
				Vector3.new(-10, 0, 0),
				Vector3.new(10, 0, 0),
				Vector3.new(40, 0, 0),   -- 2nd closest to B
				Vector3.new(50, 0, 0),   -- closest to B
			}
			local states = {
				STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE,
				STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE,
			}

			-- Rival B call first
			local selectedB = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(100, 0, 0), 2, STATE_ACTIVE
			)
			expect(#selectedB).to.equal(2)
			-- Closest to B: index 6 (X=50), then index 5 (X=40)
			expect(selectedB[1]).to.equal(6)
			expect(selectedB[2]).to.equal(5)

			-- Caller mutates states[5]=Peeling, states[6]=Peeling between calls
			states[5] = STATE_PEELING
			states[6] = STATE_PEELING

			-- Rival C call
			local selectedC = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(-100, 0, 0), 2, STATE_ACTIVE
			)
			expect(#selectedC).to.equal(2)
			-- Closest to C among remaining Active (indices 1-4): index 1 (X=-50), index 2 (X=-40)
			expect(selectedC[1]).to.equal(1)
			expect(selectedC[2]).to.equal(2)

			-- B and C selections are disjoint
			local bSet: { [number]: boolean } = {}
			for _, idx in selectedB do
				bSet[idx] = true
			end
			for _, idx in selectedC do
				expect(bSet[idx]).to.equal(nil)
			end
		end)
	end)

	-- ===========================================================================
	-- Degenerate cases — F6 robustness
	-- ===========================================================================

	describe("PeelSelection — degenerate cases", function()
		it("test_peel_degenerate_empty_active_returns_empty", function()
			-- 0 Active followers → no selection, no error
			local positions = { Vector3.new(0, 0, 0) }
			local states = { STATE_PEELING }  -- not Active
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 5, STATE_ACTIVE
			)
			expect(#selected).to.equal(0)
		end)

		it("test_peel_degenerate_n_greater_than_active_returns_all", function()
			-- N=10 > Active=3 → return all 3
			local positions = {
				Vector3.new(0, 0, 0),
				Vector3.new(5, 0, 0),
				Vector3.new(10, 0, 0),
			}
			local states = { STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE }
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 10, STATE_ACTIVE
			)
			expect(#selected).to.equal(3)
		end)

		it("test_peel_degenerate_n_zero_returns_empty", function()
			-- N=0 → no-op (early return)
			local positions = { Vector3.new(0, 0, 0) }
			local states = { STATE_ACTIVE }
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 0, STATE_ACTIVE
			)
			expect(#selected).to.equal(0)
		end)

		it("test_peel_degenerate_n_negative_returns_empty", function()
			-- Defensive: negative N treated as no-op
			local positions = { Vector3.new(0, 0, 0) }
			local states = { STATE_ACTIVE }
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), -3, STATE_ACTIVE
			)
			expect(#selected).to.equal(0)
		end)

		it("test_peel_degenerate_all_peeling_returns_empty", function()
			-- All 80 followers already Peeling → no candidates
			local positions: { Vector3 } = {}
			local states: { string } = {}
			for i = 1, 80 do
				positions[i] = Vector3.new(i, 0, 0)
				states[i] = STATE_PEELING
			end
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 4, STATE_ACTIVE
			)
			expect(#selected).to.equal(0)
		end)
	end)

	-- ===========================================================================
	-- State filter — non-Active states (Spawning, Despawning) excluded
	-- ===========================================================================

	describe("PeelSelection — state filter", function()
		it("test_peel_state_filter_spawning_excluded", function()
			-- Spawning followers must NOT be peeled (they are not yet visible)
			local positions = {
				Vector3.new(40, 0, 0),  -- closest, but Spawning
				Vector3.new(20, 0, 0),  -- Active
			}
			local states = { STATE_SPAWNING, STATE_ACTIVE }
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 1, STATE_ACTIVE
			)
			expect(#selected).to.equal(1)
			expect(selected[1]).to.equal(2) -- Active only
		end)

		it("test_peel_state_filter_mixed_states_only_active_selected", function()
			-- Mix of Active, Peeling, Spawning, Despawning — only Active candidates
			local positions = {
				Vector3.new(50, 0, 0),  -- Peeling, dist 0
				Vector3.new(48, 0, 0),  -- Spawning, dist 2
				Vector3.new(46, 0, 0),  -- Active, dist 4
				Vector3.new(44, 0, 0),  -- Despawning, dist 6
				Vector3.new(42, 0, 0),  -- Active, dist 8
			}
			local states = {
				STATE_PEELING, STATE_SPAWNING, STATE_ACTIVE, "Despawning", STATE_ACTIVE,
			}
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 5, STATE_ACTIVE
			)
			-- Only 2 Active → both returned, ascending distance
			expect(#selected).to.equal(2)
			expect(selected[1]).to.equal(3) -- (46,0,0), dist 4
			expect(selected[2]).to.equal(5) -- (42,0,0), dist 8
		end)
	end)

	-- ===========================================================================
	-- Performance / scale — 80-follower full sort
	-- ===========================================================================

	describe("PeelSelection — 80-follower scale (Story §AC implicit)", function()
		it("test_peel_scale_80_followers_select_4_closest_to_rival", function()
			-- Story §Implementation: full sort acceptable for n ≤ 80
			-- Build 80 followers spread along X; rival at (1000, 0, 0); top 4 are X=80, 79, 78, 77
			local positions: { Vector3 } = {}
			local states: { string } = {}
			for i = 1, 80 do
				positions[i] = Vector3.new(i, 0, 0)
				states[i] = STATE_ACTIVE
			end
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(1000, 0, 0), 4, STATE_ACTIVE
			)
			expect(#selected).to.equal(4)
			-- Top 4 are indices 80, 79, 78, 77 (highest X)
			expect(selected[1]).to.equal(80)
			expect(selected[2]).to.equal(79)
			expect(selected[3]).to.equal(78)
			expect(selected[4]).to.equal(77)
		end)
	end)

	-- ===========================================================================
	-- Return order — ascending distance (closest first)
	-- ===========================================================================

	describe("PeelSelection — return order", function()
		it("test_peel_order_ascending_distance_closest_first", function()
			-- Verify the returned list is sorted ascending by distance.
			local positions = {
				Vector3.new(0, 0, 0),    -- dist 50
				Vector3.new(20, 0, 0),   -- dist 30
				Vector3.new(40, 0, 0),   -- dist 10
				Vector3.new(45, 0, 0),   -- dist 5
			}
			local states = { STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE, STATE_ACTIVE }
			local selected = PeelSelection.selectClosestToRival(
				positions, states, Vector3.new(50, 0, 0), 4, STATE_ACTIVE
			)
			expect(selected[1]).to.equal(4) -- dist 5
			expect(selected[2]).to.equal(3) -- dist 10
			expect(selected[3]).to.equal(2) -- dist 30
			expect(selected[4]).to.equal(1) -- dist 50
		end)
	end)
end
