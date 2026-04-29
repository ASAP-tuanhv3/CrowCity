--!strict

--[[
	lifecycle.spec.luau — TickOrchestrator start/stop/idempotence
	Implements: ADR-0002 §Validation Criteria
	  AC-06 — start() idempotent (same connection on double-start)
	  AC-07 — start() fails loud without _registerPhases
	  AC-10 — stop() → start() re-creates a new connection
	  AC-11 — stop() with no prior start() / double stop() are no-ops
	  AC-12 — stop() resets _accumulator to 0; preserves _tickCount

	Uses _tick(dt) directly for tick accumulation; does not require a live
	Heartbeat signal. Every test calls _resetForTests() in beforeEach.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)

	local function noop() end

	local function validPhases(): { TickOrchestrator.TickPhase }
		local phases = {}
		for i = 1, 9 do
			table.insert(phases, { phase = i, name = "Phase" .. i, callback = noop })
		end
		return phases
	end

	describe("TickOrchestrator start/stop lifecycle", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("start() requires _registerPhases first — fails loud", function()
			-- AC-07: assert fires if _phases is empty at start() time.
			local ok = pcall(TickOrchestrator.start)
			expect(ok).to.equal(false)
		end)

		it("start() succeeds after _registerPhases with valid table", function()
			TickOrchestrator._registerPhases(validPhases())
			local ok = pcall(TickOrchestrator.start)
			expect(ok).to.equal(true)
			expect(TickOrchestrator._getHeartbeatConnection()).to.be.ok()
			TickOrchestrator.stop()
		end)

		it("start() is idempotent — second call without stop() reuses the same connection", function()
			-- AC-06: no new connection created on double-start.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.start()
			local conn1 = TickOrchestrator._getHeartbeatConnection()
			TickOrchestrator.start()  -- no-op
			local conn2 = TickOrchestrator._getHeartbeatConnection()
			expect(conn1).to.equal(conn2)  -- identity preserved
			TickOrchestrator.stop()
		end)

		it("start() → stop() → start() re-creates a new connection", function()
			-- AC-10: stop() clears the connection; next start() creates a fresh one.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.start()
			local conn1 = TickOrchestrator._getHeartbeatConnection()
			TickOrchestrator.stop()
			TickOrchestrator.start()
			local conn2 = TickOrchestrator._getHeartbeatConnection()
			expect(conn1).never.to.equal(conn2)
			TickOrchestrator.stop()
		end)

		it("stop() with no prior start() is a no-op (no error)", function()
			-- AC-11a: _heartbeatConnection is nil from the start; stop() must return
			-- cleanly without error.
			local ok = pcall(TickOrchestrator.stop)
			expect(ok).to.equal(true)
		end)

		it("double stop() is a no-op", function()
			-- AC-11b: second stop() after first has already nil'd the connection.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.start()
			TickOrchestrator.stop()
			local ok = pcall(TickOrchestrator.stop)
			expect(ok).to.equal(true)
		end)

		it("stop() clears _heartbeatConnection (structural ≤5 ms claim per ADR-0002)", function()
			-- ADR-0002 §Validation: "stop() halts within <5 ms of call;
			-- no further phase dispatches observed." The ≤5 ms claim is
			-- trivially satisfied by synchronous :Disconnect() and is asserted
			-- structurally (connection nil'd in same call) rather than by wall
			-- timing — wall timing is non-deterministic on loaded CI runners
			-- per coding-standards.md §Determinism.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.start()
			TickOrchestrator.stop()
			expect(TickOrchestrator._getHeartbeatConnection()).to.equal(nil)
		end)

		it("stop() preserves _tickCount (counter not reset)", function()
			-- AC-12a: _tickCount is a monotone counter; stop() must not zero it.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.setTickDelegate(noop)
			TickOrchestrator._tick(2 / 15)  -- 2 ticks accrue without start()
			expect(TickOrchestrator.getCurrentTick()).to.equal(2)
			TickOrchestrator.start()
			TickOrchestrator.stop()
			expect(TickOrchestrator.getCurrentTick()).to.equal(2)  -- preserved
		end)

		it("stop() resets _accumulator to 0", function()
			-- AC-12b: sub-tick residual must be cleared on stop() so the next
			-- start() cycle begins with a clean accumulator.
			TickOrchestrator._registerPhases(validPhases())
			TickOrchestrator.setTickDelegate(noop)
			TickOrchestrator._tick(1 / 30)  -- sub-tick — accumulator > 0
			expect(TickOrchestrator._getAccumulator() > 0).to.equal(true)
			TickOrchestrator.start()
			TickOrchestrator.stop()
			expect(TickOrchestrator._getAccumulator()).to.equal(0)
		end)

		it("getCurrentTick() returns 0 before any tick", function()
			expect(TickOrchestrator.getCurrentTick()).to.equal(0)
		end)

		it("setTickDelegate(nil) clears the hook", function()
			-- Verifies that clearing the delegate stops it from being invoked
			-- on subsequent _tick() calls.
			TickOrchestrator._registerPhases(validPhases())
			local fired = 0
			TickOrchestrator.setTickDelegate(function(_: number)
				fired += 1
			end)
			TickOrchestrator._tick(1 / 15)
			expect(fired).to.equal(1)
			TickOrchestrator.setTickDelegate(nil)
			TickOrchestrator._tick(1 / 15)
			expect(fired).to.equal(1)  -- unchanged after delegate cleared
		end)
	end)
end
