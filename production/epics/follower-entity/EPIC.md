# Epic: FollowerEntity (Follower Entity — client simulation)

> **Layer**: Feature
> **GDD**: design/gdd/follower-entity.md
> **Architecture Module**: FollowerEntity (client) — `ReplicatedStorage/Source/FollowerEntity/Client.luau` (architecture.md §2.3 row 3)
> **Status**: **Ready** (ADR-0007 Accepted 2026-05-04 — all 12 stories writable)
> **Stories**: 12 stories created 2026-05-04 — see Stories table below

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Pool bootstrap + 2-Part rig assembly | Integration | Complete (2026-05-04) | ADR-0007 |
| 002 | CrowdManagerClient orchestrator + per-crowd lifecycle | Integration | Ready | ADR-0007 |
| 003 | Boids F1-F4 flocking (separation + cohesion + leader + zero-vector guards) | Logic | Ready | ADR-0007 |
| 004 | Walk bob F8 + standstill freeze + micro-sway F9 | Logic | Ready | ADR-0007 |
| 005 | Spawn states (FadeIn / SlideIn) + 4/frame throttle + d_init random | Logic | Ready | ADR-0007 |
| 006 | Hue Color3 write + dirty flag + reconciliation timer | Logic | Ready | ADR-0007 |
| 007 | Peel selection F6 (closest-to-rival) + concurrent dual-rival peel | Logic | Ready | ADR-0007 |
| 008 | Peel transit F7 + hue-flip latch + rival-nil abort | Logic | Ready | ADR-0007 |
| 009 | setPoolSize + Peeling immunity + getPeelingCount accessor | Logic | Ready | ADR-0007 |
| 010 | LOD tier swap F5 + d preservation + teleport snap | Logic | Ready | ADR-0007 + ADR-0001 |
| 011 | Perf soak validation — 80 LOD-0 followers ≤ 2.5 ms p99 | Integration | Ready | ADR-0003 + ADR-0007 |
| 012 | Pool hide/unhide LOD swap — no Instance.new on swap | Integration | Ready | ADR-0007 |

**Implementation order**: 001 → 002 → 003/004/006 (parallel after 002) → 005 → 007 → 008 → 009 → 010 → 011 → 012. Each story's `Depends on:` field lists the gating predecessors.

## Overview

This epic delivers the client-side visual representation of every follower in every crowd on the server — the thousands of chunky, cheerful civilians that make the snowball visible. Each entity is a tiny CFrame-driven rig (2-Part Body+Hat per FE GDD §C.1; ADR-0001 originally specified 4-6 parts — **C1 conflict pending resolution in ADR-0007**), no Humanoid, flocked via boids behavior toward its crowd's authoritative position. It has no server-side existence beyond its crowd's aggregate count; it exists only as pixels, only on the client, only while on-screen. ADR-0001 decoupled authoritative gameplay count from rendered part count — a 300-follower crowd on server may render as 80 entities on the closest client and a single billboard impostor on a distant one, preserving the mob feel without rendering cost. Three LOD tiers span close (0-20m, 400-tri full rig), medium (20-40m, 100-tri simplified primitive), and far (40-100m, one billboard impostor per crowd — tier 2 cap owned by Follower LOD Manager §F3); beyond 100m, entities cull. Owns its own procedural walk animation, hue tint, hat accessory, snap-in-on-absorb and pop-out-on-loss visual moments. Without this system, CrowdStateServer is a number on a scoreboard; with it, CrowdStateServer is an army.

## ⚠️ ADR-0007 — Proposed 2026-05-02; Pending /architecture-review

ADR-0007 Client Rendering Strategy was authored 2026-05-02 (`docs/architecture/adr-0007-client-rendering-strategy.md`). **Status: Proposed**. Stories that touch ADR-0007 territory remain **Blocked** until ADR-0007 is **Accepted** via `/architecture-review` in a fresh session.

**ADR-0007 must cover**:
- Client-side rig structure (Part count, anchored CFrame authority) — resolves C1 conflict
- Boids flocking algorithm + neighborhood query budget
- LOD tier transitions + hysteresis rules
- Procedural walk-bob/hue-tint/hat-accessory rendering contracts
- Eviction priority during cap shrink (mid-peel protection)
- Per-frame budget @ RenderStepped on min-spec mobile

