# Systems Index: Crowdsmith

> **Status**: Draft
> **Created**: 2026-04-20
> **Last Updated**: 2026-04-20
> **Source Concept**: design/gdd/game-concept.md
> **Review Gates**: TD-SYSTEM-BOUNDARY / PR-SCOPE / CD-SYSTEMS — SKIPPED (lean review mode)

---

## Overview

Crowdsmith is a 5-minute Roblox arena (hypercasual .io + roguelike relic-draft hybrid). Players absorb neutral NPCs to grow a crowd of followers, pay follower tolls at tiered chests (T1 chest / T2 car / T3 building) for random run-scoped relics, and crush smaller rival crowds. Cosmetic-only meta progression (skin shop + daily quests).

Pillars constrain the system set:

1. **Snowball Dopamine** — Absorb + VFX + Audio systems must feel intrinsically great
2. **Risky Chests** — Chest + Relic systems drive mid-round decision depth
3. **5-Minute Clean Rounds** — Round Lifecycle + Match State Machine enforce round purity; no persistent power
4. **Cosmetic Expression** — Skin System applies to player AND whole follower crowd
5. **Comeback Always Possible** — Crowd Collision Resolution + Relic variance keep underdog path open

**Scope**: 31 systems (7 template-provided + 24 new). 13 MVP, 6 Vertical Slice, 7 Alpha/V1, 5 V1.5 Full Vision.

