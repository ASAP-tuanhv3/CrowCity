# Story 010: LOD tier swap F5 + d preservation + teleport snap

> **Epic**: FollowerEntity (Follower Entity — client simulation)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 4h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/follower-entity.md`
**Requirement**: `TR-follower-entity-015` (LOD render caps 80/30/15/1), `TR-follower-entity-006` (d preservation across LOD swap), `TR-follower-entity-016` (TELEPORT_THRESHOLD = 30 stud snap)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 Client Rendering Strategy + ADR-0001 (LOD render caps + tier numbering)
**ADR Decision Summary**: Tier numbering `0/1/2/CULL`. CULL signalled by `setPoolSize(crowdId, 0)`, NOT a fourth tier value. `setLOD(tier)` is dispatched **before** `setPoolSize` on same-tick tier+cap change. LOD swaps are atomic per-Part. F8 walk-bob suppressed at LOD 1+. Per-follower `d` accumulates across tier transitions (NOT reset).

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: pure state machine + Vector math; no post-cutoff API.

**Control Manifest Rules (Presentation layer)**:
- Required: LOD swap at 10 Hz (every 0.1 s); not per-frame
- Forbidden: per-frame LOD swap
- Guardrail: ≤150 rendered Parts per client view

---

## Acceptance Criteria

*From GDD `design/gdd/follower-entity.md`, scoped to this story:*

- [ ] **AC-13 (F5 LOD tiers)**: Given camera distances `[0, 20, 20.1, 40, 40.1, 100, 100.1]`, when tier computed, then `[0, 0, 1, 1, 2, 2, CULL]`. AND when LOD swap fires (e.g., LOD-1 → LOD-0 demote), then `_d` is NOT reset; each follower's per-follower `_d` value carries over; on LOD-0 re-entry follower bobs at its unique phase, NOT at phase 0.
- [ ] **AC-14 (Teleport snap)**: Given player teleports >30 studs in 1 frame (crowd center delta > `TELEPORT_THRESHOLD`), when boids update runs, then followers skip `V_final` interp; CFrame direct to `crowd_center + spawn_offset`. Subsequent frame resumes normal boids.
- [ ] **`setLOD(tier: 0 | 1 | 2)` public API**: stores current tier on `FollowerEntityClient`; per-frame update consults the tier to gate F8/F9 (Story 004) and choose render path.
- [ ] **CULL via `setPoolSize(0)`**: not a separate `setLOD(CULL)` call. LOD Manager calls `setLOD(2)` once at the 40-100 m boundary, then `setPoolSize(0)` at the 100 m boundary.
- [ ] **`setLOD` ordering**: when LOD Manager dispatches both `setLOD(tier)` and `setPoolSize(n)` on same-tick tier+cap change, `setLOD` runs FIRST (per ADR-0007 + LOD GDD AC-LOD-18).
- [ ] **F5 boundary semantics**: tier 0 for `d <= 20`, tier 1 for `20 < d <= 40`, tier 2 for `40 < d <= 100`, CULL for `d > 100`. Non-overlapping; closed-on-the-low-end where applicable.
- [ ] **Teleport detection**: per crowd, track `_lastCrowdCenter[crowdId]`. Each frame, if `(currentCenter - _lastCrowdCenter).Magnitude > TELEPORT_THRESHOLD`, apply CFrame-direct snap for one frame, then resume.
- [ ] **`d` continuity across swaps**: covered in Story 004 (per-follower `_d` array). This story verifies the contract holds when `setLOD(0 → 1 → 0)` swaps fire.
- [ ] **Constants in `SharedConstants/FollowerVisualConfig.luau`**: `TELEPORT_THRESHOLD = 30`. LOD distance boundaries `20, 40, 100` are LOCKED (art bible §5; NOT tuning knobs).

---

## Implementation Notes

*Derived from GDD §F5 + §Edge Cases (player teleport) + ADR-0007 §LOD Tier Render Specs:*

- F5 implementation lives in `FollowerLODManager` (sibling system) — NOT in this epic. This story implements only the receiver: `FollowerEntityClient:setLOD(tier)` + tier-aware per-frame update gating.
- `setLOD(self, tier: 0 | 1 | 2)`:
  ```
  self._tier = tier
  -- pool reassignment to tier-appropriate Part bundle handled here:
  -- LOD 0 → 2-Part Body+Hat from LOD0 pool
  -- LOD 1 → 1-Part simplified primitive from LOD1 pool
  -- LOD 2 → BillboardGui impostor from LOD2 pool (one per crowd)
  -- Returned-to-pool Parts are hidden (Transparency=1, Position=(0,-1000,0)); NOT destroyed
  ```
- `_tier` is read by Story 003 (boids — F4 still runs at LOD 0/1; suppressed at LOD 2 since billboard impostor uses single anchored Part), Story 004 (F8 bob LOD 0 only; F9 sway LOD 0 only), Story 006 (hue writes apply at all tiers).
- LOD 2 → 1 cross-fade and 1 → 2 cross-fade: tween `Transparency` 0→1 / 1→0 over 0.2 s on the leaving and arriving rigs. Per ADR-0007 §Billboard Impostor Render Path.
- Teleport detection: `CrowdManagerClient` (or per-crowd) records `_lastCrowdCenter`. Each frame:
  ```
  local current = CrowdStateClient.get(crowdId).position
  local delta = (current - self._lastCrowdCenter).Magnitude
  if delta > TELEPORT_THRESHOLD then
      -- direct CFrame snap: each follower → current + (followerOffset)
      for i = 1, #self._positions do
          self._positions[i] = current + self._spawnOffsets[i]
          self._parts[i].CFrame = CFrame.new(self._positions[i])
      end
      -- skip boids math for this follower-set this frame
      self._teleportFlag = true
  else
      self._teleportFlag = false
  end
  self._lastCrowdCenter = current
  ```
- `_spawnOffsets[i]` is each follower's offset from crowd_center at spawn (random within radius). Re-using these on teleport gives a clean snap.
- After teleport, next frame resumes boids normally — `_d` is preserved (Story 004), so bob doesn't reset.
- Tier boundary edges (`d == 20`, `d == 40`, `d == 100`) are HANDLED BY LOD Manager, not this story. F5 specification documented here for reference only — actual hysteresis (±1 stud per LOD GDD §F2) lives in LOD Manager epic.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: F4 boids math.
- Story 004: F8/F9 — gated by `_tier` value set here.
- Story 009: `setPoolSize(n)` is the cap-side companion to `setLOD(tier)`. LOD Manager ordering (`setLOD` before `setPoolSize`) is verified there + here.
- LOD Manager epic (deferred Presentation): F5 distance computation, hysteresis, render-cap lookup table, 10 Hz tick.

---

## QA Test Cases

- **AC-13a (F5 boundary distances)**:
  - Given: F5 helper function (or LOD Manager mock) called with distances `[0, 20, 20.1, 40, 40.1, 100, 100.1]`
  - When: tier computed
  - Then: returned tiers `[0, 0, 1, 1, 2, 2, CULL]` exactly
  - Edge cases: negative distance — undefined; not expected from camera math.

- **AC-13b (`d` continuity across LOD swap)**:
  - Given: follower at LOD 0 with `_d[i] = 5.5`; `setLOD(1)` called; 30 frames pass at `d_delta = 0.5/frame`; `setLOD(0)` called
  - When: state inspected
  - Then: `_d[i] == 5.5 + 30 * 0.5 == 20.5`; on LOD 0 re-entry, F8 bob computed against `_d=20.5`; bob phase NOT reset to 0
  - Edge cases: LOD 0 → 2 → 0 also preserves `_d`. (LOD 2 is single billboard, no per-follower bob, but `_d` array continues accumulating for the still-pooled followers awaiting tier change.)

- **AC-14 (Teleport snap)**:
  - Given: 80 followers in crowd; `_lastCrowdCenter = (0,0,0)`; next frame `CrowdStateClient.get` returns position `(50, 0, 0)` (delta 50 > TELEPORT_THRESHOLD=30)
  - When: per-frame update runs
  - Then: every follower's CFrame.Position == `(50,0,0) + _spawnOffsets[i]`; F4 boids NOT applied this frame; `_teleportFlag == true`
  - When: subsequent frame, `currentCenter == (51,0,0)` (delta 1 < 30)
  - Then: F4 boids resumes normally; `_teleportFlag == false`
  - Edge cases: delta exactly == 30 — no snap (`>`, not `>=`); delta == 31 — snap fires.

- **CULL via setPoolSize(0)**:
  - Given: crowd at 80 LOD-2 followers; LOD Manager dispatches `setLOD(2)` followed by `setPoolSize(0)`
  - When: state inspected
  - Then: setLOD(2) reassigns tier; setPoolSize(0) evicts all Active followers (Story 009 path); pool is now 0 followers rendered for this crowd; billboard impostor returned to LOD2 pool
  - Edge cases: peelCount=5 at this moment — `actualN = max(0, 5) = 5`; 5 Peeling retained, no others rendered.

- **setLOD before setPoolSize ordering**:
  - Given: LOD Manager dispatches both calls same frame in order `setLOD(1), setPoolSize(15)`
  - When: state inspected after both
  - Then: `_tier == 1`; pool count of LOD-1 Parts == 15; correct render path used
  - Edge cases: reversed order (`setPoolSize` before `setLOD`) — not produced by spec'd LOD Manager, but defensive: `setPoolSize` operates on the previous tier's Parts; subsequent `setLOD` then swaps. Tolerated but suboptimal; document the intended order.

- **Tier-gated F8 / F9** (cross-check Story 004):
  - Given: follower at LOD 1 moving with `d_delta = 1.0/frame`
  - When: F8 / F9 computed
  - Then: `Body.CFrame == Root_target` (no Y bob, no X sway); `_d` continues accumulating
  - Edge cases: covered fully in Story 004 AC-26.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/follower-entity/lod_swap_teleport_test.luau` — must exist and pass under TestEZ (mock `CrowdStateClient.get`, controlled tier transitions, deterministic `_d` arrays)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (orchestrator), Story 003 (boids — gated by tier), Story 004 (`_d` array continuity), Story 005 (`_spawnOffsets` recorded at spawn), Story 009 (setPoolSize for CULL via 0)
- Unlocks: Story 012 (LOD swap evidence integration test consumes setLOD)
