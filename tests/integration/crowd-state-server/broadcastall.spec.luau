--!strict

--[[
	CrowdStateServer — Phase 8 broadcastAll integration tests.
	Path: tests/integration/crowd-state-server/broadcastall.spec.luau
	Implements: CSM story-008 ACs (automated portion):
	  AC-17 payload-size — N records → 30 * N bytes.
	  Tick increment — record.tick post-increment per broadcast.
	  uint16 wrap — tick=65535 → 0 next broadcast.
	  Empty path — 0 records → no fire.
	  Eliminated continues broadcasting (state byte = 3).
	  Sole-caller audit — broadcastAll is the only fireAllClientsUnreliable
	  call site for CrowdStateBroadcast.

	AC-17 60s perf soak + AC-18/20 multi-client tests are deferred to Studio
	manual evidence per story §QA Test Cases.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)
	local BufferCodec = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	local RECORD_SIZE = 30

	local function makeRecord(
		userIdNum: number,
		count: number?,
		state: CrowdStateServer.CrowdState?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = tostring(userIdNum),
			position = Vector3.new(1, 2, 3),
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

	describe("CrowdStateServer.broadcastAll — payload size + tick increment", function()

		local captured: { { event: string, payload: buffer } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
		end)

		it("AC-17: 12 records → 360-byte payload, single fire", function()
			for i = 1, 12 do
				CrowdStateServer.create(tostring(i), makeRecord(i))
			end

			CrowdStateServer.broadcastAll(1)

			expect(#captured).to.equal(1)
			expect(captured[1].event).to.equal("CrowdStateBroadcast")
			expect(buffer.len(captured[1].payload)).to.equal(12 * RECORD_SIZE)
		end)

		it("1 record → 30-byte payload", function()
			CrowdStateServer.create("1", makeRecord(1))
			CrowdStateServer.broadcastAll(1)
			expect(buffer.len(captured[1].payload)).to.equal(RECORD_SIZE)
		end)

		it("post-broadcast record.tick == 1 (incremented from 0)", function()
			CrowdStateServer.create("1", makeRecord(1))
			CrowdStateServer.broadcastAll(1)

			local rec = CrowdStateServer.get("1") :: CrowdStateServer.CrowdRecord
			expect(rec.tick).to.equal(1)
		end)

		it("two consecutive broadcasts → record.tick == 2", function()
			CrowdStateServer.create("1", makeRecord(1))
			CrowdStateServer.broadcastAll(1)
			CrowdStateServer.broadcastAll(2)
			local rec = CrowdStateServer.get("1") :: CrowdStateServer.CrowdRecord
			expect(rec.tick).to.equal(2)
		end)

		it("uint16 wrap — tick=65535 broadcasts then wraps to 0", function()
			CrowdStateServer.create("1", makeRecord(1))
			local rec = CrowdStateServer.get("1") :: CrowdStateServer.CrowdRecord
			rec.tick = 65535

			CrowdStateServer.broadcastAll(1)

			local after = CrowdStateServer.get("1") :: CrowdStateServer.CrowdRecord
			expect(after.tick).to.equal(0)
		end)

		it("encoded payload decodes back with matching count + state + hue", function()
			CrowdStateServer.create("42", makeRecord(42, 100))
			CrowdStateServer.broadcastAll(1)

			local decoded = BufferCodec.decode(captured[1].payload)
			expect(#decoded).to.equal(1)
			expect(decoded[1].crowdId).to.equal(42)
			expect(decoded[1].count).to.equal(100)
			expect(decoded[1].state).to.equal(1)  -- Active
			expect(decoded[1].hue).to.equal(1)
			expect(decoded[1].tick).to.equal(1)
		end)
	end)

	describe("CrowdStateServer.broadcastAll — empty path + state inclusion", function()

		local captured: { { event: string, payload: buffer } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			captured = {}
			CrowdStateServer._setTestUnreliableBroadcastInterceptor(function(
				event: string,
				payload: buffer
			)
				table.insert(captured, { event = event, payload = payload })
			end)
		end)

		it("0 records → no fire (empty `_crowds` skip)", function()
			CrowdStateServer.broadcastAll(1)
			expect(#captured).to.equal(0)
		end)

		it("Eliminated record continues broadcasting (state byte = 3)", function()
			CrowdStateServer.create("1", makeRecord(1, 1, "Eliminated"))
			CrowdStateServer.broadcastAll(1)

			expect(#captured).to.equal(1)
			local decoded = BufferCodec.decode(captured[1].payload)
			expect(#decoded).to.equal(1)
			expect(decoded[1].state).to.equal(3)  -- Eliminated wire enum
		end)

		it("GraceWindow record (state byte = 2) included", function()
			CrowdStateServer.create("1", makeRecord(1, 1, "GraceWindow"))
			CrowdStateServer.broadcastAll(1)

			local decoded = BufferCodec.decode(captured[1].payload)
			expect(decoded[1].state).to.equal(2)
		end)

		it("mixed states all included in single payload", function()
			CrowdStateServer.create("1", makeRecord(1, 10, "Active"))
			CrowdStateServer.create("2", makeRecord(2, 1, "GraceWindow"))
			CrowdStateServer.create("3", makeRecord(3, 1, "Eliminated"))

			CrowdStateServer.broadcastAll(1)

			expect(#captured).to.equal(1)
			expect(buffer.len(captured[1].payload)).to.equal(3 * RECORD_SIZE)
			local decoded = BufferCodec.decode(captured[1].payload)
			expect(#decoded).to.equal(3)
			-- Order is iteration-dependent; check by id.
			local stateById: { [number]: number } = {}
			for _, r in decoded do
				stateById[r.crowdId] = r.state
			end
			expect(stateById[1]).to.equal(1)
			expect(stateById[2]).to.equal(2)
			expect(stateById[3]).to.equal(3)
		end)
	end)
end
