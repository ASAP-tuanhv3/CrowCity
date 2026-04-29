--!strict

--[[
	CrowdStateServer — reliable signal fanout unit tests.
	Path: tests/unit/crowd-state-server/signal_fanout.spec.luau
	Implements: CSM story-001 ACs:
	  AC-23 (CrowdCreated fires with {crowdId, hue, initialCount} payload)
	  AC-26 (CrowdDestroyed fires with {crowdId} payload)
	  No event on idempotent destroy (absent record)
	  No second event on duplicate create (error fires before fanout)
	  8-player createAll fans exactly 8 CrowdCreated events

	Test strategy: Network.fireAllClients sends to Roblox clients; in a
	TestEZ-in-Studio server-only context no client is present to receive.
	We use _setTestFanoutInterceptor to capture payloads before they reach
	the network layer. The production path (interceptor nil) is unchanged —
	fanout() falls through to Network.fireAllClients.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	local function makeRecord(
		crowdId: string,
		count: number?,
		hue: number?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = count or 10,
			hue = hue or 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer reliable signal fanout", function()

		--- Ordered log of all fanout calls made during the current test.
		local recorded: { { event: string, payload: { [string]: any } } }

		beforeEach(function()
			CrowdStateServer._resetForTests()
			recorded = {}
			-- Wire the interceptor so every fanout() call appends to `recorded`.
			-- _resetForTests() will clear this at the start of the next test.
			CrowdStateServer._setTestFanoutInterceptor(function(
				eventName: string,
				payload: { [string]: any }
			)
				table.insert(recorded, { event = eventName, payload = payload })
			end)
		end)

		-- AC-23: create fires exactly one CrowdCreated event with the correct payload.
		it("create fires CrowdCreated with {crowdId, hue, initialCount} (AC-23)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 10, 5))
			expect(#recorded).to.equal(1)
			expect(recorded[1].event).to.equal("CrowdCreated")
			expect(recorded[1].payload.crowdId).to.equal("u1")
			expect(recorded[1].payload.hue).to.equal(5)
			expect(recorded[1].payload.initialCount).to.equal(10)
		end)

		-- AC-26: destroy fires exactly one CrowdDestroyed event with {crowdId}.
		-- Clears `recorded` after the create event so only the destroy event is checked.
		it("destroy fires CrowdDestroyed with {crowdId} (AC-26)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			recorded = {}  -- discard CrowdCreated; we only want to observe CrowdDestroyed
			CrowdStateServer.destroy("u1")
			expect(#recorded).to.equal(1)
			expect(recorded[1].event).to.equal("CrowdDestroyed")
			expect(recorded[1].payload.crowdId).to.equal("u1")
		end)

		-- AC-23: 8-player createAll equivalent fans exactly 8 CrowdCreated events,
		-- each with the correct crowdId and initialCount.
		it("8-player createAll fans 8 CrowdCreated events (AC-23 scale)", function()
			for i = 1, 8 do
				local id = "u" .. i
				CrowdStateServer.create(id, makeRecord(id, 10, ((i - 1) % 12) + 1))
			end
			expect(#recorded).to.equal(8)
			for i = 1, 8 do
				expect(recorded[i].event).to.equal("CrowdCreated")
				expect(recorded[i].payload.crowdId).to.equal("u" .. i)
				expect(recorded[i].payload.initialCount).to.equal(10)
			end
		end)

		-- AC-26 edge: destroy on absent record fires NO event.
		-- Idempotent destroy must never produce a CrowdDestroyed fanout for a
		-- record that never existed (or was already destroyed).
		it("destroy on absent record fires NO event (AC-26 idempotent edge)", function()
			CrowdStateServer.destroy("u1")  -- no prior create
			expect(#recorded).to.equal(0)
		end)

		-- AC-23 edge: duplicate create errors before reaching fanout.
		-- The first create fires one event; the second call must error and must
		-- NOT produce a second CrowdCreated event for the same crowdId.
		it("duplicate create errors before fanout — no second event (AC-23 edge)", function()
			CrowdStateServer.create("u1", makeRecord("u1"))
			expect(#recorded).to.equal(1)
			-- pcall absorbs the error; we only care that #recorded stays at 1
			pcall(CrowdStateServer.create, "u1", makeRecord("u1"))
			expect(#recorded).to.equal(1)
		end)

	end)
end
