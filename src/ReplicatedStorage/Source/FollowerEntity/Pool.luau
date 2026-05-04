--!strict

--[[
	Pool.luau
	Pre-allocated object pool for follower rig bundles.
	Implements: design/gdd/follower-entity.md §Pool architecture
	ADR: ADR-0007 §Pool Allocation Strategy

	Responsibilities:
	  - Pre-allocate Body + optional Hat bundles via task.defer in batchSize chunks
	  - Grant bundles to callers (grantBundle) and reclaim them (returnBundle)
	  - Report free/active counts
	  - Warn once per session on pool exhaustion (AC-7)
	  - Support body-only grants for hueIndex=0 sentinel (AC-6)
	  - Idempotent initAsync (safe to call twice)

	Out of scope:
	  - Hue colour writes (Story 006)
	  - Spawn state / transparency tweens (Story 005)
	  - LOD tier management (FollowerLODManager epic)
	  - RenderStepped boids loop (CrowdManagerClient + FollowerEntityClient)
	  - WeldConstraint assembly details (Rig.luau)

	Hue-swap at grant time (TODO for Story 006):
	  Pre-allocated bundles use hueIndex = 1 so they include hats.
	  grantBundle() does NOT re-template hue at grant time in Story 001.
	  Story 006 will add hue colour writes; hat-swap (skin system) defers to
	  Skin System (VS-tier). Document here to avoid silent scope creep.

	Body-only grant (AC-6):
	  If caller passes hueIndex whose hatTemplateProvider returns nil, the
	  prealloc hat is destroyed at grant time and a body-only bundle is returned.
	  The body is stamped with attribute "FollowerHadHat" = false so returnBundle
	  knows this slot cannot be returned to the free pool cleanly (known MVP
	  limitation — re-templating defers to Story 006 / Skin System).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Connections = require(ReplicatedStorage.Source.Connections)
local Rig = require(ReplicatedStorage.Source.FollowerEntity.Rig)

-- --------------------------------------------------------------------------
-- Types
-- --------------------------------------------------------------------------

--- Configuration passed to Pool.new.
export type PoolConfig = {
	--- Number of Body bundles to pre-allocate.
	bodyCapacity: number,
	--- Number of Hat bundles to pre-allocate (matched 1:1 with Body in practice).
	hatCapacity: number,
	--- Workspace Folder that owns the parked Parts.
	parent: Instance,
	--- Returns a cloned BasePart for the body at the given hue index.
	bodyTemplateProvider: (hueIndex: number) -> BasePart,
	--- Returns a cloned BasePart hat for the given hue index, or nil (no hat).
	hatTemplateProvider: (hueIndex: number) -> BasePart?,
	--- Y offset for hat attachment (studs).
	headOffsetY: number,
	--- How many bundles to allocate per task.defer slot (typically POOL_BATCH_SIZE = 25).
	batchSize: number,
	--- Optional injectable logger for warnings (defaults to warn). Used by tests.
	logger: ((string) -> ())?,
}

--- The bundle type returned by grantBundle / passed to returnBundle.
export type RigBundle = Rig.RigBundle

export type ClassType = typeof(setmetatable(
	{} :: {
		-- Config
		_config: PoolConfig,
		_logger: (string) -> (),
		-- Internal pool state
		_freeBodyBundles: { RigBundle },
		_activeBundles: { [BasePart]: RigBundle },
		-- Init guard
		_initialized: boolean,
		_initializing: boolean,
		_initDoneEvent: BindableEvent,
		-- Exhaustion warning dedup
		_exhaustionWarned: boolean,
		-- Per-hueIndex nil-hat warning dedup (AC-6: warning once per skin_id)
		_nilHatWarnedHues: { [number]: boolean },
		-- Lifecycle
		_connections: Connections.ClassType,
	},
	{} :: typeof({ __index = {} })
))

-- --------------------------------------------------------------------------
-- Private helpers (module-local)
-- --------------------------------------------------------------------------

local Pool = {}
Pool.__index = Pool

local function logExhaustionOnce(self: ClassType)
	if self._exhaustionWarned then
		return
	end
	self._exhaustionWarned = true
	self._logger("[FollowerEntity.Pool] grantBundle() returned nil — pool exhausted. "
		.. "Raise POOL_PREALLOC_LOD0_BODY toward 640 if this fires in production.")
end

-- --------------------------------------------------------------------------
-- Constructor
-- --------------------------------------------------------------------------

--- Creates a new Pool.
--- Does NOT pre-allocate. Call :initAsync() to allocate.
--- @param config PoolConfig
function Pool.new(config: PoolConfig): ClassType
	local self = setmetatable({} :: any, Pool)
	self._config           = config
	self._logger           = config.logger or warn
	self._freeBodyBundles  = {} :: { RigBundle }
	self._activeBundles    = {} :: { [BasePart]: RigBundle }
	self._initialized      = false
	self._initializing     = false
	self._exhaustionWarned = false
	self._nilHatWarnedHues = {} :: { [number]: boolean }
	self._connections      = Connections.new()
	-- BindableEvent used to signal concurrent callers that init is complete.
	local event = Instance.new("BindableEvent")
	self._initDoneEvent = event
	return self
end

-- --------------------------------------------------------------------------
-- Initialization
-- --------------------------------------------------------------------------

--- Pre-allocates pool entries in chunked task.defer batches (ADR-0007 pattern).
--- Idempotent: subsequent calls after the first are no-ops.
--- Concurrent calls: if initAsync is already in progress, yields until done.
function Pool.initAsync(self: ClassType)
	-- Already done — no-op.
	if self._initialized then
		return
	end

	-- Another caller already started init — yield until the event fires.
	if self._initializing then
		self._initDoneEvent.Event:Wait()
		return
	end

	self._initializing = true

	local config = self._config
	local targetCount = config.bodyCapacity

	-- Allocate in batches; each batch deferred so we don't spike one frame.
	-- Prealloc uses hueIndex = 1 so bundles include hats (body-only at hue=0
	-- would waste hat slots and produce mismatched free counts).
	-- TODO (Story 006): at grantBundle time, apply actual hue colour write.
	-- Hat-swap (skin system) defers to Skin System (VS-tier).
	while self:getFreeCount() < targetCount do
		local batchRemaining = math.min(
			config.batchSize,
			targetCount - self:getFreeCount()
		)
		task.defer(function()
			for _ = 1, batchRemaining do
				if self:getFreeCount() >= targetCount then
					break
				end
				local bundle: RigBundle = Rig.assemble(
					config.bodyTemplateProvider(1),
					config.hatTemplateProvider(1),
					config.headOffsetY,
					config.parent
				)
				-- Stamp hat presence attribute for returnBundle bookkeeping.
				-- hatTemplateProvider(1) is non-nil for DefaultSkin, so HasHat=true here.
				bundle.body:SetAttribute("FollowerHadHat", bundle.hat ~= nil)
				table.insert(self._freeBodyBundles, bundle)
			end
		end)
		-- Yield so the deferred work for this batch can run before we
		-- queue the next batch. This keeps per-frame allocation to batchSize Parts.
		task.wait()
	end

	self._initialized  = true
	self._initializing = false
	self._initDoneEvent:Fire()
end

-- --------------------------------------------------------------------------
-- Grant / return
-- --------------------------------------------------------------------------

--- Grants a bundle from the free pool to the caller.
--- Returns nil if the pool is exhausted (AC-7).
--- If hatTemplateProvider(hueIndex) returns nil, the prealloc hat is destroyed
--- and a body-only bundle is returned (AC-6).
--- @param hueIndex number — desired hue index (0 = no-hat sentinel per AC-6)
function Pool.grantBundle(self: ClassType, hueIndex: number): RigBundle?
	if #self._freeBodyBundles == 0 then
		logExhaustionOnce(self)
		return nil
	end

	-- Pop from the end of the free list (O(1)).
	local bundle: RigBundle = self._freeBodyBundles[#self._freeBodyBundles]
	self._freeBodyBundles[#self._freeBodyBundles] = nil

	-- AC-6: if the requested hue yields no hat, destroy the prealloc hat.
	local hatForHue: BasePart? = self._config.hatTemplateProvider(hueIndex)
	if hatForHue == nil and bundle.hat ~= nil then
		-- Destroy prealloc hat + weld from this slot.
		if bundle.weld then
			bundle.weld:Destroy()
		end
		bundle.hat:Destroy()
		bundle = {
			body = bundle.body,
			hat  = nil,
			weld = nil,
		}
		-- Stamp body-only flag so returnBundle knows not to re-pool this slot.
		bundle.body:SetAttribute("FollowerHadHat", false)
		-- AC-6 dedup: warn once per hueIndex (proxy for skin_id at pool level).
		-- Story spec mandates "exactly once per (crowdId, skin_id)". crowdId is not
		-- visible at pool layer, so dedup on hueIndex; cross-crowd dedup deferred
		-- to caller (Story 006 scope).
		if not self._nilHatWarnedHues[hueIndex] then
			self._nilHatWarnedHues[hueIndex] = true
			self._logger(
				("[FollowerEntity.Pool] hatTemplateProvider returned nil for hueIndex=%d — "
					.. "spawning body-only follower (AC-6). "
					.. "Replace DefaultSkin with Skin System for hue-specific hats.")
				:format(hueIndex)
			)
		end
	elseif hatForHue ~= nil then
		-- Hat-present path: prealloc bundle already has its hat. The clone we
		-- fetched for the nil-check is unused — destroy it to avoid orphan
		-- accumulation across many grants. (Story 006 will swap hue colour at
		-- grant time and may re-use this Part; for Story 001 we discard.)
		hatForHue:Destroy()
	end

	-- Track as active, keyed by body Part for O(1) returnBundle lookup.
	self._activeBundles[bundle.body] = bundle

	return bundle
end

--- Returns a bundle to the free pool.
--- Resets position/transparency; removes from active set.
--- Body-only slots (FollowerHadHat == false) are NOT returned to the free pool
--- because they cannot be re-used without a hat re-assembly step.
--- Known MVP limitation — deferred to Story 006 / Skin System.
--- @param bundle RigBundle — bundle previously obtained from grantBundle.
function Pool.returnBundle(self: ClassType, bundle: RigBundle)
	local body = bundle.body

	-- Remove from active tracking.
	self._activeBundles[body] = nil

	-- Body-only slots: skip re-pooling (can't be re-granted cleanly without hat).
	-- Log for QA visibility but do not warn repeatedly — this is a known limitation.
	if body:GetAttribute("FollowerHadHat") == false then
		-- Known MVP limitation: body-only grant cannot be returned to free pool.
		-- Pool count will be off by 1 per body-only grant. Story 006 / Skin System
		-- will add hat re-assembly on return for affected slots.
		return
	end

	-- Park the body off-screen.
	body.Transparency = 1
	body.CFrame = CFrame.new(0, -1000, 0)

	-- If there is a hat, park it too (it is welded so it moves with the body,
	-- but we also explicitly reset its CFrame and transparency for safety).
	if bundle.hat then
		bundle.hat.Transparency = 1
	end

	table.insert(self._freeBodyBundles, bundle)
end

-- --------------------------------------------------------------------------
-- Query
-- --------------------------------------------------------------------------

--- Returns the number of bundles currently in the free pool.
function Pool.getFreeCount(self: ClassType): number
	return #self._freeBodyBundles
end

--- Returns the number of bundles currently granted to callers.
function Pool.getActiveCount(self: ClassType): number
	local count = 0
	for _ in self._activeBundles do
		count += 1
	end
	return count
end

-- --------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------

--- Destroys the pool: disconnects all connections, destroys the init event,
--- and destroys all Parts owned by this pool.
--- After destroy, the pool instance must not be used.
function Pool.destroy(self: ClassType)
	self._connections:disconnect()

	-- Destroy all free bundle bodies (children of config.parent we created).
	for _, bundle in self._freeBodyBundles do
		-- bundle.hat is parented under bundle.body so :Destroy() on body handles it.
		bundle.body:Destroy()
	end
	self._freeBodyBundles = {}

	-- Destroy all active bundle bodies.
	for body in self._activeBundles do
		body:Destroy()
	end
	self._activeBundles = {}

	-- Clean up init event.
	self._initDoneEvent:Destroy()

	self._initialized  = false
	self._initializing = false
end

return Pool
