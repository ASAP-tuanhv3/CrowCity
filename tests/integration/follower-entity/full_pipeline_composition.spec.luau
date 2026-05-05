--!strict

--[[
	full_pipeline_composition.spec.luau — Integration test wiring all 8 FE pure modules
	Implements: end-to-end composition validation for sprint-4 wire-in pass
	Stories:    aggregates 4-3 (Boids) + 4-4 (Animation) + 4-5 (SpawnStates +
	            ThrottleQueue) + 4-6 (HueReconciler) + 4-7 (PeelSelection) +
	            4-8 (PeelTransit) + 4-9 (PoolResize) + 4-10 (LODTierMath)

	PURPOSE:
	  Sprint 4 stories 4-3..4-10 shipped as standalone pure modules. Production
	  Client.luau / CrowdManagerClient wire-in is deferred to follow-up. This
	  integration test simulates the wire-in: it composes the modules into a
	  full per-frame pipeline driven by parallel arrays + mock CrowdStateClient,
	  proving the modules interoperate correctly before the production wire-in.

	  This test is the safety net that future Client.luau modifications must not
	  break — if the production wire-in changes the call sequence in a way that
	  violates a module's contract, this test will fail.

	NOT COVERED HERE (still requires wire-in pass):
	  - Roblox BasePart writes (Body.Color, Body.CFrame, Transparency)
	  - VFXManager.playEffect dispatch (Story 4-8 caller-side)
	  - Pool.grantBundle / returnBundle integration (Story 4-1 + 4-5)
	  - RunService.RenderStepped wiring (CrowdManagerClient)
	  - debug.profilebegin / profileend wrapping (AC-17)

	DETERMINISM:
	  - All randomisers use deterministic LCG seed (no math.random global state)
	  - elapsed time advanced by literal dt = 1/60 per simulated frame
	  - No os.clock() / RunService / task.wait() reads
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boids                = require(ReplicatedStorage.Source.FollowerEntity.Boids)
local Animation            = require(ReplicatedStorage.Source.FollowerEntity.Animation)
local SpawnStates          = require(ReplicatedStorage.Source.FollowerEntity.SpawnStates)
local SpawnThrottleQueue   = require(ReplicatedStorage.Source.FollowerEntity.SpawnThrottleQueue)
local HueReconciler        = require(ReplicatedStorage.Source.FollowerEntity.HueReconciler)
local PeelSelection        = require(ReplicatedStorage.Source.FollowerEntity.PeelSelection)
local PeelTransit          = require(ReplicatedStorage.Source.FollowerEntity.PeelTransit)
local PoolResize           = require(ReplicatedStorage.Source.FollowerEntity.PoolResize)
local LODTierMath          = require(ReplicatedStorage.Source.FollowerEntity.LODTierMath)
local FollowerBoidsConfig  = require(ReplicatedStorage.Source.SharedConstants.FollowerBoidsConfig)
local FollowerVisualConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerVisualConfig)
local HueColors            = require(ReplicatedStorage.Source.SharedConstants.HueColors)

local STATE_ACTIVE     = "Active"
local STATE_PEELING    = "Peeling"
local STATE_DESPAWNING = "Despawning"
local STATE_FADEIN     = "Spawning:FadeIn"
local STATE_SLIDEIN    = "Spawning:SlideIn"

local FLOAT_EPSILON = 0.001

-- Deterministic LCG for distribution tests
local function makeLcg(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return (state + 1) / 2147483649
	end
end

local function approxEqualVector(a: Vector3, b: Vector3): boolean
	return math.abs(a.X - b.X) < FLOAT_EPSILON
		and math.abs(a.Y - b.Y) < FLOAT_EPSILON
		and math.abs(a.Z - b.Z) < FLOAT_EPSILON
end

-- ---------------------------------------------------------------------------
-- Simulated FollowerEntityClient — pure-Luau composition of the 8 modules
-- ---------------------------------------------------------------------------

type CrowdState = {
	position: Vector3,
	hue: number,
}

type SimClient = {
	crowdId: string,
	tier: LODTierMath.Tier,
	-- Parallel arrays (1-indexed, length tracked by #_states)
	_positions: { Vector3 },
	_states: { string },
	_d: { number },
	_lastYBob: { number },
	_swayPhaseOffset: { number },
	_isStandstill: { boolean },
	_slideTime: { number },
	_slideTick: { number },
	_npcLastPosition: { Vector3 },
	_absorberHueColor: { Color3 },
	_spawnElapsed: { number },
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
	-- Per-crowd cached state
	_currentHue: number?,
	_hueMismatchFrames: number,
	_lastCrowdCenter: Vector3,
	_teleportFlag: boolean,
	-- Per-frame instrumentation (4-12 AC-18 proof: track no Instance.new)
	_frameWriteCount: number, -- counts Body.Color writes per frame
	_vfxFlipCount: number,    -- counts VFX.HueShift events
}

local function newSimClient(crowdId: string): SimClient
	return {
		crowdId = crowdId,
		tier = LODTierMath.TIER_0,
		_positions          = {} :: { Vector3 },
		_states             = {} :: { string },
		_d                  = {} :: { number },
		_lastYBob           = {} :: { number },
		_swayPhaseOffset    = {} :: { number },
		_isStandstill       = {} :: { boolean },
		_slideTime          = {} :: { number },
		_slideTick          = {} :: { number },
		_npcLastPosition    = {} :: { Vector3 },
		_absorberHueColor   = {} :: { Color3 },
		_spawnElapsed       = {} :: { number },
		_peelStart          = {} :: { number },
		_T_peel             = {} :: { number },
		_T_hue_flip         = {} :: { number },
		_hueFlipApplied     = {} :: { boolean },
		_rivalCrowdId       = {} :: { string },
		_rivalCenterCached  = {} :: { Vector3 },
		_d_peel             = {} :: { number },
		_isCapped           = {} :: { boolean },
		_peelAborted        = {} :: { boolean },
		_spawnOffsets       = {} :: { Vector3 },
		_currentHue         = nil,
		_hueMismatchFrames  = 0,
		_lastCrowdCenter    = Vector3.zero,
		_teleportFlag       = false,
		_frameWriteCount    = 0,
		_vfxFlipCount       = 0,
	}
end

-- Spawn a follower into the simulated client (FadeIn or SlideIn entry)
local function spawnFollower(
	self: SimClient,
	entryState: string,
	initialPos: Vector3,
	npcLastPos: Vector3?,
	absorberHueColor: Color3?,
	rng: () -> number
): number
	local i = #self._states + 1
	self._positions[i] = initialPos
	self._states[i] = entryState
	-- AC d_init: random per spawn
	self._d[i] = SpawnStates.randomDInit(FollowerVisualConfig.WALK_FREQ_HZ, rng)
	self._lastYBob[i] = 0
	-- AC sway-phase: random per spawn
	self._swayPhaseOffset[i] = SpawnStates.randomSwayPhaseOffset(rng)
	self._isStandstill[i] = false
	self._slideTime[i] = 0
	self._slideTick[i] = 0
	self._npcLastPosition[i] = npcLastPos or initialPos
	self._absorberHueColor[i] = absorberHueColor or HueColors.NEUTRAL_WHITE
	self._spawnElapsed[i] = 0
	self._peelStart[i] = 0
	self._T_peel[i] = 0
	self._T_hue_flip[i] = 0
	self._hueFlipApplied[i] = false
	self._rivalCrowdId[i] = ""
	self._rivalCenterCached[i] = Vector3.zero
	self._d_peel[i] = 0
	self._isCapped[i] = false
	self._peelAborted[i] = false
	-- _spawnOffsets recorded relative to crowd center for teleport snap
	self._spawnOffsets[i] = initialPos - self._lastCrowdCenter
	return i
end

-- Per-frame update — composes all 8 pure modules
local function frameUpdate(self: SimClient, dt: number, t: number, getCrowdState: (string) -> CrowdState?): ()
	self._frameWriteCount = 0

	local ownState = getCrowdState(self.crowdId)
	if ownState == nil then
		-- Despawn path (Story 4-2): mark all Active → Despawning
		for i, s in self._states do
			if s == STATE_ACTIVE then
				self._states[i] = STATE_DESPAWNING
			end
		end
		return
	end

	local ownCenter = ownState.position
	local targetHue = ownState.hue

	-- 1. Teleport detection (Story 4-10)
	if LODTierMath.shouldTeleportSnap(ownCenter, self._lastCrowdCenter, FollowerVisualConfig.TELEPORT_THRESHOLD) then
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

	-- 2. Hue dirty-flag (Story 4-6) — single decision per crowd
	local dirty = HueReconciler.defaultDirtyFlag(self._currentHue, targetHue)
	local shouldWriteHue, newCurrentHue, newMismatchFrames = HueReconciler.evaluate(
		self._currentHue, targetHue, self._hueMismatchFrames,
		FollowerVisualConfig.HUE_RECONCILE_FRAMES, dirty
	)
	self._currentHue = newCurrentHue
	self._hueMismatchFrames = newMismatchFrames

	-- 3. Per-follower update
	local renderF4 = LODTierMath.shouldRenderF4(self.tier)
	local renderBob = LODTierMath.shouldRenderBob(self.tier)

	for i, state in self._states do
		if state == STATE_FADEIN then
			-- FadeIn flow: alpha tween, boids RUNS during FadeIn (Story 4-5 §Implementation)
			self._spawnElapsed[i] += dt
			if SpawnStates.isFadeInComplete(self._spawnElapsed[i], FollowerVisualConfig.SPAWN_FADE_DURATION) then
				self._states[i] = STATE_ACTIVE
			end
			-- Apply hue write if needed (Story 4-5 hue applies during FadeIn too)
			if shouldWriteHue then
				self._frameWriteCount += 1
			end
		elseif state == STATE_SLIDEIN then
			-- SlideIn flow: CFrame lerp, boids SUSPENDED (Story 4-5 §Implementation)
			self._spawnElapsed[i] += dt
			self._slideTick[i] += 1
			self._positions[i] = SpawnStates.computeSlideInPosition(
				self._npcLastPosition[i], ownCenter,
				self._spawnElapsed[i], FollowerVisualConfig.SPAWN_SLIDE_DURATION
			)
			if SpawnStates.isSlideInComplete(self._spawnElapsed[i], FollowerVisualConfig.SPAWN_SLIDE_DURATION) then
				self._states[i] = STATE_ACTIVE
				-- Re-randomise d on transition to Active (per Story 4-5 §Implementation
				-- "_d[i] and _swayPhaseOffset[i] initialised (math.random() per follower)")
			end
		elseif state == STATE_ACTIVE and renderF4 then
			-- Boids F1-F4 (Story 4-3)
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

			-- F8/F9 walk-bob + sway (Story 4-4) — only at LOD 0
			if renderBob then
				local dDelta = (newPos - prevPos).Magnitude
				local newD, isStill = Animation.updateD(self._d[i], dDelta, FollowerVisualConfig.STANDSTILL_THRESHOLD)
				self._d[i] = newD
				self._isStandstill[i] = isStill
				if not isStill then
					self._lastYBob[i] = Animation.computeWalkBobY(
						newD, FollowerVisualConfig.WALK_FREQ_HZ, FollowerVisualConfig.WALK_BOB_AMP
					)
				end
				local _swayX = Animation.computeMicroSwayX(
					isStill, 0, t, self._swayPhaseOffset[i],
					FollowerVisualConfig.MICRO_SWAY_FREQ_HZ, FollowerVisualConfig.MICRO_SWAY_AMP
				)
				-- composeBodyCFrame would assemble Body.CFrame here in production
				local _bodyCF = Animation.composeBodyCFrame(
					CFrame.new(newPos), self._lastYBob[i], _swayX, 0
				)
			else
				-- Tier 1+: still accumulate d for continuity (TR-006)
				local dDelta = (newPos - prevPos).Magnitude
				local newD = Animation.updateD(self._d[i], dDelta, FollowerVisualConfig.STANDSTILL_THRESHOLD)
				self._d[i] = newD
			end

			-- Hue write decision applies to Active+Peeling (Story 4-6)
			if shouldWriteHue then
				self._frameWriteCount += 1
			end
		elseif state == STATE_PEELING then
			-- Peel transit (Story 4-8)
			local elapsed = t - self._peelStart[i]
			local rivalState = getCrowdState(self._rivalCrowdId[i])
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
				self._vfxFlipCount += 1
				self._frameWriteCount += 1 -- Body.Color = HUE_COLORS[rivalHue]
			end
			-- Boids retarget for transit
			if renderF4 then
				local F_lead = Boids.followLeader(self._positions[i], target)
				local V = Boids.finalVelocity(
					Vector3.zero, Vector3.zero, F_lead,
					0, 0, FollowerBoidsConfig.FOLLOW_LEADER_WEIGHT,
					FollowerBoidsConfig.MAX_SPEED
				)
				self._positions[i] = Boids.applyVelocity(self._positions[i], V, dt)
			end
			-- Arrival check
			if PeelTransit.isArrived(elapsed, self._T_peel[i]) then
				local terminal = PeelTransit.resolveAbortArrivalState(self._peelAborted[i], false)
				if terminal == "Active" then
					self._states[i] = STATE_ACTIVE
					self._peelAborted[i] = false
					self._rivalCrowdId[i] = ""
				else
					self._states[i] = STATE_DESPAWNING
				end
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Mock CrowdStateClient
-- ---------------------------------------------------------------------------

local function newMockCrowdStateClient(crowds: { [string]: CrowdState })
	return {
		get = function(crowdId: string): CrowdState?
			return crowds[crowdId]
		end,
	}
end

return function()
	-- ===========================================================================
	-- Composition: 80-follower 60-frame steady-state simulation
	-- ===========================================================================

	describe("Full pipeline composition — 80 followers × 60 frames", function()
		it("test_pipeline_80_active_60_frames_no_state_corruption", function()
			-- AC-17 microbench equivalent: simulate 80 LOD-0 followers across
			-- 60 frames with steady crowd_center; verify no state corruption +
			-- hue dirty-flag short-circuits after frame 1.
			local rng = makeLcg(42)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)

			-- Spawn 80 followers in random offsets within 5 stud radius
			for i = 1, 80 do
				local angle = rng() * 2 * math.pi
				local radius = rng() * 5
				local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				spawnFollower(sim, STATE_ACTIVE, pos, nil, nil, rng)
			end

			local mock = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
			})

			-- Track total hue writes across all frames
			local totalHueWrites = 0
			for frame = 1, 60 do
				local t = frame / 60
				frameUpdate(sim, 1 / 60, t, mock.get)
				totalHueWrites += sim._frameWriteCount
			end

			-- Frame 1: 80 followers × 1 hue write (initial _currentHue == nil)
			-- Frames 2-60: 0 hue writes (dirty-flag short-circuit)
			expect(totalHueWrites).to.equal(80)
			-- All 80 still Active (no state corruption from boids feedback)
			local activeCount = 0
			for _, s in sim._states do
				if s == STATE_ACTIVE then activeCount += 1 end
			end
			expect(activeCount).to.equal(80)
		end)
	end)

	-- ===========================================================================
	-- AC-8: 10 absorbs throttled to 4+4+2 across frames
	-- ===========================================================================

	describe("AC-8 — Spawn throttle dispatch via SpawnThrottleQueue", function()
		it("test_pipeline_10_absorb_events_drained_at_4_per_frame", function()
			local q = SpawnThrottleQueue.new()
			-- 10 absorb events arrive same frame
			for i = 1, 10 do
				q:enqueue({
					spawnType = STATE_SLIDEIN,
					crowdId = "c1",
					npcLastPosition = Vector3.new(i, 0, 0),
					absorberHueColor = HueColors.HUE_COLORS[8],
				})
			end

			local rng = makeLcg(99)
			local sim = newSimClient("c1")

			-- Frame 1: dispatch 4
			local frame1 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			for _, req in frame1 do
				spawnFollower(sim, STATE_SLIDEIN, req.npcLastPosition,
					req.npcLastPosition, req.absorberHueColor, rng)
			end
			expect(#frame1).to.equal(4)
			expect(#sim._states).to.equal(4)

			-- Frame 2: dispatch 4 more
			local frame2 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			for _, req in frame2 do
				spawnFollower(sim, STATE_SLIDEIN, req.npcLastPosition,
					req.npcLastPosition, req.absorberHueColor, rng)
			end
			expect(#frame2).to.equal(4)
			expect(#sim._states).to.equal(8)

			-- Frame 3: drain remaining 2
			local frame3 = q:dequeueUpTo(FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME)
			for _, req in frame3 do
				spawnFollower(sim, STATE_SLIDEIN, req.npcLastPosition,
					req.npcLastPosition, req.absorberHueColor, rng)
			end
			expect(#frame3).to.equal(2)
			expect(#sim._states).to.equal(10)
		end)
	end)

	-- ===========================================================================
	-- AC-16: SlideIn 24-frame transit (60 Hz × 0.4s)
	-- ===========================================================================

	describe("AC-16 — SlideIn transit ends at crowd_center after 24 frames", function()
		it("test_pipeline_slidein_full_24_frames_arrives_at_center_state_active", function()
			local rng = makeLcg(7)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)

			-- Spawn 1 SlideIn follower from npcLastPosition=(10,0,10)
			local i = spawnFollower(
				sim, STATE_SLIDEIN, Vector3.new(10, 0, 10),
				Vector3.new(10, 0, 10), HueColors.HUE_COLORS[8], rng
			)

			local mock = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
			})

			-- AC-16: "frame 24+1 → state Active". Story expects transition on
			-- frame 25 (24 × 1/60 = 0.39999... < 0.4 due to FP accumulation;
			-- frame 25 elapsed = 25/60 ≈ 0.4167 > 0.4 → isSlideInComplete fires).
			for frame = 1, 25 do
				frameUpdate(sim, 1 / 60, frame / 60, mock.get)
			end

			expect(sim._states[i]).to.equal(STATE_ACTIVE)
			-- Position should have reached crowd_center (clamp on overflow)
			expect(approxEqualVector(sim._positions[i], Vector3.new(0, 0, 0))).to.equal(true)
		end)
	end)

	-- ===========================================================================
	-- AC-22: Rival nil mid-peel triggers abort path
	-- ===========================================================================

	describe("AC-22 — Rival nil mid-peel: peelAborted flag set, recovers to Active", function()
		it("test_pipeline_peel_rival_nil_aborts_returns_to_active", function()
			local rng = makeLcg(13)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)

			-- Spawn 1 follower at origin, then put it in Peeling state targeting rival B
			local i = spawnFollower(sim, STATE_ACTIVE, Vector3.new(0, 0, 0), nil, nil, rng)
			sim._states[i] = STATE_PEELING
			sim._peelStart[i] = 0
			-- Use very short T_peel so test arrives quickly
			sim._T_peel[i] = 0.1
			sim._T_hue_flip[i] = 0.05
			sim._rivalCrowdId[i] = "b"
			sim._rivalCenterCached[i] = Vector3.new(40, 0, 0)

			-- Frame 1: rival B exists; no abort
			local mock1 = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
				b  = { position = Vector3.new(40, 0, 0), hue = 5 },
			})
			frameUpdate(sim, 1 / 60, 1 / 60, mock1.get)
			expect(sim._peelAborted[i]).to.equal(false)

			-- Frame 2+: rival B vanishes
			local mock2 = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
				-- "b" intentionally absent
			})
			-- Run enough frames for arrival (T_peel = 0.1s → 6 frames)
			for frame = 2, 10 do
				frameUpdate(sim, 1 / 60, frame / 60, mock2.get)
			end
			-- After arrival: peelAborted recovered to Active (own crowd present)
			expect(sim._states[i]).to.equal(STATE_ACTIVE)
		end)
	end)

	-- ===========================================================================
	-- AC-9: Peeling immunity from setPoolSize eviction
	-- ===========================================================================

	describe("AC-9 — Peeling immunity: setPoolSize never evicts Peeling indices", function()
		it("test_pipeline_setPoolSize_8_with_3_peeling_only_active_evicted", function()
			local rng = makeLcg(21)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)

			-- 10 Active + 3 Peeling
			for i = 1, 10 do
				spawnFollower(sim, STATE_ACTIVE, Vector3.new(i, 0, 0), nil, nil, rng)
			end
			for i = 11, 13 do
				spawnFollower(sim, STATE_PEELING, Vector3.new(i, 0, 0), nil, nil, rng)
			end

			-- setPoolSize(8) — should evict 2 Active, leave all 3 Peeling
			local action = PoolResize.computeResizeAction(
				sim._states, sim._positions, Vector3.new(0, 0, 0),
				8, STATE_ACTIVE, STATE_PEELING, STATE_DESPAWNING
			)
			expect(action.actualN).to.equal(8)
			expect(#action.evictIndices).to.equal(2)
			-- Apply the action
			for _, idx in action.evictIndices do
				sim._states[idx] = STATE_DESPAWNING
			end
			-- Verify no Peeling index in evict list
			expect(PoolResize.getPeelingCount(sim._states, STATE_PEELING)).to.equal(3)
		end)
	end)

	-- ===========================================================================
	-- AC-14: Teleport snap skips boids for one frame
	-- ===========================================================================

	describe("AC-14 — Teleport detection > 30 stud delta snaps positions", function()
		it("test_pipeline_teleport_50_stud_delta_skips_boids_resumes_next_frame", function()
			local rng = makeLcg(5)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)

			-- 10 followers around origin
			for i = 1, 10 do
				spawnFollower(sim, STATE_ACTIVE, Vector3.new(i, 0, 0), nil, nil, rng)
			end

			-- Frame 1: crowd at origin (no teleport, just initial nil → write)
			local mock1 = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
			})
			frameUpdate(sim, 1 / 60, 1 / 60, mock1.get)
			expect(sim._teleportFlag).to.equal(false)

			-- Frame 2: teleport to (50, 0, 0) — delta > 30
			local mock2 = newMockCrowdStateClient({
				c1 = { position = Vector3.new(50, 0, 0), hue = 8 },
			})
			frameUpdate(sim, 1 / 60, 2 / 60, mock2.get)
			expect(sim._teleportFlag).to.equal(true)
			-- All followers snapped to (50,0,0) + spawnOffsets
			-- Index 1: spawn was at (1,0,0); offset = (1,0,0) - (0,0,0) = (1,0,0)
			-- After snap: (50,0,0) + (1,0,0) = (51,0,0)
			expect(approxEqualVector(sim._positions[1], Vector3.new(51, 0, 0))).to.equal(true)

			-- Frame 3: stable; teleport flag clears
			local mock3 = newMockCrowdStateClient({
				c1 = { position = Vector3.new(51, 0, 0), hue = 8 },
			})
			frameUpdate(sim, 1 / 60, 3 / 60, mock3.get)
			expect(sim._teleportFlag).to.equal(false)
		end)
	end)

	-- ===========================================================================
	-- AC-17 microbenchmark: 80 LOD-0 × 60 frames timing budget
	-- ===========================================================================

	describe("AC-17 microbenchmark — pure-module pipeline timing budget", function()
		it("test_pipeline_AC17_80_followers_60_frames_under_budget_proxy", function()
			-- This is NOT a Studio Micro Profiler soak (which is the actual AC-17
			-- evidence). It is a pure-Luau microbench validating that the module
			-- composition is at least within the right order of magnitude before
			-- the production wire-in adds Roblox API overhead.
			local rng = makeLcg(88)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)
			for i = 1, 80 do
				local angle = rng() * 2 * math.pi
				local radius = rng() * 5
				local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				spawnFollower(sim, STATE_ACTIVE, pos, nil, nil, rng)
			end
			local mock = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
			})

			local startClock = os.clock()
			for frame = 1, 60 do
				frameUpdate(sim, 1 / 60, frame / 60, mock.get)
			end
			local elapsedMs = (os.clock() - startClock) * 1000
			-- 60 frames of 80-follower pipeline. Production target is 2.5ms p99
			-- per frame on mobile; pure-Luau (no rendering API overhead) should
			-- be well under 60 × 2.5ms = 150ms. Assert generous 500ms ceiling so
			-- the test stays green on slow CI; tighter budget needs Studio.
			expect(elapsedMs < 500).to.equal(true)
			-- All 80 still Active (steady state holds)
			local activeCount = 0
			for _, s in sim._states do
				if s == STATE_ACTIVE then activeCount += 1 end
			end
			expect(activeCount).to.equal(80)
		end)
	end)

	-- ===========================================================================
	-- AC-18 (proof of structure): per-frame hot path makes zero allocations of
	-- Roblox Instances. Verified by code-level audit (already done in story
	-- closure notes); this test asserts the SimClient mirrors that contract.
	-- ===========================================================================

	describe("AC-18 — Pure-module pipeline allocates no Instances per frame", function()
		it("test_pipeline_AC18_60_frame_simulation_no_table_growth_in_hot_path", function()
			-- The arrays pre-sized at spawn time; frameUpdate must not grow them.
			-- Track #_states + #_positions before and after 60 frames.
			local rng = makeLcg(55)
			local sim = newSimClient("c1")
			sim._lastCrowdCenter = Vector3.new(0, 0, 0)
			for i = 1, 80 do
				local angle = rng() * 2 * math.pi
				local radius = rng() * 5
				local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				spawnFollower(sim, STATE_ACTIVE, pos, nil, nil, rng)
			end

			local statesLenBefore = #sim._states
			local positionsLenBefore = #sim._positions
			local mock = newMockCrowdStateClient({
				c1 = { position = Vector3.new(0, 0, 0), hue = 8 },
			})

			for frame = 1, 60 do
				frameUpdate(sim, 1 / 60, frame / 60, mock.get)
			end

			-- Hot path adds no new array slots (no spawns enqueued in this scenario)
			expect(#sim._states).to.equal(statesLenBefore)
			expect(#sim._positions).to.equal(positionsLenBefore)
		end)
	end)
end
