--!strict

--[[
	HueReconciler.luau — Pure dirty-flag + reconciliation-timer logic for crowd hue
	Implements: TR-follower-entity-011 (Color3 write; dirty flag gates steady-state writes)
	GDD:        design/gdd/follower-entity.md §Hue Application + §Cross-system Constraints
	ADR:        ADR-0007 §Three-Module Split (FollowerEntityClient owns _currentHue cache)
	Story:      production/epics/follower-entity/story-006-hue-dirty-flag.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	State (currentHue, mismatchFrames) is owned by FollowerEntityClient and passed
	in/out by value each frame.

	DIRTY-FLAG vs RECONCILIATION:
	  The dirty flag is the fast path: skip per-follower Body.Color writes when
	  currentHue == targetHue. With 80 followers and 60 Hz this saves ~4800 writes
	  per second per crowd in steady state.

	  The reconciliation timer is the safety net: if a bug ever short-circuits
	  the dirty-flag comparator AND the actual values diverge silently (e.g.,
	  dropped CrowdStateBroadcast event), the counter accumulates frames in this
	  state and forces a write at HUE_RECONCILE_FRAMES.

	  In normal operation, the comparator and actual-equality always agree, the
	  counter never increments past 0, and reconciliation is a no-op.
--]]

local HueReconciler = {}

-- ---------------------------------------------------------------------------
-- evaluate — single-frame decision: write hue or skip?
--
-- INPUTS (all pure values; caller owns state):
--   currentHue            — last applied hue index, or nil if never written
--   targetHue             — current crowd hue index from CrowdStateClient
--   mismatchFrames        — previous frame's counter value (>= 0)
--   reconcileThreshold    — HUE_RECONCILE_FRAMES (typically 4)
--   dirtyFlagSaysMatched  — comparator's view (production: currentHue == targetHue;
--                           tests may simulate buggy short-circuit)
--
-- OUTPUTS (caller writes back to FollowerEntityClient state):
--   shouldWrite        — true → caller iterates followers and sets Body.Color
--   newCurrentHue      — value to store in _currentHue (always = targetHue when
--                        shouldWrite, else currentHue unchanged)
--   newMismatchFrames  — value to store in _hueMismatchFrames
-- ---------------------------------------------------------------------------

--- Computes the next hue-update decision. Pure function — no side effects.
--- See module-header DIRTY-FLAG vs RECONCILIATION section for the contract.
---
--- Truth table (assuming dirtyFlagSaysMatched defaults to currentHue == targetHue):
---
---   | currentHue | targetHue | dirtyFlag | mismatchFrames | shouldWrite | newCH | newMF |
---   |------------|-----------|-----------|----------------|-------------|-------|-------|
---   | nil        | 8         | false     | 0              | true        | 8     | 0     |
---   | 5          | 8         | false     | 0              | true        | 8     | 0     |
---   | 8          | 8         | true      | 0              | false       | 8     | 0     |
---   | 5          | 8         | true*     | 3              | true (force)| 8     | 0     |
---   | 5          | 8         | true*     | 0              | false       | 5     | 1     |
---
--- * dirtyFlag=true while values differ ↔ buggy comparator short-circuit
function HueReconciler.evaluate(
	currentHue: number?,
	targetHue: number,
	mismatchFrames: number,
	reconcileThreshold: number,
	dirtyFlagSaysMatched: boolean
): (boolean, number, number)
	-- Fast path: comparator says different → write immediately, reset counter.
	if not dirtyFlagSaysMatched then
		return true, targetHue, 0
	end

	-- Comparator says matched. Check actual equality for the reconcile counter.
	local actuallyMatches = currentHue == targetHue
	if actuallyMatches then
		-- Steady state: skip write, counter stays 0.
		-- (currentHue is non-nil here because nil ~= any number, so this branch
		-- is only reached when both are equal numbers.)
		return false, currentHue :: number, 0
	end

	-- Buggy state: comparator short-circuited but values differ silently.
	local newMF = mismatchFrames + 1
	if newMF >= reconcileThreshold then
		-- Force-write threshold reached — resync and reset counter.
		return true, targetHue, 0
	end
	-- Wait for threshold; preserve currentHue value as-is. currentHue is non-nil
	-- here because nil ~= targetHue (any number), so dirtyFlag=true with nil
	-- currentHue is impossible under the production comparator. Tests that
	-- simulate this case should pass currentHue as a number, not nil.
	return false, currentHue :: number, newMF
end

-- ---------------------------------------------------------------------------
-- defaultDirtyFlag — convenience for callers using the production comparator
-- ---------------------------------------------------------------------------

--- Returns the standard dirty-flag value: true iff currentHue == targetHue.
--- Wraps Luau's `==` so callers using the standard comparator have a one-line
--- helper rather than inlining the comparison at every call site.
---
--- Treats nil currentHue as never-matched (always returns false), which forces
--- the first-frame write of any newly-spawned crowd.
function HueReconciler.defaultDirtyFlag(currentHue: number?, targetHue: number): boolean
	return currentHue == targetHue
end

return HueReconciler
