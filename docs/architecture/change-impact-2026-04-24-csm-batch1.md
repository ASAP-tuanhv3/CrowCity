# Change Impact Report — Crowd State Manager Batch 1 Amendment

**Date:** 2026-04-24
**Changed GDD:** `design/gdd/crowd-state-manager.md`
**Trigger:** `/review-all-gdds` 2026-04-24 FAIL verdict — Batch 1 flagged 9 missing signals/fields/APIs blocking 7 downstream GDDs
**Related prior impact doc:** `docs/architecture/change-impact-2026-04-24-crowd-replication.md` (ADR-0001 + CSM §Network amendment for buffer mandate)

---

## 1. Change Summary

### Fields added to `CrowdRecord`
| Field | Type | Default | Mutator | Purpose |
|---|---|---|---|---|
| `radiusMultiplier` | f32 | 1.0 | `recomputeRadius()` | Relic composition on F1 radius (Wingspan μ=1.35, future μ=0.5 shrink relics) |
| `tick` | uint16 | 0 | broadcast tick | Already broadcast; now explicit record field |
| `stillOverlapping` | bool | false | `setStillOverlapping()` | CollisionResolver signals GraceWindow timer evaluation input |
| `timer_start` | float? | nil | state machine | GraceWindow entry timestamp (was implicit; now explicit) |
| `state` enum | enum | Active | state machine | {Active, GraceWindow, Eliminated}; already broadcast |

### Formula change
- **F1 pre-Batch-1:** `radius = 2.5 + sqrt(count) * 0.55`
- **F1 post-Batch-1:** `radius_base(count) = 2.5 + sqrt(count) * 0.55`; `radius(count, μ) = radius_base(count) * radiusMultiplier`
- **Output range change:** Base [3.05, 12.03] → composed [1.53, 24.06] full range; MVP [3.05, 16.24] at μ_max=1.35.

### APIs added
- `recomputeRadius(crowdId, newMultiplier: f32)` — RelicEffectHandler only. Writes `radiusMultiplier` (validated [0.5, 2.0] in original Batch 1; **subsequently corrected to [0.5, 1.5] same-session during `/consistency-check` Fix A** to align with registry `RADIUS_MULTIPLIER_MAX` hard ceiling). Idempotent.
- `getAllActive(): {CrowdRecord}` — CollisionResolver. All records in `Active` ∪ `GraceWindow`, excludes `Eliminated`.
- `getAllCrowdPositions(): {[crowdId]: Vector3}` — NPCSpawner. Snapshot map for min-distance respawn gate.
- `setStillOverlapping(crowdId, flag: bool)` — CollisionResolver only. Last-write-wins per tick.
- `create(crowdId, initial)` + `destroy(crowdId)` — formalized as named lifecycle APIs (previously implicit in §Interactions).

### Signals added
| Signal | Channel | Payload | Consumers |
|---|---|---|---|
| `CrowdCreated` | Reliable RemoteEvent | `{crowdId, hue, initialCount}` | Player Nameplate, HUD leaderboard |
| `CrowdDestroyed` | Reliable RemoteEvent | `{crowdId}` | Chest (draft modal close), Relic (unhook), HUD, Nameplate (billboard destroy) |
| `CrowdCountClamped` | Reliable RemoteEvent (local-filtered) | `{crowdId, attemptedDelta, clampedCount}` | HUD (MAX CROWD flash — debounce in HUD) |
| `CountChanged` | BindableEvent (server-only) | `{crowdId, oldCount, newCount, deltaSource}` | Round Lifecycle (peakCount + placement), analytics |

### Renames
- `CrowdJoined` → `CrowdCreated` (semantic clarity; pairs with `CrowdDestroyed`).

### Acceptance criteria added
AC-21 through AC-28 — 8 new ACs covering radiusMultiplier composition, recomputeRadius contract, signal firing semantics, API contracts.

### Unchanged
- Server-authoritative hitbox-only decision (ADR-0001 core)
- 15 Hz broadcast tick rate
- Buffer encoding mandate (CRS Rule 10)
- LOD tier structure (Near/Mid/Far)
- F2-F7 formulas
- State machine topology (3 states, 6 transitions)
- Tuning knobs defaults

---

## 2. Loaded Architecture Inputs

- **ADRs loaded:** 1 (adr-0001-crowd-replication-strategy.md)
- **ADRs referencing CSM:** 1 (ADR-0001)
- **Traceability index:** not yet created (no `architecture-traceability.md`)

---

## 3. Impact Analysis — ADR-0001

### Classification: ⚠️ Needs Review → **Updated in place (this document)**

**What ADR-0001 assumed (pre-Batch-1):**
- `CrowdState` record: `{id, position, radius, count, hue, activeRelics}` — 6 fields
- `radius` derivation: `2.5 + sqrt(count) * 0.55` — no multiplier
- CSM API surface: 3 methods (`get`, `updateCount`, `updatePosition`)
- Reliable events: single `RemoteEvents.GameplayEvent` with `eventType` discriminator

**What CSM now says (post-Batch-1):**
- `CrowdState` record: 11 fields (+ `radiusMultiplier`, `state`, `tick`, `stillOverlapping`, `timer_start`)
- `radius` derivation: composed `radius_base * radiusMultiplier`
- CSM API surface: 8 methods (+ `create`, `destroy`, `recomputeRadius`, `getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`; `updatePosition` removed — never existed in CSM)
- Reliable events: 5 distinct named RemoteEvents + 1 server-only BindableEvent

