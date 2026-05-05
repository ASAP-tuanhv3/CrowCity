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

	Manifest Version: 2026-04-27 (Presentation Layer)
	Updated: Sprint 4 / Story 4-2 (follower-entity/story-002)
	  Added CrowdCreated and CrowdEliminated BindableEvent signal definitions +
	  matching _debugFireCrowdCreated / _debugFireCrowdEliminated test seams.
	  Fire-side wiring (on receipt of reliable RemoteEvents) deferred to
	  crowd-replication-broadcast/story-003 (CRB story-003, Sprint 5).

	Layer Boundary Rules (ADR-0006 §Control Manifest Presentation Layer):
	  - MUST NOT require from ServerStorage
	  - MUST NOT expose a write API to other client modules
	  - Cache write path is reserved for story-002 (broadcast subscriber) +
	    story-003 (reliable subscribers)
	  - Callers of get() and getAllActive() MUST NOT mutate returned tables

	Story Scope:
	  story-001: Module skeleton + CrowdRecord type + _crowds cache + _lastReceivedTick +
	             get() / getAllActive() read API + tick_is_newer() F4 helper.
	  story-002: Broadcast subscriber + decode + stale-defense write path (out of scope here).
	  story-003: Reliable subscribers — CrowdCreated/Destroyed/Eliminated/RelicChanged (out of scope).
	  follower-entity/story-002 (Sprint 4): CrowdCreated / CrowdEliminated signal definitions
	             + test seams. Actual firing wired in CRB story-003.

	Public API (story-001):
	  get(crowdId: string): CrowdRecord?       — read-only mirror lookup
	  getAllActive(): { CrowdRecord }           — fresh array of current cache records
	  tick_is_newer(new: number, old: number): boolean — F4 wrap-aware comparator; standalone DI export

	Public Signals (follower-entity/story-002):
	  CrowdCreated   — BindableEvent; subscribers connect via .CrowdCreated.Event:Connect(handler)
	                   handler signature: (crowdId: string) -> ()
	                   Fires when a crowd is created. Wiring to reliable remote lands in CRB story-003.
	  CrowdEliminated — BindableEvent; subscribers connect via .CrowdEliminated.Event:Connect(handler)
	                   handler signature: (crowdId: string) -> ()
	                   Fires when a crowd is eliminated/destroyed. Wiring to reliable remote in CRB story-003.

	Test-only API:
	  _debugSetRecord(crowdId, record)           — seed cache for unit tests (see §TEST ONLY below)
	  _debugClearAll()                           — reset cache for test isolation
	  _debugGetLastReceivedTick(crowdId)         — inspect stale-defense state in tests
	  _debugFireCrowdCreated(crowdId)            — fire CrowdCreated signal in tests (TEST ONLY)
	  _debugFireCrowdEliminated(crowdId)         — fire CrowdEliminated signal in tests (TEST ONLY)
--]]

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

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local CrowdStateClient = {}

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
--- @return { CrowdRecord } — fresh array of all cached records (references only)
function CrowdStateClient.getAllActive(): { CrowdRecord }
	local result: { CrowdRecord } = {}
	for _, record in _crowds do
		table.insert(result, record)
	end
	return result
end

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
end

--- **TEST ONLY** — returns the last accepted tick for `crowdId`, or nil if
--- no record has been seeded. Used by stale-defense tests in story-002.
--- @param crowdId string
--- @return number?
function CrowdStateClient._debugGetLastReceivedTick(crowdId: string): number?
	return _lastReceivedTick[crowdId]
end

-- ---------------------------------------------------------------------------
-- Standalone export of tick_is_newer (DI shape — CRS §DI Requirements)
-- ---------------------------------------------------------------------------
-- Exported as a module field so callers can do:
--   local f = require(ReplicatedStorage.Source.CrowdStateClient).tick_is_newer
--   f(5, 4) -- true, no module instantiation needed
CrowdStateClient.tick_is_newer = tick_is_newer

-- ---------------------------------------------------------------------------
-- Lifecycle signals — follower-entity/story-002
-- ---------------------------------------------------------------------------
-- Signal definitions added here so CrowdManagerClient (follower-entity/story-002)
-- can subscribe before CRB story-003 wires the firing side.
--
-- Firing:  CRB story-003 will call _debugFireCrowdCreated / _debugFireCrowdEliminated
--          from its reliable subscriber when it processes CrowdCreated / CrowdEliminated
--          remote payloads. In production those calls will be replaced by direct
--          BindableEvent:Fire() calls inside the subscriber.
--
-- READ-ONLY CONTRACT: these BindableEvents expose only .Event (subscribe side).
-- No external module may call :Fire() on them directly — that path belongs to the
-- write surface in CRB story-003. Enforcement: code review per ADR-0006 §Forbidden Patterns.

--- Fires when a crowd is first created (reliable remote CrowdCreated — wired in CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdCreated.Event:Connect(function(crowdId: string) end)`
CrowdStateClient.CrowdCreated = Instance.new("BindableEvent")

--- Fires when a crowd is eliminated or destroyed (reliable remote — wired in CRB story-003).
--- Subscribers: `CrowdStateClient.CrowdEliminated.Event:Connect(function(crowdId: string) end)`
CrowdStateClient.CrowdEliminated = Instance.new("BindableEvent")

-- ---------------------------------------------------------------------------
-- Test-only signal seams — follower-entity/story-002
-- ---------------------------------------------------------------------------

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

return CrowdStateClient
