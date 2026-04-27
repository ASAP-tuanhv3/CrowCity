--!strict

--[[
	RemoteValidator — server-side 4-check guard pattern per ADR-0010
	(§4-Check Guard Pattern + §Identity Trust Model + §Server-Time Authority +
	§Per-Player Rate Limit Policy).

	Every server-side `Network.connectEvent` handler that consumes a client-sent
	payload MUST execute these checks before any state mutation. Order is fixed:

	  1. checkIdentity   — engine-set Player only; never trust payload userId
	  2. checkState      — server-authoritative read of round/match state
	  3. checkParameters — typeof / shape validation of payload fields
	  4. checkRate       — per-(player, remoteName) token-bucket throttle

	Cheapest first; rate last so attackers cannot exhaust state-read budget by
	flooding handler entry. Caller idiom — short-circuit on first false:

	    Network.connectEvent(RemoteEventName.ChestInteract, function(player, chestId)
	        if not RemoteValidator.checkIdentity(player) then return end
	        if not RemoteValidator.checkState(function() return MatchState.get() == "Active" end) then return end
	        if not RemoteValidator.checkParameters({chestId = chestId}, {chestId = "string"}) then return end
	        if not RemoteValidator.checkRate(player, RemoteEventName.ChestInteract) then return end
	        -- mutate state here
	    end)

	Silent-rejection rule (ADR-0010 §Anti-Cheat by Ambiguity): no guard raises
	an exception or returns a client-visible error; rejections logged
	server-side only with `[RemoteValidator]` prefix for grep-ability.

	Placement: ServerStorage per ADR-0006 §Source Tree Map. Clients cannot require.
--]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimitConfig = require(ReplicatedStorage.Source.SharedConstants.RateLimitConfig)

local PAYLOAD_SIZE_DEFAULT_MAX_BYTES = 4096 -- ADR-0010 §Payload Size Budgets target

export type ParamSchema = { [string]: string }

type Bucket = {
	tokens: number,
	lastRefill: number,
}

local RemoteValidator = {}

-- Per-(player, remoteName) token-bucket state.
-- Outer key is Player instance (cleaned on PlayerRemoving); inner key is remoteName.
RemoteValidator._buckets = {} :: { [Player]: { [string]: Bucket } }

-- ----------------------------------------------------------------------
-- Internal helpers
-- ----------------------------------------------------------------------

local function logRejection(remoteName: string, reason: string, player: Player?)
	local userId = if player then tostring(player.UserId) else "<no-player>"
	warn(`[RemoteValidator] reject remote='{remoteName}' reason='{reason}' userId={userId}`)
end

local function getBucket(player: Player, remoteName: string): Bucket
	local playerBuckets = RemoteValidator._buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		RemoteValidator._buckets[player] = playerBuckets
	end

	local bucket = playerBuckets[remoteName]
	if not bucket then
		local config = RateLimitConfig[remoteName] or RateLimitConfig.default
		bucket = {
			tokens = config.burst,
			lastRefill = os.clock(),
		}
		playerBuckets[remoteName] = bucket
	end

	return bucket
end

local function typeCheckField(value: any, expectedType: string): boolean
	if expectedType == "Vector3" then
		return typeof(value) == "Vector3"
	elseif expectedType == "EnumItem" then
		return typeof(value) == "EnumItem"
	else
		return type(value) == expectedType
	end
end

-- ----------------------------------------------------------------------
-- Public API — 4-check guard pattern
-- ----------------------------------------------------------------------

function RemoteValidator.checkIdentity(player: any): boolean
	-- AC-3: only the engine-set `Player` argument is trusted. Payload-embedded
	-- userId fields are never consulted here. typeof("Player") catches both
	-- nil and non-Player passes (table, string, number, payload-derived data).
	if typeof(player) ~= "Instance" then
		logRejection("<unknown>", "checkIdentity: not an Instance")
		return false
	end
	if not (player :: Instance):IsA("Player") then
		logRejection("<unknown>", "checkIdentity: not a Player")
		return false
	end
	return true
end

function RemoteValidator.checkState(predicate: () -> boolean): boolean
	-- AC + ADR-0010: caller-supplied predicate reads server-authoritative state.
	-- Predicate is wrapped in pcall so a faulty predicate cannot crash the handler;
	-- error in predicate → rejection (fail-closed).
	local ok, result = pcall(predicate)
	if not ok then
		logRejection("<unknown>", `checkState: predicate raised: {tostring(result)}`)
		return false
	end
	if result ~= true then
		logRejection("<unknown>", "checkState: predicate returned false")
		return false
	end
	return true
end

function RemoteValidator.checkParameters(payload: { [string]: any }, schema: ParamSchema): boolean
	-- AC-5: every schema field must be present with the right type;
	-- payload must NOT carry any unexpected fields (whitelist semantics).
	if type(payload) ~= "table" then
		logRejection("<unknown>", "checkParameters: payload is not a table")
		return false
	end

	-- Every schema field present with correct type.
	for fieldName, expectedType in schema do
		local value = payload[fieldName]
		if value == nil then
			logRejection("<unknown>", `checkParameters: missing field '{fieldName}'`)
			return false
		end
		if not typeCheckField(value, expectedType) then
			local actualType = typeof(value)
			logRejection("<unknown>", `checkParameters: field '{fieldName}' expected '{expectedType}' got '{actualType}'`)
			return false
		end
	end

	-- No extra unexpected fields in payload.
	for fieldName, _ in payload do
		if schema[fieldName] == nil then
			logRejection("<unknown>", `checkParameters: unexpected field '{fieldName}'`)
			return false
		end
	end

	return true
end

function RemoteValidator.checkRate(player: Player, remoteName: string): boolean
	-- AC-4: token-bucket per (player, remoteName). Server-time-authoritative
	-- via os.clock() per ADR-0010 §Server-Time Authority — no client clock trust.
	local config = RateLimitConfig[remoteName] or RateLimitConfig.default
	local bucket = getBucket(player, remoteName)

	local now = os.clock()
	local elapsed = now - bucket.lastRefill
	bucket.tokens = math.min(config.burst, bucket.tokens + (elapsed * config.rate))
	bucket.lastRefill = now

	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end

	logRejection(remoteName, "checkRate: bucket exhausted", player)
	return false
end

function RemoteValidator.checkPayloadSize(payload: any, maxBytes: number?): boolean
	-- AC-6: size budget per ADR-0010 §Payload Size Budgets (4 KB target, 16 KB cap).
	-- For buffers, use buffer.len directly. For tables, approximate via JSON-encode
	-- byte length — not exact wire-format size but conservative within an order of magnitude.
	local limit = maxBytes or PAYLOAD_SIZE_DEFAULT_MAX_BYTES
	local size: number

	if typeof(payload) == "buffer" then
		size = buffer.len(payload :: buffer)
	elseif type(payload) == "string" then
		size = #payload
	else
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
		if not ok then
			logRejection("<unknown>", `checkPayloadSize: JSONEncode failed: {tostring(encoded)}`)
			return false
		end
		size = #encoded
	end

	if size > limit then
		logRejection("<unknown>", `checkPayloadSize: {size}B over limit {limit}B`)
		return false
	end
	return true
end

-- ----------------------------------------------------------------------
-- Lifecycle: per-player bucket cleanup on PlayerRemoving
-- ----------------------------------------------------------------------

local function onPlayerRemoving(player: Player)
	RemoteValidator._buckets[player] = nil
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ----------------------------------------------------------------------
-- Test-only API — _prefixed per project convention; NOT for production callers.
-- ----------------------------------------------------------------------

function RemoteValidator._resetForTest()
	RemoteValidator._buckets = {}
end

return RemoteValidator
