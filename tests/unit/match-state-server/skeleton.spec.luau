--!strict

--[[
	MatchStateServer — skeleton + public API surface tests.
	Story-001 (Sprint 2-8): AC-1 (Lobby boot), public surface, no public
	transitionTo, getStateEndsAt nil at boot, 7-state enum compile + runtime.

	Spec: production/epics/match-state-server/story-001-module-skeleton-state-enum-participation-flags.md
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)

	describe("MatchStateServer skeleton + public API surface", function()
		beforeEach(function()
			MatchStateServer._resetForTests()
		end)

		it("AC-1: boot default is Lobby", function()
			expect(MatchStateServer.get()).to.equal("Lobby")
		end)

		it("public surface: get / getParticipation / getStateEndsAt / start are functions", function()
			expect(typeof(MatchStateServer.get)).to.equal("function")
			expect(typeof(MatchStateServer.getParticipation)).to.equal("function")
			expect(typeof(MatchStateServer.getStateEndsAt)).to.equal("function")
			expect(typeof(MatchStateServer.start)).to.equal("function")
		end)

		it("no public transitionTo (internal-only per ADR-0005)", function()
			expect((MatchStateServer :: any).transitionTo).to.equal(nil)
		end)

		it("getStateEndsAt is nil at boot (Lobby is non-timed)", function()
			expect(MatchStateServer.getStateEndsAt()).to.equal(nil)
		end)

		it("MatchState type accepts canonical 7 strings (compile + runtime check)", function()
			-- Runtime portion: each of these is a valid string assignable to MatchState.
			-- Compile-time strict-mode would reject "Foo" :: MatchState (validated by LSP).
			local validStates: { MatchStateServer.MatchState } = {
				"Lobby",
				"Countdown:Ready",
				"Countdown:Snap",
				"Active",
				"Result",
				"Intermission",
				"ServerClosing",
			}
			expect(#validStates).to.equal(7)
			for _, s in validStates do
				MatchStateServer._setStateForTests(s)
				expect(MatchStateServer.get()).to.equal(s)
			end
		end)
	end)
end
