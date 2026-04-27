--!strict

-- Unit tests for RemoteEventName + RemoteFunctionName extensions (Story 002, network-layer-ext).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (22 RemoteEventName entries), AC-2 (GetParticipation),
--         AC-3 (RemoteEvent instances post-boot — proxy), AC-4 (RemoteFunction instances post-boot — proxy),
--         AC-5 (uniqueness), AC-6 (--!strict — proxy), AC-7 (grep gate — out-of-band)
-- Source of truth: architecture.md §5.7 wire contracts.

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
	local RemoteFunctionName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteFunctionName)

	-- The 22 RemoteEvent entries this story adds (from architecture.md §5.7).
	local NEW_REMOTE_EVENTS = {
		"MatchStateChanged",
		"ParticipationChanged",
		"CrowdCreated",
		"CrowdDestroyed",
		"CrowdEliminated",
		"CrowdCountClamped",
		"CrowdRelicChanged",
		"ChestInteract",
		"ChestDraftOffer",
		"ChestDraftPick",
		"ChestStateChanged",
		"ChestPeelOff",
		"ChestDraftOpenFX",
		"ChestOpenBurst",
		"Absorbed",
		"HueShift",
		"CollisionContactEvent",
		"RelicGrantVFX",
		"RelicExpireVFX",
		"RelicDraftPick",
		"AFKToggle",
		"NpcPoolBootstrap",
	}

	-- Pre-existing template entries that MUST be preserved.
	local TEMPLATE_REMOTE_EVENTS = {
		"PlayerDataLoaded",
		"PlayerDataUpdated",
		"PlayerDataSaved",
		"ResetData",
	}

	describe("RemoteEventName (AC-1)", function()

		it("contains all 22 architecture.md §5.7 entries", function()
			for _, name in NEW_REMOTE_EVENTS do
				expect((RemoteEventName :: any)[name]).to.equal(name)
			end
		end)

		it("preserves all 4 pre-existing template entries", function()
			for _, name in TEMPLATE_REMOTE_EVENTS do
				expect((RemoteEventName :: any)[name]).to.equal(name)
			end
		end)

		it("has total entry count of 26 (4 template + 22 §5.7)", function()
			local count = 0
			for _ in pairs(RemoteEventName) do
				count += 1
			end
			expect(count).to.equal(26)
		end)

	end)

	describe("RemoteFunctionName (AC-2)", function()

		it("contains GetParticipation", function()
			expect(RemoteFunctionName.GetParticipation).to.equal("GetParticipation")
		end)

		it("preserves pre-existing RequestItemPurchase template entry", function()
			expect(RemoteFunctionName.RequestItemPurchase).to.equal("RequestItemPurchase")
		end)

	end)

	describe("Uniqueness (AC-5)", function()

		it("RemoteEventName values are unique", function()
			local seen: { [string]: string } = {}
			for key, value in RemoteEventName do
				expect(seen[value] == nil).to.equal(true)
				seen[value] = key
			end
		end)

		it("RemoteFunctionName values are unique", function()
			local seen: { [string]: string } = {}
			for key, value in RemoteFunctionName do
				expect(seen[value] == nil).to.equal(true)
				seen[value] = key
			end
		end)

		it("every value equals its key (template idiom)", function()
			for key, value in RemoteEventName do
				expect(value).to.equal(key)
			end
			for key, value in RemoteFunctionName do
				expect(value).to.equal(key)
			end
		end)

	end)

	describe("Boot-time instance creation (AC-3 + AC-4 — ADVISORY proxy)", function()

		-- ADVISORY: Boot-time `Instance.new("RemoteEvent")` walks happen inside
		-- `createRemotesFolders` at server start. TestEZ harness may or may not
		-- have run startServer; the test gracefully skips when remoteFolder absent.
		-- Real verification: Studio playtest — folder shape under
		-- ReplicatedStorage.Remotes.RemoteEvents and .RemoteFunctions matches enums.
		it("post-boot RemoteEvents folder contains every enum entry (skipped pre-boot)", function()
			local Network = require(ReplicatedStorage.Source.Network)
			if not Network._remoteFolder then
				return
			end

			local eventsFolder = (Network._remoteFolder :: Folder):FindFirstChild("RemoteEvents")
			expect(eventsFolder).to.be.ok()

			for _, name in RemoteEventName do
				local instance = (eventsFolder :: Folder):FindFirstChild(name :: string)
				expect(instance).to.be.ok()
				expect((instance :: Instance).ClassName).to.equal("RemoteEvent")
			end
		end)

		it("post-boot RemoteFunctions folder contains every enum entry (skipped pre-boot)", function()
			local Network = require(ReplicatedStorage.Source.Network)
			if not Network._remoteFolder then
				return
			end

			local functionsFolder = (Network._remoteFolder :: Folder):FindFirstChild("RemoteFunctions")
			expect(functionsFolder).to.be.ok()

			for _, name in RemoteFunctionName do
				local instance = (functionsFolder :: Folder):FindFirstChild(name :: string)
				expect(instance).to.be.ok()
				expect((instance :: Instance).ClassName).to.equal("RemoteFunction")
			end
		end)

	end)

	describe("AC-6 + AC-7 (compile-time + grep gate proxies)", function()

		-- AC-6 + AC-7 ADVISORY: --!strict + magic-string grep gate enforced
		-- out-of-band by Selene CI + Bash grep at /story-done time.
		it("modules load without error", function()
			expect(RemoteEventName).to.be.ok()
			expect(RemoteFunctionName).to.be.ok()
		end)

	end)

end
