--!strict

--[[
	LODTierMath.luau — Pure F5 LOD-tier math + teleport detection
	Implements: TR-follower-entity-015 (LOD render caps 80/30/15/1)
	            TR-follower-entity-016 (TELEPORT_THRESHOLD = 30 stud snap)
	            TR-follower-entity-006 (d preservation across LOD swap — invariant)
	GDD:        design/gdd/follower-entity.md §F5 + §AC-13/14 + §Edge Cases (player teleport)
	ADR:        ADR-0007 + ADR-0001 (LOD render caps + tier numbering 0/1/2/CULL)
	Story:      production/epics/follower-entity/story-010-lod-tier-swap-teleport.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	NOTE on "no distance math against camera": this module's `computeTier` accepts
	a pre-computed distance value as a SCALAR — it does NOT read camera state.
	The actual `Camera.CFrame.Position - crowd_center).Magnitude` computation
	lives in FollowerLODManager (sibling system, not this epic) which runs at
	10 Hz, OUTSIDE RenderStepped.

	TIER NUMBERING (ADR-0001 + ADR-0007 §LOD Tier Render Specs):
	  0    — full fidelity (Body + Hat parts; F4 + F8/F9 active)
	  1    — simplified primitive (single Part; F4 active; F8/F9 suppressed)
	  2    — billboard impostor (single anchored Part per crowd; F4 suppressed)
	  CULL — not a fourth tier value; signalled via setPoolSize(crowdId, 0)
--]]

local LODTierMath = {}

-- Tier label constants. Returned as strings to match GDD §F5 tier nomenclature.
-- Numeric tier 0/1/2 + sentinel "CULL" string for the > LOD_TIER_2_MAX case.
LODTierMath.TIER_0    = "0"
LODTierMath.TIER_1    = "1"
LODTierMath.TIER_2    = "2"
LODTierMath.TIER_CULL = "CULL"

export type Tier = "0" | "1" | "2" | "CULL"

-- ---------------------------------------------------------------------------
-- 1. computeTier — F5 distance → tier mapping
-- GDD §AC-13a: [0, 20] → 0; (20, 40] → 1; (40, 100] → 2; > 100 → CULL
-- ---------------------------------------------------------------------------

--- Returns the LOD tier for a given camera-to-crowd distance.
--- Boundaries are closed-on-the-low-end (e.g., d == 20 → tier 0; d == 20.1 → tier 1)
--- per GDD §AC-13a explicit example `[0, 20, 20.1, 40, 40.1, 100, 100.1] →
--- [0, 0, 1, 1, 2, 2, CULL]`.
---
--- Hysteresis (±1 stud per LOD GDD §F2) is OUT OF SCOPE for this module —
--- handled by FollowerLODManager (sibling system) before calling this.
---
--- Negative distances are not expected (camera math always produces non-negative
--- distance). Treated as tier 0 defensively (consistent with `d <= LOD_TIER_0_MAX`).
---
--- @param distance        number — camera-to-crowd Magnitude (caller-computed)
--- @param tier0Max        number — FollowerVisualConfig.LOD_TIER_0_MAX (20)
--- @param tier1Max        number — FollowerVisualConfig.LOD_TIER_1_MAX (40)
--- @param tier2Max        number — FollowerVisualConfig.LOD_TIER_2_MAX (100)
--- @return Tier — "0" | "1" | "2" | "CULL"
function LODTierMath.computeTier(
	distance: number,
	tier0Max: number,
	tier1Max: number,
	tier2Max: number
): Tier
	if distance <= tier0Max then
		return LODTierMath.TIER_0
	elseif distance <= tier1Max then
		return LODTierMath.TIER_1
	elseif distance <= tier2Max then
		return LODTierMath.TIER_2
	end
	return LODTierMath.TIER_CULL
end

-- ---------------------------------------------------------------------------
-- 2. shouldTeleportSnap — strict-greater-than threshold check
-- GDD §AC-14 + TR-follower-entity-016: delta > THRESHOLD triggers snap;
--   delta == THRESHOLD does NOT trigger (strict >, not >=).
-- ---------------------------------------------------------------------------

--- Returns true iff the crowd_center delta between frames exceeds the teleport
--- threshold and a one-frame CFrame-snap should be applied (skipping boids).
---
--- Strict greater-than per AC-14 explicit edge case: "delta exactly == 30 →
--- no snap (`>`, not `>=`); delta == 31 → snap fires."
---
--- @param currentCenter   Vector3 — this frame's crowd_center
--- @param lastCenter      Vector3 — last frame's crowd_center
--- @param threshold       number  — FollowerVisualConfig.TELEPORT_THRESHOLD (30)
--- @return boolean
function LODTierMath.shouldTeleportSnap(
	currentCenter: Vector3,
	lastCenter: Vector3,
	threshold: number
): boolean
	local diff = currentCenter - lastCenter
	-- Use squared magnitude to avoid sqrt — equivalent ordering for comparison.
	local distSq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z
	return distSq > (threshold * threshold)
end

-- ---------------------------------------------------------------------------
-- 3. computeTeleportSnapPositions — bulk reposition followers around new center
-- GDD §AC-14: each follower's new pos = currentCenter + spawnOffset[i]
-- ---------------------------------------------------------------------------

--- Returns a fresh array of post-teleport positions: `currentCenter + spawnOffsets[i]`.
--- The caller writes these to `_positions[i]` and `_parts[i].CFrame = CFrame.new(pos)`.
---
--- Allocates a new array — caller-owned. Does not mutate inputs.
---
--- @param currentCenter   Vector3    — post-teleport crowd_center
--- @param spawnOffsets    { Vector3 } — `_spawnOffsets[i]` per follower (recorded at spawn)
--- @return { Vector3 } — new positions array of same length as spawnOffsets
function LODTierMath.computeTeleportSnapPositions(
	currentCenter: Vector3,
	spawnOffsets: { Vector3 }
): { Vector3 }
	local n = #spawnOffsets
	local positions: { Vector3 } = table.create(n)
	for i = 1, n do
		positions[i] = currentCenter + spawnOffsets[i]
	end
	return positions
end

-- ---------------------------------------------------------------------------
-- 4. shouldRenderF4 — boids gate by tier
-- ADR-0007 §LOD Tier Render Specs: F4 active at tier 0 + 1; suppressed at 2.
-- ---------------------------------------------------------------------------

--- Returns true iff F4 boids math should run for a follower at the given tier.
--- Encodes the rendering policy from ADR-0007 §LOD Tier Render Specs:
---   tier 0 → run F4 (full fidelity)
---   tier 1 → run F4 (simplified primitive still uses boids motion)
---   tier 2 → suppress F4 (billboard impostor anchored at crowd_center)
---
--- @param tier  Tier
--- @return boolean
function LODTierMath.shouldRenderF4(tier: Tier): boolean
	return tier == LODTierMath.TIER_0 or tier == LODTierMath.TIER_1
end

-- ---------------------------------------------------------------------------
-- 5. shouldRenderBob (F8) — gated by tier 0 only (consistent with Story 4-4 AC-26)
-- ---------------------------------------------------------------------------

--- Returns true iff F8 walk-bob should be applied at the given tier.
--- Per Story 4-4 AC-26: F8 + F9 are LOD-0 only.
function LODTierMath.shouldRenderBob(tier: Tier): boolean
	return tier == LODTierMath.TIER_0
end

return LODTierMath
