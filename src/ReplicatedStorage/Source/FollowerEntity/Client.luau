--!strict

--[[
	FollowerEntity/Client.luau  — per-crowd follower entity client class
	Path: ReplicatedStorage/Source/FollowerEntity/Client.luau

	Implements:
	  - design/gdd/follower-entity.md §Client Simulation
	  - ADR-0007 §Three-Module Split (FollowerEntityClient per-crowd class)
	  - TR-follower-entity-001 (no Humanoid; Anchored Parts; CFrame authority)
	  - TR-follower-entity-020 (read-only consumer; never writes to CrowdStateClient/Server)
	  - Sprint 4 / Story 4-2 (orchestrator scaffold)
	  - Sprint 4 / Stories 4-3..4-10 (pure modules) — composed here at the wire-in layer

	Responsibilities:
	  - Maintain parallel arrays of follower state for Luau cache locality
	    (ADR-0007 §Data Layout — parallel arrays, not per-instance tables)
	  - Compose Boids + Animation + SpawnStates + HueReconciler + PeelSelection +
	    PeelTransit + PoolResize + LODTierMath into a per-frame pipeline
	  - Provide public API: spawnFromAbsorb, startPeel, setLOD, setPoolSize, getPeelingCount
	  - Provide _update(dt, t, ownState) for orchestrator
	  - Provide _markAllDespawning() — transitions Active → Despawning on nil-crowd
	  - Provide destroy() via injected Janitor

	BACKWARD COMPATIBILITY (story 4-2 scaffold):
	  Existing tests rely on `_debugSeedActiveFollowers(parts)` and `_debugGetFollowerStates()`.
	  These remain operational. The legacy seed populates ONLY `_followerStates` +
	  `_followerParts` arrays. The new pipeline gates real per-frame work on
	  `#self._positions > 0` — when only legacy arrays are seeded (no positions),
	  _update is a no-op. New code paths populate `_positions` via spawnFromAbsorb /
	  startPeel / cap-growth FadeIn, which triggers the real pipeline.

	OUT OF SCOPE FOR THIS WIRE-IN:
	  - Pool.grantBundle / returnBundle integration (depends on Pool singleton bootstrap
	    in start.server.luau — separate follow-up)
	  - VFXManager.playEffect dispatch on hue-flip (depends on VFXManager singleton)
	  - BasePart property writes (Body.Color, Body.CFrame, Body.Transparency) —
	    parallel arrays maintain logical state; production wire-in adds the writes

	READ-ONLY CONTRACT (TR-follower-entity-020):
	  This module never writes to CrowdStateClient, CrowdStateServer, or any
	  server state. No `:set`, `:update`, or server RemoteEvent fires here.

	ADR-0007 BOIDS LOOP DISCIPLINE — forbidden inside RenderStepped:
	  - No Instance.new()
	  - No WaitForChild / :Wait() / task.wait()
	  - No Player.Character traversal
	  - No distance math against camera
	  - No Heartbeat:Connect
	  - No direct subscription to CrowdStateBroadcast
--]]

-- ---------------------------------------------------------------------------
-- Services + dependencies
-- ---------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local JanitorModule = require(Packages.janitor)
type Janitor = typeof(JanitorModule.new())

local Boids                = require(ReplicatedStorage.Source.FollowerEntity.Boids)
local Animation            = require(ReplicatedStorage.Source.FollowerEntity.Animation)
local SpawnStates          = require(ReplicatedStorage.Source.FollowerEntity.SpawnStates)
local HueReconciler        = require(ReplicatedStorage.Source.FollowerEntity.HueReconciler)
local PeelSelection        = require(ReplicatedStorage.Source.FollowerEntity.PeelSelection)
local PeelTransit          = require(ReplicatedStorage.Source.FollowerEntity.PeelTransit)
local PoolResize           = require(ReplicatedStorage.Source.FollowerEntity.PoolResize)
local LODTierMath          = require(ReplicatedStorage.Source.FollowerEntity.LODTierMath)

local FollowerBoidsConfig  = require(ReplicatedStorage.Source.SharedConstants.FollowerBoidsConfig)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)
local HueColors            = require(ReplicatedStorage.Source.SharedConstants.HueColors)
local Pool                 = require(ReplicatedStorage.Source.FollowerEntity.Pool)
type RigBundle = Pool.RigBundle
type PoolType  = Pool.ClassType

-- ---------------------------------------------------------------------------
-- Follower state enum constants (module-level; no magic strings per CLAUDE.md)
-- ---------------------------------------------------------------------------

local FOLLOWER_STATE_ACTIVE     = "Active"
local FOLLOWER_STATE_DESPAWNING = "Despawning"
local FOLLOWER_STATE_PEELING    = "Peeling"
local FOLLOWER_STATE_FADEIN     = "Spawning:FadeIn"
local FOLLOWER_STATE_SLIDEIN    = "Spawning:SlideIn"
local FOLLOWER_STATE_DONE       = "Done" -- post-despawn tombstone slot

