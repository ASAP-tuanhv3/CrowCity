--!strict

--[[
	CrowdStateClient — tick_is_newer F4 wrap-aware comparator unit tests.
	Path: tests/unit/crowd-state-client/tick_is_newer_f4.spec.luau

	Implements:
	  AC-7 (F4 tick_is_newer uint16 wrap) — happy + boundary cases
	  DI shape: tick_is_newer accessible as standalone module export without
	            instantiating any module state (CRS §DI Requirements)

	F4 formula (authoritative — ADR-0001 §Key Interfaces; story-001 spec):
	  local UINT16_HALF = 32768
	  local UINT16_MOD  = 65536
	  local function tick_is_newer(new, old)
	      local diff = (new - old) % UINT16_MOD
	      return diff > 0 and diff < UINT16_HALF
	  end

	Note on QA test case discrepancy (story §QA Test Cases):
	  The story lists tick_is_newer(32767, 0) == false ("half-window stale") and
	  tick_is_newer(32767, 65535) == true ("wraps + within half"). Applying the F4
	  formula produces the OPPOSITE:
	    (32767 - 0) % 65536     = 32767 → 32767 < 32768 → true
	    (32767 - 65535) % 65536 = 32768 → 32768 < 32768 → false
	  These two story QA result labels appear transposed. The formula is the
	  normative spec. Tests follow the formula. Flagged for story author review.

	Covered test cases (formula-authoritative):
	  Happy:
	    tick_is_newer(5, 4)         == true   (strictly newer)
	    tick_is_newer(4, 5)         == false  (older)
	    tick_is_newer(0, 65535)     == true   (uint16 wrap-around)
	    tick_is_newer(65534, 65535) == false  (one behind wrap)
	    tick_is_newer(32767, 0)     == true   (diff=32767; within front half; formula says true)
	    tick_is_newer(N, N)         == false  (equal tick = duplicate)
	  Boundary:
	    tick_is_newer(32768, 0)     == false  (exactly half-window — defensive; diff=32768 NOT < 32768)
	    tick_is_newer(32767, 65535) == false  (diff=32768 — exactly half-window; formula says false)
	    tick_is_newer(0, 32768)     == false  (other side; diff=32768)
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)

	-- Obtain the standalone function reference per CRS §DI Requirements (AC-7 DI shape).
	-- Validates that tick_is_newer is usable without any module state.
	local f = CrowdStateClient.tick_is_newer

	describe("tick_is_newer F4 — DI shape", function()

		-- Confirms tick_is_newer is exported as a module field and callable
		-- as a plain function without module instantiation (CRS §DI Requirements).
		it("is a callable function exported directly on the module table", function()
			expect(type(f)).to.equal("function")
			expect(f(5, 4)).to.equal(true)
		end)

	end)

	describe("tick_is_newer F4 — happy cases (AC-7)", function()

		-- diff = (5 - 4) % 65536 = 1; 1 > 0 and 1 < 32768 → true.
		it("tick_is_newer(5, 4) == true — strictly newer adjacent tick", function()
			expect(f(5, 4)).to.equal(true)
		end)

		-- diff = (4 - 5) % 65536 = 65535; 65535 < 32768 is false → false.
		it("tick_is_newer(4, 5) == false — strictly older tick", function()
			expect(f(4, 5)).to.equal(false)
		end)

		-- Uint16 wrap-around: diff = (0 - 65535) % 65536 = 1; 1 < 32768 → true.
		it("tick_is_newer(0, 65535) == true — uint16 wrap-around (AC-7 canonical)", function()
			expect(f(0, 65535)).to.equal(true)
		end)

		-- diff = (65534 - 65535) % 65536 = 65535; 65535 < 32768 is false → false.
		it("tick_is_newer(65534, 65535) == false — one behind the wrap", function()
			expect(f(65534, 65535)).to.equal(false)
		end)

		-- diff = (32767 - 0) % 65536 = 32767; 32767 > 0 and 32767 < 32768 → true.
		-- Note: story QA labels this "half-window stale → false" but the formula
		-- produces true (32767 is still within the front-half window). Formula wins.
		-- Discrepancy flagged in file header above.
		it("tick_is_newer(32767, 0) == true — diff=32767 is within front-half window (formula authoritative)", function()
			expect(f(32767, 0)).to.equal(true)
		end)

		-- diff = 0 for equal ticks; 0 > 0 is false → false. Tested at multiple values.
		it("tick_is_newer(N, N) == false — equal tick is duplicate broadcast (AC-7)", function()
			expect(f(0, 0)).to.equal(false)
			expect(f(1, 1)).to.equal(false)
			expect(f(65535, 65535)).to.equal(false)
			expect(f(32768, 32768)).to.equal(false)
		end)

	end)

	describe("tick_is_newer F4 — boundary cases (AC-7 boundary)", function()

		-- Exactly at UINT16_HALF: diff = (32768 - 0) % 65536 = 32768.
		-- 32768 < 32768 is false → false (defensive: ambiguous distance treated as stale).
		it("tick_is_newer(32768, 0) == false — exactly half-window boundary is defensive (AC-7 boundary)", function()
			expect(f(32768, 0)).to.equal(false)
		end)

		-- diff = (32767 - 65535) % 65536 = (-32768) % 65536 = 32768.
		-- 32768 < 32768 is false → false.
		-- Note: story QA labels this "wraps + within half → true" but formula produces
		-- false (diff == 32768 == UINT16_HALF → defensive boundary → false). Formula wins.
		-- Discrepancy flagged in file header above.
		it("tick_is_newer(32767, 65535) == false — diff=32768 hits half-window boundary (formula authoritative)", function()
			expect(f(32767, 65535)).to.equal(false)
		end)

		-- diff = (0 - 32768) % 65536 = (-32768) % 65536 = 32768.
		-- 32768 < 32768 is false → false.
		it("tick_is_newer(0, 32768) == false — other side of half-window (AC-7 boundary)", function()
			expect(f(0, 32768)).to.equal(false)
		end)

		-- One step inside front-half from the wrap:
		-- diff = (32766 - 65535) % 65536 = (-32769) % 65536 = 65536 - 32769 = 32767.
		-- 32767 < 32768 → true.
		it("tick_is_newer(32766, 65535) == true — one step inside front-half after wrap", function()
			expect(f(32766, 65535)).to.equal(true)
		end)

		-- One step past the half-window boundary (from zero):
		-- diff = (32769 - 0) % 65536 = 32769; 32769 < 32768 is false → false.
		it("tick_is_newer(32769, 0) == false — one past half-window boundary", function()
			expect(f(32769, 0)).to.equal(false)
		end)

		-- Trivial forward step at top of uint16 range.
		it("tick_is_newer(65535, 65534) == true — last tick before uint16 wrap", function()
			expect(f(65535, 65534)).to.equal(true)
		end)

		-- Trivial forward step at bottom of uint16 range.
		it("tick_is_newer(1, 0) == true — first tick above zero", function()
			expect(f(1, 0)).to.equal(true)
		end)

	end)

end
