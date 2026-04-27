--!strict

-- Unit tests for AssetId.Mesh inventory (Story 002).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (char keys), AC-2 (prop keys), AC-3 (env keys),
--         AC-4 (value format), AC-5 (key naming convention), AC-6 (no duplicate values)

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AssetId = require(ReplicatedStorage.Source.SharedConstants.AssetId)

	describe("AssetId.Mesh", function()

		-- AC-1: character mesh slots present
		it("contains all 4 character mesh keys", function()
			local CHAR_KEYS = {
				"CharFollowerBody",
				"CharFollowerHat",
				"CharPlayerAvatar",
				"CharNpcNeutral",
			}
			for _, key in CHAR_KEYS do
				expect(type(AssetId.Mesh[key])).to.equal("string")
			end
		end)

		-- AC-2: prop mesh slots present
		it("contains all 3 prop mesh keys", function()
			local PROP_KEYS = {
				"PropChestT1",
				"PropChestT2Car",
				"PropChestT3Building",
			}
			for _, key in PROP_KEYS do
				expect(type(AssetId.Mesh[key])).to.equal("string")
			end
		end)

		-- AC-3: environment mesh slots present
		it("contains all 4 environment mesh keys", function()
			local ENV_KEYS = {
				"EnvBuildingBlockA",
				"EnvBuildingBlockB",
				"EnvFloor",
				"EnvBoundaryWall",
			}
			for _, key in ENV_KEYS do
				expect(type(AssetId.Mesh[key])).to.equal("string")
			end
		end)

		-- AC-4: all values match rbxassetid://N format (N = one or more digits)
		-- ADVISORY: string.match is a runtime check. The `--!strict` compile-time
		-- gate and Luau LSP in Studio are the primary enforcement mechanisms for
		-- type safety; this test validates runtime string shape only.
		it("all values match rbxassetid://N format", function()
			for key, value in AssetId.Mesh do
				expect(type(value)).to.equal("string")
				expect(#value > 0).to.equal(true)
				local matched = value:match("^rbxassetid://%d+$")
				expect(matched ~= nil).to.equal(true)
			end
		end)

		-- AC-5: all keys follow [Category][AssetName] PascalCase per art bible §8.8.
		-- Pattern: starts with one uppercase letter, then one or more lowercase
		-- letters (the category word), then at least one more uppercase letter
		-- (start of the asset name word). Catches: "chestT1", "CHEST_T1", "Chest-T1".
		-- ADVISORY: this regex validates structural shape, not vocabulary.
		-- Vocabulary correctness (e.g. "Char" vs "Chr") is enforced by the
		-- literal key lists in AC-1 / AC-2 / AC-3 tests above.
		it("all keys follow [Category][AssetName] PascalCase convention", function()
			for key, _ in AssetId.Mesh do
				local matched = key:match("^[A-Z][a-z]+[A-Z]")
				expect(matched ~= nil).to.equal(true)
			end
		end)

		-- AC-6: no duplicate values among non-placeholder entries.
		-- Placeholder rbxassetid://0 is exempted from uniqueness — all MVP
		-- slots share this value intentionally until real uploads land.
		it("has no duplicate non-placeholder values", function()
			local PLACEHOLDER = "rbxassetid://0"
			local seen: { [string]: string } = {}
			for key, value in AssetId.Mesh do
				if value ~= PLACEHOLDER then
					expect(seen[value] == nil).to.equal(true)
					seen[value] = key
				end
			end
		end)

	end)
end
