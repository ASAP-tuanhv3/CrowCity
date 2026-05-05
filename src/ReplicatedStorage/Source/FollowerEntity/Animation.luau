--!strict

--[[
	Animation.luau — Pure animation math for F8 walk-bob + F9 micro-sway
	Implements: TR-follower-entity-005 (F8 walk-bob)
	            TR-follower-entity-006 (d continuity across LOD)
	            TR-follower-entity-017 (F9 micro-sway)
	GDD:        design/gdd/follower-entity.md §F8-F9 Formulas (lines 226-275)
	ADR:        ADR-0007 §Boids Loop Discipline + §Three-Module Split
	Story:      production/epics/follower-entity/story-004-walk-bob-microsway.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	All inputs (number, Vector3) are plain Luau values. `os.clock()` is supplied
	as an argument by the caller (Client.luau) — NOT read inside this module —
	so tests can inject deterministic time.

	All 5 animation knobs are passed as function arguments (not hard-coded).
	Callers supply them from SharedConstants/FollowerVisualConfig. Tests may pass
	inline literal values for isolation.
--]]

local Animation = {}

-- ---------------------------------------------------------------------------
-- F8a. update_d (distance accumulator with standstill freeze)
-- GDD §F8: d accumulates travel distance; standstill freeze prevents idle drift.
--          AC-3: |d_delta| < THRESHOLD → do NOT accumulate; isStandstill = true.
-- ---------------------------------------------------------------------------

--- Updates the per-follower distance accumulator `d` and standstill flag.
--- Returns the new `d` value and a boolean isStandstill.
--- If `dDelta` (this frame's travel) is below the threshold, `d` is NOT
--- accumulated (returned unchanged) and isStandstill is true. Otherwise `d`
--- is incremented by `dDelta` and isStandstill is false.
---
--- @param d                    number — Previous accumulated distance
--- @param dDelta               number — This frame's travel distance (studs)
--- @param standstillThreshold  number — Threshold below which follower is "still"
--- @return number, boolean — (new d, isStandstill)
function Animation.updateD(
	d: number,
	dDelta: number,
	standstillThreshold: number
): (number, boolean)
	if math.abs(dDelta) < standstillThreshold then
		return d, true
	end
	return d + dDelta, false
end

-- ---------------------------------------------------------------------------
-- F8b. compute_walk_bob_y (Y offset)
-- GDD §F8: y_bob = abs(sin(d * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP
-- ---------------------------------------------------------------------------

--- Computes the F8 walk-bob Y offset from accumulated distance `d`.
--- Pure formula: `abs(sin(d × 2π × walkFreqHz)) × walkBobAmp`.
--- The `abs` produces a hopping bounce (always non-negative Y offset).
---
--- @param d            number — Accumulated travel distance (studs)
--- @param walkFreqHz   number — Cycles per stud (from FollowerVisualConfig)
--- @param walkBobAmp   number — Peak Y offset in studs (from FollowerVisualConfig)
--- @return number — Y offset to add to Root_target.Y (studs)
function Animation.computeWalkBobY(
	d: number,
	walkFreqHz: number,
	walkBobAmp: number
): number
	return math.abs(math.sin(d * 2 * math.pi * walkFreqHz)) * walkBobAmp
end

-- ---------------------------------------------------------------------------
-- F9. compute_micro_sway_x (X offset, standstill only, LOD 0 only)
-- GDD §F9: micro_sway_x = sin(t * 2π * MICRO_SWAY_FREQ_HZ + phase) * MICRO_SWAY_AMP
--          AC-21 / AC-26: applies ONLY at LOD 0 + standstill; zero otherwise.
-- ---------------------------------------------------------------------------

--- Computes the F9 micro-sway X offset for a standstill follower at LOD 0.
--- Returns zero if not standstill OR if not at LOD 0 (AC-21, AC-26).
--- Time-based (uses caller-supplied `t` from `os.clock()`); per-follower
--- `phaseOffset` prevents synchronised lockstep across the crowd.
---
--- @param isStandstill  boolean — From updateD; sway only when true
--- @param lodTier       number  — 0 = full anim, 1/2 = suppressed
--- @param t             number  — Current time (caller passes os.clock())
--- @param phaseOffset   number  — Per-follower phase ∈ [0, 2π); from spawn init
--- @param swayFreqHz    number  — Time-based frequency (FollowerVisualConfig)
--- @param swayAmp       number  — Peak X offset in studs (FollowerVisualConfig)
--- @return number — X offset to add to Root_target.X (studs); 0 when suppressed
function Animation.computeMicroSwayX(
	isStandstill: boolean,
	lodTier: number,
	t: number,
	phaseOffset: number,
	swayFreqHz: number,
	swayAmp: number
): number
	-- AC-21: only at LOD 0. AC-26: bob/sway suppressed at LOD 1/2.
	if lodTier ~= 0 then
		return 0
	end
	-- F9 applies only at standstill (movement uses F8 instead).
	if not isStandstill then
		return 0
	end
	return math.sin(t * 2 * math.pi * swayFreqHz + phaseOffset) * swayAmp
end

-- ---------------------------------------------------------------------------
-- Composite. compose_body_cframe
-- GDD §F8/§F9: Body.CFrame = Root_target * CFrame.new(micro_sway_x, y_bob, 0)
--              At LOD 1/2: Body.CFrame = Root_target (no offset applied).
--              `_d` accumulates regardless of LOD (TR-follower-entity-006 continuity).
-- ---------------------------------------------------------------------------

--- Composes the final Body.CFrame from the F4 root target plus F8/F9 offsets.
--- At LOD 1 / LOD 2: returns rootTarget unchanged (AC-26 — bob/sway suppressed).
--- At LOD 0: applies `CFrame.new(microSwayX, yBob, 0)` as a local offset.
---
--- During movement (`isStandstill == false`):
---   - yBob is the live F8 output
---   - microSwayX is 0 (F9 suppressed during movement, AC-21)
---
--- During standstill (`isStandstill == true`):
---   - yBob is the FROZEN last value (caller passes `_lastYBob[i]`)
---   - microSwayX is the live F9 output
---
--- @param rootTarget    CFrame  — F4 boids output root position+rotation
--- @param yBob          number  — Live F8 output OR frozen `_lastYBob[i]`
--- @param microSwayX    number  — F9 output (0 if not standstill or LOD ~= 0)
--- @param lodTier       number  — 0 / 1 / 2
--- @return CFrame — Final Body.CFrame to write
function Animation.composeBodyCFrame(
	rootTarget: CFrame,
	yBob: number,
	microSwayX: number,
	lodTier: number
): CFrame
	-- AC-26: at LOD 1/2 the bob/sway offsets are suppressed entirely.
	if lodTier ~= 0 then
		return rootTarget
	end
	return rootTarget * CFrame.new(microSwayX, yBob, 0)
end

return Animation
