# Epic: CollisionResolver (Crowd Collision Resolution)

> **Layer**: Feature
> **GDD**: design/gdd/crowd-collision-resolution.md
> **Architecture Module**: CollisionResolver (architecture.md §2.3 row 5)
> **Status**: Ready
> **Stories**: 11 stories drafted 2026-05-06 (lean mode; QL-STORY-READY skipped)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Phase 1 callback skeleton + Dormant/Ticking states | Logic | Ready | ADR-0002 + ADR-0006 |
| 002 | F1 pair overlap + F2 pair_key + O(p²) iteration | Logic | Ready | ADR-0010 |
| 003 | F3 drip rate + per-pair updateCount + equal-count drain | Logic | Ready | ADR-0004 |
| 004 | Skip conditions — nil/Eliminated + GraceWindow | Logic | Ready | ADR-0002 + ADR-0004 |
| 005 | Overlap-bit feed — setStillOverlapping post-drip | Logic | Ready | ADR-0004 |
| 006 | PairEntered first-contact event + diff against prev tick | Logic | Ready | ADR-0001 + ADR-0010 |
| 007 | Equal-count two-way peel emission | Logic | Ready | ADR-0001 |
| 008 | PeelDispatcher — F4 relevance filter + batched FireClient | Logic | Ready | ADR-0001 + ADR-0002 + ADR-0010 |
| 009 | Client peel observation — FollowerEntityClient.startPeel | Integration | Ready | ADR-0001 + ADR-0007 |
| 010 | Write-access contract integration + lag-spike 2-tick | Integration | Ready | ADR-0002 + ADR-0004 |
| 011 | Perf soak — p99 ≤0.15ms + peel bandwidth ≤6.6 KB/s pileup | Integration | Ready | ADR-0003 |

## Overview

This epic delivers the server-authoritative module that runs the 15 Hz hit-detection tick at the heart of Crowdsmith's combat. Every 66 ms (Phase 1 — first per tick, before Absorb), for every pair of active crowds in the match (O(p²) ≤ 66 pairs at 12-crowd cap), it performs one 2D squared-distance overlap test against authoritative positions and `radius_from_count`-derived radii, builds the set of overlapping pairs, and applies the **drip model** locked by Crowd State §C.3 — one `updateCount(±n, "Collision")` call per side using F3 `TRANSFER_RATE_effective`. The larger-count crowd gains, the smaller loses; equal-count clashes mutually drain at base rate; triple-overlap stacks additively per F4. When a crowd's count reaches floor of 1 with overlap still active, this system feeds the state signal driving CSM `Active → GraceWindow` (CSM owns the transition); when the 3-second F7 grace expires with overlap persisting, CSM fires `CrowdEliminated`. A companion client-side path observes broadcast count deltas and dispatches `FollowerEntity.startPeel(ownId, rivalId, n)` so players see followers peel off and cross over with a 50%-transit hue flip. This module is also the tick-loop owner — Absorb piggybacks on the same pass; future per-tick gameplay subscribes here rather than running a second loop.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: TickOrchestrator | Phase 1 collision tick (first per tick); state-skip rule (Eliminated crowds excluded) | LOW |
| ADR-0004: CSM Authority | `updateCount(±n, "Collision")` write; `setStillOverlapping` per CSM Phase 5 input contract | LOW |
| ADR-0001: Crowd Replication Strategy | Peel buffer payload schema (client-side visual contract) | HIGH (UREvent post-cutoff) |
| ADR-0003: Performance Budget | Phase 1 budget ≤0.6 ms/tick @ 66 pair-checks (12 crowds, O(p²)) | MEDIUM |
| ADR-0010: Server-Authoritative Validation | Peel emission relevance filter; PairEntered reliable contract | LOW |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/CollisionResolver/init.luau` | LOW |

## GDD Requirements

20 TRs from `tr-registry.yaml`. Coverage post-A10 acceptance:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-ccr-001 | Networking — Phase 1 cadence | ✅ ADR-0002 |
| TR-ccr-002 | Performance — Phase 1 budget | ⚠️ ADR-0003 §Phase 1 budget |
| TR-ccr-003 | Core — F1 overlap formula | ❌ design-internal F1 |
| TR-ccr-004 | Authority — `updateCount("Collision")` permitted | ✅ ADR-0004 |
| TR-ccr-005 | Authority — equal-count mutual-drain rule | ⚠️ ADR-0002 §simultaneity |
| TR-ccr-006 | Authority — F3 transfer rate | ❌ F3 design-internal |
| TR-ccr-007 | Authority — Eliminated crowds skip | ⚠️ ADR-0002 §Phase 1 state-skip |
| TR-ccr-008 | Authority — `setStillOverlapping` write | ✅ ADR-0004 |
| TR-ccr-009 | Networking — PairEntered reliable contract | ✅ ADR-0010 |
| TR-ccr-010 | Networking — peel emission schema | ❌ design-internal |
| TR-ccr-011 | Performance — Phase 9 cleanup | ✅ ADR-0002 |
| TR-ccr-012 | Networking — peel relevance filter | ✅ ADR-0010 |
| TR-ccr-013 | Networking — server-side peel validation | ✅ ADR-0010 |
| TR-ccr-014 | Networking — peel UREvent channel | ⚠️ ADR-0001 (peel not specifically named) |
| TR-ccr-015 | Authority — phase ordering (collision before absorb) | ✅ ADR-0002 |
| TR-ccr-016 | Authority — Write-Access Matrix | ✅ ADR-0004 |
| TR-ccr-017 | State — F2 triple-overlap stacking | ❌ F2 design-internal |
| TR-ccr-018 | Authority — same-tick simultaneity | ✅ ADR-0002 |
| TR-ccr-019 | Authority — write-access | ✅ ADR-0004 |
| TR-ccr-020 | Performance — pair-check budget | ✅ ADR-0003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/crowd-collision-resolution.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- Phase 1 budget verified ≤0.6 ms/tick @ 66 pair-checks (synthetic; real-soak deferred to MVP-Integration-1)
- End-to-end integration with CSM `setStillOverlapping` + GraceWindow + Eliminated path verified

## Next Step

Run `/create-stories crowd-collision-resolution` to break this epic into implementable stories.