-- ---------------------------------------------------------------------------
-- Optional crowd state record interface (callers provide; we never write)
-- ---------------------------------------------------------------------------

export type CrowdStateRecord = {
	position: Vector3,
	hue: number,
	[any]: any,
}

--- Callback type that returns the current crowd state for a given crowdId,
--- or nil if the crowd has been eliminated. Injected by CrowdManagerClient
--- (which holds the CrowdStateClient reference).
export type CrowdStateGetter = (crowdId: string) -> CrowdStateRecord?

-- ---------------------------------------------------------------------------
-- Class definition
-- ---------------------------------------------------------------------------

local FollowerEntityClient = {}
FollowerEntityClient.__index = FollowerEntityClient

--- ClassType: per-crowd follower entity client.
--- Parallel arrays store per-follower state for Luau cache locality (ADR-0007 §Data Layout).
export type ClassType = typeof(setmetatable(
	{} :: {
		-- Identity
		_crowdId: string,
		_janitor: Janitor,
		-- Legacy parallel arrays (story 4-2 scaffold; tests rely on these)
		_followerParts: { BasePart },
		_followerStates: { string },
		_despawningStartedAt: { [number]: number },
		_peelingFollowers: { [BasePart]: boolean },
		-- New parallel arrays (wire-in: stories 4-3..4-10 composed)
		_positions: { Vector3 },
		_d: { number },
		_lastYBob: { number },
		_swayPhaseOffset: { number },
		_isStandstill: { boolean },
		_spawnElapsed: { number },
		_slideTick: { number },
		_npcLastPosition: { Vector3 },
		_absorberHueColor: { Color3 },
		_peelStart: { number },
		_T_peel: { number },
		_T_hue_flip: { number },
		_hueFlipApplied: { boolean },
		_rivalCrowdId: { string },
		_rivalCenterCached: { Vector3 },
		_d_peel: { number },
		_isCapped: { boolean },
		_peelAborted: { boolean },
		_spawnOffsets: { Vector3 },
		_despawnElapsed: { number },  -- dt-accumulated since transition to Despawning
		-- Pool integration (optional — nil = parallel-array-only mode for tests)
		_pool: PoolType?,
		_bundles: { RigBundle? },
		-- Per-crowd cached state
		_currentHue: number?,
		_hueMismatchFrames: number,
		_lastCrowdCenter: Vector3,
		_teleportFlag: boolean,
		_tier: LODTierMath.Tier,
		-- Lifecycle
		_destroyed: boolean,
		-- Optional injected getter for cross-crowd reads (peel transit needs rival state).
		-- nil → peel rivalRecord lookups behave as nil (abort path engages).
		_getCrowdState: CrowdStateGetter?,
		-- Optional cap-grow callback: when setPoolSize requires N FadeIn spawns,
		-- this is invoked N times by the orchestrator's throttle queue plumbing.
		-- nil → grow requests logged but no spawns enqueued.
		_onCapGrowRequest: ((number) -> ())?,
		-- Random source override (tests inject deterministic LCG).
		_randFn: (() -> number)?,
		-- Per-frame instrumentation (read by tests / Micro Profiler proxy).
		_lastFrameHueWrites: number,
		_lastFrameVfxFlips: number,
	},
	FollowerEntityClient
))

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- Creates a new FollowerEntityClient for the given crowd.
--- The injected `janitor` is the orchestrator's per-crowd Janitor.
--- Call :destroy() to tear down (which calls janitor:Destroy()).
function FollowerEntityClient.new(crowdId: string, janitor: Janitor): ClassType
	local self = setmetatable({} :: any, FollowerEntityClient)
	self._crowdId            = crowdId
	self._janitor            = janitor
	-- Legacy arrays
	self._followerParts      = {} :: { BasePart }
	self._followerStates     = {} :: { string }
	self._despawningStartedAt = {} :: { [number]: number }
	self._peelingFollowers   = {} :: { [BasePart]: boolean }
	-- New parallel arrays
	self._positions          = {} :: { Vector3 }
	self._d                  = {} :: { number }
	self._lastYBob           = {} :: { number }
	self._swayPhaseOffset    = {} :: { number }
	self._isStandstill       = {} :: { boolean }
	self._spawnElapsed       = {} :: { number }
	self._slideTick          = {} :: { number }
	self._npcLastPosition    = {} :: { Vector3 }
	self._absorberHueColor   = {} :: { Color3 }
	self._peelStart          = {} :: { number }
	self._T_peel             = {} :: { number }
	self._T_hue_flip         = {} :: { number }
	self._hueFlipApplied     = {} :: { boolean }
	self._rivalCrowdId       = {} :: { string }
	self._rivalCenterCached  = {} :: { Vector3 }
	self._d_peel             = {} :: { number }
	self._isCapped           = {} :: { boolean }
	self._peelAborted        = {} :: { boolean }
	self._spawnOffsets       = {} :: { Vector3 }
	self._despawnElapsed     = {} :: { number }
	-- Pool integration (nil unless setPool is called)
	self._pool               = nil
	self._bundles            = {} :: { RigBundle? }
	-- Per-crowd cached
	self._currentHue         = nil
	self._hueMismatchFrames  = 0
	self._lastCrowdCenter    = Vector3.zero
	self._teleportFlag       = false
	self._tier               = LODTierMath.TIER_0
	-- Story 6-1: tracks last-seen broadcast count so _update can detect deltas
	-- and call setPoolSize(record.count) → cap-grow callback enqueues N FadeIn
	-- spawns through the throttle queue. Initial spawn at CrowdCreated already
	-- calls setPoolSize(record.count); _lastSeenCount captures that initial
	-- value so subsequent broadcast-driven deltas don't double-grow.
	self._lastSeenCount      = nil :: number?
	-- Lifecycle
	self._destroyed          = false
	self._getCrowdState      = nil
	self._onCapGrowRequest   = nil
	self._randFn             = nil
	self._lastFrameHueWrites = 0
	self._lastFrameVfxFlips  = 0
	return self
