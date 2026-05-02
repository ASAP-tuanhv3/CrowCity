--!strict

--[[
	ShutdownCoordinator — BindToClose chain owner
	Implements: ADR-0002 §Migration L4 + ADR-0005 §BindToClose ownership
	            + ADR-0011 §BindToClose 30 s grace + architecture.md §4.5
	Path: ServerStorage/Source/ShutdownCoordinator/init.luau

	Chain order (architecture.md §4.5 Scenario E):
	  1. TickOrchestrator.stop()                — halt all gameplay-tick work
	  2. MatchStateServer.requestServerClosing()— broadcast MatchStateChanged("ServerClosing")
	  3. ProfileStore session-release           — runs in ProfileStore's own
	                                              internal BindToClose handler
	                                              (vendored library; not invoked
	                                              from this module)

	NO currency grant during shutdown — manifest L106 + L142; ADR-0011.

	Public API:
	  ShutdownCoordinator.runShutdown(deps)  — execute chain (test + production entry)
	  ShutdownCoordinator.register(deps)     — wire game:BindToClose handler (idempotent)

	Test-only API (_-prefixed):
	  ShutdownCoordinator._resetForTests()         — zero module state
	  ShutdownCoordinator._isRegistered()          — register-flag visibility
	  ShutdownCoordinator._wasShutdownTriggered()  — runShutdown idempotence visibility
--]]

export type Deps = {
	tickOrchestrator: { stop: () -> () },
	matchStateServer: { requestServerClosing: () -> () },
}

local _bindToCloseRegistered: boolean = false
local _shutdownTriggered: boolean = false

local ShutdownCoordinator = {}

--- Runs the BindToClose chain synchronously.
--- Idempotent across calls in the same process. stop() failure halts the
--- chain (the broadcast is not attempted) per story-004 AC-2 policy.
--- Tests call this directly with mock deps; production calls via the
--- BindToClose handler registered by ShutdownCoordinator.register().
function ShutdownCoordinator.runShutdown(deps: Deps): ()
	-- Idempotent: a second invocation in the same process is a no-op.
	-- Real BindToClose fires once per shutdown — guard is defensive.
	if _shutdownTriggered then
		return
	end
	_shutdownTriggered = true

	print("[BindToClose] Server shutdown initiated")

	-- Step 1: halt gameplay tick. pcall isolates a faulty stop()
	-- implementation so the warn surfaces in the server log; chain
	-- aborts because the broadcast invariant requires a halted tick.
	local stopOk, stopErr = pcall(deps.tickOrchestrator.stop)
	if not stopOk then
		warn(
			"[BindToClose] TickOrchestrator.stop() failed: "
				.. tostring(stopErr)
				.. " — halting shutdown chain (no MSM broadcast)"
		)
		return
	end

	-- Step 2: MSM broadcasts ServerClosing. Stub fires the reliable
	-- RemoteEvent until the MSM epic ships its real entry point.
	local broadcastOk, broadcastErr = pcall(deps.matchStateServer.requestServerClosing)
	if not broadcastOk then
		warn(
			"[BindToClose] MatchStateServer.requestServerClosing() failed: "
				.. tostring(broadcastErr)
		)
	end

	-- Step 3 (ProfileStore session-release) runs in ProfileStore's own
	-- BindToClose handler, registered internally by the vendored library.
	-- Not invoked here. Roblox runs all BindToClose callbacks concurrently
	-- and waits up to 30 s for each to return.
end

--- Registers a game:BindToClose handler that runs the shutdown chain.
--- Idempotent — defensive guard against the boot script running twice
--- in dev (Studio auto-reload). Real shutdown fires the registered
--- callback once per process.
function ShutdownCoordinator.register(deps: Deps): ()
	if _bindToCloseRegistered then
		return
	end
	_bindToCloseRegistered = true

	-- The callback is a thin trampoline. runShutdown's body owns the
	-- print + stop() + broadcast contract per story-004 AC-2.
	game:BindToClose(function()
		ShutdownCoordinator.runShutdown(deps)
	end)
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Resets module state for test isolation. Must run in beforeEach() for
--- every spec that exercises ShutdownCoordinator.
function ShutdownCoordinator._resetForTests(): ()
	_bindToCloseRegistered = false
	_shutdownTriggered = false
end

--- **TEST ONLY** — never call from production code.
--- Returns whether register() has wired a game:BindToClose handler.
function ShutdownCoordinator._isRegistered(): boolean
	return _bindToCloseRegistered
end

--- **TEST ONLY** — never call from production code.
--- Returns whether runShutdown() has executed (used to verify idempotence
--- and post-stop dispatch invariants).
function ShutdownCoordinator._wasShutdownTriggered(): boolean
	return _shutdownTriggered
end

return ShutdownCoordinator
