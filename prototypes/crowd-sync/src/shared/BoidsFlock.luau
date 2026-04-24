--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Question: Can Roblox handle 800-3000 follower entities across 8-12 players at 60 FPS on mobile?
-- Date: 2026-04-20

-- Minimal boids flocking math. Called per follower per frame on client.
-- Simple separation + cohesion + follow-leader. No alignment (crowds don't need coherent heading).

local CrowdConfig = require(script.Parent.CrowdConfig)

local BoidsFlock = {}

type Follower = {
	position: Vector3,
	velocity: Vector3,
}

-- Returns new velocity for a follower given its local neighbors and crowd center.
function BoidsFlock.step(
	follower: Follower,
	neighbors: { Follower },
	leaderPosition: Vector3,
	dt: number
): Vector3
	local sepAccum = Vector3.zero
	local cohAccum = Vector3.zero
	local sepCount = 0
	local cohCount = 0

	for _, neighbor in neighbors do
		if neighbor == follower then
			continue
		end
		local delta = follower.position - neighbor.position
		local dist = delta.Magnitude
		if dist > 0 and dist < CrowdConfig.BOIDS_NEIGHBOR_RADIUS then
			-- separation: push away from close neighbors (inverse distance)
			sepAccum = sepAccum + (delta / math.max(dist * dist, 0.01))
			sepCount = sepCount + 1
			-- cohesion: pull toward local group mean
			cohAccum = cohAccum + neighbor.position
			cohCount = cohCount + 1
		end
	end

	local separation = Vector3.zero
	if sepCount > 0 then
		separation = sepAccum * CrowdConfig.BOIDS_SEPARATION_WEIGHT
	end

	local cohesion = Vector3.zero
	if cohCount > 0 then
		local meanPos = cohAccum / cohCount
		cohesion = (meanPos - follower.position) * CrowdConfig.BOIDS_COHESION_WEIGHT
	end

	-- follow leader (move toward crowd center)
	local toLeader = leaderPosition - follower.position
	local leaderForce = toLeader.Unit * CrowdConfig.BOIDS_FOLLOW_LEADER_WEIGHT

	local acceleration = separation + cohesion + leaderForce
	local newVelocity = follower.velocity + acceleration * dt

	-- clamp to max speed
	local speed = newVelocity.Magnitude
	if speed > CrowdConfig.BOIDS_MAX_SPEED then
		newVelocity = newVelocity.Unit * CrowdConfig.BOIDS_MAX_SPEED
	end

	-- Keep on ground plane (Y fixed to leader's Y + small offset for visual bob)
	newVelocity = Vector3.new(newVelocity.X, 0, newVelocity.Z)

	return newVelocity
end

return BoidsFlock
