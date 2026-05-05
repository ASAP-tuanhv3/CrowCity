--!strict

--[[
	lod_swap_teleport.spec.luau — TestEZ unit tests for LODTierMath.luau
	Implements verification of: TR-follower-entity-015, TR-follower-entity-016
	Story: production/epics/follower-entity/story-010-lod-tier-swap-teleport.md

	NAMING DEVIATION (precedent: stories 4-1..4-9):
	  Story §Test Evidence specifies `lod_swap_teleport_test.luau`.
	  Actual filename uses `.spec.luau` (TestEZ runner convention).

	TEST NAMING:
	  `test_lod_<scenario>_<expected_outcome>` per coding-standards.md.

	DETERMINISM:
	  - Distances passed as literal scalars
	  - Vector3 inputs constructed inline
	  - No `os.clock()` / `task.wait()` / `RunService` reads
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LODTierMath = require(ReplicatedStorage.Source.FollowerEntity.LODTierMath)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)

local FLOAT_EPSILON = 0.001

local function approxEqualVector(a: Vector3, b: Vector3): boolean
	return math.abs(a.X - b.X) < FLOAT_EPSILON
		and math.abs(a.Y - b.Y) < FLOAT_EPSILON
		and math.abs(a.Z - b.Z) < FLOAT_EPSILON
end

return function()
	-- ===========================================================================
	-- AC-13a — F5 boundary distances → tier mapping
	-- ===========================================================================

	describe("LODTierMath.computeTier — AC-13a F5 boundaries", function()
		local t0 = FollowerVisualConfig.LOD_TIER_0_MAX
		local t1 = FollowerVisualConfig.LOD_TIER_1_MAX
		local t2 = FollowerVisualConfig.LOD_TIER_2_MAX

		it("test_lod_AC13a_explicit_distance_table_matches_expected_tiers", function()
			-- Story §AC-13a: [0, 20, 20.1, 40, 40.1, 100, 100.1] → [0, 0, 1, 1, 2, 2, CULL]
			expect(LODTierMath.computeTier(0,    t0, t1, t2)).to.equal("0")
			expect(LODTierMath.computeTier(20,   t0, t1, t2)).to.equal("0")
			expect(LODTierMath.computeTier(20.1, t0, t1, t2)).to.equal("1")
			expect(LODTierMath.computeTier(40,   t0, t1, t2)).to.equal("1")
			expect(LODTierMath.computeTier(40.1, t0, t1, t2)).to.equal("2")
			expect(LODTierMath.computeTier(100,  t0, t1, t2)).to.equal("2")
			expect(LODTierMath.computeTier(100.1, t0, t1, t2)).to.equal("CULL")
		end)

		it("test_lod_computeTier_negative_distance_returns_tier_0", function()
			-- Defensive: negative distance treated as tier 0
			expect(LODTierMath.computeTier(-1, t0, t1, t2)).to.equal("0")
		end)

		it("test_lod_computeTier_zero_returns_tier_0", function()
			expect(LODTierMath.computeTier(0, t0, t1, t2)).to.equal("0")
		end)

		it("test_lod_computeTier_huge_distance_returns_CULL", function()
			expect(LODTierMath.computeTier(10000, t0, t1, t2)).to.equal("CULL")
		end)

		it("test_lod_computeTier_uses_TIER_constants", function()
			-- Module exposes TIER_0/TIER_1/TIER_2/TIER_CULL — use these in callers
			expect(LODTierMath.TIER_0).to.equal("0")
			expect(LODTierMath.TIER_1).to.equal("1")
			expect(LODTierMath.TIER_2).to.equal("2")
			expect(LODTierMath.TIER_CULL).to.equal("CULL")
		end)
	end)

	-- ===========================================================================
	-- AC-14 — Teleport detection (strict >, not >=)
	-- ===========================================================================

	describe("LODTierMath.shouldTeleportSnap — AC-14 strict greater-than", function()
		local THRESH = FollowerVisualConfig.TELEPORT_THRESHOLD

		it("test_lod_teleport_delta_50_triggers_snap", function()
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(50, 0, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(true)
		end)

		it("test_lod_teleport_delta_exactly_threshold_does_not_trigger", function()
			-- AC-14 edge: "delta exactly == 30 — no snap (`>`, not `>=`)"
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(30, 0, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(false)
		end)

		it("test_lod_teleport_delta_threshold_plus_one_triggers", function()
			-- AC-14 edge: "delta == 31 — snap fires"
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(31, 0, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(true)
		end)

		it("test_lod_teleport_small_delta_does_not_trigger", function()
			-- Subsequent frame after teleport: delta 1 < 30 → no snap
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(51, 0, 0), Vector3.new(50, 0, 0), THRESH
			)).to.equal(false)
		end)

		it("test_lod_teleport_3D_uses_full_magnitude", function()
			-- Y + Z components contribute — guard against X-only delta
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(0, 31, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(true)
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(0, 0, 31), Vector3.new(0, 0, 0), THRESH
			)).to.equal(true)
		end)

		it("test_lod_teleport_diagonal_delta_uses_magnitude", function()
			-- delta = (3, 4, 0) → mag 5 → no snap; (30, 40, 0) → mag 50 → snap
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(3, 4, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(false)
			expect(LODTierMath.shouldTeleportSnap(
				Vector3.new(30, 40, 0), Vector3.new(0, 0, 0), THRESH
			)).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- Teleport snap positions
	-- ===========================================================================

	describe("LODTierMath.computeTeleportSnapPositions — AC-14 snap math", function()
		it("test_lod_teleport_snap_positions_offset_by_spawn_offsets", function()
			-- AC-14: every follower's new pos = currentCenter + _spawnOffsets[i]
			local currentCenter = Vector3.new(50, 0, 0)
			local offsets = {
				Vector3.new(1, 0, 0),
				Vector3.new(0, 0, 2),
				Vector3.new(-1, 0, -1),
			}
			local positions = LODTierMath.computeTeleportSnapPositions(currentCenter, offsets)
			expect(#positions).to.equal(3)
			expect(approxEqualVector(positions[1], Vector3.new(51, 0, 0))).to.equal(true)
			expect(approxEqualVector(positions[2], Vector3.new(50, 0, 2))).to.equal(true)
			expect(approxEqualVector(positions[3], Vector3.new(49, 0, -1))).to.equal(true)
		end)

		it("test_lod_teleport_snap_positions_empty_offsets_returns_empty", function()
			local positions = LODTierMath.computeTeleportSnapPositions(
				Vector3.new(50, 0, 0), {}
			)
			expect(#positions).to.equal(0)
		end)

		it("test_lod_teleport_snap_positions_does_not_mutate_input", function()
			local offsets = { Vector3.new(1, 0, 0) }
			local _ = LODTierMath.computeTeleportSnapPositions(
				Vector3.new(50, 0, 0), offsets
			)
			-- offsets unchanged
			expect(approxEqualVector(offsets[1], Vector3.new(1, 0, 0))).to.equal(true)
		end)

		it("test_lod_teleport_snap_80_followers_all_offset_correctly", function()
			-- 80 followers at varied offsets; verify all repositioned
			local offsets: { Vector3 } = {}
			for i = 1, 80 do
				offsets[i] = Vector3.new(i, 0, 0)
			end
			local positions = LODTierMath.computeTeleportSnapPositions(
				Vector3.new(100, 0, 0), offsets
			)
			expect(#positions).to.equal(80)
			expect(approxEqualVector(positions[1], Vector3.new(101, 0, 0))).to.equal(true)
			expect(approxEqualVector(positions[80], Vector3.new(180, 0, 0))).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- shouldRenderF4 — boids gating per tier (ADR-0007)
	-- ===========================================================================

	describe("LODTierMath.shouldRenderF4 — boids gate per tier", function()
		it("test_lod_renderF4_tier0_returns_true", function()
			expect(LODTierMath.shouldRenderF4("0")).to.equal(true)
		end)

		it("test_lod_renderF4_tier1_returns_true", function()
			expect(LODTierMath.shouldRenderF4("1")).to.equal(true)
		end)

		it("test_lod_renderF4_tier2_returns_false", function()
			-- Tier 2 = billboard impostor; F4 boids suppressed
			expect(LODTierMath.shouldRenderF4("2")).to.equal(false)
		end)

		it("test_lod_renderF4_CULL_returns_false", function()
			expect(LODTierMath.shouldRenderF4("CULL")).to.equal(false)
		end)
	end)

	-- ===========================================================================
	-- shouldRenderBob — F8/F9 gating (LOD 0 only per Story 4-4 AC-26)
	-- ===========================================================================

	describe("LODTierMath.shouldRenderBob — F8/F9 gate (Story 4-4 AC-26)", function()
		it("test_lod_renderBob_tier0_returns_true", function()
			expect(LODTierMath.shouldRenderBob("0")).to.equal(true)
		end)

		it("test_lod_renderBob_tier1_returns_false", function()
			expect(LODTierMath.shouldRenderBob("1")).to.equal(false)
		end)

		it("test_lod_renderBob_tier2_returns_false", function()
			expect(LODTierMath.shouldRenderBob("2")).to.equal(false)
		end)

		it("test_lod_renderBob_CULL_returns_false", function()
			expect(LODTierMath.shouldRenderBob("CULL")).to.equal(false)
		end)
	end)

	-- ===========================================================================
	-- FollowerVisualConfig LOD constants
	-- ===========================================================================

	describe("FollowerVisualConfig LOD constants match story values", function()
		it("test_config_teleport_threshold_equals_30", function()
			expect(FollowerVisualConfig.TELEPORT_THRESHOLD).to.equal(30)
		end)

		it("test_config_lod_tier_0_max_equals_20", function()
			expect(FollowerVisualConfig.LOD_TIER_0_MAX).to.equal(20)
		end)

		it("test_config_lod_tier_1_max_equals_40", function()
			expect(FollowerVisualConfig.LOD_TIER_1_MAX).to.equal(40)
		end)

		it("test_config_lod_tier_2_max_equals_100", function()
			expect(FollowerVisualConfig.LOD_TIER_2_MAX).to.equal(100)
		end)
	end)

	-- ===========================================================================
	-- Integration scenarios — story-level AC end-to-end
	-- ===========================================================================

	describe("Integration scenarios (LOD swap + teleport)", function()
		it("test_lod_AC14_full_teleport_simulation", function()
			-- AC-14: lastCenter=(0,0,0); next frame current=(50,0,0); delta 50 > 30 → snap
			-- Subsequent frame current=(51,0,0); delta 1 < 30 → resume normal
			local THRESH = FollowerVisualConfig.TELEPORT_THRESHOLD

			-- Frame 1: teleport detected
			local frame1Snap = LODTierMath.shouldTeleportSnap(
				Vector3.new(50, 0, 0), Vector3.new(0, 0, 0), THRESH
			)
			expect(frame1Snap).to.equal(true)

			-- Frame 2: resume normal
			local frame2Snap = LODTierMath.shouldTeleportSnap(
				Vector3.new(51, 0, 0), Vector3.new(50, 0, 0), THRESH
			)
			expect(frame2Snap).to.equal(false)
		end)

		it("test_lod_AC13_tier_progression_during_camera_zoom_out", function()
			-- Camera zooms out from crowd: distance 5 → 25 → 50 → 90 → 150
			-- Tiers: 0 → 1 → 2 → 2 → CULL
			local t0 = FollowerVisualConfig.LOD_TIER_0_MAX
			local t1 = FollowerVisualConfig.LOD_TIER_1_MAX
			local t2 = FollowerVisualConfig.LOD_TIER_2_MAX
			expect(LODTierMath.computeTier(5, t0, t1, t2)).to.equal("0")
			expect(LODTierMath.computeTier(25, t0, t1, t2)).to.equal("1")
			expect(LODTierMath.computeTier(50, t0, t1, t2)).to.equal("2")
			expect(LODTierMath.computeTier(90, t0, t1, t2)).to.equal("2")
			expect(LODTierMath.computeTier(150, t0, t1, t2)).to.equal("CULL")
		end)
	end)
end
