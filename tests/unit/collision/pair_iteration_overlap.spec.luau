--!strict

--[[
	CollisionResolver Story 002 — pair iteration + F1 overlap + F2 pair_key — unit tests.
	Path: tests/unit/collision/pair_iteration_overlap.spec.luau

	Implements Story 002 (CCR) QA test cases:
	  AC-03 — O(p²) unique unordered pair iteration; no self-pair; no duplicate;
	          1/2/3/12 crowd counts; reverse input order still produces lex-sorted pairKeys.
	  AC-04 — F1 squared-distance test, Y axis ignored; boundary distSq == combinedSq.
	  AC-05 — F2 pair_key canonical lex form; order-independent.
	  AC-15 — Stacked position (distSq=0) → overlap=true; no divide-by-zero.

	Test isolation:
	  CollisionResolver._resetForTests() in afterEach.
	  All deps injected via mocks — no real CSM or PeelDispatcher required.

	Test naming: it("AC-NN — description", ...) per project convention
	(mirrors tests/unit/collision/phase1_skeleton.spec.luau).
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

	--- Builds a CSM-shaped crowd record for tests. Defaults state to "Active"
	--- (getAllActive already excludes Eliminated per CSM contract).
	local function buildCrowd(id: string, position: Vector3, radius: number): any
		return {
			crowdId = id,
			position = position,
			radius = radius,
			-- count + state included so Story 003 drip pass + Story 004 state filter
			-- work against this mock without erroring. Story 002 tests don't observe
			-- updateCount calls, but the drip pass still runs each tick and needs
			-- these fields to be present.
			count = 50,
			state = "Active",
		}
	end

	--- Builds a mock CSM with a configurable getAllActive return value.
	--- Indexes the crowds list by crowdId so `get(id)` returns the matching record
	--- (required by Story 004 drip-pass nil-guard re-fetch).
	local function buildMockCsm(crowds: { any }?): any
		local getAllActiveSpy = spy()
		local byId: { [string]: any } = {}
		if crowds ~= nil then
			for _, c in ipairs(crowds) do
				byId[c.crowdId] = c
			end
		end
		return {
			getAllActive = function(): { any }
				getAllActiveSpy()
				-- Return a fresh array per call — matches real CSM contract
				-- (CrowdStateServer.getAllActive returns fresh array each call).
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
			updateCount = function(_id: string, _delta: number, _source: string): number
				return 0  -- no-op for Story 002 (drip pass calls this; we don't assert on it)
			end,
			setStillOverlapping = function(_id: string, _flag: boolean): ()
				-- no-op for Story 002 tests; Story 005 added this fan-out call
			end,
			_getAllActiveSpy = getAllActiveSpy,
		}
	end

	--- Builds a mock PeelDispatcher (no-op for Story 002; Story 008+ exercises it).
	local function buildMockPeelDispatcher(): any
		return {
			dispatch = spy(),
		}
	end

	--- Helper: collect pairKeys from a snapshot into a set for order-insensitive assertions.
	local function collectPairKeys(snapshot: { any }): { [string]: boolean }
		local keys: { [string]: boolean } = {}
		for _, entry in ipairs(snapshot) do
			keys[entry.pairKey] = true
		end
		return keys
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CollisionResolver Story 002 — pair iteration + F1 + F2", function()
		afterEach(function()
			CollisionResolver._resetForTests()
		end)

		-- -----------------------------------------------------------------------
		-- AC-03: O(p²) unique unordered pair iteration
		-- -----------------------------------------------------------------------

		-- AC-03: 1 crowd → 0 pairs (degenerate case).
		it("AC-03 — 1 crowd: zero pairs accumulated", function()
			local mockCsm = buildMockCsm({
				buildCrowd("111", Vector3.new(0, 0, 0), 5),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(0)
		end)

		-- AC-03: 2 crowds overlapping → 1 pair. Also verifies pair record contains
		-- the actual CrowdRecord references for `a` and `b` (Story 003 consumes
		-- these for drip math; swapped references would silently produce wrong
		-- attacker/defender targets).
		it("AC-03 — 2 crowds overlapping: exactly 1 pair, a/b refs preserved", function()
			local crowdA = buildCrowd("111", Vector3.new(0, 0, 0), 8)
			local crowdB = buildCrowd("222", Vector3.new(5, 0, 0), 8)
			local mockCsm = buildMockCsm({ crowdA, crowdB })
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
			local snap = CollisionResolver._snapshotOverlapPairs()
			expect(snap[1].pairKey).to.equal("111|222")
			-- Reference identity: pair record holds the same record table objects
			-- supplied via getAllActive (NOT clones). Pre-sort means a == "111", b == "222".
			expect(snap[1].a.crowdId).to.equal("111")
			expect(snap[1].b.crowdId).to.equal("222")
			expect(snap[1].a.position).to.equal(crowdA.position)
			expect(snap[1].b.position).to.equal(crowdB.position)
		end)

		-- AC-03: 3 crowds all overlapping → exactly 3 unique pairs (no self-pair, no dup).
		it("AC-03 — 3 crowds all overlapping: 3 unique pairs, no self-pair, no duplicate", function()
			local mockCsm = buildMockCsm({
				buildCrowd("111", Vector3.new(0, 0, 0), 100),
				buildCrowd("222", Vector3.new(0, 0, 0), 100),
				buildCrowd("333", Vector3.new(0, 0, 0), 100),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(3)
			local keys = collectPairKeys(CollisionResolver._snapshotOverlapPairs())
			expect(keys["111|222"]).to.equal(true)
			expect(keys["111|333"]).to.equal(true)
			expect(keys["222|333"]).to.equal(true)
			-- Audit: no self-pair, no inverted-order key.
			expect(keys["111|111"]).to.never.be.ok()
			expect(keys["222|222"]).to.never.be.ok()
			expect(keys["222|111"]).to.never.be.ok()
			expect(keys["333|111"]).to.never.be.ok()
			expect(keys["333|222"]).to.never.be.ok()
		end)

		-- AC-03: reverse input order still produces lex-sorted pairKeys (pre-sort works).
		it("AC-03 — reverse input order: pairKeys still lex-sorted", function()
			local mockCsm = buildMockCsm({
				buildCrowd("333", Vector3.new(0, 0, 0), 100),
				buildCrowd("222", Vector3.new(0, 0, 0), 100),
				buildCrowd("111", Vector3.new(0, 0, 0), 100),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			local keys = collectPairKeys(CollisionResolver._snapshotOverlapPairs())
			expect(keys["111|222"]).to.equal(true)
			expect(keys["111|333"]).to.equal(true)
			expect(keys["222|333"]).to.equal(true)
		end)

		-- AC-03: 12 crowds all overlapping → 66 pairs (validates O(p²) count: 12*11/2).
		it("AC-03 — 12 crowds all overlapping: 66 pairs (O(p²) count)", function()
			local crowds: { any } = {}
			for i = 1, 12 do
				table.insert(crowds, buildCrowd(string.format("%03d", i), Vector3.new(0, 0, 0), 100))
			end
			local mockCsm = buildMockCsm(crowds)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(66)
		end)

		-- -----------------------------------------------------------------------
		-- AC-04: F1 squared-distance overlap, Y ignored
		-- -----------------------------------------------------------------------

		-- AC-04: A(0,0,0) r=8 vs B(10,50,0) r=8 — Y differs but XZ within combined radius.
		-- distSq=100, combinedSq=256, overlap=true.
		it("AC-04 — F1 Y-ignored: A-B horizontal overlap despite Y=50 difference", function()
			-- Direct F1 helper assertion
			expect(CollisionResolver._isOverlapSq(0, 0, 10, 0, 256)).to.equal(true)

			-- Integration via tickPhase1
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8),
				buildCrowd("bbb", Vector3.new(10, 50, 0), 8),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
			local snap = CollisionResolver._snapshotOverlapPairs()
			expect(snap[1].distSq).to.equal(100)
			expect(snap[1].pairKey).to.equal("aaa|bbb")
		end)

		-- AC-04: A(0,0,0) r=8 vs C(20,0,0) r=8 — too far apart.
		-- distSq=400, combinedSq=256, overlap=false.
		it("AC-04 — F1 non-overlap: 20 studs apart with combinedSq=256", function()
			expect(CollisionResolver._isOverlapSq(0, 0, 20, 0, 256)).to.equal(false)

			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8),
				buildCrowd("ccc", Vector3.new(20, 0, 0), 8),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(0)
		end)

		-- AC-04 GDD example: 3-crowd setup A,B,C — verify only A-B overlaps.
		-- A at (0,0,0) r=8, B at (10,50,0) r=8 → distSq=100 (Y=50 ignored), overlap=true.
		-- A-C: distSq=50²=2500 (XZ=50 stud horizontal), overlap=false.
		-- B-C: dx=40, dz=0 → distSq=1600, overlap=false.
		-- Closes story-spec QA row "B-C overlap=false" with end-to-end integration.
		-- C is placed at X=50 (not X=20 as in the AC-04 helper test) because Y is
		-- ignored — at X=20 the B-C pair (dx=10) would also overlap, defeating the
		-- 3-crowd "only A-B" intent.
		it("AC-04 — GDD 3-crowd example: only A-B pair overlaps (A-C + B-C non-overlap)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8),
				buildCrowd("bbb", Vector3.new(10, 50, 0), 8),
				buildCrowd("ccc", Vector3.new(50, 0, 0), 8),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
			local snap = CollisionResolver._snapshotOverlapPairs()
			expect(snap[1].pairKey).to.equal("aaa|bbb")
			-- B-C and A-C absences (proven by total count == 1 above).
		end)

		-- AC-04 boundary: distSq == combinedSq → overlap=true (≤ inclusive).
		it("AC-04 — F1 boundary: distSq == combinedSq → overlap (inclusive ≤)", function()
			-- A(0,0,0) r=8, B(16,0,0) r=8 → dx=16, dx²=256, combined=16, combinedSq=256.
			expect(CollisionResolver._isOverlapSq(0, 0, 16, 0, 256)).to.equal(true)

			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(0, 0, 0), 8),
				buildCrowd("bbb", Vector3.new(16, 0, 0), 8),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
		end)

		-- -----------------------------------------------------------------------
		-- AC-05: F2 pair_key canonical lex
		-- -----------------------------------------------------------------------

		-- AC-05: numeric-string lex compare. "3"<"5" so "3891" < "512" lex-wise.
		it("AC-05 — pairKey('3891','512') == '3891|512' (lex compare, not numeric)", function()
			expect(CollisionResolver._pairKey("3891", "512")).to.equal("3891|512")
		end)

		-- AC-05: order-independence — flipping arg order yields same key.
		it("AC-05 — pairKey order-independent: pairKey(a,b) == pairKey(b,a)", function()
			expect(CollisionResolver._pairKey("512", "3891")).to.equal("3891|512")
			expect(CollisionResolver._pairKey("3891", "512")).to.equal("3891|512")
		end)

		-- AC-05: zero-padded vs nines.
		it("AC-05 — pairKey('000','999') == '000|999'", function()
			expect(CollisionResolver._pairKey("000", "999")).to.equal("000|999")
			expect(CollisionResolver._pairKey("999", "000")).to.equal("000|999")
		end)

		-- AC-05: alphabetic strings.
		it("AC-05 — pairKey alphabetic: 'aaa' vs 'aab' lex differ at last char", function()
			expect(CollisionResolver._pairKey("aaa", "aab")).to.equal("aaa|aab")
			expect(CollisionResolver._pairKey("aab", "aaa")).to.equal("aaa|aab")
		end)

		-- AC-05: single-char ids.
		it("AC-05 — pairKey single-char: 'a' vs 'b' → 'a|b'", function()
			expect(CollisionResolver._pairKey("a", "b")).to.equal("a|b")
			expect(CollisionResolver._pairKey("b", "a")).to.equal("a|b")
		end)

		-- -----------------------------------------------------------------------
		-- AC-15: Stacked position (no divide-by-zero)
		-- -----------------------------------------------------------------------

		-- AC-15: A and B at exact same XZ → distSq=0 → overlap=true.
		it("AC-15 — stacked XZ: distSq=0, overlap=true, no divide-by-zero", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(5, 0, 5), 3.05),
				buildCrowd("bbb", Vector3.new(5, 0, 5), 3.05),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			local ok = pcall(function()
				CollisionResolver.tickPhase1(1, {})
			end)
			expect(ok).to.equal(true)

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
			local snap = CollisionResolver._snapshotOverlapPairs()
			expect(snap[1].distSq).to.equal(0)
		end)

		-- AC-15: Y differs but XZ identical → still overlap (Y ignored).
		it("AC-15 — Y-only difference: still overlap (Y ignored)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", Vector3.new(5, 0, 5), 3.05),
				buildCrowd("bbb", Vector3.new(5, 100, 5), 3.05),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
			expect(CollisionResolver._snapshotOverlapPairs()[1].distSq).to.equal(0)
		end)

		-- AC-15 degenerate: both r=0 stacked → distSq=0, combinedSq=0 → overlap on stack only.
		it("AC-15 — both r=0 stacked: combinedSq=0 → overlap on exact stack only", function()
			-- Direct helper call: stacked → overlap.
			expect(CollisionResolver._isOverlapSq(0, 0, 0, 0, 0)).to.equal(true)
			-- 1 stud apart with r=0 → no overlap.
			expect(CollisionResolver._isOverlapSq(0, 0, 1, 0, 0)).to.equal(false)
		end)

		-- -----------------------------------------------------------------------
		-- Cross-cutting: _overlapPairs scratch is cleared each tick (qa-tester gap B
		-- from Story 001 review now satisfied by the test-only accessor).
		-- -----------------------------------------------------------------------

		it("scratch — _overlapPairs cleared at top of each tick (no leak across ticks)", function()
			local crowdList: { any } = {
				buildCrowd("aaa", Vector3.new(0, 0, 0), 100),
				buildCrowd("bbb", Vector3.new(0, 0, 0), 100),
			}
			-- Inline mock provides get + updateCount so Story 004 drip pass (which
			-- re-fetches via csm.get) does not error when run against this fixture.
			local mockCsm: any = {
				getAllActive = function(): { any }
					local copy: { any } = {}
					for i, v in ipairs(crowdList) do
						copy[i] = v
					end
					return copy
				end,
				get = function(crowdId: string): any
					for _, v in ipairs(crowdList) do
						if v.crowdId == crowdId then
							return v
						end
					end
					return nil
				end,
				updateCount = function(_id: string, _delta: number, _source: string): number
					return 0  -- no-op for scratch-clear test
				end,
				setStillOverlapping = function(_id: string, _flag: boolean): () end,
			}
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			-- Tick 1: 2 crowds overlapping → 1 pair
			CollisionResolver.tickPhase1(1, {})
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)

			-- Tick 2: clear crowds → empty (Dormant) → length back to 0
			table.clear(crowdList)
			CollisionResolver.tickPhase1(2, {})
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(0)

			-- Tick 3: re-populate → length restored to 1 (proves scratch reset, not append)
			table.insert(crowdList, buildCrowd("aaa", Vector3.new(0, 0, 0), 100))
			table.insert(crowdList, buildCrowd("bbb", Vector3.new(0, 0, 0), 100))
			CollisionResolver.tickPhase1(3, {})
			expect(CollisionResolver._getOverlapPairsLength()).to.equal(1)
		end)
	end)
end
