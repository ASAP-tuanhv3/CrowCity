--!strict

--[[
	MatchStateServer — server-authoritative match state machine.
	Path: ServerStorage/Source/MatchStateServer/init.luau
	Implements: ADR-0005 (MSM/RoundLifecycle Split) §Decision
	            ADR-0006 §Source Tree Map
	            GDD design/gdd/match-state-machine.md

	Story-001 (Sprint 2-8) scope:
	  - 7-state enum (MatchState type)
	  - Placement type export
	  - get() / getParticipation() / getStateEndsAt() read accessors
	  - module-private _transitionTo (driver wiring deferred to story-002+)
	  - module-private _setParticipation honoring Snap-freeze rule
	  - PlayerAdded handler: auto-set participation = true
	  - PlayerRemoving handler: clear participation entry
	  - AFKToggle reliable RemoteEvent stub connect (full validation per
	    ADR-0010 4-check guard lives in story-007)

	Public API (story-001):
	  get() -> MatchState
	  getParticipation(player) -> boolean
	  getStateEndsAt() -> number?
	  start() -> ()  -- boot wiring; connects PlayerAdded/Removing/AFKToggle

	Story-002 scope: T1 (Lobby→Countdown:Ready) on participation count threshold;
	F5 revert (Countdown:Ready→Lobby) on participation drop; Phase 6 `timerCheck`
	for T3 (Ready→Snap @ 7s), T4 (Snap→Active @ 10s with createAll), T5 (Snap→
	Result @ 10s zero participants). Pre-Active timer transitions only; T7 +
	tiebreak deferred to story-003.

	Public API (story-002):
	  timerCheck(tickCount) -> ()  -- TickOrchestrator Phase 6 only

	Story-003 scope: T7 (Active → Result on round timer expiry); F4 winner
	tiebreak (count desc → peakTimestamp asc → UserId asc); _winnerId field;
	getWinnerId accessor.

	Story-004 scope: Phase 7 `eliminationConsumer` callback — drains queued
	CrowdEliminated signals (subscribed via CSM.CrowdEliminatedServer); double-
	signal guard (`_state ~= Active` returns); T6 last-standing transition;
	T8 instant-win on PlayerRemoving when sole survivor remains.

	Public API (story-003):
	  getWinnerId() -> string?

	Public API (story-004):
	  eliminationConsumer(tickCount) -> ()  -- TickOrchestrator Phase 7 only

	Caller restrictions (ADR-0005 §Decision):
	  Read accessors  — any server module + exposed to client via RemoteFunction
	                    (story-007 wires GetParticipation RemoteFunction)
	  start()         — ServerScriptService/start.server.luau boot only
	  No external transitionTo (internal-only per ADR-0005 §Decision).

	Test-only API (_-prefixed, never call from production code):
	  _resetForTests()                       — zero state, disconnect handlers, restore Lobby
	  _getState() / _setStateForTests(state) — direct state probe + override
	  _setParticipation(player, flag)        — internal API exposed for testing
	  _getPlayerAddedConnection() / _getPlayerRemovingConnection() / _getAFKToggleConnection()
	    — identity checks for idempotence tests
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Network = require(ReplicatedStorage.Source.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
local RemoteFunctionName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteFunctionName)
local RemoteValidator = require(ServerStorage.Source.RemoteValidator)
local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)
local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)
local CurrencyStub = require(ServerStorage.Source._PhaseStubs.CurrencyStub)
local RelicSystemStub = require(ServerStorage.Source._PhaseStubs.RelicSystemStub)

-- ---------------------------------------------------------------------------
-- Exported types per architecture.md §5.2 L577-587
-- ---------------------------------------------------------------------------

--- The 7 canonical match states. Lobbying transitions to Countdown:Ready when
--- MIN_PLAYERS_TO_START threshold is met (story-002 wires the driver).
--- ADR-0005 §Decision; GDD design/gdd/match-state-machine.md §State Enum.
export type MatchState =
	"Lobby"
	| "Countdown:Ready"
	| "Countdown:Snap"
	| "Active"
	| "Result"
	| "Intermission"
	| "ServerClosing"

--- End-of-round placement record. Populated by RoundLifecycle and broadcast
--- via RemoteEvent at round end. Story-001 exports the type only; writer logic
--- lands in story-004+. ADR-0005 §Decision; architecture.md §5.2 L584-587.
export type Placement = {
	crowdId: string,
	userId: number,
	placement: number,
	crowdCount: number,
	eliminationTime: number?,
}

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

-- Boot default per AC-1 + control-manifest L105 (MIN_PLAYERS_TO_START).
local _state: MatchState = "Lobby"
local _participation: { [number]: boolean } = {}
local _stateStartTime: number? = nil
local _stateEndsAt: number? = nil
-- Winner id resolved at T6/T7/T8; nil before round end + zero-participant Result.
local _winnerId: string? = nil

