--!strict

--[[
	Server-side entry point. Initializes all server modules in the correct order.

	Boot sequence:
	  1. Start network and player data system
	  2. Register dev products (Robux purchases)
	  3. TODO: Start your global server-side gameplay systems here
	  4. Per PlayerAdded: load data, register objects, TODO start gameplay, spawn character
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Network)
local Market = require(ServerStorage.Source.Market)
local FtueManagerServer = require(ServerStorage.Source.FtueManagerServer)
local CharacterSpawner = require(ServerStorage.Source.CharacterSpawner)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local DefaultPlayerData = require(ServerStorage.Source.DefaultPlayerData)
local ReceiptProcessor = require(ServerStorage.Source.ReceiptProcessor)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local SoundManager = require(ReplicatedStorage.Source.SoundManager)
local safePlayerAdded = require(ReplicatedStorage.Source.Utility.safePlayerAdded)

print("To test, ensure this place is published and Enable Studio Access to API Services is enabled")

Network.startServer()
PlayerDataServer.start(DefaultPlayerData, "PlayerData_v2", { ReceiptProcessor.receiptHistoryValueName })

-- ---------------------------------------------------------------------------
-- TickOrchestrator boot wiring (ADR-0002 §Phase Registration L162-178)
--
-- Static 9-phase callback table wired here AFTER all module-level requires.
-- Each phase points to its owning module's `.tick(tickCount, ctx)` function.
-- Stubs (in _PhaseStubs/) hold each slot until the consuming epic ships its
-- real module. To replace a stub: edit the `callback = ...` field below and
-- swap the `require` at the top — phase number + name strings stay locked.
--
-- Phase order (NEVER reorder — ADR-0002 §Architecture lock):
--   1. Collision   → CollisionResolver.tick   [CCR epic]
--   2. Relic       → RelicSystem.tick         [relic-system epic]
--   3. Absorb      → AbsorbSystem.tick        [absorb-system epic]
--   4. Chest       → ChestSystem.tick         [chest-system epic]
--   5. CSM:Eval    → CrowdStateServer.stateEvaluate          [CSM epic]
--   6. MSM:Timer   → MatchStateServer.timerCheck             [MSM epic]
--   7. MSM:Elim    → MatchStateServer.eliminationConsumer    [MSM epic]
--   8. CSM:Cast    → CrowdStateServer.broadcastAll           [CSM epic]
--   9. PeelDispatch → PeelDispatcher.flush  [CCR epic — PeelDispatcher]
--
-- Stub status (2026-04-29): all 9 phases stubbed. Replace as epics land.
-- ---------------------------------------------------------------------------
local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)
-- CollisionResolverStub replaced by real CollisionResolver (CCR epic, Sprint 6 story 001).
-- CollisionResolverStub.luau retained (close-out story removes it).
local CollisionResolver = require(ServerStorage.Source.CollisionResolver)
local RelicSystemStub = require(ServerStorage.Source._PhaseStubs.RelicSystemStub)
-- AbsorbSystemStub replaced by real AbsorbSystem (absorb-system epic, Sprint 5 stories 5-10..5-14).
-- AbsorbSystemStub.luau retained (close-out Story 011 removes it).
local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)
local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)
local NPCSpawner = require(ServerStorage.Source.NPCSpawner)
local ChestSystemStub = require(ServerStorage.Source._PhaseStubs.ChestSystemStub)
-- MSMTimerCheckStub + MSMEliminationConsumerStub + MatchStateServerStub replaced by
-- real MatchStateServer (Sprint 6 task 6-2 — Lobby→Countdown→Active timer driver).
-- Stub modules retained in _PhaseStubs/ for close-out story removal.
local MatchStateServer = require(ServerStorage.Source.MatchStateServer)
local PeelDispatcherStub = require(ServerStorage.Source._PhaseStubs.PeelDispatcherStub)
-- CSMStateEvaluateStub + CSMBroadcastAllStub replaced by real CrowdStateServer.stateEvaluate
-- + CrowdStateServer.broadcastAll (Sprint 5 unblock — wired below).

-- Initialise CollisionResolver with production dependencies (DI per ADR-0006 + CCR Story 001).
-- Must be called before TickOrchestrator._registerPhases / .start().
-- ADR-0004: CollisionResolver is sole authorised caller of csm.getAllActive() in Phase 1.
-- peelDispatcher = PeelDispatcherStub until Story 008 wires the real PeelDispatcher.
CollisionResolver.init({
	csm = CrowdStateServer,
	peelDispatcher = PeelDispatcherStub,
})

