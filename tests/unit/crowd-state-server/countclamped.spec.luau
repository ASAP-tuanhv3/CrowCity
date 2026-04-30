--!strict

--[[
	CrowdStateServer — CrowdCountClamped reliable remote unit tests.
	Path: tests/unit/crowd-state-server/countclamped.spec.luau
	Implements: CSM story-002 ACs:
	  AC-25 (CrowdCountClamped fires to LOCAL player only on positive overflow)
	  AC-25 per-call semantic (same-tick at ceiling fires again each call)
	  AC-25 edge (floor clamp does NOT fire CrowdCountClamped)
	  AC-25 edge (in-range delta does NOT fire CrowdCountClamped)
	  AC-25 target routing (non-nil target = Network.fireClient, not fireAllClients)
	  Owner unresolvable (player DC mid-tick) → no fire, no error, count still clamped
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string, count: number): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = count,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	-- Mock player builder for owner resolution.
	-- Returns a table typed as Player for testing purposes only.
	local function makeMockPlayer(userId: number)
		return ({ UserId = userId, Name = "MockPlayer" .. userId } :: any) :: Player
	end

	describe("CrowdStateServer.updateCount → CrowdCountClamped reliable", function()
		local fanoutLog: { { event: string, payload: { [string]: any }, target: Player? } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			fanoutLog = {}
			CrowdStateServer._setTestFanoutInterceptor(
				function(eventName: string, payload: { [string]: any }, target: Player?)
					table.insert(fanoutLog, { event = eventName, payload = payload, target = target })
				end
			)
			CrowdStateServer._setTestOwnerResolver(function(crowdId: string): Player?
				return makeMockPlayer(tonumber(crowdId) or 0)
			end)
		end)

		-- AC-25: count=298, delta=+5 → CrowdCountClamped fires to owner only
		-- with {crowdId, attemptedDelta=+5, clampedCount=300}.
		it("AC-25: count=298, delta=+5 → CrowdCountClamped fires {crowdId, attemptedDelta=+5, clampedCount=300}", function()
			CrowdStateServer.create("101", makeRecord("101", 298))
			-- Reset log after create (CrowdCreated was fired during create)
			fanoutLog = {}
			CrowdStateServer.updateCount("101", 5, "Absorb")

			-- Find the CrowdCountClamped event
			local clampedEvents = {}
			for _, entry in fanoutLog do
				if entry.event == "CrowdCountClamped" then
					table.insert(clampedEvents, entry)
				end
			end
			expect(#clampedEvents).to.equal(1)
			expect(clampedEvents[1].payload.crowdId).to.equal("101")
			expect(clampedEvents[1].payload.attemptedDelta).to.equal(5)
			expect(clampedEvents[1].payload.clampedCount).to.equal(300)
			-- Target must be non-nil: this is fireClient (local player only), NOT fireAllClients.
			expect(clampedEvents[1].target).to.be.ok()
			expect((clampedEvents[1].target :: any).UserId).to.equal(101)
		end)

		-- AC-25 per-call semantic: count=300 + delta=+1 fires CrowdCountClamped AGAIN.
		-- Same-tick repeat calls at ceiling each fire — HUD-side debounce per GDD L145.
		it("AC-25: count=300 + delta=+1 → fires AGAIN (per-call semantic; HUD debounces)", function()
			CrowdStateServer.create("101", makeRecord("101", 300))
			fanoutLog = {}
			CrowdStateServer.updateCount("101", 1, "Absorb")
			CrowdStateServer.updateCount("101", 2, "Absorb")
			local clampedCount = 0
			for _, entry in fanoutLog do
				if entry.event == "CrowdCountClamped" then
					clampedCount += 1
				end
			end
			expect(clampedCount).to.equal(2)
		end)

		-- AC-25 edge: floor clamp does NOT fire CrowdCountClamped.
		-- Lower-bound clamp is a different signal scope per GDD L145.
		it("AC-25 edge: floor clamp does NOT fire CrowdCountClamped", function()
			CrowdStateServer.create("101", makeRecord("101", 3))
			fanoutLog = {}
			CrowdStateServer.updateCount("101", -50, "Relic")  -- clamps to floor 1
			for _, entry in fanoutLog do
				expect(entry.event ~= "CrowdCountClamped").to.equal(true)
			end
		end)

		-- AC-25 edge: in-range delta does NOT fire CrowdCountClamped.
		it("AC-25 edge: in-range delta does NOT fire CrowdCountClamped", function()
			CrowdStateServer.create("101", makeRecord("101", 50))
			fanoutLog = {}
			CrowdStateServer.updateCount("101", 5, "Absorb")
			for _, entry in fanoutLog do
				expect(entry.event ~= "CrowdCountClamped").to.equal(true)
			end
		end)

		-- AC-25 routing: target is the OWNER player (non-nil → filtered per-client route).
		-- Non-nil target proves production path uses Network.fireClient, not fireAllClients.
		it("AC-25: target is the OWNER player (filtered routing, not fanout)", function()
			CrowdStateServer.create("101", makeRecord("101", 298))
			fanoutLog = {}
			CrowdStateServer.updateCount("101", 5, "Absorb")
			for _, entry in fanoutLog do
				if entry.event == "CrowdCountClamped" then
					-- Non-nil target proves this is a per-client send, not fireAllClients.
					expect(entry.target).to.be.ok()
				end
			end
		end)

		-- Owner unresolvable (player DC mid-tick): no fire, no error.
		-- Count still clamps to 300 normally — only the network fire is skipped.
		it("owner unresolvable (player DC mid-tick) → no fire, no error", function()
			-- Override resolver to return nil (simulates disconnected player)
			CrowdStateServer._setTestOwnerResolver(function(_)
				return nil
			end)
			CrowdStateServer.create("101", makeRecord("101", 298))
			fanoutLog = {}
			-- Should not error even though owner is nil
			local ok = pcall(CrowdStateServer.updateCount, "101", 5, "Absorb")
			expect(ok).to.equal(true)
			-- No CrowdCountClamped fired
			for _, entry in fanoutLog do
				expect(entry.event ~= "CrowdCountClamped").to.equal(true)
			end
			-- Count still clamped to 300 normally
			local rec = CrowdStateServer.get("101") :: CrowdStateServer.CrowdRecord
			expect(rec.count).to.equal(300)
		end)
	end)
end
