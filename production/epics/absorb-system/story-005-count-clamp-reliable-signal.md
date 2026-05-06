# Story 005: Count clamp passthrough + Absorbed reliable RemoteEvent

> **Epic**: AbsorbSystem (Absorb System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/absorb-system.md`
**Requirement**: `TR-absorb-005`, `TR-absorb-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy + ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: `Absorbed` fires reliable RemoteEvent (not UnreliableRemoteEvent) — discrete must-arrive event for VFX snap + audio. Count ceiling 300 enforced inside `CSM.updateCount` clamp (F5), NOT in AbsorbSystem — Absorb passes through `+1` unconditionally. Payload schema: `(crowdId, npcLastPosition)`.

**Engine**: Roblox | **Risk**: HIGH (post-cutoff)
**Engine Notes**: ADR-0001 buffer-encoded broadcast. Absorbed is discrete reliable event — uses standard RemoteEvent through Network wrapper. No buffer encoding needed (low frequency, ~10/sec peak per crowd).

**Control Manifest Rules (Foundation + Feature layers)**:
- Required: All remotes via Network wrapper (ADR-0006)
- Required: Reliable RemoteEvent for must-arrive discrete events (ADR-0010)
- Required: RemoteEventName enum entry — no magic strings (ADR-0006)
- Forbidden: UnreliableRemoteEvent for must-arrive events (ADR-0010 — data loss)
- Forbidden: AbsorbSystem-side `if count >= 300` guard — clamp lives in CSM F5 (per AC-9)

---

## Acceptance Criteria

*From GDD `design/gdd/absorb-system.md`, scoped to this story:*

- [ ] **AC-9 (300 ceiling truncate, no AbsorbSide guard)**: crowd at count=300 + NPC in radius → AbsorbSystem calls `updateCount(+1)` + `reclaim` UNCONDITIONALLY. Code grep verifies no `if count >= 300` branch in AbsorbSystem source.
- [ ] **Absorbed reliable RemoteEvent registered**: `RemoteEventName.Absorbed` added to enum; payload `(crowdId: string, npcLastPosition: Vector3)`.
- [ ] **Reliable transport**: fired via `Network.fireAllClients(RemoteEventName.Absorbed, crowdId, npcLastPosition)` — never UREvent.
- [ ] **Server BindableEvent intra-server signal kept**: VFX + Audio (Story 006) still consume the in-process `Absorbed` BindableEvent for zero-latency callback; client broadcast is parallel fire.

---

## Implementation Notes

*Derived from ADR-0001 §Reliable Gameplay Events + ADR-0010 §Reliable-vs-Unreliable Selection:*

- Add to `src/ReplicatedStorage/Source/Network/RemoteName/RemoteEventName.luau`: `Absorbed = "Absorbed"`.
- Confirm Network wrapper auto-creates RemoteEvent at boot (per template ANATOMY §5).
- AbsorbSystem fires both edges per overlap (after `updateCount`, before `reclaim` per Story 003 sequence): (a) intra-server `Absorbed` BindableEvent for VFX/audio Story 006; (b) `Network.fireAllClients(RemoteEventName.Absorbed, crowdId, pos)` for client-side replication consumers.
- AC-9 grep gate added to `tools/audit-absorb-no-count-guard.sh` (new tool — short bash script greps `count\s*>=\s*300\|count\s*==\s*MAX_CROWD_COUNT` inside `src/ServerStorage/Source/AbsorbSystem/`; exit 1 on match).
- Bandwidth budget: peak ~10 fires/sec/crowd × 12 crowds = 120 events/sec, ~25 B each = ~3 KB/s — fits within "Reliable gameplay events 0.5 KB/s" share when considered burst (per ADR-0003 burst allowance ≤500 ms).
  - **Note**: if soak shows steady-state above 0.5 KB/s, route Absorbed through batched-per-tick reliable event in a follow-up amendment to ADR-0001/0003.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001-004: skeleton, overlap, sequence, state guards.
- Story 006: V/A consumers (VFX snap + audio batching/streak).
- Story 007: perf soak.

---

## QA Test Cases

- **AC-9 (No AbsorbSide guard)**:
  - Given: crowd at count=300; mock CSM.updateCount returns 300 (clamped)
  - When: 1 NPC absorbed in tick
  - Then: spy on updateCount fires `(crowdId, +1, "Absorb")` exactly once; reclaim fires; AbsorbSystem source contains zero `count >= MAX_CROWD_COUNT` branches (grep)
  - Edge cases: count=299 → +1 → 300 (no clamp); count=300 → +1 → still 300 (CSM clamps); ceiling enforced upstream.

- **Absorbed reliable RemoteEvent payload**:
  - Given: 1 NPC absorbed at world `(7, 0, -3)` for crowd "alpha"
  - When: tick fires
  - Then: `Network.fireAllClients` spy captures `(RemoteEventName.Absorbed, "alpha", Vector3.new(7,0,-3))` exactly once
  - Edge cases: 8 absorbs in same tick → 8 fires; pos vectors distinct.

- **Intra-server BindableEvent parity**:
  - Given: connected listener on `Absorbed` BindableEvent
  - When: 1 NPC absorbed
  - Then: BindableEvent fires synchronously inside the tick; payload matches the RemoteEvent payload
  - Edge cases: zero listeners — fire still safe (no error).

- **Audit script gate**:
  - Given: introduce `if count >= 300 then return end` into AbsorbSystem source
  - When: `bash tools/audit-absorb-no-count-guard.sh`
  - Then: exit code 1, error message names the offending file:line
  - Edge cases: comment containing the string `count >= 300` is not flagged (regex anchored to non-comment).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/absorb/count_clamp_reliable_signal.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (per-overlap sequence — fire site).
- Unlocks: Story 006 (V/A consumers subscribe Absorbed signal).