**Story-implementable today** (3 TRs without A7 dependency):
- TR-fe-001 — No Humanoid; Parts anchored for CFrame authority (✅ ADR-0001)
- TR-fe-015 — LOD render caps 80/30/15/1 (✅ ADR-0001 + ADR-0003)
- TR-fe-020 — Pillar 4 anti-P2W (no skin-derived stats) (✅ ADR-0004 + ADR-0001)

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Client Rendering Strategy | **Proposed 2026-05-02** — covers boids/RenderStepped discipline, LOD authority split (FollowerEntity execution vs FollowerLODManager decisions), pool ownership, eviction protection, billboard impostor, anti-physics-movement bans. Pending Accept via `/architecture-review`. | MEDIUM (post-Accept) |
| ADR-0001: Crowd Replication Strategy | No Humanoid, server-authoritative count, LOD tier definition, render caps | HIGH (post-cutoff) |
| ADR-0004: CSM Authority | Pillar 4 anti-P2W: cosmetic systems forbidden as CSM write-callers | LOW |
| ADR-0003: Performance Budget | Instance cap (80/30/15 + 1 impostor); RenderStepped mobile budget | MEDIUM |
| ADR-0006: Module Placement Rules | Client module under `ReplicatedStorage/Source/FollowerEntity/Client.luau` | LOW |

## GDD Requirements

20 TRs from `tr-registry.yaml`. Coverage:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-follower-entity-001 | Core — No Humanoid; CFrame authority | ✅ ADR-0001 |
| TR-follower-entity-002 | Core — Part count (2-Part vs 4-6-Part) | ⚠️ **C1 conflict** ADR-0001 vs GDD; A7 needed |
| TR-follower-entity-003 | Performance — RenderStepped budget | ❌ ADR-0007 needed |
| TR-follower-entity-004 | Performance — Reserve | ⚠️ ADR-0003 §Reserve (implicit) |
| TR-follower-entity-005 | State — F8 walk-bob animation | ❌ design-internal F8 |
| TR-follower-entity-006 | State — boids flocking | ❌ ADR-0007 needed |
| TR-follower-entity-007 | State — hue tint | ❌ design-internal |
| TR-follower-entity-008 | Authority — eviction protection (mid-peel) | ❌ ADR-0007 needed |
| TR-follower-entity-009 | Core — pool granting | ❌ ADR-0007 needed |
| TR-follower-entity-010 | State — hat accessory | ❌ design-internal |
| TR-follower-entity-011..014 | State/Networking/Performance — LOD swap, snap-in, pop-out, peel transit | ❌ ADR-0007 needed |
| TR-follower-entity-015 | Render — 80/30/15/1 LOD caps | ✅ ADR-0001 + ADR-0003 |
| TR-follower-entity-016 | State — pool-size sync to LOD Manager | ❌ ADR-0007 needed |
| TR-follower-entity-017 | State — render fallback | ❌ design-internal |
| TR-follower-entity-018 | State — pool eviction priority | ❌ ADR-0007 needed |
| TR-follower-entity-019 | State — billboard impostor render | ❌ ADR-0007 needed |
| TR-follower-entity-020 | Authority — Pillar 4 anti-P2W (no skin-stat coupling) | ✅ ADR-0004 + ADR-0001 |

## Definition of Done

This epic is complete when:
- ADR-0007 (Client Rendering Strategy) is Accepted, closing C1 conflict + 15 ADR-gap TRs
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/follower-entity.md` are verified
- All Visual/Feel stories (snap-in, pop-out, peel hue-flip, walk-bob) have evidence docs with sign-off in `production/qa/evidence/`
- Per-frame RenderStepped budget verified on min-spec mobile (deferred to MVP-Integration-1 per ADR-0003 §Validation Sprint Plan)
- Integration with FollowerLODManager (Presentation epic, deferred) verified end-to-end

## Next Step

**Recommended sequence**:
1. Run `/architecture-decision` for ADR-0007 Client Rendering Strategy (closes C1 conflict + 15 TR gap)
2. After ADR-0007 Accepted: run `/create-stories follower-entity`
3. Stories touching ADR-0007 territory will be Ready; pre-A7 stories (3 TRs only) can begin in parallel if velocity demands