**Assessment:** Core architectural decision (server-authoritative hitbox-only, 15 Hz broadcast, client-side visual-only followers, 3-tier LOD, no Humanoid) is unchanged. Batch 1 refines the consumer interface without challenging the model. The only risk was ADR-0001's illustration blocks (code snippets + diagram) drifting from CSM and misleading future readers.

**Resolution:** Updated in place. 5 edits applied to ADR-0001:
1. Status header — 2026-04-24 Batch 1 amendment note appended
2. Architecture diagram — crowd state shape updated with `radiusMultiplier`, `state`, `tick`, `(composed)` radius note
3. Gameplay events block — replaced `GameplayEvent` discriminator with 5 named reliable events + server-only BindableEvent reference
4. `CrowdState` type + API surface — full refresh (11 fields, 8 methods, caller restrictions in line comments)
5. GDD Requirements Addressed table — +1 row linking Batch 1 amendment to refreshed interfaces

**Not Likely Superseded** — ADR-0001's Decision, Alternatives, Consequences, Risks, Validation Criteria all remain valid.

---

## 4. Downstream GDDs Unblocked

Batch 1 CSM amendments resolve the following dependency asymmetries from `/review-all-gdds` 2026-04-24 report:

| GDD | Amendment consumed | Unblocked |
|---|---|---|
| `relic-system.md` | `radiusMultiplier` field + `recomputeRadius()` API (DA-11) | ✓ Wingspan implementation path defined |
| `player-nameplate.md` | `CrowdCreated` signal (DA-6) | ✓ Billboard bind lifecycle defined |
| `hud.md` | `CrowdCountClamped` signal (DA-5) | ✓ MAX CROWD flash contract defined (debounce owned by HUD) |
| `round-lifecycle.md` | `CountChanged` BindableEvent (DA-7) | ✓ peakCount tracking source defined |
| `chest-system.md` / `relic-system.md` | `CrowdDestroyed` signal (DA-8) | ✓ UI cleanup hook defined; distinct from `CrowdEliminated` |
| `crowd-collision-resolution.md` | `getAllActive()` + `setStillOverlapping()` (DA-4) | ✓ Overlap scan + grace-timer handshake defined |
| `npc-spawner.md` | `getAllCrowdPositions()` (DA-3) | ✓ Min-distance respawn gate source defined |

7 downstream GDDs unblocked in a single pass.

---

## 5. Remaining Blockers (not covered by Batch 1)

The `/review-all-gdds` 2026-04-24 report identifies these as separate batches — **not** resolved by Batch 1:

### Batch 2 — Radius range + density propagation
- Propagate composed radius range [1.53, 24.06] to Absorb F1-F4 + CCR F1 variable tables (currently stale at [3.05, 12.03])
- Propagate ρ rename (ρ_neutral → ρ_design) to Absorb; repair F4 Pillar 5 table at ρ=0.075 (currently stale ρ=0.05)
- Fix NPC pool text "200" → 300; Follower Entity `collision_transfer_per_tick = 2` → [1,4]
- CCR AC-17 perf budget 1200 → 3600

### Batch 3 — LOD tier / tuning ownership
- Reconcile LOD tier 2 cap 3-way mismatch (Follower Entity / Follower LOD Manager / CRS)
- Declare Follower LOD Manager sole owner of render caps + LOD distances

### Batch 4 — Chest + Relic + MSM contracts
- Chest `crowdState == Active` guard
- Chest draft modal close-on-opener-elimination hook (consumes `CrowdEliminated`)
- MSM / TickOrchestrator explicit handler order: CCR → CSM elim → MSM timer → T7 winner

### Batch 5 — Design decisions (blocking)
- Wingspan μ cap vs `NPC_RESPAWN_MIN_CROWD_DIST` numerical value (FLAG-1)
- T1 toll scaling rule (FLAG-2 DSN-B-2)
- Placement rule: peakCount weighting vs passivity penalty (FLAG-3 DSN-B-3)
- Grace-window rescue math at late-round density (DSN-B-MATH)

### Batch 6 — UI + VFX polish
- HUD `CrowdCountClamped` debounce implementation (contract defined in Batch 1; implementation is HUD's scope)
- VFX AbsorbSnap per-tick particle cap arithmetic

### Batch 7 — Pillar 4 coverage
- Promote Skin System to MVP OR document anti-pay-to-win guard elsewhere

---

## 6. Follow-Up Actions

1. **Run `/consistency-check`** — verify Batch 1 amendments did not introduce new registry conflicts.
2. **Run `/propagate-design-change` on `design/gdd/relic-system.md`** — Batch 2 cascade for radius range propagation (composed [1.53, 24.06]).
3. **Re-run `/review-all-gdds`** — after Batches 1–4 complete, to verify blocking consistency issues cleared.
4. **Do NOT run `/create-architecture` yet** — pre-production gate requires all blocking items resolved; Batch 5 design decisions still open.

---

## 7. Sign-off

**Applied by:** /propagate-design-change skill (2026-04-24)
**Reviewed by:** user (per-edit approval)
**ADR-0001 status:** Still Proposed (not promoted to Accepted — awaits `/architecture-review` + resolution of remaining Batch 2–5 blockers)
