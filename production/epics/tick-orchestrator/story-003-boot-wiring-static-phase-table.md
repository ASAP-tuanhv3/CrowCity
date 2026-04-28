# Story 003: Boot-time static 9-phase wiring in start.server.luau

> **Epic**: tick-orchestrator
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md` (TickOrchestrator §15a + canonical ADR-0002 §Phase Registration); architecture.md §5.8 (Phase registration boot-time wiring)
**Requirement**: `TR-systems-index-005` (15 Hz orchestration); cross-system coverage of phase-ordering TRs (`TR-csm-019`, `TR-msm-007`, `TR-relic-007`, `TR-chest-016`, `TR-absorb-001`, `TR-ccr-001/011/015`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 — TickOrchestrator — 15 Hz Server Tick Sequencing
**ADR Decision Summary**: 9-phase callback table is statically wired at server boot in `ServerScriptService/start.server.luau` after all module requires; `_registerPhases` then `start()` called in that order; phase entries reference the canonical 9 module callbacks (Collision, Relic, Absorb, Chest, CSM:Eval, MSM:Timer, MSM:Elim, CSM:Cast, PeelDispatch).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: MEDIUM
**Engine Notes**: `ServerScriptService/start.server.luau` already exists in template per CLAUDE.md "Two-entry-point model". This story adds a TODO-block-anchored section that requires the orchestrator + 9 phase modules and wires them. Phase modules' real `tick(tickCount, ctx)` implementations live in the consuming epics (CSM/MSM/RoundLifecycle/etc.); this story uses NO-OP stub callbacks where the consuming module hasn't shipped yet.

**Control Manifest Rules (Core layer)**:
- Required: Phases statically wired at boot in `ServerScriptService/start.server.luau` after all module requires (manifest L61); 9-phase sequence locked exactly per L60.
- Required: TickOrchestrator at `ServerStorage/Source/TickOrchestrator/init.luau` is the sole accumulator (L59).
- Forbidden: Never register phases at runtime (L133).

---

## Acceptance Criteria

*From ADR-0002 §Phase Registration (L162-178) + architecture.md §5.8 + control-manifest L60-L61, scoped to this story:*

- [ ] `src/ServerScriptService/start.server.luau` contains a marked block (`-- TickOrchestrator boot wiring (ADR-0002)`) that runs AFTER all module-level `require` calls and BEFORE any per-player setup logic
- [ ] The block requires `TickOrchestrator` from `ServerStorage.Source.TickOrchestrator` and the 9 phase-owning modules (or no-op stubs where the real module hasn't shipped). Stub modules live under `ServerStorage/Source/_PhaseStubs/` and each export a single `function Stub.tick(tickCount: number, ctx: any): () end` no-op
- [ ] Stub modules are wired for any phase whose owning epic hasn't been implemented yet — the canonical Phase-1 callback name is `CollisionResolver.tick`, but until CCR epic ships a real `CollisionResolver`, the boot wiring uses `CollisionResolverStub.tick`. Each stub's filename matches its phase: `CollisionResolverStub.luau`, `RelicSystemStub.luau`, `AbsorbSystemStub.luau`, `ChestSystemStub.luau`, `CSMStateEvaluateStub.luau`, `MSMTimerCheckStub.luau`, `MSMEliminationConsumerStub.luau`, `CSMBroadcastAllStub.luau`, `PeelDispatcherStub.luau`. Each is replaced by its consuming epic via in-place rename of the `_registerPhases` argument when the real module ships
- [ ] `_registerPhases` is called with EXACTLY the 9-entry table per ADR-0002 §Phase Registration L164-174 — `{ phase = N, name = "...", callback = ... }` for N ∈ 1..9 with the names matching the manifest L60 sequence (`Collision`, `Relic`, `Absorb`, `Chest`, `CSM:Eval`, `MSM:Timer`, `MSM:Elim`, `CSM:Cast`, `PeelDispatch`)
- [ ] `TickOrchestrator.start()` is called immediately after `_registerPhases` and the call site comment cites `ADR-0002 §Phase Registration L162-178`
- [ ] No other module anywhere in `src/` registers a competing `RunService.Heartbeat:Connect` for gameplay-tick work (audit grep). NPCSpawner exemption (manifest L197) is documented separately in NPC epic
- [ ] Integration replay: stub phase callbacks each push their `phase.phase` integer into a shared recorder list; after running 30 ticks of real `RunService.Heartbeat`, the recorder list = `{1,2,3,4,5,6,7,8,9}` repeated 30 times
- [ ] Boot order verified: assertion fixture inserted in test runner verifies the order — `_registerPhases` called BEFORE `start()`; `start()` raises if `_registerPhases` not yet called (covered by story-001 AC, integration-confirmed here)

---

## Implementation Notes

*Derived from ADR-0002 §Phase Registration + architecture.md §5.8 + CLAUDE.md "Two-entry-point model":*

- Boot wiring goes in the existing `start.server.luau` between the module-require block and the per-player setup block. Place after Network init + PlayerData init (so the broadcast path's network registry is live when Phase 8 fires).
- Stub module file structure (each phase):

```lua
--!strict
-- ServerStorage/Source/_PhaseStubs/CollisionResolverStub.luau
local CollisionResolverStub = {}
function CollisionResolverStub.tick(tickCount: number, ctx: any): ()
    -- Stub: replaced by real CollisionResolver.tick when CCR epic ships.
    -- ADR-0002 §Phase Registration boot wiring requires a callable here.