**Binding risks**: Crowd Replication Strategy + Follower Entity + Follower LOD Manager are technically unproven at 800+ on-screen characters. Prototype before MVP lock-in.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Network Layer (template-provided) | Core | MVP | Approved (via template) | — | — |
| 2 | PlayerData / ProfileStore (template-provided) | Persistence | MVP | Approved (via template) | — | Network Layer |
| 3 | UIHandler (template-provided) | UI | MVP | Approved (via template) | — | — |
| 4 | Currency — Coins (template-provided) | Economy | MVP | Approved (via template) | — | PlayerData |
| 5 | Zone Handler (template-provided) | Core | MVP | Approved (via template) | — | — |
| 6 | ComponentCreator (template-provided) | Core | MVP | Approved (via template) | — | — |
| 7 | Collision Groups (template-provided) | Core | MVP | Approved (via template) | — | — |
| 8 | AssetId Registry | Core | MVP | Convention (art bible §8.9) | design/art/art-bible.md §8.8–8.9 | — |
| 9 | NPC Spawner (inferred) | Gameplay | MVP | Consistency-sync 2026-04-24 (16 prior blockers; all cross-doc patches landed except ADR-0001 NPC-replication consumer doc — non-blocking) | design/gdd/npc-spawner.md | AssetId Registry, Crowd State Manager, Round Lifecycle, Network Layer, ADR-0001, Level Design |
| 10 | Follower Entity | Gameplay | MVP | Batch 3 Applied 2026-04-24 (Overview tier 2 cap aligned; transfer rate dynamic) | design/gdd/follower-entity.md | AssetId Registry, Crowd State Manager, ADR-0001 |
| 11 | Follower LOD Manager | Gameplay | MVP | Sole Owner Declared 2026-04-24 (render caps + LOD distances) | design/gdd/follower-lod-manager.md | Follower Entity, Crowd State Manager, ADR-0001 |
| 12 | Crowd State Manager | Gameplay | MVP | Batch 1 Applied 2026-04-24 (pending Batches 2-5) | design/gdd/crowd-state-manager.md | PlayerData, Network Layer, ADR-0001 |
| 13 | Match State Machine | Core | MVP | Batch 4 Close Applied 2026-04-24 (9-phase TickOrchestrator handler order locked; T6/T7 simultaneity resolved) | design/gdd/match-state-machine.md | Network Layer, Crowd State Manager |
| 14 | Absorb System | Gameplay | MVP | Batch 2 Applied 2026-04-24 (radius range + ρ rename + F4 recalibrate; pending DSN-B-MATH Batch 5) | design/gdd/absorb-system.md | Follower Entity, NPC Spawner, Crowd State Manager, ADR-0001 |
| 15 | Crowd Collision Resolution | Gameplay | MVP | Batch 2 Applied 2026-04-24 (radius range composed + 7 CSM-amendment flags cleared) | design/gdd/crowd-collision-resolution.md | Crowd State Manager, Follower Entity, ADR-0001 |
| 15a | TickOrchestrator (spin-off — introduced by Crowd Collision Resolution) | Core | MVP | Designed (within Crowd Collision Resolution GDD) | design/gdd/crowd-collision-resolution.md | Network Layer, ADR-0001 |
| 16 | Chest System (T1/T2) | Gameplay | MVP | Batch 4 Applied 2026-04-24 (Active-strict guard + modal-close-on-elim hook + minimap deferred; pending DSN-B-2 T1 toll design decision Batch 5) | design/gdd/chest-system.md | Crowd State Manager, Relic System, Round Lifecycle, Match State Machine, Network Layer, Level Design, AssetId Registry, ADR-0001 |
| 17 | Relic System | Gameplay | MVP | CSM Batch 1 Sync 2026-04-24 (pending FLAG-1 Wingspan design decision) | design/gdd/relic-system.md | PlayerData, Match State Machine, Crowd State Manager, TickOrchestrator, ADR-0001 |
| 18 | Round Lifecycle | Core | MVP | Consistency-sync 2026-04-24 (CountChanged flags cleared; CSM Batch 1 landed) — pending FLAG-3 placement design decision Batch 5 | design/gdd/round-lifecycle.md | Match State Machine, Crowd State Manager |
| 19 | Crowd Replication Strategy | Core | MVP | Designed (pending review) | design/gdd/crowd-replication-strategy.md | ADR-0001, Network Layer, Crowd State Manager, Round Lifecycle, Match State Machine |
| 20 | HUD | UI | MVP | Consistency-sync 2026-04-24 (7 CSM/Chest amendment flags cleared) | design/gdd/hud.md | UIHandler, Crowd State Manager, Match State Machine, Round Lifecycle, Relic System, AssetId Registry, Art Bible §7 |
| 21 | Player Nameplate | UI | MVP | Consistency-sync 2026-04-24 (CrowdCreated flags cleared) | design/gdd/player-nameplate.md | UIHandler, Crowd State Manager, Match State Machine, Character/CharacterSpawner, Art Bible §7 |
| 22 | Chest Billboard (inferred) | UI | MVP | Not Started | — | UIHandler, Chest System |
| 23 | VFX Manager (inferred) | Presentation | MVP | Consistency-sync 2026-04-24 (soft amendment flag annotated) | design/gdd/vfx-manager.md | AssetId Registry, CrowdStateClient, Network Layer, Absorb, Follower Entity, Crowd Collision Resolution, Chest, Relic, Match State Machine |
| 24 | Skin System | Progression | Vertical Slice | Not Started | — | PlayerData, Follower Entity, AssetId Registry |
| 25 | Relic Card / Reveal UI (inferred) | UI | Vertical Slice | Not Started | — | UIHandler, Relic System |
| 26 | Round Result Screen (inferred) | UI | Vertical Slice | Not Started | — | UIHandler, Round Lifecycle |
| 27 | Lobby / Main Menu UI (inferred) | UI | Vertical Slice | Not Started | — | UIHandler, Match State Machine |
| 28 | Audio Manager (inferred) | Audio | Vertical Slice | Not Started | — | AssetId Registry |
| 29 | FTUE / Tutorial | Meta | Vertical Slice | Not Started (template skeleton exists) | — | PlayerData, UIHandler, Absorb, Chest |
| 30 | T3 Building (Chest System extension) | Gameplay | Alpha | Not Started | — | Chest System |
| 31 | Shop System | Economy | Alpha | Not Started | — | PlayerData, Currency, Skin System |
| 32 | Shop UI (inferred) | UI | Alpha | Not Started | — | UIHandler, Shop System |
| 33 | Daily Quest System | Progression | Alpha | Not Started | — | PlayerData, Absorb, Chest, Crowd Collision |
| 34 | Daily Quest Panel UI (inferred) | UI | Alpha | Not Started | — | UIHandler, Daily Quest System |
| 35 | Leaderboard System | Progression | Alpha | Not Started | — | PlayerData, Round Lifecycle, Network Layer |
| 36 | Analytics | Meta | Alpha | Not Started (template stubs exist) | — | All gameplay systems (event sources) |
| 37 | Battlepass / Seasonal Events | Progression | Full Vision | Not Started | — | Shop System, Daily Quest, Leaderboard |
| 38 | Friend Party / Invite | Meta | Full Vision | Not Started | — | Match State Machine, Network Layer |
| 39 | Additional Relics (15 → 25-30) | Gameplay | Full Vision | Not Started | — | Relic System |
| 40 | Additional Skins (5 → 15) | Progression | Full Vision | Not Started | — | Skin System |
| 41 | Additional City (3rd theme) | Gameplay | Full Vision | Not Started | — | NPC Spawner, Chest System |

