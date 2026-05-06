# Story 002: Guard pipeline — 6-stage strict serial reject

> **Epic**: ChestSystem (Chest System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/chest-system.md`
**Requirement**: `TR-chest-002`, `TR-chest-003`, `TR-chest-006`, `TR-chest-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 Server-Authoritative Validation
**ADR Decision Summary**: 6-stage guard pipeline runs server-side on `ProximityPrompt.Triggered`; reject silently on first failure, no side-effects, no subsequent stage evaluated. Active state strict (rejects GraceWindow + Eliminated post-2026-04-24 amendment).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: 4-check guard pattern from ADR-0010 (identity / state / parameters / rate) extended with chest-specific stages.

**Control Manifest Rules:**
- Required: 4-check guard pattern on every server-side handler (ADR-0010): identity → state → parameters → rate
- Required: Silent rejection on validation failure (ADR-0010)
- Required: Per-player rate limit via `RateLimitConfig` for ChestPromptTrigger remote (ADR-0010)
- Forbidden: Skip any of 4 guard categories (ADR-0010)

---

## Acceptance Criteria

*From GDD `design/gdd/chest-system.md`, scoped to this story:*

- [ ] **AC-4 (Guard reject paths 3a-3f)**: Each individually-set false guard rejects silently with no toll, no state change, no subsequent guard evaluated:
  - (a) `matchState != Active`
  - (b) `participationFlag == false`
  - (c) `crowdState != "Active"` strict (rejects Eliminated AND GraceWindow)
  - (d) `#activeRelics >= MAX_RELIC_SLOTS = 4`
  - (e) chest `_state != "Available"` (rejects DraftOpen / Cooldown / Respawning / Dormant)
  - (f) `crowdCount <= effectiveToll` (count-at-floor reject — covered fully in Story 004)
- [ ] **AC-5 (Full pass)**: All 6 guards passing → interaction proceeds; toll deducted (Story 006); chest → `Claimed`.
- [ ] **AC-21 (Rival trigger during DraftOpen)**: rival trigger on chest in DraftOpen → guard (e) rejects; no toll, no state change.

---

## Implementation Notes

*Derived from GDD §C Rule 3 + ADR-0010 §4-Check:*

- ProximityPrompt.Triggered handler signature `(player: Player)` — engine-supplied identity is sole trusted source.
- Guard order (serial; first failure exits):
  1. **Identity (engine `player`)**: not nil; ServerScript scope.
  2. **State** (server-authoritative reads):
     - `matchState = MatchStateServer.getCurrentState()`; reject if != "Active"
     - `participationFlag = MatchStateServer.getParticipation(player)`; reject if false
     - `crowd = CrowdStateServer.get(player.crowdId)`; reject if nil
     - reject if `crowd.state != "Active"` (strict — no GraceWindow)
     - reject if `#crowd.activeRelics >= MAX_RELIC_SLOTS` (4)
     - reject if chest `_state != "Available"`
     - reject if `crowd.count <= queryChestToll(crowd.crowdId, tier, baseToll)` (Story 004 + 005 own queryChestToll)
  3. **Parameters**: prompt has no client payload — n/a.
  4. **Rate**: `RemoteValidator.checkRate(player, "ChestPromptTrigger")`; reject if exceeded.
- Silent reject = `return` early from handler. No `Network.fireClient` reject message; no log (info-level log per ADR-0010 first-of-kind allowed).
- Add to `SharedConstants/RateLimitConfig.luau`: ChestPromptTrigger token-bucket (rate = 5/s sustained, burst = 8 per ADR-0010 burst envelope).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Open exclusivity (distance/UserId tiebreak — separate from guards).
- Story 004: F1 base_toll_scaled.
- Story 005: F2 queryChestToll.
- Story 006: Atomic claim post-pass.

---

## QA Test Cases

- **AC-4 (6 reject paths)** — 6 test fns, one per path:
  - Given: 5 of 6 guards passing, 1 set to fail
  - When: Triggered fires
  - Then: spy on `csm.updateCount` shows zero calls; chest state unchanged; no `ChestDraftOffer` fired
  - Edge cases: simultaneous failure of (a) AND (b) — first one (a) wins; later guards not evaluated (verify spy not called).

- **AC-5 (Full pass)**:
  - Given: matchState=Active, participation=true, crowdState=Active strict, activeRelics=2, chestState=Available, count > effectiveToll
  - When: Triggered
  - Then: post-guard, claim flow proceeds (Story 003 owns)
  - Edge cases: count exactly == effectiveToll → guard (f) rejects; count > effectiveToll by 1 → passes.

- **AC-21 (Rival during DraftOpen)**:
  - Given: chest in DraftOpen state; rival player triggers
  - When: Triggered fires
  - Then: guard (e) rejects (chestState != Available); zero side effects
  - Edge cases: same player who opened triggers again → also (e) rejects.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chest/guard_pipeline.spec.luau` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (ChestComponent state); RemoteValidator (Sprint 3 closed); MatchStateServer participation API (Sprint 3 partial).
- Unlocks: Stories 003 + 006.
