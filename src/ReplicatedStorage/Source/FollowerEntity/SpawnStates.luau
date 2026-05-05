--!strict

--[[
	SpawnStates.luau — Pure spawn-state machine math for FadeIn / SlideIn flows
	Implements: TR-follower-entity-004 (4/frame throttle — see SpawnThrottleQueue)
	            TR-follower-entity-010 (d_init random phase)
	            TR-follower-entity-012 (white-state SlideIn frame 1)
	            TR-follower-entity-019 (Absorb slide-in lerp)
	GDD:        design/gdd/follower-entity.md §Spawn Triggers + §States and Transitions
	ADR:        ADR-0007 §Three-Module Split (FollowerEntityClient owns spawn state arrays)
	Story:      production/epics/follower-entity/story-005-spawn-states-throttle.md

	DESIGN CONSTRAINTS (ADR-0007 §Boids Loop Discipline — forbidden inside RenderStepped):
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast

	This module is deliberately isolated from all Roblox service dependencies.
	All inputs (number, Vector3, Color3) are plain Luau values. `math.random` is
	OPTIONAL — callers that need determinism (tests) inject a random function.

	Two state flows (per GDD §Spawn Triggers):
	  - Spawning:FadeIn  — alpha tween 1→0 over SPAWN_FADE_DURATION; boids RUNS
	  - Spawning:SlideIn — CFrame lerp npcLastPos→crowd_center over SPAWN_SLIDE_DURATION;
	                       boids SUSPENDED; frame 1 white, frame 2+ absorber hue
--]]

local SpawnStates = {}

-- ---------------------------------------------------------------------------
-- Module-level constant: white color for SlideIn frame 1 (TR-follower-entity-012).
-- GDD §AC-24: frame 1 of SlideIn → Body.Color == Color3.new(1, 1, 1).
-- Defined once at module level to avoid per-call Color3.new allocation.
-- ---------------------------------------------------------------------------

local WHITE_COLOR = Color3.new(1, 1, 1)

-- ---------------------------------------------------------------------------
-- 1. randomDInit — per-spawn d initial phase
-- GDD §`d_init` random per spawn: _d[i] = random() * (1 / WALK_FREQ_HZ)
--                                  ∈ [0, 0.667) when WALK_FREQ_HZ = 1.5
-- ---------------------------------------------------------------------------

--- Returns a fresh random initial value for a follower's `_d[i]` distance accumulator.
--- Range is `[0, 1/walkFreqHz)` — exactly one walk-bob period at the configured frequency.
--- Story §AC: "no value exactly 0" is statistically vanishingly rare for `math.random()`
--- which never returns 0 (returns floats in (0, 1)) — but caller may filter if needed.
---
--- @param walkFreqHz  number     — from FollowerVisualConfig.WALK_FREQ_HZ (cycles per stud)
--- @param randFn      ()->number? — optional injected random source for determinism (tests)
--- @return number — _d[i] initial value ∈ [0, 1/walkFreqHz)
function SpawnStates.randomDInit(walkFreqHz: number, randFn: (() -> number)?): number
	local r = if randFn ~= nil then randFn() else math.random()
	return r * (1 / walkFreqHz)
end

-- ---------------------------------------------------------------------------
-- 2. randomSwayPhaseOffset — per-spawn sway phase
-- Story §`_swayPhaseOffset[i]` random per spawn: math.random() * 2π
--                                                 ∈ [0, 2π)
-- ---------------------------------------------------------------------------

--- Returns a fresh random sway phase offset for a follower.
--- Range is `[0, 2π)` — one full F9 micro-sway period.
--- Per-follower distinct phase prevents synchronised metronome lockstep across crowd.
---
--- @param randFn  ()->number? — optional injected random source for determinism (tests)
--- @return number — _swayPhaseOffset[i] initial value ∈ [0, 2π)
function SpawnStates.randomSwayPhaseOffset(randFn: (() -> number)?): number
	local r = if randFn ~= nil then randFn() else math.random()
	return r * 2 * math.pi
end

-- ---------------------------------------------------------------------------
-- 3. computeFadeInTransparency — alpha tween 1 → 0 over SPAWN_FADE_DURATION
-- GDD §AC-19: FadeIn alpha 1→0 over 0.3 s.
-- ---------------------------------------------------------------------------

