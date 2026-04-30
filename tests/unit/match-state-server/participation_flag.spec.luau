--!strict

--[[
	MatchStateServer — participation flag tests.
	Story-001 (Sprint 2-8): AC-2 (PlayerAdded auto-set), PlayerRemoving clears,
	default false for unknown player, start() idempotent, connections wired.

	Note: cannot fire real Players.PlayerAdded from TestEZ. Handler logic is
	verified via direct _setParticipation calls; start() idempotence verified
	by comparing connection identities.

	Spec: production/epics/match-state-server/story-001-module-skeleton-state-enum-participation-flags.md
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	local function makePlayer(userId: number)
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	describe("MatchStateServer participation flags", function()
		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("default participation is false for unknown player", function()
			expect(MatchStateServer.getParticipation(makePlayer(101))).to.equal(false)
		end)

		it("AC-2: _setParticipation(player, true) flips flag to true", function()
			-- Real PlayerAdded handler simply calls _setParticipation(player, true).
			-- Functional equivalence verified here without firing the actual signal.
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			expect(MatchStateServer.getParticipation(player)).to.equal(true)
		end)

		it("PlayerRemoving handler clears participation entry (functional equivalence)", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			expect(MatchStateServer.getParticipation(player)).to.equal(true)
			-- PlayerRemoving body sets _participation[uid] = nil; for getParticipation
			-- purposes this is equivalent to false (both yield false).
			MatchStateServer._setParticipation(player, false)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		it("start() wires PlayerAdded + PlayerRemoving connections", function()
			expect(MatchStateServer._getPlayerAddedConnection()).to.equal(nil)
			expect(MatchStateServer._getPlayerRemovingConnection()).to.equal(nil)
			MatchStateServer.start()
			expect(MatchStateServer._getPlayerAddedConnection()).to.be.ok()
			expect(MatchStateServer._getPlayerRemovingConnection()).to.be.ok()
			-- AFKToggle wiring deferred to story-007 (ADR-0010 4-check guard
			-- must wrap the handler before it accepts traffic). Connection
			-- stays nil until that story.
			expect(MatchStateServer._getAFKToggleConnection()).to.equal(nil)
		end)

		it("start() is idempotent (second call reuses existing connections)", function()
			MatchStateServer.start()
			local conn1 = MatchStateServer._getPlayerAddedConnection()
			MatchStateServer.start()
			local conn2 = MatchStateServer._getPlayerAddedConnection()
			expect(conn1).to.equal(conn2)
		end)
	end)
end
