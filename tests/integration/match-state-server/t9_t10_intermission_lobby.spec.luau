--!strict

--[[
	MatchStateServer — T9 + T10 timer-driven transitions tests.
	Path: tests/integration/match-state-server/t9_t10_intermission_lobby.spec.luau
	Implements: MSM story-005 ACs:
	  AC-14 — T9 ordering: [destroyAll, clearAll, broadcast(Intermission)].
	  AC-15 — T10 flag reset: Intermission → Lobby resets all flags to TRUE.
	  Result endsAt stays unset on Lobby (untimed state).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	describe("MatchStateServer T9 — Result → Intermission ordering", function()

		local log: { string }

		beforeEach(function()
			MatchStateServer._resetForTests()
			log = {}

			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(_p: { Player }) end,
				destroyAll = function()
					table.insert(log, "destroyAll")
				end,
				getPeakTimestamp = function(_id: string): number?
					return nil
				end,
				setWinner = function(_id: string?) end,
				getPlacements = function(): { any }
					return {}
				end,
			})

			MatchStateServer._setRelicSystemOverride({
				clearAll = function()
					table.insert(log, "clearAll")
				end,
			})

			MatchStateServer._setCurrencyOverride({
				grantMatchRewards = function(_placements: { any }) end,
			})
		end)

		it("AC-14: Result expiry triggers [destroyAll, clearAll] in order", function()
			MatchStateServer._setStateForTests("Result")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			expect(log[1]).to.equal("destroyAll")
			expect(log[2]).to.equal("clearAll")
			expect(MatchStateServer.get()).to.equal("Intermission")
		end)

		it("Intermission endsAt = now + INTERMISSION_DURATION_SEC (~10s)", function()
			MatchStateServer._setStateForTests("Result")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt > os.clock() + 9.5).to.equal(true)
			expect(endsAt < os.clock() + 10.5).to.equal(true)
		end)
	end)

	describe("MatchStateServer T10 — Intermission → Lobby flag reset", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(_p: { Player }) end,
				destroyAll = function() end,
				getPeakTimestamp = function(_id: string): number?
					return nil
				end,
				setWinner = function(_id: string?) end,
				getPlacements = function(): { any }
					return {}
				end,
			})
		end)

		it("AC-15: all flags reset to TRUE on T10", function()
			-- Set up some FALSE/TRUE flags before transition.
			local p1 = makePlayer(101)
			local p2 = makePlayer(102)
			MatchStateServer._setParticipation(p1, false)
			MatchStateServer._setParticipation(p2, true)

			expect(MatchStateServer.getParticipation(p1)).to.equal(false)
			expect(MatchStateServer.getParticipation(p2)).to.equal(true)

			-- Force Intermission with expired timer.
			MatchStateServer._setStateForTests("Intermission")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			expect(MatchStateServer.get()).to.equal("Lobby")
			expect(MatchStateServer.getParticipation(p1)).to.equal(true)
			expect(MatchStateServer.getParticipation(p2)).to.equal(true)
		end)

		it("Lobby has no _stateEndsAt (untimed)", function()
			local p1 = makePlayer(101)
			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setStateForTests("Intermission")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			expect(MatchStateServer.getStateEndsAt()).to.equal(nil)
		end)
	end)
end
