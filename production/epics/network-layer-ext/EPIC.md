# Epic: Network Layer Extensions

> **Layer**: Foundation
> **GDD**: N/A — extension of template `Network` module; contracts derived from ADRs + architecture §5.7
> **Architecture Module**: Network (architecture.md §3.1 row 1)
> **Status**: Ready
> **Stories**: 5 created 2026-04-27 (see table below)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [UnreliableRemoteEvent wrapper + UnreliableRemoteEventName enum](story-001-unreliable-wrapper.md) | Logic | Ready | ADR-0001, ADR-0006 |
| 002 | [RemoteEventName + RemoteFunctionName extensions](story-002-remote-name-extensions.md) | Logic | Ready | ADR-0006 |
| 003 | [Buffer codec for CrowdStateBroadcast (30 B/crowd)](story-003-crowd-state-buffer-codec.md) | Logic | Ready | ADR-0001 §buffer mandate |
| 004 | [RemoteValidator shared module (4-check guard)](story-004-remote-validator.md) | Logic | Ready | ADR-0010 |
| 005 | [RateLimitConfig SharedConstants table](story-005-rate-limit-config.md) | Config/Data | Ready | ADR-0010 |

Order: 001 + 002 parallel after start; 003 depends on 001+002; 004 depends on 005 (or develop in parallel with 005 stub).

## Overview

This epic extends the template-provided `Network/init.luau` wrapper with the post-cutoff Roblox APIs and new event surface required by every Core+ system. It adds an `UnreliableRemoteEvent` wrapper, `connectUnreliableEvent` API, the `UnreliableRemoteEventName` enum (mandatory per ADR-0001), buffer encode/decode helpers (mandated by ADR-0001 amend 2026-04-24), and the new `RemoteEventName` / `RemoteFunctionName` entries the gameplay tick path needs. It also lands the shared `RemoteValidator` module that ADR-0010 mandates as the 4-check guard surface for every remote handler in the project.

Without this epic, no downstream system can wire its broadcast or reliable-event path — CSM, MSM, NPC Spawner, Chest, and Match-state all depend on the new event names and the Unreliable+buffer transport.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Crowd Replication Strategy | Mandates `UnreliableRemoteEvent` + Luau `buffer` encoding for `CrowdStateBroadcast` (15 Hz, ~30 B/crowd) | HIGH (post-cutoff API) |
| ADR-0006: Module Placement + Layer Boundary | All remotes via `Network` module; no direct path/string-literal access | LOW |
| ADR-0010: Server-Authoritative Validation | Shared `RemoteValidator` 4-check pattern (identity / state / parameters / rate); silent rejection model; per-player rate limits via `RateLimitConfig` | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| (none direct) | Foundation extension; downstream consumers register Network as upstream dep — see CSM TR-csm-* (wire path), MSM TR-msm-* (MatchStateChanged remote), NPC TR-npc-* (NpcStateBroadcast). | Indirect — covered by ADR-0001/0010 |

⚠️ **Untraced by TR registry as a Network-system entry** — work is ADR-traced. Each story cites ADR-0001 §Decision (UREvent + buffer mandate), ADR-0010 §Decision (4-check validator + RateLimitConfig), or architecture.md §5.7 (Wire contracts table).

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- `Network/init.luau` exposes `connectUnreliableEvent(name, callback)` + `fireAllClientsUnreliable(name, payload)` + `fireClientUnreliable(player, name, payload)`
- `Network/RemoteName/UnreliableRemoteEventName.luau` enum module exists with entries: `CrowdStateBroadcast`, `NpcStateBroadcast`
- `Network/RemoteName/RemoteEventName.luau` updated with: `CrowdCreated`, `CrowdDestroyed`, `CrowdEliminated`, `CrowdRelicChanged`, `MatchStateChanged`, `ParticipationChanged`, `GameplayEvent`, `NpcPoolBootstrap`, `ChestStateChanged`
- `Network/RemoteName/RemoteFunctionName.luau` updated with `GetParticipation`
- Buffer encode/decode helpers for the CSM broadcast payload (~30 B/crowd: position f32×2 + radius f32 + count u8 + hue u4 + state u4 + tick u16 + relic-bitmask u8) live in `Network/BufferCodec/CrowdState.luau` (or equivalent)
- `RemoteValidator` shared module under `ReplicatedStorage/Source/RemoteValidator/init.luau` exposing 4-check guard API + `RateLimitConfig` registration per ADR-0010
- All Logic stories (validator unit tests, buffer round-trip) have passing test files in `tests/unit/network/` + `tests/unit/remote-validator/`
- Integration story (multi-client buffer broadcast smoke test) has evidence in `production/qa/evidence/`

## Next Step

Run `/create-stories network-layer-ext` to break this epic into implementable stories.
