--!strict

--[[
	PoolResize.luau — Pure pool resize logic with Peeling immunity
	Implements: TR-follower-entity-008 (Peeling immunity from cap-shrink eviction)
	GDD:        design/gdd/follower-entity.md §Peeling Immunity + §AC-9/25
	ADR:        ADR-0007 §Three-Module Split (FollowerEntityClient owns state arrays)
	            + §Eviction-Protection Contract
	Story:      production/epics/follower-entity/story-009-set-pool-size-peeling-immunity.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.

	NOT CALLED INSIDE RenderStepped — invoked from a 0.1 s LOD Manager tick.
	Full sort + scan acceptable: 80 followers × O(n log n) ≈ negligible at 10 Hz.

	EVICTION-PROTECTION CONTRACT (ADR-0007):
	  Peeling-state followers are never evicted by setPoolSize. The defensive
	  `actualN = max(n, peelingCount)` clamp guards against a buggy LOD Manager
	  that forgets to precompute `n_effective` per LOD GDD §F4. Worst-case
	  outcome of the bug: pool slightly larger than rawCap (Peeling held safe).
	  Best case: defensive clamp matches LOD Manager's precomputation; no-op.
--]]

local PoolResize = {}

-- ---------------------------------------------------------------------------
-- Result type — what the caller does with each call
-- ---------------------------------------------------------------------------

export type ResizeAction = {
	actualN: number,           -- max(n, peelingCount) — defensive clamp result
	evictIndices: { number },  -- indices in `states` to transition to Despawning
	growCount: number,         -- count of new FadeIn spawns to enqueue
}

-- ---------------------------------------------------------------------------
-- 1. countByState — internal helper
-- ---------------------------------------------------------------------------

--- Counts the number of indices in `states` whose value equals `targetLabel`.
--- O(n). Pure.
local function countByState(states: { string }, targetLabel: string): number
	local count = 0
	for _, s in states do
		if s == targetLabel then
			count += 1
		end
	end
	return count
end

-- ---------------------------------------------------------------------------
-- 2. getPeelingCount — public accessor (Story 4-9 §AC)
-- ---------------------------------------------------------------------------

--- Returns the number of followers in the Peeling state.
--- Caller's `getPeelingCount(self): number` delegates to this with `self._state` and
--- the project's "Peeling" state label.
---
--- @param states         { string } — parallel-array `_state[]` from FollowerEntityClient
--- @param peelingLabel   string     — typically "Peeling"
--- @return number — count of indices where states[i] == peelingLabel
function PoolResize.getPeelingCount(
	states: { string },
	peelingLabel: string
): number
	return countByState(states, peelingLabel)
end

-- ---------------------------------------------------------------------------
-- 3. computeResizeAction — main entry: defensive clamp + evict-or-grow decision
-- GDD §setPoolSize defensive re-clamp: actualN = max(n, peelingCount)
-- ---------------------------------------------------------------------------

--- Computes the eviction list + spawn count for a setPoolSize(n) call.
--- The caller applies the result by:
---   1. for each index in `evictIndices`: set `_state[i] = "Despawning"`
---   2. enqueue `growCount` FadeIn spawns into the throttle queue (Story 005)
---
--- Eviction order (Story §`Cap-shrink eviction order`):
---   1. `Despawning` followers already fading (highest priority — perimeter
---      irrelevant since they're already on the way out)
---   2. `Active` followers, perimeter-first (highest distance from crowd_center)
---      with tie-break by lower index first
---
--- Peeling followers are NEVER evicted regardless of distance (TR-008 invariant).
---
--- @param states              { string }  — parallel `_state[]`
--- @param positions           { Vector3 } — parallel `_positions[]`
--- @param crowdCenter         Vector3    — for distance-from-center sort
--- @param n                   number     — caller's requested cap
--- @param activeLabel         string     — typically "Active"
--- @param peelingLabel        string     — typically "Peeling"
--- @param despawningLabel     string     — typically "Despawning"
--- @return ResizeAction
function PoolResize.computeResizeAction(
	states: { string },
	positions: { Vector3 },
	crowdCenter: Vector3,
	n: number,
	activeLabel: string,
	peelingLabel: string,
	despawningLabel: string
): ResizeAction
	-- Defensive clamp: protect Peeling subset (TR-008)
	local peelingCount = countByState(states, peelingLabel)
	local actualN = math.max(n, peelingCount)

	-- Pool slot accounting
	local activeCount = countByState(states, activeLabel)
	local despawningCount = countByState(states, despawningLabel)
	local nonPeelTotal = activeCount + despawningCount

	-- Three branches: grow, shrink, or no-op
	if actualN > nonPeelTotal then
		-- Cap-growth: queue (actualN - nonPeelTotal) FadeIn spawns
		return {
			actualN = actualN,
			evictIndices = {},
			growCount = actualN - nonPeelTotal,
		}
	elseif actualN < nonPeelTotal then
		-- Cap-shrink: select (nonPeelTotal - actualN) eviction targets,
		-- preferring already-Despawning followers, then perimeter-first Active.
		local toEvict = nonPeelTotal - actualN

		-- Build candidate lists (separate so we can prioritise Despawning).
		local despawningIndices: { number } = {}
		local activeIndices: { number } = {}
		for i, s in states do
			if s == despawningLabel then
				table.insert(despawningIndices, i)
			elseif s == activeLabel then
				table.insert(activeIndices, i)
			end
		end

		-- Sort Active by descending distance from crowd_center (perimeter first).
		-- Stable sort with tie-break by lower index first (deterministic).
		table.sort(activeIndices, function(a, b)
			local diffA = positions[a] - crowdCenter
			local diffB = positions[b] - crowdCenter
			local distSqA = diffA.X * diffA.X + diffA.Y * diffA.Y + diffA.Z * diffA.Z
			local distSqB = diffB.X * diffB.X + diffB.Y * diffB.Y + diffB.Z * diffB.Z
			if distSqA == distSqB then
				return a < b  -- lower index wins on tie
			end
			return distSqA > distSqB  -- farther from center first
		end)

		-- Sort Despawning by index for deterministic ordering (no distance metric;
		-- they're already evicting, so order doesn't affect visible behaviour).
		table.sort(despawningIndices)

		-- Build eviction list: Despawning first, then perimeter-Active.
		local evictIndices: { number } = {}
		local evicted = 0
		for _, idx in despawningIndices do
			if evicted >= toEvict then break end
			evicted += 1
			evictIndices[evicted] = idx
		end
		for _, idx in activeIndices do
			if evicted >= toEvict then break end
			evicted += 1
			evictIndices[evicted] = idx
		end

		return {
			actualN = actualN,
			evictIndices = evictIndices,
			growCount = 0,
		}
	end

	-- actualN == nonPeelTotal: no-op
	return {
		actualN = actualN,
		evictIndices = {},
		growCount = 0,
	}
end

return PoolResize
