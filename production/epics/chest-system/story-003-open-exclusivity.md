# Story 003: Open exclusivity — 2D distance + UserId tiebreak

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: When two players trigger the same chest in the same server frame and both pass guards, the nearer player (2D squared distance to chest position) claims; ties resolved by lower `player.UserId`. Other player's claim discarded silently.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Pre-cutoff stable APIs.

**Control Manifest Rules:**
- Required: Server-authoritative claim resolution (ADR-0010)
- Required: 2D squared distance (Y ignored — per chest GDD)
- Forbidden: Trust client-asserted timestamp / hold duration (ADR-0010)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-6 (Distance + UserId tiebreak)**:
  - Given: two players trigger same chest same server frame, both pass guards
  - When: distances differ → nearer player claims
  - When: distances equal → lower UserId claims
  - Other player discarded silently (no toll, no state change for their crowd).

---

## Implementation Notes

*Derived from GDD §C Rule 4:*

- Within a server frame, multiple Triggered fires for same chest are queued. The chest accumulates them in `_pendingClaims = { {player, hrpPos, t} ... }` for the frame.
- Resolution at frame end (use `RunService.Heartbeat` defer or `task.defer`): pick winner per AC-6 rule.
  - 2D squared distance: `(hrpPos.X - chestPos.X)^2 + (hrpPos.Z - chestPos.Z)^2`. Y ignored.
  - Tiebreak: `winner.UserId < runner.UserId`.
- Implementation simplification: ChestComponent maintains `_lastFrameClaim: {player, distSq, userId}` updated on each Triggered; existing claim replaced only if new distSq is strictly less, OR equal-distSq AND lower UserId. Frame-end consume: `_lastFrameClaim` resolved as winner; cleared.
- Note: Roblox ProximityPrompt has minimum HoldDuration = 0.8s, so simultaneous triggers on a single frame are rare but possible (multi-input + lag). Cover via test injection.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: guard pipeline (this story runs after).
- Story 006: atomic claim mechanics (this story picks the winner; 006 deducts toll).

---

## QA Test Cases

- **AC-6 (Distance tiebreak)**:
  - Given: players P1 (UserId=100) at distSq=25 and P2 (UserId=200) at distSq=50; both Triggered same frame
  - When: frame resolves
  - Then: P1 claims; P2 discarded
  - Edge cases: P1 at distSq=50 and P2 at distSq=25 → P2 claims (UserId not relevant when distances differ).

- **AC-6 (UserId tiebreak)**:
  - Given: P1 (UserId=100) and P2 (UserId=200), both at distSq=49.0
  - When: frame resolves
  - Then: P1 claims (lower UserId)
  - Edge cases: same UserId impossible (UserIds globally unique).

- **3-way frame race**:
  - Given: P1=100/distSq=25, P2=200/distSq=20, P3=150/distSq=20
  - When: frame resolves
  - Then: distSq min == 20 (P2, P3); UserId tiebreak P3 (150) < P2 (200) → P3 claims
  - Edge cases: ordering of Triggered fires must not affect outcome (deterministic).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/open_exclusivity.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (guard pass precedes claim resolution).
- Unlocks: Story 006 (claim winner enters atomic deduction).
