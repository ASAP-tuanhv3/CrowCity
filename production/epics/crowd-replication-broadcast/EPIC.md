# Epic: Crowd Replication Broadcast Path

> **Layer**: Core (server send) + Presentation (client mirror) — bi-layer per architecture.md §3.2 row 5
> **GDD**: design/gdd/crowd-replication-strategy.md
> **Architecture Module**: Crowd Replication broadcast path (server `broadcastAll` inside CSM + `CrowdStateClient` mirror)
> **Status**: Ready (5 stories drafted 2026-04-28)
> **Stories**: 5 Ready

## Stories

| # | Story | Type | Status | Primary ADR |
|---|-------|------|--------|-------------|
| 001 | [CrowdStateClient skeleton + mirror cache + lastReceivedTick + tick_is_newer (F4)](story-001-crowdstateclient-mirror-tick-is-newer-f4.md) | Logic | Ready | ADR-0001 + ADR-0006 |
| 002 | [Broadcast subscriber + decode + idempotent overwrite + stale freeze (F2) + Eliminated defensive](story-002-broadcast-subscriber-decode-stale-defense.md) | Logic | Ready | ADR-0001 |
| 003 | [Reliable subscribers + 4 client BindableEvent signals + late-reliable handling](story-003-reliable-subscribers-late-reliable-handling.md) | Integration | Ready | ADR-0001 |
| 004 | [Server-side broadcast loop + Dormant → Active → Closing transport phase machine (integration)](story-004-server-transport-phase-machine.md) | Integration | Ready | ADR-0001 + ADR-0002 |
| 005 | [F1 bandwidth estimator + static gates + multi-client perf (deferred)](story-005-f1-bandwidth-static-gates-perf-deferred.md) | Logic + Audit + Performance (deferred) | Ready | ADR-0001 + ADR-0003 |

Order: 001 → 002 + 003 (parallelizable post-001) → 004 (integration of CSM+RL+TickOrch+client) → 005 (helpers + static gates).

## Overview

This epic delivers the 15 Hz buffer-encoded broadcast path that replicates crowd state from server authority (CSM) to every client. It has two halves:

1. **Server broadcast** — the `CrowdStateServer.broadcastAll(tickCount)` Phase 8 hook: walks `_crowds`, builds the 30 B/crowd buffer payload via the Foundation `BufferCodec/CrowdState.luau` codec, fires `CrowdStateBroadcast` `UnreliableRemoteEvent` to all clients with monotonic uint16 tick.
2. **Client mirror** — `ReplicatedStorage/Source/CrowdStateClient/init.luau`: receives unreliable broadcast + 5 reliable named events (CrowdCreated/Destroyed/Eliminated/CountClamped/RelicChanged), maintains read-only `_crowds` mirror with `lastReceivedTick` per crowd (CRS F4 stale-packet defense), exposes `get(crowdId)` accessor + 4 client signals (`CrowdCreated / CrowdDestroyed / CrowdEliminated / CrowdRelicChanged`).

Per architecture §3.2 the broadcast path is treated as ONE module spanning Core+Presentation because the wire-format contract is indivisible — server payload schema + client decoder are a single contract. Buffer codec lives in Foundation (`network-layer-ext` story-003 — already complete). This epic depends on Foundation Network + Foundation buffer codec + CSM record schema.

This epic is the heaviest engine-risk module in the Core layer. It is the sole consumer of `UnreliableRemoteEvent` + Luau `buffer` API, both post-cutoff (May 2025) per `replication-best-practices.md`. Multi-client + soak validation is deferred to first MVP integration sprint per ADR-0003 §Validation Sprint Plan.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Crowd Replication Strategy | UREvent + Luau `buffer` mandate (15 Hz, 30 B/crowd payload schema), 5 reliable named events for life-cycle/eliminate/relic/clamp, monotonic uint16 tick + lastReceivedTick stale defense, late-join gap acknowledged | HIGH (UREvent + buffer post-cutoff) |
| ADR-0003: Performance Budget | Network bandwidth budget (~360 B/tick @ 12 crowds × 30 B); burst allowance for reliable lifecycle events; Phase 8 0.6 ms server budget | MEDIUM (multi-client deferred) |
| ADR-0004: CSM Authority | `broadcastAll` is CSM-internal Phase 8 hook; CrowdStateClient is read-only mirror | LOW |

## GDD Requirements

27 TRs from `tr-registry.yaml` — best-covered system in the project (ADR-0001 + GDD are 1:1 by design).

| TR Range | Requirement Domain | ADR Coverage |
|----------|--------------------|--------------|
| TR-crs-001 .. TR-crs-024 | Wire format, payload schema, monotonic tick, stale-packet defense, 5 reliable events, late-join behavior, UREvent broadcast cadence | ✅ ADR-0001 (varies §Decision / Key Interfaces / Risks / amends) |
| TR-crs-025 | Network bandwidth budget | ✅ ADR-0003 §Network bandwidth budget |
| TR-crs-026 | Burst allowance for reliable events | ✅ ADR-0003 §Burst allowance |
| TR-crs-027 | Authority + replication boundary | ✅ ADR-0001 + ADR-0004 |

**Coverage**: 25 ✅ / 2 ⚠️ / 0 ❌

⚠️ Items:
- **TR-crs-021** — cross-channel ordering between unreliable broadcast and reliable lifecycle events is "advisory" (no ADR locks). Stories must call out tolerance for late lifecycle arrival.
- **TR-crs-024** — mid-round join blocked (ADR-0001 §Negative Consequences). Stories must implement the late-join gap behavior explicitly.

⚠️ **Untraced**: None blocking.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, and closed via `/story-done`
- **Server side**: `CrowdStateServer.broadcastAll(tickCount)` Phase 8 hook builds 30 B/crowd buffer per arch §5.7 schema, fires `CrowdStateBroadcast` UREvent via `Network.fireAllClientsUnreliable`, increments tick monotonically (uint16 wrap-around tolerated)
- **Client side**: `CrowdStateClient/init.luau` exposes `get(crowdId)`, `getAllActive()` accessors + 4 BindableEvent-style signals (`CrowdCreated / CrowdDestroyed / CrowdEliminated / CrowdRelicChanged`)
- Client maintains `lastReceivedTick` per crowd; out-of-order packets dropped (older tick than last seen → discard, treat uint16 wrap explicitly)
- Reliable lifecycle events (`CrowdCreated / CrowdDestroyed / CrowdEliminated / CrowdCountClamped / CrowdRelicChanged`) processed in arrival order; unreliable broadcast packets older than reliable lifecycle event are tolerated (cross-channel ordering = advisory per TR-crs-021)
- Late-join behavior (TR-crs-024): client receives last reliable `CrowdCreated` snapshots on join; pre-join unreliable packets are NOT replayed (mid-round join gap acknowledged)
- All 27 acceptance criteria from `design/gdd/crowd-replication-strategy.md` verified
- Logic stories pass automated TestEZ tests in `tests/unit/crowd-replication-broadcast/` (round-trip codec → mirror, monotonic tick + uint16 wrap, stale-packet drop, reliable+unreliable interleaving, late-join behavior, payload schema byte-for-byte match)
- Bandwidth telemetry hook in place (instrumented but multi-client validation deferred to MVP integration sprint per ADR-0003)
- Audit gates green: `tools/audit-asset-ids.sh` + `tools/audit-persistence.sh` exit 0
- Client module respects ADR-0006: NEVER `require`s from `ServerStorage`; lives in `ReplicatedStorage/Source/CrowdStateClient/init.luau`

## Next Step

Run `/create-stories crowd-replication-broadcast` to break this epic into implementable stories.
