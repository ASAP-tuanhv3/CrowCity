---
name: Crowdsmith AC Test Type Misclassifications
description: Multiple ACs in Crowd State Manager and Follower Entity GDDs require integration evidence or have untestable assertions; AC-18 (Follower Entity) is a blocking rewrite
type: project
---

## Crowd State Manager GDD

AC-17 (performance soak) and AC-18 (replication correctness) are written as if they are unit tests but cannot be satisfied by TestEZ alone.

**AC-17:** Requires a 60-second soak in a live Roblox server session. `os.clock()` in a headless runner does not measure Roblox scheduler CPU time. The p99 threshold cannot be verified outside a Studio Server or run-in-roblox environment. Evidence goes in `production/qa/evidence/perf-soak-[date].txt`.

**AC-18:** Requires a live UnreliableRemoteEvent, a running `task.spawn` broadcast loop, and actual network delivery between server and client processes. TestEZ cannot schedule `task.wait()` or simulate inter-process remotes. Evidence goes in `production/qa/evidence/replication-[date].txt`.

**Why:** Both ACs were written with correct assertions but wrong test type assumptions. The Roblox engine's broadcast and scheduler are not mockable at unit test level without a full Studio session.

**How to apply:** When setting up test files for Crowd State Manager stories, place AC-17 and AC-18 in `tests/integration/crowd/` and mark them as requiring manual playtest or run-in-roblox runner. Do not accept a story as Done on the basis of TestEZ passing alone for these two ACs.

## Follower Entity GDD

**AC-17 (Follower Entity perf soak):** Correctly classified as Integration. Evidence required: Micro Profiler export with `FollowerEntityUpdate` label (must be added by programmer via `debug.profilebegin`/`debug.profileend`). p99 <= 2.5ms. Evidence file: `production/qa/evidence/perf-soak-[date].txt`.

**AC-18 (Follower Entity pool hide/unhide) -- BLOCKING REWRITE REQUIRED:** The assertion "spy on `Instance.new` returns 0 calls" is not achievable in Luau. `Instance.new` is a C++ engine global and cannot be monkey-patched at the script level. This AC must be rewritten to use structural instance-count assertions (count parts in pool folder before and after LOD swap; assert count unchanged). Still Integration-tier. Evidence: `production/qa/evidence/lod-swap-[date].txt`.

**ACs 4, 5, 14 (Follower Entity, conditionally Integration):** These ACs require DI seams (`_writeBodyColor`, `_vfxManager`, `CrowdStateClient` position-delta tracking) to be unit-testable. If seams are not implemented by the programmer, these escalate to Integration evidence. Block story Done until seams are confirmed present in the implementation.

**AC-2 (Follower Entity walk bob) -- BLOCKING REWRITE REQUIRED:** `Root_target` is used in the assertion but not defined as a variable in the AC or F8 variable table. Test cannot be written without knowing whether `Root_target` is the F4 boids output position before bob is applied. GDD must add this definition.

**AC-5 (Follower Entity hue flip) -- BLOCKING REWRITE REQUIRED:** Uses `elapsed / T_peel == 0.5` (exact float equality). Frame-rate-driven systems will almost never hit exactly 0.5. Must use threshold-crossing logic: first frame where `elapsed / T_peel >= 0.5 AND previous_elapsed / T_peel < 0.5`.

**AC-7 (Pool exhaustion "once per session") -- BLOCKING:** "Warning logged exactly once per session" is not unit-testable without a module-level flag reset seam. Programmer must expose `resetWarningFlag()`. Without it, test isolation is impossible across multiple test cases in the same module scope.

**AC-9 (Peeling immunity) -- MAJOR structural issue:** AC tests the LOD Manager's query behavior, not the Follower Entity's enforcement behavior. Additionally, `setPoolSize` cap semantics are ambiguous: does `n` cap Active-only or Active+Peeling total? Must be resolved before test can be written.

**AC-17 (Follower Entity perf soak) -- Integration, p99 procedure undefined:** Micro Profiler does not natively output p99. Evidence procedure must specify: export profiler JSON, extract per-frame "FollowerEntityUpdate" label durations (requires programmer to add `debug.profilebegin`/`debug.profileend`), sort samples, take 99th percentile. This must be added to the AC and to the evidence template.

**AC-20 (F4 boids) -- Math correct, two cases missing:** Math verified correct. Missing: (1) clamp-branch test where ‖V_raw‖ > MAX_SPEED; (2) zero-vector normalization skip test where F_sep=(0,0,0).

**Coverage gaps with no AC (adversarial review 2026-04-22):**
- Micro-sway behavior (`MICRO_SWAY_AMP`) during standstill — no AC exists
- Source crowd destroyed mid-peel (distinct from AC-10 which only covers Active state)
- Concurrent dual-rival peel against same Active pool
- Hat color independence during `Spawning:SlideIn` (AC-16 does not assert Hat.Color)
- `setPoolSize` cap semantics (Active-only vs. total including Peeling)
- LOD-tier bob suppression (AC-13 resets `d` but does not verify bob formula is skipped at LOD 1+)

**Why:** AC-18's spy pattern was authored against a general testing pattern, not against Roblox engine constraints. `Instance` is a userdata type; its `new` is a C++ function, not a Luau table key. AC-2 and AC-5 are formula-correctness issues found in adversarial QA review on 2026-04-22.

**How to apply:** When reviewing Follower Entity story for Done, require AC-2, AC-5, AC-7, AC-17, and AC-18 rewrites before test file is accepted. Flag ACs 4, 9, and 14 at story kickoff to confirm DI seams and cap semantics are resolved. Six coverage gaps require new ACs before sprint review.
