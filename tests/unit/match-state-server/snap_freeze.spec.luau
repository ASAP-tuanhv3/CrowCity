--!strict

--[[
	snap_freeze.spec.luau — MatchStateServer asymmetric Countdown:Snap freeze
	Implements: ADR-0005 §Decision (asymmetric freeze rule)
	            Story-001 AC-3

	Rule: in Countdown:Snap, TRUE→FALSE rejected (locked-in participants
	cannot opt out mid-snap). FALSE→TRUE always allowed (late opt-in).
	Outside Snap, both directions are allowed.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number)
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	describe("MatchStateServer Countdown:Snap asymmetric freeze (AC-3)", function()
		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-3: in Snap, TRUE→FALSE rejected (flag stays TRUE)", function()
			local playerA = makePlayer(101)
			MatchStateServer._setParticipation(playerA, true)
			MatchStateServer._setStateForTests("Countdown:Snap")

			MatchStateServer._setParticipation(playerA, false)  -- attempt opt-out
			expect(MatchStateServer.getParticipation(playerA)).to.equal(true)  -- rejected
		end)

		it("AC-3: in Snap, FALSE→TRUE succeeds (late opt-in allowed)", function()
			local playerB = makePlayer(102)
			-- B has no entry → defaults to false
			MatchStateServer._setStateForTests("Countdown:Snap")

			MatchStateServer._setParticipation(playerB, true)  -- attempt opt-in
			expect(MatchStateServer.getParticipation(playerB)).to.equal(true)  -- allowed
		end)

		it("AC-3: outside Snap, TRUE→FALSE allowed (Lobby)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			MatchStateServer._setStateForTests("Lobby")

			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		it("AC-3: outside Snap, TRUE→FALSE allowed (Countdown:Ready)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			MatchStateServer._setStateForTests("Countdown:Ready")

			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		it("AC-3: outside Snap, TRUE→FALSE allowed (Active)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			MatchStateServer._setStateForTests("Active")

			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		it("AC-3: in Snap with FALSE→FALSE write is a no-op", function()
			local player = makePlayer(101)
			-- Player has no entry → default false. Write false in Snap.
			MatchStateServer._setStateForTests("Countdown:Snap")
			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)
	end)
end
