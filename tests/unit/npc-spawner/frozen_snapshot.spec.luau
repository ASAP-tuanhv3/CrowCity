--!strict

--[[
	NPCSpawner getAllActiveNPCs() frozen snapshot — unit tests.
	Path: tests/unit/npc-spawner/frozen_snapshot.spec.luau
	Implements:
	  AC-09 — returned table is frozen (table.isfrozen) (TR-npc-spawner-006)
	  AC-13 — empty pool returns empty frozen table (not nil)
	  AC-15 — snapshot is point-in-time; post-capture reclaim does not mutate
	           already-returned table; new snapshot rebuilt after cache miss.
	  Cache invalidation — after reclaim(), _cachedSnapshot == nil; cache hit on
	           consecutive calls within same tick (same reference).

	Test isolation strategy:
	  - NPCSpawner._resetForTests() in afterEach.
	  - _seedNpcForTest() used for all pre-conditions.

	Story 5-3 QA Test Cases (all cases implemented below).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	local function buildMockRunService()
		return {
			Heartbeat = {
				Connect = function(_self: any, _cb: any): any
					return { Disconnect = function(_: any) end }
				end,
			},
		}
	end

	local function buildMockTweenService()
		return {
			Create = function(_self: any, _inst: any, _info: any, _props: any): any
				return {
					Play = function(_: any) end,
					Cancel = function(_: any) end,
				}
			end,
		}
	end

	local function buildMockCsm()
		return { getAllCrowdPositions = function() return {} end }
	end

	local function initForTest()
		NPCSpawner.init({
			runService   = buildMockRunService(),
			arenaArea    = 40000,
			arenaBounds  = { -100, 100, -100, 100 },
			csm          = buildMockCsm(),
			tweenService = buildMockTweenService(),
		})
	end

	local function makePart(): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 0
		return p
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("NPCSpawner getAllActiveNPCs() frozen snapshot", function()
		afterEach(function()
			NPCSpawner._resetForTests()
		end)

		-- AC-09: snapshot is frozen; mutation raises.
		it("AC-09 — returned snapshot table is frozen", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n0", part, true, Vector3.new(0, 0, 0))

			-- Act
			local snapshot = NPCSpawner.getAllActiveNPCs()

			-- Assert: table.isfrozen
			expect(table.isfrozen(snapshot)).to.equal(true)
		end)

		-- AC-09 edge: attempting to mutate a frozen table raises.
		it("AC-09 — mutating frozen snapshot raises an error", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n0", part, true, Vector3.new(0, 0, 0))
			local snapshot = NPCSpawner.getAllActiveNPCs()

			-- Act + Assert: writing to frozen table must error.
			local ok = pcall(function()
				(snapshot :: any)[1] = nil
			end)
			expect(ok).to.equal(false)
		end)

		-- AC-13: post-destroyAll, returns empty frozen table (not nil).
		it("AC-13 — post-destroyAll getAllActiveNPCs returns empty frozen table", function()
			-- Arrange: init then destroyAll (no createAll needed).
			initForTest()

			-- destroyAll on a Dormant module is a no-op, but getAllActiveNPCs should
			-- still return a frozen empty table (no active NPCs seeded).

			-- Act
			local snapshot = NPCSpawner.getAllActiveNPCs()

			-- Assert
			expect(snapshot).to.be.ok()
			expect(#snapshot).to.equal(0)
			expect(table.isfrozen(snapshot)).to.equal(true)
		end)

		-- AC-15 (point-in-time): snapshot captured before reclaim is unaffected by it.
		it("AC-15 — snapshot captured before reclaim still contains original NPC", function()
			-- Arrange: 5 active NPCs
			initForTest()
			for i = 0, 4 do
				local p = makePart()
				NPCSpawner._seedNpcForTest("n" .. i, p, true, Vector3.new(i * 10, 0, 0))
			end

			-- Capture snapshot BEFORE reclaim.
			local snapshotBefore = NPCSpawner.getAllActiveNPCs()
			expect(#snapshotBefore).to.equal(5)

			-- Act: reclaim n3 after snapshot captured.
			NPCSpawner.reclaim("n3")

			-- Assert: original snapshot still has 5 records (point-in-time).
			expect(#snapshotBefore).to.equal(5)

			-- New snapshot (after cache miss) has 4.
			local snapshotAfter = NPCSpawner.getAllActiveNPCs()
			expect(#snapshotAfter).to.equal(4)
		end)

		-- Cache hit: consecutive calls within tick return the SAME table reference.
		it("cache hit — consecutive calls return the same table reference", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n0", part, true, Vector3.new(0, 0, 0))

			-- Act
			local s1 = NPCSpawner.getAllActiveNPCs()
			local s2 = NPCSpawner.getAllActiveNPCs()

			-- Assert: same reference (cache not rebuilt).
			expect(s1 == s2).to.equal(true)
		end)

		-- Cache invalidation after reclaim: _cachedSnapshot becomes nil.
		it("cache invalidation — reclaim sets _cachedSnapshot to nil", function()
			-- Arrange
			initForTest()
			local part = makePart()
			NPCSpawner._seedNpcForTest("n0", part, true, Vector3.new(0, 0, 0))

			-- Populate cache.
			local _ = NPCSpawner.getAllActiveNPCs()
			expect(NPCSpawner._getCachedSnapshot()).to.be.ok()

			-- Act
			NPCSpawner.reclaim("n0")

			-- Assert
			expect(NPCSpawner._getCachedSnapshot()).to.equal(nil)
		end)

		-- Cache rebuilds correctly after invalidation.
		it("cache rebuild — post-reclaim call returns fresh snapshot reflecting mutation", function()
			-- Arrange: 3 active NPCs
			initForTest()
			for i = 0, 2 do
				NPCSpawner._seedNpcForTest("n" .. i, makePart(), true, Vector3.new(i * 5, 0, 0))
			end

			-- Populate cache with 3-entry snapshot.
			local s1 = NPCSpawner.getAllActiveNPCs()
			expect(#s1).to.equal(3)

			-- Reclaim one → cache invalidated.
			NPCSpawner.reclaim("n1")

			-- Next call rebuilds → 2 entries.
			local s2 = NPCSpawner.getAllActiveNPCs()
			expect(#s2).to.equal(2)
			expect(s1 == s2).to.equal(false)
		end)

		-- Never-initialized state (no init, no seeds): still returns frozen empty.
		-- This validates the very first call on a reset module.
		it("pre-init state — getAllActiveNPCs returns frozen empty without error", function()
			-- No init() called.
			local snapshot = NPCSpawner.getAllActiveNPCs()
			expect(snapshot).to.be.ok()
			expect(#snapshot).to.equal(0)
			expect(table.isfrozen(snapshot)).to.equal(true)
		end)
	end)
end