end

-- ---------------------------------------------------------------------------
-- Dependency injection — orchestrator wires these at construction-time
-- ---------------------------------------------------------------------------

--- Injects the cross-crowd state getter. Called by CrowdManagerClient at
--- construction. Used by peel transit to read rival crowd state per frame.
function FollowerEntityClient.setCrowdStateGetter(self: ClassType, getter: CrowdStateGetter): ()
	self._getCrowdState = getter
end

--- Injects the cap-grow callback. CrowdManagerClient owns the global throttle
--- queue; this callback enqueues a single FadeIn spawn request when called.
--- @param cb  function — invoked once per spawn requested (called N times for cap-grow N)
function FollowerEntityClient.setCapGrowCallback(self: ClassType, cb: (number) -> ()): ()
	self._onCapGrowRequest = cb
end

--- Injects a deterministic random source for testing. nil → use math.random.
function FollowerEntityClient.setRandomSource(self: ClassType, randFn: () -> number): ()
	self._randFn = randFn
end

--- Injects the shared Pool instance. When set, spawnFromAbsorb /
--- spawnFadeInAtCenter call `pool:grantBundle(hueIndex)` and the per-frame
--- _update writes to the granted Body's CFrame/Color/Transparency. When nil
--- (default), the client operates in parallel-array-only mode (tests).
---
--- The pool is shared across crowds — a single Pool singleton instance is
--- typically created at boot in start.server.luau and injected into every
--- FollowerEntityClient via CrowdManagerClient.constructCrowd.
function FollowerEntityClient.setPool(self: ClassType, pool: PoolType): ()
	self._pool = pool
end

-- ---------------------------------------------------------------------------
-- Internal: append a new follower row to the parallel arrays
-- ---------------------------------------------------------------------------

local function appendFollowerRow(
	self: ClassType,
	state: string,
	position: Vector3,
	npcLastPos: Vector3?,
	absorberHueColor: Color3?,
	bundle: RigBundle?
): number
	local rng = self._randFn
	local i = #self._followerStates + 1
	self._followerStates[i]       = state
	self._positions[i]            = position
	self._d[i]                    = SpawnStates.randomDInit(FollowerVisualConfig.WALK_FREQ_HZ, rng)
	self._lastYBob[i]             = 0
	self._swayPhaseOffset[i]      = SpawnStates.randomSwayPhaseOffset(rng)
	self._isStandstill[i]         = false
	self._spawnElapsed[i]         = 0
	self._slideTick[i]            = 0
	self._npcLastPosition[i]      = npcLastPos or position
	self._absorberHueColor[i]     = absorberHueColor or HueColors.NEUTRAL_WHITE
	self._peelStart[i]            = 0
	self._T_peel[i]               = 0
	self._T_hue_flip[i]           = 0
	self._hueFlipApplied[i]       = false
	self._rivalCrowdId[i]         = ""
	self._rivalCenterCached[i]    = Vector3.zero
	self._d_peel[i]               = 0
	self._isCapped[i]             = false
	self._peelAborted[i]          = false
	self._spawnOffsets[i]         = position - self._lastCrowdCenter
	self._despawnElapsed[i]       = 0
	self._bundles[i]              = bundle  -- nil if no pool injected
	-- If pool granted a bundle, populate _followerParts[i] for backward-compat
	-- (existing tests inspect _followerParts via _debugSeedActiveFollowers seam).
	if bundle ~= nil then
		self._followerParts[i] = bundle.body
		-- Position the body at the spawn location (out-of-pool default is (0,-1000,0)).
		bundle.body.CFrame = CFrame.new(position)
		-- Make visible (pool grant returns Parts at Transparency=1).
		bundle.body.Transparency = 0
		if bundle.hat ~= nil then
			bundle.hat.Transparency = 0
		end
	end
	return i
