# Story 008: Phase 8 broadcastAll + buffer codec wiring + Eliminated continues broadcasting + perf evidence

> **Epic**: crowd-state-server
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Server API (Implementation note + Network event contract); `design/gdd/crowd-replication-strategy.md` §Rules + payload schema
**Requirement**: `TR-csm-011` (Networking Key Interfaces), `TR-csm-012` (5 named reliable events), `TR-csm-013` (Eliminated continues broadcasting), `TR-csm-020` (Phase 5/8 budget), `TR-csm-022` (Write-Access Matrix Phase 8 sole caller)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Crowd Replication Strategy) §Decision + amend 2026-04-24 (UREvent + buffer mandate, 30 B/crowd payload schema, monotonic uint16 tick); ADR-0002 §Phase 8 (TickOrchestrator sole caller); ADR-0003 §Network bandwidth (5.4 KB/s/client steady-state) + §Per-tick CPU (Phase 8 0.4 ms budget); ADR-0004 §Write-Access Matrix.
**ADR Decision Summary**: `broadcastAll(tickCount)` is the Phase 8 hook called by TickOrchestrator. It builds a buffer payload (30 B/crowd × ≤12 active+eliminated crowds) using the Foundation `BufferCodec/CrowdState.luau` codec (from `network-layer-ext` story-003 — already shipped) and fires `CrowdStateBroadcast` UREvent to all clients. Eliminated crowds continue broadcasting with `state=Eliminated, count=1` until `RoundLifecycle.destroyAll`. Monotonic uint16 tick written each broadcast; client-side stale-packet defense lives in the Replication Broadcast epic.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: HIGH
**Engine Notes**: `UnreliableRemoteEvent.FireAllClients` is post-cutoff (May 2025) — verified via `replication-best-practices.md` §UnreliableRemoteEvent and Foundation network-layer-ext story-001. Luau `buffer.create / writeu* / writef32` is post-cutoff — verified via `luau-type-system.md` §buffer + Foundation buffer codec story-003. Multi-client + soak validation deferred to MVP integration sprint per ADR-0003 §Validation Sprint Plan; this story validates single-server-soak only.

**Control Manifest Rules (Core layer)**:
- Required: `broadcastAll(tickCount)` is Phase 8 sole caller TickOrchestrator (manifest L75); `UnreliableRemoteEvent CrowdStateBroadcast` at 15 Hz (L84); buffer encoding mandatory MVP — payload schema fixed at 30 B/crowd (L85); `tick: uint16` monotonic (L87); Eliminated crowds continue broadcasting with `state=Eliminated` until `RoundLifecycle.destroyAll` (L88).
- Performance: Phase 8 budget 0.4 ms; Network steady 5.4 KB/s for CrowdStateBroadcast (manifest L167 + L174).
- Forbidden: Never use UnreliableRemoteEvent for must-arrive discrete events (L147 — applies to lifecycle events; broadcast itself is OK).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-17 (Performance — Integration/Performance evidence required)** — 12 active crowds with O(p²)=66 pair overlap checks per tick. One full 15 Hz tick (state update + broadcast) total server CPU < 1 ms per the GDD wording. **Note**: the per-phase budgets per manifest are Phase 5 0.2 ms + Phase 8 0.4 ms = 0.6 ms total CSM contribution to a tick. The GDD's <1 ms target is a looser ceiling; passing the <1 ms threshold automatically satisfies the per-phase split. Evidence: `production/qa/evidence/csm-perf-soak-evidence.md` documents the 60-second soak in Roblox Studio with `os.clock()` deltas captured by story-005's instrumentation hook (TickOrch story-005). *Evidence type: Integration/Performance — not unit-testable in TestEZ; requires Studio profiler soak.*
- [ ] **AC-18 (Replication Correctness — Integration evidence required)** — Client subscribed to `CrowdStateBroadcast`, `CrowdRelicChanged`, and `CrowdEliminated`. Server mutates `count` 100→102 on a tick. Within 1 broadcast interval (≤67 ms at 15 Hz), client cache reflects `count=102`, `radius ≈ 8.05` studs, and no other broadcast field changes. Relic and Eliminated transitions fire correctly via reliable events. *Evidence type: Integration — multi-client Studio test.*
- [ ] **AC-20 (Eliminated Replication — Integration evidence required)** — Client C subscribed; B's server crowd transitions to Eliminated (grace timer expiry with overlap persisting). (a) Server fires `CrowdEliminated` with `{crowdId = B.crowdId}` BEFORE the next 15 Hz broadcast; (b) client C's state for B reflects Eliminated; (c) subsequent 15 Hz broadcasts for B continue to arrive but do NOT change the Eliminated flag back to Active or GraceWindow. *Evidence type: Integration — multi-client Studio test.*
- [ ] `broadcastAll(tickCount: number): ()` exposed per arch §5.1 L549.
- [ ] Per-broadcast logic:
  1. Walk `_crowds`. Include records where `state ∈ {"Active", "GraceWindow", "Eliminated"}` (do NOT prune Eliminated until `destroy`).
  2. For each included record, increment a per-record monotonic `tick` field (`record.tick = (record.tick + 1) % 65536`) — uint16 wrap.
  3. Build a 30 B/crowd buffer using Foundation `BufferCodec.CrowdState.encode(record)` (from network-layer-ext story-003).
  4. Concat per-crowd buffers into one outgoing buffer (or use the codec's batch helper — match the codec's actual API).
  5. `Network.fireAllClientsUnreliable(UnreliableRemoteEventName.CrowdStateBroadcast, finalBuffer)` — single fire per tick.
