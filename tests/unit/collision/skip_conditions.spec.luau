--!strict

--[[
	CollisionResolver Story 004 — skip conditions: nil/Eliminated guard +
	GraceWindow drip suspension — unit tests.
	Path: tests/unit/collision/skip_conditions.spec.luau

	Implements Story 004 (CCR) QA test cases:
	  AC-06 — Skip nil/Eliminated: pairs where csm.get returns nil OR record state
	          is Eliminated → no updateCount calls; no Luau errors.
	  GraceWindow drip suspended: GraceWindow ↔ Active → no drip; GraceWindow ↔
	          GraceWindow → no drip. Pair entries remain in _overlapPairs for
	          Story 005 overlap-bit feed.
	  No state writes: CCR module never invokes csm.transitionTo* / setState* —
	          verified via tripwire spy on a CSM mock that explodes if those
	          methods are called.

	Test isolation: CollisionResolver._resetForTests() in afterEach.
	All deps injected via mocks — no real CSM or PeelDispatcher required.

	Test naming: it("AC-NN — description", ...) per project convention
	(mirrors tests/unit/collision/drip_math.spec.luau).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CollisionResolver = require(ServerStorage.Source.CollisionResolver)

	-- -------------------------------------------------------------------------
	-- Spy factory
	-- -------------------------------------------------------------------------

	local function spy()
		local calls: { { n: number, [number]: any } } = {}
		local self: any = {
			calls = calls,
			callCount = function(): number
				return #calls
			end,
			getCall = function(i: number): { n: number, [number]: any }
				return calls[i]
			end,
		}
		setmetatable(self, {
			__call = function(_self: any, ...): ()
				table.insert(calls, table.pack(...))
			end,
		})
		return self
	end

	-- -------------------------------------------------------------------------
	-- Mock + record factories
	-- -------------------------------------------------------------------------

	--- Builds a CSM-shaped crowd record with explicit state.
	local function buildCrowd(id: string, state: string, count: number?): any
		return {
			crowdId = id,
			position = Vector3.new(0, 0, 0),  -- all overlapping for these tests
			radius = 100,
			count = count or 50,
			state = state,
		}
	end

	--- Builds a mock CSM that supports configurable per-id `get` overrides.
	--- `getOverrides[crowdId] = nil` forces csm.get(crowdId) to return nil even
	--- when the record is in `getAllActive`. Use to simulate the PlayerRemoving
	--- race scenario from AC-06.
	---
	--- Tripwire: `transitionTo` and `setState` exist on the mock as functions
	--- that call into a spy; if any call happens, the test fails (no state
	--- writes from CCR per ADR-0004 §Write-Access Matrix).
	local function buildMockCsm(crowds: { any }?, getOverrides: { [string]: boolean }?): any
		local updateCountSpy = spy()
		local setStillOverlappingSpy = spy()
		local transitionToSpy = spy()
		local setStateSpy = spy()
		local byId: { [string]: any } = {}
		if crowds ~= nil then
			for _, c in ipairs(crowds) do
				byId[c.crowdId] = c
			end
		end
		return {
			getAllActive = function(): { any }
				local copy: { any } = {}
				if crowds ~= nil then
					for i, v in ipairs(crowds) do
						copy[i] = v
					end
				end
				return copy
			end,
			get = function(crowdId: string): any
				if getOverrides ~= nil and getOverrides[crowdId] == true then
					return nil  -- explicit nil override (race simulation)
				end
				return byId[crowdId]
			end,
			updateCount = function(id: string, delta: number, source: string): number
				updateCountSpy(id, delta, source)
				return 0
			end,
			setStillOverlapping = function(id: string, flag: boolean): ()
				setStillOverlappingSpy(id, flag)
			end,
			-- Tripwire methods (must NEVER fire from CCR per ADR-0004).
			transitionTo = function(...): ()
				transitionToSpy(...)
			end,
			setState = function(...): ()
				setStateSpy(...)
			end,
			_updateCountSpy = updateCountSpy,
			_setStillOverlappingSpy = setStillOverlappingSpy,
			_transitionToSpy = transitionToSpy,
			_setStateSpy = setStateSpy,
		}
	end

	local function buildMockPeelDispatcher(): any
		return { dispatch = spy() }
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CollisionResolver Story 004 — skip conditions", function()
		afterEach(function()
			CollisionResolver._resetForTests()
		end)

		-- -----------------------------------------------------------------------
		-- AC-06: Skip nil/Eliminated
		-- -----------------------------------------------------------------------

		-- AC-06: csm.get returns nil for one side → skip pair, no updateCount, no error.
		it("AC-06 — csm.get nil for A: no updateCount, no error", function()
			local crowdA = buildCrowd("aaa", "Active", 100)
			local crowdB = buildCrowd("bbb", "Active", 50)
			local mockCsm = buildMockCsm(
				{ crowdA, crowdB },
				{ ["aaa"] = true }  -- force csm.get("aaa") → nil
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			local ok = pcall(function()
				CollisionResolver.tickPhase1(1, {})
			end)
			expect(ok).to.equal(true)
			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- AC-06: csm.get returns nil for B → skip pair, no updateCount, no error.
		it("AC-06 — csm.get nil for B: no updateCount, no error", function()
			local crowdA = buildCrowd("aaa", "Active", 100)
			local crowdB = buildCrowd("bbb", "Active", 50)
			local mockCsm = buildMockCsm(
				{ crowdA, crowdB },
				{ ["bbb"] = true }
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- AC-06 edge: both csm.get nil → skip silently.
		it("AC-06 edge — both csm.get nil: skip silently, no updateCount", function()
			local mockCsm = buildMockCsm(
				{ buildCrowd("aaa", "Active"), buildCrowd("bbb", "Active") },
				{ ["aaa"] = true, ["bbb"] = true }
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- AC-06: Eliminated state → skip drip; no updateCount.
		-- Note: getAllActive in production excludes Eliminated, but the Eliminated
		-- record can still appear via mock to verify the defensive guard.
		it("AC-06 — Eliminated state: no updateCount calls", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Eliminated"),
				buildCrowd("bbb", "Active"),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- AC-06 edge: both Eliminated → no updateCount.
		it("AC-06 edge — both Eliminated: no updateCount, no error", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Eliminated"),
				buildCrowd("bbb", "Eliminated"),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- -----------------------------------------------------------------------
		-- GraceWindow drip suspended (TR-ccr-019)
		-- -----------------------------------------------------------------------

		-- GraceWindow + Active → no drip; pair entry stays in _overlapPairs (Story 005).
		it("GraceWindow ↔ Active: no drip, pair entry preserved for Story 005", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "GraceWindow", 100),
				buildCrowd("bbb", "Active", 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
			-- Pair entry retained for overlap-bit reporting in Story 005.
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
		end)

		-- Active + GraceWindow (reversed argument order) → still no drip.
		it("Active ↔ GraceWindow (reversed): no drip", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100),
				buildCrowd("bbb", "GraceWindow", 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
		end)

		-- Both GraceWindow → no drip; pair entry preserved.
		it("GraceWindow ↔ GraceWindow: no drip, pair entry preserved", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "GraceWindow", 50),
				buildCrowd("bbb", "GraceWindow", 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
		end)

		-- -----------------------------------------------------------------------
		-- Active + Active continues to drip (regression check vs Story 003)
		-- -----------------------------------------------------------------------

		it("Active ↔ Active: drip still fires (Story 003 regression check)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100),
				buildCrowd("bbb", "Active", 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- 2 calls: aaa+delta, bbb-delta (cd=50 → delta=2).
			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
		end)

		-- -----------------------------------------------------------------------
		-- Mixed scenarios — triple-pair with state diversity
		-- -----------------------------------------------------------------------

		-- 3 crowds: Active / Active / GraceWindow.
		-- Pairs: aaa-bbb (Active+Active drip), aaa-ccc (Active+GraceWindow no drip),
		-- bbb-ccc (Active+GraceWindow no drip). Expected: 2 updateCount calls (aaa-bbb only).
		it("Mixed — 3 crowds Active/Active/GraceWindow: only Active+Active pair drips", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100),
				buildCrowd("bbb", "Active", 50),
				buildCrowd("ccc", "GraceWindow", 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(3)
		end)

		-- 3 crowds: Active / Eliminated / Active.
		-- Pairs: aaa-bbb (Active+Eliminated no drip), aaa-ccc (Active+Active drip),
		-- bbb-ccc (Eliminated+Active no drip). Expected: 2 updateCount calls (aaa-ccc).
		-- Pair entries preserved for Story 005 overlap-bit feed (Eliminated path).
		it("Mixed — 3 crowds Active/Eliminated/Active: only Active+Active pair drips, all entries preserved", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100),
				buildCrowd("bbb", "Eliminated", 50),
				buildCrowd("ccc", "Active", 30),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			-- Story 005 prerequisite: drip-skip must NOT remove pair entries from
			-- _overlapPairs. All 3 pairs (aaa-bbb, aaa-ccc, bbb-ccc) preserved.
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(3)
		end)

		-- -----------------------------------------------------------------------
		-- No state writes (TR-ccr-007 audit)
		-- -----------------------------------------------------------------------

		-- Tripwire: across many overlapping pair scenarios, transitionTo + setState
		-- spies must remain at zero call count. CCR is a state CONSUMER, not a state
		-- WRITER (ADR-0004 §Write-Access Matrix).
		it("No state writes — transitionTo + setState spies never fire", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100),
				buildCrowd("bbb", "GraceWindow", 50),
				buildCrowd("ccc", "Eliminated", 30),
				buildCrowd("ddd", "Active", 80),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})
			CollisionResolver.tickPhase1(2, {})
			CollisionResolver.tickPhase1(3, {})

			expect(mockCsm._transitionToSpy.callCount()).to.equal(0)
			expect(mockCsm._setStateSpy.callCount()).to.equal(0)
			-- Story 005 owns setStillOverlapping; Story 004 must not pre-empt it.
			-- Closes full ADR-0004 §Write-Access Matrix surface for this story.
			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(0)
		end)

		-- -----------------------------------------------------------------------
		-- Cross-cutting: nil-skip case still allows other valid pairs to drip
		-- -----------------------------------------------------------------------

		-- 4 crowds. csm.get nil for "aaa" AND "bbb" (two simultaneous races).
		-- Pairs (lex-sorted): aaa-bbb (skip — both nil), aaa-ccc (skip — aaa nil),
		-- aaa-ddd (skip — aaa nil), bbb-ccc (skip — bbb nil), bbb-ddd (skip — bbb nil),
		-- ccc-ddd (Active+Active → drip). Expected: 2 updateCount calls (ccc-ddd only).
		-- Validates `continue` interaction with multiple sequential skips before a
		-- valid pair appears in iteration order.
		it("Mixed — two nil crowds + one valid pair: only valid pair drips", function()
			local mockCsm = buildMockCsm(
				{
					buildCrowd("aaa", "Active", 100),
					buildCrowd("bbb", "Active", 80),
					buildCrowd("ccc", "Active", 60),
					buildCrowd("ddd", "Active", 40),
				},
				{ ["aaa"] = true, ["bbb"] = true }  -- both disappear pre-drip
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			local found_ccc, found_ddd = false, false
			for i = 1, mockCsm._updateCountSpy.callCount() do
				local call = mockCsm._updateCountSpy.getCall(i)
				if call[1] == "ccc" then found_ccc = true end
				if call[1] == "ddd" then found_ddd = true end
			end
			expect(found_ccc).to.equal(true)
			expect(found_ddd).to.equal(true)
		end)

		-- 3 crowds. csm.get nil for "bbb" (race). Pairs: aaa-bbb (skip — bbb nil),
		-- aaa-ccc (Active+Active → drip), bbb-ccc (skip — bbb nil).
		-- Expected: 2 updateCount calls (aaa-ccc only).
		it("Mixed — nil-fetch for one crowd does not poison other valid pairs", function()
			local mockCsm = buildMockCsm(
				{
					buildCrowd("aaa", "Active", 100),
					buildCrowd("bbb", "Active", 80),
					buildCrowd("ccc", "Active", 50),
				},
				{ ["bbb"] = true }  -- bbb disappears between getAllActive and drip
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Only aaa-ccc pair drips (cd=50 → delta=2).
			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			local found_aaa, found_ccc = false, false
			for i = 1, mockCsm._updateCountSpy.callCount() do
				local call = mockCsm._updateCountSpy.getCall(i)
				if call[1] == "aaa" then found_aaa = true end
				if call[1] == "ccc" then found_ccc = true end
			end
			expect(found_aaa).to.equal(true)
			expect(found_ccc).to.equal(true)
		end)
	end)
end
