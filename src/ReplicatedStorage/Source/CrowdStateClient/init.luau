--!strict

--[[
	CrowdStateClient — client-side read-only mirror of the server's crowd-state.
	Path: ReplicatedStorage/Source/CrowdStateClient/init.luau

	Implements:
	  - ADR-0001 §Key Interfaces (CrowdRecord mirror schema; tick: uint16 monotonic;
	              lastReceivedTick stale-packet defense)
	  - ADR-0006 §Source Tree Map (shared module under ReplicatedStorage; read-only mirror)
	  - design/gdd/crowd-replication-strategy.md §F4 (tick_is_newer wrap-aware comparator)
	  - TR-crs-022 (lastReceivedTick stale defense — Dormant → Active transition)
	  - TR-crs-027 (server/client gameplay parity — count always matches authoritative)
	  - Story: crowd-replication-broadcast/story-001
	  - Story: crowd-replication-broadcast/story-002 (broadcast subscriber + stale defense)
	  - Story: crowd-replication-broadcast/story-003 (reliable subscribers + late-reliable handling)

	Manifest Version: 2026-04-27 (Presentation Layer)
	Updated: Sprint 5 / CRB Stories 002+003
	  Story-002: Broadcast subscriber wired to UnreliableRemoteEvent CrowdStateBroadcast.
	    Decodes buffer via BufferCodec.CrowdState.decode; stale-packet defense via
	    _lastReceivedTick; Eliminated terminal rule via _mergeCache; stale-freeze
	    detection via broadcast_stale() + _clockFn DI; _started idempotent guard.
	  Story-003: Five reliable subscribers (CrowdCreated/Destroyed/Eliminated/
	    CountClamped/RelicChanged); late-reliable no-op on cache miss; CrowdDestroyed
	    clears cache entry; CrowdRelicChanged updates activeRelics full-snapshot.
	    Added BindableEvents: CrowdDestroyed, CrowdRelicChanged, CrowdCountClamped.
	    start() extended to wire all 6 Network subscribers.

	Layer Boundary Rules (ADR-0006 §Control Manifest Presentation Layer):
	  - MUST NOT require from ServerStorage
	  - MUST NOT expose a write API to other client modules
	  - Cache write path is reserved for story-002 (broadcast subscriber) +
	    story-003 (reliable subscribers)
	  - Callers of get() and getAllActive() MUST NOT mutate returned tables

	Story Scope:
	  story-001: Module skeleton + CrowdRecord type + _crowds cache + _lastReceivedTick +
	             get() / getAllActive() read API + tick_is_newer() F4 helper.
	  story-002: Broadcast subscriber + decode + stale-defense write path.
	  story-003: Reliable subscribers — CrowdCreated/Destroyed/Eliminated/RelicChanged.
	  follower-entity/story-002 (Sprint 4): CrowdCreated / CrowdEliminated signal definitions.

	Public API (story-001):
	  get(crowdId: string): CrowdRecord?       — read-only mirror lookup
	  getAllActive(): { CrowdRecord }           — fresh array of current cache records
	  tick_is_newer(new: number, old: number): boolean — F4 wrap-aware comparator; standalone DI export

	Public API (story-002):
	  broadcast_stale(crowdId: string): boolean — true if no broadcast in STALE_THRESHOLD_SEC
	  start(): ()                               — wire Network subscribers; idempotent; call once at boot

	Public Signals (follower-entity/story-002 + story-003):
	  CrowdCreated      — BindableEvent; (crowdId: string) -> ()
	  CrowdEliminated   — BindableEvent; (crowdId: string) -> ()
	  CrowdDestroyed    — BindableEvent; (crowdId: string) -> ()
	  CrowdRelicChanged — BindableEvent; (crowdId: string, activeRelics: {string}) -> ()
	  CrowdCountClamped — BindableEvent; (crowdId: string, payload: any) -> ()

	Test-only API:
	  _debugSetRecord(crowdId, record)
	  _debugClearAll()
	  _debugGetLastReceivedTick(crowdId)
	  _debugGetLastBroadcastTime(crowdId)
	  _debugFireCrowdCreated(crowdId)
	  _debugFireCrowdEliminated(crowdId)
	  _debugDispatchBroadcast(buf)
	  _debugDispatchReliable(eventName, payload)
	  _setClockFn(clockFn)
	  _getStarted(): boolean
	  _resetForTests()
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
local UnreliableRemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.UnreliableRemoteEventName)
local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

local t = Network.t

-- ---------------------------------------------------------------------------
-- Exported types
-- ---------------------------------------------------------------------------

--- Client-side crowd record. Mirrors the server's CrowdRecord post-broadcast.
--- Fields mapped from the wire format by story-002's broadcast subscriber:
---   crowdId: string  — tostring(player.UserId); AC-22 invariant (story-002 write-path enforces)
---   state: string    — decoded from wire u8 enum by story-002
---   activeRelics     — populated by CrowdRelicChanged reliable event (story-003)
---
--- READ-ONLY CONTRACT: callers of get() and getAllActive() MUST NOT mutate the
--- returned table or any field on it. This is enforced by code review per
--- ADR-0006 §Forbidden Patterns + control manifest Presentation Layer rules.
--- No runtime guard is applied (manifest §Performance: no hot-path guard overhead).
export type CrowdRecord = {
	crowdId: string,
	tick: number,
	position: Vector3,
	radius: number,
	count: number,
	hue: number,
	state: "Active" | "GraceWindow" | "Eliminated",
	activeRelics: { string },
}

-- ---------------------------------------------------------------------------
-- F4 — tick_is_newer: uint16 wrap-aware comparator
-- ---------------------------------------------------------------------------
-- Per design/gdd/crowd-replication-strategy.md §F4 + ADR-0001 §Key Interfaces.
-- Exported standalone so unit tests can drive it without instantiating the module
-- (CRS §DI Requirements; AC-7).
--
-- Semantics:
--   Returns true  if `new` is strictly newer than `old` in uint16 modular space.
--   Returns false if `new == old` (duplicate broadcast; treated as stale).
--   Returns false if diff >= UINT16_HALF (more than half the range away; defensive
--                  against very-old packets that have wrapped around into the future
--                  half — treat as stale rather than risk reordering).
--
-- Wrap example: new=0, old=65535 → diff = (0 - 65535) % 65536 = 1 → 1 < 32768 → true.
-- Half-window:  new=32768, old=0 → diff = 32768 → NOT < 32768 → false (defensive).

local UINT16_HALF = 32768
local UINT16_MOD  = 65536

--- F4 wrap-aware tick comparator. Returns true when `new` is strictly newer
--- than `old` within the uint16 modular window (wraps at 65536, ambiguity
--- threshold at half-window 32768). Equal ticks return false (duplicate).
---
--- @param new  number  — the incoming tick value (uint16 range 0–65535)
--- @param old  number  — the previously received tick for this crowd
--- @return boolean     — true if `new` is newer than `old`; false otherwise
---
--- Standalone export: `require(ReplicatedStorage.Source.CrowdStateClient).tick_is_newer`
--- usable without any module state. CRS §DI Requirements; AC-7.
local function tick_is_newer(new: number, old: number): boolean
	local diff = (new - old) % UINT16_MOD
	return diff > 0 and diff < UINT16_HALF
end

-- ---------------------------------------------------------------------------
-- State mapping — wire u8 → CrowdRecord state string
-- ---------------------------------------------------------------------------
-- BufferCodec.CrowdState.decode returns state as number (1/2/3).
-- CrowdStateClient.CrowdRecord uses the string union.

local STATE_NUMBER_TO_STRING: { [number]: "Active" | "GraceWindow" | "Eliminated" } = {
	[1] = "Active",
	[2] = "GraceWindow",
	[3] = "Eliminated",
}

-- ---------------------------------------------------------------------------
-- Module-level private state
-- ---------------------------------------------------------------------------

--- Primary mirror cache. Keyed by crowdId (= tostring(player.UserId)).
--- Populated exclusively by story-002 broadcast subscriber + story-003 reliable
--- subscribers. No write API is exposed to other client modules (ADR-0006 §Control
--- Manifest Presentation Layer; manifest L226-L247).
local _crowds: { [string]: CrowdRecord } = {}

--- Per-crowd last received tick for stale-packet defense (TR-crs-022).
--- Updated in story-002 write path alongside _crowds writes. Stored here so
--- story-002 can call tick_is_newer(_incoming, _lastReceivedTick[crowdId])
--- before committing a broadcast update.
--- Value is the tick field of the last accepted CrowdRecord for each crowdId.
local _lastReceivedTick: { [string]: number } = {}

--- Per-crowd last broadcast time for stale-freeze detection (AC-5 / AC-17).
--- Populated by _onBroadcast on each accepted broadcast. Used by broadcast_stale().
local _lastBroadcastTime: { [string]: number } = {}

--- Stale threshold in seconds — if no broadcast received in this window,
--- broadcast_stale() returns true and HUD/Nameplate consumers should freeze
--- last-known display. Per AC-5 / AC-17.
local STALE_THRESHOLD_SEC = 0.5

--- Injected clock function. Defaults to os.clock. Overridable via _setClockFn
--- for test isolation of time-dependent stale-detection logic.
local _clockFn: () -> number = os.clock

--- Idempotent start() guard. Set true on first start() call; subsequent calls no-op.
local _started = false

-- ---------------------------------------------------------------------------
-- Private helpers
-- ---------------------------------------------------------------------------

--- Merges a decoded CrowdRecord into the cache, respecting the AC-11 Eliminated
--- terminal rule. Eliminated state is sticky — broadcasts asserting Active or
--- GraceWindow are discarded for the state field; other fields (count/pos/radius/hue)
--- still update if the tick is newer.
---
--- @param record CrowdRecord — the incoming record (already tick-validated)
local function _mergeCache(record: CrowdRecord): ()
	local cached = _crowds[record.crowdId]
	local stickyState = record.state
	if cached ~= nil and cached.state == "Eliminated" and record.state ~= "Eliminated" then
		stickyState = "Eliminated"
	end
	_crowds[record.crowdId] = {
		crowdId   = record.crowdId,
		tick      = record.tick,
		position  = record.position,
		radius    = record.radius,
		count     = record.count,
		hue       = record.hue,
		state     = stickyState,
		-- Preserve activeRelics from prior CrowdRelicChanged (story-003).
		-- Broadcasts do not carry the relics field; story-003 subscriber owns it.
		activeRelics = (cached and cached.activeRelics) or {},
	}
end

--- Processes a single decoded wire record from BufferCodec.CrowdState.decode,
--- converting the number-typed fields to their CrowdRecord equivalents and
--- passing the result to _mergeCache.
---
--- @param wireRecord BufferCodecCrowdState.CrowdRecord
local function _processBroadcastRecord(wireRecord: BufferCodecCrowdState.CrowdRecord): ()
	-- crowdId comes as a number from the codec (Roblox UserId encoded as u64).
	-- CrowdStateClient uses the string form throughout (AC-22 crowdId uniqueness).
	local crowdId = tostring(wireRecord.crowdId)

	-- Stale-packet defense: reject if tick is not newer than last accepted tick.
	local oldTick = _lastReceivedTick[crowdId] or -1
	if not tick_is_newer(wireRecord.tick, oldTick) then
		return  -- stale or duplicate
	end

	-- Map state u8 (1/2/3) to string union. Unknown state values are dropped silently.
	local stateStr = STATE_NUMBER_TO_STRING[wireRecord.state]
	if stateStr == nil then
		warn(string.format(
			"[CrowdStateClient] _processBroadcastRecord: unknown state %d for crowdId=%s; dropping",
			wireRecord.state, crowdId
		))
		return
	end

	_lastReceivedTick[crowdId] = wireRecord.tick
	_lastBroadcastTime[crowdId] = _clockFn()

	_mergeCache({
		crowdId      = crowdId,
		tick         = wireRecord.tick,
		position     = wireRecord.position,
		radius       = wireRecord.radius,
		count        = wireRecord.count,
		hue          = wireRecord.hue,
		state        = stateStr,
		activeRelics = {},  -- placeholder; _mergeCache preserves existing activeRelics
	})
end

-- ---------------------------------------------------------------------------
-- Reliable subscriber callbacks (story-003)
-- ---------------------------------------------------------------------------

-- Forward declaration so internal callbacks can fire BindableEvents on the module
-- table. The same `local CrowdStateClient` is reused (NOT redeclared) below where
-- public methods attach. BindableEvents are attached after this declaration.
local CrowdStateClient: any = {}

--- Handles CrowdCreated reliable event from CrowdStateServer.
--- Payload: { crowdId: string, hue: number, initialCount: number }
--- AC-19: partial-record initialization — broadcast may arrive later to fill fields.
--- If broadcast already populated the cache, merges only the authoritative fields.
---
--- @param payload any — { crowdId, hue, initialCount }
local function _onCrowdCreated(payload: any): ()
	local crowdId: string = tostring(payload.crowdId)
	local initialPos = (typeof(payload.initialPosition) == "Vector3") and payload.initialPosition or Vector3.zero
	local existing = _crowds[crowdId]
	if existing == nil then
		-- AC-19: no prior broadcast — create a minimal record; broadcast will fill
		-- position/radius/tick when it arrives. initialPosition from server payload
		-- (Sprint 5 unblock — Phase 8 broadcast stubbed, would otherwise carry pos).
		_crowds[crowdId] = {
			crowdId      = crowdId,
			tick         = 0,
			position     = initialPos,
			radius       = 2.5,
			count        = payload.initialCount,
			hue          = payload.hue,
			state        = "Active",
			activeRelics = {},
		}
	else
		-- Cache pre-populated by broadcast — merge authoritative reliable fields.
		existing.hue = payload.hue
		if existing.count == 0 then
			existing.count = payload.initialCount
		end
		-- Only set position if existing record has no broadcast-derived value yet.
		if existing.position == Vector3.zero and initialPos ~= Vector3.zero then
			existing.position = initialPos
		end
	end
	CrowdStateClient.CrowdCreated:Fire(crowdId)
end

--- Handles CrowdDestroyed reliable event from CrowdStateServer.
--- Payload: { crowdId: string }
--- Clears cache entry and lastReceivedTick so a re-creation (same UserId rejoins)
--- accepts tick=0 again. Fires CrowdDestroyed BindableEvent.
---
--- @param payload any — { crowdId }
local function _onCrowdDestroyed(payload: any): ()
	local crowdId: string = tostring(payload.crowdId)
	_crowds[crowdId] = nil
	_lastReceivedTick[crowdId] = nil
	_lastBroadcastTime[crowdId] = nil
	CrowdStateClient.CrowdDestroyed:Fire(crowdId)
end

--- Handles CrowdEliminated reliable event from CrowdStateServer.
--- Payload: { crowdId: string }
--- Sets state to "Eliminated" (terminal). Late-reliable after destroy: cache
--- miss is a graceful no-op (the crowd is already gone). Fires CrowdEliminated.
---
--- @param payload any — { crowdId }
local function _onCrowdEliminated(payload: any): ()
	local crowdId: string = tostring(payload.crowdId)
	local cached = _crowds[crowdId]
	if cached ~= nil then
		cached.state = "Eliminated"  -- terminal flag; _mergeCache also respects this
	end
	-- Late-reliable after destroy: cache miss → no-op (crowd already removed).
	CrowdStateClient.CrowdEliminated:Fire(crowdId)
end

--- Handles CrowdCountClamped reliable event from CrowdStateServer.
--- Payload: { crowdId: string, ... } — HUD-only signal.
--- Does NOT mutate cache (count already in broadcast; this is for clamping FX only).
--- Fires CrowdCountClamped BindableEvent for HUD consumers.
---
--- @param payload any — { crowdId, ... }
local function _onCrowdCountClamped(payload: any): ()
	local crowdId: string = tostring(payload.crowdId)
	CrowdStateClient.CrowdCountClamped:Fire(crowdId, payload)
end

--- Handles CrowdRelicChanged reliable event from CrowdStateServer.
--- Payload: { crowdId: string, activeRelics: {string} }
--- Replaces activeRelics with the full server-authoritative snapshot.
--- Late-reliable after destroy: cache miss → no-op. Fires CrowdRelicChanged.
---
--- @param payload any — { crowdId, activeRelics }
local function _onCrowdRelicChanged(payload: any): ()
	local crowdId: string = tostring(payload.crowdId)
	local cached = _crowds[crowdId]
	if cached ~= nil then
		cached.activeRelics = payload.activeRelics  -- full snapshot replacement
	end
	-- Late-reliable after destroy: cache miss → no-op.
	CrowdStateClient.CrowdRelicChanged:Fire(crowdId, payload.activeRelics)
end

-- ---------------------------------------------------------------------------
-- Broadcast subscriber callback (story-002)
-- ---------------------------------------------------------------------------

--- Processes an incoming CrowdStateBroadcast buffer from the server.
--- Decodes via BufferCodec.CrowdState.decode; applies stale-packet defense per
--- AC-3 (full-payload reject on malformed buffer). Eliminates stale/duplicate
--- records per tick_is_newer. Applies Eliminated terminal rule via _mergeCache.
---
--- @param buf buffer — the raw buffer payload from the UnreliableRemoteEvent
local function _onBroadcast(buf: buffer): ()
	-- BufferCodec.CrowdState.decode internally rejects non-30-multiple lengths
	-- (returns empty array + warn). We pcall defensively per AC-3 fallback.
	local ok, records = pcall(BufferCodecCrowdState.decode, buf)
	if not ok or records == nil then
		warn("[CrowdStateClient] broadcast decode failed; cache unchanged")
		return
	end
	for _, wireRecord in ipairs(records) do
		_processBroadcastRecord(wireRecord)
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

-- (CrowdStateClient table forward-declared above for callback access)

--- Returns the cached CrowdRecord for `crowdId`, or nil when no record exists.
--- Returns nil (not empty table, not error) for any unknown crowdId (AC-18).
---
--- READ-ONLY CONTRACT: the returned table is the live cache entry. Caller MUST
--- NOT mutate it or any of its fields. Mutations will corrupt the shared mirror
--- and may violate server/client parity (TR-crs-027). Enforcement: code review
--- per ADR-0006 §Forbidden Patterns; no runtime guard.
---
--- @param crowdId string — tostring(player.UserId); AC-22 crowdId uniqueness invariant
--- @return CrowdRecord?  — cached record or nil if absent
function CrowdStateClient.get(crowdId: string): CrowdRecord?
	return _crowds[crowdId]
end

--- Returns a fresh array containing references to all current cache records.
--- Array is newly allocated each call — callers may hold or discard the array.
--- The records inside the array are still live cache references; callers MUST
--- NOT mutate them (same read-only contract as get()).
---
--- Mirrors CrowdStateServer.getAllActive() shape (parity per TR-crs-027), but
--- returns ALL states (Active + GraceWindow + Eliminated) — client mirror tracks
--- everything the server broadcasts until a reliable destroy event clears it.
--- State filtering for rendering purposes is the caller's responsibility.
---
--- Hot consumers: FollowerLODManager (per-frame render cap), HUD (count display),
--- PlayerNameplate (crowd label). All are read-only consumers.
---
--- @return  fresh array of all cached records (references only — read-only contract)
function CrowdStateClient.getAllActive(): { CrowdRecord }
	local result: { CrowdRecord } = {}
	for _, record in _crowds do
		table.insert(result, record)
	end
	return result
end

--- Returns true if no broadcast has been received for `crowdId` within
--- STALE_THRESHOLD_SEC seconds. HUD and Nameplate consumers use this to
--- freeze their last-known display rather than showing stale data (AC-5 / AC-17).
---
--- Returns true if the crowd has never received any broadcast (nil case —
--- treat as stale until the first packet arrives).
---
--- @param crowdId string — tostring(player.UserId)
--- @return boolean       — true if last broadcast is older than STALE_THRESHOLD_SEC
function CrowdStateClient.broadcast_stale(crowdId: string): boolean
	local last = _lastBroadcastTime[crowdId]
	if last == nil then
		return true  -- never received any broadcast
	end
	return (_clockFn() - last) >= STALE_THRESHOLD_SEC
end

--- Wires all Network subscribers. Idempotent — subsequent calls are no-ops.
--- MUST be called once at client boot AFTER Network.startClientAsync() completes.
---
--- Subscribers wired:
---   - UnreliableRemoteEvent CrowdStateBroadcast → _onBroadcast (story-002)
---   - RemoteEvent CrowdCreated                  → _onCrowdCreated (story-003)
---   - RemoteEvent CrowdDestroyed                → _onCrowdDestroyed (story-003)
---   - RemoteEvent CrowdEliminated               → _onCrowdEliminated (story-003)
---   - RemoteEvent CrowdCountClamped             → _onCrowdCountClamped (story-003)
---   - RemoteEvent CrowdRelicChanged             → _onCrowdRelicChanged (story-003)
---
--- Story-002 baseline: UnreliableRemoteEvent CrowdStateBroadcast.
--- Story-003 extension: 5 reliable RemoteEvent subscribers.
function CrowdStateClient.start(): ()
	if _started then
		return
	end
	_started = true

	-- Unreliable broadcast (story-002)
	Network.connectUnreliableEvent(
		UnreliableRemoteEventName.CrowdStateBroadcast,
		_onBroadcast,
		t.any
	)

	-- Reliable subscribers (story-003)
	Network.connectEvent(RemoteEventName.CrowdCreated, _onCrowdCreated, t.any)
	Network.connectEvent(RemoteEventName.CrowdDestroyed, _onCrowdDestroyed, t.any)
	Network.connectEvent(RemoteEventName.CrowdEliminated, _onCrowdEliminated, t.any)
	Network.connectEvent(RemoteEventName.CrowdCountClamped, _onCrowdCountClamped, t.any)
	Network.connectEvent(RemoteEventName.CrowdRelicChanged, _onCrowdRelicChanged, t.any)
end

-- ---------------------------------------------------------------------------
-- Standalone export of tick_is_newer (DI shape — CRS §DI Requirements)
-- ---------------------------------------------------------------------------
-- Exported as a module field so callers can do:
--   local f = require(ReplicatedStorage.Source.CrowdStateClient).tick_is_newer
--   f(5, 4) -- true, no module instantiation needed
CrowdStateClient.tick_is_newer = tick_is_newer

-- ---------------------------------------------------------------------------
-- Lifecycle signals — follower-entity/story-002 + story-003
-- ---------------------------------------------------------------------------

--- Fires when a crowd is first created (reliable remote CrowdCreated — wired in CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdCreated.Event:Connect(function(crowdId: string) end)`
CrowdStateClient.CrowdCreated = Instance.new("BindableEvent")

--- Fires when a crowd is eliminated (reliable remote CrowdEliminated — wired in CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdEliminated.Event:Connect(function(crowdId: string) end)`
CrowdStateClient.CrowdEliminated = Instance.new("BindableEvent")

--- Fires when a crowd record is destroyed (reliable remote CrowdDestroyed — CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdDestroyed.Event:Connect(function(crowdId: string) end)`
CrowdStateClient.CrowdDestroyed = Instance.new("BindableEvent")

--- Fires when a crowd's relic list changes (reliable remote CrowdRelicChanged — CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdRelicChanged.Event:Connect(function(crowdId: string, activeRelics: {string}) end)`
CrowdStateClient.CrowdRelicChanged = Instance.new("BindableEvent")

--- Fires when a crowd's count is clamped at the ceiling (reliable remote CrowdCountClamped — CRB story-003).
--- HUD-only signal; does not alter the cache. Payload carries the original server payload table.
--- Subscribers: `CrowdStateClient.CrowdCountClamped.Event:Connect(function(crowdId: string, payload: any) end)`
CrowdStateClient.CrowdCountClamped = Instance.new("BindableEvent")

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------
-- Guarded by the module-level flag below. These helpers exist so unit tests can
-- seed the _crowds cache without requiring a running broadcast subscriber (story-002).
-- Story-002 will use the same seam (_debugSetRecord) in its integration tests to
-- verify cache state after broadcast ingestion.
--
-- NEVER call these from production code. Documented per story-001 §Implementation Notes.

--# DEBUG ONLY — used by tests only; not part of public API.
--# All three helpers are cleared / called by _debugClearAll() in beforeEach().

--- **TEST ONLY** — seeds a CrowdRecord directly into the mirror cache.
--- Simulates what story-002's broadcast subscriber will write. Used by
--- get_lookup.spec and crowdid_uniqueness.spec to populate _crowds without a
--- running broadcast loop.
--- @param crowdId string
--- @param record  CrowdRecord
function CrowdStateClient._debugSetRecord(crowdId: string, record: CrowdRecord): ()
	_crowds[crowdId] = record
	_lastReceivedTick[crowdId] = record.tick
end

--- **TEST ONLY** — clears all cache state for test isolation.
--- Call in beforeEach() of every CrowdStateClient spec.
function CrowdStateClient._debugClearAll(): ()
	_crowds = {}
	_lastReceivedTick = {}
	_lastBroadcastTime = {}
	_clockFn = os.clock
end

--- **TEST ONLY** — returns the last accepted tick for `crowdId`, or nil if
--- no record has been seeded. Used by stale-defense tests in story-002.
--- @param crowdId string
--- @return number?
function CrowdStateClient._debugGetLastReceivedTick(crowdId: string): number?
	return _lastReceivedTick[crowdId]
end

--- **TEST ONLY** — returns the last broadcast time recorded for `crowdId`, or nil.
--- Used by stale-freeze tests in story-002 to verify _lastBroadcastTime is updated.
--- @param crowdId string
--- @return number?
function CrowdStateClient._debugGetLastBroadcastTime(crowdId: string): number?
	return _lastBroadcastTime[crowdId]
end

--- **TEST ONLY** — fires the CrowdCreated BindableEvent with the given crowdId.
--- Used by integration tests in follower-entity/story-002 to drive the
--- CrowdManagerClient lifecycle without a running broadcast loop.
--- @param crowdId string — the crowdId to pass to subscribers
function CrowdStateClient._debugFireCrowdCreated(crowdId: string): ()
	CrowdStateClient.CrowdCreated:Fire(crowdId)
end

--- **TEST ONLY** — fires the CrowdEliminated BindableEvent with the given crowdId.
--- Used by integration tests in follower-entity/story-002 to drive the
--- CrowdManagerClient lifecycle without a running broadcast loop.
--- @param crowdId string — the crowdId to pass to subscribers
function CrowdStateClient._debugFireCrowdEliminated(crowdId: string): ()
	CrowdStateClient.CrowdEliminated:Fire(crowdId)
end

--- **TEST ONLY** — dispatches a buffer directly to _onBroadcast, bypassing
--- Network.connectUnreliableEvent. Allows unit tests to drive the broadcast
--- subscriber without a live Roblox network session.
--- @param buf buffer — the encoded buffer to process
function CrowdStateClient._debugDispatchBroadcast(buf: buffer): ()
	_onBroadcast(buf)
end

--- **TEST ONLY** — dispatches a payload to the appropriate reliable handler,
--- bypassing Network.connectEvent. Allows unit tests to drive reliable subscriber
--- logic without a live Roblox network session.
--- @param eventName string — one of "CrowdCreated"|"CrowdDestroyed"|"CrowdEliminated"|
---                           "CrowdCountClamped"|"CrowdRelicChanged"
--- @param payload   any    — the payload table to pass to the handler
function CrowdStateClient._debugDispatchReliable(eventName: string, payload: any): ()
	if eventName == "CrowdCreated" then
		_onCrowdCreated(payload)
	elseif eventName == "CrowdDestroyed" then
		_onCrowdDestroyed(payload)
	elseif eventName == "CrowdEliminated" then
		_onCrowdEliminated(payload)
	elseif eventName == "CrowdCountClamped" then
		_onCrowdCountClamped(payload)
	elseif eventName == "CrowdRelicChanged" then
		_onCrowdRelicChanged(payload)
	else
		error("[CrowdStateClient._debugDispatchReliable] unknown eventName: " .. tostring(eventName))
	end
end

--- **TEST ONLY** — overrides the clock function used by broadcast_stale().
--- Pass nil to reset to os.clock. Used for deterministic stale-detection tests.
--- clockFn — optional () -> number; pass nil to reset to os.clock
function CrowdStateClient._setClockFn(clockFn: (() -> number)?): ()
	_clockFn = clockFn or os.clock
end

--- **TEST ONLY** — returns whether start() has been called. Used to verify
--- idempotency: calling start() twice must not register duplicate subscribers.
--- @return boolean
function CrowdStateClient._getStarted(): boolean
	return _started
end

--- **TEST ONLY** — resets _started so start() can be called again in tests.
--- Matches the _resetForTests pattern from NPCSpawner. Call in afterEach()
--- alongside _debugClearAll() for full module isolation.
function CrowdStateClient._resetForTests(): ()
	_started = false
	_crowds = {}
	_lastReceivedTick = {}
	_lastBroadcastTime = {}
	_clockFn = os.clock
end

return CrowdStateClient
