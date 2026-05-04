# Story 011: Perf soak validation — 80 LOD-0 followers ≤ 2.5 ms p99

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: AC-17 verification — implementation TR coverage spans the full per-frame pipeline: `TR-follower-entity-001` (CFrame authority), `TR-follower-entity-005/006/017` (F8/F9/d), boids F1-F4 (Story 003), throttle (Story 005)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003 Performance Budget + ADR-0007 Client Rendering Strategy
**ADR Decision Summary**: Per-frame budget for `follower-entity-client-sim` is 1.5 ms desktop / 2.5 ms mobile. AC-17 baseline is 80 LOD-0 followers (160 Parts) on desktop @ 60 FPS, 60 s sustained, p99 ≤ 2.5 ms via Roblox Micro Profiler label `FollowerEntityClient_Update`. Full-lobby (290 LOD-0) profile must be run separately before mobile-cap decisions are finalized.

**Engine**: Roblox | **Risk**: MEDIUM
**Engine Notes**: Roblox Micro Profiler is the canonical client perf tool. `debug.profilebegin / profileend` for custom labels. Pre-cutoff stable.

**Control Manifest Rules (Presentation layer)**:
- Guardrail: 1.5 ms desktop / 2.5 ms mobile — this story validates the desktop budget at AC-17 scenario
- Guardrail: ≤150 rendered Parts per client view — AC-17 uses 160 Parts (2×80) which is over the cap; AC-17's perf scenario predates final cap rationalisation. Documented exception per AC-17.

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-17 (Perf soak)**: Given 80 LOD-0 followers on desktop client (60 FPS target, 160 Parts = 2 Parts × 80 followers), when 60-sec sustained playtest with Roblox Micro Profiler (label `FollowerEntityClient_Update`), then per-frame update loop ≤ 2.5 ms at p99 (p99 = sort 3,600 samples descending, read sample at index 36).
- [ ] Evidence file at `production/qa/evidence/perf-soak-[YYYY-MM-DD].txt` (or .md) — must include: scenario summary, hardware spec, Micro Profiler raw sample distribution, computed p50/p90/p99 values, PASS/FAIL conclusion.
- [ ] `debug.profilebegin("FollowerEntityClient_Update")` / `debug.profileend()` calls wrap the per-frame update path inside the orchestrator's `RenderStepped` callback (Story 002 + 003).
- [ ] Sample size: 60 s × 60 FPS = 3,600 samples minimum.
- [ ] Scenario reproducible via a perf-fixture place file or test scaffold (rojo-buildable).

---

## Implementation Notes

*Derived from GDD AC-17 + ADR-0003 §Validation Sprint Plan:*

- **NOT a unit test.** This is a manual integration / perf benchmark. Evidence is a captured Micro Profiler dump.
- Wrap the per-frame update inside `CrowdManagerClient` RenderStepped callback:
  ```lua
  RunService.RenderStepped:Connect(function(dt)
      debug.profilebegin("FollowerEntityClient_Update")
      -- Story 003 (boids) + Story 004 (bob) + Story 006 (hue) + Story 008 (peel transit)
      for crowdId, client in self._crowds do
          client:_perFrameUpdate(dt)
      end
      debug.profileend()
  end)
  ```
- Build a perf-fixture: 1 crowd, 80 LOD-0 followers, no peeling, no spawning bursts, no LOD swaps — pure steady-state boids + bob + sway + per-frame nil-check. This isolates the hot path.
- Open Roblox Studio → Studio Settings → Show Diagnostics → Micro Profiler. Filter for label `FollowerEntityClient_Update`. Run 60 s. Export samples (Ctrl+P, save to file).
- p99 calculation: sort the 3,600 samples descending; read sample at index 36 (the 36th-worst, equivalent to top 1%).
- Hardware: desktop client running Roblox Player (NOT Studio mode unless explicitly noted). Studio adds overhead.
- Mobile soak (separate AC, deferred to MVP-Integration-1 sprint per ADR-0003 §Validation Sprint Plan) is OUT OF SCOPE for this story.
- Full-lobby (290 LOD-0) profile is also OUT OF SCOPE — separate evidence file needed before mobile-cap decisions finalised.
- Evidence file template:
  ```markdown
  # Follower Entity perf soak — AC-17 evidence
  Date: 2026-MM-DD
  Hardware: <CPU/GPU/RAM/OS>
  Build: rojo-built place file <hash>
  Scenario: 1 crowd, 80 LOD-0 followers, steady-state boids, 60 s
  Samples: 3,600 frames
  p50: <value> ms
  p90: <value> ms
  p99: <value> ms (target ≤ 2.5 ms)
  Verdict: PASS / FAIL
  Notes: <anomalies, frame spikes, GC pauses>
  ```

---

## Out of Scope

*Handled by neighbouring stories or deferred:*

- All Story 003-010 implementations must be complete before this story can produce meaningful evidence — this is the perf gate, not the implementation.
- Mobile soak (deferred to MVP-Integration-1 per ADR-0003).
- Full-lobby 290-follower soak (separate evidence file, deferred).
- AC-18 LOD-swap no-alloc validation — Story 012.

---

## QA Test Cases

*Manual verification per AC-17 — no automated test possible at this fidelity.*

- **Manual check: Perf soak desktop**:
  - Setup: rojo-build a perf-fixture place with 1 crowd × 80 LOD-0 followers + steady-state movement (e.g., follow a scripted patrol path). Open in Roblox Player. Open Micro Profiler (Ctrl+F6 / Studio Settings).
  - Verify: filter label `FollowerEntityClient_Update`. Capture 60 s of samples. Sort descending. p99 (index 36) is the value to read.
  - Pass condition: p99 ≤ 2.5 ms; no individual frame > 5 ms (spike sentinel); no GC pause > 10 ms during the soak.

- **Manual check: Evidence file present + valid**:
  - Setup: after the soak run, save the captured samples + summary
  - Verify: `production/qa/evidence/perf-soak-[date].txt` (or .md) exists; contains scenario summary, hardware spec, p50/p90/p99 values, PASS/FAIL verdict
  - Pass condition: file exists AND p99 ≤ 2.5 ms is documented as PASS.

- **Manual check: profilebegin/profileend wraps the update path**:
  - Setup: code-search the orchestrator file
  - Verify: exactly one `debug.profilebegin("FollowerEntityClient_Update")` paired with one `debug.profileend()` in the RenderStepped callback; no other `FollowerEntityClient_*` labels orphaned
  - Pass condition: balanced profile begin/end, label string matches the AC verbatim.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `production/qa/evidence/perf-soak-[YYYY-MM-DD].txt` — must exist with PASS verdict + p99 ≤ 2.5 ms
- Sign-off: gameplay-programmer + qa-lead in evidence file footer

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-010 (full per-frame pipeline must be implemented to soak meaningfully)
- Unlocks: epic gate (AC-17 closes); MVP-Integration-1 mobile soak (separate evidence file)
