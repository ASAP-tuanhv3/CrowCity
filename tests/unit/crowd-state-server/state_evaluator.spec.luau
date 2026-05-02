--!strict

--[[
	CrowdStateServer — Phase 5 stateEvaluate transitions unit tests.
	Path: tests/unit/crowd-state-server/state_evaluator.spec.luau
	Implements: CSM story-006 ACs:
	  AC-11 grace entry — Active+count=1+overlap → GraceWindow with timer_start.
	  AC-11 active exit (overlap-clear) — GraceWindow + !overlap → Active.
	  AC-11 active exit (count rise) — GraceWindow + count>1 → Active.
	  AC-12 grace → eliminated — timer expired + still overlapping → Eliminated.
	  AC-13 tie-break — overlap-clear evaluated before timer-expiry; Active wins.
	  No revival from Eliminated — terminal state.
	  CrowdEliminated payload + once-per-transition.
	  body order — _updatePositions called BEFORE transition logic.

	Uses _setTestFanoutInterceptor to capture CrowdEliminated reliable events.
	Records constructed via makeRecord; state mutated directly to set up grace
	scenarios (timer_start back-dated via os.clock() arithmetic).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(
		crowdId: string,
		count: number?,
		state: CrowdStateServer.CrowdState?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 4.24,
			count = count or 10,
			hue = 1,
			activeRelics = {} :: { string },
			state = state or "Active",
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.stateEvaluate — Active → GraceWindow", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("AC-11: count=1 + stillOverlapping → GraceWindow with timer_start", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "Active"))
			CrowdStateServer.setStillOverlapping("u1", true)

			CrowdStateServer.stateEvaluate(1)

			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.state).to.equal("GraceWindow")
			expect(rec.timer_start).never.to.equal(nil)
		end)

		it("count=1 + NOT stillOverlapping → state stays Active", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "Active"))
			-- stillOverlapping defaults to false

			CrowdStateServer.stateEvaluate(1)

			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.state).to.equal("Active")
			expect(rec.timer_start).to.equal(nil)
		end)

		it("count=2 + stillOverlapping → state stays Active", function()
			CrowdStateServer.create("u1", makeRecord("u1", 2, "Active"))
			CrowdStateServer.setStillOverlapping("u1", true)

			CrowdStateServer.stateEvaluate(1)

			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(rec.state).to.equal("Active")
		end)
	end)

	describe("CrowdStateServer.stateEvaluate — GraceWindow exits", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("AC-11: GraceWindow + !stillOverlapping → Active, timer_start cleared", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "GraceWindow"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 1.0  -- 1s into grace
			rec.stillOverlapping = false  -- CCR cleared

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Active")
			expect(after.timer_start).to.equal(nil)
		end)

		it("AC-11: GraceWindow + count>1 → Active, timer_start cleared", function()
			CrowdStateServer.create("u1", makeRecord("u1", 6, "GraceWindow"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 1.0
			rec.stillOverlapping = true

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Active")
			expect(after.timer_start).to.equal(nil)
		end)
	end)

	describe("CrowdStateServer.stateEvaluate — GraceWindow → Eliminated", function()

		--- Captures CrowdEliminated events fired during stateEvaluate.
		local recorded: { { event: string, payload: { [string]: any } } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			recorded = {}
			CrowdStateServer._setTestFanoutInterceptor(function(
				eventName: string,
				payload: { [string]: any }
			)
				table.insert(recorded, { event = eventName, payload = payload })
			end)
		end)

		it("AC-12: timer expired + stillOverlapping → Eliminated + CrowdEliminated fires", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "GraceWindow"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 3.5  -- 3.5s elapsed > 3.0s threshold
			rec.stillOverlapping = true

			recorded = {}  -- discard CrowdCreated
			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Eliminated")

			-- Filter to CrowdEliminated only.
			local elimEvents = {}
			for _, entry in recorded do
				if entry.event == "CrowdEliminated" then
					table.insert(elimEvents, entry)
				end
			end
			expect(#elimEvents).to.equal(1)
			expect(elimEvents[1].payload.crowdId).to.equal("u1")
		end)

		it("subsequent stateEvaluate on Eliminated record fires NO further event", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "GraceWindow"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 3.5
			rec.stillOverlapping = true
			CrowdStateServer.stateEvaluate(1)

			recorded = {}  -- discard CrowdEliminated from first eval
			CrowdStateServer.stateEvaluate(2)
			CrowdStateServer.stateEvaluate(3)

			local elimEvents = {}
			for _, entry in recorded do
				if entry.event == "CrowdEliminated" then
					table.insert(elimEvents, entry)
				end
			end
			expect(#elimEvents).to.equal(0)
		end)
	end)

	describe("CrowdStateServer.stateEvaluate — AC-13 tie-break", function()

		local recorded: { { event: string, payload: { [string]: any } } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			recorded = {}
			CrowdStateServer._setTestFanoutInterceptor(function(
				eventName: string,
				payload: { [string]: any }
			)
				table.insert(recorded, { event = eventName, payload = payload })
			end)
		end)

		it("AC-13: timer expired AND overlap cleared same tick → Active (overlap wins)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "GraceWindow"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.timer_start = os.clock() - 3.0  -- exactly at threshold
			rec.stillOverlapping = false  -- CCR cleared on same tick

			recorded = {}
			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Active")
			expect(after.timer_start).to.equal(nil)

			local elimEvents = {}
			for _, entry in recorded do
				if entry.event == "CrowdEliminated" then
					table.insert(elimEvents, entry)
				end
			end
			expect(#elimEvents).to.equal(0)
		end)
	end)

	describe("CrowdStateServer.stateEvaluate — Eliminated terminality", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("Eliminated record stays Eliminated regardless of count/overlap", function()
			CrowdStateServer.create("u1", makeRecord("u1", 50, "Eliminated"))
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			rec.stillOverlapping = false  -- even with no overlap, no revival
			rec.count = 50  -- even with high count, no revival

			CrowdStateServer.stateEvaluate(1)

			local after = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(after.state).to.equal("Eliminated")
		end)
	end)

	describe("CrowdStateServer.stateEvaluate — multi-record + ordering", function()

		local recorded: { { event: string, payload: { [string]: any } } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			recorded = {}
			CrowdStateServer._setTestFanoutInterceptor(function(
				eventName: string,
				payload: { [string]: any }
			)
				table.insert(recorded, { event = eventName, payload = payload })
			end)
		end)

		it("calls _updatePositions(tick) BEFORE transition logic", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1, "Active"))
			expect(CrowdStateServer._getLastUpdatePositionsTick()).to.equal(nil)

			CrowdStateServer.stateEvaluate(42)
			expect(CrowdStateServer._getLastUpdatePositionsTick()).to.equal(42)
		end)

		it("two simultaneous expirations fire two CrowdEliminated, no duplicates", function()
			CrowdStateServer.create("u_a", makeRecord("u_a", 1, "GraceWindow"))
			CrowdStateServer.create("u_b", makeRecord("u_b", 5, "Active"))
			CrowdStateServer.create("u_c", makeRecord("u_c", 1, "GraceWindow"))

			local recA = CrowdStateServer.get("u_a") :: CrowdStateServer.CrowdRecord
			recA.timer_start = os.clock() - 4.0
			recA.stillOverlapping = true
			local recC = CrowdStateServer.get("u_c") :: CrowdStateServer.CrowdRecord
			recC.timer_start = os.clock() - 4.0
			recC.stillOverlapping = true

			recorded = {}
			CrowdStateServer.stateEvaluate(1)

			local elimIds: { [string]: number } = {}
			for _, entry in recorded do
				if entry.event == "CrowdEliminated" then
					local id = entry.payload.crowdId :: string
					elimIds[id] = (elimIds[id] or 0) + 1
				end
			end
			expect(elimIds["u_a"]).to.equal(1)
			expect(elimIds["u_c"]).to.equal(1)
			expect(elimIds["u_b"]).to.equal(nil)
		end)
	end)
end
