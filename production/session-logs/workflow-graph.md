# Crowdsmith — Workflow Graph

*Period: 2026-04-20 → 2026-04-22 (3 sessions)*
*Current state: Pre-Production / Systems Design phase — 6/16 MVP GDDs Designed*

---

## Full Workflow Graph — `/start` → now

```
═══════════════════════════════════════════════════════════════════════════════
  PHASE 1 — CONCEPT                                           2026-04-20 (Day 1)
═══════════════════════════════════════════════════════════════════════════════

  [START]
     │
     ▼
  ┌──────────────────────┐
  │ /start               │  onboarding, review-mode = lean
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ /brainstorm          │  "crowd city clone" → Crowdsmith concept
  │   crowd city clone   │    • 5 pillars locked
  └──────────┬───────────┘    • MDA, core loop, scope tiers
             │                • design/gdd/game-concept.md ✓
             ▼
  ┌──────────────────────┐
  │ /setup-engine        │  Roblox + Luau strict
  └──────────┬───────────┘    • technical-preferences.md ✓
             │                • docs/engine-reference/roblox/ ✓
             ▼
  ┌──────────────────────┐
  │ /art-bible           │  9 sections — visual identity locked
  └──────────┬───────────┘    • 12-color safe palette
             │                • 2-Part rig + LOD tiers + tri budgets
             │                • design/art/art-bible.md ✓
             ▼
  ┌──────────────────────┐
  │ /map-systems         │  41 systems enumerated + dependency-sorted
  └──────────┬───────────┘    • 23 MVP (7 template + 16 new)
             │                • design/gdd/systems-index.md ✓
             │
             ═══════════ CONCEPT PHASE COMPLETE ═══════════
             │
             ▼
═══════════════════════════════════════════════════════════════════════════════
  PHASE 2 — PROTOTYPE + ARCHITECTURE                          2026-04-20 (Day 1)
═══════════════════════════════════════════════════════════════════════════════

  ┌──────────────────────┐
  │ /prototype           │  8 crowds × 300 followers sustained 60 FPS 5-min
  │   crowd-sync         │  memory plateau, no leak
  └──────────┬───────────┘    • prototypes/crowd-sync/REPORT.md → PROCEED ✓
             ▼
  ┌──────────────────────┐
  │ /architecture-       │  ADR-0001 Crowd Replication Strategy — Proposed
  │   decision           │  Server hitbox-only + client boids + render caps
  └──────────┬───────────┘    • docs/architecture/adr-0001-*.md ✓
             │                • architecture.yaml: +6 stances ✓
             │
             ═══════════ SESSION BOUNDARY — COMPACTION ═══════════
             │
             ▼
═══════════════════════════════════════════════════════════════════════════════
  PHASE 3 — SYSTEMS DESIGN (current session)         2026-04-20 → 2026-04-22
═══════════════════════════════════════════════════════════════════════════════

  ┌──────────────────────┐
  │ /help                │  determine next workflow step
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ /design-system       │  SKIPPED — user: "just constant table, no GDD"
  │   AssetId Registry   │  → Convention (art bible §8.9)
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ /design-system       │  Drip-model collision + GraceWindow 3s
  │   Crowd State Manager│  7 formulas, 19 ACs, 3-state machine
  └──────────┬───────────┘    • Registry: +4 formulas + 10 constants
             ▼
  ┌──────────────────────┐
  │ /consistency-check #1│  🔴 T2_TOLL art-bible mismatch
  └──────────┬───────────┘  → art-bible.md updated, PASS
             ▼
  ┌──────────────────────┐
  │ /design-system       │  7-state machine, 10s countdown + AFK opt-out
  │   Match State Machine│  19 ACs, asymmetric AFK freeze
  └──────────┬───────────┘    • Registry: +8 constants
             ▼
  ┌──────────────────────┐
  │ /consistency-check #2│  🔴🔴 tiebreak algo + clock source
  └──────────┬───────────┘  → UserId lex + os.clock() chosen, PASS
             ▼
  ┌──────────────────────┐
  │ [Plan mode]          │  user entered plan mode → plan file
  │ ExitPlanMode         │
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ /design-system       │  Thin coordinator, peaks + placements
  │   Round Lifecycle    │  3 formulas, 16 ACs
  └──────────┬───────────┘    • RESOLVES Crowd State provisional contract
             ▼                  • Registry: +1 constant + 2 xrefs
  ┌──────────────────────┐
  │ /consistency-check #3│  ✅ PASS (0 conflicts)
  └──────────┬───────────┘
             │
             ═══════════ SESSION BOUNDARY — DATE ROLL 2026-04-21 → 2026-04-22 ═══════════
             │
             ▼
  ┌──────────────────────┐
  │ /design-system       │  HEAVIEST MVP system (L, 4+ sessions)
  │   Follower Entity    │  2-Part MeshPart (technical-artist wins)
  │                      │  boids + peel + LOD + global pool
  └──────────┬───────────┘  8 formulas, 20 ACs, 19 knobs + V/A mandatory
             ▼
  ┌──────────────────────┐
  │ /consistency-check #4│  🔴🔴🔴 TRANSFER_RATE deprecation spread
  └──────────┬───────────┘  → TRANSFER_RATE deprecated
             │                BASE=15 + SCALE=0.15 + MAX=60 added
             │                collision_transfer_per_tick formula revised
             │                Crowd State §C.1 + Follower Entity §D fixed, PASS
             ▼
  ┌──────────────────────┐
  │ /design-system       │  Thin sibling of Follower Entity
  │   Follower LOD Mgr   │  10 Hz setInterval, hysteresis ±1, mobile x0.5
  └──────────┬───────────┘  4 formulas, 15 ACs
             ▼                • RESOLVES Follower Entity getPeelingCount contract
  ┌──────────────────────┐
  │ /consistency-check #5│  ⚠️⚠️⚠️ 3 doc-staleness TRANSFER_RATE refs
  └──────────┬───────────┘  → 3 in-place edits, PASS
             ▼
  ┌──────────────────────┐
  │ /design-system       │  Pillar 1 primary — the +1 tick dopamine
  │   Absorb System      │  piggyback Crowd State 15 Hz loop
  └──────────┬───────────┘  4 formulas (sqrt Pillar 5 comeback math), 17 ACs
             ▼                • 6 cross-GDD contracts flagged
  ┌──────────────────────┐
  │ /consistency-check #6│  🔴 VFX call-site ambiguity (FE vs Absorb)
  └──────────┬───────────┘  → FE §V aligned to Absorb Model A, PASS
             │
             │
             ▼
   [CURRENT STATE]
   ════════════════════════════════════════════
    Pre-Production / Systems Design — 6/16 MVP GDDs Designed
    ════════════════════════════════════════════


═══════════════════════════════════════════════════════════════════════════════
  PHASE 4 — AHEAD (not yet run)
═══════════════════════════════════════════════════════════════════════════════

             ▼ (next possible paths)
  ┌─────────────────────────────────┐
  │ /design-system NPC Spawner      │  resolves 4 Absorb contracts
  │ /design-system Crowd Collision  │  closes peel server-side
  │ /design-system Chest / Relic    │  Pillar 2 Risky Chests
  │ /design-system HUD / Nameplate  │  UI layer
  │ /design-system VFX Mgr / Audio  │  V/A consumers
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /review-all-gdds                │  holistic design-theory cross-review
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /create-architecture            │  master architecture doc
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /architecture-decision (x N)    │  more ADRs (currently have ADR-0001 only)
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /architecture-review            │  validate ADR set
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /create-control-manifest        │  programmer rules sheet
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /gate-check pre-production      │  phase-gate validation
  └──────────────┬──────────────────┘
                 ▼
  ┌─────────────────────────────────┐
  │ /ux-design → /prototype → ...   │  Pre-Production phase
  └─────────────────────────────────┘
```

