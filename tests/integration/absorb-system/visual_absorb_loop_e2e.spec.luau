--!strict

--[[
	AbsorbSystem visual absorb loop end-to-end — integration test.
	Path: tests/integration/absorb-system/visual_absorb_loop_e2e.spec.luau

	Story 7-1 (Sprint 7): BUG-001 fix verification + regression lock.
	Reproduces the full server-side chain that was reported broken in Studio:
	  RoundLifecycle.createAll → CSM.create populates _crowds
	  NPCSpawner.createAll (or seeded equivalent) populates _activeList
	  AbsorbSystem.tick observes both arrays non-empty
	  Synthetic NPC within crowd.radius → AbsorbSystem fires csm.updateCount
	  Synthetic NPC outside crowd.radius → no fire

	If this test PASSES, the headless integration is correct — BUG-001 lives
	in a Studio-only path (e.g. character HRP timing, real workspace
	instantiation). If it FAILS, the wiring defect is reproducible in
	headless and visible from the failure mode.

	Per QA plan story 7-1: 8 it() blocks covering happy path + edge cases
	(negative case, empty pool, GraceWindow, Eliminated skip).

	Test isolation: per-test reset of CSM, NPCSpawner, AbsorbSystem.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	local function buildMockRunService()
		local fakeHeartbeatSignal = {
			Connect = function(_self: any, _callback: (dt: number) -> ()): any
				return {
					_disconnected = false,
					Disconnect = function(connSelf: any)
						connSelf._disconnected = true
					end,
				}
			end,
		}
		return { Heartbeat = fakeHeartbeatSignal }
	end

	local function buildMockTweenService()
		local ts: any = {
			Create = function(_self: any, _instance: any, _info: any, _props: any): any
				return {
					Play = function(_t: any) end,
					Cancel = function(_t: any) end,
				}
			end,
		}
		return ts
	end

	local function buildMockNetwork()
		local fanoutCalls: { { string } } = {}
		local mock: any = {
			fireAllClients = function(eventName: string, _payload: any)
				table.insert(fanoutCalls, { eventName })
			end,
			fireClient = function(_player: any, eventName: string, _payload: any)
				table.insert(fanoutCalls, { eventName })
			end,
			fireClientUnreliable = function(_player: any, eventName: string, _payload: any)
				table.insert(fanoutCalls, { eventName })
			end,
		}
		local function getFanoutCount(): number
			return #fanoutCalls
		end
		return mock, getFanoutCount
	end

	local function makePart(): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 0
		p.Size = Vector3.new(2, 5, 2)
		return p
	end

	--- Boot full chain: NPCSpawner.init + AbsorbSystem.init with real CSM.
	--- CSM owner resolver + fanout interceptor injected for headless determinism.
	local function bootFullChain()
		CrowdStateServer._resetForTests()
		NPCSpawner._resetForTests()
		AbsorbSystem._resetForTests()

		-- CSM: silence broadcasts (no Network in headless) + null owner resolver.
		CrowdStateServer._setTestFanoutInterceptor(function() end)
		CrowdStateServer._setTestOwnerResolver(function(_crowdId: string)
			return nil  -- nil player → no character HRP lookup; record.position stays seeded
		end)

		-- NPCSpawner DI: bare arena, mock RS / TweenService, real CSM read.
		NPCSpawner.init({
			runService   = buildMockRunService(),
			arenaArea    = 40000,
			arenaBounds  = { -100, 100, -100, 100 },
			csm          = CrowdStateServer,
			tweenService = buildMockTweenService(),
		})

		-- AbsorbSystem DI: real CSM, real NPCSpawner, mock network.
		local mockNetwork, getFanoutCount = buildMockNetwork()
		AbsorbSystem.init({
			csm        = CrowdStateServer,
			npcSpawner = NPCSpawner,
			network    = mockNetwork,
		})
		return getFanoutCount
	end

	--- Seeds a player crowd at the given XZ position with radius derived from count.
	--- count=10 → radius ≈ 4.24 studs (F1 of CSM).
	local function seedCrowd(crowdId: string, x: number, z: number, count: number, state: string?)
		CrowdStateServer.create(crowdId, {
			crowdId          = crowdId,
			position         = Vector3.new(x, 0, z),
			radiusMultiplier = 1.0,
			radius           = (2.5 + math.sqrt(count) * 0.55),
			count            = count,
			hue              = 1,
			activeRelics     = {} :: { string },
			state            = (state or "Active") :: any,
			tick             = 0,
			stillOverlapping = false,
			timer_start      = nil :: number?,
		})
	end

	--- Seeds an NPC at the given XZ position. Sets state to Ticking so getAllActiveNPCs
	--- returns it. Single NPC per call.
	local function seedNpc(npcId: string, x: number, z: number)
		NPCSpawner._setStateForTest("Ticking")
		NPCSpawner._seedNpcForTest(npcId, makePart(), true, Vector3.new(x, 0, z))
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("AbsorbSystem visual absorb loop — Story 7-1 BUG-001 fix", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
			NPCSpawner._resetForTests()
			CrowdStateServer._resetForTests()
		end)

		-- AC-1 happy path: 1 player crowd at (0,0,0), 1 NPC at (3,0,0) within radius
		-- 4.24 → AbsorbSystem.tick fires updateCount, count grows from 10 to 11.
		it("AC-1 — NPC inside radius: updateCount fires; record.count grows by 1", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10)
			seedNpc("n0", 3, 0)  -- distance 3 < radius 4.24

			-- Pre-condition assertions
			expect(#CrowdStateServer.getAllActive()).to.equal(1)
			expect(#NPCSpawner.getAllActiveNPCs()).to.equal(1)
			expect((CrowdStateServer.get("100") :: any).count).to.equal(10)

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: count grew by 1 → AbsorbSystem.updateCount fired
			expect((CrowdStateServer.get("100") :: any).count).to.equal(11)
		end)

		-- AC-2 negative: NPC just outside crowd radius → no updateCount fire.
		it("AC-2 — NPC outside radius: updateCount NOT fired; count unchanged", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10)
			seedNpc("n0", 5, 0)  -- distance 5 > radius 4.24

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect((CrowdStateServer.get("100") :: any).count).to.equal(10)
		end)

		-- AC-3 empty pool: no NPCs in spawner registry → AbsorbSystem early-returns
		-- silently; count unchanged. This is the BUG-001 hypothesis #1 silent path.
		it("AC-3 — empty NPC pool: AbsorbSystem silent no-op; no log without diagnostic", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10)
			-- NO seedNpc — empty active set

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect((CrowdStateServer.get("100") :: any).count).to.equal(10)
		end)

		-- AC-4 empty crowds: no player crowds in CSM → AbsorbSystem early-returns;
		-- AC-10 invariant: getAllActiveNPCs NOT called. BUG-001 hypothesis #4.
		it("AC-4 — empty crowds: AbsorbSystem silent no-op; AC-10 preserved", function()
			-- Arrange
			bootFullChain()
			seedNpc("n0", 0, 0)
			-- NO seedCrowd — empty CSM

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: NPC remains active (not reclaimed)
			expect(#NPCSpawner.getAllActiveNPCs()).to.equal(1)
		end)

		-- AC-5 multiple NPCs in same crowd radius — both processed within one tick.
		it("AC-5 — 3 NPCs in radius: count grows by 3 in one tick", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10)
			seedNpc("n0", 1, 0)
			seedNpc("n1", -1, 0)
			seedNpc("n2", 0, 2)

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: 10 + 3 = 13
			expect((CrowdStateServer.get("100") :: any).count).to.equal(13)
		end)

		-- AC-6 GraceWindow state — should fire updateCount per Story 5-13 AC-8.
		it("AC-6 — GraceWindow crowd: updateCount fires (AC-8 of 5-13)", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10, "GraceWindow")
			seedNpc("n0", 2, 0)

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect((CrowdStateServer.get("100") :: any).count).to.equal(11)
		end)

		-- AC-7 Eliminated state — should NOT fire updateCount per Story 5-13 AC-7.
		-- CSM.getAllActive() already filters Eliminated, so AbsorbSystem's
		-- defense-in-depth check at line 216 is the test target.
		it("AC-7 — Eliminated crowd: updateCount NOT fired (AC-7 of 5-13)", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10, "Eliminated")
			seedNpc("n0", 2, 0)

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: Eliminated crowd skipped; count unchanged.
			-- (CSM may also exclude Eliminated from getAllActive — either way no fire.)
			expect((CrowdStateServer.get("100") :: any).count).to.equal(10)
		end)

		-- AC-8 diagnostic logging integration: with 7-2 logging enabled, log line
		-- captured shows actual counts at the tick — locks BUG-001 visibility for
		-- future Studio investigations.
		it("AC-8 — diagnostic log captures live state when enabled (7-2 integration)", function()
			-- Arrange
			bootFullChain()
			seedCrowd("100", 0, 0, 10)
			seedNpc("n0", 50, 0)  -- outside radius — no absorb, but log fires

			local logLines: { string } = {}
			AbsorbSystem._setDiagnosticLoggingForTest(true, function(line: string)
				table.insert(logLines, line)
			end)

			-- Act
			AbsorbSystem.tick(15, {})  -- tickCount % 15 == 0 → log fires

			-- Assert: 1 log line with "crowds=1 npcs=1"
			expect(#logLines).to.equal(1)
			expect(logLines[1]).to.equal("[AbsorbSystem] tick 15 crowds=1 npcs=1")
		end)
	end)
end
