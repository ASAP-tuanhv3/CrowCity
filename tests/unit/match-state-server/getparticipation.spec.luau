--!strict

--[[
	MatchStateServer GetParticipation RemoteFunction handler — unit tests.
	Path: tests/unit/match-state-server/getparticipation.spec.luau

	Story 7-10 (Sprint 7) / match-state-server story-007.
	Covers AC: GetParticipation returns boolean from _participation map.
	Stateless — no mutation. Default false for unknown player.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number): any
		return { UserId = userId, Name = "P" .. userId }
	end

	describe("MatchStateServer GetParticipation handler — Story 7-10", function()
		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("returns false for unknown player (no entry)", function()
			expect(MatchStateServer._handleGetParticipationForTest(makePlayer(999))).to.equal(false)
		end)

		it("returns true after _setParticipation(player, true)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			expect(MatchStateServer._handleGetParticipationForTest(player)).to.equal(true)
		end)

		it("returns false after _setParticipation(player, false)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer._handleGetParticipationForTest(player)).to.equal(false)
		end)

		-- Stateless — calling handler does not mutate state. Repeated invocations
		-- return same value; participation map unaffected.
		it("handler is stateless — repeated calls do not mutate participation", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)

			-- Call 5 times
			for _ = 1, 5 do
				expect(MatchStateServer._handleGetParticipationForTest(player)).to.equal(true)
			end

			-- State still consistent
			expect(MatchStateServer.getParticipation(player)).to.equal(true)
		end)
	end)
end
