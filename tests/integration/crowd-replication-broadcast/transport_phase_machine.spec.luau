--!strict

--[[
	Crowd Replication Broadcast — story-004 transport phase machine integration test.
	Path: tests/integration/crowd-replication-broadcast/transport_phase_machine.spec.luau
	Implements: CRB story-004 ACs:
	  AC-8  Dormant → Active emergence — RL.createAll([A, B]) → next CSM.broadcastAll
	        fires 60-byte payload (2 records).
	  AC-9  Eliminated continues broadcasting — C drops to Eliminated via Phase 5
	        real pipeline (Active→GraceWindow→Eliminated); broadcast keeps including
	        C with state=3 (Eliminated), count=1 across 5 subsequent ticks.
	  AC-10 Closing → Dormant emergence — RL.destroyAll → next CSM.broadcastAll fires
	        no packet (empty _crowds skip per CSM story-008 AC). No Lua error.

	Composition under test: RoundLifecycle.createAll/destroyAll → CSM.create/destroy →
	CSM.broadcastAll. Real CSM used throughout (no _setCSMOverride). The "transport
	phase machine" is implicit — emerges from round-lifecycle boundaries; no separate
	state field (story-004 implementation note).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)
	local BufferCodec = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	local RECORD_SIZE = 30
	local GRACE_WINDOW_SEC = 3.0
	-- CROWD_START_COUNT = 10 per RoundLifecycle/init.luau:49; C count=1 means
	-- delta = 1 - 10 = -9 applied via updateCount.
	local CROWD_START_COUNT = 10

	local function makePlayer(userId: number): Player
		return ({ UserId = userId } :: any) :: Player
	end

	-- -------------------------------------------------------------------------
	-- AC-8: Dormant → Active on RL.createAll
	-- -------------------------------------------------------------------------

	describe("transport phase: Dormant → Active on RL.createAll", function()
		local captured: { { event: string, payload: buffer } }

		beforeEach(function()
			-- Order: RL first (clears _janitor + aux _crowds), then CSM.
			RoundLifecycle._resetForTests()
			CrowdStateServer._resetForTests()
			-- Real CSM path: do NOT call RoundLifecycle._setCSMOverride.
			-- Suppress reliable fanout (CrowdCountClamped, CrowdEliminated) — not
			-- under test here; avoids Network.fireAllClients in headless context.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
		end)

		it("AC-8: Lobby broadcastAll fires nothing; after createAll([A,B]) next broadcastAll fires 60-byte payload", function()
			-- Arrange: Dormant — no _crowds yet (Lobby/pre-round state).
			CrowdStateServer.broadcastAll(1)
			-- Assert Dormant: empty _crowds → no fire (CSM story-008 skip-path).
			expect(#captured).to.equal(0)

			-- Act: round-start boundary — createAll populates CSM _crowds.
			RoundLifecycle.createAll({ makePlayer(101), makePlayer(102) })
			CrowdStateServer.broadcastAll(2)

			-- Assert Active: 1 packet, 2 records × 30 B = 60 bytes.
			expect(#captured).to.equal(1)
			expect(captured[1].event).to.equal("CrowdStateBroadcast")
			expect(buffer.len(captured[1].payload)).to.equal(2 * RECORD_SIZE)
			local decoded = BufferCodec.decode(captured[1].payload)
			expect(#decoded).to.equal(2)
		end)

		it("AC-8 sanity: both player crowdIds present in decoded payload", function()
			-- Arrange + Act
			RoundLifecycle.createAll({ makePlayer(201), makePlayer(202) })
			CrowdStateServer.broadcastAll(1)

			-- Assert: both crowdIds decode correctly as numeric u64.
			expect(#captured).to.equal(1)
			local decoded = BufferCodec.decode(captured[1].payload)
			local idSet: { [number]: boolean } = {}
			for _, rec in decoded do
				idSet[rec.crowdId] = true
			end
			expect(idSet[201]).to.equal(true)
			expect(idSet[202]).to.equal(true)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC-9: Eliminated continues broadcasting (Rule 13)
	-- -------------------------------------------------------------------------

	describe("transport phase: Eliminated continues broadcasting (Rule 13 / TR-crs-013)", function()
		local captured: { { event: string, payload: buffer } }

		beforeEach(function()
			RoundLifecycle._resetForTests()
			CrowdStateServer._resetForTests()
			-- Real CSM path — no _setCSMOverride.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
		end)

		it("AC-9: C eliminated via Phase 5 real pipeline → 5 subsequent broadcasts include C with state=3, count=1", function()
			-- Arrange: 3-player Active round; C has crowdId "103".
			RoundLifecycle.createAll({
				makePlayer(101),
				makePlayer(102),
				makePlayer(103),
			})

			-- Force C count to 1 via real updateCount (delta = 1 - CROWD_START_COUNT).
			-- updateCount asserts record present — createAll must succeed first.
			CrowdStateServer.updateCount("103", 1 - CROWD_START_COUNT, "Absorb")

			-- Set stillOverlapping=true on C — meets Active→GraceWindow condition
			-- (count==1 AND stillOverlapping per stateEvaluate Phase 5 logic).
			CrowdStateServer.setStillOverlapping("103", true)

			-- Phase 5 tick 1: Active → GraceWindow for C.
			-- (A and B remain Active: count=10, stillOverlapping=false.)
			CrowdStateServer.stateEvaluate(1)

			local recC = CrowdStateServer.get("103") :: CrowdStateServer.CrowdRecord
			expect(recC.state).to.equal("GraceWindow")
			-- stillOverlapping is still true (stateEvaluate does not reset it;
			-- CollisionResolver is the sole writer). Needed for Eliminated path.
			expect(recC.stillOverlapping).to.equal(true)

			-- Deterministic time-warp: shift timer_start back past GRACE_WINDOW_SEC
			-- so the next stateEvaluate sees elapsed >= 3.0. Avoids real-time waits
			-- per test-standards.md (no task.wait / os.clock polling).
			recC.timer_start = (recC.timer_start :: number) - (GRACE_WINDOW_SEC + 0.5)

			-- Phase 5 tick 2: GraceWindow → Eliminated for C.
			CrowdStateServer.stateEvaluate(2)

			expect(recC.state).to.equal("Eliminated")
			expect(recC.count).to.equal(1)

			-- Reset capture to isolate only the 5 subsequent broadcast ticks.
			-- Re-register interceptor; the prior closure captured the old
			-- `captured` table reference and cannot be redirected by reassignment.
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)

			-- Act: 5 subsequent broadcast ticks (Rule 13: Eliminated broadcasts
			-- until destroyAll — no early removal from _crowds).
			for tick = 3, 7 do
				CrowdStateServer.broadcastAll(tick)
			end

			-- Assert: exactly 5 packets fired.
			expect(#captured).to.equal(5)

			for _, packet in captured do
				-- Each payload must contain all 3 crowds (A, B, C — C is Eliminated
				-- but still in _crowds per CSM story-008 broadcastAll AC).
				local decoded = BufferCodec.decode(packet.payload)
				expect(#decoded).to.equal(3)

				-- Find C's record by numeric crowdId (u64 wire encoding;
				-- string "103" → decoded number 103 per BufferCodec.decode).
				local foundC = false
				for _, rec in decoded do
					if rec.crowdId == 103 then
						foundC = true
						expect(rec.state).to.equal(3) -- Eliminated wire enum
						expect(rec.count).to.equal(1)
					end
				end
				expect(foundC).to.equal(true)
			end
		end)

		it("AC-9 sanity: A and B remain Active (state=1) across all 5 ticks", function()
			-- Arrange: same Eliminated-C setup.
			RoundLifecycle.createAll({
				makePlayer(101),
				makePlayer(102),
				makePlayer(103),
			})
			CrowdStateServer.updateCount("103", 1 - CROWD_START_COUNT, "Absorb")
			CrowdStateServer.setStillOverlapping("103", true)
			CrowdStateServer.stateEvaluate(1)
			local recC = CrowdStateServer.get("103") :: CrowdStateServer.CrowdRecord
			recC.timer_start = (recC.timer_start :: number) - (GRACE_WINDOW_SEC + 0.5)
			CrowdStateServer.stateEvaluate(2)

			-- Capture only broadcast ticks 3..7.
			-- Re-register interceptor; the prior closure captured the old
			-- `captured` table reference and cannot be redirected by reassignment.
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
			for tick = 3, 7 do
				CrowdStateServer.broadcastAll(tick)
			end

			-- Assert: A (101) and B (102) hold state=1 (Active) in every packet.
			for _, packet in captured do
				local decoded = BufferCodec.decode(packet.payload)
				for _, rec in decoded do
					if rec.crowdId == 101 or rec.crowdId == 102 then
						expect(rec.state).to.equal(1) -- Active wire enum
					end
				end
			end
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC-10: Closing → Dormant on RL.destroyAll
	-- -------------------------------------------------------------------------

	describe("transport phase: Closing → Dormant on RL.destroyAll", function()
		local captured: { { event: string, payload: buffer } }

		beforeEach(function()
			RoundLifecycle._resetForTests()
			CrowdStateServer._resetForTests()
			-- Real CSM path — no _setCSMOverride.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
		end)

		it("AC-10: 3 crowds Active → destroyAll → next broadcastAll fires no packet, no error", function()
			-- Arrange: Active round with 3 crowds.
			RoundLifecycle.createAll({
				makePlayer(101),
				makePlayer(102),
				makePlayer(103),
			})
			CrowdStateServer.broadcastAll(1)
			-- Sanity: pre-destroy packet fires with 3 records (90 bytes).
			expect(#captured).to.equal(1)
			expect(buffer.len(captured[1].payload)).to.equal(3 * RECORD_SIZE)

			-- Act: round-end boundary — destroyAll calls CSM.destroy per crowd.
			RoundLifecycle.destroyAll()

			local capturedBefore = #captured
			local ok = pcall(function()
				CrowdStateServer.broadcastAll(2)
			end)

			-- Assert: no Lua error.
			expect(ok).to.equal(true)
			-- Assert: no additional packet fired (empty _crowds → skip per CSM
			-- story-008 AC: "if next(_crowds) == nil then return end" path).
			expect(#captured).to.equal(capturedBefore)
		end)

		it("AC-10 idempotency: second destroyAll + broadcastAll still no packet, no error", function()
			-- Arrange: round created then destroyed.
			RoundLifecycle.createAll({ makePlayer(101) })
			RoundLifecycle.destroyAll()

			-- Act: second destroyAll (idempotent per RL contract) + broadcast.
			local ok = pcall(function()
				RoundLifecycle.destroyAll()
				CrowdStateServer.broadcastAll(1)
			end)

			-- Assert: no error; captured still empty (never had any crowd records).
			expect(ok).to.equal(true)
			expect(#captured).to.equal(0)
		end)

		it("AC-10 empty-start: destroyAll on empty state + broadcastAll fires nothing, no error", function()
			-- Arrange: no createAll at all — pure Dormant state.
			local ok = pcall(function()
				RoundLifecycle.destroyAll()
				CrowdStateServer.broadcastAll(1)
			end)

			expect(ok).to.equal(true)
			expect(#captured).to.equal(0)
		end)
	end)
end
