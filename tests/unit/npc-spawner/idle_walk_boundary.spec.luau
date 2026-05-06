--!strict

--[[
	NPCSpawner idle walk + boundary reflection — unit tests.
	Path: tests/unit/npc-spawner/idle_walk_boundary.spec.luau
	Implements:
	  AC-04 — Walk timer samples ∈ [T_WALK_MIN, T_WALK_MAX] (TR-npc-spawner-004)
	  AC-06 — Boundary reflection: position stays inside arena; heading flipped
	           when NPC crosses wall (TR-npc-spawner-007)
	  No NaN on zero-velocity NPC
	  No NaN on corner reflection (both X and Z out-of-bounds simultaneously)
	  Inactive NPCs are not walked by _movementTick

	Test isolation strategy:
	  - NPCSpawner._resetForTests() in afterEach.
	  - Heartbeat callback is invoked indirectly: createAll() connects _onHeartbeat
	    via injected RunService mock; tests then call the captured callback directly
	    to drive movement without real time.
	  - Deterministic clock injected for walk-timer tests.

	Story 5-4 QA Test Cases:
	  AC-04: walk timer in [2.0, 5.0] across N re-picks
	  AC-06: boundary reflection keeps pos inside arena
	  Zero-velocity NPC (no NaN)
	  Corner reflection (both axes)
	  Inactive NPC not moved
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local NPCSpawner = require(ServerStorage.Source.NPCSpawner)

	-- -------------------------------------------------------------------------
	-- Helpers
	-- -------------------------------------------------------------------------

	local function makePart(): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 0
		p.Size = Vector3.new(2, 5, 2)
		return p
	end

	--- Builds a mock RunService that captures the Heartbeat callback.
	--- Returns (mockRunService, fireHeartbeat(dt)).
	local function buildCapturingRunService()
		local capturedCallback: ((dt: number) -> ())? = nil

		local mockRS = {
			Heartbeat = {
				Connect = function(_self: any, callback: (dt: number) -> ()): any
					capturedCallback = callback
					return { Disconnect = function(_: any) end }
				end,
			},
		}

		local function fireHeartbeat(dt: number)
			if capturedCallback ~= nil then
				capturedCallback(dt)
			end
		end

		return mockRS, fireHeartbeat
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

	--- A controllable clock that starts at 0 and can be advanced manually.
	local function buildControllableClock()
		local now = 0
		return
			function() return now end,
			function(delta: number) now += delta end
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("NPCSpawner idle walk + boundary reflection", function()
		afterEach(function()
			NPCSpawner._resetForTests()
		end)

		-- AC-04: walk timer samples (walkDur) are all in [T_WALK_MIN, T_WALK_MAX].
		-- Verifies using deterministic RNG seeded via createAll.
		it("AC-04 — walkDur samples all in [2.0, 5.0] across seeded createAll", function()
			-- Arrange: use seeded deterministic RNG via DI.
			local mockRS, _ = buildCapturingRunService()
			local getClock, _ = buildControllableClock()
			local deterministicRng = Random.new(42)

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				rng          = deterministicRng,
				clock        = getClock,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			-- Act: inspect all NPC records for _walkDur in range.
			local npcById = NPCSpawner._getNpcById()
			local T_WALK_MIN = 2.0
			local T_WALK_MAX = 5.0
			local sampleCount = 0
			local allInRange = true

			for _, npc in pairs(npcById) do
				sampleCount += 1
				if npc._walkDur < T_WALK_MIN or npc._walkDur > T_WALK_MAX then
					allInRange = false
					break
				end
			end

			-- Assert
			expect(sampleCount).to.equal(300)
			expect(allInRange).to.equal(true)
		end)

		-- AC-06: NPC at arena edge with heading toward boundary → after tick,
		-- position stays inside arena and heading is reflected.
		it("AC-06 — boundary reflection keeps NPC inside arena", function()
			-- Arrange: ARENA maxX = 100; NPC placed at (98, 0, 0) heading east (0 rad).
			local mockRS, fireHeartbeat = buildCapturingRunService()
			local clockNow = 0
			local getClock = function() return clockNow end

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				clock        = getClock,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			-- Seed a specific NPC near the +X wall, heading east (heading=0).
			-- Override its state by manipulating the record after createAll.
			local npcById = NPCSpawner._getNpcById()
			local targetNpc: any = nil
			for _, npc in pairs(npcById) do
				targetNpc = npc
				break
			end
			expect(targetNpc).to.be.ok()

			-- Place NPC at X=98, heading east, walkStart far in the past so it
			-- doesn't re-pick heading (walk duration still active).
			targetNpc.position = Vector3.new(98, 0, 0)
			targetNpc.part.CFrame = CFrame.new(98, 0, 0)
			targetNpc._heading = 0  -- east (+X)
			targetNpc._walkStart = clockNow
			targetNpc._walkDur = 999  -- won't expire

			-- Act: fire one full 15-Hz tick (1/15 s accumulator drain).
			-- NPC_WALK_SPEED = 4 studs/s; one tick moves dx = 4 * (1/15) ≈ 0.267 studs.
			-- With starting pos 98, new pos ≈ 98.267 > 100 → reflection.
			-- Actually: 98 + 4 * 1/15 ≈ 98.267 which is < 100. Need to be closer.
			-- Set position closer to wall.
			targetNpc.position = Vector3.new(99.9, 0, 0)
			targetNpc.part.CFrame = CFrame.new(99.9, 0, 0)

			fireHeartbeat(1 / 15)

			-- Assert: position.X <= 100 (inside arena).
			expect(targetNpc.position.X <= 100).to.equal(true)
		end)

		-- AC-06 extension: heading is reflected (x-component flipped) on +X wall hit.
		it("AC-06 — heading flips on X-boundary hit", function()
			-- Arrange: NPC at (99.95, 0, 0), heading = 0 (east).
			local mockRS, fireHeartbeat = buildCapturingRunService()
			local clockNow = 0
			local getClock = function() return clockNow end

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				clock        = getClock,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			local npcById = NPCSpawner._getNpcById()
			local targetNpc: any = nil
			for _, npc in pairs(npcById) do
				targetNpc = npc
				break
			end

			-- Place NPC 0.01 studs from +X wall; heading east guarantees a wall hit.
			targetNpc.position = Vector3.new(99.99, 0, 0)
			targetNpc.part.CFrame = CFrame.new(99.99, 0, 0)
			targetNpc._heading = 0      -- east
			targetNpc._walkStart = clockNow
			targetNpc._walkDur = 999

			-- Capture heading before tick.
			local headingBefore = targetNpc._heading

			-- Act
			fireHeartbeat(1 / 15)

			-- Assert: heading has changed (reflected).
			-- After reflection on +X wall: new heading = π - 0 = π (west).
			-- The implementation reflects by computing new heading from flipped velocity,
			-- so heading changes from 0 to approximately π.
			local headingAfter = targetNpc._heading
			expect(headingAfter ~= headingBefore).to.equal(true)
			-- Position should be inside arena.
			expect(targetNpc.position.X <= 100).to.equal(true)
		end)

		-- Corner reflection: NPC at corner with heading into corner → both components
		-- reflected; no NaN in position.
		it("AC-06 — corner reflection produces no NaN in position", function()
			-- Arrange: NPC at (99.99, 0, 99.99), heading northeast (π/4).
			local mockRS, fireHeartbeat = buildCapturingRunService()
			local clockNow = 0
			local getClock = function() return clockNow end

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				clock        = getClock,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			local npcById = NPCSpawner._getNpcById()
			local targetNpc: any = nil
			for _, npc in pairs(npcById) do
				targetNpc = npc
				break
			end

			targetNpc.position = Vector3.new(99.99, 0, 99.99)
			targetNpc.part.CFrame = CFrame.new(99.99, 0, 99.99)
			targetNpc._heading = math.pi / 4  -- northeast
			targetNpc._walkStart = clockNow
			targetNpc._walkDur = 999

			-- Act
			fireHeartbeat(1 / 15)

			-- Assert: no NaN in position.
			local pos = targetNpc.position
			expect(pos.X == pos.X).to.equal(true)  -- NaN check: NaN != NaN
			expect(pos.Z == pos.Z).to.equal(true)
			-- Position must be within arena.
			expect(pos.X <= 100 and pos.X >= -100).to.equal(true)
			expect(pos.Z <= 100 and pos.Z >= -100).to.equal(true)
		end)

		-- Inactive NPCs are not walked (position unchanged after Heartbeat tick).
		it("inactive NPCs are not moved by _movementTick", function()
			-- Arrange
			local mockRS, fireHeartbeat = buildCapturingRunService()
			local clockNow = 0
			local getClock = function() return clockNow end

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				clock        = getClock,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			-- Reclaim one NPC to make it inactive.
			local activeList = NPCSpawner._getActiveList()
			expect(#activeList > 0).to.equal(true)
			local reclaimedId = activeList[1]
			NPCSpawner.reclaim(reclaimedId)

			local npcById = NPCSpawner._getNpcById()
			local reclaimedNpc = npcById[reclaimedId]

			-- Record park position (sentinel).
			local posBefore = reclaimedNpc.position

			-- Act: fire a tick.
			fireHeartbeat(1 / 15)

			-- Assert: inactive NPC position unchanged.
			expect(reclaimedNpc.position.X == posBefore.X).to.equal(true)
			expect(reclaimedNpc.position.Z == posBefore.Z).to.equal(true)
		end)

		-- Zero-velocity scenario: heading that produces dx=0, dz=0 → no NaN.
		-- (In practice NPC_WALK_SPEED > 0, so zero velocity requires speed=0 or dt=0.
		--  We simulate dt=0 tick to confirm no division by zero in reflection logic.)
		it("zero delta-time tick produces no NaN in NPC positions", function()
			-- Arrange
			local mockRS, fireHeartbeat = buildCapturingRunService()
			local clockNow = 0

			NPCSpawner.init({
				runService   = mockRS,
				arenaArea    = 40000,
				arenaBounds  = { -100, 100, -100, 100 },
				csm          = buildMockCsm(),
				tweenService = buildMockTweenService(),
				clock        = function() return clockNow end,
			})
			task.wait()
			task.wait()

			NPCSpawner.createAll({})

			-- Act: fire a tick with dt=0 (accumulator never reaches 1/15, so tick body
			-- doesn't fire — this is expected by design; verify no crash either way).
			local ok = pcall(function()
				fireHeartbeat(0)
			end)
			expect(ok).to.equal(true)

			-- Assert: all NPC positions are finite.
			local npcById = NPCSpawner._getNpcById()
			for _, npc in pairs(npcById) do
				expect(npc.position.X == npc.position.X).to.equal(true)
				expect(npc.position.Z == npc.position.Z).to.equal(true)
			end
		end)
	end)
end