end

-- ---------------------------------------------------------------------------
-- Public API — spawn flows
-- ---------------------------------------------------------------------------

--- Spawns a follower at the last known position of an absorbed NPC.
--- Implements Story 4-5 §spawnFromAbsorb: SlideIn flow, frame-1 white hue,
--- frame-2+ absorber hue, 0.4s CFrame lerp to crowd_center, boids suspended.
---
--- The throttle (4/frame) is enforced by CrowdManagerClient's SpawnThrottleQueue
--- — this method is the dequeue handler, called once per dispatched request.
---
--- @param npcLastPosition   Vector3
--- @param absorberHueIndex  number? — palette index; defaults to 0 (neutral)
function FollowerEntityClient.spawnFromAbsorb(
	self: ClassType,
	npcLastPosition: Vector3,
	absorberHueIndex: number?
): ()
	if self._destroyed then
		return
	end
	local hueIdx = absorberHueIndex or 0
	local hueColor = HueColors.get(hueIdx)
	-- Pool grant: nil if pool not injected (tests) or pool exhausted.
	local bundle: RigBundle? = nil
	if self._pool ~= nil then
		bundle = self._pool:grantBundle(hueIdx)
		if bundle == nil then
			-- Pool exhausted (Story 4-1 AC-7) — silently drop spawn; pool's
			-- internal warn-once log fires on the first exhaustion.
			return
		end
	end
	local idx = appendFollowerRow(
		self, FOLLOWER_STATE_SLIDEIN, npcLastPosition, npcLastPosition, hueColor, bundle
	)
	-- Frame-1 white latch (TR-follower-entity-012, Story 4-5 AC-24)
	if bundle ~= nil then
		bundle.body.Color = HueColors.NEUTRAL_WHITE
	end
	local _ = idx
end

--- Cap-growth path: spawns a follower in FadeIn state at the crowd center.
--- Used by setPoolSize when actualN > nonPeelTotal. Throttle queue dispatch
--- enqueues one FadeIn request per growCount; this method runs per dispatch.
function FollowerEntityClient.spawnFadeInAtCenter(self: ClassType): ()
	if self._destroyed then
		return
	end
	-- Cap-growth uses the crowd's current hue (read from CrowdState if available)
	-- or falls back to neutral. Used as a placeholder hueIndex for pool grant.
	local hueIdx = self._currentHue or 0
	local bundle: RigBundle? = nil
	if self._pool ~= nil then
		bundle = self._pool:grantBundle(hueIdx)
		if bundle == nil then
			return
		end
	end
	appendFollowerRow(self, FOLLOWER_STATE_FADEIN, self._lastCrowdCenter, nil, nil, bundle)
	if bundle ~= nil then
		-- FadeIn starts fully transparent; alpha tween fades it in over SPAWN_FADE_DURATION
		bundle.body.Transparency = 1
		if bundle.hat ~= nil then
			bundle.hat.Transparency = 1
		end
	end
end

-- ---------------------------------------------------------------------------
-- Public API — peel flow (Story 4-7 + 4-8)
-- ---------------------------------------------------------------------------

--- Initiates a peel of `n` followers toward a rival crowd.
--- Implements Story 4-7 (F6 closest-to-rival selection) + Story 4-8 (transit setup).
--- Selects N closest-to-rival Active followers via PeelSelection, transitions them
--- to Peeling state, and computes per-follower transit timing via PeelTransit.
---
--- @param rivalCrowdId  string — target crowd identifier
--- @param n             number — broadcast-reported peel count
function FollowerEntityClient.startPeel(
	self: ClassType,
	rivalCrowdId: string,
	n: number
): ()
	if self._destroyed then
		return
	end
	-- Story 4-7 §Implementation step 1: read rivalRecord; nil → no-op
	local getter = self._getCrowdState
	if getter == nil then
		return
	end
	local rivalRecord = getter(rivalCrowdId)
	if rivalRecord == nil then
		return
	end
	local rivalCenter = rivalRecord.position

	-- Story 4-7 §F6: select N closest Active followers
	local selected = PeelSelection.selectClosestToRival(
		self._positions, self._followerStates, rivalCenter, n, FOLLOWER_STATE_ACTIVE
	)

	-- Story 4-8 §Implementation: per-follower transit setup
	local peelStartT = os.clock()
	for _, idx in selected do
		local params = PeelTransit.computeTransitParams(
			self._positions[idx],
			rivalCenter,
			FollowerVisualConfig.PEEL_SPEED,
			FollowerVisualConfig.PEEL_MAX_DURATION
		)
		self._followerStates[idx]     = FOLLOWER_STATE_PEELING
		self._peelStart[idx]          = peelStartT
		self._T_peel[idx]             = params.tPeel
		self._T_hue_flip[idx]         = params.tHueFlip
		self._d_peel[idx]             = params.dPeel
		self._isCapped[idx]           = params.isCapped
		self._hueFlipApplied[idx]     = false
		self._rivalCrowdId[idx]       = rivalCrowdId
		self._rivalCenterCached[idx]  = rivalCenter
		self._peelAborted[idx]        = false
	end