-- Boot connections — wired by start(); cleared by _resetForTests.
local _playerAddedConnection: RBXScriptConnection? = nil
local _playerRemovingConnection: RBXScriptConnection? = nil
local _afkToggleConnection: RBXScriptConnection? = nil
local _crowdEliminatedConnection: RBXScriptConnection? = nil

-- Tick-local queue of crowdIds eliminated since last eliminationConsumer
-- drain. Subscribed via CSM.CrowdEliminatedServer in start(). Cleared at top
-- of each eliminationConsumer call.
local _pendingElims: { string } = {}

-- Server-only BindableEvent fired on every _transitionTo. Mirrors CSM's
-- CrowdEliminatedServer pattern — server-side consumers (e.g. NPCSpawner)
-- subscribe to receive intra-server lifecycle signals without going through
-- the MatchStateChanged RemoteEvent (which is for client broadcast).
-- Payload: (newState: MatchState, endsAt: number?).
-- Story-007 (broadcast Participation) wires the client-side RemoteEvent
-- separately; this server-side signal fires regardless and is ADR-0005
-- compliant — it's a read-only notification, not a state-write API.
local _matchStateChangedServer: BindableEvent = Instance.new("BindableEvent")
_matchStateChangedServer.Name = "MatchStateServer_MatchStateChangedServer"

-- Constants — MSM tuning knobs per GDD design/gdd/match-state-machine.md
-- §Tuning Knobs L336-340 + control-manifest L105.
-- Future: GDD L355 calls for `SharedConstants/MatchConfig.luau` extraction;
-- module-local for now (KISS — refactor when MatchConfig module ships).
local MIN_PLAYERS_TO_START = 2
local COUNTDOWN_READY_SEC = 7.0
local COUNTDOWN_SNAP_SEC = 3.0
local ROUND_DURATION_SEC = 300.0
local RESULT_DURATION_SEC = 10.0
local INTERMISSION_DURATION_SEC = 10.0

-- Test-only RoundLifecycle dependency override. Production path goes through
-- the imported RoundLifecycle module; tests inject a mock to spy createAll.
type RoundLifecycleDependency = {
	createAll: ({ Player }) -> (),
	destroyAll: () -> (),
	getPeakTimestamp: (crowdId: string) -> number?,
	setWinner: (crowdId: string?) -> (),
	getPlacements: () -> { any },
}
local _roundLifecycleOverride: RoundLifecycleDependency? = nil

local function _getRoundLifecycle(): RoundLifecycleDependency
	if _roundLifecycleOverride ~= nil then
		return _roundLifecycleOverride
	end
	return RoundLifecycle :: any
end

-- Test-only Currency dep override — production uses CurrencyStub until the
-- currency epic ships its real module. ADR-0011 §Coins grant only at MSM
-- Result entry; manifest L126.
type CurrencyDependency = {
	grantMatchRewards: (placements: { any }) -> (),
}
local _currencyOverride: CurrencyDependency? = nil

local function _getCurrency(): CurrencyDependency
	if _currencyOverride ~= nil then
		return _currencyOverride
	end
	return CurrencyStub :: any
end

-- Test-only RelicSystem dep override — production uses RelicSystemStub until
-- the relic-system epic ships clearAll. T9 ordering invariant: destroyAll
-- (RoundLifecycle) → clearAll (RelicSystem) → broadcast.
type RelicSystemDependency = {
	clearAll: () -> (),
}
local _relicSystemOverride: RelicSystemDependency? = nil

local function _getRelicSystem(): RelicSystemDependency
	if _relicSystemOverride ~= nil then
		return _relicSystemOverride
	end
	return RelicSystemStub :: any
end

--- Strips the InternalPlacement fields (peakCount/isWinner/wasEliminated)
--- from a placement array before broadcast. Manifest L100 forbids leaking
--- internal fields to clients.
local function _stripInternalPlacements(placements: { any }): { Placement }
	local out: { Placement } = {}
	for _, p in placements do
		table.insert(out, {
			crowdId = p.crowdId,
			userId = p.userId,
			placement = p.placement,
			crowdCount = p.crowdCount,
			eliminationTime = p.eliminationTime,
		})
	end
	return out
end

