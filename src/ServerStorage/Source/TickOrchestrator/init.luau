--!strict

--[[
	TickOrchestrator — 15 Hz Server Tick Sequencing
	Implements: ADR-0002 (TickOrchestrator — 15 Hz Server Tick Sequencing)
	Path: ServerStorage/Source/TickOrchestrator/init.luau

	Owns the sole RunService.Heartbeat accumulator for gameplay cadence.
	Every 1/15 s of accumulated dt it runs the 9-phase sequence synchronously.
	Phases are statically wired at boot in ServerScriptService/start.server.luau
	via _registerPhases(). No runtime phase registration.

	Public API:
	  TickOrchestrator.start()                — connect Heartbeat; assert _phases registered
	  TickOrchestrator.stop()                 — disconnect Heartbeat; reset accumulator
	  TickOrchestrator.getCurrentTick()       — returns monotone tick counter
	  TickOrchestrator.setTickDelegate(fn)    — set test/delegate hook (nil clears)
	  TickOrchestrator._registerPhases(t)     — boot-only phase table registration

	Test-only API (_-prefixed):
	  TickOrchestrator._tick(dt)              — factored Heartbeat body; tests call directly
	  TickOrchestrator._resetForTests()       — zero all module state for test isolation
	  TickOrchestrator._getHeartbeatConnection() — identity check for idempotence test
	  TickOrchestrator._getAccumulator()      — verify stop() accumulator reset
--]]

local RunService = game:GetService("RunService")

-- ---------------------------------------------------------------------------
-- Exported types
-- ---------------------------------------------------------------------------

--- Shared context passed to every phase callback within a single tick.
--- outPairs and outPeel are scratch buffers allocated fresh each tick.
--- They are typed as { any } here; CCR/PeelDispatcher modules narrow them
--- to { CollisionPair } and { PeelEntry } respectively.
export type TickContext = {
	tickCount: number,
	outPairs: { any },  -- typed in CCR module as { CollisionPair }
	outPeel: { any },   -- typed in CCR module as { PeelEntry }
}

--- Descriptor for one phase in the 9-phase sequence.
--- phase: integer in [1, 9] — execution order.
--- name: human-readable label for logging and instrumentation.
--- callback: synchronous — must not yield or defer.
export type TickPhase = {
	phase: number,
	name: string,
	callback: (tickCount: number, ctx: TickContext) -> (),
}

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

local _accumulator: number = 0
local _tickCount: number = 0
local _heartbeatConnection: RBXScriptConnection? = nil
local _phases: { TickPhase } = {}
local _tickDelegate: ((number) -> ())? = nil
local _tickPeriod: number = 1 / 15

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Runs one logical tick. If _tickDelegate is set (test mode), calls delegate
--- and returns immediately — phase iteration is bypassed.
--- ADR-0002 §Architecture _runTick + §Simultaneity Resolution L180-185.
--- Implements: story-002 (phase dispatch loop + pcall isolation + ctx assembly)
local function _runTick(tickCount: number): ()
	if _tickDelegate ~= nil then
		_tickDelegate(tickCount)
		return
	end

	-- Per-tick ctx allocated fresh — outPairs/outPeel must NOT bleed across
	-- ticks (ADR-0002 §Architecture). Phase 1 fills outPairs/outPeel; Phase 9
	-- consumes outPeel; intermediate phases pass through.
	local ctx: TickContext = {
		tickCount = tickCount,
		outPairs = {},
		outPeel = {},
	}

	-- Iterate in ascending phase order (1..9). _phases was sorted at
	-- _registerPhases time. pcall isolates per-phase exceptions: a failed
	-- phase logs and lets remaining phases run; next tick recovers.
	-- ADR-0004 forbids xpcall with traceback in hot loops; plain pcall only.
	-- Luau strict-mode pcall infers Rets... from callback signature; when the
	-- callback returns `()`, pcall is typed as `(boolean)` only. Cast the
	-- callback to `(...) -> any` so pcall destructures `(ok, err)` cleanly.
	for i = 1, 9 do
		local phase = _phases[i]
		local cb = phase.callback :: (number, TickContext) -> any
		local ok, err = pcall(cb, tickCount, ctx)
		if not ok then
			warn(string.format(
				"TickOrchestrator: Phase %d (%s) errored at tick %d: %s",
				phase.phase, phase.name, tickCount, tostring(err)
			))
		end
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local TickOrchestrator = {}