end

-- ---------------------------------------------------------------------------
-- Public API — LOD + cap (Stories 4-9 + 4-10)
-- ---------------------------------------------------------------------------

--- Sets the LOD tier for this crowd's followers.
--- Story 4-10: stores tier; per-frame _update consults it via LODTierMath gates.
--- Tier values: 0 (full fidelity), 1 (simplified), 2 (billboard impostor).
function FollowerEntityClient.setLOD(self: ClassType, tier: number): ()
	if self._destroyed then
		return
	end
	if tier == 0 then
		self._tier = LODTierMath.TIER_0
	elseif tier == 1 then
		self._tier = LODTierMath.TIER_1
	elseif tier == 2 then
		self._tier = LODTierMath.TIER_2
	end
	-- Out-of-range tier values are silently ignored. Story 4-10 wire-in scope:
	-- the runtime assert + LOD-pool reassignment lives in a separate
	-- integration pass that actually plumbs Pool.grantBundle through this path.
end

--- Resizes the active follower pool for this crowd.
--- Story 4-9 + Story 4-10 §CULL: defensive `actualN = max(n, peelingCount)`
--- clamp; perimeter-first eviction of Active+Despawning; cap-grow via the
--- injected throttle queue callback.
---
--- @param n  number — desired cap (peeling subset is held immune)
function FollowerEntityClient.setPoolSize(self: ClassType, n: number): ()
	if self._destroyed then
		return
	end
	-- Story 6-1: keep _lastSeenCount in sync so the per-frame _update
	-- count-delta check doesn't double-fire on the initial CrowdManagerClient
	-- setPoolSize(record.count) call. Both call paths converge here.
	self._lastSeenCount = n
	local action = PoolResize.computeResizeAction(
		self._followerStates,
		self._positions,
		self._lastCrowdCenter,
		n,
		FOLLOWER_STATE_ACTIVE,
		FOLLOWER_STATE_PEELING,
		FOLLOWER_STATE_DESPAWNING
	)
	-- Apply evictions: transition selected indices to Despawning
	for _, idx in action.evictIndices do
		self._followerStates[idx] = FOLLOWER_STATE_DESPAWNING
		self._despawningStartedAt[idx] = os.clock() -- legacy/audit timestamp
		self._despawnElapsed[idx] = 0 -- dt-accumulated fade timer (reset)
	end
	-- Cap-grow: enqueue N FadeIn spawn requests
	if action.growCount > 0 and self._onCapGrowRequest ~= nil then
		self._onCapGrowRequest(action.growCount)
	end
end

--- Returns the current count of followers in Peeling state.
--- Story 4-9 §getPeelingCount.
function FollowerEntityClient.getPeelingCount(self: ClassType): number
	if self._destroyed then
		return 0
	end
	return PoolResize.getPeelingCount(self._followerStates, FOLLOWER_STATE_PEELING)
end

-- ---------------------------------------------------------------------------
-- Internal per-frame update — composes all 8 pure modules
-- ---------------------------------------------------------------------------

