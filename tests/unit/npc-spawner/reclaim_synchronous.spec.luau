--!strict

--[[
	NPCSpawner reclaim() synchronous postconditions — unit tests.
	Path: tests/unit/npc-spawner/reclaim_synchronous.spec.luau
	Implements:
	  AC-07 — reclaim() synchronous postconditions (TR-npc-spawner-005)
	  AC-08 — double-reclaim raises (TR-npc-spawner-010)
	  No yield — reclaim body never calls task.wait / task.defer

	Test isolation strategy:
	  - NPCSpawner._resetForTests() called in afterEach.
	  - NPCSpawner._seedNpcForTest() used to set up pre-conditions without
	    running the full createAll() pipeline.
	  - DI deps injected to keep tests deterministic.

	Story 5-2 / Story 002 QA Test Cases:
	  - AC-07: reclaim postconditions (active, transparency, position, snapshot)
	  - AC-08: double-reclaim error message
	  - Unknown npcId raises distinct error
	  - Snapshot invalidated post-reclaim
	  - Reclaim of active NPC removes it from getAllActiveNPCs()
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)

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

	--- Builds a mock TweenService whose tweens record Cancel/Play calls.
	local function buildMockTweenService()
		local cancelCallCount = 0
		local playCallCount = 0

		local ts = {
			_getCancelCount = function() return cancelCallCount end,
			_getPlayCount   = function() return playCallCount end,
			Create = function(_self: any, _instance: any, _info: any, _props: any): any
				return {
					Play = function(_t: any) playCallCount += 1 end,
					Cancel = function(_t: any) cancelCallCount += 1 end,
				}
			end,
		}
		return ts
	end

	--- Builds a deterministic mock CSM with no crowds.
	local function buildMockCsm()
		return {
			getAllCrowdPositions = function(): { [string]: any }
				return {}
			end,
		}
	end

	--- Initialises NPCSpawner with minimal DI suitable for reclaim tests.
	--- Does NOT call task.wait() — uses _seedNpcForTest instead of createAll().
	local function initForTest()
		local mockRS = buildMockRunService()
		local mockTs = buildMockTweenService()
		local mockCsm = buildMockCsm()

		NPCSpawner.init({
			runService   = mockRS,
			arenaArea    = 40000,
			arenaBounds  = { -100, 100, -100, 100 },
			csm          = mockCsm,
			tweenService = mockTs,
		})
		return mockTs
	end

	--- Creates a bare Part suitable for use as an NPC part in tests.
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

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("NPCSpawner reclaim() synchronous postconditions", function()
		afterEach(function()
			NPCSpawner._resetForTests()
		end)

		-- AC-07: After reclaim, active=false, Part.Transparency==1,
		-- Part.CFrame.Y < -1000, NPC absent from getAllActiveNPCs().
		it("AC-07 — reclaim sets active=false and parks Part at sentinel", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n42", part, true, Vector3.new(5, 0, 5))

			-- Pre-condition: NPC is active and in snapshot.
			local snapshotBefore = NPCSpawner.getAllActiveNPCs()
			local foundBefore = false
			for _, rec in ipairs(snapshotBefore) do
				if rec.npcId == "n42" then
					foundBefore = true
					break
				end
			end
			expect(foundBefore).to.equal(true)

			-- Act
			NPCSpawner.reclaim("n42")

			-- Assert: Part parked.
			expect(part.Transparency).to.equal(1)
			expect(part.CFrame.Y < -1000).to.equal(true)

			-- Assert: NPC not in active list.
			local snapshotAfter = NPCSpawner.getAllActiveNPCs()
			local foundAfter = false
			for _, rec in ipairs(snapshotAfter) do
				if rec.npcId == "n42" then
					foundAfter = true
					break
				end
			end
			expect(foundAfter).to.equal(false)

			-- Assert: NPC record shows inactive.
			local npcById = NPCSpawner._getNpcById()
			expect(npcById["n42"].active).to.equal(false)
		end)

		-- AC-07 postcondition: _activeList no longer contains npcId.
		it("AC-07 — reclaim removes npcId from _activeList", function()
			-- Arrange
			initForTest()
			local partA = makePart()
			local partB = makePart()
			NPCSpawner._seedNpcForTest("n0", partA, true, Vector3.new(10, 0, 10))
			NPCSpawner._seedNpcForTest("n1", partB, true, Vector3.new(20, 0, 20))

			expect(#NPCSpawner._getActiveList()).to.equal(2)

			-- Act
			NPCSpawner.reclaim("n0")

			-- Assert
			local activeList = NPCSpawner._getActiveList()
			expect(#activeList).to.equal(1)
			expect(activeList[1]).to.equal("n1")
		end)

		-- AC-08: Double-reclaim raises with message containing "double-reclaim"
		-- or "already inactive".
		it("AC-08 — double-reclaim raises with descriptive message", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n42", part, true, Vector3.new(5, 0, 5))
			NPCSpawner.reclaim("n42")

			-- Act: second reclaim should raise.
			local ok, err = pcall(function()
				NPCSpawner.reclaim("n42")
			end)

			-- Assert
			expect(ok).to.equal(false)
			local errStr = tostring(err)
			local mentionsDoubleReclaim = string.find(errStr, "double%-reclaim") ~= nil
			local mentionsAlreadyInactive = string.find(errStr, "already inactive") ~= nil
			expect(mentionsDoubleReclaim or mentionsAlreadyInactive).to.equal(true)
		end)

		-- Unknown npcId raises a distinct error (not double-reclaim).
		it("unknown npcId raises with 'unknown npcId' in message", function()
			-- Arrange
			initForTest()

			-- Act
			local ok, err = pcall(function()
				NPCSpawner.reclaim("n999")
			end)

			-- Assert
			expect(ok).to.equal(false)
			local errStr = tostring(err)
			expect(string.find(errStr, "unknown npcId") ~= nil
				or string.find(errStr, "n999") ~= nil).to.equal(true)
		end)

		-- Snapshot cache invalidated post-reclaim: _cachedSnapshot == nil.
		it("snapshot cache is nil immediately after reclaim", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n5", part, true, Vector3.new(1, 0, 1))

			-- Build the cache.
			local _ = NPCSpawner.getAllActiveNPCs()
			expect(NPCSpawner._getCachedSnapshot()).to.be.ok()

			-- Act
			NPCSpawner.reclaim("n5")

			-- Assert: cache invalidated.
			expect(NPCSpawner._getCachedSnapshot()).to.equal(nil)
		end)

		-- Reclaim does not yield: wrap in a coroutine, resume, check no task.wait calls.
		-- Since we cannot monkey-patch task.wait, we verify the coroutine completes
		-- synchronously within a single resume (status == "dead" after one resume).
		it("AC-07 — reclaim completes without yielding (synchronous contract)", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n10", part, true, Vector3.new(3, 0, 3))

			-- Act: wrap reclaim in a coroutine; if it yields, status will be "suspended".
			local co = coroutine.create(function()
				NPCSpawner.reclaim("n10")
			end)
			coroutine.resume(co)

			-- Assert: coroutine is dead (returned) — did not yield.
			expect(coroutine.status(co)).to.equal("dead")
		end)

		-- Reclaim of the only active NPC leaves an empty active list.
		it("reclaim of last active NPC leaves empty active list", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n0", part, true, Vector3.new(0, 0, 0))
			expect(#NPCSpawner._getActiveList()).to.equal(1)

			-- Act
			NPCSpawner.reclaim("n0")

			-- Assert
			expect(#NPCSpawner._getActiveList()).to.equal(0)
			local snapshot = NPCSpawner.getAllActiveNPCs()
			expect(#snapshot).to.equal(0)
			expect(table.isfrozen(snapshot)).to.equal(true)
		end)
	end)
end