--- Computes the linear-interpolated transparency value for a FadeIn-state follower.
--- t=0 → 1.0 (fully transparent); t=duration → 0.0 (fully opaque).
--- Clamped at both ends so callers can blindly pass elapsed without bounds-checking.
---
--- @param elapsed   number — time since FadeIn began (seconds)
--- @param duration  number — total tween duration (FollowerVisualConfig.SPAWN_FADE_DURATION)
--- @return number — Transparency to write to BasePart, ∈ [0, 1]
function SpawnStates.computeFadeInTransparency(elapsed: number, duration: number): number
	if elapsed <= 0 then
		return 1.0
	end
	if elapsed >= duration then
		return 0.0
	end
	-- Linear lerp from 1 → 0 over [0, duration]
	return 1.0 - (elapsed / duration)
end

-- ---------------------------------------------------------------------------
-- 4. computeSlideInPosition — CFrame lerp npcLastPos → crowdCenter over SPAWN_SLIDE_DURATION
-- GDD §AC-16: SlideIn linear interpolation; clamps at endpoints.
-- ---------------------------------------------------------------------------

--- Computes the lerped Vector3 position for a SlideIn-state follower.
--- Linear interpolation from `npcLastPos` at t=0 to `crowdCenter` at t=duration.
--- Clamps at both ends so callers can pass arbitrary elapsed without bounds-checking.
---
--- The caller composes the final CFrame via `CFrame.new(returnedPosition)`; this
--- function returns Vector3 (not CFrame) because SlideIn does not rotate followers.
---
--- @param npcLastPos   Vector3 — initial position (where the absorbed NPC was)
--- @param crowdCenter  Vector3 — target position (current crowd center)
--- @param elapsed      number  — time since SlideIn began (seconds)
--- @param duration     number  — total slide duration (FollowerVisualConfig.SPAWN_SLIDE_DURATION)
--- @return Vector3 — interpolated position to write to Body.CFrame
function SpawnStates.computeSlideInPosition(
	npcLastPos: Vector3,
	crowdCenter: Vector3,
	elapsed: number,
	duration: number
): Vector3
	if elapsed <= 0 then
		return npcLastPos
	end
	if elapsed >= duration then
		return crowdCenter
	end
	local alpha = elapsed / duration
	-- Vector3:Lerp performs the same math; explicit `+ alpha * (b - a)` avoids
	-- a method-call dispatch — minor but in a 4/frame hot path adds up.
	return npcLastPos + (crowdCenter - npcLastPos) * alpha
end

-- ---------------------------------------------------------------------------
-- 5. isFadeInComplete / isSlideInComplete — terminal predicates
-- ---------------------------------------------------------------------------

--- Returns true when a FadeIn-state follower should transition to Active.
--- Complete iff `elapsed >= duration` (per GDD §State Machine Transitions).
function SpawnStates.isFadeInComplete(elapsed: number, duration: number): boolean
	return elapsed >= duration
end

--- Returns true when a SlideIn-state follower should transition to Active.
--- Complete iff `elapsed >= duration`. On transition, caller resumes boids
--- and initialises `_d[i]` and `_swayPhaseOffset[i]` (per Story Implementation Notes).
function SpawnStates.isSlideInComplete(elapsed: number, duration: number): boolean
	return elapsed >= duration
end

-- ---------------------------------------------------------------------------
-- 6. getSlideInBodyColor — frame-1 white vs frame-2+ absorber hue (AC-24)
-- GDD §AC-24: frame 1 → Color3.new(1,1,1); frame 2+ → HUE_COLORS[absorberHue].
-- ---------------------------------------------------------------------------

--- Returns the Body.Color value for a SlideIn-state follower based on the tick index.
--- tickIndex = 1 → white (TR-follower-entity-012); tickIndex >= 2 → absorberHueColor.
---
--- The caller increments `_slideTick[i]` from 1 each RenderStepped while in SlideIn.
--- Hat color is NOT modified here — it is skin-defined and writes only on initial
--- spawn from Skin System (per Story §Implementation Notes).
---
--- @param tickIndex          number — 1-based frame counter since SlideIn began
--- @param absorberHueColor   Color3 — HUE_COLORS[absorberHue] (lookup is caller's job)
--- @return Color3 — Color to write to Body.Color this frame
function SpawnStates.getSlideInBodyColor(tickIndex: number, absorberHueColor: Color3): Color3
	if tickIndex <= 1 then
		return WHITE_COLOR
	end
	return absorberHueColor
end

return SpawnStates
