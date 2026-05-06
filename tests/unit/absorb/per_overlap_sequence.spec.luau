--!strict

--[[
	AbsorbSystem per-overlap sequence + reclaim contract + snapshot atomicity — unit tests.
	Path: tests/unit/absorb/per_overlap_sequence.spec.luau

	Implements Story 5-12 QA test cases:
	  AC-4  — 8 NPCs in radius, 1 tick: 8 Absorbed events; updateCount +1 called 8×;
	           reclaim called 8× (1 per npcId, no duplicates).
	  AC-6  — Per-overlap sequence: Absorbed:Fire → updateCount → reclaim. Verified
	           via ordered-call spy across all three.
	  AC-12 — Snapshot atomicity: reclaim called only on NPCs in tick-start frozen snapshot;
	           mid-tick-added NPCs never reclaimed in same tick.
	  reclaim synchronous postconditions — mock validates active=false before continuing.

	Test isolation: AbsorbSystem._resetForTests() in afterEach.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)

	-- -------------------------------------------------------------------------
	-- Spy + ordered-call log factory
	-- -------------------------------------------------------------------------

	--- Creates a shared ordered-call log that multiple spies can write to.
	--- Use this to verify cross-function call ordering (AC-6).
	local function makeOrderedLog(): { string }
		return {}
	end

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

	--- Creates a spy that also appends a tag string to a shared ordered log on each call.
	local function orderedSpy(log: { string }, tag: string)
		local calls: { { n: number, [number]: any } } = {}
		local fn: any = function(...)
			table.insert(log, tag)
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

	local function buildMockCsm(crowds: { any }, log: { string }?, logTag: string?): any
		local updateCountFn = log and orderedSpy(log, logTag or "updateCount") or spy()
		return {
			getAllActive = function(): { any }
				return crowds
			end,
			updateCount = updateCountFn,
		}
	end

	local function buildMockNpcSpawner(npcs: { any }, log: { string }?, logTag: string?): any
		local reclaimFn = log and orderedSpy(log, logTag or "reclaim") or spy()
		return {
			getAllActiveNPCs = function(): { any }
				return table.freeze(npcs)
			end,
			reclaim = reclaimFn,
		}
	end

	--- Builds a mock Network whose fireAllClients spy can log to an ordered call log.
	local function buildMockNetwork(log: { string }?, logTag: string?): any
		local fireAllClientsFn = log and orderedSpy(log, logTag or "fireAllClients") or spy()
		return {
			fireAllClients = fireAllClientsFn,
		}
	end

	local function makeCrowd(crowdId: string, x: number, z: number, radius: number, state: string?): any
		return {
			crowdId = crowdId,
			position = Vector3.new(x, 0, z),
			radius = radius,
			state = state or "Active",
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

	describe("AbsorbSystem per-overlap sequence + snapshot atomicity", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
		end)

		-- AC-4: 8 NPCs all in radius → 8 Absorbed events, 8 updateCount calls, 8 reclaims (no dupes).
		it("AC-4 — 8 NPCs in radius: 8 Absorbed, 8 updateCount, 8 reclaim (no duplicates)", function()
			-- Arrange: 1 crowd at origin r=100; 8 NPCs all within range.
			local crowd = makeCrowd("777", 0, 0, 100)
			local npcs: { any } = {}
			for i = 0, 7 do
				table.insert(npcs, makeNpc("n" .. tostring(i), i * 5, 0))
			end

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner(npcs)
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: exactly 8 of each
			expect((mockCsm.updateCount :: any).callCount()).to.equal(8)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(8)
			expect((mockNetwork.fireAllClients :: any).callCount()).to.equal(8)

			-- All updateCount calls use +1 delta and "Absorb" source.
			for i = 1, 8 do
				local call = (mockCsm.updateCount :: any).getCall(i)
				expect(call[1]).to.equal("777")   -- crowdId
				expect(call[2]).to.equal(1)        -- delta = +1
				expect(call[3]).to.equal("Absorb") -- source
			end

			-- No duplicate reclaim calls — each npcId appears exactly once.
			local reclaimedIds: { [string]: number } = {}
			for i = 1, 8 do
				local call = (mockSpawner.reclaim :: any).getCall(i)
				local npcId = call[1] :: string
				reclaimedIds[npcId] = (reclaimedIds[npcId] or 0) + 1
			end
			for npcId, count in pairs(reclaimedIds) do
				expect(count).to.equal(1)  -- each NPC reclaimed exactly once
				local _ = npcId
			end
		end)

		-- AC-4 edge: 0 NPCs in range → 0 calls.
		it("AC-4 edge — 0 NPCs in range: 0 updateCount, 0 reclaim calls", function()
			-- Arrange: crowd at origin; NPC far away
			local crowd = makeCrowd("777", 0, 0, 5)
			local npc = makeNpc("n0", 1000, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect((mockCsm.updateCount :: any).callCount()).to.equal(0)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(0)
		end)

		-- AC-4 edge: 1 NPC → 1 call each.
		it("AC-4 edge — 1 NPC in radius: exactly 1 updateCount + 1 reclaim", function()
			-- Arrange
			local crowd = makeCrowd("777", 0, 0, 10)
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect((mockCsm.updateCount :: any).callCount()).to.equal(1)
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(1)
		end)

		-- AC-6: Per-overlap sequence — ordered-call spy across fireAllClients, updateCount, reclaim.
		-- Expected order for 1 overlap: ["fireAllClients", "updateCount", "reclaim"].
		it("AC-6 — per-overlap order: Absorbed → updateCount → reclaim (1 overlap)", function()
			-- Arrange: shared ordered call log across all 3 spies.
			local callLog = makeOrderedLog()

			local crowd = makeCrowd("777", 0, 0, 10)
			local npc = makeNpc("n0", 0, 0)

			local mockCsm = buildMockCsm({ crowd }, callLog, "updateCount")
			local mockSpawner = buildMockNpcSpawner({ npc }, callLog, "reclaim")
			local mockNetwork = buildMockNetwork(callLog, "fireAllClients")
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: ordered log must be exactly ["fireAllClients", "updateCount", "reclaim"]
			expect(#callLog).to.equal(3)
			expect(callLog[1]).to.equal("fireAllClients")
			expect(callLog[2]).to.equal("updateCount")
			expect(callLog[3]).to.equal("reclaim")
		end)

		-- AC-6: 8 overlaps → 24 calls in 8 ordered triples (no interleaving).
		it("AC-6 — 8 overlaps: 24 calls in 8 ordered triples", function()
			-- Arrange
			local callLog = makeOrderedLog()

			local crowd = makeCrowd("777", 0, 0, 100)
			local npcs: { any } = {}
			for i = 0, 7 do
				table.insert(npcs, makeNpc("n" .. tostring(i), i * 5, 0))
			end

			local mockCsm = buildMockCsm({ crowd }, callLog, "updateCount")
			local mockSpawner = buildMockNpcSpawner(npcs, callLog, "reclaim")
			local mockNetwork = buildMockNetwork(callLog, "fireAllClients")
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: 24 total entries in groups of 3 in strict order
			expect(#callLog).to.equal(24)
			for triple = 0, 7 do
				local base = triple * 3 + 1
				expect(callLog[base]).to.equal("fireAllClients")
				expect(callLog[base + 1]).to.equal("updateCount")
				expect(callLog[base + 2]).to.equal("reclaim")
			end
		end)

		-- AC-12: Snapshot atomicity — mid-tick-added NPC never reclaimed in same tick.
		-- The spawner's internal state changes after getAllActiveNPCs() is called,
		-- but the frozen snapshot is already captured; the 6th NPC is never seen.
		it("AC-12 — snapshot atomicity: mid-tick added NPC not reclaimed in same tick", function()
			-- Arrange: initial 5 NPCs in snapshot; 6th added to spawner after snapshot capture.
			-- Simulate by building spawner that returns 5 NPCs on first call, then 6 on second.
			-- Since AbsorbSystem calls getAllActiveNPCs() ONCE, the 6th is never in scope.
			local callNumber = 0
			local npcsFirst: { any } = {}
			for i = 0, 4 do
				table.insert(npcsFirst, { npcId = "n" .. tostring(i), position = Vector3.new(i * 2, 0, 0) })
			end
			local npcsSixth = { npcId = "n5", position = Vector3.new(100, 0, 0) }

			local mockSpawner: any = {
				getAllActiveNPCs = function(): { any }
					callNumber += 1
					if callNumber == 1 then
						return table.freeze(npcsFirst)
					else
						-- Would include 6th NPC — but AbsorbSystem must not call this again
						local withSixth: { any } = {}
						for _, npc in ipairs(npcsFirst) do
							table.insert(withSixth, npc)
						end
						table.insert(withSixth, npcsSixth)
						return table.freeze(withSixth)
					end
				end,
				reclaim = spy(),
			}

			-- Crowd covers all 5 original NPCs (and would cover 6th too if seen)
			local crowd = makeCrowd("777", 0, 0, 1000)
			local mockCsm = buildMockCsm({ crowd })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: getAllActiveNPCs called exactly once (atomicity)
			expect(callNumber).to.equal(1)

			-- reclaim called at-most 5 times (only from snapshot)
			local reclaimCount = (mockSpawner.reclaim :: any).callCount()
			expect(reclaimCount).to.equal(5)

			-- "n5" never reclaimed (not in snapshot)
			local n5Reclaimed = false
			for i = 1, reclaimCount do
				local call = (mockSpawner.reclaim :: any).getCall(i)
				if call[1] == "n5" then
					n5Reclaimed = true
				end
			end
			expect(n5Reclaimed).to.equal(false)
		end)

		-- AC-12 edge: frozen snapshot — mutation attempt raises Lua error.
		it("AC-12 edge — frozen snapshot: mutation attempt raises", function()
			-- Arrange: build a real frozen table and try to insert into it
			local frozenTable = table.freeze({ { npcId = "n0", position = Vector3.new(0, 0, 0) } })

			local ok = pcall(function()
				-- This should raise: frozen table is read-only
				table.insert(frozenTable :: any, { npcId = "n1", position = Vector3.new(1, 0, 0) })
			end)

			-- Assert: mutation raises
			expect(ok).to.equal(false)
		end)

		-- reclaim synchronous postconditions: mock spawner validates active=false before returning.
		it("reclaim synchronous — mock validates active=false postcondition before tick continues", function()
			-- Arrange: mock spawner whose reclaim sets active=false on the NPC record,
			-- then verifies postcondition. Control continues only after postcondition set.
			local npcRecord: { npcId: string, position: Vector3, active: boolean } = {
				npcId = "n0",
				position = Vector3.new(0, 0, 0),
				active = true,
			}
			local postconditionChecked = false

			local mockSpawner: any = {
				getAllActiveNPCs = function(): { any }
					return table.freeze({ npcRecord })
				end,
				reclaim = function(npcId: string): ()
					-- Synchronous postcondition: mark inactive, verify before returning
					local npc = npcRecord
					assert(npc.npcId == npcId, "wrong npcId in reclaim")
					npc.active = false  -- postcondition
					postconditionChecked = npc.active == false
					-- Return immediately (synchronous)
				end,
			}

			local crowd = makeCrowd("777", 0, 0, 10)
			local mockCsm = buildMockCsm({ crowd })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: postcondition was checked and NPC is inactive
			expect(postconditionChecked).to.equal(true)
			expect(npcRecord.active).to.equal(false)
		end)
	end)
end