--- Result entry handler — enforces grant-before-broadcast ordering invariant.
--- Order per ADR-0005 §Result-entry ordering invariant + manifest L99:
---   1. RoundLifecycle.setWinner(_winnerId)
---   2. placements = RoundLifecycle.getPlacements()
---   3. stripped = _stripInternalPlacements(placements)
---   4. Currency.grantMatchRewards(stripped)
---   5. _state = "Result", _stateEndsAt = now + RESULT_DURATION_SEC
---   6. (broadcast — story-007 owns the wire fire)
---
--- Sole callers: T6 (eliminationConsumer last-standing), T7 (timerCheck Active
--- expiry), T8 (PlayerRemoving sole-survivor detection).
local function _handleResultEntry(): ()
	local rl = _getRoundLifecycle()
	rl.setWinner(_winnerId)
	local placements = rl.getPlacements()
	local stripped = _stripInternalPlacements(placements)
	_getCurrency().grantMatchRewards(stripped)

	local now = os.clock()
	_state = "Result"
	_stateStartTime = now
	_stateEndsAt = now + RESULT_DURATION_SEC
end

--- Intermission entry handler (T9) — enforces destroyAll-before-broadcast
--- ordering invariant per ADR-0005 §T9 ordering invariant + manifest L98:
---   1. RoundLifecycle.destroyAll()
---   2. RelicSystem.clearAll()
---   3. _state = "Intermission", _stateEndsAt = now + INTERMISSION_DURATION_SEC
---   4. (broadcast — story-007 owns)
local function _handleIntermissionEntry(): ()
	_getRoundLifecycle().destroyAll()
	_getRelicSystem().clearAll()

	local now = os.clock()
	_state = "Intermission"
	_stateStartTime = now
	_stateEndsAt = now + INTERMISSION_DURATION_SEC
end

--- Lobby entry from Intermission (T10) — resets all participation flags to
--- TRUE for every connected player, then transitions to Lobby (untimed).
local function _handleLobbyEntryFromIntermission(): ()
	-- Reset all flags to TRUE. Iterate the participation map directly — every
	-- entry corresponds to a connected (or recently-connected) player. New
	-- joiners during Intermission also have their entries (auto-set on
	-- PlayerAdded, story-001).
	for userId in _participation do
		_participation[userId] = true
	end

	_state = "Lobby"
	_stateStartTime = os.clock()
	_stateEndsAt = nil
end

-- Test-only CSM dep override. Production uses CrowdStateServer; tests inject
-- a mock with `getAllActive` to seed the F4 tiebreak fixture.
type CSMDependency = {
	getAllActive: () -> { CrowdStateServer.CrowdRecord },
}
local _csmOverride: CSMDependency? = nil

local function _getCSM(): CSMDependency
	if _csmOverride ~= nil then
		return _csmOverride
	end
	return CrowdStateServer :: any
end

--- F4 sort predicate: count desc, peakTimestamp asc, UserId asc per ADR-0005.
--- Nil peakTimestamp treated as math.huge per arch §5.3 L638.
--- Used by `_resolveWinnerF4`.
local function _f4Less(
	a: CrowdStateServer.CrowdRecord,
	b: CrowdStateServer.CrowdRecord
): boolean
	if a.count ~= b.count then
		return a.count > b.count
	end
	local rl = _getRoundLifecycle()
	local ta = rl.getPeakTimestamp(a.crowdId) or math.huge
	local tb = rl.getPeakTimestamp(b.crowdId) or math.huge
	if ta ~= tb then
		return ta < tb
	end
	-- crowdId is tostring(UserId); deterministic numeric compare.
	local ua = tonumber(a.crowdId) or math.huge
	local ub = tonumber(b.crowdId) or math.huge
	return ua < ub
end

--- Resolves the round winner via F4 tiebreak. Returns the crowdId or nil if
--- no Active candidates remain (all eliminated). Excludes Eliminated per
--- CSM.getAllActive contract.
local function _resolveWinnerF4(): string?
	local candidates = _getCSM().getAllActive()
	if #candidates == 0 then
		return nil
	end
	table.sort(candidates, _f4Less)
	return candidates[1].crowdId
end

-- Test-only player resolver. Production uses Players:GetPlayerByUserId, which
-- returns nil for fake `{ UserId = N }` test fixtures. Tests register a lookup
-- function so `_participatingPlayers()` can return the original Player refs.
local _playerResolverOverride: ((userId: number) -> Player?)? = nil

local function _resolvePlayer(userId: number): Player?
	if _playerResolverOverride ~= nil then
		return _playerResolverOverride(userId)
	end
	return Players:GetPlayerByUserId(userId)
end

-- ---------------------------------------------------------------------------
-- Module-private helpers (local functions; exposed via test surface only)
-- ---------------------------------------------------------------------------

