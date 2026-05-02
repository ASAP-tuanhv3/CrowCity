--!strict

--[[
	MatchStateServer — T1 Lobby ↔ Countdown:Ready driver tests.
	Path: tests/unit/match-state-server/transition_lobby_ready.spec.luau
	Implements: MSM story-002 ACs:
	  AC-4 — Lobby → Countdown:Ready when participation count ≥ MIN_PLAYERS_TO_START.
	  AC-5 — Countdown:Ready → Lobby revert (F5) when count drops below threshold.
	  Same revert on PlayerRemoving (handler bypasses _setParticipation).

	No timer advances here — those land in transition_ready_snap.spec.luau.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	describe("MatchStateServer T1 — Lobby → Countdown:Ready", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-4: count = 1 → state stays Lobby (below threshold)", function()
			MatchStateServer._setParticipation(makePlayer(101), true)
			expect(MatchStateServer.get()).to.equal("Lobby")
		end)

		it("AC-4: count = 2 → state becomes Countdown:Ready", function()
			MatchStateServer._setParticipation(makePlayer(101), true)
			MatchStateServer._setParticipation(makePlayer(102), true)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")
		end)

		it("AC-4: getStateEndsAt is set to now + 7s on Countdown:Ready entry", function()
			local before = os.clock()
			MatchStateServer._setParticipation(makePlayer(101), true)
			MatchStateServer._setParticipation(makePlayer(102), true)
			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt).never.to.equal(nil)
			expect(endsAt > before + 6.5).to.equal(true)
			expect(endsAt < before + 7.5).to.equal(true)
		end)

		it("count = 3 (over threshold) keeps state Countdown:Ready", function()
			MatchStateServer._setParticipation(makePlayer(101), true)
			MatchStateServer._setParticipation(makePlayer(102), true)
			MatchStateServer._setParticipation(makePlayer(103), true)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")
		end)
	end)

	describe("MatchStateServer F5 — Countdown:Ready → Lobby revert", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-5: count drops to 1 via flag flip → reverts to Lobby", function()
			local p1 = makePlayer(101)
			local p2 = makePlayer(102)
			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setParticipation(p2, true)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")

			MatchStateServer._setParticipation(p1, false)
			expect(MatchStateServer.get()).to.equal("Lobby")
			expect(MatchStateServer.getStateEndsAt()).to.equal(nil)
		end)

		it("count drops to 2 (still ≥ threshold) keeps Countdown:Ready", function()
			local p1 = makePlayer(101)
			local p2 = makePlayer(102)
			local p3 = makePlayer(103)
			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setParticipation(p2, true)
			MatchStateServer._setParticipation(p3, true)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")

			MatchStateServer._setParticipation(p3, false)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")
		end)
	end)
end
