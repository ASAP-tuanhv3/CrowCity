--!strict

--[[
	CollisionResolver Story 003 — F3 drip math + per-pair updateCount + equal-count
	mutual drain — unit tests.
	Path: tests/unit/collision/drip_math.spec.luau

	Implements Story 003 (CCR) QA test cases:
	  AC-07 — Drip application: A 100 vs B 50 → +2/-2 with "Collision" source.
	  AC-08 — Equal-count mutual drain: A 50 vs B 50 → both -1, no `+`.
	  F3 clamp — delta_per_tick ∈ [1, 4]; small differential floor; massive cap.
	  Triple-overlap — 3 mutually overlapping crowds → 6 updateCount calls.

	Test isolation: CollisionResolver._resetForTests() in afterEach.
	All deps injected via mocks — no real CSM or PeelDispatcher required.

	Test naming: it("AC-NN — description", ...) per project convention
	(mirrors tests/unit/collision/pair_iteration_overlap.spec.luau).
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

	--- Builds a CSM-shaped crowd record for tests. Includes `count` field for F3.
	local function buildCrowd(id: string, position: Vector3, radius: number, count: number): any
		return {
			crowdId = id,
			position = position,
			radius = radius,
			count = count,
			state = "Active",
		}
	end

	--- Builds a mock CSM with a configurable getAllActive return + spy on updateCount.
	--- Indexes the crowds list by crowdId so `get(id)` returns the matching record
	--- (required by Story 004 drip-pass nil-guard re-fetch).
	local function buildMockCsm(crowds: { any }?): any
		local updateCountSpy = spy()
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
				return byId[crowdId]
			end,
			updateCount = function(crowdId: string, delta: number, source: string): number
				updateCountSpy(crowdId, delta, source)
				return 0  -- mock return; real CSM returns the new clamped count
			end,
			_updateCountSpy = updateCountSpy,
		}
	end

	local function buildMockPeelDispatcher(): any
		return { dispatch = spy() }
	end

	--- Helper: collect updateCount calls into per-crowdId dict for assertion.
	--- Returns map { [crowdId] = { totalDelta, callCount, sources } }.
	local function summarizeUpdateCounts(updateCountSpy: any): { [string]: any }
		local summary: { [string]: any } = {}
		for i = 1, updateCountSpy.callCount() do
			local call = updateCountSpy.getCall(i)
			local crowdId = call[1]
			local delta = call[2]
			local source = call[3]
			if summary[crowdId] == nil then
				summary[crowdId] = { totalDelta = 0, callCount = 0, sources = {} }
			end
			summary[crowdId].totalDelta += delta
			summary[crowdId].callCount += 1
			summary[crowdId].sources[source] = (summary[crowdId].sources[source] or 0) + 1
		end
		return summary
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CollisionResolver Story 003 — F3 drip math + per-pair updateCount", function()
		afterEach(function()
			CollisionResolver._resetForTests()
		end)

		-- -----------------------------------------------------------------------
		-- AC-07: F3 drip application (count differential drives delta)
		-- -----------------------------------------------------------------------

		-- AC-07 GDD reference: A count=100 vs B count=50, both r=8, overlapping.
		-- cd=50 → effective = 15 + 50*0.15 = 22.5 → ceil(22.5/15) = 2 → delta=2 (clamp).
		-- A is attacker (higher count) → +2; B defender → -2.
		it("AC-07 — A=100 vs B=50: +2 to A, -2 to B, source='Collision'", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8, 100),
				buildCrowd("bbb", Vector3.new(5, 0, 0), 8, 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].totalDelta).to.equal(2)
			expect(summary["bbb"].totalDelta).to.equal(-2)
			expect(summary["aaa"].sources["Collision"]).to.equal(1)
			expect(summary["bbb"].sources["Collision"]).to.equal(1)
		end)

		-- AC-07: ordered call sequence — story doc says "ordered call sequence" for
		-- attacker first then defender. Pair-iteration order is lex-sorted by pairKey,
		-- so within the aaa-bbb pair the equal-count branch and the count-differential
		-- branch both call `a.crowdId` first, then `b.crowdId`.
		it("AC-07 — ordered call sequence: attacker call first, defender second", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8, 100),
				buildCrowd("bbb", Vector3.new(5, 0, 0), 8, 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			-- Call 1: attacker aaa receives +delta. Call 2: defender bbb receives -delta.
			-- Order locked by drip-pass branch: `if a.count > b.count then a+ then b-`.
			local call1 = mockCsm._updateCountSpy.getCall(1)
			local call2 = mockCsm._updateCountSpy.getCall(2)
			expect(call1[1]).to.equal("aaa")
			expect(call1[2] > 0).to.equal(true)
			expect(call2[1]).to.equal("bbb")
			expect(call2[2] < 0).to.equal(true)
		end)

		-- AC-07 reverse-direction: B has higher count → B is attacker.
		it("AC-07 — B=200 vs A=100: +delta to B, -delta to A (direction flip)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8, 100),
				buildCrowd("bbb", Vector3.new(5, 0, 0), 8, 200),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- cd=100 → effective = 15 + 100*0.15 = 30 → ceil(30/15) = 2 → delta=2.
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["bbb"].totalDelta).to.equal(2)   -- attacker (higher count)
			expect(summary["aaa"].totalDelta).to.equal(-2)  -- defender (lower count)
		end)

		-- AC-07 edge: A count=300 (max), B count=10 → cd=290, effective=15+43.5=58.5
		-- → 58.5 < TRANSFER_RATE_MAX=60 (no rate cap hit) → ceil(58.5/15)=4 → hits
		-- DELTA_PER_TICK_MAX=4 clamp. Rate cap kicks in only at cd>=300; this case
		-- is bounded by the integer-delta clamp, not the float rate cap.
		it("AC-07 edge — cd=290: delta=4 (DELTA_PER_TICK_MAX clamp; rate cap not yet hit)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 50, 300),
				buildCrowd("bbb", Vector3.new(5, 0, 0), 50, 10),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].totalDelta).to.equal(4)
			expect(summary["bbb"].totalDelta).to.equal(-4)
		end)

		-- -----------------------------------------------------------------------
		-- AC-08: Equal-count mutual drain
		-- -----------------------------------------------------------------------

		-- AC-08 GDD reference: A and B both count=50, overlapping.
		-- count_delta=0 → mutual rule: BOTH lose 1; no `+` calls.
		it("AC-08 — A=50 vs B=50 equal: both -1, no `+` calls", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8, 50),
				buildCrowd("bbb", Vector3.new(5, 0, 0), 8, 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].totalDelta).to.equal(-1)
			expect(summary["bbb"].totalDelta).to.equal(-1)
			-- Audit: no positive deltas anywhere.
			for i = 1, mockCsm._updateCountSpy.callCount() do
				local call = mockCsm._updateCountSpy.getCall(i)
				expect(call[2] < 0).to.equal(true)
			end
		end)

		-- AC-08 floor edge: count=1 each — drip still fires (-1 to both); CSM F5
		-- owns the floor clamp, not CollisionResolver.
		it("AC-08 floor — A=1 vs B=1 equal: both -1 (CSM owns floor clamp)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 3, 1),
				buildCrowd("bbb", Vector3.new(1, 0, 0), 3, 1),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- CollisionResolver MUST NOT short-circuit on count=1; CSM F5 clamps.
			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].totalDelta).to.equal(-1)
			expect(summary["bbb"].totalDelta).to.equal(-1)
		end)

		-- -----------------------------------------------------------------------
		-- F3 clamp — delta_per_tick ∈ [1, 4]
		-- -----------------------------------------------------------------------

		-- F3: cd=0 → effective=15 → ceil(15/15)=1 → delta=1 (floor)
		it("F3 clamp — cd=0 → delta=1 (DELTA_PER_TICK_MIN floor)", function()
			expect(CollisionResolver._computeDeltaPerTick(50, 50)).to.equal(1)
			expect(CollisionResolver._computeDeltaPerTick(1, 1)).to.equal(1)
			expect(CollisionResolver._computeDeltaPerTick(300, 300)).to.equal(1)
		end)

		-- F3: cd=290 → effective=15+43.5=58.5 → ceil(58.5/15)=ceil(3.9)=4 → delta=4
		it("F3 clamp — cd=290 → delta=4 (DELTA_PER_TICK_MAX ceiling)", function()
			expect(CollisionResolver._computeDeltaPerTick(300, 10)).to.equal(4)
			expect(CollisionResolver._computeDeltaPerTick(10, 300)).to.equal(4)  -- abs symmetric
		end)

		-- F3: TRANSFER_RATE_MAX cap — cd=300 → uncapped effective=60, capped=60
		-- → ceil(60/15)=4 → delta=4
		it("F3 clamp — cd=300 → effective hits TRANSFER_RATE_MAX cap, delta=4", function()
			expect(CollisionResolver._computeDeltaPerTick(300, 0)).to.equal(4)
		end)

		-- F3: cd=10 → effective=15+1.5=16.5 → ceil(16.5/15)=ceil(1.1)=2 → delta=2
		it("F3 clamp — cd=10 → delta=2 (small differential)", function()
			expect(CollisionResolver._computeDeltaPerTick(60, 50)).to.equal(2)
		end)

		-- F3: cd=110 → effective=15+16.5=31.5 → ceil(31.5/15)=ceil(2.1)=3 → delta=3
		it("F3 clamp — cd=110 → delta=3 (mid-range)", function()
			expect(CollisionResolver._computeDeltaPerTick(110, 0)).to.equal(3)
		end)

		-- F3: cd=150 → effective=15+22.5=37.5 → ceil(37.5/15)=ceil(2.5)=3 → delta=3
		it("F3 clamp — cd=150 → delta=3 (story edge case)", function()
			expect(CollisionResolver._computeDeltaPerTick(150, 0)).to.equal(3)
		end)

		-- F3 story-doc narrative edges (story-003-drip-math.md line 76):
		-- "A count=110 → cd=60 → effective=15+9=24 → delta=ceil(24/15)=2"
		--   inputs: A=110, B=50, cd=60, effective=24, delta=2
		it("F3 clamp — story-doc edge: A=110 vs B=50 (cd=60) → delta=2", function()
			expect(CollisionResolver._computeDeltaPerTick(110, 50)).to.equal(2)
		end)

		-- F3 story-doc narrative edges (story-003-drip-math.md line 76):
		-- "A count=150 → cd=100 → effective=15+15=30 → delta=2"
		--   inputs: A=150, B=50, cd=100, effective=30, delta=2
		it("F3 clamp — story-doc edge: A=150 vs B=50 (cd=100) → delta=2", function()
			expect(CollisionResolver._computeDeltaPerTick(150, 50)).to.equal(2)
		end)

		-- F3: integer output guarantee — floating-point ceil produces integer.
		it("F3 clamp — output is always integer", function()
			for _, pair in ipairs({ {100, 50}, {110, 0}, {150, 0}, {200, 0}, {299, 1}, {1, 300} }) do
				local result = CollisionResolver._computeDeltaPerTick(pair[1], pair[2])
				expect(result == math.floor(result)).to.equal(true)
			end
		end)

		-- -----------------------------------------------------------------------
		-- Triple-overlap (TR-ccr-018)
		-- -----------------------------------------------------------------------

		-- Triple-overlap equal-count: 3 mutually overlapping crowds, all count=50.
		-- 3 pairs × 2 sides = 6 updateCount calls; all -1 (mutual drain per pair).
		-- Each crowd appears in 2 pairs → totalDelta per crowd = -2.
		it("Triple-overlap — 3 equal-count crowds: 6 updateCount calls, all -1, totalDelta=-2 each", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 100, 50),
				buildCrowd("bbb", Vector3.new(0, 0, 0), 100, 50),
				buildCrowd("ccc", Vector3.new(0, 0, 0), 100, 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(6)
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].callCount).to.equal(2)
			expect(summary["bbb"].callCount).to.equal(2)
			expect(summary["ccc"].callCount).to.equal(2)
			expect(summary["aaa"].totalDelta).to.equal(-2)
			expect(summary["bbb"].totalDelta).to.equal(-2)
			expect(summary["ccc"].totalDelta).to.equal(-2)
		end)

		-- Triple-overlap monotonic counts: 3 crowds A=100, B=200, C=300, all overlapping.
		-- Pairs (sorted by lex pairKey): aaa-bbb, aaa-ccc, bbb-ccc.
		-- aaa-bbb: cd=100 → delta=2; B (higher) attacker, A defender. A:-2, B:+2.
		-- aaa-ccc: cd=200 → effective=45 → ceil(3)=3 → delta=3. C attacker, A defender. A:-3, C:+3.
		-- bbb-ccc: cd=100 → delta=2. C attacker, B defender. B:-2, C:+2.
		-- Net per crowd: A = -2-3 = -5; B = +2-2 = 0; C = +3+2 = +5.
		it("Triple-overlap — monotonic counts A=100 < B=200 < C=300: net deltas correct", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 100, 100),
				buildCrowd("bbb", Vector3.new(0, 0, 0), 100, 200),
				buildCrowd("ccc", Vector3.new(0, 0, 0), 100, 300),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(6)
			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].totalDelta).to.equal(-5)
			expect(summary["bbb"].totalDelta).to.equal(0)
			expect(summary["ccc"].totalDelta).to.equal(5)
		end)

		-- Triple-overlap: each crowd appears in exactly 2 distinct pairs (not 3 — no self).
		it("Triple-overlap — no self-pair: each crowd in exactly 2 pairs", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 100, 100),
				buildCrowd("bbb", Vector3.new(0, 0, 0), 100, 200),
				buildCrowd("ccc", Vector3.new(0, 0, 0), 100, 300),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			local summary = summarizeUpdateCounts(mockCsm._updateCountSpy)
			expect(summary["aaa"].callCount).to.equal(2)
			expect(summary["bbb"].callCount).to.equal(2)
			expect(summary["ccc"].callCount).to.equal(2)
		end)

		-- -----------------------------------------------------------------------
		-- Cross-cutting: no updateCount fires when no overlap pairs accumulated
		-- -----------------------------------------------------------------------

		it("no overlap — far-apart crowds: zero updateCount calls", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 5, 100),
				buildCrowd("bbb", Vector3.new(100, 0, 0), 5, 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- Dormant tick — no updateCount fires.
		it("Dormant — empty getAllActive: zero updateCount calls", function()
			local mockCsm = buildMockCsm({})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
		end)

		-- All updateCount calls use source="Collision".
		it("source — all updateCount calls use source='Collision'", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 100, 100),
				buildCrowd("bbb", Vector3.new(0, 0, 0), 100, 200),
				buildCrowd("ccc", Vector3.new(0, 0, 0), 100, 300),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			for i = 1, mockCsm._updateCountSpy.callCount() do
				local call = mockCsm._updateCountSpy.getCall(i)
				expect(call[3]).to.equal("Collision")
			end
		end)
	end)
end
