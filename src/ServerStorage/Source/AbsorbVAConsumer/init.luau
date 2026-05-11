--!strict

--[[
	AbsorbVAConsumer — V/A subscriber for AbsorbSystem.AbsorbedSignal.
	Path: ServerStorage/Source/AbsorbVAConsumer/init.luau

	Implements:
	  Story 7-9 / absorb-system story-006: VFX AbsorbSnap + audio batching +
	  streak escalation.

	Design doc: design/gdd/absorb-system.md §V/A Requirements + AC-14/15/16
	ADR governance: ADR-0004 §Pillar 4 (cosmetic systems read-only)

	Layer: Presentation (consumer of server-side AbsorbedSignal).
	Singleton module — no .new() constructor.

	Public surface:
	  AbsorbVAConsumer.init(deps)      — DI: vfxManager?, audioManager?, clock?
	  AbsorbVAConsumer.start()         — connects to AbsorbSystem.AbsorbedSignal
	  AbsorbVAConsumer.stop()          — disconnects + clears state
	  AbsorbVAConsumer.flushTick()     — drains per-tick batch (called per tick)

	DI seams (Story 7-9 ships Logic-only; full VFX/Audio managers land in
	dedicated VFX / Audio epics):
	  vfxManager: { playEffect: (effectId, context) -> () }? — nil → log only
	  audioManager: { playBatched: (crowdId, pitch, volume) -> () }? — nil → log only
	  streakEscalation: BindableEvent? — fires on 10-in-3s streak per crowd

	Control Manifest:
	  - VFXManager funnel via single playEffect API (when present)
	  - Read-only — never mutates CSM state
	  - VFX cap: ABSORB_PER_FRAME_CAP = 6 particles/tick (ADR-0003 §Instance Caps)
--]]

local AbsorbSystem = require(script.Parent.AbsorbSystem)

local AbsorbVAConsumer = {}

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

--- Per-tick VFX particle cap. Per ADR-0003 §Instance Caps. Overflow plays
--- sound but skips particles (silent count tracked for QA visibility).
local ABSORB_PER_FRAME_CAP = 6

--- Streak escalation window in seconds. 10 absorbs within this window →
--- pitch +0.3 + StreakEscalation signal.
local STREAK_WINDOW_SEC = 3.0
local STREAK_THRESHOLD = 10

--- Audio pitch + volume tiers by batch count (per tick per crowd).
--- Tier 1: 1 absorb baseline
--- Tier 2: 2-4 absorbs → pitch +0.15, vol +20%
--- Tier 3: 5+ absorbs → pitch +0.20, vol +30%
local PITCH_BASELINE = 1.0
local PITCH_TIER2 = 1.15
local PITCH_TIER3 = 1.20
local PITCH_STREAK_BONUS = 0.10  -- added on top of tier when streak escalated (total +0.30 from tier 3)
local VOLUME_BASELINE = 1.0
local VOLUME_TIER2 = 1.20
local VOLUME_TIER3 = 1.30

-- ---------------------------------------------------------------------------
-- DI + state
-- ---------------------------------------------------------------------------

type VFXManager = {
	playEffect: (effectId: string, context: { position: Vector3, crowdId: string }) -> (),
}
type AudioManager = {
	playBatched: (crowdId: string, pitch: number, volume: number) -> (),
}

local _vfxManager: VFXManager? = nil
local _audioManager: AudioManager? = nil
local _clock: (() -> number)? = nil

--- Per-crowd batch state for current tick.
--- {[crowdId] = { count: number, lastPos: Vector3 }}
type BatchEntry = { count: number, lastPos: Vector3 }
local _batch: { [string]: BatchEntry } = {}

--- Per-crowd streak ring buffer (timestamps of absorbs within STREAK_WINDOW_SEC).
--- {[crowdId] = { number }}
local _streak: { [string]: { number } } = {}