---

## Phase Summary

| Phase | Skills run | Outputs | Duration |
|---|---|---|---|
| 1 Concept | `/start`, `/brainstorm`, `/setup-engine`, `/art-bible`, `/map-systems` | game-concept.md, art-bible.md, systems-index.md, engine-reference docs | Day 1 |
| 2 Prototype+ADR | `/prototype`, `/architecture-decision` | crowd-sync prototype (PROCEED), ADR-0001, architecture.yaml | Day 1 |
| 3 Systems Design (current) | `/help`, `/design-system` ×6, `/consistency-check` ×6, `ExitPlanMode` | 6 MVP GDDs, 26 registry entries, 106 ACs | Days 1-3 |
| 4 Architecture (ahead) | `/create-architecture`, `/architecture-decision`, `/architecture-review`, `/create-control-manifest` | architecture.md, more ADRs, control-manifest.md | TBD |
| 5 Pre-Prod (ahead) | `/ux-design`, `/prototype`, `/create-epics`, `/create-stories`, `/sprint-plan` | UX specs, epics, stories, first sprint | TBD |
| 6 Production (ahead) | `/dev-story`, `/story-done`, `/sprint-plan` | src/ code, sprint artifacts | TBD |

---

## Gate Status (per workflow catalog)

```
  Concept Gate              ✅ CROSSED (5/5 required steps done)
  Systems Design Gate       ⏳ IN PROGRESS (6/16 MVP GDDs — cross-GDD review not run)
  Technical Setup Gate      ○ NOT STARTED (1/3+ ADRs; no architecture.md; no control-manifest)
  Pre-Production Gate       ○ NOT STARTED
  Production Gate           ○ NOT STARTED
```

