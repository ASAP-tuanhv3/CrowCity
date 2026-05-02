--!strict

--[[
	MatchStateServer — Result entry ordering invariant integration test.
	Path: tests/integration/match-state-server/grant_before_broadcast.spec.luau
	Implements: MSM story-005 ACs:
	  AC-20 — Result entry: [setWinner, getPlacements, grantMatchRewards, broadcast].
	  Strip rule — broadcast meta omits internal fields (peakCount/isWinner/wasEliminated).

	Tests T7 path drives Active → Result through _handleResultEntry. Spies on RL
	+ Currency record call order via shared call log.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makeCSMRecord(crowdId: string, count: number)
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 4.24,
			count = count,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: any,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("MatchStateServer Result entry — ordering invariant", function()

		local log: { string }
		local capturedPlacements: { any }?

		beforeEach(function()
			MatchStateServer._resetForTests()
			log = {}
			capturedPlacements = nil

			-- RoundLifecycle mock — records setWinner + returns synthetic placements.
			MatchStateServer._setRoundLifecycleOverride({
				createAll = function(_p: { Player }) end,
				destroyAll = function()
					table.insert(log, "destroyAll")
				end,
				getPeakTimestamp = function(_id: string): number?
					return nil
				end,
				setWinner = function(_id: string?)
					table.insert(log, "setWinner")
				end,
				getPlacements = function(): { any }
					table.insert(log, "getPlacements")
					return {
						{
							crowdId = "101", userId = 101, placement = 1,
							crowdCount = 80, eliminationTime = nil,
							peakCount = 90, isWinner = true, wasEliminated = false,
						},
					}
				end,
			})

			MatchStateServer._setCurrencyOverride({
				grantMatchRewards = function(placements: { any })
					table.insert(log, "grantMatchRewards")
					capturedPlacements = placements
				end,
			})

			MatchStateServer._setRelicSystemOverride({
				clearAll = function()
					table.insert(log, "clearAll")
				end,
			})
		end)

		it("AC-20: T7 Active expiry → [setWinner, getPlacements, grantMatchRewards] order", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 80) }
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			expect(log[1]).to.equal("setWinner")
			expect(log[2]).to.equal("getPlacements")
			expect(log[3]).to.equal("grantMatchRewards")
			expect(MatchStateServer.get()).to.equal("Result")
		end)

		it("AC-20: T6 last-standing → [setWinner, getPlacements, grantMatchRewards]", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 80) }  -- sole survivor
				end,
			})
			MatchStateServer._setStateForTests("Active")

			MatchStateServer.eliminationConsumer(1)

			expect(log[1]).to.equal("setWinner")
			expect(log[2]).to.equal("getPlacements")
			expect(log[3]).to.equal("grantMatchRewards")
			expect(MatchStateServer.get()).to.equal("Result")
		end)

		it("strip rule: grant payload omits peakCount/isWinner/wasEliminated", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 80) }
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)

			local placements = capturedPlacements :: { any }
			expect(placements).never.to.equal(nil)
			expect(#placements).to.equal(1)
			expect(placements[1].crowdId).to.equal("101")
			expect(placements[1].placement).to.equal(1)
			expect(placements[1].crowdCount).to.equal(80)
			-- Internal fields STRIPPED.
			expect(placements[1].peakCount).to.equal(nil)
			expect(placements[1].isWinner).to.equal(nil)
			expect(placements[1].wasEliminated).to.equal(nil)
		end)
	end)
end
