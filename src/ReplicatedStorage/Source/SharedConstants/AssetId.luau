--!strict

-- Logical asset name → rbxassetid:// URI map per art bible §8.9.
-- Placeholder rbxassetid://0 indicates asset slot reserved but not yet uploaded.
--
-- MVP scope (this file):
--   Skin     — story 001 (cosmetic-shop slate; final IDs owned by VS+ art pipeline)
--   Mesh     — story 002 (character rigs, props, environment blocks)
--   Particle — story 003 (VFX effect IDs cross-ref `design/gdd/vfx-manager.md` §V/A row IDs)
--   Sound    — story 003 (audio cues cross-ref `design/gdd/game-concept.md` §Audio cue inventory)
--
-- Reserved for VS+: real asset IDs replace placeholder rbxassetid://0 entries
--   once art / audio pipelines upload assets (Studio Asset Manager — out of scope here).
--
-- Volume / Looped / per-emitter rate are NOT held here. Consumers (VFXManager,
-- AudioManager) wrap the URI with their own playback config — see story 003
-- Implementation Notes + VFX Manager GDD §C.

export type AssetIdValue = string

local AssetId = {
	-- Implements: Story 001 (asset-id-registry epic)
	-- Skin category: follower appearance textures / meshes.
	-- Keys reserved for MVP cosmetic-shop slate (VS+ owns final asset IDs).
	Skin = {
		FollowerDefault = "rbxassetid://0",
		FollowerCity1   = "rbxassetid://0",
		FollowerCity2   = "rbxassetid://0",
		FollowerNeon    = "rbxassetid://0",
		FollowerEvent1  = "rbxassetid://0",
	},
	-- Implements: Story 002 (asset-id-registry epic)
	-- Mesh category: character rigs, interactive props, environment blocks.
	-- All values are placeholders; real uploads handled by Studio Asset Manager.
	Mesh = {
		-- Characters (Follower Entity GDD §C.1 — 2-Part rig: Body + Hat)
		CharFollowerBody    = "rbxassetid://0",
		CharFollowerHat     = "rbxassetid://0",
		CharPlayerAvatar    = "rbxassetid://0",
		CharNpcNeutral      = "rbxassetid://0",
		-- Props (Chest GDD §C — T1/T2/T3 tiers; T3 reserved, Alpha-deferred)
		PropChestT1         = "rbxassetid://0",
		PropChestT2Car      = "rbxassetid://0",
		PropChestT3Building = "rbxassetid://0",
		-- Environment (arena-layout placeholder; real IDs pending level design)
		EnvBuildingBlockA   = "rbxassetid://0",
		EnvBuildingBlockB   = "rbxassetid://0",
		EnvFloor            = "rbxassetid://0",
		EnvBoundaryWall     = "rbxassetid://0",
	},
	-- Implements: Story 003 (asset-id-registry epic)
	-- Particle category: VFX effect IDs. Names MUST match VFX Manager GDD §V/A
	-- row IDs exactly — VFXManager.playEffect(effectId) uses these as lookup keys.
	-- A typo here breaks the wire contract.
	Particle = {
		AbsorbSnap            = "rbxassetid://0",
		CollisionContactRing  = "rbxassetid://0",
		ChestPeelMarch        = "rbxassetid://0",
		ChestOpenT1Confetti   = "rbxassetid://0",
		ChestOpenT2Confetti   = "rbxassetid://0",
		ChestDraftOpen        = "rbxassetid://0",
		RelicGrantCommon      = "rbxassetid://0",
		RelicGrantRare        = "rbxassetid://0",
		RelicGrantEpic        = "rbxassetid://0",
		RelicExpire           = "rbxassetid://0",
		PeelVanish            = "rbxassetid://0",
		MaxCrowdFlash         = "rbxassetid://0",
	},
	-- Implements: Story 003 (asset-id-registry epic)
	-- Sound category: audio cues per game-concept Pillar 1 audio inventory.
	-- *Cue suffix is the contract — AudioManager (VS+) looks up by these keys.
	Sound = {
		AbsorbCue             = "rbxassetid://0",
		ChestOpenT1Cue        = "rbxassetid://0",
		ChestOpenT2Cue        = "rbxassetid://0",
		RelicGrantCommonCue   = "rbxassetid://0",
		RelicGrantRareCue     = "rbxassetid://0",
		RelicGrantEpicCue     = "rbxassetid://0",
		MatchStartCue         = "rbxassetid://0",
		MatchEndCue           = "rbxassetid://0",
		EliminationCue        = "rbxassetid://0",
		FinalMinuteCue        = "rbxassetid://0",
	},
}

return AssetId
