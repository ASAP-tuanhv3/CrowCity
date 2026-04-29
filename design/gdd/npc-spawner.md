# NPC Spawner

> **Status**: In Revision (2026-04-22 review — 16 blockers resolved; 2026-04-24 consistency-check sync pass — CROWD_START_COUNT 10→20 patch REJECTED (CSM locked 10); ρ_neutral → ρ_design rename LANDED in Absorb Batch 2; NPC pool text "200" → 300 fix; radius range [3.05, 12.03] → composed [1.53, 18.04]; F2 table recalibrated for CROWD_START=10; stale "blocks approval" flags cleared. **2026-04-26 ADR-0008 sync** — 5 edits: R5 + §Interactions L70 + §Dependencies L243 + AC-05 + §DI requirements `Accumulator` → `RunServiceShim`. ADR-0008 (Proposed 2026-04-26) locks NPCSpawner own `RunService.Heartbeat:Connect` per ADR-0002 §Related Decisions non-gameplay-tick exemption; "shared ServerTickAccumulator" placeholder eliminated. See `docs/architecture/change-impact-2026-04-26-npc-cadence.md`.)
> **Author**: user + game-designer + systems-designer + gameplay-programmer + creative-director + qa-lead + network-programmer + performance-analyst + level-designer
> **Last Updated**: 2026-04-26 (ADR-0008 cadence sync)
> **Implements Pillar**: 1 (Snowball Dopamine) — raw material for every absorb; 5 (Comeback Always Possible) — respawn pacing controls recovery rate

## Overview

The **NPC Spawner** is a server-authoritative service that manages the full lifecycle of neutral citizen NPCs — the white, player-less figures that populate the arena map and serve as the raw material for the Absorb System. On round start (`RoundLifecycle.createAll()`), it pre-populates the map with a configured neutral NPC count (`NPC_POOL_SIZE = 300`) drawn from a reusable instance pool; each NPC is assigned a starting position and begins an idle walk pattern. Per-tick, it exposes `getAllActiveNPCs()` — a frozen copy of a mutable internal snapshot of currently active NPCs — consumed by the Absorb System every 15 Hz server tick to run overlap tests. When an NPC is absorbed, the Absorb System calls `reclaim(npcId)` synchronously; the NPC Spawner marks it inactive, returns it to the pool, and schedules a respawn at an unoccupied map position after a configurable delay. Respawned NPCs fade in (Transparency tween 1→0 over 0.3s) to preserve the "oblivious drifter" fantasy. NPC positions replicate via `UnreliableRemoteEvent` with client-side interpolation — consistent with ADR-0001's server-authoritative-with-soft-broadcast pattern, NOT native Roblox Part replication. The system owns two values that feed directly into Absorb System pacing formulas: `NPC_WALK_SPEED` (how fast neutrals move, amplifying absorb rate) and `ρ_design` (round-start density of NPCs per map area; mid-round `ρ_effective` is lower and derived from F4). Without this system, the Absorb System has nothing to overlap and the core loop has no input.

## Player Fantasy

Players never see "the spawner" — they see a city that already feels alive with drifting white silhouettes, oblivious to the crowd forming behind them. The spawner's job is to make the map read as *pre-populated and sweepable* the moment a player enters view. Fantasy ownership belongs to Absorb System (`absorb-system.md`); this system owns the ambient density that makes absorption feel inevitable.

## Detailed Design

### Core Rules

**Pool initialization (round start)**
1. On `RoundLifecycle.createAll()`, allocate exactly `NPC_POOL_SIZE` (300) `Part` instances. All Parts are `Anchored = true` (direct CFrame assignment is authoritative; no physics contention). Allocation is chunked across `task.defer` — 25 Parts per deferred batch (12 batches total) — to keep round-init hitch under 50ms per frame on mobile. No `Instance.new()` calls after round start completes. Pool size is fixed for the round.
2. Initial positions drawn from a pre-registered `SPAWN_POINT_LIST` — a static list of `Vector3` positions across the arena walkable surface, authored at design time. No two NPCs start within `NPC_MIN_SPAWN_SEPARATION` studs of each other. All 300 start in `Active` state.
3. Hidden NPCs (state: `Respawning`) are parked at a holding position outside arena bounds with `Part.Transparency = 1` (server-replicated). Never destroyed or reparented mid-round — instance identity is stable, avoiding replication churn. `LocalTransparencyModifier` is NOT used — `Transparency` is the authoritative hide flag and replicates cleanly through the UREvent path (R39).

**NPC movement**
4. Each `Active` NPC runs a random walk: pick a random direction (uniform angle, XZ plane) and walk duration `T_walk ∈ [NPC_WALK_MIN_SEC, NPC_WALK_MAX_SEC]`. Move at `NPC_WALK_SPEED` studs/s via direct `CFrame` assignment (Parts are anchored — R1) for that duration, then pick a new direction.
5. Movement updates on a 15 Hz internal accumulator driven by NPC Spawner's **own** dedicated `RunService.Heartbeat:Connect` connection (per ADR-0008 §Cadence Exemption + ADR-0002 §Related Decisions L289 non-gameplay-tick exemption — NPC movement is NOT gameplay-tick work, so the "single Heartbeat" rule for TickOrchestrator does not apply). NPC Spawner registers exactly **one** `RunService.Heartbeat:Connect` after `createAll`, disconnects it on `destroyAll`, and registers ZERO `task.wait` / `task.spawn` sleep loops. CrowdStateServer + AbsorbSystem + ChestSystem + RelicSystem + CollisionResolver run on TickOrchestrator's accumulator (Phase 1-9); NPCSpawner is intentionally outside that 9-phase atomic sequence. Stale terminology note: prior text referenced a "shared `ServerTickAccumulator`" — superseded by ADR-0002 (TickOrchestrator) + ADR-0008 sync 2026-04-26.
6. If a next-step position would exceed `ARENA_BOUNDARY`, reflect direction off the boundary normal or re-roll angle. NPC never leaves the walkable area. Obstacle collision (buildings, props) is OUT OF SCOPE for MVP — NPCs phase through non-boundary geometry; arena assumed convex + single-level for MVP. Non-convex/multi-level city layouts deferred to post-MVP level-design session (see Open Questions).

**Reclaim**
7. `reclaim(npcId)` is **synchronous**. Before returning: (a) set `npc.active = false` in the mutable internal `_activeNpcs` table, (b) remove `npcId` entry from `_activeNpcs` (standard Luau table mutation — internal table is NOT frozen), (c) park Part to dormant position + set `Part.Transparency = 1`, (d) invalidate the cached frozen snapshot (set `_cachedSnapshot = nil`). All four complete before the call returns. This is the Absorb System's double-absorb prevention contract.
8. `getAllActiveNPCs()` returns a frozen COPY of the internal `_activeNpcs` table. Cached copy pattern: if `_cachedSnapshot == nil`, shallow-copy `_activeNpcs` into a new table, `table.freeze` the copy, store in `_cachedSnapshot`, return it. If cached, return the cache directly. Cache is invalidated on every `reclaim()` (R7d) and every respawn completion (R10c). Absorb System calling `getAllActiveNPCs()` once per tick gets a stable frozen snapshot; mid-tick spawns / reclaims invalidate the cache so the NEXT tick's snapshot reflects reality. Mid-iteration mutations do NOT affect the current frozen copy.

