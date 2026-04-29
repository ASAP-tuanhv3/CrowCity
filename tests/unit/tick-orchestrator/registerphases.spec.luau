--!strict

--[[
	registerphases.spec.luau — TickOrchestrator._registerPhases validation
	Implements: ADR-0002 §Validation Criteria AC-03 (9-entry assert fails loud)
	            ADR-0002 §Validation Criteria AC-04 (no public runtime registerPhase API)

	Tests happy path acceptance and every documented failure mode for
	_registerPhases(). Also asserts the absence of the public `registerPhase`
	method (no-underscore) per ADR-0002 §Architecture — static phase table only.
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

	describe("TickOrchestrator._registerPhases — happy path", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("9 valid phases ordered 1..9 succeeds", function()
			local ok = pcall(TickOrchestrator._registerPhases, validPhases())
			expect(ok).to.equal(true)
			expect(TickOrchestrator.getCurrentTick()).to.equal(0)
		end)

		it("9 phases in scrambled order succeeds (input-order doesn't matter)", function()
			local order = { 3, 1, 9, 2, 5, 4, 7, 8, 6 }
			local phases = {}
			for _, p in order do
				table.insert(phases, { phase = p, name = "P" .. p, callback = noop })
			end
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(true)
		end)
	end)

	describe("TickOrchestrator._registerPhases — failure modes", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("rejects #phases == 8 (one missing)", function()
			local phases = validPhases()
			table.remove(phases, 9)
			local ok, err = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
			expect(typeof(err)).to.equal("string")
		end)

		it("rejects #phases == 10 (extra entry)", function()
			local phases = validPhases()
			-- Insert a 10th entry; the duplicate phase value also triggers
			-- the duplicate-guard, but #phases == 10 assertion fires first.
			table.insert(phases, { phase = 5, name = "Dup", callback = noop })
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects phase value 0", function()
			local phases = validPhases()
			phases[1].phase = 0
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects phase value 10", function()
			local phases = validPhases()
			phases[1].phase = 10
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects two entries with same phase value", function()
			local phases = validPhases()
			phases[2].phase = 1  -- duplicate of phases[1].phase
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects empty name string", function()
			local phases = validPhases()
			phases[3].name = ""
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects nil callback", function()
			local phases = validPhases()
			phases[4].callback = nil :: any
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects non-function callback (number)", function()
			local phases = validPhases()
			phases[5].callback = 42 :: any
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects fractional phase value (5.5)", function()
			-- Impl-introduced guard: math.floor() integer check. Boundary value
			-- not enumerated in the original story QA test cases.
			local phases = validPhases()
			phases[1].phase = 5.5
			local ok = pcall(TickOrchestrator._registerPhases, phases)
			expect(ok).to.equal(false)
		end)

		it("rejects second _registerPhases call (boot-only invariant)", function()
			-- ADR-0002 §Architecture: "Static phase table — post-Acceptance phase
			-- insertion forbidden at runtime." A second call must fail loud.
			TickOrchestrator._registerPhases(validPhases())
			local ok = pcall(TickOrchestrator._registerPhases, validPhases())
			expect(ok).to.equal(false)
		end)
	end)

	describe("TickOrchestrator public API surface", function()
		beforeEach(function()
			TickOrchestrator._resetForTests()
		end)

		it("module exposes the five required public functions (AC-01, AC-02)", function()
			-- AC-01 + AC-02 + QA TC 1: explicit surface-shape contract.
			expect(typeof(TickOrchestrator.start)).to.equal("function")
			expect(typeof(TickOrchestrator.stop)).to.equal("function")
			expect(typeof(TickOrchestrator.getCurrentTick)).to.equal("function")
			expect(typeof(TickOrchestrator.setTickDelegate)).to.equal("function")
			expect(typeof(TickOrchestrator._registerPhases)).to.equal("function")
		end)

		it("registerPhase (no underscore) is nil — no public runtime registration", function()
			-- AC-04: only _registerPhases exists; a runtime-accessible registerPhase
			-- without the underscore must NOT be present. ADR-0002 §Architecture:
			-- "Static phase table — post-Acceptance phase insertion forbidden at runtime."
			expect((TickOrchestrator :: any).registerPhase).to.equal(nil)
		end)
	end)
end