- [ ] Empty `_crowds` (e.g. Lobby state) → `broadcastAll` may skip the fire entirely OR send an empty buffer. **Decision**: skip the fire if no records included — saves trivial bandwidth in Lobby; clients tolerate gap (no packets to process means no state to update).
- [ ] Phase 8 hook is the SOLE call site of `Network.fireAllClientsUnreliable(CrowdStateBroadcast, ...)` — no other module fires this UREvent (audit grep).
- [ ] Performance: 12 records × 30 B = 360 B per tick × 15 Hz = 5.4 KB/s/client (manifest L174 budget) — validated by per-tick `os.clock` instrumentation against the Phase 8 0.4 ms budget.
- [ ] `record.tick` field starts at 0 in `create` (story-001) and increments only inside `broadcastAll`. Each crowd has its own monotonic counter.

---

## Implementation Notes

*Derived from ADR-0001 §Decision + amends + ADR-0003 §Network bandwidth + arch §5.7 wire contract:*

- The Foundation buffer codec at `ServerStorage/Source/Network/BufferCodec/CrowdState.luau` (or wherever network-layer-ext story-003 placed it) exposes `encode(record): buffer` + `decode(buf): CrowdRecord` + `recordSize: number = 30`. This story's `broadcastAll` uses `encode` only.
- Outgoing buffer assembly: total size = `recordSize * #includedRecords`. Allocate via `buffer.create(total)` once, then per-record `encode` into a fixed offset:
  ```lua
  local total = 30 * #included
  local out = buffer.create(total)
  for i, record in ipairs(included) do
      BufferCodec.CrowdState.encodeInto(out, (i - 1) * 30, record)  -- if codec supports offset-based write
  end
  ```
  If the codec only exposes `encode(record): buffer` (per-record), then build a list of per-record buffers and use `buffer.copy` to assemble, or pre-allocate and use `writeu8`/etc directly. Match whatever the codec actually shipped in network-layer-ext story-003.
- `Network.fireAllClientsUnreliable` must exist (Foundation network-layer-ext story-001 — already shipped). If the API name differs, match the actual exported name.
- `record.tick` increment placement: increment IN `broadcastAll` per record, BEFORE encoding so the encoded `tick` field is the post-increment value. Alternative: increment after encoding so the encoded value is N before tick++. **Decision**: increment first → encoded tick reflects the broadcast number for THIS broadcast. Per GDD L140 "Server writes `tick` as monotonic counter each broadcast".
- Eliminated continues broadcasting per GDD L139 — Phase 8 includes Eliminated records in the payload with `state=3` (Eliminated enum byte). The client mirrors this; Replication Broadcast epic owns client-side stale defense.
- AC-20 ordering: `CrowdEliminated` reliable fires from Phase 5 (story-006). Phase 8 runs AFTER Phase 7 per TickOrch sequence (manifest L60). So a same-tick Active→Eliminated transition: Phase 5 fires CrowdEliminated reliable; Phase 8 broadcast carries `state=Eliminated`. The reliable event arrives before-or-after the unreliable broadcast (cross-channel ordering tolerated per ADR-0001 §Negative L139 + Replication Broadcast epic AC TR-crs-021).

---

## Out of Scope

*Handled by neighbouring stories or epics — do not implement here:*