--- Called every RenderStepped frame by CrowdManagerClient when the crowd is non-nil.
--- Composes Boids + Animation + SpawnStates + HueReconciler + PeelTransit + LODTierMath
--- into a per-frame pipeline.
---
--- Backward-compat: when `#self._positions == 0` (only legacy `_followerParts` /
--- `_followerStates` seeded by `_debugSeedActiveFollowers`), this method is a no-op.
--- New code paths populate `_positions` via spawnFromAbsorb / spawnFadeInAtCenter
--- which triggers the real pipeline.
---
--- @param dt  number  — RenderStepped delta-time
--- @param t   number? — current time (os.clock); defaults to os.clock() if nil
function FollowerEntityClient._update(self: ClassType, dt: number, t: number?): ()
	if self._destroyed then
		return
	end
	if #self._positions == 0 then
		-- Legacy / story-002 stub path: only old arrays seeded → no-op
		return
	end

	local now = t or os.clock()
	self._lastFrameHueWrites = 0
	self._lastFrameVfxFlips = 0

	-- Read crowd state via injected getter; if absent, no per-frame work.
	-- Orchestrator already gates this call behind a non-nil check, but the
	-- getter-not-injected case (e.g., tests) defensively short-circuits.
	local getter = self._getCrowdState
	if getter == nil then
		return
	end
	local ownState = getter(self._crowdId)
	if ownState == nil then
		-- Defensive: orchestrator should have caught this, but if not, no-op.
		return
	end

	local ownCenter = ownState.position
	local targetHue = ownState.hue

	-- Story 6-1: broadcast-count delta → cap-grow / cap-shrink. CSM Phase 8
	-- broadcasts updated record.count at 15 Hz; client `setPoolSize` resolves
	-- the visual delta via PoolResize.computeResizeAction (cap-grow enqueues
	-- N FadeIn spawns through throttle queue; cap-shrink evicts perimeter-
	-- first). Compare against last-seen count to skip no-op frames.
	-- This closes the visual absorb loop end-to-end: NPC absorbed →
	-- AbsorbSystem updateCount(+1, "Collision") → CSM broadcast → here →
	-- visible follower count grows by 1.
	local newCount = ownState.count
	if newCount ~= nil and newCount ~= self._lastSeenCount then
		self._lastSeenCount = newCount
		self:setPoolSize(newCount)
	end

	-- 1. Teleport detection (Story 4-10)
	if LODTierMath.shouldTeleportSnap(
		ownCenter, self._lastCrowdCenter, FollowerVisualConfig.TELEPORT_THRESHOLD
	) then
		local snapped = LODTierMath.computeTeleportSnapPositions(ownCenter, self._spawnOffsets)
		for i, p in snapped do
			self._positions[i] = p
		end
		self._teleportFlag = true
		self._lastCrowdCenter = ownCenter
		return -- skip boids this frame per AC-14
	end
	self._teleportFlag = false
	self._lastCrowdCenter = ownCenter

	-- 2. Hue dirty-flag (Story 4-6)
	local dirty = HueReconciler.defaultDirtyFlag(self._currentHue, targetHue)
	local shouldWriteHue, newCurrentHue, newMismatchFrames = HueReconciler.evaluate(
		self._currentHue, targetHue, self._hueMismatchFrames,
		FollowerVisualConfig.HUE_RECONCILE_FRAMES, dirty
	)
	self._currentHue = newCurrentHue
	self._hueMismatchFrames = newMismatchFrames

	-- 3. Per-follower update (state-machine dispatch)
	local renderF4 = LODTierMath.shouldRenderF4(self._tier)
	local renderBob = LODTierMath.shouldRenderBob(self._tier)

	for i, state in self._followerStates do
		local bundle = self._bundles[i]

		if state == FOLLOWER_STATE_FADEIN then
			-- Story 4-5: alpha tween 1→0; boids RUNS during FadeIn
			self._spawnElapsed[i] += dt
			-- Apply transparency lerp via SpawnStates pure module
			if bundle ~= nil then
				bundle.body.Transparency = SpawnStates.computeFadeInTransparency(
					self._spawnElapsed[i], FollowerVisualConfig.SPAWN_FADE_DURATION
				)
			end
			if SpawnStates.isFadeInComplete(self._spawnElapsed[i], FollowerVisualConfig.SPAWN_FADE_DURATION) then
				self._followerStates[i] = FOLLOWER_STATE_ACTIVE
				if bundle ~= nil then
					bundle.body.Transparency = 0
				end
			end
			if shouldWriteHue and bundle ~= nil then
				bundle.body.Color = HueColors.get(targetHue)
				self._lastFrameHueWrites += 1
			elseif shouldWriteHue then
				self._lastFrameHueWrites += 1
			end
		elseif state == FOLLOWER_STATE_SLIDEIN then
			-- Story 4-5: CFrame lerp; boids SUSPENDED
			self._spawnElapsed[i] += dt
			self._slideTick[i] += 1
			self._positions[i] = SpawnStates.computeSlideInPosition(
				self._npcLastPosition[i], ownCenter,
				self._spawnElapsed[i], FollowerVisualConfig.SPAWN_SLIDE_DURATION
			)
			if bundle ~= nil then
				bundle.body.CFrame = CFrame.new(self._positions[i])
				-- AC-24: frame 1 white; frame 2+ absorber hue
				bundle.body.Color = SpawnStates.getSlideInBodyColor(
					self._slideTick[i], self._absorberHueColor[i]
				)
			end
			if SpawnStates.isSlideInComplete(self._spawnElapsed[i], FollowerVisualConfig.SPAWN_SLIDE_DURATION) then
				self._followerStates[i] = FOLLOWER_STATE_ACTIVE
			end
		elseif state == FOLLOWER_STATE_ACTIVE then
			if renderF4 then
				-- Story 4-3: Boids F1-F4
				local F_sep = Boids.separation(
					self._positions[i], self._positions,
					FollowerBoidsConfig.SEPARATION_RADIUS, FollowerBoidsConfig.EPSILON
				)
				local F_coh = Boids.cohesion(
					self._positions[i], self._positions, FollowerBoidsConfig.NEIGHBOR_RADIUS
				)
				local F_lead = Boids.followLeader(self._positions[i], ownCenter)
				local V = Boids.finalVelocity(
					F_sep, F_coh, F_lead,
					FollowerBoidsConfig.SEPARATION_WEIGHT,
					FollowerBoidsConfig.COHESION_WEIGHT,
					FollowerBoidsConfig.FOLLOW_LEADER_WEIGHT,
					FollowerBoidsConfig.MAX_SPEED
				)
				local prevPos = self._positions[i]
				local newPos = Boids.applyVelocity(prevPos, V, dt)
				self._positions[i] = newPos

				-- Story 4-4: F8/F9 walk-bob + sway (TR-006: d accumulates regardless of tier)
				local dDelta = (newPos - prevPos).Magnitude
				local newD, isStill = Animation.updateD(
					self._d[i], dDelta, FollowerVisualConfig.STANDSTILL_THRESHOLD
				)
				self._d[i] = newD
				self._isStandstill[i] = isStill
				if not isStill then
					self._lastYBob[i] = Animation.computeWalkBobY(
						newD,
						FollowerVisualConfig.WALK_FREQ_HZ,
						FollowerVisualConfig.WALK_BOB_AMP
					)
				end
				-- F9 + final CFrame composition gated by tier (LOD 0 only)
				local swayX = 0
				if renderBob then
					swayX = Animation.computeMicroSwayX(
						isStill, 0, now, self._swayPhaseOffset[i],
						FollowerVisualConfig.MICRO_SWAY_FREQ_HZ,
						FollowerVisualConfig.MICRO_SWAY_AMP
					)
				end
				if bundle ~= nil then
					-- LOD 0: apply F8/F9 offsets; LOD 1+: rootTarget unchanged
					local lodTierNumeric = if self._tier == LODTierMath.TIER_0 then 0
						elseif self._tier == LODTierMath.TIER_1 then 1
						else 2
					local bodyCF = Animation.composeBodyCFrame(
						CFrame.new(newPos), self._lastYBob[i], swayX, lodTierNumeric
					)
					bundle.body.CFrame = bodyCF
				end
			end
			-- Hue write (gated by dirty flag)
			if shouldWriteHue then
				if bundle ~= nil then
					bundle.body.Color = HueColors.get(targetHue)
				end
				self._lastFrameHueWrites += 1
			end
		elseif state == FOLLOWER_STATE_PEELING then
			-- Story 4-8: peel transit
			local elapsed = now - self._peelStart[i]
			local rivalState = if getter ~= nil
				then getter(self._rivalCrowdId[i])
				else nil
			local rivalPos = if rivalState ~= nil then rivalState.position else nil
			local target, isAborted = PeelTransit.computeFLeadTarget(
				rivalPos, self._rivalCenterCached[i], ownCenter
			)
			if rivalState ~= nil then
				self._rivalCenterCached[i] = rivalState.position
			end
			if isAborted then
				self._peelAborted[i] = true
			end
			-- Hue flip latch
			if PeelTransit.shouldFlipHue(elapsed, self._T_hue_flip[i], self._hueFlipApplied[i]) then
				self._hueFlipApplied[i] = true
				self._lastFrameVfxFlips += 1
				self._lastFrameHueWrites += 1
				-- Body.Color flips to rival's hue (rival state is non-nil if not aborted;
				-- abort path retains caller-cached own hue color).
				if bundle ~= nil and rivalState ~= nil then
					bundle.body.Color = HueColors.get(rivalState.hue)
				end
			end
			-- Boids retarget for transit (F_lead toward target; F_sep + F_coh suppressed
			-- during transit per Story 4-8 §F_lead reads rival_center)
			if renderF4 then
				local F_lead = Boids.followLeader(self._positions[i], target)
				local V = Boids.finalVelocity(
					Vector3.zero, Vector3.zero, F_lead,
					0, 0, FollowerBoidsConfig.FOLLOW_LEADER_WEIGHT,
					FollowerBoidsConfig.MAX_SPEED
				)
				self._positions[i] = Boids.applyVelocity(self._positions[i], V, dt)
				if bundle ~= nil then
					bundle.body.CFrame = CFrame.new(self._positions[i])
				end
			end
			-- Arrival
			if PeelTransit.isArrived(elapsed, self._T_peel[i]) then
				local terminal = PeelTransit.resolveAbortArrivalState(self._peelAborted[i], false)
				if terminal == "Active" then
					-- Rival-nil abort recovery
					self._followerStates[i] = FOLLOWER_STATE_ACTIVE
					self._peelAborted[i] = false
					self._rivalCrowdId[i] = ""
				else
					-- Normal arrival: despawn (rival-side spawn dispatched by orchestrator)
					self._followerStates[i] = FOLLOWER_STATE_DESPAWNING
					self._despawningStartedAt[i] = now
					self._despawnElapsed[i] = 0
					if self._isCapped[i] then
						-- AC-12b: capped peel CFrame-snaps to rival_center on arrival
						self._positions[i] = self._rivalCenterCached[i]
						if bundle ~= nil then
							bundle.body.CFrame = CFrame.new(self._rivalCenterCached[i])
						end
					end
				end
			end
		elseif state == FOLLOWER_STATE_DESPAWNING then
			-- Despawn fade-out: alpha tween 0→1 over DESPAWN_FADE_DURATION; on
			-- complete, return bundle to pool and tombstone the slot.
			-- Only ticks when pool injected — legacy/test mode skips this branch.
			-- Uses dt-accumulated `_despawnElapsed[i]` (NOT wall-clock) so headless
			-- tests stepping `_debugStepRenderFrame(dt)` advance the fade correctly.
			if bundle ~= nil then
				self._despawnElapsed[i] += dt
				local elapsed = self._despawnElapsed[i]
				local duration = FollowerVisualConfig.DESPAWN_FADE_DURATION
				if elapsed >= duration then
					-- Fade complete — return to pool, tombstone slot.
					bundle.body.Transparency = 1
					if bundle.hat ~= nil then
						bundle.hat.Transparency = 1
					end
					(self._pool :: PoolType):returnBundle(bundle)
					self._bundles[i] = nil
					self._followerStates[i] = FOLLOWER_STATE_DONE
				else
					-- Linear lerp 0 → 1 over duration
					bundle.body.Transparency = elapsed / duration
					if bundle.hat ~= nil then
						bundle.hat.Transparency = elapsed / duration
					end
				end
			end
		end
		-- FOLLOWER_STATE_DONE slots are skipped (no-op).
	end