--- Module-private state transition. Called by internal driver loops only
--- (story-002+ wires the timer + signal subscribers). Writes _state +
--- _stateStartTime + _stateEndsAt and fires the server-only
--- MatchStateChangedServer BindableEvent for intra-server consumers.
--- Story 7-10: also fires the client-facing MatchStateChanged reliable
--- RemoteEvent via _fireMatchStateChanged (single broadcast chokepoint).
local function _transitionTo(newState: MatchState, endsAt: number?, meta: { [string]: any }?): ()
	_state = newState
	_stateStartTime = os.clock()
	_stateEndsAt = endsAt
	_matchStateChangedServer:Fire(newState, endsAt)
	-- Story 7-10: also broadcast to clients with full payload schema.
	-- Wrapped in pcall — fire failures must not break state-machine integrity.
	local ok, err = pcall(function()
		Network.fireAllClients(RemoteEventName.MatchStateChanged, {
			state = newState,
			serverTimestamp = _stateStartTime,
			stateEndsAt = endsAt,
			meta = meta or {},
		})
	end)
	if not ok then
		warn("[MatchStateServer] MatchStateChanged broadcast failed: " .. tostring(err))
	end
end

--- Counts the participating (truthy) entries in `_participation`.
local function _countParticipating(): number
	local count = 0
	for _, flag in _participation do
		if flag == true then
			count += 1
		end
	end
	return count
end

--- Returns an array of Player instances whose participation flag is true.
--- Iteration order is arbitrary (pairs traversal). Used by RoundLifecycle.createAll
--- on Snap → Active. Skips players that have already disconnected (resolveOwner
--- guard via Players:GetPlayerByUserId).
local function _participatingPlayers(): { Player }
	local out: { Player } = {}
	for userId, flag in _participation do
		if flag == true then
			local player = _resolvePlayer(userId)
			if player ~= nil then
				table.insert(out, player)
			end
		end
	end
	return out
end

--- Module-private participation flag setter. Honors the Snap-freeze rule:
--- when in "Countdown:Snap", a TRUE→FALSE attempt is REJECTED (locked-in
--- participants cannot drop out mid-snap). FALSE→TRUE is always allowed.
--- Outside Snap, both directions are allowed.
---
--- T1 / F5 driver wiring (story-002): post-write side effects:
---   * Lobby + count(post) ≥ MIN_PLAYERS_TO_START → transition to Countdown:Ready.
---   * Countdown:Ready + count(post) < MIN_PLAYERS_TO_START → revert to Lobby (F5).
---
--- ADR-0005 §Decision; GDD design/gdd/match-state-machine.md §Participation Rules + T1/T2/F5.
local function _setParticipation(player: Player, flag: boolean): ()
	local userId = player.UserId
	local current = _participation[userId] == true

	-- Snap freeze: TRUE→FALSE rejected. Locked-in participants cannot opt out
	-- once the Countdown:Snap phase begins (GDD §Participation Rules).
	if _state == "Countdown:Snap" and current == true and flag == false then
		return
	end

	-- Always write the explicit entry — keeps T10 reset's `for k in _participation`
	-- iteration aware of every player who has ever interacted, even if the
	-- value is unchanged. (Without explicit entry, a never-participated player
	-- would be skipped by T10 and stay implicitly false post-Intermission.)
	_participation[userId] = flag

	-- Story 7-10: ParticipationChanged reliable RemoteEvent fanout. Per-player
	-- (owning player only). SKIP signal when flag unchanged — avoid spurious
	-- broadcasts on idempotent writes. Wrapped in pcall — broadcast failures
	-- must not break the state-machine driver below.
	if current ~= flag then
		local ok, err = pcall(function()
			Network.fireClient(RemoteEventName.ParticipationChanged, player, {
				participating = flag,
			})
		end)
		if not ok then
			warn("[MatchStateServer] ParticipationChanged broadcast failed: " .. tostring(err))
		end
	end

	-- Post-write driver: T1 (Lobby → Countdown:Ready) and F5 revert.
	-- Forward-declared via assignment below to allow _transitionTo reference
	-- inside this body. _transitionTo defined directly above; the reference
	-- works because Lua closes over local variable by name at call time.
	local count = _countParticipating()
	if _state == "Lobby" and count >= MIN_PLAYERS_TO_START then
		_transitionTo("Countdown:Ready", os.clock() + COUNTDOWN_READY_SEC)
	elseif _state == "Countdown:Ready" and count < MIN_PLAYERS_TO_START then
		_transitionTo("Lobby", nil)
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local MatchStateServer = {}

