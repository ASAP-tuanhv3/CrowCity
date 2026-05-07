--!strict

--[[
	CrowdStateClient — reliable subscriber handler tests (CRB story-003).
	Path: tests/unit/crowd-state-client/reliable_subscribers.spec.luau

	Implements:
	  CrowdCreated handler (AC-19):
	    - AC-19a: no prior cache entry → partial-record init with initialCount + hue.
	    - AC-19b: broadcast pre-populated → merge hue; initialCount fills 0-count only.
	    - CrowdCreated BindableEvent fires with correct crowdId.
	  CrowdDestroyed handler:
	    - Cache entry removed.
	    - _lastReceivedTick + _lastBroadcastTime cleared (re-creation accepts tick=0).
	    - CrowdDestroyed BindableEvent fires.
	    - Late-reliable after destroy: second destroy is graceful no-op (entry already nil).
	  CrowdEliminated handler:
	    - Cache entry state set to "Eliminated" (terminal).
	    - CrowdEliminated BindableEvent fires.
	    - Late-reliable: no cache entry → no error (graceful no-op).
	  CrowdCountClamped handler:
	    - Does NOT mutate cache (HUD-only signal).
	    - CrowdCountClamped BindableEvent fires with crowdId + payload.
	  CrowdRelicChanged handler:
	    - activeRelics replaced with server snapshot.
	    - CrowdRelicChanged BindableEvent fires with crowdId + relics array.
	    - Late-reliable: no cache entry → no error.
	  AC-13 cross-channel ordering:
	    - Reliable CrowdCreated then broadcast arrives: merged correctly.
	    - Broadcast first then reliable CrowdCreated: hue/count merged.

	Test isolation strategy:
	  - CrowdStateClient._resetForTests() in afterEach.
	  - _debugDispatchReliable drives handlers directly (no live Network).
	  - BindableEvent signals verified via .Event:Connect + counter.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
	local BufferCodecCrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	--- Constructs a minimal CrowdRecord for seeding via _debugSetRecord.
	local function makeCacheRecord(
		crowdId: string,
		tick: number,
		state: ("Active" | "GraceWindow" | "Eliminated")?
	): CrowdStateClient.CrowdRecord
		return {
			crowdId      = crowdId,
			tick         = tick,
			position     = Vector3.new(0, 0, 0),
			radius       = 3.0,
			count        = 10,
			hue          = 2,
			state        = state or "Active",
			activeRelics = {} :: { string },
		}
	end

	--- Connects to a BindableEvent and returns a counter + cleanup function.
	--- counter() returns the number of times the event fired.
	local function connectCounter(event: BindableEvent): (() -> number, () -> ())
		local count = 0
		local conn = event.Event:Connect(function(...)
			count += 1
		end)
		return function(): number
			return count
		end, function(): ()
			conn:Disconnect()
		end
	end

	-- =========================================================================
	-- CrowdCreated handler
	-- =========================================================================

	describe("CrowdCreated handler — AC-19 partial-record init", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- AC-19a: no prior cache entry → record created with initialCount + hue.
		it("AC-19a — no prior cache: record created with initialCount and hue", function()
			-- Arrange
			local crowdId = "111"

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = crowdId,
				hue          = 7,
				initialCount = 50,
			})

			-- Assert
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).hue).to.equal(7)
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(50)
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Active")
		end)

		-- AC-19a: crowdId is normalized to string (tostring of payload.crowdId).
		it("AC-19a — crowdId coerced to string (numeric payload.crowdId)", function()
			-- Arrange: numeric crowdId in payload (as server sends)
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = 222,
				hue          = 3,
				initialCount = 5,
			})

			-- Assert: reachable via string key
			expect(CrowdStateClient.get("222")).to.be.ok()
		end)

		-- AC-19b: broadcast pre-populated before reliable arrives → hue merged;
		-- initialCount fills 0-count case only (count already > 0 → not overwritten).
		it("AC-19b — broadcast pre-populated: hue merged; initialCount only fills 0-count", function()
			-- Arrange: seed a record that broadcast would have produced
			local crowdId = "333"
			CrowdStateClient._debugSetRecord(crowdId, {
				crowdId      = crowdId,
				tick         = 3,
				position     = Vector3.new(1, 0, 1),
				radius       = 4.0,
				count        = 25,   -- already > 0
				hue          = 0,    -- stale hue; will be overwritten by reliable
				state        = "Active" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			})

			-- Act: reliable CrowdCreated arrives with authoritative hue
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = crowdId,
				hue          = 9,
				initialCount = 100,  -- not applied since existing.count > 0
			})

			-- Assert: hue updated; count unchanged (was > 0)
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).hue).to.equal(9)   -- updated
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(25)  -- unchanged
		end)

		-- AC-19b complement: initialCount fills when existing.count == 0.
		it("AC-19b — initialCount fills count when existing cache count is 0", function()
			-- Arrange: seed record with count=0 (broadcast arrived before count was known)
			local crowdId = "444"
			CrowdStateClient._debugSetRecord(crowdId, {
				crowdId      = crowdId,
				tick         = 1,
				position     = Vector3.new(0, 0, 0),
				radius       = 2.0,
				count        = 0,
				hue          = 0,
				state        = "Active" :: "Active" | "GraceWindow" | "Eliminated",
				activeRelics = {} :: { string },
			})

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = crowdId,
				hue          = 5,
				initialCount = 60,
			})

			-- Assert: count filled from initialCount
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(60)
		end)

		-- CrowdCreated fires the BindableEvent with the correct crowdId.
		it("CrowdCreated BindableEvent fires with correct crowdId string", function()
			-- Arrange
			local fired: string? = nil
			local conn = CrowdStateClient.CrowdCreated.Event:Connect(function(id: string)
				fired = id
			end)

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = "555",
				hue          = 1,
				initialCount = 10,
			})

			-- Assert
			expect(fired).to.equal("555")
			conn:Disconnect()
		end)

	end)

	-- =========================================================================
	-- CrowdDestroyed handler
	-- =========================================================================

	describe("CrowdDestroyed handler", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- Cache entry is nil after CrowdDestroyed.
		it("CrowdDestroyed — cache entry removed", function()
			-- Arrange
			local crowdId = "601"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 5))
			expect(CrowdStateClient.get(crowdId)).to.be.ok()

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdDestroyed", { crowdId = crowdId })

			-- Assert
			expect(CrowdStateClient.get(crowdId)).to.equal(nil)
		end)

		-- _lastReceivedTick cleared so re-creation accepts tick=0.
		it("CrowdDestroyed — _lastReceivedTick cleared for crowdId", function()
			-- Arrange: seed with a known tick
			local crowdId = "602"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 20))
			expect(CrowdStateClient._debugGetLastReceivedTick(crowdId)).to.equal(20)

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdDestroyed", { crowdId = crowdId })

			-- Assert: cleared
			expect(CrowdStateClient._debugGetLastReceivedTick(crowdId)).to.equal(nil)
		end)

		-- CrowdDestroyed BindableEvent fires.
		it("CrowdDestroyed BindableEvent fires with correct crowdId", function()
			-- Arrange
			local fired: string? = nil
			local conn = CrowdStateClient.CrowdDestroyed.Event:Connect(function(id: string)
				fired = id
			end)

			CrowdStateClient._debugSetRecord("603", makeCacheRecord("603", 1))

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdDestroyed", { crowdId = "603" })

			-- Assert
			expect(fired).to.equal("603")
			conn:Disconnect()
		end)

		-- Late-reliable: second CrowdDestroyed for same crowdId is graceful no-op.
		it("CrowdDestroyed — second destroy (late-reliable) is graceful no-op", function()
			-- Arrange
			local crowdId = "604"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 5))

			-- Act: first destroy
			CrowdStateClient._debugDispatchReliable("CrowdDestroyed", { crowdId = crowdId })
			-- Act: second destroy (late-reliable)
			local ok, _ = pcall(function()
				CrowdStateClient._debugDispatchReliable("CrowdDestroyed", { crowdId = crowdId })
			end)

			-- Assert: no error
			expect(ok).to.equal(true)
			expect(CrowdStateClient.get(crowdId)).to.equal(nil)
		end)

	end)

	-- =========================================================================
	-- CrowdEliminated handler
	-- =========================================================================

	describe("CrowdEliminated handler", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- Cache entry state set to Eliminated.
		it("CrowdEliminated — state set to Eliminated in cache", function()
			-- Arrange
			local crowdId = "701"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 5, "Active"))

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdEliminated", { crowdId = crowdId })

			-- Assert
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).state).to.equal("Eliminated")
		end)

		-- CrowdEliminated BindableEvent fires.
		it("CrowdEliminated BindableEvent fires with correct crowdId", function()
			-- Arrange
			local fired: string? = nil
			local conn = CrowdStateClient.CrowdEliminated.Event:Connect(function(id: string)
				fired = id
			end)
			CrowdStateClient._debugSetRecord("702", makeCacheRecord("702", 1))

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdEliminated", { crowdId = "702" })

			-- Assert
			expect(fired).to.equal("702")
			conn:Disconnect()
		end)

		-- Late-reliable: CrowdEliminated with no cache entry → no error (graceful no-op).
		it("CrowdEliminated late-reliable — no cache entry → no error", function()
			-- Arrange: no record seeded for 703
			local ok, _ = pcall(function()
				CrowdStateClient._debugDispatchReliable("CrowdEliminated", { crowdId = "703" })
			end)
			expect(ok).to.equal(true)
		end)

		-- CrowdEliminated still fires BindableEvent even when cache miss (late-reliable).
		it("CrowdEliminated fires BindableEvent even on cache miss", function()
			-- Arrange
			local getCount, cleanup = connectCounter(CrowdStateClient.CrowdEliminated)

			-- Act: no cache entry
			CrowdStateClient._debugDispatchReliable("CrowdEliminated", { crowdId = "704" })

			-- Assert
			expect(getCount()).to.equal(1)
			cleanup()
		end)

	end)

	-- =========================================================================
	-- CrowdCountClamped handler
	-- =========================================================================

	describe("CrowdCountClamped handler", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- CrowdCountClamped does NOT mutate cache count.
		it("CrowdCountClamped — does not mutate cache count (HUD-only)", function()
			-- Arrange
			local crowdId = "801"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 5))
			local originalCount = (CrowdStateClient.get(crowdId) :: CrowdStateClient.CrowdRecord).count

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdCountClamped", {
				crowdId  = crowdId,
				newCount = 999,
				delta    = -50,
			})

			-- Assert: count unchanged in cache
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect((rec :: CrowdStateClient.CrowdRecord).count).to.equal(originalCount)
		end)

		-- CrowdCountClamped BindableEvent fires with crowdId + payload.
		it("CrowdCountClamped BindableEvent fires with crowdId and payload", function()
			-- Arrange
			local firedId: string? = nil
			local firedPayload: any = nil
			local conn = CrowdStateClient.CrowdCountClamped.Event:Connect(function(
				id: string,
				payload: any
			)
				firedId = id
				firedPayload = payload
			end)

			-- Act
			local payload = { crowdId = "802", newCount = 100, delta = -20 }
			CrowdStateClient._debugDispatchReliable("CrowdCountClamped", payload)

			-- Assert
			expect(firedId).to.equal("802")
			expect(firedPayload).to.be.ok()
			conn:Disconnect()
		end)

	end)

	-- =========================================================================
	-- CrowdRelicChanged handler
	-- =========================================================================

	describe("CrowdRelicChanged handler", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- activeRelics replaced with server snapshot.
		it("CrowdRelicChanged — activeRelics replaced with full snapshot", function()
			-- Arrange: seed record with empty relics
			local crowdId = "901"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 3))

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdRelicChanged", {
				crowdId      = crowdId,
				activeRelics = { "relic_speed", "relic_shield" },
			})

			-- Assert
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			local relics = (rec :: CrowdStateClient.CrowdRecord).activeRelics
			expect(#relics).to.equal(2)
		end)

		-- CrowdRelicChanged BindableEvent fires with crowdId + relics.
		it("CrowdRelicChanged BindableEvent fires with crowdId and relics array", function()
			-- Arrange
			local firedId: string? = nil
			local firedRelics: { string }? = nil
			local conn = CrowdStateClient.CrowdRelicChanged.Event:Connect(function(
				id: string,
				relics: { string }
			)
				firedId = id
				firedRelics = relics
			end)

			CrowdStateClient._debugSetRecord("902", makeCacheRecord("902", 1))

			-- Act
			CrowdStateClient._debugDispatchReliable("CrowdRelicChanged", {
				crowdId      = "902",
				activeRelics = { "relic_magnet" },
			})

			-- Assert
			expect(firedId).to.equal("902")
			expect(firedRelics).to.be.ok()
			expect(#(firedRelics :: { string })).to.equal(1)
			conn:Disconnect()
		end)

		-- Late-reliable: CrowdRelicChanged with no cache entry → no error.
		it("CrowdRelicChanged late-reliable — no cache entry → no error", function()
			local ok, _ = pcall(function()
				CrowdStateClient._debugDispatchReliable("CrowdRelicChanged", {
					crowdId      = "903",
					activeRelics = { "relic_x" },
				})
			end)
			expect(ok).to.equal(true)
		end)

		-- activeRelics update: second CrowdRelicChanged replaces the first snapshot.
		it("CrowdRelicChanged — second update replaces first snapshot (full replacement)", function()
			-- Arrange
			local crowdId = "904"
			CrowdStateClient._debugSetRecord(crowdId, makeCacheRecord(crowdId, 1))

			CrowdStateClient._debugDispatchReliable("CrowdRelicChanged", {
				crowdId      = crowdId,
				activeRelics = { "relic_a", "relic_b" },
			})

			-- Act: second update with different snapshot
			CrowdStateClient._debugDispatchReliable("CrowdRelicChanged", {
				crowdId      = crowdId,
				activeRelics = { "relic_c" },
			})

			-- Assert: only relic_c remains
			local rec = CrowdStateClient.get(crowdId)
			expect(rec).to.be.ok()
			expect(#(rec :: CrowdStateClient.CrowdRecord).activeRelics).to.equal(1)
		end)

	end)

	-- =========================================================================
	-- AC-13: cross-channel ordering
	-- =========================================================================

	describe("AC-13 cross-channel ordering", function()

		afterEach(function()
			CrowdStateClient._resetForTests()
		end)

		-- AC-13a: reliable CrowdCreated arrives BEFORE any broadcast.
		-- Then broadcast arrives — broadcast fields (position, radius, tick) merge in.
		it("AC-13a — reliable CrowdCreated before broadcast: broadcast merges correctly", function()
			-- Arrange: reliable CrowdCreated first (partial init; tick=0)
			local userId = 9001
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = tostring(userId),
				hue          = 6,
				initialCount = 30,
			})

			-- Verify partial init
			local rec1 = CrowdStateClient.get(tostring(userId))
			expect(rec1).to.be.ok()
			expect((rec1 :: CrowdStateClient.CrowdRecord).tick).to.equal(0)

			-- Act: broadcast arrives (tick=1 > 0 → accepted)
			local buf = BufferCodecCrowdState.encode({
				{
					crowdId  = userId,
					tick     = 1,
					position = Vector3.new(50, 0, 50),
					radius   = 8.0,
					count    = 30,
					hue      = 6,
					state    = 1,
				},
			})
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Assert: broadcast fields merged into cache
			local rec2 = CrowdStateClient.get(tostring(userId))
			expect(rec2).to.be.ok()
			expect((rec2 :: CrowdStateClient.CrowdRecord).tick).to.equal(1)
			expect((rec2 :: CrowdStateClient.CrowdRecord).radius).to.equal(8.0)
		end)

		-- AC-13b: broadcast arrives BEFORE reliable CrowdCreated.
		-- Then reliable arrives — hue merged; count filled only if still 0.
		it("AC-13b — broadcast before reliable CrowdCreated: hue merged; count kept", function()
			-- Arrange: broadcast first (tick=2, count=15, hue=4)
			local userId = 9002
			local buf = BufferCodecCrowdState.encode({
				{
					crowdId  = userId,
					tick     = 2,
					position = Vector3.new(10, 0, 10),
					radius   = 6.0,
					count    = 15,
					hue      = 4,
					state    = 1,
				},
			})
			CrowdStateClient._debugDispatchBroadcast(buf)

			-- Verify broadcast populated cache
			local rec1 = CrowdStateClient.get(tostring(userId))
			expect(rec1).to.be.ok()
			expect((rec1 :: CrowdStateClient.CrowdRecord).count).to.equal(15)

			-- Act: reliable CrowdCreated arrives after broadcast
			CrowdStateClient._debugDispatchReliable("CrowdCreated", {
				crowdId      = tostring(userId),
				hue          = 11,  -- authoritative hue from reliable
				initialCount = 5,   -- not applied (count=15 > 0)
			})

			-- Assert
			local rec2 = CrowdStateClient.get(tostring(userId))
			expect(rec2).to.be.ok()
			expect((rec2 :: CrowdStateClient.CrowdRecord).hue).to.equal(11)   -- authoritative hue
			expect((rec2 :: CrowdStateClient.CrowdRecord).count).to.equal(15)  -- unchanged
		end)

	end)

end
