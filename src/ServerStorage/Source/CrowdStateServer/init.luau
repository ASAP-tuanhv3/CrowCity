--!strict

--[[
	CrowdStateServer — authoritative crowd-state hub.
	Path: ServerStorage/Source/CrowdStateServer/init.luau
	Implements: ADR-0001 §Key Interfaces (record schema + 5 reliable events)
	            ADR-0004 §Write-Access Matrix (caller authority)
	            GDD design/gdd/crowd-state-manager.md

	Story-001 scope: module skeleton + record schema types + create/destroy
	lifecycle + Players.PlayerRemoving handler + CrowdCreated + CrowdDestroyed
	reliable fanout. updateCount / recomputeRadius / stateEvaluate / broadcastAll
	deferred to follow-up stories.

	Story-002 scope: updateCount + DeltaSource enum (already exported in story-001)
	+ F5 clamp + CountChanged BindableEvent + CrowdCountClamped reliable to local
	player.

	Story-007 scope: getAllActive (Eliminated-excluded) + getAllCrowdPositions (snapshot
	map) + setStillOverlapping (CCR-only writer, last-write-wins, absent-record no-op).

	Story-003 scope: hue ∈ [1, 12] range assertion in create (immutable post-create)
	+ addActiveRelic / removeActiveRelic (RelicEffectHandler/RelicSystem-only callers)
	+ CrowdRelicChanged reliable fanout (full-snapshot, all clients) per GDD L141.

	Story-004 scope: F1 composed radius — `_recomposeRadius` private helper
	(`(2.5 + sqrt(count) * 0.55) * radiusMultiplier`) wired into create + updateCount;
	`recomputeRadius(crowdId, newMultiplier)` public API (RelicEffectHandler-only
	caller; range [0.5, 1.5] gate; idempotent same-value no-op).

	Story-006 scope: Phase 5 `stateEvaluate(tickCount)` callback — TickOrchestrator-
	only caller; F7 grace timer (`GRACE_WINDOW_SEC = 3.0`); state transitions
	Active ↔ GraceWindow ↔ Eliminated; CrowdEliminated reliable fanout for
	Active→Eliminated; tie-break overlap-clear-wins; no revival from Eliminated.
	Calls `_updatePositions(tickCount)` first per body order (story-005 fills math).

	Story-008 scope: Phase 8 `broadcastAll(tickCount)` callback — TickOrchestrator-
	only caller; per-record monotonic uint16 tick increment (wraps 65536); buffer-
	encoded CrowdStateBroadcast UnreliableRemoteEvent fired once per tick to all
	clients; Eliminated continues broadcasting; empty `_crowds` skips fire entirely.

	Public API (story-001):
	  create(crowdId, initial) -> CrowdRecord  -- RoundLifecycle-only caller
	  destroy(crowdId) -> ()                   -- RoundLifecycle-only + DC handler
	  get(crowdId) -> CrowdRecord?             -- any server module (read-only)
	  start() -> ()                            -- boot wiring; connect PlayerRemoving

	Public API (story-002):
	  updateCount(crowdId, delta, source) -> number  -- 4 callers: Absorb / Collision / Chest / Relic
	  CountChanged (BindableEvent module field)       -- subscribe: CrowdStateServer.CountChanged.Event:Connect(...)

	Public API (story-007):
	  getAllActive() -> { CrowdRecord }                  -- excludes Eliminated; fresh array
	  getAllCrowdPositions() -> { [string]: Vector3 }    -- snapshot; excludes Eliminated
	  setStillOverlapping(crowdId, flag) -> ()           -- CCR-only writer

	Public API (story-003):
	  addActiveRelic(crowdId, specId) -> boolean         -- RelicEffectHandler/RelicSystem only
	  removeActiveRelic(crowdId, specId) -> boolean      -- RelicEffectHandler relic-expiry only

	Public API (story-004):
	  recomputeRadius(crowdId, newMultiplier) -> number  -- RelicEffectHandler only; [0.5, 1.5] gate

	Public API (story-006):
	  stateEvaluate(tickCount) -> ()                     -- TickOrchestrator Phase 5 only

	Public API (story-008):
	  broadcastAll(tickCount) -> ()                      -- TickOrchestrator Phase 8 only

	Caller restrictions (ADR-0004 §Write-Access Matrix):
	  create()                — RoundLifecycle.createAll only
	  destroy()               — RoundLifecycle (destroyAll + Players.PlayerRemoving handler)
	  get()                   — any server-side system (read-only; caller MUST NOT mutate)
	  start()                 — ServerScriptService/start.server.luau boot only
	  updateCount()           — AbsorbSystem / CollisionResolver / ChestSystem / RelicEffectHandler ONLY
	                            (Pillar 4: cosmetic systems FORBIDDEN)
	  getAllActive()           — any server module (CCR Phase 1 hot path)
	  getAllCrowdPositions()   — NPCSpawner; any server module (read-only)
	  setStillOverlapping()    — CollisionResolver ONLY (ADR-0004 §Write-Access Matrix)
	  addActiveRelic()         — RelicEffectHandler / RelicSystem ONLY (Pillar 4: cosmetics FORBIDDEN)
	  removeActiveRelic()      — RelicEffectHandler relic-expiry path ONLY
	  recomputeRadius()        — RelicEffectHandler ONLY (Pillar 4: cosmetics FORBIDDEN)
	  stateEvaluate()          — TickOrchestrator Phase 5 dispatch ONLY
	  broadcastAll()           — TickOrchestrator Phase 8 dispatch ONLY

	Pillar 4 anti-P2W invariant (ADR-0004 §Pillar 4):
	  Cosmetic systems FORBIDDEN as callers. Skin System, Avatar System, Banner
	  System, Trail System and any future visual-identity system MUST NOT mutate
	  any field of a crowd record.

	Test-only API (_-prefixed, never call from production code):
	  _resetForTests()                      — zeros _crowds, disconnects DC handler, clears interceptors
	  _getCrowdsCount()                     — size of internal _crowds map
	  _getPlayerRemovingConnection()        — RBXScriptConnection? identity check
	  _setTestFanoutInterceptor(fn)         — intercepts Network calls for tests (3-arg: eventName, payload, target)
	  _setTestOwnerResolver(fn)             — overrides Players:GetPlayerByUserId for tests
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
local UnreliableRemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.UnreliableRemoteEventName)
local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

-- ---------------------------------------------------------------------------
-- Exported types (per architecture.md §5.1 L512-527)
-- ---------------------------------------------------------------------------

--- Crowd lifecycle state. GraceWindow is transient: ~0.5s overlap grace before
--- Eliminated is assigned. ADR-0001 §Key Interfaces; ADR-0004 §Write-Access Matrix.
export type CrowdState = "Active" | "GraceWindow" | "Eliminated"

--- Source of a count mutation. Used as runtime caller fingerprint on updateCount.
--- Enforced by code review: each call site passes a value matching its module identity.
--- ADR-0004 §Write-Access Matrix (4 authorised callers for updateCount).
export type DeltaSource = "Absorb" | "Collision" | "Chest" | "Relic"

--- Authoritative server-side crowd record.
--- Fields must not use `read` qualifier — plain types; immutability enforced by
--- convention + control-manifest L155 (callers MUST NOT mutate returned references).
--- ADR-0001 §Key Interfaces; architecture.md §5.1 L515-527.
export type CrowdRecord = {
	crowdId: string,
	position: Vector3,
	radiusMultiplier: number,          -- [0.5, 1.5]
	radius: number,                    -- composed: radius_base(count) * mult
	count: number,                     -- [1, 300]
	hue: number,                       -- [1, 12] immutable post-create
	activeRelics: { string },          -- max 4
	state: CrowdState,
	tick: number,                      -- uint16 monotonic broadcast counter
	stillOverlapping: boolean,
	timer_start: number?,              -- os.clock() on GraceWindow entry; nil otherwise
}

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

local _crowds: { [string]: CrowdRecord } = {}
local _playerRemovingConnection: RBXScriptConnection? = nil

--- Test-only interceptor. When set, fanout() calls this instead of the Network
--- layer. Receives all 3 args (eventName, payload, target) so countclamped.spec
--- can assert per-player routing. Cleared by _resetForTests().
--- Existing 2-arg interceptors in story-001 tests silently ignore the extra arg.
local _testFanoutInterceptor: ((eventName: string, payload: { [string]: any }, target: Player?) -> ())? = nil

--- Test-only owner resolver override. When set, resolveOwner() calls this
--- instead of Players:GetPlayerByUserId. Cleared by _resetForTests().
local _testOwnerResolver: ((crowdId: string) -> Player?)? = nil

--- Test-only interceptor for the Phase 8 broadcast path. When set, broadcastAll()
--- routes (eventName, buffer) here instead of Network.fireAllClientsUnreliable.
--- Required because Network is not started in TestEZ context — the real path
--- would error. Cleared by _resetForTests.
local _testUnreliableBroadcastInterceptor: ((eventName: string, payload: buffer) -> ())? = nil

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

-- Per ADR-0001 §Key Interfaces; F5 clamp range.
local COUNT_FLOOR = 1
local COUNT_CEILING = 300

-- Per ADR-0001 §Key Interfaces (max 4) + GDD §activeRelics semantics
-- (MAX_RELIC_SLOTS named tuning knob). 5th grant rejected by addActiveRelic.
local MAX_RELIC_SLOTS = 4

-- Per ADR-0001 §Key Interfaces L213 + GDD §F1 + manifest L79.
-- Composed radius: radius = (RADIUS_BASE_OFFSET + sqrt(count) * RADIUS_BASE_SCALE) * radiusMultiplier.
-- radiusMultiplier ∈ [RADIUS_MULTIPLIER_MIN, RADIUS_MULTIPLIER_MAX] (registry-locked).
local RADIUS_BASE_OFFSET = 2.5
local RADIUS_BASE_SCALE = 0.55
local RADIUS_MULTIPLIER_MIN = 0.5
local RADIUS_MULTIPLIER_MAX = 1.5

-- Per GDD §F7 + L309. GraceWindow → Eliminated when timer elapsed AND still
-- overlapping. Tie-break: overlap-clear evaluated before timer-expiry per AC-13.
local GRACE_WINDOW_SEC = 3.0

-- Per ADR-0001 §Decision (uint16 tick wrap) + GDD L140.
local TICK_WRAP = 65536

-- Wire enum mapping per BufferCodec/CrowdState.luau §STATE constants.
local STATE_TO_ENUM: { [CrowdState]: number } = {
	Active = 1,
	GraceWindow = 2,
	Eliminated = 3,
}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Test-only counter: records the tick at which _updatePositions was last
--- invoked. Used by state_evaluator.spec.luau to verify Phase 5 ordering
--- (position update happens BEFORE state-transition evaluation per AC).
local _lastUpdatePositionsTick: number? = nil

--- Per-tick position lag update — F2 placeholder.
--- Story-005 (`CSM 005 F2 position lag + nil HRP guard`) fills the actual
--- math: `position_new = position_old + (char_pos - position_old) * CROWD_POS_LAG`
--- with nil-HRP guard. Until story-005 ships, this is a no-op shim that exists
--- so Phase 5 (`stateEvaluate`) can call it in the prescribed order.
--- ADR-0002 §Phase Sequence; GDD §F2; manifest L62 no-yield invariant.
local function _updatePositions(tickCount: number): ()
	_lastUpdatePositionsTick = tickCount
	-- TODO(story-005): apply F2 position lag for each active record.
end

--- Recomputes `record.radius` from `record.count` and `record.radiusMultiplier`
--- per F1: radius = (2.5 + sqrt(count) * 0.55) * radiusMultiplier.
--- Returns the freshly composed radius. Mutates record in place.
--- Called from: create (initial composition), updateCount (post-clamp count
--- changed), recomputeRadius (multiplier changed). NEVER from broadcast path —
--- broadcast reads record.radius directly per ADR-0001 §Key Interfaces.
--- ADR-0001 §Key Interfaces L213; GDD §F1; manifest L79.
local function _recomposeRadius(record: CrowdRecord): number
	record.radius = (RADIUS_BASE_OFFSET + math.sqrt(record.count) * RADIUS_BASE_SCALE)
		* record.radiusMultiplier
	return record.radius
end

--- Resolves a Player from a crowdId. Production: Players:GetPlayerByUserId(tonumber(crowdId)).
--- Returns nil if the player has disconnected mid-tick (CrowdCountClamped fire is
--- skipped for that frame; client-side broadcast handles the eliminated state).
--- Test override available via _setTestOwnerResolver.
local function resolveOwner(crowdId: string): Player?
	if _testOwnerResolver ~= nil then
		return _testOwnerResolver(crowdId)
	end
	local userId = tonumber(crowdId)
	if userId == nil then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

--- Routes reliable fanout through the test interceptor when set; otherwise
--- delegates to Network.fireClient(eventName, target, ...) when target is non-nil, or
--- Network.fireAllClients(eventName, ...) when target is nil. Test interceptor receives
--- all three args so countclamped.spec can assert per-player routing.
local function fanout(
	eventName: RemoteEventName.EnumType,
	payload: { [string]: any },
	target: Player?
): ()
	if _testFanoutInterceptor ~= nil then
		_testFanoutInterceptor(eventName, payload, target)
	elseif target ~= nil then
		Network.fireClient(eventName, target, payload)
	else
		Network.fireAllClients(eventName, payload)
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local CrowdStateServer = {}

--- Server-only BindableEvent fired after every successful updateCount with
--- effective_delta != 0. Payload: (crowdId, oldCount, newCount, deltaSource).
--- Subscribers: RoundLifecycle (peakCount tracking, story-002 of RL), state
--- evaluator (story-006). NEVER replicated to clients (manifest L77).
--- ADR-0004 §Read-vs-Write Split.
local _countChanged: BindableEvent = Instance.new("BindableEvent")
_countChanged.Name = "CrowdStateServer_CountChanged"

-- Public BindableEvent reference. Subscribe via:
--   CrowdStateServer.CountChanged.Event:Connect(function(crowdId, oldCount, newCount, deltaSource) ... end)
-- Architecture.md §5.1 L552 — exposed as module field.
CrowdStateServer.CountChanged = _countChanged

--- Server-only BindableEvent fired in tandem with the client-facing
--- CrowdEliminated reliable RemoteEvent (Phase 5 Active → Eliminated
--- transition). MSM Phase 7 elimination consumer (MSM story-004) subscribes
--- here for server-server signaling; clients read via the reliable RemoteEvent.
--- Payload: (crowdId).
--- ADR-0001 §Key Interfaces; ADR-0004 §Read-vs-Write Split (server-only
--- BindableEvent + client reliable RemoteEvent split per CountChanged pattern).
local _crowdEliminatedServer: BindableEvent = Instance.new("BindableEvent")
_crowdEliminatedServer.Name = "CrowdStateServer_CrowdEliminatedServer"

-- Public BindableEvent reference. Subscribe via:
--   CrowdStateServer.CrowdEliminatedServer.Event:Connect(function(crowdId) ... end)
CrowdStateServer.CrowdEliminatedServer = _crowdEliminatedServer

--- Creates an authoritative crowd record. Sole caller: RoundLifecycle.createAll
--- (round start). Errors loudly if a record already exists for crowdId (per GDD
--- §Server API "Fails if record exists"). Fires CrowdCreated reliable event with
--- payload {crowdId, hue, initialCount} before returning the stored reference.
--- ADR-0004 §Write-Access Matrix; ADR-0001 §Key Interfaces.
function CrowdStateServer.create(crowdId: string, initial: CrowdRecord): CrowdRecord
	assert(
		initial.hue >= 1 and initial.hue <= 12,
		"CrowdStateServer.create: hue must be in [1, 12], got " .. tostring(initial.hue)
	)
	assert(
		_crowds[crowdId] == nil,
		"CrowdStateServer.create: record already exists for crowdId=" .. crowdId
	)
	_crowds[crowdId] = initial
	-- F1 initial composition — caller may pass a stale radius; CSM is the
	-- composition authority. Source: ADR-0001 §Key Interfaces L213 + manifest L79.
	_recomposeRadius(initial)
	fanout(RemoteEventName.CrowdCreated, {
		crowdId = initial.crowdId,
		hue = initial.hue,
		initialCount = initial.count,
	}, nil)
	return initial
end

--- Destroys a crowd record. Callers: RoundLifecycle.destroyAll (round end) and the
--- Players.PlayerRemoving handler below (mid-round disconnect). Idempotent — no-op
--- and no event if the record is absent (per GDD §Server API "Idempotent (no-op if
--- absent)"). Fires CrowdDestroyed reliable event {crowdId} only when a record was
--- actually removed.
--- ADR-0004 §Write-Access Matrix.
function CrowdStateServer.destroy(crowdId: string): ()
	if _crowds[crowdId] == nil then
		return  -- idempotent: no event fired
	end
	_crowds[crowdId] = nil
	fanout(RemoteEventName.CrowdDestroyed, { crowdId = crowdId }, nil)
end

--- Returns the crowd record for crowdId, or nil if absent. Read-only access —
--- caller MUST NOT mutate the returned table (control-manifest L155; ADR-0004
--- §Read-vs-Write Split). Full read surface (getAllActive, getAllCrowdPositions,
--- setStillOverlapping) ships in story-007; this basic accessor lands here so
--- create/destroy ACs can be verified.
--- ADR-0004 §Write-Access Matrix (unrestricted server-side read).
function CrowdStateServer.get(crowdId: string): CrowdRecord?
	return _crowds[crowdId]
end

--- Returns an array of all crowd records EXCEPT those in state "Eliminated".
--- Iteration order is arbitrary (pairs traversal). Caller MUST NOT mutate
--- returned records — read-only contract per control-manifest L155 (enforced
--- by code review; no runtime guard per manifest L137).
--- Hot path: CollisionResolver.tick (Phase 1) calls per-tick to enumerate
--- overlap-pair candidates. Returns a FRESH array each call — callers may
--- discard or hold; no shared mutable state.
--- ADR-0004 §Read-vs-Write Matrix; arch §5.1 L541; GDD §States table
--- ("Eliminated" = excluded from active set).
function CrowdStateServer.getAllActive(): { CrowdRecord }
	local result: { CrowdRecord } = {}
	for _, record in _crowds do
		if record.state ~= "Eliminated" then
			table.insert(result, record)
		end
	end
	return result
end

--- Returns a snapshot map of crowdId → position Vector3 for all crowds NOT
--- in state "Eliminated". Eliminated records' positions are stale per GDD
--- §Server API L179 — exclude from snapshot. Returns a FRESH table each
--- call — defensive copy. Acceptable cost given ≤12 crowds (manifest §Performance).
--- Hot consumer: NPCSpawner min-distance gate.
--- ADR-0004 §Read-vs-Write Matrix; arch §5.1 L542.
function CrowdStateServer.getAllCrowdPositions(): { [string]: Vector3 }
	local result: { [string]: Vector3 } = {}
	for crowdId, record in _crowds do
		if record.state ~= "Eliminated" then
			result[crowdId] = record.position
		end
	end
	return result
end

--- Sets the per-tick overlap flag on a crowd record. Sole caller:
--- CollisionResolver. Last-write-wins within a tick (race tolerated — CCR
--- iterates pairs once per Phase 1 with no internal contention). No-op if
--- the record is absent (handles the rare race where CCR's snapshot
--- includes a crowd that destroys mid-tick e.g. via PlayerRemoving).
--- Writes unconditionally on state — CSM does NOT gate on state="Eliminated"
--- (CCR is responsible for not calling on Eliminated crowds; if it does,
--- the write is harmless because Eliminated records are scheduled for
--- destroy by RoundLifecycle).
--- ADR-0004 §Write-Access Matrix (CollisionResolver-only writer); arch §5.1 L545.
function CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()
	local record = _crowds[crowdId]
	if record == nil then
		return  -- silent no-op per race-tolerance contract
	end
	record.stillOverlapping = flag
end

--- Connects the Players.PlayerRemoving handler. Called once at boot from
--- ServerScriptService/start.server.luau. Idempotent — second call returns early
--- without replacing the existing connection. The handler invokes
--- destroy(tostring(player.UserId)) on disconnect, satisfying AC-02 (record absent
--- by next tick; no error during tick processing). RoundLifecycle also subscribes to
--- PlayerRemoving for its own peakCount cleanup — both subscribers run independently.
--- ADR-0004 §Write-Access Matrix (destroy caller: RoundLifecycle + PlayerRemoving).
function CrowdStateServer.start(): ()
	if _playerRemovingConnection ~= nil then
		return  -- idempotent
	end
	_playerRemovingConnection = Players.PlayerRemoving:Connect(function(player: Player)
		local crowdId = tostring(player.UserId)
		CrowdStateServer.destroy(crowdId)
	end)
end

--- Mutates the count of crowdId by `delta`, applying F5 clamp [1, 300].
--- Returns post-clamp count. Sole callers (ADR-0004 §Write-Access Matrix):
--- AbsorbSystem.tick (delta > 0), CollisionResolver.tick (delta < 0),
--- ChestSystem.tick (delta < 0), RelicEffectHandler.tick (delta any).
--- Asserts loud if record absent — caller bug per ADR-0004 §Decision tone.
---
--- Side effects:
---   1. Mutates record.count to clamp(count_old + delta, 1, 300).
---   2. Fires CountChanged BindableEvent with (crowdId, oldCount, newCount,
---      deltaSource) ONLY IF effective_delta != 0 (post-clamp difference).
---   3. Fires CrowdCountClamped reliable to LOCAL PLAYER ONLY when positive
---      overflow truncated (count_old + delta > 300). Lower-bound clamp does
---      NOT fire CrowdCountClamped (different signal scope per GDD L145).
---   4. Per-call semantic — same-tick repeat calls at ceiling each fire
---      CrowdCountClamped (HUD-side debounce per GDD L145).
---
--- Pillar 4 anti-P2W invariant: cosmetic systems FORBIDDEN as callers
--- (control-manifest L135). Enforced by code review (manifest L137 forbids
--- runtime traceback validation in hot loop).
function CrowdStateServer.updateCount(crowdId: string, delta: number, source: DeltaSource): number
	local record = _crowds[crowdId]
	assert(
		record ~= nil,
		"CrowdStateServer.updateCount: record absent for crowdId=" .. crowdId
	)

	local oldCount = record.count
	local proposed = oldCount + delta
	local newCount = math.clamp(proposed, COUNT_FLOOR, COUNT_CEILING)

	-- F5 clamp ceiling: positive overflow → CrowdCountClamped reliable to owner.
	-- Floor clamp does NOT fire this signal (different scope per GDD L145).
	if proposed > COUNT_CEILING then
		local owner = resolveOwner(crowdId)
		if owner ~= nil then
			fanout(RemoteEventName.CrowdCountClamped, {
				crowdId = crowdId,
				attemptedDelta = delta,
				clampedCount = newCount,
			}, owner)
		end
	end

	-- Effective delta: post-clamp difference. When count is already at floor or
	-- ceiling and the proposed delta would push past, effective_delta == 0 →
	-- skip CountChanged per AC-24.
	local effectiveDelta = newCount - oldCount
	if effectiveDelta ~= 0 then
		record.count = newCount
		-- F1 recomposition — count drives radius_base; broadcast (story-008)
		-- reads record.radius directly. Source: ADR-0001 §Key Interfaces L213.
		_recomposeRadius(record)
		_countChanged:Fire(crowdId, oldCount, newCount, source)
	end

	return newCount
end

--- Adds `specId` to the crowd's activeRelics list. Sole callers: RelicEffectHandler
--- / RelicSystem (relic-grant path). Returns `true` on insert, `false` on rejection.
---
--- Rejection cases (no event fired, list unchanged):
---   1. Record absent — `_crowds[crowdId] == nil`. Tolerates the rare race where a
---      relic grants on a crowd destroyed mid-tick (DC handler races vs RelicSystem).
---   2. Cap full — `#record.activeRelics >= 4`. MAX_RELIC_SLOTS per GDD §activeRelics
---      semantics + ADR-0001 §Key Interfaces (max 4). 5th grant rejected.
---   3. Duplicate — `specId` already in list. Re-roll is upstream at chest per GDD.
---
--- On success: `table.insert(record.activeRelics, specId)`, fires CrowdRelicChanged
--- reliable to ALL CLIENTS with payload `{crowdId, activeRelics={...defensive copy}}`
--- per GDD L141 (full snapshot, not delta — simplifies client cache).
---
--- Pillar 4 anti-P2W invariant: cosmetic systems FORBIDDEN as callers
--- (control-manifest L135). Skin / Avatar / Banner / Trail systems MUST NOT
--- call this. Enforced by code review.
---
--- ADR-0004 §Write-Access Matrix; ADR-0001 §Key Interfaces (CrowdRelicChanged).
function CrowdStateServer.addActiveRelic(crowdId: string, specId: string): boolean
	local record = _crowds[crowdId]
	if record == nil then
		return false
	end
	if #record.activeRelics >= MAX_RELIC_SLOTS then
		return false
	end
	for _, existing in record.activeRelics do
		if existing == specId then
			return false
		end
	end
	table.insert(record.activeRelics, specId)
	local snapshot: { string } = table.clone(record.activeRelics)
	fanout(RemoteEventName.CrowdRelicChanged, {
		crowdId = crowdId,
		activeRelics = snapshot,
	}, nil)
	return true
end

--- Removes `specId` from the crowd's activeRelics list. Sole caller:
--- RelicEffectHandler relic-expiry path. Returns `true` if removed, `false`
--- otherwise (absent crowd or specId not present — no event fired).
---
--- On success: `table.remove(record.activeRelics, idx)` then fires
--- CrowdRelicChanged reliable to all clients with payload `{crowdId,
--- activeRelics={...defensive copy of post-remove list}}` per GDD L141.
--- Frees a slot for subsequent addActiveRelic.
---
--- ADR-0004 §Write-Access Matrix.
function CrowdStateServer.removeActiveRelic(crowdId: string, specId: string): boolean
	local record = _crowds[crowdId]
	if record == nil then
		return false
	end
	for idx, existing in record.activeRelics do
		if existing == specId then
			table.remove(record.activeRelics, idx)
			local snapshot: { string } = table.clone(record.activeRelics)
			fanout(RemoteEventName.CrowdRelicChanged, {
				crowdId = crowdId,
				activeRelics = snapshot,
			}, nil)
			return true
		end
	end
	return false
end

--- Sets the crowd's `radiusMultiplier` and recomposes `radius` per F1.
--- Sole caller: RelicEffectHandler (relic-grant/expire path). Returns the
--- post-composition radius.
---
--- Validation:
---   1. Record absent — `assert` loud-fails (caller bug per ADR-0004 §Decision tone).
---      Differs from addActiveRelic race-tolerance: relic-radius writes happen
---      after relic effect application, by which point CSM destroy has already
---      cleared the record; calling recomputeRadius on absent crowd is a logic bug.
---   2. `newMultiplier` out of [0.5, 1.5] (RADIUS_MULTIPLIER_MIN/MAX) — `warn`
---      log + return current radius unchanged. Graceful degrade — relic spec
---      misconfiguration must not crash CSM; control manifest L72 enforces the
---      range at the relic-spec authoring level.
---   3. Same-value idempotence — `record.radiusMultiplier == newMultiplier` →
---      no-op (no field write). Avoids spurious broadcast dirty in story-008.
---
--- On success: writes `record.radiusMultiplier = newMultiplier` then calls
--- `_recomposeRadius(record)` (which writes `record.radius`).
---
--- Pillar 4 anti-P2W invariant: cosmetic systems FORBIDDEN as callers
--- (control-manifest L135). Skin / Avatar / Banner / Trail systems MUST NOT
--- call this. Enforced by code review.
---
--- ADR-0001 §Key Interfaces L213; ADR-0004 §Write-Access Matrix; manifest L72/L79.
function CrowdStateServer.recomputeRadius(crowdId: string, newMultiplier: number): number
	local record = _crowds[crowdId]
	assert(
		record ~= nil,
		"CrowdStateServer.recomputeRadius: record absent for crowdId=" .. crowdId
	)
	if newMultiplier < RADIUS_MULTIPLIER_MIN or newMultiplier > RADIUS_MULTIPLIER_MAX then
		warn(string.format(
			"CrowdStateServer.recomputeRadius: multiplier %.3f out of [0.5, 1.5] — rejected",
			newMultiplier
		))
		return record.radius
	end
	if record.radiusMultiplier == newMultiplier then
		return record.radius  -- idempotent no-op
	end
	record.radiusMultiplier = newMultiplier
	return _recomposeRadius(record)
end

--- Phase 5 callback — evaluates state transitions for every record per F7.
--- Sole caller: TickOrchestrator (Phase 5 dispatch). Must NOT yield.
---
--- Body order (per AC-stateEvaluate body order):
---   1. `_updatePositions(tickCount)` — refresh position lag (story-005 math)
---      BEFORE state evaluation so any position-dependent transition logic
---      reads current values.
---   2. Iterate every record; apply F7 transition rules.
---   3. Fire CrowdEliminated reliable for any Active→Eliminated transitions
---      this tick AFTER iteration completes (avoids re-entrancy if a fanout
---      subscriber synchronously triggers another transition).
---
--- Per-record transition logic:
---   * state == "Eliminated"  → terminal; skip.
---   * state == "Active":
---       count == 1 AND stillOverlapping → "GraceWindow", timer_start = os.clock().
---   * state == "GraceWindow":
---       a. NOT stillOverlapping → "Active", timer_start = nil. (Tie-break: AC-13
---          overlap-clear evaluated BEFORE timer-expiry; overlap-clear wins.)
---       b. count > 1 → "Active", timer_start = nil.
---       c. (os.clock() - timer_start) >= GRACE_WINDOW_SEC AND stillOverlapping →
---          "Eliminated"; queue CrowdEliminated fire.
---
--- ADR-0001 §Key Interfaces (CrowdEliminated reliable); ADR-0002 §Phase 5;
--- ADR-0004 §Write-Access Matrix; GDD §States + §F7; manifest L75/L86/L88.
function CrowdStateServer.stateEvaluate(tickCount: number): ()
	_updatePositions(tickCount)

	local now = os.clock()
	local eliminatedThisTick: { string } = {}

	for _, record in _crowds do
		if record.state == "Eliminated" then
			continue  -- terminal; no revival in MVP
		end

		if record.state == "Active" then
			if record.count == 1 and record.stillOverlapping then
				record.state = "GraceWindow"
				record.timer_start = now
			end
		elseif record.state == "GraceWindow" then
			-- AC-13 tie-break: overlap-clear evaluated BEFORE timer-expiry. Combined
			-- with count>1 exit (both → Active path); selene flags split branches
			-- as duplicate, so OR'd into one condition. Stillness check runs first
			-- to preserve overlap-clear-wins semantics.
			if (not record.stillOverlapping) or record.count > 1 then
				record.state = "Active"
				record.timer_start = nil
			else
				local timerStart = record.timer_start
				if timerStart ~= nil and (now - timerStart) >= GRACE_WINDOW_SEC then
					record.state = "Eliminated"
					table.insert(eliminatedThisTick, record.crowdId)
				end
			end
		end
	end

	for _, crowdId in eliminatedThisTick do
		-- Fire BOTH the server-only BindableEvent (MSM Phase 7 consumer)
		-- AND the client-facing reliable RemoteEvent (HUD kill feed).
		_crowdEliminatedServer:Fire(crowdId)
		fanout(RemoteEventName.CrowdEliminated, { crowdId = crowdId }, nil)
	end
end

--- Phase 8 callback — encodes every record into a single buffer payload and
--- fires CrowdStateBroadcast UnreliableRemoteEvent to all clients. Sole caller:
--- TickOrchestrator (Phase 8 dispatch). Must NOT yield.
---
--- Per-broadcast logic:
---   1. Walk `_crowds`. Include records in any of {"Active", "GraceWindow",
---      "Eliminated"} (Eliminated continues until destroy per GDD L139).
---   2. For each included record, increment `record.tick = (tick + 1) % 65536`
---      BEFORE encoding so encoded value reflects this broadcast's tick.
---   3. Map internal record (string crowdId + string state) → wire record (u64
---      crowdId + u8 state enum) and call `BufferCodec.CrowdState.encode`.
---   4. Empty `_crowds` → skip fire entirely (Lobby-state bandwidth save).
---   5. `Network.fireAllClientsUnreliable(CrowdStateBroadcast, buffer)` once.
---
--- Test interception: the `_testUnreliableBroadcastInterceptor`, when set,
--- captures the (eventName, buffer) pair instead of routing to Network.
--- Production path leaves the interceptor nil.
---
--- ADR-0001 §Decision (UREvent + buffer mandate, 30 B/crowd schema, monotonic
--- uint16 tick); ADR-0002 §Phase 8; ADR-0004 §Write-Access Matrix; manifest L75/L84/L85/L87/L88.
function CrowdStateServer.broadcastAll(_tickCount: number): ()
	-- _tickCount is the orchestrator-supplied global tick; broadcast uses
	-- the per-record monotonic record.tick instead per ADR-0001 §Decision.
	-- Param accepted for orchestrator signature consistency.
	local wireRecords: { BufferCodecCrowdState.CrowdRecord } = {}

	for _, record in _crowds do
		-- All three states broadcast per GDD L139. (No state filter.)
		record.tick = (record.tick + 1) % TICK_WRAP

		local crowdIdNum = tonumber(record.crowdId)
		if crowdIdNum == nil then
			-- Internal id always tostring(player.UserId); guard for completeness.
			continue
		end
		table.insert(wireRecords, {
			crowdId = crowdIdNum,
			tick = record.tick,
			position = record.position,
			radius = record.radius,
			count = record.count,
			hue = record.hue,
			state = STATE_TO_ENUM[record.state],
		})
	end

	if #wireRecords == 0 then
		return  -- Lobby state — skip fire (no records, no bandwidth)
	end

	local payload = BufferCodecCrowdState.encode(wireRecords)

	if _testUnreliableBroadcastInterceptor ~= nil then
		_testUnreliableBroadcastInterceptor(
			UnreliableRemoteEventName.CrowdStateBroadcast :: string,
			payload
		)
	else
		Network.fireAllClientsUnreliable(
			UnreliableRemoteEventName.CrowdStateBroadcast,
			payload
		)
	end
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module state for test isolation. Disconnects the PlayerRemoving
--- handler if connected; clears the _crowds map; clears the fanout interceptor
--- and owner resolver.
--- Must be called in beforeEach() for every CrowdStateServer spec.
function CrowdStateServer._resetForTests(): ()
	if _playerRemovingConnection ~= nil then
		_playerRemovingConnection:Disconnect()
		_playerRemovingConnection = nil
	end
	_crowds = {}
	_testFanoutInterceptor = nil
	_testOwnerResolver = nil
	_testUnreliableBroadcastInterceptor = nil
	_lastUpdatePositionsTick = nil
end

--- **TEST ONLY** — never call from production code.
--- Returns the tick at which `_updatePositions` was last invoked. Used by
--- state_evaluator.spec.luau to verify Phase 5 calls `_updatePositions(tick)`
--- before any state-transition logic. nil when never called since reset.
function CrowdStateServer._getLastUpdatePositionsTick(): number?
	return _lastUpdatePositionsTick
end

--- **TEST ONLY** — never call from production code.
--- Returns the count of records in the private _crowds map. Used to verify
--- AC-16 (record presence/absence after createAll/destroyAll) without exposing
--- _crowds directly (control-manifest L155 forbids direct export).
function CrowdStateServer._getCrowdsCount(): number
	local count = 0
	for _ in _crowds do
		count += 1
	end
	return count
end

--- **TEST ONLY** — never call from production code.
--- Returns the current RBXScriptConnection for identity comparison in
--- idempotence tests (dc_cleanup.spec AC-start-idempotence).
function CrowdStateServer._getPlayerRemovingConnection(): RBXScriptConnection?
	return _playerRemovingConnection
end

--- **TEST ONLY** — never call from production code.
--- Sets an interceptor called by fanout() instead of the Network layer.
--- Interceptor signature: (eventName: string, payload: {[string]: any}, target: Player?) -> ()
--- Existing 2-arg interceptors silently ignore the third arg (Lua semantics).
--- Pass nil to clear (also cleared by _resetForTests). Used by signal_fanout.spec
--- and countclamped.spec to capture network events without a connected client.
function CrowdStateServer._setTestFanoutInterceptor(
	fn: ((eventName: string, payload: { [string]: any }, target: Player?) -> ())?
): ()
	_testFanoutInterceptor = fn
end

--- **TEST ONLY** — never call from production code.
--- Overrides resolveOwner to return a mock Player for the given crowdId.
--- Used by countclamped.spec to verify per-player routing without a connected
--- Roblox client. Cleared by _resetForTests.
function CrowdStateServer._setTestOwnerResolver(
	fn: ((crowdId: string) -> Player?)?
): ()
	_testOwnerResolver = fn
end

--- **TEST ONLY** — never call from production code.
--- Sets an interceptor for `broadcastAll`'s Phase 8 unreliable broadcast.
--- Interceptor signature: (eventName: string, payload: buffer) -> ()
--- Pass nil to clear (also cleared by _resetForTests). Used by
--- broadcastall.spec.luau to capture the encoded buffer headlessly.
function CrowdStateServer._setTestUnreliableBroadcastInterceptor(
	fn: ((eventName: string, payload: buffer) -> ())?
): ()
	_testUnreliableBroadcastInterceptor = fn
end

return CrowdStateServer