--- Server-only BindableEvent. Fires on every `_transitionTo` call with payload
--- `(newState: MatchState, endsAt: number?)`. Subscribe via:
---   `MatchStateServer.MatchStateChangedServer.Event:Connect(handler)`
--- Use cases: NPCSpawner createAll/destroyAll wiring, intra-server lifecycle
--- side-effects that don't belong inside MSM. Read-only — never re-fire,
--- never invoke state mutators from the handler.
---
--- **Result-state caveat**: `_handleResultEntry` writes `_state = "Result"`
--- DIRECTLY (bypasses `_transitionTo`) to honor the grants-before-broadcast
--- ordering invariant per ADR-0005 §Result-entry. Consequence: this
--- BindableEvent does NOT fire for Result entry. Subsequent Result→Intermission
--- transitions DO fire (those go through `_transitionTo`). Future server-side
--- consumers that need a Result signal should subscribe to the
--- `MatchStateChanged` reliable RemoteEvent (story-007) instead.
---
--- **Dispatch is deferred** (Roblox BindableEvent contract): handlers run on
--- the next micro-task resumption, not synchronously inline with `:Fire`.
MatchStateServer.MatchStateChangedServer = _matchStateChangedServer

--- Returns the current match state. Read-only for external consumers.
--- Callers: HUD, FTUE, spectator camera, Currency system.
--- ADR-0005 §Decision — any server module may read.
function MatchStateServer.get(): MatchState
	return _state
end

--- Returns the participation flag for the given player. Defaults to false if
--- the player has no entry yet (e.g. PlayerAdded handler not fired). New
--- joiners auto-set to true on PlayerAdded.
--- ADR-0005 §Decision — any server module may read.
function MatchStateServer.getParticipation(player: Player): boolean
	return _participation[player.UserId] == true
end

--- Returns the absolute timestamp at which the current state's timer expires,
--- or nil for non-timed states (Lobby, Active, ServerClosing). Set by
--- _transitionTo when entering a timed state. Story-002 owns the writer logic.
function MatchStateServer.getStateEndsAt(): number?
	return _stateEndsAt
end

--- Phase 6 timer-driven transition callback. Sole caller: TickOrchestrator
--- Phase 6 dispatch. Must NOT yield.
---
--- Pre-Active timer transitions (story-002 — this story):
---   * Countdown:Ready, elapsed ≥ 7s → Countdown:Snap (state ends at +3s).
---   * Countdown:Snap,  elapsed ≥ 3s (10s total) → handleSnapToActiveOrResult:
---       - 0 participants → Result, _stateEndsAt = now + RESULT_DURATION_SEC,
---         RoundLifecycle.createAll NOT invoked.
---       - ≥1 participant → RoundLifecycle.createAll(participatingPlayers)
---         FIRST, then transition to Active with _stateEndsAt = now + 300s.
---
--- T7 (Active → Result via timer expiry) + F4 tiebreak land in story-003.
---
--- ADR-0002 §Phase 6; ADR-0005 §Decision T1-T5; manifest L96.
function MatchStateServer.timerCheck(_tickCount: number): ()
	local now = os.clock()
	local endsAt = _stateEndsAt
	if endsAt == nil then
		return
	end

	if _state == "Active" and now >= endsAt then
		-- T7 — round timer expiry → Result. Resolve winner via F4 tiebreak
		-- on the Phase 6 snapshot (per AC-21: counts captured BEFORE Phase 7
		-- elim consumer can act). Phase 7 will see _state == "Result" and
		-- silently drop any queued elim signal.
		_winnerId = _resolveWinnerF4()
		_handleResultEntry()
	elseif _state == "Countdown:Ready" and now >= endsAt then
		-- T3 — Ready → Snap (snap freezes participation flags from this point).
		_transitionTo("Countdown:Snap", now + COUNTDOWN_SNAP_SEC)
	elseif _state == "Countdown:Snap" and now >= endsAt then
		-- T4 / T5 — Snap → Active (≥1 participant) OR Snap → Result (0).
		local participants = _participatingPlayers()
		if #participants == 0 then
			-- T5 — zero participants → Result with no winner. Skip Result-entry
			-- grant chain (no winner, no createAll → no placements).
			_winnerId = nil
			_transitionTo("Result", now + RESULT_DURATION_SEC)
		else
			-- T4 — call createAll FIRST then transition to Active.
			-- Order matters per AC-7: [createAll, broadcast("Active")].
			_getRoundLifecycle().createAll(participants)
			_transitionTo("Active", now + ROUND_DURATION_SEC)
		end
	elseif _state == "Result" and now >= endsAt then
		-- T9 — Result → Intermission per destroyAll → clearAll ordering invariant.
		_handleIntermissionEntry()
	elseif _state == "Intermission" and now >= endsAt then
		-- T10 — Intermission → Lobby with full flag reset.
		_handleLobbyEntryFromIntermission()
	end
end

