# Story 007: Perf soak — 3600 overlap tests p99 ≤1.5ms

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md` §AC-17 + §F3 N_max budget
**Requirement**: `TR-absorb-009`, `TR-absorb-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 Performance Budget
**ADR Decision Summary**: Phase 3 absorb budget = 0.4 ms typical / 1.5 ms worst-case at 12 crowds × 300 NPCs (3600 overlap tests). Real-soak deferred to MVP-Integration-1 sprint per ADR-0003; this story does the synthetic soak with `debug.profilebegin` evidence.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `debug.profilebegin/profileend` available pre-cutoff; Micro Profiler JSON export for evidence.

**Control Manifest Rules (Performance Guardrails)**:
- Phase 3 AbsorbSystem: 0.4 ms typical; 1.5 ms worst-case (3600 overlap tests) (ADR-0003)
- Required: Synthetic soak via `tools/perf-fixture` style runner (existing fixture for FollowerEntity Sprint 4)
- Forbidden: Real-server soak gating this story (deferred to MVP-Integration-1)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md` AC-17 + F3 N_max bound:*

- [ ] **AC-17 (Perf — Integration tier)**: 12 crowds × 300 NPCs each (3600 overlap tests) at 60 consecutive ticks in live Roblox Server, p99 tick cost via `debug.profilebegin("AbsorbTick")` ≤ 1.5 ms.
- [ ] **F3 N_max bound check**: at radius=10, ρ_design=0.075, formula `N_max = floor(π × radius² × ρ_design) = floor(23.56) = 23` — synthetic test asserts max-absorbs-per-tick across the soak does not exceed F3-derived bound (sanity check on density math).
- [ ] **Evidence file**: `production/qa/evidence/perf-soak-absorb-2026-XX-XX.md` containing Micro Profiler JSON export + p99 calculation + soak setup notes.

---

## Implementation Notes

*Derived from ADR-0003 §Phase 3 budget + existing perf-fixture pattern (Sprint 4):*

- Reuse perf-fixture pattern from Sprint 4 FollowerEntity work (`perf-fixture.rbxl` + `[L]` hotkey for snapshot).
- Add `[A]` hotkey: spawn 12 crowds of 300 followers + 300 NPCs each in 12 zones; pin TickOrchestrator to fixed 15 Hz; run 60 ticks.
- `debug.profilebegin("AbsorbTick")` wraps each tickPhase3 call inside the fixture-only soak harness (NOT inside production AbsorbSystem source — fixture-only instrumentation).
- Collect 60 sample timings; compute p50, p95, p99; emit JSON to `production/qa/evidence/`.
- F3 bound check: sample max absorbs/tick across 60 ticks; assert ≤ 23 per crowd at radius=10. (Defensive — caps on absorbs-per-tick come from NPC density, not a code-side cap.)
- If p99 exceeds 1.5 ms: log offending ticks + flame-graph hotspot; raise CONCERNS (does not auto-fail story — escalate to perf-analyst review).

---

## Out of Scope

*Handled by neighbouring stories or other sprints — do not implement here:*

- Story 001-006: implementation (this story validates).
- Real-server soak in production-deployed game — deferred to MVP-Integration-1 sprint (per ADR-0003).
- Mobile-binding 45 FPS confirmation — separate device-specific story in Polish phase.

---

## QA Test Cases

- **AC-17 (p99 ≤ 1.5 ms)** [Integration — Studio runtime]:
  - Setup: open `perf-fixture.rbxl` in Studio; press `[A]`; soak runs 60 ticks at 15 Hz in live server context
  - Verify: read Micro Profiler export (Studio → Output → Micro Profiler → Save As JSON); compute p99 of `AbsorbTick` markers
  - Pass condition: p99 ≤ 1.5 ms; evidence file committed at `production/qa/evidence/perf-soak-absorb-[date].md`

- **F3 N_max sanity** [Integration — same soak]:
  - Setup: same fixture, count absorbs/tick in shared counter
  - Verify: max value ≤ 23 per crowd at radius=10
  - Pass condition: bound respected across all 60 ticks

- **Evidence completeness** [Logic — file presence]:
  - Setup: post-soak
  - Verify: evidence file exists with required fields (date, fixture commit hash, p50/p95/p99, N_max, hardware notes)
  - Pass condition: file passes `tests/qa-evidence-schema.spec.luau` (schema linter — VS+ tooling)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/perf-soak-absorb-2026-XX-XX.md` — Micro Profiler export + p99 math + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001-006 (full AbsorbSystem implementation under measurement); perf-fixture infra from Sprint 4.
- Unlocks: AbsorbSystem epic Definition of Done (Phase 3 ≤0.5 ms synthetic budget verified).
