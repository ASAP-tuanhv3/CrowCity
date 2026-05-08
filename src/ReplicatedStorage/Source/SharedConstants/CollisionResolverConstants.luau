--!strict

--[[
	CollisionResolverConstants — compile-time constants for the CollisionResolver system.
	Path: ReplicatedStorage/Source/SharedConstants/CollisionResolverConstants.luau
	Implements: TR-ccr-006 (delta_per_tick clamp), TR-ccr-018 (F3 inputs).

	GDD §F3 transfer-rate formula inputs. All values registry-locked by
	`design/gdd/crowd-collision-resolution.md` §Tuning Knobs.

	Tuning knobs (designer-facing — change requires GDD amendment + propagate):
	  TRANSFER_RATE_BASE   — base rate (followers/sec) at zero count differential
	  TRANSFER_RATE_SCALE  — per-count-differential scaling factor (followers/sec per count)
	  TRANSFER_RATE_MAX    — hard cap on effective rate (followers/sec)
	  SERVER_TICK_HZ       — must match ADR-0001 / ADR-0002 server tick cadence
	  DELTA_PER_TICK_MIN   — floor on per-tick integer delta (ensures minimum drip)
	  DELTA_PER_TICK_MAX   — ceiling on per-tick integer delta (caps massive differentials)

	F3 formula:
	  cd        = abs(countA - countB)
	  effective = min(TRANSFER_RATE_BASE + cd * TRANSFER_RATE_SCALE, TRANSFER_RATE_MAX)
	  delta     = clamp(ceil(effective / SERVER_TICK_HZ), DELTA_PER_TICK_MIN, DELTA_PER_TICK_MAX)
--]]

--- Base transfer rate (followers/sec) at zero count differential.
--- Source: GDD §F3; story-003 AC-07 reference inputs.
local TRANSFER_RATE_BASE = 15

--- Per-count-differential scaling factor (followers/sec per unit count delta).
--- Source: GDD §F3; story-003 AC-07 reference inputs.
local TRANSFER_RATE_SCALE = 0.15

--- Hard cap on effective transfer rate (followers/sec).
--- Source: GDD §F3; reached at cd=300 (effective = 15 + 300*0.15 = 60).
local TRANSFER_RATE_MAX = 60

--- Server tick cadence (Hz). Must match ADR-0001 / ADR-0002.
--- Source: TickOrchestrator._tickPeriod = 1/15.
local SERVER_TICK_HZ = 15

--- Floor on per-tick integer delta. Ensures every overlapping pair drips at least
--- one follower per tick regardless of how small the count differential is.
--- Source: GDD §F3 clamp; TR-ccr-006.
local DELTA_PER_TICK_MIN = 1

--- Ceiling on per-tick integer delta. Caps the worst-case attrition rate at 4
--- followers/tick (= 60/sec) to keep elimination pacing predictable.
--- Source: GDD §F3 clamp; TR-ccr-006.
local DELTA_PER_TICK_MAX = 4

return {
	TRANSFER_RATE_BASE = TRANSFER_RATE_BASE,
	TRANSFER_RATE_SCALE = TRANSFER_RATE_SCALE,
	TRANSFER_RATE_MAX = TRANSFER_RATE_MAX,
	SERVER_TICK_HZ = SERVER_TICK_HZ,
	DELTA_PER_TICK_MIN = DELTA_PER_TICK_MIN,
	DELTA_PER_TICK_MAX = DELTA_PER_TICK_MAX,
}