--- Returns the resolved round winner's crowdId, or nil if no winner has been
--- set yet (or zero-participant Result). Set by T6/T7/T8 paths. Read by
--- broadcast (story-005) + Currency.grantMatchRewards (story-005).
--- T11 BindToClose entry point. Fires MatchStateChanged("ServerClosing") to
--- all clients so the UI can react before ProfileStore's 30s grace finishes.
--- Called by ShutdownCoordinator (sole caller) per ADR-0005 §BindToClose ownership.
--- Does NOT call _transitionTo — at shutdown the state machine is already
--- being torn down; the broadcast is the only observable outcome the client
--- needs. NO currency grant during shutdown (ADR-0011 §Grace + manifest L106).
--- Mirrors MatchStateServerStub.requestServerClosing semantics so the
--- ShutdownCoordinator chain is unaffected by the stub→real swap.
function MatchStateServer.requestServerClosing(): ()
	-- Story 7-10: full schema payload {state, serverTimestamp, stateEndsAt, meta}.
	-- stateEndsAt = nil for ServerClosing (no timer — shutdown is immediate).
	local ok, err = pcall(function()
		Network.fireAllClients(RemoteEventName.MatchStateChanged, {
			state = "ServerClosing",
			serverTimestamp = os.clock(),
			stateEndsAt = nil,
			meta = {},
		})
	end)
	if not ok then
		warn("[MatchStateServer] MatchStateChanged ServerClosing broadcast failed: " .. tostring(err))
	end
end

function MatchStateServer.getWinnerId(): string?
	return _winnerId
end

--- Phase 7 callback — drains the queued CrowdEliminated signals and triggers
--- T6 (last-standing → Result) when active count ≤ 1. Sole caller:
--- TickOrchestrator (Phase 7 dispatch). Must NOT yield.
---
--- Body:
---   1. `if _state ~= "Active" then return end` — double-signal guard. If
---      Phase 6 already transitioned to Result this tick, drop queued elims
---      silently (per AC-11/AC-21).
---   2. Clear `_pendingElims` (drain at top — handler accumulates into queue
---      between ticks; drain is the side effect of running Phase 7).
---   3. Query CSM.getAllActive() count (Eliminated already filtered).
---   4. If `#active <= 1` → resolve winner (sole survivor or nil), transition
---      to Result. T6 path uses winnerId from sole survivor; empty path nil.
---
--- T8 instant-win (DC sole-survivor) lands in PlayerRemoving handler — fires
--- the same path with `meta.rivalDisconnected = true`. This callback handles
--- the elim-driven path only.
---
--- ADR-0002 §Phase 7; ADR-0005 §Decision T6 + double-signal guard;
--- manifest L97.
function MatchStateServer.eliminationConsumer(_tickCount: number): ()
	if _state ~= "Active" then
		-- AC-11/AC-21 double-signal guard: Phase 6 (T7) already moved to Result.
		-- Drop queued elims silently; do NOT clear _pendingElims here — they
		-- already happened, but state advanced past Active.
		_pendingElims = {}
		return
	end

	-- Drain. (Stored crowdIds not consumed individually — count check below
	-- inspects CSM authoritative state, which CSM Phase 5 has already updated.)
	_pendingElims = {}

	local active = _getCSM().getAllActive()
	if #active > 1 then
		return  -- match continues
	end

	-- T6 — sole survivor (or empty). Resolve winner from remaining set.
	if #active == 1 then
		_winnerId = active[1].crowdId
	else
		_winnerId = nil
	end

	-- Result-entry ordering invariant: setWinner → getPlacements → grant → broadcast.
	_handleResultEntry()
end

--- Connects PlayerAdded / PlayerRemoving / AFKToggle handlers. Called once
--- at boot from ServerScriptService/start.server.luau. Idempotent — second
--- call returns early without replacing existing connections.
---
--- PlayerAdded: auto-set participation = true (any state).
--- PlayerRemoving: clear participation entry (frees memory; transition
---                 effects handled by story-002+).
--- AFKToggle: stub — full validation per ADR-0010 4-check guard lives in
---            story-007. Story-001 wire accepts the flag verbatim via
---            _setParticipation (which honors Snap freeze).
--- Story 7-10: extracted AFKToggle handler — production path is wrapped by
--- Network.connectEvent in start(); tests invoke this directly via the
--- `_handleAFKToggleForTest` seam to bypass Network requirement.
--- Performs full ADR-0010 4-check guard. Silent reject on any check failure.
local function _handleAFKToggle(player: Player, payload: any): ()
	if not RemoteValidator.checkIdentity(player) then return end
	if not RemoteValidator.checkState(function()
		return _state == "Lobby" or _state == "Countdown:Ready"
	end) then return end
	if not RemoteValidator.checkParameters(payload, { participating = "boolean" }) then return end
	if not RemoteValidator.checkRate(player, RemoteEventName.AFKToggle) then return end
	_setParticipation(player, payload.participating)
