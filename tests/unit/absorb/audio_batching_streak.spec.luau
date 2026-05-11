--!strict

--[[
	AbsorbVAConsumer audio batching + streak escalation — unit tests.
	Path: tests/unit/absorb/audio_batching_streak.spec.luau

	Story 7-9 (Sprint 7) / absorb-system story-006.
	Covers AC-15 (audio batching tiered by count) + AC-16 (streak escalation
	threshold + signal exclusivity) + VFX 6/frame cap.

	Audio + VFX managers are stubbed via DI; consumer's Logic is the unit
	under test. Clock is injected for deterministic time-window semantics.

	AC-14 (single absorb single sound) covered via the 1-count tier path of
	AC-15 + the VFX visible particles path.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local AbsorbVAConsumer = require(ServerStorage.Source.AbsorbVAConsumer)

	-- -------------------------------------------------------------------------
	-- Mocks
	-- -------------------------------------------------------------------------

	--- Builds a mock VFX manager that records every playEffect call.
	local function buildMockVfx()
		local calls: { { effectId: string, position: Vector3, crowdId: string } } = {}
		local mock = {
			playEffect = function(effectId: string, context: any)
				table.insert(calls, {
					effectId = effectId,
					position = context.position,
					crowdId = context.crowdId,
				})
			end,
		}
		local function getCalls() return calls end
		return mock, getCalls
	end

	--- Builds a mock audio manager that records every playBatched call.
	local function buildMockAudio()
		local calls: { { crowdId: string, pitch: number, volume: number } } = {}
		local mock = {
			playBatched = function(crowdId: string, pitch: number, volume: number)
				table.insert(calls, { crowdId = crowdId, pitch = pitch, volume = volume })
			end,
		}
		local function getCalls() return calls end
		return mock, getCalls
	end

	--- Injectable clock fixture.
	local function buildMockClock(initial: number)
		local now = initial
		local function getNow() return now end
		local function advance(dt: number) now += dt end
		return getNow, advance
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("AbsorbVAConsumer — Story 7-9 audio batching + streak escalation", function()
		afterEach(function()
			AbsorbVAConsumer._resetForTests()
		end)

		-- AC-14: single absorb → 1 sound + 1 VFX at NPC position.
		it("AC-14 — single absorb fires exactly 1 sound + 1 VFX at NPC position", function()
			-- Arrange
			local vfx, getVfxCalls = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			-- Act
			AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(5, 0, 5))
			AbsorbVAConsumer._flushForTest()

			-- Assert
			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(1)
			expect(audioCalls[1].crowdId).to.equal("c1")
			expect(audioCalls[1].pitch).to.equal(1.0)  -- baseline
			expect(audioCalls[1].volume).to.equal(1.0)

			local vfxCalls = getVfxCalls()
			expect(#vfxCalls).to.equal(1)
			expect(vfxCalls[1].effectId).to.equal("AbsorbSnap")
			expect(vfxCalls[1].crowdId).to.equal("c1")
			expect(vfxCalls[1].position).to.equal(Vector3.new(5, 0, 5))
		end)

		-- AC-15: 4 absorbs same tick → exactly 1 audio play at tier-2 pitch/volume.
		it("AC-15 — 4 absorbs in same tick: 1 sound, pitch +0.15, vol +20%", function()
			local vfx = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			-- Act: 4 injections same tick, then 1 flush
			for i = 1, 4 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
			end
			AbsorbVAConsumer._flushForTest()

			-- Assert: exactly 1 audio play with tier-2 values
			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(1)
			expect(audioCalls[1].pitch).to.equal(1.15)  -- PITCH_TIER2
			expect(audioCalls[1].volume).to.equal(1.20)  -- VOLUME_TIER2
		end)

		-- AC-15 edge: 5+ absorbs → tier 3 pitch/volume.
		it("AC-15 edge — 5 absorbs: tier-3 pitch +0.20 vol +30%", function()
			local vfx = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			for i = 1, 5 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
			end
			AbsorbVAConsumer._flushForTest()

			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(1)
			expect(audioCalls[1].pitch).to.equal(1.20)  -- PITCH_TIER3
			expect(audioCalls[1].volume).to.equal(1.30)  -- VOLUME_TIER3
		end)

		-- AC-15 boundary: tick A has 4 absorbs, tick B has 1 → 2 plays total.
		it("AC-15 boundary — 4 absorbs tick A + 1 tick B: 2 audio plays (one per tick)", function()
			local vfx = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			for i = 1, 4 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
			end
			AbsorbVAConsumer._flushForTest()

			AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(99, 0, 0))
			AbsorbVAConsumer._flushForTest()

			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(2)
			expect(audioCalls[1].pitch).to.equal(1.15)  -- tier-2 first tick
			expect(audioCalls[2].pitch).to.equal(1.0)   -- baseline second tick
		end)

		-- AC-16: 10 absorbs within 3 s → 10th fires streak. pitch escalates to
		-- tier-base + STREAK_BONUS. StreakEscalation signal fires exactly once.
		it("AC-16 — 10 absorbs in 3 s: streak fires once, pitch escalates by +0.10 bonus", function()
			local vfx = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local getNow, advance = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = getNow })

			-- Subscribe to streak signal to count fires
			local streakFires: { string } = {}
			local streakEvent = AbsorbVAConsumer.StreakEscalation :: BindableEvent
			local conn = streakEvent.Event:Connect(function(crowdId: string)
				table.insert(streakFires, crowdId)
			end)

			-- Act: 10 absorbs spread over 2.5 s (well within 3 s window)
			for i = 1, 10 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
				advance(0.25)
			end
			AbsorbVAConsumer._flushForTest()

			-- Assert: streak signal fired exactly ONCE (on 10th absorb).
			expect(#streakFires).to.equal(1)
			expect(streakFires[1]).to.equal("c1")

			-- Audio tier: 10 absorbs in one tick → tier 3 (1.20) + streak bonus (0.10)
			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(1)
			expect(audioCalls[1].pitch).to.equal(1.20 + 0.10)  -- 1.30 total streak pitch

			conn:Disconnect()
		end)

		-- AC-16 edge: 9 in 2.999 s + 10th at 3.001 s — first absorb evicted,
		-- streak does NOT escalate (buffer = 9 by 10th eval).
		it("AC-16 edge — 9 absorbs in 2.999 s + 10th past window: no escalation", function()
			local vfx = buildMockVfx()
			local audio = buildMockAudio()
			local getNow, advance = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = getNow })

			local streakFires: { string } = {}
			local conn = (AbsorbVAConsumer.StreakEscalation :: BindableEvent).Event:Connect(function(crowdId: string)
				table.insert(streakFires, crowdId)
			end)

			-- 9 absorbs over 2.999s (timestamps 0.0, 0.333, ..., 2.666)
			for i = 1, 9 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
				advance(0.333)  -- 9 × 0.333 ≈ 2.997s elapsed after loop
			end
			-- Now at ~2.997s. Jump past 3 s window so first ts (0.0) evicts on next push.
			advance(0.05)  -- now ~3.047s
			AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(10, 0, 0))

			-- Buffer at 10th push: first ts (0.0) is 3.047 ago > 3.0 → evicted.
			-- Buffer count = 9 + 1 (10th) - 1 (evicted) = 9. Below threshold.
			expect(#streakFires).to.equal(0)
			expect(AbsorbVAConsumer._isStreakActiveForTest("c1")).to.equal(false)

			conn:Disconnect()
		end)

		-- VFX per-frame cap: 8 absorbs in one tick → 6 visible particles, 2 silent.
		-- Audio still plays for all 8 (single batched play).
		it("VFX cap — 8 absorbs in same tick: 6 VFX visible, 1 audio play tier 3", function()
			local vfx, getVfxCalls = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			for i = 1, 8 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
			end
			AbsorbVAConsumer._flushForTest()

			-- VFX: capped at 6
			local vfxCalls = getVfxCalls()
			expect(#vfxCalls).to.equal(6)

			-- Audio: still 1 play, tier-3 because count was 8
			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(1)
			expect(audioCalls[1].pitch).to.equal(1.20)  -- tier 3
		end)

		-- VFX cap is shared ACROSS crowds in same tick.
		it("VFX cap — shared across crowds: 4 each on c1+c2 → 6 visible total, 2 per-crowd plays", function()
			local vfx, getVfxCalls = buildMockVfx()
			local audio, getAudioCalls = buildMockAudio()
			local clock = buildMockClock(0)
			AbsorbVAConsumer.init({ vfxManager = vfx, audioManager = audio, clock = clock })

			-- 4 absorbs on c1
			for i = 1, 4 do
				AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(i, 0, 0))
			end
			-- 4 absorbs on c2
			for i = 1, 4 do
				AbsorbVAConsumer._injectAbsorbedForTest("c2", Vector3.new(i + 100, 0, 0))
			end
			AbsorbVAConsumer._flushForTest()

			-- VFX total capped at 6 across both crowds
			local vfxCalls = getVfxCalls()
			expect(#vfxCalls).to.equal(6)

			-- Audio: 1 play per crowd = 2 total
			local audioCalls = getAudioCalls()
			expect(#audioCalls).to.equal(2)
		end)

		-- Nil DI graceful degradation — no error, no log spam.
		it("nil-DI — no vfxManager / audioManager: no error on flush", function()
			AbsorbVAConsumer.init({ vfxManager = nil, audioManager = nil, clock = function() return 0 end })

			AbsorbVAConsumer._injectAbsorbedForTest("c1", Vector3.new(0, 0, 0))
			expect(function()
				AbsorbVAConsumer._flushForTest()
			end).never.to.throw()
		end)
	end)
end
