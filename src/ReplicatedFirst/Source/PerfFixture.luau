--!strict

--[[
	PerfFixture.luau — AC-17 Micro Profiler perf-soak harness (CLIENT-SIDE)
	Story:   production/epics/follower-entity/story-011-perf-soak-validation.md
	GDD:     design/gdd/follower-entity.md §AC-17 (perf soak 80 LOD-0 ≤ 2.5 ms p99)
	ADR:     ADR-0003 §Performance Budget + ADR-0007 §Boids Loop Discipline
	Status:  IN-DEV ONLY — guarded by FollowerPerfFixtureEnabled attribute on
	         workspace. NEVER ship in a production build (uses _debug seams).

	WHY CLIENT-SIDE:
	  CrowdStateClient + CrowdManagerClient are CLIENT modules. Each Roblox
	  environment (server vs client) gets its own ModuleScript copy with its
	  own singleton state. A server-side fixture would populate the SERVER's
	  copy of CrowdStateClient — the client's CrowdManagerClient would never
	  see the seeded crowd. Fixture must run client-side to drive the same
	  module instance the orchestrator subscribes to.

	WHAT IT DOES:
	  Called by start.server.luau (ReplicatedFirst, RunContext: Client) AFTER
	  CrowdManagerClient:start() has connected to CrowdStateClient signals.
	  Seeds CrowdStateClient with one crowd record for the local player, fires
	  CrowdCreated, enqueues 80 absorb spawns through the SpawnThrottleQueue
	  (drains 4/frame ≈ 0.33 s for full crowd), then drives a scripted patrol
	  path via 15 Hz CrowdState updates so the boids loop has continuous
	  movement throughout the soak.

	HOW TO USE:
	  1. Build:   `rojo build default.project.json -o perf-fixture.rbxl`
	  2. Open in Roblox Studio. Workspace → Properties → Attributes → +Attribute
	     → name `FollowerPerfFixtureEnabled` (boolean) → set true. Ctrl+S.
	  3. F5 (Play in Roblox Player). NOT "Run" — Studio mode adds overhead.
	  4. Ctrl+F6 → Micro Profiler → Pause/Resume to start recording.
	  5. Wait ~5 s for full crowd spawn + 60 s soak (3,600 frames @ 60 FPS).
	  6. Pause → right-click frame range → Save As → export samples.
	     Filter label `FollowerEntityClient_Update`.
	  7. Sort 3,600 samples descending; sample at index 36 = p99.
	  8. Fill production/qa/evidence/perf-soak-2026-05-04-microbench.md.

	WHY GUARDED:
	  Uses CrowdStateClient._debugSetRecord + _debugFireCrowdCreated test seams.
	  Production runs would seed fake crowd state — undefined behaviour.
	  The Workspace attribute gate ensures it runs only when explicitly enabled.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FIXTURE_ATTRIBUTE_NAME = "FollowerPerfFixtureEnabled"

-- Patrol path tuning. Sin-wave crowd center motion within a ~20-stud radius
-- so followers continuously redirect (exercising boids F4 + F8 walk-bob).
local PATROL_RADIUS = 20
local PATROL_FREQ_HZ = 0.2 -- one full loop every 5 s
local BROADCAST_HZ = 15    -- matches CrowdStateBroadcast cadence
local TARGET_FOLLOWER_COUNT = 80
local CROWD_HUE = 8        -- art-bible §4 index 8 = Red

local PerfFixture = {}

local function isEnabled(): boolean
	return Workspace:GetAttribute(FIXTURE_ATTRIBUTE_NAME) == true
end

--- Starts the perf-soak fixture. Called by start.server.luau (client) after
--- CrowdManagerClient:start() has wired up its signal subscriptions.
--- No-op if the FollowerPerfFixtureEnabled Workspace attribute is not set.
function PerfFixture.start(): ()
	if not isEnabled() then
		return
	end

	print("[perf_fixture] AC-17 perf soak harness ENABLED on client")

	-- Lazy-require so production builds don't pay the require cost when the
	-- attribute gate is off.
	local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
	local CrowdManagerClient = require(ReplicatedStorage.Source.FollowerEntity.CrowdManagerClient)

	local localPlayer = Players.LocalPlayer
	if localPlayer == nil then
		warn("[perf_fixture] LocalPlayer is nil — cannot run client-side fixture")
		return
	end

	local crowdId = tostring(localPlayer.UserId)

	-- 1. Seed initial crowd state record on the client's CrowdStateClient
	--    cache (the same module instance that CrowdManagerClient subscribes to).
	CrowdStateClient._debugSetRecord(crowdId, {
		crowdId      = crowdId,
		tick         = 1,
		position     = Vector3.new(0, 5, 0),
		radius       = 5.0,
		count        = TARGET_FOLLOWER_COUNT,
		hue          = CROWD_HUE,
		state        = "Active",
		activeRelics = {} :: { string },
	})
	CrowdStateClient._debugFireCrowdCreated(crowdId)

	-- 2. Enqueue 80 absorb spawns. Throttle queue drains 4/frame so full crowd
	--    spawns over ~80/4 = 20 frames ≈ 0.33 s at 60 FPS.
	for i = 1, TARGET_FOLLOWER_COUNT do
		local angle = (i / TARGET_FOLLOWER_COUNT) * 2 * math.pi
		local pos = Vector3.new(
			math.cos(angle) * 8,
			5,
			math.sin(angle) * 8
		)
		CrowdManagerClient:enqueueAbsorbSpawn(crowdId, pos, CROWD_HUE)
	end

	print(string.format(
		"[perf_fixture] crowd %s seeded with %d followers; patrol path active. "
			.. "Open Micro Profiler (Ctrl+F6) and capture %d samples (label "
			.. "'FollowerEntityClient_Update'). "
			.. "Press [L] for AC-18 LOD-swap instance count snapshot.",
		crowdId, TARGET_FOLLOWER_COUNT, 60 * 60
	))

	-- AC-18 LOD-swap instance count harness.
	-- Bind L key: snapshot BasePart count → setPoolSize(15) → snapshot → setPoolSize(80) → snapshot.
	-- Outputs counts to Output window so user can paste into evidence MD.
	local UserInputService = game:GetService("UserInputService")

	local function countDescendantBaseParts(): number
		local count = 0
		for _, descendant in Workspace:GetDescendants() do
			if descendant:IsA("BasePart") then
				count += 1
			end
		end
		return count
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.KeyCode ~= Enum.KeyCode.L then return end

		local crowdClient = CrowdManagerClient:getCrowdClient(crowdId)
		if crowdClient == nil then
			warn("[perf_fixture] AC-18: crowd client missing")
			return
		end

		-- Snapshot 1: baseline (80 followers active)
		local before = countDescendantBaseParts()
		print(string.format("[perf_fixture] AC-18 SNAPSHOT BEFORE: %d BaseParts in Workspace", before));

		-- Action 1: shrink to 15 → 65 followers despawn over 0.2 s fade
		(crowdClient :: any):setPoolSize(15)
		print("[perf_fixture] AC-18: setPoolSize(15) called — wait ~0.5 s for fade")

		task.wait(0.5)
		local afterShrink = countDescendantBaseParts()
		print(string.format("[perf_fixture] AC-18 SNAPSHOT AFTER SHRINK: %d BaseParts (delta %+d)",
			afterShrink, afterShrink - before));

		-- Action 2: grow back to 80 → 65 cap-grow FadeIn drain at 4/frame ≈ 17 frames ≈ 0.28 s
		(crowdClient :: any):setPoolSize(80)
		print("[perf_fixture] AC-18: setPoolSize(80) called — wait ~1 s for cap-grow drain")

		task.wait(1.0)
		local afterGrow = countDescendantBaseParts()
		print(string.format("[perf_fixture] AC-18 SNAPSHOT AFTER REGROW: %d BaseParts (delta %+d vs initial)",
			afterGrow, afterGrow - before))

		print("[perf_fixture] AC-18 INVARIANT: BasePart count should be IDENTICAL across all 3 snapshots "
			.. "(Pool pre-allocated; no Instance.new on shrink or grow). Paste these counts into "
			.. "production/qa/evidence/lod-swap-2026-05-04-structural.md.")
	end)

	-- 3. Patrol path: 15 Hz CrowdState updates with sin-wave motion.
	--    task.spawn so this loop doesn't block the entry script's continuation.
	task.spawn(function()
		local startT = os.clock()
		local tick = 1
		while localPlayer.Parent ~= nil do
			local elapsed = os.clock() - startT
			local theta = elapsed * PATROL_FREQ_HZ * 2 * math.pi
			local centerX = math.sin(theta) * PATROL_RADIUS
			local centerZ = math.cos(theta) * PATROL_RADIUS
			tick = (tick + 1) % 65536 -- u16 tick wrap per CRB schema
			CrowdStateClient._debugSetRecord(crowdId, {
				crowdId      = crowdId,
				tick         = tick,
				position     = Vector3.new(centerX, 5, centerZ),
				radius       = 5.0,
				count        = TARGET_FOLLOWER_COUNT,
				hue          = CROWD_HUE,
				state        = "Active",
				activeRelics = {} :: { string },
			})
			task.wait(1 / BROADCAST_HZ)
		end
	end)
end

return PerfFixture
