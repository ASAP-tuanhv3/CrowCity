--!strict

--[[
	CrowdStateBroadcast buffer codec — Story 003 (network-layer-ext epic).

	Per architecture.md §5.7 + ADR-0001 Rule 10 (amendment 2026-04-24):
	CrowdStateBroadcast MUST use Luau buffer encoding for MVP. Per-entry layout
	is exactly 30 bytes; ≤12 crowds per server; broadcast at 15 Hz; ~5.4 KB/s/client
	steady state per ADR-0003 §Network sub-allocation.

	Per-crowd byte layout (little-endian — Luau buffer default):

	  Offset  Size  Field      Type   Notes
	  ──────  ────  ─────────  ─────  ────────────────────────────────────────
	      0     8   crowdId    u64    UserId-encoded; split as low u32 + high u32
	      8     2   tick       u16    server-tick wraparound counter
	     10    12   position   3xf32  Vector3 components: x at 10, y at 14, z at 18
	     22     4   radius     f32    crowd radius (studs)
	     26     2   count      u16    follower count (0..65535)
	     28     1   hue        u8     palette index (0..255)
	     29     1   state      u8     1=Active, 2=GraceWindow, 3=Eliminated

	Total: 30 bytes per record. N records → buffer of length N*30.
	No header. No padding. Decoder rejects non-30-multiple lengths.

	Validation (encoder): records with count > u16::MAX or state ∉ {1,2,3}
	are silently skipped per ADR-0010 silent-rejection rule; remainder
	encoded normally. One warn log per skip with the offending field.

	Validation (decoder): malformed buffer (non-30-multiple length) is
	full-payload reject — returns empty array + one warn. Per ADR-0001
	desync tolerance, drop the tick and wait for next broadcast.

	Engine API (HIGH risk per VERSION.md): Luau `buffer` is post-cutoff.
	Reference: docs/engine-reference/roblox/replication-best-practices.md §buffer.
--]]

local CrowdState = {}

-- Layout constants — single source of truth; consumers must read recordSize().
local RECORD_SIZE = 30

local OFFSET_CROWDID_LOW = 0
local OFFSET_CROWDID_HIGH = 4
local OFFSET_TICK = 8
local OFFSET_POSITION_X = 10
local OFFSET_POSITION_Y = 14
local OFFSET_POSITION_Z = 18
local OFFSET_RADIUS = 22
local OFFSET_COUNT = 26
local OFFSET_HUE = 28
local OFFSET_STATE = 29

local U16_MAX = 65535
local U8_MAX = 255

-- Valid state enum per ADR-0001 §State Machine.
local STATE_ACTIVE = 1
local STATE_GRACE_WINDOW = 2
local STATE_ELIMINATED = 3

export type CrowdRecord = {
	crowdId: number, -- u64 in buffer; Luau number is f64 (safe for Roblox UserIds < 2^53)
	tick: number, -- u16 wraparound
	position: Vector3,
	radius: number,
	count: number, -- 0..65535
	hue: number, -- 0..255 palette index
	state: number, -- 1 | 2 | 3
}

-- ----------------------------------------------------------------------
-- Internal helpers
-- ----------------------------------------------------------------------

-- Split a 64-bit non-negative integer into low and high u32 halves for
-- buffer encoding. Roblox UserIds are well within Luau's f64 safe-integer
-- range (2^53), so this split is bit-exact.
local function splitU64(n: number): (number, number)
	local high = math.floor(n / 4294967296)
	local low = n - (high * 4294967296)
	return low, high
end

local function joinU64(low: number, high: number): number
	return (high * 4294967296) + low
end

local function isValidState(state: number): boolean
	return state == STATE_ACTIVE or state == STATE_GRACE_WINDOW or state == STATE_ELIMINATED
end

-- ----------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------

function CrowdState.recordSize(): number
	return RECORD_SIZE
end

function CrowdState.encode(records: { CrowdRecord }): buffer
	-- First pass: filter records that pass validation. Logs one warn per skip.
	local valid: { CrowdRecord } = {}
	for _, record in records do
		if record.count < 0 or record.count > U16_MAX then
			warn(`[CrowdState.encode] skipping record crowdId={record.crowdId}: count {record.count} out of u16 range [0, {U16_MAX}]`)
			continue
		end
		if not isValidState(record.state) then
			warn(`[CrowdState.encode] skipping record crowdId={record.crowdId}: state {record.state} not in [1,2,3]`)
			continue
		end
		if record.hue < 0 or record.hue > U8_MAX then
			warn(`[CrowdState.encode] skipping record crowdId={record.crowdId}: hue {record.hue} out of u8 range [0, {U8_MAX}]`)
			continue
		end
		table.insert(valid, record)
	end

	local buf = buffer.create(#valid * RECORD_SIZE)

	for i, record in valid do
		local base = (i - 1) * RECORD_SIZE
		local low, high = splitU64(record.crowdId)
		buffer.writeu32(buf, base + OFFSET_CROWDID_LOW, low)
		buffer.writeu32(buf, base + OFFSET_CROWDID_HIGH, high)
		buffer.writeu16(buf, base + OFFSET_TICK, record.tick)
		buffer.writef32(buf, base + OFFSET_POSITION_X, record.position.X)
		buffer.writef32(buf, base + OFFSET_POSITION_Y, record.position.Y)
		buffer.writef32(buf, base + OFFSET_POSITION_Z, record.position.Z)
		buffer.writef32(buf, base + OFFSET_RADIUS, record.radius)
		buffer.writeu16(buf, base + OFFSET_COUNT, record.count)
		buffer.writeu8(buf, base + OFFSET_HUE, record.hue)
		buffer.writeu8(buf, base + OFFSET_STATE, record.state)
	end

	return buf
end

function CrowdState.decode(buf: buffer): { CrowdRecord }
	local len = buffer.len(buf)

	-- Reject non-30-multiple lengths per AC-7 (full-payload reject + warn).
	if len % RECORD_SIZE ~= 0 then
		warn(`[CrowdState.decode] malformed buffer length {len} not a multiple of {RECORD_SIZE}; dropping payload`)
		return {}
	end

	local n = len // RECORD_SIZE
	local records: { CrowdRecord } = table.create(n)

	for i = 1, n do
		local base = (i - 1) * RECORD_SIZE
		local low = buffer.readu32(buf, base + OFFSET_CROWDID_LOW)
		local high = buffer.readu32(buf, base + OFFSET_CROWDID_HIGH)
		records[i] = {
			crowdId = joinU64(low, high),
			tick = buffer.readu16(buf, base + OFFSET_TICK),
			position = Vector3.new(
				buffer.readf32(buf, base + OFFSET_POSITION_X),
				buffer.readf32(buf, base + OFFSET_POSITION_Y),
				buffer.readf32(buf, base + OFFSET_POSITION_Z)
			),
			radius = buffer.readf32(buf, base + OFFSET_RADIUS),
			count = buffer.readu16(buf, base + OFFSET_COUNT),
			hue = buffer.readu8(buf, base + OFFSET_HUE),
			state = buffer.readu8(buf, base + OFFSET_STATE),
		}
	end

	return records
end

return CrowdState
