--!strict
-- TestEZ headless runner. Discovers all `*_test.luau` modules under
-- ServerStorage.Tests (mapped from tests/ via Rojo) and runs them.
-- RunContext: Server. Auto-runs on play.
-- Exit codes (when invoked via run-in-roblox): 0 success, 1 failure.

local TestEZ = require(game:GetService("ReplicatedStorage").Packages.testez)
local ServerStorage = game:GetService("ServerStorage")

local function collectTestRoots(): { Instance }
    local roots = {}
    local testsContainer = ServerStorage:FindFirstChild("Tests")
    if testsContainer ~= nil then
        local unit = testsContainer:FindFirstChild("unit")
        local integration = testsContainer:FindFirstChild("integration")
        if unit ~= nil then table.insert(roots, unit) end
        if integration ~= nil then table.insert(roots, integration) end
    else
        warn("[runner] ServerStorage.Tests not found — Rojo project must map tests/ → ServerStorage/Tests")
    end
    return roots
end

local roots = collectTestRoots()
if #roots == 0 then
    warn("[runner] No test roots found. Failing.")
    if game.Workspace:GetAttribute("HeadlessTestExitCode") == nil then
        game.Workspace:SetAttribute("HeadlessTestExitCode", 1)
    end
    return
end

print(string.format("[runner] Running TestEZ across %d root(s)", #roots))
local results = TestEZ.TestBootstrap:run(roots, TestEZ.Reporters.TextReporter)

local exitCode: number
if results.failureCount > 0 or (results.errors ~= nil and #results.errors > 0) then
    exitCode = 1
    warn(string.format("[runner] FAIL — %d failures, %d errors", results.failureCount, results.errors and #results.errors or 0))
else
    exitCode = 0
    print(string.format("[runner] PASS — %d successes", results.successCount))
end

-- Surface exit code via attribute for run-in-roblox harness to read
game.Workspace:SetAttribute("HeadlessTestExitCode", exitCode)
