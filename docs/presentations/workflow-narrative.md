# Crowdsmith — Claude Code Workflow Narrative

> **Purpose**: Source data for interactive HTML presentation. Hand this file to Claude (or any designer-LLM) to render as a live walkthrough of the development workflow used to build Crowdsmith from concept to mid-Production.
>
> **Audience**: Studio leadership, prospective collaborators, AI-tooling enthusiasts.
>
> **Format hint**: Sections below map naturally to:
> - Hero / intro slide
> - Horizontal timeline (Phases 1–7)
> - Click-to-expand per phase
> - Side-by-side skill catalog
> - Verdict-tracker dashboard
> - Outcome stats panel
> - Decision-tree / loop-pattern visualizer

---

## 1. Project Context

**Game**: Crowdsmith — a Roblox party game (crowd-aggregation, 5-min rounds, 8–12 players per server).
**Engine**: Roblox (Luau strict mode; engine-ref pinned 2026-04-20).
**Status**: Mid-Production. Foundation phase shipped. Sprint 1 Design-Lock complete. Vertical Slice + Core implementation are next.
**Repository**: Git, trunk-based. Main branch tracking origin.
**Workflow**: Claude Code with project-scoped skills + agents.

**The pillars** (from `design/gdd/game-concept.md`):
1. Dopamine Snowball — count-up satisfaction (felt)
2. Social Anxiety / Identity — visible crowd, public stakes (felt)
3. Clean 5-Min Rounds — anti-power-persistence (rule)
4. Cosmetic Expression — anti-pay-to-win (rule)
5. Comeback Mechanic — grace-window + relics (felt)

**Sentence summary**: a walking parade of cheerful civilians grows by absorbing rivals + neutral NPCs in 5-minute matches, where identity = your crowd's hue and cosmetics never affect outcome.

---

## 2. Workflow Philosophy

The project ran on a **skill-driven, verdict-gated workflow**:

- **Skills are reusable workflows**. Each skill is a Markdown file with phases. Examples: `/brainstorm`, `/map-systems`, `/design-review`, `/gate-check`, `/dev-story`, `/story-done`.
- **Agents are domain specialists**. Spawned via `Task` for narrow expertise: `creative-director`, `technical-director`, `art-director`, `producer`, `qa-lead`, `gameplay-programmer`, `ux-designer`, etc.
- **Verdicts gate progression**. Each major checkpoint produces APPROVE / CONCERNS / REJECT or PASS / FAIL — no advancing on hand-waving.
- **Lean review mode**. The project ran in `lean` mode — director-panel reviews fire only at phase gates (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE) instead of on every checkpoint. Solo-dev-friendly without abandoning rigor.
- **Documents are the memory**. Every decision is captured in a versioned file (GDD, ADR, story, evidence doc). Conversations are ephemeral. Files persist.

**Visualization hint**: a 4-quadrant diagram works well — "Skills (workflows)" / "Agents (specialists)" / "Verdicts (gates)" / "Files (memory)".

---

## 3. Phase Timeline

Seven phases, from `/start` to current state. Phases are not strictly chronological — some loop back (e.g. consistency-check rounds revisit GDDs after later GDDs reveal contradictions).

| # | Phase | Date Range | Skills Run | Verdicts | Key Output |
|---|-------|------------|------------|----------|------------|
| 1 | Concept | 2026-04-20 | `/start`, `/brainstorm` | (no formal verdict — single-person concept lock) | `design/gdd/game-concept.md` (5 pillars locked) |
| 2 | Technical Setup | 2026-04-20 | `/setup-engine`, `/art-bible`, `/map-systems` | (no formal verdict — artifacts gate manually) | Roblox pinned, art bible 9 sections, 41 systems enumerated |
| 3 | Systems Design | 2026-04-21 → 2026-04-24 | 16× `/design-system`, multi-round `/consistency-check` + `/propagate-design-change`, `/review-all-gdds` | `/review-all-gdds` FAIL → fixed → PASS | 16 MVP-tier GDDs |
| 4 | Pre-Production Prep | 2026-04-24 → 2026-04-26 | `/prototype crowd-sync`, `/architecture-decision` ×9, `/create-architecture`, `/architecture-review`, `/create-control-manifest` | Prototype PROCEED, Architecture-review CONCERNS→resolved | architecture.md v1.0, 9 Accepted ADRs, control-manifest v2026-04-27 |
| 5 | Foundation Implementation | 2026-04-27 (single-day burst) | `/gate-check` (FAIL), `/create-epics layer:foundation`, `/create-stories` ×4, `/story-readiness` ×N, `/dev-story` ×14, `/code-review` ×N, `/story-done` ×14 | Gate FAIL #1; per-story COMPLETE / COMPLETE-WITH-NOTES / OBSOLETE-CLOSED | 4 Foundation epics shipped (12 stories Complete + 2 Obsolete-closed); ADR-0011 Amendment 1; 2 audit gates; 10 test files |
| 6 | Sprint 1 Design-Lock | 2026-04-27 (afternoon) | `/gate-check` re-run (FAIL), `ux-designer` agent spawns ×2, direct authoring ×4 | Gate FAIL #2 | accessibility-requirements.md, 3 UX specs, 4 character profiles, asset-specs aggregate, art-bible APPROVE |
| 7 | Core Epic Planning | (current cusp) | `/create-epics layer:core` | (Producer gate per `/create-epics`) | 5 Core epics READY (tick-orchestrator, crowd-state-server, match-state-server, round-lifecycle, crowd-replication-broadcast) |

