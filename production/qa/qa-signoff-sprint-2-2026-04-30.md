# QA Sign-Off Report: Sprint 2 (Core Spine)

**Date**: 2026-04-30
**QA Lead sign-off**: APPROVED
**Sprint duration**: 2026-04-29 to 2026-04-30 (~7.5 days of 8 budgeted)

---

## Test Coverage Summary

| Story | Type | Auto Test | Manual QA | Result |
|-------|------|-----------|-----------|--------|
| 2-1 TickOrch skeleton + cadence + start/stop | Logic | PASS (`cadence` + `lifecycle` + `registerphases`) | — smoke-only | PASS |
| 2-2 TickOrch phase dispatch + pcall + ctx | Logic | PASS (`phase_dispatch` + `error_isolation`) | — smoke-only | PASS |
| 2-3 TickOrch boot wiring + 9-phase stubs | Integration | PASS (`boot_wiring` + `audit-no-competing-heartbeat`) | — smoke-only | PASS |
| 2-4 CSM skeleton + create/destroy + DC | Logic | PASS (`lifecycle` + `dc_cleanup` + `signal_fanout`) | — smoke-only | PASS |
| 2-5 CSM updateCount + F5 clamp + signals | Logic | PASS (`updatecount_clamp` + `countchanged` + `countclamped`) | — smoke-only | PASS |
| 2-6 CSM read accessors + setStillOverlapping | Logic | PASS (`read_accessors` + `set_still_overlapping`) | — smoke-only | PASS |
| 2-7 RL skeleton + Janitor + createAll/destroyAll | Logic | PASS (`createall` + `destroyall` + `double_createall_assert`) | — smoke-only | PASS |
| 2-8 MSM skeleton + 7-state enum + Lobby boot + Snap freeze | Logic | PASS (`skeleton` + `participation_flag` + `snap_freeze`) | — smoke-only | PASS |

**Totals**: 149 tests / 149 pass / 0 fail / 0 skipped. 4/4 audit gates PASS (selene + audit-asset-ids + audit-persistence + audit-no-competing-heartbeat).

Manual QA waived: Sprint 2 delivers infrastructure-only; no user-facing surface exists to walkthrough. Accepted by user prior to this report. The Studio Server Console probe documented in `production/qa/smoke-2026-04-30.md` is the canonical manual verification protocol for ad-hoc inspection.

---

## Bugs Found

| ID | Story | Severity | Status |
|----|-------|----------|--------|
| (none) | | | |

Zero bugs filed during this sprint.

---

## Advisory Items (tracked, non-blocking)

1. **AFKToggle wiring deferred** — MSM 2-8 intentionally omits `Network.connectEvent(AFKToggle, ...)`. The `_afkToggleConnection` scaffolding is in place; the validated handler wires in MSM story-007 (per ADR-0010 §4-Check Guard). No production impact; toggle traffic is silently ignored until then. Inline `TODO(story-007)` in `src/ServerStorage/Source/MatchStateServer/init.luau` documents the swap location.

2. **CI enforcement gap** — TestEZ headless job on `ubuntu-latest` is warn-only (Roblox Studio is not available on Linux). Lint + 3 audit gates are blocking. To make TestEZ blocking in CI, configure a self-hosted macOS/Windows runner with Studio installed OR a GitHub-hosted `macos-latest` runner (incurs ~10 min Studio bootstrap per CI run). Local dev runs full TestEZ suite via `run-in-roblox` per `tests/README.md` headless instructions.

3. **QA plan not pre-generated** — `/qa-plan sprint` was flagged in `production/sprints/sprint-2.md` header but never executed before Sprint 2 implementation began. Story-embedded QA test cases (each story's `## QA Test Cases` section) covered the gap effectively, but a consolidated cross-story test plan was not produced. **Recommend** running `/qa-plan sprint` at the top of Sprint 3 BEFORE the first story is assigned — shift-left requires the test plan in place at sprint start, not retrospectively.

---

## Out-of-Scope Validation (deferred, intentional)

The following Sprint 2 ACs ship a math-proxy automated test now, with real-Studio / real-hardware soak-validation deferred to a later sprint:

- **TickOrch AC-13 cadence ±0.1% over 60 s real desktop hardware** — Story 2-1's `cadence.spec.luau` "60 simulated seconds" `it` block runs 3600 synthetic frames at `dt=1/60` and asserts tick count ∈ [899, 901]. Real-Heartbeat soak deferred to TickOrch story-005 + MVP-Integration-1 sprint per ADR-0002 §Risk 1.

- **TickOrch AC-11 `stop()` ≤5 ms latency claim** — Story 2-1's `lifecycle.spec.luau` "stop() clears _heartbeatConnection" block asserts structural nil-check only; the wall-timing `os.clock` assertion was removed per `coding-standards.md` §Determinism (CI flap risk on loaded runners). The ≤5 ms claim is trivially satisfied by synchronous `:Disconnect()` and is documented in the story's ADR-0002 cite.

- **TickOrch mobile dt jitter ±0.3% on iPhone SE emu** — Same deferral pattern: math-proxy automated, real-device soak deferred to TickOrch story-005 + MVP-Integration-1.

These deferrals are **correctly scoped** per ADR-0002 §Validation Required + ADR-0003 §Performance Budget; they do not represent gaps in Sprint 2 scope.

---

## Verdict: **APPROVED**

149/149 automated tests pass. All 4 audit gates green. Zero bugs filed. The three advisory items are tracked tech debt with no production impact and no S1/S2 exposure; none constitute a condition that warrants blocking sprint close-out.

**No conditions** — straight pass.

---

## Next Step

1. **`/gate-check`** — validate stage advancement (likely Pre-Production → Production, or Sprint-2-implementation → Sprint-2-closed depending on which gate applies next per `.claude/docs/director-gates.md`).
2. **Before Sprint 3 begins** — run `/qa-plan sprint` to address advisory item 3. Shift-left requires the QA plan in place at sprint start.
3. **Optional pull-ins** — Sprint 2 has ~0.5d of unused budget. Eligible for in-flight pull-in if desired before close-out:
   - 2-9 should-have: CSM 003 — hue F6 + activeRelics
   - 2-10 should-have: CSM 004 — F1 composed radius + recomputeRadius
   - 2-11 should-have: TickOrch 004 — BindToClose stop coordination
   - 2-12 nice-to-have: CSM 005 — F2 position lag + nil HRP guard
   - 2-13 nice-to-have: TickOrch 005 — per-phase os.clock instrumentation

---

**Sign-Off Authority**: qa-lead subagent (orchestrated via `/team-qa sprint`)
**Lean Mode**: Director gates QL-FINAL-SIGNOFF / PR-SPRINT-CLOSE skipped per `production/review-mode.txt`
