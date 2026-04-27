--!strict

-- Unit tests for RateLimitConfig (Story 005, network-layer-ext epic).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (module exists), AC-2 (entry shape), AC-3 (required entries),
--         AC-4 (canonical values), AC-5 (type export — proxy), AC-6 (default fallback),
--         AC-7 (--!strict — proxy)

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RateLimitConfig = require(ReplicatedStorage.Source.SharedConstants.RateLimitConfig)

	describe("RateLimitConfig structure (AC-1 + AC-2 + AC-7)", function()

		it("module loads as a table", function()
			expect(type(RateLimitConfig)).to.equal("table")
		end)

		it("every entry has numeric rate > 0 and burst >= 1", function()
			for name, entry in RateLimitConfig do
				expect(type(entry.rate)).to.equal("number")
				expect(type(entry.burst)).to.equal("number")
				expect(entry.rate > 0).to.equal(true)
				expect(entry.burst >= 1).to.equal(true)
			end
		end)

	end)

	describe("Required entries (AC-3 + AC-4)", function()

		-- AC-3 + AC-4: ADR-0010 §Per-Player Rate Limit Policy canonical entries
		-- (windowed model converted to token-bucket; see RateLimitConfig.luau header).
		it("ChestInteract entry matches ADR-0010 (rate=4, burst=4)", function()
			expect(RateLimitConfig.ChestInteract.rate).to.equal(4)
			expect(RateLimitConfig.ChestInteract.burst).to.equal(4)
		end)

		it("ChestDraftPick entry matches ADR-0010 (rate=1, burst=1)", function()
			expect(RateLimitConfig.ChestDraftPick.rate).to.equal(1)
			expect(RateLimitConfig.ChestDraftPick.burst).to.equal(1)
		end)

		it("AFKToggle entry matches ADR-0010 (rate=0.4, burst=2)", function()
			expect(RateLimitConfig.AFKToggle.rate).to.equal(0.4)
			expect(RateLimitConfig.AFKToggle.burst).to.equal(2)
		end)

	end)

	describe("Default fallback (AC-6)", function()

		it("default entry exists with conservative {rate=1, burst=2}", function()
			expect(RateLimitConfig.default).to.be.ok()
			expect(RateLimitConfig.default.rate).to.equal(1)
			expect(RateLimitConfig.default.burst).to.equal(2)
		end)

		-- AC-6 contract: any unknown remote name falls through to default.
		it("unknown remote name resolves via `or default` idiom", function()
			local entry = (RateLimitConfig :: any)["NotARealRemote"] or RateLimitConfig.default
			expect(entry.rate).to.equal(1)
			expect(entry.burst).to.equal(2)
		end)

	end)

	describe("Type export (AC-5 — proxy)", function()

		-- AC-5 ADVISORY: type export verified at compile time by Luau LSP +
		-- consumer module strict-mode checks. Runtime probe verifies entry
		-- shape conforms to RateLimitEntry contract (rate + burst numbers).
		it("ChestInteract entry satisfies RateLimitEntry shape at runtime", function()
			local entry: RateLimitConfig.RateLimitEntry = RateLimitConfig.ChestInteract
			expect(type(entry.rate)).to.equal("number")
			expect(type(entry.burst)).to.equal("number")
		end)

	end)

end
