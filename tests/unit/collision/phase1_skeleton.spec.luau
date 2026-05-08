--!strict

--[[
	CollisionResolver Phase 1 callback skeleton — unit tests.
	Path: tests/unit/collision/phase1_skeleton.spec.luau

	Implements Story 001 (CCR) QA test cases:
	  AC-01 — Tick cadence: tickPhase1 invocable via TickOrchestrator phase contract;
	           multiple sequential calls do not error; signature accepts (tickCount, ctx);
	           no own Heartbeat connection registered.
	  AC-02 — Dormant no-op: getAllActive returns {} → state stays Dormant;
	           nil return treated as empty (no crash); state transitions correct.
	  DI    — Missing csm raises at init time with "csm" in message.
	  DI    — Missing peelDispatcher raises at init time with "peelDispatcher" in message.
	  DI    — clock is OPTIONAL (init succeeds without it).
	  DI    — Re-init with same deps is idempotent (no double-assert).
	  DI    — tick before init raises with "init" in message.
	  State — Start state == "Dormant" before any tick.
	  State — After tick with empty getAllActive, state == "Dormant".
	  State — After tick with non-empty getAllActive, state == "Ticking".
	  State — After subsequent tick with empty getAllActive, state back to "Dormant".

	Test isolation:
	  CollisionResolver._resetForTests() in afterEach.
	  All deps injected via mocks — no real CSM or PeelDispatcher required.

	Test naming: it("AC-NN — description", ...) per project convention
	(mirrors tests/unit/absorb/phase3_callback_skeleton.spec.luau).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CollisionResolver = require(ServerStorage.Source.CollisionResolver)

	-- -------------------------------------------------------------------------
	-- Spy factory
	-- -------------------------------------------------------------------------

	local function spy()
		local calls: { { n: number, [number]: any } } = {}
		local self: any = {
			calls = calls,
			callCount = function(): number
				return #calls
			end,
			getCall = function(i: number): { n: number, [number]: any }
				return calls[i]
			end,
		}
		setmetatable(self, {
			__call = function(_self: any, ...): ()
				table.insert(calls, table.pack(...))
			end,
		})
		return self
	end

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	--- Builds a mock CSM with a configurable getAllActive return value.
	local function buildMockCsm(crowds: { any }?): any
		local getAllActiveSpy = spy()
		return {
			getAllActive = function(): { any }
				getAllActiveSpy()
				return crowds or {}
			end,
			_getAllActiveSpy = getAllActiveSpy,
		}
	end

	--- Builds a mock PeelDispatcher (no-op for Story 001; Story 008+ exercises it).
	local function buildMockPeelDispatcher(): any
		return {
			dispatch = spy(),
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CollisionResolver Phase 1 callback skeleton", function()
		afterEach(function()
			CollisionResolver._resetForTests()
		end)

		-- -----------------------------------------------------------------------
		-- AC-01: Tick cadence
		-- -----------------------------------------------------------------------

		-- AC-01: init does not register its own Heartbeat:Connect.
		-- CollisionResolver must not touch RunService.Heartbeat at all —
		-- TickOrchestrator is the sole accumulator (ADR-0002).
		it("AC-01 — init does not register own Heartbeat:Connect", function()
			-- Arrange: spy to detect any Heartbeat:Connect invocations
			local heartbeatConnectCount = 0
			local mockRunService = {
				Heartbeat = {
					Connect = function(_self: any, _cb: any): any
						heartbeatConnectCount += 1
						return { Disconnect = function() end }
					end,
				},
			}
			-- CollisionResolver does not accept runService as a dep — it must NOT
			-- reach RunService at all. Referenced here to make the intent explicit.
			local _ = mockRunService

			local mockCsm = buildMockCsm({})
			local mockPeel = buildMockPeelDispatcher()

			-- Act: init + tick cycle
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })
			CollisionResolver.tickPhase1(1, {})

			-- Assert: zero Heartbeat connections registered through CollisionResolver
			expect(heartbeatConnectCount).to.equal(0)
		end)

		-- AC-01: tickPhase1 is callable and does not error on multiple calls.
		it("AC-01 — tickPhase1 callable via direct invocation, multiple calls no-error", function()
			-- Arrange
			local mockCsm = buildMockCsm({})
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act + Assert: sequential calls must not throw
			local ok = pcall(function()
				CollisionResolver.tickPhase1(1, {})
				CollisionResolver.tickPhase1(2, {})
				CollisionResolver.tickPhase1(100, {})
			end)
			expect(ok).to.equal(true)
		end)

		-- AC-01: tickPhase1 signature accepts (tickCount: number, ctx: any).
		-- Mirrors the TickOrchestrator TickPhase contract (ADR-0002).
		it("AC-01 — tickPhase1 signature accepts (tickCount, ctx) per TickOrchestrator contract", function()
			-- Arrange
			local mockCsm = buildMockCsm({})
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act: call with a realistic TickContext table
			local ctx = { tickCount = 5, outPairs = {}, outPeel = {} }
			local ok = pcall(function()
				CollisionResolver.tickPhase1(5, ctx)
			end)

			-- Assert: no error; both args consumed without crash
			expect(ok).to.equal(true)
		end)

		-- -----------------------------------------------------------------------
		-- AC-02: Dormant no-op
		-- -----------------------------------------------------------------------

		-- AC-02: getAllActive returns {} → state stays Dormant; no downstream calls fire.
		it("AC-02 — zero crowds: state stays Dormant, no downstream calls", function()
			-- Arrange
			local mockCsm = buildMockCsm({})  -- empty crowd list
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act
			CollisionResolver.tickPhase1(1, {})

			-- Assert: state is Dormant; getAllActive read once (early-return-read contract);
			-- no peel dispatch calls. The getAllActive assertion locks the spec's
			-- "early-return read" intent before Story 002 — prevents a future refactor
			-- from skipping the read entirely on a Dormant tick.
			expect(CollisionResolver.getState()).to.equal("Dormant")
			expect(mockCsm._getAllActiveSpy.callCount()).to.equal(1)
			expect((mockPeel.dispatch :: any).callCount()).to.equal(0)
		end)

		-- AC-02 edge: nil return from getAllActive treated as empty (no crash).
		it("AC-02 edge — nil getAllActive return treated as empty, no crash", function()
			-- Arrange: CSM returns nil
			local mockCsm: any = {
				getAllActive = function(): any
					return nil
				end,
			}
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act + Assert: nil return must not crash
			local ok = pcall(function()
				CollisionResolver.tickPhase1(1, {})
			end)
			expect(ok).to.equal(true)
			expect(CollisionResolver.getState()).to.equal("Dormant")
		end)

		-- AC-02: state transitions — Dormant → Ticking → Dormant.
		it("AC-02 — state transitions: Dormant → Ticking → Dormant on getAllActive changes", function()
			-- Arrange: configurable crowd list (swapped between ticks)
			local crowdList: { any } = {}
			local mockCsm: any = {
				getAllActive = function(): { any }
					return crowdList
				end,
			}
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Start state: Dormant (before any tick)
			expect(CollisionResolver.getState()).to.equal("Dormant")

			-- Tick 1: empty crowds → Dormant
			CollisionResolver.tickPhase1(1, {})
			expect(CollisionResolver.getState()).to.equal("Dormant")

			-- Tick 2: add a crowd → Ticking
			table.insert(crowdList, {
				crowdId = "crowd-A",
				position = Vector3.new(0, 0, 0),
				radius = 10,
				state = "Active",
			})
			CollisionResolver.tickPhase1(2, {})
			expect(CollisionResolver.getState()).to.equal("Ticking")

			-- Tick 3: remove crowd → back to Dormant
			table.clear(crowdList)
			CollisionResolver.tickPhase1(3, {})
			expect(CollisionResolver.getState()).to.equal("Dormant")
		end)

		-- -----------------------------------------------------------------------
		-- DI scaffold
		-- -----------------------------------------------------------------------

		-- DI: missing csm raises at init time with "csm" in message.
		it("DI — missing csm raises at init, message contains 'csm'", function()
			-- Arrange + Act
			local ok, err = pcall(function()
				CollisionResolver.init({
					csm = nil,
					peelDispatcher = buildMockPeelDispatcher(),
				} :: any)
			end)

			-- Assert: error at init; message references csm
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "csm")).to.be.ok()
		end)

		-- DI: missing peelDispatcher raises at init time with "peelDispatcher" in message.
		it("DI — missing peelDispatcher raises at init, message contains 'peelDispatcher'", function()
			-- Arrange + Act
			local ok, err = pcall(function()
				CollisionResolver.init({
					csm = buildMockCsm(),
					peelDispatcher = nil,
				} :: any)
			end)

			-- Assert: error at init; message references peelDispatcher
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "peelDispatcher")).to.be.ok()
		end)

		-- DI: clock is OPTIONAL — init succeeds without it.
		it("DI — clock is optional: init succeeds without clock dep", function()
			-- Arrange + Act
			local ok = pcall(function()
				CollisionResolver.init({
					csm = buildMockCsm({}),
					peelDispatcher = buildMockPeelDispatcher(),
					-- clock intentionally omitted
				})
			end)

			-- Assert: no error when clock is absent
			expect(ok).to.equal(true)
			expect(CollisionResolver._isInitialized()).to.equal(true)
		end)

		-- DI: re-init with same deps is idempotent (does not double-assert).
		it("DI — re-init with same deps is idempotent", function()
			-- Arrange: first init succeeds
			local mockCsm = buildMockCsm({})
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act: second init with same deps — must not raise
			local ok = pcall(function()
				CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })
			end)

			-- Assert
			expect(ok).to.equal(true)
			expect(CollisionResolver._isInitialized()).to.equal(true)
		end)

		-- DI: tick before init raises with "init" in error message.
		it("DI — tick before init raises with 'init' in message", function()
			-- _resetForTests in afterEach ensures _initialized = false at start
			local ok, err = pcall(function()
				CollisionResolver.tickPhase1(1, {})
			end)
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "init")).to.be.ok()
		end)

		-- -----------------------------------------------------------------------
		-- State transitions
		-- -----------------------------------------------------------------------

		-- State: initial state is "Dormant" before any tick.
		it("State — initial state is Dormant before any tick", function()
			-- _resetForTests guarantees clean state
			expect(CollisionResolver.getState()).to.equal("Dormant")
		end)

		-- State: after tick with empty getAllActive, state == "Dormant".
		it("State — after tick with empty crowds, state == Dormant", function()
			-- Arrange
			local mockCsm = buildMockCsm({})
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act
			CollisionResolver.tickPhase1(1, {})

			-- Assert
			expect(CollisionResolver.getState()).to.equal("Dormant")
		end)

		-- State: after tick with non-empty getAllActive, state == "Ticking".
		it("State — after tick with non-empty crowds, state == Ticking", function()
			-- Arrange: one active crowd
			local mockCsm = buildMockCsm({
				{
					crowdId = "crowd-1",
					position = Vector3.new(0, 0, 0),
					radius = 15,
					state = "Active",
				},
			})
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Act
			CollisionResolver.tickPhase1(1, {})

			-- Assert
			expect(CollisionResolver.getState()).to.equal("Ticking")
		end)

		-- State: after Ticking tick, a subsequent empty tick returns to Dormant.
		it("State — Ticking → Dormant on subsequent empty-crowd tick", function()
			-- Arrange: mutable crowd list to control per-tick results
			local crowdList: { any } = {
				{
					crowdId = "crowd-1",
					position = Vector3.new(0, 0, 0),
					radius = 15,
					state = "Active",
				},
			}
			local mockCsm: any = {
				getAllActive = function(): { any }
					return crowdList
				end,
			}
			local mockPeel = buildMockPeelDispatcher()
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = mockPeel })

			-- Tick 1: non-empty → Ticking
			CollisionResolver.tickPhase1(1, {})
			expect(CollisionResolver.getState()).to.equal("Ticking")

			-- Tick 2: empty → Dormant
			table.clear(crowdList)
			CollisionResolver.tickPhase1(2, {})
			expect(CollisionResolver.getState()).to.equal("Dormant")
		end)
	end)
end
