# Story 001: AbsorbSystem Phase 3 callback skeleton + DI scaffold

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md`
**Requirement**: `TR-absorb-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 TickOrchestrator + ADR-0006 Module Placement
**ADR Decision Summary**: AbsorbSystem registers a single Phase 3 callback with TickOrchestrator (no own `Heartbeat:Connect`); module placed at `ServerStorage/Source/AbsorbSystem/init.luau`. Callback runs synchronously, no yields. DI for CrowdStateServer / NPCSpawner / VFXManager / AudioManager / clock function.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs only. No post-cutoff hazard.

**Control Manifest Rules (Feature layer)**:
- Required: AbsorbSystem (Phase 3) is sole caller of `getAllActiveNPCs()` + `reclaim(npcId)` (ADR-0008)
- Required: All Luau files start with `--!strict` (ADR-0006)
- Required: Server module under `ServerStorage/Source/AbsorbSystem/init.luau` (ADR-0006)
- Forbidden: Competing `RunService.Heartbeat:Connect` for gameplay-tick work — TickOrchestrator is sole accumulator (ADR-0002)
- Forbidden: Yield inside Phase 3 callback (`task.wait` / `task.defer` / async) — breaks tick atomicity (ADR-0002)
- Guardrail: Phase 3 budget 0.4 ms typical, 1.5 ms worst-case @ 3600 overlap tests (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md`, scoped to this story:*

- [ ] **AC-5 (Piggyback 15 Hz tick)**: AbsorbSystem registers no own `task.delay` / `RunService.Heartbeat`; absorb eval invoked exactly once per tick via TickOrchestrator Phase 3 callback. Verified via scheduler spy.
- [ ] **AC-10 (Zero crowds early-return)**: 0 registered crowds → inner NPC loop body NEVER entered (`NPCSpawner.getSnapshot` call count == 0).
- [ ] **AC-11 (Zero NPCs no-op)**: 1 Active crowd + empty NPC snapshot → no Absorbed signals, no errors, tick completes normally.
- [ ] **DI scaffold**: AbsorbSystem.new() / AbsorbSystem.init(deps) accepts `CrowdStateServer`, `NPCSpawner`, `VFXManager`, `AudioManager`, `clock` as injected deps (no global singletons consumed inside Phase 3 callback).
- [ ] **Path placement**: `src/ServerStorage/Source/AbsorbSystem/init.luau`.

---

## Implementation Notes

*Derived from ADR-0002 §Phase 3 callback contract + ADR-0006 §Source Tree Map:*

- Module folder-as-module entry at `ServerStorage/Source/AbsorbSystem/init.luau`.
- Public surface: `AbsorbSystem.init(deps: Deps)` + `AbsorbSystem.tickPhase3(tickCount: number)`.
- `Deps` is a typed table: `{ csm, npcSpawner, vfx, audio, clock }`. No `require()` of these inside the callback — all consumed via `self` / module-scoped refs set at init.
- Phase 3 callback wired in `ServerScriptService/start.server.luau` AFTER all module requires: `TickOrchestrator.registerPhase(3, AbsorbSystem.tickPhase3)`.
- Early-return path: if `csm.getAllActive()` returns empty list, skip `npcSpawner.getAllActiveNPCs()` call entirely.
- No-yield assertion: callback body uses no `task.wait` / `task.defer` / `:WaitForChild` / coroutine.yield. Verify by grep at code review.
- `pcall` wrapper applied by TickOrchestrator at phase boundary (not inside this module per ADR-0002).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: F1 overlap math + F2 contention.
- Story 003: Per-overlap sequence + reclaim contract + frozen snapshot atomicity.
- Story 004: State guards (Active/GraceWindow/Eliminated skip).
- Story 005: Absorbed reliable RemoteEvent + count clamp passthrough.
- Story 006: V/A signal consumers (VFX + audio batching/streak).
- Story 007: Perf soak (Integration tier).

---

## QA Test Cases

- **AC-5 (Piggyback)**:
  - Given: TickOrchestrator mock + scheduler spy on `Heartbeat`
  - When: `AbsorbSystem.init(deps)` runs
  - Then: zero new `Heartbeat:Connect` registered by AbsorbSystem; `tickPhase3` callable but only invoked through TickOrchestrator
  - Edge cases: re-init must not double-register.

- **AC-10 (Zero crowds early-return)**:
  - Given: `csm.getAllActive` returns `{}`
  - When: `tickPhase3(1)` fires
  - Then: `npcSpawner.getAllActiveNPCs` call count == 0
  - Edge cases: nil return treated as empty (no crash).

- **AC-11 (Zero NPCs no-op)**:
  - Given: `csm.getAllActive` returns 1 crowd Active; `npcSpawner.getAllActiveNPCs` returns `{}`
  - When: `tickPhase3(1)` fires
  - Then: zero Absorbed events fired; no errors thrown; deterministic exit
  - Edge cases: nil snapshot treated as empty.

- **DI scaffold**:
  - Given: missing dep in init payload
  - When: `init({csm = ..., npcSpawner = ..., vfx = nil, ...})`
  - Then: assertion fires at init, not at tick time
  - Edge cases: re-init with same deps idempotent.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/absorb/phase3_skeleton.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TickOrchestrator must exist (already implemented Sprint 3); CrowdStateServer + NPCSpawner DI surfaces present.
- Unlocks: Story 002, 003, 004, 005 (all assume Phase 3 callback skeleton in place).