**Respawn scheduling**
9. On reclaim, schedule respawn after `T_respawn ∈ [NPC_RESPAWN_DELAY_MIN, NPC_RESPAWN_DELAY_MAX]` seconds via an injected `scheduleCallback(delay, fn) → cancelToken` function (DI contract — defaults to `task.delay` wrapped in a cancel token at production assembly; tests inject a mock-clock-driven scheduler). The returned cancel token is tracked in `self._respawnTimerJanitor:Add(cancelToken, "Cancel")` per CLAUDE.md Janitor pattern. Randomized per NPC to prevent synchronized mass-respawn pulse.
10. On respawn:
    (a) select a position from `SPAWN_POINT_LIST` where `distance_2d(pos, any crowd.position) >= NPC_RESPAWN_MIN_CROWD_DIST`. If no position qualifies after `NPC_RESPAWN_ATTEMPTS` tries, use the candidate with the greatest minimum crowd distance. Crowd positions read from Crowd State Manager via injected `CrowdStateManager:getAllCrowdPositions() → {[crowdId]: Vector3}` (one read per respawn, not per tick).
    (b) set `npc.active = true`, move Part CFrame to position.
    (c) **Fade-in**: start at `Part.Transparency = 1`, tween to `0` over `NPC_RESPAWN_FADE_SEC = 0.3s` using `TweenService`. Tween is tracked in `self._tweenJanitor` and cancelled on `destroyAll()`. NPC is in snapshot (absorb-eligible) from tween start — fade is cosmetic only.
    (d) update mutable `_activeNpcs` internal table (add entry); invalidate `_cachedSnapshot` so next `getAllActiveNPCs()` call rebuilds.
11. If all 300 NPCs are in `Respawning` simultaneously, `getAllActiveNPCs()` returns an empty frozen table. This is valid — Absorb System no-ops on empty snapshot. Not an error state; pool self-replenishes as timers fire.

**Replication strategy (ADR-0001 aligned)**
NPC positions broadcast to clients via `UnreliableRemoteEvent` (consistent with `CrowdStateBroadcast` pattern — ADR-0001). Dedicated event `NpcStateBroadcast` fires at 15 Hz carrying `{[npcId]: {pos: Vector3, active: bool}}` deltas (only NPCs whose state or position changed since last broadcast). Parts are anchored; clients hold a mirror pool of 300 Parts and apply server positions with client-side interpolation (same interp lib as Follower Entity). Server does NOT write `Part.CFrame` for replication — `CFrame` is only used server-side for overlap math + authoritative state. `Transparency` changes fire through the same broadcast delta. Rationale for consistency with ADR-0001: identical bandwidth profile, identical client-side architecture, no special case. Prerequisite implementation task: `UnreliableRemoteEventName.NpcStateBroadcast` + `Network.connectUnreliableEvent()` wrapper (same prereq as CSM GDD §C — belongs in Crowd Replication epic). Bandwidth measurement gate: joint multi-client measurement with `CrowdStateBroadcast` before MVP lock (~15 KB/s/client combined budget). Native Roblox Part replication is NOT used.

### States and Transitions

| State | Description |
|---|---|
| `Dormant` | No pool active. No NPCs in world. Between rounds. |
| `Ticking` | Pool active. All 300 NPCs managed (Active or Respawning). 15 Hz loop running. |

| Trigger | From | To |
|---|---|---|
| `RoundLifecycle.createAll()` completes | Dormant | Ticking |
| `RoundLifecycle.destroyAll()` fires | Ticking | Dormant |

No `Paused` state — NPCs continue walking during `COUNTDOWN_SNAP_SEC`. Absorb System remains Dormant during countdown (transitions at `createAll()`), so walking NPCs cannot be absorbed pre-round.

**Per-NPC state** (boolean flag on pool record, not a sub-FSM):
- `Active` — visible in world, in snapshot, movement tick running
- `Respawning` — parked off-camera, transparent, timer pending, excluded from snapshot

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|---|---|---|---|
| Absorb System | Called by | `getAllActiveNPCs()` (read, 15 Hz); `reclaim(npcId)` (write, per absorb) | Reclaim synchronous. Snapshot = frozen copy of internal table (R7/R8). |
| Round Lifecycle | Control | `createAll(participants)` → Ticking; `destroyAll()` → Dormant + pool cleanup + janitor destroy | Register listener during module init. |
| Crowd State Manager | Read (respawn only) | `CrowdStateManager:getAllCrowdPositions() → {[crowdId]: Vector3}` — used in R10a for crowd-distant spawn selection | Injected DI. One query per NPC respawn, not per tick. New method on CSM — cross-ref patch required. |
| RunService.Heartbeat (Roblox) | Direct connect | NPC Spawner owns ONE `RunService.Heartbeat:Connect` — drives 15 Hz internal accumulator (movement + broadcast). Per ADR-0008 §Cadence Exemption. | Connection registered at `createAll`; disconnected at `destroyAll`. NOT a TickOrchestrator phase callback (per ADR-0002 §Related Decisions L289). |
| Network Layer | Broadcast | Fires `UnreliableRemoteEventName.NpcStateBroadcast` at 15 Hz with position + transparency deltas | Prereq: `Network.connectUnreliableEvent` wrapper (shared with CSM). |
| TweenService (Roblox) | Call | `TweenService:Create(Part, TweenInfo.new(0.3), {Transparency = 0})` for R10c fade-in | Tracked in `_tweenJanitor`. |

### Design Tensions

1. **Late-round pool depletion**: At 8-player max absorb scenario (count=50 each), `R_absorb_total ≈ 122.6/s` (F4 recomputed with `ρ_design = 0.075`). All 300 NPCs can drain in ~2.4s peak. With `NPC_RESPAWN_DELAY_MIN = 5s` pool may be deep in `Respawning` briefly. Steady-state active ≈ 74 NPCs (F4 corrected formula). If playtest shows barren late-round arena, activate design guard: `NPC_RESPAWN_DELAY_LATE_MULT = 0.5` kicking in when active NPCs < `NPC_LATE_FLOOR = 30` for > 5s. Knob reserved in §Tuning Knobs; default off for MVP.
2. **Respawn position bias**: R10 avoids spawning near *any* crowd (crowd-distance filter is neutral). It does not actively bias toward the trailing crowd. A future relic ("Reinforcements: NPCs respawn nearer to smallest crowd") could exploit this interface cleanly without changing core rules.
3. **Opening-round density ramp**: At round start, 300 active → `ρ_design = 0.075` (peak). At 8-player steady state ~74 active → `ρ_effective ≈ 0.019`. Density drops ~4× over round. Framed as intentional "sweepable streets clear as absorbed" per art bible §6; F4 row documents the delta. If playtest shows steady-state feels dead, raise `NPC_POOL_SIZE` (safe range up to 400 at default area).

