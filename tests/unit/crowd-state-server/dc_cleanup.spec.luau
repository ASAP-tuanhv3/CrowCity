--!strict

--[[
	CrowdStateServer — disconnect (PlayerRemoving) cleanup unit tests.
	Path: tests/unit/crowd-state-server/dc_cleanup.spec.luau
	Implements: CSM story-001 AC-02 (DC cleanup).

	Strategy note: TestEZ in Studio server context cannot synthesise a real
	Player instance to fire Players.PlayerRemoving. Instead we test:
	  (a) start() wires the connection (non-nil after call)
	  (b) start() is idempotent (same connection object on second call)
	  (c) destroy(tostring(userId)) removes the record — the PlayerRemoving
	      handler is a one-line delegate to destroy(); testing the delegate
	      path directly validates the same removal contract (AC-02 functional
	      path). Full end-to-end PlayerRemoving → handler invocation is covered
	      by integration playtest.
--]]

return function()
	local ServerStorage = game:GetService("ServerStorage")
	local CrowdStateServer = require(ServerStorage.Source.CrowdStateServer)

	--- Constructs a minimal valid CrowdRecord for test fixtures.
	local function makeRecord(crowdId: string): CrowdStateServer.CrowdRecord
		return {
			crowdId = crowdId,
			position = Vector3.new(0, 0, 0),
			radiusMultiplier = 1.0,
			radius = 5.0,
			count = 10,
			hue = 1,
			activeRelics = {} :: { string },
			state = "Active" :: CrowdStateServer.CrowdState,
			tick = 0,
			stillOverlapping = false,
			timer_start = nil :: number?,
		}
	end

	describe("CrowdStateServer DC cleanup (PlayerRemoving handler)", function()

		beforeEach(function()
			CrowdStateServer._resetForTests()
			-- Suppress reliable RemoteEvent fanout — Network is not started in
			-- TestEZ context. AC-23/AC-26 payload verification lives in
			-- signal_fanout.spec.
			CrowdStateServer._setTestFanoutInterceptor(function() end)
		end)

		-- AC-02 setup: start() must wire a non-nil RBXScriptConnection.
		-- The connection is what lets the module receive PlayerRemoving events.
		it("start() connects the PlayerRemoving handler", function()
			expect(CrowdStateServer._getPlayerRemovingConnection()).to.equal(nil)
			CrowdStateServer.start()
			expect(CrowdStateServer._getPlayerRemovingConnection()).to.be.ok()
		end)

		-- start() is idempotent: calling it twice must not replace the connection.
		-- Identity equality verifies the same RBXScriptConnection object is reused.
		it("start() is idempotent — second call reuses the same connection", function()
			CrowdStateServer.start()
			local conn1 = CrowdStateServer._getPlayerRemovingConnection()
			CrowdStateServer.start()
			local conn2 = CrowdStateServer._getPlayerRemovingConnection()
			expect(conn1).to.equal(conn2)
		end)

		-- AC-02 functional path: the PlayerRemoving handler is
		-- `destroy(tostring(player.UserId))`. Testing destroy directly
		-- validates the same removal contract without a real Player instance.
		it("destroy(tostring(userId)) removes record (AC-02 functional path)", function()
			local userId = "12345"
			CrowdStateServer.create(userId, makeRecord(userId))
			expect(CrowdStateServer._getCrowdsCount()).to.equal(1)
			CrowdStateServer.destroy(userId)
			expect(CrowdStateServer.get(userId)).to.equal(nil)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(0)
		end)

		-- AC-02 edge: PlayerRemoving for a player without an active crowd
		-- record (e.g. player disconnects before round starts). Must be a no-op.
		it("destroy on record-absent userId is a no-op — no error (AC-02 edge)", function()
			local ok = pcall(CrowdStateServer.destroy, "99999")
			expect(ok).to.equal(true)
			expect(CrowdStateServer._getCrowdsCount()).to.equal(0)
		end)

	end)
end
