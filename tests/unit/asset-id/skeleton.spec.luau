--!strict

-- Unit tests for AssetId module skeleton (Story 001).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AssetId = require(ReplicatedStorage.Source.SharedConstants.AssetId)

	describe("AssetId", function()
		-- AC-1: module loads at runtime.
		-- ADVISORY: `--!strict` is a compile-time directive — TestEZ cannot
		-- introspect the source. Project-wide enforcement comes from
		-- `selene src/` (CI gate) and the Luau type checker in Studio.
		it("loads without error", function()
			expect(AssetId).to.be.ok()
		end)

		-- AC-2: module returns a table with exactly 4 required category keys
		-- (presence + count — guards against drift if a 5th category is added
		-- without spec update).
		it("has exactly the 4 required category sub-tables", function()
			expect(type(AssetId.Skin)).to.equal("table")
			expect(type(AssetId.Mesh)).to.equal("table")
			expect(type(AssetId.Particle)).to.equal("table")
			expect(type(AssetId.Sound)).to.equal("table")

			local count = 0
			for _ in pairs(AssetId) do
				count += 1
			end
			expect(count).to.equal(4)
		end)

		-- AC-3 + AC-4: Skin has >= 5 entries and all values are valid rbxassetid:// strings
		describe("Skin sub-table", function()
			it("contains at least 5 entries", function()
				local count = 0
				for _ in AssetId.Skin do
					count += 1
				end
				expect(count >= 5).to.equal(true)
			end)

			it("contains FollowerDefault key", function()
				expect(AssetId.Skin.FollowerDefault).to.be.ok()
			end)

			it("all values are non-empty strings starting with rbxassetid://", function()
				for key, value in AssetId.Skin do
					expect(type(value)).to.equal("string")
					expect(#value > 0).to.equal(true)
					expect(value:sub(1, 13)).to.equal("rbxassetid://")
					-- Confirm the part after the prefix is present
					expect(#value > 13).to.equal(true)
				end
			end)
		end)

		-- AC-5: module returns the same table on repeated require (Roblox module cache).
		-- ADVISORY: TestEZ runs in a single execution context. True cross-context
		-- (server-side fixture + client-side fixture) verification requires a
		-- playtest step or a Rojo-driven place file harness. This assertion
		-- proves Roblox's module cache identity within one context only.
		it("returns the same table identity on repeated require", function()
			local AssetId2 = require(ReplicatedStorage.Source.SharedConstants.AssetId)
			expect(AssetId2).to.equal(AssetId)
		end)

		-- AC-6: AssetIdValue type is exported.
		-- ADVISORY: TestEZ has no compile-time type introspection. The line
		-- below would fail to type-check under `--!strict` if the
		-- `export type AssetIdValue` declaration were missing or malformed,
		-- but at runtime the assertion only validates string-ness as a proxy.
		-- Real gate: `--!strict` on consumer modules + Luau LSP in Studio.
		it("Skin values satisfy AssetIdValue (string) contract", function()
			local id: AssetId.AssetIdValue = AssetId.Skin.FollowerDefault
			expect(type(id)).to.equal("string")
		end)
	end)
end