## Formulas

### F1. ρ_design and ρ_effective (NPC Density)

Two distinct density values. Both needed — designers tune the first, the system derives the second.

**F1a — ρ_design (round-start / peak density)**
`ρ_design = NPC_POOL_SIZE / ARENA_WALKABLE_AREA_SQ`

Peak density — achieved at round start before any absorb has occurred, when all pool Parts are Active. This is the **input** to Absorb System F4 formulas. ✓ Rename `ρ_neutral` → `ρ_design` LANDED in Absorb Batch 2 propagation 2026-04-24.

**F1b — ρ_effective (steady-state density)**
`ρ_effective = NPC_ACTIVE_EXPECTED / ARENA_WALKABLE_AREA_SQ` where `NPC_ACTIVE_EXPECTED` comes from F4 corrected.

Derived **output** — useful diagnostically, not as an input. Decays from `ρ_design` toward a lower steady state as absorb pressure ramps mid-round.

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| NPC pool size | `NPC_POOL_SIZE` | int | [150, 400] | Total instances managed. **Primary design lever.** Locked at 300. Upper safe range 400 (requires `ARENA_WALKABLE_AREA_SQ ≥ 4000` to keep ρ_design ≤ 0.1). |
| Arena walkable area | `ARENA_WALKABLE_AREA_SQ` | float | [1000, +∞) studs² | Measured walkable floor area. **Required — assert non-nil and > 0 at NPC Spawner module init. Module init fails loudly if unset.** No silent div-by-zero. |
| Design density | `ρ_design` | float | (0, 0.1] NPCs/stud² | Round-start density. Design target ≈ 0.075. Values > 0.1 create overcrowded visuals + saturate Absorb N_max. |
| Expected active NPCs (F4) | `NPC_ACTIVE_EXPECTED` | float | (0, NPC_POOL_SIZE] | Steady-state active count derived from F4. |
| Effective density | `ρ_effective` | float | (0, ρ_design] | Derived. Diagnostic only. |

**Output range**: `ρ_design` ≈ 0.075 at POOL=300, AREA=4000. `ρ_effective` ≈ 0.019 at 8-player peak absorb.

**Guard rule**: at module init, `assert(ARENA_WALKABLE_AREA_SQ and ARENA_WALKABLE_AREA_SQ > 0, "NPC Spawner: ARENA_WALKABLE_AREA_SQ must be registered before init")`. Round cannot start without this constant registered by level-designer tooling.

**Example**: `ARENA_WALKABLE_AREA_SQ = 4000` studs², `NPC_POOL_SIZE = 300` → `ρ_design = 0.075`. At 8 players × count=50, F4 gives `NPC_ACTIVE_EXPECTED ≈ 74` → `ρ_effective ≈ 0.019`. If level design shrinks walkable area to 2000 studs², `ρ_design = 0.15` — above 0.1 threshold → assert fails at integration. `ARENA_WALKABLE_AREA_SQ` is a Pillar 5 lever and MUST be registered as a cross-system constant in `entities.yaml` before arena ships.

---

### F2. Absorb Rate (Ownership Cross-Reference)

`R_absorb = (radius_from_count(count) * 2 * NPC_WALK_SPEED) * ρ_design`

Formula owned by Absorb System §F4. This GDD owns the three input variables:

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| NPC walk speed | `NPC_WALK_SPEED` | float | (0, 28] studs/s | **OWNED HERE.** Locked at 16 studs/s. Linear multiplier on R_absorb — change ±25% shifts all Pillar 5 values proportionally. |
| Design density | `ρ_design` | float | (0, 0.1] | **OWNED HERE** (via F1a). Linear multiplier on R_absorb. ✓ Absorb Batch 2 2026-04-24 adopted `ρ_design` name in §F3/F4 — rename complete. |
| Crowd absorb radius | `radius_from_count(count, radiusMultiplier)` | float | [1.53, 18.04] studs (composed); baseline [3.05, 12.03] at μ=1.0; MVP max [3.05, 16.24] at μ=1.35 Wingspan | Owned by registry (`radius_from_count` formula, source: ADR-0001 / CSM §F1). Composition via `crowd.radiusMultiplier` landed CSM Batch 1 2026-04-24. |

**Output range** (at locked calibration `v=16, ρ_design=0.075`, `CROWD_START_COUNT=10`):

| count | R_absorb/sec | % growth/sec | Pillar |
|---|---|---|---|
| 1 (GraceWindow floor) | 7.3 | **732%** (doubles in 0.14s) | 5 — GraceWindow rescue path at count=1 |
| 10 (CROWD_START) | 10.2 | **102%** | 1 — doubles in ~1s from fresh round start; strong absorb-dopamine onboarding beat |
| 20 | 12.2 | 61.1% | 1 — early-round growth feel |
| 50 | 15.3 | 30.7% | 1 — mid-round absorb feel |
| 100 | 19.2 | 19.2% | 1 — solid absorb feel |
| 300 | 28.9 | 9.6% | 1 — leader absorbs less relatively |

Values calibrated at `ρ_design = 0.075` (300 pool / 4000 studs² arena) and `CROWD_START_COUNT = 10` (CSM-locked 2026-04-24). Any change to `NPC_WALK_SPEED`, `ARENA_WALKABLE_AREA_SQ`, or `ρ_design` must re-verify this table. GraceWindow row (count=1) deliberately aggressive — Pillar 5 floor rescue. **⚠️ DSN-B-MATH advisory (Absorb §F4):** at late-round `ρ_effective ≈ 0.011`, the count=1 rescue rate collapses to ~1.07/s, below the 3-second grace-window threshold. Resolution deferred Batch 5 design pass (scale GRACE_WINDOW_SEC by ρ_effective OR elevate NPC density floor at count=1).

**✓ Cross-doc patches landed 2026-04-24**: Absorb Batch 2 propagated ρ rename (`ρ_neutral` → `ρ_design`) + F4 table recalibration at ρ=0.075. CSM locked `CROWD_START_COUNT = 10` (10→20 patch REJECTED — preserves first-chest gating via T1_TOLL=10 strict `count > toll` guard = 1-absorb-required beat). This GDD no longer blocks on those items.

---

### F3. Respawn Delay (T_respawn)