--- Per-crowd "streak active" flag — true after threshold reached; prevents
--- StreakEscalation signal from re-firing on each subsequent absorb in window.
--- Cleared when streak buffer drops below threshold.
local _streakActive: { [string]: boolean } = {}

--- Per-tick particle count for ABSORB_PER_FRAME_CAP enforcement. Reset on flush.
local _particleCountThisTick = 0

--- Signal connection handle (cleanup target).
local _connection: RBXScriptConnection? = nil

--- Optional BindableEvent for streak signal — exposed publicly so PlayerNameplate
--- (separate epic) can subscribe. Lazily created on first init.
local _streakEscalationEvent: BindableEvent? = nil

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

local function getClock(): number
	if _clock ~= nil then
		return (_clock :: () -> number)()
	end
	return os.clock()
end

--- Computes pitch + volume for the per-crowd batch count + streak state.
local function tierFor(count: number, streakActive: boolean): (number, number)
	local pitch, volume
	if count >= 5 then
		pitch = PITCH_TIER3
		volume = VOLUME_TIER3
	elseif count >= 2 then
		pitch = PITCH_TIER2
		volume = VOLUME_TIER2
	else
		pitch = PITCH_BASELINE
		volume = VOLUME_BASELINE
	end
	if streakActive then
		pitch = pitch + PITCH_STREAK_BONUS
	end
	return pitch, volume
end

--- Append timestamp to crowd's streak ring buffer; evict entries older than
--- STREAK_WINDOW_SEC. Returns whether streak threshold was just crossed.
local function pushStreak(crowdId: string, now: number): boolean
	local buf = _streak[crowdId]
	if buf == nil then
		buf = {}
		_streak[crowdId] = buf
	end
	-- Evict timestamps outside window.
	local writeIdx = 1
	for _, ts in ipairs(buf) do
		if now - ts < STREAK_WINDOW_SEC then
			buf[writeIdx] = ts
			writeIdx += 1
		end
	end
	for i = #buf, writeIdx, -1 do
		buf[i] = nil
	end
	-- Append current.
	table.insert(buf, now)

	-- Streak active when >= threshold; signal fires on entry, not every absorb.
	if #buf >= STREAK_THRESHOLD then
		if not _streakActive[crowdId] then
			_streakActive[crowdId] = true
			return true  -- crossed threshold this absorb
		end
	else
		-- Dropped below threshold → reset active flag.
		if _streakActive[crowdId] then
			_streakActive[crowdId] = false
		end
	end
	return false
end

--- BindableEvent callback. Captures one absorb event into batch + streak state.
--- Does NOT play sound or VFX inline — those happen in flushTick.
local function onAbsorbed(crowdId: string, npcPos: Vector3): ()
	local now = getClock()

	-- Batch state for current tick.
	local entry = _batch[crowdId]
	if entry == nil then
		entry = { count = 0, lastPos = npcPos }
		_batch[crowdId] = entry
	end
	entry.count += 1
	entry.lastPos = npcPos

	-- Streak tracking — fires escalation signal on threshold crossing.
	local justCrossed = pushStreak(crowdId, now)
	if justCrossed then
		local ev = _streakEscalationEvent
		if ev ~= nil then
			ev:Fire(crowdId)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Optional BindableEvent exposed for PlayerNameplate consumer (separate epic).
--- Fires once per (crowdId, streak-entry) — does NOT re-fire on subsequent
--- absorbs within the same streak window.
AbsorbVAConsumer.StreakEscalation = nil :: BindableEvent?

--- Initialises consumer with DI. All deps optional — nil deps gracefully
--- degrade to log-only (useful before VFX / Audio epics ship).
function AbsorbVAConsumer.init(deps: {
	vfxManager: VFXManager?,
	audioManager: AudioManager?,
	clock: (() -> number)?,
}?): ()
	if deps ~= nil then
		_vfxManager = deps.vfxManager
		_audioManager = deps.audioManager
		_clock = deps.clock
	end

	-- Lazy-create streak BindableEvent on first init.
	if _streakEscalationEvent == nil then
		_streakEscalationEvent = Instance.new("BindableEvent")
		_streakEscalationEvent.Name = "AbsorbVA_StreakEscalation"
		AbsorbVAConsumer.StreakEscalation = _streakEscalationEvent
	end
