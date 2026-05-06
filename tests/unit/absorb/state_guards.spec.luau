--!strict

--[[
	AbsorbSystem state guards — unit tests.
	Path: tests/unit/absorb/state_guards.spec.luau

	Implements Story 5-13 QA test cases:
	  AC-7  — Skip Eliminated: crowd state == "Eliminated" + NPC in radius →
	           Absorbed NOT fired; reclaim NOT called.
	  AC-8  — Active + GraceWindow allowed: both fire Absorbed + reclaim normally.
	  AC-13 — No state transitions: AbsorbSystem issues zero state-transition calls;
	           only updateCount mutator fired.

	ADR-0004: AbsorbSystem MUST NOT call csm.transitionTo* or any state-write API
	          other than updateCount. Enforced here by verifying mock CSM has no
	          unexpected calls beyond updateCount + getAllActive.

	Test isolation: AbsorbSystem._resetForTests() in afterEach.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)

	-- -------------------------------------------------------------------------
	-- Spy factory
	-- -------------------------------------------------------------------------

	local function spy()
		local calls: { { n: number, [number]: any } } = {}
		local fn: any = function(...)
			table.insert(calls, table.pack(...))
		end
		fn.calls = calls
		fn.callCount = function(): number
			return #calls
		end
		fn.getCall = function(i: number): { n: number, [number]: any }
			return calls[i]
		end
		return fn
	end

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	--- Builds a mock CSM that also spies on any forbidden state-transition calls.
	--- transitionToActive and setState are sentinel spies — AbsorbSystem must NEVER call them.
	local function buildMockCsm(crowds: { any }): any
		return {
			getAllActive = function(): { any }
				return crowds
			end,
			updateCount = spy(),
			-- Sentinel spies for AC-13 — AbsorbSystem must not call these.
			transitionToActive = spy(),
			setState = spy(),
			transitionTo = spy(),
		}
	end

	local function buildMockNpcSpawner(npcs: { any }): any
		return {
			getAllActiveNPCs = function(): { any }
				return table.freeze(npcs)
			end,
			reclaim = spy(),
		}
	end

	local function buildMockNetwork(): any
		return {
			fireAllClients = spy(),
		}
	end

	local function makeCrowd(crowdId: string, x: number, z: number, radius: number, state: string): any
		return {
			crowdId = crowdId,
			position = Vector3.new(x, 0, z),
			radius = radius,
			state = state,
		}
	end

	local function makeNpc(npcId: string, x: number, z: number): any
		return {
			npcId = npcId,
			position = Vector3.new(x, 0, z),
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("AbsorbSystem state guards", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
		end)

		-- AC-7: Eliminated crowd + NPC in radius → zero Absorbed fires, zero reclaims.
		it("AC-7 — Eliminated crowd: Absorbed NOT fired, reclaim NOT called", function()
			-- Arrange: eliminated crowd whose radius covers the NPC
			local crowd = makeCrowd("777", 0, 0, 100, "Eliminated")
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: eliminated crowd skipped entirely
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(0)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(0)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(0)
		end)

		-- AC-7 edge: mixed Active + Eliminated in same tick → only Active processed.
		it("AC-7 edge — mixed Active+Eliminated: only Active crowd processed", function()
			-- Arrange: crowdA Active (NPC1 in range), crowdB Eliminated (NPC2 in range).
			-- Position crowds far apart so each only covers its own NPC.
			local crowdActive = makeCrowd("active-crowd", 0, 0, 10, "Active")
			local crowdElim   = makeCrowd("elim-crowd", 1000, 0, 10, "Eliminated")
			local npc1 = makeNpc("n0", 0, 0)       -- inside Active crowd
			local npc2 = makeNpc("n1", 1000, 0)    -- inside Eliminated crowd

			local mockCsm = buildMockCsm({ crowdActive, crowdElim })
			local mockSpawner = buildMockNpcSpawner({ npc1, npc2 })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: only NPC1 absorbed (only Active crowd processed)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			local updateCall = (mockCsm.updateCount :: any).getCall(1)
			expect(updateCall[1]).to.equal("active-crowd")

			expect((mockSpawner.reclaim :: any).callCount()).to.equal(1)
			local reclaimCall = (mockSpawner.reclaim :: any).getCall(1)
			expect(reclaimCall[1]).to.equal("n0")  -- n1 (Eliminated crowd's NPC) NOT reclaimed
		end)

		-- AC-8: Active crowd absorbs normally.
		it("AC-8 — Active crowd: Absorbed fires, updateCount called, reclaim called", function()
			-- Arrange
			local crowd = makeCrowd("active-1", 0, 0, 10, "Active")
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: full absorb sequence fired
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(1)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(1)
		end)

		-- AC-8: GraceWindow crowd absorbs normally.
		-- GraceWindow allows rescue absorbs (Pillar 5 comeback math relies on this).
		it("AC-8 — GraceWindow crowd: Absorbed fires, updateCount called, reclaim called", function()
			-- Arrange
			local crowd = makeCrowd("grace-1", 0, 0, 10, "GraceWindow")
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: GraceWindow crowd processed normally
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(1)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(1)
		end)

		-- AC-8: Both Active + GraceWindow fire normally in same tick.
		it("AC-8 — Active + GraceWindow in same tick: both fire Absorbed + reclaim", function()
			-- Arrange: 2 crowds, 2 NPCs (one per crowd, no contention)
			local crowdA = makeCrowd("active-crowd", 0, 0, 10, "Active")
			local crowdG = makeCrowd("grace-crowd", 1000, 0, 10, "GraceWindow")
			local npc1 = makeNpc("n0", 0, 0)      -- inside Active crowd
			local npc2 = makeNpc("n1", 1000, 0)   -- inside GraceWindow crowd

			local mockCsm = buildMockCsm({ crowdA, crowdG })
			local mockSpawner = buildMockNpcSpawner({ npc1, npc2 })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: 2 absorbs — both crowds processed
			expect((mockCsm.updateCount :: any).callCount()).to.equal(2)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(2)
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(2)

			-- Both crowdIds appear in updateCount calls
			local crowdIdsSeen: { [string]: boolean } = {}
			for i = 1, 2 do
				local call = (mockCsm.updateCount :: any).getCall(i)
				crowdIdsSeen[call[1] :: string] = true
			end
			expect(crowdIdsSeen["active-crowd"]).to.equal(true)
			expect(crowdIdsSeen["grace-crowd"]).to.equal(true)
		end)

		-- AC-8 edge: GraceWindow crowd at count=1 still attempts absorb (CSM clamp owns ceiling).
		it("AC-8 edge — GraceWindow at count=1 still absorbs (CSM handles ceiling)", function()
			-- Arrange: GraceWindow crowd with count=1 (already at floor)
			local crowd: any = makeCrowd("grace-low", 0, 0, 10, "GraceWindow")
			crowd.count = 1  -- at floor; AbsorbSystem still passes +1 to updateCount

			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: AbsorbSystem still calls updateCount unconditionally
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			local updateCall = (mockCsm.updateCount :: any).getCall(1)
			expect(updateCall[2]).to.equal(1)        -- delta = +1 always
			expect(updateCall[3]).to.equal("Absorb") -- source
		end)

		-- AC-13: No state transitions issued — AbsorbSystem must not call any state-write API
		-- other than updateCount. Verified by sentinel spies on forbidden methods.
		it("AC-13 — no state-transition calls: only updateCount mutator fired", function()
			-- Arrange: GraceWindow crowd + NPC absorbed
			local crowd = makeCrowd("grace-1", 0, 0, 10, "GraceWindow")
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: updateCount fired (expected), forbidden APIs NOT called
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			expect((mockCsm.transitionToActive :: any).callCount()).to.equal(0)
			expect((mockCsm.setState :: any).callCount()).to.equal(0)
			expect((mockCsm.transitionTo :: any).callCount()).to.equal(0)
		end)

		-- AC-13 edge: count at recovery threshold — AbsorbSystem still issues no transition.
		-- (Recovery threshold is hypothetical — CSM owns transitions; AbsorbSystem never checks.)
		it("AC-13 edge — count at any threshold: AbsorbSystem issues no transition calls", function()
			-- Arrange: crowd at count=2 (recovery threshold edge case — CSM handles it)
			local crowd: any = makeCrowd("grace-1", 0, 0, 10, "GraceWindow")
			crowd.count = 2

			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: AbsorbSystem only calls updateCount — no state transitions
			expect((mockCsm.transitionToActive :: any).callCount()).to.equal(0)
			expect((mockCsm.setState :: any).callCount()).to.equal(0)
			expect((mockCsm.transitionTo :: any).callCount()).to.equal(0)
			-- updateCount IS called (the one allowed mutation)
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
		end)

		-- AC-7 edge: all 3 state values combined in one tick.
		-- Only Active + GraceWindow process; Eliminated skips.
		it("AC-7 combined — Active, GraceWindow, Eliminated in same tick: correct dispatch", function()
			-- Arrange: 3 crowds, 3 NPCs (one per crowd)
			local crowdA = makeCrowd("aa", 0,    0, 10, "Active")
			local crowdG = makeCrowd("gg", 1000, 0, 10, "GraceWindow")
			local crowdE = makeCrowd("ee", 2000, 0, 10, "Eliminated")
			local npc1 = makeNpc("n0", 0,    0)  -- Active crowd
			local npc2 = makeNpc("n1", 1000, 0)  -- GraceWindow crowd
			local npc3 = makeNpc("n2", 2000, 0)  -- Eliminated crowd

			local mockCsm = buildMockCsm({ crowdA, crowdG, crowdE })
			local mockSpawner = buildMockNpcSpawner({ npc1, npc2, npc3 })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: 2 absorbs (Active + GraceWindow), 0 for Eliminated
			expect((mockCsm.updateCount :: any).callCount()).to.equal(2)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(2)

			-- Verify Eliminated crowd NPC (n2) not reclaimed
			local n2Reclaimed = false
			for i = 1, 2 do
				local call = (mockSpawner.reclaim :: any).getCall(i)
				if call[1] == "n2" then
					n2Reclaimed = true
				end
			end
			expect(n2Reclaimed).to.equal(false)
		end)
	end)
end
