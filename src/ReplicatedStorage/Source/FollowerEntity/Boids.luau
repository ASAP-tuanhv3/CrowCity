--!strict

--[[
	Boids.luau — Pure boids math for F1-F4 (separation, cohesion, follow-leader, final velocity)
	Implements: TR-follower-entity-001 (CFrame authority — no Humanoid; Parts anchored)
	GDD:        design/gdd/follower-entity.md §F1-F4 Formulas (lines 144–225)
	ADR:        ADR-0007 §Boids Loop Discipline + §Three-Module Split
	Story:      production/epics/follower-entity/story-003-boids-flocking.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	All inputs arrive as plain Luau values (Vector3, number). This enables
	deterministic unit testing with literal inputs under TestEZ without a running
	Roblox server.

	All 7 boids knobs are passed as function arguments (not hard-coded). Callers
	supply them from SharedConstants/FollowerBoidsConfig to ensure data-driven
	configuration. Tests may pass inline literal values for isolation.
--]]

local Boids = {}

-- ---------------------------------------------------------------------------
-- F1. boids_separation_force
-- GDD §F1: F_sep = Σ (P_i - P_j) / max(‖P_i - P_j‖², ε)
--           for all j where ‖P_i - P_j‖ < separationRadius
-- ---------------------------------------------------------------------------

--- Computes the separation force for follower at `P_i` given a list of neighbor positions.
--- Filters to neighbors strictly within `separationRadius` internally.
--- Uses `epsilon` as a denominator floor to guard against divide-by-zero on exact overlap
--- (AC-15). Returns Vector3.zero when no neighbors are within the radius.
---
--- @param P_i             Vector3  — This follower's world position
--- @param neighbors       {Vector3} — All candidate neighbor positions
--- @param separationRadius number   — Repulsion radius (studs); from FollowerBoidsConfig
--- @param epsilon          number   — Denominator floor (default 0.001); from FollowerBoidsConfig
--- @return Vector3 — Unbounded separation force vector
function Boids.separation(
	P_i: Vector3,
	neighbors: { Vector3 },
	separationRadius: number,
	epsilon: number
): Vector3
	local force = Vector3.zero

	for _, P_j in neighbors do
		local displacement = P_i - P_j
		local dist = displacement.Magnitude

		-- Only contribute if the neighbor is within the separation radius.
		if dist < separationRadius then
			-- Denominator is magnitude-squared, floored at epsilon to prevent NaN
			-- on exact overlap (dist == 0). Division is a scalar on the displacement vector.
			local distSq = dist * dist
			local denominator = math.max(distSq, epsilon)
			force = force + displacement / denominator
		end
	end

	return force
end

-- ---------------------------------------------------------------------------
-- F2. boids_cohesion_force
-- GDD §F2: centroid = (1/N) Σ P_j  for j within neighborRadius
--          F_coh = centroid - P_i
--          N=0 guard: return Vector3.zero BEFORE the (1/N) divide.
-- ---------------------------------------------------------------------------

--- Computes the cohesion force drawing follower at `P_i` toward the centroid of neighbors
--- within `neighborRadius`. Mandatory N=0 short-circuit: returns Vector3.zero when there
--- are no qualifying neighbors, preventing `1/0 = math.huge` and `math.huge * 0 = nan`.
---
--- @param P_i          Vector3   — This follower's world position
--- @param neighbors    {Vector3} — All candidate neighbor positions
--- @param neighborRadius number  — Cohesion awareness radius (studs); from FollowerBoidsConfig
--- @return Vector3 — Cohesion force vector (magnitude ≤ neighborRadius, or zero when isolated)
function Boids.cohesion(
	P_i: Vector3,
	neighbors: { Vector3 },
	neighborRadius: number
): Vector3
	local sum = Vector3.zero
	local count = 0

	for _, P_j in neighbors do
		if (P_j - P_i).Magnitude < neighborRadius then
			sum = sum + P_j
			count = count + 1
		end
	end

	-- Mandatory N=0 guard — short-circuit before (1/N); Luau 1/0 = math.huge.
	if count == 0 then
		return Vector3.zero
	end

	local centroid = sum / count
	return centroid - P_i
end

-- ---------------------------------------------------------------------------
-- F3. boids_follow_leader_force
-- GDD §F3: F_lead = leaderPos - P_i
--          Nil-guard: caller (Client.luau) owns the Despawning transition.
--          Module-level safety net: if leaderPos is nil, return Vector3.zero.
-- ---------------------------------------------------------------------------

