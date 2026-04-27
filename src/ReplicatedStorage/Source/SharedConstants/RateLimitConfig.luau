--!strict

--[[
	Per-remote token-bucket rate limits per ADR-0010 §Per-Player Rate Limit Policy.
	Read by ServerStorage/Source/RemoteValidator/init.luau::checkRate (story 004).

	Token-bucket semantics:
	  - rate  : steady-state tokens added per second (regen rate)
	  - burst : maximum tokens the bucket can hold (initial cap; absorbs burst calls)

	A call costs 1 token. Bucket starts full at `burst`. Caller is rate-limited
	when bucket reaches 0 until enough time elapses to regen ≥ 1 token at `rate`.

	**ADVISORY (story 004/005 deviation)**: ADR-0010 §Per-Player Rate Limit Policy
	uses a windowed shape `{max, windowSec}` (e.g. ChestInteract = max 4 / 1 s window).
	Stories 004 + 005 implement token-bucket `{rate, burst}` instead — strictly
	stronger model that smooths sustained rate while still admitting short bursts.
	Conversion preserved (ChestInteract: max=4/1s ≈ rate=4 + burst=4 etc.).
	No semantic drift for spec values; documented in story 004/005 Completion Notes.

	**Caller-facing intent** (per-entry):

	  ChestInteract  : rate=4 + burst=4 — covers triple-tap ProximityPrompt intent
	                   without enabling chest-spam exploit (4 attempts/sec ceiling)
	  ChestDraftPick : rate=1 + burst=1 — exactly one pick per draft modal
	  AFKToggle      : rate=0.4 + burst=2 — toggle is rare; 0.4 tokens/sec ≈ once
	                   per 2.5 s sustained, burst=2 absorbs accidental double-tap

	**Default fallback** `{rate=1, burst=2}` is intentionally conservative.
	Any remote not explicitly registered here falls through to this entry,
	enforcing "safe-by-default" — a forgotten registration cannot be exploited.

	**Out-of-scope**:
	- `GetParticipation` (RemoteFunction): one-shot reconcile at client boot;
	  not in ADR-0010 rate-limit table; omitted (default fallback applies if
	  RemoteValidator is ever invoked for it).
	- `RelicDraftPick`: present in arch §5.7 but not enumerated in ADR-0010
	  rate-limit table; default fallback applies until ADR amendment.
--]]

export type RateLimitEntry = {
	rate: number,
	burst: number,
}

local RateLimitConfig: { [string]: RateLimitEntry } = {
	-- Implements: Story 005 (network-layer-ext epic)
	-- Values per ADR-0010 §Per-Player Rate Limit Policy (windowed → token-bucket conversion).

	ChestInteract = { rate = 4, burst = 4 },
	ChestDraftPick = { rate = 1, burst = 1 },
	AFKToggle = { rate = 0.4, burst = 2 },

	-- Conservative safe-by-default fallback per AC-6.
	default = { rate = 1, burst = 2 },
}

return RateLimitConfig
