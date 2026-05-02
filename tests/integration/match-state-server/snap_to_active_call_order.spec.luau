--!strict

--[[
	MatchStateServer — T4 Snap → Active call-order integration test.
	Path: tests/integration/match-state-server/snap_to_active_call_order.spec.luau
	Implements: MSM story-002 AC-7:
	  Snap → Active with ≥1 participant: RoundLifecycle.createAll called BEFORE
	  the state transition writes "Active". Order log: [createAll, transitionTo].

	Spy: RoundLifecycle.createAll wrapper records call. State transition
	captured by reading _state immediately after timerCheck. The full
	MatchStateChanged broadcast wiring lives in story-007; this story
	asserts the createAll-before-state-write ordering only.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	describe("MatchStateServer T4 — Snap → Active createAll ordering", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-7: createAll called before state transitions to Active", function()
			local p1 = makePlayer(101)
			local p2 = makePlayer(102)

			-- Player resolver: returns the fake players for our userIds.
			MatchStateServer._setPlayerResolverForTests(function(userId: number): Player?
				if userId == 101 then return p1 end
				if userId == 102 then return p2 end
				return nil
			end)

			-- Spy log captures (event, state-snapshot-at-call-time).
			local log: { { event: string, state: string } } = {}
			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(_participants: { Player })
					-- Capture the state AT the moment createAll runs. Per AC-7
					-- the state must still be "Countdown:Snap" — transitionTo
					-- happens AFTER createAll returns.
					table.insert(log, {
						event = "createAll",
						state = MatchStateServer.get(),
					})
				end,
				destroyAll = function() end,
			})

			-- Set up snap with 2 participants and an expired timer.
			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setParticipation(p2, true)
			-- Bypass intermediate Ready→Snap: force Snap directly with expired timer.
			MatchStateServer._setStateForTests("Countdown:Snap")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			-- After timerCheck: log should have createAll entry, and state should be Active.
			expect(#log).to.equal(1)
			expect(log[1].event).to.equal("createAll")
			expect(log[1].state).to.equal("Countdown:Snap")
			expect(MatchStateServer.get()).to.equal("Active")
		end)

		it("AC-7: Active timer ends ~300s in the future (ROUND_DURATION_SEC)", function()
			local p1 = makePlayer(101)
			MatchStateServer._setPlayerResolverForTests(function(userId: number): Player?
				if userId == 101 then return p1 end
				return nil
			end)
			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(_participants: { Player }) end,
				destroyAll = function() end,
			})

			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setStateForTests("Countdown:Snap")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt).never.to.equal(nil)
			expect(endsAt > os.clock() + 295).to.equal(true)
			expect(endsAt < os.clock() + 305).to.equal(true)
		end)

		it("createAll receives exactly the participating players (count = 2)", function()
			local p1 = makePlayer(101)
			local p2 = makePlayer(102)
			MatchStateServer._setPlayerResolverForTests(function(userId: number): Player?
				if userId == 101 then return p1 end
				if userId == 102 then return p2 end
				return nil
			end)

			local capturedParticipants: { Player }? = nil
			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(participants: { Player })
					capturedParticipants = participants
				end,
				destroyAll = function() end,
			})

			MatchStateServer._setParticipation(p1, true)
			MatchStateServer._setParticipation(p2, true)
			MatchStateServer._setStateForTests("Countdown:Snap")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			local participants = capturedParticipants :: { Player }
			expect(participants).never.to.equal(nil)
			expect(#participants).to.equal(2)
		end)
	end)
end
