--!strict

--[[
	RoundLifecycle — F2 Eliminated subscription + idempotent eliminationTime.
	Path: tests/unit/round-lifecycle/eliminated_subscription.spec.luau
	Implements: RL story-003 ACs:
	  AC-9 (first fire)  — `eliminationTime` written once between tBefore and now;
	                       `survived` flipped to false.
	  AC-9 (idempotent)  — second fire leaves `eliminationTime` UNCHANGED.
	  AC-8 (silent guard) — non-record crowdId fire is no-op (no error).
	  Subscription wired in createAll via CrowdEliminatedServer BindableEvent.
	  Subscription disposed in destroyAll — stray fires post-destroy are no-op.
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

	describe("RoundLifecycle F2 — Eliminated handler direct (test seam)", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("AC-9 first fire — eliminationTime written + survived=false", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101) })
			expect(RoundLifecycle._getEliminationTime("101")).to.equal(nil)
			expect(RoundLifecycle._getSurvived("101")).to.equal(true)
			local tBefore = os.clock()

			-- Act
			RoundLifecycle._handleEliminatedForTest("101")

			-- Assert: eliminationTime sandwiched between tBefore and now.
			local elimTime = RoundLifecycle._getEliminationTime("101") :: number
			expect(elimTime).never.to.equal(nil)
			expect(elimTime >= tBefore).to.equal(true)
			expect(elimTime <= os.clock()).to.equal(true)
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
		end)

		it("AC-9 idempotent — second fire leaves eliminationTime UNCHANGED", function()
			-- Arrange: first fire
			RoundLifecycle.createAll({ makePlayer(101) })
			RoundLifecycle._handleEliminatedForTest("101")
			local firstValue = RoundLifecycle._getEliminationTime("101") :: number
			expect(firstValue).never.to.equal(nil)
			task.wait()  -- ensure clock advances

			-- Act: second fire
			RoundLifecycle._handleEliminatedForTest("101")

			-- Assert: unchanged
			expect(RoundLifecycle._getEliminationTime("101")).to.equal(firstValue)
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
		end)

		it("AC-8 silent guard — fire for non-record crowdId is no-op", function()
			RoundLifecycle.createAll({})
			local ok = pcall(function()
				RoundLifecycle._handleEliminatedForTest("ghost")
			end)
			expect(ok).to.equal(true)
			expect(RoundLifecycle._getEliminationTime("ghost")).to.equal(nil)
		end)
	end)

	describe("RoundLifecycle F2 — Eliminated subscription wiring", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("createAll subscribes — firing BindableEvent fires _onEliminated", function()
			RoundLifecycle.createAll({ makePlayer(101) })
			local tBefore = os.clock()

			csm.CrowdEliminatedServer:Fire("101")
			task.wait()

			local elimTime = RoundLifecycle._getEliminationTime("101") :: number
			expect(elimTime).never.to.equal(nil)
			expect(elimTime >= tBefore).to.equal(true)
		end)

		it("destroyAll disconnects — subsequent BindableEvent fires no-op", function()
			RoundLifecycle.createAll({ makePlayer(101) })
			RoundLifecycle.destroyAll()

			local ok = pcall(function()
				csm.CrowdEliminatedServer:Fire("101")
				task.wait()
			end)
			expect(ok).to.equal(true)
			-- _crowds was cleared by destroyAll → no record to query.
			expect(RoundLifecycle._getEliminationTime("101")).to.equal(nil)
		end)
	end)

	describe("RoundLifecycle F2 — multi-record isolation", function()
		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("eliminating one crowd does not touch others", function()
			RoundLifecycle.createAll({
				makePlayer(101),
				makePlayer(102),
				makePlayer(103),
			})

			RoundLifecycle._handleEliminatedForTest("101")

			expect(RoundLifecycle._getEliminationTime("101")).never.to.equal(nil)
			expect(RoundLifecycle._getSurvived("101")).to.equal(false)
			expect(RoundLifecycle._getEliminationTime("102")).to.equal(nil)
			expect(RoundLifecycle._getSurvived("102")).to.equal(true)
			expect(RoundLifecycle._getEliminationTime("103")).to.equal(nil)
			expect(RoundLifecycle._getSurvived("103")).to.equal(true)
		end)
	end)
end