---

## Categories

| Category | Description | Count |
|----------|-------------|-------|
| Core | Foundation and framework systems | 8 |
| Gameplay | Systems driving the 5-min round | 10 |
| Progression | Meta growth (cosmetics, quests, leaderboards) | 5 |
| Economy | Currency + shop | 2 |
| Persistence | Save state (template-provided) | 1 |
| UI | Player-facing information | 9 |
| Audio | Sound + music | 1 |
| Meta | Analytics, tutorial, party | 4 |
| Presentation | VFX feedback | 1 |

Narrative category omitted — Crowdsmith has no story (concept pillar decision).

---

## Priority Tiers

| Tier | Definition | Target Milestone | Count |
|------|------------|------------------|-------|
| **MVP** | Core loop functional; answers "is absorb + chest + relic fun?" | 6-8 weeks | 23 (incl. 7 template-provided) |
| **Vertical Slice** | One polished round experience, with meta identity (skins) | 10-12 weeks | 6 |
| **Alpha** | All features rough, multi-city, meta loop working | 3-4 months | 7 |
| **Full Vision** | Content-complete, live-ops ready | 5-6 months | 5 |

---

## Dependency Map

### Foundation Layer (no cross-project dependencies)

1. **Network Layer** (template-provided) — remote event wrapper; all cross-boundary traffic flows through this
2. **PlayerData / ProfileStore** (template-provided) — session-locked save state
3. **UIHandler** (template-provided) — UI layer + HUD management
4. **Currency — Coins** (template-provided) — depends on PlayerData
5. **Zone Handler** (template-provided) — CollectionService tag-based area triggers
6. **ComponentCreator** (template-provided) — CollectionService → component class attachment
7. **Collision Groups** (template-provided) — physics group management
8. **AssetId Registry** — string constants mapping logical names to `rbxassetid://`; unblocks all mesh/texture refs

### Core Layer (depends on Foundation)

1. **Crowd State Manager** — per-player follower roster + count; PlayerData for persistent stats; Network Layer for replication
2. **Match State Machine** — lobby / round / result state; Network Layer for broadcast
3. **Round Lifecycle** — depends on Match State Machine + Crowd State Manager; owns timer + win/elim conditions
4. **Crowd Replication Strategy** — depends on Network Layer + Follower Entity; defines client-side flocking vs. server-authoritative count split

### Feature Layer — Gameplay (depends on Core)

1. **NPC Spawner** — depends on AssetId Registry; produces neutral targets
2. **Follower Entity** — depends on AssetId Registry + Crowd State Manager; custom 4-6-part CFrame rig, NO Humanoid
3. **Follower LOD Manager** — depends on Follower Entity; client-side distance-tier swap every 0.1s
4. **Absorb System** — depends on Follower Entity + NPC Spawner + Crowd State Manager; magnetic-snap recruitment
5. **Crowd Collision Resolution** — depends on Crowd State Manager + Follower Entity; larger consumes smaller
6. **Chest System** — depends on Crowd State Manager + Relic System; T1/T2 in MVP, T3 in Alpha
7. **Relic System** — depends on PlayerData (temporary round state) + Match State Machine; registry + application
8. **Skin System** — depends on PlayerData + Follower Entity + AssetId Registry; body color + hat swap
9. **Shop System** — depends on Currency + Skin System
10. **Daily Quest System** — depends on PlayerData + gameplay event hooks (Absorb, Chest, Collision)
11. **Leaderboard System** — depends on PlayerData + Round Lifecycle + Network Layer

