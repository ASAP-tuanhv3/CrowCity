--!strict

-- Unit tests for UILayerId + UILayerType + UILayerTypeByLayerId (Story 001).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (4 new IDs), AC-2 (value-equals-key), AC-3 (UILayerType has both),
--         AC-4 (mapping correctness), AC-5 (uniqueness), AC-6 (type export — proxy),
--         AC-7 (--!strict — proxy)

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
	local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
	local UILayerTypeByLayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerTypeByLayerId)

	describe("UILayerId", function()

		-- AC-1: 4 new project IDs present alongside any existing template entries.
		it("contains all 4 new project layer IDs", function()
			local NEW_KEYS = { "HUD", "RelicDraft", "MainMenu", "PauseMenu" }
			for _, key in NEW_KEYS do
				expect(type((UILayerId :: any)[key])).to.equal("string")
			end
		end)

		-- AC-1 follow-up: pre-existing template entries preserved.
		it("preserves pre-existing template entries", function()
			expect(UILayerId.DataErrorNotice).to.equal("DataErrorNotice")
			expect(UILayerId.ExampleHud).to.equal("ExampleHud")
			expect(UILayerId.ResetDataButton).to.equal("ResetDataButton")
		end)

		-- AC-2: value-equals-key convention for every entry.
		it("every value equals its key", function()
			for key, value in UILayerId do
				expect(value).to.equal(key)
			end
		end)

		-- AC-5: keys + values are unique.
		it("has no duplicate values", function()
			local seen: { [string]: string } = {}
			for key, value in UILayerId do
				expect(seen[value] == nil).to.equal(true)
				seen[value] = key
			end
		end)

	end)

	describe("UILayerType", function()

		-- AC-3: HeadsUpDisplay + Menu types both present.
		it("contains HeadsUpDisplay + Menu", function()
			expect(UILayerType.HeadsUpDisplay).to.equal("HeadsUpDisplay")
			expect(UILayerType.Menu).to.equal("Menu")
		end)

	end)

	describe("UILayerTypeByLayerId", function()

		-- AC-4: each new ID maps to its expected UILayerType.
		it("maps HUD to HeadsUpDisplay", function()
			expect(UILayerTypeByLayerId[UILayerId.HUD]).to.equal(UILayerType.HeadsUpDisplay)
		end)

		it("maps RelicDraft / MainMenu / PauseMenu to Menu", function()
			expect(UILayerTypeByLayerId[UILayerId.RelicDraft]).to.equal(UILayerType.Menu)
			expect(UILayerTypeByLayerId[UILayerId.MainMenu]).to.equal(UILayerType.Menu)
			expect(UILayerTypeByLayerId[UILayerId.PauseMenu]).to.equal(UILayerType.Menu)
		end)

		-- AC-4 contract: lookup of unmapped ID returns nil (not error).
		it("unmapped ID lookup returns nil (no error)", function()
			expect(UILayerTypeByLayerId[UILayerId.DataErrorNotice]).to.equal(nil)
		end)

	end)

	describe("UILayerId (cross-module type contract)", function()

		-- AC-6 (proxy): EnumType export usable for consumer type-annotation.
		-- ADVISORY: Story AC-6 wording specified `UILayerIdValue = string`. Implemented
		-- as `EnumType` string-union to match existing template precedent in
		-- UILayerType.luau / ZoneIdTag.luau (per Implementation Notes "match the
		-- existing pattern exactly"). String-union is strictly stronger typing
		-- than `string` alias — gives consumers compile-time narrowing on assignment.
		-- This runtime probe confirms the value resolves to a string at runtime;
		-- the type-export gate is enforced by Luau LSP under `--!strict`.
		it("UILayerId.HUD satisfies EnumType (string) contract at runtime", function()
			local id: UILayerId.EnumType = UILayerId.HUD
			expect(type(id)).to.equal("string")
		end)

		-- AC-7 (proxy): `--!strict` is a compile-time directive.
		-- ADVISORY: TestEZ cannot introspect source bytes. Real gate is
		-- Selene CI + Luau LSP in Studio. This probe verifies the modules
		-- load cleanly at runtime as a smoke check.
		it("modules load without runtime error", function()
			expect(UILayerId).to.be.ok()
			expect(UILayerType).to.be.ok()
			expect(UILayerTypeByLayerId).to.be.ok()
		end)

	end)
end
