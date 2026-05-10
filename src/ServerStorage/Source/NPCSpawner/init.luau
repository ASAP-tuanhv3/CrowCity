--!strict

--[[
	NPCSpawner — sole authority for the 300-Part neutral NPC pool.
	Path: ServerStorage/Source/NPCSpawner/init.luau
	Implements: TR-npc-spawner-001 (pool + chunked alloc)
	            TR-npc-spawner-003 (zero mid-round Part alloc)
	            TR-npc-spawner-011 (ARENA_WALKABLE_AREA_SQ boot guard)
	            TR-npc-spawner-012 (ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ)
	            TR-npc-spawner-013 superseded by ADR-0008 §Cadence Exemption —
	              own RunService.Heartbeat:Connect (non-gameplay-tick, ADR-0002 §Related
	              Decisions L289 exemption). Follow ADR-0008, not TR-013.
	            TR-npc-spawner-004 (walk loop + boundary reflection, Story 004)
	            TR-npc-spawner-005 (reclaim synchronous, Story 002)
	            TR-npc-spawner-006 (getAllActiveNPCs frozen snapshot, Story 003)
	            TR-npc-spawner-002 (respawn pipeline, Story 005)
	            TR-npc-spawner-009 (respawn fade-in, Story 006)
	            TR-npc-spawner-014 (density guards F2/F4, Story 008)
	            TR-npc-spawner-015/016 (UREvent broadcast, Story 009)
	            ADR-0008 §Architecture + §Boot + Round Lifecycle + §Cadence Exemption
	            ADR-0006 §Source Tree Map (server-only module placement)

	Story 5-1 scope: init() + pre-allocation + Heartbeat connect/disconnect lifecycle
	  + ARENA_WALKABLE_AREA_SQ validation + ρ_design constant + getDesignDensity().
	Story 5-2: reclaim() synchronous + double-reclaim assert.
	Story 5-3: getAllActiveNPCs() frozen snapshot + cache invalidation.
	Story 5-4: idle walk + boundary reflection (_movementTick body).
	Story 5-5: respawn pipeline — delay, position, crowd exclusion, fallback.
	Story 5-6: respawn fade-in (TweenService 1→0 over NPC_FADE_IN_DURATION).
	Story 5-7: destroyAll() cleanup — cancel pending timers + tweens.
	Story 5-8: density guards — getAbsorbRate + getSteadyStateActive + EPSILON guard.
	Story 5-9: UREvent NpcStateBroadcast + NpcPoolBootstrap Bootstrap.

	Singleton module: module-level state only. No .new() constructor.
	Mirror style: ServerStorage/Source/CrowdStateServer/init.luau.

	Heartbeat connect/disconnect lifecycle (ADR-0008 §Boot + Round Lifecycle):
	  init()      — validates ARENA_WALKABLE_AREA_SQ, pre-allocates pool; DOES NOT connect Heartbeat.
	  createAll() — connects single Heartbeat; state = "Ticking".
	  destroyAll() — disconnects Heartbeat; state = "Dormant". Pool Parts RETAINED.

	Caller restrictions (ADR-0008 §Caller Authority Matrix):
	  init()             — ServerScriptService/start.server.luau boot only (once)
	  createAll()        — RoundLifecycle T4 only
	  destroyAll()       — RoundLifecycle T9 only
	  getDesignDensity() — any server module (read-only)
	  getAllActiveNPCs() — AbsorbSystem Phase 3 only
	  reclaim()          — AbsorbSystem Phase 3 only
	  getAbsorbRate()    — any server module (read-only formula)
	  getSteadyStateActive() — any server module (read-only formula)

	CSM read-only consumer rule (ADR-0004 §Write-Access Matrix + ADR-0008):
	  NPCSpawner FORBIDDEN from: updateCount, recomputeRadius, setStillOverlapping,
	  create, destroy, stateEvaluate, broadcastAll.
	  Reads: getAllCrowdPositions() only (called in _doRespawn).

	Part flag set (ADR-0008 / ADR-0001 bare-Part conventions):
	  Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false,
	  CastShadow=false, Transparency=1 (parked state).

	NpcRecord internal schema (ADR-0008 §Key Interfaces):
	  npcId:          string   — "n0".."n299"; stable index-derived ID
	  part:           Part     — pre-allocated bare Part from _pool
	  active:         boolean  — false = Respawning / parked
	  position:       Vector3  — authoritative server position (Y always 0 for MVP)
	  transparency:   number   — 0=opaque, 1=invisible
	  _heading:       number   — current walk direction in radians
	  _walkStart:     number   — os.clock() timestamp when current walk segment started
	  _walkDur:       number   — duration (s) of current walk segment; Uniform[T_WALK_MIN, T_WALK_MAX]
	  _respawnThread: thread?  — task.delay cancellation token
	  _fadeTween:     any?     — in-flight TweenService tween (cancel on destroy)
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NPCSpawnerConstants = require(ReplicatedStorage.Source.SharedConstants.NPCSpawnerConstants)
local Network = require(ReplicatedStorage.Source.Network)
local UnreliableRemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.UnreliableRemoteEventName)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

local NPC_POOL_SIZE           = NPCSpawnerConstants.NPC_POOL_SIZE
local NPC_BATCH_SIZE          = NPCSpawnerConstants.NPC_BATCH_SIZE
local NPC_WALK_SPEED          = NPCSpawnerConstants.NPC_WALK_SPEED
local NPC_FADE_IN_DURATION    = NPCSpawnerConstants.NPC_FADE_IN_DURATION
local NPC_RESPAWN_MIN_DELAY   = NPCSpawnerConstants.NPC_RESPAWN_MIN_DELAY
local NPC_RESPAWN_MAX_DELAY   = NPCSpawnerConstants.NPC_RESPAWN_MAX_DELAY
local NPC_RESPAWN_MAX_RETRIES = NPCSpawnerConstants.NPC_RESPAWN_MAX_RETRIES
local NPC_RESPAWN_MIN_CROWD_DIST = NPCSpawnerConstants.NPC_RESPAWN_MIN_CROWD_DIST
local T_WALK_MIN              = NPCSpawnerConstants.T_WALK_MIN
local T_WALK_MAX              = NPCSpawnerConstants.T_WALK_MAX
local NPC_MIN_INITIAL_SEP     = NPCSpawnerConstants.NPC_MIN_INITIAL_SEP
local EPSILON_DENSITY         = NPCSpawnerConstants.EPSILON_DENSITY
local R_RESPAWN_AVG           = NPCSpawnerConstants.R_RESPAWN_AVG

-- ADR-0008 §Replication Contract: per-NPC relevance filter cushion.
-- NPCs within (crowd.radius + RELEVANCE_CUSHION) of a client's crowd are broadcast.
-- BUG-002 polish 2026-05-10: bumped 25 → 100 studs. User feedback — orange
-- NPCs only appearing within ~29 studs made navigation a guessing game.
-- Trade: arena 200×200 = 40000 sq studs; π × 104² ≈ 34000 sq studs covered
-- per crowd = ~85% of arena visible at any time. Bandwidth ~30 KB/s over the
-- 3 KB/s ADR-0008 budget. Acceptable for Studio dev; revisit at production
-- mobile/multi-client soak (MVP-Integration sprint per ADR-0003).
local RELEVANCE_CUSHION = 100

-- ADR-0008 §Replication Contract buffer layout (8 bytes per NPC):
--   offset 0: npcId  u8    (0-299)
--   offset 1: posX   i16   (quantized; arena-bounded ±2048 studs)
--   offset 3: posZ   i16
--   offset 5: flags  u8    (bit 0 = active, bit 1 = transparency-changing)
--   offset 6: transp u8    (0=opaque .. 255=invisible; valid when bit 1 set)
--   offset 7: reserved u8
local BROADCAST_RECORD_SIZE = 8
local BROADCAST_OFFSET_NPCID  = 0
local BROADCAST_OFFSET_POSX   = 1
local BROADCAST_OFFSET_POSZ   = 3
local BROADCAST_OFFSET_FLAGS  = 5
local BROADCAST_OFFSET_TRANSP = 6

-- Parked position sentinel — NPCs waiting for respawn are placed here.
local PARK_Y = -10000
local PARK_CFRAME = CFrame.new(0, PARK_Y, 0)

-- Max position-selection retry when building initial NPC spread.
local INITIAL_POS_MAX_RETRIES = 100

-- Rate-limit fallback warning: one per round per NPC (tracked by flag on record).
-- We use a simple round-scoped counter to rate-limit at 1 per round.
local _fallbackWarningCount = 0

-- ---------------------------------------------------------------------------
-- State (all private)
-- ---------------------------------------------------------------------------

--- Lifecycle state of the spawner.
--- "Dormant" = between rounds (or pre-first-round). "Ticking" = Heartbeat connected.
type SpawnerState = "Dormant" | "Ticking"

--- NPC record type (per ADR-0008 §Key Interfaces).
export type NpcRecord = {
	npcId: string,
	part: Part,
	active: boolean,
	position: Vector3,
	transparency: number,
	_heading: number,
	_walkStart: number,
	_walkDur: number,
	_respawnThread: thread?,
	_fadeTween: any?,
}

--- Pre-allocated pool of bare NPC Parts. Sized NPC_POOL_SIZE at init().
--- Pool is retained across rounds — destroyAll() does NOT free these Parts.
--- Source: ADR-0008 §Architecture (_pool: { Part } × 300).
local _pool: { Part } = {}

--- Story 7-1 BUG-001 fix: NPCs reclaimed since last _broadcastTick. Each entry
--- captures the npcId + LAST KNOWN active position (captured pre-park so the
--- relevance filter can route the despawn signal to the correct player). Drained
--- (cleared) at the END of every _broadcastTick. Without this list the client
--- mirror has no signal that an absorbed NPC was reclaimed — server iterates
--- only `_activeList` in broadcast, so a reclaimed NPC silently exits broadcast
--- scope and the client mirror stays visible at its last received position.
type ReclaimedEntry = { npcId: string, position: Vector3 }
local _recentlyReclaimed: { ReclaimedEntry } = {}

--- Story 7-1 BUG-001 follow-up: per-UserId last-broadcast NPC set. When an NPC
--- leaves a player's relevance window (player walked away — NPC still alive on
--- server), the next broadcast omits that npcId. Without this set, the client
--- mirror is never told to park — visual stays at the last received position
--- forever. We compare current relevant set vs last set; npcIds present in last
--- but not current get a one-shot park signal (flags=0 + transparency=255 at
--- last-known position).
local _lastBroadcastSet: { [number]: { [string]: Vector3 } } = {}

