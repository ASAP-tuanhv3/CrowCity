--!strict

--[[
	CrowdStateClient — Eliminated terminal state rule tests (CRB story-002 AC-11).
	Path: tests/unit/crowd-state-client/eliminated_terminal.spec.luau

	Implements:
	  AC-11 — Eliminated state is sticky (terminal):
	    - Once state = "Eliminated" in cache, subsequent broadcasts asserting
	      Active or GraceWindow do NOT revert the state field.
	    - Other fields (count, position, radius, hue, tick) still update on a
	      newer tick from broadcast.
	  AC-11 complement — Eliminated → Eliminated broadcast is accepted (same state).
	  Story-003 interaction — CrowdEliminated reliable handler ALSO sets terminal;
	    this is tested via _debugDispatchReliable (story-003 handler).

	Test isolation strategy:
	  - CrowdStateClient._debugClearAll() + _resetForTests() in afterEach.
	  - Buffers built via BufferCodecCrowdState.encode.
	  - Clock is os.clock default (stale not exercised here).
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
	local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	local function makeWireRecord(
		crowdId: number,
		tick: number,
		state: number,
		count: number?
	): BufferCodecCrowdState.CrowdRecord
		return {
			crowdId  = crowdId,
			tick     = tick,
			position = Vector3.new(5, 0, 5),
			radius   = 4.0,
			count    = count or 10,
			hue      = 1,
			state    = state,
		}
	end

	describe("Eliminated terminal rule (AC-11)", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-11: broadcast with state=Eliminated sets terminal; later broadcast
		-- with state=Active (newer tick) does NOT revert the state field.
		it("AC-11 — Eliminated from broadcast; later Active broadcast keeps Eliminated state", function()
			-- Arrange: first broadcast → Eliminated (tick=5, state=3)
			local userId = 1111
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 5, 3) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			local rec = CrowdStateClient.get(tostring(userId))
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")

			-- Act: later broadcast with Active state (tick=6) — newer tick
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 6, 1, 20) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: state remains Eliminated (terminal rule)
			local rec2 = CrowdStateClient.get(tostring(userId))
			expect(rec2).to.be.ok()
			expect((rec2 :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

		-- AC-11: non-state fields (count, tick) still update on newer tick even when
		-- state is sticky at Eliminated.
		it("AC-11 — non-state fields update on newer tick despite Eliminated sticky state", function()
			-- Arrange: first broadcast → Eliminated (tick=5, count=10)
			local userId = 2222
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 5, 3, 10) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			-- Act: newer tick broadcast with Active state + count=99
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 6, 1, 99) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert
			local rec = CrowdStateClient.get(tostring(userId))
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")  -- sticky
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(99)            -- updated
			expect((rec :: CrowdStateClient.CrowdRecord).tick).to.equal(6)              -- updated
		end)

		-- AC-11: GraceWindow broadcast after Eliminated is also blocked (not just Active).
		it("AC-11 — GraceWindow broadcast after Eliminated also keeps Eliminated state", function()
			-- Arrange: Eliminated first (tick=3, state=3)
			local userId = 3333
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 3, 3) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			-- Act: GraceWindow broadcast (tick=4, state=2)
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 4, 2) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: still Eliminated
			local rec = CrowdStateClient.get(tostring(userId))
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

		-- AC-11 complement: Eliminated → Eliminated broadcast is accepted normally.
		it("AC-11 — Eliminated → Eliminated broadcast accepted; state remains Eliminated", function()
			-- Arrange
			local userId = 4444
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 2, 3, 5) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			-- Act: another Eliminated broadcast with newer tick
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 3, 3, 0) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: state Eliminated; tick advanced; count updated
			local rec = CrowdStateClient.get(tostring(userId))
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
			expect((rec :: CrowdStateClient.CrowdRecord).tick).to.equal(3)
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(0)
		end)

		-- Eliminated set via reliable handler is also terminal for broadcasts.
		it("AC-11 — Eliminated set by reliable CrowdEliminated handler is terminal for broadcasts", function()
			-- Arrange: seed an Active record via _debugSetRecord
			local crowdId = "5555"
			CrowdStateClient._debugSetRecord(crowdId, {
				crowdId      = crowdId,
				tick         = 10,
				position     = Vector3.new(0, 0, 0),
				radius       = 3.0,
				count        = 20,
				hue          = 5,
				state        = "Active" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			})

			-- Act: reliable CrowdEliminated handler sets terminal
			CrowdStateClient._debugDispatchReliable("CrowdEliminated", { crowdId = crowdId })

			-- Verify state is now Eliminated
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")

			-- Act: subsequent broadcast with Active (newer tick than 10)
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(5555, 11, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert: still Eliminated
			local rec2 = CrowdStateClient.get("5555")
			expect(rec2).to.be.ok()
			expect((rec2 :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

		-- Fresh crowd (no prior record) with Eliminated broadcast is set directly.
		it("AC-11 — first-ever broadcast with Eliminated state sets Eliminated directly", function()
			-- Arrange: no prior record for this crowd
			local userId = 6666

			-- Act
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1, 3) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local rec = CrowdStateClient.get(tostring(userId))
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

	end)

end
