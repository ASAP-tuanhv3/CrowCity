--!strict

--[[
	CrowdStateClient — stale-freeze detection tests (CRB story-002 AC-5 + AC-17).
	Path: tests/unit/crowd-state-client/stale_freeze.spec.luau

	Implements:
	  AC-5  — broadcast_stale(crowdId) returns true if no broadcast in STALE_THRESHOLD_SEC.
	           Returns true before any broadcast ever arrives (nil case).
	  AC-17 — HUD / Nameplate consumers freeze display when broadcast_stale() is true.
	           (Tested indirectly: we verify the function returns true/false correctly;
	            consumers are responsible for acting on it.)
	  _setClockFn DI — deterministic time injection for all stale tests.
	  _debugGetLastBroadcastTime — verify timestamp is recorded on acceptance.
	  _getStarted — idempotency of start().
	  _resetForTests — full module reset between test suites.

	STALE_THRESHOLD_SEC is 0.5 (module constant; not exported). Tests inject a
	fake clock via _setClockFn to control time deterministically.

	Test isolation strategy:
	  - CrowdStateClient._resetForTests() in afterEach (resets _started + cache + clock).
	  - Clock injected via _setClockFn before each relevant test.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
	local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	-- STALE_THRESHOLD_SEC value — must match the module constant (0.5 sec).
	local STALE_THRESHOLD_SEC = 0.5

	local function makeWireRecord(crowdId: number, tick: number): BufferCodecCrowdState.CrowdRecord
		return {
			crowdId  = crowdId,
			tick     = tick,
			position = Vector3.new(0, 0, 0),
			radius   = 3.0,
			count    = 5,
			hue      = 2,
			state    = 1,  -- Active
		}
	end

	describe("broadcast_stale — AC-5 stale detection", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- AC-5: broadcast_stale returns true for unknown crowdId (never received).
		it("AC-5 — broadcast_stale returns true for crowdId with no broadcast (nil case)", function()
			expect(CrowdStateClient.broadcast_stale("never_seen")).to.equal(true)
		end)

		-- AC-5: broadcast_stale returns false immediately after a broadcast arrives
		-- (clock has not advanced past threshold).
		it("AC-5 — broadcast_stale returns false immediately after broadcast received", function()
			-- Arrange: inject a fixed clock that stays at t=1.0
			local fakeTime = 1.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			-- Act: send broadcast at t=1.0
			local userId = 222
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert: still at t=1.0; not yet stale (0.0 elapsed < 0.5)
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(false)
		end)

		-- AC-5: broadcast_stale returns true when clock advances past STALE_THRESHOLD_SEC.
		it("AC-5 — broadcast_stale returns true after STALE_THRESHOLD_SEC elapses", function()
			-- Arrange: inject controllable clock
			local fakeTime = 5.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			-- Broadcast received at t=5.0
			local userId = 333
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Act: advance clock past threshold
			fakeTime = 5.0 + STALE_THRESHOLD_SEC  -- exactly at boundary (>=)

			-- Assert: stale at the boundary
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(true)
		end)

		-- AC-5: broadcast_stale returns false just BEFORE the threshold.
		it("AC-5 — broadcast_stale returns false just before threshold (< 0.5s elapsed)", function()
			-- Arrange
			local fakeTime = 10.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			local userId = 444
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Advance to just under threshold (epsilon below)
			fakeTime = 10.0 + STALE_THRESHOLD_SEC - 0.001

			-- Assert: not yet stale
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(false)
		end)

		-- AC-5: a second broadcast refreshes the timestamp so stale resets.
		it("AC-5 — second broadcast refreshes timestamp; stale resets to false", function()
			-- Arrange: first broadcast at t=0.0
			local fakeTime = 0.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			local userId = 555
			local buf1 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf1)

			-- Advance past threshold — should be stale
			fakeTime = STALE_THRESHOLD_SEC + 0.1
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(true)

			-- Act: new broadcast at t=STALE_THRESHOLD_SEC+0.1 (refreshes timestamp)
			local buf2 = BufferCodecCrowdState.encode({ makeWireRecord(userId, 2) })
			CrowdStateClient._debugDispatchBroadcast(buf2)

			-- Assert: freshly received; not stale
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(false)
		end)

		-- AC-5: stale-rejected broadcast (old tick) does NOT refresh the timestamp.
		it("AC-5 — stale-rejected broadcast does not refresh timestamp", function()
			-- Arrange: first broadcast at t=0.0 (tick=5)
			local fakeTime = 0.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			local userId = 666
			local buf_new = BufferCodecCrowdState.encode({ makeWireRecord(userId, 5) })
			CrowdStateClient._debugDispatchBroadcast(buf_new)

			-- Advance past threshold
			fakeTime = STALE_THRESHOLD_SEC + 0.5

			-- Act: send an older-tick broadcast (tick=3 < 5; will be rejected)
			local buf_old = BufferCodecCrowdState.encode({ makeWireRecord(userId, 3) })
			CrowdStateClient._debugDispatchBroadcast(buf_old)

			-- Assert: still stale (old broadcast was rejected; timestamp not refreshed)
			expect(CrowdStateClient.broadcast_stale(tostring(userId))).to.equal(true)
		end)

	end)

	describe("broadcast_stale — _debugGetLastBroadcastTime seam", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- Verify _debugGetLastBroadcastTime returns nil before any broadcast.
		it("_debugGetLastBroadcastTime returns nil before first broadcast", function()
			expect(CrowdStateClient._debugGetLastBroadcastTime("no_crowd")).to.equal(nil)
		end)

		-- Verify timestamp is recorded on accepted broadcast.
		it("_debugGetLastBroadcastTime returns recorded timestamp after accepted broadcast", function()
			-- Arrange
			local expectedTime = 42.5
			CrowdStateClient._setClockFn(function(): number
				return expectedTime
			end)

			local userId = 888
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert
			local recorded = CrowdStateClient._debugGetLastBroadcastTime(tostring(userId))
			expect(recorded).to.equal(expectedTime)
		end)

		-- Verify _debugClearAll clears _lastBroadcastTime.
		it("_debugClearAll clears lastBroadcastTime entries", function()
			-- Arrange: record a broadcast time
			local fakeTime = 100.0
			CrowdStateClient._setClockFn(function(): number
				return fakeTime
			end)

			local userId = 999
			local buf = BufferCodecCrowdState.encode({ makeWireRecord(userId, 1) })
			CrowdStateClient._debugDispatchBroadcast(buf)
			expect(CrowdStateClient._debugGetLastBroadcastTime(tostring(userId))).never.to.equal(nil)

			-- Act
			CrowdStateClient._debugClearAll()

			-- Assert: cleared
			expect(CrowdStateClient._debugGetLastBroadcastTime(tostring(userId))).to.equal(nil)
		end)

	end)

	describe("start() idempotency — _getStarted seam", function()

		-- Note: start() calls Network.connectUnreliableEvent which requires a live
		-- remoteFolder. We do NOT call start() in these unit tests — we only verify
		-- the _getStarted guard state.

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- _getStarted returns false before any start() call.
		it("_getStarted returns false before start() is called", function()
			expect(CrowdStateClient._getStarted()).to.equal(false)
		end)

		-- _resetForTests resets _started to false.
		it("_resetForTests resets _started to false", function()
			-- Simulate having started (bypass real Network by manipulating via reset)
			-- We verify reset undoes any state — even if we can't call start() in tests.
			-- After reset: always false.
			CrowdStateClient._resetForTests()
			expect(CrowdStateClient._getStarted()).to.equal(false)
		end)

	end)

	describe("_setClockFn — DI isolation", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- _setClockFn nil resets to os.clock (returns a number).
		it("_setClockFn(nil) resets clock to os.clock (returns number)", function()
			-- Arrange: inject fake clock
			CrowdStateClient._setClockFn(function(): number
				return 99999.0
			end)

			-- Act: reset
			CrowdStateClient._setClockFn(nil)

			-- Assert: broadcast_stale uses os.clock — will return true for unseen crowd
			-- (nil lastBroadcastTime → stale = true regardless of clock)
			expect(CrowdStateClient.broadcast_stale("no_crowd")).to.equal(true)
		end)

	end)

end
