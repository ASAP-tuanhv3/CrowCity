--!strict

--[[
	pool_bootstrap_rig_assembly.spec.luau
	Implements: Story 001 (Pool bootstrap + 2-Part rig assembly)
	GDD: design/gdd/follower-entity.md §Pool architecture + §C.1 + §Edge Cases
	ADR: ADR-0007 §Pool Allocation Strategy

	Coverage:
	  AC-1a  — Rig parts: 1 Body + 1 Hat, no Humanoid; Anchored; weld under body; hat offset
	  AC-1b  — d_init range: [0, 0.667), never 0, non-zero stddev across 1000 samples
	  AC-6   — Hat template nil: body-only bundle; warning logged once
	  AC-7   — Pool exhaustion: nil on drain; warning exactly once; returnBundle re-arms grant

	Pool prealloc invariants (Pool-PA):
	  PA-1   — after initAsync, getFreeCount == bodyCapacity
	  PA-2   — per-Part flags correct on pre-alloc'd bodies
	  PA-3   — Part.Parent == sandbox folder after initAsync
	  PA-4   — initAsync is idempotent

	Note: test capacities are deliberately small (body=4, hat=4) to keep tests fast.
	Production capacities are POOL_PREALLOC_LOD0_BODY = 460 per FollowerPoolConfig.
	Using small capacities ensures initAsync completes within the TestEZ run time
	budget without triggering dozens of task.defer yield cycles.
--]]

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Rig  = require(ReplicatedStorage.Source.FollowerEntity.Rig)
	local Pool = require(ReplicatedStorage.Source.FollowerEntity.Pool)
	local FollowerPoolConfig = require(ReplicatedStorage.Source.SharedConstants.FollowerPoolConfig)

	-- -----------------------------------------------------------------------
	-- Sandbox helpers
	-- -----------------------------------------------------------------------

	-- Small test capacity to keep initAsync fast.
	local TEST_CAPACITY = 4
	local TEST_BATCH_SIZE = 2
	local HEAD_OFFSET_Y = FollowerPoolConfig.HEAD_OFFSET_Y

	-- Creates a fresh sandbox Folder in Workspace for each test.
	local function makeSandboxFolder(): Folder
		local folder = Instance.new("Folder")
		folder.Name = "_FollowerPoolTest_" .. tostring(math.random(1, 999999))
		folder.Parent = workspace
		return folder
	end

	-- Minimal body template provider: returns a new Part each call.
	local function makeBodyProvider(): (hueIndex: number) -> BasePart
		return function(_hueIndex: number): BasePart
			local part = Instance.new("Part")
			part.Name = "Body"
			part.Size = Vector3.new(2, 2, 2)
			return part
		end
	end

	-- Hat provider that always returns a valid hat (for normal tests).
	local function makeHatProvider(): (hueIndex: number) -> BasePart?
		return function(_hueIndex: number): BasePart?
			local hat = Instance.new("Part")
			hat.Name = "Hat"
			hat.Size = Vector3.new(1.5, 0.5, 1.5)
			return hat
		end
	end

	-- Hat provider that returns nil for hueIndex == 0 (sentinel); valid otherwise.
	local function makeNilHatProviderForZero(): (hueIndex: number) -> BasePart?
		return function(hueIndex: number): BasePart?
			if hueIndex <= 0 then
				return nil
			end
			local hat = Instance.new("Part")
			hat.Name = "Hat"
			hat.Size = Vector3.new(1.5, 0.5, 1.5)
			return hat
		end
	end

	-- Hat provider that ALWAYS returns nil (used for AC-6 pool-level nil path).
	local function makeAlwaysNilHatProvider(): (hueIndex: number) -> BasePart?
		return function(_hueIndex: number): BasePart?
			return nil
		end
	end

	-- Builds a minimal PoolConfig for tests.
	local function makePoolConfig(
		folder: Folder,
		hatProvider: (hueIndex: number) -> BasePart?,
		logger: (string) -> (),
		capacity: number?
	): Pool.PoolConfig
		local cap = capacity or TEST_CAPACITY
		return {
			bodyCapacity         = cap,
			hatCapacity          = cap,
			parent               = folder,
			bodyTemplateProvider = makeBodyProvider(),
			hatTemplateProvider  = hatProvider,
			headOffsetY          = HEAD_OFFSET_Y,
			batchSize            = TEST_BATCH_SIZE,
			logger               = logger,
		}
	end

	-- -----------------------------------------------------------------------
	-- AC-1a: Rig parts
	-- -----------------------------------------------------------------------

	describe("AC-1a (Rig parts)", function()
		local folder: Folder

		beforeEach(function()
			folder = makeSandboxFolder()
		end)

		afterEach(function()
			folder:Destroy()
		end)

		it("produces 1 Body Part parented to folder after Rig.assemble", function()
			-- Arrange
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			-- Act
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			-- Assert
			expect(bundle.body).to.be.ok()
			expect(bundle.body.Parent).to.equal(folder)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("Body.Anchored == true after assemble", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			expect(bundle.body.Anchored).to.equal(true)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("Body.CanCollide / CanQuery / CanTouch / CastShadow all false", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			expect(bundle.body.CanCollide).to.equal(false)
			expect(bundle.body.CanQuery).to.equal(false)
			expect(bundle.body.CanTouch).to.equal(false)
			expect(bundle.body.CastShadow).to.equal(false)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("WeldConstraint exists with Part0=body, Part1=hat", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			expect(bundle.weld).to.be.ok()
			local weld = bundle.weld :: WeldConstraint
			expect(weld.Part0).to.equal(bundle.body)
			expect(weld.Part1).to.equal(bundle.hat)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("WeldConstraint is parented under body (not under folder)", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			local weld = bundle.weld :: WeldConstraint
			-- Must be under body, NOT directly under folder.
			expect(weld.Parent).to.equal(bundle.body)
			expect(weld.Parent).never.to.equal(folder)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("Hat is parented under body (not under folder)", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			local hat = bundle.hat :: BasePart
			expect(hat.Parent).to.equal(bundle.body)
			expect(hat.Parent).never.to.equal(folder)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("Hat.CFrame == body.CFrame * CFrame.new(0, headOffsetY, 0)", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			local hat = bundle.hat :: BasePart
			-- Both parts are parked at (0, -1000, 0). Hat should be offset by HEAD_OFFSET_Y.
			local expectedCFrame = bundle.body.CFrame * CFrame.new(0, HEAD_OFFSET_Y, 0)
			local actualCFrame   = hat.CFrame
			-- Compare position component (weld keeps hat relative to body).
			local posExpected = expectedCFrame.Position
			local posActual   = actualCFrame.Position
			expect(math.abs(posActual.Y - posExpected.Y) < 0.01).to.equal(true)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)

		it("two assemblies in same frame produce independent bodies with no shared WeldConstraint", function()
			local bt1 = Instance.new("Part")
			local ht1 = Instance.new("Part")
			local bt2 = Instance.new("Part")
			local ht2 = Instance.new("Part")
			local b1 = Rig.assemble(bt1, ht1, HEAD_OFFSET_Y, folder)
			local b2 = Rig.assemble(bt2, ht2, HEAD_OFFSET_Y, folder)
			expect(b1.body).never.to.equal(b2.body)
			expect(b1.weld).never.to.equal(b2.weld)
			bt1:Destroy() ht1:Destroy() bt2:Destroy() ht2:Destroy()
		end)

		it("no Humanoid exists anywhere under the assembled rig", function()
			local bodyTemplate = Instance.new("Part")
			local hatTemplate  = Instance.new("Part")
			local bundle = Rig.assemble(bodyTemplate, hatTemplate, HEAD_OFFSET_Y, folder)
			-- Search the body and all its descendants for any Humanoid.
			local humanoids = bundle.body:GetDescendants()
			local found = false
			for _, descendant in humanoids do
				if descendant:IsA("Humanoid") then
					found = true
					break
				end
			end
			expect(found).to.equal(false)
			bodyTemplate:Destroy()
			hatTemplate:Destroy()
		end)
	end)

	-- -----------------------------------------------------------------------
	-- AC-1b: d_init range
	-- -----------------------------------------------------------------------

	describe("AC-1b (d_init range)", function()

		it("returns values in [0, 1/WALK_FREQ_HZ), never exactly 0, with non-zero stddev across 1000 samples", function()
			-- Arrange
			local WALK_FREQ_HZ = FollowerPoolConfig.WALK_FREQ_HZ
			local phaseMax = 1 / WALK_FREQ_HZ  -- 0.667 studs at WALK_FREQ_HZ = 1.5

			local SAMPLE_COUNT = 1000
			local samples: { number } = {}

			-- Act
			for _ = 1, SAMPLE_COUNT do
				table.insert(samples, Rig.initWalkPhase())
			end

			-- Assert: range check
			local foundZero = false
			for _, v in samples do
				expect(v >= 0).to.equal(true)
				expect(v < phaseMax).to.equal(true)
				if v == 0 then
					foundZero = true
				end
			end
			expect(foundZero).to.equal(false)

			-- Assert: non-zero standard deviation (values are not all identical)
			local sum = 0
			for _, v in samples do
				sum += v
			end
			local mean = sum / SAMPLE_COUNT
			local sumSq = 0
			for _, v in samples do
				local diff = v - mean
				sumSq += diff * diff
			end
			local stddev = math.sqrt(sumSq / SAMPLE_COUNT)
			expect(stddev > 0).to.equal(true)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- AC-6: Hat template nil
	-- -----------------------------------------------------------------------

	describe("AC-6 (Hat template nil)", function()
		local folder: Folder

		beforeEach(function()
			folder = makeSandboxFolder()
		end)

		afterEach(function()
			folder:Destroy()
		end)

		it("returns body-only bundle when hatTemplateProvider returns nil (via Rig.assemble directly)", function()
			-- Arrange: nil hat template
			local bodyTemplate = Instance.new("Part")
			-- Act
			local bundle = Rig.assemble(bodyTemplate, nil, HEAD_OFFSET_Y, folder)
			-- Assert
			expect(bundle.body).to.be.ok()
			expect(bundle.hat).to.equal(nil)
			expect(bundle.weld).to.equal(nil)
			bodyTemplate:Destroy()
		end)

		it("grantBundle returns body-only bundle when hatTemplateProvider returns nil for hueIndex=0", function()
			-- Arrange
			local warns: { string } = {}
			local function captureWarn(msg: string)
				table.insert(warns, msg)
			end
			local pool = Pool.new(makePoolConfig(folder, makeNilHatProviderForZero(), captureWarn))
			pool:initAsync()

			-- Act: grant with hueIndex = 0 (no-hat sentinel)
			local bundle = pool:grantBundle(0)

			-- Assert: body-only
			expect(bundle).to.be.ok()
			local b = bundle :: Pool.RigBundle
			expect(b.body).to.be.ok()
			expect(b.hat).to.equal(nil)
			expect(b.weld).to.equal(nil)

			pool:destroy()
		end)

		it("warning is logged exactly once per hueIndex when hatTemplateProvider returns nil", function()
			-- Arrange
			local warns: { string } = {}
			local function captureWarn(msg: string)
				table.insert(warns, msg)
			end
			local pool = Pool.new(makePoolConfig(folder, makeNilHatProviderForZero(), captureWarn))
			pool:initAsync()

			-- Act: three grants with same nil-hat hueIndex (0)
			pool:grantBundle(0)
			pool:grantBundle(0)
			pool:grantBundle(0)

			-- Assert: dedup — warning fires exactly once for hueIndex=0 across multiple grants
			-- (per-hueIndex dedup proxies the (crowdId, skin_id) dedup spec at pool layer).
			local nilHatWarns = 0
			for _, msg in warns do
				if msg:find("body%-only follower") then
					nilHatWarns += 1
				end
			end
			expect(nilHatWarns).to.equal(1)

			pool:destroy()
		end)

		it("body-only grant stamps body:GetAttribute('FollowerHadHat') == false (AC-6 returnBundle gate)", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeNilHatProviderForZero(), warn))
			pool:initAsync()

			-- Act
			local bundle = pool:grantBundle(0)

			-- Assert: attribute stamped — returnBundle skip-gate depends on this flag.
			expect(bundle).to.be.ok()
			local b = bundle :: Pool.RigBundle
			expect(b.body:GetAttribute("FollowerHadHat")).to.equal(false)

			pool:destroy()
		end)

		it("returnBundle does NOT re-pool a body-only slot (known MVP limitation)", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeNilHatProviderForZero(), warn))
			pool:initAsync()
			local before = pool:getFreeCount()

			-- Drain one slot via body-only grant.
			local bundle = pool:grantBundle(0)
			expect(bundle).to.be.ok()
			expect(pool:getFreeCount()).to.equal(before - 1)

			-- Act: return body-only bundle
			pool:returnBundle(bundle :: Pool.RigBundle)

			-- Assert: free count NOT restored — body-only slots intentionally drift
			-- per Story 001 known MVP limitation (Story 006 / Skin System will fix).
			expect(pool:getFreeCount()).to.equal(before - 1)

			pool:destroy()
		end)

		it("no error thrown when hat is nil (no pcall explosion)", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeAlwaysNilHatProvider(), warn))
			pool:initAsync()

			-- Act + Assert (no error)
			local ok = pcall(function()
				local bundle = pool:grantBundle(1)
				-- Should be body-only; no crash.
				if bundle then
					pool:returnBundle(bundle)
				end
			end)
			expect(ok).to.equal(true)

			pool:destroy()
		end)

		it("subsequent grant with valid hueIndex succeeds normally after nil-hat grant", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeNilHatProviderForZero(), warn, TEST_CAPACITY + 2))
			pool:initAsync()

			-- Drain one slot with nil-hat hueIndex.
			local nilBundle = pool:grantBundle(0)
			expect(nilBundle).to.be.ok()

			-- Act: valid hueIndex (non-zero — hat provider returns a Part).
			local validBundle = pool:grantBundle(1)

			-- Assert: valid bundle has hat
			expect(validBundle).to.be.ok()
			if validBundle then
				expect(validBundle.hat).to.be.ok()
			end

			pool:destroy()
		end)
	end)

	-- -----------------------------------------------------------------------
	-- AC-7: Pool exhaustion
	-- -----------------------------------------------------------------------

	describe("AC-7 (Pool exhaustion)", function()
		local folder: Folder

		beforeEach(function()
			folder = makeSandboxFolder()
		end)

		afterEach(function()
			folder:Destroy()
		end)

		it("returns nil when pool drained", function()
			-- Arrange
			local warns: { string } = {}
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), function(m) table.insert(warns, m) end))
			pool:initAsync()

			-- Drain all slots.
			local grants: { Pool.RigBundle } = {}
			for _ = 1, TEST_CAPACITY do
				local b = pool:grantBundle(1)
				if b then table.insert(grants, b) end
			end

			-- Act: one more grant on empty pool
			local result = pool:grantBundle(1)

			-- Assert: nil returned
			expect(result).to.equal(nil)

			pool:destroy()
		end)

		it("logs warning exactly once per session when pool drained", function()
			-- Arrange
			local warns: { string } = {}
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), function(m) table.insert(warns, m) end))
			pool:initAsync()

			-- Drain pool.
			for _ = 1, TEST_CAPACITY do
				pool:grantBundle(1)
			end

			-- Act: multiple nil grants
			pool:grantBundle(1)
			pool:grantBundle(1)
			pool:grantBundle(1)

			-- Assert: warning fired exactly once (deduplicated).
			local exhaustionWarns = 0
			for _, msg in warns do
				if msg:find("exhausted") then
					exhaustionWarns += 1
				end
			end
			expect(exhaustionWarns).to.equal(1)

			pool:destroy()
		end)

		it("returnBundle re-arms availability without re-arming the exhaustion warning", function()
			-- Arrange
			local warns: { string } = {}
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), function(m) table.insert(warns, m) end))
			pool:initAsync()

			-- Drain all slots.
			local grants: { Pool.RigBundle } = {}
			for _ = 1, TEST_CAPACITY do
				local b = pool:grantBundle(1)
				if b then table.insert(grants, b) end
			end

			-- Trigger exhaustion warning.
			pool:grantBundle(1)

			-- Return one bundle.
			if #grants > 0 then
				pool:returnBundle(grants[1])
				table.remove(grants, 1)
			end

			-- Act: grant should succeed now.
			local result = pool:grantBundle(1)

			-- Assert: grant succeeded (pool re-armed).
			expect(result).to.be.ok()

			-- Assert: no second exhaustion warning fired.
			local exhaustionWarns = 0
			for _, msg in warns do
				if msg:find("exhausted") then
					exhaustionWarns += 1
				end
			end
			-- Still exactly 1 — returning then re-granting does not re-arm the warning.
			expect(exhaustionWarns).to.equal(1)

			pool:destroy()
		end)

		it("no error thrown on nil grant (no pcall explosion)", function()
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()

			-- Drain.
			for _ = 1, TEST_CAPACITY do
				pool:grantBundle(1)
			end

			-- Act: nil grant should not throw.
			local ok = pcall(function()
				pool:grantBundle(1)
			end)
			expect(ok).to.equal(true)

			pool:destroy()
		end)
	end)

	-- -----------------------------------------------------------------------
	-- Pool prealloc invariants
	-- -----------------------------------------------------------------------

	describe("Pool prealloc (PA)", function()
		local folder: Folder

		beforeEach(function()
			folder = makeSandboxFolder()
		end)

		afterEach(function()
			folder:Destroy()
		end)

		it("PA-1: after initAsync, getFreeCount == bodyCapacity", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			-- Act
			pool:initAsync()
			-- Assert
			expect(pool:getFreeCount()).to.equal(TEST_CAPACITY)
			pool:destroy()
		end)

		it("PA-2: per-Part flags correct on pre-alloc'd bodies AND hats (Anchored, CanCollide, CastShadow)", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()

			-- Sample all free bundles by granting and inspecting each one.
			local bundles: { Pool.RigBundle } = {}
			for _ = 1, TEST_CAPACITY do
				local b = pool:grantBundle(1)
				if b then table.insert(bundles, b) end
			end

			-- Assert each body has correct flags.
			for _, bundle in bundles do
				expect(bundle.body.Anchored).to.equal(true)
				expect(bundle.body.CanCollide).to.equal(false)
				expect(bundle.body.CanQuery).to.equal(false)
				expect(bundle.body.CanTouch).to.equal(false)
				expect(bundle.body.CastShadow).to.equal(false)
				-- Hat flags must match per Rig.applyPoolFlags
				expect(bundle.hat).to.be.ok()
				local hat = bundle.hat :: BasePart
				expect(hat.Anchored).to.equal(true)
				expect(hat.CanCollide).to.equal(false)
				expect(hat.CanQuery).to.equal(false)
				expect(hat.CanTouch).to.equal(false)
				expect(hat.CastShadow).to.equal(false)
			end

			pool:destroy()
		end)

		it("PA-3: Body parented to sandbox folder; Hat parented under Body after initAsync", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()

			-- Grant all to inspect parents.
			local bundles: { Pool.RigBundle } = {}
			for _ = 1, TEST_CAPACITY do
				local b = pool:grantBundle(1)
				if b then table.insert(bundles, b) end
			end

			-- Assert: each body's parent is the sandbox folder; hat parent is its body.
			for _, bundle in bundles do
				expect(bundle.body.Parent).to.equal(folder)
				expect(bundle.hat).to.be.ok()
				local hat = bundle.hat :: BasePart
				expect(hat.Parent).to.equal(bundle.body)
			end

			pool:destroy()
		end)

		it("PA-4: initAsync is idempotent — calling twice does not double-allocate", function()
			-- Arrange
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()
			local countAfterFirst = pool:getFreeCount()

			-- Act: call again
			pool:initAsync()
			local countAfterSecond = pool:getFreeCount()

			-- Assert: count unchanged
			expect(countAfterFirst).to.equal(TEST_CAPACITY)
			expect(countAfterSecond).to.equal(TEST_CAPACITY)

			pool:destroy()
		end)

		it("PA-5: getActiveCount increases on grant and decreases on return", function()
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()

			expect(pool:getActiveCount()).to.equal(0)

			local b1 = pool:grantBundle(1)
			expect(pool:getActiveCount()).to.equal(1)

			local b2: Pool.RigBundle? = pool:grantBundle(1)
			expect(pool:getActiveCount()).to.equal(2)

			if b1 then
				pool:returnBundle(b1)
			end
			-- b2 left active intentionally — verify count stays at 1 after one return.
			_ = b2
			expect(pool:getActiveCount()).to.equal(1)

			pool:destroy()
		end)

		it("PA-6: getFreeCount + getActiveCount == bodyCapacity when no body-only grants", function()
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))
			pool:initAsync()

			local b1 = pool:grantBundle(1)
			local b2 = pool:grantBundle(1)

			expect(pool:getFreeCount() + pool:getActiveCount()).to.equal(TEST_CAPACITY)

			if b1 then pool:returnBundle(b1) end
			if b2 then pool:returnBundle(b2) end

			expect(pool:getFreeCount() + pool:getActiveCount()).to.equal(TEST_CAPACITY)

			pool:destroy()
		end)

		it("PA-7: concurrent initAsync — second caller yields and sees consistent count", function()
			-- Two coroutines call initAsync on a fresh pool. The second must yield
			-- on _initDoneEvent.Event:Wait() and resume after the first completes,
			-- with both observing the final getFreeCount == capacity.
			local pool = Pool.new(makePoolConfig(folder, makeHatProvider(), warn))

			local firstDone, secondDone = false, false
			local firstCount, secondCount = -1, -1

			task.spawn(function()
				pool:initAsync()
				firstCount = pool:getFreeCount()
				firstDone = true
			end)
			task.spawn(function()
				pool:initAsync()
				secondCount = pool:getFreeCount()
				secondDone = true
			end)

			-- Yield until both coroutines finish (bounded by initAsync batches).
			local timeout = 0
			while not (firstDone and secondDone) do
				task.wait()
				timeout += 1
				if timeout > 200 then  -- ~3 seconds at 60 Hz; way more than needed
					error("PA-7: concurrent initAsync timed out")
				end
			end

			expect(firstDone).to.equal(true)
			expect(secondDone).to.equal(true)
			expect(firstCount).to.equal(TEST_CAPACITY)
			expect(secondCount).to.equal(TEST_CAPACITY)

			pool:destroy()
		end)
	end)

	-- -----------------------------------------------------------------------
	-- FollowerPoolConfig constants (Story 001 AC: 460/460/100/60 + batch 25)
	-- -----------------------------------------------------------------------

	describe("FollowerPoolConfig constants", function()
		it("exports POOL_PREALLOC_LOD0_BODY = 460", function()
			expect(FollowerPoolConfig.POOL_PREALLOC_LOD0_BODY).to.equal(460)
		end)
		it("exports POOL_PREALLOC_LOD0_HAT = 460", function()
			expect(FollowerPoolConfig.POOL_PREALLOC_LOD0_HAT).to.equal(460)
		end)
		it("exports POOL_PREALLOC_LOD1 = 100", function()
			expect(FollowerPoolConfig.POOL_PREALLOC_LOD1).to.equal(100)
		end)
		it("exports POOL_PREALLOC_LOD2_BILLBOARD = 60", function()
			expect(FollowerPoolConfig.POOL_PREALLOC_LOD2_BILLBOARD).to.equal(60)
		end)
		it("exports POOL_BATCH_SIZE = 25 (matches NPC Spawner pattern)", function()
			expect(FollowerPoolConfig.POOL_BATCH_SIZE).to.equal(25)
		end)
		it("exports WALK_FREQ_HZ = 1.5 (art-bible lock)", function()
			expect(FollowerPoolConfig.WALK_FREQ_HZ).to.equal(1.5)
		end)
	end)
end