`T_respawn ~ Uniform(NPC_RESPAWN_DELAY_MIN, NPC_RESPAWN_DELAY_MAX)`

**Guard**: `assert(NPC_RESPAWN_DELAY_MIN < NPC_RESPAWN_DELAY_MAX, "Respawn delay range must be non-degenerate")` at module init. MIN == MAX is degenerate (collapses to constant, creates synchronized pulses); rejected loudly.

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Min respawn delay | `NPC_RESPAWN_DELAY_MIN` | float | [1, 10] s | Floor on respawn cooldown. Default: 5s. Must be strictly less than MAX. |
| Max respawn delay | `NPC_RESPAWN_DELAY_MAX` | float | (NPC_RESPAWN_DELAY_MIN, 30] s | Ceiling. Default: 10s. |
| Respawn delay | `T_respawn` | float | [MIN, MAX) s | Sampled independently per NPC per reclaim event via injected RNG. |

**Output range**: [5, 10)s at defaults. Uniform — no bunching.

**Example**: NPC reclaimed at t=42.3s, sample `T_respawn = 7.4s` → NPC re-enters pool at t=49.7s.

No late-round scaling by default. A feedback loop (fewer NPCs → slower respawn → even fewer) would run against Pillar 5. Flat uniform preserves consistent density regardless of round phase. Optional `NPC_RESPAWN_DELAY_LATE_MULT` knob (default 1.0 = off) kicks in if Design Tension §1 requires late-round pool replenishment.

---

### F4. Population at Rest (Steady-State Active NPC Count)

**Derivation** — two-compartment birth-death equilibrium. Each NPC cycles: Active (mean duration `T_active_avg`) → Respawning (mean duration `T_respawn_avg`) → Active. At steady state, flow into Respawning equals flow out:
- `N_active / T_active_avg = N_respawn / T_respawn_avg` (flow-balance: absorbs/s = respawns/s)
- `N_active + N_respawn = NPC_POOL_SIZE`
- Solving: **`NPC_ACTIVE_EXPECTED = NPC_POOL_SIZE × T_active_avg / (T_active_avg + T_respawn_avg)`** ← active-fraction numerator is `T_active`, not `T_respawn` (prior revision had these swapped — corrected).

where `T_respawn_avg = (NPC_RESPAWN_DELAY_MIN + NPC_RESPAWN_DELAY_MAX) / 2` and `T_active_avg = NPC_POOL_SIZE / R_absorb_total`.

**Guard** — if `R_absorb_total == 0` (no active crowds — pre-absorb, early round, or all Eliminated), the formula is undefined (div-by-zero through `T_active_avg`). Return `NPC_POOL_SIZE` directly: when no absorbs occur, pool stays fully active. Formal: `if R_absorb_total <= EPSILON then return NPC_POOL_SIZE end` where `EPSILON = 1e-6`.

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Pool size | `NPC_POOL_SIZE` | int | [150, 400] | Managed instances (default 300) |
| Mean respawn delay | `T_respawn_avg` | float | (0, 30] s | (MIN+MAX)/2 = 7.5s at defaults |
| Mean time active per NPC | `T_active_avg` | float | (0, +∞) s | `NPC_POOL_SIZE / R_absorb_total`; undefined at `R_absorb_total=0` (see guard) |
| Total absorb rate | `R_absorb_total` | float | [0, +∞) absorbs/s | Sum of `R_absorb(count_i)` across all active crowds. At 0, return POOL (guard). |
| Expected active NPCs | `NPC_ACTIVE_EXPECTED` | float | (0, NPC_POOL_SIZE] | Equilibrium active count |

**Output range at defaults (POOL=300, respawn 5-10s, ρ_design=0.075)**:

| Scenario | R_absorb_total | T_active_avg | NPC_ACTIVE_EXPECTED | ρ_effective |
|---|---|---|---|---|
| Lobby (0 crowds) | 0 | ∞ (guarded) | 300 | 0.075 |
| Round start (8 × count=20) | 8 × 11.9 = 95.2/s | 3.15s | 300 × 3.15/10.65 = **89** | 0.022 |
| Mid-round (8 × count=50) | 8 × 15.3 = 122.6/s | 2.45s | 300 × 2.45/9.95 = **74** | 0.018 |
| Late-round (2 × count=200) | 2 × 23.6 = 47.2/s | 6.36s | 300 × 6.36/13.86 = **138** | 0.034 |
| Peak (12 × count=100) | 12 × 19.2 = 230.4/s | 1.30s | 300 × 1.30/8.80 = **44** | 0.011 |

**Worked example (8 players, count=50 each)** — corrected computation:
- `radius_from_count(50) = 2.5 + √50 × 0.55 = 6.39 studs`
- `R_absorb(50) = (6.39 × 2 × 16) × 0.075 = 15.33/s`; × 8 = `R_absorb_total = 122.6/s`
- `T_active_avg = 300 / 122.6 = 2.45s`
- `NPC_ACTIVE_EXPECTED = 300 × 2.45 / (2.45 + 7.5) = 73.9 NPCs`

**Pool depletion verdict**: at peak-combat scenarios (12 × count=100), steady-state active can drop to ~44. Arena is noticeably thinner mid-round vs round-start (~89) — documented as intentional in Design Tension §3, consistent with art bible §6 "streets clear as absorbed." Design guard `NPC_RESPAWN_DELAY_LATE_MULT` can be activated if playtest shows this breaks Pillar 5.

## Edge Cases

**Pool boundary conditions**
- **If `reclaim()` called when `active_count == 0`**: Assert/error log — double-reclaim bug. Never silently no-op. This surfaces an Absorb System contention defect.
- **If all 300 NPCs are active (round start, none yet reclaimed)**: `getAllActiveNPCs()` returns full 300-entry frozen table. Iteration cost hits pool ceiling — Absorb AC-17 perf budget must account for this worst case (12 crowds × 300 NPCs = 3600 overlap tests/tick — supersedes prior 1200/tick assumption; cross-doc patch required on Absorb §AC-17).
- **If `getAllActiveNPCs()` called with exactly 1 active NPC**: Returns single-entry frozen table. Absorb processes normally. Snapshot construction must not short-circuit or return nil for count=1.
- **If `reclaim()` called twice on the same `npcId`** (not necessarily same tick — Luau single-threaded; race is only possible via nested callbacks): Second call finds `active == false` — MUST assert/error, not silently succeed. Forces contention bugs to surface immediately.
- **If `ARENA_WALKABLE_AREA_SQ` unregistered at module init**: hard assert fails — module refuses to initialize. No silent div-by-zero in F1. Round cannot start.
- **If `R_absorb_total == 0` mid-round** (all crowds Eliminated): F4 guard returns `NPC_POOL_SIZE` (stay full active). Pool self-sustains; no respawn timers fire (nothing to reclaim).

