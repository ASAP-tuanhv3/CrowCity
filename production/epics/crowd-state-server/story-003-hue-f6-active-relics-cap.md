# Story 003: Hue F6 + activeRelics cap

> **Epic**: crowd-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Formulas/F6 + §Server API record schema; art bible §4 (12-hue safe palette)
**Requirement**: `TR-csm-004` (immutable hue), `TR-csm-005` (max 4 activeRelics), `TR-csm-021` (Key Interfaces hue render)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 §Key Interfaces (immutable `hue ∈ [1, 12]`, `activeRelics` max 4); ADR-0004 §Read-vs-Write (hue is read-only post-create).
**ADR Decision Summary**: `hue` assigned at `create` time deterministically per join order using F6 `((join_index - 1) mod 12) + 1`. Immutable post-create — even cosmetic systems (Skin) cannot override (Pillar 4 anti-P2W: hue is not skin-derived). `activeRelics` capped at 4 — 5th grant rejected. CSM exposes a small relic-grant helper used by RelicSystem; the actual relic effect application lives in RelicSystem epic.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: Pure Luau math; no engine API risk.

**Control Manifest Rules (Core layer)**:
- Required: Crowd record fields `hue ∈ [1, 12]` immutable, `activeRelics` max 4 (manifest L78).
- Forbidden: Hue NEVER skin-derived (manifest L135 cosmetic-can't-mutate-CSM); cosmetic systems must read hue via `CrowdStateClient`, never write.

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-05 (Hue Assignment, F6)** — Players join in order 1, 2, 12, 13. Crowd records created with `hue` = 1, 2, 12, 1 respectively (13th recycles via `((13-1) mod 12) + 1 = 1`).
- [ ] **AC-06 (activeRelics cap)** — `activeRelics = {A, B, C, D}` (4 slots full); 5th relic grant attempted via `addActiveRelic(crowdId, "E")` (or whatever the helper name is); grant REJECTED, list still contains exactly 4 entries, no duplicates added, function returns `false` (or similar fail-flag).
- [ ] **AC-16 (Hue + initialCount portion)** — `RoundLifecycle.createAll()` passes `initial.count = 10` and `initial.hue = F6(joinIndex)` into `create()`; assert post-create `_crowds[id].hue` matches expected and `_crowds[id].count == 10`.
- [ ] CSM exposes a `joinIndex` counter or accepts `hue` in `initial` argument — **decision**: accept `hue` in `initial` per architecture.md §5.1 L530 signature `create(crowdId, initial: CrowdRecord)`. The F6 computation lives in RoundLifecycle (which knows join order). **CSM only enforces `hue ∈ [1, 12]` range assertion at create** — out-of-range loud-fails.
- [ ] CSM exposes `addActiveRelic(crowdId: string, specId: string): boolean` — adds `specId` to `activeRelics` if list has < 4 entries AND `specId` not already present; returns `true` on success / `false` on rejection. Caller is `RelicSystem` exclusively (code-review enforced).
- [ ] CSM exposes `removeActiveRelic(crowdId: string, specId: string): boolean` — removes from list if present; returns `true` on success / `false` if absent. Caller is `RelicSystem` (relic expiry path).
- [ ] `activeRelics` field in CrowdRecord is initialised to `{}` in `create` (story-001 already did this, but assert).
- [ ] `hue` field is read-only — CSM module exposes no `setHue` API. Skin System (VS+) reads via `CrowdStateClient`, never writes.

---

## Implementation Notes

*Derived from ADR-0001 §Key Interfaces + GDD F6 + Pillar 4 invariant:*

- F6 formula is a one-liner — implementation lives in `RoundLifecycle.createAll`'s composition step. CSM's role is to receive and validate the `hue` value from the `initial` argument.
- Hue range assertion at `create`: `assert(initial.hue >= 1 and initial.hue <= 12, "CrowdStateServer.create: hue must be in [1, 12], got " .. tostring(initial.hue))`.
- `addActiveRelic` validates: (1) `_crowds[crowdId] ~= nil`; (2) `#record.activeRelics < 4`; (3) `specId` not already in list. On success: `table.insert(record.activeRelics, specId)`. Fires `CrowdRelicChanged` reliable RemoteEvent with `{crowdId, activeRelics}` snapshot per GDD L141 (this story owns the fanout for relic grants).
- `removeActiveRelic` finds + removes; fires `CrowdRelicChanged` snapshot on change.
- `CrowdRelicChanged` payload is the FULL snapshot (not delta) per GDD L141 — simplifies client cache.
- Note: the relic `addActiveRelic` API helper in CSM is a thin list-mutator — the actual relic-effect-handler logic (apply onAcquire / onTick / onExpire callbacks) lives in `RelicSystem`. This story does NOT execute relic callbacks.
- Pillar 4 invariant — Skin System NEVER calls `addActiveRelic` (skins are NOT relics). The 4-caller `updateCount` rule is enforced by code review; the `addActiveRelic` caller-set is similarly RelicSystem-only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-001**: Record schema + create stores `initial.hue` and `initial.activeRelics={}`.
- **story-002**: `updateCount` API.
- **RelicSystem epic**: F6 actually-computed-by-CSM (NO — F6 lives in RoundLifecycle composition). Relic effect application (`onAcquire`, `onTick`, `onExpire`) is RelicSystem epic.
- **RoundLifecycle epic**: F6 invocation at createAll, joinIndex maintenance — RoundLifecycle composes `initial.hue` from join order.
- **Skin System (VS+)**: Hue render via `CrowdStateClient` — Presentation layer concern.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-05**: Fixture invokes `create("u1", {..., hue=1})`, `create("u2", {..., hue=2})`, `create("u3", {..., hue=12})`, `create("u4", {..., hue=1})`. Assert `get("u1").hue == 1`, etc. The F6 wrap-around correctness is RoundLifecycle's responsibility, but this story validates that CSM accepts and stores 1..12 cleanly. Edge cases: `create("u5", {..., hue=0})` → `pcall` fails (out-of-range assert); `create("u6", {..., hue=13})` → `pcall` fails.

- **AC-06**: Create record; `addActiveRelic(id, "A")` → returns `true`, list = {"A"}. Repeat for B/C/D. `addActiveRelic(id, "E")` → returns `false`, list still {"A", "B", "C", "D"}. Edge cases: `addActiveRelic(id, "A")` (duplicate) → returns `false`, no duplicate added; `removeActiveRelic(id, "A")` → returns `true`, list = {"B", "C", "D"}; subsequent `addActiveRelic(id, "E")` → `true` (slot freed).

- **AC-16 (hue + initialCount portion)**: 8-player fixture; `RoundLifecycle.createAll()` invoked; for each crowd assert `hue ∈ [1, 8]` (8 distinct join indices) and `count == 10`. Edge cases: 13-player fixture (over MAX_PARTICIPANTS=12, but for hue test just synthesize) — assert hue at join index 13 = 1 (recycle).

- **`hue` immutability (no setHue API)**: grep `CrowdStateServer.setHue` → zero matches; grep `record.hue =` outside `create` → zero matches.

- **`addActiveRelic` on absent crowd**: `addActiveRelic("nonexistent", "A")` → returns `false` (record absent — fail flag rather than assert; relics may briefly race vs destroy).

- **`CrowdRelicChanged` fires on grant + expire**: Network mock subscribed; `addActiveRelic(id, "A")` → mock receives `{crowdId, activeRelics={"A"}}`; `removeActiveRelic(id, "A")` → mock receives `{crowdId, activeRelics={}}`. Edge cases: grant rejection (cap full) → no event fired.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/hue.spec.luau` + `tests/unit/crowd-state-server/active_relics_cap.spec.luau` + `tests/unit/crowd-state-server/relic_changed_signal.spec.luau`.

**Status**: [x] Created + passing 2026-05-02 (187/0/0 headless)

---

## Dependencies

- Depends on: story-001 (create + record schema)
- Unlocks: story-006 (state evaluator reads `activeRelics` for relic-active info — actually no, state machine doesn't read relics; this is a self-contained API surface); RelicSystem epic (consumes `addActiveRelic` / `removeActiveRelic`); RoundLifecycle (composes `initial.hue` via F6 + joinIndex)

---

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: 8/8 passing (0 deferred)
**Test result**: 187/0/0 headless (run-in-roblox; up from 159 baseline = +28 new)
**Deviations**: ADVISORY — ADR-0004 amended in same scope (Write-Access Matrix +2 rows for addActiveRelic/removeActiveRelic; Pillar 4 forbidden-list extended; Read-vs-Write `activeRelics` row updated). Closes doc gap surfaced by /code-review; no semantic change.
**Test Evidence**: Logic — `tests/unit/crowd-state-server/hue.spec.luau` + `active_relics_cap.spec.luau` + `relic_changed_signal.spec.luau` all PASS.
**Code Review**: Complete (lean mode — manual review). Verdict APPROVED WITH SUGGESTIONS; both suggestions applied (MAX_RELIC_SLOTS constant + ADR-0004 amendment).
**Lint**: selene 0/0 on modified module. audit-no-currency-in-shutdown PASS.