**Visualization hint**: horizontal timeline ribbon, color-coded by phase. Click-to-expand reveals per-phase deep dive.

---

## 4. Skill Catalog

### 4.1 Discovery / Concept skills

| Skill | Purpose | When used |
|-------|---------|-----------|
| `/start` | First-time onboarding — asks where you are, routes to right workflow | Project kickoff |
| `/brainstorm` | Guided ideation — concept → 5 pillars + visual identity anchor + scope tiers | Phase 1 |

### 4.2 Design skills

| Skill | Purpose | When used |
|-------|---------|-----------|
| `/setup-engine` | Pin engine + version, populate engine-reference docs, detect knowledge gaps | Phase 2 |
| `/art-bible` | 9-section visual identity spec (palettes, typography, materials, neon-permit policy) | Phase 2 |
| `/map-systems` | Decompose concept into systems, dependency graph, design-order priority | Phase 2 |
| `/design-system` | Section-by-section GDD authoring with 8 required sections | Phase 3 (×16) |
| `/design-review` | Per-GDD validation — completeness, internal consistency, implementability | Phase 3 (per-GDD) |
| `/consistency-check` | Cross-document scan vs entity registry; flags stale formulas + double-spec | Phase 3 (multi-round) |
| `/propagate-design-change` | When a GDD changes, scans all dependent docs + ADRs for stale references | Phase 3 (multi-round) |
| `/review-all-gdds` | Holistic cross-GDD design review (cross-doc consistency + game-design theory) | Phase 3 close |
| `/quick-design` | Lightweight spec for changes <4hr (skips full GDD) | (not used in this project) |

### 4.3 Architecture skills

| Skill | Purpose | When used |
|-------|---------|-----------|
| `/prototype` | Throwaway implementation to validate concept; produces structured prototype report | Phase 4 (`crowd-sync` PROCEED) |
| `/architecture-decision` | Authors a single ADR with template (Status, Context, Decision, Consequences, Engine Compat, Dependencies) | Phase 4 (×9) |
| `/create-architecture` | Master architecture blueprint — reads all GDDs + ADRs to produce the canonical doc | Phase 4 |
| `/architecture-review` | Validates architecture completeness vs all GDDs; builds traceability matrix; PASS/CONCERNS/FAIL | Phase 4 (CONCERNS→resolved) |
| `/create-control-manifest` | Flat actionable rules sheet extracted from Accepted ADRs — what programmers MUST/MUST-NOT do per layer | Phase 4 |

### 4.4 Production-pipeline skills

| Skill | Purpose | When used |
|-------|---------|-----------|
| `/gate-check` | Phase-transition validation; PASS/CONCERNS/FAIL with director panel | Phase 5 (×2 — both FAIL) |
| `/create-epics` | One epic per architectural module; defines scope + governing ADRs + engine risk | Phase 5 + Phase 7 |
| `/create-stories` | Break epic into implementable stories; each embeds GDD-req + ADR + ACs + test path | Phase 5 (×4) |
| `/story-readiness` | Pre-implementation validation — embeds correct GDD-ref + ADR + ACs + estimate | Phase 5 (×N) |
| `/dev-story` | Reads story → loads context → routes to programmer agent → implements + writes test | Phase 5 (×14) |
| `/code-review` | Architectural + quality review of changed files | Phase 5 (per-story) |
| `/story-done` | End-of-story verification — every AC checked, deviations logged, status flipped to Complete | Phase 5 (×14) |

### 4.5 Coordination + meta skills

| Skill | Purpose | When used |
|-------|---------|-----------|
| `/sprint-plan` | Generates / updates sprint plan based on milestone + capacity | (not yet used — Sprint 0 plan still pending) |
| `/qa-plan` | Test plan per sprint; classifies stories by Logic / Integration / Visual / UI / Config | (not yet used — pre-VS) |
| `/team-qa` | Orchestrates qa-lead + qa-tester for full QA cycle | (not yet used) |
| `/sprint-status` | Quick situational awareness mid-sprint | (not yet used) |
| `/scope-check` | Detects scope creep vs original plan | (not yet used) |
| `/help` | Routes to the right skill based on current state | (not yet used in this project) |

**Total skill types invoked this project**: ~17 distinct skills × many invocations = ~50+ skill runs.

---

## 5. Phase Deep-Dive

### Phase 1 — Concept (2026-04-20)