### Presentation Layer (depends on Feature)

1. **HUD** — depends on UIHandler + Crowd State Manager + Round Lifecycle + Relic System
2. **Player Nameplate** — depends on UIHandler + Crowd State Manager
3. **Chest Billboard** — depends on UIHandler + Chest System
4. **Relic Card / Reveal UI** — depends on UIHandler + Relic System
5. **Round Result Screen** — depends on UIHandler + Round Lifecycle
6. **Lobby / Main Menu UI** — depends on UIHandler + Match State Machine
7. **Shop UI** — depends on UIHandler + Shop System
8. **Daily Quest Panel UI** — depends on UIHandler + Daily Quest System
9. **VFX Manager** — depends on AssetId Registry; wrapper over ParticleEmitter / Beam / Trail
10. **Audio Manager** — depends on AssetId Registry; SFX bus + ambient + stingers

### Polish Layer (depends on everything)

1. **FTUE / Tutorial** — depends on PlayerData + UIHandler + Absorb + Chest; template state machine customized for Crowdsmith stages
2. **Analytics** — depends on all gameplay systems (as event sources); template stubs populated w/ Crowdsmith events
3. **Battlepass / Seasonal Events** — depends on Shop + Daily Quest + Leaderboard
4. **Friend Party / Invite** — depends on Match State Machine + Network Layer

---

## Recommended Design Order

Design order combines dependency sort + priority tier. Prototype-first for high-risk systems.

### Prototype Phase (before MVP lock-in)

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| P1 | Crowd Replication Strategy (prototype) | MVP | Core | technical-director, gameplay-programmer | L — prototype story |
| P2 | Follower Entity (prototype) | MVP | Feature | gameplay-programmer | L — prototype story |

### MVP Design Order (GDDs after prototype validates tech)

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | AssetId Registry | MVP | Foundation | gameplay-programmer, technical-artist | S |
| 2 | Crowd State Manager | MVP | Core | game-designer, gameplay-programmer | M |
| 3 | Follower Entity (GDD) | MVP | Feature | game-designer, gameplay-programmer, technical-artist | L |
| 4 | NPC Spawner | MVP | Feature | game-designer, gameplay-programmer | M |
| 5 | Match State Machine | MVP | Core | game-designer, gameplay-programmer | M |
| 6 | Round Lifecycle | MVP | Core | game-designer | M |
| 7 | Absorb System | MVP | Feature | game-designer, systems-designer | M |
| 8 | Crowd Collision Resolution | MVP | Feature | game-designer, systems-designer | M |
| 9 | Relic System | MVP | Feature | game-designer, systems-designer, economy-designer | L |
| 10 | Chest System | MVP | Feature | game-designer, systems-designer | M |
| 11 | Follower LOD Manager | MVP | Feature | technical-artist, gameplay-programmer | M |
| 12 | Crowd Replication Strategy (GDD — formalize prototype findings) | MVP | Core | network-programmer, technical-director | M |
| 13 | VFX Manager | MVP | Presentation | technical-artist, sound-designer | S |
| 14 | HUD | MVP | UI | ux-designer, ui-programmer | M |
| 15 | Player Nameplate | MVP | UI | ux-designer, ui-programmer | S |
| 16 | Chest Billboard | MVP | UI | ux-designer, ui-programmer | S |

### Vertical Slice Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 17 | Skin System | VS | Feature | game-designer, technical-artist, economy-designer | M |
| 18 | Relic Card / Reveal UI | VS | UI | ux-designer, ui-programmer | S |
| 19 | Round Result Screen | VS | UI | ux-designer, ui-programmer | S |
| 20 | Lobby / Main Menu UI | VS | UI | ux-designer, ui-programmer | M |
| 21 | Audio Manager | VS | Audio | audio-director, sound-designer | M |
| 22 | FTUE / Tutorial | VS | Meta | game-designer, ux-designer | M |