--- All NPC records (active and parked), indexed by npcId.
--- Built in createAll(); cleared in destroyAll(). Keys are "n0".."n299".
local _npcById: { [string]: NpcRecord } = {}

--- Ordered list of npcIds currently active (i.e. in-world, eligible for absorb).
--- O(1) swap-pop removal in reclaim().
local _activeList: { string } = {}

--- Frozen cached snapshot of active NPC records. nil = dirty (needs rebuild).
--- Invalidated by reclaim() and _doRespawn(). Rebuilt lazily on next getAllActiveNPCs().
local _cachedSnapshot: { NpcRecord }? = nil

--- Whether init() has completed. Guards against double-init (defect surface per story spec).
local _initialized = false

--- Init epoch token. Incremented on every init() AND on every _resetForTests().
--- The pool-allocation `task.defer` callbacks scheduled by init() capture the
--- token value at schedule time and check equality before pushing parts; any
--- defer fired AFTER a reset (or a re-init) is rejected at the top, preventing
--- pool growth across tests. Sprint 6 task 6-3 — TestEZ isolation fix.
local _initToken: number = 0

--- Current lifecycle state.
local _state: SpawnerState = "Dormant"

--- Own RunService.Heartbeat connection. nil when Dormant; non-nil when Ticking.
--- Single connection per ADR-0008 §Cadence Exemption + AC-05.
local _heartbeatConn: RBXScriptConnection? = nil

--- 15 Hz accumulator. Advances in _onHeartbeat; drained per 1/15 s window.
local _accumulator: number = 0

--- ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ, computed once at init().
--- Read-only after init; never recomputed across rounds.
--- Source: TR-npc-spawner-012; ADR-0008 §Boot + Round Lifecycle.
local _densityDesign: number = 0

-- ---------------------------------------------------------------------------
-- Test-only overrides (dependency injection)
-- ---------------------------------------------------------------------------

--- Injected RunService. Default: game:GetService("RunService").
--- Tests inject a mock to spy on Heartbeat:Connect / :Disconnect.
local _runService: any = nil

--- Injected arena walkable area (studs²). Default: reads workspace attribute "ArenaWalkableAreaSq".
--- Tests inject a number directly; pass nil to use the workspace attribute path.
local _arenaAreaOverride: number? = nil

--- Injected arena bounds. Default: reads workspace attributes.
--- Tests inject directly. Format: {minX, maxX, minZ, maxZ}.
local _arenaBoundsOverride: { number }? = nil

--- Injected CSM (CrowdStateServer). Default: lazy-required on first use.
--- Tests inject a mock with getAllCrowdPositions() returning { [string]: Vector3 }.
local _csm: any = nil

--- Injected TweenService. Default: game:GetService("TweenService").
--- Tests inject a mock to spy on Create/Play/Cancel calls.
local _tweenService: any = nil

--- Injected RNG. Default: Random.new() at createAll().
--- Tests inject a deterministic mock for walk timer + respawn position sampling.
local _rng: any = nil

--- Injected clock function. Default: os.clock.
--- Tests inject a controllable clock for deterministic time-based tests.
local _clock: (() -> number)? = nil

--- Injected Players service. Default: game:GetService("Players").
--- Tests inject mock with `:GetPlayers() -> { Player }`. Story 6-11 follow-up
--- closes the DI gap documented in tests/integration/npc-spawner/
--- urevent_replication_test.luau header (Story 5-9 left this hardcoded).
local _players: any = nil

--- Injected Network module. Default: ReplicatedStorage.Source.Network.
--- Tests inject mock with `fireClientUnreliable(player, eventName, buf)`
--- + `fireClient(eventName, player, payload)`. Same DI gap as `_players`.
local _network: any = nil

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Returns the RunService instance, using the DI override when set.
local function getRunService(): any
	return _runService or game:GetService("RunService")
end

--- Returns the ARENA_WALKABLE_AREA_SQ value, using override or workspace attribute.
--- Returns nil if the workspace attribute is absent or not a number.
local function resolveArenaArea(): number?
	if _arenaAreaOverride ~= nil then
		return _arenaAreaOverride
	end
	local raw = game.Workspace:GetAttribute("ArenaWalkableAreaSq")
	if typeof(raw) == "number" then
		return raw
	end
	return nil
end

