# Story 004: Server-side broadcast loop wiring + Dormant → Active → Closing transport phase machine

> **Epic**: crowd-replication-broadcast
> **Status**: Ready
> **Layer**: Core (server-side)
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-replication-strategy.md` §States and Transitions (3-phase Dormant → Active → Closing)
**Requirement**: `TR-crs-017..020` (transport phase machine), `TR-crs-013` (Eliminated continues)
**ADR**: ADR-0001 §Decision (broadcast loop activation tied to round lifecycle); ADR-0002 §Phase 8 (TickOrchestrator drives the broadcast hook).
**ADR Decision Summary**: The broadcast transport has 3 phases mirroring round lifecycle: **Dormant** (no broadcast — Lobby state), **Active** (broadcasting — Active+Result+Intermission states), **Closing** (broadcasting drains then halts — destroyAll). Phase 8 of TickOrch unconditionally calls `CrowdStateServer.broadcastAll` (CSM story-008); this story coordinates when broadcastAll has crowds to send vs. empty (Dormant/Closing).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: TickOrch + Phase 8 (LOW); `Network.fireAllClientsUnreliable` (HIGH; Foundation-shipped).

**Control Manifest Rules (Core):**
- Required: TickOrchestrator sole accumulator (manifest L59); broadcastAll Phase 8 sole caller TickOrch (L75); Eliminated continues broadcasting until destroyAll (L88).

---

## Acceptance Criteria

- [ ] **AC-8 (Dormant → Active on createAll)** — `CrowdReplicationServer` Dormant (no broadcast loop active); `RoundLifecycle.createAll()` fires + crowd records created; broadcast accumulator loop starts within one Heartbeat; `CrowdStateBroadcast` fires within 67ms (1 tick at 15 Hz).
- [ ] **AC-9 (Active: post-elimination broadcast continues — Rule 13)** — Crowd transitions to Eliminated via grace-timer expiry; `destroyAll` NOT called; `CrowdStateBroadcast` continues to include that `crowdId` at every tick w/ `state=Eliminated`; broadcast does NOT drop until `destroyAll`.
- [ ] **AC-10 (Closing → Dormant on destroyAll)** — `RoundLifecycle.destroyAll()` called; next broadcast tick fires; no destroyed `crowdId` appears in payload; broadcast loop halts if zero records remain; no Lua error at empty-record edge.
- [ ] **Implementation note: This story's "transport phase machine" is implicit — there is no separate state field needed**. Phase 8 in TickOrch always runs (TickOrch always running between server boot and BindToClose). CSM `broadcastAll` (CSM story-008) iterates `_crowds` — empty `_crowds` → no fire (or empty payload, decision per CSM story-008 AC). So the Dormant/Active/Closing transitions ARE the round-lifecycle createAll/destroyAll boundaries, no extra code needed beyond the existing CSM behavior.
- [ ] AC-8 verification: end-to-end integration test. Setup: Lobby state (no `_crowds` records). Force `RoundLifecycle.createAll([A, B])`. Assert within 67ms (1 tick), client receives a `CrowdStateBroadcast` packet containing 2 crowd records.
- [ ] AC-9 verification: end-to-end integration test. Active state w/ 3 crowds. Force crowd C to Eliminated via fixture (CSM story-006). For 5 subsequent ticks: each broadcast packet includes C's record w/ `state=Eliminated, count=1`. (Per CSM story-008 AC: Eliminated records are still included in broadcast.)
- [ ] AC-10 verification: end-to-end integration test. Active state w/ 3 crowds. `RoundLifecycle.destroyAll()`. Next broadcast tick: payload empty (or fire skipped). No error in any phase.
- [ ] AC-9 implicit dependency on CSM story-008 broadcastAll behavior — AC validated here, implementation sits in CSM. This story owns the integration test that proves CSM + RoundLifecycle + TickOrch together produce the expected broadcast behavior under round-lifecycle transitions.
- [ ] No new module needed. This story only adds:
  - Integration test fixtures
  - A documentation note in CSM module + Round Lifecycle module clarifying the transport-phase semantics emerge from existing behavior (no separate state field)

---

## Implementation Notes

- The "transport phase machine" in CRS GDD is a CONCEPTUAL framing of the round-lifecycle-driven activation, not a separate state machine to build. AC-8, AC-9, AC-10 are end-to-end integration assertions that the existing CSM + RoundLifecycle + TickOrch composition produces the correct broadcast behavior.
- AC-9 hinges on CSM story-008 implementation — `broadcastAll` includes Eliminated records (per CSM story-008 AC: "Eliminated continues broadcasting"). This story's test directly verifies that integration.
- AC-10 hinges on CSM story-008 implementation — empty `_crowds` → no fire (CSM story-008 chose-skip behavior).
- This story's deliverable is THE INTEGRATION TEST + a brief doc note. It does NOT add code modules.
- Doc note location: `docs/architecture/control-manifest.md` already documents the broadcast contract; this story optionally adds a one-line clarifier under CSM section: "// Transport phase semantics: Dormant/Active/Closing emerge from RoundLifecycle createAll/destroyAll; no separate state field." (low priority — control-manifest is authoritative).

---

## Out of Scope

- story-001..003: client-side mirror + subscribers
- story-005: F1 bandwidth + static gates + perf
- CSM story-008: server-side broadcastAll implementation (this story tests its emergent behavior)
- RoundLifecycle epic: createAll/destroyAll implementation
- TickOrchestrator epic: Phase 8 wiring

---

## QA Test Cases

- **AC-8 (integration)**:
  - Setup: Multi-test-place fixture with TickOrch + CSM + RoundLifecycle module wired (use stubs for everything else); client recorder subscribed to `CrowdStateBroadcast` UREvent.
  - Action: from Lobby state, invoke `RoundLifecycle.createAll([A, B])`.
  - Verify: within 67ms (1 tick at 15Hz), client recorder logs at least one packet w/ 2-record buffer (60 bytes).
  - Pass: AC met. Document evidence in `production/qa/evidence/csm-replication-correctness-evidence.md`.

- **AC-9 (integration)**:
  - Setup: Active state w/ 3 crowds A/B/C in CSM. Client recorder running.
  - Action: force C to Eliminated via fixture (e.g. mock count=1 + stillOverlapping=true + advance os.clock 3.5s + invoke Phase 5 `stateEvaluate`).
  - Verify: for 5 subsequent ticks, recorder logs packets containing C's record w/ `state=3 (Eliminated)` and `count=1`. C is NOT removed from broadcasts.
  - Pass: AC met.

- **AC-10 (integration)**:
  - Setup: Active state w/ 3 crowds. Client recorder running.
  - Action: invoke `RoundLifecycle.destroyAll()`.
  - Verify: next broadcast tick — payload empty OR no fire (matches CSM story-008 chosen behavior). No error in TickOrch / CSM logs.
  - Pass: AC met.

- **No new module audit**: `ls src/` post-this-story — no new directory under `src/ServerStorage/Source/CrowdReplication*` (this story does NOT introduce a separate module).

---

## Test Evidence

`tests/integration/crowd-replication-broadcast/transport_phase_machine.spec.luau` (AC-8/9/10) — multi-system integration test.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: CSM story-008 (broadcastAll); RoundLifecycle story-001 (createAll/destroyAll); TickOrch stories 001+002+003 (boot wiring + Phase 8 dispatch)
- Unlocks: gate-check Pre-Production → Production re-evaluation
