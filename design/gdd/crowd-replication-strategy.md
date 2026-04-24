# Crowd Replication Strategy

> **Status**: Designed (pending review; 2026-04-24 Batch 3 — render cap + LOD distance ownership transferred to Follower LOD Manager per /review-all-gdds RC-B-NEW-3. This GDD now references those constants only; LOD Manager is authoritative. `FAR_RANGE_MAX` 4 → 1 billboard per crowd reconciled with LOD Manager spec.)
> **Author**: user + systems-designer + gameplay-programmer + creative-director (fantasy framing) + qa-lead (AC validation)
> **Last Updated**: 2026-04-24
> **Implements Pillar**: Pillar 1 (Snowball Dopamine — mass must feel like mass), Pillar 3 (5-Minute Clean Rounds — round purity), Pillar 4 (Cosmetic Expression — skin swap cheap), Pillar 5 (Comeback Always Possible — reliable authoritative state)
> **Review Mode**: lean
> **Architecture**: locked by `docs/architecture/adr-0001-crowd-replication-strategy.md` (Proposed). This GDD codifies the design-facing contract that consumer GDDs reference.
> **Creative Director Review (CD-GDD-ALIGN)**: SKIPPED — lean mode.

## Overview

The **Crowd Replication Strategy** is the foundational networking contract that decouples what the server authoritatively tracks from what every client visually renders. Architecture is locked by **ADR-0001** (`docs/architecture/adr-0001-crowd-replication-strategy.md`); this GDD codifies the design-facing contract: *what gameplay systems read, what they can trust, and what they must tolerate.* Server owns per-player aggregate crowd state `{position, radius, count, hue, activeRelics}` — exactly one record per player, regardless of follower count. Broadcasts fire at `SERVER_TICK_HZ = 15` via `UnreliableRemoteEvent` (`CrowdStateBroadcast`) using Luau `buffer` encoding (mandated by Rule 10). Payload is ~30 bytes per crowd × ≤12 crowds × 15 Hz = ~5.4 KB/s per client steady state, well below the 10 KB/s bandwidth ceiling. (ADR-0001's pre-amendment ~40 bytes / ~7 KB/s estimate assumed table serialization; amendment flagged in §Open Questions.) Discrete gameplay events (absorb, eliminate, chest open, relic grant) travel on a separate reliable `RemoteEvent` (`GameplayEvent`) — never dropped, never out-of-order. Individual follower positions are **purely client-side visual decoration**, computed by boids flocking simulation inside per-client render caps (80 own-close / 30 rival-close / 15 medium / 4 far / cull >100m). Every consumer GDD — Crowd State Manager, Absorb, Collision Resolution, Follower Entity, Follower LOD Manager, Relic, Chest, HUD, Nameplate, VFX Manager — reads from this contract; this GDD is the single place that states the tick cadence, the payload shape, the broadcast semantics, the desync tolerance window, and the design-facing tuning knobs (render caps). Consumer GDDs do not restate these values; they reference this GDD and ADR-0001. Without this contract, every downstream system would invent its own replication assumption, and gameplay math (CSM radius, Absorb overlap, Collision pairEntered) would fragment across client views.

## Player Fantasy

Players never touch this system directly — they touch what it makes possible. The stampede fantasy, the absorb snap, the rival's count looming across the arena: every felt moment inherits its truth from here. When this layer holds, nothing is noticed. When it breaks, players feel the lie instantly — a phantom horde stuttering mid-charge, a rival's 200 count collapsing to 80 on re-sync, an absorb landing where the target *was* a half-second ago.

This is the contract that lets every other fantasy tell the truth.

## Detailed Design

### Core Rules

**1. Authoritative clock.** All server gameplay systems (Absorb overlap, Collision hit detection, CSM broadcast, Chest toll guard, Relic application) run on the 15 Hz server tick owned by `TickOrchestrator`. No gameplay system may poll crowd state at a higher rate on the server. ADR-0001 locks this cadence.

**2. Reliable vs unreliable channel separation.** Discrete state-transitioning events (absorb, eliminate, chest open, relic grant, collision contact, match state change) fire on **reliable `RemoteEvent`**. Continuous crowd aggregate state (`pos`, `radius`, `count`, `hue`, `state`) broadcasts on **unreliable `CrowdStateBroadcast`**. No system may fire a gameplay-consequence event over the unreliable channel, and no system may send continuous per-frame crowd state over the reliable channel.

**3. Broadcast payload is a full snapshot, not a delta.** Each `CrowdStateBroadcast` fire carries the complete current-tick state of all active crowds. Consumers overwrite their cache — never accumulate, never apply deltas. Missed packet = missed frame of updates, not missed state.

**4. No ordering guarantee across channels.** `GameplayEvent` arrival relative to `CrowdStateBroadcast` within the same server tick is NOT guaranteed on clients. Consumers must handle either arrival order without error. The `state` field in the broadcast (Rule 9) and the reliable `CrowdEliminated` event redundantly signal elimination — whichever arrives first wins; subsequent stale broadcasts must NOT un-eliminate a crowd.

**5. Broadcast drop tolerance.** Single dropped `CrowdStateBroadcast` packet is a non-event — client holds last-known state and continues rendering. Sustained drop exceeding `STALE_THRESHOLD_SEC = 0.5s` (7-8 consecutive missed ticks) triggers client-cache freeze: all widgets (HUD, Nameplate, VFX anchors) hold last-known values. No interpolation toward zero, no "unknown" text. Next received broadcast resumes normally.

**6. Out-of-order defense via tick counter.** `CrowdStateBroadcast` payload includes `tick: uint16` (monotonic server tick counter, wraps at 65535 ≈ 72 min at 15 Hz). Clients track `lastReceivedTick`; a payload with `tick ≤ lastReceivedTick` is discarded. Prevents mobile-cluster reorder from overwriting fresher state with stale. **Requires ADR-0001 amendment** (added to payload spec).

**7. Cosmetic desync accepted; aggregate desync not.** Individual follower positions are cosmetic and differ across clients (per-client boids seeds). No system may make a gameplay decision (absorb success, collision drain, chest toll check) based on rendered follower positions. Server's `crowd.position`, `crowd.radius`, `crowd.count` are sole authoritative inputs. Cross-client follower micro-layout variance is expected.

**8. Render-cap decoupling.** Rendered follower Part count is always ≤ authoritative `crowd.count`. Systems that display or react to crowd size (HUD, Nameplate, Chest toll guard) ALWAYS use `crowd.count` from the broadcast — never the rendered Part count. Render caps (80 own-close / 30 rival-close / 15 medium / 4 far / cull > 100m) are visual budget controls, not gameplay quantities.

**9. Broadcast payload shape (authoritative catalog).** Each entry in `CrowdStateBroadcast`:

| Field | Type | Range | Bytes (buffer) | Notes |
|---|---|---|---|---|
| `crowdId` | uint64 (packed) | `player.UserId` | 8 | Key for table indexing |
| `tick` | uint16 | [0, 65535] | 2 | Monotonic server tick; wraps at ~72 min |
| `pos` | Vector3 (3× float32) | arena bounds | 12 | Authoritative lag-follow position |
| `radius` | float32 | [1.53, 18.04] | 4 | Pre-composed: `radius_from_count(count) × radiusMultiplier` |
| `count` | uint16 | [1, 300] | 2 | Authoritative follower count |
| `hue` | uint8 | [1, 12] | 1 | Safe palette index |
| `state` | uint8 (enum) | `{Active=1, GraceWindow=2, Eliminated=3}` | 1 | Crowd lifecycle state |

Per-entry = **30 bytes** (buffer format). At 12 crowds × 15 Hz = **5.4 KB/s** per client steady state. **Requires ADR-0001 amendment** (payload spec — adds `tick` + `state` fields).

**10. Broadcast encoding: `buffer` type MANDATORY for MVP.** `CrowdStateBroadcast` payload MUST use Luau `buffer` type, not table serialization. Rationale: table format ~75 bytes/crowd ≈ 13.5 KB/s exceeds 10 KB/s budget; buffer format ~30 bytes/crowd ≈ 5.4 KB/s fits with headroom. ADR-0001 flagged buffer as optional; **this GDD promotes it to required**. **Flag ADR amendment.**

**11. Server-only write authority.** No client-to-server remote writes to crowd state. `crowd.position` is derived server-side each tick from `HumanoidRootPart.Position` via lag-follow (owned by CSM §F). Client proximity prompt interactions (chest trigger) use Roblox `ProximityPrompt.Triggered` server listener, not custom crowd remote.

**12. `crowdId` stability.** `crowdId = tostring(player.UserId)` assigned at `RoundLifecycle.createAll`, stable for entire round, destroyed at `destroyAll`. Never reused mid-round for different player (DC mid-round = immediate record destruction per CSM). Client caches keyed by `crowdId` hold entries across broadcast ticks without collision.

**13. Post-elimination broadcast continues.** Eliminated crowds appear in `CrowdStateBroadcast` with `state = Eliminated` and `count = 1` until `destroyAll`. Client consumers use the reliable `CrowdEliminated` event to trigger elimination presentation (HUD strikethrough, Nameplate fade); they do NOT trigger on crowd disappearance from the broadcast.

**14. Bandwidth budget hard constraint.** Steady-state target ≤ 10 KB/s per client. At 12 crowds buffer format ≈ 5.4 KB/s. Leaves ~4.6 KB/s for reliable event traffic. Any new reliable event type added to the catalog must be costed against this budget before authoring.

**15. LOD cadence client-only.** LOD tier decision is evaluated client-side every 0.1s per crowd. Server has no awareness of any client's LOD state. Authoritative hitbox `crowd.radius` is independent of the rendered LOD tier on any client.

### States and Transitions

**No state machine owned by this GDD.** Crowd Replication Strategy is a transport layer, not a manager. Upstream state is owned elsewhere:
- Per-crowd lifecycle (`Active / GraceWindow / Eliminated`) — owned by CSM
- Round lifecycle (`Lobby / Countdown / Active / Result / Intermission`) — owned by Match State Machine

This GDD documents only WHEN broadcasting starts and stops, derived from those two upstream machines:

| Phase | Trigger | Behavior |
|---|---|---|
| **Dormant** | Match state = `Lobby / Countdown / Result / Intermission` | No `CrowdStateBroadcast` fires. `GameplayEvent` reliable channel may still fire lifecycle events (`MatchStateChanged`) |
| **Active** | `RoundLifecycle.createAll` fires | `CrowdStateBroadcast` at 15 Hz begins. All consumer systems tick against it |
| **Closing** | `RoundLifecycle.destroyAll` fires | Broadcasting ceases immediately. Any in-flight broadcast packets received after `destroyAll` on clients are silently dropped (crowdId not found in cache = no-op) |

### Interactions with Other Systems

Inbound (writers to state this GDD replicates — all mediated through CSM):

| System | What it writes | Remote / API |
|---|---|---|
| Crowd State Manager | Owns `CrowdState` record; fires `CrowdStateBroadcast` | Owns entire broadcast path |
| Absorb System | Calls `CSM.updateCount(crowdId, +1)` | Server-internal function call |
| Crowd Collision Resolution | Calls `CSM.updateCount(attacker, +Δ)` + `updateCount(victim, -Δ)` per tick | Server-internal |
| Chest System | Calls `CSM.updateCount(crowdId, -effectiveToll)` | Server-internal |
| Relic System | Writes `crowd.radiusMultiplier`; CSM composes `radius`; fires `CrowdRelicChanged` reliable | Server-internal field write + reliable remote |
| Round Lifecycle | Fires `createAll` / `destroyAll` triggers | Server-internal |
| Match State Machine | Broadcasts `MatchStateChanged` reliable | Reliable remote |

Outbound (consumers of the replicated state):

| System | What it reads | Remote subscription |
|---|---|---|
| Crowd State Manager (client-side cache) | Unreliable `CrowdStateBroadcast`; reliable `CrowdJoined`, `CrowdEliminated`, `CrowdRelicChanged`, `CrowdCountClamped` | Primary cache populator |
| Follower Entity (client) | `CountChanged` + `CrowdRelicChanged` via CSM client cache | Cache subscriber |
| Follower LOD Manager | Cached `crowd.position` + `count` per crowd | Cache subscriber |
| HUD | Cached `crowd.count`, `hue`, `state` | Cache subscriber |
| Player Nameplate | Cached `crowd.position`, `count`, `hue`, `state` | Cache subscriber |
| VFX Manager | Cached `crowd.position`, `radius`; reliable events for triggers | Cache reader + reliable subscriber |
| Audio Manager (undesigned) | Same as VFX | Expected same pattern |
| Chest System (server) | Reads `crowd.count` for toll guard | Server-internal read |
| Absorb System (server) | Reads `crowd.position`, `crowd.radius` | Server-internal read |
| Crowd Collision Resolution (server) | Reads per-crowd `{position, radius, count}` | Server-internal read |

Reliable `GameplayEvent` enum catalog (consolidated per ADR-0001 architecture):

| Event | Payload | Producer | Consumers |
|---|---|---|---|
| `absorb` | `{crowdId, delta}` | Absorb System | Follower Entity (peel-in), HUD (count pop), VFX (AbsorbSnap), Audio |
| `eliminate` | `{crowdId}` | Crowd State Manager | HUD (strikethrough), Nameplate (fade), VFX (elimination burst), Audio |
| `chestOpen` | `{crowdId, tier, tollPaid}` | Chest System | VFX (ChestOpenBurst + peel-off), Audio |
| `relicGrant` | `{crowdId, relicName, slotIndex, rarity}` | Relic System | HUD (slot update), VFX (rarity grant), Audio, Follower Entity |
| `collisionContact` | `{crowdIdA, crowdIdB}` | Crowd Collision Resolution | VFX (ImpactBurst), Audio |

Separate reliable `RemoteEvent` catalog (existing per other GDDs — not consolidated into `GameplayEvent`):

- `MatchStateChanged` (MSM)
- `ParticipationChanged` (MSM)
- `CrowdJoined` (CSM — joining player's own hue)
- `CrowdEliminated` (CSM)
- `CrowdRelicChanged` (Relic / CSM)
- `CrowdCountClamped` (CSM → owning client only; HUD MAX CROWD flash)
- `ChestPeelOff` / `ChestDraftOpenFX` / `ChestOpenBurst` (Chest)
- `RelicGrantVFX` / `RelicExpireVFX` / `RelicDraftPick` (Relic, global scope)
- `ChestDraftOffer` (Chest, opener-only targeted)
- `NameplateHighlightSet` (Nameplate, VS)

**Design rule**: New reliable events default to their own named remote unless semantically tight with existing `GameplayEvent` enum types. Avoids a single massive enum and keeps subscription handlers focused.

## Formulas

### F1 — Bandwidth budget estimator (`bandwidth_steady_state`)

The `bandwidth_steady_state` formula is defined as:

`bytes_per_sec = broadcast_size_per_tick × SERVER_TICK_HZ + reliable_event_bytes_per_sec`

where `broadcast_size_per_tick = per_crowd_bytes × active_crowd_count`.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `per_crowd_bytes` | b | int | 30 (buffer format, locked per Rule 9) | Per-entry size in `CrowdStateBroadcast` |
| `active_crowd_count` | N | int | [2, 12] | Count of crowds in `Active + GraceWindow + Eliminated` states (all broadcast) |
| `SERVER_TICK_HZ` | f | int | 15 (registry) | Tick rate |
| `reliable_event_bytes_per_sec` | R | int | [0, ~3,000] | Dynamic; absorbs + collision contacts + chest opens + relic grants |

**Output Range:** 900 bytes/s (minimum: 2 crowds) to ~8,000 bytes/s (worst-case sustained). **Steady-state target ≤ 10 KB/s.**
**Examples:**
- Minimum (2 players start of round, no events): `2 × 30 × 15 = 900 B/s = 0.9 KB/s`
- Typical mid-round (12 crowds, ~500 B/s reliable): `12 × 30 × 15 + 500 = 5,900 B/s = 5.9 KB/s`
- Worst-case burst (12 crowds + 12 simultaneous relic grants + 6 collision contacts + 8 chest opens in one tick): spike ≈ 29.5 KB in that single tick; absorbed by RakNet send buffer. AC-10 specifies bounded to ≤ 15 KB/s over any 1s rolling window.

### F2 — Stale-broadcast detection (`broadcast_stale`)

The `broadcast_stale` formula is defined as:

`broadcast_stale = (os.clock() - lastBroadcastTime) > STALE_THRESHOLD_SEC`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `os.clock()` | t_now | float | monotonic | Current client monotonic clock |
| `lastBroadcastTime` | t_last | float | monotonic | Client-side timestamp of most recent `CrowdStateBroadcast` receipt |
| `STALE_THRESHOLD_SEC` | τ | float | 0.5 (registry) | Threshold — no hysteresis |

**Output Range:** boolean. At `SERVER_TICK_HZ = 15` (66ms tick), threshold crosses after ~7-8 consecutive missed packets.
**Behavior on `true`:** client-cache freeze — no widget interpolates toward zero, no "unknown" label, no error state. All consumers hold last-known values per Rule 5.
**Recovery:** next received broadcast resets `lastBroadcastTime = os.clock()`; next check returns `false`; widgets resume normally.

### F3 — Render-cap distance tier (`render_cap_for_distance`)

The `render_cap_for_distance` formula is defined as:

```
render_cap_for_distance(distance_studs, is_own_crowd) =
  RenderCaps.OWN_CLOSE_MAX   if distance ≤ LOD_TIER_NEAR AND is_own_crowd
  RenderCaps.RIVAL_CLOSE_MAX if distance ≤ LOD_TIER_NEAR AND NOT is_own_crowd
  RenderCaps.MID_RANGE_MAX   if LOD_TIER_NEAR < distance ≤ LOD_TIER_MID
  RenderCaps.FAR_RANGE_MAX   if LOD_TIER_MID < distance ≤ LOD_TIER_FAR
  0                          if distance > LOD_TIER_FAR — cull
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `distance_studs` | d | float | [0, ∞) | Euclidean distance from camera to `crowd.position` |
| `is_own_crowd` | o | bool | — | Local player owns this crowd |
| `OWN_CLOSE_MAX` | — | int | 80 | Own crowd close-range cap. **Owned by Follower LOD Manager §F3 cap table** — referenced here. |
| `RIVAL_CLOSE_MAX` | — | int | 30 | Rival crowd close-range cap. **Owned by Follower LOD Manager**. |
| `MID_RANGE_MAX` | — | int | 15 | Any crowd mid-range cap. **Owned by Follower LOD Manager**. |
| `FAR_RANGE_MAX` | — | int | **1 billboard per crowd** | Any crowd far-range billboard impostor cap (not 4 rigs — prior value superseded 2026-04-22 by LOD Manager spec). **Owned by Follower LOD Manager**. |
| `LOD_TIER_NEAR` | — | float | 20 studs | Near/mid boundary. **Owned by Follower LOD Manager** (sourced art bible §5). |
| `LOD_TIER_MID` | — | float | 40 studs | Mid/far boundary. **Owned by Follower LOD Manager**. |
| `LOD_TIER_FAR` | — | float | 100 studs | Cull distance. **Owned by Follower LOD Manager**. |

**Output Range:** `{0, 4, 15, 30, 80}` at defaults.
**Evaluated at 10 Hz per crowd** (0.1s cadence) — not every frame. Per Rule 15, server has no awareness of this decision.

### F4 — Tick counter wrap detection (`tick_is_newer`)

The `tick_is_newer` formula is defined as:

`tick_is_newer(new_tick, last_tick) = (new_tick > last_tick) OR (last_tick > WRAP_WATERMARK AND new_tick < WRAP_EPSILON)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `new_tick` | n | uint16 | [0, 65535] | Incoming `tick` from broadcast |
| `last_tick` | l | uint16 | [0, 65535] | Client-stored `lastReceivedTick` |
| `WRAP_WATERMARK` | — | uint16 | 60000 | "Near wrap" guard |
| `WRAP_EPSILON` | — | uint16 | 5000 | "Just wrapped" guard |

**Output Range:** boolean. `true` → accept + update `lastReceivedTick`. `false` → discard packet.
**Examples:**
- `last=100, new=101` → `true` (normal forward progression)
- `last=100, new=99` → `false` (stale / reorder)
- `last=65530, new=5` → `true` (wrap: `65530 > 60000` AND `5 < 5000`)
- `last=65530, new=65529` → `false` (stale near wrap)

**Rationale:** uint16 wraps at 65535 ≈ 72 minutes at 15 Hz. MVP round is 5 minutes so wrap never occurs in normal play — but the guard is free and covers edge cases (lobby testing, stuck servers, future long-round modes).

## Edge Cases

### Broadcast delivery

- **If single `CrowdStateBroadcast` packet drops** (< `STALE_THRESHOLD_SEC`): non-event. Client holds last-known state, continues rendering. Server unaffected. Next broadcast resumes.
- **If cluster loss > `STALE_THRESHOLD_SEC = 0.5s`**: client-cache freeze per F2. Boids followers may drift up to ~5 studs from crowd center before next broadcast snaps them back (cosmetic; accepted per ADR desync tolerance). On recovery: first received broadcast = full snapshot; all consumers reconcile to current state; no interpolation, no catch-up replay.
- **If packet arrives out-of-order** (new packet has `tick ≤ lastReceivedTick`): F4 detects via wrap-aware comparison; stale packet discarded; `lastReceivedTick` unchanged.
- **If two `CrowdStateBroadcast` ticks collide in client frame** (back-to-back Receive): process in arrival order; `lastReceivedTick` advances correctly; idempotent overwrite means no accumulation bug.

### Cross-channel ordering

- **If `CrowdEliminated` reliable arrives BEFORE `CrowdStateBroadcast` reflects count=1**: client sets permanent `Eliminated` flag on `CrowdStateClient.get(crowdId).state`. Subsequent broadcasts for that crowd update `pos/count` but MUST NOT clear the flag (Rule 4).
- **If `CrowdStateBroadcast` arrives BEFORE `CrowdEliminated` reliable** (broadcast shows `state=Eliminated` first): client cache sets `state=Eliminated` from broadcast. Reliable event arrives later, triggers HUD strikethrough + Nameplate fade. Idempotent (flag already set).
- **If `relicGrant` `GameplayEvent` fires before next `CrowdStateBroadcast` (count-altering relic like Surge)**: client's `CrowdRelicChanged` cache updates immediately via reliable path. Count update arrives on next broadcast (66ms later) — expected lag. Visual `RelicGrantVFX` fires on reliable; HUD count pop fires on next broadcast.
- **If `CollisionContactEvent` arrives but the corresponding count-delta broadcast is lost**: VFX plays ImpactBurst at broadcast-cached positions (possibly stale); next broadcast brings count truth. Worst case: ImpactBurst at slightly-stale midpoint. Cosmetic-only.

### Payload edge cases

- **If `active_crowd_count < 2` at `RoundLifecycle.createAll`**: MSM guard `MIN_PLAYERS_TO_START = 2` prevents this; round never enters Active. This GDD's transport phase stays Dormant.
- **If a crowd has `state = Eliminated` AND `count != 1`** (bug guard): per Rule 13, count=1 on elimination. Mismatch indicates CSM bug; consumers trust `state` field for display, `count` for math (they'd agree post-elimination anyway).
- **If `tick` field is missing from received payload** (ADR amendment not yet implemented in server): client defaults to always-accept (backward compat during ADR amendment rollout). Log warn. Post-amendment: mandatory field; missing = dropped with warn.
- **If `buffer` decode fails on client** (corrupt packet, version skew): drop packet silently; log warn; next packet processed normally. No crash.

### Round lifecycle

- **If `RoundLifecycle.destroyAll` fires mid-tick**: currently-running tick completes (Roblox Luau not preemptive); no new broadcasts scheduled. Any client-in-flight packets received post-`destroyAll` find empty `CrowdStateClient` cache → crowdId not found → silent no-op.
- **If server shuts down mid-round (`game:BindToClose`, `SERVER_CLOSING_GRACE_SEC = 30`)**: `TickOrchestrator` ceases new ticks immediately. ProfileStore flush priority. Clients hit `STALE_THRESHOLD_SEC` within 0.5s → freeze. Roblox disconnects clients at close — expected.
- **If 13th player attempts to join**: blocked at `RoundLifecycle.createAll` assertion (`MAX_PARTICIPANTS_PER_ROUND = 12`). Roblox server-player cap configured to 12 at place settings. No crowd record created, no broadcast entry, no payload overhead.

### Late join & reconnect

- **If client connects during `Active` phase**: MVP blocks mid-round join per MSM (`Lobby`-only join). Post-MVP: requires `CrowdStateSnapshot` reliable event — flagged Open Question.
- **If client disconnects + reconnects same server**: MSM / CSM block same-round reconnect (DC mid-round = immediate record destruction). Client rejoins on next `Lobby` phase.

### Render cap

- **If client is within 20m of 6+ rival crowds simultaneously** (stacked pile): 6 × 30 = 180 rival-close rendered Parts. Plus own crowd 80 = 260 Parts this frame. Exceeds Follower Entity pool sizing worst case (unlikely in realistic play — 6 crowds within 20m is a pile-up moment, transient). Consumer handles via per-crowd render cap independence (no global pool overflow). Part churn GC-tolerated per prototype evidence.
- **If client's FPS drops below 30 on mobile**: Follower LOD Manager owns adaptive downscale (deferred post-MVP per ADR Risk 2). Replication side unchanged — caps are upper bounds, not floors.

## Dependencies

| System | Relationship | Interface | Status | Reverse-listed? |
|---|---|---|---|---|
| **ADR-0001 Crowd Replication Strategy** | Authoritative architecture owner | This GDD implements the ADR's decision surface | Proposed | ADR §GDD Requirements lists this GDD |
| **Network Layer** (template-provided) | Hard — upstream | `Network.fireAllClients` / `connectEvent` wrappers for all remotes | Approved (template) | Template-provided |
| **Crowd State Manager** | Hard — bidirectional | Writes `CrowdState` record; fires `CrowdStateBroadcast`; owns client-side cache | In Review | CSM §Dep references this GDD + ADR-0001 |
| **Round Lifecycle** | Hard — upstream trigger | `createAll` / `destroyAll` transitions this GDD's Dormant / Active / Closing phases | In Review | Round Lifecycle §Dep lists CSM (which owns broadcast); transitively this GDD |
| **Match State Machine** | Hard — upstream trigger | `MatchStateChanged` reliable remote (own channel); gates when Active phase is entered | In Review | MSM §Dep lists broadcast via Network Layer |
| **Follower Entity** | Hard — downstream consumer | Reads `CountChanged` + `CrowdRelicChanged` via CSM client cache; uses render caps from F3 | In Review | Follower Entity §Dep lists ADR-0001 + CSM |
| **Follower LOD Manager** | Hard — downstream consumer | Reads `crowd.position` + `count` per crowd; uses `LOD_TIER_NEAR/MID/FAR` from F3 | Approved | FLM §Dep lists ADR-0001 + CSM |
| **Absorb System** | Hard — downstream consumer | Server reads `crowd.position` + `crowd.radius` per tick | Designed (pending review) | Absorb §Dep lists CSM + ADR-0001 |
| **Crowd Collision Resolution** | Hard — downstream consumer | Server reads per-crowd `{position, radius, count}` per tick; fires `CollisionContactEvent` reliable | Designed (pending review) | CCR §Dep lists CSM + ADR-0001 |
| **Chest System** | Hard — downstream consumer | Server reads `crowd.count` for toll guard; fires `ChestPeelOff` / `ChestDraftOpenFX` / `ChestOpenBurst` reliable | Designed (pending review) | Chest §Dep lists ADR-0001 + CSM |
| **Relic System** | Hard — downstream consumer | Writes `crowd.radiusMultiplier`; fires `RelicGrantVFX` / `RelicExpireVFX` / `RelicDraftPick` reliable (global); `CrowdRelicChanged` reliable | Designed (pending review) | Relic §Dep lists ADR-0001 + CSM |
| **HUD** | Soft — downstream consumer | Reads CSM client cache; consumes `CrowdCountClamped` reliable | Designed (pending review) | HUD §Dep lists CSM + ADR-0001 |
| **Player Nameplate** | Soft — downstream consumer | Reads CSM client cache; hue from `hue_index_assignment` | Designed (pending review) | Nameplate §Dep lists CSM + ADR-0001 |
| **VFX Manager** | Soft — downstream consumer | Reads CSM client cache for `crowdRelative` anchor; consumes 7 reliable remotes | Designed (pending review) | VFX §Dep lists CSM + ADR-0001 |
| **Audio Manager** (undesigned) | Soft — expected downstream consumer | Expected to subscribe to same reliable remote catalog | Not started | — |
| **NPC Spawner** | None (direct) | NPC Spawner uses `UnreliableRemoteEvent` per ADR-0001 pattern but operates on NPC pool, not crowd state | Designed (pending review) | Pattern-level dependency only |

### Dependency amendments required (propagate later)

1. **ADR-0001** — amend §Key Interfaces `CrowdStateBroadcast` payload: add `tick: uint16` + `state: uint8 enum`. Update byte budget estimate from `~40 bytes/crowd` to `~30 bytes (buffer format)`. Promote `buffer` encoding from optional to **required for MVP**. (Rules 6, 9, 10 of this GDD.)
2. **ADR-0001** — amend §Consequences to acknowledge gap: no mid-round join snapshot event specified; MVP locks mid-round join OFF; post-MVP requires `CrowdStateSnapshot` reliable event.
3. **CSM GDD** — add `tick` field write logic to `broadcastAll` (server side); add `lastReceivedTick` comparison + discard to `CrowdStateClient` (client side).

### Cross-system facts confirmed consistent (no conflicts)

- `SERVER_TICK_HZ = 15` — consumed correctly (Rule 1, F1).
- `STALE_THRESHOLD_SEC = 0.5` — consumed correctly (Rule 5, F2).
- `MAX_CROWD_COUNT = 300` — consumed via `count` field range [1, 300] (Rule 9).
- `MAX_PARTICIPANTS_PER_ROUND = 12` — consumed via `active_crowd_count` bound (F1, Edge Cases).
- `radius_from_count` — consumed via `crowd.radius` field range [1.53, 18.04] (Rule 9).
- `CROWD_START_COUNT` — NOT directly consumed by this GDD (CSM owns; pending NPC Spawner 10→20 patch is unrelated to replication).

## Tuning Knobs

| Knob | Default | Safe range | Unit | What it affects | Breaks if too high | Breaks if too low | Owner |
|---|---|---|---|---|---|---|---|
**Note (2026-04-24 Batch 3):** The 7 LOD-related constants below are **referenced-only in this GDD**. Authoritative owner: `design/gdd/follower-lod-manager.md` §Tuning Knobs + §F3 cap table. Modifying their values requires a `/propagate-design-change` pass on the LOD Manager GDD, not here. CRS owns the broadcast transport contract; LOD Manager owns the client render/distance policy.

| `OWN_CLOSE_MAX` | 80 | [40, 80] | Parts | Own crowd render cap at ≤20m (F3) — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager §Tuning Knobs |
| `RIVAL_CLOSE_MAX` | 30 | [15, 40] | Parts | Rival crowd render cap at ≤20m (F3) — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager |
| `MID_RANGE_MAX` | 15 | [8, 20] | Parts | Any crowd at 20-40m (F3) — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager |
| `FAR_RANGE_MAX` | **1 billboard/crowd** | locked at 1 | Parts | Any crowd at 40-100m, billboard impostor (F3) — **referenced from Follower LOD Manager**. Value 1 supersedes prior 4-rig spec (2026-04-22 LOD Manager correction). | — | — | see Follower LOD Manager |
| `LOD_TIER_NEAR` | 20 | [10, 40] | studs | F3 near/mid boundary — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager |
| `LOD_TIER_MID` | 40 | [LOD_TIER_NEAR, 100] | studs | F3 mid/far boundary — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager |
| `LOD_TIER_FAR` | 100 | [40, 200] | studs | F3 cull distance — **referenced from Follower LOD Manager** | — | — | see Follower LOD Manager |
| `LOD_SWAP_CADENCE_SEC` | 0.1 | [0.05, 0.2] | seconds | Client-side LOD re-evaluation rate (Rule 15) | Infrequent swaps = visible popping when camera moves fast | Frequent swaps = GC churn from Part pool re-assignment | technical-artist |
| `STALE_THRESHOLD_SEC` | 0.5 | [0.2, 2.0] | seconds | Broadcast-lost freeze threshold (F2) | >2s = stale displays feel broken on mobile jitter | <0.2s = normal network jitter triggers freeze | network-programmer |
| `CROWD_POS_LAG` | 0.15 | [0.05, 0.30] | multiplier | Server lag-follow smoothing (owned by CSM, referenced here) | High lag = hitbox trails character; easy to escape collision | Low lag = hitbox snaps instantly; jitters with character | game-designer |
| `WRAP_WATERMARK` | 60000 | [50000, 65000] | uint16 | F4 near-wrap guard | Too close to wrap → may mis-accept stale pre-wrap packet | Too low → mis-rejects valid post-wrap packets | network-programmer |
| `WRAP_EPSILON` | 5000 | [1000, 10000] | uint16 | F4 just-wrapped guard | Too wide = accepts stale packets as wrapped | Too narrow = rejects valid wrapped packets | network-programmer |

**Locked values (require ADR-0001 amendment to change):**
- `SERVER_TICK_HZ = 15` — locked by ADR-0001; changing cascades 8+ GDDs
- `radius_from_count` formula — locked by ADR-0001 + registry
- `UnreliableRemoteEvent` for broadcast / `RemoteEvent` for discrete events — architecture choice
- `buffer` encoding for `CrowdStateBroadcast` — mandated by Rule 10
- Per-crowd bytes (~30 bytes buffer format) — budget spec
- `MAX_CROWD_COUNT = 300`, `MAX_PARTICIPANTS_PER_ROUND = 12` — owned by CSM / Round Lifecycle

**Registry-owned constants consumed by this GDD** (do not redefine):
- `SERVER_TICK_HZ = 15`
- `STALE_THRESHOLD_SEC = 0.5`
- `MAX_CROWD_COUNT = 300`
- `MAX_PARTICIPANTS_PER_ROUND = 12`

## Visual/Audio Requirements

**None owned by this GDD.** Crowd Replication Strategy is a transport layer; it has no direct visuals or audio. All visual beats that consume replicated state are owned by downstream systems:

| Visual / Audio beat | Owner GDD |
|---|---|
| Crowd silhouette rendering (boids-flocked Parts) | `design/gdd/follower-entity.md` §V/A |
| LOD tier swap visuals (full / simple / billboard impostor) | `design/gdd/follower-lod-manager.md` |
| Absorb snap + collision impact burst + chest open / relic grant / hue shift | `design/gdd/vfx-manager.md` §V/A |
| HUD count widget pop / MAX CROWD flash / mini-leaderboard | `design/gdd/hud.md` §V/A |
| Nameplate text / tier offset / eliminated fade | `design/gdd/player-nameplate.md` §V/A |
| Audio cues mirroring VFX events | Audio Manager GDD (undesigned) |

**Consumer contract for V/A systems reading replicated state:**
- Anchor `worldPos` / `crowdRelative` effects on `crowd.position` from CSM client cache (updates at 15 Hz).
- Hue tint reads `crowd.hue` index 1-12 resolved to safe palette color.
- Stale-broadcast behavior: freeze last-known position + hue per Rule 5; no interpolation to zero, no "unknown" state.
- LOD-tier-aware effects (if any) read Follower LOD Manager's tier decision, not this GDD.

No Asset Spec flag — no assets.

## UI Requirements

**None.** Crowd Replication Strategy has no UI surface. Transport-layer system — no menus, no HUD widgets, no screen-space elements, no debug overlays in production.

**Diagnostic overlays** (developer-only, not shipped):
- Optional `debug.profilebegin("CrowdStateBroadcast")` tag for MicroProfiler — specified in §H AC.
- Optional development-build print of `_particleCount`-equivalent bandwidth estimator — not a shipped feature.

All UI that READS replicated state belongs to its respective consumer GDD (HUD, Nameplate, Relic Card UI VS).

## Acceptance Criteria

QA-lead validated + extended seed ACs. 27 ACs cover all 15 Core Rules, all 4 formulas, all transport-phase transitions, cross-channel ordering edges, bandwidth thresholds, consumer contract. Logic ACs BLOCKING per coding standards; perf ACs ADVISORY.

**Evidence tier legend:** `unit` = TestEZ with mocked dependencies; `integration` = TestEZ + test harness OR multi-client Studio session; `manual` = playtest + lead sign-off; `static` = selene lint / grep CI gate.

### Payload & buffer encoding (Rules 9-10)

**AC-1 (Buffer payload byte size — Rule 9)** — GIVEN `CrowdStateServer` constructs single-crowd broadcast in `buffer` encoding, WHEN buffer written with one crowd record (uint64 crowdId + uint16 tick + Vec3 pos [3×f32] + f32 radius + uint16 count + uint8 hue + uint8 state), THEN `buffer.len(buf) == 30`; each field round-trips via `buffer.writef32 / writeu16 / writeu8` without precision loss beyond f32 tolerance. *Evidence: unit.* **BLOCKING.**

**AC-2 (Buffer decode round-trip)** — GIVEN 30-byte buffer from server encoder, WHEN `CrowdStateClient.decode(buf)` called, THEN decoded struct fields match original within f32 epsilon for floats and exactly for integers; no decode error. *Evidence: unit.* **BLOCKING.**

**AC-3 (Buffer decode failure graceful fallback)** — GIVEN malformed buffer (length < 30 bytes), WHEN decoder called, THEN no Lua error propagates, function returns `nil`, client cache for that `crowdId` retains prior value unchanged. *Evidence: unit.* **BLOCKING.**

### Formulas (F1-F4 boundary)

**AC-4 (F1 bandwidth boundary — 12-crowd steady state)** — GIVEN `N=12`, `HZ=15`, `per_crowd_bytes=30`, `reliable_overhead=100 B/s`, WHEN `BandwidthEstimator.compute(N, HZ, payloadBytes, reliableOverhead)` evaluated, THEN result = `5500 B/s` (5.37 KB/s) < `BANDWIDTH_BUDGET_BYTES_PER_SEC = 10240` (10 KB/s). *Evidence: unit.* **BLOCKING.**

**AC-5 (F2 stale threshold boundary)** — GIVEN `lastBroadcastTime = T` and `STALE_THRESHOLD_SEC = 0.5`, WHEN `clockFn()` returns `T + 0.499` → `broadcast_stale()` returns `false`; WHEN returns `T + 0.500` → returns `true`. *Evidence: unit. DI: `clockFn` injected.* **BLOCKING.**

**AC-6 (F3 render cap tier boundaries)** — GIVEN `render_cap_for_distance(d, isOwnCrowd)`, WHEN `d` evaluated at `{0, 20, 20.001, 40, 40.001, 100, 100.001}`, THEN returns `{80, 80, 15, 15, 4, 4, 0}` for own-crowd; rival-crowd ≤20m returns 30 (not 80). *Evidence: unit.* **BLOCKING.**

**AC-7 (F4 tick counter uint16 wrap-around)** — GIVEN `tickCounter = 65535` (uint16 max), WHEN server increments to `0`, THEN `tick_is_newer(0, 65535) = true` (wrap-aware); `tick_is_newer(65534, 65535) = false`; `tick_is_newer(32767, 0) = false` (≥ half-window, treat stale). *Evidence: unit. DI: `tick_is_newer` exported standalone on `CrowdReplicationUtil`.* **BLOCKING.**

### Transport phase state machine

**AC-8 (Dormant → Active on createAll)** — GIVEN `CrowdReplicationServer` Dormant (no broadcast loop), WHEN `RoundLifecycle.createAll()` fires + crowd records created, THEN broadcast accumulator loop starts within one `Heartbeat`, `CrowdStateBroadcast` fires within 67ms (1 tick at 15 Hz). *Evidence: integration.* **BLOCKING.**

**AC-9 (Active: post-elimination broadcast continues — Rule 13)** — GIVEN crowd transitions to `Eliminated` via grace-timer expiry, WHEN `destroyAll` has NOT been called, THEN `CrowdStateBroadcast` continues to include that `crowdId` at every tick with `state = Eliminated`; broadcast does NOT drop until `destroyAll`. *Evidence: integration.* **BLOCKING.**

**AC-10 (Closing → Dormant on destroyAll)** — GIVEN `RoundLifecycle.destroyAll()` called, WHEN next broadcast tick fires, THEN no destroyed `crowdId` appears in payload; broadcast loop halts if zero records remain; no Lua error at empty-record edge. *Evidence: integration.* **BLOCKING.**

### Cross-channel ordering (Rule 4)

**AC-11 (Defensive: broadcast handler does not un-eliminate)** — GIVEN `CrowdStateClient` cache has `state = Eliminated` for `crowdId = "A"`, WHEN subsequent `CrowdStateBroadcast` arrives for A carrying `state = Active` or `GraceWindow` (e.g. stale packet arrived late), THEN client handler discards state update for that crowd; cache remains `Eliminated`. *Evidence: unit.* **BLOCKING.**

**AC-12 (Elimination reliable before unreliable — observational)** — GIVEN crowd transitions to `Eliminated` on server tick T, WHEN server dispatches tick T's outputs, THEN `CrowdEliminated` reliable event fires before (or atomically with) `CrowdStateBroadcast`; client handler ordering observed via instrumented log. *Evidence: integration (multi-client).* **ADVISORY** (engine ordering non-deterministic; AC-11 is the enforceable guarantee).

**AC-13 (Relic-grant + count-update ordering)** — GIVEN `CrowdRelicChanged` reliable + `CrowdStateBroadcast` arrive at client in either order, WHEN client processes both, THEN cache correctly reflects relics from `CrowdRelicChanged` AND count/radius/pos from broadcast regardless of order; relic state never overwritten by broadcast. *Evidence: unit.* **BLOCKING.**

### Bandwidth & rate cap

**AC-14 (Steady-state bandwidth ≤10 KB/s)** — GIVEN 12-player session, 60s after active play begins (crowds ≥50 count each), `buffer` encoding active, WHEN `DataSendKbps` measured per client over rolling 5s window, THEN measurement ≤ 10 KB/s. *Evidence: integration (12-client Studio harness).* **BLOCKING — deferred to first multi-client integration sprint per ADR-0001 Risk 4.**

**AC-15 (Bandwidth burst cap ≤15 KB/s over 1s)** — GIVEN round start with 12 crowds emitting first broadcast + up to 12 `CrowdJoined` reliable events, WHEN measured over 1s window, THEN total outbound per-client ≤ 15,360 B/s; decays to steady within 3s. *Evidence: integration (12-client Studio harness).* **BLOCKING — same sprint as AC-14.**

**AC-16 (LOD cadence ≤10 Hz per crowd — Rule 15)** — GIVEN 12 crowds visible, WHEN LOD manager runs 60s, THEN no crowd's LOD re-evaluated >600 times (10 Hz × 60s), verified via instrumented counter inside `evaluateLOD(crowdId)`. *Evidence: unit. DI: `timerFn` injected.* **BLOCKING.**

### Consumer contract

**AC-17 (Stale freeze last-known — Rule 5)** — GIVEN `CrowdStateClient` cache has crowd at `pos=(10,0,10), count=75`, WHEN no broadcast for `STALE_THRESHOLD_SEC + 0.1s = 0.6s`, THEN `get(crowdId)` returns frozen `{pos=(10,0,10), count=75}` unchanged; cache does NOT return zero/nil/interpolated; no error. *Evidence: unit.* **BLOCKING.**

**AC-18 (Nil crowdId lookup returns nil)** — GIVEN no record for `crowdId = "999999"`, WHEN `get("999999")` called, THEN returns `nil` (not empty table, not default struct, not error); caller nil-checks. *Evidence: unit.* **BLOCKING.**

**AC-19 (Reliable arrives first before broadcast)** — GIVEN cache has no entry for `crowdId = "A"`, WHEN reliable `CrowdJoined` arrives carrying `{crowdId="A", hue=3}` before any broadcast for A, THEN `get("A")` returns partial record with `hue=3` + other fields zero/default without error; first broadcast for A completes the record with live values. *Evidence: unit.* **BLOCKING.**

**AC-20 (No client count accumulation error — Rule 3)** — GIVEN `CrowdStateClient` receives 50 broadcasts over 5s with varying counts, WHEN final cache value read, THEN `cache.count` equals the LAST received broadcast's count value (idempotent overwrite), NOT the sum of all received broadcast counts. *Evidence: unit.* **BLOCKING.**

**AC-21 (Reliable exactly-once — loopback counter)** — GIVEN server fires `N = 100` `GameplayEvent` remote events over 10s, WHEN client-side receipt counter observed, THEN counter = 100 (no drops, no duplicates). *Evidence: integration (multi-client OR Studio loopback harness).* **BLOCKING.**

### Correctness / authority

**AC-22 (crowdId uniqueness per round — Rule 12)** — GIVEN 5-min round with 12 players, WHEN client cache insertion log asserted, THEN no two different `crowdId` entries exist for same `player.UserId`; every entry's `crowdId == tostring(player.UserId)`. *Evidence: unit (inject mock broadcasts) + integration (12-player session log).* **BLOCKING.**

**AC-23 (Server/client gameplay outcome parity)** — GIVEN 5-min 8-player session, WHEN server `updateCount` call inputs logged alongside broadcast values received same tick, THEN server authoritative count always matches last broadcast count (no drift, no off-by-one). *Evidence: integration.* **ADVISORY.**

**AC-24 (Render cap independence)** — GIVEN own crowd `count=300` + rival crowd `count=300` both within 20m of camera, WHEN scene rendered, THEN `#workspace:GetDescendants()` filtered to follower Parts ≤ (80 + 30) = 110; per-crowd caps independent. *Evidence: unit (instrumented Part count query).* **BLOCKING.**

**AC-25 (No gameplay decision on rendered count — Rule 7 static gate)** — GIVEN codebase built, WHEN grep across `src/ServerStorage/` for references to client-side `renderedCount` field or equivalent, THEN zero matches; all server gameplay decisions reference `crowdState.count` (authoritative). *Evidence: static (grep CI gate).* **BLOCKING.**

**AC-26 (Server-only write authority — Rule 11 static gate)** — GIVEN codebase built, WHEN selene with custom rule (or explicit code-review checklist) asserts `CrowdStateServer.updateCount / create / destroy` never referenced from `src/ReplicatedStorage/` or `src/ReplicatedFirst/`, THEN zero violations. *Evidence: static (selene OR code-review).* **BLOCKING.**

### Performance (ADVISORY)

**AC-27 (Mobile ≥45 FPS at 12-player × 300-count)** — GIVEN iPhone SE (or emulator equiv) in 12-player session with 300-count crowds, WHEN 3-min window observed via MicroProfiler, THEN FPS ≥ 45 sustained; crowd-related time slices (boids + LOD swap amortized) ≤ 4ms/frame. *Evidence: integration (MicroProfiler on device).* **ADVISORY — deferred to ADR-0001 Validation Criteria item 2.**

### DI requirements (for unit-testable ACs)

Per ANATOMY.md §16 (DI over singletons). `CrowdReplicationServer` + `CrowdStateClient` must accept on init:

| Dependency | Interface | Used by |
|---|---|---|
| `BufferEncoder` | `{ encode: (CrowdState) → buffer, decode: (buffer) → CrowdState? }` | AC-1, AC-2, AC-3 |
| `clockFn` | `() → number` | AC-5, AC-17 |
| `BandwidthEstimator` | `{ compute: (N, HZ, bytes, overhead) → number }` | AC-4 |
| `timerFn` | `() → number` injectable, defaults to `os.clock` | AC-16 |
| `CrowdReplicationUtil.tick_is_newer` | `(uint16, uint16) → boolean` exported standalone | AC-7 |

**Lead-programmer sign-off required** on DI shape before sprint start. Consistent with `task.delay` / `clockFn` injection patterns already used in CSM, Absorb, Match State Machine, VFX Manager ACs.

### Flags

1. **AC-14, AC-15** require deployed 12-player server or 12-client Studio harness — cannot run in solo Studio. Tag sprint: "first multi-client integration sprint" per ADR-0001 Risk 4 mitigation.
2. **AC-25, AC-26** are static analysis gates. If selene cannot enforce the server/client boundary via custom rule, promote to explicit code-review checklist item (still BLOCKING; silent pass unacceptable).
3. **Late-join** (mid-round `CrowdStateSnapshot` event) has NO AC in this list — MVP-blocked per MSM (`Lobby`-only join). Re-add when mid-round join is enabled post-MVP.
4. **AC-12** classified ADVISORY because Roblox engine does not guarantee reliable/unreliable cross-remote ordering within same server frame. AC-11 is the BLOCKING enforceable guarantee (client-side defensive rule).

## Open Questions

1. **ADR-0001 amendment: payload spec + `buffer` mandate** — This GDD requires 3 changes to ADR-0001's §Key Interfaces: (a) add `tick: uint16` field; (b) add `state: uint8 enum`; (c) promote `buffer` encoding from optional to required for MVP. **Owner:** technical-director + network-programmer. **Target:** `/propagate-design-change docs/architecture/adr-0001-crowd-replication-strategy.md` before ADR marked Accepted.

2. **Multi-client bandwidth test execution** — ADR-0001 Validation Criteria item 3 (multi-client bandwidth <10 KB/s) is deferred to MVP integration. AC-14 + AC-15 formalize this. Blocking for MVP ship, not for GDD approval. **Owner:** network-programmer + qa-lead. **Target:** first multi-client integration sprint; 4+ clients via Studio Test > Start.

3. **Mobile mobile validation (iPhone SE ≥45 FPS)** — ADR-0001 Risk 1 + AC-27. Deferred per prototype report. **Owner:** technical-artist + gameplay-programmer. **Target:** first mobile playtest milestone (MVP integration).

4. **`CrowdStateSnapshot` reliable remote for late-join** — gameplay-programmer flagged this gap in ADR-0001 during §C consult. Not needed MVP (MSM locks mid-round join OFF), but required when mid-round join is enabled post-MVP. **Owner:** game-designer (scope) + network-programmer (implementation). **Target:** VS or Alpha phase when mid-round-join mechanic is designed.

5. **Static analysis enforcement for AC-25 + AC-26** — selene may not support custom rules for the server/client boundary + rendered-count gameplay-decision prohibition. If not, both ACs become manual code-review gates. **Owner:** lead-programmer + devops-engineer. **Target:** pre-sprint tooling review.

6. **Cross-remote ordering engine investigation** — AC-12 (elimination reliable before unreliable) is advisory because Roblox doesn't guarantee ordering across remote types. Should we empirically characterize this on current Roblox engine (2026-04 pinned)? If ordering IS reliably reliable-first, AC-12 could upgrade to BLOCKING. **Owner:** network-programmer. **Target:** pre-MVP integration — quick test.

7. **Lag-follow formula ownership** — `CROWD_POS_LAG` knob (0.15 default) is listed here but formula owned by CSM GDD. Confirm CSM §F has the authoritative formula; if not, flag amendment. **Owner:** game-designer + systems-designer. **Target:** CSM fresh-session `/design-review`.

8. **`buffer` type production validation** — `buffer` encoding mandated Rule 10 but prototype used Luau table format. Need to validate `buffer` encode/decode perf on mobile + multi-client bandwidth matches estimate. **Owner:** network-programmer. **Target:** prototype-before-ship task (1 sprint). Flag as Risk 2-addendum on ADR-0001.

9. **`GameplayEvent` enum vs separate remotes** — §C lists 5 event types under consolidated `GameplayEvent` (absorb/eliminate/chestOpen/relicGrant/collisionContact) but other GDDs reference separate reliable `RemoteEvent`s (ChestPeelOff/DraftOpenFX/OpenBurst, RelicGrantVFX, etc.). Final remote namespace organization needs architecture review. **Owner:** lead-programmer + network-programmer. **Target:** pre-implementation architecture review; possibly ADR addendum.

10. **Bandwidth budget re-baseline if ADR-0001 table-format-defaulted** — GP flagged table format = ~13.5 KB/s (exceeds 10 KB/s). This GDD's mandate (buffer MVP) solves it. But if buffer type proves problematic on mobile, fallback must be re-designed (tighter caps? sparse deltas?). **Owner:** technical-director. **Target:** contingency plan if OQ #8 fails.
