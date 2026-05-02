--!strict

--[[
	CrowdStateServer — hue range + immutability unit tests.
	Path: tests/unit/crowd-state-server/hue.spec.luau
	Implements: CSM story-003 ACs:
	  AC-05 (Hue Assignment, F6) — players join order 1, 2, 12, 13 → hue
	  records 1, 2, 12, 1; CSM stores values [1..12] cleanly.
	  AC-16 (hue + initialCount portion) — create stores both fields.
	  No setHue API (immutability — Pillar 4 anti-P2W; ADR-0001 §Key Interfaces).
	  Out-of-range pcall failures — hue=0 / hue=13 trip range assertion.

	Note: F6 wrap-around correctness ((join_order - 1) mod 12) + 1 is
	RoundLifecycle's responsibility (composes initial.hue from join order).
	This story validates only that CSM accepts and stores any value in
	[1, 12] and rejects values outside that range.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	local function makeRecord(
		crowdId: string,
		hue: number?
	): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = 10,
			hue = hue or 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.create — hue range assertion + storage", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- Suppress reliable RemoteEvent fanout — Network is not started in
			-- TestEZ context and would error on fireAllClients. CrowdCreated
			-- payload assertions live in signal_fanout.spec.luau.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		it("AC-05: stores hue=1 for first joiner", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1))
			local rec = CrowdStateServer.get("u1")
			expect(rec).never.to.equal(nil)
			expect((rec :: CrowdStateServer.CrowdRecord).hue).to.equal(1)
		end)

		it("AC-05: stores hue=2 for second joiner", function()
			CrowdStateServer.create("u2", makeRecord("u2", 2))
			expect((CrowdStateServer.get("u2") :: CrowdStateServer.CrowdRecord).hue)
				.to.equal(2)
		end)

		it("AC-05: stores hue=12 (palette edge)", function()
			CrowdStateServer.create("u12", makeRecord("u12", 12))
			expect((CrowdStateServer.get("u12") :: CrowdStateServer.CrowdRecord).hue)
				.to.equal(12)
		end)

		it("AC-05: stores hue=1 for 13th joiner (RoundLifecycle wraps F6)", function()
			-- F6 wrap is RL's job; CSM only stores the value RL hands it.
			-- Simulating RL-output for join_order=13: ((13-1) mod 12)+1 = 1.
			CrowdStateServer.create("u13", makeRecord("u13", 1))
			expect((CrowdStateServer.get("u13") :: CrowdStateServer.CrowdRecord).hue)
				.to.equal(1)
		end)

		it("AC-16: create stores both hue and initial count", function()
			local rec = makeRecord("u1", 5)
			rec.count = 10
			CrowdStateServer.create("u1", rec)
			local stored = CrowdStateServer.get("u1") :: CrowdStateServer.CrowdRecord
			expect(stored.hue).to.equal(5)
			expect(stored.count).to.equal(10)
		end)

		it("rejects hue=0 with [1, 12] range error", function()
			local ok, err = pcall(function()
				CrowdStateServer.create("u_lo", makeRecord("u_lo", 0))
			end)
			expect(ok).to.equal(false)
			expect(string.find(tostring(err), "hue must be in %[1, 12%]")).to.be.ok()
			expect(string.find(tostring(err), "got 0")).to.be.ok()
		end)

		it("rejects hue=13 with [1, 12] range error", function()
			local ok, err = pcall(function()
				CrowdStateServer.create("u_hi", makeRecord("u_hi", 13))
			end)
			expect(ok).to.equal(false)
			expect(string.find(tostring(err), "hue must be in %[1, 12%]")).to.be.ok()
			expect(string.find(tostring(err), "got 13")).to.be.ok()
		end)

		it("rejects negative hue", function()
			local ok = pcall(function()
				CrowdStateServer.create("u_neg", makeRecord("u_neg", -1))
			end)
			expect(ok).to.equal(false)
		end)
	end)

	describe("CrowdStateServer hue immutability — no setHue API", function()
		it("does not export setHue (Pillar 4 anti-P2W; ADR-0001 immutable hue)", function()
			expect((CrowdStateServer :: any).setHue).to.equal(nil)
		end)
	end)
end
