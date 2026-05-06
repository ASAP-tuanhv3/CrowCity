--!strict

--[[
	perf_fixture_world.server.luau — Server-side world setup for AC-17 perf soak

	Creates a baseplate + SpawnLocation when the FollowerPerfFixtureEnabled
	Workspace attribute is set. This is the SERVER half of the perf fixture —
	world geometry must be server-authored so the player character has
	something to stand on (server-side physics). The CLIENT half (crowd
	seeding via CrowdStateClient + CrowdManagerClient) lives in
	src/ReplicatedFirst/Source/PerfFixture.luau and is invoked by
	start.server.luau (RunContext: Client) at the end of gameplay init.

	Status: IN-DEV ONLY. Never ships in production.
--]]

local Workspace = game:GetService("Workspace")

local FIXTURE_ATTRIBUTE_NAME = "FollowerPerfFixtureEnabled"

if Workspace:GetAttribute(FIXTURE_ATTRIBUTE_NAME) ~= true then
	return
end

if Workspace:FindFirstChild("PerfFixtureBaseplate") == nil then
	local baseplate = Instance.new("Part")
	baseplate.Name = "PerfFixtureBaseplate"
	baseplate.Size = Vector3.new(200, 1, 200)
	baseplate.Position = Vector3.new(0, -0.5, 0)
	baseplate.Anchored = true
	baseplate.Material = Enum.Material.SmoothPlastic
	baseplate.BrickColor = BrickColor.new("Dark stone grey")
	baseplate.TopSurface = Enum.SurfaceType.Smooth
	baseplate.Parent = Workspace
end

if Workspace:FindFirstChild("PerfFixtureSpawn") == nil then
	-- Spawn 30 studs back from the crowd center; clean side-on view of the
	-- 20-stud-radius patrol orbit.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PerfFixtureSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 30)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.BrickColor = BrickColor.new("Bright green")
	spawn.Parent = Workspace
end

print("[perf_fixture_world] Baseplate + spawn placed")