**Respawn position failure modes**
- **If `SPAWN_POINT_LIST` filtered by crowd-distance yields zero valid positions**: Respawn timer fires but NPC stays inactive. Restart timer with fresh `T_respawn ∈ [5, 10]s`. Not an error — valid at high crowd density. NPC re-enters pool on next successful attempt.
- **If all spawn points simultaneously invalid** (12 players at max spread covering all zones): All pending respawn timers loop indefinitely on retry. `NPC_ACTIVE_EXPECTED` collapses toward zero. Absorb System receives near-empty list — valid, no crash — but this is a tuning signal: `SPAWN_POINT_LIST` density is insufficient for the arena layout.

**Timing races**
- **If `destroyAll()` fires while respawn timers are pending**: `destroyAll()` cancels all pending timers BEFORE clearing the pool. Mandatory ordering. A timer resolving post-`destroyAll()` would activate an NPC into a torn-down pool — `reclaim()` must guard on `pool_initialized` state.
- **If `destroyAll()` fires while Absorb System is mid-iteration of the current tick's frozen snapshot**: Iteration completes on the frozen snapshot (safe — not a live reference). Any `reclaim()` calls generated during that final iteration must be guarded on pool state and no-op if pool is torn down.

**Movement edge cases**
- **If `T_walk` expires at the exact instant `reclaim()` is called**: Movement state discarded with the reclaim. On respawn, `T_walk` drawn fresh — no residual movement state remains.
- **If random walk heading points into a corner** (reflected vector near-zero length after boundary collision): Normalize reflected heading after computation. If magnitude < epsilon, reverse the NPC's heading as fallback. Zero-length heading would freeze the NPC at the boundary permanently.

**Absorb System contract edges**
- **If an NPC becomes active (respawns) between snapshot creation and tick completion**: Absent from current tick's snapshot — cannot be absorbed this tick. Appears in next tick's snapshot after cache invalidation (R10d). Correct by design — the frozen cached snapshot exists precisely to prevent mid-tick mutation inconsistency.
- **If Absorb System calls `getAllActiveNPCs()` multiple times within one tick**: each call returns the same cached frozen table until `_cachedSnapshot` is invalidated by a reclaim/respawn. No extra rebuild cost from repeated reads.

**Replication + visibility edges**
- **If Instance Streaming is enabled on the arena**: NPC Parts must be explicitly configured `StreamingEnabled = false` at the `Workspace` level OR NPC Parts set `ModelStreamingMode.Atomic` with an always-persistent ancestor Model — because client-side mirror pool (R39) assumes 300 stable Part instances replicated at all times. MVP decision: disable Instance Streaming on arena map; NPC replication goes through UnreliableRemoteEvent path, not native Part streaming.
- **If client joins mid-round**: client's mirror pool spawns 300 Parts locally on first `NpcStateBroadcast` receipt; initial full state sent in a reliable bootstrap event `NpcPoolBootstrap` on `CrowdStateBroadcast` first tick. Mid-round join policy aligns with CSM.
- **If fade-in tween is interrupted by reclaim** (NPC absorbed during fade): tween cancelled, Part transparency jumps to 1 at reclaim — consistent with absorbed VFX snap overriding residual fade.
- **If `Transparency` replication lag exceeds fade duration** (0.3s): client briefly sees NPC at full visibility before server Transparency=1 delta arrives. Accepted cosmetic edge at > 300ms latency.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Dependency type |
|---|---|---|---|
| AssetId Registry | Approved (art bible §8.9) | NPC Part meshId / appearance asset IDs | HARD — NPC Parts reference registry entries for visual appearance |
| Round Lifecycle | In Review | `createAll(participants)` → spawn pool + start ticking; `destroyAll()` → cancel timers + clear pool | HARD — cannot function outside round lifecycle events |
| Crowd State Manager | In Revision | `CrowdStateManager:getAllCrowdPositions() → {[crowdId]: Vector3}` — new method; used at respawn only | HARD — injected DI. CSM §F must add this method to its provided interface (cross-doc patch required). |
| Crowd State Manager | Batch 1 Applied 2026-04-24 | `CROWD_START_COUNT` LOCKED at 10 (2026-04-24 decision — 10→20 patch REJECTED). F2 table recalibrated at count=10 (row added). Registry source-of-truth. | ✓ RESOLVED — no longer blocks this GDD. |
| Network Layer | Approved (template) + gap | `UnreliableRemoteEventName.NpcStateBroadcast` + `NpcPoolBootstrap` (reliable) + `Network.connectUnreliableEvent()` wrapper | HARD — wrapper prereq shared with CSM; belongs in Crowd Replication epic. |
| ADR-0001 Crowd Replication | Proposed | `UnreliableRemoteEvent` broadcast cadence (15 Hz); client-side interpolation pattern | HARD — architectural foundation. NPC replication consistency with ADR required. |
| ADR-0008 NPC Spawner Authority | Accepted 2026-04-26 | §Cadence Exemption — own `RunService.Heartbeat:Connect`; §Replication Contract — `NpcStateBroadcast` UREvent + `NpcPoolBootstrap` reliable; §Caller Authority Matrix — RoundLifecycle/AbsorbSystem-only callers | HARD — architectural lock. Replaces prior "ServerTickAccumulator (new shared module)" placeholder; no shared accumulator exists. |
| ADR-0002 TickOrchestrator | Accepted 2026-04-26 | §Related Decisions L289 explicitly excludes NPCSpawner from Phase 1-9 callbacks; non-gameplay-tick exemption | HARD — codifies that NPC Spawner is OUTSIDE TickOrchestrator's 9-phase sequence. |
| Level design | Not started | `SPAWN_POINT_LIST` (list of Vector3); `ARENA_WALKABLE_AREA_SQ` (float, measured); obstacle collision model; multi-level/ledge policy; authoring format | HARD — 5 unresolved level-design deps. See Open Questions. |
| TweenService (Roblox) | Always available | `TweenService:Create()` for R10c fade-in | HARD — built-in. |
| Packages.janitor (Wally) | Listed in `wally.toml` | `Janitor.new`, `:Add(token, "Cancel")`, `:Destroy()` | HARD — lifecycle cleanup per CLAUDE.md. |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Notes |
|---|---|---|---|
| Absorb System | Designed (pending review) | `getAllActiveNPCs()` → frozen point-in-time snapshot; `reclaim(npcId)` → synchronous inactive + park | Primary consumer. All contracts in §C are authored to serve Absorb. |
| Additional City (41) | Full Vision (not started) | Same `getAllActiveNPCs()` / `reclaim()` interface — NPC Spawner is map-agnostic if `SPAWN_POINT_LIST` is injected per-map | City 2/3 reuse the same NPC Spawner with a different spawn point list. |

### Bidirectional consistency notes

