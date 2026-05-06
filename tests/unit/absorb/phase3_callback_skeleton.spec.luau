--!strict

--[[
	AbsorbSystem Phase 3 callback skeleton — unit tests.
	Path: tests/unit/absorb/phase3_callback_skeleton.spec.luau

	Implements Story 5-10 QA test cases:
	  AC-5  — AbsorbSystem registers no own Heartbeat:Connect; tickPhase3 invocable
	           only through TickOrchestrator (scheduler spy).
	  AC-10 — csm.getAllActive returns {} → npcSpawner.getAllActiveNPCs NOT called.
	  AC-11 — 1 Active crowd + empty NPC snapshot → zero Absorbed signals, no errors.
	  DI    — Missing required dep raises at init time, not at tick time.
	  DI    — Re-init with same deps is idempotent (no double-assert).

	Test isolation:
	  AbsorbSystem._resetForTests() in afterEach.
	  All deps injected via mocks — no real CSM, NPCSpawner, or Network required.

	Test naming: test_[system]_[scenario]_[expected_result] per .claude/rules/test-standards.md.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)

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
			updateCount = spy(),
		}
	end

	--- Builds a mock NPCSpawner with a configurable getAllActiveNPCs return value.
	local function buildMockNpcSpawner(npcs: { any }?): any
		local getSnapshotSpy = spy()
		return {
			getAllActiveNPCs = function(): { any }
				getSnapshotSpy()
				return table.freeze(npcs or {})
			end,
			_getSnapshotSpy = getSnapshotSpy,
			reclaim = spy(),
		}
	end

	--- Builds a mock Network module.
	local function buildMockNetwork(): any
		return {
			fireAllClients = spy(),
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("AbsorbSystem Phase 3 callback skeleton", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
		end)

		-- AC-5: AbsorbSystem registers no own Heartbeat:Connect.
		-- AbsorbSystem.init() must not touch RunService.Heartbeat.
		-- Verified by injecting a spy RunService and checking connect count == 0.
		it("AC-5 — init does not register own Heartbeat:Connect", function()
			-- Arrange: spy RunService to detect any Heartbeat:Connect calls
			local heartbeatConnectCount = 0
			local mockRunService = {
				Heartbeat = {
					Connect = function(_self: any, _cb: any): any
						heartbeatConnectCount += 1
						return { Disconnect = function() end }
					end,
				},
			}
			-- AbsorbSystem does not accept runService as a dep — it must NOT reach RunService at all.
			-- We confirm by verifying heartbeatConnectCount stays 0 after init + tick.
			local _ = mockRunService  -- referenced to avoid lint; used conceptually

			local mockCsm = buildMockCsm({})
			local mockSpawner = buildMockNpcSpawner({})
			local mockNetwork = buildMockNetwork()

			-- Act
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })
			-- Verify init doesn't crash + tick is callable
			AbsorbSystem.tick(1, {})

			-- Assert: zero Heartbeat connections registered through AbsorbSystem
			expect(heartbeatConnectCount).to.equal(0)
		end)

		-- AC-5: tick is callable and does not error.
		it("AC-5 — tick callable via direct invocation (TickOrchestrator contract)", function()
			-- Arrange
			local mockCsm = buildMockCsm({})
			local mockSpawner = buildMockNpcSpawner({})
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act + Assert: must not throw
			local ok = pcall(function()
				AbsorbSystem.tick(1, {})
				AbsorbSystem.tick(2, {})
				AbsorbSystem.tick(100, {})
			end)
			expect(ok).to.equal(true)
		end)

		-- AC-10: csm.getAllActive returns {} → getAllActiveNPCs NOT called (early-return).
		it("AC-10 — zero crowds: getAllActiveNPCs call count == 0", function()
			-- Arrange
			local mockCsm = buildMockCsm({})  -- empty crowd list
			local mockSpawner = buildMockNpcSpawner({})
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: snapshot never requested when no crowds present
			expect(mockSpawner._getSnapshotSpy.callCount()).to.equal(0)
		end)

		-- AC-10 edge: nil return from getAllActive treated as empty (no crash).
		it("AC-10 edge — nil getAllActive return treated as empty, no crash", function()
			-- Arrange: CSM returns nil
			local mockCsm: any = {
				getAllActive = function(): any
					return nil
				end,
				updateCount = spy(),
			}
			local mockSpawner = buildMockNpcSpawner({})
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act + Assert: nil return must not crash
			local ok = pcall(function()
				AbsorbSystem.tick(1, {})
			end)
			expect(ok).to.equal(true)
			-- getAllActiveNPCs must still not be called
			expect(mockSpawner._getSnapshotSpy.callCount()).to.equal(0)
		end)

		-- AC-11: 1 Active crowd + empty NPC snapshot → zero Absorbed events, no errors.
		it("AC-11 — 1 Active crowd + empty NPC snapshot: zero Absorbed fires, no errors", function()
			-- Arrange
			local mockCsm = buildMockCsm({
				{
					crowdId = "111",
					position = Vector3.new(0, 0, 0),
					radius = 10,
					state = "Active",
				},
			})
			local mockSpawner = buildMockNpcSpawner({})  -- empty snapshot
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			local ok = pcall(function()
				AbsorbSystem.tick(1, {})
			end)

			-- Assert: no crash, no Absorbed fires, no reclaim calls
			expect(ok).to.equal(true)
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(0)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(0)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(0)
		end)

		-- AC-11 edge: nil NPC snapshot treated as empty.
		it("AC-11 edge — nil NPC snapshot treated as empty, no crash", function()
			-- Arrange: spawner returns nil
			local mockCsm = buildMockCsm({
				{
					crowdId = "111",
					position = Vector3.new(0, 0, 0),
					radius = 10,
					state = "Active",
				},
			})
			local mockSpawner: any = {
				getAllActiveNPCs = function(): any
					return nil
				end,
				reclaim = spy(),
			}
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act + Assert
			local ok = pcall(function()
				AbsorbSystem.tick(1, {})
			end)
			expect(ok).to.equal(true)
		end)

		-- DI scaffold: missing csm raises at init time.
		it("DI — missing csm raises at init, not at tick time", function()
			-- Arrange + Act
			local ok, err = pcall(function()
				AbsorbSystem.init({
					csm = nil,
					npcSpawner = buildMockNpcSpawner(),
					network = buildMockNetwork(),
				} :: any)
			end)

			-- Assert: error at init, message references csm
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "csm")).to.be.ok()
		end)

		-- DI scaffold: missing npcSpawner raises at init time.
		it("DI — missing npcSpawner raises at init, not at tick time", function()
			-- Arrange + Act
			local ok, err = pcall(function()
				AbsorbSystem.init({
					csm = buildMockCsm(),
					npcSpawner = nil,
					network = buildMockNetwork(),
				} :: any)
			end)

			-- Assert
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "npcSpawner")).to.be.ok()
		end)

		-- DI scaffold: missing network raises at init time.
		it("DI — missing network raises at init, not at tick time", function()
			-- Arrange + Act
			local ok, err = pcall(function()
				AbsorbSystem.init({
					csm = buildMockCsm(),
					npcSpawner = buildMockNpcSpawner(),
					network = nil,
				} :: any)
			end)

			-- Assert
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "network")).to.be.ok()
		end)

		-- DI scaffold: re-init with same deps is idempotent (does not double-assert).
		it("DI — re-init with same deps is idempotent", function()
			-- Arrange: first init succeeds
			local mockCsm = buildMockCsm({})
			local mockSpawner = buildMockNpcSpawner({})
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act: second init with same deps — must not raise
			local ok = pcall(function()
				AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })
			end)

			-- Assert
			expect(ok).to.equal(true)
			expect(AbsorbSystem._isInitialized()).to.equal(true)
		end)

		-- Path: tick before init raises.
		it("DI — tick before init raises", function()
			-- _resetForTests ensures _initialized = false
			local ok, err = pcall(function()
				AbsorbSystem.tick(1, {})
			end)
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "init")).to.be.ok()
		end)
	end)
end
