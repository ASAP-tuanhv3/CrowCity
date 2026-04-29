--!strict

--[[
	RoundLifecycle — double createAll assertion unit tests.
	Path: tests/unit/round-lifecycle/double_createall_assert.spec.luau
	Implements: RL story-001 ACs:
	  AC-3  (double createAll without destroyAll → assert fires BEFORE mutation;
	         _crowds + _participants unchanged from first call)
	  Round cycle: createAll → destroyAll → createAll succeeds (round re-use).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)

	local function makeMockCSM()
		return {
			create = function(_crowdId: string, _initial: any): any
				return {}
			end,
			destroy = function(_crowdId: string): ()
			end,
		}
	end

	local function makePlayer(userId: number)
		return ({ UserId = userId } :: any) :: Player
	end

	describe("RoundLifecycle.createAll double-call assertion", function()
		beforeEach(function()
			RoundLifecycle._resetForTests()
			RoundLifecycle._setCSMOverride(makeMockCSM())
		end)

		-- AC-3: Module is Active (prior createAll succeeded); second createAll
		-- without destroyAll must assert. Error must be a string (from assert()).
		it("AC-3: double createAll without destroyAll fires assert", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101) })

			-- Act + Assert
			local ok, err = pcall(RoundLifecycle.createAll, { makePlayer(102) })
			expect(ok).to.equal(false)
			expect(typeof(err)).to.equal("string")
		end)

		-- AC-3: Assert must fire BEFORE any mutation. _crowds and _participants
		-- must remain exactly as left by the first (successful) createAll.
		it("AC-3: state unchanged after assert (no mutation pre-error)", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101) })
			local crowdsAfterFirst = RoundLifecycle._getCrowdsCount()
			local participantsAfterFirst = RoundLifecycle._getParticipantsCount()
			expect(crowdsAfterFirst).to.equal(1)
			expect(participantsAfterFirst).to.equal(1)

			-- Act — attempt second createAll (should fail)
			pcall(RoundLifecycle.createAll, { makePlayer(102), makePlayer(103) })

			-- Assert — state unchanged
			expect(RoundLifecycle._getCrowdsCount()).to.equal(1)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(1)
		end)

		-- Round cycle: createAll → destroyAll → createAll must succeed.
		-- Verifies that destroyAll correctly resets _janitor to nil so the
		-- next createAll passes its guard. The new crowd (102) must be tracked.
		it("createAll → destroyAll → createAll succeeds (round cycle)", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101) })
			RoundLifecycle.destroyAll()

			-- Act
			local ok = pcall(RoundLifecycle.createAll, { makePlayer(102) })

			-- Assert
			expect(ok).to.equal(true)
			expect(RoundLifecycle._getCrowdsCount()).to.equal(1)
			expect(RoundLifecycle._getJanitor()).to.be.ok()
		end)
	end)
end
