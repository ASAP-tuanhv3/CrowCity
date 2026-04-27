# ADR-0002: TickOrchestrator — 15 Hz Server Tick Sequencing

## Status

**Accepted 2026-04-26** (validated by `/architecture-review` 2026-04-26 — verdict CONCERNS at project level; ADR-0002 specifically had no blocking issues and is a foundational dep of ADR-0003/0004/0005/0008).

Status history:
- 2026-04-24 — Proposed (initial)
- **2026-04-26 — ACCEPTED** (batch flip with ADR-0001/0003/0004/0006)

## Date

2026-04-24 (initial), 2026-04-26 (Accepted)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — `RunService.Heartbeat` stable API predating LLM cutoff; accumulator pattern widely documented in creator forum |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md`, ADR-0001 §Decision, CSM §E implementation note, MSM §Core Rules (TickOrchestrator phase table), CCR §15a |
| **Post-Cutoff APIs Used** | None — uses only `RunService.Heartbeat` + `os.clock` + standard Luau control flow |
| **Verification Required** | (A) Heartbeat callback jitter ≤5 ms on iPhone SE emu over 60 s soak; (B) 9-phase sequence deterministic across server restarts; (C) tick-loss/tick-double test under artificial lag spike (`task.wait(0.5)` injection); (D) exception-in-phase recovery test |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (Crowd Replication Strategy — locks 15 Hz cadence) |
| **Enables** | ADR-0004 (CSM Authority), ADR-0005 (MSM/RoundLifecycle Split), ADR-0008 (NPC Spawner) — all downstream orchestrated systems |
| **Blocks** | Every server gameplay story (Collision, Absorb, Chest, Relic, CSM eval, MSM timer, MSM elim, broadcast, peel) — cannot start without this locked |
| **Ordering Note** | Must be Accepted before `/create-control-manifest`. Must be Accepted before any Phase 1-9 implementation story enters a sprint. Architecture doc `docs/architecture/architecture.md` §5.4 + §5.8 already depends on this decision. |

## Context

### Problem Statement

Crowdsmith gameplay requires deterministic same-tick ordering across 9 handler phases on the server. Without explicit sequencing:

1. **Elimination race** — a crowd at count=1 hit by Collision drain in the same tick an Absorb would restore it produces ambiguous state (eliminated or saved?).
2. **State machine feedback** — CSM transitions a crowd to `Eliminated`, fires `CrowdEliminated` signal; MSM consumes it in the same tick. Without phase ordering, MSM cannot know whether a signal came from this tick's CSM evaluation or a prior tick.
3. **T6 vs T7 simultaneity** — at round expiry (t=300s) the second-to-last crowd can be eliminated on the same tick. Both "last standing" (T6) and "timer expired" (T7) would fire. Winner determination becomes non-deterministic without explicit priority.
4. **Broadcast atomicity** — clients must receive count/radius/state as a single snapshot, not mid-mutation stale state. Phase 8 broadcast must see post-everything-else state.

ADR-0001 locked the 15 Hz cadence. No module implements the accumulator yet. GDDs (CCR §C Rule 8, MSM §Core Rules, CSM §E, Absorb, Chest, Relic) each specify their tick contracts independently, all implying a central orchestrator but none owning it. This ADR names and locks that orchestrator.

### Constraints

- **Single-threaded Luau** — Roblox server runs one Luau VM; `Heartbeat` fires once per frame. Must chain all 9 phases within one callback.
- **Determinism required** — replay + testability rely on identical phase sequence every run.
- **No yielding inside phases** — `task.wait` / `task.defer` / async yields would split a tick across frames, break atomicity (count writes then broadcast fires on different frames).
- **Static phase table** — post-Acceptance phase insertion or reorder requires ADR amendment + GDD amendment + `/propagate-design-change`. Runtime registration API forbidden to prevent uncontrolled growth.
- **Accumulator under lag** — if `Heartbeat` delivers large `dt` after platform pause, must fire multiple ticks back-to-back without loss or double-tick.
- **No cross-server state** — TickOrchestrator is per-server singleton. No DataStore. No MessagingService.

### Requirements

- 15 Hz cadence (1/15 s = 66.67 ms per tick) locked by ADR-0001
- 9 phases run sequentially, in fixed order (Collision → Relic → Absorb → Chest → CSM eval → MSM timer → MSM elim → Broadcast → Peel) every tick
- Synchronous phase dispatch — no yields, no deferrals, no events queued across ticks
- Single `Heartbeat` connection; no other module may create a competing accumulator
- Tick counter exposed to phases for telemetry and replay-debug
- Exception in one phase must not halt the orchestrator permanently — log, continue next Heartbeat

## Decision

**TickOrchestrator is a server-only singleton module that owns the sole `RunService.Heartbeat` accumulator for gameplay cadence. Every 1/15 s of accumulated `dt`, it runs the 9-phase sequence synchronously. Phases are statically wired at boot in `ServerScriptService/start.server.luau`. The module exposes `start()`, `stop()`, `getCurrentTick()`, and a test-only delegate hook. No runtime phase registration.**

### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│ TickOrchestrator (server-only, single instance)                │
│                                                                │
│  fields:                                                       │
│    _accumulator: number                   = 0                  │
│    _tickCount: number                     = 0                  │
│    _heartbeatConnection: RBXScriptConnection?                  │
│    _phases: { TickPhase }                 (9 entries)          │
│    _tickDelegate: ((number) -> ())?       (test hook only)     │
│    _tickPeriod: number                    = 1 / 15             │
│                                                                │
│  start():                                                      │
│    _heartbeatConnection = RunService.Heartbeat:Connect(dt -> ) │
│    callback:                                                   │
│      _accumulator += dt                                        │
│      while _accumulator >= _tickPeriod:                        │
│        _accumulator -= _tickPeriod                             │
│        _runTick(_tickCount)                                    │
│        _tickCount += 1                                         │
│                                                                │
│  _runTick(tickCount):                                          │
│    if _tickDelegate ~= nil then                                │
│      _tickDelegate(tickCount)                                  │
│      return                                                    │
│    end                                                         │
│    ctx = { tickCount, outPairs = {}, outPeel = {} }            │
│    for each phase in _phases, ordered 1..9:                    │
│      ok, err = pcall(phase.callback, tickCount, ctx)           │
│      if not ok then log(phase.name, err); continue end         │
└────────────────────────────────────────────────────────────────┘
```