-- Initialise AbsorbSystem with production dependencies (DI per ADR-0006 + Story 5-10).
-- Must be called before TickOrchestrator._registerPhases / .start().
-- ADR-0004: AbsorbSystem is sole authorised caller of csm.updateCount(crowdId, +1, "Absorb")
--           and npcSpawner.reclaim(npcId). (ADR-0008 §Caller Authority Matrix)
AbsorbSystem.init({
	csm = CrowdStateServer,
	npcSpawner = NPCSpawner,
	network = Network,
})

-- Story 7-1 (BUG-001 investigation): boot-time diagnostic toggle. Reads
-- `workspace:GetAttribute("AbsorbDiagnosticLogging")` once at server boot.
-- When true, AbsorbSystem.tick logs `[AbsorbSystem] tick N crowds=M npcs=K`
-- once/sec. Disabled in production (default attribute false/nil).
-- Set the attribute in Studio Explorer (workspace properties) before play
-- to surface BUG-001 root cause (silent no-op paths at AC-10/AC-11).
if workspace:GetAttribute("AbsorbDiagnosticLogging") == true then
	AbsorbSystem.setDiagnosticLogging(true)
	print("[start] AbsorbSystem diagnostic logging ENABLED via workspace attribute")
end

TickOrchestrator._registerPhases({
	{ phase = 1, name = "Collision",     callback = CollisionResolver.tickPhase1 },
	{ phase = 2, name = "Relic",         callback = RelicSystemStub.tick },
	{ phase = 3, name = "Absorb",        callback = AbsorbSystem.tick },
	{ phase = 4, name = "Chest",         callback = ChestSystemStub.tick },
	{ phase = 5, name = "CSM:Eval",      callback = CrowdStateServer.stateEvaluate },
	{ phase = 6, name = "MSM:Timer",     callback = MatchStateServer.timerCheck },
	{ phase = 7, name = "MSM:Elim",      callback = MatchStateServer.eliminationConsumer },
	{ phase = 8, name = "CSM:Cast",      callback = CrowdStateServer.broadcastAll },
	{ phase = 9, name = "PeelDispatch",  callback = PeelDispatcherStub.tick },
})

-- CSM Players.PlayerRemoving handler — destroys crowd record on disconnect.
-- Idempotent; safe to call once at boot. ADR-0004 §Write-Access Matrix.
CrowdStateServer.start()

-- MSM lifecycle wiring (Sprint 6 task 6-2): connects PlayerAdded/Removing for
-- participation tracking + subscribes to CSM CrowdEliminatedServer for Phase 7
-- elim consumer. Idempotent. ADR-0005 §Decision T1 driver entry.
MatchStateServer.start()

-- ADR-0002 §Phase Registration L162-178: start() must follow _registerPhases.
TickOrchestrator.start()
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- BindToClose shutdown coordination (architecture.md §4.5 Scenario E)
--
-- ADR-0002 §Migration L4 + ADR-0005 §BindToClose ownership + ADR-0011 §Grace.
-- Chain order at server shutdown:
--   1. TickOrchestrator.stop()                — halt gameplay tick
--   2. MatchStateServer.requestServerClosing()— broadcast MatchStateChanged
--   3. ProfileStore session-release           — runs in ProfileStore's own
--                                               internal BindToClose handler
--                                               (vendored library; not invoked
--                                               from this script).
--
-- NO currency grant during shutdown — manifest L106 + L142; ADR-0011.
-- MSM epic replaces MatchStateServerStub with the real MatchStateServer
-- module via in-place edit of the require + register({...}) deps below.
-- ---------------------------------------------------------------------------
local ShutdownCoordinator = require(ServerStorage.Source.ShutdownCoordinator)

ShutdownCoordinator.register({
	tickOrchestrator = TickOrchestrator,
	matchStateServer = MatchStateServer,
})
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Sprint 5 gameplay boot wiring
--
-- NPCSpawner.init() — pre-allocates 300-Part neutral pool. ARENA_WALKABLE_AREA_SQ
-- workspace attribute MUST be set before this runs (asserted at init).
-- Default = 40000 studs² (200×200 ARENA) if attribute absent (dev convenience).
-- ---------------------------------------------------------------------------
do
	local arenaArea = workspace:GetAttribute("ArenaWalkableAreaSq")
	if typeof(arenaArea) ~= "number" or arenaArea <= 0 then
		warn("[start] ArenaWalkableAreaSq attribute missing — defaulting to 40000 (200×200 ARENA)")
		workspace:SetAttribute("ArenaWalkableAreaSq", 40000)
	end
	NPCSpawner.init({})
end