end

--- Story 7-10: extracted GetParticipation handler. Stateless; safe to expose
--- to tests as the read API. Returns boolean (nil entry → false).
local function _handleGetParticipation(player: Player): boolean
	return _participation[player.UserId] == true
end

function MatchStateServer.start(): ()
	if _playerAddedConnection ~= nil then
		return -- idempotent
	end

	_playerAddedConnection = Players.PlayerAdded:Connect(function(player: Player)
		_setParticipation(player, true)
	end)

	_playerRemovingConnection = Players.PlayerRemoving:Connect(function(player: Player)
		_participation[player.UserId] = nil
		-- F5 revert mirror: PlayerRemoving bypasses _setParticipation, so re-check
		-- the participation count and revert Countdown:Ready → Lobby if needed.
		if _state == "Countdown:Ready" and _countParticipating() < MIN_PLAYERS_TO_START then
			_transitionTo("Lobby", nil)
			return
		end
		-- T8 instant-win detection: if we're Active and the disconnect leaves
		-- exactly one crowd active (CSM destroy already ran via its own
		-- PlayerRemoving handler), trigger Result with rivalDisconnected meta.
		-- Note: this story stores winner + transitions; meta payload is consumed
		-- by story-005 broadcast wiring.
		if _state == "Active" then
			local active = _getCSM().getAllActive()
			if #active == 1 then
				_winnerId = active[1].crowdId
				_handleResultEntry()
			elseif #active == 0 then
				_winnerId = nil
				_handleResultEntry()
			end
		end
	end)

	-- Subscribe to CSM CrowdEliminatedServer BindableEvent (server-only signal
	-- fired in tandem with the CrowdEliminated reliable RemoteEvent from
	-- CSM Phase 5). Queue payload crowdId for Phase 7 drain.
	_crowdEliminatedConnection = CrowdStateServer.CrowdEliminatedServer.Event:Connect(
		function(crowdId: string)
			table.insert(_pendingElims, crowdId)
		end
	)

	-- Story 7-10: AFKToggle handler with ADR-0010 4-check guard.
	-- Wrapped in pcall — Network.connectEvent requires Network.startServer
	-- to have run; in headless TestEZ context Network is not booted and the
	-- connect throws. Production boot order: Network.startServer →
	-- MatchStateServer.start() so connect succeeds. Failure logged but does
	-- not crash module init.
	local connectOk, connectErr = pcall(function()
		_afkToggleConnection = Network.connectEvent(
			RemoteEventName.AFKToggle,
			function(player: Player, payload: any)
				_handleAFKToggle(player, payload)
			end,
			function(_player, _payload) return true end  -- typing handled by RemoteValidator
		)
	end)
	if not connectOk then
		warn("[MatchStateServer] AFKToggle connect failed (likely no Network in test context): "
			.. tostring(connectErr))
	end

	-- Story 7-10: GetParticipation RemoteFunction — stateless reconcile for
	-- mid-state-join clients. Returns boolean; nil _participation entry → false.
	local bindOk, bindErr = pcall(function()
		Network.bindFunction(
			RemoteFunctionName.GetParticipation,
			function(player: Player): boolean
				return _handleGetParticipation(player)
			end,
			function(_player) return true end
		)
	end)
	if not bindOk then
		warn("[MatchStateServer] GetParticipation bind failed (likely no Network in test context): "
			.. tostring(bindErr))
	end
end

-- ---------------------------------------------------------------------------
-- Test-only surface — _-prefixed; NEVER call from production code
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module state for test isolation. Disconnects all event handlers;
--- clears participation map; resets state to Lobby.
--- Must be called in beforeEach() for every MatchStateServer spec.
function MatchStateServer._resetForTests(): ()
	if _playerAddedConnection ~= nil then
		_playerAddedConnection:Disconnect()
		_playerAddedConnection = nil
	end
	if _playerRemovingConnection ~= nil then
		_playerRemovingConnection:Disconnect()
		_playerRemovingConnection = nil
	end
	if _afkToggleConnection ~= nil then
		_afkToggleConnection:Disconnect()
		_afkToggleConnection = nil
	end
	if _crowdEliminatedConnection ~= nil then
		_crowdEliminatedConnection:Disconnect()
		_crowdEliminatedConnection = nil
	end
	_state = "Lobby"
	_participation = {}
	_stateStartTime = nil
	_stateEndsAt = nil
	_roundLifecycleOverride = nil
	_playerResolverOverride = nil
	_csmOverride = nil
	_currencyOverride = nil
	_relicSystemOverride = nil
	_winnerId = nil
	_pendingElims = {}
end

