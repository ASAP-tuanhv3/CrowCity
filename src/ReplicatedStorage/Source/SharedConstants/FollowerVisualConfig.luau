--!strict

--[[
	FollowerVisualConfig.luau
	Implements: TR-follower-entity-005 (F8 walk-bob), TR-follower-entity-017 (F9 micro-sway)
	            TR-follower-entity-004 (4/frame spawn throttle)
	            TR-follower-entity-010 (d_init random phase per spawn)
	            TR-follower-entity-012 (white-state SlideIn frame 1)
	            TR-follower-entity-019 (Absorb slide-in lerp)
	GDD:        design/gdd/follower-entity.md §F8-F9 Formulas + §Spawn Triggers
	ADR:        ADR-0007 §Boids Loop Discipline (procedural CFrame, not Humanoid)
	Stories:    production/epics/follower-entity/story-004-walk-bob-microsway.md
	            production/epics/follower-entity/story-005-spawn-states-throttle.md

	Tunable numeric constants for animation (F8/F9) and spawn-state machine layers.
	No code logic lives here — pure data.

	Safe ranges from GDD §Tuning Knobs (Animation):
	  WALK_FREQ_HZ        — [0.8, 2.5]   (cycles per stud of travel)
	  WALK_BOB_AMP        — [0.05, 0.3]  studs Y offset
	  STANDSTILL_THRESHOLD — [0.005, 0.05] studs/frame; below = "standing still"
	  MICRO_SWAY_AMP      — [0.01, 0.06] studs X offset
	  MICRO_SWAY_FREQ_HZ  — [0.2, 0.8]   Hz time-based oscillation

	Safe ranges from GDD §Tuning Knobs (Spawn States):
	  SPAWN_FADE_DURATION       — [0.2, 0.5] s; transparency 1→0 lerp duration
	  SPAWN_SLIDE_DURATION      — [0.3, 0.6] s; CFrame lerp from npcLastPos to crowd_center
	  SPAWN_THROTTLE_PER_FRAME  — [2, 8]; mobile thermal cap on per-frame spawns
--]]

-- Walk-bob frequency (cycles per stud of travel distance d).
-- GDD §F8: y_bob = abs(sin(d * 2π * WALK_FREQ_HZ)) * WALK_BOB_AMP
-- Distance-based (not time-based) — faster movement = faster bob.
-- Safe range: [0.8, 2.5]. Too high → frantic; too low → barely visible.
local WALK_FREQ_HZ: number = 1.5

-- Walk-bob amplitude (studs Y offset).
-- GDD §F8: y_bob magnitude in studs.
-- Safe range: [0.05, 0.3]. Too high → cartoon flailing; too low → static-looking crowd.
local WALK_BOB_AMP: number = 0.15

-- Threshold (studs/frame) below which a follower is considered "standing still".
-- GDD §AC-3: |d_delta| < THRESHOLD for 3 consecutive frames → freeze d, freeze y_bob.
-- Safe range: [0.005, 0.05]. Too high → bob freezes during slow movement;
-- too low → standstill never detected, F9 sway never engages.
local STANDSTILL_THRESHOLD: number = 0.01

-- Micro-sway amplitude (studs X offset).
-- GDD §F9: micro_sway_x = sin(t * 2π * MICRO_SWAY_FREQ_HZ + phase) * MICRO_SWAY_AMP
-- Applies only at standstill at LOD 0 (suppressed at LOD 1/2 — AC-21, AC-26).
-- Safe range: [0.01, 0.06]. Too high → drifting crowd; too low → invisible "alive" cue.
local MICRO_SWAY_AMP: number = 0.03

-- Micro-sway frequency (Hz, time-based).
-- GDD §F9: 2π * MICRO_SWAY_FREQ_HZ rad/s; per-follower phase offset prevents lockstep.
-- Safe range: [0.2, 0.8]. Too high → twitchy; too low → imperceptible.
local MICRO_SWAY_FREQ_HZ: number = 0.4

-- Spawn FadeIn duration (seconds).
-- GDD §AC-19 / §Spawn Triggers: render-cap grow + peel-rival arrival use FadeIn
-- with Transparency tween 1→0 over this duration.
-- Safe range: [0.2, 0.5]. Too high → laggy spawns; too low → pop-in.
local SPAWN_FADE_DURATION: number = 0.3

-- Spawn SlideIn duration (seconds).
-- GDD §AC-16: Absorb event triggers SlideIn — initial CFrame at npcLastPosition
-- lerps to crowd_center over this duration; boids suspended for this follower
-- until SlideIn completes.
-- Safe range: [0.3, 0.6]. Too high → slow visual coupling; too low → no visible flow.
local SPAWN_SLIDE_DURATION: number = 0.4