--- Returns arena bounds {minX, maxX, minZ, maxZ}.
--- Reads from DI override or workspace attributes "ArenaBoundsMinX" etc.
--- Falls back to a ±1000 stud default if workspace attributes absent.
local function resolveArenaBounds(): (number, number, number, number)
	if _arenaBoundsOverride ~= nil then
		local b = _arenaBoundsOverride
		return b[1], b[2], b[3], b[4]
	end
	local ws = game.Workspace
	local minX = ws:GetAttribute("ArenaBoundsMinX")
	local maxX = ws:GetAttribute("ArenaBoundsMaxX")
	local minZ = ws:GetAttribute("ArenaBoundsMinZ")
	local maxZ = ws:GetAttribute("ArenaBoundsMaxZ")
	-- Fallback: ±1000 if attributes absent. Ideally Level Design sets these.
	return
		(typeof(minX) == "number" and minX or -1000),
		(typeof(maxX) == "number" and maxX or  1000),
		(typeof(minZ) == "number" and minZ or -1000),
		(typeof(maxZ) == "number" and maxZ or  1000)
end

--- Returns the current clock value (seconds).
local function getClock(): number
	if _clock ~= nil then
		return (_clock :: () -> number)()
	end
	return os.clock()
end

--- Returns the active TweenService (DI or real).
local function getTweenService(): any
	return _tweenService or TweenService
end

--- Returns the active CSM module.
--- Lazy-require to avoid circular dep at module load time.
local function getCsm(): any
	if _csm ~= nil then
		return _csm
	end
	-- Lazy require — only invoked during _doRespawn, never at module load.
	_csm = require(ServerStorage.Source.CrowdStateServer)
	return _csm
end

--- Returns a uniform-random number in [lo, hi].
local function rngUniform(lo: number, hi: number): number
	if _rng ~= nil then
		return _rng:NextNumber(lo, hi)
	end
	return lo + math.random() * (hi - lo)
end

--- Creates a single bare NPC Part with the mandated flag set.
--- Parented to the _NpcPool folder (hidden in ServerStorage).
--- ADR-0008 §Boot + Round Lifecycle: Parts parented to ServerStorage._NpcPool during init.
--- ADR-0001 / ADR-0008 bare-Part flag set: Anchored, no collision, no shadow, Transparency=1.
local function createBareNpcPart(folder: Folder): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1       -- parked; hidden until respawn fades in
	part.Size = Vector3.new(2, 5, 2)
	part.Color = Color3.fromRGB(255, 140, 0)
	part.Name = "NpcPart"
	part.Parent = folder
	return part
end

-- ---------------------------------------------------------------------------
-- Story 5-6: Fade-in helper
-- Internal: starts a TweenService tween on the NPC's Part (Transparency 1→0).
-- Stores the tween on the record for destroyAll() cancellation (Story 5-7).
-- ---------------------------------------------------------------------------

--- Starts a transparency 1→0 fade-in tween on the given NPC's Part.
--- Called at the END of _doRespawn, after the NPC is already gameplay-active.
--- Source: ADR-0008 §Visual Contract; Story 006.
local function _startFadeIn(npc: NpcRecord): ()
	-- Cancel any prior in-flight tween on this NPC (e.g. absorbed during prior fade).
	if npc._fadeTween ~= nil then
		npc._fadeTween:Cancel()
		npc._fadeTween = nil
	end

	npc.part.Transparency = 1

	local ts = getTweenService()
	local tweenInfo = TweenInfo.new(NPC_FADE_IN_DURATION, Enum.EasingStyle.Linear)
	local tween = ts:Create(npc.part, tweenInfo, { Transparency = 0 })
	npc._fadeTween = tween
	tween:Play()
end

-- ---------------------------------------------------------------------------
-- Story 5-5: Respawn pipeline
-- ---------------------------------------------------------------------------

--- Selects a respawn position that is ≥ NPC_RESPAWN_MIN_CROWD_DIST from every
--- active crowd centre (read-only CSM access per ADR-0004 + ADR-0008).
--- Returns (position, wasFallback).
--- Source: ADR-0008 §Respawn Contract; Story 005.
local function _selectRespawnPosition(): (Vector3, boolean)
	local minX, maxX, minZ, maxZ = resolveArenaBounds()

	-- Read crowd positions (CSM read-only; FORBIDDEN to mutate CSM).
	local crowdPositions: { [string]: Vector3 } = {}
	local csm = getCsm()
	if csm ~= nil then
		local positions = csm.getAllCrowdPositions()
		if positions ~= nil then
			crowdPositions = positions
		end
	end

	-- Flatten crowd positions to an array for fast iteration.
	local crowdPosArray: { Vector3 } = {}
	for _, pos in pairs(crowdPositions) do
		table.insert(crowdPosArray, pos)
	end

	local bestCandidate: Vector3 = Vector3.new(0, 0, 0)
	local bestMinDist: number = -1

	for attempt = 1, NPC_RESPAWN_MAX_RETRIES do
		local cx = rngUniform(minX, maxX)
		local cz = rngUniform(minZ, maxZ)
		local candidate = Vector3.new(cx, 0, cz)

		-- Compute min distance to any crowd centre.
		local minDist = math.huge
		for _, crowdPos in ipairs(crowdPosArray) do
			local dx = candidate.X - crowdPos.X
			local dz = candidate.Z - crowdPos.Z
			local d = math.sqrt(dx * dx + dz * dz)
			if d < minDist then
				minDist = d
			end
		end
		-- If no crowds, minDist stays math.huge — always accepted.

		-- Track best candidate for fallback.
		if minDist > bestMinDist then
			bestMinDist = minDist
			bestCandidate = candidate
		end

		-- Accept if sufficiently far from all crowds.
		if #crowdPosArray == 0 or minDist >= NPC_RESPAWN_MIN_CROWD_DIST then
			return candidate, false
		end

		-- Unused intentionally: attempt variable used only for loop count.
		local _ = attempt
	end

	-- Fallback: use the best-seen candidate (maximum min-distance to crowds).
	-- Rate-limit warning to once per round.
	_fallbackWarningCount += 1
	if _fallbackWarningCount == 1 then
		warn("[NPCSpawner] _selectRespawnPosition: fallback triggered — no valid position after "
			.. NPC_RESPAWN_MAX_RETRIES .. " retries. Using best-effort candidate.")
	end

	return bestCandidate, true
end

--- Performs the actual NPC respawn: assigns position, marks active, starts fade-in.
--- Called via task.delay (see _scheduleRespawn). NOT called from reclaim directly.
--- Source: ADR-0008 §Respawn Contract; Stories 005, 006.
local function _doRespawn(npc: NpcRecord): ()
	-- Guard: if destroyAll() ran before this timer fired, the record may be cleared.
	-- Check state first.
	if _state ~= "Ticking" then
		return
	end

	-- Clear the respawn thread token (it has already fired).
	npc._respawnThread = nil

	-- Select respawn position.
	local pos, _ = _selectRespawnPosition()
	npc.position = pos

	-- Reuse the existing Part (no Instance.new — ADR-0008 §Pool frozen post-boot).
	npc.part.CFrame = CFrame.new(pos)
	npc.part.Transparency = 1

	-- Mark as gameplay-active BEFORE fade (NPC is immediately eligible for absorb).
	npc.active = true
	npc.transparency = 1

	-- Push into active list.
	table.insert(_activeList, npc.npcId)

	-- Invalidate snapshot cache (Story 003).
	_cachedSnapshot = nil

	-- Reset walk loop state for this NPC.
	local t = getClock()
	npc._walkStart = t
	npc._heading = rngUniform(0, 2 * math.pi)
	npc._walkDur = rngUniform(T_WALK_MIN, T_WALK_MAX)

	-- Start fade-in tween (Story 006 — purely cosmetic; does not gate gameplay).
	_startFadeIn(npc)