- **Absorb System §D** lists `NPC Spawner (undesigned) | Read + Call` as upstream — this GDD codifies that interface. Absorb GDD provisional contract status resolved. ✅
- ✓ **Absorb System §AC-17** perf budget superseded 2026-04-24 (Absorb Batch 2 pass): 1,200 overlap tests/tick → 3,600 tests/tick (12 crowds × 300 NPCs); p99 budget 0.5 ms → 1.5 ms. Cross-doc patch landed.
- ✓ **Crowd State Manager** added `getAllCrowdPositions()` method in Batch 1 (2026-04-24). `CROWD_START_COUNT` 10→20 bump REJECTED 2026-04-24 (10 locked to preserve first-chest gating via T1_TOLL=10 strict `count > toll` guard). This GDD no longer blocks on either item.
- **Crowd State Manager** must list NPC Spawner as downstream consumer in its §F "Depended on by" after approval.
- **ADR-0001** must amend to include NPC replication as consumer of the UnreliableRemoteEvent pattern (NPCs + Followers + Crowds all share the broadcast architecture).

## Tuning Knobs

| Knob | Default | Safe Range | What breaks if too high | What breaks if too low |
|---|---|---|---|---|
| `NPC_POOL_SIZE` | 300 | [150, 400] | Overcrowded map (ρ_design > 0.1 at AREA=4000); UREvent bandwidth climbs | Map feels sparse; Pillar 5 recovery too slow for trailing crowds |
| `NPC_WALK_SPEED` | 16 studs/s | [8, 28] | R_absorb climbs; dominant crowd absorbs unsustainably; Pillar 5 table shifts | Slow NPCs; small crowds snowball too slowly; Pillar 1 feels weak |
| `NPC_RESPAWN_DELAY_MIN` | 5s | [1, 10] | N/A (floor) | Instant respawn breaks pool flow; map resets feel artificial |
| `NPC_RESPAWN_DELAY_MAX` | 10s | (MIN, 30] | Long gaps; map feels empty mid-round; Pillar 5 recovery slower | MIN ≥ MAX rejected by F3 assert |
| `NPC_WALK_MIN_SEC` | 2s | [0.5, 5] | N/A (floor) | Frantic direction-changing; unnatural jitter movement |
| `NPC_WALK_MAX_SEC` | 5s | [MIN, 10] | NPCs walk too long in one direction; cluster at map edges | Too short = jerky; approaches MIN randomization issue |
| `NPC_MIN_SPAWN_SEPARATION` | 5 studs | [2, 20] | N/A (floor) | NPCs cluster at round start; uneven early-round absorb distribution |
| `NPC_RESPAWN_MIN_CROWD_DIST` | 30 studs | [10, 60] | Respawns always far from all crowds; trailing crowd can't reach NPCs | Respawn adjacent to dominant crowd; NPCs instantly absorbed; feeds snowball leader |
| `NPC_RESPAWN_ATTEMPTS` | 10 | [3, 30] | Wasted CPU on futile search at high crowd density | Falls back to "furthest candidate" too quickly; may still place NPCs adjacent to crowds |
| `NPC_RESPAWN_FADE_SEC` | 0.3s | [0.1, 1.0] | Respawns feel slow/ghostly; concurrent tweens bloat (N × duration) | Hard pop-in; Pillar 1 fantasy breaks |
| `NPC_POOL_INIT_BATCH_SIZE` | 25 Parts | [10, 50] | Round-init hitch grows > 50ms/frame on mobile | Init takes longer total real-time (more defer cycles) |
| `NPC_RESPAWN_DELAY_LATE_MULT` | 1.0 (off) | [0.3, 1.0] | N/A (ceiling = off) | Late-round replenish more aggressive; may undermine Pillar 5 intent of "empty after sweep" |
| `NPC_LATE_FLOOR` | 30 NPCs | [10, 100] | Late-mult never activates | Late-mult activates constantly; Pillar 5 sweep feel lost |

**Interaction notes:**
- `NPC_WALK_SPEED` × `ρ_design` (derived from `NPC_POOL_SIZE` / `ARENA_WALKABLE_AREA_SQ`) are jointly the primary Pillar 5 levers. Changing one without checking the other moves the R_absorb calibration table (Absorb §F4).
- `NPC_RESPAWN_MIN_CROWD_DIST` interacts with `NPC_RESPAWN_ATTEMPTS` — if distance is high and arena is small, attempts will fail frequently. Check against arena layout before tuning either in isolation.
- `NPC_POOL_SIZE` × `ARENA_WALKABLE_AREA_SQ` must satisfy `ρ_design ≤ 0.1` — init-time assert.

## Visual/Audio Requirements

### Respawn fade-in (OWNED HERE)

Each respawning NPC runs a `TweenService` tween on `Part.Transparency` from `1` → `0` over `NPC_RESPAWN_FADE_SEC = 0.3s` (linear easing). Tween starts at R10c (after CFrame set + active=true). NPC is absorb-eligible throughout fade — snapshot inclusion not gated on transparency. Fade is cosmetic only; prevents visible pop-in contradicting "oblivious drifter" fantasy.

**Concurrent tween budget**: at 82 respawns/s steady state × 0.3s duration = ~25 concurrent tweens. Roblox `TweenService` handles this on its own scheduler; no frame cost concern on desktop, profile on iPhone SE before MVP lock.

**Interaction with replication**: `Transparency` value replicates through `NpcStateBroadcast` UREvent. Clients receiving the Transparency=1→0 change apply their own `TweenService` tween locally — server does NOT replicate mid-tween state. This halves bandwidth (one broadcast triggers client tween, not 18 discrete deltas over 0.3s at 60 Hz).

### Appearance (deferred to asset spec)

White chunky figures per art bible §3 character language. Specified in asset spec pass. Run `/asset-spec system:npc-spawner` when art bible is approved.

### No audio owned here

No SFX on respawn (respawn is ambient, not a player action). Absorb audio is owned by Absorb System §V/A.

## Acceptance Criteria

All Logic-tier ACs use TestEZ with mocked dependencies (Crowd State Manager, Round Lifecycle, scheduler, clock, RNG, Part factory). Integration-tier ACs require live Roblox Studio / `run-in-roblox`.

**AC-01 — Pool size exact** | Logic
GIVEN `createAll(participants)` completes, WHEN internal pool table queried via `getNpcPool()`, THEN the pool contains exactly `NPC_POOL_SIZE` (300) entries and every entry has `npc.active == true` (round start).

**AC-02 — Initial separation respected** | Logic
GIVEN `createAll()` with injected deterministic `SPAWN_POINT_LIST`, WHEN all NPC positions checked pairwise, THEN no two NPCs within `NPC_MIN_SPAWN_SEPARATION` studs at spawn.

