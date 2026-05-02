--!strict

--[[
	CrowdStateServer — CrowdRelicChanged reliable signal fanout unit tests.
	Path: tests/unit/crowd-state-server/relic_changed_signal.spec.luau
	Implements: CSM story-003 ACs:
	  CrowdRelicChanged fires on grant + remove with full snapshot per GDD L141.
	  No fire on rejection (cap full / duplicate / absent crowd / not present).
	  Snapshot is full list, not delta — sequential adds emit growing lists.

	Test strategy: mirrors signal_fanout.spec.luau — uses
	_setTestFanoutInterceptor to capture network events headlessly. Production
	path (interceptor nil) unchanged — fanout() falls through to
	Network.fireAllClients.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	local function makeRecord(crowdId: string): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = 10,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer CrowdRelicChanged fanout", function()

		--- Ordered log of all fanout calls during the current test.
		local recorded: { { event: string, payload: { [string]: any } } }

		--- Filter helper — returns CrowdRelicChanged events only (excludes
		--- CrowdCreated which fires from create() in beforeEach).
		local function relicEvents(): { { event: string, payload: { [string]: any } } }
			local out = {}
			for _, entry in recorded do
				if entry.event == "CrowdRelicChanged" then
					table.insert(out, entry)
				end
			end
			return out
		end

		beforeEach(function()
			CrowdStateServer._resetForTests()
			recorded = {}
			CrowdStateServer._setTestFanoutInterceptor(function(
				eventName: string,
				payload: { [string]: any }
			)
				table.insert(recorded, { event = eventName, payload = payload })
			end)
			CrowdStateServer.create("u1", makeRecord("u1"))
		end)

		it("fires exactly one event on successful grant with full snapshot", function()
			recorded = {}  -- discard CrowdCreated from create()
			CrowdStateServer.addActiveRelic("u1", "A")
			local events = relicEvents()
			expect(#events).to.equal(1)
			expect(events[1].payload.crowdId).to.equal("u1")
			local snapshot = events[1].payload.activeRelics :: { string }
			expect(#snapshot).to.equal(1)
			expect(snapshot[1]).to.equal("A")
		end)

		it("fires exactly one event on successful remove with post-remove snapshot", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			recorded = {}
			CrowdStateServer.removeActiveRelic("u1", "A")
			local events = relicEvents()
			expect(#events).to.equal(1)
			expect(events[1].payload.crowdId).to.equal("u1")
			local snapshot = events[1].payload.activeRelics :: { string }
			expect(#snapshot).to.equal(0)
		end)

		it("does NOT fire when grant rejected by cap-full", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			CrowdStateServer.addActiveRelic("u1", "B")
			CrowdStateServer.addActiveRelic("u1", "C")
			CrowdStateServer.addActiveRelic("u1", "D")
			recorded = {}
			local ok = CrowdStateServer.addActiveRelic("u1", "E")
			expect(ok).to.equal(false)
			expect(#relicEvents()).to.equal(0)
		end)

		it("does NOT fire when grant rejected by duplicate", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			recorded = {}
			local ok = CrowdStateServer.addActiveRelic("u1", "A")
			expect(ok).to.equal(false)
			expect(#relicEvents()).to.equal(0)
		end)

		it("does NOT fire on grant against absent crowd", function()
			recorded = {}
			local ok = CrowdStateServer.addActiveRelic("ghost", "A")
			expect(ok).to.equal(false)
			expect(#relicEvents()).to.equal(0)
		end)

		it("does NOT fire on remove against absent crowd", function()
			recorded = {}
			local ok = CrowdStateServer.removeActiveRelic("ghost", "A")
			expect(ok).to.equal(false)
			expect(#relicEvents()).to.equal(0)
		end)

		it("does NOT fire on remove of specId not in list", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			recorded = {}
			local ok = CrowdStateServer.removeActiveRelic("u1", "Z")
			expect(ok).to.equal(false)
			expect(#relicEvents()).to.equal(0)
		end)

		it("emits FULL snapshot per fire — sequential grants grow [A], [A,B], [A,B,C]", function()
			recorded = {}
			CrowdStateServer.addActiveRelic("u1", "A")
			CrowdStateServer.addActiveRelic("u1", "B")
			CrowdStateServer.addActiveRelic("u1", "C")
			local events = relicEvents()
			expect(#events).to.equal(3)

			-- Each event payload is the post-grant snapshot, not a delta.
			expect(#(events[1].payload.activeRelics :: { string })).to.equal(1)
			expect((events[1].payload.activeRelics :: { string })[1]).to.equal("A")

			expect(#(events[2].payload.activeRelics :: { string })).to.equal(2)
			expect((events[2].payload.activeRelics :: { string })[1]).to.equal("A")
			expect((events[2].payload.activeRelics :: { string })[2]).to.equal("B")

			expect(#(events[3].payload.activeRelics :: { string })).to.equal(3)
			expect((events[3].payload.activeRelics :: { string })[1]).to.equal("A")
			expect((events[3].payload.activeRelics :: { string })[2]).to.equal("B")
			expect((events[3].payload.activeRelics :: { string })[3]).to.equal("C")
		end)

		it("snapshot is a defensive copy — mutating it does not affect record", function()
			CrowdStateServer.addActiveRelic("u1", "A")
			local events = relicEvents()
			expect(#events).to.equal(1)
			local snapshot = events[1].payload.activeRelics :: { string }
			-- Mutate the broadcast payload — must not leak into record.
			snapshot[1] = "MUTATED"
			table.insert(snapshot, "INJECTED")
			local rec = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(#rec.activeRelics).to.equal(1)
			expect(rec.activeRelics[1]).to.equal("A")
		end)
	end)
end
