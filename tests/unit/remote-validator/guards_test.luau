--!strict

-- Unit tests for RemoteValidator 4-check guard pattern (Story 004, network-layer-ext).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (module placement), AC-2 (5 functions), AC-3 (identity guard),
--         AC-4 (rate-limit token bucket), AC-5 (parameter schema),
--         AC-6 (payload size guard), AC-7 (short-circuit idiom),
--         AC-8 (silent rejection — no exceptions), AC-9 (test isolation),
--         AC-10 (--!strict — proxy)

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local Players = game:GetService("Players")

	local RemoteValidator = require(ServerStorage.Source.RemoteValidator)

	-- Stub Player-like Instance for identity tests (real Player requires server context).
	local function makeStubPlayer(): Player
		-- Use a real Instance.new("Folder") cast as Player to verify identity guard
		-- rejects non-Player Instances. For "true" Player tests, rely on RemoteValidator
		-- accepting actual Players in Studio harness (covered out-of-band).
		return Instance.new("Folder") :: any
	end

	-- For rate tests we need an actual Player instance; use the local test player
	-- if available, otherwise skip (graceful in TestEZ harness without real player).
	local function getTestPlayer(): Player?
		return Players:GetPlayers()[1]
	end

	describe("RemoteValidator surface (AC-1 + AC-2 + AC-10)", function()

		it("module loads from ServerStorage.Source.RemoteValidator", function()
			expect(RemoteValidator).to.be.ok()
		end)

		it("exposes checkIdentity / checkState / checkParameters / checkRate / checkPayloadSize", function()
			expect(type(RemoteValidator.checkIdentity)).to.equal("function")
			expect(type(RemoteValidator.checkState)).to.equal("function")
			expect(type(RemoteValidator.checkParameters)).to.equal("function")
			expect(type(RemoteValidator.checkRate)).to.equal("function")
			expect(type(RemoteValidator.checkPayloadSize)).to.equal("function")
		end)

		it("exposes _resetForTest helper for test isolation (AC-9)", function()
			expect(type(RemoteValidator._resetForTest)).to.equal("function")
		end)

	end)

	describe("checkIdentity (AC-3)", function()

		it("rejects nil", function()
			expect(RemoteValidator.checkIdentity(nil)).to.equal(false)
		end)

		it("rejects non-Instance values", function()
			expect(RemoteValidator.checkIdentity("alice")).to.equal(false)
			expect(RemoteValidator.checkIdentity(42)).to.equal(false)
			expect(RemoteValidator.checkIdentity({ UserId = 12345 })).to.equal(false)
		end)

		it("rejects Instance that is not a Player", function()
			local fakePlayer = makeStubPlayer()
			expect(RemoteValidator.checkIdentity(fakePlayer)).to.equal(false)
			fakePlayer:Destroy()
		end)

		-- ADVISORY: testing a real Player requires a Studio playtest harness.
		-- The above 3 tests cover the rejection paths exhaustively; the accept
		-- path (engine-set Player) is verified out-of-band.

	end)

	describe("checkState (AC-2)", function()

		it("returns true when predicate returns true", function()
			expect(RemoteValidator.checkState(function() return true end)).to.equal(true)
		end)

		it("returns false when predicate returns false", function()
			expect(RemoteValidator.checkState(function() return false end)).to.equal(false)
		end)

		it("returns false when predicate returns non-true (truthy but not exactly true)", function()
			expect(RemoteValidator.checkState(function() return 1 :: any end)).to.equal(false)
		end)

		-- AC-8: silent rejection — predicate raising must not crash handler.
		it("returns false (no rethrow) when predicate raises an error", function()
			expect(RemoteValidator.checkState(function() error("simulated predicate failure") end)).to.equal(false)
		end)

	end)

	describe("checkParameters (AC-5)", function()

		it("accepts payload matching schema exactly", function()
			expect(RemoteValidator.checkParameters({ a = "x", b = 5 }, { a = "string", b = "number" })).to.equal(true)
		end)

		it("rejects payload with swapped types", function()
			expect(RemoteValidator.checkParameters({ a = 5, b = "x" }, { a = "string", b = "number" })).to.equal(false)
		end)

		it("rejects payload with extra unexpected field", function()
			expect(RemoteValidator.checkParameters({ a = "x", b = 5, c = true }, { a = "string", b = "number" })).to.equal(false)
		end)

		it("rejects payload missing a schema field", function()
			expect(RemoteValidator.checkParameters({ a = "x" }, { a = "string", b = "number" })).to.equal(false)
		end)

		it("rejects non-table payload", function()
			expect(RemoteValidator.checkParameters("not-a-table" :: any, { a = "string" })).to.equal(false)
		end)

		it("validates Vector3 type", function()
			local payload = { pos = Vector3.new(1, 2, 3) }
			expect(RemoteValidator.checkParameters(payload, { pos = "Vector3" })).to.equal(true)
		end)

		it("rejects wrong Vector3-typed field", function()
			local payload = { pos = "not-a-vector" }
			expect(RemoteValidator.checkParameters(payload, { pos = "Vector3" })).to.equal(false)
		end)

	end)

	describe("checkRate token bucket (AC-4 + AC-9)", function()

		-- AC-9: reset bucket state before each test in this describe so cases
		-- don't leak rate-limit state across each other.
		beforeEach(function()
			RemoteValidator._resetForTest()
		end)

		it("first burst-many calls succeed (AC-4)", function()
			local player = getTestPlayer()
			if not player then return end -- skip in headless TestEZ

			-- ChestInteract = {rate=4, burst=4} per ADR-0010
			local success_count = 0
			for _ = 1, 4 do
				if RemoteValidator.checkRate(player, "ChestInteract") then
					success_count += 1
				end
			end
			expect(success_count).to.equal(4)
		end)

		it("burst+1th call fails when bucket exhausted (AC-4)", function()
			local player = getTestPlayer()
			if not player then return end

			-- Drain the bucket.
			for _ = 1, 4 do
				RemoteValidator.checkRate(player, "ChestInteract")
			end
			-- 5th immediate call exhausted.
			expect(RemoteValidator.checkRate(player, "ChestInteract")).to.equal(false)
		end)

		it("unknown remote name resolves via default fallback (rate=1, burst=2)", function()
			local player = getTestPlayer()
			if not player then return end

			-- Default {rate=1, burst=2}: first 2 succeed, 3rd fails.
			expect(RemoteValidator.checkRate(player, "TotallyUnknownRemote")).to.equal(true)
			expect(RemoteValidator.checkRate(player, "TotallyUnknownRemote")).to.equal(true)
			expect(RemoteValidator.checkRate(player, "TotallyUnknownRemote")).to.equal(false)
		end)

	end)

	describe("checkPayloadSize (AC-6)", function()

		it("accepts payload under limit", function()
			expect(RemoteValidator.checkPayloadSize({ a = "x" }, 4096)).to.equal(true)
		end)

		it("rejects payload over limit", function()
			-- Generate ~5 KB string payload to exceed default 4 KB limit.
			local big = string.rep("x", 5000)
			expect(RemoteValidator.checkPayloadSize(big, 4096)).to.equal(false)
		end)

		it("uses default 4096 limit when maxBytes omitted", function()
			expect(RemoteValidator.checkPayloadSize("small", nil)).to.equal(true)
		end)

		it("handles buffer payloads via buffer.len", function()
			local buf = buffer.create(100)
			expect(RemoteValidator.checkPayloadSize(buf, 4096)).to.equal(true)
		end)

	end)

	describe("AC-7 short-circuit idiom + AC-8 silent rejection", function()

		-- AC-7 + AC-8 — caller-side discipline; verified by the documentation
		-- block at top of RemoteValidator/init.luau showing the canonical
		-- `if not checkX(...) then return end` chain. No runtime guard enforces
		-- this; it is code-review-driven per ADR-0010 §L2 enforcement.
		it("guard functions return booleans (caller pattern enabled)", function()
			expect(type(RemoteValidator.checkIdentity(nil))).to.equal("boolean")
			expect(type(RemoteValidator.checkState(function() return false end))).to.equal("boolean")
			expect(type(RemoteValidator.checkParameters({}, { x = "string" }))).to.equal("boolean")
		end)

		-- AC-8: rejections never raise exceptions back to the caller.
		it("guard rejection paths do not throw", function()
			-- All return false; none raise.
			expect(function()
				RemoteValidator.checkIdentity(nil)
				RemoteValidator.checkState(function() return false end)
				RemoteValidator.checkParameters({}, { x = "string" })
				RemoteValidator.checkPayloadSize(string.rep("x", 9999), 1024)
			end).never.to.throw()
		end)

	end)

end
