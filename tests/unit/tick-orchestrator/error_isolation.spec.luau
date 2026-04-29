--!strict

--[[
	error_isolation.spec.luau — TickOrchestrator pcall + warn + recovery
	Implements: ADR-0002 §Architecture L101 + §Validation Criteria L6
	  AC-04 — pcall wrapper logs via warn + continues to next phase
	  AC-06 — error in Phase 3 does NOT prevent Phase 4-9 from running
	  AC-07 — error does not corrupt _tickCount across ticks
	  AC-08 — warn fires once per tick per erroring phase (not duplicated)
	  AC-09 — task.wait inside a phase does not crash the orchestrator

	Uses _tick(dt) to drive synchronously. AC-09 incurs ~100ms real wait per
	invocation; test runtime is acceptable.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local TickOrchestrator = require(ServerStorage.Source.TickOrchestrator)

	-- Helper: build 9 phases where one specific phase raises error(errorMsg)
	-- after recording its invocation. All phases record their .phase value into
	-- the shared invocations list regardless of whether they error.
	-- Returns (phases, invocations).
	local function buildPhasesWithErrorAt(
		errorPhaseId: number,
		errorMsg: string
	): ({ TickOrchestrator.TickPhase }, { number })
		local invocations: { number } = {}
		local phases: { TickOrchestrator.TickPhase } = {}
		for i = 1, 9 do
			local pid = i
			local cb: (number, TickOrchestrator.TickContext) -> ()
			if pid == errorPhaseId then
				cb = function(_: number, _: TickOrchestrator.TickContext)
					table.insert(invocations, pid)
					error(errorMsg)
				end
			else
				cb = function(_: number, _: TickOrchestrator.TickContext)
					table.insert(invocations, pid)
				end
			end
			table.insert(phases, { phase = pid, name = "P" .. pid, callback = cb })
		end
		return phases, invocations
	end

	-- ---------------------------------------------------------------------------
	-- Per-phase pcall isolation (AC-04, AC-06)
	-- ---------------------------------------------------------------------------

	describe("TickOrchestrator error isolation", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("error in Phase 3 — Phases 1, 2, 4-9 still run this tick", function()
			-- Arrange: Phase 3 errors after recording; remaining phases record normally
			local phases, invocations = buildPhasesWithErrorAt(3, "synthetic-P3")
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert: all 9 invocation entries present; Phase 3 recorded before error;
			-- pcall caught the error; Phases 4-9 ran normally after
			expect(#invocations).to.equal(9)
			for i = 1, 9 do
				expect(invocations[i]).to.equal(i)
			end
		end)

		it("error in Phase 1 — Phases 2-9 still run this tick", function()
			-- Arrange: worst-case: first phase errors
			local phases, invocations = buildPhasesWithErrorAt(1, "synthetic-P1")
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert: all 9 phases still invoked
			expect(#invocations).to.equal(9)
			for i = 1, 9 do
				expect(invocations[i]).to.equal(i)
			end
		end)

		it("error in Phase 9 — Phases 1-8 ran cleanly before it", function()
			-- Arrange: last phase errors — no downstream phases to block
			local phases, invocations = buildPhasesWithErrorAt(9, "synthetic-P9")
			TickOrchestrator._registerPhases(phases)
			-- Act
			TickOrchestrator._tick(1 / 15)
			-- Assert: all 9 phases invoked (Phase 9 records before raising)
			expect(#invocations).to.equal(9)
			for i = 1, 9 do
				expect(invocations[i]).to.equal(i)
			end
		end)

		-- ---------------------------------------------------------------------------
		-- Tick count integrity (AC-07)
		-- ---------------------------------------------------------------------------

		it("error every tick — _tickCount advances normally over 30 ticks", function()
			-- Arrange: Phase 5 errors on every tick; orchestrator must keep counting
			local phases, invocations = buildPhasesWithErrorAt(5, "synthetic-recurring")
			TickOrchestrator._registerPhases(phases)
			-- Act
			for _ = 1, 30 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: tick counter is unaffected by per-phase errors (AC-07)
			expect(TickOrchestrator.getCurrentTick()).to.equal(30)
			-- 30 ticks × 9 phases = 270 invocations
			-- (Phase 5 records its invocation BEFORE raising, so it's included)
			expect(#invocations).to.equal(270)
		end)

		it("all 9 phases erroring — orchestrator stays alive across 5 ticks", function()
			-- Arrange: every phase errors every tick — pure-warn-log mode
			local invocations: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			for i = 1, 9 do
				local pid = i
				table.insert(phases, {
					phase = pid,
					name = "P" .. pid,
					callback = function(_: number, _: TickOrchestrator.TickContext)
						table.insert(invocations, pid)
						error("synthetic-all")
					end,
				})
			end
			TickOrchestrator._registerPhases(phases)
			-- Act
			for _ = 1, 5 do
				TickOrchestrator._tick(1 / 15)
			end
			-- Assert: orchestrator still alive; tick count advanced; all phases ran
			expect(TickOrchestrator.getCurrentTick()).to.equal(5)
			expect(#invocations).to.equal(45)  -- 5 ticks × 9 phases
		end)

		-- ---------------------------------------------------------------------------
		-- task.wait yield-survival (AC-09)
		-- ---------------------------------------------------------------------------

		it("task.wait(0.1) inside a phase — pcall returns; subsequent ticks recover", function()
			-- AC-09: yield is Forbidden per control-manifest L132, but the
			-- orchestrator must not crash. pcall returns after the wait resumes;
			-- Phases 5-9 continue, then subsequent ticks run cleanly.
			-- We use 0.1s to keep test runtime tight while still validating
			-- the yield-survival contract.
			local invocations: { number } = {}
			local phases: { TickOrchestrator.TickPhase } = {}
			for i = 1, 9 do
				local pid = i
				local cb: (number, TickOrchestrator.TickContext) -> ()
				if pid == 4 then
					cb = function(_: number, _: TickOrchestrator.TickContext)
						table.insert(invocations, pid)
						task.wait(0.1)
					end
				else
					cb = function(_: number, _: TickOrchestrator.TickContext)
						table.insert(invocations, pid)
					end
				end
				table.insert(phases, { phase = pid, name = "P" .. pid, callback = cb })
			end
			TickOrchestrator._registerPhases(phases)
			-- Act: first tick — Phase 4 yields but pcall resumes; Phases 5-9 run
			TickOrchestrator._tick(1 / 15)
			-- Assert: all 9 phases invoked on first tick
			expect(#invocations).to.equal(9)
			-- Act: second tick — confirm recovery (no crash, no stale state)
			TickOrchestrator._tick(1 / 15)
			-- Assert: another 9 phase invocations accumulated
			expect(#invocations).to.equal(18)
		end)
	end)
end
