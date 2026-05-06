--!strict

--[[
	NPCSpawner pool bootstrap — unit tests.
	Path: tests/unit/npc-spawner/pool_bootstrap.spec.luau
	Implements:
	  AC-01 — Pool size exactly 300 after init (TR-npc-spawner-001)
	  AC-03 — Zero Part allocation after init complete (TR-npc-spawner-003)
	  AC-05 — Single own Heartbeat:Connect; Disconnect on destroyAll (TR-npc-spawner-013 / ADR-0008)
	  TR-011 — ARENA_WALKABLE_AREA_SQ nil / zero / negative raises at init time
	  TR-012 — ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ returned by getDesignDensity()
	  Idempotency guard — second init() call raises

	Test isolation strategy:
	  - NPCSpawner._resetForTests() called in afterEach to return module to clean state.
	  - RunService injected via deps.runService mock — no real Heartbeat used.
	  - Arena area injected via deps.arenaArea — no workspace attribute read.

	Instance.new spy note (AC-01 / AC-03):
	  Roblox's Luau sandbox does not allow monkey-patching the global Instance.new.
	  Pool size is verified via #NPCSpawner._getPool() after init() completes.
	  AC-03 (zero mid-round alloc) is verified by checking _getPool() length does
	  NOT grow between init()-complete and destroyAll() — Parts are pre-allocated
	  at init(), pool is frozen for the round.
	  This approach is documented in the story spec as the approved alternative.

	task.defer scheduler note (AC-01):
	  NPCSpawner.init() fires 12 task.defer batches. In Roblox Studio's TestEZ
	  runner the task scheduler runs normally; task.wait() yields until deferred
	  callbacks complete. This test REQUIRES Studio's scheduler — it will not
	  pass in a headless runner that does not drain the task queue between frames.
	  The project's testing model is manual verification in Roblox Studio (CLAUDE.md §Testing).

	Test naming convention: test_[system]_[scenario]_[expected_result] per
	.claude/rules/test-standards.md.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	--- Builds a minimal mock RunService with a spy on Heartbeat:Connect.
	--- The mock tracks cumulative Connect calls and provides Disconnect spies
	--- on each returned connection object.
	local function buildMockRunService()
		local connectCallCount = 0
		local disconnectCallCount = 0

		-- Each call to Heartbeat:Connect returns a new fake connection.
		-- The connection's :Disconnect() increments disconnectCallCount.
		local fakeHeartbeatSignal = {
			Connect = function(_self: any, _callback: (dt: number) -> ()): any
				connectCallCount += 1
				local conn = {
					_disconnected = false,
					Disconnect = function(connSelf: any)
						if not connSelf._disconnected then
							connSelf._disconnected = true
							disconnectCallCount += 1
						end
					end,
				}
				return conn
			end,
		}

		local mockRunService = {
			Heartbeat = fakeHeartbeatSignal,
			_getConnectCallCount = function(): number
				return connectCallCount
			end,
			_getDisconnectCallCount = function(): number
				return disconnectCallCount
			end,
		}

		return mockRunService
	end

	--- Builds standard deps for tests that need a valid state to proceed.
	--- area: defaults to 40000 (produces ρ_design = 0.0075 with pool=300).
	local function buildDeps(overrides: { runService: any?, arenaArea: number? }?)
		local mockRS = buildMockRunService()
		return {
			runService = (overrides and overrides.runService) or mockRS,
			arenaArea = (overrides and overrides.arenaArea) or 40000,
			_mockRS = mockRS,  -- expose for assertions even if overridden
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("NPCSpawner pool bootstrap", function()
		beforeEach(function()
			-- Clear any workspace pollution from prior tests / Studio session.
			-- TR-011 nil-area test relies on the workspace attribute being absent.
			game.Workspace:SetAttribute("ArenaWalkableAreaSq", nil)
		end)

		afterEach(function()
			-- Reset singleton state between tests so each test is isolated.
			NPCSpawner._resetForTests()
			-- Clear workspace attribute again so leftover state cannot leak across describes.
			game.Workspace:SetAttribute("ArenaWalkableAreaSq", nil)
		end)

		-- AC-01 (TR-npc-spawner-001): pool size == 300 after init + scheduler drain.
		-- Verifies 12 batches × 25 Parts = 300 Parts in _pool.
		-- Uses task.wait() to drain deferred callbacks (requires Studio scheduler).
		it("AC-01 — pool size exactly 300 after init", function()
			-- Arrange
			local deps = buildDeps()

			-- Act
			NPCSpawner.init({ runService = deps.runService, arenaArea = 40000 })
			-- Drain 12 deferred batches. Each batch fires one task.defer; a single
			-- task.wait() yields past all pending defers queued in the same frame.
			-- Two yields are used defensively (first yield exits current frame,
			-- second ensures all 12 batches have been serviced).
			task.wait()
			task.wait()

			-- Assert
			local pool = NPCSpawner._getPool()
			expect(#pool).to.equal(300)
		end)

		-- AC-03 (TR-npc-spawner-003): pool size does NOT grow after init completes.
		-- Verifies no additional Instance.new('Part') calls occur during the round.
		-- Strategy: record pool size post-init; simulate a round by calling createAll
		-- + destroyAll; verify pool size is unchanged.
		-- TODO(Story 5-2): extend this test to simulate 60-tick reclaim/respawn cycles
		-- once reclaim() + respawn pipeline land. Story QA case specifies "60 ticks pass
		-- with reclaim/respawn cycles" — current 5-1 substitution covers init-frozen pool only.
		it("AC-03 — no Part allocation after init complete (pool frozen mid-round)", function()
			-- Arrange
			local deps = buildDeps()
			NPCSpawner.init({ runService = deps.runService, arenaArea = 40000 })
			task.wait()
			task.wait()

			local poolSizeAfterInit = #NPCSpawner._getPool()
			expect(poolSizeAfterInit).to.equal(300)

			-- Act: simulate round start + end (no alloc should occur)
			NPCSpawner.createAll({})
			NPCSpawner.destroyAll()

			-- Assert: pool size unchanged — no new Parts created mid-round
			local poolSizeAfterRound = #NPCSpawner._getPool()
			expect(poolSizeAfterRound).to.equal(poolSizeAfterInit)
		end)

		-- AC-05 (ADR-0008 §Cadence Exemption): single Heartbeat:Connect per createAll;
		-- Disconnect called on destroyAll; second createAll re-connects (1 active at a time).
		it("AC-05 — single Heartbeat:Connect on createAll; Disconnect on destroyAll", function()
			-- Arrange
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()
			task.wait()

			-- Act 1: first round
			NPCSpawner.createAll({})

			-- Assert: exactly 1 Connect call after first createAll
			expect(mockRS._getConnectCallCount()).to.equal(1)
			expect(mockRS._getDisconnectCallCount()).to.equal(0)

			NPCSpawner.destroyAll()

			-- Assert: Disconnect called once after destroyAll
			expect(mockRS._getDisconnectCallCount()).to.equal(1)

			-- Act 2: second round (re-connect)
			NPCSpawner.createAll({})

			-- Assert: cumulative Connect == 2 (one per round); 1 active at any time
			expect(mockRS._getConnectCallCount()).to.equal(2)
			expect(mockRS._getDisconnectCallCount()).to.equal(1)  -- previous still disconnected

			NPCSpawner.destroyAll()

			-- Assert: cumulative Disconnect == 2
			expect(mockRS._getDisconnectCallCount()).to.equal(2)
		end)

		-- TR-npc-spawner-011: nil area raises at init time with ARENA_WALKABLE_AREA_SQ in message.
		it("TR-011 — init with nil arenaArea raises with ARENA_WALKABLE_AREA_SQ in message", function()
			-- Arrange: inject nil via override — workspace attribute absent in Studio TestEZ context
			local mockRS = buildMockRunService()

			-- Act + Assert: pcall captures the assert
			local ok, err = pcall(function()
				-- Passing arenaArea=nil and no workspace attribute → resolveArenaArea returns nil
				-- We cannot pass nil directly through deps table without bypassing the merge logic,
				-- so we use _resetForTests to clear any prior override and rely on the workspace
				-- attribute path returning nil (no attribute set in test context).
				NPCSpawner.init({ runService = mockRS })
			end)

			expect(ok).to.equal(false)
			-- Error message must reference the config key so the developer knows what to fix.
			expect(string.find(err :: string, "ARENA_WALKABLE_AREA_SQ")).to.be.ok()
		end)

		-- TR-npc-spawner-011: zero area raises at init time.
		it("TR-011 — init with arenaArea = 0 raises", function()
			-- Arrange
			local mockRS = buildMockRunService()

			-- Act + Assert
			local ok, err = pcall(function()
				NPCSpawner.init({ runService = mockRS, arenaArea = 0 })
			end)

			expect(ok).to.equal(false)
			expect(string.find(err :: string, "ARENA_WALKABLE_AREA_SQ")).to.be.ok()
		end)

		-- TR-npc-spawner-011: negative area raises at init time.
		it("TR-011 — init with arenaArea = -1 raises", function()
			-- Arrange
			local mockRS = buildMockRunService()

			-- Act + Assert
			local ok, err = pcall(function()
				NPCSpawner.init({ runService = mockRS, arenaArea = -1 })
			end)

			expect(ok).to.equal(false)
			expect(string.find(err :: string, "ARENA_WALKABLE_AREA_SQ")).to.be.ok()
		end)

		-- TR-npc-spawner-012: ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ.
		-- 300 / 40000 = 0.0075 exactly.
		it("TR-012 — getDesignDensity returns NPC_POOL_SIZE / arenaArea", function()
			-- Arrange
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()

			-- Act
			local density = NPCSpawner.getDesignDensity()

			-- Assert: 300 / 40000 = 0.0075
			local expected = 300 / 40000
			local epsilon = 1e-9
			expect(math.abs(density - expected) < epsilon).to.equal(true)
		end)

		-- Idempotency guard: second init() call must raise with a clear message.
		-- This is a defect surface — double-init is a caller bug.
		it("idempotency — second init raises", function()
			-- Arrange: first init succeeds
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()

			-- Act: second init should raise
			local mockRS2 = buildMockRunService()
			local ok = pcall(function()
				NPCSpawner.init({ runService = mockRS2, arenaArea = 40000 })
			end)

			expect(ok).to.equal(false)
		end)

		-- State transitions: verify _getState() reflects lifecycle correctly.
		-- "Dormant" after init; "Ticking" after createAll; "Dormant" after destroyAll.
		it("state — Dormant after init, Ticking after createAll, Dormant after destroyAll", function()
			-- Arrange
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()

			-- Assert post-init
			expect(NPCSpawner._getState()).to.equal("Dormant")

			-- Act + Assert post-createAll
			NPCSpawner.createAll({})
			expect(NPCSpawner._getState()).to.equal("Ticking")

			-- Act + Assert post-destroyAll
			NPCSpawner.destroyAll()
			expect(NPCSpawner._getState()).to.equal("Dormant")
		end)

		-- Heartbeat connection nil after destroyAll (complements AC-05).
		it("AC-05 — _heartbeatConn is nil after destroyAll", function()
			-- Arrange
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()
			NPCSpawner.createAll({})

			-- Conn non-nil during round
			expect(NPCSpawner._getHeartbeatConn()).to.be.ok()

			-- Act
			NPCSpawner.destroyAll()

			-- Assert
			expect(NPCSpawner._getHeartbeatConn()).to.equal(nil)
		end)

		-- TR-012 / public-API guard: getDesignDensity() must raise if called before init().
		-- Public method has an assert branch with no other coverage; this is its test.
		it("getDesignDensity raises before init", function()
			-- Arrange: no init() — module is in fresh state via afterEach reset

			-- Act + Assert
			local ok, err = pcall(function()
				NPCSpawner.getDesignDensity()
			end)

			expect(ok).to.equal(false)
			-- Error message names the method so the developer knows the call site is wrong.
			expect(string.find(err :: string, "getDesignDensity")).to.be.ok()
		end)

		-- AC-01 edge / idempotency: createAll called twice without destroyAll must raise.
		-- Story QA case lists this as an explicit edge condition.
		it("createAll double-call without destroyAll raises", function()
			-- Arrange: init + first createAll (state goes to Ticking)
			local mockRS = buildMockRunService()
			NPCSpawner.init({ runService = mockRS, arenaArea = 40000 })
			task.wait()
			NPCSpawner.createAll({})

			-- Act: second createAll while already Ticking
			local ok, err = pcall(function()
				NPCSpawner.createAll({})
			end)

			-- Assert
			expect(ok).to.equal(false)
			expect(string.find(err :: string, "createAll")).to.be.ok()
			-- Sanity: only the original Heartbeat connection remains (second connect rejected).
			expect(mockRS._getConnectCallCount()).to.equal(1)
		end)
	end)
end
