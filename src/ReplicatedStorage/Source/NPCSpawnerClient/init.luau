--!strict

--[[
	NPCSpawnerClient — client-side mirror pool for the 300-Part NPC pool.
	Path: ReplicatedStorage/Source/NPCSpawnerClient/init.luau
	Implements: Story 5-9 client mirror (ADR-0008 §Replication Contract)

	Responsibilities:
	  - On NpcPoolBootstrap (reliable RemoteEvent): spawn 300 client-only
	    mirror Parts in a Workspace folder keyed by npcId.
	  - On each NpcStateBroadcast (UREvent): decode 8-byte buffer records
	    and apply CFrame + Transparency deltas to the matching mirror Part.
	  - On round-end (or Bootstrap re-receipt): park all mirror Parts
	    (Transparency=1, CFrame sentinel) to reset cycle.

	Buffer layout (matches server NPCSpawner/init.luau §Replication Contract):
	  offset 0: npcId  u8    (0..299)
	  offset 1: posX   u16   (i16 + 32768 offset-encoded)
	  offset 3: posZ   u16   (i16 + 32768 offset-encoded)
	  offset 5: flags  u8    (bit 0 = active, bit 1 = transparency-changing)
	  offset 6: transp u8    (0=opaque .. 255=invisible; valid when bit 1 set)
	  offset 7: reserved u8

	Singleton module: module-level state only. No .new() constructor.
	Public surface:
	  NPCSpawnerClient.start(deps?) — subscribe to remotes, create mirror folder.
	  NPCSpawnerClient.stop()       — park all Parts, disconnect connections.
	  NPCSpawnerClient._getMirrorParts() — TEST ONLY: returns mirror parts map.

	Dependency injection (for testing):
	  deps.network — mock Network module (default: require ReplicatedStorage.Source.Network)

	Source: ADR-0008 §Replication Contract; Story 009 client mirror spec.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ---------------------------------------------------------------------------
-- Buffer layout constants (must match server NPCSpawner/init.luau exactly)
-- ---------------------------------------------------------------------------

local BROADCAST_RECORD_SIZE = 8
local BROADCAST_OFFSET_NPCID  = 0
local BROADCAST_OFFSET_POSX   = 1
local BROADCAST_OFFSET_POSZ   = 3
local BROADCAST_OFFSET_FLAGS  = 5
local BROADCAST_OFFSET_TRANSP = 6

-- Y-position for all NPC mirror Parts (MVP: NPCs are ground-level, Y=0).
local NPC_MIRROR_Y = 0

-- Sentinel CFrame used to park mirror Parts between rounds.
local PARK_SENTINEL = CFrame.new(0, -10000, 0)

-- Pool size — must match server NPC_POOL_SIZE.
local NPC_POOL_SIZE = 300

-- Name of the Workspace folder holding client-only mirror Parts.
local MIRROR_FOLDER_NAME = "NpcMirrorPool"

-- ---------------------------------------------------------------------------
-- Module-level state
-- ---------------------------------------------------------------------------

--- Connections accumulated during start(). All disconnected by stop().
local _connections: { RBXScriptConnection } = {}

--- Map: npcId string ("n0".."n299") → client mirror Part.
--- Populated by _onBootstrap; keyed by the same "nN" convention as server.
local _mirrorParts: { [string]: Part } = {}

--- Workspace folder holding the mirror Parts. Created by _initMirrorFolder().
local _mirrorFolder: Folder? = nil

--- Whether start() has been called and not yet stopped.
local _running = false

--- Injected Network module. Default: lazy-required on first start().
local _network: any = nil

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Returns the Network module (DI override or real).
local function getNetwork(): any
	if _network ~= nil then
		return _network
	end
	_network = require(ReplicatedStorage.Source.Network)
	return _network
end

--- Returns or creates the NpcMirrorPool folder in Workspace.
local function _initMirrorFolder(): Folder
	local existing = Workspace:FindFirstChild(MIRROR_FOLDER_NAME)
	if existing ~= nil and existing:IsA("Folder") then
		return existing :: Folder
	end
	local folder = Instance.new("Folder")
	folder.Name = MIRROR_FOLDER_NAME
	folder.Parent = Workspace
	_mirrorFolder = folder
	return folder
end

--- Creates a single bare mirror Part with the mandated flag set.
--- Parented to the mirror folder; initially parked at sentinel.
--- Part flag set matches server's bare-Part convention (ADR-0001 / ADR-0008):
---   Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false,
---   CastShadow=false, Transparency=1 (parked).
local function _createMirrorPart(folder: Folder, npcId: string): Part
	local part = Instance.new("Part")
	part.Name = "NpcMirror_" .. npcId
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 5, 2)
	part.Color = Color3.fromRGB(255, 140, 0)
	part.CFrame = PARK_SENTINEL
	part.Parent = folder
	return part
end

--- Parks all mirror Parts at the sentinel position (Transparency=1).
--- Called on Bootstrap receipt (cycle reset) and on stop().
local function _parkAll(): ()
	for _, part in pairs(_mirrorParts) do
		part.Transparency = 1
		part.CFrame = PARK_SENTINEL
	end
end

--- Handles NpcPoolBootstrap reliable event.
--- On first receipt: creates 300 mirror Parts. On re-receipt: parks existing parts.
--- Then applies the active-NPC snapshot from the payload.
---
--- payload format (reliable, table): { { npcId: string, posX: number, posZ: number,
---   transparency: number } }
local function _onBootstrap(payload: any): ()
	local folder = _initMirrorFolder()

	-- If Parts don't exist yet, pre-create all 300.
	if next(_mirrorParts) == nil then
		for i = 0, NPC_POOL_SIZE - 1 do
			local npcId = "n" .. tostring(i)
			local part = _createMirrorPart(folder, npcId)
			_mirrorParts[npcId] = part
		end
	end

	-- Park everything first (cycle reset).
	_parkAll()

	-- Apply the initial snapshot from Bootstrap payload.
	if typeof(payload) ~= "table" then
		return
	end
	for _, record in ipairs(payload) do
		if typeof(record) ~= "table" then
			continue
		end
		local npcId = record.npcId
		local posX = record.posX
		local posZ = record.posZ
		local transparency = record.transparency

		if typeof(npcId) ~= "string" then
			continue
		end
		local part = _mirrorParts[npcId]
		if part == nil then
			continue
		end

		part.CFrame = CFrame.new(
			typeof(posX) == "number" and posX or 0,
			NPC_MIRROR_Y,
			typeof(posZ) == "number" and posZ or 0
		)
		part.Transparency = typeof(transparency) == "number" and math.clamp(transparency, 0, 1) or 0
	end
end

--- Handles NpcStateBroadcast UREvent.
--- Decodes the 8-byte-per-NPC buffer and applies CFrame + Transparency to mirror Parts.
---
--- Buffer layout (per ADR-0008 §Replication Contract):
---   offset 0: npcId  u8
---   offset 1: posX   u16 (i16 offset-encoded: stored value - 32768 = real value)
---   offset 3: posZ   u16
---   offset 5: flags  u8  (bit 0 = active, bit 1 = transparency-changing)
---   offset 6: transp u8  (0=opaque .. 255=invisible)
---   offset 7: reserved
local function _onStateBroadcast(payload: any): ()
	if typeof(payload) ~= "buffer" then
		return
	end

	local bufSize = buffer.len(payload)
	local recordCount = bufSize // BROADCAST_RECORD_SIZE

	for i = 0, recordCount - 1 do
		local base = i * BROADCAST_RECORD_SIZE

		local idNum   = buffer.readu8(payload,  base + BROADCAST_OFFSET_NPCID)
		local qxU     = buffer.readu16(payload, base + BROADCAST_OFFSET_POSX)
		local qzU     = buffer.readu16(payload, base + BROADCAST_OFFSET_POSZ)
		local flags   = buffer.readu8(payload,  base + BROADCAST_OFFSET_FLAGS)
		local transpU = buffer.readu8(payload,  base + BROADCAST_OFFSET_TRANSP)

		-- Decode i16 from offset-encoded u16.
		local posX = qxU - 32768
		local posZ = qzU - 32768

		-- Decode transparency (0=opaque, 255=invisible → 0..1 float).
		local transparency = transpU / 255

		-- Determine which flags are set.
		-- bit 0 = active, bit 1 = transparency-changing
		local isActive = (bit32.band(flags, 1) ~= 0)
		local transparencyChanging = (bit32.band(flags, 2) ~= 0)

		local npcId = "n" .. tostring(idNum)
		local part = _mirrorParts[npcId]
		if part == nil then
			continue
		end

		if isActive then
			part.CFrame = CFrame.new(posX, NPC_MIRROR_Y, posZ)
		end

		-- Apply transparency if the flag signals it is changing (fade in progress),
		-- or always apply to keep in sync with server state.
		if transparencyChanging then
			part.Transparency = transparency
		elseif isActive then
			-- Ensure active NPCs are fully opaque when not mid-fade.
			part.Transparency = 0
		else
			-- Inactive NPC (should not normally appear in broadcast — park defensively).
			part.Transparency = 1
			part.CFrame = PARK_SENTINEL
		end
	end
end

-- ---------------------------------------------------------------------------
-- Public module
-- ---------------------------------------------------------------------------

local NPCSpawnerClient = {}

--- Starts the client mirror: subscribes to NpcPoolBootstrap (reliable) and
--- NpcStateBroadcast (UREvent). Creates the NpcMirrorPool Workspace folder.
---
--- Idempotent — second call without stop() is a no-op.
---
--- Dependency injection:
---   deps.network — mock Network module (for testing; default: real Network)
---
--- Source: ADR-0008 §Replication Contract; Story 009 §Client Mirror.
function NPCSpawnerClient.start(deps: { network: any? }?): ()
	if _running then
		return
	end
	_running = true

	if deps ~= nil and deps.network ~= nil then
		_network = deps.network
	end

	local net = getNetwork()

	-- Subscribe to reliable Bootstrap event (fired once on join + on createAll).
	local bootstrapConn = net.connectEvent(
		net.RemoteEvents.NpcPoolBootstrap,
		_onBootstrap,
		net.t.any
	)
	table.insert(_connections, bootstrapConn)

	-- Subscribe to UREvent NpcStateBroadcast (15 Hz delta updates).
	local broadcastConn = net.connectUnreliableEvent(
		net.UnreliableRemoteEvents.NpcStateBroadcast,
		_onStateBroadcast,
		net.t.any
	)
	table.insert(_connections, broadcastConn)
end

--- Stops the client mirror: disconnects all remote connections, parks all
--- mirror Parts. Does NOT destroy the Parts (retain for next round).
---
--- Idempotent — second call without start() is a no-op.
---
--- Source: ADR-0008 §Replication Contract; Story 009 §Janitor Cleanup.
function NPCSpawnerClient.stop(): ()
	if not _running then
		return
	end
	_running = false

	-- Disconnect all remote subscriptions.
	for _, conn in ipairs(_connections) do
		if conn ~= nil then
			conn:Disconnect()
		end
	end
	_connections = {}

	-- Park all mirror Parts at sentinel position.
	_parkAll()
end

-- ---------------------------------------------------------------------------
-- Test-only surface (never call from production code)
-- ---------------------------------------------------------------------------

--- **TEST ONLY** — never call from production code.
--- Returns the internal _mirrorParts map: { [npcId]: Part }.
--- Tests use this to inspect CFrame + Transparency after applying deltas.
function NPCSpawnerClient._getMirrorParts(): { [string]: Part }
	return _mirrorParts
end

--- **TEST ONLY** — never call from production code.
--- Resets all module state for TestEZ isolation.
--- Disconnects connections, clears parts map, resets DI override.
function NPCSpawnerClient._resetForTests(): ()
	for _, conn in ipairs(_connections) do
		if conn ~= nil then
			conn:Disconnect()
		end
	end
	_connections = {}
	_mirrorParts = {}
	_mirrorFolder = nil
	_running = false
	_network = nil
end

--- **TEST ONLY** — exposes _onBootstrap for direct invocation in unit tests.
function NPCSpawnerClient._testOnBootstrap(payload: any): ()
	_onBootstrap(payload)
end

--- **TEST ONLY** — exposes _onStateBroadcast for direct invocation in unit tests.
function NPCSpawnerClient._testOnStateBroadcast(payload: any): ()
	_onStateBroadcast(payload)
end

return NPCSpawnerClient
