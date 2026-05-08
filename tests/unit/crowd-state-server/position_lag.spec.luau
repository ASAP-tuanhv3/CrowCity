--!strict

--[[
	CrowdStateServer Story 005 — F2 position lag + nil HumanoidRootPart guard
	— unit tests.
	Path: tests/unit/crowd-state-server/position_lag.spec.luau

	Implements Story 005 (CSM) QA test cases:
	  AC-07 (F2 math) — single-tick + multi-tick convergence.
	  AC-19 (nil HRP guard) — Character nil / HRP nil / disconnected player
	         all leave record.position + stillOverlapping + state untouched.
	  CROWD_POS_LAG boundary — value matches GDD §F2 default of 0.15.
	  All-crowds iteration — 8 crowds with distinct characters.
	  Eliminated keeps moving — per GDD §States L83.
	  Performance — 12-record fixture < 0.5 ms (soft assertion).

	Test isolation:
	  CrowdStateServer._resetForTests() in afterEach.
	  Player resolution via _setTestOwnerResolver — no real Players service
	  needed in headless TestEZ.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	-- -------------------------------------------------------------------------
	-- Float-precision helper — Roblox Vector3 stores float32; arithmetic that
	-- is exact in float64 (e.g., 0 + 100*0.15 = 15.0) introduces ~6e-7 drift
	-- when the result is written into a Vector3 component. Use approx compare.
	-- -------------------------------------------------------------------------

	local FLOAT_EPS = 1e-5

	local function approxVector3(actual: Vector3, expected: Vector3, eps: number?): boolean
		local e = eps or FLOAT_EPS
		return math.abs(actual.X - expected.X) < e
			and math.abs(actual.Y - expected.Y) < e
			and math.abs(actual.Z - expected.Z) < e
	end

	-- -------------------------------------------------------------------------
	-- Mock factories
	-- -------------------------------------------------------------------------

	--- Builds a mock Player with a controllable Character + HumanoidRootPart.
	--- `hrpPos` Vector3 — initial HRP position. Pass nil to leave Character nil.
	local function buildMockPlayer(userId: number, hrpPos: Vector3?): any
		if hrpPos == nil then
			-- nil-Character path
			return {
				UserId = userId,
				Character = nil,
			}
		end
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Anchored = true
		hrp.CanCollide = false
		hrp.Position = hrpPos
		local character = Instance.new("Model")
		character.Name = "MockChar_" .. userId
		hrp.Parent = character
		return {
			UserId = userId,
			Character = character,
		}
	end

	--- Builds a mock Player with Character but no HRP child (void-fall scenario).
	local function buildMockPlayerNoHrp(userId: number): any
		local character = Instance.new("Model")
		character.Name = "MockChar_NoHrp_" .. userId
		return {
			UserId = userId,
			Character = character,
		}
	end

	--- Seeds a CSM record directly via create() then optionally adjusts fields.
	--- crowdId equals userId stringified (matches resolveOwner's tonumber path).
	--- All fields required by CrowdRecord type — create() runs F1 sqrt(count)
	--- radius composition so count must be a real number, not nil.
	local function seedRecord(userId: number, position: Vector3): ()
		CrowdStateServer.create(tostring(userId), {
			crowdId = tostring(userId),
			position = position,
			radiusMultiplier = 1.0,
			radius = 0,  -- recomposed inside create
			count = 10,
			hue = 1,
			activeRelics = {},
			state = "Active",
			tick = 0,
			stillOverlapping = false,
			timer_start = nil,
		} :: any)
	end

	--- Sets the player resolver: maps crowdId → mock player or nil.
	local function setOwnerMap(map: { [string]: any })
		CrowdStateServer._setTestOwnerResolver(function(crowdId: string): any
			return map[crowdId]
		end)
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CrowdStateServer Story 005 — F2 position lag + nil HRP guard", function()
		beforeEach(function()
			-- Network is not started in headless TestEZ — intercept fanout calls
			-- so create()/setStillOverlapping()/etc don't crash on missing remotes.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		afterEach(function()
			CrowdStateServer._resetForTests()
		end)

		-- ---------------------------------------------------------------------
		-- CROWD_POS_LAG boundary
		-- ---------------------------------------------------------------------

		it("CROWD_POS_LAG — equals GDD §F2 default 0.15 (boundary value)", function()
			expect(CrowdStateServer._getCrowdPosLag()).to.equal(0.15)
		end)

		-- ---------------------------------------------------------------------
		-- AC-07: F2 math — single tick exact
		-- ---------------------------------------------------------------------

		-- Story doc reference: position_old (0,0,0), char_pos (100,0,0), lag=0.15
		-- → position_new = 0 + (100 - 0) * 0.15 = (15, 0, 0) (within float32 eps).
		-- Vector3 components are float32 so an "exact" 15.0 comparison drifts
		-- by ~6e-7 between the float64 arithmetic and the Vector3 store.
		it("AC-07 — single tick: (0,0,0) toward (100,0,0) → (15, 0, 0)", function()
			seedRecord(1001, Vector3.new(0, 0, 0))
			setOwnerMap({
				["1001"] = buildMockPlayer(1001, Vector3.new(100, 0, 0)),
			})

			CrowdStateServer._updatePositionsForTest(1)

			local rec = CrowdStateServer.get("1001")
			expect(rec).to.be.ok()
			expect(approxVector3((rec :: any).position, Vector3.new(15, 0, 0))).to.equal(true)
		end)

		-- Multi-tick: tick 2 from (15, 0, 0) toward (100, 0, 0)
		-- → 15 + (100 - 15) * 0.15 = 15 + 12.75 = 27.75 (within float32 eps).
		it("AC-07 — second tick: (15,0,0) toward (100,0,0) → (27.75, 0, 0)", function()
			seedRecord(1001, Vector3.new(15, 0, 0))
			setOwnerMap({
				["1001"] = buildMockPlayer(1001, Vector3.new(100, 0, 0)),
			})

			CrowdStateServer._updatePositionsForTest(1)

			local rec = CrowdStateServer.get("1001")
			expect(approxVector3((rec :: any).position, Vector3.new(27.75, 0, 0))).to.equal(true)
		end)

		-- Multi-tick convergence: 40 ticks should land within 0.5 studs of target.
		-- Math: position(n) = 100 * (1 - 0.85^n). At n=40 → 100 * 0.99850 = 99.85.
		-- 30 ticks only reaches 99.24 — too tight for 0.5 threshold. Use 40.
		it("AC-07 — convergence: 40 ticks from (0,0,0) toward (100,0,0) within 0.5 studs", function()
			seedRecord(1001, Vector3.new(0, 0, 0))
			setOwnerMap({
				["1001"] = buildMockPlayer(1001, Vector3.new(100, 0, 0)),
			})

			for tick = 1, 40 do
				CrowdStateServer._updatePositionsForTest(tick)
			end

			local rec = CrowdStateServer.get("1001")
			local pos = (rec :: any).position
			local dx = math.abs(pos.X - 100)
			expect(dx < 0.5).to.equal(true)
		end)

		-- ---------------------------------------------------------------------
		-- AC-19: nil HRP / Character / Player → graceful degrade
		-- ---------------------------------------------------------------------

		-- Character == nil: position unchanged; no error.
		it("AC-19 — Character nil: position unchanged, no error", function()
			seedRecord(2001, Vector3.new(50, 0, 0))
			setOwnerMap({
				["2001"] = buildMockPlayer(2001, nil),  -- Character = nil
			})

			local ok = pcall(function()
				CrowdStateServer._updatePositionsForTest(1)
			end)
			expect(ok).to.equal(true)

			local rec = CrowdStateServer.get("2001")
			expect((rec :: any).position).to.equal(Vector3.new(50, 0, 0))
		end)

		-- Character ~= nil but HumanoidRootPart child missing → graceful.
		it("AC-19 edge — Character without HRP: position unchanged, no error", function()
			seedRecord(2002, Vector3.new(50, 0, 0))
			setOwnerMap({
				["2002"] = buildMockPlayerNoHrp(2002),
			})

			local ok = pcall(function()
				CrowdStateServer._updatePositionsForTest(1)
			end)
			expect(ok).to.equal(true)

			local rec = CrowdStateServer.get("2002")
			expect((rec :: any).position).to.equal(Vector3.new(50, 0, 0))
		end)

		-- resolveOwner returns nil (player disconnected mid-iteration).
		it("AC-19 edge — resolveOwner nil (player DC): position unchanged", function()
			seedRecord(2003, Vector3.new(50, 0, 0))
			setOwnerMap({
				-- "2003" intentionally absent → owner resolves to nil
			})

			local ok = pcall(function()
				CrowdStateServer._updatePositionsForTest(1)
			end)
			expect(ok).to.equal(true)

			local rec = CrowdStateServer.get("2003")
			expect((rec :: any).position).to.equal(Vector3.new(50, 0, 0))
		end)

		-- AC-19: nil-HRP path must NOT mutate stillOverlapping or state.
		it("AC-19 — nil HRP: stillOverlapping + state preserved", function()
			seedRecord(2004, Vector3.new(50, 0, 0))
			-- Stage state via update — setStillOverlapping is the public API.
			CrowdStateServer.setStillOverlapping("2004", true)
			-- Force record state via internal field (test-only — record is direct ref).
			local rec = CrowdStateServer.get("2004");
			(rec :: any).state = "Active"

			setOwnerMap({
				["2004"] = buildMockPlayer(2004, nil),  -- Character = nil
			})

			CrowdStateServer._updatePositionsForTest(1)

			local recAfter = CrowdStateServer.get("2004")
			expect((recAfter :: any).position).to.equal(Vector3.new(50, 0, 0))
			expect((recAfter :: any).stillOverlapping).to.equal(true)
			expect((recAfter :: any).state).to.equal("Active")
		end)

		-- ---------------------------------------------------------------------
		-- All-crowds iteration: 8 records with distinct characters
		-- ---------------------------------------------------------------------

		it("Iteration — 8 crowds each lerp toward their own character", function()
			local ownerMap: { [string]: any } = {}
			for i = 1, 8 do
				local userId = 3000 + i
				seedRecord(userId, Vector3.new(0, 0, 0))
				ownerMap[tostring(userId)] = buildMockPlayer(userId, Vector3.new(i * 10, 0, 0))
			end
			setOwnerMap(ownerMap)

			CrowdStateServer._updatePositionsForTest(1)

			-- Each crowd N: from (0,0,0) toward (N*10, 0, 0) → (N*10*0.15, 0, 0).
			for i = 1, 8 do
				local rec = CrowdStateServer.get(tostring(3000 + i))
				local expectedX = i * 10 * 0.15
				expect(math.abs((rec :: any).position.X - expectedX) < FLOAT_EPS).to.equal(true)
			end
		end)

		-- ---------------------------------------------------------------------
		-- Eliminated still moves — per GDD §States table L83
		-- ---------------------------------------------------------------------

		-- Story explicit: "Eliminated crowds DO continue position updates"
		it("Eliminated state — position still updates per GDD §States L83", function()
			seedRecord(4001, Vector3.new(0, 0, 0))
			-- Force state to Eliminated (test-only direct mutation; production
			-- path is CSM Phase 5 stateEvaluate).
			local rec = CrowdStateServer.get("4001")
			;(rec :: any).state = "Eliminated"

			setOwnerMap({
				["4001"] = buildMockPlayer(4001, Vector3.new(100, 0, 0)),
			})

			CrowdStateServer._updatePositionsForTest(1)

			local recAfter = CrowdStateServer.get("4001")
			-- Position SHOULD have updated despite Eliminated state (within float eps).
			expect(approxVector3((recAfter :: any).position, Vector3.new(15, 0, 0))).to.equal(true)
			-- State unchanged (we never mutate state from _updatePositions).
			expect((recAfter :: any).state).to.equal("Eliminated")
		end)

		-- ---------------------------------------------------------------------
		-- Performance — 12-record fixture (soft assertion)
		-- ---------------------------------------------------------------------

		it("Performance — 12 crowds < 0.5 ms (soft, ADR-0003 Phase 5 budget headroom)", function()
			local ownerMap: { [string]: any } = {}
			for i = 1, 12 do
				local userId = 5000 + i
				seedRecord(userId, Vector3.new(0, 0, 0))
				ownerMap[tostring(userId)] = buildMockPlayer(userId, Vector3.new(i * 5, 0, 0))
			end
			setOwnerMap(ownerMap)

			local start = os.clock()
			CrowdStateServer._updatePositionsForTest(1)
			local elapsed = os.clock() - start

			-- Soft assertion: 0.5 ms is well under Phase 5 budget (0.2 ms allocated;
			-- but allow generous slack for headless test variance).
			expect(elapsed < 0.0005).to.equal(true)
		end)

		-- ---------------------------------------------------------------------
		-- Cross-cutting: tick counter recorded
		-- ---------------------------------------------------------------------

		-- Verify _lastUpdatePositionsTick is recorded (Phase 5 ordering check).
		it("Tick counter — _lastUpdatePositionsTick reflects most recent invocation", function()
			seedRecord(6001, Vector3.new(0, 0, 0))
			setOwnerMap({
				["6001"] = buildMockPlayer(6001, Vector3.new(100, 0, 0)),
			})

			CrowdStateServer._updatePositionsForTest(42)
			expect(CrowdStateServer._getLastUpdatePositionsTick()).to.equal(42)

			CrowdStateServer._updatePositionsForTest(99)
			expect(CrowdStateServer._getLastUpdatePositionsTick()).to.equal(99)
		end)
	end)
end
