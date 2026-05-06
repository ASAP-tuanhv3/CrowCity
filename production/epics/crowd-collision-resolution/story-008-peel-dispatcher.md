# Story 008: PeelDispatcher — F4 relevance filter + batched FireClient

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-011`, `TR-ccr-012`, `TR-ccr-013`, `TR-ccr-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy + ADR-0002 §Phase 9 + ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: PeelDispatcher runs as Phase 9 (last per tick) per ADR-0002. Reads `_peelBuffer` (from Story 007); per player, filters entries to those involving their crowdId (F4 relevance); batches all entries into ONE `FireClient` call per player per tick. UnreliableRemoteEvent acceptable (cosmetic; ADR-0001 tolerance for peel).

**Engine**: Roblox | **Risk**: HIGH (post-cutoff UREvent)
**Engine Notes**: UnreliableRemoteEvent stable post-cutoff. Verify against `replication-best-practices.md`.

**Control Manifest Rules (Foundation/Feature):**
- Required: All remotes via Network wrapper (ADR-0006)
- Required: UnreliableRemoteEvent for high-frequency continuous; cosmetic-only acceptable per ADR-0001 (peel)
- Required: One FireClient call per player per tick — batched buffer (ADR-0001 §peel batch)
- Required: Phase 9 last per tick (ADR-0002)
- Forbidden: Per-entry FireClient (collapses bandwidth)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-11 (F4 peel buffer relevance filter)**: GIVEN `_overlapPairs/_peelBuffer = [{attackId="111", defendId="222", n=2}, {attackId="333", defendId="444", n=1}]`, WHEN `flush()` runs, THEN player "222" receives exactly one FireClient call with buffer `[{loserId="222", winnerId="111", n=2}]`; player "555" (no involvement) receives ZERO FireClient calls this tick.
- [ ] **AC-18 (Eliminated skip in dispatch)**: GIVEN _peelBuffer entry involves a crowd just Eliminated (now absent from `getAllActive()`), WHEN `flush()` runs, THEN the player whose crowdId matches the Eliminated crowd receives no FireClient call for that entry; OTHER players still receive entries naming the Eliminated crowd as opposing party (rival-nil handling on client per Story 009); no nil-deref errors.
- [ ] **AC-21 (Batched FireClient + bandwidth)**: GIVEN 12 crowds in pileup (11 pairs involving one player's crowd), WHEN `flush()` runs for that player, THEN exactly ONE FireClient call (buffer batched 11 entries); per-client `CollisionPeelEvent` bandwidth ≤ 6.6 KB/s under sustained 12-crowd pileup; ≤1.8 KB/s at 3-pair steady state.

---

## Implementation Notes

*Derived from GDD §F4 + ADR-0002 §Phase 9:*

- Add to `RemoteName/UnreliableRemoteEventName.luau`: `CollisionPeelEvent = "CollisionPeelEvent"`.
- PeelDispatcher module at `ServerStorage/Source/CollisionResolver/PeelDispatcher.luau` (sibling of `init.luau`).
- Phase 9 callback `PeelDispatcher.flush(tickCount)`:
  - Build `playerByCrowdId: {[crowdId]=Player}` map (cached; updated on `MatchStateServer.Participation` changes — likely already present from MSM epic).
  - Build per-player buffer map `bufferByPlayer: {[Player]={...entries...}}`:
    - For each `entry` in `_peelBuffer`:
      - `attackerPlayer = playerByCrowdId[entry.attackId]`; if not nil → push `{loserId=entry.defendId, winnerId=entry.attackId, n=entry.delta}` to `bufferByPlayer[attackerPlayer]`.
      - `defenderPlayer = playerByCrowdId[entry.defendId]`; if not nil → push `{loserId=entry.defendId, winnerId=entry.attackId, n=entry.delta}` to `bufferByPlayer[defenderPlayer]`.
    - Same direction sent to both relevant players (each player gets entry where their crowdId is involved).
  - For each player with non-empty buffer: `Network.fireClientUnreliable(player, UREventName.CollisionPeelEvent, buffer)`.
- AC-18: if `csm.get(entry.attackId) == nil` (just Eliminated), still emit to defender side (defender sees followers leaving toward stale rival visual — Story 009 client handles rival-nil); but if entry's defender is Eliminated, attacker side still receives (sees rival's followers arriving).
- Buffer encoding: entries packed via buffer codec from network-layer-ext epic; same channel pattern as CrowdStateBroadcast.
- Phase 9 wiring: `TickOrchestrator.registerPhase(9, PeelDispatcher.flush)`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: _peelBuffer assembly (consumed here).
- Story 009: client-side `FollowerEntityClient.startPeel(loserId, winnerId, n)` consumer.
- Story 011: bandwidth soak measurement.

---

## QA Test Cases

- **AC-11 (Relevance filter)**:
  - Given: 2 entries: `{attackId="111", defendId="222", n=2}`, `{attackId="333", defendId="444", n=1}`; players P1=>"111", P2=>"222", P3=>"333", P4=>"444", P5=>"555"
  - When: flush
  - Then: P2 receives `[{loserId="222", winnerId="111", n=2}]`; P5 receives zero FireClient
  - Edge cases: P1 also receives `[{loserId="222", winnerId="111", n=2}]` (attacker side) — symmetric per-player coverage.

- **AC-18 (Eliminated skip)**:
  - Given: entry attackId = "Z" (Z just eliminated, absent from getAllActive); pZ player exists but has no own crowd anymore
  - When: flush
  - Then: P_Z (eliminated player) receives nothing for this entry; defender player still receives (showing rival-nil visual)
  - Edge cases: both eliminated → no FireClient.

- **AC-21 (Batched FireClient)**:
  - Given: pileup with 11 entries involving player P
  - When: flush
  - Then: exactly 1 FireClient call to P; payload buffer length 11
  - Edge cases: 0 entries for P → 0 FireClient; bandwidth metric tracked separately Story 011.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/peel_dispatcher.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007 (_peelBuffer); MatchStateServer participant tracking (Sprint 3 partial — `playerByCrowdId` mapping already exists or close).
- Unlocks: Story 009 (client consumer).
