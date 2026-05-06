--!strict

--[[
	perf_fixture.server.luau — AC-17 Micro Profiler perf-soak harness
	Story:   production/epics/follower-entity/story-011-perf-soak-validation.md
	GDD:     design/gdd/follower-entity.md §AC-17 (perf soak 80 LOD-0 ≤ 2.5 ms p99)
	ADR:     ADR-0003 §Performance Budget + ADR-0007 §Boids Loop Discipline
	Status:  IN-DEV ONLY — guarded by FOLLOWER_PERF_FIXTURE_ENABLED attribute
	         on workspace. NEVER ship in a production build (uses _debug seams).

	WHAT IT DOES:
	  On the first PlayerAdded event, seeds CrowdStateClient with one crowd record
	  for the joining player, fires CrowdCreated, enqueues 80 absorb spawns through
	  the SpawnThrottleQueue (drains 4/frame ≈ 5 s for full crowd), then drives a
	  scripted patrol path via 15 Hz CrowdState updates so the boids loop has
	  movement + d-accumulation + steady hue throughout the soak.

	HOW TO USE:
	  1. Build the place: `rojo build default.project.json -o perf-fixture.rbxl`
	  2. Open in Roblox Studio. In Studio: select Workspace → Properties → Attributes
	     → click +Attribute → name `FollowerPerfFixtureEnabled` (boolean) → set true.
	     (This guard prevents the fixture from running in normal Studio sessions.)
	  3. Press F5 (Play in Roblox Player). NOT "Run" (Studio mode adds overhead).
	  4. Ctrl+F6 to open Micro Profiler → click Pause/Resume to start recording.
	  5. Wait for full crowd spawn (~5 s of throttle-drained spawns) + 60 s soak
	     (3,600 frames @ 60 FPS). Total observe time: ~70 s.
	  6. Click Pause to stop recording. Right-click frame range → Save As → export
	     samples. Filter label `FollowerEntityClient_Update` to isolate the loop.
	  7. Sort 3,600 samples descending; sample at index 36 = p99.
	  8. Fill production/qa/evidence/perf-soak-2026-05-04-microbench.md with
	     hardware spec + p50/p90/p99 + verdict + sign-off.

	WHY GUARDED:
	  The fixture uses CrowdStateClient._debugSetRecord + _debugFireCrowdCreated
	  test seams. Running in production would seed fake crowd state — undefined
	  behaviour. The Workspace attribute gate ensures it runs only when explicitly
	  enabled by the perf engineer.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FIXTURE_ATTRIBUTE_NAME = "FollowerPerfFixtureEnabled"

local function isEnabled(): boolean
	return Workspace:GetAttribute(FIXTURE_ATTRIBUTE_NAME) == true
end

if not isEnabled() then
	-- Fixture disabled: silent no-op. Production safety guard.
	return
end

print("[perf_fixture] AC-17 perf soak harness ENABLED — waiting for player join")

-- Lazy-require so production builds without the fixture attribute don't pay
-- the require cost or accidentally pull in test-only seams.
local CrowdStateClient = require(ReplicatedStorage.Source.CrowdStateClient)
local CrowdManagerClient = require(ReplicatedStorage.Source.FollowerEntity.CrowdManagerClient)

-- Patrol path tuning. Sin-wave crowd center motion within a ~20-stud radius
-- so followers continuously redirect (exercising boids F4 + F8 walk-bob).
local PATROL_RADIUS = 20
local PATROL_FREQ_HZ = 0.2 -- one full loop every 5 s
local BROADCAST_HZ = 15    -- matches CrowdStateBroadcast cadence
local TARGET_FOLLOWER_COUNT = 80
local CROWD_HUE = 8        -- art-bible §4 index 8 = Red

local function onPlayerAdded(player: Player): ()
	-- Wait briefly for client gameplay init (PlayerData load, character spawn,
	-- CrowdManagerClient:start()). 2 s is generous; in practice ~0.5 s.
	task.wait(2)

	local crowdId = tostring(player.UserId)

	-- 1. Seed initial crowd state record.
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
			.. "'FollowerEntityClient_Update').",
		crowdId, TARGET_FOLLOWER_COUNT, 60 * 60
	))

	-- 3. Patrol path: 15 Hz CrowdState updates with sin-wave motion.
	--    Loops indefinitely; user stops the place when soak is complete.
	local startT = os.clock()
	local tick = 1
	while player.Parent ~= nil do
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

	-- Player left: clean up the crowd record.
	CrowdStateClient._debugFireCrowdEliminated(crowdId)
end

-- F5 race: PlayerAdded may fire before this script's :Connect() runs (Studio
-- spawns local player on Play start). Handle pre-existing players too.
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(function(player: Player)
	task.spawn(onPlayerAdded, player)
end)
