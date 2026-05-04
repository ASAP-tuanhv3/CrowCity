--!strict

--[[
	Rig.luau
	Pure helper module — no instance state, no connections.
	Implements: design/gdd/follower-entity.md §C.1 (2-Part rig assembly)
	ADR: ADR-0007 §Pool Allocation Strategy

	Responsibilities:
	  - Clone Body + optional Hat from caller-supplied templates
	  - Apply required Part flags (Anchored, CanCollide = false, etc.)
	  - Position Hat via WeldConstraint parented under Body (Roblox requirement:
	    constraint must be parented under one of its constrained Parts to be active)
	  - Generate per-follower walk-phase offset (d_init)

	Out of scope for this module:
	  - Pool management (Pool.luau)
	  - Hue writes (Story 006)
	  - Spawn state / transparency tweens (Story 005)
	  - Any RBXScriptConnection (caller owns lifecycle)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FollowerPoolConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerPoolConfig)

local WALK_FREQ_HZ: number = FollowerPoolConfig.WALK_FREQ_HZ

-- Maximum phase offset (exclusive upper bound): 1 / WALK_FREQ_HZ studs.
-- GDD §F8: d_init ∈ [0, 1/WALK_FREQ_HZ). Must never be exactly 0.
local PHASE_MAX: number = 1 / WALK_FREQ_HZ

-- --------------------------------------------------------------------------
-- Types
-- --------------------------------------------------------------------------

--- The bundle returned by Rig.assemble.
--- body  — the primary CFrame-driven Part (Anchored, pool-parked when inactive).
--- hat   — optional hat Part, welded under body. Nil when hatTemplate is nil.
--- weld  — the WeldConstraint(Part0=body, Part1=hat), parented under body.
---          Nil when hat is nil.
export type RigBundle = {
	body: BasePart,
	hat: BasePart?,
	weld: WeldConstraint?,
}

-- --------------------------------------------------------------------------
-- Part flag helpers
-- --------------------------------------------------------------------------

-- Applies all required pool-entry flags per ADR-0007 §Pool Allocation Strategy
-- (mobile thermal protection: Anchored, no collision, no shadow, parked off-screen).
local function applyPoolFlags(part: BasePart)
	part.Anchored       = true
	part.CanCollide     = false
	part.CanQuery       = false
	part.CanTouch       = false
	part.CastShadow     = false
	part.Transparency   = 1
	part.Position       = Vector3.new(0, -1000, 0)
end

-- --------------------------------------------------------------------------
-- Public API
-- --------------------------------------------------------------------------

local Rig = {}

--- Assembles a 2-Part (or 1-Part body-only) follower rig.
---
--- @param bodyTemplate  BasePart   — clone source for the body.
--- @param hatTemplate   BasePart?  — clone source for the hat; nil → body-only rig (AC-6).
--- @param headOffsetY   number     — Y offset of hat CFrame relative to body (studs).
--- @param parent        Instance   — folder to parent assembled Parts into (e.g., _FollowerPool).
--- @return RigBundle
function Rig.assemble(
	bodyTemplate: BasePart,
	hatTemplate: BasePart?,
	headOffsetY: number,
	parent: Instance
): RigBundle
	-- Clone body from template; apply flags + park.
	local body: BasePart = bodyTemplate:Clone()
	body.Name = "Body"
	applyPoolFlags(body)
	body.Parent = parent

	if hatTemplate == nil then
		-- Body-only rig (AC-6: hat template missing).
		return {
			body = body,
			hat  = nil,
			weld = nil,
		}
	end

	-- Clone hat; apply same flags; position relative to body.
	local hat: BasePart = (hatTemplate :: BasePart):Clone()
	hat.Name = "Hat"
	applyPoolFlags(hat)
	-- Position hat at head offset relative to body's parked location.
	-- This CFrame is cosmetic — it mirrors the body's parked-off-screen location
	-- plus the head offset. At grant time the caller drives position via boids.
	hat.CFrame = body.CFrame * CFrame.new(0, headOffsetY, 0)

	-- WeldConstraint: Part0=body, Part1=hat.
	-- MUST be parented under one of its constrained Parts to be active in Roblox.
	-- We parent under body so hat cleanup is automatic when body is destroyed.
	local weld: WeldConstraint = Instance.new("WeldConstraint")
	weld.Name = "HatWeld"
	weld.Part0 = body
	weld.Part1 = hat
	weld.Parent = body  -- parented under body per GDD §C.1 + AC-1

	-- Hat parented under body so it is destroyed automatically with its body.
	hat.Parent = body

	return {
		body = body,
		hat  = hat,
		weld = weld,
	}
end

--- Generates a per-follower walk-phase offset.
--- Range: (0, 1/WALK_FREQ_HZ) — strictly > 0 per AC-1e.
--- GDD §F8: "each follower initializes d = math.random() * (1 / WALK_FREQ_HZ),
---   a random phase in [0, 0.667). Do NOT reset on despawn/respawn; re-randomize
---   each time."
--- Re-roll if result is exactly 0 (probability = 0 on IEEE-754 float, but the
--- spec requires non-zero so we guard explicitly.
--- @return number — d_init ∈ (0, PHASE_MAX)
function Rig.initWalkPhase(): number
	local d: number
	-- Guard: re-roll on exact zero. In practice math.random() on Luau VM
	-- never produces exactly 0.0, but the spec mandates non-zero (AC-1e).
	repeat
		d = math.random() * PHASE_MAX
	until d > 0
	return d
end

return Rig
