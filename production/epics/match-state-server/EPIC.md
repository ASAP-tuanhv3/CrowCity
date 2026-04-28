# Epic: MatchStateServer (Match State Machine)

> **Layer**: Core
> **GDD**: design/gdd/match-state-machine.md
> **Architecture Module**: MatchStateServer (architecture.md §3.2 row 3; API §5.2)
> **Status**: Ready (8 stories drafted 2026-04-28)
> **Stories**: 8 Ready

## Stories

| # | Story | Type | Status | Primary ADR |
|---|-------|------|--------|-------------|
| 001 | [Module skeleton + 7-state enum + Lobby boot + participation flags + Snap freeze](story-001-module-skeleton-state-enum-participation-flags.md) | Logic | Ready | ADR-0005 |
| 002 | [Lobby → Ready → Snap → Active transition driver + countdown timer](story-002-lobby-countdown-active-transition-driver.md) | Logic | Ready | ADR-0005 |
| 003 | [Phase 6 timerCheck + T7 timer-expiry → Result + F4 tiebreak](story-003-phase6-timercheck-t7-f4-tiebreak.md) | Logic | Ready | ADR-0002 + ADR-0005 |
| 004 | [Phase 7 elimConsumer + T6 last-standing + double-signal guard + T8 instant win](story-004-phase7-elim-consumer-t6-t8-double-signal-guard.md) | Logic | Ready | ADR-0002 + ADR-0005 |
| 005 | [Result → Intermission T9 + grant-before-broadcast + flag reset T10](story-005-result-intermission-t9-grant-before-broadcast.md) | Integration | Ready | ADR-0005 + ADR-0011 |
| 006 | [T11 BindToClose + ServerClosing + no-grant during shutdown](story-006-t11-bindtoclose-serverclosing-no-grant.md) | Integration | Ready | ADR-0005 + ADR-0011 |
| 007 | [MatchStateChanged + ParticipationChanged broadcast + GetParticipation + AFK toggle](story-007-broadcast-participation-getparticipation-afk.md) | Integration | Ready | ADR-0005 + ADR-0010 |
| 008 | [Performance budget evidence — Phase 6 + Phase 7 < 0.1ms over 100 ticks](story-008-perf-budget-evidence.md) | Logic | Ready | ADR-0003 |

Order: 001 → 002 → 003 + 004 (parallelizable) → 005 → 006 + 007 (parallelizable) → 008 (assembled-module validation).

## Overview

This epic delivers the server-side match state machine: the 7-state enum (`Lobby / Countdown:Ready / Countdown:Snap / Active / Result / Intermission / ServerClosing`), per-state timer, T11 `BindToClose` shutdown path, and the participationFlag table with `GetParticipation` RemoteFunction reconcile. MSM is the sole owner of `transitionTo` (internal-only — driven by `PlayerAdded/Removing`, AFK toggle, `CrowdEliminated` from CSM, and `game:BindToClose`); external consumers (HUD, FTUE, spectator camera, Currency) are read-only.

MSM owns Phase 6 (timerCheck — T7 elapse-driven Active → Result) and Phase 7 (eliminationConsumer — T6 last-crowd-standing transition) inside the TickOrchestrator schedule, and enforces the simultaneity invariant **timer wins over elimination on same tick**. It coordinates round-grant ordering (Currency.grantMatchRewards BEFORE `MatchStateChanged("Result")`), the T9 destroyAll → clearAll → broadcast order on Result→Intermission, and the double-signal guard preventing double-transition on same-tick elim.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: MSM/RoundLifecycle Split + Authority Matrix | 7-state enum, transitionTo authority, participation snapshot timing, peakTimestamp owner, grant-before-broadcast invariant, spectator mode, clock consistency | LOW |
| ADR-0002: TickOrchestrator | Phase 6 timerCheck + Phase 7 eliminationConsumer hook contract; simultaneity Phase 6 < Phase 7 | MEDIUM |
| ADR-0010: Server-Authoritative Validation | AFK RemoteEvent 4-check guard (identity / state / parameters / rate); `GetParticipation` RemoteFunction validation | LOW |
| ADR-0011: Persistence Schema + Pillar 3 Exclusions | Match state is round-scoped (NEVER persisted); BindToClose path coordinates with ProfileStore session-release order | LOW |
| ADR-0006: Module Placement Rules | Server-only module under `ServerStorage/Source/MatchStateServer/init.luau` | LOW |

## GDD Requirements

20 TRs from `tr-registry.yaml`. Coverage post-ADR-0005 acceptance:

| TR-ID | Requirement Domain | ADR Coverage |
|-------|--------------------|--------------|
| TR-msm-001 | Core — 7-state enum | ✅ ADR-0005 |
| TR-msm-002 | Authority — transitionTo internal-only | ✅ ADR-0005 |
| TR-msm-003 | Core — per-state timer | ✅ ADR-0005 |
| TR-msm-004 | Authority — Phase 7 elimination consumer | ✅ ADR-0002 + ADR-0005 |
| TR-msm-005 | Core/Timing — Phase 6 timerCheck | ✅ ADR-0002 §Phase 6 |
| TR-msm-006 | Authority — participationFlag table | ✅ ADR-0005 |
| TR-msm-007 | Core/Timing — Phase 6 < Phase 7 simultaneity | ✅ ADR-0002 |
| TR-msm-008 | Authority — driver set (PlayerAdded/Removing/AFK/CrowdEliminated/BindToClose) | ✅ ADR-0005 |
| TR-msm-009 | Networking — `MatchStateChanged` wire format | ✅ arch §5.7 + ADR-0005 |
| TR-msm-010 | Authority — read-only external consumers | ✅ ADR-0005 |
| TR-msm-011 | Authority — `getParticipation` RemoteFunction | ✅ ADR-0005 |
| TR-msm-012 | UI/Core — `getStateEndsAt` absolute epoch | ✅ ADR-0005 |
| TR-msm-013 | Networking — payload `{state, serverTimestamp, stateEndsAt, meta}` | ✅ arch §5.7 + ADR-0005 |
| TR-msm-014 | Persistence/Networking — BindToClose schema interaction | ✅ arch §4.5 + ADR-0006 + ADR-0011 |
| TR-msm-015 | Authority — double-signal guard on same-tick elim | ✅ ADR-0002 §Phase 7 |
| TR-msm-016 | Gameplay — spectator mode | ✅ ADR-0005 |
| TR-msm-017 | Authority — grants BEFORE Result broadcast | ✅ ADR-0005 |
| TR-msm-018 | Performance — Phase 6/7 budget 0.1 ms total | ✅ ADR-0003 |
| TR-msm-019 | Core/Timing — cadence accuracy | ✅ ADR-0002 |
| TR-msm-020 | Networking — clock consistency invariant | ✅ ADR-0005 |

**Coverage after ADR-0005 Accepted**: 20 / 20 ✅

⚠️ **Untraced**: None.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, and closed via `/story-done`
- `MatchStateServer/init.luau` exposes the 5-method API per architecture.md §5.2: `get / getParticipation / getStateEndsAt / timerCheck / eliminationConsumer`
- All 20 acceptance criteria from `design/gdd/match-state-machine.md` are verified
- 7-state enum + transitions encoded per ADR-0005 §Decision (Lobby, Countdown:Ready, Countdown:Snap, Active, Result, Intermission, ServerClosing)
- Phase 6 timer drives T7 (Active elapsed ≥ 300s → Result with F4 winner tiebreak: count → peakTimestamp → UserId)
- Phase 7 drains queued `CrowdEliminated` signals; T6 on `numActiveNonEliminated ≤ 1` ∧ matchState==Active; double-signal guard silently drops if state already transitioned
- `MatchStateChanged` reliable RemoteEvent fires on every transition with `{state, serverTimestamp, stateEndsAt, meta}` payload (arch §5.7)
- `Currency.grantMatchRewards(placements)` invoked BEFORE `MatchStateChanged("Result")` broadcast (AC-20 grant-before-broadcast invariant)
- T9 order: `RoundLifecycle.destroyAll → RelicSystem.clearAll → MatchStateChanged("Intermission")` (AC-14)
- `T11 BindToClose` path: `TickOrchestrator.stop → MatchStateChanged("ServerClosing") → ProfileStore release` (architecture §4.5)
- `GetParticipation` RemoteFunction stateless reconcile passes ADR-0010 4-check guard
- `ParticipationChanged` reliable RemoteEvent fires per-player on participation flag change
- Logic stories pass automated TestEZ tests in `tests/unit/match-state-server/` (transition graph, simultaneity Phase 6 < Phase 7, double-signal guard, grant-before-broadcast ordering, BindToClose sequencing, F4 tiebreak determinism)
- Audit gates green: `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` exit 0
- Pillar 3 exclusion verified: match state never appears in `PlayerDataKey` / `DefaultPlayerData`

## Next Step

Run `/create-stories match-state-server` to break this epic into implementable stories.
