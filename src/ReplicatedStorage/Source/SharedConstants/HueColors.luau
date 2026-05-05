--!strict

--[[
	HueColors.luau — 12 signature crowd hues (palette index → Color3)
	Implements: TR-follower-entity-011 (Color3 write — palette lookup)
	GDD:        design/art/art-bible.md §4 Color System §Player Crowd Colors
	Story:      production/epics/follower-entity/story-006-hue-dirty-flag.md

	Locked safe palette — enforces minimum 30-degree LCH perceptual distance under
	deuteranopia simulation per art-bible. Round-start auto-assigned, 1 per player.

	Index conventions:
	  0    — Neutral / Unassigned (off-white, used for un-absorbed NPCs and lobby)
	  1-12 — Player signature hues (per art-bible §Player Crowd Colors table)

	The Crowd State Manager wire format encodes hue as `u8` (palette index 0..255),
	but only 0..12 are presently meaningful. Indices 13-255 reserved for future
	expansion and treated as Neutral by callers (defensive fallback).

	IMPORTANT: Do NOT use BrickColor here — the GDD §AC-4 explicitly requires
	`Color3` writes (faster C++ property write, no string palette lookup).
--]]

-- Color3.fromRGB takes integers in [0, 255]. Hex values from art-bible converted directly.
local NEUTRAL_WHITE = Color3.fromRGB(245, 245, 245)  -- #F5F5F5 (NPC default per art-bible)

local HUE_COLORS: { Color3 } = {
	[0]  = NEUTRAL_WHITE,                  -- Neutral / Unassigned
	[1]  = Color3.fromRGB(255, 45, 120),   -- #FF2D78 Hot Pink
	[2]  = Color3.fromRGB(0, 207, 255),    -- #00CFFF Cyan
	[3]  = Color3.fromRGB(127, 255, 0),    -- #7FFF00 Lime
	[4]  = Color3.fromRGB(255, 122, 0),    -- #FF7A00 Orange
	[5]  = Color3.fromRGB(0, 85, 255),     -- #0055FF Electric Blue
	[6]  = Color3.fromRGB(255, 229, 0),    -- #FFE500 Yellow
	[7]  = Color3.fromRGB(155, 0, 255),    -- #9B00FF Purple
	[8]  = Color3.fromRGB(255, 34, 34),    -- #FF2222 Red
	[9]  = Color3.fromRGB(0, 229, 176),    -- #00E5B0 Teal
	[10] = Color3.fromRGB(255, 95, 87),    -- #FF5F57 Coral
	[11] = Color3.fromRGB(0, 255, 153),    -- #00FF99 Mint
	[12] = Color3.fromRGB(255, 170, 0),    -- #FFAA00 Gold-Yellow
}

--- Returns the Color3 for the given palette index, defaulting to neutral white
--- for out-of-range or unassigned indices. Pure lookup — never errors.
---
--- @param hueIndex  number — palette index 0..255 (only 0..12 meaningful)
--- @return Color3 — palette color, or NEUTRAL_WHITE for indices >= 13
local function get(hueIndex: number): Color3
	local color = HUE_COLORS[hueIndex]
	if color == nil then
		return NEUTRAL_WHITE
	end
	return color
end

return {
	HUE_COLORS    = HUE_COLORS,
	NEUTRAL_WHITE = NEUTRAL_WHITE,
	get           = get,
}