--- Computes the follow-leader force pulling follower at `P_i` toward `leaderPos`.
--- Pure subtraction: F_lead = leaderPos - P_i.
---
--- Nil handling: the Despawning state transition when `CrowdStateClient.get` returns nil
--- is the caller's responsibility (Client.luau, story-002 path). This function provides
--- a safety net by returning Vector3.zero for a nil leaderPos, but callers MUST handle
--- the nil case upstream before invoking F4 to avoid unnecessary frame work.
---
--- @param P_i      Vector3  — This follower's world position
--- @param leaderPos Vector3? — Leader's world position (nil if crowd data unavailable)
--- @return Vector3 — Direction and magnitude toward leader, or zero if leaderPos is nil
function Boids.followLeader(P_i: Vector3, leaderPos: Vector3?): Vector3
	if leaderPos == nil then
		return Vector3.zero
	end
	return leaderPos - P_i
end

-- ---------------------------------------------------------------------------
-- F4. boids_final_velocity
-- GDD §F4: Compose F_sep, F_coh, F_lead with per-component zero-vector guards.
--          V_raw zero-guard: hold position if all forces cancel.
--          MAX_SPEED clamp: V_final = clamp(V_raw.Magnitude, 0, maxSpeed) * V_raw.Unit
-- ---------------------------------------------------------------------------

--- Composes the three boids forces into a final velocity vector.
--- Zero-vector guard per component (AC-20): each force is only normalised and added
--- if its magnitude > 0, preventing `.Unit` on zero-vectors (which produces NaN).
--- Zero V_raw guard: if the composed V_raw has zero magnitude (all forces zero or cancel),
--- returns Vector3.zero — the caller's applyVelocity will hold position unchanged.
---
--- @param F_sep      Vector3 — Separation force (from Boids.separation)
--- @param F_coh      Vector3 — Cohesion force   (from Boids.cohesion)
--- @param F_lead     Vector3 — Follow-leader force (from Boids.followLeader)
--- @param sepWeight  number  — SEPARATION_WEIGHT from FollowerBoidsConfig
--- @param cohWeight  number  — COHESION_WEIGHT from FollowerBoidsConfig
--- @param leadWeight number  — FOLLOW_LEADER_WEIGHT from FollowerBoidsConfig
--- @param maxSpeed   number  — MAX_SPEED from FollowerBoidsConfig (studs/s)
--- @return Vector3 — Final velocity vector (magnitude ∈ [0, maxSpeed]), or Vector3.zero
function Boids.finalVelocity(
	F_sep: Vector3,
	F_coh: Vector3,
	F_lead: Vector3,
	sepWeight: number,
	cohWeight: number,
	leadWeight: number,
	maxSpeed: number
): Vector3
	local V_raw = Vector3.zero

	-- Per-component zero-vector guard: skip .Unit on any zero-magnitude force.
	-- F_sep + F_coh: unit-normalized (constant push/pull magnitude regardless
	-- of density). F_lead: RAW vector × weight — distance to leader-slot drives
	-- speed (far = fast catch-up, close = settle). MAX_SPEED clamp below applies
	-- the design ceiling. Without raw F_lead, follower max speed = sum-of-weights
	-- (5.5 stud/sec) which can't track player walk speed (16 stud/sec).
	if F_sep.Magnitude > 0 then
		V_raw = V_raw + F_sep.Unit * sepWeight
	end
	if F_coh.Magnitude > 0 then
		V_raw = V_raw + F_coh.Unit * cohWeight
	end
	if F_lead.Magnitude > 0 then
		V_raw = V_raw + F_lead * leadWeight
	end

	-- Zero V_raw guard: if all forces are absent or cancel, signal hold-position via zero.
	-- Caller's applyVelocity handles the hold (P_new = P_i when V == zero).
	if V_raw.Magnitude == 0 then
		return Vector3.zero
	end

	-- MAX_SPEED clamp: scale direction by clamped magnitude.
	local speed = math.clamp(V_raw.Magnitude, 0, maxSpeed)
	return speed * V_raw.Unit
end

-- ---------------------------------------------------------------------------
-- Helper: apply velocity to position
-- ---------------------------------------------------------------------------

--- Advances position `P_i` by velocity `V` scaled by delta time `dt`.
--- If `V` is exactly Vector3.zero, returns `P_i` unchanged with no arithmetic
--- (avoids float drift from `P_i + 0 * dt` in edge cases).
--- This is the canonical per-frame position update; callers must not call `.Unit` on V.
---
--- @param P_i Vector3 — Current world position
--- @param V   Vector3 — Final velocity vector (output of Boids.finalVelocity)
--- @param dt  number  — RenderStepped delta time (seconds)
--- @return Vector3 — New world position
function Boids.applyVelocity(P_i: Vector3, V: Vector3, dt: number): Vector3
	if V == Vector3.zero then
		return P_i
	end
	return P_i + V * dt
end

return Boids