-- Maximum spawn dispatches per RenderStepped frame across ALL crowds (global cap).
-- GDD §AC-8 + Control Manifest §Presentation guardrail: mobile thermal protection;
-- prevents 80-spawn batch hits when a player triggers many absorbs simultaneously.
-- Excess requests queue FIFO and drain at this rate.
-- Safe range: [2, 8]. Too high → thermal spike; too low → visible queue lag.
local SPAWN_THROTTLE_PER_FRAME: number = 4

-- Hue reconciliation force-write threshold (frames).
-- GDD §AC-Hue: dirty-flag short-circuits steady-state writes; if a bug allowed
-- _currentHue to diverge silently from server hue without triggering a write
-- (e.g., dropped event), this counter forces a re-write after N consecutive
-- mismatch frames (≈66 ms at 60 Hz, one CrowdStateBroadcast interval at 15 Hz).
-- Safe range: [2, 10]. Too low → spurious writes during real broadcast lag;
-- too high → visual desync persists too long after a missed event.
local HUE_RECONCILE_FRAMES: number = 4

-- Peel transit speed (studs/s).
-- GDD §F7: T_peel = min(d_peel / PEEL_SPEED, PEEL_MAX_DURATION).
-- Safe range: [12, 30]. Too high → instant rival absorption no readability;
-- too low → drawn-out transit feels lethargic.
local PEEL_SPEED: number = 20

-- Peel transit duration cap (seconds).
-- GDD §F7 + §AC-12b: protects long-distance peels from drawn-out transit on
-- mobile mid-game with sparse positioning. When d_peel > PEEL_SPEED * PEEL_MAX_DURATION,
-- follower travels for PEEL_MAX_DURATION then CFrame-snaps to rival_center on arrival.
-- Safe range: [2.0, 4.0]. Too high → cross-map peels look stuck;
-- too low → close peels feel rushed.
local PEEL_MAX_DURATION: number = 3.0

-- Teleport detection threshold (studs/frame).
-- GDD §AC-14 + TR-follower-entity-016: when crowd_center delta between frames
-- exceeds this value, followers CFrame-snap to (currentCenter + spawnOffset)
-- for one frame, skipping V_final interp. Strict greater-than (`>`); delta
-- exactly equal does NOT trigger.
-- Locked-by-art-bible — NOT a tuning knob.
local TELEPORT_THRESHOLD: number = 30

-- LOD tier boundary distances (studs) — LOCKED per art-bible §5; NOT tuning knobs.
-- GDD §AC-13a + TR-follower-entity-015: F5 maps camera distance → tier.
--   d <= LOD_TIER_0_MAX             → tier 0
--   LOD_TIER_0_MAX < d <= LOD_TIER_1_MAX → tier 1
--   LOD_TIER_1_MAX < d <= LOD_TIER_2_MAX → tier 2
--   d > LOD_TIER_2_MAX              → CULL (signalled via setPoolSize(0); no fourth tier value)
local LOD_TIER_0_MAX: number = 20
local LOD_TIER_1_MAX: number = 40
local LOD_TIER_2_MAX: number = 100

-- Despawn fade-out duration (seconds).
-- GDD §Despawn Path + ADR-0007: when a follower transitions to Despawning
-- (via _markAllDespawning, peel arrival, or cap-shrink eviction), Body.Transparency
-- tweens 0→1 over this duration; on completion the bundle is returned to Pool.
-- Safe range: [0.15, 0.4]. Too high → followers visibly linger after kill;
-- too low → pop-out instead of fade.
local DESPAWN_FADE_DURATION: number = 0.2

return {
	WALK_FREQ_HZ            = WALK_FREQ_HZ,
	WALK_BOB_AMP            = WALK_BOB_AMP,
	STANDSTILL_THRESHOLD    = STANDSTILL_THRESHOLD,
	MICRO_SWAY_AMP          = MICRO_SWAY_AMP,
	MICRO_SWAY_FREQ_HZ      = MICRO_SWAY_FREQ_HZ,
	SPAWN_FADE_DURATION     = SPAWN_FADE_DURATION,
	SPAWN_SLIDE_DURATION    = SPAWN_SLIDE_DURATION,
	SPAWN_THROTTLE_PER_FRAME = SPAWN_THROTTLE_PER_FRAME,
	HUE_RECONCILE_FRAMES    = HUE_RECONCILE_FRAMES,
	PEEL_SPEED              = PEEL_SPEED,
	PEEL_MAX_DURATION       = PEEL_MAX_DURATION,
	TELEPORT_THRESHOLD      = TELEPORT_THRESHOLD,
	LOD_TIER_0_MAX          = LOD_TIER_0_MAX,
	LOD_TIER_1_MAX          = LOD_TIER_1_MAX,
	LOD_TIER_2_MAX          = LOD_TIER_2_MAX,
	DESPAWN_FADE_DURATION   = DESPAWN_FADE_DURATION,
}
