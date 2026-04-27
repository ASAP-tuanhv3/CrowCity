# Story 001: UnreliableRemoteEvent wrapper + UnreliableRemoteEventName enum

> **Epic**: network-layer-ext
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 4–5 hours (HIGH-risk post-cutoff API)

## Context

**GDD**: N/A — extension of template `Network` module; contracts derived from ADR-0001 §Decision (UREvent + 15 Hz cadence) + architecture.md §5.7
**Requirement**: TR-network-??? (no TR registered for Foundation infra; cite ADR-0001 §Decision + ADR-0006 §Source Tree Map directly)

**ADR Governing Implementation**: ADR-0001 — Crowd Replication Strategy
**ADR Decision Summary**: Server tracks per-player crowd aggregate state only; broadcasts at 15 Hz via `UnreliableRemoteEvent` (post-cutoff Roblox API) using Luau `buffer` encoding (mandated by Rule 10 amendment 2026-04-24). This story lands the wrapper API + enum module; payload encoding lives in story 003.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: HIGH (post-cutoff API)
**Engine Notes**: `UnreliableRemoteEvent` GA'd post-cutoff per `docs/engine-reference/roblox/replication-best-practices.md`. Behaviour: best-effort delivery, no ordering, no retransmit. Wrapper must mirror existing `RemoteEvent` wrapper API shape (`fireServer` → `fireAllClientsUnreliable`, `connectEvent` → `connectUnreliableEvent`).

**Control Manifest Rules (Foundation layer)**:
- Required: All remotes via `Network` module — never reference `UnreliableRemoteEvent` instances directly by path or string literal (ADR-0006)
- Required: Cross-module identifiers via `SharedConstants/` enums (ADR-0006)
- Forbidden: Direct `RemoteEvent` / `UnreliableRemoteEvent` access by path (ADR-0006)

---

## Acceptance Criteria

*Derived from ADR-0001 §Decision + architecture.md §5.7 + control manifest:*

- [ ] AC-1: New `src/ReplicatedStorage/Source/Network/RemoteName/UnreliableRemoteEventName.luau` enum module exists with `--!strict`; entries include `CrowdStateBroadcast` (mandatory per ADR-0001) and `NpcStateBroadcast` (mandatory per ADR-0008 §Replication Contract)
- [ ] AC-2: `Network/init.luau` exposes three new public functions: `connectUnreliableEvent(name: string, callback: (Player, ...any) -> ())`, `fireAllClientsUnreliable(name: string, ...)`, `fireClientUnreliable(player: Player, name: string, ...)`
- [ ] AC-3: Wrapper auto-creates one `UnreliableRemoteEvent` instance per `UnreliableRemoteEventName` entry under `ReplicatedStorage.RemoteEvents` at server boot (mirrors existing reliable-wrapper boot logic)
- [ ] AC-4: Calling `fireAllClientsUnreliable("CrowdStateBroadcast", ...)` from server reaches every connected client's `connectUnreliableEvent("CrowdStateBroadcast", ...)` listener (round-trip smoke)
- [ ] AC-5: Calling any wrapper API with an unknown event name (string not in `UnreliableRemoteEventName`) raises a typed error with the offending name (no silent path)
- [ ] AC-6: `--!strict` type checks pass on `Network/init.luau` after the additions
- [ ] AC-7: No instance access to `UnreliableRemoteEvent` by path appears outside `Network/init.luau` (verified by grep gate scoped to this story's diff)

---

## Implementation Notes

*Derived from ADR-0001 §Key Interfaces + ADR-0006 §Source Tree Map:*

- Mirror the existing `RemoteEventName` + `Network/init.luau` pattern. The shape is canonical — do not invent a new naming style for the unreliable side.
- File placement is fixed by ADR-0006 §Source Tree Map: enum under `Network/RemoteName/UnreliableRemoteEventName.luau`. Do not place under SharedConstants top-level.
- Boot-time instance creation: extend existing init logic that walks `RemoteEventName` entries and `Instance.new("RemoteEvent")`s each one. Add a parallel walk for `UnreliableRemoteEventName` calling `Instance.new("UnreliableRemoteEvent")`.
- The `UnreliableRemoteEvent` instance class name is **literal** — `Instance.new("UnreliableRemoteEvent")`. This is the post-cutoff API.
- Type-strict the wrapper API: payload arg list typed as `...any` is acceptable (Roblox remotes accept variadic packed payloads); buffer-typed payloads work transparently because Roblox replicates buffers natively.
- Keep all `UnreliableRemoteEvent` access funneled through this wrapper. Future stories (003 codec, downstream CSM stories) MUST NOT walk to `ReplicatedStorage.RemoteEvents.CrowdStateBroadcast` directly.

---

## Out of Scope

- Story 002: RemoteEventName + RemoteFunctionName additions (reliable side)
- Story 003: Buffer codec for CrowdStateBroadcast payload (this story creates the wire; 003 defines what flows through it)
- Story 004 / 005: RemoteValidator + RateLimitConfig
- Per-system handler wiring (consumer epics)

---

## QA Test Cases

- **AC-1**: enum integrity
  - Given: clean working tree
  - When: TestEZ harness loads `UnreliableRemoteEventName`
  - Then: module returns table with `CrowdStateBroadcast` and `NpcStateBroadcast` keys; all values are unique strings
  - Edge cases: missing key → fail with key name; duplicate value → fail

- **AC-2 / AC-3**: API surface + boot
  - Given: server harness imports `Network` module
  - When: inspect Network table + `ReplicatedStorage.RemoteEvents`
  - Then: three new functions exist as `function`-typed; `RemoteEvents` contains a `UnreliableRemoteEvent`-classed child for each enum entry
  - Edge cases: re-init creates duplicate instances → fail (boot must be idempotent); wrong ClassName → fail

- **AC-4**: round-trip smoke
  - Given: server harness fires + client harness listens (run via TestEZ in-Studio with two scripts)
  - When: `Network.fireAllClientsUnreliable("CrowdStateBroadcast", testPayload)`
  - Then: client listener receives `testPayload` within 1 frame
  - Edge cases: mark as ADVISORY if multi-client harness unavailable in TestEZ; document in evidence doc

- **AC-5**: unknown-name guard
  - Given: server harness
  - When: `Network.fireAllClientsUnreliable("NotARealName", payload)`
  - Then: raises error with message containing `"NotARealName"`
  - Edge cases: empty string → fail with empty-name error; nil → typed-error

- **AC-6**: strict type-check
  - Given: working tree
  - When: Selene + Luau `--!strict` analysis on `Network/init.luau`
  - Then: zero errors
  - Edge cases: any non-strict mode introduced → fail (per ADR-0006 forbidden pattern)

- **AC-7**: grep gate
  - Given: working tree post-implementation
  - When: `grep -rn "UnreliableRemoteEvent" src/ --exclude-dir=Dependencies | grep -v "src/ReplicatedStorage/Source/Network/"`
  - Then: zero matches outside Network module
  - Edge cases: any matches → fail

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/network/unreliable-wrapper_test.luau` — must exist and pass via TestEZ. Round-trip smoke (AC-4) may also produce manual evidence at `production/qa/evidence/unreliable-wrapper-evidence.md` if multi-client harness unavailable.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation; first story for this epic)
- Unlocks: Story 002 (parallel-runnable), Story 003 (codec, consumes the wrapper), all CSM/NPC server-broadcast stories
