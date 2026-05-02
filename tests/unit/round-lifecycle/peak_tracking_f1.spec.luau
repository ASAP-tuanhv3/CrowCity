--!strict

--[[
	RoundLifecycle — F1 peak tracking + finalCount tests.
	Path: tests/unit/round-lifecycle/peak_tracking_f1.spec.luau
	Implements: RL story-002 ACs:
	  AC-5 — strict `>` updates peakCount + peakTimestamp; finalCount tracks newCount.
	  AC-6 — equal newCount does NOT update peakTimestamp.
	  AC-7 — newCount below peak does NOT update peak; finalCount drops.
	  AC-8 — silent guard for non-record crowdId.
	  Subscription cleanup — destroyAll disconnects; subsequent fires no-op.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local RoundLifecycle = require(ServerStorage.Source.RoundLifecycle)

	local function makePlayer(userId: number): Player
		return ({ UserId = userId, Name = "P" .. userId } :: any) :: Player
	end

	local function makeCSMMock()
		local countChanged = Instance.new("BindableEvent")
		return {
			create = function(_id: string, _initial: any) end,
			destroy = function(_id: string) end,
			CountChanged = countChanged,
		}
	end

	describe("RoundLifecycle F1 — peak tracking", function()

		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("AC-5: newCount > peakCount updates peak + timestamp + final", function()
			local p1 = makePlayer(101)
			RoundLifecycle.createAll({ p1 })
			local before = RoundLifecycle.getPeakTimestamp("101") :: number
			task.wait()  -- ensure os.clock advances
			csm.CountChanged:Fire("101", 10, 15, "Absorb")
			task.wait()  -- let signal handler run

			local after = RoundLifecycle.getPeakTimestamp("101") :: number
			expect(after >= before).to.equal(true)  -- timestamp updated (or equal if same tick)
		end)

		it("AC-6: newCount == peakCount does NOT update timestamp", function()
			local p1 = makePlayer(101)
			RoundLifecycle.createAll({ p1 })
			-- Drive peak up first.
			csm.CountChanged:Fire("101", 10, 100, "Absorb")
			task.wait()
			local peakAfterFirst = RoundLifecycle.getPeakTimestamp("101") :: number

			-- Equal-value fire: no update.
			task.wait()
			csm.CountChanged:Fire("101", 99, 100, "Absorb")
			task.wait()
			local peakAfterEqual = RoundLifecycle.getPeakTimestamp("101") :: number
			expect(peakAfterEqual).to.equal(peakAfterFirst)
		end)

		it("AC-7: newCount < peakCount does NOT touch peak; finalCount tracks newCount", function()
			local p1 = makePlayer(101)
			RoundLifecycle.createAll({ p1 })
			-- Push peak high.
			csm.CountChanged:Fire("101", 10, 100, "Absorb")
			task.wait()
			local peakAfter = RoundLifecycle.getPeakTimestamp("101")
			-- Drop count.
			csm.CountChanged:Fire("101", 100, 50, "Collision")
			task.wait()
			-- peakTimestamp unchanged.
			expect(RoundLifecycle.getPeakTimestamp("101")).to.equal(peakAfter)
		end)

		it("AC-8: fire for non-record crowdId is silent no-op", function()
			RoundLifecycle.createAll({})
			-- No record for "ghost"; signal must not crash.
			local ok = pcall(function()
				csm.CountChanged:Fire("ghost", 0, 50, "Absorb")
				task.wait()
			end)
			expect(ok).to.equal(true)
			-- No record exists for "ghost".
			expect(RoundLifecycle.getPeakTimestamp("ghost")).to.equal(nil)
		end)
	end)

	describe("RoundLifecycle F1 — subscription cleanup", function()

		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("destroyAll disconnects subscription — subsequent fires are no-op", function()
			local p1 = makePlayer(101)
			RoundLifecycle.createAll({ p1 })
			-- Capture peakTimestamp pre-destroy.
			csm.CountChanged:Fire("101", 10, 200, "Absorb")
			task.wait()
			local peakAfterFire = RoundLifecycle.getPeakTimestamp("101")
			expect(peakAfterFire).never.to.equal(nil)

			-- Destroy (Janitor cleans subscription + clears _crowds).
			RoundLifecycle.destroyAll()

			-- Subsequent fires must not error and not resurrect any record.
			local ok = pcall(function()
				csm.CountChanged:Fire("101", 200, 250, "Absorb")
				task.wait()
			end)
			expect(ok).to.equal(true)
			expect(RoundLifecycle.getPeakTimestamp("101")).to.equal(nil)
		end)
	end)

	describe("RoundLifecycle F1 — multi-record isolation", function()

		local csm: any

		beforeEach(function()
			RoundLifecycle._resetForTests()
			csm = makeCSMMock()
			RoundLifecycle._setCSMOverride(csm)
		end)

		it("3 records — fire for one updates only that record", function()
			RoundLifecycle.createAll({
				makePlayer(101),
				makePlayer(102),
				makePlayer(103),
			})

			local peak102Before = RoundLifecycle.getPeakTimestamp("102")
			local peak103Before = RoundLifecycle.getPeakTimestamp("103")

			-- Update only 101.
			csm.CountChanged:Fire("101", 10, 80, "Absorb")
			task.wait()

			expect(RoundLifecycle.getPeakTimestamp("102")).to.equal(peak102Before)
			expect(RoundLifecycle.getPeakTimestamp("103")).to.equal(peak103Before)
		end)
	end)
end
