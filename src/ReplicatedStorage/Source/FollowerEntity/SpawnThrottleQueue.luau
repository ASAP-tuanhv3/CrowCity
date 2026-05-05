--!strict

--[[
	SpawnThrottleQueue.luau — Pure FIFO queue with per-frame dispatch limit
	Implements: TR-follower-entity-004 (4/frame spawn throttle, mobile thermal protection)
	GDD:        design/gdd/follower-entity.md §AC-8 + §AC-19 (throttle behaviour)
	ADR:        ADR-0007 §Three-Module Split (CrowdManagerClient owns the queue)
	Story:      production/epics/follower-entity/story-005-spawn-states-throttle.md

	DESIGN:
	  Single global queue across all crowds (NOT per-crowd) so that a player
	  triggering 80 absorbs in one frame does not starve other crowds — drains
	  at SPAWN_THROTTLE_PER_FRAME requests/frame, FIFO.

	  CrowdManagerClient instantiates ONE queue at init; calls dequeueUpTo()
	  at the start of each RenderStepped and dispatches the returned requests
	  via per-crowd FollowerEntityClient APIs.

	  Request payloads are opaque to the queue — caller defines shape:
	    { crowdId: string, spawnType: "FadeIn" | "SlideIn",
	      npcLastPosition: Vector3?, absorberHueColor: Color3? }
	  This keeps the queue testable without Roblox types.

	IMPLEMENTATION:
	  Head/tail integer indexing for O(1) enqueue + dequeue (avoids O(n)
	  table.remove(arr, 1) on every frame). When the queue drains to empty
	  (head > tail), reset both indices to 1 to bound table growth.
--]]

local SpawnThrottleQueue = {}
SpawnThrottleQueue.__index = SpawnThrottleQueue

--- Opaque request payload; queue does not inspect contents.
--- Defined as `{ [string]: any }` for static-typing flexibility — actual shape
--- is enforced by CrowdManagerClient (the only producer).
export type Request = { [string]: any }

export type ClassType = typeof(setmetatable(
	{} :: {
		_items: { Request },
		_head: number,
		_tail: number,
	},
	SpawnThrottleQueue
))

-- ---------------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------------

--- Creates a new empty throttle queue.
--- O(1) — pre-allocates no storage. First enqueue grows the underlying table.
---
--- @return ClassType
function SpawnThrottleQueue.new(): ClassType
	local self = setmetatable({} :: any, SpawnThrottleQueue)
	self._items = {}
	-- head: index of next item to dequeue; tail: index after last enqueued.
	-- Empty when head == tail.
	self._head = 1
	self._tail = 1
	return self
end

-- ---------------------------------------------------------------------------
-- enqueue
-- ---------------------------------------------------------------------------

--- Appends `request` to the back of the queue.
--- O(1) amortised. No copy of request — caller must not mutate after enqueue.
---
--- @param request  Request — opaque payload (see module-header doc for shape)
function SpawnThrottleQueue.enqueue(self: ClassType, request: Request): ()
	self._items[self._tail] = request
	self._tail += 1
end

-- ---------------------------------------------------------------------------
-- dequeueUpTo
-- ---------------------------------------------------------------------------

--- Removes and returns up to `maxN` requests from the front of the queue.
--- Returns fewer than `maxN` if the queue has fewer items.
--- Returns an empty table `{}` if the queue is empty (NOT nil).
---
--- After draining to empty (head reaches tail), both indices reset to 1 so
--- the underlying `_items` table does not grow unbounded over a long session.
---
--- @param maxN  number — typically FollowerVisualConfig.SPAWN_THROTTLE_PER_FRAME
--- @return { Request } — dispatched requests in FIFO order (front-most first)
function SpawnThrottleQueue.dequeueUpTo(self: ClassType, maxN: number): { Request }
	local dispatched: { Request } = {}
	local count = 0
	while count < maxN and self._head < self._tail do
		count += 1
		dispatched[count] = self._items[self._head]
		-- Clear the slot to allow GC of payload references in long-running queues.
		self._items[self._head] = nil :: any
		self._head += 1
	end
	-- If we drained fully, reset indices to 1 to bound _items growth.
	if self._head >= self._tail then
		self._head = 1
		self._tail = 1
	end
	return dispatched
end

-- ---------------------------------------------------------------------------
-- size
-- ---------------------------------------------------------------------------

--- Returns the current number of queued requests.
--- O(1).
---
--- @return number — count of pending requests
function SpawnThrottleQueue.size(self: ClassType): number
	return self._tail - self._head
end

-- ---------------------------------------------------------------------------
-- clear
-- ---------------------------------------------------------------------------

--- Removes all queued requests (used by Story 009 cap-drop edge case per AC-19:
--- "cap drops back to 0 mid-queue → remaining queued spawns are cancelled").
--- O(n) where n is the number of queued items (clears slots so GC can collect payloads).
function SpawnThrottleQueue.clear(self: ClassType): ()
	for i = self._head, self._tail - 1 do
		self._items[i] = nil :: any
	end
	self._head = 1
	self._tail = 1
end

return SpawnThrottleQueue