**AC-03 — Zero Part allocation mid-round** | Logic
GIVEN injected `partFactory` mock with allocation spy, WHEN 100 reclaim/respawn cycles run against the pool, THEN the spy records zero `partFactory()` invocations after initial pool creation; parked NPCs have `Part.Transparency == 1`; respawned NPCs have `Part.Transparency` trending toward 0 via active tween.

**AC-04 — Walk timer in bounds (deterministic)** | Logic
GIVEN 1000 direction-change events with seeded RNG mock using a known fixed seed, WHEN `T_walk` samples collected, THEN every sample `d` satisfies `NPC_WALK_MIN_SEC ≤ d ≤ NPC_WALK_MAX_SEC` and `abs(sample_mean - expected_mean) < 0.1s`. Deterministic — no statistical tolerance required under fixed seed.

**AC-05 — Own Heartbeat connection (no competing accumulator) — REVISED 2026-04-26 per ADR-0008** | Logic
GIVEN NPC Spawner initialized with injected mock `RunServiceShim` exposing `Heartbeat:Connect(fn) → connection`, WHEN mock Heartbeat is NOT fired for 3 simulated seconds, THEN no NPC CFrame changes. WHEN mock fires with `dt = 1/15` once, THEN all active NPC CFrames advance by exactly one tick-step (one accumulator drain). Verify: (a) NPC Spawner registers EXACTLY 1 `Heartbeat:Connect` after `createAll` (via mock spy); (b) connection's `:Disconnect()` is invoked exactly once at `destroyAll`; (c) NPC Spawner registers 0 `task.wait` / `task.spawn` sleep loops (inspect module source); (d) NPC Spawner does NOT subscribe to TickOrchestrator (per ADR-0008 §Cadence Exemption — NPC movement is non-gameplay-tick).

**AC-06 — Boundary reflection** | Logic
GIVEN NPC next-step position exits `ARENA_BOUNDARY`, WHEN movement step computed, THEN velocity component normal to boundary is negated; NPC remains inside boundary after step.

**AC-07 — reclaim() synchronous — observable postconditions** | Logic
GIVEN active NPC `npcId`, WHEN `reclaim(npcId)` returns on the calling frame, THEN: (a) `npcRecord.active == false`, (b) `getAllActiveNPCs()[npcId] == nil`, (c) `Part.Position == DORMANT_POSITION`, (d) `Part.Transparency == 1`, (e) `_cachedSnapshot == nil` immediately after return. All five postconditions asserted BEFORE any yield point; a yielding impl would fail these.

**AC-08 — Double-reclaim raises error** | Logic
GIVEN `reclaim(npcId)` already called once, WHEN called again on same `npcId`, THEN assertion error thrown (`pcall` returns `false`); pool count unchanged.

**AC-09 — getAllActiveNPCs() returns frozen cached copy** | Logic
GIVEN N sequential calls with no mutations between calls, WHEN returned table references compared via `rawequal`, THEN same frozen table reference returned every call. Attempting `t[k] = v` raises error. After a `reclaim()` call, the next `getAllActiveNPCs()` returns a NEW frozen table (different reference; reflects the removed entry).

**AC-10 — Respawn delay is Uniform[MIN, MAX]** | Logic
GIVEN 500 reclaim events with seeded RNG mock (fixed seed), WHEN delays collected, THEN every delay `d` satisfies `NPC_RESPAWN_DELAY_MIN ≤ d < NPC_RESPAWN_DELAY_MAX`; `abs(sample_mean - 7.5s) < 0.3s`. Remove prior "no two consecutive identical" sub-claim.

**AC-11 — Respawn position respects crowd exclusion** | Integration
GIVEN one or more active crowds present, WHEN an NPC respawns, THEN chosen position `>= NPC_RESPAWN_MIN_CROWD_DIST` from every crowd center. Evidence: `production/qa/evidence/npc-spawner-crowd-exclusion-[date].md`.

**AC-12 — Respawn fallback when no valid position** | Logic
GIVEN injected crowd positions covering all spawn candidates within `NPC_RESPAWN_MIN_CROWD_DIST`, WHEN `respawn()` runs, THEN NPC placed at farthest candidate; no error; NPC marked active.

**AC-13 — Empty pool returns empty frozen table** | Logic
GIVEN all 300 NPCs in Respawning state, WHEN `getAllActiveNPCs()` called, THEN returns a frozen empty table (length 0); not nil; no error.

**AC-14 — destroyAll() cancels pending timers (injected scheduler)** | Logic
GIVEN NPCs in Respawning with pending timers registered on injected `scheduleCallback` mock, WHEN `destroyAll()` called, THEN all registered cancel tokens have `:cancel()` invoked (verify via mock spy); advancing mock clock 30s past all scheduled times fires zero respawn callbacks; pool is empty; no errors.

**AC-15 — Snapshot point-in-time (resolved via `_testRespawnNow` hook)** | Logic
GIVEN `getAllActiveNPCs()` captured at T0, WHEN `_testRespawnNow(npcId)` (production-code-backed test hook) forces an immediate respawn on a previously-reclaimed `npcId`, THEN the T0 frozen snapshot still excludes that `npcId` (does not mutate retroactively); the NEXT `getAllActiveNPCs()` call includes it. `_testRespawnNow(npcId)` cancels the pending respawn timer, invokes the shared `_respawnNow(npcId)` internal method synchronously, invalidates `_cachedSnapshot`. Exposed behind `__DEV__` compile-time guard (stripped in production builds via `RunService:IsStudio()` fallback). See Open Question resolution.

**AC-16 — Absorb rate cross-reference guard (F2)** | Logic
GIVEN `NPC_WALK_SPEED` imported from `SharedConstants/NpcConfig.luau` (shared constant location — resolved), WHEN Absorb System F4 rate table verified against this GDD §F2 table, THEN at defaults (`v=16, ρ_design=0.075, CROWD_START=10`): count=1 → 7.32/s ±0.01, count=10 → 10.2/s ±0.01, count=100 → 19.2/s ±0.01, count=300 → 28.9/s ±0.01. Any change to `NPC_WALK_SPEED` causes this assertion to fail on both test suites (cross-GDD guard).

**AC-17 — Steady-state equilibrium (F4) — deterministic mock-clock** | Logic
GIVEN injected mock clock + deterministic absorb schedule (inter-arrival times matching F4 expected `R_absorb_total = 122.6/s` for 8 players × count=50), WHEN mock clock advances 120 simulated seconds, THEN time-averaged active NPC count over the final 60s satisfies `|avg - 73.9| ≤ 15` (tolerance ±15 NPCs around analytical center from F4 worked example). Deterministic — no RNG variance. Prior stochastic integration test moved to AC-17b.

**AC-17b — Steady-state equilibrium soak** | Integration
GIVEN 8 live mock-player crowds at count=50 in Roblox Studio, WHEN round runs 120 real seconds with logging of active NPC count per tick, THEN time-averaged active NPC count over final 60s is within `[50, 100]`. Evidence: `production/qa/evidence/npc-spawner-soak-[date].md` (MicroProfiler JSON + active-count log).

