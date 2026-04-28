# Epic: RoundLifecycle

> **Layer**: Core
> **GDD**: design/gdd/round-lifecycle.md
> **Architecture Module**: RoundLifecycle (architecture.md §3.2 row 4; API §5.3)
> **Status**: Ready (5 stories drafted 2026-04-28)
> **Stories**: 5 Ready

## Stories

| # | Story | Type | Status | Primary ADR |
|---|-------|------|--------|-------------|
| 001 | [Module skeleton + Janitor + createAll + destroyAll](story-001-module-skeleton-janitor-createall-destroyall.md) | Logic | Ready | ADR-0005 + ADR-0006 |
| 002 | [CountChanged subscription + peak tracking F1 + signal guard](story-002-countchanged-peak-tracking-f1.md) | Logic | Ready | ADR-0005 + ADR-0004 |
| 003 | [Eliminated subscription + eliminationTime idempotent + DC freeze](story-003-eliminated-subscription-dc-freeze.md) | Logic | Ready | ADR-0005 |
| 004 | [setWinner + getPeakTimestamp + invalid guards](story-004-setwinner-getpeaktimestamp.md) | Logic | Ready | ADR-0005 |
| 005 | [getPlacements F3 5-key sort + InternalPlacement strip + idempotence + perf](story-005-getplacements-f3-sort-strip-perf.md) | Logic | Ready | ADR-0005 |

Order: 001 → 002 + 003 + 004 (parallelizable post-001) → 005.

## Overview

This epic delivers the round-scoped coordinator that owns per-crowd auxiliary fields not on the CSM record (peakCount, peakTimestamp, finalCount, eliminationTime), the `_participants` snapshot, the `_winnerId`, and the Janitor lifecycle for all round-scoped subscriptions. RoundLifecycle is invoked exclusively by MatchStateServer at the round-boundary transitions (T4 createAll → Active, T8 setWinner → Result, T9 destroyAll → Intermission). It produces the broadcast-shape `Placements` table for the result fanout, computes peak-dominance placement, and is responsible for stripping internal fields from the `InternalPlacement` records before they cross the wire.

This epic does NOT include the result-screen UI (Presentation layer) or Currency.grantMatchRewards (Foundation). Round-scoped state is ephemeral by Pillar 3 — nothing in this module ever touches `DataStoreService` or persistence. Janitor is the lifecycle primitive (Wally `Packages.janitor`).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: MSM/RoundLifecycle Split + Authority Matrix | RoundLifecycle is sub-coordinator of MSM; participation snapshot timing, peakTimestamp owner, peak-dominance placement (F3), broadcast-shape stripping, MAX_PARTICIPANTS_PER_ROUND=12 cap | LOW |
| ADR-0004: CSM Authority | RoundLifecycle subscribes `CountChanged` BindableEvent (read-only); calls `CSM.create / destroy` at round boundary | LOW |
| ADR-0003: Performance Budget | Memory + CPU budgets for the per-crowd aux table (≤12 records, sort O(N log N)) | LOW |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/RoundLifecycle/init.luau`; uses Wally `Packages.janitor` per template policy | LOW |

## GDD Requirements

16 TRs from `tr-registry.yaml`. Coverage post-ADR-0005 acceptance:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-round-lifecycle-001 | State — round-scoped aux fields | ✅ ADR-0005 |
| TR-round-lifecycle-002 | Authority — RoundLifecycle owns peakTimestamp | ✅ ADR-0005 |
| TR-round-lifecycle-003 | Authority — sole `setWinner` caller (MSM) | ✅ ADR-0005 |
| TR-round-lifecycle-004 | Authority — `getPlacements` 5-field broadcast shape | ✅ ADR-0005 |
| TR-round-lifecycle-005 | Authority — `getPeakTimestamp` MSM F4 tiebreak | ✅ ADR-0005 |
| TR-round-lifecycle-006 | Authority — Phase 7 elim consumer interaction | ✅ ADR-0002 + ADR-0005 |
| TR-round-lifecycle-007 | Authority — `createAll` no-prior-Janitor assertion | ✅ ADR-0005 |
| TR-round-lifecycle-008 | State/Persistence — Janitor scope; ephemeral | ✅ ADR-0006 + ADR-0005 |
| TR-round-lifecycle-009 | Authority — `_winnerId` set before `getPlacements` | ✅ ADR-0005 |
| TR-round-lifecycle-010 | Authority — memory budget (≤12 aux records) | ✅ ADR-0003 + arch §5.3 |
| TR-round-lifecycle-011 | Networking — `CountChanged` subscribe | ✅ ADR-0004 §Write-Access Matrix |
| TR-round-lifecycle-012 | State — `Players.PlayerRemoving` lifecycle | ✅ ADR-0005 |
| TR-round-lifecycle-013 | Networking — InternalPlacement stripping pre-broadcast | ✅ ADR-0005 |
| TR-round-lifecycle-014 | Authority — `destroyAll` Janitor disconnect | ✅ ADR-0005 |
| TR-round-lifecycle-015 | Authority — stray-signal no-op post-destroy | ✅ ADR-0005 |
| TR-round-lifecycle-016 | Performance — sort + reduce O(N log N) on ≤12 | ⚠️ ADR-0003 §Reserve (not explicitly allocated; covered by per-tick reserve) |

**Coverage after ADR-0005 Accepted**: 15 / 16 ✅, 1 ⚠️ (TR-round-lifecycle-016 — performance reserve, not blocking).

⚠️ **Untraced**: None blocking.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, and closed via `/story-done`
- `RoundLifecycle/init.luau` exposes the 5-method API per architecture.md §5.3: `createAll(participatingPlayers) / setWinner(crowdId?) / getPlacements() / getPeakTimestamp(crowdId) / destroyAll()`
- All 16 acceptance criteria from `design/gdd/round-lifecycle.md` are verified
- MatchStateServer is the sole caller of all 5 public methods (architecture invariant — code-review enforced)
- `createAll` asserts `_janitor == nil` before allocating new Janitor (double-call = code bug)
- Per-crowd aux table (`peakCount / peakTimestamp / finalCount / eliminationTime`) updated by `CountChanged` BindableEvent subscription
- `setWinner` must be called before `getPlacements` when participants non-empty (assertion)
- `getPlacements` returns 5-field broadcast shape per arch §5.3 (`crowdId / userId / placement / crowdCount / eliminationTime`); InternalPlacement fields (`peakCount / isWinner / wasEliminated`) stripped by adapter
- `getPeakTimestamp` returns nil → MSM F4 treats as `math.huge` for tiebreak
- `MAX_PARTICIPANTS_PER_ROUND = 12` enforced at `createAll`
- `destroyAll` disconnects every subscription via `_janitor:Cleanup()`; subsequent `CountChanged` or `Players.PlayerRemoving` signals no-op
- `Players.PlayerRemoving` mid-round triggers `setWasEliminated` for that player's crowd (ADR-0005 path)
- Logic stories pass automated TestEZ tests in `tests/unit/round-lifecycle/` (peak-dominance F3 determinism, broadcast-shape stripping, Janitor lifecycle assertions, double-call guard, F4 tiebreak via getPeakTimestamp)
- Audit gates green: `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` exit 0
- Pillar 3 exclusion verified: zero references to `DataStoreService` or `PlayerDataServer` in this module

## Next Step

Run `/create-stories round-lifecycle` to break this epic into implementable stories.