- **story-001..007**: Record schema, lifecycle, updateCount, hue, radius, position, state evaluator, read accessors — all upstream prereqs.
- **Foundation network-layer-ext story-001 / 003**: `Network.fireAllClientsUnreliable` API + `BufferCodec.CrowdState.encode` codec — already shipped; this story consumes them.
- **TickOrchestrator epic**: Phase 8 boot wiring (`CSMBroadcastAllStub.tick` → `CrowdStateServer.broadcastAll`) via `_registerPhases` table edit per tick-orchestrator story-003 stub-replacement contract.
- **Replication Broadcast epic**: Client-side `CrowdStateClient` mirror + `lastReceivedTick` stale defense + signal fanout to HUD/Nameplate/etc.
- **Multi-client soak validation**: Deferred to MVP integration sprint per ADR-0003 §Validation Sprint Plan; this story produces single-server perf evidence.

---

## QA Test Cases

*Integration story — manual + automated where possible.*

- **AC-17 (Manual perf check)**:
  - Setup: 12 active crowds + 60 NPCs in Studio test place (use a multi-bot fixture script if multi-client unavailable). Enable TickOrch instrumentation hook (`TickOrchestrator.setInstrumentationEnabled(true)`).
  - Verify: Run for 60 s. Read `getLastTickTimings()` periodically; record mean Phase 5 + Phase 8 duration.
  - Pass condition: Mean (Phase 5 + Phase 8) < 1.0 ms over 60 s; max < 2.0 ms (any spike >2 ms logged with cause). Document in `production/qa/evidence/csm-perf-soak-evidence.md`.

- **AC-17 (Automated payload size assertion)**:
  - Given: 12 records seeded; mock `Network.fireAllClientsUnreliable` capturing the buffer
  - When: `broadcastAll(tickCount=42)` invoked
  - Then: captured buffer length == 12 * 30 == 360 bytes; per-record `tick` field reads back as 1 (post-increment from initial 0) for all 12
  - Edge cases: 0 records → no fire (or empty buffer per chosen behavior); 1 record → 30-byte buffer

- **AC-18 (Manual multi-client check)**:
  - Setup: 2 clients connected to same Studio server. Server-side test script forces `updateCount(crowdA, +2, "Absorb")` from count=100 → 102.
  - Verify: Client console logs the `CrowdStateBroadcast` arrival within 67 ms of the server mutation; client-side `CrowdStateClient.get(crowdA).count == 102` and `radius ≈ 8.05` studs (precision ±0.01).
  - Pass condition: All ACs pass; no other broadcast field changed; document in `production/qa/evidence/csm-replication-correctness-evidence.md`.

- **AC-20 (Manual eliminated-replication check)**:
  - Setup: 2 clients, server-side script forces crowd B into GraceWindow with persistent overlap, advances time 3.5 s.
  - Verify: Client receives `CrowdEliminated` reliable event with `{crowdId=B}`; subsequent broadcasts continue to arrive for B with `state=Eliminated, count=1`; client-side flag for B stays "Eliminated" (does NOT revert to Active/GraceWindow on stale broadcast).
  - Pass condition: AC-20 (a)/(b)/(c) all pass; document in `production/qa/evidence/csm-eliminated-replication-evidence.md`.

- **broadcastAll empty path**: 0 records; invoke `broadcastAll(0)`; mock recorder asserts no fire occurred (or the chosen empty-buffer behavior matches spec).

- **broadcastAll uint16 wrap**: fixture initializes `record.tick = 65535`; invoke `broadcastAll`; assert `record.tick == 0` post-call (wrap-around).

- **Phase 8 sole-caller audit**: `grep -rn "fireAllClientsUnreliable.*CrowdStateBroadcast" src/` → only one match in `CrowdStateServer/init.luau` `broadcastAll` body.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/crowd-state-server/broadcastall_test.luau` (payload size, tick increment, wrap-around, empty path) + `production/qa/evidence/csm-perf-soak-evidence.md` (AC-17, 60-s soak) + `production/qa/evidence/csm-replication-correctness-evidence.md` (AC-18, multi-client) + `production/qa/evidence/csm-eliminated-replication-evidence.md` (AC-20, multi-client).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..007 (full CSM module surface); Foundation network-layer-ext story-001 (UREvent wrapper) + story-002 (RemoteEventName extensions) + story-003 (buffer codec)
- Unlocks: Replication Broadcast epic (CrowdStateClient consumes broadcasts); HUD / Nameplate / Follower Entity client-side reads; gate-check Pre-Production → Production re-evaluation (Core epic deliverable)
