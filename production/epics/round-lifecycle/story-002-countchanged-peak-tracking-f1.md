# Story 002: CountChanged subscription + peakCount/peakTimestamp/finalCount tracking (F1) + signal guard

> **Epic**: round-lifecycle
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/round-lifecycle.md` §Formulas/F1 + §Edge Cases/peak-tracking
**Requirement**: `TR-round-lifecycle-002` (peakTimestamp owner), `TR-round-lifecycle-011` (CountChanged subscribe), `TR-round-lifecycle-012` (PlayerRemoving lifecycle — partial; full coverage in story-003)
**ADR**: ADR-0005 §F1 strict `>` rule (manifest L102); ADR-0004 §Write-Access Matrix (`CountChanged` BindableEvent server-only consumer = RoundLifecycle for peakCount).
**ADR Decision Summary**: RoundLifecycle subscribes CSM's `CountChanged` BindableEvent. F1 strict `>` rule: only update `peakCount` and `peakTimestamp` when new count is STRICTLY greater than current peak. Equal counts do NOT update peak. `finalCount` always tracks newCount (regardless of peak comparison).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: BindableEvent subscribe (LOW); `os.clock` (LOW); Janitor for cleanup (LOW).

**Control Manifest Rules (Core layer)**:
- Required: `CountChanged` BindableEvent server-only consumer = RoundLifecycle peakCount tracking (manifest L77); F1 peakCount strict `>` rule (L102).

---

## Acceptance Criteria

- [ ] **AC-5 (Peak update on strict `>`)** — Record at `peakCount=10`; `onCountChanged(id, 15, 10)` fires; `peakCount=15`, `peakTimestamp` updated to `os.clock()` at fire time, `finalCount=15`.
- [ ] **AC-6 (Peak NOT updated on equal)** — `peakCount=300`; `onCountChanged(id, 300, 250)` (newCount equal to peak); `peakTimestamp` UNCHANGED; `finalCount=300`.
- [ ] **AC-7 (Peak NOT updated on below)** — `peakCount=300`; `onCountChanged(id, 250, 300)`; `peakCount` remains 300, `peakTimestamp` unchanged, `finalCount=250`.
- [ ] **AC-8 (Signal guard for non-record)** — `CountChanged` fires for a `crowdId` not in `_crowds` (e.g. spectator, post-destroyAll relic event); silent return; no mutation; no log output.
- [ ] CSM `CountChanged` subscription is added to `_janitor` in `createAll` (story-001's Janitor). Disposed automatically in `destroyAll`.
- [ ] Subscription handler signature matches CSM-side fire: `function(crowdId: string, oldCount: number, newCount: number, deltaSource: string): ()` (per CSM story-002 AC-24 payload).
- [ ] F1 implementation:
  ```lua
  local function _onCountChanged(crowdId: string, oldCount: number, newCount: number, deltaSource: string): ()
      local record = _crowds[crowdId]
      if record == nil then return end  -- AC-8 silent guard
      if newCount > record.peakCount then  -- strict `>`
          record.peakCount = newCount
          record.peakTimestamp = os.clock()
      end
      record.finalCount = newCount  -- always track latest
  end
  ```
- [ ] Subscription wire-up inside `createAll` body (story-001 extension):
  ```lua
  _janitor:Add(CrowdStateServer.CountChanged.Event:Connect(_onCountChanged), "Disconnect")
  ```
  (Roblox `BindableEvent.Event` is the `RBXScriptSignal`.)

---

## Implementation Notes

- F1 strict `>` rule per manifest L102 — equal counts intentionally do NOT update peakTimestamp. Tiebreak preference goes to the EARLIER timestamp; updating on equal would erase the original peak's recency.
- `finalCount` is the simpler companion field — tracks every count change regardless of peak comparison. Used by getPlacements F3 for ranking.
- AC-8 signal guard: post-`destroyAll`, the Janitor cleared the subscription so this code shouldn't even fire. The guard is defensive against race: if `destroyAll` fires `_crowds = {}` BEFORE `_janitor:Destroy()` (story-001 contract: Janitor first, but defensive anyway). Silent return — no log spam.
- `_onCountChanged` must NOT yield (it runs inside CSM's Phase 5 stateEvaluate or other tick context). Pure synchronous. `os.clock()` is non-yielding.

---

## Out of Scope

- story-001: createAll Janitor allocation (this story extends body)
- story-003: Eliminated subscription + eliminationTime
- story-004: setWinner / getPeakTimestamp
- story-005: getPlacements F3 sort consumes peakCount/peakTimestamp set here

---

## QA Test Cases

- **AC-5**: Fixture creates record w/ `peakCount=10, peakTimestamp=tA`. Mock `os.clock` returns tB. Fire CountChanged(id, 15, 10, "Absorb"). Assert peakCount=15, peakTimestamp=tB, finalCount=15. Edge: tB > tA always.
- **AC-6**: Record at `peakCount=300, peakTimestamp=tA, finalCount=250`. Fire CountChanged(id, 300, 250, "Absorb"). Assert peakCount=300, peakTimestamp=tA UNCHANGED, finalCount=300. Edge: same value never updates timestamp.
- **AC-7**: Record at `peakCount=300, peakTimestamp=tA, finalCount=300`. Fire CountChanged(id, 250, 300, "Collision"). Assert peakCount=300, peakTimestamp=tA, finalCount=250.
- **AC-8**: Fire CountChanged("nonexistent", 50, 49, "Absorb"). Assert no error, no log line, `_crowds` unchanged.
- **Subscription cleanup**: createAll → fire CountChanged → handler runs. destroyAll. fire CountChanged again → handler does NOT run (Janitor disconnected). Verify via spy.
- **Multiple records**: 3 records. Fire CountChanged for each in sequence. Each updates own record only. Edge: cross-contamination zero.

---

## Test Evidence

`tests/unit/round-lifecycle/peak_tracking_f1.spec.luau` (AC-5/6/7) + `tests/unit/round-lifecycle/signal_guard.spec.luau` (AC-8) + `tests/unit/round-lifecycle/subscription_lifecycle.spec.luau`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (createAll Janitor + `_crowds` aux); CSM story-002 (CountChanged BindableEvent fires from updateCount)
- Unlocks: story-005 (getPlacements consumes peakCount/peakTimestamp)

---

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: AC-5 (strict > peak update), AC-6 (equal no-op), AC-7 (below peak preserves; final tracks), AC-8 (silent guard non-record), subscription cleanup post-destroyAll, multi-record isolation. 6 it blocks.
**Test result**: 278/0/0 headless (+6 from 3-10)
**Files modified**: src/ServerStorage/Source/RoundLifecycle/init.luau (+CountChanged in CSMDependency type + forward-declared _onCountChanged + Janitor-tracked CountChanged subscription in createAll + F1 strict > peak update + finalCount-always-tracks).
**Test files created**: tests/unit/round-lifecycle/peak_tracking_f1.spec.luau
**Deviations**: None.
**Lint**: selene 0/0
