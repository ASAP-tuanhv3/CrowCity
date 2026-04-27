# Epic: Network Layer Extensions

> **Layer**: Foundation
> **GDD**: N/A — extension of template `Network` module; contracts derived from ADRs + architecture §5.7
> **Architecture Module**: Network (architecture.md §3.1 row 1)
> **Status**: Complete (2026-04-27 — 5/5 shipped)
> **Stories**: 5/5 Complete

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [UnreliableRemoteEvent wrapper + UnreliableRemoteEventName enum](story-001-unreliable-wrapper.md) | Logic | Complete | ADR-0001, ADR-0006 |
| 002 | [RemoteEventName + RemoteFunctionName extensions](story-002-remote-name-extensions.md) | Logic | Complete | ADR-0006 |
| 003 | [Buffer codec for CrowdStateBroadcast (30 B/crowd)](story-003-crowd-state-buffer-codec.md) | Logic | Complete | ADR-0001 §buffer mandate |
| 004 | [RemoteValidator shared module (4-check guard)](story-004-remote-validator.md) | Logic | Complete | ADR-0010 |
| 005 | [RateLimitConfig SharedConstants table](story-005-rate-limit-config.md) | Config/Data | Complete | ADR-0010 |

Order: 001 + 002 → 003 → 005 → 004 (linear in this implementation pass).

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
- All 5 stories implemented, reviewed, and closed via `/story-done` ✓ (2026-04-27)
- `Network/init.luau` exposes `connectUnreliableEvent(name, callback, typeValidator)` + `fireAllClientsUnreliable(name, ...)` + `fireClientUnreliable(player, name, ...)` ✓
- `Network/RemoteName/UnreliableRemoteEventName.luau` enum exists with entries `CrowdStateBroadcast`, `NpcStateBroadcast` ✓
- `Network/RemoteName/RemoteEventName.luau` extended with 22 architecture.md §5.7 entries (4 + 22 = 26 total) ✓
- `Network/RemoteName/RemoteFunctionName.luau` extended with `GetParticipation` (1 + 1 = 2 total) ✓
- `Network/BufferCodec/CrowdState.luau` codec with `encode/decode/recordSize/CrowdRecord type`; 30-byte per-crowd layout matching arch §5.7 byte-for-byte ✓
- `RemoteValidator` shared module under `ServerStorage/Source/RemoteValidator/init.luau` exposing 4 named guards (`checkIdentity / checkState / checkParameters / checkRate`) + `checkPayloadSize` helper ✓
- `SharedConstants/RateLimitConfig.luau` with token-bucket per-remote entries (3 explicit + default fallback) ✓
- All Logic + Config/Data stories have passing test files in `tests/unit/network/` + `tests/unit/remote-validator/` (5 test files, ~80 test functions total) ✓
- Audit gates green: tools/audit-asset-ids.sh exit 0 / tools/audit-persistence.sh exit 0 / AC-7 magic-string grep zero matches outside Network module ✓

**Status**: Epic Complete (5/5 deliverables shipped 2026-04-27).

## Next Step

Foundation deliverable complete. **All 4 Foundation epics now Complete** (asset-id-registry 4/4, ui-handler-layer-reg 1/1 effective, player-data-schema 2/3 effective, network-layer-ext 5/5). Foundation phase ready for `/gate-check` to advance to Core layer. Consumer epics now unblocked: CSM `broadcastAll` / NpcPool / Match-state-machine / Chest / Relic / Absorb.
