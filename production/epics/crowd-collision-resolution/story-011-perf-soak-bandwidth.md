# Story 011: Perf soak — p99 ≤0.15ms + peel bandwidth ≤6.6 KB/s pileup

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md` §AC-20 + AC-21
**Requirement**: `TR-ccr-020`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 Performance Budget
**ADR Decision Summary**: Phase 1 budget ≤0.6 ms/tick (manifest); CCR-specific p99 ≤0.15 ms at 66 pairs (12 crowds, ~6 overlapping pairs). Peel bandwidth ≤6.6 KB/s 12-crowd pileup; ≤1.8 KB/s at 3-pair steady state. Both advisory gates — milestone check, not per-story-blocking.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: `debug.profilebegin/end` + StatsService.DataSendKbps available pre-cutoff.

**Control Manifest Rules (Performance Guardrails):**
- Phase 1 CollisionResolver: 0.6 ms/tick worst-case (66 pairs × 9 µs/pair) (ADR-0003)
- CollisionPeelEvent bandwidth budget within Reliable+UREvent envelope (ADR-0003)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md` AC-20 + AC-21:*

- [ ] **AC-20 (Perf soak)**: GIVEN 12 active crowds (66 pairs) with ~6 overlapping pairs, WHEN server runs 900 consecutive ticks (60-sec soak at 15 Hz) in Studio test server, THEN `CollisionResolverTick` p99 ≤ 0.15 ms via `debug.profilebegin/end`; full tick (Collision + Absorb + Broadcast + PeelDispatch) p99 ≤ 0.80 ms.
- [ ] **AC-21 (Bandwidth — pileup)**: GIVEN 12 crowds in single pileup (11 pairs involving one player's crowd), WHEN PeelDispatcher.flush runs for that player, THEN exactly 1 FireClient call (buffer batched 11 entries); per-client `CollisionPeelEvent` bandwidth via StatsService.DataSendKbps over 60-sec sustained 12-crowd pileup ≤ 6.6 KB/s; at 3-pair steady state ≤ 1.8 KB/s.
- [ ] **Evidence files**: `production/qa/evidence/perf-soak-collision-2026-XX-XX.md` (Micro Profiler JSON p99) + `production/qa/evidence/bandwidth-peel-2026-XX-XX.md` (StatsService capture).

---

## Implementation Notes

*Derived from ADR-0003 §Phase 1 budget + perf-fixture pattern (Sprint 4):*

- Reuse perf-fixture `[L]` snapshot pattern + add `[C]` hotkey: spawn 12 crowds with 6 overlapping pairs at varying counts; pin TickOrchestrator at 15 Hz; soak 900 ticks.
- Wrap `tickPhase1` in fixture-only `debug.profilebegin("CollisionResolverTick")` / `profileend` (NOT inside production source — fixture-only instrumentation pattern from Absorb story-007).
- Capture full-tick wall time via outer `profilebegin("FullTick")` per tick; compute p99 across both markers.
- Bandwidth: instrument fixture client via `StatsService:GetCounter("DataSendKbps")` integrated over 60 s soak window.
- Pileup scenario: spawn 12 crowds positioned so all 12 overlap one center crowd's footprint (11 pairs all-to-one from that perspective).
- 3-pair steady-state: spawn 4 crowds with 3 overlapping pairs.

---

## Out of Scope

*Handled by neighbouring stories or other sprints — do not implement here:*

- Stories 001-010: implementation (this story validates).
- Real-server soak — deferred to MVP-Integration-1 sprint per ADR-0003.
- Mobile-binding 45 FPS — separate device-specific story in Polish phase.

---

## QA Test Cases

- **AC-20 (CCR p99)** [Integration]:
  - Setup: open `perf-fixture.rbxl`; press `[C]`; soak 900 ticks
  - Verify: read Micro Profiler export; compute p99 of CollisionResolverTick + FullTick
  - Pass condition: CCR p99 ≤ 0.15 ms; FullTick p99 ≤ 0.80 ms; evidence committed

- **AC-21 (Bandwidth pileup)** [Integration]:
  - Setup: same fixture, pileup scenario; instrument client StatsService over 60 s
  - Verify: integrated DataSendKbps for CollisionPeelEvent
  - Pass condition: pileup ≤ 6.6 KB/s; 3-pair ≤ 1.8 KB/s

- **Single FireClient batching**:
  - Given: 11-entry pileup
  - When: flush
  - Then: exactly 1 FireClient observed (test-server spy on RemoteEvent send count)
  - Edge cases: 0 entries → 0 fires.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/perf-soak-collision-2026-XX-XX.md` — p99 + sign-off
- `production/qa/evidence/bandwidth-peel-2026-XX-XX.md` — bandwidth + sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-010 implemented; perf-fixture infra from Sprint 4.
- Unlocks: CCR epic Definition of Done.
