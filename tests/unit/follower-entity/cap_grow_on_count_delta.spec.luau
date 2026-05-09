--!strict

--[[
	cap_grow_on_count_delta.spec.luau — Story 6-1 unit tests.
	Path: tests/unit/follower-entity/cap_grow_on_count_delta.spec.luau

	Sprint 6 task 6-1 (no story file): "Client cap-grow on broadcast count
	delta — visual absorb loop end-to-end".

	Verifies that FollowerEntityClient._update tracks broadcast-count deltas
	and calls setPoolSize(record.count) whenever the value changes. This is
	the closing link of the visual absorb loop:
	  AbsorbSystem updateCount(+1) → CSM Phase 8 broadcast →
	  CrowdStateClient mirror → FollowerEntityClient._update → setPoolSize →
	  cap-grow callback enqueues N FadeIn spawns.

	Coverage:
	  - Initial count → setPoolSize called once with that value
	  - Same count next tick → no extra setPoolSize call (no-op)
	  - Increased count → setPoolSize called with new value
	  - Decreased count → setPoolSize called with new value
	  - nil count → no call (defensive)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FollowerEntityClient = require(ReplicatedStorage.Source.FollowerEntity.Client)
local Janitor = require(ReplicatedStorage.Packages.janitor)

return function()
	-- -------------------------------------------------------------------------
	-- Helpers
	-- -------------------------------------------------------------------------

	--- Build a FollowerEntityClient with a controllable getter + cap-grow spy.
	--- Returns (client, getCallCount, getRequestedSizes, setRecord).
	local function buildClient()
		local janitor = Janitor.new()
		local client = FollowerEntityClient.new("crowdA", janitor)

		-- Cap-grow spy. Tracks every call (count of N grow requests).
		local capGrowCallCount = 0
		client:setCapGrowCallback(function(_growCount: number)
			capGrowCallCount += 1
		end)

		-- Pool size spy via setPoolSize wrapper. Capture every n passed.
		-- Patch by replacing the method on the instance only.
		local sizeCalls: { number } = {}
		local originalSetPoolSize = client.setPoolSize
		;(client :: any).setPoolSize = function(self: any, n: number): ()
			table.insert(sizeCalls, n)
			originalSetPoolSize(self, n)
		end

		-- Cross-crowd state getter that returns a controllable record.
		local currentRecord: any = nil
		client:setCrowdStateGetter(function(_id: string): any
			return currentRecord
		end)
		local function setRecord(rec: any)
			currentRecord = rec
		end

		-- Seed parallel arrays so _update doesn't early-return on
		-- `#self._positions == 0`. We don't actually need these to be
		-- coherent — just non-empty.
		;(client :: any)._positions = { Vector3.zero }
		;(client :: any)._followerStates = { "Active" }
		;(client :: any)._d = { 0 }
		;(client :: any)._lastYBob = { 0 }
		;(client :: any)._swayPhaseOffset = { 0 }
		;(client :: any)._isStandstill = { false }
		;(client :: any)._spawnElapsed = { 0 }
		;(client :: any)._spawnOffsets = { Vector3.zero }
		;(client :: any)._despawnElapsed = { 0 }

		return client, function() return capGrowCallCount end, sizeCalls, setRecord
	end

	local function makeRecord(count: number?): any
		return {
			crowdId = "crowdA",
			position = Vector3.zero,
			count = count,
			hue = 1,
			state = "Active",
			radius = 5.0,
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("FollowerEntityClient — Story 6-1 cap-grow on broadcast count delta", function()
		it("first tick with count=10: setPoolSize(10) called once", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(10))

			client:_update(1 / 60, 0)

			expect(#sizeCalls).to.equal(1)
			expect(sizeCalls[1]).to.equal(10)
		end)

		it("same count next tick: setPoolSize NOT called again (no-op)", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(10))

			client:_update(1 / 60, 0)
			expect(#sizeCalls).to.equal(1)

			-- Second tick: same count, no change.
			client:_update(1 / 60, 1 / 60)
			expect(#sizeCalls).to.equal(1)  -- unchanged
		end)

		it("count increases 10 → 12: setPoolSize(12) called second tick", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(10))
			client:_update(1 / 60, 0)

			-- Broadcast delta: count grew from 10 to 12.
			setRecord(makeRecord(12))
			client:_update(1 / 60, 1 / 60)

			expect(#sizeCalls).to.equal(2)
			expect(sizeCalls[1]).to.equal(10)
			expect(sizeCalls[2]).to.equal(12)
		end)

		it("count decreases 10 → 7: setPoolSize(7) called second tick", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(10))
			client:_update(1 / 60, 0)

			setRecord(makeRecord(7))
			client:_update(1 / 60, 1 / 60)

			expect(#sizeCalls).to.equal(2)
			expect(sizeCalls[2]).to.equal(7)
		end)

		it("monotonic absorb sequence 10→11→12→13: 4 setPoolSize calls", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			for n = 10, 13 do
				setRecord(makeRecord(n))
				client:_update(1 / 60, n)
			end

			expect(#sizeCalls).to.equal(4)
			expect(sizeCalls[1]).to.equal(10)
			expect(sizeCalls[2]).to.equal(11)
			expect(sizeCalls[3]).to.equal(12)
			expect(sizeCalls[4]).to.equal(13)
		end)

		it("nil count in record: setPoolSize NOT called (defensive guard)", function()
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(nil))

			client:_update(1 / 60, 0)

			expect(#sizeCalls).to.equal(0)
		end)

		it("explicit setPoolSize call syncs _lastSeenCount: subsequent same count tick = no-op", function()
			-- Mirrors CrowdManagerClient initial seed: setPoolSize(record.count)
			-- happens BEFORE first _update fires. Story 6-1 fix in setPoolSize
			-- syncs _lastSeenCount so the per-frame check sees no delta.
			local client, _capCount, sizeCalls, setRecord = buildClient()
			setRecord(makeRecord(10))

			-- Initial seed (CrowdManagerClient pattern at line 155).
			client:setPoolSize(10)
			expect(#sizeCalls).to.equal(1)

			-- First _update should NOT re-fire setPoolSize (count unchanged).
			client:_update(1 / 60, 0)
			expect(#sizeCalls).to.equal(1)
		end)
	end)
end
