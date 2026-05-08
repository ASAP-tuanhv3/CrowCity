--!strict

--[[
	CollisionResolver — Phase 1 tick callback: crowd-pair collision resolution.
	Path: ServerStorage/Source/CollisionResolver/init.luau

	Implements:
	  Story 001 (CCR): Phase 1 callback skeleton + Dormant/Ticking states (TR-ccr-001)
	  Story 002 (CCR): F1 pair overlap + F2 pair_key + O(p²) unique pair iteration
	                   (TR-ccr-002 / TR-ccr-003 / TR-ccr-017) — populates _overlapPairs
	  Story 003 (CCR): F3 drip math + per-pair updateCount + equal-count mutual drain
	                   (TR-ccr-004 / TR-ccr-005 / TR-ccr-006 / TR-ccr-016 / TR-ccr-018)
	  Story 004 (CCR): Skip conditions — nil/Eliminated guard + GraceWindow drip suspend
	                   (TR-ccr-007 / TR-ccr-019)
	  Story 005 (CCR): Overlap-bit feed — setStillOverlapping post-drip, exactly one
	                   call per active crowd per tick (TR-ccr-008 / TR-ccr-016)
	  Story 006+ (CCR): peel dispatch (pairEntered diff), client replication

	Design doc: design/gdd/crowd-collision-resolution.md
	ADR governance: ADR-0002 (TickOrchestrator), ADR-0004 (CSM Authority),
	                ADR-0006 (Module Placement)

	Singleton module: module-level state only. No .new() constructor.
	Mirror style: ServerStorage/Source/AbsorbSystem/init.luau.

	Public surface:
	  CollisionResolver.init(deps)              — DI: csm (required), peelDispatcher (required),
	                                               clock (optional)
	  CollisionResolver.tickPhase1(tickCount, ctx) — Phase 1 callback; registered with
	                                               TickOrchestrator via _registerPhases
	  CollisionResolver.getState()              — returns "Dormant" | "Ticking"

	Control Manifest (Feature layer):
	  - FORBIDDEN: yield inside tickPhase1 (task.wait / task.defer / async) [ADR-0002]
	  - FORBIDDEN: own RunService.Heartbeat:Connect [ADR-0002]
	  - FORBIDDEN: require(CrowdStateServer) at module scope — DI only [ADR-0006]
	  - FORBIDDEN: mutate table returned by csm.getAllActive() [ADR-0004]
	  - FORBIDDEN: csm.updateCount / setStillOverlapping calls in this story [Story 003+]
	  - Phase 1 budget <= 0.6 ms/tick [ADR-0003]; skeleton << 0.05 ms (no pair work yet)

	Story 005 scope: overlap-bit feed now live as a separate post-drip pass.
	Stories 006+ extend with peel dispatch (pairEntered diff) and client replication.

	Control Manifest (Story 003 + Story 004 + Story 005):
	  - SOLE caller of csm.updateCount(crowdId, ±delta, "Collision") for the
	    "Collision" DeltaSource per ADR-0004 §Write-Access Matrix (4-caller rule).
	  - SOLE caller of csm.setStillOverlapping(crowdId, flag) per ADR-0004
	    §Write-Access Matrix. Exactly one call per active crowd per tick (last-
	    write-wins). Called AFTER drip completes (GDD §C Rule 6 ordering).
	  - F3 delta_per_tick clamped [DELTA_PER_TICK_MIN, DELTA_PER_TICK_MAX] = [1, 4]
	    via SharedConstants/CollisionResolverConstants. NEVER hardcoded magic numbers.
	  - Equal-count rule: count_delta=0 → BOTH crowds receive updateCount(-1, "Collision");
	    no `+` calls; mutual drain at floor delta. Never a single-side call.
	  - Drip restricted to pairs where BOTH re-fetched records are state="Active"
	    (TR-ccr-007). Eliminated / GraceWindow / nil records skip drip but remain
	    eligible for overlap-bit reporting (TR-ccr-019).
	  - Overlap-bit aggregation per side, not per pair:
	      nil-side          → does NOT contribute (record gone)
	      Eliminated side   → does NOT contribute
	      Active side       → contributes
	      GraceWindow side  → contributes (TR-ccr-019: GraceWindow overlap-bit
	                          drives CSM Phase 5 timer expiry)
	  - FORBIDDEN: any state-transition call from CCR — `transitionTo*` / `setState*`
	    are CSM-owned (ADR-0004 §Write-Access Matrix). CCR calls only `updateCount`
	    + `setStillOverlapping`.
	  - FORBIDDEN: side-side count clamp (e.g., `if count > 1 then ...`) — CSM F5
	    owns the clamp at floor 1; CollisionResolver passes the unclamped delta.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollisionResolverConstants = require(
	ReplicatedStorage.Source.SharedConstants.CollisionResolverConstants
)

-- ---------------------------------------------------------------------------
-- Exported types
-- ---------------------------------------------------------------------------

--- One overlapping crowd pair entry produced by the Phase 1 pair-iteration loop
--- and consumed by the F3 drip pass (Story 003) plus subsequent stories
--- (overlap-bit feed / pairEntered diff / peel dispatch).
---
--- a, b are CrowdRecord references kept as `any` until CrowdRecord is
--- importable across modules. By construction (lex pre-sort + i<j loop),
--- `a.crowdId < b.crowdId` always holds.
export type CollisionPair = {
	a: any,
	b: any,
	pairKey: string,
	distSq: number,
}

-- ---------------------------------------------------------------------------
-- Module-level DI state (set by init(), consumed by tickPhase1())
-- ---------------------------------------------------------------------------

--- CrowdStateServer — provides getAllActive().
--- Type: any (DI surface; production = real CSM; tests = mock).
--- NEVER required at module scope — injected via init(deps) only.
local _csm: any = nil

--- PeelDispatcher — receives peel events from the collision resolver (Story 008+).
--- Type: any (DI surface; production = real PeelDispatcher; tests = mock).
local _peelDispatcher: any = nil

--- Optional injected clock function () -> number. Default: os.clock.
--- Tests inject a controllable clock for deterministic time assertions.
local _clock: (() -> number)? = nil

--- Guard: true after init() completes. Prevents tickPhase1 from running without DI.
local _initialized: boolean = false

--- State: "Dormant" when no active crowds; "Ticking" when crowds are present.
--- Starts Dormant. Transitions on getAllActive() result each tick.
local _state: "Dormant" | "Ticking" = "Dormant"

--- Internal scratch table — cleared at top of each tickPhase1 call.
--- Story 002 populates with overlapping pairs; Story 003 drip pass consumes
--- structured fields (entry.a, entry.b, entry.a.count, etc.). Story 006+ will
--- extend with pairEntered diff.
--- Never exposed outside the module; never references csm.getAllActive() result directly.
local _overlapPairs: { CollisionPair } = {}

--- Internal scratch set — cleared at top of each tickPhase1 call.
--- Story 005 populates during the drip+aggregation pass: per-side eligibility
--- decided during _overlapPairs iteration (nil/Eliminated do not contribute;
--- Active/GraceWindow do). The post-drip overlap-bit feed reads this set.
--- Never exposed outside the module.
local _overlapCrowds: { [string]: boolean } = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Returns current clock value (seconds). Uses DI override when set.
local function getClock(): number
	if _clock ~= nil then
		return (_clock :: () -> number)()
	end
	return os.clock()
end

--- F2 — pair_key canonical lex form. Returns "lower|higher" so the key is
--- order-independent: pairKey(a, b) == pairKey(b, a). String comparison is
--- lex-byte (Luau strings) — sufficient because crowdId values are stable
--- engine-assigned strings.
--- TR-ccr-017. Used by Story 006 pairEntered diff.
local function pairKey(a: string, b: string): string
	if a < b then
		return a .. "|" .. b
	else
		return b .. "|" .. a
	end
end

--- F1 — pair_overlap_test. 2D squared-distance against precomputed
--- combined_radius_sq. Y axis ignored per GDD §F1.
--- NEVER call math.sqrt — squared form keeps Phase 1 hot path branchless.
--- TR-ccr-003.
local function isOverlapSq(ax: number, az: number, bx: number, bz: number, combinedSq: number): boolean
	local dx = ax - bx
	local dz = az - bz
	return (dx * dx + dz * dz) <= combinedSq
end

--- Module-level comparator hoisted out of `table.sort` call site to guarantee
--- zero per-tick closure allocation on the Phase 1 hot path (Luau VM may or
--- may not constant-fold non-capturing inline closures depending on version).
local function crowdIdComparator(a: any, b: any): boolean
	return a.crowdId < b.crowdId
end

--- F3 — delta_per_tick computation (TR-ccr-006).
--- Returns the integer follower count to transfer per pair per tick.
---
---   cd        = abs(countA - countB)
---   effective = min(TRANSFER_RATE_BASE + cd * TRANSFER_RATE_SCALE, TRANSFER_RATE_MAX)
---   delta     = clamp(ceil(effective / SERVER_TICK_HZ), DELTA_PER_TICK_MIN, DELTA_PER_TICK_MAX)
---
--- The clamp guarantees `delta ∈ [1, 4]` regardless of input. The `+` direction
--- (attacker vs defender) is decided by the caller; this function returns the
--- absolute magnitude only.
local function computeDeltaPerTick(countA: number, countB: number): number
	local cd = math.abs(countA - countB)
	local effective = math.min(
		CollisionResolverConstants.TRANSFER_RATE_BASE
			+ cd * CollisionResolverConstants.TRANSFER_RATE_SCALE,
		CollisionResolverConstants.TRANSFER_RATE_MAX
	)
	return math.clamp(
		math.ceil(effective / CollisionResolverConstants.SERVER_TICK_HZ),
		CollisionResolverConstants.DELTA_PER_TICK_MIN,
		CollisionResolverConstants.DELTA_PER_TICK_MAX
	)
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local CollisionResolver = {}

--- Initialises CollisionResolver with injected dependencies. Call ONCE at server boot,
--- before TickOrchestrator.start(). Required deps: csm, peelDispatcher. Optional: clock.
---
--- Asserts at init time (not at tick time) if any required dep is nil.
--- Re-init with same deps is idempotent (module fields overwritten with equal values).
---
--- ADR-0002 §Phase Registration: tickPhase1 is registered at boot wiring in
--- start.server.luau AFTER this init() call completes.
---
--- deps fields:
---   csm            (CrowdStateServer) — required
---   peelDispatcher (PeelDispatcher)   — required; Story 008 wires real module
---   clock          (() -> number)?    — optional injectable clock for tests
function CollisionResolver.init(deps: {
	csm: any,
	peelDispatcher: any,
	clock: (() -> number)?,
}): ()
	assert(deps ~= nil, "CollisionResolver.init: deps must be a table")
	assert(deps.csm ~= nil, "CollisionResolver.init: deps.csm is required (CrowdStateServer)")
	assert(deps.peelDispatcher ~= nil, "CollisionResolver.init: deps.peelDispatcher is required (PeelDispatcher)")

	_csm = deps.csm
	_peelDispatcher = deps.peelDispatcher
	_clock = deps.clock  -- nil is valid; falls back to os.clock

	_initialized = true
end

--- Phase 1 tick callback. Registered with TickOrchestrator via _registerPhases.
--- Must NOT yield. Must NOT own a RunService.Heartbeat (ADR-0002).
---
--- Body:
---   1. Assert _initialized == true (guard against missing init call).
---   2. table.clear(_overlapPairs) — internal scratch reset for this tick.
---   3. Read csm.getAllActive() ONCE — sole CSM read in Phase 1.
---   4. If no active crowds → state = "Dormant"; early return.
---   5. Else state = "Ticking"; pre-sort `active` by crowdId; iterate unique unordered
---      pairs (i<j) running F1 overlap test (squared-distance, Y ignored). Accumulate
---      every overlapping pair into _overlapPairs as { a, b, pairKey, distSq }.
---   6. Story 003 + Story 004 + Story 005: drip + overlap-bit pass —
---      for each entry in _overlapPairs:
---      a. Re-fetch records via csm.get(crowdId). Per-side eligibility for
---         overlap-bit contribution (Story 005): nil → no contribution;
---         Eliminated → no contribution; Active or GraceWindow → contributes
---         (TR-ccr-019). Aggregated into _overlapCrowds set.
---      b. Drip eligibility (Story 004 TR-ccr-007): only when BOTH sides are
---         non-nil and state="Active". Otherwise skip drip; overlap-bit
---         contribution from step (a) is independent of drip-skip.
---      c. Active+Active drip: compute F3 delta_per_tick from counts and call
---         csm.updateCount(±delta, "Collision") per attacker/defender/equal rule.
---   7. Story 005: overlap-bit feed — iterate `active` once and call
---      csm.setStillOverlapping(crowd.crowdId, _overlapCrowds[crowd.crowdId] == true)
---      for every active crowd. Exactly one call per crowd per tick. Called
---      AFTER drip per GDD §C Rule 6 ordering (drip results in count mutations
---      that must NOT be observed by overlap-bit aggregation — but the aggregation
---      is decided by the pair geometry from Story 002, not by post-drip counts,
---      so the order is informational rather than load-bearing here).
---
--- No peel dispatch / FireClient calls in this story (Story 008+).
---
--- @param tickCount number — monotone tick counter from TickOrchestrator.
--- @param _ctx any — TickContext (unused; required by phase signature).
function CollisionResolver.tickPhase1(tickCount: number, _ctx: any): ()
	-- Suppress lint: tickCount and clock accessible for future instrumentation.
	local _ = tickCount
	local __ = getClock()

	-- Guard: init() must have been called (DI established).
	assert(_initialized, "CollisionResolver.tickPhase1: called before init() — call CollisionResolver.init(deps) at boot")

	-- Reset internal scratch tables each tick.
	-- Story 002 populates _overlapPairs with overlapping (a, b) candidate pairs.
	-- Story 005 populates _overlapCrowds during the drip+aggregation pass below.
	table.clear(_overlapPairs)
	table.clear(_overlapCrowds)

	-- Read active crowds — SOLE CSM call in Phase 1.
	-- ADR-0004 read-only contract: we NEVER mutate the returned table or its records.
	-- The returned array is a fresh table per call (CSM doc-comment line 367-368), so
	-- sorting it locally is safe — does not mutate CSM's internal _crowds dict.
	local active = _csm.getAllActive()

	-- Dormant gate: no active crowds → transition to Dormant and exit.
	if active == nil or #active == 0 then
		_state = "Dormant"
		return
	end

	-- Transition to Ticking: at least one active crowd exists.
	_state = "Ticking"

	-- Pre-sort `active` by crowdId for deterministic pair iteration order across
	-- ticks regardless of CSM's arbitrary `pairs()` traversal order (AC-03).
	-- Comparator is module-level (zero per-tick closure allocation).
	table.sort(active, crowdIdComparator)

	-- O(p²) unique unordered pair iteration. With 12 crowds = 66 pairs/tick @ 15 Hz
	-- (well under Phase 1 0.6 ms budget per ADR-0003).
	-- TR-ccr-002 (lex-sorted unique pairs) + TR-ccr-003 (F1 overlap test).
	-- Stories 003+ consume _overlapPairs (drip math / overlap-bit feed / pairEntered diff).
	for i = 1, #active do
		local a = active[i]
		for j = i + 1, #active do
			local b = active[j]
			-- F1 — squared-distance overlap (Y ignored, no math.sqrt).
			-- combined_radius_sq = (radiusA + radiusB)² ∈ [37.22, 578.88] per GDD §F1.
			local combined = a.radius + b.radius
			local combinedSq = combined * combined
			local dx = a.position.X - b.position.X
			local dz = a.position.Z - b.position.Z
			local distSq = dx * dx + dz * dz
			if distSq <= combinedSq then
				-- AC-15: stacked position → distSq=0 → overlap=true; no divide-by-zero.
				-- Use the pairKey() helper rather than inline concat — pre-sort makes
				-- the inline form correct today, but the helper is the canonical form
				-- that future loop-body changes (Story 003+) cannot accidentally break.
				table.insert(_overlapPairs, {
					a = a,
					b = b,
					pairKey = pairKey(a.crowdId, b.crowdId),
					distSq = distSq,
				})
			end
		end
	end

	-- Story 003 + Story 004 + Story 005 — F3 drip + overlap-bit aggregation pass.
	-- Iterates _overlapPairs in pair-iteration order (alphabetic by canonical
	-- pairKey from the lex-sorted active array, so the updateCount call sequence
	-- is deterministic for snapshot-based tests).
	--
	-- Per-side overlap-bit eligibility (Story 005 — TR-ccr-008 / TR-ccr-019):
	--   nil-side          → does NOT contribute (record gone)
	--   Eliminated side   → does NOT contribute
	--   Active side       → contributes (sets _overlapCrowds[crowdId] = true)
	--   GraceWindow side  → contributes (drives CSM Phase 5 timer expiry next tick)
	--
	-- Drip eligibility (Story 004 — TR-ccr-007): only when BOTH sides are
	-- non-nil and state="Active". Otherwise skip drip; overlap-bit contribution
	-- from the per-side pass above is INDEPENDENT of drip-skip.
	--
	-- Per-pair drip (TR-ccr-004 + TR-ccr-005, Active+Active only):
	--   countA > countB:  csm.updateCount(a, +delta, "Collision");
	--                     csm.updateCount(b, -delta, "Collision")
	--   countA < countB:  reversed
	--   countA == countB: BOTH csm.updateCount(_, -1, "Collision") (mutual drain)
	--
	-- Triple-overlap stacks naturally (TR-ccr-018): each unordered pair processes
	-- independently — no special triple logic. CSM F5 owns the count clamp at
	-- floor 1 (ADR-0004); CollisionResolver passes the unclamped delta.
	for _, entry in ipairs(_overlapPairs) do
		-- Re-fetch records via csm.get for defensive nil-guard. Within a single
		-- synchronous Phase 1 callback no yield can happen, but the explicit
		-- re-fetch (i) matches the GDD §C Rule 4 prose and (ii) makes the
		-- nil-skip path testable via a CSM mock that returns nil for specific
		-- crowdIds.
		local recA = _csm.get(entry.a.crowdId)
		local recB = _csm.get(entry.b.crowdId)

		-- Per-side overlap-bit aggregation (Story 005). nil → no contribution;
		-- Eliminated → no contribution; Active or GraceWindow → contribute.
		if recA ~= nil and recA.state ~= "Eliminated" then
			_overlapCrowds[recA.crowdId] = true
		end
		if recB ~= nil and recB.state ~= "Eliminated" then
			_overlapCrowds[recB.crowdId] = true
		end

		-- Drip eligibility (Story 004). Either nil → skip drip entirely.
		if recA == nil or recB == nil then
			continue
		end

		-- State filter: drip only when BOTH crowds are Active.
		-- GraceWindow / Eliminated → skip drip; pair entry remains in
		-- _overlapPairs and the per-side aggregation above already applied.
		--
		-- POSITIVE-LIST CHECK BY DESIGN: any state other than "Active" skips drip.
		-- If a future state is added to the CrowdRecord union (e.g. Story 010+
		-- adds "Stunned" / "Invincible"), this line is the explicit forcing
		-- function that drip-eligibility must be opted-into per state. Negative-
		-- list checks (skip GraceWindow + Eliminated only) would silently grant
		-- drip to unrecognised future states — which is the wrong default for a
		-- state machine that drives gameplay-critical mutations.
		if recA.state ~= "Active" or recB.state ~= "Active" then
			continue
		end

		if recA.count == recB.count then
			-- Equal-count mutual drain: both lose delta=1 (TR-ccr-005).
			-- delta is fixed at DELTA_PER_TICK_MIN regardless of computeDeltaPerTick
			-- output — equal counts always drain at the floor by GDD definition.
			_csm.updateCount(recA.crowdId, -CollisionResolverConstants.DELTA_PER_TICK_MIN, "Collision")
			_csm.updateCount(recB.crowdId, -CollisionResolverConstants.DELTA_PER_TICK_MIN, "Collision")
		else
			local delta = computeDeltaPerTick(recA.count, recB.count)
			if recA.count > recB.count then
				_csm.updateCount(recA.crowdId, delta, "Collision")
				_csm.updateCount(recB.crowdId, -delta, "Collision")
			else
				_csm.updateCount(recB.crowdId, delta, "Collision")
				_csm.updateCount(recA.crowdId, -delta, "Collision")
			end
		end
	end

	-- Story 005 — overlap-bit feed (TR-ccr-008 / TR-ccr-016).
	-- Iterate ALL active crowds (cached `active` array, lex-sorted from Story 002
	-- pre-sort) and emit exactly ONE setStillOverlapping call per crowd. Crowds
	-- absent from any overlapping pair receive `false` (CSM consumer reads this
	-- as the "no overlap this tick" signal that exits GraceWindow per CSM §F7).
	--
	-- Order: this loop runs AFTER all drip calls per GDD §C Rule 6. The
	-- setStillOverlapping fan-out is sole-caller per ADR-0004 §Write-Access
	-- Matrix; no cosmetic / read-only consumer may invoke it.
	for _, crowd in ipairs(active) do
		_csm.setStillOverlapping(crowd.crowdId, _overlapCrowds[crowd.crowdId] == true)
	end
end

--- Returns the current resolver state.
--- "Dormant" — no active crowds; Phase 1 early-returns without work.
--- "Ticking"  — at least one active crowd; Phase 1 runs pair-check logic (Story 002+).
function CollisionResolver.getState(): "Dormant" | "Ticking"
	return _state
end

-- ---------------------------------------------------------------------------
-- Test-only surface
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Resets all module-level DI state for TestEZ isolation.
--- Allows re-initialisation in the same Luau session (required by beforeEach/afterEach).
function CollisionResolver._resetForTests(): ()
	_csm = nil
	_peelDispatcher = nil
	_clock = nil
	_initialized = false
	_state = "Dormant"
	table.clear(_overlapPairs)
	table.clear(_overlapCrowds)
end

--- **TEST ONLY** — never call from production code.
--- Returns whether init() has completed. Tests use this to verify DI assertion timing.
function CollisionResolver._isInitialized(): boolean
	return _initialized
end

--- **TEST ONLY** — never call from production code.
--- Returns the count of overlap pairs accumulated during the most recent tick.
--- Story 002 added this so tests can verify pair iteration without exposing the
--- mutable scratch table.
function CollisionResolver._getOverlapPairsLength(): number
	return #_overlapPairs
end

--- **TEST ONLY** — never call from production code.
--- Returns a snapshot copy of _overlapPairs for inspection. Returns a fresh array
--- each call so callers cannot accidentally hold a stale reference into the live
--- scratch buffer.
function CollisionResolver._snapshotOverlapPairs(): { CollisionPair }
	return table.clone(_overlapPairs)
end

--- **TEST ONLY** — exposes pairKey internal helper for AC-05 verification.
function CollisionResolver._pairKey(a: string, b: string): string
	return pairKey(a, b)
end

--- **TEST ONLY** — exposes isOverlapSq internal helper for AC-04 verification.
function CollisionResolver._isOverlapSq(ax: number, az: number, bx: number, bz: number, combinedSq: number): boolean
	return isOverlapSq(ax, az, bx, bz, combinedSq)
end

--- **TEST ONLY** — exposes computeDeltaPerTick internal helper for F3 verification.
--- Used by AC-07/F3-clamp tests to validate the formula independently of the
--- pair-iteration loop body.
function CollisionResolver._computeDeltaPerTick(countA: number, countB: number): number
	return computeDeltaPerTick(countA, countB)
end

--- **TEST ONLY** — exposes the per-tick overlap-bit aggregation snapshot.
--- Story 005 tests inspect which crowds were marked overlapping during the
--- most recent tickPhase1 invocation. Returns a fresh shallow copy.
function CollisionResolver._snapshotOverlapCrowds(): { [string]: boolean }
	return table.clone(_overlapCrowds)
end

return CollisionResolver