---

## Session Stats

| Metric | Value |
|---|---|
| GDDs authored | 6 (+ 1 skipped as convention) |
| Total formulas designed | 27 (4 Crowd + 7 Match + 3 Round + 8 Follower Entity + 4 LOD + 4 Absorb, dedup count) |
| Total ACs written | 106 (19+19+16+20+15+17) |
| Registry entries created | 26 (4 formulas + 22 constants, 1 deprecated) |
| Specialist agent spawns | ~25 (creative-director ×7, systems-designer ×10, technical-artist ×3, gameplay-programmer ×5, art-director ×3, qa-lead ×6) |
| Consistency checks run | 6 |
| Conflicts resolved | 8 (1 art-bible, 2 Match State, 3 TRANSFER_RATE, 1 doc-staleness batch, 1 VFX) |
| Pillar coverage | 1 (Snowball) ✓, 2 (Chests) pending Chest/Relic, 3 (Clean Rounds) ✓, 4 (Cosmetic) ✓ partial, 5 (Comeback) ✓ |

---

## Consistency-Check Run Log

| Run | Date | GDDs | Conflicts | Classification | Fix |
|---|---|---|---|---|---|
| 1 | 2026-04-20 | 1 | 1 | 🔴 art-bible T2_TOLL vs GDD | art-bible updated |
| 2 | 2026-04-20 | 2 | 2 | 🔴 tiebreak algo + clock source | UserId + `os.clock()` |
| 3 | 2026-04-21 | 3 | 0 | ✅ PASS | — |
| 4 | 2026-04-22 | 4 | 3 | 🔴 TRANSFER_RATE deprecation spread | registry + 2 GDDs |
| 5 | 2026-04-22 | 5 | 0 | ✅ PASS (3 ⚠️ doc staleness fixed) | 3 in-place edits |
| 6 | 2026-04-22 | 6 | 1 | 🔴 VFX call-site ambiguity | FE §V aligned |

---

## Cross-GDD Patches Propagated Cleanly

```
  ┌─ Crowd State Manager §F provisional              RESOLVED by Round Lifecycle §F
  │  "Round Lifecycle exposes createAll/destroyAll"
  │
  ├─ Follower Entity §F contract requirement         RESOLVED by Follower LOD Manager §C.1
  │  "LOD Manager must honor getPeelingCount"
  │
  ├─ Match State §F4 peak_count_timestamp ownership  RESOLVED by Round Lifecycle §F1
  │  (Round Lifecycle owns via getPeakTimestamp)
  │
  ├─ VFX AbsorbSnap call-site                        RESOLVED in /consistency-check #6
  │  (VFX Manager direct subscriber, not Follower Entity relay)
  │
  ├─ Crowd State CountChanged signal declaration     PENDING patch to Crowd State §F
  │  (flagged by Round Lifecycle + Follower Entity)
  │
  └─ NPC Spawner interface contract (4 items)        PENDING NPC Spawner GDD
     (snapshot semantics, atomic reclaim, NPC_WALK_SPEED, ρ_neutral)
```

---

## GDD Dependency Graph (current)