end

--- Schedules a respawn for the given NPC after a Uniform[MIN, MAX] delay.
--- Called at the end of reclaim(). The delay is async; reclaim returns immediately.
--- Source: ADR-0008 §Respawn Contract; Stories 002, 005.
local function _scheduleRespawn(npc: NpcRecord): ()
	local delay = rngUniform(NPC_RESPAWN_MIN_DELAY, NPC_RESPAWN_MAX_DELAY)
	npc._respawnThread = task.delay(delay, function()
		_doRespawn(npc)
	end)
end

-- ---------------------------------------------------------------------------
-- Story 5-2: reclaim() synchronous postconditions
-- ---------------------------------------------------------------------------

--- Synchronously reclaims an NPC back to the pool (parks Part, clears record).
--- Postconditions before return (ADR-0008 §Lifecycle Contract):
---   - active=false
---   - removed from getAllActiveNPCs() return (via swap-pop from _activeList)
---   - parked at sentinel position (0, -10000, 0)
---   - Transparency=1
---   - _cachedSnapshot = nil (invalidated)
---   - Respawn scheduled via task.delay (async; not part of synchronous body)
--- Double-reclaim asserts (defect surface). AbsorbSystem Phase 3 is sole caller.
--- Source: TR-npc-spawner-005; TR-npc-spawner-010; ADR-0008 §Lifecycle Contract.
---
--- @param npcId string — e.g. "n42"
local function _reclaimInternal(npcId: string): ()
	-- 1. Assert NPC exists in registry.
	local npc = _npcById[npcId]
	assert(npc ~= nil, "NPCSpawner.reclaim: unknown npcId '" .. npcId .. "'")

	-- 2. Assert NPC currently active (double-reclaim guard — defect surface).
	assert(
		npc.active,
		"NPCSpawner.reclaim: double-reclaim detected for npcId '"
			.. npcId
			.. "' — NPC is already inactive"
	)

	-- 3. Mark inactive.
	npc.active = false

	-- 4. Remove from active list — swap-pop for O(1).
	local idx = table.find(_activeList, npcId)
	if idx ~= nil then
		local last = _activeList[#_activeList]
		_activeList[idx] = last
		table.remove(_activeList)
	end

	-- 4b. Story 7-1 BUG-001 fix: queue despawn signal for next _broadcastTick.
	-- Capture the LIVE position BEFORE step 5 parks it — this is needed for the
	-- per-player relevance filter (the absorbing player's crowd is close to the
	-- pre-park position by definition; relevance check matches there, never at
	-- the sentinel). Drained at end of next _broadcastTick.
	table.insert(_recentlyReclaimed, { npcId = npcId, position = npc.position })

	-- 5. Park Part at sentinel position.
	npc.part.CFrame = PARK_CFRAME
	npc.position = Vector3.new(0, PARK_Y, 0)

	-- 6. Set transparency to 1 (invisible / parked).
	npc.part.Transparency = 1
	npc.transparency = 1

	-- 7. Cancel any in-flight fade tween (NPC was absorbed during fade).
	if npc._fadeTween ~= nil then
		npc._fadeTween:Cancel()
		npc._fadeTween = nil
	end

	-- 8. Invalidate snapshot cache (Story 003 consumer).
	_cachedSnapshot = nil

	-- Respawn is scheduled asynchronously after return (Story 005).
	-- reclaim() itself does NOT yield.
	_scheduleRespawn(npc)
end

-- ---------------------------------------------------------------------------
-- Story 5-4: _movementTick() — idle walk + boundary reflection
-- ---------------------------------------------------------------------------

--- 15 Hz movement tick: integrate each active NPC's position by velocity*dt,
--- reflect velocity when crossing ARENA bounds, write Part.CFrame.
--- Source: ADR-0008 §Movement Loop; TR-npc-spawner-004; Story 004.
local function _movementTick(): ()
	local tickPeriod = 1 / 15
	local minX, maxX, minZ, maxZ = resolveArenaBounds()
	local t = getClock()

	for _, npcId in ipairs(_activeList) do
		local npc = _npcById[npcId]
		if npc == nil then
			continue
		end

		-- Re-pick walk heading if walk segment has expired.
		if t - npc._walkStart >= npc._walkDur then
			npc._heading = rngUniform(0, 2 * math.pi)
			npc._walkDur = rngUniform(T_WALK_MIN, T_WALK_MAX)
			npc._walkStart = t
		end

		-- Integrate position.
		local h = npc._heading
		local dx = math.cos(h) * NPC_WALK_SPEED * tickPeriod
		local dz = math.sin(h) * NPC_WALK_SPEED * tickPeriod

		local newX = npc.position.X + dx
		local newZ = npc.position.Z + dz

		-- Boundary reflection: flip velocity component when crossing bounds,
		-- clamp position back inside arena. Guards NaN at corner (both X and Z exceed).
		local headingX = math.cos(npc._heading)
		local headingZ = math.sin(npc._heading)

		if newX < minX then
			newX = minX
			headingX = math.abs(headingX)  -- flip to positive
		elseif newX > maxX then
			newX = maxX
			headingX = -math.abs(headingX)  -- flip to negative
		end

		if newZ < minZ then
			newZ = minZ
			headingZ = math.abs(headingZ)  -- flip to positive
		elseif newZ > maxZ then
			newZ = maxZ
			headingZ = -math.abs(headingZ)  -- flip to negative
		end

		-- Recompute heading from reflected components.
		-- Guard against near-zero vector (e.g. exact corner): re-pick random heading.
		local magSq = headingX * headingX + headingZ * headingZ
		if magSq > 1e-10 then
			npc._heading = math.atan2(headingZ, headingX)
		else
			npc._heading = rngUniform(0, 2 * math.pi)
		end

		npc.position = Vector3.new(newX, 0, newZ)
		npc.part.CFrame = CFrame.new(newX, 0, newZ)

		-- Keep transparency in sync from Part (tween may be active).
		npc.transparency = npc.part.Transparency
	end
end

-- ---------------------------------------------------------------------------
-- Story 5-9: _broadcastTick() — UREvent NpcStateBroadcast
-- ---------------------------------------------------------------------------

--- 15 Hz broadcast tick: for each player, compute relevant NPCs via per-relevance
--- filter, buffer-encode delta payload, fire NpcStateBroadcast UREvent.
--- Source: ADR-0008 §Replication Contract; TR-npc-spawner-015; Story 009.
local function _broadcastTick(): ()
	-- Story 7-1: empty active list is OK if there are pending despawns to flush.
	-- Without this guard relax, despawn-only ticks (e.g. last NPC absorbed)
	-- would skip broadcast and never reach the client.
	if #_activeList == 0 and #_recentlyReclaimed == 0 then
		return
	end

	-- We need CSM to look up crowd radius for relevance filter.
	-- getAllCrowdPositions() returns { [string]: Vector3 } — we need radius too.
	-- ADR-0008 §Replication Contract: filter = NPCs within (crowd.radius + 25).
	-- CrowdStateServer.getAllActive() returns full records with radius.
	local csm = getCsm()
	local allCrowds: { any } = {}
	if csm ~= nil then
		local ok, result = pcall(function()
			return csm.getAllActive()
		end)
		if ok and result ~= nil then
			allCrowds = result
		end
	end

	-- Build per-player crowd lookup: { [Player]: { {pos, radius} } }
	-- CrowdRecord has: crowdId (string — encodes userId), position (Vector3), radius (number).
	-- _players DI seam: production = real Players service; tests = mock w/ GetPlayers().
	local players = _players or game:GetService("Players")
	local playerList = players:GetPlayers()

	-- Pre-build crowd data for fast iteration.
	type CrowdEntry = { pos: Vector3, radius: number, userId: number }
	local crowdEntries: { CrowdEntry } = {}
	for _, crowd in ipairs(allCrowds) do
		if crowd.position ~= nil and crowd.radius ~= nil and crowd.crowdId ~= nil then
			-- crowdId encodes userId (see CrowdStateServer).
			local userId = tonumber(tostring(crowd.crowdId))
			if userId ~= nil then
				table.insert(crowdEntries, {
					pos = crowd.position,
					radius = crowd.radius,
					userId = userId,
				})
			end
		end
	end

	for _, player in ipairs(playerList) do
		-- Find this player's crowd entries.
		local ownCrowds: { CrowdEntry } = {}
		for _, entry in ipairs(crowdEntries) do
			if entry.userId == player.UserId then
				table.insert(ownCrowds, entry)
			end
		end

		-- Build relevant NPC list. Each entry tracks whether it's an active-state
		-- broadcast or a despawn signal (Story 7-1 BUG-001 fix). Despawn entries
		-- use the npc's pre-park position for relevance filtering.
		type RelevantEntry = { npcId: string, isDespawn: boolean, position: Vector3 }
		local relevantEntries: { RelevantEntry } = {}

		if #ownCrowds == 0 then
			-- Spectator / lobby client: no crowds → no NPC updates (active or despawn).
			continue
		end

		for _, npcId in ipairs(_activeList) do
			local npc = _npcById[npcId]
			if npc == nil then
				continue
			end

			-- Include NPC if within (any own crowd.radius + RELEVANCE_CUSHION).
			local relevant = false
			for _, crowd in ipairs(ownCrowds) do
				local dx = npc.position.X - crowd.pos.X
				local dz = npc.position.Z - crowd.pos.Z
				local dist = math.sqrt(dx * dx + dz * dz)
				if dist <= crowd.radius + RELEVANCE_CUSHION then
					relevant = true
					break
				end
			end

			if relevant then
				table.insert(relevantEntries, {
					npcId = npcId,
					isDespawn = false,
					position = npc.position,
				})
			end
		end

		-- Story 7-1: append despawn signals for NPCs reclaimed this tick. SKIPS
		-- the relevance filter — every player must receive every despawn so client
		-- mirrors that left the player's relevance window earlier (NPC walked away,
		-- or NPC absorbed by another player while this client was far) still get
		-- the despawn signal and park the mirror. Without this, stale mirrors
		-- accumulate visibly across the arena. Bandwidth cost is negligible
		-- (absorb rate per ADR-0008 §F2 is bounded; despawn entries are 8 bytes
		-- each, capped well under the 16 KB packet budget per ADR-0010).
		for _, reclaimed in ipairs(_recentlyReclaimed) do
			table.insert(relevantEntries, {
				npcId = reclaimed.npcId,
				isDespawn = true,
				position = reclaimed.position,
			})
		end

		-- Story 7-1 follow-up: park NPCs that LEFT this player's relevance window.
		-- Compare current relevant active set vs lastBroadcastSet. NPCs present
		-- last tick but not this tick → emit one-shot park signal at LAST known
		-- position (so mirror knows to park there, not at sentinel — sentinel
		-- could mislead future re-entry logic). Without this, the mirror visual
		-- freezes at last broadcast position forever and creates "ghost" NPCs.
		local userId = player.UserId
		local lastSet = _lastBroadcastSet[userId] or {}
		local currentSet: { [string]: Vector3 } = {}
		for _, entry in ipairs(relevantEntries) do
			if not entry.isDespawn then
				currentSet[entry.npcId] = entry.position
			end
		end
		for npcId, lastPos in pairs(lastSet) do
			if currentSet[npcId] == nil then
				-- Was relevant last tick, not this tick → emit park signal.
				-- Skip if this npcId was already added as a despawn (reclaim path).
				local alreadyDespawned = false
				for _, e in ipairs(relevantEntries) do
					if e.isDespawn and e.npcId == npcId then
						alreadyDespawned = true
						break
					end
				end
				if not alreadyDespawned then
					table.insert(relevantEntries, {
						npcId = npcId,
						isDespawn = true,
						position = lastPos,
					})
				end
			end
		end
		_lastBroadcastSet[userId] = currentSet

		if #relevantEntries == 0 then
			continue
		end

		-- Buffer-encode delta payload: BROADCAST_RECORD_SIZE bytes per NPC.
		-- Layout per ADR-0008 §Replication Contract:
		--   u8 npcId, i16 posX (quantized), i16 posZ (quantized), u8 flags, u8 transparency, u8 reserved
		local buf = buffer.create(#relevantEntries * BROADCAST_RECORD_SIZE)
		for i, entry in ipairs(relevantEntries) do
			-- Derive integer npcId from string "nN" → N.
			local idNum = tonumber(string.sub(entry.npcId, 2)) or 0
			local base = (i - 1) * BROADCAST_RECORD_SIZE

			-- Quantize position to i16: clamp to ±2048, scale to integer.
			local qx = math.clamp(math.round(entry.position.X), -32767, 32767)
			local qz = math.clamp(math.round(entry.position.Z), -32767, 32767)
			local qxU = qx + 32768
			local qzU = qz + 32768

			-- Story 7-1: flags + transparency depend on entry kind.
			-- Active entry: bit 0 = 1 (active), bit 1 = fade-in-progress; transparency from npc.
			-- Despawn entry: bit 0 = 0 (inactive), bit 1 = 0; transparency = 255 (parked).
			local flags = 0
			local transpU8 = 255
			if not entry.isDespawn then
				local npc = _npcById[entry.npcId]
				if npc ~= nil then
					if npc.active then
						flags = flags + 1  -- bit 0 = active
					end
					if npc._fadeTween ~= nil then
						flags = flags + 2  -- bit 1 = transparency changing
					end
					transpU8 = math.clamp(math.round(npc.transparency * 255), 0, 255)
				end
			end

			buffer.writeu8(buf,  base + BROADCAST_OFFSET_NPCID, idNum)
			buffer.writeu16(buf, base + BROADCAST_OFFSET_POSX,  qxU)
			buffer.writeu16(buf, base + BROADCAST_OFFSET_POSZ,  qzU)
			buffer.writeu8(buf,  base + BROADCAST_OFFSET_FLAGS, flags)
			buffer.writeu8(buf,  base + BROADCAST_OFFSET_TRANSP, transpU8)
			buffer.writeu8(buf,  base + BROADCAST_RECORD_SIZE - 1, 0)  -- reserved byte
		end

		-- Fire UREvent to this player. _network DI seam: production = real
		-- Network module; tests = mock w/ fireClientUnreliable spy.
		local network = _network or Network
		network.fireClientUnreliable(player, UnreliableRemoteEventName.NpcStateBroadcast, buf)
	end

	-- Story 7-1: drain reclaimed list AFTER all per-player broadcasts so every
	-- player sees the despawn this tick exactly once. Cleared even if some
	-- players had no relevant entries (no point holding stale despawns).
	if #_recentlyReclaimed > 0 then
		_recentlyReclaimed = {}
	end
end

-- ---------------------------------------------------------------------------
-- Heartbeat callback (Stories 5-1, 5-4, 5-9)
-- ---------------------------------------------------------------------------

--- Heartbeat callback. 15 Hz accumulator pattern per ADR-0008 §Cadence Exemption.
--- Movement tick filled by Story 004; broadcast tick filled by Story 009.
local function _onHeartbeat(dt: number): ()
	_accumulator += dt
	local TICK_RATE = 1 / 15
	while _accumulator >= TICK_RATE do
		_accumulator -= TICK_RATE
		_movementTick()   -- Story 004: idle walk + boundary reflection
		_broadcastTick()  -- Story 009: fire NpcStateBroadcast UREvent
	end
end

-- ---------------------------------------------------------------------------
-- Story 5-9: Bootstrap helper
-- ---------------------------------------------------------------------------

--- Fires NpcPoolBootstrap reliable RemoteEvent to the given player with the
--- full active-NPC snapshot. Called from createAll() and PlayerAdded handler.
--- Source: ADR-0008 §Replication Contract (reliable bootstrap); Story 009.
local function _sendBootstrap(player: Player): ()
	-- Build snapshot of NPCs in this player's relevance window only.
	-- Story 7-1 BUG-001 follow-up: full-pool bootstrap leaves ~280 stale mirror
	-- parts at bootstrap positions for the rest of the round (only relevant
	-- NPCs get position updates via NpcStateBroadcast). Filtering bootstrap
	-- to the relevance window means out-of-range NPCs stay parked (client
	-- _parkAll resets them; absent from snapshot → never unparked). When they
	-- walk into range later, NpcStateBroadcast adds them via the spawn path.
	local snapshot: { { npcId: string, posX: number, posZ: number, transparency: number } } = {}

	-- Resolve player's own crowd(s) for relevance filtering.
	type CrowdEntry = { pos: Vector3, radius: number }
	local ownCrowds: { CrowdEntry } = {}
	local csm = getCsm()
	if csm ~= nil then
		local ok, allCrowds = pcall(function()
			return csm.getAllActive()
		end)
		if ok and allCrowds ~= nil then
			for _, crowd in ipairs(allCrowds) do
				if crowd.crowdId ~= nil and crowd.position ~= nil and crowd.radius ~= nil then
					local userId = tonumber(tostring(crowd.crowdId))
					if userId == player.UserId then
						table.insert(ownCrowds, { pos = crowd.position, radius = crowd.radius })
					end
				end
			end
		end
	end

	for _, npcId in ipairs(_activeList) do
		local npc = _npcById[npcId]
		if npc == nil or not npc.active then
			continue
		end
		-- If player has no crowd yet (mid-creation race), include nothing — first
		-- broadcast tick will populate via spawn path once crowd registers.
		local relevant = false
		for _, crowd in ipairs(ownCrowds) do
			local dx = npc.position.X - crowd.pos.X
			local dz = npc.position.Z - crowd.pos.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist <= crowd.radius + RELEVANCE_CUSHION then
				relevant = true
				break
			end
		end
		if relevant then
			table.insert(snapshot, {
				npcId = npcId,
				posX = npc.position.X,
				posZ = npc.position.Z,
				transparency = npc.transparency,
			})
		end
	end

	-- Seed _lastBroadcastSet so the next broadcast tick treats these as already
	-- "live" (no spurious park signal next tick). Without this seed, the first
	-- broadcast would re-emit park entries for everything in the bootstrap.
	local seedSet: { [string]: Vector3 } = {}
	for _, rec in ipairs(snapshot) do
		seedSet[rec.npcId] = Vector3.new(rec.posX, 0, rec.posZ)
	end
	_lastBroadcastSet[player.UserId] = seedSet

	-- _network DI seam: production = real Network; tests = mock spy.
	local network = _network or Network
	network.fireClient(RemoteEventName.NpcPoolBootstrap, player, snapshot)
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local NPCSpawner = {}

--- Initialises the NPCSpawner singleton. Call ONCE at server boot, BEFORE
--- TickOrchestrator.start(). Validates ARENA_WALKABLE_AREA_SQ, pre-allocates
--- 300 Parts chunked 25/batch via task.defer (12 batches × 25 = 300 Parts),
--- computes ρ_design, and leaves state = "Dormant". Does NOT connect Heartbeat.
---
--- Raises loudly if:
---   - Called a second time (idempotency guard — defect surface).
---   - ARENA_WALKABLE_AREA_SQ is nil, non-number, zero, or negative.
---
--- Dependency injection (for testing):
---   deps.runService   — mock RunService (default: game:GetService("RunService"))
---   deps.arenaArea    — number override for ARENA_WALKABLE_AREA_SQ (default: workspace attribute)
---   deps.arenaBounds  — {minX, maxX, minZ, maxZ} override (default: workspace attributes)
---   deps.csm          — mock CrowdStateServer (default: lazy require)
---   deps.tweenService — mock TweenService (default: game:GetService("TweenService"))
---   deps.rng          — mock Random object with :NextNumber(lo, hi) (default: Random.new())
---   deps.clock        — mock clock function () -> number (default: os.clock)
---   deps.players      — mock Players service with :GetPlayers() (default: game:GetService("Players"))
---   deps.network      — mock Network module with fireClient + fireClientUnreliable
---                       (default: ReplicatedStorage.Source.Network). Story 6-11 follow-up.
---
--- Source: TR-npc-spawner-001, TR-npc-spawner-011, TR-npc-spawner-012; ADR-0008 §Boot.
function NPCSpawner.init(deps: {
	runService: any?,
	arenaArea: number?,
	arenaBounds: { number }?,
	csm: any?,
	tweenService: any?,
	rng: any?,
	clock: (() -> number)?,
	players: any?,
	network: any?,
}?): ()
	assert(not _initialized, "NPCSpawner.init: already initialised — init() must only be called once per server lifetime")

	-- Merge DI overrides.
	if deps ~= nil then
		_runService        = deps.runService
		_arenaAreaOverride = deps.arenaArea
		_arenaBoundsOverride = deps.arenaBounds
		_csm               = deps.csm
		_tweenService      = deps.tweenService
		_rng               = deps.rng
		_clock             = deps.clock
		_players           = deps.players
		_network           = deps.network
	end

	-- TR-npc-spawner-011: ARENA_WALKABLE_AREA_SQ must be present and valid at boot.
	local area = resolveArenaArea()
	assert(
		area ~= nil and typeof(area) == "number" and area > 0,
		"ARENA_WALKABLE_AREA_SQ missing or invalid — must be a positive number (got "
			.. tostring(area)
			.. "). Set the ArenaWalkableAreaSq workspace attribute or pass deps.arenaArea."
	)

	-- TR-npc-spawner-012: ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ.
	_densityDesign = NPC_POOL_SIZE / (area :: number)

	-- TR-npc-spawner-001: Pre-allocate 300 Parts chunked 25/batch via task.defer.
	local npcPoolFolder = ServerStorage:FindFirstChild("_NpcPool")
	if npcPoolFolder == nil then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "_NpcPool"
		newFolder.Parent = ServerStorage
		npcPoolFolder = newFolder
	end

	local folder = npcPoolFolder :: Folder
	local batchCount = NPC_POOL_SIZE / NPC_BATCH_SIZE  -- 12 batches

	-- Init epoch — capture current token before scheduling defers. Any defer
	-- that fires AFTER a _resetForTests or re-init will see a mismatched token
	-- and exit without pushing to the (potentially-different) _pool. Without
	-- this guard, TestEZ runs across multiple specs leaked Parts into the
	-- shared module-level _pool array, growing it 3x/8x by the third+ test.
	_initToken += 1
	local myToken = _initToken

	for _ = 1, batchCount do
		task.defer(function()
			if _initToken ~= myToken then
				return  -- this batch was scheduled by an obsolete init; reject
			end
			for _ = 1, NPC_BATCH_SIZE do
				local part = createBareNpcPart(folder)
				table.insert(_pool, part)
			end
		end)
	end

	_state = "Dormant"
	_initialized = true
end

--- Connects the NPCSpawner's single Heartbeat and marks the spawner Ticking.
--- Called by RoundLifecycle at T4. Spawns NPCs at initial positions with
--- ≥ NPC_MIN_INITIAL_SEP pairwise separation. Fires NpcPoolBootstrap to participants.
--- Connects exactly one RunService.Heartbeat connection per ADR-0008 §Cadence Exemption + AC-05.
---
--- Asserts if state is already "Ticking" (double-call without destroyAll is a
--- RoundLifecycle logic bug).
---
--- Source: ADR-0008 §Boot + Round Lifecycle (createAll).
function NPCSpawner.createAll(participants: { Player }): ()
	assert(
		_state == "Dormant",
		"NPCSpawner.createAll: already Ticking — call destroyAll() before createAll() for a new round"
	)

	-- Reset round-scoped fallback warning counter.
	_fallbackWarningCount = 0

	-- Seed RNG for this round if not injected.
	if _rng == nil then
		_rng = Random.new()
	end

	_state = "Ticking"
	_accumulator = 0

	-- Build NPC records from the pre-allocated pool.
	-- Place NPCs at initial positions with ≥ NPC_MIN_INITIAL_SEP pairwise separation.
	local minX, maxX, minZ, maxZ = resolveArenaBounds()
	local t = getClock()
	local placedPositions: { Vector3 } = {}

	_npcById = {}
	_activeList = {}
	_cachedSnapshot = nil

	for i, part in ipairs(_pool) do
		local npcId = "n" .. tostring(i - 1)  -- "n0" .. "n299"

		-- Find a position with ≥ NPC_MIN_INITIAL_SEP from already-placed NPCs.
		local pos = Vector3.new(0, 0, 0)
		local found = false
		for _ = 1, INITIAL_POS_MAX_RETRIES do
			local cx = rngUniform(minX, maxX)
			local cz = rngUniform(minZ, maxZ)
			local candidate = Vector3.new(cx, 0, cz)

			local ok = true
			for _, placed in ipairs(placedPositions) do
				local dx = candidate.X - placed.X
				local dz = candidate.Z - placed.Z
				if math.sqrt(dx * dx + dz * dz) < NPC_MIN_INITIAL_SEP then
					ok = false
					break
				end
			end

			if ok then
				pos = candidate
				found = true
				break
			end
		end

		-- If we couldn't find a valid position (very dense arena), use unchecked position.
		-- This should never happen in practice with a 200×200 arena and 300 NPCs.
		if not found then
			pos = Vector3.new(
				rngUniform(minX, maxX),
				0,
				rngUniform(minZ, maxZ)
			)
		end

		table.insert(placedPositions, pos)
		part.CFrame = CFrame.new(pos)
		part.Transparency = 0  -- Initially visible.

		local npc: NpcRecord = {
			npcId       = npcId,
			part        = part,
			active      = true,
			position    = pos,
			transparency = 0,
			_heading    = rngUniform(0, 2 * math.pi),
			_walkStart  = t,
			_walkDur    = rngUniform(T_WALK_MIN, T_WALK_MAX),
			_respawnThread = nil,
			_fadeTween  = nil,
		}

		_npcById[npcId] = npc
		table.insert(_activeList, npcId)
	end

	-- Single Heartbeat connection — non-gameplay-tick cadence exemption per ADR-0002
	-- §Related Decisions L289 + ADR-0008 §Cadence Exemption.
	_heartbeatConn = getRunService().Heartbeat:Connect(_onHeartbeat)

	-- Fire NpcPoolBootstrap reliable RemoteEvent to each participant (Story 009).
	for _, player in ipairs(participants) do
		_sendBootstrap(player)
	end
end

--- Disconnects the Heartbeat and returns the spawner to Dormant state.
--- Cancels all pending task.delay respawn timers and in-flight fade tweens.
--- Parks all active Parts. Clears active list and cache.
--- Pool Parts are RETAINED — destroyAll does NOT free the 300 Parts.
--- Idempotent — second call is a no-op.
--- Called by RoundLifecycle at T9.
---
--- Source: ADR-0008 §Boot + Round Lifecycle (destroyAll); Story 007.
function NPCSpawner.destroyAll(): ()
	-- Idempotent guard: if already Dormant, no-op (Story 007 §Idempotent).
	if _state == "Dormant" and _heartbeatConn == nil then
		return
	end

	-- 1. Disconnect Heartbeat connection.
	if _heartbeatConn ~= nil then
		_heartbeatConn:Disconnect()
		_heartbeatConn = nil
	end

	-- 2. Cancel all pending respawn timers and in-flight tweens; park active Parts.
	for _, npc in pairs(_npcById) do
		-- Cancel respawn timer (task.cancel is safe-no-op if thread already completed).
		if npc._respawnThread ~= nil then
			task.cancel(npc._respawnThread)
			npc._respawnThread = nil
		end

		-- Cancel in-flight fade tween.
		if npc._fadeTween ~= nil then
			npc._fadeTween:Cancel()
			npc._fadeTween = nil
		end

		-- Park Part back at sentinel position.
		npc.part.CFrame = PARK_CFRAME
		npc.part.Transparency = 1
		npc.active = false
		npc.transparency = 1
	end

	-- 3. Clear active list, record dict, snapshot cache, reclaimed queue,
	--    last-broadcast set (per-player relevance tracking — Story 7-1 follow-up).
	_npcById = {}
	_activeList = {}
	_recentlyReclaimed = {}
	_lastBroadcastSet = {}
	_cachedSnapshot = nil

	-- 4. Reset RNG injection so next round gets a fresh one if not re-injected.
	-- (Keep other DI overrides intact — tests may re-inject between rounds.)

	_accumulator = 0
	_state = "Dormant"
end

--- Returns ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ, computed once at init().
--- Read-only — the value never changes after init().
--- Source: TR-npc-spawner-012; ADR-0008 §Boot + Round Lifecycle.
function NPCSpawner.getDesignDensity(): number
	assert(_initialized, "NPCSpawner.getDesignDensity: called before init()")
	return _densityDesign
end

--- Returns a frozen cached snapshot of all currently active NPC records.
--- The returned table is frozen — mutation raises a Lua error.
--- Cache invalidated on every reclaim() or _doRespawn() call.
--- Returns empty frozen table when no NPCs are active (post-destroyAll or pre-createAll).
--- Source: TR-npc-spawner-006; ADR-0008 §Snapshot Contract; Story 003.
function NPCSpawner.getAllActiveNPCs(): { NpcRecord }
	if _cachedSnapshot ~= nil then
		return _cachedSnapshot
	end

	-- Build fresh snapshot from _activeList.
	local snapshot: { NpcRecord } = {}
	for _, npcId in ipairs(_activeList) do
		local npc = _npcById[npcId]
		if npc ~= nil then
			table.insert(snapshot, npc)
		end
	end

	table.freeze(snapshot)
	_cachedSnapshot = snapshot
	return snapshot
end

--- Synchronously reclaims an NPC back to the pool (parks Part, clears record).
--- Postconditions before return: active=false, removed from snapshot, parked, Transparency=1.
--- Double-reclaim asserts (defect surface). AbsorbSystem Phase 3 is sole caller.
--- Respawn is scheduled asynchronously via task.delay (does not block reclaim).
--- Source: TR-npc-spawner-005, TR-npc-spawner-010; ADR-0008 §Lifecycle Contract; Story 002.
function NPCSpawner.reclaim(npcId: string): ()
	_reclaimInternal(npcId)
end

-- ---------------------------------------------------------------------------
-- Story 5-8: Density guards — F2/F4 formula exports
-- ---------------------------------------------------------------------------

--- Returns R_absorb for a crowd with the given radius, per GDD F2 formula:
---   R_absorb = crowdRadius × 2 × NPC_WALK_SPEED × ρ_design
---
--- Cross-references AbsorbSystem F4 (same formula — consistency invariant).
--- Source: ADR-0008 §Density Cross-Reference; design/gdd/npc-spawner.md §F2; Story 008 AC-16.
function NPCSpawner.getAbsorbRate(crowdRadius: number): number
	assert(_initialized, "NPCSpawner.getAbsorbRate: called before init()")
	return crowdRadius * 2 * NPC_WALK_SPEED * _densityDesign
end

--- Returns steady-state active NPC count per F4 formula:
---   N_steady = NPC_POOL_SIZE × (R_respawn_avg / (R_absorb_total + R_respawn_avg))
---
--- EPSILON guard: when R_absorb_total ≤ EPSILON_DENSITY (1e-6), returns NPC_POOL_SIZE
--- directly (avoids divide-by-zero and correctly represents zero-crowd steady state).
--- Source: ADR-0008 §Density Cross-Reference; design/gdd/npc-spawner.md §F4; Story 008.
function NPCSpawner.getSteadyStateActive(R_absorb_total: number): number
	assert(_initialized, "NPCSpawner.getSteadyStateActive: called before init()")
	if R_absorb_total <= EPSILON_DENSITY then
		return NPC_POOL_SIZE
	end
	return NPC_POOL_SIZE * (R_RESPAWN_AVG / (R_absorb_total + R_RESPAWN_AVG))
end

-- ---------------------------------------------------------------------------
-- Test-only surface (never call from production code)
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Resets all module state for TestEZ isolation. Disconnects Heartbeat if
--- connected, clears pool, clears DI overrides. Allows re-initialisation
--- in the same Luau session (required by TestEZ beforeEach/afterEach pattern).
function NPCSpawner._resetForTests(): ()
	if _heartbeatConn ~= nil then
		_heartbeatConn:Disconnect()
		_heartbeatConn = nil
	end

	-- Cancel any pending respawn timers.
	for _, npc in pairs(_npcById) do
		if npc._respawnThread ~= nil then
			task.cancel(npc._respawnThread)
		end
		if npc._fadeTween ~= nil then
			npc._fadeTween:Cancel()
		end
	end

	-- Invalidate any pool-allocation defers scheduled by a prior init() that
	-- have not yet fired. Sprint 6 task 6-3 — TestEZ isolation fix. Without
	-- this bump, leaked defers would push parts onto the freshly-cleared _pool,
	-- inflating it 3x/8x across multi-test runs and breaking AC-01 assertions.
	_initToken += 1

	-- Destroy the orphaned pool folder + parts in ServerStorage so the next
	-- init() recreates a clean folder. Without this, parts created by prior
	-- init() defers that DID complete would accumulate as orphan Instances
	-- in ServerStorage._NpcPool across multi-test runs.
	local existingFolder = ServerStorage:FindFirstChild("_NpcPool")
	if existingFolder ~= nil then
		existingFolder:Destroy()
	end

	_pool = {}
	_npcById = {}
	_activeList = {}
	_recentlyReclaimed = {}
	_lastBroadcastSet = {}
	_cachedSnapshot = nil
	_state = "Dormant"
	_accumulator = 0
	_densityDesign = 0
	_initialized = false
	_runService = nil
	_arenaAreaOverride = nil
	_arenaBoundsOverride = nil
	_csm = nil
	_tweenService = nil
	_rng = nil
	_clock = nil
	_players = nil
	_network = nil
	_fallbackWarningCount = 0
end

--- **TEST ONLY** — never call from production code.
--- Returns a reference to the internal pool array. Tests use #NPCSpawner._getPool()
--- to verify AC-01 (300 Parts after init). Do not mutate the returned array.
function NPCSpawner._getPool(): { Part }
	return _pool
end

--- **TEST ONLY** — never call from production code.
--- Returns the current lifecycle state string ("Dormant" | "Ticking").
function NPCSpawner._getState(): string
	return _state
end

--- **TEST ONLY** — never call from production code.
--- Returns the current Heartbeat connection (or nil). Used to verify AC-05
--- (single connection identity) without exposing _heartbeatConn directly.
function NPCSpawner._getHeartbeatConn(): RBXScriptConnection?
	return _heartbeatConn
end

--- **TEST ONLY** — never call from production code.
--- Returns the _npcById map for test state inspection.
function NPCSpawner._getNpcById(): { [string]: NpcRecord }
	return _npcById
end

--- **TEST ONLY** — never call from production code.
--- Returns the _activeList array for test state inspection.
function NPCSpawner._getActiveList(): { string }
	return _activeList
end

--- **TEST ONLY** — never call from production code.
--- Returns the current _cachedSnapshot (or nil if dirty).
function NPCSpawner._getCachedSnapshot(): { NpcRecord }?
	return _cachedSnapshot
end

--- **TEST ONLY** — never call from production code.
--- Sets the spawner state directly so tests that exercise respawn paths
--- (which guard `_state == "Ticking"` per ADR-0008 §Respawn Contract) can
--- complete without going through createAll. Production sets _state via
--- start() / createAll / destroyAll. Type system enforces SpawnerState union;
--- no runtime assert needed (caller can't pass an invalid string under strict).
function NPCSpawner._setStateForTest(state: SpawnerState): ()
	_state = state
end

--- **TEST ONLY** — never call from production code.
--- Invokes the module-private `_broadcastTick()` helper directly so
--- urevent_replication_test.luau can drive a single broadcast cycle
--- without running the full Heartbeat accumulator. Story 6-11 follow-up.
function NPCSpawner._broadcastTickForTest(): ()
	_broadcastTick()
end

--- **TEST ONLY** — never call from production code.
--- Invokes the module-private `_sendBootstrap(player)` helper for the
--- given mock Player. Lets tests assert NpcPoolBootstrap reliable fires
--- before any UREvent. Story 6-11 follow-up.
function NPCSpawner._sendBootstrapForTest(player: any): ()
	_sendBootstrap(player)
end

--- **TEST ONLY** — never call from production code.
--- Seeds an NPC record directly into _npcById and optionally _activeList.
--- Used by test scaffolding to set up pre-conditions without calling createAll().
function NPCSpawner._seedNpcForTest(npcId: string, part: Part, active: boolean, pos: Vector3): ()
	local npc: NpcRecord = {
		npcId        = npcId,
		part         = part,
		active       = active,
		position     = pos,
		transparency = active and 0 or 1,
		_heading     = 0,
		_walkStart   = 0,
		_walkDur     = 3,
		_respawnThread = nil,
		_fadeTween   = nil,
	}
	_npcById[npcId] = npc

	if active then
		table.insert(_activeList, npcId)
		_cachedSnapshot = nil
	end
end

return NPCSpawner
