--!strict

--[[
	FollowerBoidsConfig.luau
	Implements: TR-follower-entity-001 (CFrame authority — no Humanoid; Parts anchored)
	GDD:        design/gdd/follower-entity.md §F1-F4 Formulas + §Tuning Knobs (Boids knobs)
	ADR:        ADR-0007 §Boids Loop Discipline + §Three-Module Split
	Story:      production/epics/follower-entity/story-003-boids-flocking.md

	All tunable numeric constants for the F1-F4 boids simulation.
	No code logic lives here — pure data.

	Safe ranges from GDD §Tuning Knobs:
	  NEIGHBOR_RADIUS       — [3.0, 12.0] studs
	  SEPARATION_RADIUS     — [1.0, NEIGHBOR_RADIUS) studs; MUST be < NEIGHBOR_RADIUS
	  SEPARATION_WEIGHT     — [0.5, 4.0]
	  COHESION_WEIGHT       — [0.3, 3.0]
	  FOLLOW_LEADER_WEIGHT  — [1.0, 8.0]
	  MAX_SPEED             — [8.0, 24.0] studs/s; must be ≥ PlayerWalkSpeed (~16)
	  EPSILON               — fixed at 0.001; do not lower below 1e-4 (NaN risk in F1)
--]]

-- Awareness + cohesion radius (studs).
-- GDD §F2: neighbors within this radius contribute to cohesion centroid.
-- Safe range: [3.0, 12.0]. Too high → heavy O(n²) per-frame; too low → crowd scatters.
local NEIGHBOR_RADIUS: number = 16.0

-- Inter-follower repulsion radius (studs).
-- GDD §F1: neighbors within this radius contribute to separation force.
-- MUST remain < NEIGHBOR_RADIUS — startup assertion enforces this.
-- Safe range: [1.0, NEIGHBOR_RADIUS). Too high → crowd sparse; too low → visual clipping.
-- BUG-002 tune 2026-05-10: 2.5 → 5.0 → 8.0 progressive widening. Larger
-- repulsion radius gives visible swarm spread instead of tight clump.
local SEPARATION_RADIUS: number = 8.0

-- Weight applied to the normalised separation force in F4 composition.
-- GDD §F4: V_raw += F_sep.Unit * SEPARATION_WEIGHT  (only if F_sep.Magnitude > 0)
-- Safe range: [0.5, 4.0]. Too high → crowd sprawls wide; too low → followers pile up.
-- BUG-002 tune 2026-05-10: 1.5 → 4.0 → 6.0 (above spec range; pragmatic).
-- Raw F_lead term scales with distance, so push needs higher weight to keep
-- followers visibly distinct under aggressive leader pull.
local SEPARATION_WEIGHT: number = 6.0

-- Weight applied to the normalised cohesion force in F4 composition.
-- GDD §F4: V_raw += F_coh.Unit * COHESION_WEIGHT  (only if F_coh.Magnitude > 0)
-- Safe range: [0.3, 3.0]. Too high → tight ball fights separation; too low → loose flock.
local COHESION_WEIGHT: number = 1.0

-- Weight applied to the normalised follow-leader force in F4 composition.
-- GDD §F4: V_raw += F_lead.Unit * FOLLOW_LEADER_WEIGHT  (dominant term; largest weight)
-- Safe range: [1.0, 8.0]. Too high → immediate snap, no inertia; too low → crowd lags.
local FOLLOW_LEADER_WEIGHT: number = 3.0

-- Maximum follower travel speed (studs/s).
-- GDD §F4: V_final = clamp(V_raw.Magnitude, 0, MAX_SPEED) * V_raw.Unit
-- Safe range: [8.0, 24.0]; must be ≥ PlayerWalkSpeed (Roblox default 16).
local MAX_SPEED: number = 16

-- Denominator floor for F1 separation (prevents divide-by-zero on exact overlap).
-- GDD §F1: denominator = max(‖P_i - P_j‖², EPSILON)
-- Do not lower below 1e-4 — force magnitude approaches 1/EPSILON when overlapping.
local EPSILON: number = 0.001

-- Startup assertion: SEPARATION_RADIUS must be strictly less than NEIGHBOR_RADIUS.
-- If inverted, separation never finds neighbors within its radius.
assert(
	SEPARATION_RADIUS < NEIGHBOR_RADIUS,
	"FollowerBoidsConfig: SEPARATION_RADIUS must be < NEIGHBOR_RADIUS "
		.. "— separation force would never find neighbors otherwise "
		.. string.format("(SEPARATION_RADIUS=%g, NEIGHBOR_RADIUS=%g)", SEPARATION_RADIUS, NEIGHBOR_RADIUS)
)

return {
	NEIGHBOR_RADIUS      = NEIGHBOR_RADIUS,
	SEPARATION_RADIUS    = SEPARATION_RADIUS,
	SEPARATION_WEIGHT    = SEPARATION_WEIGHT,
	COHESION_WEIGHT      = COHESION_WEIGHT,
	FOLLOW_LEADER_WEIGHT = FOLLOW_LEADER_WEIGHT,
	MAX_SPEED            = MAX_SPEED,
	EPSILON              = EPSILON,
}
