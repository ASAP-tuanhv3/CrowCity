--!strict

--[[
	bindtoclose_shutdown.spec.luau — TickOrchestrator BindToClose chain
	Implements: story-004 ACs (chain order, no-phase-post-stop, 5 s budget,
	            idempotence, single MatchStateChanged broadcast)

	Coverage:
	  AC: chain order — stop() before MSM requestServerClosing
	  AC: stop() failure halts chain (no MSM broadcast)
	  AC: callback completes within 5 s (typical < 100 ms)
	  AC: runShutdown idempotent — second call is no-op
	  AC: register idempotent — _isRegistered flag set once
	  AC: no phase dispatch after stop() runs
	  AC: MatchStateServerStub fires MatchStateChanged("ServerClosing") once

	Note: AC-7 (client-side recorder) is not testable headless without
	connected players. Verified instead via stub's _invocationCount +
	_lastBroadcastState test hooks. Wire-level transmission is a Roblox
	engine guarantee.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)
	local ShutdownCoordinator = require(ServerStorage.Source.ShutdownCoordinator)
	local MatchStateServerStub = require(ServerStorage.Source._PhaseStubs.MatchStateServerStub)

	describe("ShutdownCoordinator runShutdown — chain order", function()
		beforeEach(function()
			ShutdownCoordinator._resetForTests()
			MatchStateServerStub._resetForTests()
		end)

		it("invokes stop() before MSM requestServerClosing", function()
			local order: { string } = {}
			local mockTick = {
				stop = function()
					table.insert(order, "stop")
				end,
			}
			local mockMsm = {
				requestServerClosing = function()
					table.insert(order, "msm")
				end,
			}

			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})

			expect(#order).to.equal(2)
			expect(order[1]).to.equal("stop")
			expect(order[2]).to.equal("msm")
		end)

		it("halts chain when stop() raises — MSM broadcast NOT invoked", function()
			local msmCalls = 0
			local mockTick = {
				stop = function()
					error("simulated stop failure")
				end,
			}
			local mockMsm = {
				requestServerClosing = function()
					msmCalls += 1
				end,
			}

			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})

			expect(msmCalls).to.equal(0)
			expect(ShutdownCoordinator._wasShutdownTriggered()).to.equal(true)
		end)

		it("isolates MSM broadcast failure — chain still records triggered", function()
			local stopCalls = 0
			local mockTick = {
				stop = function()
					stopCalls += 1
				end,
			}
			local mockMsm = {
				requestServerClosing = function()
					error("simulated broadcast failure")
				end,
			}

			-- pcall around runShutdown — broadcast pcall already swallows
			-- the error, but we wrap defensively to assert no unhandled.
			local ok = pcall(ShutdownCoordinator.runShutdown, {
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})

			expect(ok).to.equal(true)
			expect(stopCalls).to.equal(1)
			expect(ShutdownCoordinator._wasShutdownTriggered()).to.equal(true)
		end)
	end)

	describe("ShutdownCoordinator runShutdown — performance + idempotence", function()
		beforeEach(function()
			ShutdownCoordinator._resetForTests()
		end)

		it("completes within 5 s on the happy path (typical < 100 ms)", function()
			local mockTick = { stop = function() end }
			local mockMsm = { requestServerClosing = function() end }

			local t0 = os.clock()
			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})
			local elapsed = os.clock() - t0

			expect(elapsed < 5).to.equal(true)
			expect(elapsed < 0.1).to.equal(true)
		end)

		it("second runShutdown invocation is a no-op", function()
			local stopCalls = 0
			local msmCalls = 0
			local mockTick = {
				stop = function()
					stopCalls += 1
				end,
			}
			local mockMsm = {
				requestServerClosing = function()
					msmCalls += 1
				end,
			}

			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})
			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})

			expect(stopCalls).to.equal(1)
			expect(msmCalls).to.equal(1)
		end)
	end)

	describe("ShutdownCoordinator register — idempotence guard", function()
		beforeEach(function()
			ShutdownCoordinator._resetForTests()
		end)

		it("first register sets _isRegistered true; second is no-op", function()
			local mockTick = { stop = function() end }
			local mockMsm = { requestServerClosing = function() end }

			expect(ShutdownCoordinator._isRegistered()).to.equal(false)

			ShutdownCoordinator.register({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})
			expect(ShutdownCoordinator._isRegistered()).to.equal(true)

			-- Second call exits early at the flag check; engine BindToClose
			-- registration is internal — flag check is the testable contract.
			ShutdownCoordinator.register({
				tickOrchestrator = mockTick,
				matchStateServer = mockMsm,
			})
			expect(ShutdownCoordinator._isRegistered()).to.equal(true)
		end)
	end)

	describe("BindToClose chain — no phase dispatch post-stop", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
			ShutdownCoordinator._resetForTests()
		end)

		afterEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("Heartbeat-driven phases stop firing after runShutdown halts tick", function()
			local recorder = 0
			local phases: { TickOrchestrator.TickPhase } = {}
			for i = 1, 9 do
				table.insert(phases, {
					phase = i,
					name = "Phase" .. tostring(i),
					callback = function(_, _)
						recorder += 1
					end,
				})
			end

			TickOrchestrator._registerPhases(phases)
			TickOrchestrator.start()

			-- ~5-6 ticks fire (15 Hz × 0.4 s = 6 ticks × 9 callbacks).
			task.wait(0.4)
			local preStopCount = recorder
			expect(preStopCount > 0).to.equal(true)

			-- runShutdown stops the orchestrator. Heartbeat connection
			-- disconnected; subsequent Heartbeat events cannot drive _tick.
			local mockMsm = { requestServerClosing = function() end }
			ShutdownCoordinator.runShutdown({
				tickOrchestrator = TickOrchestrator,
				matchStateServer = mockMsm,
			})

			-- Allow real Heartbeat to fire many times — recorder stays put.
			task.wait(0.4)
			expect(recorder).to.equal(preStopCount)
			expect(TickOrchestrator._getHeartbeatConnection()).to.equal(nil)
		end)
	end)

	describe("MatchStateServerStub.requestServerClosing", function()
		beforeEach(function()
			MatchStateServerStub._resetForTests()
		end)

		it("records exactly one invocation per call with state ServerClosing", function()
			expect(MatchStateServerStub._getInvocationCount()).to.equal(0)
			expect(MatchStateServerStub._getLastBroadcastState()).to.equal(nil)

			MatchStateServerStub.requestServerClosing()

			expect(MatchStateServerStub._getInvocationCount()).to.equal(1)
			expect(MatchStateServerStub._getLastBroadcastState()).to.equal("ServerClosing")
		end)

		it("invocation count increments per call", function()
			MatchStateServerStub.requestServerClosing()
			MatchStateServerStub.requestServerClosing()
			MatchStateServerStub.requestServerClosing()
			expect(MatchStateServerStub._getInvocationCount()).to.equal(3)
		end)
	end)

	describe("Integration — ShutdownCoordinator + real stub fire MatchStateChanged", function()
		beforeEach(function()
			ShutdownCoordinator._resetForTests()
			MatchStateServerStub._resetForTests()
		end)

		it("runShutdown with the real MSM stub drives one ServerClosing broadcast", function()
			local mockTick = { stop = function() end }

			ShutdownCoordinator.runShutdown({
				tickOrchestrator = mockTick,
				matchStateServer = MatchStateServerStub,
			})

			expect(MatchStateServerStub._getInvocationCount()).to.equal(1)
			expect(MatchStateServerStub._getLastBroadcastState()).to.equal("ServerClosing")
		end)
	end)
end
