# Story 009: Client peel observation — FollowerEntityClient.startPeel hook

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy + ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: `CollisionResolverClient` subscribes to `CollisionPeelEvent` UnreliableRemoteEvent and dispatches to `FollowerEntityClient.startPeel(loserId, winnerId, n)` per buffer entry. Cosmetic only — auth count comes from CrowdStateBroadcast (next tick). UREvent drop is acceptable (AC-19 — count cache reconciles within 67 ms).

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: UnreliableRemoteEvent stable post-cutoff.

**Control Manifest Rules (Presentation layer):**
- Required: Read-only consumer of `CrowdStateClient` mirror (ADR-0001)
- Required: Client peel reacts to UREvent only — no server-side peel reconciliation (cosmetic per ADR-0001)
- Forbidden: Mutate `CrowdStateClient` (ADR-0004 — read-only)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-12 (Client peel observation)**: GIVEN `CollisionResolverClient` subscribed to `CollisionPeelEvent` receives buffer `[{loserId="A", winnerId="B", n=2}]`, WHEN unreliable event fires, THEN `FollowerEntityClient.startPeel("A", "B", 2)` called exactly once with those args.
- [ ] **AC-19 (Unreliable peel packet drop is cosmetic-only)**: GIVEN server fires CollisionPeelEvent but unreliable packet dropped (handler not invoked), WHEN client's next CrowdStateBroadcast arrives (≤67 ms later), THEN authoritative count cache reflects post-drip; no gameplay state corruption; no retry/ACK.
- [ ] **Path placement**: `src/ReplicatedStorage/Source/CollisionResolverClient/init.luau`.

---

## Implementation Notes

*Derived from ADR-0001 §Peel + ADR-0007 §FollowerEntityClient API:*

- Module: `ReplicatedStorage/Source/CollisionResolverClient/init.luau` (Presentation tier — shared placement OK because client-only consumer; not requiring from server).
- Public surface: `init(deps)`, `start()` (subscribes UREvent), `stop()` (cleanup Janitor).
- Subscribe: `Network.connectUnreliableEvent(UREventName.CollisionPeelEvent, function(buffer) ... end)`.
- For each entry in buffer (decoded): `local crowdClient = CrowdManagerClient.getCrowdClient(entry.loserId); if crowdClient then crowdClient:startPeel(entry.loserId, entry.winnerId, entry.n) end`.
- Note: `startPeel` API exists as stub on `FollowerEntityClient` per Sprint 4 story-002 (deferred fill to FE story-007/008 — already complete). This story wires the call site only.
- AC-19 sketch: do NOT call `CrowdStateClient.set` or any cache mutator; rely on next CrowdStateBroadcast (ADR-0001 broadcast path) for count truth.
- DI: `CrowdManagerClient` injected (or required at module-level — per ADR-0006 Presentation can require Presentation siblings).

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- Server-side peel dispatch (Story 008).
- FollowerEntityClient.startPeel implementation (Sprint 4 FE epic — already implemented).
- Bandwidth measurement (Story 011).

---

## QA Test Cases

- **AC-12 (Peel observation)** [Integration]:
  - Given: mock UREvent receiver; FollowerEntityClient.startPeel spy
  - When: server fires `(RemoteEventName.CollisionPeelEvent, [{loserId="A", winnerId="B", n=2}])`
  - Then: spy.startPeel called exactly once with `("A", "B", 2)`
  - Edge cases: empty buffer — no startPeel calls; multi-entry buffer — sequential startPeel per entry.

- **AC-19 (Drop is cosmetic-only)** [Integration]:
  - Given: simulate UREvent drop (handler skipped); CrowdStateBroadcast arrives next at t+67 ms
  - When: client state inspected at t+100ms
  - Then: `CrowdStateClient.get(loserId).count` matches server post-drip value; no error from missing peel
  - Edge cases: 100% peel drop rate — count still converges within RTT; visual peel never plays but absorb visual on server-broadcast count change still fires (separate channel).

- **No client cache mutation**:
  - Given: full `CollisionResolverClient` source
  - When: grep for `CrowdStateClient.set\|.update\|.write`
  - Then: zero matches
  - Edge cases: tests/ may have mocks — OK.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/collision/client_peel_observation.spec.luau` — must exist and pass
- `tests/integration/collision/peel_drop_cosmetic.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 008 (server side fires UREvent); FollowerEntityClient.startPeel from FE epic (Sprint 4 closed).
- Unlocks: End-to-end peel visual verification.