end
return CollisionResolverStub
```

- Replace each stub via in-place edit of the `_registerPhases({...})` argument when the consuming epic completes — change `callback = CollisionResolverStub.tick` to `callback = CollisionResolver.tick`. The phase number + name strings remain unchanged.
- The comment block above `_registerPhases({...})` must explicitly list which entries are stubs and which are real (auditable trail). When the last stub is replaced, this comment can be removed.
- Place the stub directory `_PhaseStubs/` under `ServerStorage/Source/` (server-only — clients must not see). Underscore prefix flags the temporary nature.
- Audit grep: `tools/audit-asset-ids.sh` does not cover this; manual `grep -rn "Heartbeat:Connect" src/ServerStorage src/ReplicatedStorage` MUST return only the TickOrchestrator + (eventually) NPCSpawner files.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-001 + story-002**: TickOrchestrator module itself + accumulator + dispatch loop.
- **story-004**: BindToClose `stop()` invocation — separate boot block.
- **story-005**: Instrumentation hook initialization — separate one-line wiring after `start()`.
- **CSM/MSM/CCR/Relic/Absorb/Chest/PeelDispatch epic stories**: Real `tick(tickCount, ctx)` implementations replacing each stub. Each consuming epic tracks its own stub-replacement story.
- **NPCSpawner own Heartbeat exemption**: NPC epic owns its own Heartbeat:Connect per manifest L197; this story only audits that no OTHER module connects.

---

## QA Test Cases

*Integration story — automated integration test + audit grep.*

- **AC: Boot block exists at correct location in start.server.luau**
  - Given: fresh checkout
  - When: `grep -n "TickOrchestrator boot wiring" src/ServerScriptService/start.server.luau`
  - Then: returns exactly one match; the line number is AFTER the last module-level `require` and BEFORE the `Players.PlayerAdded` connection
  - Edge cases: no other `_registerPhases` call elsewhere in repo

- **AC: 9 stubs exist with correct interface**
  - Given: `ls src/ServerStorage/Source/_PhaseStubs/`
  - When: directory listing
  - Then: 9 files: `CollisionResolverStub.luau`, `RelicSystemStub.luau`, `AbsorbSystemStub.luau`, `ChestSystemStub.luau`, `CSMStateEvaluateStub.luau`, `MSMTimerCheckStub.luau`, `MSMEliminationConsumerStub.luau`, `CSMBroadcastAllStub.luau`, `PeelDispatcherStub.luau`
  - Edge cases: each stub exports a `.tick` function callable with `(tickCount, ctx)` returning `()`; each file starts with `--!strict`

- **AC: `_registerPhases` called with exactly the canonical 9-row table**
  - Given: instrumented test run that captures the argument passed to `_registerPhases`
  - When: server boot
  - Then: argument has 9 entries; entry N has `phase = N`, name matches manifest L60 (`Collision / Relic / Absorb / Chest / CSM:Eval / MSM:Timer / MSM:Elim / CSM:Cast / PeelDispatch`), callback is non-nil function
  - Edge cases: no extra entries; no duplicate phase numbers; assertion in `_registerPhases` (story-001) catches any drift

- **AC: Boot order — `_registerPhases` BEFORE `start()`**
  - Given: instrumented `_registerPhases` and `start()` capturing `os.clock` invocation timestamps
  - When: server boot
  - Then: `_registerPhases` timestamp < `start()` timestamp
  - Edge cases: `start()` called twice in row → second is no-op (story-001 idempotence)

- **AC: 30-tick integration replay — 1..9 ordering**
  - Given: each stub's `.tick` decorated with a recorder that pushes `phase.phase` to a shared list
  - When: `start()` runs against a real `RunService.Heartbeat` for ~2 s (≈ 30 ticks)
  - Then: `#recorder == 270`; for every i ∈ [0, 29], `recorder[i*9+1..i*9+9] == {1,2,3,4,5,6,7,8,9}`
  - Edge cases: at least one tick fires (rules out broken Heartbeat connection); cadence loose tolerance OK here — strict cadence covered by story-001

- **AC: No competing Heartbeat:Connect**
  - Given: full repo
  - When: `grep -rn "Heartbeat:Connect" src/`
  - Then: matches contain only `src/ServerStorage/Source/TickOrchestrator/init.luau` (and, post-NPC epic, `src/ServerStorage/Source/NPCSpawner/init.luau`)
  - Edge cases: no `RunService:GetService("RunService").Heartbeat:Connect` indirection elsewhere; no `RenderStepped` server-side connections (Roblox forbids RenderStepped server-side anyway, but lint)

- **AC: Stub replacement contract — interchangeable**
  - Given: `_registerPhases` argument is read fresh at boot
  - When: a stub callback is swapped for a real-module callback (test fixture replaces e.g. `CollisionResolverStub.tick` with a fixture function in-place)
  - Then: subsequent ticks invoke the new callback; no other phase callbacks affected
  - Edge cases: confirm the boot wiring's `callback` field is referenced once at `_registerPhases` time — runtime swap requires re-running `_registerPhases` (which is forbidden post-`start()` per ADR-0002 — this AC is conceptual; real swap happens at next server restart)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tick-orchestrator/boot_wiring_test.luau` (asserts 9-row table + boot order + 30-tick replay) + `tests/integration/tick-orchestrator/audit_no_competing_heartbeat.sh` (grep audit script) — both must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (module + `_registerPhases` API), story-002 (phase iteration)
- Unlocks: story-004 (BindToClose wiring relies on `start()` call already shipped), story-005 (instrumentation wires alongside the boot block)
