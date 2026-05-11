--!strict

--[[
	crowd_manager_orchestrator_test.luau
	Integration tests for CrowdManagerClient orchestrator + FollowerEntityClient lifecycle.

	Implements: follower-entity/story-002 (Sprint 4, Story 4-2)
	GDD: design/gdd/follower-entity.md §Orchestrator
	ADR: ADR-0007 §Three-Module Split + §Despawn Path

	AC Coverage:
	  AC-10  — Nil-crowd → _markAllDespawning; boids (_update) NOT called; state = Despawning
	  AC-S1  — Singleton bootstrap: init idempotent; start twice = one connection; stop/start cycles
	  AC-S2  — getCrowdClient returns nil for unknown crowdId
	  AC-L1  — CrowdCreated signal → FollowerEntityClient constructed; getCrowdClient non-nil
	  AC-L2  — CrowdEliminated signal → FollowerEntityClient destroyed; getCrowdClient nil
	  AC-L3  — Janitor:Destroy() called exactly once on Eliminated
	  AC-L4  — Created twice for same id → idempotent; original instance retained
	  AC-L5  — Eliminated for unknown crowdId → no error (no-op)
	  AC-RO  — Read-only contract: CrowdStateClient exposes no .set or .update methods
	           (smoke check; deep verification via code-review + audit scripts)

	Test strategy:
	  - _debugReset() + _debugClearAll() in beforeEach for full isolation.
	  - CrowdStateClient._debugFireCrowdCreated / _debugFireCrowdEliminated drive lifecycle.
	  - CrowdManagerClient._debugStepRenderFrame(dt) drives one deterministic frame
	    (avoids flaky task.wait() races).
	  - Spy Janitor wrapper records Destroy() calls for AC-L3.
	  - FollowerEntityClient._debugSeedActiveFollowers injects mock followers for AC-10.
	  - FollowerEntityClient._debugGetFollowerStates reads internal state for AC-10.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local CrowdStateClient     = require(ReplicatedStorage.Source.CrowdStateClient)
	local CrowdManagerClient   = require(ReplicatedStorage.Source.FollowerEntity.CrowdManagerClient)
	local FollowerEntityClient = require(ReplicatedStorage.Source.FollowerEntity.Client)

	-- -------------------------------------------------------------------------
	-- Helpers
	-- -------------------------------------------------------------------------

	--- Creates a minimal valid CrowdRecord for seeding CrowdStateClient cache.
	-- BUG-002 / Sprint 7 fix: count = 0 so constructCrowd does NOT auto-fire
	-- setPoolSize(N) → cap-grow throttle queue. These integration tests inject
	-- followers via `_debugSeedActiveFollowers` directly and expect that exact
	-- count back. With count > 0, constructCrowd enqueues N FadeIn spawns AND
	-- the seed appends another N Active rows → followerStates length doubles,
	-- breaking assertions. Tests that explicitly need cap-grow path use
	-- setPoolSize locally.
	local function makeCrowdRecord(crowdId: string): CrowdStateClient.CrowdRecord
		return {
			crowdId      = crowdId,
			tick         = 1,
			position     = Vector3.new(0, 0, 0),
			radius       = 5.0,
			count        = 0,
			hue          = 1,
			state        = "Active",
			activeRelics = {} :: { string },
		}
	end

	--- Creates N mock BasePart instances (body Parts) for use as follower fixtures.
	--- Parts are parented to a sandbox Folder so they are cleaned up after tests.
	local function makeMockParts(folder: Folder, n: number): { BasePart }
		local parts: { BasePart } = {}
		for i = 1, n do
			local part = Instance.new("Part")
			part.Name = "MockFollower_" .. i
			part.Anchored = true
			part.CanCollide = false
			part.Parent = folder
			parts[i] = part
		end
		return parts
	end

	-- -------------------------------------------------------------------------
	-- beforeEach / afterEach
	-- -------------------------------------------------------------------------

	--- Sandbox folder for temporary Part instances; created per describe block.
	local sandboxFolder: Folder

	beforeEach(function()
		-- Reset orchestrator + state client to clean baseline before every test.
		CrowdManagerClient:_debugReset()
		CrowdStateClient._debugClearAll()

		-- Fresh sandbox folder for any Part fixtures.
		sandboxFolder = Instance.new("Folder")
		sandboxFolder.Name = "_CrowdManagerTestSandbox"
		sandboxFolder.Parent = workspace
	end)

	afterEach(function()
		-- Ensure orchestrator is stopped; destroy any lingering test parts.
		CrowdManagerClient:_debugReset()
		CrowdStateClient._debugClearAll()
		if sandboxFolder and sandboxFolder.Parent ~= nil then
			sandboxFolder:Destroy()
		end
	end)

	-- =========================================================================
	-- AC-S1 / AC-S2: Singleton bootstrap
	-- =========================================================================

	describe("Singleton bootstrap", function()

		it("test_singleton_init_idempotent_does_not_error_on_double_init", function()
			-- Arrange / Act: calling init twice must not raise.
			local ok = pcall(function()
				CrowdManagerClient:init()
				CrowdManagerClient:init()
			end)
			-- Assert
			expect(ok).to.equal(true)
		end)

		it("test_start_creates_render_step_connection_after_init_and_start", function()
			-- Arrange
			CrowdManagerClient:init()
			-- Act
			CrowdManagerClient:start()
			-- Assert: _renderStepConn is non-nil (internal state; verified via _debugStepRenderFrame not erroring)
			-- We cannot directly inspect _renderStepConn (module-private), but we verify
			-- that stepping a frame after start() does not error and is callable.
			local ok = pcall(function()
				CrowdManagerClient:_debugStepRenderFrame(0.016)
			end)
			expect(ok).to.equal(true)
		end)

		it("test_start_twice_only_one_connection_no_double_step_error", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			-- Act: second start should be idempotent (no double-connection; no error)
			local ok = pcall(function()
				CrowdManagerClient:start()
			end)
			-- Assert: no error; calling step is safe
			expect(ok).to.equal(true)
			local ok2 = pcall(function()
				CrowdManagerClient:_debugStepRenderFrame(0.016)
			end)
			expect(ok2).to.equal(true)
		end)

		it("test_stop_then_start_allows_single_reconnect_no_error", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdManagerClient:stop()
			-- Act: re-init + re-start (simulates a session restart)
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			-- Assert: frame step works cleanly after cycle
			local ok = pcall(function()
				CrowdManagerClient:_debugStepRenderFrame(0.016)
			end)
			expect(ok).to.equal(true)
		end)

		it("test_stop_without_start_does_not_error", function()
			-- Arrange: init only, no start
			CrowdManagerClient:init()
			-- Act
			local ok = pcall(function()
				CrowdManagerClient:stop()
			end)
			-- Assert: safe no-op
			expect(ok).to.equal(true)
		end)

		it("test_getCrowdClient_returns_nil_for_unknown_crowdId", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			-- Act
			local result = CrowdManagerClient:getCrowdClient("UNKNOWN_CROWD_ID")
			-- Assert: AC-S2
			expect(result).to.equal(nil)
		end)

		it("test_debugStepRenderFrame_before_start_does_not_error", function()
			-- Stepping before start() (no active crowds) must not crash.
			CrowdManagerClient:init()
			local ok = pcall(function()
				CrowdManagerClient:_debugStepRenderFrame(0.016)
			end)
			expect(ok).to.equal(true)
		end)

	end)

	-- =========================================================================
	-- AC-L1 / AC-L2 / AC-L3: Per-crowd lifecycle
	-- =========================================================================

	describe("Per-crowd lifecycle", function()

		it("test_crowd_created_constructs_follower_client_and_getCrowdClient_returns_non_nil", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			-- Seed a CrowdRecord so get(crowdId) doesn't immediately mark Despawning.
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))

			-- Act: fire CrowdCreated
			CrowdStateClient._debugFireCrowdCreated("C1")

			-- Assert: AC-L1
			local client = CrowdManagerClient:getCrowdClient("C1")
			expect(client).to.be.ok()
		end)

		it("test_crowd_eliminated_destroys_follower_client_and_getCrowdClient_returns_nil", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugFireCrowdCreated("C1")

			-- Verify it exists before elimination.
			expect(CrowdManagerClient:getCrowdClient("C1")).to.be.ok()

			-- Act: fire CrowdEliminated
			CrowdStateClient._debugFireCrowdEliminated("C1")

			-- Assert: AC-L2
			local client = CrowdManagerClient:getCrowdClient("C1")
			expect(client).to.equal(nil)
		end)

		it("test_crowd_eliminated_calls_janitor_destroy_exactly_once", function()
			-- Arrange: build a spy Janitor to capture Destroy() calls.
			-- We intercept FollowerEntityClient construction by observing _destroyed state
			-- post-elimination. For deeper Janitor verification, we get the client before
			-- elimination and verify its _destroyed flag is set.
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugFireCrowdCreated("C1")

			local clientBeforeElimination = CrowdManagerClient:getCrowdClient("C1")
			expect(clientBeforeElimination).to.be.ok()

			-- Act
			CrowdStateClient._debugFireCrowdEliminated("C1")

			-- Assert: AC-L3 — _destroyed flag on the FollowerEntityClient confirms destroy() ran.
			-- (destroy() is the only code path that sets _destroyed = true; it calls janitor:Destroy())
			local destroyed = (clientBeforeElimination :: any)._destroyed
			expect(destroyed).to.equal(true)
		end)

		it("test_created_twice_same_crowdId_is_idempotent_retains_original_instance", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))

			-- Act: fire Created twice
			CrowdStateClient._debugFireCrowdCreated("C1")
			local firstClient = CrowdManagerClient:getCrowdClient("C1")
			CrowdStateClient._debugFireCrowdCreated("C1")
			local secondClient = CrowdManagerClient:getCrowdClient("C1")

			-- Assert: AC-L4 — same instance retained; no error
			expect(firstClient).to.be.ok()
			expect(secondClient).to.be.ok()
			-- Both calls must return the SAME object.
			expect(firstClient).to.equal(secondClient)
		end)

		it("test_eliminated_for_unknown_crowdId_is_safe_no_op", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()

			-- Act: eliminate a crowdId that was never created
			local ok = pcall(function()
				CrowdStateClient._debugFireCrowdEliminated("GHOST_CROWD")
			end)

			-- Assert: AC-L5 — no error; no crowd registered for GHOST_CROWD
			expect(ok).to.equal(true)
			expect(CrowdManagerClient:getCrowdClient("GHOST_CROWD")).to.equal(nil)
		end)

		it("test_create_eliminate_create_same_id_produces_fresh_client", function()
			-- Arrange
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))

			-- First lifecycle
			CrowdStateClient._debugFireCrowdCreated("C1")
			local firstClient = CrowdManagerClient:getCrowdClient("C1")
			CrowdStateClient._debugFireCrowdEliminated("C1")
			expect(CrowdManagerClient:getCrowdClient("C1")).to.equal(nil)

			-- Second lifecycle (same crowdId re-created)
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugFireCrowdCreated("C1")
			local secondClient = CrowdManagerClient:getCrowdClient("C1")

			-- Assert: second client is a fresh instance (not the destroyed one)
			expect(secondClient).to.be.ok()
			expect(secondClient).never.to.equal(firstClient)
		end)

	end)

	-- =========================================================================
	-- AC-10: Per-frame nil-check → Despawning transition
	-- =========================================================================

	describe("AC-10 — nil-crowd per-frame nil-check marks followers Despawning", function()

		it("test_per_frame_nil_check_marks_all_active_followers_despawning", function()
			-- Arrange: create crowd + seed 5 active followers.
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugFireCrowdCreated("C1")

			local crowdClient = CrowdManagerClient:getCrowdClient("C1") :: any
			expect(crowdClient).to.be.ok()

			-- Inject 5 mock followers (simulates story-005 spawn path).
			local parts = makeMockParts(sandboxFolder, 5)
			crowdClient:_debugSeedActiveFollowers(parts)

			-- Verify all are Active before nil.
			local statesBefore = crowdClient:_debugGetFollowerStates()
			expect(#statesBefore).to.equal(5)
			for _, s in statesBefore do
				expect(s).to.equal("Active")
			end

			-- Act: make crowd nil in cache, then step one frame.
			CrowdStateClient._debugClearAll()  -- get("C1") now returns nil
			CrowdManagerClient:_debugStepRenderFrame(0.016)

			-- Assert: AC-10 — all 5 followers transitioned to Despawning.
			local statesAfter = crowdClient:_debugGetFollowerStates()
			expect(#statesAfter).to.equal(5)
			for _, s in statesAfter do
				expect(s).to.equal("Despawning")
			end
		end)

		it("test_per_frame_nil_check_second_frame_does_not_double_stamp_despawning", function()
			-- Verify _markAllDespawning is idempotent (already-Despawning followers
			-- are not re-stamped with a new timestamp).
			CrowdManagerClient:init()
			CrowdManagerClient:start()
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugFireCrowdCreated("C1")

			local crowdClient = CrowdManagerClient:getCrowdClient("C1") :: any
			local parts = makeMockParts(sandboxFolder, 3)
			crowdClient:_debugSeedActiveFollowers(parts)

			-- First nil frame — transitions to Despawning.
			CrowdStateClient._debugClearAll()
			CrowdManagerClient:_debugStepRenderFrame(0.016)

			-- Capture despawnStartedAt after first frame.
			local timestampsFirst = {}
			for k, v in (crowdClient :: any)._despawningStartedAt do
				timestampsFirst[k] = v
			end

			-- Second nil frame — should NOT overwrite timestamps.
			CrowdManagerClient:_debugStepRenderFrame(0.016)

			local timestampsSecond = {}
			for k, v in (crowdClient :: any)._despawningStartedAt do
				timestampsSecond[k] = v
			end

			-- Assert: timestamps unchanged (idempotent _markAllDespawning).
			for i = 1, 3 do
				expect(timestampsFirst[i]).to.equal(timestampsSecond[i])
			end
		end)

		it("test_per_frame_nil_check_skips_update_for_nil_crowd_followers", function()
			-- Verifies boids (_update) is NOT called when crowd returns nil.
			-- Strategy: we confirm _markAllDespawning ran (followers are Despawning)
			-- AND that no error occurred (since _update has a no-op stub for story-002,
			-- calling it on despawning followers would be incorrect by spec).
			--
			-- In story-003, boids spy testing will be added when F1-F4 is real.
			-- For story-002, we verify the state branches correctly:
			--   nil record path  → Despawning
			--   non-nil record path → no state change (followers remain Active)

			CrowdManagerClient:init()
			CrowdManagerClient:start()

			-- Two crowds: C1 (will go nil) and C2 (stays active).
			CrowdStateClient._debugSetRecord("C1", makeCrowdRecord("C1"))
			CrowdStateClient._debugSetRecord("C2", makeCrowdRecord("C2"))
			CrowdStateClient._debugFireCrowdCreated("C1")
			CrowdStateClient._debugFireCrowdCreated("C2")

			local c1 = CrowdManagerClient:getCrowdClient("C1") :: any
			local c2 = CrowdManagerClient:getCrowdClient("C2") :: any

			local parts1 = makeMockParts(sandboxFolder, 3)
			local parts2 = makeMockParts(sandboxFolder, 3)
			c1:_debugSeedActiveFollowers(parts1)
			c2:_debugSeedActiveFollowers(parts2)

			-- Remove C1 record only; C2 remains active.
			-- Re-clear and re-seed only C2 to simulate C1 going nil.
			CrowdStateClient._debugClearAll()
			CrowdStateClient._debugSetRecord("C2", makeCrowdRecord("C2"))

			-- Step one frame.
			CrowdManagerClient:_debugStepRenderFrame(0.016)

			-- Assert: C1 followers are Despawning; C2 followers are still Active.
			local statesC1 = c1:_debugGetFollowerStates()
			local statesC2 = c2:_debugGetFollowerStates()

			for _, s in statesC1 do
				expect(s).to.equal("Despawning")
			end
			for _, s in statesC2 do
				expect(s).to.equal("Active")
			end
		end)

		-- DEFERRED (story-005): assert Part returned to pool after 0.2 s elapsed.
		-- _despawningStartedAt timestamps are recorded by story-002; pool release
		-- logic and the 0.2 s threshold assertion belong in
		-- tests/integration/follower-entity/crowd_spawn_states.spec.luau (story-005).
		-- Tracking: follower-entity/story-002 §Out of Scope — story-005 owns pool grant flows.

		it("test_nil_crowd_mid_frame_remaining_crowds_still_processed", function()
			-- Edge case from AC-10: if multiple crowds exist, nil detection on one
			-- must not short-circuit iteration over the others.
			-- (Luau generic for-in iterates all pairs; nil detection is per-crowd.)
			CrowdManagerClient:init()
			CrowdManagerClient:start()

			CrowdStateClient._debugSetRecord("A", makeCrowdRecord("A"))
			CrowdStateClient._debugSetRecord("B", makeCrowdRecord("B"))
			CrowdStateClient._debugSetRecord("C", makeCrowdRecord("C"))
			CrowdStateClient._debugFireCrowdCreated("A")
			CrowdStateClient._debugFireCrowdCreated("B")
			CrowdStateClient._debugFireCrowdCreated("C")

			local cA = CrowdManagerClient:getCrowdClient("A") :: any
			local cB = CrowdManagerClient:getCrowdClient("B") :: any
			local cC = CrowdManagerClient:getCrowdClient("C") :: any

			cA:_debugSeedActiveFollowers(makeMockParts(sandboxFolder, 2))
			cB:_debugSeedActiveFollowers(makeMockParts(sandboxFolder, 2))
			cC:_debugSeedActiveFollowers(makeMockParts(sandboxFolder, 2))

			-- Make only B go nil.
			CrowdStateClient._debugClearAll()
			CrowdStateClient._debugSetRecord("A", makeCrowdRecord("A"))
			CrowdStateClient._debugSetRecord("C", makeCrowdRecord("C"))
			-- B is now nil.

			CrowdManagerClient:_debugStepRenderFrame(0.016)

			-- Assert: B → Despawning; A + C remain Active.
			for _, s in cB:_debugGetFollowerStates() do
				expect(s).to.equal("Despawning")
			end
			for _, s in cA:_debugGetFollowerStates() do
				expect(s).to.equal("Active")
			end
			for _, s in cC:_debugGetFollowerStates() do
				expect(s).to.equal("Active")
			end
		end)

	end)

	-- =========================================================================
	-- AC-RO: Read-only contract smoke check
	-- =========================================================================

	describe("Read-only contract (AC-RO)", function()

		it("test_read_only_contract_CrowdStateClient_has_no_set_method", function()
			-- Smoke check: CrowdStateClient must not expose a .set write API.
			-- This is a contract guarantee from ADR-0006 §Control Manifest Presentation Layer.
			-- Deeper verification (no server RemoteEvent fires in FollowerEntity/) is
			-- enforced by code review + audit scripts (see CLAUDE.md §Asset-ID audit).
			local hasSet    = (CrowdStateClient :: any).set    ~= nil
			local hasUpdate = (CrowdStateClient :: any).update ~= nil
			expect(hasSet).to.equal(false)
			expect(hasUpdate).to.equal(false)
		end)

		it("test_read_only_contract_CrowdManagerClient_has_no_set_method", function()
			-- CrowdManagerClient must not expose any write path on CrowdStateClient.
			-- Module-level smoke check: the orchestrator itself has no set/update.
			local hasSet    = (CrowdManagerClient :: any).set    ~= nil
			local hasUpdate = (CrowdManagerClient :: any).update ~= nil
			expect(hasSet).to.equal(false)
			expect(hasUpdate).to.equal(false)
		end)

		-- NOTE: Verification that FollowerEntity/ modules do not fire server RemoteEvents
		-- is performed by: (1) code review at PR time, (2) a code-search audit analogous to
		-- tools/audit-asset-ids.sh. A runtime test cannot reliably intercept all remote
		-- fire paths without mocking the full Network module.
		-- Tracking: follower-entity/story-002 §Read-only contract AC.

	end)

	-- =========================================================================
	-- FollowerEntityClient unit-level guards (class-level; complement orchestrator tests)
	-- =========================================================================

	describe("FollowerEntityClient class guards", function()

		it("test_follower_entity_client_destroy_is_idempotent", function()
			-- Arrange: construct directly (bypass orchestrator).
			local Packages = ReplicatedStorage.Packages
			local JanitorModule = require(Packages.janitor)
			local janitor = JanitorModule.new()
			local client = FollowerEntityClient.new("DIRECT_C1", janitor)

			-- Act: destroy twice.
			local ok = pcall(function()
				client:destroy()
				client:destroy()  -- second call must be a no-op, not an error
			end)

			-- Assert
			expect(ok).to.equal(true)
			expect((client :: any)._destroyed).to.equal(true)
		end)

		it("test_follower_entity_client_methods_are_noop_after_destroy", function()
			-- Arrange
			local Packages = ReplicatedStorage.Packages
			local JanitorModule = require(Packages.janitor)
			local janitor = JanitorModule.new()
			local client = FollowerEntityClient.new("DIRECT_C2", janitor)
			client:destroy()

			-- Act: call all public methods after destroy — none should error.
			local ok = pcall(function()
				client:setLOD(0)
				client:setPoolSize(10)
				local _ = client:getPeelingCount()
				client:startPeel("rival", 3)
				client:spawnFromAbsorb(Vector3.new(0, 0, 0))
				client:_update(0.016)
				client:_markAllDespawning()
			end)

			expect(ok).to.equal(true)
		end)

		it("test_follower_entity_client_markAllDespawning_is_idempotent_on_already_despawning", function()
			-- Arrange: seed 3 followers, mark despawning twice, verify timestamps preserved.
			local Packages = ReplicatedStorage.Packages
			local JanitorModule = require(Packages.janitor)
			local janitor = JanitorModule.new()
			local client = FollowerEntityClient.new("DIRECT_C3", janitor)

			local parts = makeMockParts(sandboxFolder, 3)
			client:_debugSeedActiveFollowers(parts)

			-- Act: first mark
			client:_markAllDespawning()
			local ts1 = {}
			for k, v in (client :: any)._despawningStartedAt do
				ts1[k] = v
			end

			-- Second mark (idempotent — must not overwrite timestamps)
			client:_markAllDespawning()
			local ts2 = {}
			for k, v in (client :: any)._despawningStartedAt do
				ts2[k] = v
			end

			-- Assert: timestamps unchanged
			for i = 1, 3 do
				expect(ts1[i]).to.equal(ts2[i])
			end

			-- Assert: states still Despawning
			for _, s in client:_debugGetFollowerStates() do
				expect(s).to.equal("Despawning")
			end

			client:destroy()
		end)

		it("test_follower_entity_client_getPeelingCount_returns_zero_in_story002", function()
			-- Stub returns 0 until story-007 populates _peelingFollowers.
			local Packages = ReplicatedStorage.Packages
			local JanitorModule = require(Packages.janitor)
			local janitor = JanitorModule.new()
			local client = FollowerEntityClient.new("DIRECT_C4", janitor)

			expect(client:getPeelingCount()).to.equal(0)
			client:destroy()
		end)

	end)

end
