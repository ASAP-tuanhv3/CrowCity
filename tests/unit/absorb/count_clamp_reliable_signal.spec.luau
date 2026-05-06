--!strict

--[[
	AbsorbSystem count clamp passthrough + Absorbed reliable RemoteEvent — unit tests.
	Path: tests/unit/absorb/count_clamp_reliable_signal.spec.luau

	Implements Story 5-14 QA test cases:
	  AC-9  — No AbsorbSide guard: crowd at count=300, AbsorbSystem calls updateCount(+1)
	           + reclaim UNCONDITIONALLY. Zero `if count >= 300` branches in source.
	  Absorbed reliable RemoteEvent payload — fireAllClients called with
	           (RemoteEventName.Absorbed, crowdId, Vector3).
	  Intra-server BindableEvent parity — AbsorbedSignal fires synchronously inside tick;
	           payload matches RemoteEvent payload.
	  8 absorbs → 8 fireAllClients fires with distinct positions.
	  Audit: source must contain no `count >= 300` or `count == MAX_CROWD_COUNT` guard.

	Test isolation: AbsorbSystem._resetForTests() in afterEach.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)
	local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)

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

	local function buildMockCsm(crowds: { any }, updateCountResult: number?): any
		local updateCountSpy = spy()
		return {
			getAllActive = function(): { any }
				return crowds
			end,
			updateCount = function(crowdId: string, delta: number, source: string): number
				updateCountSpy(crowdId, delta, source)
				return updateCountResult or 300  -- simulate clamped return
			end,
			_updateCountSpy = updateCountSpy,
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

	local function makeCrowd(crowdId: string, x: number, z: number, radius: number, count: number?, state: string?): any
		return {
			crowdId = crowdId,
			position = Vector3.new(x, 0, z),
			radius = radius,
			count = count or 100,
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

	describe("AbsorbSystem count clamp + reliable signal", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
		end)

		-- AC-9: crowd at count=300 → AbsorbSystem calls updateCount(+1) UNCONDITIONALLY.
		-- No `if count >= 300` guard in AbsorbSystem (clamp lives in CSM F5).
		it("AC-9 — count=300: AbsorbSystem calls updateCount(+1) unconditionally, reclaim fires", function()
			-- Arrange: crowd already at max count (300); CSM.updateCount returns 300 (clamped)
			local crowd = makeCrowd("777", 0, 0, 10, 300)  -- count=300

			-- CSM.updateCount spy returns 300 (simulates internal clamp at ceiling)
			local mockCsm = buildMockCsm({ crowd }, 300)
			local mockSpawner = buildMockNpcSpawner({ makeNpc("n0", 0, 0) })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: updateCount called unconditionally with +1
			expect(mockCsm._updateCountSpy.callCount()).to.equal(1)
			local updateCall = mockCsm._updateCountSpy.getCall(1)
			expect(updateCall[1]).to.equal("777")    -- crowdId
			expect(updateCall[2]).to.equal(1)         -- delta = +1 (no guard)
			expect(updateCall[3]).to.equal("Absorb")  -- source

			-- reclaim also fires unconditionally
			expect((mockSpawner.reclaim :: any).callCount()).to.equal(1)
		end)

		-- AC-9 edge: count=299 → +1 → 300 (reaches ceiling; AbsorbSystem still fires).
		it("AC-9 edge — count=299: AbsorbSystem calls updateCount(+1), CSM clamps at 300", function()
			-- Arrange
			local crowd = makeCrowd("777", 0, 0, 10, 299)  -- count=299

			local mockCsm = buildMockCsm({ crowd }, 300)  -- updateCount returns 300 (clamped result)
			local mockSpawner = buildMockNpcSpawner({ makeNpc("n0", 0, 0) })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			expect(mockCsm._updateCountSpy.callCount()).to.equal(1)
			local call = mockCsm._updateCountSpy.getCall(1)
			expect(call[2]).to.equal(1)  -- +1 passed; CSM clamps internally
		end)

		-- Absorbed reliable RemoteEvent payload: (RemoteEventName.Absorbed, crowdId, npcLastPosition).
		it("reliable RemoteEvent — fireAllClients called with (Absorbed, crowdId, Vector3)", function()
			-- Arrange: NPC at world position (7, 0, -3) absorbed by crowd "alpha"
			local crowd = makeCrowd("alpha", 0, 0, 20)
			local npcPos = Vector3.new(7, 0, -3)
			local npc = { npcId = "n0", position = npcPos }

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: fireAllClients called with correct payload
			local networkSpy = mockNetwork.fireAllClients :: any
			expect(networkSpy.callCount()).to.equal(1)

			local call = networkSpy.getCall(1)
			-- Arg 1: RemoteEventName.Absorbed (enum string value)
			expect(call[1]).to.equal(RemoteEventName.Absorbed)
			-- Arg 2: crowdId
			expect(call[2]).to.equal("alpha")
			-- Arg 3: npcLastPosition (Vector3)
			expect(typeof(call[3])).to.equal("Vector3")
			local firedPos = call[3] :: Vector3
			expect(math.abs(firedPos.X - 7) < 0.001).to.equal(true)
			expect(math.abs(firedPos.Y - 0) < 0.001).to.equal(true)
			expect(math.abs(firedPos.Z - (-3)) < 0.001).to.equal(true)
		end)

		-- 8 absorbs → 8 fireAllClients fires; positions distinct.
		it("reliable RemoteEvent — 8 absorbs: 8 fireAllClients fires, positions distinct", function()
			-- Arrange: 8 NPCs at different positions, all in range
			local crowd = makeCrowd("beta", 0, 0, 1000)
			local npcs: { any } = {}
			for i = 0, 7 do
				table.insert(npcs, { npcId = "n" .. tostring(i), position = Vector3.new(i * 10, 0, i * 5) })
			end

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner(npcs)
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: 8 fires
			local networkSpy = mockNetwork.fireAllClients :: any
			expect(networkSpy.callCount()).to.equal(8)

			-- All fires use Absorbed event name + crowdId "beta"
			for i = 1, 8 do
				local call = networkSpy.getCall(i)
				expect(call[1]).to.equal(RemoteEventName.Absorbed)
				expect(call[2]).to.equal("beta")
			end

			-- Positions are distinct (one per NPC)
			local seenPositions: { string } = {}
			for i = 1, 8 do
				local call = networkSpy.getCall(i)
				local pos = call[3] :: Vector3
				local key = string.format("%.0f,%.0f,%.0f", pos.X, pos.Y, pos.Z)
				local alreadySeen = false
				for _, seen in ipairs(seenPositions) do
					if seen == key then
						alreadySeen = true
						break
					end
				end
				expect(alreadySeen).to.equal(false)
				table.insert(seenPositions, key)
			end
		end)

		-- Intra-server BindableEvent parity: AbsorbedSignal fires synchronously inside tick.
		-- Payload matches the RemoteEvent payload.
		it("BindableEvent parity — AbsorbedSignal fires synchronously with same payload", function()
			-- Arrange: connect a listener to AbsorbedSignal before tick
			local signalFires: { { crowdId: string, pos: Vector3 } } = {}
			local conn = AbsorbSystem.AbsorbedSignal.Event:Connect(function(crowdId: string, pos: Vector3)
				table.insert(signalFires, { crowdId = crowdId, pos = pos })
			end)

			local crowd = makeCrowd("alpha", 0, 0, 20)
			local npcPos = Vector3.new(3, 0, 4)
			local npc = { npcId = "n0", position = npcPos }

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Disconnect listener
			conn:Disconnect()

			-- Assert: BindableEvent fired once
			expect(#signalFires).to.equal(1)
			expect(signalFires[1].crowdId).to.equal("alpha")

			-- Position matches the RemoteEvent payload
			local networkSpy = mockNetwork.fireAllClients :: any
			expect(networkSpy.callCount()).to.equal(1)
			local remoteCall = networkSpy.getCall(1)
			local remotePos = remoteCall[3] :: Vector3

			local bindPos = signalFires[1].pos
			expect(math.abs(bindPos.X - remotePos.X) < 0.001).to.equal(true)
			expect(math.abs(bindPos.Z - remotePos.Z) < 0.001).to.equal(true)
		end)

		-- BindableEvent: zero listeners — fire still safe (no error).
		it("BindableEvent — zero listeners: fire safe, no error", function()
			-- Arrange: no listener connected
			local crowd = makeCrowd("alpha", 0, 0, 10)
			local npc = { npcId = "n0", position = Vector3.new(0, 0, 0) }

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act + Assert: no crash
			local ok = pcall(function()
				AbsorbSystem.tick(1, {})
			end)
			expect(ok).to.equal(true)
		end)

		-- RemoteEventName.Absorbed exists in enum (AC: enum entry registered).
		it("RemoteEventName.Absorbed enum entry exists", function()
			expect(RemoteEventName.Absorbed).to.equal("Absorbed")
		end)

		-- updateCount delta is always +1 — never 0 or negative from AbsorbSystem.
		it("updateCount delta is always +1 (positive increment only)", function()
			-- Arrange: 3 NPCs in range
			local crowd = makeCrowd("crowd1", 0, 0, 100)
			local npcs = {
				{ npcId = "n0", position = Vector3.new(0, 0, 0) },
				{ npcId = "n1", position = Vector3.new(1, 0, 0) },
				{ npcId = "n2", position = Vector3.new(2, 0, 0) },
			}

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner(npcs)
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert: all updateCount calls use delta = +1
			local updateSpy = mockCsm._updateCountSpy
			expect(updateSpy.callCount()).to.equal(3)
			for i = 1, 3 do
				local call = updateSpy.getCall(i)
				expect(call[2]).to.equal(1)  -- delta always +1
			end
		end)

		-- updateCount source is always "Absorb".
		it("updateCount source is always 'Absorb'", function()
			-- Arrange: 1 NPC
			local crowd = makeCrowd("crowd1", 0, 0, 10)
			local npc = { npcId = "n0", position = Vector3.new(0, 0, 0) }

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			local mockNetwork = buildMockNetwork()
			AbsorbSystem.init({ csm = mockCsm, npcSpawner = mockSpawner, network = mockNetwork })

			-- Act
			AbsorbSystem.tick(1, {})

			-- Assert
			local call = mockCsm._updateCountSpy.getCall(1)
			expect(call[3]).to.equal("Absorb")
		end)
	end)
end
