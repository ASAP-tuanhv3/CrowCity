--!strict

-- Unit tests for MVP PlayerDataKey schema lock (Story 001, player-data-schema epic).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (7 keys), AC-2 (defaults integrity), AC-3 (no Pillar 3 forbidden keys),
--         AC-4 (Pillar 4 categories), AC-5 (--!strict — proxy), AC-6 (bidirectional),
--         AC-7 (no VS+/Alpha+ leak)
-- Source of truth: ADR-0011 §MVP PlayerDataKey Schema (Amended 2026-04-27).

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")

	local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
	local DefaultPlayerData = require(ServerStorage.Source.DefaultPlayerData)
	local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

	-- Canonical 7-key MVP scope per ADR-0011 §MVP PlayerDataKey Schema (Amended 2026-04-27).
	local MVP_KEYS = {
		"Coins",
		"OwnedSkins",
		"SelectedSkin",
		"LifetimeAbsorbs",
		"LifetimeWins",
		"FtueStage",
		"Inventory",
	}

	-- Pillar 3 forbidden-class string fragments per ADR-0011 §Pillar 3 Forbidden Keys.
	-- Case-insensitive substring match on key names to catch class drift
	-- (e.g. `RoundCoins`, `currentRadius`, `OpenedChestIds` would all flag).
	local PILLAR_3_FORBIDDEN_FRAGMENTS = {
		"currentcount",
		"currentradius",
		"currenthue",
		"currentposition",
		"activecrowdid",
		"ownedrelics",
		"activerelics",
		"relichistory",
		"openedchestids",
		"chestcooldowns",
		"lastchestopentime",
		"eliminationcount",
		"lasteliminationtime",
		"iseliminated",
		"peakcount",
		"bestplacement",
		"lastplacement",
		"lastvfxid",
		"activeparticlecount",
		"ownednpcs",
		"npckills",
		"npcrespawntimers",
		"lastmatchstate",
		"lastmatchendtime",
		"participationflag",
		"absorbbonusmultiplier",
		"radiusboost",
		"raredraftrollchance",
		"friends",
		"blockedplayers",
		"mailbox",
		"lastroundreplay",
		"matchhistorydetails",
	}

	-- VS+ / Alpha+ keys that MUST NOT appear in MVP (gated by future _schemaVersion bumps).
	local DEFERRED_KEYS = {
		"DailyQuestState",
		"LastDailyResetTime",
		"AnalyticsOptIn",
		"AccessibilitySettings",
		"LastShopRefreshTime",
	}

	describe("PlayerDataKey", function()

		-- AC-1: enum exact-match — 7 keys.
		it("contains exactly the 7 MVP keys", function()
			for _, key in MVP_KEYS do
				expect(type((PlayerDataKey :: any)[key])).to.equal("string")
				expect((PlayerDataKey :: any)[key]).to.equal(key)
			end

			local count = 0
			for _ in pairs(PlayerDataKey) do
				count += 1
			end
			expect(count).to.equal(7)
		end)

		-- AC-3: no Pillar 3 forbidden-class keys present.
		-- Case-insensitive substring scan against the catalog from ADR-0011.
		it("contains zero Pillar 3 forbidden-class keys", function()
			for key, _ in PlayerDataKey do
				local lowered = string.lower(key)
				for _, forbidden in PILLAR_3_FORBIDDEN_FRAGMENTS do
					expect(string.find(lowered, forbidden, 1, true) == nil).to.equal(true)
				end
			end
		end)

		-- AC-7: no VS+ / Alpha+ keys leak into MVP enum.
		it("contains zero deferred VS+ / Alpha+ keys", function()
			for _, deferredKey in DEFERRED_KEYS do
				expect((PlayerDataKey :: any)[deferredKey]).to.equal(nil)
			end
		end)

	end)

	describe("DefaultPlayerData", function()

		-- AC-2: defaults integrity — 7 keys + _schemaVersion = 1.
		it("contains _schemaVersion = 1", function()
			expect(DefaultPlayerData._schemaVersion).to.equal(1)
		end)

		it("contains all 7 MVP keys with correct default shapes", function()
			expect(DefaultPlayerData[PlayerDataKey.Coins]).to.equal(0)
			expect(type(DefaultPlayerData[PlayerDataKey.OwnedSkins])).to.equal("table")
			expect(DefaultPlayerData[PlayerDataKey.SelectedSkin]).to.equal("Default")
			expect(DefaultPlayerData[PlayerDataKey.LifetimeAbsorbs]).to.equal(0)
			expect(DefaultPlayerData[PlayerDataKey.LifetimeWins]).to.equal(0)
			expect(DefaultPlayerData[PlayerDataKey.FtueStage]).to.equal(FtueStage.Stage1)
			expect(type(DefaultPlayerData[PlayerDataKey.Inventory])).to.equal("table")
		end)

		-- Anti-P2W: Coins must default to zero (anti-P2W per ADR-0011).
		it("Coins default is zero (anti-P2W)", function()
			expect(DefaultPlayerData[PlayerDataKey.Coins]).to.equal(0)
		end)

		-- AC-7 again at defaults level: no VS+ / Alpha+ keys leak into defaults.
		it("contains zero deferred VS+ / Alpha+ keys", function()
			for _, deferredKey in DEFERRED_KEYS do
				expect((DefaultPlayerData :: any)[deferredKey]).to.equal(nil)
			end
		end)

	end)

	describe("Bidirectional consistency (AC-6)", function()

		-- AC-6: every PlayerDataKey entry has a DefaultPlayerData default.
		it("every PlayerDataKey has a corresponding DefaultPlayerData entry", function()
			for _, keyValue in PlayerDataKey do
				expect(DefaultPlayerData[keyValue] ~= nil).to.equal(true)
			end
		end)

		-- AC-6: every DefaultPlayerData entry (except _schemaVersion meta) is in PlayerDataKey.
		it("every DefaultPlayerData entry (except _schemaVersion) appears in PlayerDataKey", function()
			-- Build set of declared key values for membership check.
			local declaredKeys: { [string]: true } = {}
			for _, keyValue in PlayerDataKey do
				declaredKeys[keyValue] = true
			end

			for defaultKey, _ in DefaultPlayerData do
				if defaultKey == "_schemaVersion" then
					continue
				end
				expect(declaredKeys[defaultKey :: string] == true).to.equal(true)
			end
		end)

	end)

	describe("Pillar 4 category contract (AC-4)", function()

		-- ADVISORY: Category-comment introspection requires source-byte read; TestEZ runs
		-- against compiled module values only. This probe verifies that all 7 keys load
		-- as strings; the comment-block category labelling is verified at /story-done by
		-- manual review of PlayerDataKey.luau top-of-file documentation block.
		it("all 7 MVP keys load as strings (category-comment review deferred to /story-done)", function()
			for _, key in MVP_KEYS do
				expect(type((PlayerDataKey :: any)[key])).to.equal("string")
			end
		end)

	end)

	describe("AC-5 type contract (proxy)", function()

		-- AC-5 ADVISORY: `--!strict` is a compile-time directive; Selene CI + Luau LSP
		-- in Studio enforce it. EnumType string-union export gives stronger consumer
		-- typing than a plain `string` alias — verified at compile time, not runtime.
		it("PlayerDataKey.Coins satisfies EnumType (string) contract at runtime", function()
			local id: PlayerDataKey.EnumType = PlayerDataKey.Coins
			expect(type(id)).to.equal("string")
		end)

	end)

end
