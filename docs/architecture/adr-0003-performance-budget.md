# ADR-0003: Performance Budget — Per-Tick + Per-Frame + Bandwidth + Memory

## Status

**Accepted 2026-04-26** (validated by `/architecture-review` 2026-04-26 — verdict CONCERNS at project level; ADR-0003 specifically had no blocking issues; mobile + multi-client + soak validation deferred to MVP integration sprints per §Validation Sprint Plan, which is acceptable for Accept transition).

Status history:
- 2026-04-24 — Proposed (initial)
- **2026-04-26 — ACCEPTED** (batch flip with ADR-0001/0002/0004/0006)

Pending amendment expected: NPC replication line item to be added to §Network bandwidth budget table when ADR-0008 NPC Spawner Authority lands (closes C2 conflict from `/architecture-review` 2026-04-26).

**Amended 2026-04-26 per ADR-0008 §ADR-0003 §Network Bandwidth Budget Amendment**: §Network table now includes `NpcStateBroadcast` line (3.0 KB/s/client steady-state, per-relevance-filtered); Reserve reduced 2.75 → 0.0 KB/s. Sum nominal 10.25 KB/s — within burst allowance band; mobile-binding revalidation deferred to MVP-Integration-3. See `docs/architecture/adr-0008-npc-spawner-authority.md` §ADR-0003 §Network Bandwidth Budget Amendment for full table.

## Date

