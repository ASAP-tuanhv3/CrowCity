--!strict

--[[
	NPCSpawnerConstants — compile-time constants for the NPCSpawner system.
	Path: ReplicatedStorage/Source/SharedConstants/NPCSpawnerConstants.luau
	Implements: TR-npc-spawner-001 (pool size + batch), ADR-0008 §Boot + Round Lifecycle.

	These are known-at-compile-time module configuration values. ARENA_WALKABLE_AREA_SQ
	is intentionally absent — it is a runtime-resolved workspace attribute validated in
	NPCSpawner.init() (TR-npc-spawner-011; ADR-0008 §Boot guard).

	Tuning knobs (designer-facing):
	  NPC_POOL_SIZE              — total pre-allocated Part count (never changes at runtime)
	  NPC_BATCH_SIZE             — Parts created per task.defer batch during init()
	  NPC_RESPAWN_MIN_CROWD_DIST — minimum studs from any active crowd before NPC may respawn
	  NPC_WALK_SPEED             — NPC movement speed in studs/s (Story 004 physics owner)
	  NPC_FADE_IN_DURATION       — TweenService fade-in duration (Story 006)
	  NPC_RESPAWN_MIN_DELAY      — minimum delay in seconds before respawn (Story 005)
	  NPC_RESPAWN_MAX_DELAY      — maximum delay in seconds before respawn (Story 005)
	  NPC_RESPAWN_MAX_RETRIES    — max position-selection retries before fallback (Story 005)
	  T_WALK_MIN                 — min walk timer sample in seconds (Story 004)
	  T_WALK_MAX                 — max walk timer sample in seconds (Story 004)
	  NPC_MIN_INITIAL_SEP        — minimum separation between NPCs at createAll (Story 004)
	  EPSILON_DENSITY            — guard: R_absorb_total below this → steady-state = pool size (Story 008)
	  R_RESPAWN_AVG              — average respawn rate = 1/mean(T_respawn) (Story 008)
--]]

--- Total neutral NPC Part pool size. Pre-allocated at boot, retained across rounds.
--- Source: TR-npc-spawner-001; ADR-0008 §Architecture (_pool: { Part } × 300).
local NPC_POOL_SIZE = 300

--- Parts created per task.defer batch during NPCSpawner.init().
--- 12 batches × 25 Parts = 300. Must satisfy NPC_POOL_SIZE / NPC_BATCH_SIZE == integer.
--- Source: TR-npc-spawner-001; ADR-0008 §Boot + Round Lifecycle (chunked 25/batch).
local NPC_BATCH_SIZE = 25

--- Minimum distance in studs between a respawn candidate position and any active
--- crowd centre. Guards against NPCs spawning inside a player's crowd bubble.
--- Source: design/gdd/npc-spawner.md §Respawn rules; Story 005 consumer.
local NPC_RESPAWN_MIN_CROWD_DIST = 30

--- NPC lateral walk speed in studs per second.
--- Source: design/gdd/npc-spawner.md §Walk speed tuning knob.
local NPC_WALK_SPEED = 4

--- TweenService fade-in duration (seconds). NPC Transparency 1→0 over this interval.
--- Source: design/gdd/npc-spawner.md §V/A AC-18; ADR-0008 §Visual Contract.
local NPC_FADE_IN_DURATION = 0.3

--- Minimum respawn delay after reclaim (seconds). Uniform[MIN, MAX] per F3 (GDD).
--- Source: ADR-0008 §Respawn Contract; Story 005.
local NPC_RESPAWN_MIN_DELAY = 5.0

--- Maximum respawn delay after reclaim (seconds). Uniform[MIN, MAX] per F3 (GDD).
--- Source: ADR-0008 §Respawn Contract; Story 005.
local NPC_RESPAWN_MAX_DELAY = 10.0

--- Maximum position-selection retries before fallback best-effort rule.
--- Source: ADR-0008 §Respawn Contract; Story 005.
local NPC_RESPAWN_MAX_RETRIES = 50

--- Minimum walk timer sample in seconds. Injected RNG samples Uniform[T_WALK_MIN, T_WALK_MAX].
--- Source: design/gdd/npc-spawner.md §Walk timer; ADR-0008 §Movement Loop; Story 004.
local T_WALK_MIN = 2.0

--- Maximum walk timer sample in seconds. Injected RNG samples Uniform[T_WALK_MIN, T_WALK_MAX].
--- Source: design/gdd/npc-spawner.md §Walk timer; ADR-0008 §Movement Loop; Story 004.
local T_WALK_MAX = 5.0

--- Minimum pairwise separation between NPCs at createAll() spawn.
--- Source: ADR-0008 §Movement Loop; Story 004 AC-02.
local NPC_MIN_INITIAL_SEP = 2.5

--- Epsilon guard for F4 steady-state formula. When R_absorb_total ≤ EPSILON,
--- getSteadyStateActive() returns NPC_POOL_SIZE directly (avoid divide-by-zero).
--- Source: ADR-0008 §Density Cross-Reference; Story 008 F4 EPSILON guard.
local EPSILON_DENSITY = 1e-6

--- Average respawn rate = 1 / mean(T_respawn) where mean = (5.0 + 10.0) / 2 = 7.5 s.
--- Used in F4 steady-state equilibrium formula.
--- Source: design/gdd/npc-spawner.md §F4; ADR-0008 §Density Cross-Reference; Story 008.
local R_RESPAWN_AVG = 1.0 / ((NPC_RESPAWN_MIN_DELAY + NPC_RESPAWN_MAX_DELAY) / 2.0)

return {
	NPC_POOL_SIZE             = NPC_POOL_SIZE,
	NPC_BATCH_SIZE            = NPC_BATCH_SIZE,
	NPC_RESPAWN_MIN_CROWD_DIST = NPC_RESPAWN_MIN_CROWD_DIST,
	NPC_WALK_SPEED            = NPC_WALK_SPEED,
	NPC_FADE_IN_DURATION      = NPC_FADE_IN_DURATION,
	NPC_RESPAWN_MIN_DELAY     = NPC_RESPAWN_MIN_DELAY,
	NPC_RESPAWN_MAX_DELAY     = NPC_RESPAWN_MAX_DELAY,
	NPC_RESPAWN_MAX_RETRIES   = NPC_RESPAWN_MAX_RETRIES,
	T_WALK_MIN                = T_WALK_MIN,
	T_WALK_MAX                = T_WALK_MAX,
	NPC_MIN_INITIAL_SEP       = NPC_MIN_INITIAL_SEP,
	EPSILON_DENSITY           = EPSILON_DENSITY,
	R_RESPAWN_AVG             = R_RESPAWN_AVG,
}
