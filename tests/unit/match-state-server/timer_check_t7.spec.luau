--!strict

--[[
	MatchStateServer — T7 Active → Result timer-expiry tests.
	Path: tests/unit/match-state-server/timer_check_t7.spec.luau
	Implements: MSM story-003 ACs:
	  T7 — Active + elapsed ≥ ROUND_DURATION_SEC → Result with F4-resolved winnerId.
	  Pre-expiry: state stays Active.
	  Empty CSM (all eliminated) → winnerId nil, state still transitions Result.

	F4 sort coverage in f4_tiebreak.spec.luau; this spec only covers the
	timer-expiry transition + side effects.
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

	local function makeRLMock(timestamps: { [string]: number }?)
		local stamps = timestamps or {}
		return {
			createAll = function(_p: { Player }) end,
			destroyAll = function() end,
			getPeakTimestamp = function(crowdId: string): number?
				return stamps[crowdId]
			end,
			setWinner = function(_id: string?) end,
			getPlacements = function(): { any }
				return {}
			end,
		}
	end

	describe("MatchStateServer T7 — Active timer expiry", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock() :: any)
		end)

		it("Active + endsAt in past → transitions to Result", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 50) }
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Result")
		end)

		it("Active + endsAt in future → state stays Active", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 50) }
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() + 1.0)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Active")
		end)

		it("T7 expiry resolves winnerId via F4 highest count", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("101", 50),
						makeCSMRecord("102", 80),  -- highest count → winner
						makeCSMRecord("103", 60),
					}
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.getWinnerId()).to.equal("102")
		end)

		it("Result endsAt = now + RESULT_DURATION_SEC (~10s)", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return { makeCSMRecord("101", 50) }
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			local endsAt = MatchStateServer.getStateEndsAt() :: number
			expect(endsAt > os.clock() + 9.5).to.equal(true)
			expect(endsAt < os.clock() + 10.5).to.equal(true)
		end)

		it("empty CSM (all eliminated) → winnerId nil, state still → Result", function()
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {}
				end,
			})
			MatchStateServer._setStateForTests("Active")
			MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)

			MatchStateServer.timerCheck(1)
			expect(MatchStateServer.get()).to.equal("Result")
			expect(MatchStateServer.getWinnerId()).to.equal(nil)
		end)
	end)
end
