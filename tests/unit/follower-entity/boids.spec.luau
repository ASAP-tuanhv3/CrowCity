--!strict

--[[
	boids.spec.luau — Unit tests for FollowerEntity/Boids.luau (F1-F4 boids math)
	Path:  tests/unit/follower-entity/boids.spec.luau
	Story: production/epics/follower-entity/story-003-boids-flocking.md

	NAMING CONVENTION DEVIATION (document per brief):
	  The story §Test Evidence section names this file `boids_test.luau`.
	  The TestEZ runner (tests/runner.server.luau) discovers `*.spec.luau` only.
	  This file uses `boids.spec.luau` to match the runner convention — the same
	  fix applied in story 4-1 (pool_bootstrap_rig_assembly.spec.luau) and
	  story 4-2 (crowd_manager_orchestrator.spec.luau). The story file title is
	  unchanged; only the on-disk filename follows the runner pattern.

	AC Coverage:
	  AC-15 — F1 EPSILON guard: overlap (P_i == P_j) produces finite result, no NaN/inf
	  AC-20a — F4 nominal inputs (F_sep, F_coh, F_lead) → V_raw ≈ (1.3, 0, 2.4), ‖V_raw‖ ≈ 2.73
	  AC-20b — F4 all-zero forces → Vector3.zero; P_new == P_i (no movement, no NaN)
	  F1 separation    — correct per-neighbor contribution; radius filter; N=0 case
	  F2 cohesion      — N=0 short-circuit before (1/N); centroid math; radius filter
	  F3 follow-leader — pure subtraction; nil → zero; at-leader → zero
	  F4 final velocity — per-component zero guard; V_raw zero guard; MAX_SPEED clamp
	  applyVelocity    — zero-V exact equality; non-zero correct advance
	  Constants        — all 7 knobs match story values; SEPARATION_RADIUS < NEIGHBOR_RADIUS

	Test strategy:
	  - Pure Vector3 math; no Roblox services required.
	  - Boids module is required directly; FollowerBoidsConfig required for constants tests.
	  - No task.wait(), os.clock(), math.random(), RunService — fully deterministic.
	  - NaN detection: IEEE 754 — `v ~= v` is true for NaN; isFinite() helper checks all axes.
	  - Float tolerance: approxEqualVector(a, b, eps) for per-component; eps=0.001 per story.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Boids  = require(ReplicatedStorage.Source.FollowerEntity.Boids)
	local Config = require(ReplicatedStorage.Source.SharedConstants.FollowerBoidsConfig)

	-- =========================================================================
	-- Test helpers
	-- =========================================================================

	--- Returns true when v has no NaN or infinite components and finite magnitude.
	--- NaN detection: IEEE 754 guarantees NaN ~= NaN == true (i.e. v.X == v.X is false for NaN).
	local function isFinite(v: Vector3): boolean
		return v.X == v.X
			and v.Y == v.Y
			and v.Z == v.Z
			and v.Magnitude < math.huge
	end

	--- Returns true when two Vector3 values are within `eps` distance of each other.
	local function approxEqualVector(a: Vector3, b: Vector3, eps: number): boolean
		return (a - b).Magnitude < eps
	end

	--- Returns true when two numbers are within `eps` of each other.
	local function approxEqual(a: number, b: number, eps: number): boolean
		return math.abs(a - b) < eps
	end

	-- =========================================================================
	-- F1 Separation
	-- =========================================================================

	describe("F1 separation", function()

		it("test_boids_separation_overlap_returns_finite_no_nan", function()
			-- Arrange: P_i == P_j exactly — EPSILON guard must prevent NaN/inf (AC-15)
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(0, 0, 0) }

			-- Act
			local result = Boids.separation(P_i, neighbors, Config.SEPARATION_RADIUS, Config.EPSILON)

			-- Assert: finite, no NaN, no error raised
			expect(isFinite(result)).to.equal(true)
		end)

		it("test_boids_separation_overlap_three_followers_sum_finite", function()
			-- Arrange: 3 followers all at same position (AC-15 edge case)
			local P_i = Vector3.new(5, 0, 5)
			local neighbors = {
				Vector3.new(5, 0, 5),
				Vector3.new(5, 0, 5),
				Vector3.new(5, 0, 5),
			}

			-- Act
			local result = Boids.separation(P_i, neighbors, Config.SEPARATION_RADIUS, Config.EPSILON)

			-- Assert: sum of (0,0,0)/0.001 three times = (0,0,0); finite, no NaN
			expect(isFinite(result)).to.equal(true)
		end)

		it("test_boids_separation_single_neighbor_repels_correctly", function()
			-- Arrange: GDD §F1 example — P_i=(0,0,0), neighbor=(1,0,0), sepRadius=3
			-- displacement = (-1,0,0), dist_sq = 1, max(1, 0.001) = 1
			-- force = (-1,0,0) / 1 = (-1, 0, 0)
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(1, 0, 0) }
			local separationRadius = 3.0

			-- Act
			local result = Boids.separation(P_i, neighbors, separationRadius, Config.EPSILON)

			-- Assert
			expect(approxEqualVector(result, Vector3.new(-1, 0, 0), 0.001)).to.equal(true)
		end)

		it("test_boids_separation_no_neighbors_returns_zero", function()
			-- Arrange: empty neighbors list
			local P_i = Vector3.new(0, 0, 0)

			-- Act
			local result = Boids.separation(P_i, {}, Config.SEPARATION_RADIUS, Config.EPSILON)

			-- Assert: no neighbors → zero force
			expect(result).to.equal(Vector3.zero)
		end)

		it("test_boids_separation_neighbor_outside_radius_excluded", function()
			-- Arrange: neighbor at distance 12, separationRadius = 8.0 → excluded.
			-- BUG-002 tune 2026-05-10: SEPARATION_RADIUS bumped 2.5 → 8.0 so
			-- neighbor distance updated from 5 to 12 to stay outside.
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(12, 0, 0) }

			-- Act
			local result = Boids.separation(P_i, neighbors, Config.SEPARATION_RADIUS, Config.EPSILON)

			-- Assert: outside radius → zero force
			expect(result).to.equal(Vector3.zero)
		end)

	end)

	-- =========================================================================
	-- F2 Cohesion
	-- =========================================================================

	describe("F2 cohesion", function()

		it("test_boids_cohesion_zero_neighbors_returns_zero_skips_divide", function()
			-- Arrange: no neighbors within NEIGHBOR_RADIUS (mandatory N=0 short-circuit)
			-- The (1/N) path must NOT be entered — Luau 1/0 = math.huge, math.huge*0 = nan
			local P_i = Vector3.new(0, 0, 0)
			-- All neighbors placed far outside radius
			local neighbors = { Vector3.new(100, 0, 0), Vector3.new(-100, 0, 0) }

			-- Act
			local result = Boids.cohesion(P_i, neighbors, Config.NEIGHBOR_RADIUS)

			-- Assert: exactly zero (not nan, not math.huge)
			expect(result).to.equal(Vector3.zero)
			expect(isFinite(result)).to.equal(true)
		end)

		it("test_boids_cohesion_one_neighbor_centroid_matches_neighbor", function()
			-- Arrange: one neighbor at (4,0,0), P_i at (0,0,0)
			-- centroid = (4,0,0), F_coh = (4,0,0) - (0,0,0) = (4,0,0)
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(4, 0, 0) }

			-- Act
			local result = Boids.cohesion(P_i, neighbors, Config.NEIGHBOR_RADIUS)

			-- Assert
			expect(approxEqualVector(result, Vector3.new(4, 0, 0), 0.001)).to.equal(true)
		end)

		it("test_boids_cohesion_two_neighbors_centroid_average", function()
			-- Arrange: GDD §F2 example — P_i=(0,0,0), neighbors at (4,0,0) + (2,0,0)
			-- centroid = (3,0,0), F_coh = (3,0,0)
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(4, 0, 0), Vector3.new(2, 0, 0) }

			-- Act
			local result = Boids.cohesion(P_i, neighbors, Config.NEIGHBOR_RADIUS)

			-- Assert
			expect(approxEqualVector(result, Vector3.new(3, 0, 0), 0.001)).to.equal(true)
		end)

		it("test_boids_cohesion_neighbor_outside_radius_excluded", function()
			-- Arrange: one neighbor inside (3,0,0) and one outside (20,0,0)
			-- BUG-002 tune 2026-05-10: NEIGHBOR_RADIUS bumped 6.0 → 16.0 so
			-- outside neighbor moved from (10,0,0) to (20,0,0).
			-- Only neighbor at (3,0,0) contributes: centroid = (3,0,0), F_coh = (3,0,0)
			local P_i = Vector3.new(0, 0, 0)
			local neighbors = { Vector3.new(3, 0, 0), Vector3.new(20, 0, 0) }

			-- Act
			local result = Boids.cohesion(P_i, neighbors, Config.NEIGHBOR_RADIUS)

			-- Assert: only the in-radius neighbor contributes
			expect(approxEqualVector(result, Vector3.new(3, 0, 0), 0.001)).to.equal(true)
		end)

	end)

	-- =========================================================================
	-- F3 Follow-leader
	-- =========================================================================

	describe("F3 follow-leader", function()

		it("test_boids_follow_leader_returns_displacement_to_leader", function()
			-- Arrange: GDD §F3 example — crowd at (10,0,0), follower at (0,0,0)
			-- F_lead = (10,0,0) - (0,0,0) = (10,0,0)
			local P_i = Vector3.new(0, 0, 0)
			local leaderPos = Vector3.new(10, 0, 0)

			-- Act
			local result = Boids.followLeader(P_i, leaderPos)

			-- Assert
			expect(approxEqualVector(result, Vector3.new(10, 0, 0), 0.001)).to.equal(true)
		end)

		it("test_boids_follow_leader_at_leader_returns_zero", function()
			-- Arrange: follower already at leader position
			local P_i = Vector3.new(5, 0, 5)
			local leaderPos = Vector3.new(5, 0, 5)

			-- Act
			local result = Boids.followLeader(P_i, leaderPos)

			-- Assert: displacement is zero when at leader
			expect(approxEqualVector(result, Vector3.zero, 0.001)).to.equal(true)
		end)

		it("test_boids_follow_leader_nil_leader_returns_zero", function()
			-- Arrange: leaderPos is nil (caller-handled case — module safety net)
			-- The Despawning state transition lives in Client.luau (story-002 path).
			-- The module returns Vector3.zero to prevent NaN propagation.
			local P_i = Vector3.new(3, 0, 3)

			-- Act
			local result = Boids.followLeader(P_i, nil)

			-- Assert: nil leader → zero force, no error
			expect(result).to.equal(Vector3.zero)
		end)

	end)

	-- =========================================================================
	-- F4 Final velocity
	-- =========================================================================

	describe("F4 final velocity", function()

		it("test_boids_final_velocity_AC20_nominal_inputs_match_expected", function()
			-- Arrange: AC-20a — GDD §F4 worked example (uses EXPLICIT weights so the
			-- documented math stays stable when Config values are tuned).
			-- BUG-002 2026-05-10: F_lead now uses RAW vector (not .Unit) in
			-- finalVelocity so distance to leader drives speed. Worked example
			-- uses |F_lead|=1.0 so raw == Unit — same result either way.
			-- F_sep = (-1,0,0), F_coh = (1,0,0), F_lead = (0.6,0,0.8)
			-- F_sep.Unit × 1.5 = (-1.5, 0, 0)
			-- F_coh.Unit × 1.0 = ( 1.0, 0, 0)
			-- F_lead RAW × 3.0 = (1.8, 0, 2.4) (|F_lead|=1.0 → raw==Unit here)
			-- V_raw = (-1.5+1.0+1.8, 0, 0+0+2.4) = (1.3, 0, 2.4)
			-- ‖V_raw‖ = sqrt(1.69 + 5.76) = sqrt(7.45) ≈ 2.729
			-- clamp(2.729, 0, 16) = 2.729 → V_final ≈ (1.3, 0, 2.4) (unchanged, below max)
			local F_sep  = Vector3.new(-1, 0, 0)
			local F_coh  = Vector3.new(1, 0, 0)
			local F_lead = Vector3.new(0.6, 0, 0.8)

			-- Explicit weights (1.5/1.0/3.0/16) — decoupled from Config to keep this
			-- worked-example test stable against tuning changes.
			-- Act
			local V_final = Boids.finalVelocity(
				F_sep, F_coh, F_lead,
				1.5,   -- SEPARATION_WEIGHT (worked-example constant)
				1.0,   -- COHESION_WEIGHT
				3.0,   -- FOLLOW_LEADER_WEIGHT
				16     -- MAX_SPEED
			)

			-- Assert: V_final ≈ (1.3, 0, 2.4) within ±0.001 per component
			expect(approxEqual(V_final.X, 1.3, 0.001)).to.equal(true)
			expect(approxEqual(V_final.Y, 0.0, 0.001)).to.equal(true)
			expect(approxEqual(V_final.Z, 2.4, 0.001)).to.equal(true)
			-- ‖V_raw‖ ≈ 2.73 within ±0.01
			expect(approxEqual(V_final.Magnitude, 2.729, 0.01)).to.equal(true)
			-- finite (no NaN/inf)
			expect(isFinite(V_final)).to.equal(true)
		end)

		it("test_boids_final_velocity_AC20_zero_forces_returns_zero", function()
			-- Arrange: AC-20b — all three forces zero
			-- No .Unit must be called on any zero vector; V_raw must be zero; result must be zero.
			local F_sep  = Vector3.zero
			local F_coh  = Vector3.zero
			local F_lead = Vector3.zero

			-- Act
			local result = Boids.finalVelocity(
				F_sep, F_coh, F_lead,
				Config.SEPARATION_WEIGHT,
				Config.COHESION_WEIGHT,
				Config.FOLLOW_LEADER_WEIGHT,
				Config.MAX_SPEED
			)

			-- Assert: exactly zero (not NaN — no .Unit on zero-vector triggered)
			expect(result).to.equal(Vector3.zero)
			expect(isFinite(result)).to.equal(true)
		end)

		it("test_boids_final_velocity_per_component_zero_guard", function()
			-- Arrange: F_sep zero, F_coh zero, only F_lead non-zero.
			-- BUG-002 2026-05-10: F_lead is RAW × FOLLOW_LEADER_WEIGHT (not .Unit).
			-- F_lead = (0, 0, 4) × 3.0 = (0, 0, 12). Below MAX_SPEED=16, no clamp.
			local F_sep  = Vector3.zero
			local F_coh  = Vector3.zero
			local F_lead = Vector3.new(0, 0, 4)

			-- Act
			local result = Boids.finalVelocity(
				F_sep, F_coh, F_lead,
				Config.SEPARATION_WEIGHT,
				Config.COHESION_WEIGHT,
				Config.FOLLOW_LEADER_WEIGHT,
				Config.MAX_SPEED
			)

			-- Assert: only Z component from F_lead × FOLLOW_LEADER_WEIGHT = 12.
			expect(approxEqual(result.X, 0.0, 0.001)).to.equal(true)
			expect(approxEqual(result.Y, 0.0, 0.001)).to.equal(true)
			expect(approxEqual(result.Z, 4 * Config.FOLLOW_LEADER_WEIGHT, 0.001)).to.equal(true)
			expect(isFinite(result)).to.equal(true)
		end)

		it("test_boids_final_velocity_max_speed_clamp_applies", function()
			-- Arrange: construct forces such that V_raw magnitude >> MAX_SPEED
			-- Use F_sep only pointing in +Z with large weights to exceed 16.
			-- F_sep = (0,0,1) → V_raw = (0,0,1) * SEPARATION_WEIGHT = (0,0,1.5)
			-- Use custom large weight to force > MAX_SPEED: pass sepWeight=100.
			local F_sep  = Vector3.new(0, 0, 1)
			local F_coh  = Vector3.zero
			local F_lead = Vector3.zero
			local bigWeight = 100.0

			-- Act
			local result = Boids.finalVelocity(
				F_sep, F_coh, F_lead,
				bigWeight,          -- sepWeight = 100 → V_raw = (0,0,100)
				Config.COHESION_WEIGHT,
				Config.FOLLOW_LEADER_WEIGHT,
				Config.MAX_SPEED
			)

			-- Assert: magnitude clamped to exactly MAX_SPEED; direction preserved (+Z)
			expect(approxEqual(result.Magnitude, Config.MAX_SPEED, 0.001)).to.equal(true)
			expect(approxEqual(result.X, 0.0, 0.001)).to.equal(true)
			expect(approxEqual(result.Y, 0.0, 0.001)).to.equal(true)
			expect(approxEqual(result.Z, Config.MAX_SPEED, 0.001)).to.equal(true)
		end)

		it("test_boids_final_velocity_below_max_speed_no_clamp_applied", function()
			-- Arrange: F_lead = (0,0,1) → V_raw = (0,0,FOLLOW_LEADER_WEIGHT = 3.0)
			-- 3.0 < MAX_SPEED=16, so no clamp; result magnitude == 3.0
			local F_sep  = Vector3.zero
			local F_coh  = Vector3.zero
			local F_lead = Vector3.new(0, 0, 1)

			-- Act
			local result = Boids.finalVelocity(
				F_sep, F_coh, F_lead,
				Config.SEPARATION_WEIGHT,
				Config.COHESION_WEIGHT,
				Config.FOLLOW_LEADER_WEIGHT,
				Config.MAX_SPEED
			)

			-- Assert: no clamping; magnitude preserved
			expect(approxEqual(result.Magnitude, Config.FOLLOW_LEADER_WEIGHT, 0.001)).to.equal(true)
		end)

	end)

	-- =========================================================================
	-- Helper: applyVelocity
	-- =========================================================================

	describe("applyVelocity helper", function()

		it("test_boids_apply_velocity_zero_velocity_returns_p_i_exact", function()
			-- Arrange: V = zero → P_new must be exactly P_i (no float drift from + 0 * dt)
			local P_i = Vector3.new(3.14159, 2.71828, 1.41421)
			local V   = Vector3.zero
			local dt  = 1 / 60

			-- Act
			local result = Boids.applyVelocity(P_i, V, dt)

			-- Assert: exact equality (not just approx — spec says "exact")
			expect(result).to.equal(P_i)
		end)

		it("test_boids_apply_velocity_non_zero_velocity_p_new_correct", function()
			-- Arrange: P_i=(0,0,0), V=(1,0,0), dt=1/60 → P_new ≈ (1/60, 0, 0)
			local P_i = Vector3.new(0, 0, 0)
			local V   = Vector3.new(1, 0, 0)
			local dt  = 1 / 60

			-- Act
			local result = Boids.applyVelocity(P_i, V, dt)

			-- Assert: P_new ≈ (1/60, 0, 0) within float tolerance
			expect(approxEqualVector(result, Vector3.new(dt, 0, 0), 0.0001)).to.equal(true)
		end)

	end)

	-- =========================================================================
	-- Constants and startup assertion
	-- =========================================================================

	describe("FollowerBoidsConfig constants", function()

		it("test_boids_config_constants_match_story_values", function()
			-- BUG-002 tune 2026-05-10: NEIGHBOR_RADIUS / SEPARATION_RADIUS /
			-- SEPARATION_WEIGHT bumped from story-003 §AC values to enable
			-- visible swarm spread with raw F_lead. Other 4 unchanged.
			expect(Config.NEIGHBOR_RADIUS).to.equal(16.0)
			expect(Config.SEPARATION_RADIUS).to.equal(8.0)
			expect(Config.SEPARATION_WEIGHT).to.equal(6.0)
			expect(Config.COHESION_WEIGHT).to.equal(1.0)
			expect(Config.FOLLOW_LEADER_WEIGHT).to.equal(3.0)
			expect(Config.MAX_SPEED).to.equal(16)
			expect(Config.EPSILON).to.equal(0.001)
		end)

		it("test_boids_config_separation_radius_less_than_neighbor_radius", function()
			-- Sanity check: startup assertion already fires at module load, but test is
			-- explicit so CI clearly labels this failure if a future change inverts the relation.
			-- Story §QA: "if a future change inverts the relation, the assertion must fail."
			expect(Config.SEPARATION_RADIUS < Config.NEIGHBOR_RADIUS).to.equal(true)
		end)

	end)

end