```
                      ┌──────────────────────────────────┐
                      │  ADR-0001 Crowd Replication      │
                      │  (Proposed — foundational)       │
                      └────────┬─────────────────────────┘
                               │
                               │ locks: 15 Hz, radius_from_count,
                               │ tier distances, render caps
                               ▼
           ┌───────────────────────────────────────┐
           │     Crowd State Manager (In Review)   │
           │  3 states, drip model, hue assign     │◄─┐
           └───────┬────────┬────────┬──────────┬──┘  │
                   │        │        │          │     │
            createAll│  positions │  Eliminated│  updateCount
            destroyAll  +count+hue    +CountChanged   (+1/+N)
                   │        │        │          │     │
                   ▼        ▼        ▼          │     │
           ┌──────────┐ ┌──────────┐ ┌─────────┴─────┴──────┐
           │  Round   │ │ Follower │ │  Match State Machine │
           │Lifecycle │ │  Entity  │ │  (In Revision)       │
           │(InReview)│ │(InReview)│ │  7 states, timer     │
           └────┬─────┘ └────┬─────┘ └──────┬───────────────┘
                │            │              │
       get      │            │  setLOD      │ createAll/destroyAll
       Peaks/   │  Absorbed  │  setPoolSize │ getPlacements
       Placmnts │  signal    │  getPeeling  │ setWinner
                │            │              │
                ▼            ▼              ▼
         ┌────────────────────────┐  ┌──────────────────┐
         │  Absorb System         │  │ Follower LOD     │
         │  (Designed)            │  │ Manager          │
         │  + piggyback 15 Hz     │  │ (Designed)       │
         │  + Pillar 1 dopamine   │  │ 10 Hz tick,      │
         └───────┬────────────────┘  │ hysteresis,      │
                 │                   │ mobile x0.5      │
                 │ contracts flagged └──────────────────┘
                 ▼
         ┌────────────────────────────────────────┐
         │ UNDESIGNED (provisional contracts)     │
         │ • NPC Spawner                          │
         │ • VFX Manager                          │
         │ • Audio / Crowd Collision Resolution   │
         │ • Chest / Relic / HUD / Skin           │
         └────────────────────────────────────────┘
```

---

## Systems Index Snapshot

```
MVP systems designed:  6 / 16 new MVP  (+7 template = 13 / 23 MVP total)
                       ─────────────────────────────────────────
  ✓ Convention      AssetId Registry            (art bible §8.9)
  ✓ Designed        Crowd State Manager         [In Revision]
  ✓ Designed        Match State Machine         [In Revision]
  ✓ Designed        Round Lifecycle             [In Revision]
  ✓ Designed        Follower Entity             [In Review]
  ✓ Designed        Follower LOD Manager        [pending review]
  ✓ Designed        Absorb System               [pending review]
  ○ Not Started     NPC Spawner                 (4 contracts pending)
  ○ Not Started     Crowd Collision Resolution
  ○ Not Started     Chest System T1/T2
  ○ Not Started     Relic System
  ○ Not Started     HUD
  ○ Not Started     Player Nameplate
  ○ Not Started     Chest Billboard
  ○ Not Started     VFX Manager
  ○ Not Started     Crowd Replication Strategy (GDD — ADR exists)
```

---

## Registry Growth Curve

```
  Entries
    │
  26┤                                     ●●●●●●●●●●●● 26 (4 formulas + 22 constants)
  24┤                                 ●●●●
  22┤                             ●●● 22 (Absorb x-refs)
  20┤                         ●●● 19 (LOD Mgr: no new)
  18┤                   ●●●●●●
  16┤                ●●● 16 (Follower Entity x-refs)
  14┤            ●●● 14 (TRANSFER_RATE split: -1 +3 +1 fmla = +3 net)
  12┤         ●●●  +1 (Round Lifecycle)
  10┤     ●●● 11 (Match State +8 const + 3 xref)
   8┤  ●●●  12 (Crowd State: 4 fmla + 10 const)
   6┤● initial
   4┤
   2┤
   0┤●
     └────┬────┬────┬────┬────┬────┬────┬────
       /CS  /MS  /RL  /FE  /LOD /AB  now
```

---

## Next Systems to Design (per provisional contract density)

1. **NPC Spawner** — resolves 4 Absorb provisional contracts
2. **Crowd Collision Resolution** — closes server-side peel contract, consumes Crowd State drip model
3. **Relic System** — resolves radius-modifier ownership flag from Absorb §E + Crowd State GraceWindow up-delta rule
