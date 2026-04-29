# Story 005: F1 bandwidth estimator + static gates + multi-client perf evidence (deferred)

> **Epic**: crowd-replication-broadcast
> **Status**: Ready
> **Layer**: Core (helper module + audit gates)
> **Type**: Logic + Audit + Performance (deferred)
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-replication-strategy.md` §Formulas/F1 + §AC-4/14/15/25/26
**Requirement**: `TR-crs-025` (Bandwidth budget), `TR-crs-026` (Burst allowance)
**ADR**: ADR-0001 (UREvent + buffer mandate); ADR-0003 §Network bandwidth budget (10 KB/s/client steady-state; 20 KB/s burst); ADR-0004 §Write-Access Matrix.
**ADR Decision Summary**: F1 bandwidth estimator is a pure-math helper used by automated tests + future telemetry. Static gates ensure server/client boundary is preserved (no client-side `renderedCount` consulted for gameplay; CSM mutators never referenced from client). Multi-client soak validation deferred to MVP integration sprint per ADR-0003 §Validation Sprint Plan.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW (helpers + static analysis); MEDIUM (deferred multi-client validation).
**Engine Notes**: Pure Luau math (LOW); grep-based audit (LOW); MicroProfiler / DataSendKbps measurement (MEDIUM, deferred).

**Control Manifest Rules:**
- Required: 4-check guard pattern (manifest L111); selene custom rules deferred to Production-phase per ADR-0006 §Migration Plan; defense-in-depth via L1 (engine), L2 (review), L4 (manifest), L5 (architecture review), L6 (story readiness) is sufficient.
- Performance: bandwidth budget 10 KB/s/client steady; 20 KB/s burst (manifest L173).

---

## Acceptance Criteria

- [ ] **AC-4 (F1 bandwidth boundary)** — `BandwidthEstimator.compute(N=12, HZ=15, payloadBytes=30, reliableOverhead=100)` returns `5500 B/s` (5.37 KB/s) `< BANDWIDTH_BUDGET_BYTES_PER_SEC = 10240` (10 KB/s).
- [ ] **AC-14 (Steady-state bandwidth ≤10 KB/s — DEFERRED)** — 12-player session, 60s post-active-play, `buffer` encoding active. Per-client `DataSendKbps` rolling 5s window ≤ 10 KB/s. *Evidence: integration (12-client Studio harness) — DEFERRED to first multi-client integration sprint per ADR-0001 Risk 4 + ADR-0003 §Validation Sprint Plan.*
- [ ] **AC-15 (Burst cap ≤15 KB/s over 1s — DEFERRED)** — Round start w/ 12 crowds first broadcast + 12 `CrowdJoined` reliable. 1s window total outbound per-client ≤ 15,360 B/s; decays to steady within 3s. *Evidence: integration — DEFERRED.*
- [ ] **AC-25 (No gameplay decision on rendered count — Static gate)** — `grep -rn "renderedCount" src/ServerStorage/` → ZERO matches. All server gameplay decisions reference `crowdState.count` (authoritative). *Evidence: static gate via shell script.*
- [ ] **AC-26 (Server-only write authority — Static gate)** — `grep -rn "CrowdStateServer\.\(updateCount\|create\|destroy\|recomputeRadius\|setStillOverlapping\|stateEvaluate\|broadcastAll\)" src/ReplicatedStorage/ src/ReplicatedFirst/` → ZERO matches. CSM mutators never referenced from client-side code. *Evidence: static gate via shell script.*
- [ ] `BandwidthEstimator.luau` module created at `ServerStorage/Source/Network/BandwidthEstimator.luau`:
  ```lua
  --!strict
  local BandwidthEstimator = {}
  
  function BandwidthEstimator.compute(
      N: number,            -- crowd count (or active record count)
      HZ: number,           -- broadcast frequency Hz
      payloadBytes: number, -- per-record payload bytes (30 for CrowdState)
      reliableOverhead: number  -- per-second reliable-event overhead bytes
  ): number
      return N * HZ * payloadBytes + reliableOverhead
  end
  
  return BandwidthEstimator
  ```
- [ ] `BANDWIDTH_BUDGET_BYTES_PER_SEC = 10240` constant exposed in module.
- [ ] Static gate scripts created:
  - `tools/audit-replication-renderedcount.sh` — runs grep AC-25, exits 1 on match
  - `tools/audit-csm-write-from-client.sh` — runs grep AC-26, exits 1 on match
- [ ] AC-14 / AC-15 evidence document exists as a placeholder: `production/qa/evidence/replication-bandwidth-soak-evidence.md` w/ "DEFERRED to MVP integration sprint per ADR-0001 Risk 4 + ADR-0003 §Validation Sprint Plan" — gates the Production milestone, not this Core sprint.

---

## Implementation Notes

- F1 formula (per CRS GDD F1):
  ```
  bandwidth_steady_state = N × HZ × payloadBytes + reliableOverhead
  ```
  `N=12, HZ=15, payloadBytes=30, reliableOverhead=100` → `12 * 15 * 30 + 100 = 5500 B/s`.
- BandwidthEstimator is server-only at this story; can be moved to ReplicatedStorage later if client telemetry consumes it. For MVP: server-side only.
- Static gates live in `tools/` directory alongside `audit-asset-ids.sh` + `audit-persistence.sh` (already shipped). Pattern matches.
- Static gate scripts are short (5-10 lines each); make them executable + add to a meta-audit makefile or pre-commit hook (out-of-scope here — DevOps follow-up).
- AC-14 + AC-15 deferred validation: explicitly documented as such per CRS §Flags 1 + ADR-0003 §Validation Sprint Plan. Production milestone gate-check will catch this; no need to block Core sprint on it.

---

## Out of Scope

- story-001..004: prereqs.
- Multi-client harness: deferred per AC-14/15 flag.
- ADR amendments: ADR-0001 already amended per CRS GDD (status Accepted 2026-04-26).

---

## QA Test Cases

- **AC-4**: `BandwidthEstimator.compute(12, 15, 30, 100) == 5500`. Edge: `compute(0, 15, 30, 0) == 0` (Lobby); `compute(12, 30, 30, 100) == 10900` (hypothetical 30 Hz exceeds budget — flag in caller).
- **AC-25**: `bash tools/audit-replication-renderedcount.sh` exits 0 (no matches in clean repo); after seeded violation (`renderedCount = 5` inserted into a server file), exits 1.
- **AC-26**: `bash tools/audit-csm-write-from-client.sh` exits 0 (clean); after seeded violation (e.g. `CrowdStateServer.updateCount(...)` in a `ReplicatedStorage` file), exits 1.
- **AC-14 / AC-15 (deferred)**: existence of placeholder evidence doc; references the sprint plan. No actual measurement this story.

---

## Test Evidence

`tests/unit/bandwidth-estimator/compute.spec.luau` (AC-4) + `tools/audit-replication-renderedcount.sh` (AC-25) + `tools/audit-csm-write-from-client.sh` (AC-26) + `production/qa/evidence/replication-bandwidth-soak-evidence.md` (AC-14/15 placeholder).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001..004 (full epic surface for static gates to scan)
- Unlocks: MVP integration sprint multi-client soak (AC-14/15 actual measurement); future analytics integration consumes BandwidthEstimator