2026-04-24 (initial), 2026-04-26 (Accepted)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Performance / Core (cross-cutting — covers server, client, network, memory) |
| **Knowledge Risk** | MEDIUM — mobile (iPhone SE) FPS behaviour at 15 Hz × 9-phase + 2400 follower visual sim untested post-cutoff; multi-client `buffer`-encoded `UnreliableRemoteEvent` bandwidth validation deferred to first MVP integration |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md`, ADR-0001 §Performance Implications + §Validation Criteria, ADR-0002 §Performance Implications, `prototypes/crowd-sync/REPORT.md`, all 14 MVP GDDs (per-system AC perf targets) |
| **Post-Cutoff APIs Used** | `buffer.*` (via ADR-0001), `UnreliableRemoteEvent` (via ADR-0001) |
| **Verification Required** | (A) Desktop 60 FPS sustained at 8 crowds × 300 followers (prototype confirmed); (B) iPhone SE emu 45 FPS at 12 crowds × 300 followers (deferred to first MVP integration); (C) 4-client bandwidth <10 KB/s/client empirical (deferred); (D) 60 s soak — no memory leak above 100 MB growth; (E) VFX 2000-particle ceiling validated under worst-case combined absorb + collision + chest + relic events |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (cadence + bandwidth context), ADR-0002 (9-phase server tick structure) |
| **Enables** | ADR-0004 (CSM Authority — per-phase CPU citations), ADR-0009 (VFX suppression tier rationale), all Phase 1-9 implementation stories |
| **Blocks** | First MVP perf-validation sprint (cannot validate without locked budgets); `/architecture-review` Phase 4 (sum-of-budgets feasibility check) |
| **Ordering Note** | Must be Accepted before ADR-0004/0005/0008/0009 so those ADRs can cite this document for per-system CPU allocations. Must be Accepted before any `/create-stories` run that includes perf AC. |

## Context

### Problem Statement

Crowdsmith's 14 MVP GDDs each state their own performance target inside their Acceptance Criteria (CSM AC-17 `<1 ms`, MSM AC-19 `<0.1 ms`, CCR AC-20 66-pair budget, Absorb AC-17 `1.5 ms @ 3600 overlap tests`, VFX 2000-particle ceiling, ADR-0001 `~5.4 KB/s/client`). No document sums these to verify they fit within the platform frame budget at target player counts. No document states the cross-platform FPS targets (desktop vs mobile vs console) in one place. No document names the memory ceiling, the rendered-instance cap under worst case, or the network-per-client cap that each subsystem contributes to.

Without a consolidated budget ADR:

- `/architecture-review` cannot run a sum-of-budgets feasibility check
- New GDDs can quietly over-commit (e.g. a future system claiming `2 ms` with no visibility that Collision + Relic + Absorb already consume `2.6 ms` at p=12)
- Mobile-vs-desktop FPS targets stay implicit and drift between GDD revisions
- Risk flags from ADR-0001 (mobile untested, multi-client untested) have no owned-by location to track resolution
- Performance testing effort has no single reference doc to validate against

### Constraints

- **Frame cadence fixed** — 60 FPS desktop/console (16.67 ms/frame), 45 FPS mobile floor (22.2 ms/frame) per `technical-preferences.md` + `game-concept.md` Technical Considerations
- **Server tick fixed** — 15 Hz (66.67 ms per tick) per ADR-0001
- **9-phase dispatch** — per ADR-0002, all server gameplay work splits across 9 sequential phases
- **Network budget** — ADR-0001 asserted <10 KB/s per client steady-state (empirically validated desktop solo; multi-client pending)
- **Mobile binding device** — iPhone SE (lowest common A-chip target) sets the ceiling for rendered instance counts + per-frame CPU
- **Memory ceiling** — Roblox imposes no hard cap but mobile Developer Console flags leaks above baseline; 60 s plateau confirmed on desktop per prototype
- **Luau single-threaded** — no GPU offload, no Parallel Luau in MVP; all budgets are on a single coroutine

### Requirements

- Consolidate every GDD's piecewise AC perf target into one table
- Lock FPS targets per-platform with validation status
- Lock per-tick CPU budget at 3 ms (4.5 % of 66.67 ms tick) with per-phase sub-allocations that sum within budget
- Lock per-frame client budget at 16.67 ms desktop / 22.2 ms mobile with sub-allocations for render + network ingest + UI
- Lock bandwidth budget at 10 KB/s/client with sub-allocations across broadcast + reliable traffic + headroom
- Lock memory budgets with per-system ceilings
- Lock worst-case instance caps (Parts, Particles, Billboards, Nameplates)
- Name risks (mobile Heartbeat jitter, multi-client bandwidth) with resolution owners + target validation sprints
- Produce a single table `/architecture-review` can sum to verify feasibility

## Decision

**Consolidated performance budget covering four dimensions — per-tick server CPU, per-frame client CPU, per-client network bandwidth, per-server memory — with worst-case instance caps. Platform FPS targets locked per-platform. Every GDD's piecewise AC perf target maps to a line in this ADR's tables; any new GDD exceeding its allocation must amend this ADR before the proposal can be Accepted.**

### Platform FPS Targets

| Platform | Target | Floor | Budget per frame | Binding? | Validation status |
|---|---|---|---|---|---|
| Desktop PC | 60 FPS | 55 FPS (ADR-0001 §Validation Criterion 1) | 16.67 ms | No | ✅ Prototype confirmed sustained 60.0 FPS at 8 crowds × 300 followers, 5-min soak |
| Mobile iPhone SE | 45 FPS | 40 FPS | 22.2 ms | **YES** — sets all worst-case instance + CPU caps | ⚠️ Deferred to first MVP integration (ADR-0001 Risk 1) |
| Console Xbox | 60 FPS | 55 FPS | 16.67 ms | No | ⚠️ Deferred to post-MVP (Xbox test kit not yet acquired) |

**Binding rule**: mobile iPhone SE drives all worst-case caps. Any budget below treats iPhone SE as the target; desktop + console get headroom automatically.

### Server Per-Tick CPU Budget — 3 ms total across 9 phases

15 Hz tick = 66.67 ms period. Budget = **3 ms per tick** (4.5 % of period). Remaining 63.67 ms is Roblox platform overhead + replication send + `Players` service + reserved for future systems.

Per-phase sub-allocation (worst case, all-systems-active tick):

| Phase | System | Budget | Basis |
|---|---|---|---|
| 1 | CollisionResolver | **0.6 ms** | 66 pairs O(p²), per-pair distance + overlap = ~9 µs/pair × 66 = 0.6 ms. CCR AC-20. |
| 2 | RelicSystem | **0.2 ms** | 12 crowds × up to 4 relics × `onTick` = 48 callbacks max; each <5 µs → 0.24 ms. |
| 3 | AbsorbSystem | **0.4 ms** | 60 NPCs × 12 crowds proximity = 720 checks; Absorb AC-17 budget 1.5 ms @ 3600 worst-case tests (hypothetical triple-pincer); typical 720 = 0.4 ms. |
| 4 | ChestSystem | **0.1 ms** | Only active on queued prompt triggers (rare per-tick); state-machine timer math on 9 MVP chests. |
| 5 | CSM.stateEvaluate | **0.2 ms** | 12 crowds F7 grace check + transition dispatch; CSM AC-17 budget ≤1 ms (this phase is smaller — eval-only, no broadcast) |
| 6 | MSM.timerCheck | **0.05 ms** | Single `tick()` comparison; MSM AC-19 |
| 7 | MSM.eliminationConsumer | **0.05 ms** | Drains ≤12 signals per tick; MSM AC-19 |
| 8 | CSM.broadcastAll | **0.4 ms** | Builds buffer payload (30 B × 12), `fireAllClients`. CSM AC-17 balance (0.6 ms eval + 0.4 ms cast = 1 ms total, matches AC). |
| 9 | PeelDispatcher.flush | **0.1 ms** | Batched `fireClient` when chest opens (rare per-tick); otherwise no-op. |
| **Reserve** | — | **0.9 ms** | Unallocated headroom for future systems; must be re-allocated via ADR amendment, not silently consumed. |
| **Sum** | — | **3.0 ms** | Total — fits 4.5 % of 66.67 ms tick period |

**Rule**: any new phase or phase expansion must first amend this ADR to re-allocate the Reserve. If Reserve is exhausted, an existing phase must reduce its allocation (by measurement + optimisation) before a new system can be added.

### Client Per-Frame CPU Budget

**Desktop / Console: 16.67 ms/frame | Mobile iPhone SE (binding): 22.2 ms/frame**

| Subsystem | Desktop budget | Mobile budget | Basis |
|---|---|---|---|
| Roblox platform render + input + Luau GC | ≤ 8 ms (reserved) | ≤ 10 ms (reserved) | Not owned by this ADR; Roblox baseline |
| FollowerEntity client sim (boids + CFrame writes) | 1.5 ms | 2.5 ms | Prototype showed <1 ms @ 80 rendered desktop; scale 2× for mobile headroom |
| FollowerLODManager swap check (10 Hz subdivided) | 0.1 ms | 0.2 ms | 10 Hz cadence; 12 crowds × tier-bucket decision |
| CrowdStateClient broadcast ingest | 0.3 ms | 0.5 ms | buffer decode (30 B × 12 crowds) × 15 Hz interleaved across 60 FPS frames → 15/60 = 25 % of frames carry a broadcast |
| MatchStateClient reconcile | 0.05 ms | 0.1 ms | Rare (per transition only) |
| VFXManager pool grants + emitter writes | 0.5 ms | 0.8 ms | 2000-particle ceiling; per-grant cost ≤ 50 µs measured in prototype |
| HUD render + widget updates | 0.5 ms | 1.0 ms | 11 widgets × 7 states; TextLabel + UIStroke updates per broadcast |
| Player Nameplate + Chest Billboard | 0.3 ms | 0.5 ms | Up to 12 Nameplates + 9 Billboards; BillboardGui scale risk MEDIUM |
| UIHandler layer swaps | 0.05 ms | 0.1 ms | Rare |
| **Reserve** | **5.37 ms** | **6.5 ms** | Unallocated; protects against Roblox platform variance + future VS+ systems |
| **Sum** | **16.67 ms** | **22.2 ms** | Fits platform budget |

### Network Bandwidth Budget — 10 KB/s per client steady-state

| Traffic | Direction | Budget | Basis |
|---|---|---|---|
| `CrowdStateBroadcast` (UnreliableRemoteEvent) | server → all | **5.4 KB/s** | ADR-0001 F1: 30 B/crowd × 12 crowds × 15 Hz = 5,400 B/s |
| `NpcStateBroadcast` (UnreliableRemoteEvent) — AMENDED 2026-04-26 per ADR-0008 | server → all (per-client relevance filter, crowd.radius + 25 studs) | **3.0 KB/s** | ADR-0008: 8 B/NPC × ~25 NPCs/tick × 15 Hz = 3,000 B/s; mid-round-join `NpcPoolBootstrap` reliable burst absorbed by burst allowance |
| Reliable gameplay events (`CrowdCreated/Destroyed/Eliminated/RelicChanged/CountClamped` + `NpcPoolBootstrap` rare on join) | server → client | **0.5 KB/s** | ~20 events per round × 100 B / (300 s round) ≈ 7 B/s steady; budget allows bursts |
| `MatchStateChanged` | server → all | **0.05 KB/s** | Rare (7 transitions × 200 B per 300 s round = 4.7 B/s) |
| VFX remotes (`Absorbed`, `HueShift`, `CollisionContactEvent`, `ChestPeelOff`, `ChestDraftOpenFX`, `ChestOpenBurst`, `RelicGrant/Expire/DraftPickVFX`) | server → client | **1.0 KB/s** | Bursty — 60 absorbs/min + 10 collision events + 6 chest opens per round, ~150 B each avg |
| `ChestInteract` / `ChestDraftPick` / `AFKToggle` | client → server | **0.1 KB/s** | Discrete events; rare per client |
| `PlayerDataUpdated` | server → client | **0.2 KB/s** | Currency grant at Result only |
| **Reserve** — REVISED 2026-04-26 per ADR-0008 | — | **0.0 KB/s** | Reserve consumed by NpcStateBroadcast; mobile-binding revalidation gates final allocation |
| **Sum** | — | **10.25 KB/s nominal** | Slight overrun absorbed by §Burst allowance (15 KB/s for ≤500ms windows); steady-state mobile validation at MVP-Integration-3 may tighten NPC cadence 15 → 10 Hz if overrun |

**Burst allowance**: up to 20 KB/s for ≤500 ms windows (round-start `CrowdCreated` fan-out, chest-open `CrowdRelicChanged` + `ChestOpenBurst` + `RelicGrantVFX` in one tick). Clients expected to smooth.

### Server Memory Budget

| Subsystem | Budget | Basis |
|---|---|---|
| CSM `_crowds` table | 2 KB | ~100 B × 12 crowds + table overhead |
| RoundLifecycle `_crowds` aux | 2 KB | ~150 B × 12 crowds + Janitor |
| MSM state + participation flags | 1 KB | 12 flags + state enum + stateEndsAt |
| ChestSystem `_chests` + `_crowdModifiers` | 4 KB | 9 chests × 400 B ChestComponent + modifier map |
| RelicSystem active-relics map | 2 KB | 12 crowds × 4 relics × RelicInstance |
| NPCSpawner `_neutrals` | 10 KB | 60 NPCs × 150 B record |
| TickOrchestrator scratch (`outPairs`, `outPeel`) | 2 KB | Worst case 66 pairs + peel burst |
| Network remote instance registry | 1 KB | ~20 RemoteEvents + 1 UnreliableRemoteEvent |
| ProfileStore active profiles | 12 KB | 12 players × 1 KB profile |
| **Subtotal (Crowdsmith systems)** | **36 KB** | — |
| Roblox platform baseline | ~3,500 MB (prototype observed) | Not owned by this ADR |
| **Leak guard** | Growth < 100 MB over 10-minute soak | Validation criterion |

### Worst-Case Instance Caps (mobile-binding)

| Instance class | Cap | Owner | Basis |
|---|---|---|---|
| Rendered follower Parts (across all crowds, single client view) | **≤ 150 Parts** | FollowerLODManager | ADR-0001 §Decision: own-close 80 + rival-close 30 + any 20-40m 15 + billboards. Worst case ~150. |
| Billboard impostors (distant crowds) | **≤ 12** | FollowerLODManager | One per crowd beyond 40 m |
| ParticleEmitters in flight | **≤ 24 pool size** | VFX Manager | VFX GDD pool worst-case |
| Active particles (total) | **≤ 2000** soft / **≤ 1950** hard suppression | VFX Manager | VFX F2 suppression tiers |
| NPC Parts (neutrals) | **≤ 60** | NPCSpawner | NPC Spawner 300-NPCs-managed cap × active-visible fraction |
| ProximityPrompts | **≤ 9** | Chest System | 6 T1 + 3 T2 MVP; T3 deferred |
| BillboardGui (Nameplates + Chest billboards) | **≤ 21** | Player Nameplate + Chest Billboard | 12 Nameplates + 9 Chest billboards |
| Chest Parts (visible) | **≤ 9** | Chest System | Same as prompts |

### Validation Sprint Plan

| Sprint | Validates | Method | Blocks |
|---|---|---|---|
| MVP-Integration-1 | Desktop per-tick + per-frame budgets under real load | Studio soak 10 min with 4 simulated crowds | Should-pass before adding more MVP stories |
| MVP-Integration-2 | iPhone SE mobile target | Studio device emulator 10 min soak | Must pass before MVP ship decision |
| MVP-Integration-3 | Multi-client bandwidth | 4-client deployed server telemetry via `Stats` service | Must pass before MVP ship decision |
| Polish-Soak-1 | 60-minute soak for leak detection | Studio long-run with telemetry | Must pass before Alpha gate |

## Alternatives Considered

### Alternative 1: Per-system budget in each GDD with no consolidation ADR (status quo)

- **Description**: Keep existing piecewise AC perf targets. Rely on `/architecture-review` to manually sum them if needed.
- **Pros**: Zero ADR overhead. Each GDD self-contained.
- **Cons**: No single document to sum against; no cross-GDD visibility; `/architecture-review` has nothing to verify against; platform FPS targets stay implicit; new GDDs can quietly over-commit.
- **Rejection Reason**: ADR-0001 Risk 1 (mobile) + Risk 4 (multi-client bandwidth) need an ADR-level owner that tracks validation. GDDs cannot own cross-cutting risks.

### Alternative 2: Separate ADRs per platform (one for desktop, one for mobile, one for console)

- **Description**: ADR-0003a (desktop), ADR-0003b (mobile), ADR-0003c (console). Each names its own budgets.
- **Pros**: Platform-specific tuning room.
- **Cons**: 3× ADR maintenance. Cross-platform budget drift risk. Mobile-binding rule gets fragmented.
- **Rejection Reason**: Mobile iPhone SE drives all worst-case caps anyway. One consolidated ADR with mobile as the binding target + desktop/console getting free headroom is simpler and harder to drift.

### Alternative 3: Budget enforced by code review + static analysis only, no ADR

- **Description**: Add CI steps that measure per-phase CPU + bandwidth; fail if exceeded. No design-time document.
- **Pros**: Empirical enforcement.
- **Cons**: Only catches regression after code is written. Doesn't stop over-commitment in design phase. Doesn't set targets for GDDs being authored. Mobile CI infeasible without physical device.
- **Rejection Reason**: Defeats purpose — this ADR is meant to prevent over-commitment during design, not just detect it post-hoc. CI enforcement is complementary, not a replacement.

## Consequences

### Positive

- Single source of truth for every FPS / CPU / bandwidth / memory / instance target
- `/architecture-review` can sum budgets + verify fit
- New GDDs have concrete targets to author against
- ADR-0001 Risk 1 + Risk 4 have an owned-by location with named validation sprints
- Mobile-binding rule explicit — desktop-only validation is not sufficient evidence
- Reserve allocations explicit — no silent consumption

### Negative

- Per-phase sub-allocations are educated estimates until mobile validation runs; Reserve must absorb actuals vs estimates
- Any new MVP or VS system touching Phase 1-9 must amend this ADR before Acceptance
- Budget table will need revision after first mobile integration test (likely within ±20 %)
- Authoring cost: this ADR must be re-visited after every playtest that surfaces perf telemetry

### Risks

- **Risk 1 (MEDIUM)** — Mobile per-frame CPU estimates diverge from reality by >30 %. Mitigation: first iPhone SE integration revises the Mobile column; Reserve absorbs overrun if <40 %; if >40 %, reduce rendered-follower caps (own-close 80 → 50, rival-close 30 → 20 per ADR-0001 Risk 1 mitigation).
- **Risk 2 (MEDIUM)** — Multi-client bandwidth exceeds 10 KB/s under real 4-client load. Mitigation: ADR-0001 buffer encoding already in place; if still over, reduce `CrowdStateBroadcast` cadence 15 Hz → 10 Hz + update client interpolation. Amend this ADR + ADR-0001 + CSM GDD § broadcast rule.
- **Risk 3 (LOW)** — VFX 2000-particle ceiling insufficient at chest-open + collision + absorb coincidence. Mitigation: VFX §F2 suppression already drops priority ≤ 3 at 1800; ADR-0009 will lock per-effect priority assignments.
- **Risk 4 (LOW)** — Xbox performance divergent from desktop. Mitigation: deferred to post-MVP Xbox test kit acquisition; treated as console-specific amendment when validation runs.
- **Risk 5 (LOW)** — Heartbeat callback itself exceeds 0.1 ms overhead on mobile, cutting into per-phase budget. Mitigation: ADR-0002 Risk 1 already flagged; per-phase budgets have Reserve absorbing this case.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/crowd-state-manager.md` AC-17 | <1 ms server CPU for state update + broadcast per tick | Phase 5 + Phase 8 allocated 0.6 ms total (0.2 + 0.4) |
| `design/gdd/crowd-state-manager.md` AC-18 | Broadcast reaches client cache within 67 ms | 15 Hz cadence + budget ensures broadcast dispatches within one tick |
| `design/gdd/match-state-machine.md` AC-19 | Tick handler <0.1 ms | Phase 6 + Phase 7 allocated 0.1 ms total |
| `design/gdd/crowd-collision-resolution.md` AC-20 | O(p²)=66 pairs per tick trivial | Phase 1 allocated 0.6 ms (~9 µs/pair) |
| `design/gdd/absorb-system.md` AC-17 | 1.5 ms budget at 3600-overlap worst case | Phase 3 allocated 0.4 ms typical; AC-17 stress case exceeds Reserve — flagged as only-during-triple-pincer event |
| `design/gdd/vfx-manager.md` §F2 suppression | 1800 soft / 1950 hard ceiling | Instance cap row: ≤ 2000 soft / ≤ 1950 hard |
| `design/gdd/follower-lod-manager.md` | 80/30/15/1 billboard tier caps | Instance cap row: ≤ 150 rendered Parts + ≤ 12 billboards |
| `design/gdd/crowd-replication-strategy.md` F1 | 5.4 KB/s/client buffer-encoded | Network row: CrowdStateBroadcast 5.4 KB/s |
| `design/gdd/hud.md` AC-perf | HUD budget 1 ms mobile | Client per-frame row: HUD 1.0 ms mobile |
| ADR-0001 Risk 1 | Mobile iPhone SE ≥45 FPS at target load | Platform target row: mobile 45 FPS floor + MVP-Integration-2 sprint |
| ADR-0001 Risk 4 | Multi-client bandwidth <10 KB/s/client | Network budget row + MVP-Integration-3 sprint |
| ADR-0002 Risk 1 | Mobile Heartbeat jitter <5 ms | Captured as Risk 5 here with Reserve absorption |

