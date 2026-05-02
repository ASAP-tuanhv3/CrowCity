--!strict

--[[
	MatchStateServer — T3/T4/T5 timer-driven transitions tests.
	Path: tests/unit/match-state-server/transition_ready_snap.spec.luau
	Implements: MSM story-002 ACs:
	  AC-6 — Countdown:Ready → Countdown:Snap on 7s elapsed via timerCheck.
	  AC-8 — Countdown:Snap with 0 participants → Result, createAll NOT called.
	  Pre-Active timerCheck no-op when state has no _stateEndsAt (Lobby/Active).

	Mock clock via direct manipulation: force _stateEndsAt to past via private
	state setter helper (see _setStateForTests + manual write through internal
	_transitionTo not exposed — rely on _setParticipation entry plus os.clock()
	hack via long elapsed wait OR direct _stateEndsAt manipulation through the
	internal driver. Since _transitionTo is module-private, tests use the
	natural drive: enter Countdown:Ready via _setParticipation, then since the
	timer is `os.clock() + 7`, manually wait won't work in fast tests. Solution:
	expose direct internal field setter to mock the clock OR check the relative
	logic by setting state to "Countdown:Snap" with a past _stateEndsAt and
	verify timerCheck transitions. Use _setStateForTests + a future-extension
	_setStateEndsAtForTests if needed.

	Workaround: drive the boundary via os.clock() — install fake state directly
	using existing _setStateForTests and write _stateEndsAt via re-entering
	_setParticipation arithmetic. Cleanest: add a small fixture path that
	captures os.clock() then advances by os.wait(); but TestEZ blocks task.wait.

	Implementation: tests use _setStateForTests + small _setStateEndsAtForTests
	hook (added below if missing). For now: use the natural Lobby→Ready→Snap
	chain with a tiny COUNTDOWN_READY_SEC sleep alternative.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	--- Builds a RoundLifecycle mock that records calls.
	local function makeRLMock()
		local calls: { { method: string, args: any } } = {}
		return {
			calls = calls,
			createAll = function(participants: { Player })
				table.insert(calls, { method = "createAll", args = participants })
			end,
			destroyAll = function()
				table.insert(calls, { method = "destroyAll", args = nil })
			end,
		}
	end

	describe("MatchStateServer.timerCheck — Lobby/no-state safety", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("Lobby + nil _stateEndsAt: timerCheck is a no-op", function()
			expect(MatchStateServer.get()).to.equal("Lobby")
			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Lobby")
		end)
	end)

	describe("MatchStateServer.timerCheck — T3 Ready → Snap", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-6: pre-expiry timerCheck keeps state at Countdown:Ready", function()
			MatchStateServer._setParticipation(makePlayer(101), true)
			MatchStateServer._setParticipation(makePlayer(102), true)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")

			-- Immediately after entry the timer has ~7s remaining; not expired.
			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Countdown:Ready")
		end)

		it("AC-6: post-expiry timerCheck transitions to Countdown:Snap", function()
			MatchStateServer._setParticipation(makePlayer(101), true)
			MatchStateServer._setParticipation(makePlayer(102), true)
			-- Force the Ready timer to past by directly mutating _stateEndsAt via
			-- a private path: enter Snap directly to verify state transition.
			-- For Ready→Snap natural test we'd need a clock mock; instead use a
			-- contract test by setting state manually + the past _stateEndsAt.
			MatchStateServer._setStateForTests("Countdown:Ready")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Countdown:Snap")

			-- Snap _stateEndsAt should be ~3s in the future per COUNTDOWN_SNAP_SEC.
			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt).never.to.equal(nil)
			expect(endsAt > os.clock()).to.equal(true)
			expect(endsAt < os.clock() + 3.5).to.equal(true)
		end)
	end)

	describe("MatchStateServer.timerCheck — T5 Snap → Result (zero participants)", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-8: 0 participants in Snap → Result; createAll NOT called", function()
			local rl = makeRLMock()
			MatchStateServer._setRoundLifecycleOverride(rl :: any)

			-- No participants set; force into Snap with expired timer.
			MatchStateServer._setStateForTests("Countdown:Snap")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Result")
			expect(#rl.calls).to.equal(0)
		end)
	end)
end
