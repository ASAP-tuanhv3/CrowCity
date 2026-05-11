--!strict

--[[
	MatchStateServer AFKToggle 4-check validation — unit tests.
	Path: tests/unit/match-state-server/afktoggle_validation.spec.luau

	Story 7-10 (Sprint 7) / match-state-server story-007.
	Covers ADR-0010 4-check guard on AFKToggle handler:
	  1. Identity check — server uses engine player arg, ignores payload.userId
	  2. State check — only Lobby / Countdown:Ready allow toggle
	  3. Parameters check — payload.participating MUST be boolean
	  4. Rate check — token-bucket via RemoteValidator (RateLimitConfig.AFKToggle)

	Failed validation = silent reject. _setParticipation NOT invoked.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local MatchStateServer = require(ServerStorage.Source.MatchStateServer)
	local RemoteValidator = require(ServerStorage.Source.RemoteValidator)

	local function makePlayer(userId: number): any
		return { UserId = userId, Name = "P" .. userId }
	end

	describe("MatchStateServer AFKToggle 4-check validation — Story 7-10", function()
		beforeEach(function()
			MatchStateServer._resetForTests()
			RemoteValidator._resetForTest()
			-- Override identity check: production checks typeof(player)=="Instance",
			-- tests use plain table mocks. Accept any table with `UserId` field.
			RemoteValidator._setIdentityCheckOverrideForTest(function(p)
				return type(p) == "table" and type(p.UserId) == "number"
			end)
		end)

		afterEach(function()
			RemoteValidator._resetForTest()
		end)

		-- Happy path: valid payload in Lobby → _setParticipation flips.
		it("AC-7 happy path — valid AFKToggle in Lobby: participation flag updated", function()
			-- Arrange: player starts NOT participating; state = Lobby (default).
			local player = makePlayer(101)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)

			-- Act: client fires AFKToggle with {participating=true}
			MatchStateServer._handleAFKToggleForTest(player, { participating = true })

			-- Assert: _setParticipation called → participation now true
			expect(MatchStateServer.getParticipation(player)).to.equal(true)
		end)

		-- Identity check: payload.userId IGNORED — handler uses engine player arg.
		-- Spoofed payload with extra userId field is rejected by checkParameters
		-- whitelist semantics (extra fields not in schema → reject). Either way,
		-- A's identity is not spoofable to be B.
		it("Check 1 (identity) — payload.userId spoof rejected by whitelist; B untouched", function()
			-- Arrange: 2 players; A fires payload claiming to be B
			local playerA = makePlayer(101)
			local playerB = makePlayer(202)

			-- Act: A fires with spoofed userId=B payload (extra field)
			MatchStateServer._handleAFKToggleForTest(
				playerA,
				{ participating = true, userId = playerB.UserId }  -- extra field
			)

			-- Assert: rejected (whitelist enforces no extra fields).
			-- A's flag NOT flipped. B's flag never touched.
			expect(MatchStateServer.getParticipation(playerA)).to.equal(false)
			expect(MatchStateServer.getParticipation(playerB)).to.equal(false)

			-- Clean payload (no extras) → A's flag flips correctly.
			MatchStateServer._handleAFKToggleForTest(playerA, { participating = true })
			expect(MatchStateServer.getParticipation(playerA)).to.equal(true)
			expect(MatchStateServer.getParticipation(playerB)).to.equal(false)
		end)

		-- State check: Active state rejects toggle (only Lobby / Countdown:Ready allowed).
		it("Check 2 (state) — AFKToggle during Active state silently rejected", function()
			local player = makePlayer(101)
			MatchStateServer._setStateForTests("Active")

			MatchStateServer._handleAFKToggleForTest(player, { participating = true })

			-- Assert: rejected (no participation flip)
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		-- State check edge: Countdown:Snap freeze rule. TRUE→FALSE in Snap rejected.
		-- Note: full Snap freeze rule lives in _setParticipation (defense in depth);
		-- handler state check rejects ALL toggles in Snap to be safe.
		it("Check 2 (state) edge — AFKToggle during Countdown:Snap rejected", function()
			local player = makePlayer(101)
			MatchStateServer._setParticipation(player, true)
			MatchStateServer._setStateForTests("Countdown:Snap")

			MatchStateServer._handleAFKToggleForTest(player, { participating = false })

			expect(MatchStateServer.getParticipation(player)).to.equal(true)
		end)

		-- Parameters check: non-boolean payload.participating → rejected.
		it("Check 3 (parameters) — payload.participating is string: rejected", function()
			local player = makePlayer(101)

			-- Act: send string instead of boolean
			MatchStateServer._handleAFKToggleForTest(player, { participating = "yes" })

			-- Assert: rejected
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		-- Parameters check: missing field → rejected.
		it("Check 3 (parameters) — payload missing participating field: rejected", function()
			local player = makePlayer(101)

			MatchStateServer._handleAFKToggleForTest(player, {})

			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)

		-- Rate check: AFKToggle config = rate 0.4, burst 2. 3rd call within burst
		-- window → 3rd call rejected (bucket exhausted).
		it("Check 4 (rate) — 3rd toggle within burst window rejected", function()
			local player = makePlayer(101)

			-- Toggle 1: should succeed (burst=2 available)
			MatchStateServer._handleAFKToggleForTest(player, { participating = true })
			expect(MatchStateServer.getParticipation(player)).to.equal(true)

			-- Toggle 2: should succeed (1 burst remaining)
			MatchStateServer._handleAFKToggleForTest(player, { participating = false })
			expect(MatchStateServer.getParticipation(player)).to.equal(false)

			-- Toggle 3: bucket exhausted (0 tokens, regen too slow) → reject
			MatchStateServer._handleAFKToggleForTest(player, { participating = true })
			-- Last successful toggle was false; rate-rejected toggle should NOT flip
			expect(MatchStateServer.getParticipation(player)).to.equal(false)
		end)
	end)
end
