# Crowd State Manager

> **Status**: In Revision (2026-04-22 review — 4 blockers resolved; 2026-04-24 CRS amendment — §G network event contract updated per design/gdd/crowd-replication-strategy.md Rules 6/9/10/13; 2026-04-24 Batch 1 amendment — added `radiusMultiplier` field + F1 composition + `recomputeRadius` API + 4 signals (CrowdCreated, CrowdDestroyed, CrowdCountClamped, CountChanged) + 3 read/overlap APIs (getAllActive, getAllCrowdPositions, setStillOverlapping) per /review-all-gdds 2026-04-24 report — unblocks 7 downstream GDDs)
> **Author**: user + game-designer + systems-designer + gameplay-programmer
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine), 3 (5-Min Clean Rounds), 4 (Cosmetic Expression), 5 (Comeback Always Possible)

## Overview

The **Crowd State Manager** is the server-authoritative system that holds the live aggregate state of every active crowd in a match — one record per player, keyed by `crowdId`. Each record carries the crowd's authoritative position, hitbox radius (derived from count with relic multiplier composition), follower count, signature hue, and list of active relics. This is the number that grows when absorbing, shrinks w hen colliding, buys rarities at chests, and decides who eliminates whom. Every gameplay system that causes or reacts to a crowd change — Absorb, Chest, Collision, Relic, HUD — reads and mutates state through this module's API; no system reaches around it. The state's data shape and replication contract are locked by **ADR-0001 (Crowd Replication Strategy)**; this GDD specifies the rules that govern creation, mutation, and lifecycle. State is strictly ephemeral — created at match start, destroyed at match end, never persisted (Pillar 3). The count is the game's core feedback channel: the snowball players feel (Pillar 1), the skin that projects across the whole pack (Pillar 4), and the underdog comeback in the final minute (Pillar 5).

## Player Fantasy

Your crowd doesn't grow — it **ticks**. Every absorbed stranger snaps into your pack with a crisp +1, and that number climbing is the whole drug: 47, 48, 49, the counter pulsing faster than your thumb can track. Smash a smaller rival and your crowd doesn't just gain — it **swells**, a fat burst of bodies flooding in while the screen shakes and their old color drowns in yours. Paying a chest toll is the opposite feeling: you watch 30 of your people peel off and vanish into the box, stomach held, waiting to see what rolled. When a bigger pack catches you wrong, the drop is instant and physical — 280 crashing to 40 in one sickening lurch, and the quiet after. Then you look down: every single follower still wearing your hue, a rolling ripple of color saying *these are mine, and I'm coming back*.

## Detailed Design

### Core Rules

**Crowd identity**
- One crowd per player for life of match. `crowdId = tostring(player.UserId)`.
- DC mid-round → immediate record destruction. No reconnect-same-round.

**Count floor: 1 (with Grace window)**
- `updateCount` clamps such that `count >= 1`.
- If CollisionResolver drain results in count = 1 (floor reached, whether via clamp or exact drain) AND overlap persists → transition to `GraceWindow`.
- If clamp triggered by ChestSystem → reject entire toll (chest guard: strict `count > toll`).
- If clamp triggered by RelicEffectHandler → stay `Active` at count=1.

**Count ceiling: hard clamp 300**
- All callers. No relic overflow. Excess delta silently truncated.
- Cap source: art bible §8 follower visual-budget.

**Position authority: lag-follow character**
- Each 15 Hz tick: `position += (character.HumanoidRootPart.Position - position) * CROWD_POS_LAG`.
- `CROWD_POS_LAG = 0.15` default. Smooths jitter, blocks teleport exploits.
- Flocking + collision math both read `position`, not character CFrame.

**Hue assignment: join-order deterministic**
- On `PlayerAdded`: `hue_index = ((join_order - 1) mod 12) + 1` from safe palette (art bible §4).
- 13th+ player recycles index — acknowledged edge, out of 8-12 prod config.

**activeRelics semantics**
- Max 4 concurrent. No duplicates (re-roll upstream at chest).
- Order irrelevant. Effects apply as independent modifiers.

**Crowd record shape (authoritative)**

| Field | Type | Default | Mutator | Notes |
|---|---|---|---|---|
| `crowdId` | string | — | `create()` only | `tostring(player.UserId)` |
| `count` | int [1,300] | `CROWD_START_COUNT=10` | `updateCount()` | Write-access contract below |
| `position` | Vector3 | spawn point | position-lag tick | F2 |
| `radiusMultiplier` | f32 [0.5, 1.5] | **1.0** | `recomputeRadius()` | RelicEffectHandler-only write. Hard ceiling 1.5 per registry `RADIUS_MULTIPLIER_MAX` (beyond this, sit-still strategy becomes viable). |
| `hue` | uint8 [1,12] | `hue_index(join_order)` | `create()` only | F6; immutable post-create |
| `activeRelics` | {RelicId} | {} | `RelicEffectHandler` | Max `MAX_RELIC_SLOTS = 4` |
| `state` | enum | `Active` | state machine | {Active, GraceWindow, Eliminated} |
| `tick` | uint16 | 0 | broadcast tick | Monotonic; wraps 65535 (~72 min at 15 Hz) |
| `timer_start` | float? | nil | GraceWindow entry/exit | F7 |
| `stillOverlapping` | bool | false | `setStillOverlapping()` | CollisionResolver-only write |

No other fields persist on the record. Derived values (final composed radius, in-flight timer deltas) are computed per-tick and not stored.

**Write-access contract on `updateCount`**

| Caller | Delta shape |
|---|---|
| AbsorbSystem | `+1` per neutral absorbed |
| CollisionResolver | `+ceil(TRANSFER_RATE_effective(A,B) / 15)` winner, `-ceil(TRANSFER_RATE_effective(A,B) / 15)` loser, per-tick while overlapping (F3 dynamic rate based on count_delta) |
| ChestSystem | `-effective_toll` per Chest §F2 (= floor(`base_toll_scaled(tier, count)` × relic multipliers), post-F1 scaling; T1 ∈ [7, 24], T2 ∈ [28, 60], T3 = 120 flat) after `count > effective_toll` guard |
| RelicEffectHandler | variable (per-relic spec, defined in Relic System GDD) |

No other system may call `updateCount`. Enforced by server-only module placement (`ServerStorage/Source/CrowdStateServer/init.luau`).

### States and Transitions

Three states: `Active` / `GraceWindow` / `Eliminated`.

