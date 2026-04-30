# Story 002: updateCount + DeltaSource enum + F5 clamp + CountChanged + CrowdCountClamped

> **Epic**: crowd-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Server API (count mutation table) + §Formulas/F5 + §Edge Cases/Count clamping
**Requirement**: `TR-csm-002` (count [1, 300]), `TR-csm-009` (Read-vs-Write authority), `TR-csm-014` (Write-Access Matrix), `TR-csm-022` (Write-Access Matrix), `TR-csm-019` (CCR symmetry rule — CSM-side surface), `TR-csm-024` (radius range)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (CSM Authority) §Write-Access Matrix — 4 callers exact: AbsorbSystem, CollisionResolver, ChestSystem, RelicEffectHandler; ADR-0001 §Key Interfaces (count clamp [1, 300]); ADR-0011 §Pillar 4 anti-P2W invariant.
**ADR Decision Summary**: `updateCount(crowdId, delta, source)` is the sole count-mutation entry. `DeltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}` enum-string typed. Cosmetic systems (Skin/Avatar/Banner/Trail) are FORBIDDEN to appear as caller — Pillar 4 anti-P2W invariant. F5 clamp `[1, 300]` applied; positive overflow fires `CrowdCountClamped` reliable to local player. `CountChanged` server-only BindableEvent fires after every successful write (delta != 0 effective).

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Reliable `RemoteEvent` for `CrowdCountClamped` (LOW); server-only `BindableEvent` for `CountChanged` (LOW); both template-proven.