end

-- ---------------------------------------------------------------------------
-- Despawn path — nil-crowd detection (story 4-2)
-- ---------------------------------------------------------------------------

--- Transitions all followers in this crowd from Active → Despawning.
--- Called by CrowdManagerClient when CrowdStateClient.get(crowdId) returns nil.
--- Idempotent: followers already in Despawning are not re-stamped.
function FollowerEntityClient._markAllDespawning(self: ClassType): ()
	if self._destroyed then
		return
	end
	local now = os.clock()
	for i = 1, #self._followerStates do
		if self._followerStates[i] == FOLLOWER_STATE_ACTIVE then
			self._followerStates[i] = FOLLOWER_STATE_DESPAWNING
			self._despawningStartedAt[i] = now
			-- Reset dt-accumulated fade timer (paired with Despawning state arrays).
			-- Idempotent for legacy clients without `_despawnElapsed`: assignment
			-- on a sparse array is safe.
			self._despawnElapsed[i] = 0
		end
	end
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function FollowerEntityClient.destroy(self: ClassType): ()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._janitor:Destroy()
end

-- ---------------------------------------------------------------------------
-- Test-only accessors
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — returns the _followerStates parallel array for inspection.
function FollowerEntityClient._debugGetFollowerStates(self: ClassType): { string }
	return self._followerStates
