--!strict

--[[
	RoundLifecycle — round-scoped aux state + Janitor lifecycle.
	Path: ServerStorage/Source/RoundLifecycle/init.luau
	Implements: ADR-0005 §Decision (RoundLifecycle as sub-coordinator of MSM)
	            ADR-0003 §Memory (≤2 KB per round)
	            ADR-0006 §Source Tree Map (server-only)
	            GDD design/gdd/round-lifecycle.md

	Story-001 scope: module skeleton + InternalAuxRecord type + per-round
	Janitor allocation + createAll(participants) + destroyAll() with proper
	teardown order. CountChanged subscription + peak tracking deferred to
	story-002; Eliminated subscription + DC freeze to story-003;
	setWinner / getPeakTimestamp to story-004; getPlacements to story-005.

	Caller invariant: MSM is the SOLE caller of all RoundLifecycle methods
	(control-manifest L138). Outside-MSM access forbidden.

	Public API (story-001):
	  createAll(participatingPlayers) -> ()  -- T4 / round-start
	  destroyAll() -> ()                     -- T9 / round-end + cleanup

	Test-only API (_-prefixed):
	  _resetForTests()                       -- zero state + nil out _janitor
	  _getCrowdsCount()                      -- size of internal _crowds aux
	  _getParticipantsCount()                -- length of _participants
	  _getJanitor()                          -- expose for assertion (nil-or-not)
	  _setCSMOverride(csm)                   -- DI seam for tests
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Janitor = require(Packages.janitor)

local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

-- ADR-0005 §Authority Matrix; control-manifest L104.
local MAX_PARTICIPANTS_PER_ROUND = 12

-- Matches ADR-0003 §Memory (RoundLifecycle aux peakCount initial value) and
-- story-001 AC-1 fixture: peakCount=10, finalCount=10 on createAll success.
local CROWD_START_COUNT = 10

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

--- ADR-0001 §Key Interfaces hue palette: 12 named slots, 1-indexed.
--- RL assigns hue by participant index (1..N → 1..N capped at 12).
local function hueForIndex(i: number): number
	return ((i - 1) % 12) + 1
end

--- Per-crowd auxiliary record owned exclusively by RoundLifecycle.
--- ADR-0005 §Module Split RL diagram; GDD design/gdd/round-lifecycle.md §C.
--- story-001 fields: crowdId, userId, peakCount, peakTimestamp, finalCount,
--- eliminationTime, survived.
--- peakCount / peakTimestamp updated in story-002 (CountChanged subscriber).
--- eliminationTime / survived updated in story-003 (CrowdEliminated subscriber).
--- isWinner updated in story-004 (setWinner).
export type InternalAuxRecord = {
	crowdId: string,
	userId: number,
	peakCount: number,
	peakTimestamp: number,
	finalCount: number,
	eliminationTime: number?,
	survived: boolean,
}

--- Minimal CSM dependency surface used by RoundLifecycle. Tests inject a mock
--- via _setCSMOverride; production path uses the real CrowdStateServer module.
--- Matches CrowdStateServer.create + CrowdStateServer.destroy public surface
--- (CSM story-001 shipped).
type CSMDependency = {
	create: (crowdId: string, initial: any) -> any,
	destroy: (crowdId: string) -> (),
	-- CountChanged BindableEvent — story-002 subscribes via .Event:Connect.
	CountChanged: BindableEvent?,
}

-- Forward declaration — defined after createAll, used inside it.
local _onCountChanged: (crowdId: string, newCount: number) -> ()

-- ---------------------------------------------------------------------------
-- Module-level state (all private)
-- ---------------------------------------------------------------------------

local _crowds: { [string]: InternalAuxRecord } = {}
local _participants: { Player } = {}
local _winnerId: string? = nil
-- Janitor instance — `any` because Janitor's type signature is opaque from
-- this module's POV. Janitor itself is runtime-typed; we interact via
-- :Add() / :Destroy() methods documented in Packages.janitor.
local _janitor: any = nil

--- DI seam: tests inject a mock CSM via _setCSMOverride. Production path
--- reads the real CrowdStateServer module.
local _csmOverride: CSMDependency? = nil

local function getCSM(): CSMDependency
	return _csmOverride or (CrowdStateServer :: any) :: CSMDependency
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local RoundLifecycle = {}

--- Allocates a fresh Janitor + creates a CSM record per participant + builds
--- the aux record for each. Sole caller: MatchStateServer.transitionTo("Active")
--- (T4 round-start path). Asserts no prior Janitor exists (caller bug if not
--- destroyAll'd first) and that participant count <= MAX_PARTICIPANTS_PER_ROUND.
--- Per-player CSM.create is wrapped in pcall — failures logged + skipped, do
--- not abort the entire call.
--- ADR-0005 §Decision; control-manifest L94.
function RoundLifecycle.createAll(participatingPlayers: { Player }): ()
	assert(
		_janitor == nil,
		"RoundLifecycle: createAll called without prior destroyAll"
	)
	assert(
		#participatingPlayers <= MAX_PARTICIPANTS_PER_ROUND,
		"RoundLifecycle: MAX_PARTICIPANTS_PER_ROUND ("
			.. MAX_PARTICIPANTS_PER_ROUND
			.. ") exceeded; got "
			.. #participatingPlayers
	)

	-- Allocate the per-round Janitor FIRST so it exists even for empty rounds.
	-- story-002 + story-003 add signal subscriptions via _janitor:Add().
	_janitor = Janitor.new()
	_participants = {}
	_winnerId = nil
	_crowds = {}

	local csm = getCSM()
	local now = os.clock()

	for i, player in participatingPlayers do
		local crowdId = tostring(player.UserId)
		-- Initial CrowdRecord shape mirrors CrowdStateServer.CrowdRecord.
		-- Spawn position composition lives outside this story (story-002/CSM).
		local initial = {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = CROWD_START_COUNT,
			hue = hueForIndex(i),
			activeRelics = {},
			state = "Active",
			tick = 0,
			stillOverlapping = false,
			timer_start = nil,
		}

		local ok, err = pcall(csm.create, crowdId, initial)
		if not ok then
			-- AC-2: warn cites UserId + error; player excluded from _participants
			-- and _crowds. Subsequent getPlacements (story-005) iterates _crowds
			-- keys → missing player naturally absent.
			warn(string.format(
				"RoundLifecycle: CSM.create failed for player UserId=%d (crowdId=%s): %s",
				player.UserId,
				crowdId,
				tostring(err)
			))
			continue
		end

		-- AC-1: peakCount=CROWD_START_COUNT, peakTimestamp=os.clock(), finalCount=CROWD_START_COUNT,
		-- eliminationTime=nil, survived=true (until CrowdEliminated fires in story-003).
		_crowds[crowdId] = {
			crowdId = crowdId,
			userId = player.UserId,
			peakCount = CROWD_START_COUNT,
			peakTimestamp = now,
			finalCount = CROWD_START_COUNT,
			eliminationTime = nil,
			survived = true,
		}
		table.insert(_participants, player)
	end

	-- Story-002: subscribe to CSM.CountChanged for F1 peak tracking. Janitor-
	-- managed so destroyAll auto-disconnects. Real CSM exposes the BindableEvent
	-- as a module field (CSM story-001 line 191). Test mocks may omit it — guard
	-- nil-safely.
	local countChanged = (csm :: any).CountChanged
	if countChanged ~= nil then
		_janitor:Add(
			countChanged.Event:Connect(function(
				crowdId: string,
				_oldCount: number,
				newCount: number,
				_deltaSource: string
			): ()
				_onCountChanged(crowdId, newCount)
			end),
			"Disconnect"
		)
	end
end

--- F1 peak tracking handler. Strict `>` rule per manifest L102: equal counts
--- do NOT update peakTimestamp (preserves earliest-peak wins F4 tiebreak).
--- Always tracks `finalCount` regardless of peak comparison (used by getPlacements).
--- Silent guard for non-record crowdIds (post-destroy race tolerance per AC-8).
--- ADR-0005 §F1; CSM story-002 BindableEvent contract.
_onCountChanged = function(crowdId: string, newCount: number): ()
	local record = _crowds[crowdId]
	if record == nil then
		return  -- AC-8 silent guard
	end
	if newCount > record.peakCount then
		record.peakCount = newCount
		record.peakTimestamp = os.clock()
	end
	record.finalCount = newCount
end

--- Tears down the round: Janitor destroyed FIRST (disconnects all subscribers
--- so stray signals post-destroy are silently no-op), THEN per-crowd CSM
--- destroys, THEN local state cleared. Sole caller: MatchStateServer T9 path
--- + ServerClosing path.
--- Ordering invariant: destroyAll → RelicSystem.clearAll → MatchStateChanged
--- broadcast (ADR-0005 §Round-End Ordering Invariants T9, locked).
--- ADR-0005 §Decision; control-manifest L94.
function RoundLifecycle.destroyAll(): ()
	-- Step 1: destroy Janitor FIRST so subscribers (story-002 + story-003)
	-- are disconnected before CSM.destroy fires. Otherwise stray CountChanged
	-- or Eliminated signals during teardown would mutate _crowds mid-iteration.
	if _janitor ~= nil then
		_janitor:Destroy()
		_janitor = nil
	end

	-- Step 2: idempotent CSM destroys for every aux record we tracked.
	-- CrowdStateServer.destroy is idempotent per CSM story-001 contract.
	local csm = getCSM()
	for crowdId in _crowds do
		csm.destroy(crowdId)
	end

	-- Step 3: zero local state (Pillar 3 clean-wipe invariant;
	-- ADR-0005 §Constraints; control-manifest L150).
	_crowds = {}
	_participants = {}
	_winnerId = nil
end

-- ---------------------------------------------------------------------------
-- Test-only surface (_-prefixed)
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Zeros all module-level state for test isolation. Destroys any live Janitor;
--- clears all tables; clears the CSM override. Must be called in beforeEach()
--- for every RoundLifecycle spec.
function RoundLifecycle._resetForTests(): ()
	if _janitor ~= nil then
		_janitor:Destroy()
		_janitor = nil
	end
	_crowds = {}
	_participants = {}
	_winnerId = nil
	_csmOverride = nil
end

--- **TEST ONLY** — never call from production code.
--- Returns the count of records in the private _crowds aux table.
--- Used to verify AC-1, AC-2, AC-3, AC-4 without exposing _crowds directly.
function RoundLifecycle._getCrowdsCount(): number
	local count = 0
	for _ in _crowds do
		count += 1
	end
	return count
end

--- **TEST ONLY** — never call from production code.
--- Returns #_participants for assertion in createAll + destroyAll specs.
function RoundLifecycle._getParticipantsCount(): number
	return #_participants
end

--- **TEST ONLY** — never call from production code.
--- Returns the live Janitor instance (or nil). Tests assert non-nil after
--- createAll and nil after destroyAll / _resetForTests.
function RoundLifecycle._getJanitor(): any
	return _janitor
end

--- **TEST ONLY** — never call from production code.
--- Injects a mock CSM dependency. Pass nil to clear (also cleared by
--- _resetForTests). Mirrors the _setTestFanoutInterceptor DI seam pattern
--- established by CrowdStateServer story-001.
--- Returns the `peakTimestamp` for the given crowdId, or nil if no aux record
--- exists. Used by MSM F4 tiebreak (story-003 of MSM epic) — earliest peak
--- timestamp wins on count tie.
--- ADR-0005 §F4 tiebreak; arch §5.3 L638 nil treated as math.huge by caller.
function RoundLifecycle.getPeakTimestamp(crowdId: string): number?
	local record = _crowds[crowdId]
	if record == nil then
		return nil
	end
	return record.peakTimestamp
end

--- Marks the given crowdId as the round winner. Sole caller: MSM Result
--- entry (`_handleResultEntry` per ADR-0005 §Result-entry ordering invariant).
--- nil winnerId allowed (zero-participant Result + empty-elimination edge).
--- Asserts loud if crowdId set but record absent (caller bug).
--- ADR-0005 §Decision; arch §5.3.
function RoundLifecycle.setWinner(crowdId: string?): ()
	_winnerId = crowdId
	if crowdId ~= nil then
		assert(
			_crowds[crowdId] ~= nil,
			"RoundLifecycle.setWinner: record absent for crowdId=" .. crowdId
		)
	end
end

--- Placement record returned by getPlacements. Includes per-crowd round
--- summary used by Currency.grantMatchRewards + Result broadcast meta.
--- Internal fields (peakCount, isWinner, wasEliminated) are STRIPPED before
--- broadcast per manifest L100 InternalPlacement strip rule — stripping is
--- MSM's job in `_stripInternalPlacements`. RoundLifecycle returns the full
--- record; caller filters.
export type Placement = {
	crowdId: string,
	userId: number,
	placement: number,
	crowdCount: number,
	eliminationTime: number?,
	-- Internal fields — strip before broadcast.
	peakCount: number,
	isWinner: boolean,
	wasEliminated: boolean,
}

--- Returns the per-crowd placement array for the round. Sole caller: MSM
--- `_handleResultEntry` (after `setWinner`). Sort: winner first, then survivors
--- by finalCount desc, then eliminated by eliminationTime desc (most recent
--- first). Placement field assigned by sort position (1 = winner).
---
--- Asserts that `setWinner` was called first (when participants non-empty)
--- per ADR-0005 §Result-entry ordering invariant.
--- ADR-0005 §Decision; arch §5.3 L630.
function RoundLifecycle.getPlacements(): { Placement }
	-- Empty participants → empty placements (zero-participant Result edge).
	local recordCount = 0
	for _ in _crowds do
		recordCount += 1
	end
	if recordCount == 0 then
		return {}
	end

	assert(
		_winnerId ~= nil or recordCount == 0,
		"RoundLifecycle.getPlacements: setWinner must be called before getPlacements when participants are non-empty"
	)

	local placements: { Placement } = {}
	for _, record in _crowds do
		table.insert(placements, {
			crowdId = record.crowdId,
			userId = record.userId,
			placement = 0,  -- assigned post-sort
			crowdCount = record.finalCount,
			eliminationTime = record.eliminationTime,
			peakCount = record.peakCount,
			isWinner = (record.crowdId == _winnerId),
			wasEliminated = (not record.survived),
		})
	end

	table.sort(placements, function(a, b)
		-- Winner first.
		if a.isWinner ~= b.isWinner then
			return a.isWinner
		end
		-- Among non-winners: survivors before eliminated.
		if a.wasEliminated ~= b.wasEliminated then
			return not a.wasEliminated
		end
		-- Survivors: highest finalCount first.
		if not a.wasEliminated and not b.wasEliminated then
			return a.crowdCount > b.crowdCount
		end
		-- Eliminated: most-recently-eliminated first.
		local ta = a.eliminationTime or -math.huge
		local tb = b.eliminationTime or -math.huge
		if ta ~= tb then
			return ta > tb
		end
		-- Final tiebreak: argmin(userId) for determinism.
		return a.userId < b.userId
	end)

	for i, p in placements do
		p.placement = i
	end

	return placements
end

function RoundLifecycle._setCSMOverride(csm: CSMDependency?): ()
	_csmOverride = csm
end

return RoundLifecycle
