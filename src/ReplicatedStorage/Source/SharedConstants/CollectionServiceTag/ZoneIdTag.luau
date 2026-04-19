--!strict

--[[
	CollectionService tags for zone membership. The server-side ZoneHandler applies these
	tags to instances (typically characters) when they are inside a matching zone part.
	The client-side UIZoneHandler listens to these to open/close UI layers.

	To add a zone:
	  1. Add a value here
	  2. Place a Part in Workspace, tag it with ZonePartTag, set its ZoneId attribute to this value
	  3. Optionally map it to a UI layer in UILayerIdByZoneId.luau
--]]

export type EnumType = "InShop"
-- TODO: Add your zone IDs here.
-- | "InMyZone"

local ZoneIdTag = {
	InShop = "InShop" :: "InShop",
	-- TODO: Add your zone IDs here.
	-- InMyZone = "InMyZone" :: "InMyZone",
}

return ZoneIdTag
