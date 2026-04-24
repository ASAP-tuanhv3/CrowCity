--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Question: Can Roblox handle 800-3000 follower entities across 8-12 players at 60 FPS on mobile?
-- Date: 2026-04-20

-- Tuning knobs for crowd-sync prototype.
-- Change these in Studio without editing code: flip values here, hit Play, observe metrics.

local CrowdConfig = {}

-- ==========================================================================
-- SCENARIO — edit these to sweep load
-- ==========================================================================

-- Number of simulated crowds (bot players + your own)
-- Bot crowds wander randomly; your own follows your character
CrowdConfig.BOT_CROWD_COUNT = 8 -- target: 8-12 (server density)

-- Starting follower count per crowd
CrowdConfig.STARTING_FOLLOWERS_PER_CROWD = 100

-- Max follower count per crowd (crowds grow toward this during test)
CrowdConfig.MAX_FOLLOWERS_PER_CROWD = 300

-- Growth rate (followers/second added until MAX)
CrowdConfig.FOLLOWER_GROWTH_RATE = 10

-- ==========================================================================
-- SERVER BUDGET
-- ==========================================================================

-- Hit-detection tick rate (Hz). Server only checks collisions at this rate.
CrowdConfig.HIT_DETECTION_HZ = 15

-- Crowd-state broadcast rate (Hz). UnreliableRemoteEvent fires at this rate.
CrowdConfig.BROADCAST_HZ = 15

-- Wander radius for bot crowds (studs from origin)
CrowdConfig.BOT_WANDER_RADIUS = 150

-- Bot crowd movement speed (studs/sec)
CrowdConfig.BOT_MOVE_SPEED = 8

-- ==========================================================================
-- RENDER CAPS — core test of Approach B (decouple gameplay count from rendered count)
-- ==========================================================================

-- Max rendered followers per crowd by camera distance tier
CrowdConfig.RENDER_CAP_OWN_CLOSE = 80     -- own crowd, distance ≤ 20m
CrowdConfig.RENDER_CAP_RIVAL_CLOSE = 30   -- rival crowd, distance ≤ 20m
CrowdConfig.RENDER_CAP_MEDIUM = 15        -- any crowd, 20-40m
CrowdConfig.RENDER_CAP_FAR = 4            -- any crowd, 40-100m (billboard-like sparse indicator)
CrowdConfig.CULL_DISTANCE = 100           -- crowds beyond this: not rendered at all

-- LOD swap distances (studs from camera)
CrowdConfig.LOD_0_MAX = 20   -- 0-20m: full-geom block Part
CrowdConfig.LOD_1_MAX = 40   -- 20-40m: simpler Part, half-size
CrowdConfig.LOD_2_MAX = 100  -- 40-100m: 2-tri billboard
-- >100m: culled

-- Client LOD check rate (Hz). Recomputed per-follower this often.
CrowdConfig.LOD_CHECK_HZ = 10

-- ==========================================================================
-- BOIDS (client-side flocking)
-- ==========================================================================

-- Flocking radius — followers influenced by neighbors within this distance
CrowdConfig.BOIDS_NEIGHBOR_RADIUS = 6

-- Weights
CrowdConfig.BOIDS_SEPARATION_WEIGHT = 2.0
CrowdConfig.BOIDS_COHESION_WEIGHT = 0.8
CrowdConfig.BOIDS_FOLLOW_LEADER_WEIGHT = 3.0   -- move toward crowd center
CrowdConfig.BOIDS_MAX_SPEED = 12

-- ==========================================================================
-- FOLLOWER VISUAL SHAPE
-- ==========================================================================

-- Each follower is a Roblox Part (prototype simplification — no mesh import)
CrowdConfig.FOLLOWER_SIZE_LOD0 = Vector3.new(1.5, 2.5, 1.5)
CrowdConfig.FOLLOWER_SIZE_LOD1 = Vector3.new(1.0, 1.5, 1.0)
CrowdConfig.FOLLOWER_SIZE_LOD2 = Vector3.new(1.5, 3.0, 0.1) -- billboard-like flat

-- ==========================================================================
-- METRICS
-- ==========================================================================

-- How often to log FPS + bandwidth to output (seconds)
CrowdConfig.METRIC_LOG_INTERVAL = 2

return CrowdConfig
