--!strict

--[[
	CollisionResolver Story 005 — overlap-bit feed (setStillOverlapping post-drip)
	— unit tests.
	Path: tests/unit/collision/overlap_bit_feed.spec.luau

	Implements Story 005 (CCR) QA test cases:
	  AC-09 — Overlap-bit feed: every active crowd receives exactly one
	          setStillOverlapping call per tick; flag matches whether crowd
	          appeared in any overlapping pair (with state-eligibility filter).
	  AC-14 — 2-vs-2 mutual GraceWindow: equal-count Active+Active overlap →
	          updateCount(-1) ×2 (Story 003) + setStillOverlapping(true) ×2 ×
	          this tick. CSM transition to GraceWindow happens in Phase 5
	          (out of CCR scope). Next tick if records flip to GraceWindow:
	          drip skipped (Story 004) but overlap-bit still reported true.
	  TR-019 — GraceWindow overlap reported: GraceWindow-side contributes to
	          overlap-bit aggregation (drives CSM Phase 5 timer expiry).
	  AC-13 partial — Write-access contract: ONLY updateCount +
	          setStillOverlapping fire from CCR; transitionTo/setState never.

	Test isolation: CollisionResolver._resetForTests() in afterEach.
	All deps injected via mocks — no real CSM or PeelDispatcher required.

	Test naming: it("AC-NN — description", ...) per project convention.
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

	--- Builds a CSM-shaped crowd record. position defaults to (0,0,0) so all
	--- crowds with default position overlap by radius alone.
	local function buildCrowd(id: string, state: string, count: number?, position: Vector3?, radius: number?): any
		return {
			crowdId = id,
			position = position or Vector3.new(0, 0, 0),
			radius = radius or 100,
			count = count or 50,
			state = state,
		}
	end

	--- Builds a mock CSM with spies on updateCount + setStillOverlapping +
	--- tripwires on transitionTo + setState.
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
					return nil
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

	--- Helper: build per-crowdId summary of setStillOverlapping calls.
	--- Returns { [crowdId] = { callCount, lastFlag } }.
	local function summarizeSetStillOverlapping(spyObj: any): { [string]: any }
		local summary: { [string]: any } = {}
		for i = 1, spyObj.callCount() do
			local call = spyObj.getCall(i)
			local id = call[1]
			local flag = call[2]
			if summary[id] == nil then
				summary[id] = { callCount = 0, lastFlag = nil }
			end
			summary[id].callCount += 1
			summary[id].lastFlag = flag
		end
		return summary
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("CollisionResolver Story 005 — overlap-bit feed", function()
		afterEach(function()
			CollisionResolver._resetForTests()
		end)

		-- -----------------------------------------------------------------------
		-- AC-09: Exactly one setStillOverlapping call per active crowd per tick
		-- -----------------------------------------------------------------------

		-- AC-09 main scenario: A-B overlap (Active), C standalone (no overlap),
		-- D-A overlap with D in GraceWindow.
		-- Expected: 4 setStillOverlapping calls — A=true, B=true, C=false, D=true.
		it("AC-09 — A-B overlap + C standalone + D in GraceWindow overlapping A: 4 calls, correct flags", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),  -- overlaps A
				buildCrowd("ccc", "Active", 30, Vector3.new(500, 0, 0), 5),  -- far apart
				buildCrowd("ddd", "GraceWindow", 1, Vector3.new(0, 0, 0), 50),  -- overlaps A
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(4)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].callCount).to.equal(1)
			expect(summary["bbb"].callCount).to.equal(1)
			expect(summary["ccc"].callCount).to.equal(1)
			expect(summary["ddd"].callCount).to.equal(1)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(true)
			expect(summary["ccc"].lastFlag).to.equal(false)
			expect(summary["ddd"].lastFlag).to.equal(true)
		end)

		-- AC-09 edge: 12 crowds far apart → 12 setStillOverlapping calls all `false`.
		it("AC-09 edge — 12 crowds, zero overlaps: 12 calls all false", function()
			local crowds: { any } = {}
			for i = 1, 12 do
				table.insert(
					crowds,
					buildCrowd(
						string.format("%03d", i),
						"Active",
						50,
						Vector3.new(i * 1000, 0, 0),  -- far apart
						5
					)
				)
			end
			local mockCsm = buildMockCsm(crowds)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(12)
			for i = 1, 12 do
				local call = mockCsm._setStillOverlappingSpy.getCall(i)
				expect(call[2]).to.equal(false)
			end
		end)

		-- AC-09 edge: 2 crowds overlapping → 2 calls both `true`.
		it("AC-09 edge — 2 overlapping crowds: 2 calls both true", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(2)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- AC-09 edge: 1 crowd → 1 call, flag=false (no pair to overlap with).
		it("AC-09 edge — 1 crowd: 1 call, flag=false", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(1)
			local call = mockCsm._setStillOverlappingSpy.getCall(1)
			expect(call[1]).to.equal("aaa")
			expect(call[2]).to.equal(false)
		end)

		-- AC-09 edge: Dormant tick (empty getAllActive) → 0 setStillOverlapping calls.
		it("AC-09 edge — Dormant: zero setStillOverlapping calls", function()
			local mockCsm = buildMockCsm({})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(0)
		end)

		-- -----------------------------------------------------------------------
		-- AC-09: ordering — setStillOverlapping fires AFTER all updateCount calls
		-- -----------------------------------------------------------------------

		-- All updateCount calls must precede all setStillOverlapping calls within
		-- a single tick (GDD §C Rule 6 ordering: drip pass before overlap-bit feed).
		it("AC-09 — call order: all updateCount precedes all setStillOverlapping", function()
			-- Track relative invocation order via a single sequence spy
			local sequence: { string } = {}
			local mockCsm: any = {
				getAllActive = function(): { any }
					return {
						buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
						buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
					}
				end,
				get = function(crowdId: string): any
					return {
						crowdId = crowdId,
						position = Vector3.new(0, 0, 0),
						radius = 50,
						count = if crowdId == "aaa" then 100 else 50,
						state = "Active",
					}
				end,
				updateCount = function(_id: string, _delta: number, _source: string): number
					table.insert(sequence, "updateCount")
					return 0
				end,
				setStillOverlapping = function(_id: string, _flag: boolean): ()
					table.insert(sequence, "setStillOverlapping")
				end,
			}
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Find the first setStillOverlapping. All earlier entries must be updateCount.
			local firstSetStillIdx: number? = nil
			for i, label in ipairs(sequence) do
				if label == "setStillOverlapping" then
					firstSetStillIdx = i
					break
				end
			end
			expect(firstSetStillIdx).to.be.ok()
			for i = 1, (firstSetStillIdx :: number) - 1 do
				expect(sequence[i]).to.equal("updateCount")
			end
		end)

		-- -----------------------------------------------------------------------
		-- TR-ccr-019: GraceWindow side contributes to overlap-bit
		-- -----------------------------------------------------------------------

		-- GraceWindow + Active overlapping → both report true (drives CSM Phase 5).
		it("TR-019 — GraceWindow side contributes to overlap-bit (true for both, 2 fan-out calls)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "GraceWindow", 1, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(2)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].callCount).to.equal(1)
			expect(summary["bbb"].callCount).to.equal(1)
			expect(summary["aaa"].lastFlag).to.equal(true)  -- GraceWindow side
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- Both GraceWindow overlapping → both report true.
		it("TR-019 — GraceWindow ↔ GraceWindow: both report true (2 fan-out calls)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "GraceWindow", 1, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "GraceWindow", 1, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(2)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].callCount).to.equal(1)
			expect(summary["bbb"].callCount).to.equal(1)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- -----------------------------------------------------------------------
		-- Per-side eligibility: nil-side does NOT contribute
		-- -----------------------------------------------------------------------

		-- A overlap pair appears in iteration but A's csm.get returns nil (race).
		-- A is also absent from getAllActive (representing PlayerRemoving).
		-- Expected: B receives `false` because A's side did not contribute and
		-- there's no other overlap pair for B.
		it("Per-side — nil A side does not contribute to overlap aggregation", function()
			-- Setup: getAllActive returns only B; pair iteration produces no pairs
			-- (only 1 crowd). Confirms the nil-side contract through degenerate path.
			local mockCsm = buildMockCsm({
				buildCrowd("bbb", "Active", 50, Vector3.new(0, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Only B in active set → 1 call, flag=false (no overlap pairs).
			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(1)
			local call = mockCsm._setStillOverlappingSpy.getCall(1)
			expect(call[1]).to.equal("bbb")
			expect(call[2]).to.equal(false)
		end)

		-- Two crowds overlap. csm.get returns nil for A only (PlayerRemoving race
		-- between getAllActive and the drip pass).
		-- Per-side eligibility is decided per crowd, NOT per pair: B's side is
		-- non-nil + Active so B contributes its own side regardless of A's nil
		-- status. A's side is nil so A does not contribute.
		-- Both crowds remain in `active` (the snapshot from getAllActive at tick
		-- start), so both still receive a setStillOverlapping call from the
		-- fan-out — A with flag=false, B with flag=true.
		it("Per-side — nil A from get: A flag=false, B flag=true (per-crowd eligibility)", function()
			local mockCsm = buildMockCsm(
				{
					buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
					buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
				},
				{ ["aaa"] = true }  -- aaa fetch returns nil; aaa side does not contribute
			)
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Both still in active set → both called once.
			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(2)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].lastFlag).to.equal(false)
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- -----------------------------------------------------------------------
		-- Per-side eligibility: Eliminated does NOT contribute
		-- -----------------------------------------------------------------------

		-- A overlapping with Eliminated B → A reports true (A is Active and
		-- contributes from its own side); B reports false (Eliminated does not).
		-- Total fan-out assertion: both still in `active` (mock returns them
		-- both via getAllActive), so callCount must be exactly 2 — guards
		-- against fan-out accidentally skipping Eliminated crowds.
		it("Per-side — Eliminated B does not contribute; A reports true; fan-out fires for both", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Eliminated", 1, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(2)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].callCount).to.equal(1)
			expect(summary["bbb"].callCount).to.equal(1)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(false)
		end)

		-- -----------------------------------------------------------------------
		-- AC-14: 2-vs-2 mutual GraceWindow scenario
		-- -----------------------------------------------------------------------

		-- A count=2 Active, B count=2 Active overlap.
		-- Story 003 equal-count drain: updateCount(-1) for both.
		-- Story 005 overlap-bit: both true.
		-- CSM transitions to GraceWindow next tick (Phase 5 — out of scope here).
		it("AC-14 — A=B=2 Active overlap: 2 updateCount(-1) + 2 setStillOverlapping(true)", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 2, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 2, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Drip: 2 updateCount calls, both -1 (equal-count mutual drain).
			expect(mockCsm._updateCountSpy.callCount()).to.equal(2)
			for i = 1, 2 do
				local call = mockCsm._updateCountSpy.getCall(i)
				expect(call[2]).to.equal(-1)
				expect(call[3]).to.equal("Collision")
			end
			-- Overlap-bit: both true.
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- AC-14 follow-up: simulate next tick where records flipped to GraceWindow.
		-- Story 004 skips drip (no updateCount); Story 005 still reports true.
		it("AC-14 — next tick GraceWindow ↔ GraceWindow: no drip, both still report true", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "GraceWindow", 1, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "GraceWindow", 1, Vector3.new(5, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- No drip (Story 004 skip).
			expect(mockCsm._updateCountSpy.callCount()).to.equal(0)
			-- Overlap-bit still true for both (TR-ccr-019).
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["aaa"].lastFlag).to.equal(true)
			expect(summary["bbb"].lastFlag).to.equal(true)
		end)

		-- -----------------------------------------------------------------------
		-- AC-13 (partial): write-access contract — no transitionTo / setState
		-- -----------------------------------------------------------------------

		it("AC-13 partial — only updateCount + setStillOverlapping fire, no transitionTo / setState", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(0, 0, 0), 50),
				buildCrowd("ccc", "GraceWindow", 1, Vector3.new(0, 0, 0), 50),
				buildCrowd("ddd", "Eliminated", 1, Vector3.new(0, 0, 0), 50),
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})
			CollisionResolver.tickPhase1(2, {})
			CollisionResolver.tickPhase1(3, {})

			-- Authorized writes fire; forbidden writes do NOT.
			expect(mockCsm._updateCountSpy.callCount() > 0).to.equal(true)
			expect(mockCsm._setStillOverlappingSpy.callCount() > 0).to.equal(true)
			expect(mockCsm._transitionToSpy.callCount()).to.equal(0)
			expect(mockCsm._setStateSpy.callCount()).to.equal(0)
		end)

		-- -----------------------------------------------------------------------
		-- Cross-cutting: overlap-bit aggregation cleared between ticks
		-- -----------------------------------------------------------------------

		-- _overlapCrowds is cleared at top of each tick. Tick 1: A overlaps B
		-- (both true). Tick 2: only A in active list (no overlap) → A flag=false.
		it("scratch — _overlapCrowds cleared between ticks (no leak)", function()
			local crowdList: { any } = {
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
			}
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
						if v.crowdId == crowdId then return v end
					end
					return nil
				end,
				updateCount = function(_id: string, _delta: number, _source: string): number
					return 0
				end,
				setStillOverlappingCalls = {} :: { { id: string, flag: boolean } },
				setStillOverlapping = function(self: any, ...): ()
					-- Method-call syntax not used; this is a function field.
				end,
			}
			-- Replace setStillOverlapping with closure that captures the calls table.
			local calls: { { id: string, flag: boolean } } = {}
			mockCsm.setStillOverlapping = function(id: string, flag: boolean): ()
				table.insert(calls, { id = id, flag = flag })
			end

			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			-- Tick 1: A and B overlap → both true.
			CollisionResolver.tickPhase1(1, {})
			expect(#calls).to.equal(2)
			expect(calls[1].flag).to.equal(true)
			expect(calls[2].flag).to.equal(true)

			-- Tick 2: remove B → A alone → A flag=false (overlap state cleared).
			calls = {}
			mockCsm.setStillOverlapping = function(id: string, flag: boolean): ()
				table.insert(calls, { id = id, flag = flag })
			end
			table.remove(crowdList, 2)
			CollisionResolver.tickPhase1(2, {})
			expect(#calls).to.equal(1)
			expect(calls[1].id).to.equal("aaa")
			expect(calls[1].flag).to.equal(false)  -- aggregation reset between ticks
		end)

		-- -----------------------------------------------------------------------
		-- Snapshot accessor sanity: _snapshotOverlapCrowds reflects last tick
		-- -----------------------------------------------------------------------

		it("_snapshotOverlapCrowds — reflects per-tick aggregation set + fan-out fires for all active crowds", function()
			local mockCsm = buildMockCsm({
				buildCrowd("aaa", "Active", 100, Vector3.new(0, 0, 0), 50),
				buildCrowd("bbb", "Active", 50, Vector3.new(5, 0, 0), 50),
				buildCrowd("ccc", "Active", 30, Vector3.new(500, 0, 0), 5),  -- far apart
			})
			CollisionResolver.init({ csm = mockCsm, peelDispatcher = buildMockPeelDispatcher() })

			CollisionResolver.tickPhase1(1, {})

			-- Aggregation set: only overlapping crowds.
			local snap = CollisionResolver._snapshotOverlapCrowds()
			expect(snap["aaa"]).to.equal(true)
			expect(snap["bbb"]).to.equal(true)
			-- ccc is NOT in the set (no overlap pairs); _snapshotOverlapCrowds
			-- only contains crowds that were aggregated to true.
			expect(snap["ccc"]).to.never.be.ok()

			-- Fan-out consumer path: iterates the FULL active set (not just the
			-- aggregation snapshot). All 3 crowds receive a setStillOverlapping
			-- call; ccc receives `false` because it's absent from _overlapCrowds.
			-- Asserting the fan-out callCount here closes the gap between the
			-- aggregation set (internal) and the consumer behavior (external).
			expect(mockCsm._setStillOverlappingSpy.callCount()).to.equal(3)
			local summary = summarizeSetStillOverlapping(mockCsm._setStillOverlappingSpy)
			expect(summary["ccc"].lastFlag).to.equal(false)
		end)
	end)
end
