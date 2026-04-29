--!strict

--[[
	RoundLifecycle — createAll unit tests.
	Path: tests/unit/round-lifecycle/createall.spec.luau
	Implements: RL story-001 ACs:
	  AC-1  (createAll success — Janitor allocated + aux records + CSM creates)
	  AC-2  (createAll pcall failure — partial failure skips player; others tracked)
	  MAX_PARTICIPANTS guard (13 players → assert; 12 → succeeds)
	  Empty participants (Janitor allocated; no CSM calls; empty crowds)
	  Hue assignment (12 players → hues 1..12 by index)
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)

	--- Mock CSM factory. Records create/destroy call order.
	--- Supports per-id failure injection via failOnIds.
	local function makeMockCSM()
		local createdIds: { string } = {}
		local destroyedIds: { string } = {}
		local failOnIds: { [string]: string } = {}

		return {
			createdIds = createdIds,
			destroyedIds = destroyedIds,
			failOnIds = failOnIds,
			create = function(crowdId: string, _initial: any): any
				if failOnIds[crowdId] then
					error(failOnIds[crowdId])
				end
				table.insert(createdIds, crowdId)
				return {}
			end,
			destroy = function(crowdId: string): ()
				table.insert(destroyedIds, crowdId)
			end,
		}
	end

	local function makePlayer(userId: number)
		return ({ UserId = userId } :: any) :: Player
	end

	describe("RoundLifecycle.createAll", function()
		local mockCSM
		beforeEach(function()
			RoundLifecycle._resetForTests()
			mockCSM = makeMockCSM()
			RoundLifecycle._setCSMOverride(mockCSM)
		end)

		-- AC-1: Two-player happy path — Janitor allocated, 2 aux records, 2 CSM
		-- creates. Verifies crowdIds are tostring(UserId) in insertion order.
		it("AC-1: 2-player createAll allocates Janitor + 2 aux records + 2 CSM creates", function()
			-- Arrange
			local players = { makePlayer(101), makePlayer(102) }

			-- Act
			RoundLifecycle.createAll(players)

			-- Assert
			expect(RoundLifecycle._getJanitor()).to.be.ok()
			expect(RoundLifecycle._getCrowdsCount()).to.equal(2)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(2)
			expect(#mockCSM.createdIds).to.equal(2)
			expect(mockCSM.createdIds[1]).to.equal("101")
			expect(mockCSM.createdIds[2]).to.equal("102")
		end)

		-- AC-2: CSM.create throws for player 101 but succeeds for 102.
		-- 101 must be absent from _crowds and _participants; 102 must be present.
		it("AC-2: CSM.create failure for one player — other player still tracked", function()
			-- Arrange
			mockCSM.failOnIds["101"] = "synthetic-csm-error"

			-- Act
			RoundLifecycle.createAll({ makePlayer(101), makePlayer(102) })

			-- Assert: only 102 tracked
			expect(RoundLifecycle._getCrowdsCount()).to.equal(1)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(1)
			expect(#mockCSM.createdIds).to.equal(1)
			expect(mockCSM.createdIds[1]).to.equal("102")
		end)

		-- AC-2 edge: all players fail — Janitor still allocated (empty round).
		-- _crowds + _participants empty; no participants in CSM.
		it("AC-2 edge: all-players-fail still allocates Janitor (empty round)", function()
			-- Arrange
			mockCSM.failOnIds["101"] = "err1"
			mockCSM.failOnIds["102"] = "err2"

			-- Act
			RoundLifecycle.createAll({ makePlayer(101), makePlayer(102) })

			-- Assert
			expect(RoundLifecycle._getJanitor()).to.be.ok()
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(0)
		end)

		-- MAX_PARTICIPANTS guard: 13 players → assert fires; 12 → succeeds.
		-- Verifies the guard fires BEFORE any mutation (Janitor stays nil).
		it("MAX_PARTICIPANTS guard: 13 players → assert; 12 succeeds", function()
			-- Arrange — 13 players
			local players13: { Player } = {}
			for i = 1, 13 do
				table.insert(players13, makePlayer(i))
			end

			-- Act + Assert — 13 should fail
			local ok = pcall(RoundLifecycle.createAll, players13)
			expect(ok).to.equal(false)

			-- _janitor must still be nil (assert fired before allocation)
			expect(RoundLifecycle._getJanitor()).to.equal(nil)

			-- Reset and try exactly 12 — must succeed
			RoundLifecycle._resetForTests()
			RoundLifecycle._setCSMOverride(mockCSM)
			local players12: { Player } = {}
			for i = 1, 12 do
				table.insert(players12, makePlayer(100 + i))
			end
			RoundLifecycle.createAll(players12)
			expect(RoundLifecycle._getCrowdsCount()).to.equal(12)
		end)

		-- Empty participants: Janitor allocated; _crowds + _participants empty;
		-- no CSM.create calls. Supports T5 round-start edge (no participants).
		it("empty participants list: Janitor allocated; no CSM calls", function()
			-- Act
			RoundLifecycle.createAll({})

			-- Assert
			expect(RoundLifecycle._getJanitor()).to.be.ok()
			expect(RoundLifecycle._getCrowdsCount()).to.equal(0)
			expect(RoundLifecycle._getParticipantsCount()).to.equal(0)
			expect(#mockCSM.createdIds).to.equal(0)
		end)

		-- Hue assignment: 12 players → hues 1..12 by index (1-indexed, wraps at 12).
		-- Uses mockCSM.create override to capture the initial.hue per crowdId.
		it("hue assignment: 12 players → hues 1..12 by index", function()
			-- Arrange — intercept create to capture hue from initial table
			local capturedHues: { [string]: number } = {}
			mockCSM.create = function(crowdId: string, initial: any): any
				capturedHues[crowdId] = initial.hue
				return {}
			end
			local players: { Player } = {}
			for i = 1, 12 do
				table.insert(players, makePlayer(200 + i))
			end

			-- Act
			RoundLifecycle.createAll(players)

			-- Assert: player at index i gets hue i
			for i = 1, 12 do
				expect(capturedHues[tostring(200 + i)]).to.equal(i)
			end
		end)
	end)
end