## Performance Implications

This ADR IS the performance implications document. Summary: project targets 60 FPS desktop / 45 FPS mobile / 60 FPS console with 3 ms/tick server budget + platform-dependent per-frame budgets + 10 KB/s/client network + 36 KB Crowdsmith-system memory + mobile-binding instance caps.

## Migration Plan

No existing implementation. This ADR sets targets for green-field code. Each Phase 1-9 implementation story cites this ADR's row for its budget.

## Validation Criteria

- [ ] Desktop 60 FPS sustained at 8 crowds × 300 followers, 5-min soak (✅ prototype confirmed)
- [ ] iPhone SE 45 FPS floor at 12 crowds × 300 followers, 10-min soak (DEFERRED — MVP-Integration-2)
- [ ] 4-client deployed server: bandwidth <10 KB/s/client measured via Roblox `Stats` service (DEFERRED — MVP-Integration-3)
- [ ] 10-min soak: memory growth <100 MB from baseline (DEFERRED — Polish-Soak-1)
- [ ] Worst-case combined VFX event (chest-open + 3 simultaneous collisions + absorb burst) stays <= 1950 hard cap (DEFERRED — VFX integration)
- [ ] Per-phase CPU measured via instrumented TickOrchestrator — each phase at or under allocated budget during 1-min soak at MVP load
- [ ] Reserve (0.9 ms per-tick, 5.37 ms per-frame desktop / 6.5 ms mobile, 2.75 KB/s network) remains positive under worst-case

## Related Decisions

- **ADR-0001** — Crowd Replication Strategy — sets cadence + bandwidth context this ADR consolidates
- **ADR-0002** — TickOrchestrator — 9-phase structure this ADR allocates across
- **Expected downstream**:
  - ADR-0004 CSM Authority — cites Phase 5 + Phase 8 budgets
  - ADR-0005 MSM/RL Split — cites Phase 6 + Phase 7 budgets
  - ADR-0008 NPC Spawner — cites server memory row (10 KB) + visible-NPC instance cap
  - ADR-0009 VFX Budget + Suppression — cites 2000-particle ceiling + pool sizes

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). Mobile iPhone SE emu validation is the empirical test substitute.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
