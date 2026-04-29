--!strict

-- Unit tests for AssetId.Particle + AssetId.Sound inventory (Story 003).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (12 particle keys), AC-2 (10 sound *Cue keys),
--         AC-3 (rbxassetid format), AC-4 (PascalCase),
--         AC-5 (Sounds.luau retirement — proxy at runtime; full check via grep at /story-done),
--         AC-6 (top-of-file cross-ref comment — proxy; manual review at /story-done).

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local AssetId = require(ReplicatedStorage.Source.SharedConstants.AssetId)

	describe("AssetId.Particle", function()

		-- AC-1: 12 effect IDs from VFX Manager GDD §V/A — literal name list.
		-- Tightly scoped: extra keys also fail (registry shape locked to GDD).
		it("contains exactly the 12 VFX Manager GDD effect IDs", function()
			local PARTICLE_KEYS = {
				"AbsorbSnap",
				"CollisionContactRing",
				"ChestPeelMarch",
				"ChestOpenT1Confetti",
				"ChestOpenT2Confetti",
				"ChestDraftOpen",
				"RelicGrantCommon",
				"RelicGrantRare",
				"RelicGrantEpic",
				"RelicExpire",
				"PeelVanish",
				"MaxCrowdFlash",
			}
			for _, key in PARTICLE_KEYS do
				expect(type(AssetId.Particle[key])).to.equal("string")
			end

			local count = 0
			for _ in pairs(AssetId.Particle) do
				count += 1
			end
			expect(count).to.equal(12)
		end)

	end)

	describe("AssetId.Sound", function()

		-- AC-2: 10 audio cues — *Cue suffix is the contract.
		it("contains exactly the 10 MVP audio cue keys", function()
			local SOUND_KEYS = {
				"AbsorbCue",
				"ChestOpenT1Cue",
				"ChestOpenT2Cue",
				"RelicGrantCommonCue",
				"RelicGrantRareCue",
				"RelicGrantEpicCue",
				"MatchStartCue",
				"MatchEndCue",
				"EliminationCue",
				"FinalMinuteCue",
			}
			for _, key in SOUND_KEYS do
				expect(type(AssetId.Sound[key])).to.equal("string")
			end

			local count = 0
			for _ in pairs(AssetId.Sound) do
				count += 1
			end
			expect(count).to.equal(10)
		end)

		-- AC-2 contract: every Sound key MUST end in 'Cue' per game-concept naming.
		it("all keys end with the 'Cue' suffix", function()
			for key, _ in AssetId.Sound do
				expect(key:sub(-3)).to.equal("Cue")
			end
		end)

	end)

	describe("AssetId.Particle + AssetId.Sound (cross-cutting)", function()

		-- AC-3: rbxassetid://N format (placeholder rbxassetid://0 allowed).
		it("all values match rbxassetid://N format", function()
			for key, value in AssetId.Particle do
				expect(type(value)).to.equal("string")
				local matched = value:match("^rbxassetid://%d+$")
				expect(matched ~= nil).to.equal(true)
			end
			for key, value in AssetId.Sound do
				expect(type(value)).to.equal("string")
				local matched = value:match("^rbxassetid://%d+$")
				expect(matched ~= nil).to.equal(true)
			end
		end)

		-- AC-4: PascalCase per CLAUDE.md §Naming.
		-- Pattern: starts with uppercase, contains only ASCII letters and digits.
		-- ADVISORY: this validates structural shape only. Vocabulary correctness
		-- (e.g. 'AbsorbSnap' vs 'AbsorbSmash') is enforced by the literal key
		-- lists in AC-1 and AC-2 tests above.
		it("all keys are PascalCase (no underscores, hyphens, or lowercase prefix)", function()
			for key, _ in AssetId.Particle do
				expect(key:match("^[A-Z][A-Za-z0-9]*$") ~= nil).to.equal(true)
			end
			for key, _ in AssetId.Sound do
				expect(key:match("^[A-Z][A-Za-z0-9]*$") ~= nil).to.equal(true)
			end
		end)

		-- AC-5 (proxy): Sounds.luau retirement.
		-- ADVISORY: TestEZ cannot grep the source tree. The file-system check
		-- (Sounds.luau absent + zero `require(...Sounds)` matches) runs at
		-- /story-done time via Bash grep. This runtime probe verifies that
		-- AssetId.Sound exists as the replacement contract — necessary but
		-- not sufficient for AC-5 closure.
		it("AssetId.Sound is the live replacement for retired Sounds.luau", function()
			expect(type(AssetId.Sound)).to.equal("table")
			-- Spot-check one cue from the original SoundManager API surface.
			expect(type(AssetId.Sound.AbsorbCue)).to.equal("string")
		end)

		-- AC-6 (proxy): top-of-file cross-reference comment.
		-- ADVISORY: comment introspection requires reading source bytes;
		-- TestEZ runs against compiled module values only. Manual review at
		-- /story-done verifies the cross-ref to VFX Manager GDD §V/A and
		-- game-concept §Audio cue inventory.
		it("module loads without error (comment cross-ref verified manually at /story-done)", function()
			expect(AssetId).to.be.ok()
			expect(AssetId.Particle).to.be.ok()
			expect(AssetId.Sound).to.be.ok()
		end)

	end)
end
