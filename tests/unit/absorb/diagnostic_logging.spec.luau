--!strict

--[[
	AbsorbSystem diagnostic logging — unit tests.
	Path: tests/unit/absorb/diagnostic_logging.spec.luau

	Story 7-2 (Sprint 7): BUG-001 prereq diagnostic logging in AbsorbSystem.tick.
	Disambiguates BUG-001 root causes (silent no-op paths at AC-10 / AC-11
	early returns) when investigating in Studio playtest.

	Acceptance Criteria coverage:
	  AC-1 — log line `[AbsorbSystem] tick N crowds=M npcs=K` once/sec at 15 Hz
	         when DIAGNOSTIC_LOGGING_ENABLED=true.
	  AC-2 — when DIAGNOSTIC_LOGGING_ENABLED=false: NO log emitted at any tickCount.
	  AC-3 — when tickCount % 15 != 0: no log emitted that tick.
	  AC-4 — log values match #csm.getAllActive() and #npcSpawner.getAllActiveNPCs()
	         at call time.
	  AC-5 — diagnostic log MUST NOT call getAllActiveNPCs() when getAllActive() is
	         empty (preserves AC-10 of Story 5-12). When crowds=0, log line is
	         `[AbsorbSystem] tick N crowds=0 npcs=skipped`.
	  AC-7 — test seam _setDiagnosticLoggingForTest captures log output via spy.

	Test isolation: AbsorbSystem._resetForTests() in afterEach restores production
	defaults (DIAGNOSTIC_LOGGING_DEFAULT=false, _diagnosticLogFn=print).
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local AbsorbSystem = require(ServerStorage.Source.AbsorbSystem)

	-- -------------------------------------------------------------------------
	-- Spy + mock helpers
	-- -------------------------------------------------------------------------

	--- Captured log lines spy. Returns (captureFn, getLines).
	local function makeLogSpy(): ((string) -> (), () -> { string })
		local lines: { string } = {}
		local function capture(line: string)
			table.insert(lines, line)
		end
		local function getLines(): { string }
			return lines
		end
		return capture, getLines
	end

	--- Mock CSM with controllable getAllActive return + empty updateCount spy.
	local function buildMockCsm(crowds: { any }): any
		return {
			getAllActive = function(): { any }
				return crowds
			end,
			updateCount = function() end,
		}
	end

	--- Mock NPCSpawner with controllable getAllActiveNPCs + a call counter so
	--- tests can assert AC-5 ("getAllActiveNPCs NOT called when crowds=0").
	--- Frozen once at construction (production contract: snapshot is frozen);
	--- subsequent calls return the same frozen reference.
	local function buildMockNpcSpawner(npcs: { any }): (any, () -> number)
		local frozenSnapshot = table.freeze(npcs)
		local callCount = 0
		local mock: any = {
			getAllActiveNPCs = function(): { any }
				callCount += 1
				return frozenSnapshot
			end,
			reclaim = function() end,
		}
		local function getCallCount(): number
			return callCount
		end
		return mock, getCallCount
	end

	local function buildMockNetwork(): any
		return {
			fireAllClients = function() end,
		}
	end

	local function makeCrowd(crowdId: string): any
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radius = 5,
			state = "Active",
		}
	end

	local function makeNpc(npcId: string, x: number, z: number): any
		return {
			npcId = npcId,
			position = Vector3.new(x, 0, z),
		}
	end

	-- -------------------------------------------------------------------------
	-- Suite
	-- -------------------------------------------------------------------------

	describe("AbsorbSystem diagnostic logging — Story 7-2", function()
		afterEach(function()
			AbsorbSystem._resetForTests()
		end)

		-- AC-1: log emits at tickCount=15 when enabled with 1 crowd + 1 NPC.
		it("emits log line at tickCount=15 when enabled with non-empty crowds and npcs", function()
			-- Arrange
			local crowd = makeCrowd("100")
			-- NPC at (50, 0, 0) — outside crowd.radius=5; AC-11 path NOT taken
			-- (npcs non-empty); diagnostic still fires at site 2.
			local npc = makeNpc("n0", 50, 0)
			local capture, getLines = makeLogSpy()

			local mockCsm = buildMockCsm({ crowd })
			local mockSpawner = buildMockNpcSpawner({ npc })
			AbsorbSystem.init({
				csm = mockCsm,
				npcSpawner = mockSpawner,
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)

			-- Act
			AbsorbSystem.tick(15, {})

			-- Assert
			local lines = getLines()
			expect(#lines).to.equal(1)
			expect(lines[1]).to.equal("[AbsorbSystem] tick 15 crowds=1 npcs=1")
		end)

		-- AC-2: production default (flag=false) suppresses log entirely.
		it("does NOT emit log when DIAGNOSTIC_LOGGING_ENABLED=false (production default)", function()
			-- Arrange
			local crowd = makeCrowd("100")
			local npc = makeNpc("n0", 50, 0)
			local capture, getLines = makeLogSpy()

			AbsorbSystem.init({
				csm = buildMockCsm({ crowd }),
				npcSpawner = buildMockNpcSpawner({ npc }),
				network = buildMockNetwork(),
			})
			-- Flag explicitly false, sink is the spy (would capture if called).
			AbsorbSystem._setDiagnosticLoggingForTest(false, capture)

			-- Act
			AbsorbSystem.tick(15, {})
			AbsorbSystem.tick(30, {})
			AbsorbSystem.tick(45, {})

			-- Assert
			expect(#getLines()).to.equal(0)
		end)

		-- AC-3: tickCount cadence — emit only when tickCount % 15 == 0.
		it("does NOT emit log when tickCount %% 15 != 0; emits at boundaries 0/15/30", function()
			-- Arrange
			local crowd = makeCrowd("100")
			local npc = makeNpc("n0", 50, 0)
			local capture, getLines = makeLogSpy()

			AbsorbSystem.init({
				csm = buildMockCsm({ crowd }),
				npcSpawner = buildMockNpcSpawner({ npc }),
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)

			-- Act: ticks 0, 7, 14, 15, 16, 30 — only 0, 15, 30 should emit.
			AbsorbSystem.tick(0, {})
			AbsorbSystem.tick(7, {})
			AbsorbSystem.tick(14, {})
			AbsorbSystem.tick(15, {})
			AbsorbSystem.tick(16, {})
			AbsorbSystem.tick(30, {})

			-- Assert
			local lines = getLines()
			expect(#lines).to.equal(3)
			expect(lines[1]).to.equal("[AbsorbSystem] tick 0 crowds=1 npcs=1")
			expect(lines[2]).to.equal("[AbsorbSystem] tick 15 crowds=1 npcs=1")
			expect(lines[3]).to.equal("[AbsorbSystem] tick 30 crowds=1 npcs=1")
		end)

		-- AC-5: crowds=0 path — log fires with literal "npcs=skipped",
		-- getAllActiveNPCs MUST NOT be called (preserves AC-10 of Story 5-12).
		it("emits crowds=0 npcs=skipped when crowds empty; preserves AC-10 (no getAllActiveNPCs call)", function()
			-- Arrange: empty crowds.
			local capture, getLines = makeLogSpy()
			local mockSpawner, getNpcCallCount = buildMockNpcSpawner({ makeNpc("n0", 0, 0) })

			AbsorbSystem.init({
				csm = buildMockCsm({}),
				npcSpawner = mockSpawner,
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)

			-- Act
			AbsorbSystem.tick(15, {})

			-- Assert: log emitted with skipped marker
			local lines = getLines()
			expect(#lines).to.equal(1)
			expect(lines[1]).to.equal("[AbsorbSystem] tick 15 crowds=0 npcs=skipped")
			-- AC-10 preserved: getAllActiveNPCs NEVER called this tick
			expect(getNpcCallCount()).to.equal(0)
		end)

		-- AC-4 bonus: crowds non-empty but npcs empty — log still fires (AC-11 path).
		-- This is the case BUG-001 hypothesis #1 surfaces: spawner pool empty
		-- despite spawned visuals in Workspace.
		it("emits crowds=N npcs=0 when npcs empty (covers AC-11 silent no-op)", function()
			-- Arrange: 2 crowds, 0 npcs.
			local capture, getLines = makeLogSpy()
			local mockSpawner, getNpcCallCount = buildMockNpcSpawner({})

			AbsorbSystem.init({
				csm = buildMockCsm({ makeCrowd("100"), makeCrowd("200") }),
				npcSpawner = mockSpawner,
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)

			-- Act
			AbsorbSystem.tick(15, {})

			-- Assert: log fires with crowds=2 npcs=0; getAllActiveNPCs called once.
			local lines = getLines()
			expect(#lines).to.equal(1)
			expect(lines[1]).to.equal("[AbsorbSystem] tick 15 crowds=2 npcs=0")
			expect(getNpcCallCount()).to.equal(1)
		end)

		-- Code-review Gap A: tick(0, {}) crowds=0 — first-frame condition.
		-- 0 % 15 == 0, so log SHOULD emit at the cold-start tick. Most common
		-- real-world condition (server boots, no crowds yet at frame 0).
		it("emits at tick 0 with empty crowds (first-frame cold start)", function()
			-- Arrange: empty crowds at boot.
			local capture, getLines = makeLogSpy()
			local mockSpawner, getNpcCallCount = buildMockNpcSpawner({})

			AbsorbSystem.init({
				csm = buildMockCsm({}),
				npcSpawner = mockSpawner,
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)

			-- Act
			AbsorbSystem.tick(0, {})

			-- Assert
			local lines = getLines()
			expect(#lines).to.equal(1)
			expect(lines[1]).to.equal("[AbsorbSystem] tick 0 crowds=0 npcs=skipped")
			expect(getNpcCallCount()).to.equal(0)
		end)

		-- Code-review Gap C: nil logCallback reverts sink to default `print`.
		-- Doc comment on _setDiagnosticLoggingForTest says: "Pass nil for
		-- logCallback to restore default print sink." Verify: passing nil
		-- after a spy was set does NOT crash on subsequent tick.
		it("nil logCallback reverts sink to print (no crash on subsequent tick)", function()
			-- Arrange: spy active first.
			local capture, _getLines = makeLogSpy()
			AbsorbSystem.init({
				csm = buildMockCsm({}),
				npcSpawner = buildMockNpcSpawner({}),
				network = buildMockNetwork(),
			})
			AbsorbSystem._setDiagnosticLoggingForTest(true, capture)
			AbsorbSystem.tick(15, {})  -- spy captures one line

			-- Act: revert sink to default print by passing nil
			AbsorbSystem._setDiagnosticLoggingForTest(true, nil)

			-- Assert: subsequent tick does NOT crash (sink is now `print`)
			expect(function()
				AbsorbSystem.tick(30, {})
			end).never.to.throw()
		end)
	end)
end
