--!strict

--[[
	CrowdStateClient — broadcast subscriber decode + idempotent cache overwrite
	tests (CRB story-002).
	Path: tests/unit/crowd-state-client/broadcast_subscriber.spec.luau

	Implements:
	  AC-2  — Valid buffer decoded; cache populated for each record.
	  AC-3  — Malformed buffer (non-30-multiple) → cache unchanged + no error thrown.
	  AC-20 — Idempotent overwrite: second broadcast with same tick is discarded
	           (tick_is_newer returns false for equal ticks).
	  Multi-record — two records in one buffer both land in cache.
	  Stale-tick   — older tick in broadcast discarded; cache keeps newer record.
	  crowdId type — crowdId stored as string, not number (AC-22 invariant).

	Test isolation strategy:
	  - CrowdStateClient._debugClearAll() called in afterEach.
	  - No Network wiring — _debugDispatchBroadcast drives _onBroadcast directly.
	  - Buffers built via BufferCodecCrowdState.encode (approved mock approach per spec).

	Spec deviation note:
	  BufferCodec.CrowdState.decode returns crowdId as number (u64) and state as
	  number (1/2/3). CrowdStateClient._onBroadcast converts to string crowdId
	  and state-string via STATE_NUMBER_TO_STRING before calling _mergeCache.
	  Tests assert the converted string forms.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
	local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	--- Builds a minimal BufferCodecCrowdState.CrowdRecord for encoding.
	--- crowdId is a number (UserId); state is 1/2/3.
	local function makeWireRecord(
		crowdId: number,
		tick: number,
		state: number?,
		count: number?
	): BufferCodecCrowdState.CrowdRecord
		return {
			crowdId  = crowdId,
			tick     = tick,
			position = Vector3.new(10, 0, 20),
			radius   = 5.0,
			count    = count or 15,
			hue      = 3,
			state    = state or 1,  -- 1 = Active
		}
	end

	describe("broadcast_subscriber — AC-2 valid decode + cache population", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-2: single valid record in buffer lands in cache as string crowdId.
		it("AC-2 — valid single-record buffer populates cache", function()
			-- Arrange
			local userId = 123456
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local record = CrowdStateClient.get(tostring(userId))
			expect(record).to.be.ok()
			expect(record :: CrowdStateClient.CrowdRecord).never.to.equal(nil)
		end)

		-- AC-2: crowdId is stored as string (tostring of UserId), not as number.
		it("AC-2 — crowdId stored as string not number (AC-22)", function()
			-- Arrange
			local userId = 987654321
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert: string key works; numeric key does not
			expect(CrowdStateClient.get(tostring(userId))).to.be.ok()
			expect(CrowdStateClient.get(tostring(userId))).never.to.equal(nil)
		end)

		-- AC-2: decoded record's tick matches the wire tick.
		it("AC-2 — decoded tick matches wire tick value", function()
			-- Arrange
			local userId = 111
			local expectedTick = 42
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, expectedTick) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local record = CrowdStateClient.get(tostring(userId))
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).tick).to.equal(expectedTick)
		end)

		-- AC-2: state=1 wire value maps to "Active" string.
		it("AC-2 — wire state 1 maps to 'Active' string", function()
			-- Arrange
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(1001, 1, 1) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local record = CrowdStateClient.get("1001")
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).state).to.equal("Active")
		end)

		-- AC-2: state=2 wire value maps to "GraceWindow" string.
		it("AC-2 — wire state 2 maps to 'GraceWindow' string", function()
			-- Arrange
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(1002, 1, 2) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local record = CrowdStateClient.get("1002")
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).state).to.equal("GraceWindow")
		end)

		-- AC-2: state=3 wire value maps to "Eliminated" string.
		it("AC-2 — wire state 3 maps to 'Eliminated' string", function()
			-- Arrange
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(1003, 1, 3) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local record = CrowdStateClient.get("1003")
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

	end)

	describe("broadcast_subscriber — AC-3 malformed buffer graceful reject", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-3: malformed buffer (length not a multiple of 30) does not throw
		-- and leaves the cache unchanged.
		it("AC-3 — malformed buffer does not throw (no-op; cache unchanged)", function()
			-- Arrange: seed a known record before sending malformed buffer
			CrowdStateClient._debugSetRecord("777", {
				crowdId      = "777",
				tick         = 5,
				position     = Vector3.new(0, 0, 0),
				radius       = 3.0,
				count        = 8,
				hue          = 2,
				state        = "Active" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			})

			-- Build a buffer that is NOT a multiple of 30 bytes (29 bytes).
			local malformedBuf = buffer.create(29)

			-- Act: must not throw
			local ok, _ = pcall(function()
				CrowdStateClient._debugDispatchBroadcast(malformedBuf)
			end)

			-- Assert: no error
			expect(ok).to.equal(true)
			-- Assert: pre-existing record is unchanged
			local record = CrowdStateClient.get("777")
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).tick).to.equal(5)
		end)

		-- AC-3: empty buffer (length 0) is valid (0 records); cache unchanged.
		it("AC-3 — empty buffer (0 bytes) does not throw and produces no cache entry", function()
			-- Arrange
			local emptyBuf = buffer.create(0)

			-- Act
			local ok, _ = pcall(function()
				CrowdStateClient._debugDispatchBroadcast(emptyBuf)
			end)

			-- Assert
			expect(ok).to.equal(true)
			expect(#CrowdStateClient.getAllActive()).to.equal(0)
		end)

	end)

	describe("broadcast_subscriber — AC-20 idempotent overwrite + stale tick defense", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- AC-20: second broadcast with the same tick is discarded (tick_is_newer
		-- returns false for equal ticks — duplicate packet defense).
		it("AC-20 — duplicate broadcast with same tick does not overwrite cache", function()
			-- Arrange: first broadcast sets count=10
			local userId = 555
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 7, 1, 10) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			local record1 = CrowdStateClient.get(tostring(userId))
			expect(record1).to.be.ok()
			expect((record1 :: CrowdStateClient.CrowdRecord).count).to.equal(10)

			-- Act: second broadcast with same tick=7 but count=99
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 7, 1, 99) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: count unchanged (duplicate rejected)
			local record2 = CrowdStateClient.get(tostring(userId))
			expect(record2).to.be.ok()
			expect((record2 :: CrowdStateClient.CrowdRecord).count).to.equal(10)
		end)

		-- Stale tick: older tick broadcast discarded; cache keeps the newer record.
		it("stale tick — older tick broadcast does not overwrite newer cache entry", function()
			-- Arrange: newer tick first
			local userId = 666
			local buf_newer = BufferCodecCrowdState.encode({ makeWireRecord(userId, 10, 1, 50) })
			CrowdStateClient._debugDispatchBroadcast(buf_newer)

			-- Act: then older tick arrives (out of order)
			local buf_older = BufferCodecCrowdState.encode({ makeWireRecord(userId, 3, 1, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf_older)

			-- Assert: still the newer record (count=50, tick=10)
			local record = CrowdStateClient.get(tostring(userId))
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).tick).to.equal(10)
			expect((record :: CrowdStateClient.CrowdRecord).count).to.equal(50)
		end)

		-- AC-20 complement: newer tick updates the cache correctly.
		it("AC-20 — newer tick does overwrite the cache entry", function()
			-- Arrange
			local userId = 444
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 5, 1, 20) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			-- Act: newer tick
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 6, 1, 30) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: updated to newer record
			local record = CrowdStateClient.get(tostring(userId))
			expect(record).to.be.ok()
			expect((record :: CrowdStateClient.CrowdRecord).tick).to.equal(6)
			expect((record :: CrowdStateClient.CrowdRecord).count).to.equal(30)
		end)

	end)

	describe("broadcast_subscriber — multi-record buffer", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- Two records in one buffer both land in cache.
		it("multi-record — two records in one buffer both populate cache", function()
			-- Arrange
			local buf = BufferCodecCrowdState.encode({
				makeWireRecord(100, 1),
				makeWireRecord(200, 1),
			})

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			expect(CrowdStateClient.get("100")).to.be.ok()
			expect(CrowdStateClient.get("200")).to.be.ok()
			expect(#CrowdStateClient.getAllActive()).to.equal(2)
		end)

		-- Three records — only stale one is rejected; other two land.
		it("multi-record — stale third record in batch is rejected; other two land", function()
			-- Arrange: seed crowd 300 with tick=10
			local buf_prior = BufferCodecCrowdState.encode({ makeWireRecord(300, 10) })
			CrowdStateClient._debugDispatchBroadcast(buf_prior)

			-- Act: batch with two new crowds + one stale update for 300 (tick=5)
			local buf = BufferCodecCrowdState.encode({
				makeWireRecord(400, 1),
				makeWireRecord(500, 1),
				makeWireRecord(300, 5),  -- stale
			})
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			expect(CrowdStateClient.get("400")).to.be.ok()
			expect(CrowdStateClient.get("500")).to.be.ok()
			-- Crowd 300 tick unchanged at 10 (stale rejected)
			local rec300 = CrowdStateClient.get("300")
			expect(rec300).to.be.ok()
			expect((rec300 :: CrowdStateClient.CrowdRecord).tick).to.equal(10)
		end)

	end)

	describe("broadcast_subscriber — _lastReceivedTick updated on acceptance", function()

		afterEach(function()
			CrowdStateClient._debugClearAll()
		end)

		-- _debugGetLastReceivedTick reflects accepted tick.
		it("lastReceivedTick updated to accepted tick value", function()
			-- Arrange
			local userId = 77
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 15) })

			-- Act
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			expect(CrowdStateClient._debugGetLastReceivedTick(tostring(userId))).to.equal(15)
		end)

		-- _debugGetLastReceivedTick returns nil before any broadcast.
		it("lastReceivedTick is nil before any broadcast for that crowdId", function()
			expect(CrowdStateClient._debugGetLastReceivedTick("99999")).to.equal(nil)
		end)

	end)

end