-- ---------------------------------------------------------------------------
-- NPCSpawner round-lifecycle subscription (Sprint 6 task 6-2).
-- MSM owns Lobby→Countdown→Active timing. NPCSpawner.createAll/destroyAll
-- are not in MSM's scope (NPCSpawner per ADR-0008 is Feature-layer; MSM per
-- ADR-0005 is Core-layer). Direct MSM→NPCSpawner import would violate the
-- Core→Feature layer direction per control-manifest §Layer hierarchy. Bridge
-- them here via the server-only MatchStateChangedServer BindableEvent.
--
--   Active (T4)   → NPCSpawner.createAll(participants)  — activate 300-Part pool
--   Intermission  → NPCSpawner.destroyAll()             — park pool at Y=-10000
--
-- ADR-0008 §Caller Authority Matrix names "RoundLifecycle (T4)" as sole
-- caller of NPCSpawner.createAll. This bridge is a de-facto deviation; ADR-0008
-- amendment pending to recognise the boot-script bridge as the authorised
-- caller given the Core→Feature import restriction.
--
-- Dispatch is DEFERRED per Roblox BindableEvent contract: this handler does
-- NOT run synchronously with MSM's `_transitionTo("Active", ...)` call inside
-- `timerCheck`. RoundLifecycle.createAll(participants) (called inside
-- timerCheck at T4) and NPCSpawner.createAll(participants) (called from this
-- handler) execute in different resumption contexts. Participant list is
-- re-resolved here via Players:GetPlayers() + getParticipation filter; this
-- list MUST remain semantically equivalent to MSM's internal
-- `_participatingPlayers()` (both filter via Players:GetPlayerByUserId so
-- a player who disconnects mid-gap is excluded from both — equivalent today;
-- maintenance coupling point if MSM's participation model changes).
--
-- The `_npcSpawnerActive` guard prevents double-create on re-entry (idempotency
-- against Active→Active no-op transitions, which shouldn't happen in MSM but
-- defensive given ADR-0005 contract is enforced elsewhere).
-- ---------------------------------------------------------------------------
local _npcSpawnerActive = false

MatchStateServer.MatchStateChangedServer.Event:Connect(function(newState: string, _endsAt: number?)
	if newState == "Active" and not _npcSpawnerActive then
		-- MSM at T4 already called RoundLifecycle.createAll(participants); resolve
		-- the same participant list via MSM read API to keep the two calls in sync.
		-- _participatingPlayers is module-private; use MSM.getParticipation iteration
		-- via Players:GetPlayers + filter (MSM has set participation flags by Snap).
		local participants: { Player } = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if MatchStateServer.getParticipation(plr) then
				table.insert(participants, plr)
			end
		end
		local ok, err = pcall(NPCSpawner.createAll, participants)
		if not ok then
			warn("[start] NPCSpawner.createAll failed on T4:", err)
			return
		end
		_npcSpawnerActive = true
		print("[start] T4 — NPCSpawner activated for", #participants, "participants")
	elseif newState == "Intermission" and _npcSpawnerActive then
		-- Reset guard BEFORE pcall so a destroyAll failure does not leave the
		-- bridge stuck — next round's Active transition can retry createAll.
		_npcSpawnerActive = false
		local ok, err = pcall(NPCSpawner.destroyAll)
		if not ok then
			warn("[start] NPCSpawner.destroyAll failed on Intermission:", err)
			return
		end
		print("[start] Intermission — NPCSpawner parked")
	end
end)

local function onPlayerAdded(player: Player)
	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	PlayerObjectsContainer.registerPlayer(player)

	FtueManagerServer.onPlayerAdded(player)
	CharacterSpawner.startRespawnLoop(player)

	-- MSM.start() (called above) wires PlayerAdded for participation tracking.
	-- This handler covers the per-player template concerns (data load + character
	-- spawn loop + FTUE). MSM's Lobby→Countdown→Active driver fires when the
	-- MIN_PLAYERS_TO_START threshold (ADR-0005 = 2) is met. Solo Studio playtest
	-- requires opening 2 clients via Test → Local Server.
end

safePlayerAdded(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player)
	CharacterSpawner.stopRespawnLoop(player)

	-- TODO: Clean up per-player server-side gameplay systems here.
	-- Example:
	--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
	--   MyGameplayServer.destroyPlayerData(player)

	PlayerObjectsContainer.unregisterPlayer(player)
	PlayerDataServer.onPlayerRemovingAsync(player)
end)

Market.start()
SoundManager:SetUp()

-- Studio-only: allows a developer to wipe and reset their own data for testing
Network.connectEvent(Network.RemoteEvents.ResetData, function(player: Player)
	local character = player.Character
	if not character then
		return
	end

	CharacterSpawner.stopRespawnLoop(player)
	player.Character = nil;
	(character :: Model):Destroy()

	PlayerObjectsContainer.unregisterPlayer(player)

	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	for _, key in pairs(PlayerDataKey) do
		PlayerDataServer.setValue(player, key, DefaultPlayerData[key])
	end

	onPlayerAdded(player)
end, Network.t.instanceOf("Player"))
