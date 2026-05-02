# Story 004: F1 composed radius + recomputeRadius write contract

> **Epic**: crowd-state-server
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/crowd-state-manager.md` §Formulas/F1 + §Server API radius composition table
**Requirement**: `TR-csm-010` (radius composition), `TR-csm-024` (radius range), `TR-csm-021` (Key Interfaces hitbox), Relic-system cross-ref via `recomputeRadius` API
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 §Key Interfaces (`radius = radius_base(count) * radiusMultiplier`, `radiusMultiplier ∈ [0.5, 1.5]`); ADR-0004 §Write-Access Matrix (`recomputeRadius` sole caller = RelicEffectHandler).
**ADR Decision Summary**: F1 radius is composed of two independently-mutable parts: (a) `radius_base(count) = 2.5 + sqrt(count) * 0.55` driven by count writes; (b) `radiusMultiplier ∈ [0.5, 1.5]` driven by RelicEffectHandler via `recomputeRadius`. Both feed the broadcast `radius` field, which is ALWAYS the pre-composed product. Clients consume as-is.

**Engine**: Roblox (engine-ref pinned 2026-04-20) | **Risk**: LOW
**Engine Notes**: `math.sqrt` (LOW); `assert` (LOW). Pure math.

**Control Manifest Rules (Core layer)**:
- Required: Composed radius formula `radius = (2.5 + sqrt(count) * 0.55) * radiusMultiplier` (manifest L79); `recomputeRadius` sole caller RelicEffectHandler with `newMultiplier ∈ [0.5, 1.5]` asserted (L72).
- Forbidden: Cosmetic systems must NEVER mutate `radiusMultiplier` (manifest L135 Pillar 4).

---

## Acceptance Criteria

*From GDD §Acceptance Criteria scoped to this story:*

- [ ] **AC-21 (radiusMultiplier composition, F1)** — Crowd at `count=100` and `radiusMultiplier=1.35` (Wingspan active); next 15 Hz broadcast fires; broadcast `radius` field == `(2.5 + sqrt(100) * 0.55) * 1.35 = 10.80` studs (within ±0.001 floating-point tolerance); `CrowdStateClient.get(crowdId).radius` reflects `10.80` within one broadcast interval (≤67 ms). **Note**: client-side propagation is verified in story-008 (broadcastAll integration); this story validates the SERVER-SIDE radius composition only.
- [ ] **AC-22 (recomputeRadius write contract)** — Crowd with `radiusMultiplier=1.0`; `RelicEffectHandler` calls `CrowdStateServer.recomputeRadius(crowdId, 1.35)`; `radiusMultiplier` field set to `1.35`, next broadcast carries new composed `radius`. Second call with `1.35` (same value) is a no-op (no broadcast dirty flag set; idempotent). Call with `newMultiplier=1.8` (outside [0.5, 1.5]) → REJECTED, value unchanged, assertion logged.
- [ ] **AC-16 (radius portion)** — 8-player fresh match; after `createAll()`, every crowd has `radius = 2.5 + sqrt(10) * 0.55 ≈ 4.24` studs (count=10, multiplier=1.0 default).
- [ ] `recomputeRadius(crowdId, newMultiplier)` signature matches architecture.md §5.1 L537: returns the post-composed radius (number).
- [ ] CSM exposes a private `_recomposeRadius(record): number` helper that recomputes the `radius` field from `record.count` and `record.radiusMultiplier`. Called from: (a) `updateCount` (story-002) after count changes, before fire; (b) `recomputeRadius` after multiplier change.
- [ ] `recomputeRadius` validates `newMultiplier ∈ [0.5, 1.5]` per registry `RADIUS_MULTIPLIER_MAX`. Out-of-range path: `warn` log + return current radius unchanged (do NOT crash — relic system may pass bad values via misconfiguration; CSM degrades gracefully).
- [ ] `recomputeRadius` is idempotent — same multiplier value as current → no-op (no `radius` field write, no broadcast dirty flag); per AC-22 invariant.
- [ ] `radius_base` initial assignment in `create()` uses `count` and `radiusMultiplier=1.0` (from `initial.radiusMultiplier` default per record schema).

---

## Implementation Notes

*Derived from ADR-0001 §Key Interfaces L213 + GDD F1 + manifest L79:*

- F1 implementation:
  ```lua
  local function _recomposeRadius(record: CrowdRecord): number
      record.radius = (2.5 + math.sqrt(record.count) * 0.55) * record.radiusMultiplier
      return record.radius
  end
  ```
- Wire `_recomposeRadius` invocation:
  - In `create` (story-001): after `_crowds[crowdId] = initial`, call `_recomposeRadius(record)` once before returning.
  - In `updateCount` (story-002): after F5 clamp, if `effective_delta != 0`, call `_recomposeRadius(record)` so the broadcast (story-008) reads the freshly-composed `radius`.
  - In `recomputeRadius` (this story): after assigning new multiplier, call `_recomposeRadius(record)`.
- `recomputeRadius` body:
  ```lua
  function CrowdStateServer.recomputeRadius(crowdId: string, newMultiplier: number): number
      local record = _crowds[crowdId]
      assert(record ~= nil, "CrowdStateServer.recomputeRadius: record absent for " .. crowdId)
      if newMultiplier < 0.5 or newMultiplier > 1.5 then
          warn(string.format("CrowdStateServer.recomputeRadius: multiplier %.3f out of [0.5, 1.5] — rejected", newMultiplier))
          return record.radius
      end
      if record.radiusMultiplier == newMultiplier then
          return record.radius  -- idempotent no-op
      end
      record.radiusMultiplier = newMultiplier
      return _recomposeRadius(record)
  end
  ```
- Floating-point comparison `radiusMultiplier == newMultiplier` is acceptable here because relic specs pass deterministic constant values (1.0, 1.35, 0.85, etc.); no accumulated FP drift.
- Broadcast dirty flag — story-008 owns the actual dirty-flag mechanism (if implemented; alternative is "always broadcast every tick"). For the AC-22 idempotence test: validate that `radiusMultiplier` and `radius` field values DO NOT change on a no-op call. The "no broadcast dirty flag set" wording in AC-22 is satisfied as long as no field is written when value is identical.
- `radius_base` MVP range: `[3.05, 12.03]` studs (count=1 → 2.5 + 0.55 = 3.05; count=300 → 2.5 + sqrt(300)*0.55 ≈ 12.03). Composed range with multiplier `[0.5, 1.5]`: `[1.53, 18.04]`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **story-002**: `updateCount` already calls `_recomposeRadius` after a count write — that line is added in story-002 OR in this story's wire-up section (decision: this story owns the helper definition; story-002 owns the call site addition. Test fixtures in this story stub the call site).
- **story-008**: `broadcastAll` reads `record.radius` and packs into buffer payload (the `radius f32` byte at offset 22 per arch §5.7). Multi-client client-side `radius` reflection covered there.
- **RelicSystem epic**: Wingspan / Surge / TollBreaker relic specs that CALL `recomputeRadius` with their multipliers.
- **Hue / activeRelics**: story-003.
- **Position lag**: story-005.

---

## QA Test Cases

*Logic story — automated test specs.*

- **AC-21**: Create record `count=100, radiusMultiplier=1.0`; `_crowds[id].radius ≈ 8.00` (2.5 + 10*0.55 = 8.00). Set `_crowds[id].radiusMultiplier = 1.35` then `_recomposeRadius(record)`; assert `_crowds[id].radius ≈ 10.80` ± 0.001. Edge cases: count=300, μ=1.5 → ≈ 18.04; count=1, μ=0.5 → ≈ 1.525.

- **AC-22 (happy path)**: Record at `radiusMultiplier=1.0, count=100, radius=8.00`. `recomputeRadius(id, 1.35)` → returns ≈ 10.80; `_crowds[id].radiusMultiplier == 1.35`. Subsequent `recomputeRadius(id, 1.35)` → returns ≈ 10.80; no field change. Test: capture `record.radius` and `record.radiusMultiplier` before/after; assert identical.

- **AC-22 (range assert)**: `recomputeRadius(id, 1.8)` → returns prior radius unchanged; `record.radiusMultiplier` unchanged at 1.35; one `warn` log line emitted with substring "out of [0.5, 1.5]". Edge cases: `recomputeRadius(id, 0.4)` → rejected; `recomputeRadius(id, 0.5)` → accepted (boundary OK); `recomputeRadius(id, 1.5)` → accepted (boundary OK).

- **AC-16 (radius portion)**: 8-player fixture; `createAll()`; for each crowd assert `_crowds[id].radius ≈ 4.24` (2.5 + sqrt(10)*0.55 ≈ 4.239). Tolerance ± 0.005.

- **`_recomposeRadius` integration with updateCount**: Record at `count=10, μ=1.0, radius=4.24`. `updateCount(id, +90, "Absorb")` → count=100; assert post-call `radius ≈ 8.00`. Edge cases: `updateCount` clamp at 300 → radius ≈ 12.03 (count=300, μ=1.0); subsequent same-tick `updateCount(+1, "Absorb")` clamp no-op → radius unchanged at 12.03.

- **`recomputeRadius` on absent record**: `recomputeRadius("nonexistent", 1.35)` → `pcall` fails (assert).

- **Pillar 4 cosmetic-cannot-mutate (negative test)**: grep `recomputeRadius` callers in repo — only `RelicEffectHandler` / `RelicSystem` callers permitted; any Skin / Avatar / cosmetic system call is a code-review violation. Audit: `grep -rn "recomputeRadius" src/` should show only RelicSystem call sites (post-RelicSystem epic shipping).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/crowd-state-server/radius_compose.spec.luau` (F1 math + range) + `tests/unit/crowd-state-server/recompute_radius.spec.luau` (write contract + idempotence + range assert).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: story-001 (record schema + create), story-002 (updateCount integration with _recomposeRadius)
- Unlocks: story-008 (broadcastAll reads composed radius); RelicSystem epic (Wingspan / TollBreaker / Surge relic specs)

---

## Completion Notes
**Completed**: 2026-05-02
**Criteria**: 8/8 passing
**Test result**: 206/0/0 headless (+19 from 3-3)
**Files modified**: src/ServerStorage/Source/CrowdStateServer/init.luau (+RADIUS_BASE_OFFSET/SCALE + RADIUS_MULTIPLIER_MIN/MAX constants + _recomposeRadius private helper + recomputeRadius public API + wire into create + updateCount)
**Test files created**: tests/unit/crowd-state-server/radius_compose.spec.luau + recompute_radius.spec.luau
**Deviations**: None
**Lint**: selene 0/0
