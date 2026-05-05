--!strict

--[[
	PeelSelection.luau — Pure F6 closest-to-rival selection algorithm
	Implements: TR-follower-entity-013 (F6 closest-to-rival contact-face selection)
	GDD:        design/gdd/follower-entity.md §F6 + §Concurrent Peel Edge Case
	ADR:        ADR-0007 §Three-Module Split (FollowerEntityClient invokes selection)
	Story:      production/epics/follower-entity/story-007-peel-selection-f6.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	Inputs are parallel-array slices (positions, states) + rivalCenter + n.
	Output is a sorted list of selected indices — caller mutates `_state[i] = Peeling`.

	NOT CALLED INSIDE RenderStepped — invoked from a 15 Hz CountChanged handler
	(once per peel event, not per frame). Full sort acceptable: 80 followers ×
	log2(80) ≈ 500 comparisons per call ≈ negligible CPU at 15 Hz.

	CONTACT-FACE INTUITION:
	  Followers closest to rival_center are physically nearest the collision face.
	  Visual conquest reads correctly when these are peeled (rival "absorbs" the
	  contact line, not random scatter from the back of the crowd).
--]]

local PeelSelection = {}

-- ---------------------------------------------------------------------------
-- selectClosestToRival
-- GDD §F6: selected = sort(Active by ‖P_i - rival_center‖ ascending)[1..min(N, |Active|)]
-- ---------------------------------------------------------------------------

--- Selects the N indices into `positions` whose followers are closest to
--- `rivalCenter`, restricted to indices where `states[i] == activeStateLabel`.
--- Returns the selected indices in ascending-distance order (closest first).
---
--- The caller is responsible for state mutation (transition to "Peeling")
--- after consuming the returned list. This module performs NO writes.
---
--- Concurrent dual-rival behaviour: by accepting the current `states` array
--- as input, a second call within the same frame naturally excludes followers
--- already moved to "Peeling" by the first call (provided the caller updates
--- `states` between calls — which is the standard pattern in Client.luau).
---
--- @param positions         { Vector3 }  — parallel array of follower positions
--- @param states            { string }   — parallel array of follower states
--- @param rivalCenter       Vector3      — cached rival crowd_center at call time
--- @param n                 number       — desired peel count (broadcast-reported)
--- @param activeStateLabel  string       — typically "Active"
--- @return { number } — selected indices in ascending-distance order; empty if 0
function PeelSelection.selectClosestToRival(
	positions: { Vector3 },
	states: { string },
	rivalCenter: Vector3,
	n: number,
	activeStateLabel: string
): { number }
	-- Defensive: n <= 0 → no-op (avoids unnecessary sort allocation)
	if n <= 0 then
		return {}
	end

	-- 1. Filter to Active followers, building (index, dist²) candidate list.
	-- Use squared distance to avoid sqrt — monotonic, so sort order is preserved.
	-- For 80 followers this saves ~80 sqrt calls per peel event.
	local candidates: { { index: number, distSq: number } } = {}
	local candidateCount = 0
	for i, state in states do
		if state == activeStateLabel then
			candidateCount += 1
			local diff = positions[i] - rivalCenter
			candidates[candidateCount] = {
				index = i,
				distSq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z,
			}
		end
	end

	-- 2. Degenerate case: no Active followers → no selection
	if candidateCount == 0 then
		return {}
	end

	-- 3. Sort ascending by distSq.
	-- Stable sort not required (story §AC-11a tie behaviour is implementation-defined).
	table.sort(candidates, function(a, b)
		return a.distSq < b.distSq
	end)

	-- 4. Take first min(n, candidateCount) indices.
	local takeCount = math.min(n, candidateCount)
	local selected: { number } = table.create(takeCount)
	for i = 1, takeCount do
		selected[i] = candidates[i].index
	end
	return selected
end

return PeelSelection