### Alpha + Full Vision (sketched, detailed design later)

23. T3 Building (Chest System extension) — M
24. Shop System — M
25. Shop UI — S
26. Daily Quest System — L
27. Daily Quest Panel UI — S
28. Leaderboard System — M
29. Analytics — M
30. Additional Relics / Skins / City — content authoring, not system design
31. Battlepass + Friend Party — V1.5 only

Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions.

---

## Circular Dependencies

- **None identified** at first-pass mapping.
- Watch list: Follower Entity ↔ Crowd Replication Strategy — entity lifecycle and replication protocol must be co-designed. Resolved by: the Crowd Replication Strategy GDD defines the server/client contract for follower spawn/despawn/update; the Follower Entity GDD consumes that contract. Design these in order (P1 Crowd Replication prototype → P2 Follower Entity prototype → both GDDs written sequentially after prototype informs both).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| **Crowd Replication Strategy** | Technical (BLOCKING) | 100-300 followers × 8-12 players exceeds naive Roblox RemoteEvent bandwidth. If client-side flocking fails to hide desync, gameplay breaks. | Prototype FIRST (`/prototype crowd-sync`). Test buffer-based crowd-count/center replication + client flocking simulation. Validate bandwidth + perception at 800 on-screen characters. |
| **Follower Entity** | Technical | Non-Humanoid CFrame rig at 800+ instances: per-frame batch cost unproven. Also blocks Follower LOD Manager. | Prototype alongside Crowd Replication. Measure CFrame-update cost on minimum-spec mobile (iPhone SE target) via MicroProfiler. |
| **Follower LOD Manager** | Technical | Manual LOD — Roblox provides no built-in fallback. LOD swap timing mistakes = popping artifacts ruining the cel-shaded aesthetic. | 2nd priority prototype. Validate swap distances (20m / 40m / 100m from art bible §5) feel correct at arena camera. |
| **Chest + Relic Balance** | Design | Toll cost vs. relic value = core fun-or-fail. Pillar 2 (Risky Chests) requires the decision to feel hard. | Playtest iteration in Vertical Slice. `/playtest-report` cycles. Economy-designer involvement in Relic System GDD. |
| **Absorb Feel** | Design | Pillar 1 depends on magnetic-snap dopamine landing. Needs VFX + Audio + Physics timing coordination. | VFX + Audio + Follower Entity tight co-design. First playtest target: new player grins within 30 seconds of absorbing their 20th NPC. |
| **Crowd Skin Broadcast** | Design | If 12 player hues don't stay distinguishable under deuteranopia at arena distance, Pillar 4 fails. | Safe palette pre-validated in art bible §4. Test in actual 12-player server early. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 42 (incl. 7 template-provided + 5 Full-Vision content + TickOrchestrator spin-off) |
| Design docs started | 14 |
| Design docs reviewed | 1 (Follower LOD Manager) |
| Design docs approved | 8 (7 template-provided + Follower LOD Manager) |
| MVP systems designed | 14 / 16 new MVP — ALL MVP GDDs AUTHORED (CSM, MSM, Round Lifecycle, Follower Entity, Follower LOD Manager, Absorb, NPC Spawner, Crowd Collision Resolution, Relic, Chest, HUD, Player Nameplate, VFX Manager, Crowd Replication Strategy — LOD Manager approved; others pending review). AssetId Registry + Chest Billboard remain (Chest Billboard is UI-only MVP system still Not Started) |
| Vertical Slice systems designed | 0 / 6 |

---

## Next Steps

- [ ] Prototype Crowd Replication Strategy before writing GDDs (`/prototype crowd-sync`)
- [ ] After prototype, author GDDs in the MVP design order above (`/design-system [first-system]`)
- [ ] Use `/map-systems next` to auto-select the highest-priority undesigned system
- [ ] Run `/design-review design/gdd/[system].md` after each GDD
- [ ] Run `/review-all-gdds` when all MVP GDDs are written (cross-consistency check)
- [ ] Run `/gate-check pre-production` when MVP systems are designed and prototype-validated
