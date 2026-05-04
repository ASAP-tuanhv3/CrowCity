--!strict

--[[
	FollowerPoolConfig.luau
	Implements: TR-follower-entity-003 (pool prealloc sizes)
	GDD: design/gdd/follower-entity.md §Pool architecture + §Pool knobs
	ADR: ADR-0007 §Pool Allocation Strategy

	All gameplay numeric constants that designers tune to adjust pool behaviour.
	No code logic lives here — pure data.

	Knob summary (safe ranges from GDD §Pool knobs):
	  POOL_PREALLOC_LOD0_BODY / HAT — [200, 640]; 640 = absolute ceiling (8 crowds × 80 own-cap)
	  POOL_PREALLOC_LOD1            — [50, 200]
	  POOL_PREALLOC_LOD2_BILLBOARD  — [30, 120]
	  POOL_BATCH_SIZE               — 25 (matches NPC Spawner pattern per ADR-0008)
	  WALK_FREQ_HZ                  — 1.5 (art-bible lock; needed for d_init random range)
	  HEAD_OFFSET_Y                 — 1.4 studs (future rig-spec tuning lives here)
--]]

-- Tuning: Body MeshPart pool. 460 = 290 baseline + 120 concurrent peel + ~50 despawn overlap.
-- Absolute ceiling 640 (8 × 80). Raise toward 640 if exhaustion warning fires in prod.
local POOL_PREALLOC_LOD0_BODY: number = 460

-- Tuning: Hat MeshPart pool, 1:1 with Body.
local POOL_PREALLOC_LOD0_HAT: number = 460

-- Tuning: LOD-1 simplified primitive pool (body-only, hat fused geometry).
local POOL_PREALLOC_LOD1: number = 100

-- Tuning: LOD-2 BillboardGui impostor pool (1 per crowd at 40-100 m).
local POOL_PREALLOC_LOD2_BILLBOARD: number = 60

-- Allocation batch size — number of Parts created per task.defer slot.
-- Matches NPC Spawner pattern (ADR-0008 §Required Patterns).
local POOL_BATCH_SIZE: number = 25

-- Hidden folder name in Workspace that stores inactive pool entries.
-- Name is prefixed with _ to signal "engine-internal; do not edit" to level designers.
local POOL_FOLDER_NAME: string = "_FollowerPool"

-- Art-bible lock: distance-based bob frequency (GDD §F8).
-- Needed to compute d_init random range = [0, 1/WALK_FREQ_HZ) = [0, 0.667).
-- DO NOT tune this without an art-bible amendment (locked per GDD §Locked constants).
local WALK_FREQ_HZ: number = 1.5

-- Hat attachment offset along Body's local Y axis (studs).
-- GDD §C.1 specifies "(0, headOffsetY, 0)" relative to Body; default 1.4 studs
-- approximates top-of-torso to hat-bottom for the MVP blocker-body mesh proportions.
-- Future Skin System may override per-skin; update here when final mesh is uploaded.
local HEAD_OFFSET_Y: number = 1.4

return {
	POOL_PREALLOC_LOD0_BODY     = POOL_PREALLOC_LOD0_BODY,
	POOL_PREALLOC_LOD0_HAT      = POOL_PREALLOC_LOD0_HAT,
	POOL_PREALLOC_LOD1          = POOL_PREALLOC_LOD1,
	POOL_PREALLOC_LOD2_BILLBOARD = POOL_PREALLOC_LOD2_BILLBOARD,
	POOL_BATCH_SIZE             = POOL_BATCH_SIZE,
	POOL_FOLDER_NAME            = POOL_FOLDER_NAME,
	WALK_FREQ_HZ                = WALK_FREQ_HZ,
	HEAD_OFFSET_Y               = HEAD_OFFSET_Y,
}