end

--- **TEST ONLY** — injects mock follower Parts and sets initial state to Active.
--- Legacy seed: populates ONLY `_followerParts` + `_followerStates`.
--- Real pipeline does NOT activate (gate: `#self._positions > 0`).
function FollowerEntityClient._debugSeedActiveFollowers(self: ClassType, parts: { BasePart }): ()
	for i, part in parts do
		self._followerParts[i] = part
		self._followerStates[i] = FOLLOWER_STATE_ACTIVE
	end
end

--- **TEST ONLY** — full-pipeline seed: populates new arrays AND state.
--- Used by integration tests of the wire-in pipeline.
function FollowerEntityClient._debugSeedActivePipeline(
	self: ClassType,
	positions: { Vector3 },
	crowdCenter: Vector3
): ()
	self._lastCrowdCenter = crowdCenter
	for _, pos in positions do
		appendFollowerRow(self, FOLLOWER_STATE_ACTIVE, pos, nil, nil)
	end
end

--- **TEST ONLY** — returns the new _positions array for inspection.
function FollowerEntityClient._debugGetPositions(self: ClassType): { Vector3 }
	return self._positions
end

--- **TEST ONLY** — returns last-frame instrumentation counters.
function FollowerEntityClient._debugGetFrameCounts(
	self: ClassType
): (number, number)
	return self._lastFrameHueWrites, self._lastFrameVfxFlips
end

return FollowerEntityClient
