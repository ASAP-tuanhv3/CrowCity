# Epic: TickOrchestrator

> **Layer**: Core
> **GDD**: design/gdd/crowd-collision-resolution.md (TickOrchestrator is the §15a spin-off; canonical spec lives in ADR-0002 + architecture.md §5.4 + §3.2)
> **Architecture Module**: TickOrchestrator (architecture.md §3.2 row 1)
> **Status**: Ready (5 stories drafted 2026-04-27)
> **Stories**: 5 Ready

## Stories

| # | Story | Type | Status | Primary ADR |
|---|-------|------|--------|-------------|
| 001 | [Core module skeleton + accumulator + cadence + start/stop API](story-001-core-module-skeleton-cadence.md) | Logic | Ready | ADR-0002 |
| 002 | [Phase dispatch loop + pcall isolation + ctx assembly](story-002-phase-dispatch-pcall-isolation.md) | Logic | Ready | ADR-0002 |
| 003 | [Boot-time static 9-phase wiring in start.server.luau](story-003-boot-wiring-static-phase-table.md) | Integration | Ready | ADR-0002 |
| 004 | [BindToClose stop() coordination](story-004-bindtoclose-shutdown-coordination.md) | Integration | Ready | ADR-0002 + ADR-0005 |
| 005 | [Per-phase instrumentation hook (mobile jitter telemetry)](story-005-per-phase-instrumentation-hook.md) | Logic | Ready | ADR-0002 §Risks + ADR-0003 |

Order: 001 → 002 → 003 → 004 + 005 (004 and 005 parallelizable after 003).

## Overview

This epic delivers the single 15 Hz server-side tick loop that drives every gameplay phase. One `RunService.Heartbeat` connection accumulates dt, fires the 9 ordered phase callbacks per tick (Collision → Relic → Absorb → Chest → CSM:Eval → MSM:Timer → MSM:Elim → CSM:Cast → PeelDispatch), and exposes a strict no-yield, statically-wired contract. Phases are registered once at server boot via `_registerPhases`; no external `registerPhase` API exists at runtime. The orchestrator is the deterministic heartbeat the entire Core + Feature layer compose against — every other Core epic registers a `tick(ctx)` callback into one of the 9 slots.

Without this epic, no Core or Feature module can run at the canonical cadence: CSM cannot evaluate states (Phase 5), broadcast (Phase 8), MSM cannot enforce the 5-min timer (Phase 6) or drain elimination signals (Phase 7), and Collision/Relic/Absorb/Chest have no scheduling host.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: TickOrchestrator | 15 Hz fixed cadence, 9-phase deterministic ordering, single Heartbeat accumulator, no-yield phase contract, simultaneity rules (Phase 6 < Phase 7) | MEDIUM (mobile Heartbeat jitter; iPhone SE untested) |
| ADR-0003: Performance Budget | Per-phase ms budgets that all phase callbacks must respect (Phase 1 0.6 ms, Phase 5/8 0.6 ms, Phase 6/7 0.1 ms total) | MEDIUM (multi-client + soak validation deferred to MVP integration) |
| ADR-0006: Module Placement Rules | Core layer source tree map; Heartbeat ownership lives only in TickOrchestrator (Feature systems must NOT register their own Heartbeat) | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| (no `tick-orchestrator` system slug in tr-registry.yaml) | Indirect coverage — every gameplay-tick TR routes through one of the 9 phase slots | ADR-traced via consumer epics |
| TR-systems-index-005 | 15 Hz server tick orchestration | ✅ ADR-0002 §Decision |
| TR-csm-008 | Tick simultaneity rule | ✅ ADR-0002 §simultaneity |
| TR-csm-019 | CCR symmetry rule (Phase 1 ordering) | ✅ ADR-0002 §Phase 1 |
| TR-csm-020 | Per-tick budget Phase 5/8 | ✅ ADR-0003 |
| TR-msm-005 | Timer check Phase 6 | ✅ ADR-0002 §Phase 6 |
| TR-msm-007 | Phase 6 < Phase 7 simultaneity | ✅ ADR-0002 |
| TR-msm-018 | MSM Phase 6/7 budget | ✅ ADR-0003 |
| TR-msm-019 | Cadence accuracy | ✅ ADR-0002 §Decision |
| TR-ccr-001 | Phase 1 ordering | ✅ ADR-0002 |
| TR-ccr-011 | Phase 9 PeelDispatch | ✅ ADR-0002 |
| TR-ccr-015 | Phase ordering invariant | ✅ ADR-0002 |
| TR-ccr-018 | Equal-count simultaneity | ✅ ADR-0002 |
| TR-relic-007 | Relic Phase 2 ordering | ✅ ADR-0002 |
| TR-relic-008 | Phase 2 + Phase 3 visibility | ✅ ADR-0002 |
| TR-chest-016 | Chest Phase 4 cadence | ✅ ADR-0002 |
| TR-chest-020 | Atomicity in tick | ✅ ADR-0002 |
| TR-absorb-001 | Phase 3 cadence | ✅ ADR-0002 |

⚠️ TickOrchestrator has no system-slug TR rows — this is intentional (orchestrator is the contract host, not a domain producer). Stories cite ADR-0002 directly + architecture.md §5.4 for the public API.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, and closed via `/story-done`
- `TickOrchestrator/init.luau` exposes `start()`, `stop()`, `getCurrentTick()`, `setTickDelegate(fn)`, `_registerPhases(table)` (boot-only, internal) per architecture.md §5.4
- 9-phase callback table statically wired at boot; runtime `registerPhase` API does NOT exist
- Single `RunService.Heartbeat` accumulator drains accumulated dt at 1/15 s steps; tick queue on lag fires sequentially in same callback (no loss, no double)
- Exception in any phase callback logged via `pcall` + remaining phases of the current tick continue executing; next tick re-runs all phases (per ADR-0002 §Decision Simultaneity Resolution + §Validation Criteria L7)
- `BindToClose` calls `TickOrchestrator.stop()` before MSM `ServerClosing` broadcast (architecture.md §4.5)
- Logic stories pass automated TestEZ tests in `tests/unit/tick-orchestrator/` (cadence determinism w/ injected clock, phase ordering, no-yield assertion via wrapped Heartbeat fixture)
- Mobile jitter telemetry hook in place (instrumented but not validated this sprint — defers to MVP integration)
- All Core+Feature tick consumers can register their `tick(ctx)` callback at boot via the static phase table

## Next Step

Run `/create-stories tick-orchestrator` to break this epic into implementable stories.
