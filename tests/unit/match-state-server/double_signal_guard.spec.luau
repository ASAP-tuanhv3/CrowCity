--!strict

--[[
	MatchStateServer — Phase 7 double-signal guard tests.
	Path: tests/unit/match-state-server/double_signal_guard.spec.luau
	Implements: MSM story-004 AC-11 + AC-21:
	  Phase 6 already moved to Result → Phase 7 silently drops queued elims.
	  Two simultaneous elim signals + sole survivor → ONE transitionTo call.
	  State != Active short-circuits eliminationConsumer body before count check.
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

	describe("MatchStateServer Phase 7 — double-signal guard", function()

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

		it("AC-11/AC-21: Phase 6 already in Result → Phase 7 returns silently", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("103") }  -- sole survivor
				end,
			})
			MatchStateServer._setStateForTests("Result")  -- Phase 6 transitioned first
			MatchStateServer._setWinnerIdForTests("PRIOR")  -- prior T7 resolution

			-- Two queued elims arrived during the same tick.
			MatchStateServer._pushPendingElimForTests("101")
			MatchStateServer._pushPendingElimForTests("102")

			MatchStateServer.eliminationConsumer(1)

			-- State must remain Result; winnerId not overwritten.
			expect(MatchStateServer.get()).to.equal("Result")
			expect(MatchStateServer.getWinnerId()).to.equal("PRIOR")
			-- Pending queue cleared even when guard fires.
			expect(MatchStateServer._getPendingElimsCount()).to.equal(0)
		end)

		it("AC-11: 2 simultaneous elims → ONE transition to Result, winnerId = remaining", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("103") }  -- C remains; A and B eliminated
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._pushPendingElimForTests("101")
			MatchStateServer._pushPendingElimForTests("102")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Result")
			expect(MatchStateServer.getWinnerId()).to.equal("103")
		end)

		it("ServerClosing state → Phase 7 returns without action", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101") }
				end,
			})
			MatchStateServer._setStateForTests("ServerClosing")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("ServerClosing")
		end)

		it("Intermission state → Phase 7 returns without action", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101") }
				end,
			})
			MatchStateServer._setStateForTests("Intermission")

			MatchStateServer.eliminationConsumer(1)

			expect(MatchStateServer.get()).to.equal("Intermission")
		end)
	end)
end
