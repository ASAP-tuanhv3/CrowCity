--!strict

--[[
	DefaultSkin.luau
	MVP fallback skin templates per FE GDD §Provisional assumptions.
	Replaced by Skin System (VS-tier) when authored.

	Implements: design/gdd/follower-entity.md §Skin / assets edge case
	GDD note: "If SkinSystem.getHatTemplate(skin_id) returns nil: spawn Body-only rig."
	ADR: ADR-0007 §Pool Allocation Strategy (MVP fallback path)

	Source of truth for HEAD_OFFSET_Y and HUE_PALETTE_SIZE at this layer:
	  HEAD_OFFSET_Y re-exported from FollowerPoolConfig (single source of truth).
	  HUE_PALETTE_SIZE is a placeholder constant; see TODO below.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FollowerPoolConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerPoolConfig)

-- TODO: source HUE_PALETTE_SIZE from CrowdStateServer / Crowd State Manager
-- when the palette is exposed via its public API. For now, 8 is the placeholder
-- matching the game-concept colour palette size referenced in design docs.
local HUE_PALETTE_SIZE: number = 8

-- Re-export HEAD_OFFSET_Y from FollowerPoolConfig — that module owns the
-- single source of truth for this tuning knob (GDD §Tuning Knobs §Pool knobs).
local HEAD_OFFSET_Y: number = FollowerPoolConfig.HEAD_OFFSET_Y

-- --------------------------------------------------------------------------
-- Cached body template (clone source). Created once; never parented.
-- --------------------------------------------------------------------------
local _bodyTemplate: BasePart? = nil

local function getOrCreateBodyTemplate(): BasePart
	if _bodyTemplate then
		return _bodyTemplate :: BasePart
	end
	local part = Instance.new("Part")
	part.Name = "Body"
	part.Size = Vector3.new(2, 2, 2)
	part.Material = Enum.Material.Plastic
	-- Neutral grey so it doesn't visually confuse with crowd hue before assignment.
	part.BrickColor = BrickColor.new("Medium stone grey")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	-- Hidden off-frustum until pool grants it to a follower.
	part.Transparency = 1
	part.Position = Vector3.new(0, -1000, 0)
	_bodyTemplate = part
	return part
end

-- --------------------------------------------------------------------------
-- Cached hat templates per hue index. Created lazily; never parented.
-- Index 0 is the sentinel "no-hat" value used to exercise AC-6.
-- Indices [1, HUE_PALETTE_SIZE] return a valid hat template.
-- --------------------------------------------------------------------------
local _hatTemplates: { [number]: BasePart } = {}

local function getOrCreateHatTemplate(hueIndex: number): BasePart
	if _hatTemplates[hueIndex] then
		return _hatTemplates[hueIndex]
	end
	local hat = Instance.new("Part")
	hat.Name = "Hat"
	hat.Size = Vector3.new(1.5, 0.5, 1.5)
	hat.Material = Enum.Material.Plastic
	-- Distinct colour so the hat reads separately from the body in Studio view.
	hat.BrickColor = BrickColor.new("Bright red")
	hat.Anchored = true
	hat.CanCollide = false
	hat.CanQuery = false
	hat.CanTouch = false
	hat.CastShadow = false
	hat.Transparency = 1
	hat.Position = Vector3.new(0, -1000, 0)
	_hatTemplates[hueIndex] = hat
	return hat
end

-- --------------------------------------------------------------------------
-- Public API
-- --------------------------------------------------------------------------

--- Returns a cloned BasePart suitable as a follower Body.
--- The returned Part is NOT parented; caller is responsible for parenting.
--- @param hueIndex number — crowd hue index (unused in MVP; template is hue-neutral)
local function getBodyTemplate(_hueIndex: number): BasePart
	return getOrCreateBodyTemplate():Clone()
end

--- Returns a cloned BasePart hat template for valid hue indices [1, HUE_PALETTE_SIZE].
--- Returns nil for hueIndex == 0 (sentinel — triggers the AC-6 body-only path).
--- The returned Part is NOT parented; caller is responsible for parenting.
--- @param hueIndex number — hue palette index; 0 = no-hat sentinel
local function getHatTemplate(hueIndex: number): BasePart?
	-- Sentinel: index 0 means "no hat" — exercises the nil branch in Pool.grantBundle.
	if hueIndex <= 0 then
		return nil
	end
	-- Out-of-range indices also return nil (future-proofing; palette may expand).
	if hueIndex > HUE_PALETTE_SIZE then
		return nil
	end
	return getOrCreateHatTemplate(hueIndex):Clone()
end

return {
	getBodyTemplate  = getBodyTemplate,
	getHatTemplate   = getHatTemplate,
	HEAD_OFFSET_Y    = HEAD_OFFSET_Y,
	HUE_PALETTE_SIZE = HUE_PALETTE_SIZE,
}