--- **TEST ONLY** — overrides Currency dependency for grant-call spy.
function MatchStateServer._setCurrencyOverride(c: CurrencyDependency?): ()
	_currencyOverride = c
end

--- **TEST ONLY** — overrides RelicSystem dependency for clearAll spy.
function MatchStateServer._setRelicSystemOverride(rs: RelicSystemDependency?): ()
	_relicSystemOverride = rs
end

--- **TEST ONLY** — direct injection into _pendingElims for fixture setup.
--- Used by elim_consumer_t6.spec to seed the queue without wiring the full
--- CSM CrowdEliminatedServer signal path.
function MatchStateServer._pushPendingElimForTests(crowdId: string): ()
	table.insert(_pendingElims, crowdId)
end

--- **TEST ONLY** — read-only inspection of the pending elim queue.
function MatchStateServer._getPendingElimsCount(): number
	return #_pendingElims
end

--- **TEST ONLY** — never call from production code.
--- Overrides CrowdStateServer dependency for F4 tiebreak fixture seeding.
--- Tests inject a mock with `getAllActive()` returning seeded records.
function MatchStateServer._setCSMOverride(csm: CSMDependency?): ()
	_csmOverride = csm
end

--- **TEST ONLY** — direct write of `_winnerId` for fixture setup. Used to
--- verify post-Result behavior without driving the full T6/T7/T8 chain.
function MatchStateServer._setWinnerIdForTests(winnerId: string?): ()
	_winnerId = winnerId
end

--- **TEST ONLY** — never call from production code.
--- Overrides RoundLifecycle dependency. Tests inject a mock with `createAll`
--- and `destroyAll` to spy on call ordering. Cleared by _resetForTests.
function MatchStateServer._setRoundLifecycleOverride(rl: RoundLifecycleDependency?): ()
	_roundLifecycleOverride = rl
end

--- **TEST ONLY** — never call from production code.
--- Overrides Players:GetPlayerByUserId for the participating-player resolver.
--- Required because TestEZ fixtures use fake `{ UserId = N }` Player tables
--- that the real Players service does not know about. Cleared by
--- _resetForTests.
function MatchStateServer._setPlayerResolverForTests(
	fn: ((userId: number) -> Player?)?
): ()
	_playerResolverOverride = fn
end

--- **TEST ONLY** — direct state probe. Avoids exposing _state via public API;
--- useful for verifying _transitionTo side-effects.
function MatchStateServer._getState(): MatchState
	return _state
end

--- **TEST ONLY** — bypass _transitionTo to set state directly for fixture
--- setup (e.g. force "Countdown:Snap" to test asymmetric freeze rule).
--- Production code MUST go through _transitionTo (story-002+).
function MatchStateServer._setStateForTests(newState: MatchState): ()
	_state = newState
end

--- **TEST ONLY** — direct write of `_stateEndsAt` for fixture setup. Used by
--- transition_ready_snap.spec to position the timer past the threshold without
--- waiting in real-time. Cleared by _resetForTests via state reset.
function MatchStateServer._setStateEndsAtForTests(endsAt: number?): ()
	_stateEndsAt = endsAt
end

--- **TEST ONLY** — exposes module-private _setParticipation for direct
--- invocation. Production callers wire via PlayerAdded handler + AFKToggle
--- RemoteEvent only.
function MatchStateServer._setParticipation(player: Player, flag: boolean): ()
	_setParticipation(player, flag)
end

--- **TEST ONLY** — returns the PlayerAdded connection for idempotence checks.
function MatchStateServer._getPlayerAddedConnection(): RBXScriptConnection?
	return _playerAddedConnection
end

--- **TEST ONLY** — returns the PlayerRemoving connection for idempotence checks.
function MatchStateServer._getPlayerRemovingConnection(): RBXScriptConnection?
	return _playerRemovingConnection
end

--- **TEST ONLY** — returns the AFKToggle connection for idempotence checks.
--- Type is RBXScriptConnection? — Network.connectEvent returns the underlying
--- OnServerEvent:Connect result (RBXScriptConnection).
function MatchStateServer._getAFKToggleConnection(): RBXScriptConnection?
	return _afkToggleConnection
end

--- **TEST ONLY** — Story 7-10. Invokes the AFKToggle 4-check handler directly,
--- bypassing the Network.connectEvent wrapper. Production callers use the
--- Network path; tests use this to exercise the validation guard without
--- requiring Network.startServer to have run.
function MatchStateServer._handleAFKToggleForTest(player: any, payload: any): ()
	_handleAFKToggle(player, payload)
end

--- **TEST ONLY** — Story 7-10. Invokes the GetParticipation handler directly.
function MatchStateServer._handleGetParticipationForTest(player: any): boolean
	return _handleGetParticipation(player)
end

return MatchStateServer