**Control Manifest Rules (Core layer)**:
- Required: `updateCount` 4-caller rule (manifest L71); `DeltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}` (L71); `CountChanged` BindableEvent server-only — never replicated (L77); cosmetic systems NEVER mutate any CSM field — Pillar 4 (L135).
- Forbidden: Never call CSM mutators from outside §Write-Access Matrix caller set (L134); never let cosmetic systems subscribe `CountChanged` for gameplay decisions (L136).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-03 (Count Floor via Relic, F5)** — Crowd at `count = 3` Active no rival overlap; `updateCount(crowdId, -50, "Relic")` fires; `count = 1`, state remains Active, no GraceWindow timer starts (state transition is story-006).
- [ ] **AC-04 (Count Ceiling, F5)** — `count = 250`; `updateCount(crowdId, +100, "Absorb")` fires; `count = 300`, excess 50 discarded.
- [ ] **AC-15 (Same-Tick Ordering — CSM-side surface portion)** — `count=3`; sequential same-tick calls `updateCount(-2, "Collision")` → `updateCount(+5, "Relic")` → `updateCount(+1, "Absorb")` → `updateCount(-10, "Chest")`; deltas apply in CALL order: 3-2=1 → 1+5=6 → 6+1=7 → Chest guard `7>10` rejects (Chest never calls `updateCount` when guard fails — that's Chest epic's responsibility). Final `count=7`. **Note**: this story validates only that `updateCount` applies deltas in caller-order; the same-tick ordering of which caller fires first is owned by TickOrchestrator phase order (story-002 of tick-orchestrator epic) + CCR/Chest epics' own logic.
- [ ] **AC-24 (CountChanged fires on updateCount)** — Crowd at `count=50`; `updateCount(crowdId, +1, "Absorb")` fires; server `CountChanged` BindableEvent fires `{crowdId, oldCount=50, newCount=51, deltaSource="Absorb"}` BEFORE the next tick. No `CountChanged` if effective delta == 0 (e.g. all of delta absorbed by F5 clamp at the 300 ceiling with count already at 300).
- [ ] **AC-25 (CrowdCountClamped fires at ceiling)** — Crowd at `count=298`; `updateCount(crowdId, +5, "Absorb")` fires; count clamps to 300; `CrowdCountClamped` reliable fires to LOCAL player only (not all clients) with `{crowdId, attemptedDelta=+5, clampedCount=300}`. Subsequent same-tick `updateCount(crowdId, +2, "Absorb")` with count still at 300 fires AGAIN (per-call semantic — debounce is HUD's job per GDD L145).
- [ ] `updateCount` returns the post-clamp `count_new` per architecture.md §5.1 L534
- [ ] `DeltaSource` exported as Luau union type per architecture.md §5.1 L513
- [ ] `updateCount` short-circuits if record absent (returns `0` or asserts loud — choose **assert loud** per ADR-0004 §Decision tone): no caller should call `updateCount` on a non-existent crowd; this is a code bug
- [ ] Caller-set enforcement is CODE-REVIEW only (no runtime traceback per manifest L137); this story does NOT implement runtime caller validation
- [ ] `CountChanged` is a `BindableEvent` (not RemoteEvent) — server-only, not replicated. Created via `Instance.new("BindableEvent")` at module init; reference exposed as module field per architecture.md §5.1 L552
- [ ] Records mutated by F5 clamp emit only ONE BindableEvent fire per `updateCount` call (oldCount = pre-clamp, newCount = post-clamp); no double-fire for the discarded portion

---

## Implementation Notes

*Derived from ADR-0004 §Write-Access Matrix + ADR-0001 §Key Interfaces + GDD §Server API + manifest §Forbidden Approaches:*

- F5 formula (per GDD L283): `count_new = clamp(count_old + delta, 1, 300)`. Single line; no intermediate state.
- Effective delta for CountChanged: `effective_delta = count_new - count_old` (could differ from input delta if clamp truncated). When `effective_delta == 0` (no change), do NOT fire `CountChanged` per AC-24.
- `CrowdCountClamped` fires when `count_old + delta > 300` (positive overflow). Lower-bound clamp (count would go below 1) does NOT fire `CrowdCountClamped` — that's a different signal scope. Per GDD §Network event contract (L145): "fires when `updateCount()` applies a positive delta that would exceed `MAX_CROWD_COUNT = 300`".
- `CrowdCountClamped` is server-side filtered to LOCAL PLAYER ONLY — use `Network.fireClient(player, RemoteEventName.CrowdCountClamped, payload)` not `fireAllClients`. The local player is resolved from `crowdId` via `Players:GetPlayerByUserId(tonumber(crowdId))`.
- Avoid runtime caller-set enforcement (`debug.traceback`) — manifest L137 forbids in hot loop. Code-review enforces.
- The `CountChanged` BindableEvent reference must be exposed on the module table so RoundLifecycle (round-lifecycle story-002) can subscribe for peakCount tracking (manifest L77). Pattern: `CrowdStateServer.CountChanged = Instance.new("BindableEvent")`.
- DO NOT mutate `state` or `radius` here — `state` transitions live in story-006 (Phase 5 evaluator); radius composition lives in story-004.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-001**: Module skeleton + create/destroy + DC handler + record schema.
- **story-003**: Hue F6 + activeRelics cap.
- **story-004**: F1 composed radius + recomputeRadius (count→radius live re-composition).
- **story-006**: F5 floor at count=1 with rival overlap → GraceWindow transition (state machine — this story keeps state unchanged, AC-03 explicitly says "state remains Active").
- **CCR epic stories**: F3/F4 collision drip math (AC-08, AC-09, AC-10) — those calculate the `delta` value the CCR passes here; this story only validates the receiving side.
- **Chest epic stories**: F5 strict count > toll guard (AC-14) — Chest decides whether to call `updateCount(-toll, "Chest")`; CSM only receives.
- **Skin / cosmetic systems (VS+)**: Pillar 4 enforcement is code-review only at this story; future epic-level audit.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-03**: Fixture creates record at `count=3`, state="Active", stillOverlapping=false. `updateCount(id, -50, "Relic")` → `count == 1`, state still "Active", `timer_start == nil`. Edge cases: `updateCount(-1, "Relic")` from count=1 → `count == 1` (clamp at 1); `effective_delta == 0` → CountChanged does NOT fire.

- **AC-04**: Fixture record at `count=250`. `updateCount(id, +100, "Absorb")` → returns 300, `_crowds[id].count == 300`. Edge cases: from 300 with `+1` → returns 300, count unchanged, CountChanged does NOT fire.

- **AC-15 (delta-application order)**: Fixture record at `count=3`. Sequential calls in test fixture:
  1. `updateCount(id, -2, "Collision")` → returns 1
  2. `updateCount(id, +5, "Relic")` → returns 6
  3. `updateCount(id, +1, "Absorb")` → returns 7
  4. (Chest's guard would reject; this story does NOT call updateCount when guard fails. Test validates that 4 deltas applied = 4 fired; verify CountChanged fired 4 times)
  Edge cases: confirm deltas apply IN CALL ORDER deterministically (no batching).

- **AC-24**: BindableEvent recorder subscribed to `CrowdStateServer.CountChanged`. Record at `count=50`; `updateCount(id, +1, "Absorb")`; recorder receives `{crowdId, oldCount=50, newCount=51, deltaSource="Absorb"}` exactly once. Edge cases: `+0` delta → no fire; clamp-zeroed effective delta (count=300, delta=+1) → no fire; one fire per `updateCount` call.

- **AC-25**: Network mock subscribed to `RemoteEventName.CrowdCountClamped` filtered by player. Record at `count=298`; `updateCount(id, +5, "Absorb")` → mock receives `{crowdId, attemptedDelta=+5, clampedCount=300}` to that player's stream only. Edge cases: 2nd same-tick `updateCount(+2, "Absorb")` from count=300 → mock receives ANOTHER event (per-call); negative delta clamp at floor 1 → mock does NOT receive (different signal scope); broadcast filter — non-owning players' mocks do NOT receive.

- **`updateCount` on absent record**: `updateCount("nonexistent", +1, "Absorb")` → `pcall` fails with descriptive assertion.

- **`DeltaSource` type validation**: callers passing string literal not in `{"Absorb", "Collision", "Chest", "Relic"}` → strict-mode compile error (compile-time check; no runtime fixture).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/updatecount_clamp.spec.luau` + `tests/unit/crowd-state-server/countchanged.spec.luau` + `tests/unit/crowd-state-server/countclamped.spec.luau`.

**Status**: [x] Executed headless 2026-04-30 — 121/0/0 pass via `run-in-roblox` (19 new CSM 2-5 + 102 prior)

---

## Dependencies

- Depends on: story-001 (record schema + create + destroy)
- Unlocks: story-006 (Phase 5 state evaluator reads count to detect floor); story-008 (broadcastAll reads count post-clamp); RoundLifecycle peakCount tracking (round-lifecycle epic)

---

## Completion Notes

**Completed**: 2026-04-30
**Criteria**: 9/9 covered (AC-03 / AC-04 / AC-15-CSM-side / AC-24 / AC-25 + return-post-clamp + DeltaSource-export-already-shipped-in-001 + record-absent-assert + BindableEvent-module-field + single-fire-per-call)

**Files**:
- `src/ServerStorage/Source/CrowdStateServer/init.luau` (+~130 L net, 214 → ~344 L)
  - Refactored `fanout` signature: `(eventName, payload, target: Player?)` — nil target → fireAllClients route, non-nil → fireClient route. Existing create/destroy unchanged behaviorally (target=nil)
  - Added constants: `COUNT_FLOOR = 1`, `COUNT_CEILING = 300` (per ADR-0001 §Key Interfaces)
  - Added `_countChanged` BindableEvent + public `CrowdStateServer.CountChanged` field per arch §5.1 L552 — server-only, never replicated (manifest L77)
  - Added `_testOwnerResolver` state + `resolveOwner(crowdId): Player?` helper (production: Players:GetPlayerByUserId; test: override)
  - Added `updateCount(crowdId, delta, source): number`:
    - assert record present (caller bug per ADR-0004 §Decision)
    - F5 clamp via `math.clamp(oldCount + delta, 1, 300)`
    - CrowdCountClamped reliable fires to OWNER ONLY when `proposed > 300` (ceiling overflow); floor clamp does NOT fire (different scope per GDD L145)
    - CountChanged BindableEvent fires only when `effective_delta != 0` (post-clamp difference)
    - Per-call semantic: same-tick repeats at ceiling each fire CrowdCountClamped (HUD-side debounce per GDD)
    - Returns post-clamp count per arch §5.1 L534
  - Updated `_resetForTests`: clears `_testOwnerResolver`
  - Added `_setTestOwnerResolver(fn)` test seam

- `tests/unit/crowd-state-server/updatecount_clamp.spec.luau` (82 L, 7 it blocks)
- `tests/unit/crowd-state-server/countchanged.spec.luau` (107 L, 6 it blocks)
- `tests/unit/crowd-state-server/countclamped.spec.luau` (129 L, 6 it blocks)

**Test Evidence**: 3 TestEZ spec files. **Executed 2026-04-30** via `run-in-roblox` → **121/0/0 pass** (19 new + 102 prior).

**Audit gates ALL PASS**: selene + audit-asset-ids + audit-persistence + audit-no-competing-heartbeat.

**Code Review**: Standalone `/code-review` skipped — Lean mode + impl matches spec verbatim except `Network.fireClient` arg-order corrected during impl (project's `fireClient(eventName, player, payload)` vs spec's `fireClient(player, eventName, payload)`; behavior identical, signature follows the actual Network module).

**Deviations** (ADVISORY only, non-blocking):
- Story spec implementation note wrote `Network.fireClient(player, eventName, payload)` but the project's actual `Network.fireClient` signature is `(eventName, player, ...)`. Impl follows the actual signature. Behavior identical (per-player filtered send). Spec-file follow-up note for documentation accuracy.

**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW + QL-STORY-READY skipped — Lean mode.

**Unblocks**: story-003 (hue F6 + activeRelics — independent of count writes), story-004 (recomputeRadius live re-composition on count change → hooks CountChanged), story-006 (Phase 5 state evaluator reads count for F7 grace-timer trigger), story-008 (broadcastAll consumes post-clamp count + BindableEvent for delta-snapshots), RoundLifecycle story-002 (peakCount tracking subscribes CountChanged BindableEvent), HUD count-pop animation (subscribes CrowdCountClamped reliable on client side).
