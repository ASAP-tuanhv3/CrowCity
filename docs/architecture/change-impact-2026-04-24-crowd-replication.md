# Change Impact Report — Crowd Replication Strategy GDD

**Date:** 2026-04-24
**Source GDD:** `design/gdd/crowd-replication-strategy.md` (new, authored 2026-04-24)
**Triggered by:** `/propagate-design-change`
**Review mode:** lean (TD-CHANGE-IMPACT skipped)

---

## Change Summary

Crowd Replication Strategy GDD is the new design-facing contract document for the networking layer. ADR-0001 (Crowd Replication Strategy, Proposed 2026-04-20) already owns architecture; the new GDD codifies 15 Core Rules, 4 formulas, a 3-phase transport machine, 20 edge cases, 12 tuning knobs, and 27 ACs.

The GDD flags 3 amendments it requests of ADR-0001 (§Dependencies + §Open Questions) plus 1 amendment of CSM GDD. During impact analysis, 2 additional payload-scope conflicts between the new GDD and CSM §G were discovered, bringing total edits to 5.

---

## Amendments Applied

### ADR-0001 amendments (3 flagged + 2 design-diagram updates + 1 GDD-citation addition = 6 edits)

1. **Payload spec amendment — §Key Interfaces** (code block)
   - Added `tick: uint16` field (Rule 6 out-of-order defense)
   - Added `state: uint8 enum {Active=1, GraceWindow=2, Eliminated=3}` (Rule 9 + Rule 13)
   - Specified Luau `buffer` encoding MANDATORY for MVP (Rule 10)
   - New per-entry layout (30 bytes buffer-encoded): `crowdId uint64 | tick uint16 | pos Vec3[3×f32] | radius f32 | count uint16 | hue uint8 | state uint8`

2. **Architecture diagram refresh** — broadcast block
   - Updated payload depiction to show new fields
   - Updated steady-state bandwidth estimate: ~40B/~7 KB/s → ~30B/~5.4 KB/s (buffer format)

3. **Performance Implications — §Network line**
   - Revised steady-state figure ~7 KB/s → ~5.4 KB/s with amendment rationale

4. **Consequences — Negative + Risks**
   - Added "No mid-round join state sync" acknowledgment (Rule 6 `CrowdStateSnapshot` gap; MVP-blocked)
   - Risk 3 updated: `tick: uint16` defends against packet reorder
   - Risk 4 promoted medium → RESOLVED in design; buffer mandate fixes byte budget

5. **GDD Requirements Addressed table** — 4 new rows
   - Rule 6 → tick counter
   - Rule 9 + Rule 13 → state enum incl. Eliminated
   - Rule 10 → buffer mandate
   - §C Consumer Contract → 15-rule codification

6. **Status header**
   - Date range: `2026-04-20 (initial), 2026-04-24 (amendment)`
   - Amendment summary appended

### CSM GDD amendments (2 edits)

1. **§G Network event contract — L118** (extensive rewrite)
   - `CrowdStateBroadcast` payload updated: buffer encoding mandatory; `tick` + `state` full enum; `hue` now carried in broadcast (not join-event-only)
   - `state` scope extended: `Active/GraceWindow only` → full enum incl. `Eliminated`; eliminated crowds continue broadcasting until `destroyAll`
   - `hue` delivery: superseded from "join event only" to "broadcast every tick"
   - Added server-side `tick` write spec + client-side `lastReceivedTick` defense via F4 (`tick_is_newer`)
   - `CrowdEliminated` reliable event: clarified role as presentation trigger + cross-channel ordering redundancy (no longer sole elimination-state source)
   - `CrowdJoined` reliable: hue removed; retained for lifecycle signaling

2. **Status header**
   - Added "2026-04-24 amendment — §G network event contract updated"
   - `Last Updated`: 2026-04-21 → 2026-04-24

---

## Conflicts Discovered During Propagation

Two additional conflicts NOT flagged by the new GDD surfaced during impact analysis (CSM §G vs CRS Rule 9):

### 🔴 Conflict A — `hue` in broadcast
- **CSM §G (original)**: hue via `CrowdJoined` reliable event only
- **CRS Rule 9**: hue in broadcast payload
- **Resolution**: CRS wins (user confirmed). CSM §G amended.

### 🔴 Conflict B — `state` field scope
- **CSM §G (original)**: state field Active/GraceWindow only; Eliminated via separate reliable event
- **CRS Rule 9 + Rule 13**: state enum incl. Eliminated=3; eliminated crowds broadcast until destroyAll
- **Resolution**: CRS wins (user confirmed). CSM §G amended.

Both resolutions simplify client cross-channel ordering burden (Rule 4 defensive rule easier to enforce with state in broadcast).

---

## ADRs Affected by This Change

| ADR | Status before | Status after | Action taken |
|---|---|---|---|
| ADR-0001 Crowd Replication Strategy | Proposed 2026-04-20 | Proposed (amended 2026-04-24) | Updated in place (§Key Interfaces, diagram, Performance, Consequences, GDD Reqs, Status) |

No other ADRs exist yet.

## GDDs Affected

| GDD | Change type | Action |
|---|---|---|
| design/gdd/crowd-state-manager.md | Network contract amendment (§G) | Updated in place |
| design/gdd/crowd-replication-strategy.md | Source (unchanged by this propagation) | — |

---

## Pre-existing Conflicts NOT Resolved This Pass

These were identified by prior `/consistency-check` runs; out of scope for this propagation but captured here for traceability:

1. **`CROWD_START_COUNT` 10 vs 20 patch** — NPC Spawner proposes patch; CSM not yet amended; Chest / CCR / Round Lifecycle still use 10. Needs design decision before next propagation.
2. **`radius_from_count` output range stale in CCR §F1 + Absorb §D variable tables** — Relic System's 2026-04-23 registry amendment didn't cascade. Needs separate `/propagate-design-change design/gdd/relic-system.md` pass.

---

## Validation

- [x] ADR-0001 file parse check — all 6 edits applied, no syntax corruption
- [x] CSM §G parse check — amendment consistent with existing §H formulas (F1 radius, F2 position_lag unchanged)
- [x] No consumer GDD (Absorb, CCR, Chest, Relic, HUD, Nameplate, VFX, Follower Entity, Follower LOD Manager) requires edit — all consume CSM client cache, not the raw broadcast payload
- [x] Byte budget rationalized: table ~75B (reality check by gameplay-programmer) → buffer 30B (mandated)
- [x] Late-join gap documented in both ADR (Negative consequence) and CRS §Open Questions OQ #4

---

## Follow-up Actions

1. **`/architecture-review`** recommended before ADR-0001 moves Proposed → Accepted. Gate: validate amendment coherence against traceability matrix.
2. **CSM GDD `/design-review`** re-run in fresh session — §G amendment material enough to warrant re-review.
3. **`/propagate-design-change design/gdd/relic-system.md`** — clears radius_from_count range stale conflict (CCR + Absorb).
4. **Design decision on CROWD_START_COUNT 10 vs 20** — NPC Spawner blocks on this.
5. **Prototype validation** flagged OQ #8 (CRS): `buffer` encode/decode perf on mobile — 1-sprint task before ADR Accepted.
6. **Multi-client bandwidth test** (ADR Risk 4, CRS AC-14/AC-15) — first multi-client integration sprint.

---

*Document written by `/propagate-design-change` — main-session edits applied directly (skill's GDD→ADR flow didn't fit; new-GDD-requests-ADR-amendment path used instead).*