--- Registers the static 9-phase table. Must be called exactly once before
--- start(). Asserts: #phases == 9, each entry has phase ∈ [1,9] (unique
--- integer), non-empty name string, and function callback.
--- ADR-0002 §Phase registration — boot-only, static.
function TickOrchestrator._registerPhases(phases: { TickPhase }): ()
	-- Boot-only invariant: ADR-0002 §Architecture forbids re-registration.
	-- _resetForTests() clears _phases for test isolation; production must call once.
	assert(#_phases == 0, "TickOrchestrator: _registerPhases may only be called once at boot")
	assert(typeof(phases) == "table", "TickOrchestrator: phases must be table")
	assert(#phases == 9, "TickOrchestrator: expected 9 phases, got " .. #phases)

	local seen: { [number]: boolean } = {}

	for i, entry in ipairs(phases) do
		assert(
			typeof(entry) == "table",
			"TickOrchestrator: phase entry " .. i .. " must be a table"
		)
		assert(
			typeof(entry.phase) == "number"
				and entry.phase >= 1
				and entry.phase <= 9
				and entry.phase == math.floor(entry.phase),
			"TickOrchestrator: phase value must be integer in [1, 9] (entry " .. i .. ")"
		)
		assert(
			typeof(entry.name) == "string" and #entry.name > 0,
			"TickOrchestrator: name must be non-empty string (entry " .. i .. ")"
		)
		assert(
			typeof(entry.callback) == "function",
			"TickOrchestrator: callback must be function (entry " .. i .. ")"
		)
		assert(
			not seen[entry.phase],
			"TickOrchestrator: duplicate phase value " .. entry.phase
		)
		seen[entry.phase] = true
	end

	-- Sort by phase field once at registration so _runTick iterates in
	-- ascending phase order with O(1) index access — no per-tick sort cost.
	-- ADR-0002 §Architecture _runTick: "for each phase in _phases, ordered 1..9"
	table.sort(phases, function(a, b)
		return a.phase < b.phase
	end)

	_phases = phases
end

--- Connects the sole RunService.Heartbeat accumulator and begins 15 Hz tick
--- dispatch. Idempotent — a second call without an intervening stop() is a
--- no-op (same connection reused). Asserts _registerPhases was called first.
--- ADR-0002 §Decision + §Architecture start().
function TickOrchestrator.start(): ()
	assert(
		#_phases == 9,
		"TickOrchestrator: start() requires _registerPhases first — got " .. #_phases .. " phases"
	)

	-- Idempotent: reuse existing connection (AC-06).
	if _heartbeatConnection ~= nil then
		return
	end

	-- _tick is the live production Heartbeat callback. Its `_`-prefix marks it
	-- as test-callable, not test-exclusive — the same factored body serves both.
	_heartbeatConnection = RunService.Heartbeat:Connect(TickOrchestrator._tick)
end

--- Disconnects the Heartbeat connection and resets the accumulator to 0.
--- Idempotent — calling stop() with no prior start(), or calling it twice,
--- is a no-op. Preserves _tickCount (AC-12).
--- ADR-0002 §Architecture stop().
function TickOrchestrator.stop(): ()
	if _heartbeatConnection == nil then
		return
	end

	_heartbeatConnection:Disconnect()
	_heartbeatConnection = nil
	_accumulator = 0
end

--- Returns the monotone tick counter. Increments after each dispatched tick.
--- Preserved across stop/start cycles (AC-12).
function TickOrchestrator.getCurrentTick(): number
	return _tickCount
end

--- Sets an optional delegate called instead of the phase table on each tick.
--- Pass nil to clear. Intended for integration tests and replay tooling.
--- ADR-0002 §Key Interfaces — test hook.
function TickOrchestrator.setTickDelegate(fn: ((tick: number) -> ())?): ()
	_tickDelegate = fn
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Factored body of the Heartbeat callback. start() wires this function
--- directly to Heartbeat:Connect. Tests call it with synthetic dt to drive
--- the accumulator without a live Heartbeat signal.
--- ADR-0002 §Architecture — accumulator drain loop.
function TickOrchestrator._tick(dt: number): ()
	_accumulator += dt
	while _accumulator >= _tickPeriod do
		_accumulator -= _tickPeriod
		_runTick(_tickCount)
		_tickCount += 1
	end
end

--- **TEST ONLY** — never call from production code.
--- Resets all module-level state to initial values for test isolation.
--- If a Heartbeat connection is live it is disconnected first.
--- Must be called in beforeEach() for every TickOrchestrator spec.
function TickOrchestrator._resetForTests(): ()
	if _heartbeatConnection ~= nil then
		_heartbeatConnection:Disconnect()
		_heartbeatConnection = nil
	end

	_accumulator = 0
	_tickCount = 0
	_phases = {}
	_tickDelegate = nil
end

--- **TEST ONLY** — never call from production code.
--- Returns the current RBXScriptConnection for identity comparison in
--- idempotence tests (AC-06 and AC-10).
function TickOrchestrator._getHeartbeatConnection(): RBXScriptConnection?
	return _heartbeatConnection
end

--- **TEST ONLY** — never call from production code.
--- Returns the current accumulator value so tests can verify stop() resets
--- it to 0 and that sub-tick dt carries forward correctly (AC-08, AC-12).
function TickOrchestrator._getAccumulator(): number
	return _accumulator
end

return TickOrchestrator