| State | count mutable | position mutable | collision drip | absorbs | chest | broadcasts |
|---|---|---|---|---|---|---|
| Active | yes | yes | yes | yes | if count > toll | yes |
| GraceWindow | up-only (Absorb/Relic+) | yes | **paused** | yes | no | yes |
| Eliminated | no | yes (character still moves) | no | no | no | yes |

| Trigger | From | To | Condition |
|---|---|---|---|
| `RoundLifecycle.createAll` | — | Active | match start, `count = CROWD_START_COUNT (10)` |
| CollisionResolver tick | Active | GraceWindow | count reaches floor (1) via drain AND overlap persists |
| Absorb / Relic +N | GraceWindow | Active | count > 1 via up-event (absorb or positive relic) |
| Overlap check tick | GraceWindow | Active | out of all rival overlaps |
| Grace timer `GRACE_WINDOW_SEC = 3` expires | GraceWindow | Eliminated | still overlapping at t=3s |
| `RoundLifecycle.destroyAll` | any | — | round end |

No revival from `Eliminated` in MVP. A future Relic GDD proposing revival must request a new transition here for approval.

### Interactions with Other Systems

**Absorb System**
- Fires `updateCount(crowdId, +1)` per neutral NPC absorbed, one call per NPC, no batching.
- Precondition: state ∈ {Active, GraceWindow}. Skip if Eliminated.

**Crowd Collision Resolution (drip model)**
- Server hit-detection tick (15 Hz, per ADR-0001) marks crowd pairs currently overlapping.
- For each overlapping pair (A, B) where `A.count >= B.count` (equal counts drain each other symmetrically):
  - `updateCount(A.id, +ceil(TRANSFER_RATE_effective(A,B) / 15))` — gain on A
  - `updateCount(B.id, -ceil(TRANSFER_RATE_effective(A,B) / 15))` — drain on B
  - `TRANSFER_RATE_effective(A,B)` from F3: `clamp(BASE + SCALE × max(0, A.count - B.count), BASE, MAX)`
- Equal-count clashes (A.count == B.count): count_delta=0 → TRANSFER_RATE_BASE applies → 1/tick at defaults. Symmetric mutual drain — whoever escapes first wins.
- No single-shot ratio swap. No cooldown. Pure drip.
- When B.count clamps to 1 AND pair still overlapping next tick → B transitions to `GraceWindow`, starts 3s timer.
- Timer cancels if B leaves all overlaps (including rivals other than A).

**Chest System**
- On interaction: check `count > toll` (strict). If false, reject, show UX-disabled prompt.
- If true: `updateCount(crowdId, -toll)` then grant relic via RelicEffectHandler.
- Tolls: T1=10, T2=40, T3=120 (tuning knobs; locked in this GDD until Relic/Chest GDD revises with economy-designer input).

**Relic System**
- All crowd-state-mutating relics route through `RelicEffectHandler` (no direct `CrowdStateServer` calls).
- Handler validates state ∈ {Active, GraceWindow} before applying.
- In `GraceWindow`: up-deltas (positive relic effects) apply and can restore count above 1, returning crowd to `Active`. Down-deltas (negative relic effects) are rejected — crowd at count=1 cannot lose further via relic.
- Non-state relics (absorb radius, move speed, toll discount) live in their own systems.

**Round Lifecycle**
- `createAll()` at round start: iterate all players, `CrowdStateServer.create(crowdId, initialState)` with `count = CROWD_START_COUNT`.
- `destroyAll()` at round end: iterate records, `CrowdStateServer.destroy(crowdId)`. Destruction order irrelevant.

**HUD / Player Nameplate**
- Read-only via `CrowdStateClient.get(crowdId)` local cache (mirrors broadcast).
- No write path from client.

