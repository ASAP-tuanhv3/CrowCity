--!strict

--[[
	MatchStateServer — Phase 7 eliminationConsumer + T6 last-standing tests.
	Path: tests/unit/match-state-server/elim_consumer_t6.spec.luau
	Implements: MSM story-004 ACs:
	  AC-9 — last crowd eliminated → Result with _winnerId = sole survivor.
	  match continues — #active > 1 keeps state Active.
	  empty active — #active == 0 → Result with _winnerId = nil.
	  _pendingElims cleared at top of every call.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makeCSMRecord(crowdId: string)
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 4.24,
			count = 50,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: any,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("MatchStateServer.eliminationConsumer — T6 last-standing", function()

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
			MatchStateServer._setCurrencyOverride({
				grantMatchRewards = function(_p: { any }) end,
			})
		end)

		it("AC-9: #active == 1 → Result with sole survivor as winnerId", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("102") }  -- sole survivor
				end,
			})
			MatchStateServer._setStateForTests("Active")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Result")
			expect(MatchStateServer.getWinnerId()).to.equal("102")
		end)

		it("#active == 0 (rare double-elim) → Result with winnerId nil", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {}
				end,
			})
			MatchStateServer._setStateForTests("Active")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Result")
			expect(MatchStateServer.getWinnerId()).to.equal(nil)
		end)

		it("#active >= 2 → state stays Active", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101"), makeCSMRecord("102") }
				end,
			})
			MatchStateServer._setStateForTests("Active")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Active")
			expect(MatchStateServer.getWinnerId()).to.equal(nil)
		end)

		it("Result endsAt = now + RESULT_DURATION_SEC after T6", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("102") }
				end,
			})
			MatchStateServer._setStateForTests("Active")

			MatchStateServer.eliminationConsumer(1)

			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt > os.clock() + 9.5).to.equal(true)
			expect(endsAt < os.clock() + 10.5).to.equal(true)
		end)
	end)

	describe("MatchStateServer.eliminationConsumer — _pendingElims drain", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101"), makeCSMRecord("102") }  -- match continues
				end,
			})
		end)

		it("_pendingElims is cleared at top of each call", function()
			MatchStateServer._pushPendingElimForTests("101")
			MatchStateServer._pushPendingElimForTests("102")
			expect(MatchStateServer._getPendingElimsCount()).to.equal(2)

			MatchStateServer._setStateForTests("Active")
			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer._getPendingElimsCount()).to.equal(0)
		end)

		it("Lobby state → drain occurs but no transition", function()
			MatchStateServer._pushPendingElimForTests("101")
			-- _state defaults to Lobby after reset
			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Lobby")
			expect(MatchStateServer._getPendingElimsCount()).to.equal(0)
		end)
	end)
end
