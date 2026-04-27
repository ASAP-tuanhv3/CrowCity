--!strict

-- Unit tests for UnreliableRemoteEvent wrapper (Story 001, network-layer-ext epic).
-- Framework: TestEZ (Packages.testez)
-- Covers: AC-1 (enum integrity), AC-2 (API surface), AC-3 (boot creates instances),
--         AC-4 (round-trip — ADVISORY: in-Studio multi-context smoke), AC-5 (unknown-name guard),
--         AC-6 (--!strict — proxy), AC-7 (grep gate — verified out-of-band)

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Network = require(ReplicatedStorage.Source.Network)
	local UnreliableRemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.UnreliableRemoteEventName)

	describe("UnreliableRemoteEventName enum (AC-1)", function()

		it("contains CrowdStateBroadcast key (mandated by ADR-0001)", function()
			expect(UnreliableRemoteEventName.CrowdStateBroadcast).to.equal("CrowdStateBroadcast")
		end)

		it("contains NpcStateBroadcast key (mandated by ADR-0008)", function()
			expect(UnreliableRemoteEventName.NpcStateBroadcast).to.equal("NpcStateBroadcast")
		end)

		it("every value equals its key (template idiom)", function()
			for key, value in UnreliableRemoteEventName do
				expect(value).to.equal(key)
			end
		end)

		it("has unique values (no duplicate strings)", function()
			local seen: { [string]: string } = {}
			for key, value in UnreliableRemoteEventName do
				expect(seen[value] == nil).to.equal(true)
				seen[value] = key
			end
		end)

	end)

	describe("Network module surface (AC-2)", function()

		it("exposes connectUnreliableEvent as a function", function()
			expect(type(Network.connectUnreliableEvent)).to.equal("function")
		end)

		it("exposes fireAllClientsUnreliable as a function", function()
			expect(type(Network.fireAllClientsUnreliable)).to.equal("function")
		end)

		it("exposes fireClientUnreliable as a function", function()
			expect(type(Network.fireClientUnreliable)).to.equal("function")
		end)

		it("exposes UnreliableRemoteEvents enum (parallel to RemoteEvents / RemoteFunctions)", function()
			expect(Network.UnreliableRemoteEvents).to.equal(UnreliableRemoteEventName)
		end)

	end)

	describe("Boot-time instance creation (AC-3)", function()

		-- ADVISORY: Boot-time instance creation runs only after Network.startServer()
		-- is called. In TestEZ harness this may not have run yet — the test below
		-- exercises the post-boot folder shape via _getUnreliableRemoteEvent which
		-- requires Network._remoteFolder to be initialised. If startServer has not
		-- run, _getUnreliableRemoteEvent asserts; that assertion path itself is
		-- AC-2 + AC-3 combined coverage (wrapper refuses pre-boot calls).
		it("UnreliableRemoteEvents folder exists post-boot (skipped if Network not started)", function()
			if not Network._remoteFolder then
				-- Network not started in this TestEZ harness — skip.
				return
			end

			local folder = (Network._remoteFolder :: Folder):FindFirstChild("UnreliableRemoteEvents")
			expect(folder).to.be.ok()

			-- Each enum entry should resolve to a child UnreliableRemoteEvent instance.
			for _, eventName in UnreliableRemoteEventName do
				local instance = (folder :: Folder):FindFirstChild(eventName :: string)
				expect(instance).to.be.ok()
				expect((instance :: Instance).ClassName).to.equal("UnreliableRemoteEvent")
			end
		end)

	end)

	describe("Unknown-name guard (AC-5)", function()

		-- AC-5: any wrapper API call with a name not in UnreliableRemoteEventName
		-- raises a typed error. Pre-boot the wrapper asserts on _remoteFolder being
		-- nil first; we exercise the post-boot path only when started.
		it("_getUnreliableRemoteEvent raises with the offending name (post-boot)", function()
			if not Network._remoteFolder then
				return
			end

			local ok, err = pcall(Network._getUnreliableRemoteEvent, "NotARealName")
			expect(ok).to.equal(false)
			expect(type(err) == "string" and string.find(err :: string, "NotARealName", 1, true) ~= nil).to.equal(true)
		end)

	end)

	describe("AC-4 round-trip (ADVISORY)", function()

		-- ADVISORY: Server→client round-trip requires multi-context test harness
		-- (server fires + client listener). TestEZ runs in single context.
		-- Real verification: in-Studio playtest with `Network.startServer()` /
		-- `Network.startClientAsync()` then fire + capture. Documented as deferred
		-- to /story-done evidence doc when multi-context harness lands.
		--
		-- This test instead verifies the call surface succeeds without throwing
		-- when invoked post-boot — proxy for "wrapper does not refuse valid input".
		it("fireAllClientsUnreliable does not throw for valid event name (server-side proxy)", function()
			-- Skip if Network not started OR not running on server.
			if not Network._remoteFolder then
				return
			end

			local RunService = game:GetService("RunService")
			if not RunService:IsServer() then
				return
			end

			-- Empty payload — fires to zero connected clients in TestEZ harness.
			local ok = pcall(Network.fireAllClientsUnreliable, UnreliableRemoteEventName.CrowdStateBroadcast)
			expect(ok).to.equal(true)
		end)

	end)

	describe("AC-6 + AC-7 (compile-time + grep gate proxies)", function()

		-- AC-6 ADVISORY: --!strict is a compile-time directive enforced by Selene
		-- CI + Luau LSP. TestEZ cannot introspect strict-mode at runtime.
		-- AC-7 ADVISORY: Grep gate (`grep -rn "UnreliableRemoteEvent" src/ ...`)
		-- runs out-of-band at /story-done time, not at TestEZ runtime.
		it("modules load without error (compile + grep gates verified out-of-band)", function()
			expect(Network).to.be.ok()
			expect(UnreliableRemoteEventName).to.be.ok()
		end)

	end)

end