**AC-18 — Respawn fade-in** | Logic
GIVEN NPC `npcId` respawning at T0 with `NPC_RESPAWN_FADE_SEC = 0.3s`, WHEN tween tracked, THEN `Part.Transparency` starts at 1 at T0 and reaches 0 at T0 + 0.3s. NPC is present in `getAllActiveNPCs()` from T0 (not blocked on fade completion).

**AC-19 — UnreliableRemoteEvent replication** | Integration
GIVEN server with 300 NPCs active, WHEN 15 Hz broadcast runs for 60 seconds, THEN `NpcStateBroadcast` fires exactly 900 times (±5 for accumulator slop); payload byte-size per broadcast averages < 600 bytes (delta-compressed); no client receives `Part.CFrame` via native replication (native Part replication disabled via `Anchored = true` + no `.CFrame` changes replicated — verify via server→client packet capture). Evidence: `production/qa/evidence/npc-spawner-replication-[date].md`.

**Test placement**:
- Logic tier (AC-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 12, 13, 14, 15, 16, 17, 18): `tests/unit/npc-spawner/npc_spawner.spec.luau`
- Integration tier (AC-11, 17b, 19): `tests/integration/npc-spawner/` + `production/qa/evidence/`

**DI requirements**: NpcSpawner must accept injected dependencies:
- `CrowdStateManager` with method `getAllCrowdPositions() → {[crowdId]: Vector3}`
- `RoundLifecycle` (listener target)
- `RunServiceShim` exposing `Heartbeat:Connect(fn: (dt: number) -> ()) -> { Disconnect: () -> () }` (defaults to real `RunService` in production; mock-fired in tests). REVISED 2026-04-26 per ADR-0008 — replaces prior "Accumulator with method subscribe(fn) → disconnect" DI contract.
- `scheduleCallback(delay: number, fn: () → ()) → cancelToken` (cancel-capable timer; defaults `task.delay` wrapper in production)
- `clock: () → number` (defaults `os.clock` in production)
- `rng: (min: number, max: number) → number` (defaults `math.random` in production)
- `partFactory: () → Part` (defaults `function() return Instance.new("Part") end` in production)
- `network` with method `fireAllUnreliable(eventName: string, payload: buffer)` + `fireAll(eventName: string, payload: any)` for reliable bootstrap

Without all eight injectables, ACs 03, 05, 07, 09, 10, 14, 15, 16, 17, 18 cannot be isolated in TestEZ.

## Open Questions

### Resolved in this revision (2026-04-22)

1. ~~**AC-15 test hook**~~ **RESOLVED** — `_testRespawnNow(npcId)` exposed as a method on the module, guarded by `__DEV__` compile-time check. Cancels pending respawn timer, invokes shared internal `_respawnNow(npcId)` synchronously, invalidates `_cachedSnapshot`. Production builds strip via `RunService:IsStudio() or _G.__DEV__` guard. Documented in AC-15.

2. ~~**AC-16 shared constant**~~ **RESOLVED** — `NPC_WALK_SPEED`, `NPC_POOL_SIZE`, all F2/F3 constants live in `SharedConstants/NpcConfig.luau`. Imported by both `npc_spawner.spec.luau` and `absorb_system.spec.luau`. Cross-GDD guard works by comparing the imported constant against the F2 table baseline. Matches `SharedConstants/CrowdConfig.luau` convention from CSM.

### Cross-GDD patches — resolved 2026-04-24

3. ✓ **Crowd State Manager `CROWD_START_COUNT`** — REJECTED 10→20 bump 2026-04-24 (user decision during CSM Batch 1). Value locked at 10 preserves first-chest gating via T1_TOLL=10 strict `count > toll` guard → 1-absorb-required beat. F2 table recalibrated at count=10 (row added).

4. ✓ **Crowd State Manager `getAllCrowdPositions()` method** — LANDED in CSM Batch 1 2026-04-24. CSM §Server API declares this as a read accessor (NPCSpawner-only caller).

5. ✓ **Absorb System §F — rename `ρ_neutral` → `ρ_design`** — LANDED in Absorb Batch 2 2026-04-24 propagation. Absorb F3/F4 use `ρ_design`. Cross-doc consistency achieved.

6. ✓ **Absorb System §AC-17 perf budget** — recalibrated 2026-04-24 (Absorb Batch 2 pass): 1,200 → 3,600 overlap tests/tick; p99 budget 0.5 ms → 1.5 ms (3× scale proportional to NPC pool 200 → 300). Re-profile during integration.

7. **ADR-0001 amendment — NPC replication consumer** — still outstanding. NPC Spawner's `UnreliableRemoteEvent` broadcast pattern should be documented in ADR-0001's consumer list. Not a blocker for this GDD's approval (architectural detail, can land pre-`/architecture-review` phase).

### Deferred to level-design session (block epic creation for NPC Spawner stories)

8. **`ARENA_WALKABLE_AREA_SQ`** — Pillar 5 lever. Must be registered in `design/registry/entities.yaml` before first arena ships. Owner: level-designer + systems-designer. Blocking for MVP.

9. **`SPAWN_POINT_LIST` authoring format + minimum floor** — choose (a) tagged Part folder in Workspace (via CollectionService tag `NpcSpawnPointTag`), (b) JSON file at `assets/data/spawn-points.json`, or (c) Lua constant module. Minimum list size: suggest 2× `NPC_POOL_SIZE` = 600 points for crowd-exclusion filter headroom. Owner: level-designer + lead-programmer. Blocking for MVP.

10. **Obstacle collision model for NPC movement** — MVP: NPCs phase through all non-boundary geometry (arena assumed convex, single-level). Post-MVP: raycast-based obstacle avoidance OR navmesh. Defer specification until first city map forces the decision. Owner: level-designer + gameplay-programmer.

11. **Multi-level / ledge policy** — MVP: single-level floor. Post-MVP: tiered arena support (NPCs constrained per floor). Defer. Owner: level-designer.

### Deferred to playtest (advisory, not blocking)

12. **Uniform-angle random walk feel** — flagged mechanical. If playtest shows movement reads as Brownian not pedestrian, explore simple flow biases (directional weighting, corridor alignment). Owner: game-designer.

13. **Respawn position bias toward trailing crowd** — R10 currently crowd-neutral. If Pillar 5 playtest shows leader-advantage, introduce a "Reinforcements" relic hooking into R10a to bias toward smaller crowds. Owner: game-designer + systems-designer.

14. **Late-round pool depletion** — `NPC_RESPAWN_DELAY_LATE_MULT` knob reserved (default 1.0 = off). Activate if late-round playtest shows barren arena breaks Pillar 5. Owner: game-designer.