end

--- Connects to AbsorbSystem.AbsorbedSignal. Idempotent — second call no-ops.
function AbsorbVAConsumer.start(): ()
	if _connection ~= nil then
		return
	end
	local signal = AbsorbSystem.AbsorbedSignal :: BindableEvent
	_connection = signal.Event:Connect(onAbsorbed)
end

--- Disconnects + clears all state. Idempotent.
function AbsorbVAConsumer.stop(): ()
	if _connection ~= nil then
		_connection:Disconnect()
		_connection = nil
	end
	_batch = {}
	_streak = {}
	_streakActive = {}
	_particleCountThisTick = 0
end

--- Drains the per-tick batch — plays at most 1 sound per crowd (with batched
--- pitch/volume tier) AND fires up to ABSORB_PER_FRAME_CAP VFX particles
--- across all crowds combined. Excess particles are tracked in counter but
--- skipped (sound still plays for the suppressed absorbs).
---
--- Caller: per-tick orchestrator (e.g. TickOrch could wire this). Until that
--- wiring lands, the test seam `_flushForTest()` drives flush directly.
function AbsorbVAConsumer.flushTick(): ()
	_particleCountThisTick = 0
	for crowdId, entry in pairs(_batch) do
		local pitch, volume = tierFor(entry.count, _streakActive[crowdId] == true)

		-- Audio: exactly 1 play per crowd per tick (the batch contract).
		if _audioManager ~= nil then
			(_audioManager :: AudioManager).playBatched(crowdId, pitch, volume)
		end

		-- VFX: one particle per absorb up to per-frame cap (shared across crowds).
		local visibleParticles = math.min(entry.count, ABSORB_PER_FRAME_CAP - _particleCountThisTick)
		if visibleParticles > 0 then
			if _vfxManager ~= nil then
				for _ = 1, visibleParticles do
					(_vfxManager :: VFXManager).playEffect("AbsorbSnap", {
						position = entry.lastPos,
						crowdId = crowdId,
					})
				end
			end
			_particleCountThisTick += visibleParticles
		end
	end
	-- Clear batch for next tick.
	_batch = {}
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — manually drive a tick flush without wiring TickOrch.
function AbsorbVAConsumer._flushForTest(): ()
	AbsorbVAConsumer.flushTick()
end

--- **TEST ONLY** — directly inject an Absorbed event without firing the
--- real BindableEvent. Useful for batch + streak unit tests.
function AbsorbVAConsumer._injectAbsorbedForTest(crowdId: string, npcPos: Vector3): ()
	onAbsorbed(crowdId, npcPos)
end

--- **TEST ONLY** — returns current batch state (read-only inspection).
function AbsorbVAConsumer._getBatchForTest(): { [string]: BatchEntry }
	return _batch
end

--- **TEST ONLY** — returns current streak buffer for inspection.
function AbsorbVAConsumer._getStreakBufferForTest(crowdId: string): { number }?
	return _streak[crowdId]
end

--- **TEST ONLY** — returns true if streak threshold currently active for crowd.
function AbsorbVAConsumer._isStreakActiveForTest(crowdId: string): boolean
	return _streakActive[crowdId] == true
end

--- **TEST ONLY** — particle count for current tick (post-flush returns 0).
function AbsorbVAConsumer._getParticleCountThisTickForTest(): number
	return _particleCountThisTick
end

--- **TEST ONLY** — resets all module state. Use in beforeEach.
function AbsorbVAConsumer._resetForTests(): ()
	AbsorbVAConsumer.stop()
	_vfxManager = nil
	_audioManager = nil
	_clock = nil
end

return AbsorbVAConsumer
