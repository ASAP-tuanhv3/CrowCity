# Story 006: PairEntered first-contact event + diff against prev tick

> **Epic**: CollisionResolver (Crowd Collision Resolution)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-collision-resolution.md`
**Requirement**: `TR-ccr-009`, `TR-ccr-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 Crowd Replication Strategy + ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: `CollisionContactEvent` (PairEntered) is reliable RemoteEvent — must-arrive on first-contact. Server diffs current overlap pairKey set against `_prevOverlapKeys` (stored last tick). Fires once per pair on entry; no fire on continued contact.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs. Reliable RemoteEvent through Network wrapper.

**Control Manifest Rules (Foundation/Feature):**
- Required: All remotes via Network wrapper (ADR-0006)
- Required: Reliable RemoteEvent for must-arrive discrete events (ADR-0010)
- Required: F2 pair_key canonical (Story 002) used for diff key
- Forbidden: UnreliableRemoteEvent for must-arrive events (ADR-0010)

---

## Acceptance Criteria

*From GDD `design/gdd/crowd-collision-resolution.md`, scoped to this story:*

- [ ] **AC-10 (PairEntered fires only on first contact)**: GIVEN A-B overlapping on tick N (key in `_prevOverlapKeys`), WHEN tick N+1 with A-B still overlapping, THEN `CollisionContactEvent` NOT fired for A-B; if C newly overlaps A on N+1, fires once with `{A, C}` payload.
- [ ] **`RemoteEventName.CollisionContactEvent` registered**: enum entry; payload `(pairKey: string)` or `(crowdIdA: string, crowdIdB: string)` — pick the canonical form.
- [ ] **Reliable transport**: fired via `Network.fireAllClients(RemoteEventName.CollisionContactEvent, ...)` — never UREvent.
- [ ] **Diff state stored**: `_prevOverlapKeys` updated at end of tick to current set; freshly observed crowds whose first-pair contact happens this tick have their key included in next-tick `_prevOverlapKeys`.

---

## Implementation Notes

*Derived from GDD §C Rule 7 + Story 002 pairKey:*

- Internal field `_prevOverlapKeys: {[string]: true} = {}` at module scope.
- After Stories 003-005 complete: build current `_currOverlapKeys = {}` from `_overlapPairs` (Story 002 — only overlapping pairs):
  - `for _, pair in _overlapPairs do _currOverlapKeys[pair.pairKey] = true end`.
- Diff: `for k in _currOverlapKeys do if not _prevOverlapKeys[k] then Network.fireAllClients(RemoteEventName.CollisionContactEvent, k) end end`.
- End of tick: `_prevOverlapKeys = _currOverlapKeys` (table swap; reuse `_currOverlapKeys` table for next tick to avoid allocation).
- Eliminated crowd departure: pairs involving Eliminated crowd no longer in `_overlapPairs` → not in `_currOverlapKeys` → no false-positive entry; on next round, prev cleared at `destroyAll`.
- Add to `RemoteName/RemoteEventName.luau`: `CollisionContactEvent = "CollisionContactEvent"`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-005: skeleton, pair iteration, drip, skip, overlap-bit.
- Story 008: peel dispatch (different event channel).

---

## QA Test Cases

- **AC-10 (First contact only)**:
  - Given: tick N — A-B overlap; _prevOverlapKeys after tick N = `{"A|B"=true}`
  - When: tick N+1 — A-B still overlapping
  - Then: `Network.fireAllClients` spy zero new fires for "A|B" on tick N+1
  - Edge cases: tick N+1 — A-B still overlapping AND C-A newly overlaps → 1 fire for "A|C" (or "C|A" canonical = "A|C").

- **Reliable transport**:
  - Given: pair entered
  - When: tick fires
  - Then: spy shows `Network.fireAllClients(RemoteEventName.CollisionContactEvent, ...)` not `Network.fireAllClientsUnreliable`
  - Edge cases: 12-crowd pileup (all pairs new) → 66 fires (boundary case — bandwidth budget Story 011).

- **Diff state on Eliminated**:
  - Given: A-B in _prevOverlapKeys; tick N+1 A becomes Eliminated and pair drops from _overlapPairs
  - When: tick N+1
  - Then: zero fire for "A|B"; _prevOverlapKeys post-N+1 no longer contains "A|B"; next tick — re-overlap-on-revive (impossible MVP, but cleanly tracked) would re-fire
  - Edge cases: destroyAll resets _prevOverlapKeys to empty.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/collision/pair_entered_event.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-002 (overlap pair set + pairKey).
- Unlocks: Client-side first-contact UI/audio cues (separate epics — not in this story scope).
