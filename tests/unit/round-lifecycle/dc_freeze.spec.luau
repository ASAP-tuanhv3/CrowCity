--!strict

--[[
	RoundLifecycle — DC freeze-at-disconnect tests.
	Path: tests/unit/round-lifecycle/dc_freeze.spec.luau
	Implements: RL story-003 ACs:
	  AC-17 (DC freeze)              — PlayerRemoving handler writes eliminationTime,
	                                   keeps record alive, flips survived=false.
	  AC-17 (placements include DC'd) — after setWinner + getPlacements, DC'd player
	                                   appears as Rank 2..N w/ frozen eliminationTime.
	  AC-8 silent guard               — PlayerRemoving for player w/ no record is no-op.
	  DC then Eliminated              — second fire is idempotent no-op.
	  Eliminated then DC              — reverse order, idempotent.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	local function makeCSMMock()
		local countChanged = Instance.new("BindableEvent")
		local crowdEliminatedServer = Instance.new("BindableEvent")
		return {
			create = function(_id: string, _initial: any) end,
			destroy = function(_id: string) end,
			CountChanged = countChanged,
			CrowdEliminatedServer = crowdEliminatedServer,
		}
	end

	describe("RoundLifecycle DC freeze — AC-17", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("AC-17 freezes record: eliminationTime set, record preserved, survived=false", function()
			-- Arrange
			local playerA = makePlayer(101)
			RoundLifecycle.createAll({ playerA })
			-- Simulate count growth so finalCount != initial.
			csm.CountChanged:Fire("101", 10, 150, "Absorb")
			task.wait()
			local tBefore = os.clock()

			-- Act
			RoundLifecycle._handlePlayerRemovingForTest(playerA)

			-- Assert: record still present (NOT removed).
			expect(RoundLifecycle._getCrowdsCount()).to.equal(1)
			-- eliminationTime sandwiched.
			local elimTime = RoundLifecycle._getEliminationTime("101") :: number
			expect(elimTime).never.to.equal(nil)
			expect(elimTime >= tBefore).to.equal(true)
			expect(elimTime <= os.clock()).to.equal(true)
			-- survived flipped false.
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
		end)

		it("AC-17 placements include DC'd player as Rank 2..N w/ frozen elimTime", function()
			-- Arrange: two players, A's count grows to 150 then DCs, B survives.
			local playerA = makePlayer(101)
			local playerB = makePlayer(202)
			RoundLifecycle.createAll({ playerA, playerB })
			csm.CountChanged:Fire("101", 10, 150, "Absorb")
			task.wait()
			RoundLifecycle._handlePlayerRemovingForTest(playerA)
			local frozenElim = RoundLifecycle._getEliminationTime("101") :: number

			-- Act: B wins.
			RoundLifecycle.setWinner("202")
			local placements = RoundLifecycle.getPlacements()

			-- Assert: 2 entries, B = Rank 1, A = Rank 2 w/ eliminated flag + frozen time.
			expect(#placements).to.equal(2)
			expect(placements[1].crowdId).to.equal("202")
			expect(placements[1].isWinner).to.equal(true)
			expect(placements[2].crowdId).to.equal("101")
			expect(placements[2].isWinner).to.equal(false)
			expect(placements[2].wasEliminated).to.equal(true)
			expect(placements[2].crowdCount).to.equal(150)
			expect(placements[2].eliminationTime).to.equal(frozenElim)
		end)

		it("AC-8 silent guard — PlayerRemoving for non-record player is no-op", function()
			RoundLifecycle.createAll({})
			local ghost = makePlayer(999)
			local ok = pcall(function()
				RoundLifecycle._handlePlayerRemovingForTest(ghost)
			end)
			expect(ok).to.equal(true)
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
		end)
	end)

	describe("RoundLifecycle DC freeze — idempotent race", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("DC then Eliminated — second fire is no-op (eliminationTime UNCHANGED)", function()
			local playerA = makePlayer(101)
			RoundLifecycle.createAll({ playerA })

			-- First: DC.
			RoundLifecycle._handlePlayerRemovingForTest(playerA)
			local firstValue = RoundLifecycle._getEliminationTime("101") :: number
			expect(firstValue).never.to.equal(nil)
			task.wait()  -- clock advances

			-- Second: Eliminated for same crowd.
			RoundLifecycle._handleEliminatedForTest("101")

			-- Assert: unchanged.
			expect(RoundLifecycle._getEliminationTime("101")).to.equal(firstValue)
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
		end)

		it("Eliminated then DC — DC fire is no-op (eliminationTime UNCHANGED)", function()
			local playerA = makePlayer(101)
			RoundLifecycle.createAll({ playerA })

			-- First: Eliminated.
			RoundLifecycle._handleEliminatedForTest("101")
			local firstValue = RoundLifecycle._getEliminationTime("101") :: number
			expect(firstValue).never.to.equal(nil)
			task.wait()

			-- Second: DC.
			RoundLifecycle._handlePlayerRemovingForTest(playerA)

			-- Assert: unchanged.
			expect(RoundLifecycle._getEliminationTime("101")).to.equal(firstValue)
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
		end)
	end)

	describe("RoundLifecycle DC freeze — subscription cleanup", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("destroyAll clears DC handler via Janitor — no error", function()
			RoundLifecycle.createAll({ makePlayer(101) })
			-- Destroying clears Janitor; subsequent calls would not fire.
			-- We can't fire Players.PlayerRemoving from a test, but verify
			-- _janitor is nil + _crowds cleared per destroyAll contract.
			RoundLifecycle.destroyAll()
			expect(RoundLifecycle._getJanitor()).to.equal(nil)
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
		end)
	end)
end