### Phase sequence (locked)

| Phase | System | Responsibility |
|---|---|---|
| 1 | CollisionResolver | O(p²) pair overlap check; F3 drip into `CSM.updateCount(±, "Collision")`; populates `ctx.outPairs` + `ctx.outPeel` |
| 2 | RelicEffectHandler | per-crowd duration countdown + `onTick` hooks; count-mutating relics call `CSM.updateCount(delta, "Relic")`; Wingspan calls `CSM.recomputeRadius` |
| 3 | AbsorbSystem | proximity check vs `NPCSpawner.getAllNeutrals()`; `CSM.updateCount(+1, "Absorb")` per absorbed NPC |
| 4 | ChestSystem | 6-guard pipeline on queued prompt triggers; `CSM.updateCount(-effectiveToll, "Chest")` on claim; chest state-machine timers (Cooldown → Respawning → Available) |
| 5 | CSM.stateEvaluate | F7 grace-timer check; Active↔GraceWindow transitions; GraceWindow→Eliminated on timer expiry; fires `CrowdEliminated` reliable per transition |
| 6 | MSM.timerCheck | T7: if `matchState==Active` AND `elapsed>=300s` → `transitionTo("Result")`; winner via F4 |
| 7 | MSM.eliminationConsumer | drains `CrowdEliminated` queued in P5; T6: if `numActiveNonEliminated<=1` AND `matchState==Active` → `transitionTo("Result")`; double-signal guard |
| 8 | CSM.broadcastAll | builds buffer payload (30 B × #active crowds); `fireAllClients(CrowdStateBroadcast, buf)` via `UnreliableRemoteEvent` |
| 9 | PeelDispatcher.flush | batched `fireClient(ChestPeelOff, ...)` per player using `ctx.outPeel` from P1 |

### Key Interfaces

```lua
-- Path: ServerStorage/Source/TickOrchestrator/init.luau
--!strict

local RunService = game:GetService("RunService")

export type TickContext = {
    tickCount: number,
    outPairs: { any },   -- typed in CCR module as { CollisionPair }
    outPeel: { any },    -- typed in CCR module as { PeelEntry }
}

export type TickPhase = {
    phase: number,       -- 1..9
    name: string,
    callback: (tickCount: number, ctx: TickContext) -> (),
}

export type ClassType = typeof(setmetatable({} :: {
    _accumulator: number,
    _tickCount: number,
    _heartbeatConnection: RBXScriptConnection?,
    _phases: { TickPhase },
    _tickDelegate: ((number) -> ())?,
}, {} :: any))

-- Public API
function TickOrchestrator.start(): ()
function TickOrchestrator.stop(): ()
function TickOrchestrator.getCurrentTick(): number

-- Test hook (integration tests only — never called from production code)
function TickOrchestrator.setTickDelegate(fn: ((tick: number) -> ())?): ()

-- Internal (called once at boot from ServerScriptService/start.server.luau;
-- not exported for external use)
function TickOrchestrator._registerPhases(phases: { TickPhase }): ()
```

### Phase registration (boot-only, static)

```lua
-- ServerScriptService/start.server.luau — after all module requires, before TickOrchestrator.start()
TickOrchestrator._registerPhases({
    { phase = 1, name = "Collision",    callback = CollisionResolver.tick },
    { phase = 2, name = "Relic",        callback = RelicSystem.tick },
    { phase = 3, name = "Absorb",       callback = AbsorbSystem.tick },
    { phase = 4, name = "Chest",        callback = ChestSystem.tick },
    { phase = 5, name = "CSM:Eval",     callback = CrowdStateServer.stateEvaluate },
    { phase = 6, name = "MSM:Timer",    callback = MatchStateServer.timerCheck },
    { phase = 7, name = "MSM:Elim",     callback = MatchStateServer.eliminationConsumer },
    { phase = 8, name = "CSM:Cast",     callback = CrowdStateServer.broadcastAll },
    { phase = 9, name = "PeelDispatch", callback = PeelDispatcher.flush },
})
TickOrchestrator.start()
```

`_registerPhases` asserts `#phases == 9` and `phase` values are 1..9 unique. Fails loud at boot if any is wrong.

### Simultaneity resolution rules (formalised)

- **T6 vs T7 same tick**: Phase 6 (MSM.timerCheck) runs before Phase 7 (MSM.eliminationConsumer). If timer expiry fires T7 first, `matchState==Result`. Phase 7's double-signal guard (`matchState != Active`) drops queued `CrowdEliminated`. Winner resolved by F4 tiebreak using counts at Phase 6 evaluation time (post-Phase 1-4 drains).
- **Double-elim same tick**: Phase 5 fires both `CrowdEliminated` signals. Phase 7 drains. First signal triggers T6 → `transitionTo("Result")`. Second signal's `matchState==Active` check fails → silently dropped.
- **Grace entry + overlap-clear same tick**: Phase 1 drains count to 1 and calls `setStillOverlapping(id, true/false)`. Phase 5's F7 evaluates with the Phase 1 flag. Overlap-clear priority (CSM AC-13) naturally wins because `still_overlapping == false` → `should_eliminate = false`.
- **Exception in phase X**: `pcall` wrapper logs + continues remaining phases. Affected phase's state mutation may be partial; next tick recovers. No permanent halt.

## Alternatives Considered

### Alternative 1: Each system registers its own `Heartbeat` callback

- **Description**: CollisionResolver, AbsorbSystem, ChestSystem, etc. each call `RunService.Heartbeat:Connect` independently at their own 15 Hz cadence.
- **Pros**: Decoupled; no central coordination module.
- **Cons**: Race conditions on CSM count mutations (callback order undefined). Broadcast fire-time ambiguous. T6/T7 simultaneity unresolvable. Testing flaky.
- **Rejection Reason**: Breaks determinism required for replay + testing. Contradicts Pillar 5 "Comeback Always Possible" — players must be able to understand why a given tick eliminated them.

### Alternative 2: Event-queue dispatcher with runtime phase subscription

- **Description**: Central `EventEmitter`-style dispatcher. Systems subscribe to `tick` signal. Dispatcher drains on `Heartbeat`.
- **Pros**: Flexible — new systems opt in at runtime. Decouples registration from implementation.
- **Cons**: Subscription order implicit in subscribe-call-order. Hard to enforce "Phase X before Phase Y". Debugging harder — callback order not visible at read time. Dispatcher queue overhead. Risk of subscribers yielding/deferring.
- **Rejection Reason**: Flexibility not needed for MVP's fixed 9 phases. If post-MVP needs dynamic phases, amend this ADR explicitly; don't default to implicit dispatch.

### Alternative 3: Separate fast (30 Hz Absorb) + slow (15 Hz everything else) orchestrators

- **Description**: AbsorbSystem runs at 30 Hz to give tighter NPC-pickup feel. CSM broadcast + Collision + Chest stay at 15 Hz.
- **Pros**: Finer-grained absorb reactivity.
- **Cons**: Phase ordering becomes implicit in frequency ratio. CSM state-eval has no single "post-everything" moment. Much more complex testing. Violates single-source-of-truth principle.
- **Rejection Reason**: Prototype confirmed 15 Hz sufficient for absorb feel. Revisit if playtest surfaces "absorb feels sluggish" — revisit then, not now.

### Alternative 4: Frame-synchronous dispatch on `RunService.Stepped` (post-physics, pre-rendering)

- **Description**: Bind to `Stepped` instead of `Heartbeat`.
- **Pros**: Slightly earlier in frame; marginally better latency.
- **Cons**: `Stepped` fires before physics simulation resolves on server — character positions used by CSM position-lag not yet final. `Heartbeat` fires AFTER physics so character positions are settled.
- **Rejection Reason**: CSM F2 position-lag reads `Character.HumanoidRootPart.Position`. Needs post-physics value. `Heartbeat` is the correct hook.

## Consequences

### Positive

- **Deterministic state machines** — T6/T7 simultaneity and all same-tick ordering questions resolve identically every run
- **Atomic broadcasts** — clients see full-tick snapshots, never mid-mutation
- **Single source of truth** — every "does X fire before Y?" question answered by reading the phase table
- **Single `Heartbeat` connection** — no callback jitter from competing accumulators
- **Easy debugging** — replay/step a tick, walk phases in order
- **Exception isolation** — one phase crashing doesn't corrupt whole-server state; next tick recovers
- **Unblocks all 9 Phase systems** — ADR-0004/0005/0008 can now reference a concrete orchestration contract

### Negative

- **Rigid phase sequence** — adding a phase requires ADR amendment + multi-GDD edit + `/propagate-design-change`. Intentional friction.
- **Single-point-of-failure** — all 9 systems depend on TickOrchestrator; if its init or `start()` fails, server is dead. Criticality is acceptable given LOW engine risk on `Heartbeat`.
- **No yielding inside phases** — phase callbacks cannot await. Limits design space for phase implementations that want async. MVP phases are all synchronous; post-MVP needs would require ADR amendment.
- **Global per-tick CPU budget** — no per-phase protection. If Phase 1 runs slow, Phase 2-9 push late. ADR-0003 will set per-phase budgets and tolerance margins.

### Risks

- **Risk 1 (MEDIUM)** — Mobile `Heartbeat` timing variance. iPhone SE scheduler may deliver `dt` with >5 ms jitter. Mitigation: measure at first MVP integration on iPhone SE emu via `os.clock` per-phase timing. If jitter blocks 15 Hz target, consider fixed-rate `task.wait(1/15)` loop as fallback (amend ADR).
- **Risk 2 (LOW)** — Phase exception log noise. A consistently-failing phase spams server log. Mitigation: rate-limit per-phase error log to 1/sec per unique error. Deferred to implementation detail, not ADR-level.
- **Risk 3 (LOW)** — Future system needs mid-sequence insertion. Mitigation: amend this ADR and ADR-0005/MSM/CCR GDDs via `/propagate-design-change` pass. Non-trivial cost intentional; prevents accidental phase-sequence drift.
- **Risk 4 (LOW)** — Tick catch-up on platform pause. If Roblox pauses the server for 500 ms, accumulator accrues 7.5 ticks. Mitigation: `while` loop drains all accrued ticks synchronously in one `Heartbeat` — no tick loss. Cap at (e.g.) 10 catch-up ticks max would drop state if platform hangs severely; deferring to implementation until playtest shows need.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/crowd-collision-resolution.md` §15a | "TickOrchestrator spin-off introduced by CCR — hosts the tick loop that calls CollisionResolver first" | Phase 1 locked as CollisionResolver.tick |
| `design/gdd/match-state-machine.md` §Core Rules (Batch 4) | 9-phase table with T6/T7 simultaneity resolver via Phase 6 before Phase 7 | Phase sequence locked exactly as MSM specifies |
| `design/gdd/crowd-state-manager.md` §E implementation note | "Broadcast dispatched via Heartbeat accumulator pattern — accumulator increments each `RunService.Heartbeat`; broadcast fires when `accumulator >= 1/SERVER_TICK_HZ`, then resets" | ADR formalises the accumulator as TickOrchestrator's sole responsibility; CSM owns only Phase 5 + Phase 8 callbacks |
| `design/gdd/absorb-system.md` | Absorb runs as server 15 Hz tick phase | Phase 3 locked as AbsorbSystem.tick |
| `design/gdd/chest-system.md` | Chest runs at Phase 4 (last count-mutator) so guard sees post-drain count | Phase 4 locked as ChestSystem.tick |
| `design/gdd/relic-system.md` | Relic runs Phase 2 (after Collision drain settles, before Absorb gains) | Phase 2 locked as RelicSystem.tick |
| ADR-0001 §Decision | 15 Hz server tick rate | `_tickPeriod = 1/15` constant in TickOrchestrator |

## Performance Implications

- **CPU (server)**: accumulator check + 9 function dispatches ≈ <0.1 ms overhead per tick. Phase work itself governed by each phase's own ADR/GDD budget. ADR-0003 will consolidate total-tick budget to 3 ms/tick (5% of 66.67 ms tick period).
- **CPU (client)**: zero — TickOrchestrator is server-only.
- **Memory (server)**: ~200 B scalar state + 9-entry phase table + per-tick `ctx.outPairs` / `ctx.outPeel` scratch buffers. `outPairs` bounded at ≤66 pairs (O(p²) with 12 crowds). `outPeel` bounded at per-chest peel burst. ~2 KB worst case.
- **Memory (client)**: zero.
- **Load Time**: one-time `Heartbeat:Connect` at server boot. Negligible.
- **Network**: zero direct; Phase 8 dispatches broadcast — cost governed by ADR-0001.

## Migration Plan

No existing orchestrator. Clean implementation.

1. Implement `ServerStorage/Source/TickOrchestrator/init.luau` with accumulator loop, `start/stop/getCurrentTick/setTickDelegate`, `_registerPhases` (9-entry assert).
2. Each Phase 1-9 system refactors to expose `tick(tickCount, ctx)` conformant callback. No independent `Heartbeat:Connect` anywhere else.
3. Wire `_registerPhases` + `start()` in `ServerScriptService/start.server.luau` after all module requires.
4. Integration test: deterministic step via `setTickDelegate`, verify 9-phase sequence replays identically.
5. Soak test 60 s on iPhone SE emu — log per-phase `os.clock` delta — confirm total tick <3 ms and jitter <5 ms.

## Validation Criteria

- [ ] `Heartbeat` accumulator fires at 15 Hz (±0.1 % desktop, ±0.3 % mobile over 60 s)
- [ ] 9 phases execute in order every tick — verified via instrumented `setTickDelegate` replay (identical output twice)
- [ ] T6 vs T7 simultaneity: fixture where round expires at same tick as last-standing — confirm winner via F4 tiebreak (not via last-standing)
- [ ] Double-elim same tick: only one T6 transition fires; `MatchStateChanged` broadcasts exactly once
- [ ] Injected `task.wait(0.5)` inside a phase — orchestrator continues remaining phases, next tick resumes cleanly (with logged error)
- [ ] Injected `error()` inside Phase 3 — Phase 4-9 still run this tick; Phase 3 error logged; next tick Phase 3 runs again
- [ ] Total per-tick CPU <3 ms at 12 crowds × 300 followers × 60 NPCs (target)
- [ ] `TickOrchestrator.stop()` halts within <5 ms of call; no further phase dispatches observed

## Related Decisions

- **ADR-0001** (Crowd Replication Strategy) — locks 15 Hz cadence + UnreliableRemoteEvent; this ADR implements the cadence
- `docs/architecture/architecture.md` §5.4 + §5.8 — API boundary + boot wiring
- **Expected downstream ADRs**:
  - ADR-0003 Performance Budget — sets per-phase CPU allocation within 3 ms/tick
  - ADR-0004 CSM Authority — Phase 5 + Phase 8 callback contract
  - ADR-0005 MSM/RoundLifecycle Split — Phase 6 + Phase 7 callback contract
  - ADR-0008 NPC Spawner Authority — NPC Spawner runs OWN cadence (not a Phase 1-9 callback — spawns are not 15 Hz work)

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). `gameplay-programmer` or `lead-programmer` would be the routing target; both operate at code-review tier, not architectural design review. Accumulator pattern is extensively documented in Roblox creator forum (`devforum.roblox.com` Heartbeat tuning threads) and used in ADR-0001 reference code. If Roblox engine best practices drift post-Acceptance, re-verify via `/setup-engine refresh`.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
