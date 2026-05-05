--!strict

--[[
	PeelTransit.luau — Pure peel transit timing + hue-flip latch math
	Implements: TR-follower-entity-007 (>= threshold-crossing latch, no float equality)
	            TR-follower-entity-014 (PEEL_MAX_DURATION cap)
	            TR-follower-entity-018 (hat retained through peel — caller-enforced)
	GDD:        design/gdd/follower-entity.md §F7 + §Hue-flip Timing + §Edge Cases
	ADR:        ADR-0007 §Three-Module Split (FollowerEntityClient owns transit state arrays)
	Story:      production/epics/follower-entity/story-008-peel-transit-hue-flip.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	`os.clock()` is supplied as `elapsed` argument by the caller.

	FLOAT EQUALITY FORBIDDEN (TR-follower-entity-007):
	  At 60 FPS, frame boundaries do NOT land exactly on `T_hue_flip`. Code that
	  writes `if elapsed == T_hue_flip` is broken — the flip never fires.
	  This module exposes ONLY `>=` threshold-crossing predicates with boolean
	  latch parameters; callers cannot accidentally float-equality their way
	  into a missed flip. Verifiable via grep audit in code-review skill.

	HUE-FLIP LATCH:
	  Once `_hueFlipApplied[i] = true`, `shouldFlipHue` returns false even if
	  `elapsed >= T_hue_flip` continues to be true. Caller MUST initialise the
	  latch to false at startPeel and pass the current value each frame.
--]]

local PeelTransit = {}

export type TransitParams = {
	dPeel: number,        -- ‖P_start - rival_center‖ at startPeel call
	tPeel: number,        -- min(dPeel / peelSpeed, maxDuration)
	tHueFlip: number,     -- tPeel * 0.5
	isCapped: boolean,    -- true ↔ dPeel > peelSpeed * maxDuration → CFrame-snap on arrival
}

-- ---------------------------------------------------------------------------
-- 1. computeTransitParams — F7 timing math at startPeel call time
-- GDD §F7: T_peel = min(d_peel / PEEL_SPEED, PEEL_MAX_DURATION); T_hue_flip = T_peel * 0.5
-- ---------------------------------------------------------------------------

--- Computes the per-follower transit parameters at the moment of startPeel.
--- Returns a struct that the caller stores in parallel arrays:
---   `_d_peel[i] = result.dPeel`
---   `_T_peel[i] = result.tPeel`
---   `_T_hue_flip[i] = result.tHueFlip`
--- and uses `result.isCapped` to know whether to CFrame-snap on arrival.
---
--- d_peel == 0 case (instant arrival): tPeel = 0, tHueFlip = 0; caller's
--- `shouldFlipHue` and `isArrived` predicates both return true on the first
--- per-frame call, so the flip fires immediately and the despawn dispatches
--- the same frame.
---
--- @param startPos     Vector3 — follower position at startPeel
--- @param rivalCenter  Vector3 — cached rival crowd_center at startPeel
--- @param peelSpeed    number  — FollowerVisualConfig.PEEL_SPEED
--- @param maxDuration  number  — FollowerVisualConfig.PEEL_MAX_DURATION
--- @return TransitParams
function PeelTransit.computeTransitParams(
	startPos: Vector3,
	rivalCenter: Vector3,
	peelSpeed: number,
	maxDuration: number
): TransitParams
	local diff = startPos - rivalCenter
	local dPeel = diff.Magnitude

	-- F7 cap: long-distance peels clamp at maxDuration to bound transit time.
	local uncappedT = dPeel / peelSpeed
	local tPeel = math.min(uncappedT, maxDuration)
	local isCapped = uncappedT > maxDuration

	return {
		dPeel = dPeel,
		tPeel = tPeel,
		tHueFlip = tPeel * 0.5,
		isCapped = isCapped,
	}
end

-- ---------------------------------------------------------------------------
-- 2. shouldFlipHue — threshold-crossing predicate with mandatory latch
-- TR-follower-entity-007: MUST use >=; float equality forbidden.
-- ---------------------------------------------------------------------------

