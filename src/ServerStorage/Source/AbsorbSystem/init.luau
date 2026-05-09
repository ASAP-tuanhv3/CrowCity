--!strict

--[[
	AbsorbSystem — Phase 3 tick callback: crowd-overlap absorb processing.
	Path: ServerStorage/Source/AbsorbSystem/init.luau

	Implements:
	  Story 5-10: Phase 3 callback skeleton + DI scaffold (TR-absorb-001)
	  Story 5-11: F1 overlap test + F2 contention resolution (TR-absorb-002, TR-absorb-003)
	  Story 5-12: Per-overlap sequence + reclaim contract + snapshot atomicity
	              (TR-absorb-004, TR-absorb-007)
	  Story 5-13: State guards — Active/GraceWindow allow, Eliminated skip
	              (TR-absorb-006, TR-absorb-008, TR-absorb-012)
	  Story 5-14: Count clamp passthrough + Absorbed reliable RemoteEvent
	              (TR-absorb-005, TR-absorb-011)

	Design doc: design/gdd/absorb-system.md
	ADR governance: ADR-0002 (TickOrchestrator), ADR-0004 (CSM Authority),
	                ADR-0006 (Module Placement), ADR-0008 (NPC Spawner Authority),
	                ADR-0010 (Server-Authoritative Validation)

	Singleton module: module-level state only. No .new() constructor.
	Mirror style: ServerStorage/Source/CrowdStateServer/init.luau.

	Public surface:
	  AbsorbSystem.init(deps)         — DI: csm, npcSpawner, network, optional clock
	  AbsorbSystem.tick(tickCount, ctx) — Phase 3 callback; registered with TickOrchestrator

	Control Manifest:
	  - AbsorbSystem is sole caller of csm.getAllActiveNPCs() [ADR-0008]
	  - AbsorbSystem is sole caller of npcSpawner.reclaim(npcId) [ADR-0008]
	  - AbsorbSystem is sole caller of csm.updateCount(crowdId, +1, "Absorb") [ADR-0004 Pillar 4]
	  - FORBIDDEN: yield inside tick (task.wait / task.defer / async) [ADR-0002]
	  - FORBIDDEN: own RunService.Heartbeat:Connect [ADR-0002]
	  - FORBIDDEN: if count >= 300 guard (clamp lives in CSM F5) [Story 5-14 AC-9]
	  - FORBIDDEN: csm.transitionTo* / any state-transition call [ADR-0004]
	  - FORBIDDEN: mutate table returned by csm.getAllActive() [ADR-0004]
	  - FORBIDDEN: mutate frozen snapshot from npcSpawner.getAllActiveNPCs() [ADR-0008]

	F1 overlap formula (2D squared-distance, no sqrt — GDD §Overlap test):
	  overlaps = (dx² + dz²) <= radius²
	  Y-axis ignored (city map elevation variance; ADR-0010 §Server-Authoritative).

	F2 contention (GDD §Contention resolution):
	  For each NPC: argmin(distSq) across all overlapping crowds.
	  Tiebreak on equal distSq: lower crowdId string (lexicographic, deterministic).
	  Exactly ONE Absorbed event + ONE updateCount per NPC per tick.

	Per-overlap sequence (Story 5-12 AC-6; Story 5-14 implementation notes):
	  1. Fire Absorbed BindableEvent (intra-server V/A consumers)
	  2. Fire Absorbed RemoteEvent via Network.fireAllClients (client-side replication)
	  3. Call csm.updateCount(crowdId, +1, "Absorb")
	  4. Call npcSpawner.reclaim(npcId)

	Snapshot atomicity (Story 5-12 AC-12):
	  getAllActiveNPCs() called ONCE at tick start; same frozen snapshot iterated for
	  entire tick body even though reclaim() mutates underlying spawner state.

	State guards (Story 5-13):
	  crowd.state == "Eliminated" → skip crowd entirely (no overlap test, no updateCount).
	  "Active" and "GraceWindow" → process normally.

	Intra-server BindableEvent (Story 5-14):
	  AbsorbSystem.AbsorbedSignal — subscribe via AbsorbSystem.AbsorbedSignal.Event:Connect(fn)
	  Payload: (crowdId: string, npcLastPosition: Vector3)
	  Fired synchronously inside the tick; zero latency for V/A consumers.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

-- ---------------------------------------------------------------------------
-- Exported types
-- ---------------------------------------------------------------------------

--- Intra-server BindableEvent for V/A consumers (VFX, audio).
--- Payload: (crowdId: string, npcLastPosition: Vector3).
--- Story 5-14: parallel to reliable RemoteEvent; zero-latency for server-side consumers.
local _absorbedSignal: BindableEvent = Instance.new("BindableEvent")
_absorbedSignal.Name = "AbsorbSystem_AbsorbedSignal"

-- ---------------------------------------------------------------------------
-- Module-level DI state (set by init(), consumed by tick())
-- ---------------------------------------------------------------------------

--- CrowdStateServer — provides getAllActive() and updateCount().
--- Type: any (DI surface; production = real CSM; tests = mock).
local _csm: any = nil

--- NPCSpawner — provides getAllActiveNPCs() and reclaim().
--- Type: any (DI surface; production = real NPCSpawner; tests = mock).
local _npcSpawner: any = nil

--- Network module — provides fireAllClients() for reliable Absorbed event.
--- Type: any (DI surface; production = real Network; tests = mock).
local _network: any = nil

--- Optional injected clock function () -> number. Default: os.clock.
--- Tests inject a controllable clock for deterministic time assertions.
local _clock: (() -> number)? = nil

--- Guard: true after init() completes. Prevents tick from running without DI.
local _initialized = false

--- Story 7-2: production default for diagnostic logging. Always false in
--- production. Override only via AbsorbSystem._setDiagnosticLoggingForTest.
--- Diagnostic disambiguates BUG-001 root causes (silent no-op paths at
--- AC-10 / AC-11 early returns) when investigating in Studio playtest.
local DIAGNOSTIC_LOGGING_DEFAULT: boolean = false
local _diagnosticLoggingEnabled: boolean = DIAGNOSTIC_LOGGING_DEFAULT

--- Story 7-2: log sink function. Default: print. Tests inject a spy.
local _diagnosticLogFn: (string) -> () = print

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Returns current clock value (seconds). Uses DI override when set.
local function getClock(): number
	if _clock ~= nil then
		return (_clock :: () -> number)()
	end
	return os.clock()
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local AbsorbSystem = {}

--- Intra-server BindableEvent — subscribe via AbsorbSystem.AbsorbedSignal.Event:Connect(fn).
--- Fired once per absorbed NPC with payload (crowdId: string, npcLastPosition: Vector3).
--- V/A consumers (VFX snap, audio streak — Story 5-14 / Story 006) subscribe here.
AbsorbSystem.AbsorbedSignal = _absorbedSignal

--- Initialises AbsorbSystem with injected dependencies. Call ONCE at server boot,
--- before TickOrchestrator.start(). All deps are required (csm, npcSpawner, network).
--- Optional: clock (injectable for tests).
---
--- Asserts at init time (not at tick time) if any required dep is nil.
--- Re-init with same deps is idempotent (module fields overwritten with equal values).
---
--- ADR-0002 §Phase Registration: callback registered at boot wiring in start.server.luau
--- AFTER this init() call completes.
---
--- deps fields: csm (CrowdStateServer), npcSpawner (NPCSpawner), network (Network module),
---              clock (optional () -> number for test injection).
function AbsorbSystem.init(deps: {
	csm: any,
	npcSpawner: any,
	network: any,
	clock: (() -> number)?,
}): ()
	assert(deps ~= nil, "AbsorbSystem.init: deps must be a table")
	assert(deps.csm ~= nil, "AbsorbSystem.init: deps.csm is required (CrowdStateServer)")
	assert(deps.npcSpawner ~= nil, "AbsorbSystem.init: deps.npcSpawner is required (NPCSpawner)")
	assert(deps.network ~= nil, "AbsorbSystem.init: deps.network is required (Network module)")

	_csm = deps.csm
	_npcSpawner = deps.npcSpawner
	_network = deps.network
	_clock = deps.clock  -- nil is valid; falls back to os.clock

	_initialized = true
end

--- Phase 3 tick callback. Registered with TickOrchestrator via _registerPhases.
--- Must NOT yield. Must NOT own a RunService.Heartbeat (ADR-0002).
---
--- Body outline (all stories integrated):
---   1. Early-return: csm.getAllActive() empty → skip getAllActiveNPCs entirely (AC-10).
---   2. Take ONE frozen NPC snapshot at tick start (snapshot atomicity, AC-12).
---   3. Build per-tick crowd cache (crowdId, posX, posZ, radiusSq, state) from getAllActive().
---   4. Skip "Eliminated" crowds in cache (Story 5-13 AC-7).
---   5. F1 overlap pass: for each NPC in snapshot × each non-Eliminated crowd,
---      test (dx² + dz²) <= radiusSq. Accumulate candidate list per NPC.
---   6. F2 contention per NPC: argmin(distSq) → lex tiebreak on crowdId.
---   7. Accumulate winning overlaps: {crowdId, npcId, npcPos}.
---   8. Per-overlap sequence: BindableEvent → RemoteEvent → updateCount → reclaim.
---
--- @param tickCount number — monotone tick counter from TickOrchestrator.
--- @param _ctx any — TickContext (unused by AbsorbSystem; required by phase signature).
function AbsorbSystem.tick(tickCount: number, _ctx: any): ()
	local __ = getClock()  -- clock accessible for instrumentation; unused in MVP

	-- Guard: init() must have been called (DI established).
	assert(_initialized, "AbsorbSystem.tick: called before init() — call AbsorbSystem.init(deps) at boot")

	-- 1. Enumerate active crowds. Early-return if none (AC-10: getAllActiveNPCs NOT called).
	--    csm.getAllActive() returns fresh array excluding Eliminated (CSM story-007).
	--    However, getAllActive() already excludes Eliminated per CSM implementation.
	--    We additionally guard below (Story 5-13) to match spec AC-7 exactly.
	local allCrowds: { any } = _csm.getAllActive()

	if allCrowds == nil or #allCrowds == 0 then
		-- Story 7-2: diagnostic log — crowds=0 path. AC-10 preserved: getAllActiveNPCs
		-- NOT called; log emits literal "npcs=skipped" instead of a count.
		if _diagnosticLoggingEnabled and tickCount % 15 == 0 then
			_diagnosticLogFn(string.format(
				"[AbsorbSystem] tick %d crowds=0 npcs=skipped",
				tickCount
			))
		end
		-- AC-10: zero crowds → inner NPC loop body NEVER entered (getAllActiveNPCs NOT called).
		return
	end

	-- 2. Snapshot atomicity (AC-12): ONE call to getAllActiveNPCs at tick start.
	--    The returned table is frozen — mutation raises a Lua error.
	--    Iteration proceeds over this snapshot even though reclaim() mutates spawner state.
	local npcSnapshot: { any } = _npcSpawner.getAllActiveNPCs()

	-- Story 7-2: diagnostic log — both arrays read. Fires regardless of whether
	-- npcSnapshot is empty so AC-11 silent no-op is observable in Studio.
	if _diagnosticLoggingEnabled and tickCount % 15 == 0 then
		_diagnosticLogFn(string.format(
			"[AbsorbSystem] tick %d crowds=%d npcs=%d",
			tickCount,
			#allCrowds,
			#npcSnapshot
		))
	end

	if npcSnapshot == nil or #npcSnapshot == 0 then
		-- AC-11: 1 Active crowd + empty NPC snapshot → no Absorbed signals, no errors.
		return
	end

	-- 3. Build per-tick crowd cache from getAllActive() result.
	--    Story 5-11: cache {crowdId, posX, posZ, radiusSq} to avoid per-NPC table indexing.
	--    Story 5-13: skip "Eliminated" crowds here (CSM getAllActive() may include GraceWindow).
	--    Note: CrowdStateServer.getAllActive() already excludes Eliminated per its implementation.
	--    We explicitly check `state ~= "Eliminated"` as a defence-in-depth guard (AC-7).
	type CrowdEntry = { crowdId: string, posX: number, posZ: number, radiusSq: number }
	local crowdCache: { CrowdEntry } = {}

	for _, crowd in ipairs(allCrowds) do
		-- Story 5-13 AC-7: skip Eliminated crowds entirely.
		-- Story 5-13 AC-8: Active AND GraceWindow are allowed through.
		-- Story 5-13 AC-13: no state-transition calls issued from AbsorbSystem.
		if crowd.state == "Eliminated" then
			continue
		end

		-- F1: Y-axis explicitly dropped. Read position.X and position.Z only.
		local posX = crowd.position.X
		local posZ = crowd.position.Z
		local radius = crowd.radius
		local radiusSq = radius * radius  -- pre-squared once per crowd per tick (perf)

		table.insert(crowdCache, {
			crowdId = crowd.crowdId :: string,
			posX = posX,
			posZ = posZ,
			radiusSq = radiusSq,
		})
	end

	if #crowdCache == 0 then
		-- All crowds were Eliminated — nothing to process.
		return
	end

	-- 4-6. F1 overlap pass + F2 contention resolution.
	--      Accumulate winning overlaps in a deferred list.
	--      Running sequence after the pass keeps the overlap-pass body branchless
	--      (Story 5-12 implementation notes).
	type WinningOverlap = { crowdId: string, npcId: string, npcPos: Vector3 }
	local pendingAbsorbs: { WinningOverlap } = {}

	for _, npc in ipairs(npcSnapshot) do
		-- For each NPC, run F1 against every crowd and collect candidates.
		-- F2: track best (lowest distSq); on equal distSq, lower crowdId (lex) wins.
		local bestCrowdId: string? = nil
		local bestDistSq: number = math.huge

		local npcX = npc.position.X
		local npcZ = npc.position.Z

		for _, entry in ipairs(crowdCache) do
			local dx = npcX - entry.posX
			local dz = npcZ - entry.posZ
			local distSq = dx * dx + dz * dz

			-- F1 overlap test: squared distance vs squared radius (no math.sqrt).
			if distSq <= entry.radiusSq then
				-- F2 contention: argmin(distSq), lex tiebreak on equal distSq.
				-- Combined first-candidate + closer-crowd branches (both update best pair).
				if bestCrowdId == nil or distSq < bestDistSq then
					bestCrowdId = entry.crowdId
					bestDistSq = distSq
				elseif distSq == bestDistSq then
					-- Equal distance: lower crowdId string (lexicographic) wins.
					-- bestDistSq is NOT updated — distances are equal by definition.
					if entry.crowdId < (bestCrowdId :: string) then
						bestCrowdId = entry.crowdId
					end
				end
			end
		end

		-- If a winning crowd was found, queue the absorb.
		if bestCrowdId ~= nil then
			table.insert(pendingAbsorbs, {
				crowdId = bestCrowdId :: string,
				npcId = npc.npcId :: string,
				npcPos = npc.position :: Vector3,
			})
		end
	end

	-- 7. Per-overlap sequence (Story 5-12 AC-6; Story 5-14):
	--    For each winning overlap (in snapshot iteration order — deterministic):
	--      a. Fire intra-server AbsorbedSignal BindableEvent (V/A consumers, Story 006).
	--      b. Fire Absorbed reliable RemoteEvent via Network.fireAllClients (client replication).
	--      c. Call csm.updateCount(crowdId, +1, "Absorb") — sole authorized caller (ADR-0004).
	--      d. Call npcSpawner.reclaim(npcId) — sole authorized caller (ADR-0008).
	--         Synchronous per ADR-0008 §Lifecycle Contract; postconditions before return.
	--
	--    Story 5-14 AC-9: NO `if count >= 300` guard here — clamp lives in CSM F5.
	--    Story 5-14: reliable RemoteEvent (not UnreliableRemoteEvent) per ADR-0010.
	for _, overlap in ipairs(pendingAbsorbs) do
		local crowdId = overlap.crowdId
		local npcId = overlap.npcId
		local npcPos = overlap.npcPos

		-- Step a: intra-server BindableEvent — zero latency for V/A consumers.
		_absorbedSignal:Fire(crowdId, npcPos)

		-- Step b: reliable RemoteEvent — must-arrive discrete event for client VFX snap.
		--         ADR-0001 §Reliable Gameplay Events; ADR-0010 §Reliable-vs-Unreliable.
		--         Payload: (crowdId: string, npcLastPosition: Vector3).
		_network.fireAllClients(RemoteEventName.Absorbed, crowdId, npcPos)

		-- Step c: count mutation — CSM F5 clamp [1, 300] applied internally.
		--         AbsorbSystem passes +1 unconditionally (AC-9: no AbsorbSide guard).
		_csm.updateCount(crowdId, 1, "Absorb")

		-- Step d: NPC reclaim — synchronous; postconditions before return.
		--         ADR-0008 §Lifecycle Contract: active=false, removed from snapshot, parked.
		_npcSpawner.reclaim(npcId)
	end
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Resets all module-level DI state for TestEZ isolation.
--- Allows re-initialisation in the same Luau session (required by beforeEach/afterEach).
function AbsorbSystem._resetForTests(): ()
	_csm = nil
	_npcSpawner = nil
	_network = nil
	_clock = nil
	_initialized = false
	_diagnosticLoggingEnabled = DIAGNOSTIC_LOGGING_DEFAULT
	_diagnosticLogFn = print
end

--- **TEST ONLY** — never call from production code.
--- Returns whether init() has completed. Tests use this to verify DI assertion timing.
function AbsorbSystem._isInitialized(): boolean
	return _initialized
end

--- **TEST ONLY** — never call from production code.
--- Story 7-2: controls diagnostic logging flag and redirects log output to a
--- spy callback. Pass nil for logCallback to restore default `print` sink.
--- Test seam for `tests/unit/absorb/diagnostic_logging.spec.luau`.
function AbsorbSystem._setDiagnosticLoggingForTest(
	enabled: boolean,
	logCallback: ((string) -> ())?
): ()
	_diagnosticLoggingEnabled = enabled
	_diagnosticLogFn = logCallback or print
end

return AbsorbSystem
