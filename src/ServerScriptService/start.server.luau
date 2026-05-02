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
local CollisionResolverStub = require(ServerStorage.Source._PhaseStubs.CollisionResolverStub)
local RelicSystemStub = require(ServerStorage.Source._PhaseStubs.RelicSystemStub)
local AbsorbSystemStub = require(ServerStorage.Source._PhaseStubs.AbsorbSystemStub)
local ChestSystemStub = require(ServerStorage.Source._PhaseStubs.ChestSystemStub)
local CSMStateEvaluateStub = require(ServerStorage.Source._PhaseStubs.CSMStateEvaluateStub)
local MSMTimerCheckStub = require(ServerStorage.Source._PhaseStubs.MSMTimerCheckStub)
local MSMEliminationConsumerStub = require(ServerStorage.Source._PhaseStubs.MSMEliminationConsumerStub)
local CSMBroadcastAllStub = require(ServerStorage.Source._PhaseStubs.CSMBroadcastAllStub)
local PeelDispatcherStub = require(ServerStorage.Source._PhaseStubs.PeelDispatcherStub)

TickOrchestrator._registerPhases({
	{ phase = 1, name = "Collision",     callback = CollisionResolverStub.tick },
	{ phase = 2, name = "Relic",         callback = RelicSystemStub.tick },
	{ phase = 3, name = "Absorb",        callback = AbsorbSystemStub.tick },
	{ phase = 4, name = "Chest",         callback = ChestSystemStub.tick },
	{ phase = 5, name = "CSM:Eval",      callback = CSMStateEvaluateStub.tick },
	{ phase = 6, name = "MSM:Timer",     callback = MSMTimerCheckStub.tick },
	{ phase = 7, name = "MSM:Elim",      callback = MSMEliminationConsumerStub.tick },
	{ phase = 8, name = "CSM:Cast",      callback = CSMBroadcastAllStub.tick },
	{ phase = 9, name = "PeelDispatch",  callback = PeelDispatcherStub.tick },
})

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
local MatchStateServerStub = require(ServerStorage.Source._PhaseStubs.MatchStateServerStub)

ShutdownCoordinator.register({
	tickOrchestrator = TickOrchestrator,
	matchStateServer = MatchStateServerStub,
})
-- ---------------------------------------------------------------------------

-- TODO: Initialize your global server-side gameplay systems here.
-- Example:
--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
--   MyGameplayServer.start()

local function onPlayerAdded(player: Player)
	if not PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.waitForDataLoadAsync(player)
	end

	PlayerObjectsContainer.registerPlayer(player)

	-- TODO: Initialize per-player server-side gameplay systems here.
	-- Example:
	--   local MyGameplayServer = require(ServerStorage.Source.MyGameplay.MyGameplayServer)
	--   MyGameplayServer.createPlayerData(player)

	FtueManagerServer.onPlayerAdded(player)
	CharacterSpawner.startRespawnLoop(player)
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
