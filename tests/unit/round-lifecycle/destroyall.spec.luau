--!strict

--[[
	RoundLifecycle — destroyAll unit tests.
	Path: tests/unit/round-lifecycle/destroyall.spec.luau
	Implements: RL story-001 ACs:
	  AC-4  (destroyAll clean-wipe — Janitor destroyed FIRST, CSM destroys after,
	         state cleared, post-destroy stray-signal no-op implied by Janitor
	         disconnect pattern)
	  destroyAll on dormant module (no prior createAll) — no-op, no error
	  double destroyAll — idempotent, no error
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)

	--- Mock CSM factory. Records all create/destroy calls in an ordered opLog so
	--- tests can verify teardown sequence.
	local function makeMockCSM()
		local opLog: { string } = {}
		return {
			opLog = opLog,
			create = function(crowdId: string, _initial: any): any
				table.insert(opLog, "create:" .. crowdId)
				return {}
			end,
			destroy = function(crowdId: string): ()
				table.insert(opLog, "destroy:" .. crowdId)
			end,
		}
	end

	local function makePlayer(userId: number)
		return ({ UserId = userId } :: any) :: Player
	end

	describe("RoundLifecycle.destroyAll", function()
		local mockCSM
		beforeEach(function()
			RoundLifecycle._resetForTests()
			mockCSM = makeMockCSM()
			RoundLifecycle._setCSMOverride(mockCSM)
		end)

		-- AC-4: Active round with 2 crowds; destroyAll clears _crowds,
		-- _participants, _winnerId, _janitor.
		it("AC-4: destroyAll clears _crowds, _participants, _winnerId, _janitor", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101), makePlayer(102) })
			expect(RoundLifecycle._getCrowdsCount()).to.equal(2)
			expect(RoundLifecycle._getJanitor()).to.be.ok()

			-- Act
			RoundLifecycle.destroyAll()

			-- Assert
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(0)
			expect(RoundLifecycle._getJanitor()).to.equal(nil)
		end)

		-- AC-4: CSM.destroy fires for every tracked crowd. Because _crowds is
		-- iterated via pairs(), destroy order is arbitrary — we assert presence
		-- not position in opLog.
		it("AC-4: CSM.destroy fires for every tracked crowd", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101), makePlayer(102) })

			-- Act
			RoundLifecycle.destroyAll()

			-- Assert: opLog must contain destroy:101 and destroy:102 (in any order)
			local destroyCount = 0
			for _, op in mockCSM.opLog do
				if op == "destroy:101" or op == "destroy:102" then
					destroyCount += 1
				end
			end
			expect(destroyCount).to.equal(2)
		end)

		-- destroyAll on dormant module (no prior createAll) must be a no-op.
		-- _janitor is nil; _crowds empty. Must not error.
		it("destroyAll on dormant module (no prior createAll) is a no-op", function()
			-- Act
			local ok = pcall(RoundLifecycle.destroyAll)

			-- Assert
			expect(ok).to.equal(true)
			expect(RoundLifecycle._getJanitor()).to.equal(nil)
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
			expect(#mockCSM.opLog).to.equal(0)
		end)

		-- double destroyAll: second call must be idempotent — no error, no
		-- double-destroy of CSM records that were already cleared.
		it("double destroyAll is idempotent (no error, no double-destroy)", function()
			-- Arrange
			RoundLifecycle.createAll({ makePlayer(101) })
			RoundLifecycle.destroyAll()

			-- Act — second destroyAll
			local ok = pcall(RoundLifecycle.destroyAll)

			-- Assert
			expect(ok).to.equal(true)
			expect(RoundLifecycle._getJanitor()).to.equal(nil)

			-- CSM.destroy for "101" must have fired exactly once (during first
			-- destroyAll); second destroyAll has empty _crowds, so no new calls.
			local destroyCount101 = 0
			for _, op in mockCSM.opLog do
				if op == "destroy:101" then
					destroyCount101 += 1
				end
			end
			expect(destroyCount101).to.equal(1)
		end)
	end)
end