**Goal**: Lock a concept that's playable, distinct, and Roblox-shaped.

**Skills run**:
- `/start` — onboarding handshake
- `/brainstorm crowd city clone` — 5-pillar lock + scope tiers + visual identity anchor

**Output**:
- `design/gdd/game-concept.md` — single-paragraph fantasy + 5 pillars + anti-pillars (NOT pay-to-win) + scope tiers (MVP / VS+ / Alpha)

**Verdicts**: none — concept-phase is creative; verdict deferred to Phase 3 cross-GDD review.

**Insight**: Pillars 1, 2, 5 are _felt_ pillars. They CANNOT be validated from documents alone — they need playtest. This single fact ends up dominating the gate-check verdict 7 days later.

---

### Phase 2 — Technical Setup (2026-04-20)

**Goal**: Pin the engine, lock the visual identity, decompose concept into systems.

**Skills run**:
- `/setup-engine` → Roblox + Luau strict; populated `docs/engine-reference/roblox/` (VERSION.md, replication-best-practices.md, profilestore-reference.md, luau-type-system.md). Detected knowledge gap: LLM cutoff May 2025; Roblox post-cutoff APIs include UnreliableRemoteEvent + Luau buffer + Parallel Luau.
- `/art-bible` → 9-section visual identity. Cel-shaded chunky civilian aesthetic. Neon-permit policy reserves saturated palette for crowd identity (Pillar 2). No custom shaders (Roblox doesn't expose GLSL/HLSL).
- `/map-systems` → 41 systems enumerated, prioritized into Foundation / Core / Feature / Presentation / Polish layers. Bidirectional dependency map.

**Outputs**:
- `docs/engine-reference/roblox/VERSION.md`
- `design/art/art-bible.md` (9 sections)
- `design/gdd/systems-index.md` (41 systems)

**Verdicts**: none formal (artifact existence checks).

**Insight**: Pinning the engine version + recording the LLM-cutoff gap is decisive. Every later ADR has an "Engine Compatibility" section that flags HIGH / MEDIUM / LOW knowledge risk for post-cutoff APIs. This prevents AI-generated code that hallucinates an API that doesn't exist on the live platform.

---

### Phase 3 — Systems Design (2026-04-21 → 2026-04-24)

**Goal**: Author a complete GDD per MVP system. Achieve cross-GDD consistency.

**Skills run**:
- `/design-system` × 16 (one per MVP system)
- `/design-review` × 16 (per-GDD)
- `/consistency-check` × multiple rounds (after batched GDD updates)
- `/propagate-design-change` × multiple rounds (when one GDD changed an entity used by others)
- `/review-all-gdds` — holistic cross-doc design-theory check

**16 GDDs authored**:
1. Crowd State Manager — 19 ACs, 4 formulas, 10 constants
2. Match State Machine — 7-state SM + 11 transitions, 19 ACs
3. Round Lifecycle — 8 sections, 16 ACs
4. Follower Entity — 2-Part rig locked, 8 formulas, 20 ACs
5. Follower LOD Manager — 4 formulas, 15 ACs
6. Absorb System — 4 formulas, 17 ACs
7. NPC Spawner — 4 formulas, 17 ACs
8. Crowd Collision Resolution — 4 new formulas, 21 ACs
9. Relic System — 12 Core Rules, 23 ACs
10. VFX Manager — 15 Core Rules, 4 formulas, 29 ACs
11. Crowd Replication Strategy — 15 Core Rules, 4 formulas, 27 ACs (buffer-encoding mandate amendment 2026-04-24)
12. Chest System — 13 Core Rules, 7-state SM, 22 ACs
13. HUD — 14 Core Rules, 22 ACs (no-minimap-MVP decision)
14. Player Nameplate — 15 Core Rules, 5-state SM, 18 ACs
+ game-concept.md (Phase 1) + art-bible.md (Phase 2)

**Notable cross-doc events**:
- **CSM Batch 1 amendment** — Crowd State Manager added 4 signals + 3 APIs + `radiusMultiplier` field. Triggered `/propagate-design-change` cascade across 7 downstream GDDs (Relic, Nameplate, HUD, Round Lifecycle, Chest, CCR, NPC Spawner).
- **`/review-all-gdds` FAIL verdict 2026-04-24** — 8 Blocking + 6 Warning items. Resolved over 4 batches:
  - Batch 1: CSM signal/field hub amendment
  - Batch 2: Absorb / CCR formula range reconciliation (radius_from_count composed range [1.53, 18.04])
  - Batch 3: Follower LOD Manager 3-way ownership of LOD tier 2 cap (1 billboard impostor per crowd)
  - Batch 4: Chest System contract close + MSM handler order lock (TickOrchestrator phase table)
- **/consistency-check post-Batch-4** — 65/66 registry entries verified consistent. Final state.

**Outputs**:
- 16 GDDs in `design/gdd/`
- `design/gdd/reviews/gdd-cross-review-2026-04-24.md` — full FAIL + remediation report
- 5+ change-impact docs in `docs/architecture/change-impact-2026-04-24-*.md`
- `docs/architecture/registry.yaml` — entity registry (canonical formula + constant + item names)

**Verdicts**:
- `/design-review` × 16 — all PASS after revision
- `/review-all-gdds` — FAIL → PASS (after 4 batches)

**Insight**: Cross-GDD consistency drift is real and fast. Authoring 16 GDDs in 4 days produced 8 Blocking inconsistencies that no single-GDD review caught. The `/review-all-gdds` skill specifically exists to catch this class of drift. Without it, the project would have entered architecture phase with hidden contradictions.

---

### Phase 4 — Pre-Production Architecture (2026-04-24 → 2026-04-26)

**Goal**: Build the architecture blueprint before any code is written.

**Skills run**:
- `/prototype crowd-sync` → throwaway prototype validating ADR-0001 viability. PROCEED verdict (5-min desktop sustained 60 FPS @ 8 crowds × 300 followers; memory plateau, no leak).
- `/architecture-decision` × 9 — one per major decision:
  - ADR-0001 — Crowd Replication Strategy (UREvent + 15 Hz + buffer encoding)
  - ADR-0002 — Networking model
  - ADR-0003 — Performance budget allocation (frame + memory + network)
  - ADR-0004 — Cosmetic data flow + Pillar 4 anti-P2W invariant
  - ADR-0005 — MSM / RoundLifecycle split + Round-End Ordering Invariants (T6/T7/T8/T9)
  - ADR-0006 — Module Placement Rules + Layer Boundary Enforcement (Source Tree Map)
  - ADR-0008 — NPC pool management
  - ADR-0010 — Server-Authoritative Validation Policy (4-check guard pattern)
  - ADR-0011 — Persistence Schema + Pillar 3 Exclusions
  - (ADRs 0007 + 0009 deferred — owned by future Feature-tier epics)
- `/create-architecture` → master architecture document (4-layer system map + module ownership + data flow + API boundaries + ADR audit)
- `/architecture-review` → traceability matrix; CONCERNS verdict; resolved by 9-ADR Accept batch.
- `/create-control-manifest` → flat rules sheet extracted from all Accepted ADRs. Manifest Version 2026-04-27.

**Outputs**:
- `prototypes/crowd-sync/` — REPORT.md PROCEED
- `docs/architecture/architecture.md` — v1.0
- 9 Accepted ADRs in `docs/architecture/`
- `docs/architecture/tr-registry.yaml` — TR-ID registry mapping GDD requirements to ADR coverage
- `docs/architecture/control-manifest.md` — date-stamped programmer rules

**Verdicts**:
- `/prototype` — PROCEED
- `/architecture-review` — CONCERNS → resolved by ADR batch Accept

**Insight**: Prototyping ONE high-risk subsystem (crowd-sync) before architecture-lock is asymmetric value. The PROCEED verdict locks ADR-0001's UREvent + buffer-encoding decision with empirical data, preventing months of hypothetical-then-disproven architecture work. The cost was 5 days of throwaway code; the value was deciding "yes, the engine can do this" with confidence.

---

### Phase 5 — Foundation Implementation (2026-04-27, single day)

**Goal**: Ship every Foundation-layer system. Validate the workflow end-to-end on a low-risk layer before committing to Core / Feature.

**Skills run** (in order):
- `/gate-check pre-production` (morning) → **FAIL #1**. 0/4 Vertical Slice Validation items + 9 missing artifacts. Director panel: 2 NOT READY (CD + PR), 2 CONCERNS (TD + AD).
- `/create-epics layer:foundation` → 4 Foundation epics created.
- `/create-stories` × 4 — 14 stories total across 4 epics.
- For each story: `/story-readiness` → `/dev-story` → `/code-review` (when applicable) → `/story-done`.

**4 Foundation epics shipped**:
1. **asset-id-registry** (4/4 stories Complete)
   - AssetId.luau with 4 categories, 38 reserved slots
   - tools/audit-asset-ids.sh — pre-commit gate enforcing zero magic-string asset refs
   - SoundManager.luau migrated; Sounds.luau template stub deleted
2. **ui-handler-layer-reg** (1/1 effective; story-002 Obsolete-closed)
   - UILayerId enum + UILayerTypeByLayerId mapping
   - story-002 closure rationale: spec contradicted shipped UIHandler API (template idiom is layer-self-registration, not central boot scaffold)
3. **player-data-schema** (2/3 effective; story-002 Obsolete-closed)
   - 7-key MVP schema + DefaultPlayerData + persistence audit gate
   - **ADR-0011 Amendment 1** — Inventory added as 7th MVP key (cosmetic-only enforcement via ContainerByCategory registration scope). Original ADR audit step expected `OwnedSkins` / `SelectedSkin` template-shipped; actual template ships `Inventory` instead. Amendment reconciled the doc with shipped Market system.
   - story-002 closure rationale: template's `profile:Reconcile()` already handles v0→v1 default-fill; migration scaffold is dead-code-on-arrival until first real schema bump
4. **network-layer-ext** (5/5 stories Complete)
   - UnreliableRemoteEvent wrapper (HIGH-risk post-cutoff API)
   - Buffer codec for CrowdStateBroadcast — 30 B/crowd, byte-exact arch §5.7 compliance, u64 split into low/high u32
   - 22 new RemoteEventName entries + 1 new RemoteFunctionName
   - RemoteValidator 4-check guard (identity / state / parameters / rate) per ADR-0010
   - RateLimitConfig — token-bucket per-remote (windowed→token-bucket conversion documented)

**Plus**:
- 10 unit-test files in `tests/unit/` (~110 test functions)
- 2 audit gates shipped + green (`tools/audit-asset-ids.sh`, `tools/audit-persistence.sh`)
- ADR-0011 Amendment 1 documented + cross-referenced

**Verdicts**:
- Gate-check #1 — **FAIL**
- Per-story: 12 Complete / 2 Obsolete-closed / 0 Blocked

**Insight on story-OBSOLETE-CLOSED pattern**: Two stories were closed unimplemented after `/dev-story` spec inspection revealed the story's premise contradicted shipped template behavior. Closing a story with documented rationale is FASTER + CLEANER than implementing dead-code-on-arrival. Both closures cited the same architectural-redundancy pattern. Workflow-level lesson: stories should be re-validated against ACTUAL shipped code at `/story-readiness` time, not against assumed code state.

---

### Phase 6 — Sprint 1 Design-Lock (2026-04-27 afternoon)

**Goal**: Address gate-check FAIL #1 blockers from CD + AD perspective.

**Skills run**:
- `/gate-check` (re-run after Foundation) → **FAIL #2**. Same Vertical Slice blocker. Foundation infrastructure (registry / network / UI scaffolding) is necessary but not sufficient — VS is gameplay code, not framework.
- `ux-designer` agent spawn × 2 (`design/ux/hud.md`, `design/ux/main-menu.md`)
- Direct authoring × 4 (accessibility-requirements, pause-menu UX, character profiles, asset-specs)

**5 Sprint 1 deliverables shipped**:
1. **`design/accessibility-requirements.md`** (271 L)
   - Standard tier committed
   - 2 features elevated above Standard tier baseline:
     - Photosensitivity reduction toggle (Pillar 1 VFX has Harding FPA risk)
     - Hue-pattern alternative encoding (Pillar 2 identity-signaling can't rely on hue alone — ~8% colorblind population)
2. **`design/ux/hud.md`** (992 L) — 11-widget HUD spec, mobile + desktop, per-widget data binding + accessibility
3. **`design/ux/main-menu.md`** (940 L) — 8-widget main menu with 7 layer states
4. **`design/ux/pause-menu.md`** (~430 L) — multiplayer-pause-impossibility expression (4 UX devices counter "I pressed pause why is world moving" expectation)
5. **`design/characters/{index, follower, npc-neutral, player-avatar}.md`** (~1100 L total) + **`design/art/asset-specs.md`** (~280 L) + **`design/art/art-bible.md`** sign-off flipped from SKIPPED → APPROVED

**Verdicts**:
- Gate-check #2 — **FAIL** (same VS blocker; Foundation work doesn't unblock VS criterion)
- AD-ART-BIBLE — **APPROVED 2026-04-27** (after Sprint 1 deliverables)

**Insight**: A FAIL verdict isn't a failure of the work; it's a measurement of distance to gate. Both gate-checks correctly identified that Vertical Slice CANNOT be substituted by Foundation infrastructure, regardless of how much Foundation ships. The skill is doing its job. The fix is to build the VS, not to argue with the verdict.

---

### Phase 7 — Core Epic Planning (current cusp)

**Goal**: Plan the Core epics that will produce the Vertical Slice in Sprint 2.

**Skills run** (in progress):
- `/create-epics layer:core` → 5 Core epics READY:
  - tick-orchestrator
  - crowd-state-server
  - match-state-server
  - round-lifecycle
  - crowd-replication-broadcast

**Next**:
- `/create-stories tick-orchestrator` (linear order — tick-orchestrator unblocks the rest)
- Then story-creation for remaining 4 Core epics in dependency order
- Sprint 2 = Vertical Slice Build = implement Core stories + 3+ playtest sessions
- Sprint 3 = Production Pipeline = tests/integration/ + GitHub Actions CI + sprint-0.md
- Re-run `/gate-check` after Sprint 2 + Sprint 3.

---

## 6. Verdict Tracker

Every verdict, every phase, in one table:

| Date | Verdict source | Verdict | Notes |
|------|----------------|---------|-------|
| 2026-04-20 | `/brainstorm` | (concept-locked, no formal verdict) | 5 pillars accepted |
| 2026-04-21 → 04-24 | `/design-review` × 16 | PASS (all 16 after revision) | per-GDD validation |
| 2026-04-22 | `/prototype crowd-sync` | **PROCEED** | 5-min sustained 60 FPS desktop |
| 2026-04-23 | `/review-all-gdds` | **FAIL** (8 Blocking + 6 Warning) | resolved over 4 batches |
| 2026-04-24 | `/review-all-gdds` (re-run after Batch 4) | (consistency-check 65/66 clean) | final consistency |
| 2026-04-26 | `/architecture-review` | **CONCERNS** | resolved by 9-ADR Accept batch |
| 2026-04-27 | `/architecture-decision` × 9 | All **Accepted** | ADRs 0001/0002/0003/0004/0005/0006/0008/0010/0011 |
| 2026-04-27 | `/create-control-manifest` | (artifact gate) | Manifest v2026-04-27 |
| 2026-04-27 morning | `/gate-check pre-production` | **FAIL #1** | 0/4 VS Validation; 9 artifacts missing |
| 2026-04-27 | `/dev-story` × 14 | 12 COMPLETE + 2 OBSOLETE-closed | story OBSOLETE pattern documented |
| 2026-04-27 | `ADR-0011 Amendment 1` | (in-flight architecture decision) | Inventory added as 7th MVP key |
| 2026-04-27 afternoon | `/gate-check pre-production` (re-run) | **FAIL #2** | same VS blocker |
| 2026-04-27 | `AD-ART-BIBLE` (in art-bible.md) | **APPROVED** | after Sprint 1 deliverables |

**Visualization hint**: timeline of dots, color-coded by verdict (green=PASS/PROCEED/APPROVED, yellow=CONCERNS, red=FAIL). Click a dot for the verdict's full report.

---

## 7. Loop Patterns

Three repeating loop patterns drove progression:

### 7.1 Author → Validate → Revise loop (per artifact)

```
Skill A: /design-system [system-name]
  ↓
[Artifact written: design/gdd/[system].md]
  ↓
Skill B: /design-review [path]
  ↓
Verdict?
  ├─ PASS → next system
  ├─ NEEDS REVISION → fix → re-run /design-review
  └─ MAJOR REVISION → restructure → re-run /design-review
```

Used for: GDDs, ADRs, UX specs, character profiles, control manifest.

### 7.2 Cross-doc reconciliation loop

```
[Artifact A authored or amended]
  ↓
/consistency-check (scan registry vs all docs)
  ↓
[Conflicts surfaced — N stale references]
  ↓
/propagate-design-change [source-doc]
  ↓
[Edits applied to all dependent docs]
  ↓
/consistency-check (re-scan)
  ↓
Drift remaining?
  ├─ Yes → another /propagate round
  └─ No → return to feature work
```

Used for: 4 batches of post-CSM-amendment cleanup, post-Absorb-formula reconciliation, etc.

### 7.3 Story implementation loop

```
[Story written by /create-stories]
  ↓
/story-readiness [path]
  ↓
Verdict?
  ├─ READY → /dev-story
  ├─ NEEDS WORK → fix story file → re-validate
  └─ BLOCKED → resolve dependencies first
  ↓
/dev-story implements + writes test
  ↓
/code-review [files] (lean mode = skip)
  ↓
/story-done
  ↓
Verdict?
  ├─ COMPLETE → next story
  ├─ COMPLETE WITH NOTES → log advisory deviations → continue
  ├─ OBSOLETE → close with documented rationale → continue
  └─ BLOCKED → revise story file → re-loop
```

Used for: 14 Foundation stories across 4 epics.

**Visualization hint**: loop-pattern diagrams as flowcharts — each loop a closed shape with verdict-branch arrows.

---

## 8. Statistics

### 8.1 Counts

| Metric | Count |
|--------|-------|
| Distinct skills invoked | ~17 |
| Total skill runs | ~50+ |
| GDDs authored | 16 |
| ADRs Accepted | 9 (+1 amendment) |
| Stories created | 14 |
| Stories Complete | 12 |
| Stories Obsolete-closed | 2 |
| Production source modules | ~12 |
| Unit-test files | 10 |
| Test functions | ~110 |
| Audit gate scripts | 2 (both green) |
| UX specs | 3 |
| Character profiles | 4 (incl. index) |
| Phase gates run | 2 (both FAIL) |
| Director-panel agent spawns | 4 per gate-check (×2 gates = 8) |
| ux-designer agent spawns | 2 |
| gameplay-programmer agent spawns | ~10 |

### 8.2 Lines of design + architecture documentation

| Doc class | Approximate lines |
|-----------|-------------------|
| GDDs (16 systems) | ~6,000 L |
| ADRs (9 + amendment) | ~3,500 L |
| Architecture + control manifest | ~2,000 L |
| UX specs (3) | ~2,400 L |
| Character profiles (4) | ~1,100 L |
| Accessibility + asset specs | ~550 L |
| Gate-check reports (2) | ~1,500 L |
| Session logs + state | ~5,500 L |
| **Total** | **~22,500 L** |

### 8.3 Code

| File class | Approximate lines |
|------------|-------------------|
| Foundation source modules | ~1,200 L |
| Unit tests | ~1,400 L |
| Audit gate shell scripts | ~165 L |
| **Total** | **~2,800 L** |

**Doc-to-code ratio at this point**: ~8:1. Front-loaded design / architecture is intentional — every line of code is supposed to map to a documented decision. Will rebalance toward 1:1 or 1:2 once Core implementation lands.

---

## 9. Notable Decisions

### 9.1 Architectural

- **ADR-0001 Crowd Replication Strategy**: UnreliableRemoteEvent + Luau buffer encoding at 15 Hz for crowd state broadcast. Decoupled authoritative gameplay count from rendered part count (300-follower crowd → 80 entities on close client / 1 billboard impostor on far client).
- **ADR-0006 Module Placement Rules**: All cross-module identifiers via `SharedConstants/` enums. Magic strings forbidden. Two-entry-point invariant (one client, one server).
- **ADR-0010 Server-Authoritative Validation**: Mandatory 4-check guard (identity / state / parameters / rate) on every client→server handler. Silent rejection rule. Never trust payload userId.
- **ADR-0011 Persistence Schema + Pillar 3 Exclusions**: 7-key MVP schema (after Amendment 1). 10-class Pillar 3 Forbidden Keys catalog. Defense-in-depth across 6 enforcement layers.

### 9.2 Workflow

- **Lean review mode** — director-panel reviews fire only at phase gates. Solo-dev-friendly without abandoning rigor.
- **Story OBSOLETE-CLOSED pattern** — when a story's premise contradicts shipped code, close with documented rationale instead of implementing dead-code-on-arrival.
- **`/story-done` lean-mode skip discipline** — QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped, but per-AC verification + advisory-deviation documentation are NEVER skipped. The verdict format is identical to full mode; only the gate spawns differ.
- **Audit-gate pre-commit ritual** — `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` run before every commit that touches asset references / persistence layer. Catches drift at human-readable speed.

### 9.3 Game design

- **Pattern-overlay encoding** (accessibility Standard-elevated) — Pillar 2 identity uses BOTH hue + pattern. ~8% colorblind population can't be served by hue alone.
- **Photosensitivity reduction toggle** (accessibility Standard-elevated) — Pillar 1 VFX (MaxCrowdFlash + AbsorbSnap + ChestOpenT2Confetti) carries Harding FPA risk. Reduction toggle caps amplitude + particle count.
- **Multiplayer-pause-impossibility expression** — Crowdsmith CANNOT pause (server-authoritative round timer; 8-12 players). The "pause menu" explicitly says MATCH IN PROGRESS at the top, dim background lets player see world continuing, AFKToggle is the player-controlled non-pause.

---

## 10. What's Next

Per the gate-check FAIL #2 minimal path:

| Sprint | Goal | Deliverables | Blocks until |
|--------|------|--------------|--------------|
| **Sprint 1** (DONE 2026-04-27 afternoon) | Design-Lock | accessibility, UX × 3, characters, asset specs, AD APPROVE | done |
| **Sprint 2** (next) | Vertical Slice Build | `/create-stories` for 5 Core epics → `/dev-story` × N → playable end-to-end core loop demo + 3+ playtest sessions | `/gate-check` re-run (#3) |
| **Sprint 3** | Production Pipeline | `tests/integration/` populated + `.github/workflows/tests.yml` + multi-client / mobile Studio empirical validation + `production/sprints/sprint-0.md` | `/gate-check` re-run (#4) — target PASS |

**Long-tail risks** (not gate-blocking but needs treatment):
- Roblox top-bar mobile pause behavior (does it intercept our PauseMenu?)
- Pattern-overlay implementation choice (texture-baked vs runtime decal vs SurfaceAppearance.ColorMap swap)
- `AccessibilityService` post-cutoff API verification (Roblox docs needed)
- Solo-team capacity unstated → producer Sprint-0 estimate must address

---

## 11. Visualization Hints

The HTML presentation should map sections like this:

| Section | UI Element | Notes |
|---------|-----------|-------|
| §1 Project Context | Hero slide with project tagline + 5-pillar cards | Clickable pillars expand into the felt-vs-rule distinction |
| §2 Workflow Philosophy | 4-quadrant interactive diagram | Skills / Agents / Verdicts / Files |
| §3 Phase Timeline | Horizontal timeline ribbon | Phase color-coded; click expands per-phase deep dive |
| §4 Skill Catalog | Filterable card grid | Filter by phase / by purpose / by frequency-of-use |
| §5 Phase Deep-Dive | Tab-switcher per phase | Each phase tab shows: skills run, outputs, verdicts, insight |
| §6 Verdict Tracker | Timeline of dots colored by verdict | Click dot → full verdict report popup |
| §7 Loop Patterns | 3 small flowchart diagrams | Animate the loop arrows on hover |
| §8 Statistics | Stat cards + bar chart of doc-to-code ratio | Highlight 8:1 ratio at this point in project |
| §9 Notable Decisions | Cards by category (Architectural / Workflow / Game-design) | Each card links to source ADR / GDD |
| §10 What's Next | Roadmap visual (3 sprints + gate-check return points) | Sprint 1 marked DONE; Sprint 2 highlighted |
| §11 (this section) | (skip in HTML; meta-only) | |

**Color palette suggestion** (matching Crowdsmith's visual identity):
- Phase 1 Concept: warm coral `(255, 107, 107)`
- Phase 2 Tech Setup: lemon `(245, 220, 80)`
- Phase 3 Systems Design: lime `(120, 220, 100)`
- Phase 4 Architecture: sky `(80, 180, 245)`
- Phase 5 Foundation Impl: lilac `(180, 130, 230)`
- Phase 6 Sprint 1 Design-Lock: bubblegum `(245, 130, 200)`
- Phase 7 Core Epic Planning: mint `(80, 220, 200)`

Verdicts:
- PASS / PROCEED / APPROVED: green `(120, 220, 100)`
- CONCERNS: amber `(255, 167, 84)`
- FAIL / NOT READY: coral `(255, 107, 107)`
- OBSOLETE-CLOSED: muted-grey `(150, 150, 150)`

Typography hint: cel-shaded chunky aesthetic from `art-bible.md §8.4`. Bold sans-serif for headings (Gotham Bold or similar). Crisp icons. No drop-shadows.

---

## Appendix A — Skill Invocation Order (chronological)

1. `/start` (Apr 20)
2. `/brainstorm crowd city clone` (Apr 20)
3. `/setup-engine` (Apr 20)
4. `/art-bible` (Apr 20)
5. `/map-systems` (Apr 20)
6. `/design-system` × 16 (Apr 21–24)
7. `/design-review` × 16 (Apr 21–24)
8. `/prototype crowd-sync` (Apr 22)
9. `/architecture-decision` × 9 (Apr 23–27, ADRs 0001/0002/0003/0004/0005/0006/0008/0010/0011)
10. `/consistency-check` × multiple (Apr 23, 24)
11. `/propagate-design-change` × multiple (Apr 24)
12. `/review-all-gdds` (Apr 24, FAIL → fixed)
13. `/create-architecture` (Apr 26)
14. `/architecture-review` (Apr 26, CONCERNS → resolved)
15. `/create-control-manifest` (Apr 27)
16. `/gate-check pre-production` (Apr 27 morning, FAIL)
17. `/create-epics layer:foundation` (Apr 27)
18. `/create-stories` × 4 (Apr 27)
19. `/story-readiness` × N (Apr 27)
20. `/dev-story` × 14 (Apr 27)
21. `/story-done` × 14 (Apr 27)
22. `/gate-check pre-production` (Apr 27 afternoon, FAIL re-run)
23. (Sprint 1 Design-Lock: ux-designer agent spawns × 2 + direct authoring × 4)
24. `/create-epics layer:core` (Apr 27 → Apr 28)
25. (Next: `/create-stories tick-orchestrator`)

---

## Appendix B — Files reference

For deeper dives, the canonical sources:

| Topic | Path |
|-------|------|
| Game concept | `design/gdd/game-concept.md` |
| Pillars + anti-pillars | `design/gdd/game-concept.md` |
| 16 GDDs | `design/gdd/[system].md` |
| All 9 Accepted ADRs | `docs/architecture/adr-0*.md` |
| Architecture blueprint | `docs/architecture/architecture.md` |
| Control manifest | `docs/architecture/control-manifest.md` |
| TR registry | `docs/architecture/tr-registry.yaml` |
| Entity registry | `design/registry/registry.yaml` |
| Foundation epics | `production/epics/{asset-id-registry, ui-handler-layer-reg, player-data-schema, network-layer-ext}/` |
| Core epic plans | `production/epics/{tick-orchestrator, crowd-state-server, match-state-server, round-lifecycle, crowd-replication-broadcast}/` |
| Foundation source code | `src/ReplicatedStorage/Source/`, `src/ServerStorage/Source/` |
| Foundation tests | `tests/unit/` |
| Audit gates | `tools/audit-asset-ids.sh`, `tools/audit-persistence.sh` |
| UX specs | `design/ux/{hud, main-menu, pause-menu}.md` |
| Character profiles | `design/characters/` |
| Accessibility tier | `design/accessibility-requirements.md` |
| Asset specs | `design/art/asset-specs.md` |
| Art bible | `design/art/art-bible.md` (AD-APPROVED 2026-04-27) |
| Gate-check reports | `production/gate-checks/2026-04-27-pre-production-to-production*.md` |
| Session state | `production/session-state/active.md` |

---

*End of workflow narrative. Hand to Claude or designer-LLM for HTML rendering.*