--- Returns true iff the per-follower hue flip should fire THIS frame.
--- Caller's per-frame contract:
---   if PeelTransit.shouldFlipHue(elapsed, tHueFlip, _hueFlipApplied[i]) then
---     Body.Color = HUE_COLORS[rivalHue]
---     _hueFlipApplied[i] = true
---     VFXManager.playEffect(VFXEffect.HueShift, Body.CFrame)
---   end
---
--- The latch is mandatory: without it, every frame after `T_hue_flip` would
--- fire the flip + VFX (story §AC-5 requires "exactly once per follower per peel").
---
--- @param elapsed              number  — os.clock() - _peelStart[i]
--- @param tHueFlip             number  — _T_hue_flip[i] (= T_peel * 0.5)
--- @param hueFlipAlreadyApplied boolean — _hueFlipApplied[i] from previous frame
--- @return boolean — true if flip should fire this frame
function PeelTransit.shouldFlipHue(
	elapsed: number,
	tHueFlip: number,
	hueFlipAlreadyApplied: boolean
): boolean
	if hueFlipAlreadyApplied then
		return false
	end
	return elapsed >= tHueFlip
end

-- ---------------------------------------------------------------------------
-- 3. isArrived — terminal predicate for despawn / rival-side spawn dispatch
-- ---------------------------------------------------------------------------

--- Returns true iff the follower has reached arrival (`elapsed >= tPeel`).
--- Caller's per-frame contract:
---   if PeelTransit.isArrived(elapsed, tPeel) then
---     -- 1. If isCapped, snap Body.CFrame.Position to rivalCenter (no lerp)
---     -- 2. Despawn from own pool; transition state to Despawning
---     -- 3. Fire rival-side spawn (FadeIn) on rival crowd's FollowerEntityClient
---   end
---
--- @param elapsed  number — os.clock() - _peelStart[i]
--- @param tPeel    number — _T_peel[i] (capped by PEEL_MAX_DURATION)
--- @return boolean
function PeelTransit.isArrived(elapsed: number, tPeel: number): boolean
	return elapsed >= tPeel
end

-- ---------------------------------------------------------------------------
-- 4. computeFLeadTarget — picks rivalCenter or own-crowd center for boids F_lead retarget
-- AC-22: rival nil mid-peel → switch to own-crowd center; no rival-side spawn.
-- ---------------------------------------------------------------------------

--- Returns the boids `F_lead` target for a Peeling follower this frame.
--- During normal transit: rivalRecord is non-nil → returns its position
--- (cached locally for the next-frame fallback).
--- Rival-nil abort path: rivalRecord is nil → returns ownCrowdCenter; caller
--- sets `_peelAborted[i] = true` and treats arrival as `Active` (not Despawning).
---
--- @param rivalRecordPosition  Vector3?  — CrowdStateClient.get(rivalCrowdId).position, or nil
--- @param cachedRivalCenter    Vector3   — _rivalCenterCached[i] from last successful read
--- @param ownCrowdCenter       Vector3   — own crowd_center for abort fallback
--- @return Vector3, boolean — (target, isAborted)
function PeelTransit.computeFLeadTarget(
	rivalRecordPosition: Vector3?,
	cachedRivalCenter: Vector3,
	ownCrowdCenter: Vector3
): (Vector3, boolean)
	if rivalRecordPosition == nil then
		-- AC-22: rival eliminated mid-peel → abort, retarget to own crowd
		return ownCrowdCenter, true
	end
	-- Normal transit: refresh cache and use latest rival center
	-- (cachedRivalCenter param unused on the happy path; caller refreshes it
	-- from rivalRecordPosition. Kept in the signature so the caller's
	-- _rivalCenterCached update is explicit at the boundary.)
	local _ = cachedRivalCenter
	return rivalRecordPosition, false
end

-- ---------------------------------------------------------------------------
-- 5. resolveAbortArrivalState — terminal-state decision for rival-nil abort
-- AC-22: on arrival at own-crowd center after rival-nil abort, state → Active
--        (NOT Despawning); pool slot retained; no rival-side spawn.
-- Edge case: own crowd ALSO nil at abort → Despawning (Story 002 path).
-- ---------------------------------------------------------------------------

--- Returns the follower's terminal state on arrival, given abort context.
--- Returns:
---   "Active"     — rival aborted, own crowd present → recover to Active
---   "Despawning" — rival aborted AND own crowd also nil → terminal despawn
---   nil          — not yet aborted; caller proceeds with normal arrival path
---                  (Despawning + rival-side FadeIn)
---
--- @param peelAborted   boolean  — _peelAborted[i] flag
--- @param ownCrowdNil   boolean  — true ↔ CrowdStateClient.get(own crowdId) == nil
--- @return string?
function PeelTransit.resolveAbortArrivalState(
	peelAborted: boolean,
	ownCrowdNil: boolean
): string?
	if not peelAborted then
		return nil
	end
	if ownCrowdNil then
		return "Despawning"
	end
	return "Active"
end

return PeelTransit
