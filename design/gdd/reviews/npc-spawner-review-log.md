# NPC Spawner — Review Log

## Review — 2026-04-22 — Verdict: MAJOR REVISION NEEDED
Scope signal: L
Specialists: game-designer, systems-designer, performance-analyst, network-programmer, gameplay-programmer, qa-lead, level-designer, creative-director (synthesis)
Blocking items: 16 | Recommended: 11
Summary: F4 formula inverted (computed respawning-count not active-count — worked example 151 was wrong; corrected yields ~74). ρ=0.05 target 2-6× sparser than "alive city" fantasy. NPC CFrame replication architecturally inconsistent with ADR-0001; bandwidth risk up to 14× budget. `LocalTransparencyModifier` wrong primitive (client-only); frozen-table mutation contradicts Luau semantics. Multiple ACs non-testable (Micro Profiler Instance.new counting, scheduler spy, chi-square binning). 2 ACs blocked on open questions. 5 level-design deps unresolved. Structure + pillar-mapping mature — salvageable via targeted revision, not rewrite.
Prior verdict resolved: First review

## Revision — 2026-04-22 — Verdict pending re-review
Decisions applied:
- Density/fantasy: pool 200→300, CROWD_START 10→20 (CSM patch required), ρ_design 0.075 target
- Replication: applied ADR-0001 UnreliableRemoteEvent path (NpcStateBroadcast) + client interpolation
- Visibility: Transparency tween 1→0 over 0.3s on respawn
- Level-design deps: flagged as unresolved upstream blockers (not shipped as placeholder)

Fixes landed in GDD:
- F4 formula re-derived (numerator `T_active`, not `T_respawn`); worked example recomputed yields ~74 active at 8-player peak
- F1 split into ρ_design (input) + ρ_effective (output); init-time assert on ARENA_WALKABLE_AREA_SQ
- F3 assert MIN < MAX
- F2 table recalibrated at ρ_design=0.075, CROWD_START=20; GraceWindow count=1 row added
- R1: pool 300, Anchored=true, chunked allocation via task.defer (25 Parts per batch)
- R3, R10: Transparency not LocalTransparencyModifier
- R5: ServerTickAccumulator shared module ownership defined
- R7, R8: mutable internal _activeNpcs + frozen cached copy pattern (not frozen-with-mutation)
- R9: injected scheduleCallback with cancel token, tracked via Janitor
- R10c: fade-in tween (0.3s) added
- R39: full replication strategy rewrite — ADR-0001 UREvent path
- R40: removed (obsolete mitigation)
- Edge cases: Instance Streaming, fade interrupted by reclaim, mid-round join bootstrap, R=0 guard
- Dependencies: Network Layer, ADR-0001, ServerTickAccumulator, TweenService, Janitor, Level Design listed
- Tuning knobs: pool 300, 4 new knobs added (fade, batch size, late-mult, late-floor)
- V/A: fade-in spec added with concurrent-tween budget
- ACs rewritten: AC-01 (split Instance.new to AC-03), AC-03 (partFactory spy), AC-04 (deterministic), AC-05 (accumulator mock), AC-07 (observable postconditions), AC-09 (cached copy pattern), AC-10 (removed "consecutive identical" claim), AC-14 (injected scheduler), AC-15 (_testRespawnNow resolved), AC-16 (SharedConstants/NpcConfig.luau), AC-17 (deterministic mock-clock Logic tier), AC-17b (integration soak), AC-18 (fade-in), AC-19 (UREvent replication)
- DI contract expanded to 8 injectables
- Open Questions #1, #2 resolved; 5 level-design deps flagged as blocking; 3 playtest items flagged as advisory

Cross-GDD patches required (blocks this GDD's approval):
- CSM: CROWD_START_COUNT 10→20; add getAllCrowdPositions() method
- Absorb: rename ρ_neutral→ρ_design; recalibrate F4 table; AC-17 perf budget reprofile at 3600 tests/tick
- ADR-0001: amend to include NPC replication as UnreliableRemoteEvent consumer

Re-review: run `/design-review design/gdd/npc-spawner.md` in fresh session after CSM + Absorb + ADR-0001 patches land.
