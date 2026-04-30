--!strict

--[[
	CrowdStateServer — CountChanged BindableEvent unit tests.
	Path: tests/unit/crowd-state-server/countchanged.spec.luau
	Implements: CSM story-002 ACs:
	  AC-24 (CountChanged fires with {crowdId, oldCount, newCount, deltaSource})
	  AC-24 edge (effective_delta == 0 → no fire: delta=0, ceiling no-op, floor no-op)
	  AC-15 (4 sequential successful calls → 4 CountChanged fires, in call order)
	  Clamp-truncated delta fires once with pre/post-clamp counts (not double-fire)
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	local function makeRecord(crowdId: string, count: number): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = count,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer.CountChanged BindableEvent", function()
		local recorded: { { crowdId: string, oldCount: number, newCount: number, deltaSource: string } }
		local connection: RBXScriptConnection? = nil

		beforeEach(function()
			CrowdStateServer._resetForTests()
			CrowdStateServer._setTestFanoutInterceptor(function() end)
			recorded = {}
			connection = CrowdStateServer.CountChanged.Event:Connect(
				function(crowdId: string, oldCount: number, newCount: number, deltaSource: string)
					table.insert(recorded, {
						crowdId = crowdId,
						oldCount = oldCount,
						newCount = newCount,
						deltaSource = deltaSource,
					})
				end
			)
		end)

		afterEach(function()
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end
		end)

		-- AC-24: fires exactly once with correct payload on a normal delta.
		it("AC-24: fires {crowdId, oldCount=50, newCount=51, deltaSource='Absorb'}", function()
			CrowdStateServer.create("u1", makeRecord("u1", 50))
			CrowdStateServer.updateCount("u1", 1, "Absorb")
			expect(#recorded).to.equal(1)
			expect(recorded[1].crowdId).to.equal("u1")
			expect(recorded[1].oldCount).to.equal(50)
			expect(recorded[1].newCount).to.equal(51)
			expect(recorded[1].deltaSource).to.equal("Absorb")
		end)

		-- AC-24 edge: delta=0 → effective_delta == 0 → no fire.
		it("AC-24 edge: delta=0 → no fire (effective_delta == 0)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 50))
			CrowdStateServer.updateCount("u1", 0, "Absorb")
			expect(#recorded).to.equal(0)
		end)

		-- AC-24 edge: count=300, delta=+1 → clamp absorbs entire delta → no fire.
		it("AC-24 edge: count=300 + delta=+1 → no fire (clamp absorbs entire delta)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 300))
			CrowdStateServer.updateCount("u1", 1, "Absorb")
			expect(#recorded).to.equal(0)
		end)

		-- AC-24 edge: count=1, delta=-1 → floor absorbs entire delta → no fire.
		it("AC-24 edge: count=1 + delta=-1 → no fire (floor absorbs entire delta)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 1))
			CrowdStateServer.updateCount("u1", -1, "Relic")
			expect(#recorded).to.equal(0)
		end)

		-- AC-15: 4 sequential successful updateCount calls → 4 CountChanged fires, in call order.
		it("AC-15 every successful updateCount fires once (4 sequential calls = 4 fires)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 3))
			CrowdStateServer.updateCount("u1", -2, "Collision")
			CrowdStateServer.updateCount("u1", 5, "Relic")
			CrowdStateServer.updateCount("u1", 1, "Absorb")
			CrowdStateServer.updateCount("u1", 2, "Chest")
			expect(#recorded).to.equal(4)
			-- Order is preserved
			expect(recorded[1].deltaSource).to.equal("Collision")
			expect(recorded[2].deltaSource).to.equal("Relic")
			expect(recorded[3].deltaSource).to.equal("Absorb")
			expect(recorded[4].deltaSource).to.equal("Chest")
		end)

		-- Clamp-truncated delta: fires once; oldCount = pre-clamp, newCount = post-clamp.
		-- No double-fire for the discarded portion (AC story-002 acceptance criterion).
		it("clamp-truncated delta still fires once (oldCount = pre-clamp, newCount = post)", function()
			CrowdStateServer.create("u1", makeRecord("u1", 298))
			CrowdStateServer.updateCount("u1", 5, "Absorb")  -- ceiling clamps to 300
			expect(#recorded).to.equal(1)
			expect(recorded[1].oldCount).to.equal(298)
			expect(recorded[1].newCount).to.equal(300)  -- post-clamp
		end)
	end)
end
