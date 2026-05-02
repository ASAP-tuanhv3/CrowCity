--!strict

--[[
	MatchStateServer — F4 tiebreak determinism tests.
	Path: tests/unit/match-state-server/f4_tiebreak.spec.luau
	Implements: MSM story-003 AC-10:
	  Highest count wins. Equal count → earliest peakTimestamp wins. Equal both
	  → argmin(UserId) wins. Result deterministic across 10 runs.
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

	local function fireT7AndGetWinner(): string?
		MatchStateServer._setStateForTests("Active")
		MatchStateServer._setStateEndsAtForTests(os.clock() - 0.01)
		MatchStateServer.timerCheck(1)
		return MatchStateServer.getWinnerId()
	end

	describe("MatchStateServer F4 tiebreak", function()

		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-10: highest count wins outright", function()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock({
				["101"] = 100, ["102"] = 100, ["103"] = 100,
			}) :: any)
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("101", 50),
						makeCSMRecord("102", 80),  -- winner
						makeCSMRecord("103", 75),
					}
				end,
			})
			expect(fireT7AndGetWinner()).to.equal("102")
		end)

		it("AC-10: count tie → earlier peakTimestamp wins", function()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock({
				["101"] = 20.3,  -- later peak
				["102"] = 10.5,  -- earlier peak — winner
			}) :: any)
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("101", 50),
						makeCSMRecord("102", 50),
					}
				end,
			})
			expect(fireT7AndGetWinner()).to.equal("102")
		end)

		it("AC-10: count + timestamp tie → argmin(UserId) wins", function()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock({
				["100"] = 15.0, ["200"] = 15.0,
			}) :: any)
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("200", 50),
						makeCSMRecord("100", 50),
					}
				end,
			})
			expect(fireT7AndGetWinner()).to.equal("100")
		end)

		it("AC-10: nil peakTimestamp → math.huge sentinel (loses to any real timestamp)", function()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock({
				["101"] = 10.0,  -- has timestamp
				-- "102" has no peakTimestamp → math.huge
			}) :: any)
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("101", 50),
						makeCSMRecord("102", 50),
					}
				end,
			})
			expect(fireT7AndGetWinner()).to.equal("101")
		end)

		it("AC-10: deterministic across 10 repeats", function()
			MatchStateServer._setRoundLifecycleOverride(makeRLMock({
				["101"] = 10.0, ["102"] = 20.0, ["103"] = 30.0,
			}) :: any)
			MatchStateServer._setCSMOverride({
				getAllActive = function()
					return {
						makeCSMRecord("101", 50),
						makeCSMRecord("102", 50),
						makeCSMRecord("103", 50),
					}
				end,
			})

			-- Run 10 times; must always pick 101 (earliest peakTimestamp).
			for _ = 1, 10 do
				MatchStateServer._resetForTests()
				MatchStateServer._setRoundLifecycleOverride(makeRLMock({
					["101"] = 10.0, ["102"] = 20.0, ["103"] = 30.0,
				}) :: any)
				MatchStateServer._setCSMOverride({
					getAllActive = function()
						return {
							makeCSMRecord("101", 50),
							makeCSMRecord("102", 50),
							makeCSMRecord("103", 50),
						}
					end,
				})
				expect(fireT7AndGetWinner()).to.equal("101")
			end
		end)
	end)
end