**Implementation note (per gameplay-programmer + ADR-0001)**: Broadcast dispatched via Heartbeat accumulator pattern — accumulator increments each `RunService.Heartbeat`; broadcast fires when `accumulator >= 1/SERVER_TICK_HZ`, then resets. Maintains consistent average tick rate under server load (not `task.wait`, which drifts). Payload table pre-allocated and mutated in place to avoid GC churn. Template `Network` module currently lacks `UnreliableRemoteEvent` support — adding `UnreliableRemoteEventName` enum + `Network.connectUnreliableEvent()` wrapper is a prerequisite implementation task (belongs in the Crowd Replication epic, not this GDD's story scope).

**Network event contract (authoritative — supplements ADR-0001):**
- **15 Hz unreliable broadcast** (`CrowdStateBroadcast`) — AMENDED 2026-04-24 per design/gdd/crowd-replication-strategy.md Rules 6, 9, 10, 13:
  - Encoding: Luau `buffer` type MANDATORY for MVP (not table serialization).
  - Per-entry fields (30 bytes, buffer-encoded): `crowdId uint64`, `tick uint16` (monotonic server tick, out-of-order defense), `pos Vector3 [3×f32]`, `radius f32` (pre-composed `radius_from_count(count) × radiusMultiplier`), `count uint16`, `hue uint8` (safe palette index 1-12), `state uint8` enum `{Active=1, GraceWindow=2, Eliminated=3}`.
  - `hue` now carried in every broadcast (not join-event-only) — simplifies client cache, no CrowdJoined dependency for hue render on late packets. Prior spec (hue via `CrowdJoined` only) superseded.
  - `state` full enum including `Eliminated` — eliminated crowds continue broadcasting with `state=Eliminated` + `count=1` until `RoundLifecycle.destroyAll`. Client `CrowdStateClient` sets permanent `Eliminated` flag on first observation (broadcast OR reliable `CrowdEliminated` event, whichever arrives first); subsequent stale broadcasts MUST NOT un-eliminate a crowd.
  - Server writes `tick` as monotonic counter each broadcast; wraps at uint16 max (65535 ≈ 72 min at 15 Hz). Client tracks `lastReceivedTick` + discards stale packets per `tick_is_newer` formula (design/gdd/crowd-replication-strategy.md F4).
- **On relic acquire or expire** (reliable `CrowdRelicChanged` event): full `activeRelics` table snapshot for that crowdId. Fires only on change, not every tick.
- **On Eliminated transition** (reliable `CrowdEliminated` event): `{crowdId: string}`. Drives kill feed, UI state, round-end screen. NOTE (2026-04-24): with `state` now in broadcast, this reliable event is presentation trigger + cross-channel ordering redundancy, no longer the sole source of truth for elimination state.
- **On crowd record creation** (reliable `CrowdCreated` event): `{crowdId, hue, initialCount}` — fires from `CrowdStateServer.create()` at round start for every player. Carries full record identity. **Supersedes `CrowdJoined`** (renamed for consistency with `CrowdDestroyed`; hue moved to 15 Hz broadcast per prior amendment). Consumers: Player Nameplate (binds BillboardGui to character), HUD (leaderboard row init).
- **On crowd record destruction** (reliable `CrowdDestroyed` event): `{crowdId}` — fires from `CrowdStateServer.destroy()` on `PlayerRemoving` DC OR `RoundLifecycle.destroyAll()` at round end. **Distinct from `CrowdEliminated`:** Eliminated = state transition (record persists broadcasting `state=Eliminated` until round end); Destroyed = record removed from store. Consumers: Chest System (close draft modal if opener destroyed), Relic System (unhook per-crowd relic state), HUD (leaderboard row removal), Player Nameplate (billboard destroy).
- **On count ceiling clamp** (reliable `CrowdCountClamped` event): `{crowdId, attemptedDelta, clampedCount}` — fires when `updateCount()` applies a positive delta that would exceed `MAX_CROWD_COUNT = 300`. Filtered server-side to local player only (not broadcast to all clients). Consumers: HUD (MAX CROWD flash). **Debounce contract:** HUD MUST gate on once-per-cap-entry (suppress until count drops below 300 and re-enters) — server fire rate at steady 300-cap can reach 15 Hz under overlap conditions. Debounce lives in HUD, not CSM.

**Server-side signals (BindableEvent, server-only — NOT replicated to clients):**
- `CountChanged(crowdId, oldCount, newCount, deltaSource)` — fires after any successful `updateCount()` write. `deltaSource ∈ {"Absorb", "Collision", "Chest", "Relic"}`. Consumers: Round Lifecycle (peakCount tracking, placement sort input), analytics stubs, future in-session scoring. Clients continue to read count via 15 Hz `CrowdStateBroadcast`; this signal is for server bookkeeping only.

### Server API

All crowd-state access goes through this module. No system reaches around it. Module placement enforces server/client separation: server APIs in `ServerStorage/Source/CrowdStateServer/init.luau`; client cache in `ReplicatedStorage/Source/CrowdStateClient/init.luau`.

**Lifecycle**

| Method | Caller | Returns | Fires | Notes |
|---|---|---|---|---|
| `create(crowdId, initialState)` | `RoundLifecycle.createAll()` | new record | `CrowdCreated` | Fails if record exists. |
| `destroy(crowdId)` | `RoundLifecycle.destroyAll()`, `Players.PlayerRemoving` | — | `CrowdDestroyed` | Idempotent (no-op if absent). |

**Count mutation (write-access contract — 4 callers only)**

| Method | Caller | Returns | Fires | Notes |
|---|---|---|---|---|
| `updateCount(crowdId, delta, source)` | Absorb, CollisionResolver, Chest, RelicEffectHandler | `count_new` | `CountChanged`; optionally `CrowdCountClamped`, `CrowdEliminated` | Applies F5 clamp. `source ∈ DeltaSource` enum. See write-access contract table above. |

**Radius composition**

| Method | Caller | Returns | Fires | Notes |
|---|---|---|---|---|
| `recomputeRadius(crowdId, newMultiplier)` | `RelicEffectHandler` only | `radius_composed` | — | Writes `radiusMultiplier` (validated in [0.5, 1.5] per registry `RADIUS_MULTIPLIER_MAX` hard ceiling). Next broadcast carries new composed radius (F1). Idempotent — no-op if `newMultiplier == current`. |

**Read accessors (no side effects)**

| Method | Caller | Returns | Notes |
|---|---|---|---|
| `get(crowdId)` | any server system | `CrowdRecord?` | Server-only. Clients use `CrowdStateClient.get`. |
| `getAllActive()` | `CollisionResolver` | `{CrowdRecord}` | All records in state `Active` ∪ `GraceWindow` (excludes `Eliminated`). Returns references; caller MUST NOT mutate. |
| `getAllCrowdPositions()` | `NPCSpawner` | `{[crowdId]: Vector3}` | Snapshot map, excludes `Eliminated` records (their position is stale). |

**Overlap state write**

| Method | Caller | Returns | Notes |
|---|---|---|---|
| `setStillOverlapping(crowdId, flag)` | `CollisionResolver` only | — | Writes `stillOverlapping` field. CSM reads this each tick to evaluate GraceWindow timer (F7: `should_eliminate` requires `still_overlapping == true`). Last-write-wins within a tick. |

**Client-side read API**

| Method | Caller | Returns | Notes |
|---|---|---|---|
| `CrowdStateClient.get(crowdId)` | HUD, Nameplate, Follower Entity | `CrowdRecord?` | Read-only mirror of `CrowdStateBroadcast`. Cache lifecycle bounded by `CrowdCreated` / `CrowdDestroyed`. |

**Caller enforcement:** Violations of the caller restrictions (e.g. Absorb calling `recomputeRadius`, or any system calling `setStillOverlapping` other than CollisionResolver) are code-review blockers, not runtime guards. Server-only module placement makes cross-machine violation impossible; same-server violations caught via convention + PR review.

**Pillar 4 anti-pay-to-win contract (added 2026-04-24 per DSN-NEW-2 of gdd-cross-review-2026-04-24-pm.md).** Cosmetic systems (Skin System, future avatar/banner/trail systems) **MUST NOT mutate** any field of a crowd record — not `count`, not `radiusMultiplier`, not `state`, not `activeRelics`, not `hue` (hue is join-order deterministic, not skin-derived). Skin application is presentation-only (Follower Entity visual swap + player character visual swap) and flows exclusively through `CrowdStateClient` read-side on the client, never through any `CrowdStateServer` write API. Any cosmetic system attempting to register as a caller in the write-access contract table above is a code-review blocker. This is the architectural enforcement of Pillar 3 (no persistent power) + Pillar 4 (cosmetic expression ≠ mechanical advantage) + anti-pillar "not pay-to-win" stated in `design/gdd/game-concept.md:179`. Skin System GDD (VS-tier) must open with this constraint.

## Formulas

### F1. radius_from_count (base + multiplier composition)

`radius_base(count) = 2.5 + sqrt(count) * 0.55`
`radius(count, radiusMultiplier) = radius_base(count) * radiusMultiplier`

| Variable | Type | Range | Description |
|---|---|---|---|
| count | int | [1, 300] | Authoritative follower count |
| radiusMultiplier | f32 | [0.5, 1.5] | Composed relic multiplier; default 1.0 (baseline). Hard ceiling 1.5 per registry `RADIUS_MULTIPLIER_MAX`. |

**radius_base output range:** [3.05, 12.03] studs.
**Composed radius output range:** [1.53, 18.04] studs (floor at μ=0.5 count=1; ceil at μ=1.5 count=300).
**MVP composed range:** [3.05, 16.24] studs (μ=1.0 baseline to μ=1.35 Wingspan at count=300).
**Example at defaults:** `count=1, μ=1.0 → 3.05`; `count=100, μ=1.0 → 8.00`; `count=300, μ=1.35 (Wingspan) → 16.24`.
**Note:** `sqrt` compresses count growth intentionally — 1→100 adds 4.95 studs, 100→300 only 4.03. Prevents late-game hitbox bloat. `radiusMultiplier` is the sole relic lever on radius; all relic-driven radius changes route through `recomputeRadius(crowdId, newMultiplier)` (see §Server API). `hitbox_radius` broadcast field (ADR-0001) carries the pre-composed value; clients consume as-is without re-multiplying.

### F2. position_lag

`position_new = position_old + (char_pos - position_old) * CROWD_POS_LAG`

| Variable | Type | Range | Description |
|---|---|---|---|
| position_old | Vector3 | — | Prior tick authoritative crowd center |
| char_pos | Vector3 | — | `Character.HumanoidRootPart.Position` this tick |
| CROWD_POS_LAG | float | [0, 1] | Lag factor. Default **0.15**. |

**Output range:** Vector3 approaching `char_pos` asymptotically. At 0.15, 91.3% gap closed after 15 ticks (~1 second).
**Example:** Player standing still → position converges to fixed point. Player teleports 50 studs → first tick jumps 7.5 studs toward new pos, converges over ~8 ticks.

### F3. collision_transfer_per_tick

`TRANSFER_RATE_effective = clamp(TRANSFER_RATE_BASE + TRANSFER_RATE_SCALE × count_delta, TRANSFER_RATE_BASE, TRANSFER_RATE_MAX)`
`delta_per_tick = ceil(TRANSFER_RATE_effective / SERVER_TICK_HZ)`

| Variable | Type | Range | Description |
|---|---|---|---|
| TRANSFER_RATE_BASE | int | [10, 40] | Base drain rate (followers/sec) at zero count differential. Default **15**. |
| TRANSFER_RATE_SCALE | float | [0, 0.5] | Additional drain per follower of count advantage. Default **0.15**. |
| TRANSFER_RATE_MAX | int | locked **60** | Hard ceiling on effective rate — prevents instant-kill at extreme count gaps. |
| count_delta | int | [0, 299] | `max(0, attacker_count - defender_count)` this tick. |
| attacker_count | int | [1, 300] | Attacker's authoritative count (higher or equal). |
| defender_count | int | [1, 300] | Defender's authoritative count (lower or equal). |
| SERVER_TICK_HZ | int | locked **15** | ADR-0001 server hit-detection rate |

**Output range:** `ceil(15/15)=1` to `ceil(60/15)=4` followers per tick (per overlapping pair).
**Examples at defaults (BASE=15, SCALE=0.15):**
- 50 vs 50 (equal, delta=0): effective=15 → **1/tick each**. Both drain to 1 in ~49 ticks (3.27s). GraceWindow 3s each. Total ~6.27s to mutual elimination if neither escapes.
- 100 vs 50 (delta=50): effective=22.5 → ceil=**2/tick**. 50-count drains in 25 ticks (1.67s).
- 300 vs 50 (delta=250): effective=52.5 → ceil=**4/tick**. 50-count drains in 13 ticks (0.87s) — the "sickening lurch" experience.
- 300 vs 1 (extreme, delta=299): effective=59.85 → clamp to 60 → **4/tick**.
**Design rationale:** Large rivals feel genuinely more dangerous (Pillar 1: Snowball Dopamine). Equal-count clashes are tense extended standoffs, not instant coin-flips. Pillar 5 preserved — a low-count comeback player always takes 1–2/tick maximum, never the 4/tick reserved for extreme gaps.

### F4. triple_overlap_drain (additive stacking)

For each overlapping rival r where **r.count ≥ self.count**:
```
victim_delta     += -ceil(TRANSFER_RATE_effective(r, self) / SERVER_TICK_HZ)   -- drain on this crowd
attacker_gain(r) += +ceil(TRANSFER_RATE_effective(r, self) / SERVER_TICK_HZ)   -- mirrored gain on r
```
where `TRANSFER_RATE_effective(r, self)` uses `count_delta = max(0, r.count - self.count)` from F3.

| Variable | Type | Range | Description |
|---|---|---|---|
| overlapping rivals | set | ∅ to 11 pairs | Rivals overlapping this crowd with r.count ≥ self.count (**≥**, not >; equal-count rivals qualify) |
| victim_delta | int | [-44, 0] | Net drain on this crowd per tick (sum across all qualifying pairs) |
| attacker_gain(r) | int | [+1, +4] | Per-rival gain per tick (mirrored from that pair's drain; each rival gains independently) |

**Output:** Each qualifying pair contributes its own F3 drain; total drain and individual gains sum independently.
**Example at defaults (TRANSFER_RATE_BASE=15, SCALE=0.15):** A (count=100) pinned by B (count=200) + C (count=150):
- B vs A: count_delta=100 → effective=30 → **2/tick** drain on A, +2 gain on B
- C vs A: count_delta=50 → effective=22.5 → **2/tick** drain on A, +2 gain on C

| Tick | A | B | C |
|---|---|---|---|
| 0 | 100 | 200 | 150 |
| 5 | 80 | 210 | 160 |
| ~25 | 1 (→ GraceWindow) | ~250 | ~200 |

A drains at **-4/tick** total. Larger count gaps produce higher per-pair rates (up to 4/tick each) — a true pincer compounds fast. GraceWindow is the safety valve.

### F5. count_clamp

`count_new = clamp(count_old + delta, 1, 300)`

| Variable | Type | Range | Description |
|---|---|---|---|
| count_old | int | [1, 300] | Prior count |
| delta | int | [-∞, +∞] | Signed delta from any authorised caller |

**Output range:** [1, 300]. Unconditional safety clamp.
**Example:** `count=250, delta=+100 → 300`. `count=10, delta=-50 → 1` (then state machine evaluates GraceWindow eligibility — clamp is pure math).

### F6. hue_index

`hue_index = ((join_order - 1) mod 12) + 1`

| Variable | Type | Range | Description |
|---|---|---|---|
| join_order | int | [1, ∞) | 1-indexed player join order on server |

**Output range:** [1, 12]. 13th+ player recycles.
**Example:** `join_order=1 → 1`, `join_order=12 → 12`, `join_order=13 → 1`.
**Implementation guard:** `assert(join_order >= 1, "join_order must be 1-indexed")` upstream. Luau `-1 mod 12 = 11` would mis-assign hue 12 silently.

### F7. grace_timer

`should_eliminate = (os.clock() - timer_start) >= GRACE_WINDOW_SEC AND state == GraceWindow AND still_overlapping`

| Variable | Type | Range | Description |
|---|---|---|---|
| timer_start | float | — | `os.clock()` captured on GraceWindow entry |
| GRACE_WINDOW_SEC | float | [0.5, 10] | Default **3.0** |
| still_overlapping | bool | — | Any rival overlap active this tick |

**Tie-break rule:** On the tick where both `timer_expired` AND `overlap_cleared` become true, **overlap-clear takes priority** → transition back to Active at count=1. Pillar 5 (comeback always possible) wins simultaneity.

## Edge Cases

### Count clamping
- **If CollisionResolver drain results in count = 1** (whether count went below 1 and clamped, OR drained exactly to 1): enter `GraceWindow` if overlap persists. Check fires AFTER the drain+clamp is applied this tick. Rationale: Pillar 5 survival path.
- **If count would drop ≤0 via ChestSystem**: chest rejects the interaction entirely (strict `count > toll` guard). Toll never deducted. Prompt shows UX-disabled state.
- **If count would drop ≤0 via RelicEffectHandler**: clamp to 1; stay `Active`. No GraceWindow — relics are not eliminations.
- **If delta would exceed 300**: silently clamp to 300. All callers. Relic "MAX CROWD" flash on HUD communicates the clamp (UX concern for HUD GDD).

### State transitions
- **If `timer_expired` AND `overlap_cleared` on the same tick**: overlap-clear takes priority → transition to `Active` at count=1. Pillar 5 simultaneity wins.
- **If both A and B clamp to 1 on the same tick while overlapping**: both enter `GraceWindow` with independent 3s timers. If neither moves, both expire simultaneously → mutual elimination. Symmetric punishment matches equal-count symmetry.

### Position / character
- **If `Character.HumanoidRootPart` is missing on a position-lag tick**: skip the update, retain `position_old`. Do NOT clear collision state. Followers flock to stale position (1 tick imperceptible at 15 Hz). Resume on next tick. Handles void-fall / respawn without nil-error.
- **If character teleports >50 studs**: position lag creates ~8-tick visual rubber-band. Not a hitbox exploit (server-authoritative). Flag for playtest visual acceptability.

### Interaction contention (same-tick mutation ordering)
- **If multiple callers mutate the same crowdId in one 15 Hz tick**: apply deltas in fixed order:
  1. **CollisionResolver** (lethality check first — must set GraceWindow before absorbs pad)
  2. **RelicEffectHandler**
  3. **AbsorbSystem**
  4. **ChestSystem** (must see post-drain count for `count > toll` guard)
- **If Absorb +1 and Collision -2 fire same tick**: net -1 after ordered processing. Correct feel — absorbing one neutral while losing ground is accurate.
- **If triple-overlap (A vs B, C simultaneously)**: drain stacks additively per F4. No cap.

### Relics
- **If relic grants +N at count=300**: relic is consumed, delta clamps to 0 net (count stays 300). No refund. HUD flashes "MAX CROWD" to communicate no-op.

### Network / replication
- **If client receives no broadcast for >0.5s** (`STALE_THRESHOLD_SEC`): client cache freezes last known state visually. Do NOT interpolate to 0 or show "missing." Server does nothing differently — this is a client-contract concern, flagged for HUD/Replication GDD.
- **If a crowd transitions to Eliminated**: server fires reliable `CrowdEliminated` event with `{crowdId}`. Clients MUST use this event to update Eliminated state — the 15 Hz broadcast does not carry the Eliminated flag. 15 Hz broadcasts continue post-elimination so spectating clients see the frozen crowd's last position until `destroyAll()`.
- **If relic state changes** (acquire or expire): server fires reliable `CrowdRelicChanged` event with full `activeRelics` snapshot. `activeRelics` is NOT included in the 15 Hz broadcast payload.

### Lifecycle
- **If player DCs mid-round**: `CrowdStateServer.destroy(crowdId)` fires immediately. Any rival overlap pair referencing the destroyed id is simply absent from the next tick's overlap set. Resolver must tolerate missing records (already required by all destruction paths).
- **If player DCs during GraceWindow**: same as above — destroy immediately. Timer dies with the record.
- **If `RoundLifecycle.destroyAll` fires while crowds are in GraceWindow**: hard wipe all records unconditionally. No Eliminated transition, no stats impact, no timer resolution. GraceWindow is within-round only.

### Implementation guards
- **If `join_order < 1`**: `assert(join_order >= 1, "join_order must be 1-indexed")` upstream of hue_index. Luau `-1 mod 12 = 11` would silently mis-assign hue.
- **If caller other than the 4 authorised systems calls `updateCount`**: no runtime guard (server-only module placement makes it code-review-only). Violation is a code review blocker, not a defensive check.

### Configuration extremes
- **If 13th+ player joins** (outside 8-12 Roblox server cap): hue index recycles via `((N-1) mod 12) + 1`. Not a valid production configuration; acknowledged fallback, not a design feature.
- **If a Relic GDD proposes revival from `Eliminated`**: requires explicit amendment to this GDD's state machine (add `Eliminated → Active` transition). Blocked until cross-system review.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| ADR-0001 Crowd Replication Strategy | Proposed (pending `/architecture-review`) | `CrowdState` record shape, `UnreliableRemoteEvent` broadcast contract, 15 Hz tick rate, forbidden patterns | This GDD implements the state model the ADR defines |
| Network Layer (template) | Approved | `RemoteEvent` wiring; **gap**: needs new `UnreliableRemoteEvent` wrapper (`UnreliableRemoteEventName` enum + `Network.connectUnreliableEvent()` — implementation prereq) | Broadcast dispatch, client subscribe |
| PlayerData / ProfileStore (template) | Approved | **Not consumed.** Crowd state is ephemeral — deliberately bypasses ProfileStore (Pillar 3) | None — noted to prevent accidental persistence |
| Round Lifecycle (undesigned) | Not Started | `createAll()` at match start, `destroyAll()` at round end | Provisional — assumed to expose these two hooks; confirm when Round Lifecycle GDD authored |
| Art Bible §4 (safe palette) | Approved | 12-color hue palette mapped to `hue_index` 1-12 | Hue → RGB conversion at render time (client concern) |
| Art Bible §8 (follower budget) | Approved | Count ceiling = 300 sourced from this constraint | Locks `MAX_CROWD_COUNT` |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Follower Entity | Not Started | `CrowdStateClient.get(crowdId).count` for render-cap calc; `position` for flocking target | Read-only |
| Absorb System | Not Started | `CrowdStateServer.updateCount(crowdId, +1)` per absorbed neutral | Write (+1 delta) |
| Crowd Collision Resolution | Not Started | `CrowdStateServer.get(crowdId).position/radius/count`; `updateCount(crowdId, ±drip)` per tick while overlapping | Read + Write |
| Chest System | Not Started | `CrowdStateServer.get(crowdId).count` for `count > toll` guard; `updateCount(crowdId, -toll)` on purchase | Read + Write |
| Relic System | Not Started | `RelicEffectHandler` routes all crowd-mutation relic effects through `CrowdStateServer.updateCount` | Write (variable) |
| HUD | Not Started | `CrowdStateClient.get(crowdId).count` for local player's count display | Read-only |
| Player Nameplate | Not Started | `CrowdStateClient.get(crowdId).count/hue` for rival identification above head | Read-only |

### Provisional assumptions (flagged for cross-check)
- Round Lifecycle exposes `createAll()` / `destroyAll()` hooks — this GDD's state creation/destruction API assumes this shape. Round Lifecycle GDD must match or explicitly override.
- `RelicEffectHandler` exists as a mediator between Relic System and this module. Relic GDD must confirm this routing constraint.
- `hue_index → Color3` mapping is owned by a client rendering system (likely Follower Entity or VFX Manager), not this GDD. The safe palette lookup table lives in `SharedConstants/` per template convention.

### Bidirectional consistency notes
- When Follower Entity / Absorb / Collision / Chest / Relic / HUD / Round Lifecycle GDDs are authored, their Dependencies sections must list Crowd State Manager back-reference with matching interface shape.
- Systems Index update required: mark `Depended on by` column for this entry to reflect all 7 downstream systems.

## Tuning Knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `CROWD_START_COUNT` | 10 | [1, 50] | Initial count on match start | Crowds feel fat from tick 0 → reduces absorb dopamine ramp (Pillar 1) | 0 = auto-grace from turn 1, dead round | Chest T1 toll must stay `>` start count or no chest access round 1 |
| `CROWD_POS_LAG` | 0.15 | [0.05, 0.40] | Crowd-center lag behind character | Position snaps to character → jitter + teleport exploits visible | Position drifts behind — rubber-band flock look, hitbox mismatch | Feel coupling with character move speed |
| `TRANSFER_RATE_BASE` | 15 /sec | [10, 40] | Base collision drain at zero count differential (F3) | >40 makes equal-count fights resolve in <2s — too swingy | <10 makes every fight a stalemate | Sets floor for all collision drains |
| `TRANSFER_RATE_SCALE` | 0.15 | [0, 0.5] | Additional drain per follower of count advantage (F3) | >0.5 makes large rivals feel unfair — near-instant elimination | 0 = flat rate, no strategic differentiation | Works with BASE to tune lurch-vs-grind feel |
| `TRANSFER_RATE_MAX` | 60 | locked [30, 60] | Hard ceiling on effective drain rate (F3) | — (IS the ceiling) | <30 removes lurch at extreme count gaps | Changing requires design review; controls worst-case exposure |
| `GRACE_WINDOW_SEC` | 3.0 | [1.0, 5.0] | Escape window at count=1 | Elimination trivial to avoid → pushes Pillar 5 toward invincibility | <1s → feels like no grace at all; player can't react | Combines with character move speed for effective escape radius |
| `MAX_CROWD_COUNT` | 300 | [100, 500] | Hard ceiling | 500+ breaks mobile frame budget (art bible §8) | <100 eliminates late-game swell dopamine | Art bible §8 follower visual budget locks this |
| `MAX_RELIC_SLOTS` | 4 | [2, 6] | `activeRelics` list cap | 6+ makes relic interactions unreadable (Pillar 2 gamble loses meaning) | 1-2 trivialises chest decisions | Relic System + Chest System depend on this capacity |
| `T1_TOLL` (FLOOR) | 10 | [5, 20] | Small chest cost floor (Chest §F1 `max()` branch) | >20 locks out early chests → Pillar 2 deferred | <5 trivial; no sacrifice felt | **Intentional**: T1_TOLL=CROWD_START_COUNT — strict `count > toll` guard means players must earn 1 absorb before first chest. Post-Batch-5 2026-04-24: semantically the FLOOR of `base_toll_scaled`; effective toll floats above floor once count > T1_TOLL / T1_TOLL_PCT = 125. Chest System GDD F1 owns scaling. |
| `T1_TOLL_PCT` | 0.08 | [0.05, 0.15] | T1 percentage-of-count lever (Chest §F1) | >0.15 too punishing late-round (T1 toll > T2 floor) | <0.05 no late-game scaling (reverts to flat feel) | Added 2026-04-24 Batch 5 DSN-B-2. Transition count = T1_TOLL/T1_TOLL_PCT. |
| `T2_TOLL` (FLOOR) | 40 | [20, 80] | Car chest cost floor | >80 mid-round economy starved | <20 collapses T1 vs T2 distinction | Post-Batch-5: FLOOR branch; T2 effective @ count=300 = 60 via T2_TOLL_PCT=0.20. |
| `T2_TOLL_PCT` | 0.20 | [0.15, 0.30] | T2 percentage-of-count lever | >0.30 T2 competes with T3 toll at peak | <0.15 insufficient late-game scaling | Added 2026-04-24 Batch 5 DSN-B-2. |
| `T3_TOLL` | 120 | [60, 200] | Building chest cost (flat — T3_TOLL_PCT=0) | >200 rarely affordable except at `MAX_CROWD_COUNT` | <60 breaks rarity tier feel | Must stay `> (MAX_CROWD_COUNT - CROWD_START_COUNT) / 4` for late-round reward feel. Stays FLAT — already 40% of MAX at peak. |
| `T3_TOLL_PCT` | 0.0 | [0.0, 0.20] | T3 scaling lever (placeholder) | >0 makes T3 prohibitive at peak | — (0 is flat) | Added 2026-04-24 Batch 5 DSN-B-2. Future tuning if T3 opens MVP. |
| `STALE_THRESHOLD_SEC` | 0.5 | [0.2, 2.0] | Client-cache freeze threshold on broadcast loss | >2s shows very stale state on mobile lag spike | <0.2s triggers on normal network jitter → flickering HUD | Client-side concern; surfaces in HUD/Replication GDDs |

### Locked constants (NOT tuning knobs — changing requires ADR amendment)
- `SERVER_TICK_HZ = 15` — locked by ADR-0001
- `MIN_CROWD_COUNT = 1` — locked by Pillar 5 (main char always counts)
- `HUE_PALETTE_SIZE = 12` — locked by art bible §4

### Where knobs live (implementation guidance)
- All `CROWD_*` / `TRANSFER_*` / `GRACE_*` / `MAX_*` → `SharedConstants/CrowdConfig.luau` (new file)
- Toll values → `SharedConstants/ChestConfig.luau` (owned by Chest System GDD; this GDD provisions defaults only)
- `STALE_THRESHOLD_SEC` → client-side, likely `SharedConstants/CrowdClientConfig.luau`

## Acceptance Criteria

**AC-01 (Identity)** — GIVEN a match starts with two connected players, WHEN `RoundLifecycle.createAll()` is called, THEN each player has exactly one crowd record, keyed by `tostring(player.UserId)`, and no two records share the same key.

**AC-02 (DC Cleanup)** — GIVEN player P has an active crowd record (confirmed: `CrowdStateServer.get(P.crowdId) ~= nil`) with at least one active collision pair, WHEN `Players.PlayerRemoving` fires for P, THEN: (a) `CrowdStateServer.get(P.crowdId)` returns `nil` by the start of the next scheduled tick; (b) the collision overlap set for that tick contains no pair where either entry equals `P.crowdId`; (c) no Luau error is thrown during tick processing.

**AC-03 (Count Floor via Relic, F5)** — GIVEN a crowd at `count = 3` in Active with no rival overlap, WHEN `updateCount(crowdId, -50)` fires from RelicEffectHandler, THEN `count = 1`, state remains Active, no GraceWindow timer starts.

**AC-04 (Count Ceiling, F5)** — GIVEN `count = 250`, WHEN `updateCount(crowdId, +100)` fires, THEN `count = 300`, excess 50 discarded.

**AC-05 (Hue Assignment, F6)** — GIVEN players join in order 1, 2, 12, 13, WHEN crowd records are created, THEN `hue_index` = 1, 2, 12, 1 respectively (13th recycles via `((13-1) mod 12) + 1`).

**AC-06 (activeRelics cap)** — GIVEN `activeRelics = {A, B, C, D}` (4 slots full), WHEN a 5th relic is granted, THEN the grant is rejected, list still contains exactly 4 entries, no duplicates.

**AC-07 (Position Lag, F2)** — GIVEN `position_old = Vector3(0,0,0)`, `char_pos = Vector3(100,0,0)`, `CROWD_POS_LAG = 0.15`, WHEN one tick elapses, THEN `position_new = Vector3(15, 0, 0)`.

**AC-08 (Collision Drip, F3)** — GIVEN A.count=100 and B.count=50 actively overlapping, `TRANSFER_RATE_BASE=15`, `TRANSFER_RATE_SCALE=0.15`, `SERVER_TICK_HZ=15`, WHEN one tick elapses, THEN A gains exactly `+2` (count=102) and B loses exactly `-2` (count=48). (count_delta=50 → effective=22.5 → `ceil(22.5/15)=2`)

**AC-09 (Triple Overlap, F4)** — GIVEN A=100, B=200, C=150 with B and C both overlapping A, `TRANSFER_RATE_BASE=15`, `TRANSFER_RATE_SCALE=0.15`, WHEN one tick elapses, THEN: B vs A: count_delta=100 → effective=30 → 2/tick drain on A; C vs A: count_delta=50 → effective=22.5 → 2/tick drain on A; THEREFORE A loses exactly `-4` (count=96), B gains `+2` (count=202), C gains `+2` (count=152).

**AC-10 (Equal-Count Drain, F3/F4)** — GIVEN A=50 and B=50 actively overlapping (`r.count >= self.count` condition met for both), `TRANSFER_RATE_BASE=15`, `TRANSFER_RATE_SCALE=0.15`, WHEN one tick elapses, THEN both A=49 and B=49. (count_delta=0 → effective=15 → `ceil(15/15)=1` per tick each.) Neither gains; mutual drain at base rate.

**AC-11 (Grace entry + Active exit, F7)** — GIVEN B at `count=3` Active, overlapping a larger rival, WHEN collision drip reduces B.count to 1 with rival still present, THEN B transitions to GraceWindow and a 3-second timer starts; AND if B moves out of all rival overlaps before 3s expire, B transitions back to Active at `count=1`.

**AC-12 (Grace → Eliminated, F7)** — GIVEN B in GraceWindow with overlap persisting, WHEN 3.0 seconds elapse (`GRACE_WINDOW_SEC = 3.0`), THEN B transitions to Eliminated; `count` is not mutated further; collision drip on B stops.

**AC-13 (Tie-Break)** — GIVEN B in GraceWindow at exactly t=3.0s, WHEN grace timer expires AND rival overlap clears on the same tick, THEN B transitions to Active at `count=1` (overlap-clear wins; Eliminated is NOT triggered).

**AC-14 (Chest Reject)** — GIVEN a crowd at `count=10` and a T1 chest with `toll=10`, WHEN the player attempts chest interaction, THEN the interaction is rejected (strict `count > toll` requires `count ≥ 11`), `count` remains 10, UX-disabled prompt is shown.

**AC-15 (Same-Tick Ordering)** — GIVEN `count=3`, simultaneously receiving Collision `-2`, Relic `+5`, Absorb `+1`, Chest `-10`, WHEN all four callers fire in the same tick, THEN deltas apply in order Collision → Relic → Absorb → Chest: `3-2=1` (GraceWindow check) → `1+5=6` (back to Active) → `6+1=7` → Chest guard `7>10` false, rejects. Final `count=7`.

**AC-16 (Round Lifecycle, F1)** — GIVEN a fresh match with 8 players, WHEN `RoundLifecycle.createAll()` is called, THEN all 8 records exist with `count=10` and `radius = 2.5 + sqrt(10) * 0.55 ≈ 4.24` studs; AND WHEN `RoundLifecycle.destroyAll()` is subsequently called, all 8 records are absent from the store.

**AC-17 (Performance — Integration/Performance evidence required)** — GIVEN 12 active crowds with O(p²)=66 pair overlap checks per tick, WHEN one full 15 Hz tick executes (state update + broadcast), THEN total server CPU time for this system < 1 ms, verified by server-side `os.clock()` delta logged during a 60-second soak test in Roblox Studio. *Evidence type: Integration/Performance — not unit-testable in TestEZ; requires Studio profiler soak.*

**AC-18 (Replication Correctness — Integration evidence required)** — GIVEN a client with handlers registered for `CrowdStateBroadcast`, `CrowdRelicChanged`, and `CrowdEliminated`, WHEN the server mutates `count` from 100 to 102 on a tick, THEN within 1 broadcast interval (≤67 ms at 15 Hz), the client cache reflects `count=102`, `radius ≈ 8.05` studs, and no other broadcast field changes; AND relic and Eliminated transitions fire correctly via their respective reliable events. *Evidence type: Integration — not unit-testable in TestEZ; requires multi-client Studio test.*

**AC-20 (Eliminated Replication — Integration evidence required)** — GIVEN client C is subscribed to crowd state updates for player B, WHEN B's server-side crowd transitions to Eliminated (grace timer expires with overlap persisting), THEN: (a) server fires `CrowdEliminated` with `{crowdId = B.crowdId}` before the next 15 Hz broadcast; (b) client C's state for B reflects Eliminated; (c) subsequent 15 Hz broadcasts for B continue to arrive but do NOT change the Eliminated flag back to Active or GraceWindow. *Evidence type: Integration — multi-client Studio test.*

**AC-19 (nil HumanoidRootPart)** — GIVEN `Character.HumanoidRootPart` is nil on a position-lag tick (void fall, respawn transition), WHEN position lag evaluates, THEN `position` retains `position_old`, no error is thrown, and collision state is NOT cleared.

**AC-21 (radiusMultiplier composition, F1)** — GIVEN a crowd with `count=100` and `radiusMultiplier=1.35` (Wingspan active), WHEN the next 15 Hz broadcast fires, THEN the broadcast `radius` field equals `(2.5 + sqrt(100) * 0.55) * 1.35 = 10.80` studs; AND `CrowdStateClient.get(crowdId).radius` reflects `10.80` within one broadcast interval.

**AC-22 (recomputeRadius write contract)** — GIVEN a crowd with `radiusMultiplier=1.0`, WHEN `RelicEffectHandler` calls `CrowdStateServer.recomputeRadius(crowdId, 1.35)`, THEN `radiusMultiplier` field is set to `1.35`, the next broadcast reflects the new composed radius, AND a second call with `1.35` (same value) is a no-op (no broadcast dirty flag set). GIVEN a call with `newMultiplier=1.8` (outside [0.5, 1.5] hard ceiling per registry `RADIUS_MULTIPLIER_MAX`), THEN the call is rejected (value unchanged, assertion logged).

**AC-23 (CrowdCreated fires on create)** — GIVEN a fresh match with 8 players joining, WHEN `RoundLifecycle.createAll()` runs, THEN every client receives exactly 8 `CrowdCreated` events with payload `{crowdId, hue, initialCount=10}`; AND no duplicate `CrowdCreated` fires for the same crowdId within one match.

**AC-24 (CountChanged fires on updateCount)** — GIVEN a crowd at `count=50`, WHEN Absorb writes `updateCount(crowdId, +1, "Absorb")`, THEN the server-side `CountChanged` BindableEvent fires with `{crowdId, oldCount=50, newCount=51, deltaSource="Absorb"}` before the next tick; AND no `CountChanged` fires if `delta=0` effective (e.g. all of the delta absorbed by F5 clamp at the 300 ceiling with count already at 300).

**AC-25 (CrowdCountClamped fires at ceiling)** — GIVEN a crowd at `count=298`, WHEN Absorb writes `updateCount(crowdId, +5, "Absorb")`, THEN count clamps to 300, AND `CrowdCountClamped` fires to the local player with `{crowdId, attemptedDelta=+5, clampedCount=300}`. GIVEN a subsequent same-tick `updateCount(crowdId, +2, "Absorb")` with count still at 300, THEN `CrowdCountClamped` fires AGAIN (per-call semantic — debounce is HUD's responsibility per contract).

**AC-26 (CrowdDestroyed fires on destroy)** — GIVEN a crowd in state `Eliminated`, WHEN `RoundLifecycle.destroyAll()` runs, THEN `CrowdDestroyed` fires with `{crowdId}` for every client; AND `CrowdStateServer.get(crowdId)` returns nil after destroy. SEPARATELY, GIVEN an active crowd and `Players.PlayerRemoving` fires for that player mid-round, THEN `CrowdDestroyed` fires immediately (not deferred to round-end), and the record is absent from the next tick's `getAllActive()` result.

**AC-27 (getAllActive excludes Eliminated)** — GIVEN 3 crowds: A (Active), B (GraceWindow), C (Eliminated), WHEN `CollisionResolver` calls `CrowdStateServer.getAllActive()`, THEN the returned list contains exactly {A, B} in some order and excludes C. GIVEN a crowd transitions to `Eliminated` mid-tick, THEN it is excluded from the NEXT tick's `getAllActive()` result (current-tick inclusion tolerated — eliminated crowd cannot gain or lose count per the state table).

**AC-28 (setStillOverlapping semantics)** — GIVEN CollisionResolver observes rival overlap on crowd B during tick N, WHEN it calls `setStillOverlapping(B.crowdId, true)`, THEN `CrowdStateServer.get(B.crowdId).stillOverlapping == true` for the duration of tick N. GIVEN the next tick N+1 CollisionResolver observes no overlap and calls `setStillOverlapping(B.crowdId, false)`, THEN if B is in `GraceWindow`, the F7 grace-timer evaluation on tick N+1 returns `should_eliminate = false` (overlap cleared).
