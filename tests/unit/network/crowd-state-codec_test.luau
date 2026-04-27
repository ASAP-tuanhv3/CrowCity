--!strict

-- Unit tests for CrowdState buffer codec (Story 003, network-layer-ext epic).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (module exists), AC-2 (encode/decode/CrowdRecord exports),
--         AC-3 (per-crowd 30-byte layout), AC-4 (no header/no padding + length contract),
--         AC-5 (round-trip preservation), AC-6 (encoder reject malformed records),
--         AC-7 (decoder reject malformed buffer), AC-8 (perf advisory)

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CrowdState = require(ReplicatedStorage.Source.Network.BufferCodec.CrowdState)

	local function makeRecord(overrides: { [string]: any }?): CrowdState.CrowdRecord
		local base: CrowdState.CrowdRecord = {
			crowdId = 12345,
			tick = 42,
			position = Vector3.new(1, 2, 3),
			radius = 4.5,
			count = 100,
			hue = 7,
			state = 1,
		}
		if overrides then
			for k, v in overrides :: { [string]: any } do
				(base :: any)[k] = v
			end
		end
		return base
	end

	describe("CrowdState codec (AC-1 + AC-2)", function()

		it("recordSize returns 30", function()
			expect(CrowdState.recordSize()).to.equal(30)
		end)

		it("exposes encode + decode functions", function()
			expect(type(CrowdState.encode)).to.equal("function")
			expect(type(CrowdState.decode)).to.equal("function")
		end)

	end)

	describe("Layout exactness (AC-3 + AC-4)", function()

		it("single-record buffer length == 30", function()
			local buf = CrowdState.encode({ makeRecord() })
			expect(buffer.len(buf)).to.equal(30)
		end)

		it("12-record buffer length == 360", function()
			local records = {}
			for i = 1, 12 do
				records[i] = makeRecord({ crowdId = i, tick = i })
			end
			local buf = CrowdState.encode(records)
			expect(buffer.len(buf)).to.equal(360)
		end)

		it("per-field offsets match arch §5.7 schema", function()
			local record = makeRecord({
				crowdId = 999888777,
				tick = 65000,
				position = Vector3.new(10.5, -7.25, 0.0625),
				radius = 12.5,
				count = 250,
				hue = 200,
				state = 2,
			})
			local buf = CrowdState.encode({ record })

			-- crowdId at offsets 0..7 (low u32 at 0, high u32 at 4)
			local low = buffer.readu32(buf, 0)
			local high = buffer.readu32(buf, 4)
			expect(low + (high * 4294967296)).to.equal(999888777)

			-- tick at offset 8 (u16)
			expect(buffer.readu16(buf, 8)).to.equal(65000)

			-- position 3xf32 at offsets 10/14/18
			expect(buffer.readf32(buf, 10)).to.equal(10.5)
			expect(buffer.readf32(buf, 14)).to.equal(-7.25)
			expect(buffer.readf32(buf, 18)).to.equal(0.0625)

			-- radius at offset 22 (f32)
			expect(buffer.readf32(buf, 22)).to.equal(12.5)

			-- count at offset 26 (u16)
			expect(buffer.readu16(buf, 26)).to.equal(250)

			-- hue at offset 28 (u8)
			expect(buffer.readu8(buf, 28)).to.equal(200)

			-- state at offset 29 (u8)
			expect(buffer.readu8(buf, 29)).to.equal(2)
		end)

	end)

	describe("Round-trip preservation (AC-5)", function()

		it("empty input → empty output", function()
			local roundtripped = CrowdState.decode(CrowdState.encode({}))
			expect(#roundtripped).to.equal(0)
		end)

		it("single-record round-trip is bit-exact", function()
			local original = makeRecord()
			local roundtripped = CrowdState.decode(CrowdState.encode({ original }))
			expect(#roundtripped).to.equal(1)

			local r = roundtripped[1]
			expect(r.crowdId).to.equal(original.crowdId)
			expect(r.tick).to.equal(original.tick)
			expect(r.position.X).to.equal(original.position.X)
			expect(r.position.Y).to.equal(original.position.Y)
			expect(r.position.Z).to.equal(original.position.Z)
			expect(r.radius).to.equal(original.radius)
			expect(r.count).to.equal(original.count)
			expect(r.hue).to.equal(original.hue)
			expect(r.state).to.equal(original.state)
		end)

		it("12-record round-trip preserves all fields bit-exact", function()
			local records: { CrowdState.CrowdRecord } = {}
			for i = 1, 12 do
				records[i] = makeRecord({
					crowdId = 1000000 + i,
					tick = i * 100,
					position = Vector3.new(i * 1.5, i * -2.5, i * 0.25),
					radius = 3 + i * 0.5,
					count = i * 25,
					hue = i * 10,
					state = ((i - 1) % 3) + 1, -- cycle 1, 2, 3
				})
			end

			local roundtripped = CrowdState.decode(CrowdState.encode(records))
			expect(#roundtripped).to.equal(12)

			for i = 1, 12 do
				local original = records[i]
				local r = roundtripped[i]
				expect(r.crowdId).to.equal(original.crowdId)
				expect(r.tick).to.equal(original.tick)
				expect(r.position.X).to.equal(original.position.X)
				expect(r.position.Y).to.equal(original.position.Y)
				expect(r.position.Z).to.equal(original.position.Z)
				expect(r.radius).to.equal(original.radius)
				expect(r.count).to.equal(original.count)
				expect(r.hue).to.equal(original.hue)
				expect(r.state).to.equal(original.state)
			end
		end)

	end)

	describe("Encoder validation (AC-6)", function()

		-- AC-6: silent rejection per ADR-0010 — skip the record, warn, continue.
		it("skips record with count > 65535", function()
			local good = makeRecord({ crowdId = 1 })
			local bad = makeRecord({ crowdId = 2, count = 70000 })
			local buf = CrowdState.encode({ good, bad })
			expect(buffer.len(buf)).to.equal(30) -- only good record encoded

			local decoded = CrowdState.decode(buf)
			expect(#decoded).to.equal(1)
			expect(decoded[1].crowdId).to.equal(1)
		end)

		it("skips record with state ∉ {1,2,3}", function()
			local good = makeRecord({ crowdId = 1, state = 1 })
			local bad = makeRecord({ crowdId = 2, state = 4 })
			local buf = CrowdState.encode({ good, bad })
			expect(buffer.len(buf)).to.equal(30)

			local decoded = CrowdState.decode(buf)
			expect(#decoded).to.equal(1)
			expect(decoded[1].crowdId).to.equal(1)
		end)

		it("skips record with hue out of u8 range", function()
			local good = makeRecord({ crowdId = 1, hue = 200 })
			local bad = makeRecord({ crowdId = 2, hue = 300 })
			local buf = CrowdState.encode({ good, bad })
			expect(buffer.len(buf)).to.equal(30)
		end)

		it("all-bad input → empty buffer", function()
			local bad1 = makeRecord({ crowdId = 1, state = 0 })
			local bad2 = makeRecord({ crowdId = 2, count = -1 })
			local buf = CrowdState.encode({ bad1, bad2 })
			expect(buffer.len(buf)).to.equal(0)
		end)

	end)

	describe("Decoder validation (AC-7)", function()

		it("non-30-multiple buffer length → empty array", function()
			local malformed = buffer.create(35)
			local decoded = CrowdState.decode(malformed)
			expect(#decoded).to.equal(0)
		end)

		it("empty buffer → empty array (no warn)", function()
			local empty = buffer.create(0)
			local decoded = CrowdState.decode(empty)
			expect(#decoded).to.equal(0)
		end)

	end)

	describe("Performance advisory (AC-8)", function()

		-- ADVISORY: ADR-0003 §Network sub-allocation budget = 0.05 ms encode +
		-- 0.05 ms decode for 12-record payload. Locked at MVP-Integration-1 sprint.
		-- This test reports the measured number; threshold not enforced as fail-condition
		-- per story spec ("ADVISORY at this story; locked at MVP-Integration-1").
		it("12-record encode+decode takes < 1 ms per pass over 1000 iterations (advisory)", function()
			local records: { CrowdState.CrowdRecord } = {}
			for i = 1, 12 do
				records[i] = makeRecord({ crowdId = i, tick = i })
			end

			local iterations = 1000
			local startTime = os.clock()
			for _ = 1, iterations do
				local buf = CrowdState.encode(records)
				CrowdState.decode(buf)
			end
			local elapsed = os.clock() - startTime
			local perPassMs = (elapsed / iterations) * 1000

			-- Advisory upper bound — generous threshold to avoid flakiness on
			-- shared CI hardware. ADR-0003 hard 0.1 ms (0.05 + 0.05) target locked
			-- at MVP-Integration-1 sprint per story spec.
			expect(perPassMs < 1.0).to.equal(true)
		end)

	end)

end
