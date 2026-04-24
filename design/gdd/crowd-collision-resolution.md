# Crowd Collision Resolution

> **Status**: In Design (2026-04-24 Batch 2 propagation — radius range [3.05, 12.03] → composed [1.53, 18.04] in F1 var tables; 7 stale "CSM amendment required" flags for `getAllActive()` + `setStillOverlapping()` cleared — CSM Batch 1 2026-04-24 landed both APIs. AC-20 perf budget (66 pairs) unchanged — review report "1200 → 3600" was mis-attributed to CCR; belonged to Absorb AC-17 (fixed in prior pass).)
> **Author**: user + game-designer + systems-designer + art-director + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine), 5 (Comeback Always Possible)

## Overview

The **Crowd Collision Resolution** system is the server-authoritative gameplay module that runs the 15 Hz hit-detection tick at the heart of Crowdsmith's combat. Every 66 ms, for every pair of active crowds in the match, it performs one 2D squared-distance overlap test against their authoritative positions and `radius_from_count`-derived radii (both served by **Crowd State Manager**), builds the set of overlapping pairs, and for each pair applies the **drip model** locked by Crowd State §C.3 — one `updateCount` call per side using the dynamic `TRANSFER_RATE_effective` from `collision_transfer_per_tick` (F3). The larger-count crowd gains, the smaller loses; equal-count clashes mutually drain at base rate; a triple-overlap stacks additively per F4. When a crowd's count reaches the floor of 1 with an overlap still active, this system feeds the state signal that drives Crowd State's `Active → GraceWindow` transition (owned upstream); when the 3-second grace timer expires with overlap persisting, Crowd State fires the `CrowdEliminated` event — this system's only role in elimination is supplying the authoritative overlap bit each tick. A companion client-side path observes broadcast count deltas and dispatches `FollowerEntity.startPeel(ownId, rivalId, n)` so the player sees the exact number of their followers peel off and cross over to the rival mob with a 50%-transit hue flip. The system is also the tick-loop owner — **Absorb System** piggybacks on the same pass (Absorb §C), and adding any future per-tick gameplay system (e.g., Chest-raid interrupt, Relic overlap effects) means subscribing to this loop rather than running a second one. Together with `radius_from_count`, this module is the machinery that turns the snowball into a weapon: mass is what you have, contact is what you spend, and the crowd who lingers in the wrong overlap is the crowd who vanishes. **ADR-0001 (Crowd Replication Strategy)** fixes the 15 Hz cadence, server authority, and O(p²) pair-check model this GDD realizes; this GDD specifies the algorithm.

## Player Fantasy

You feel it before you see the number move. Overlap: your counter stutters, then bleeds. 212, 209, 205 — your people are peeling off you, flipping their hue as they cross the gap, feeding the color that's eating yours. Two seconds to choose: run and staunch the wound, or plant your feet and trust the math. Get it wrong and you're down to one, the grace clock ticking over your head while you thread a lone body through a swarm that already owns you. Get it right and you break contact 30 fatter than when they hit you — their ambition, now your parade.

## Detailed Design

### Core Rules

The Crowd Collision Resolution system owns the server-side 15 Hz hit-detection tick loop mandated by ADR-0001. The tick loop itself is hosted by a separate `TickOrchestrator` module (sibling) that calls this system's `tick()` function first each pass (Crowd State §E same-tick ordering). This system is pure tick-logic — no Heartbeat, no `task.wait`.

**Module paths**
- Server (logic): `ServerStorage/Source/Crowd/CollisionResolverServer/init.luau`
- Server (per-tick orchestrator): `ServerStorage/Source/Crowd/TickOrchestrator/init.luau` — owns Heartbeat accumulator; sequences Collision → Relic → Absorb → Chest → Broadcast → PeelDispatch per Crowd State §E
- Server (peel dispatch): `ServerStorage/Source/Crowd/PeelDispatcher/init.luau`
- Client: `ReplicatedStorage/Source/Crowd/CollisionResolverClient/init.luau`

**1. Tick cadence (consumed from ADR-0001)**
- `TickOrchestrator` uses the Heartbeat accumulator pattern (same as Crowd State §C implementation note): `accumulator += dt`; while `accumulator >= (1 / SERVER_TICK_HZ)` → reset and run one full tick sequence. Overflow (2+ ticks in one Heartbeat callback) is acceptable and safe — every tick reads post-mutation state from the previous tick.
- `CollisionResolver.tick()` runs FIRST each sequence, before `AbsorbSystem.tick()`, before `CrowdStateServer.broadcastAll()`, before `PeelDispatcher.flush()`. Ordering is enforced by direct sequential function calls in `TickOrchestrator._runTick()`.

**2. Pair iteration (naive O(p²), lex-ordered, deterministic)**
- Each tick, read all active crowd records from `CrowdStateServer.getAllActive()` (point-in-time snapshot, excludes `Eliminated` crowds — ✓ CSM Batch 1 2026-04-24 landed this API).
- Sort `crowdIds` lexicographically into module-level scratch buffer (reused, cleared with `table.clear`).
- Iterate pairs with `i < j` to visit each unordered pair exactly once.
- At 12 players = 66 pairs × 15 Hz = 990 distance checks/sec (trivial per ADR-0001 prototype).

**3. Pair overlap test (2D, squared distance — same pattern as Absorb §F1)**
- `overlapping = (A.pos.X - B.pos.X)² + (A.pos.Z - B.pos.Z)² <= (A.radius + B.radius)²`
- Y axis ignored. Elevated crowds can overlap ground crowds horizontally (intentional, consistent with Absorb §E).
- Radius is `radius_from_count` (Crowd State §F1, registry) — read per-tick from `CrowdStateServer.get(id).radius`, precomputed by Crowd State when count changes.

**4. Pair-skip conditions (applied during iteration)**
- Skip pair if `CrowdStateServer.get(id)` returns `nil` for either crowd (PlayerRemoving race — Crowd State §E cleanup tolerance).
- Skip pair if either crowd's `state == Eliminated`.
- **Drip application is restricted to pairs where BOTH crowds are `Active`.** GraceWindow crowds are present in overlap-set maintenance (Rule 6) but their drip is **paused** per Crowd State §states table.

**5. Per-pair drip application (for qualifying Active-vs-Active pairs)**

For each overlapping pair `(A, B)` with both in `Active`:

1. Determine attacker/defender by count. If `A.count == B.count`: both are attacker-of-other (symmetric mutual drain).
2. `count_delta = max(0, attacker.count - defender.count)`.
3. `TRANSFER_RATE_effective = clamp(TRANSFER_RATE_BASE + TRANSFER_RATE_SCALE × count_delta, TRANSFER_RATE_BASE, TRANSFER_RATE_MAX)` (Crowd State §F3 — registry-locked).
4. `delta_per_tick = ceil(TRANSFER_RATE_effective / SERVER_TICK_HZ)` (range [1, 4]).
5. Call `CrowdStateServer.updateCount(attacker.id, +delta_per_tick)` then `updateCount(defender.id, -delta_per_tick)`.
6. Record pair entry into pre-allocated `_overlapPairs` array: `{attackId, defendId, delta_per_tick}`. For equal-count case, emit **two** entries — `{A, B, 1}` and `{B, A, 1}` — so per-client peel dispatch renders symmetric mutual attrition.
7. Mark both `crowdId`s as overlapping this tick in pre-allocated `_overlapFlags` dict.

**6. Overlap-bit feed (every tick, after drip pass)**

For every crowd record in `getAllActive()` (regardless of state), call:
```
CrowdStateServer.setStillOverlapping(crowdId, _overlapFlags[crowdId] == true)
```

Crowd State consumes this each tick to drive:
- `Active + count == 1 + still_overlapping == true` → internal transition to `GraceWindow` (Crowd State §C.2 trigger row).
- `GraceWindow + still_overlapping == false` → cancel grace timer, return to `Active` (Crowd State §F7 tie-break).
- `GraceWindow + still_overlapping == true + timer_expired` → transition to `Eliminated` (Crowd State §F7); Crowd State fires the reliable `CrowdEliminated` event.

**This system does NOT own the timer, the transition, or the `CrowdEliminated` event fire — only the overlap bit feed.**

**7. Pair-entered event for VFX/Audio (reliable, once per contact)**
- Maintain `_prevOverlapKeys` set (string `"idA|idB"` keys, lex order).
- After building `_currOverlapKeys` this tick, for every key in `_curr \ _prev`: fire `Network.fireClients(CollisionContactEvent, {crowdIdA, crowdIdB})` — reliable RemoteEvent, global broadcast.
- No event on `pairSustained` or `pairExited` at MVP. VFX/Audio subscribe to `CollisionContactEvent` for impact flash + collision-start stinger (see §V/A).
- Low frequency (~2-6 pairs/tick peak per ADR-0001 prototype): bandwidth negligible.
- Assign `_prev ← _curr` at end of tick.

**8. Per-client peel dispatch (unreliable, relevance-filtered)**

`PeelDispatcher.flush(_overlapPairs)` runs AFTER `broadcastAll()` each tick:
1. For each connected `player`:
   - Clear pre-allocated `_playerBuffers[UserId]` (or create if missing).
   - Scan `_overlapPairs`; append any entry where `entry.attackId == player.crowdId OR entry.defendId == player.crowdId` as `{loserId, winnerId, n}` from this player's perspective.
   - If buffer is non-empty, `UnreliableCollisionPeelRemote:FireClient(player, buffer)`.
2. Buffer payload: `{{loserId: string, winnerId: string, n: int}, ...}` — 1-11 entries typical. ~40 bytes × 3 pairs × 15 Hz ≈ 1.8 KB/s per client, within ADR-0001 10 KB/s budget.
3. Bandwidth rationale: global broadcast of all 66 pairs = ~39.6 KB/s per client (blows budget 4×). Per-client filter sends only pairs involving that player's crowd.
4. Unreliable delivery is acceptable — peel is cosmetic-only (ADR-0001 §Consequences).

**9. Client-side peel observation**

`CollisionResolverClient` subscribes to the unreliable peel remote:
```
Network.connectUnreliableEvent(CollisionPeelEvent, function(buffer)
    for _, entry in buffer do
        FollowerEntityClient.startPeel(entry.loserId, entry.winnerId, entry.n)
    end
end)
```

- `startPeel` is called on the LOSER's FollowerEntity (matches Follower Entity §C.3 contract). The loser's instance selects followers closest-to-rival via F6, state → `Peeling`, retargets boids, hue-flip at 50% transit, despawn-on-arrival at rival crowd center. Rival-side spawn (`Spawning:FadeIn`) fires organically from Follower Entity's arrival hook.
- In the equal-count symmetric case, the buffer contains two entries (`A→B` and `B→A` with n=1 each); both fire `startPeel` independently → both mobs peel one follower toward each other → visual mutual attrition (the "Foot Race" moment of Pillar 5).

**10. Write-access contract**

This system writes to:
- `CrowdStateServer.updateCount(crowdId, ±delta_per_tick)` — drip only, integer deltas [-4, +4] per pair per tick
- `CrowdStateServer.setStillOverlapping(crowdId, bool)` — once per crowd per tick

This system does NOT write to: any other state store, any follower rig, any client cache, any PlayerData.

### States and Transitions

Two states. No per-pair state machine.

| State | Description | Tick behavior |
|---|---|---|
| `Dormant` | Pre-round or post-round. `_overlapPairs`, `_overlapFlags`, `_prevOverlapKeys` all empty. | `tick()` no-ops early — does not even query `getAllActive()`. |
| `Ticking` | Round active. All §Core Rules apply. | Runs full tick sequence. |

| Trigger | From | To | Notes |
|---|---|---|---|
| `RoundLifecycle.createAll()` completes | Dormant | Ticking | `CollisionResolverServer.start()`. Accumulator and all scratch buffers reset. Crowd records guaranteed to exist per Crowd State §Dependencies. |
| `RoundLifecycle.destroyAll()` fires | Ticking | Dormant | `CollisionResolverServer.stop()`. In-flight tick (if mid-sequence inside `TickOrchestrator._runTick`) completes naturally — the state flip is observed on the NEXT Heartbeat tick. |

No `Paused` state. Server lag spikes handled by accumulator overflow (multiple ticks per Heartbeat callback).

### Interactions with Other Systems

| System | Direction | Interface | Data flow | Owner |
|---|---|---|---|---|
| **TickOrchestrator** (sibling) | Inbound (callback) | `CollisionResolverServer.tick(crowdStateServer, outPairs, outFlags)` called sequentially each tick | Control | TickOrchestrator owns Heartbeat; calls this system first per tick |
| **Crowd State Manager** | Read | `CrowdStateServer.get(crowdId).{position, radius, count, state}` — nil-tolerant | Per-pair read | Crowd State |
| **Crowd State Manager** | Read | `CrowdStateServer.getAllActive(): {[string]: CrowdState}` — snapshot (returns Active ∪ GraceWindow; excludes Eliminated) | Per-tick iteration source | ✓ CSM Batch 1 Applied 2026-04-24 |
| **Crowd State Manager** | Write | `CrowdStateServer.updateCount(crowdId, ±delta)` — integer deltas [-4, +4] per call | Per overlapping pair × 2 calls | Crowd State §C.1 write-access contract already lists CollisionResolver as authorised caller |
| **Crowd State Manager** | Write | `CrowdStateServer.setStillOverlapping(crowdId, bool)` — fires once per crowd per tick | Drives GraceWindow entry/exit + timer (CSM F7 `should_eliminate` consumer) | ✓ CSM Batch 1 Applied 2026-04-24 |
| **Absorb System** | Peer (shared tick) | Both register with `TickOrchestrator`. Collision runs first each tick per Crowd State §E. No direct call between the two. | Peer | TickOrchestrator |
| **Round Lifecycle** | Inbound (control) | `CollisionResolverServer.start()` called by `createAll()`. `CollisionResolverServer.stop()` called by `destroyAll()`. | Control | Round Lifecycle |
| **Follower Entity (client)** | Outbound (client-side call) | `FollowerEntityClient.startPeel(loserCrowdId, winnerCrowdId, n)` from `CollisionResolverClient` on unreliable event receipt | Server → client dispatch | Follower Entity §C.3 contract locked |
| **VFX Manager** (undesigned) | Outbound (signal) | Subscribes to reliable `CollisionContactEvent(crowdIdA, crowdIdB)` — fires once per `pairEntered` tick | Server → client | **VFX Manager GDD must register consumer** |
| **Audio Manager** (undesigned, VS) | Outbound (signal) | Subscribes to same `CollisionContactEvent` for `sfx_crowd_collision_start` stinger | Server → client | **Audio Manager GDD must register consumer** |
| **Network layer (template)** | Infrastructure | Requires `UnreliableRemoteEventName.CollisionPeelEvent` + `Network.connectUnreliableEvent` / `Network.fireUnreliableClient` wrappers | Implementation prereq | Shared prereq with Crowd State broadcast — part of Crowd Replication epic |
| **Network layer (template)** | Infrastructure | Requires `RemoteEventName.CollisionContactEvent` (reliable, standard enum) | Implementation prereq | Standard `Network` path |

### Design tensions flagged

1. ✓ **RESOLVED 2026-04-24** — `getAllActive()` + `setStillOverlapping()` landed on Crowd State Manager via CSM Batch 1 amendment hub (`/propagate-design-change` CSM run 2026-04-24). Both backward-compatible additions, no behavior change to existing callers. CollisionResolver now has the required iteration source + overlap-bit feed. See `docs/architecture/change-impact-2026-04-24-csm-batch1.md`.

2. **Equal-count peel emits two unreliable packets per tick per pair**. At 15 Hz sustained mutual-drain, that is 30 packets/sec per pair to up to 12 clients. Typical simultaneous equal-count pairs will be 0-2. Bandwidth impact remains within budget. If playtest reveals the two-way visual is confusing, fall back to single-direction peel via a tuning knob (`EQUAL_COUNT_VISUAL_MODE`).

3. **Peel dispatch timing vs. broadcast state**. Peel events are fired AFTER `broadcastAll()` — clients receive the broadcast (new count values) and the peel event (n followers to visually peel) within the same server tick. Client visual lag between the two is bounded by one Heartbeat (<33ms at 30 FPS, <17ms at 60 FPS). Cosmetic-only per ADR-0001.

## Formulas

This system owns NO balance-sensitive formulas. Drip rate, radius, and triple-overlap stacking are registry-locked by **Crowd State Manager** and **ADR-0001** — cited here but NOT redefined. The four formulas below are mechanics-specific to the tick loop.

### Inherited (registry-locked — cited only)

| Formula | Source | Output | Cited for |
|---|---|---|---|
| `radius_from_count` (composed) | ADR-0001 / Crowd State §F1 | [1.53, 18.04] studs (post-composed w/ `radiusMultiplier`); baseline [3.05, 12.03] at μ=1.0; MVP max [3.05, 16.24] at μ=1.35 Wingspan | F1 overlap test radii — read `crowd.radius` directly (post-composed by CSM) |
| `collision_transfer_per_tick` | Crowd State §F3 | [1, 4] followers/tick/pair | Drip `delta_per_tick` (§C Rule 5) |
| `triple_overlap_drain` (additive) | Crowd State §F4 | naturally handled by per-pair loop | §C Rule 5 executes each pair's drip independently; Crowd State F5 clamp absorbs excess when `count == 1` |

### F1. pair_overlap_test

`overlapping = ((A.pos.X - B.pos.X)² + (A.pos.Z - B.pos.Z)²) <= (A.radius + B.radius)²`

| Variable | Type | Range | Description |
|---|---|---|---|
| `A.pos, B.pos` | Vector3 | world | Authoritative crowd positions (Crowd State §F2 `position_lag`) |
| `A.radius, B.radius` | float | [1.53, 18.04] | Post-composed `crowd.radius` from CSM §F1 (`radius_from_count(count, radiusMultiplier)`). MVP range [3.05, 16.24] at μ=1.0 baseline to μ=1.35 Wingspan. |
| `distance_sq` | float | [0, ∞) | Squared 2D horizontal distance. Y axis ignored. |
| `combined_radius_sq` | float | [37.22, 578.88] | `(A.radius + B.radius)²` |

**Output**: bool. Squaring avoids `sqrt` at pair-test time (no per-tick sqrt at all — radius sqrt is paid once per count-change inside Crowd State, cached in the record).

**Output range** for `combined_radius_sq`: `(3.05 + 3.05)² = 37.21` at minimum (both at count=1) → `(12.03 + 12.03)² = 578.88` at maximum (both at count=300).

**Example** (both at count=100, radius=8.00 each, positions 10 studs apart on X):
- `distance_sq = (10)² + 0² = 100`
- `combined_radius_sq = (8 + 8)² = 256`
- `100 <= 256 → overlapping = true`

### F2. pair_key (lex-ordered canonical key)

`pair_key = (a < b) ? a .. "|" .. b : b .. "|" .. a`

| Variable | Type | Range | Description |
|---|---|---|---|
| `a, b` | string | `tostring(UserId)` | The two `crowdId` values |
| `pair_key` | string | `"lower|higher"` | Canonical lex-ordered string key |

**Output**: string. Guaranteed unique per unordered pair; used as map key in `_currOverlapKeys` / `_prevOverlapKeys` for `pairEntered` diff (§C Rule 7).

**Example**: `crowdId` values `"3891"` and `"512"`. Lex-compare `"3891" < "512"` in Luau string compare returns `true` (lex compares char-by-char: `"3"` < `"5"`), so `pair_key = "3891|512"`. (Note: string lex is NOT numeric sort — this is fine because the key is an opaque string, never ordered-for-meaning.)

### F3. delta_per_tick_from_pair (instantiation of registry `collision_transfer_per_tick`)

`delta_per_tick = ceil(clamp(TRANSFER_RATE_BASE + TRANSFER_RATE_SCALE × count_delta, TRANSFER_RATE_BASE, TRANSFER_RATE_MAX) / SERVER_TICK_HZ)`

This is NOT a new formula — it is the instantiation this system performs per-pair each tick using the registry-locked `collision_transfer_per_tick`. Variables, output range, and examples are owned by Crowd State §F3 and registered. This GDD only specifies the **invocation site**: inside the per-pair loop of §C Rule 5, using the attacker/defender count difference computed this tick.

**Variables** (reference Crowd State §F3):

| Variable | Source |
|---|---|
| `TRANSFER_RATE_BASE` | Registry constant, 15 |
| `TRANSFER_RATE_SCALE` | Registry constant, 0.15 |
| `TRANSFER_RATE_MAX` | Registry constant, 60 |
| `SERVER_TICK_HZ` | Registry constant, 15 |
| `count_delta` | `max(0, attacker.count - defender.count)` at tick time |
| `delta_per_tick` | int, range [1, 4] |

**Example invocations** (at defaults, cited from Crowd State §F3 worked examples):
- A=100, B=50: `count_delta=50` → effective=22.5 → `delta_per_tick=ceil(22.5/15)=2`. A gains +2, B loses −2.
- A=300, B=1: `count_delta=299` → effective clamp to 60 → `delta_per_tick=ceil(60/15)=4`. A gains +4, B loses −4.
- A=50, B=50 (equal): `count_delta=0` → effective=15 → `delta_per_tick=ceil(15/15)=1`. Both lose −1 (mutual drain).

### F4. peel_buffer_relevance_filter (per-client dispatch)

For each `player` on each tick, the PeelDispatcher builds a filtered buffer:

```
filtered_buffer = { entry ∈ _overlapPairs : entry.attackId == player.crowdId OR entry.defendId == player.crowdId }
```

mapped to `{loserId, winnerId, n}` per entry.

| Variable | Type | Range | Description |
|---|---|---|---|
| `_overlapPairs` | array | size [0, ~66 × 2] (×2 from equal-count two-way emission) | All overlapping pairs this tick, per §C Rule 5 |
| `player.crowdId` | string | `tostring(UserId)` | Recipient player's crowd ID |
| `filtered_buffer` | array | size [0, 11] typical | Pairs involving this player's crowd (max 11 = n-1 rivals) |

**Output**: filtered array sent via `FireClient(player, buffer)` on `UnreliableRemoteEventName.CollisionPeelEvent`. Empty buffer → no `FireClient` call.

**Bandwidth projection** at defaults:
- Entry size: 3 fields × ~13 bytes average (two UserId strings + int) ≈ 40 bytes
- Worst case sustained per player: 3 active pairs × 15 Hz × 40 bytes = **1.8 KB/s per client**
- ADR-0001 budget per client: **10 KB/s** ✓

**Example** (crowd "111" vs "222" and "111" vs "333" both overlap this tick):
- `_overlapPairs = [{attackId:"111", defendId:"222", delta:2}, {attackId:"111", defendId:"333", delta:3}]`
- Player "111" receives buffer containing both entries (flipped to objective form): `[{loserId:"222", winnerId:"111", n:2}, {loserId:"333", winnerId:"111", n:3}]`. Their client calls `startPeel` on rival Follower Entities so they see the rivals peel TOWARD them.
- Player "222" receives buffer containing only their pair: `[{loserId:"222", winnerId:"111", n:2}]`. Their client calls `startPeel("222", "111", 2)` on their own (loser's) FollowerEntity — their followers peel away toward "111".

**Clarification**: buffer entries carry objective `loserId`/`winnerId` — every recipient client calls `FollowerEntity.startPeel(loserId, winnerId, n)` on the loser's instance, regardless of which client received the packet. Rival-side spawn fires organically via Follower Entity's arrival hook.

## Edge Cases

### Pair geometry

- **If two crowd positions are exactly equal (stacked XZ)**: `distance_sq = 0 ≤ combined_radius_sq` → overlap fires normally. Crowd State's `position_lag` + boids separation in Follower Entity F1 resolve over subsequent frames. No special handling.
- **If a player character teleports mid-tick**: Crowd State `CROWD_POS_LAG = 0.15` caps position movement at 0.15 × displacement per tick. No instant overlap — overlap only registers next tick with new lag-follow position. Not exploitable.

### Tick loop

- **If Heartbeat accumulator fires 2+ ticks back-to-back (lag spike)**: each tick runs independently in sequence. Drip fires twice → count drops by `2 × delta_per_tick`. Correct behavior. Risk: sustained 3+ catch-up ticks may accelerate eliminations unexpectedly — playtest-monitor, no code fix.
- **If `_prevOverlapKeys` is empty on the first tick of a round**: every overlapping pair that tick is `_curr \ _prev` → fires `CollisionContactEvent` for each. Correct — tick 1 treats all overlaps as first-contact. Intentional.
- **If `RoundLifecycle.destroyAll()` fires while a tick is mid-execution**: Roblox single-threaded server means destroyAll cannot interleave. Current tick completes fully (including peel dispatch) before destroyAll runs. Crowd State's idempotent destroy handles any late calls for records being torn down.

### State transitions specific to overlap-bit feed

- **If drip reduces crowd A to count=1 and `setStillOverlapping(A, true)` fires in the SAME tick**: ordering within this system is locked — drip first, `setStillOverlapping` feed second. A reaches count=1, then Crowd State's internal check (`Active + count == 1 + still_overlapping == true`) transitions A to `GraceWindow` on this same tick. Timer starts immediately. Implementation must NOT defer overlap feed to next frame.
- **If a crowd is in GraceWindow with no overlaps this tick**: `setStillOverlapping(id, false)` fires → Crowd State F7 tie-break returns crowd to `Active` at `count=1` on this tick. No race — `setStillOverlapping` is called exactly once per crowd per tick, after the full pair pass completes. Intra-tick re-entry is impossible by construction.
- **If two crowds symmetrically drain each other to count=1 in the same tick (2-vs-2 mutual)**: both receive `delta_per_tick = 1` (equal-count rule). Both drop to count=1. Both receive `setStillOverlapping(id, true)`. Both transition to `GraceWindow` simultaneously, timers start synchronously. Next tick: skip condition (`NOT both Active`) prevents further drips. Both sit in GraceWindow overlapping each other; whichever absorbs a neutral first escapes (Absorb System crosses the GraceWindow → Active boundary via positive delta). Intended photo-finish standoff.

### Peel dispatch

- **If a player disconnects between buffer build and `FireClient`**: `Players:GetPlayers()` is evaluated at dispatch time (end of tick). DC'd players not in the list → buffer entry skipped. No server orphan. Client is gone — no cleanup needed.
- **If a player joins mid-round and their `crowdId` is not yet in the crowd map**: their relevance filter misses — they receive no peel events that tick. Match State Machine locks joining to Lobby state (mid-round join out of scope for MVP), so edge is academic. Flag for future work.
- **If the same crowd appears as loser in multiple buffer entries (A vs B + A vs C simultaneously)**: client receives two `startPeel(A, B, n1)` and `startPeel(A, C, n2)`. Follower Entity §C.3 already specs: "second `startPeel` call excludes already-`Peeling` entities from the first call; returns next-closest non-Peeling followers." Handled upstream — CollisionResolver has no deduplication obligation.
- **If an unreliable peel packet drops**: client misses one drip cycle's visual peel. Authoritative count broadcast (15 Hz UnreliableRemote for state, separate channel) still corrects the counter. Visual lag ≤ 67ms. Cosmetic-only per ADR-0001.

### pairEntered diff

- **If a pair is in `_prev` but absent from `_curr` because one crowd Eliminated mid-tick**: pair not in `_curr` (Eliminated skip) → `_curr \ _prev` doesn't include it → no new event fires (correct). Stale key in `_prev` is overwritten by `_prev ← _curr` assignment at tick end. No explicit cleanup step needed.
- **If one crowd Eliminated and simultaneously new overlap involves a third party**: cleanup via `_prev ← _curr` swap handles all stale keys in one assignment. No partial-state bug.

### Equal-count two-way peel + elimination race

- **If both crowds in a 2-vs-2 equal-count peel reach GraceWindow and an in-flight peel follower arrives at a now-Eliminated rival**: peel transit continues to last-known rival center (Follower Entity §E contract). On arrival, rival-side `FadeIn` spawn MUST be suppressed if `CrowdStateClient.get(rivalId) == nil` (Eliminated) — the follower is reclaimed into its own pool instead of joining a dead crowd. **This is a required Follower Entity acceptance criterion** — flag for Follower Entity GDD amendment (AC covering "arrival spawn suppressed on Eliminated rival"). CollisionResolver's responsibility ends at buffer dispatch.

### Performance / scale

- **If 12 crowds pile up in a single overlap cluster (66 simultaneous pairs)**: worst-case per-client peel dispatch is 11 entries (n-1 rivals) × 40 bytes × 15 Hz ≈ 6.6 KB/s. **Implementation requirement**: PeelDispatcher MUST batch all entries per client into ONE `FireClient` call per tick. Per-entry dispatch would generate 66 × 12 = 792 remote calls/tick — server overhead spike. Batching is baked into §C Rule 8; flag as AC.
- **If crowds spawn within collision radius of each other on tick 1**: minimum combined radius at `CROWD_START_COUNT=10` is `2 × 4.24 = 8.48` studs. If spawn scatter < 8.48 studs, collision drip begins on tick 1. Not a CollisionResolver rule violation — collision applies from first Active tick. **Upstream level-design / spawn-placement constraint**: CharacterSpawner / Round Lifecycle must enforce minimum spawn separation `≥ 2 × radius_from_count(CROWD_START_COUNT)`. Flag for Round Lifecycle / CharacterSpawner GDD amendment.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| **ADR-0001 Crowd Replication Strategy** | Proposed | 15 Hz server tick, server-authoritative hit detection, O(p²) pair-check validated, `UnreliableRemoteEvent` broadcast contract, per-client bandwidth budget | Architecture foundation |
| **Crowd State Manager** | Batch 1 Applied 2026-04-24 | Read: `get(crowdId).{position, radius, count, state}` per pair; `getAllActive()` snapshot per tick (✓ Batch 1). Write: `updateCount(crowdId, ±delta, "Collision")` per overlapping Active-vs-Active pair; `setStillOverlapping(crowdId, bool)` once per crowd per tick (✓ Batch 1) | Read + Write |
| **TickOrchestrator** (sibling, new module) | Not Started (this GDD defines it) | Owns `RunService.Heartbeat` accumulator; calls `CollisionResolver.tick(...)` first each tick sequence | Control |
| **Round Lifecycle** | In Review (designed) | `createAll()` → `CollisionResolverServer.start()` (Dormant → Ticking). `destroyAll()` → `CollisionResolverServer.stop()` (Ticking → Dormant). | Control |
| **Network Layer (template)** | Approved (partial) | Requires `UnreliableRemoteEventName.CollisionPeelEvent` + `Network.connectUnreliableEvent` / `Network.fireUnreliableClient` wrappers (shared prereq with Crowd State broadcast). Requires `RemoteEventName.CollisionContactEvent` reliable path (standard enum addition). | Infrastructure |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| **Absorb System** | Designed (pending review) | Peer on shared `TickOrchestrator`; Absorb registers to fire AFTER Collision each tick. No direct call between the two. | Peer |
| **Follower Entity (client)** | In Review (designed) | `CollisionResolverClient` dispatches `FollowerEntityClient.startPeel(loserCrowdId, winnerCrowdId, n)` on incoming unreliable `CollisionPeelEvent` buffer entries. Contract already locked in Follower Entity §C.3. | Server → client dispatch |
| **VFX Manager** | Not Started | Reliable `CollisionContactEvent(crowdIdA, crowdIdB)` fired on `pairEntered` tick. VFX Manager subscribes for impact flash (see §V/A). | Server → client signal |
| **Audio Manager** (VS tier) | Not Started | Same `CollisionContactEvent` consumed for collision-start stinger `sfx_crowd_collision_start`. | Server → client signal |
| **HUD** | Not Started | No direct interface. HUD consumes `CrowdStateBroadcast` and `CrowdEliminated` (reliable) — both owned by Crowd State. This GDD's state changes reach HUD indirectly via Crowd State. | None (indirect) |
| **Daily Quest System** (Alpha tier) | Not Started | Consumes `CollisionContactEvent` for "crush X rivals" quest counters. | Server-side event source |
| **Analytics** (Alpha tier, template stubs) | Partial | Consumes `CollisionContactEvent` + drip call logs for collision frequency / elimination attribution telemetry. | Read-only analytics |

### Provisional contracts (flagged for cross-check)

- ✓ **Crowd State Manager Batch 1 amendment landed 2026-04-24** — `CrowdStateServer.getAllActive(): {CrowdRecord}` and `CrowdStateServer.setStillOverlapping(crowdId: string, flag: boolean): ()` now specified in CSM §Server API with CollisionResolver-only caller restriction. CSM F7 `should_eliminate` reads `stillOverlapping` field each tick. See `docs/architecture/change-impact-2026-04-24-csm-batch1.md`.
- **Follower Entity GDD amendment required** — add acceptance criterion: "arrival spawn suppressed on Eliminated rival" (`CrowdStateClient.get(rivalId) == nil` guard at peel-arrival). Flagged from §E equal-count two-way peel + elimination race.
- **Round Lifecycle / CharacterSpawner constraint flagged** — enforce minimum spawn separation `≥ 2 × radius_from_count(CROWD_START_COUNT) = 8.48 studs` to avoid tick-1 spawn collisions. Not CollisionResolver's responsibility; flag for upstream.
- **TickOrchestrator** is a new sibling module introduced by this GDD. It is not yet in the Systems Index — needs a new row appended (Core layer, MVP tier). Relic System (when designed) will register as a callback; Chest System will not (chest is on-interaction, not tick-driven).
- **Network layer wrappers** — `UnreliableRemoteEventName` enum + `Network.connectUnreliableEvent` + `Network.fireUnreliableClient` are implementation prereqs shared with Crowd State. Part of the Crowd Replication epic, not this GDD's story scope.

### Bidirectional consistency notes

- **REQUIRES** Crowd State §C.1 write-access contract to continue listing CollisionResolver as authorised caller of `updateCount` with delta shape `±ceil(TRANSFER_RATE_effective / 15)` (already locked).
- **REQUIRES** Crowd State §E same-tick ordering contract (Collision → Relic → Absorb → Chest) to remain locked — this system relies on firing FIRST each tick.
- **REQUIRES** Absorb System §C to continue specifying piggyback on shared tick (already locked — Absorb §C "piggybacks on the same pass that drives Crowd Collision Resolution"). The `TickOrchestrator` this GDD introduces is the concrete mechanism.
- **CREATES** VFX Manager consumer contract for `CollisionContactEvent`.
- **CREATES** Audio Manager consumer contract for same event.
- **CREATES** Daily Quest / Analytics consumer contract (same event — event source integration point).

### Engine constraints inherited

- Server-only hit detection per ADR-0001 (no client authority on collision outcome)
- `UnreliableRemoteEvent` for peel dispatch (confirmed GA post-cutoff, used by Crowd State broadcast already)
- No separate `RunService.Heartbeat` connection — shared through `TickOrchestrator`
- No `task.wait` / `coroutine.yield` inside tick loop — all work synchronous per Heartbeat callback
- Luau `--!strict` + `Packages.janitor` for connection cleanup (same pattern as Crowd State)

### No cross-server dependency

This system is entirely within one Roblox server. No `MessagingService`. Server-authoritative collision state does not survive server restart (Pillar 3 round purity).

## Tuning Knobs

This system owns **no balance-sensitive knobs**. Drip rate, radius, grace window, and count ceiling are all Crowd State's knobs. This GDD exposes only implementation-level toggles.

### Owned by this GDD (implementation-level only)

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Notes |
|---|---|---|---|---|---|---|
| `EQUAL_COUNT_VISUAL_MODE` | `two_way` | `{two_way, single_winner, none}` | Peel dispatch behavior on equal-count symmetric drain | `two_way`: both mobs peel toward each other — richest visual but 2× peel packets per tick for equal pairs. `single_winner`: lex-lower `crowdId` peels toward other (asymmetric fallback). `none`: no peel dispatched, pure count drain | — | Playtest-only toggle. Fall back to `single_winner` if `two_way` reads confusing. |
| `PEEL_BUFFER_BATCH_ENABLED` | `true` | `{true, false}` | Whether PeelDispatcher batches all per-tick pair entries for a client into ONE `FireClient` call | `false`: per-entry `FireClient` explodes into ~792 calls/tick at 12-crowd pileup — do not disable in production | — | Locked `true` for MVP. `false` is debug-only for pinpointing individual pair dispatch issues. |
| `CONTACT_EVENT_ENABLED` | `true` | `{true, false}` | Whether `CollisionContactEvent` reliable remote fires on `pairEntered` | `false`: VFX impact flash + audio collision-start stinger silent. Breaks Pillar 1 feel. | — | MVP requires `true`. Disable only in perf-profiling scenarios. |
| `PAIR_ITERATION_SKIP_ELIMINATED` | `true` | `{true, false}` | Whether Eliminated crowds are skipped in pair iteration | — | `false`: would attempt drip on destroyed records → nil-deref crashes. Locked `true`. | Not a real tuning knob; listed for code-review auditing. |

### Inherited from upstream (consumed here — do NOT duplicate)

| Knob | Owner | Value | Cited for |
|---|---|---|---|
| `SERVER_TICK_HZ` | ADR-0001 (registry) | locked 15 | Tick cadence |
| `TRANSFER_RATE_BASE` | Crowd State (registry) | 15 followers/sec | F3 drip formula |
| `TRANSFER_RATE_SCALE` | Crowd State (registry) | 0.15 | F3 drip formula |
| `TRANSFER_RATE_MAX` | Crowd State (registry) | 60 followers/sec | F3 drip formula |
| `MAX_CROWD_COUNT` | Crowd State (registry) | 300 | Count ceiling clamped by `updateCount` |
| `GRACE_WINDOW_SEC` | Crowd State (registry) | 3.0 | F7 timer (owned by Crowd State) |
| `CROWD_POS_LAG` | Crowd State | 0.15 | Position input for F1 overlap test |
| `radius_from_count` constants (BASE=2.5, SCALE=0.55) | Crowd State / ADR-0001 | — | Radius input for F1 overlap test |

### Locked constants (NOT tuning knobs — changing requires ADR amendment)

- Tick cadence: `SERVER_TICK_HZ = 15` locked by ADR-0001
- Pair iteration: O(p²) all-pairs locked by ADR-0001 prototype validation
- Server authority on collision outcome locked by ADR-0001

### Where knobs live (implementation guidance)

- Balance knobs: **not in this system** — `SharedConstants/CrowdConfig.luau` (owned by Crowd State)
- Implementation toggles: `SharedConstants/CollisionResolverConfig.luau` (new file, this system)

### Playtest monitoring flags (not knobs)

- **Sustained lag spike detection**: log when `TickOrchestrator` accumulator overflow exceeds 2 ticks-per-Heartbeat on 3+ consecutive Heartbeats. Elimination-rate acceleration risk (see §E tick loop edges). Server-side telemetry only; no tuning lever.
- **Peel bandwidth monitoring**: log per-client `CollisionPeelEvent` bytes/sec. Trigger warning if > 5 KB/s sustained (half the ADR-0001 per-client budget for crowd data — early warning for multi-collision pileups).

## Visual/Audio Requirements

Scope: ONLY the `CollisionContactEvent` impact moment. Sustained peel visual (hue-flip, white-flash, `VFXEffect.HueShift`) is owned by **Follower Entity §V/A** — already locked. `CrowdEliminated` is owned by **Crowd State Manager**. This section covers the first-contact impact visuals + audio.

### VFX — Impact Burst

Client-side, on `CollisionContactEvent` receipt. Spawns once per pair at the **midpoint** between the two crowd center positions (projected to Y=0 ground plane). Midpoint reads as shared boundary impact rather than attribution to either crowd; silhouettes (art bible §1) are preserved because the burst spawns in the gap between mobs, not inside either cluster.

| Parameter | Value |
|---|---|
| Particle count | **12 flat-quad burst** |
| Color | **Neutral white (#F5F5F5)** — unambiguous system color (art bible §4 Neutral NPC White precedent); avoids confusion with dual-hue absorb snap |
| Lifetime | 0.4s |
| Velocity / scatter | Radial, ≤2.5 studs (wider than absorb's 1-stud to signal a larger event) |
| Emitter | Destroyed immediately after burst fires |
| Spawn position | `(A.pos + B.pos) / 2`, Y snapped to ground plane |

### VFX — Impact Ring (Neon punctuation)

Non-particle `Part` punctuation. A ring reads as "boundary" (physically accurate for two overlapping circles) — the burst alone does not convey scale.

| Parameter | Value |
|---|---|
| Form | 1 Neon-material `Part`, flat disc (thin cylinder shape: ~0.1 stud thickness, 0 Y-scale) |
| Color | White (#F5F5F5) — matches burst |
| Scale tween | 0 → 3.0 studs diameter → 0 over **0.45s** |
| Easing | Linear expand + linear contract (no ease curves — flat aesthetic per §4) |
| Transparency | 0 → 0.85 over duration |
| Material | `Enum.Material.Neon` (VFX punctuation permitted per Absorb §V/A precedent) |
| Destroy | Instance destroyed at tween end |

Diameter 3.0 studs — reads at 50m, does not occlude full crowd silhouette. Total duration < 0.5s (avoids overlap with sustained peel visual).

### Audio — `sfx_collision_impact`

**Must NOT be confused with `sfx_absorb_snap`**. Absorb is short/tonal/light (poppy click + sine tail). Collision is heavier, lower-register, blunter.

| Parameter | Value |
|---|---|
| Character | Heavy thud / crowd-mass impact: low-mid transient (80-200 Hz body), dry attack, NO pitched sine tail |
| Attack | <30ms (blunt, not poppy) |
| Tail | ~80ms noise decay (crowd-body reverb, not pitched) — distinguishes from absorb |
| Total duration | <0.25s |
| Pitch randomize | Base pitch ±0.12 semitone per event (wider than absorb's ±0.1) |
| Volume | ~1.2× absorb snap baseline |
| Spatial | 3D positional, anchored at midpoint (matches VFX origin) |
| Dedup | `CollisionContactEvent` fires at most once per pair per overlap episode — event itself handles dedup. No audio batching needed at 1-6 simultaneous peak. |

**No screen shake** at any contact (mobile iPhone SE target, Absorb §V/A precedent). **No 2D/UI audio layer** — all collision sound is 3D positional.

### Art bible compliance anchors

| Bible section | Application |
|---|---|
| §1 Visual Identity ("bold silhouette at 50m") | Burst + ring spawn at midpoint gap between crowds — neither element occludes crowd ridge-lines. Ring expansion outward, not inward. |
| §4 Flat Color / No Gradients | All elements flat white; transparency fade is opacity tween (not gradient). No color lerp. |
| §8.4 Material Standards | Neon used ONLY on ring VFX Part, not on structural geometry. |
| §8.7 VFX Budgets | 12 particles per event × 6 worst-case concurrent pairs = 72 scene-total (3.6% of 2,000 ceiling). Per-event 12 < 40 burst cap. Ring is non-particle (exempt). |
| §2 Mood — Pillar 5 | White neutral color — not red, not aggressive. Contact is a signal of risk, not punishment. |
| §2 Mood — Pillar 1 | Heavy audio thud + ring pop delivers dopamine without screen shake. Impact feels large via sound + volume, not camera disruption. |
| §8.10 Perf Validation | Tween-then-destroy. Emitter self-destroys after burst. No orphaned instances. Mobile-safe. |

### Budget check (worst-case, 6 simultaneous pairs)

| Item | Per event | Worst case | Budget |
|---|---|---|---|
| Burst particles | 12 | 72 | < 2,000 scene ceiling ✓ |
| Per-event particle cap | 12 | 12 | < 40 burst cap ✓ |
| Ring parts | 1 non-particle | 6 (0.45s) | Non-particle, no ceiling ✓ |
| Audio voices | 1 | 6 simultaneous | No polyphony ceiling; 6 distinct impacts unmasked at this frequency ✓ |

Collision fires 1-6× per overlap **episode onset only** (not sustained) — particle load lower than Absorb's 15 Hz continuous rate despite higher per-event count.

### Asset names (follows art bible §8.8 pattern)

- `VfxCollisionImpactBurst.png` — flat-quad particle texture
- `VfxCollisionImpactRing` — Part instance (Neon, white, flat disc shape)
- `sfx_collision_impact` — audio asset, registered in `AssetId.luau`

### Tuning knob additions (from V/A)

| Knob | Default | Range | Notes |
|---|---|---|---|
| `COLLISION_VFX_BURST_COUNT` | 12 | [8, 20] | Particles per contact event. Keep under 40 burst cap minus scene headroom. |
| `COLLISION_VFX_RING_DURATION` | 0.45s | [0.2, 0.5] | Full ring expand+contract. Hard max 0.5s per overlap-avoidance with peel. |
| `COLLISION_VFX_RING_DIAMETER_MAX` | 3.0 studs | [2.0, 5.0] | Peak ring diameter. < 2.0 imperceptible at 50m; > 5.0 clips crowd silhouette. |
| `COLLISION_SFX_PITCH_VARIANCE` | ±0.12 semitones | [0.05, 0.25] | Per-event pitch randomize. Wider than absorb. |
| `COLLISION_SFX_VOLUME_SCALE` | 1.2 | [0.8, 1.8] | Volume relative to absorb baseline. Keep > 1.0 — contact must feel heavier than absorb. |

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:crowd-collision-resolution` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## Acceptance Criteria

All ACs Logic-tier (TestEZ + mocked dependencies) except AC-12, AC-14, AC-16, AC-19 (Integration tier, multi-module), AC-20 (Perf tier, Micro Profiler), and AC-21 (Bandwidth tier, StatsService).

**AC-01 (Rule 1 — Tick cadence, Logic)** — GIVEN the resolver is in `Ticking` state and 66 ms have elapsed since the last tick, WHEN `TickOrchestrator`'s Heartbeat accumulator crosses the `1/15` threshold, THEN `CollisionResolverServer.tick()` fires exactly once; accumulator resets; no tick fires again until another 66 ms accumulate.

**AC-02 (Rule 1 — Dormant no-op, Logic)** — GIVEN the resolver is in `Dormant` state, WHEN `TickOrchestrator` fires a tick callback, THEN `CrowdStateServer.getAllActive()` is never called; `_overlapPairs` remains empty; no `updateCount`, `setStillOverlapping`, `CollisionContactEvent`, or `FireClient` calls fire.

**AC-03 (Rule 2 — Pair iteration unique pairs, F2, Logic)** — GIVEN three active crowds `"111"`, `"222"`, `"333"`, WHEN one tick runs, THEN exactly three unique unordered pairs are visited (`"111|222"`, `"111|333"`, `"222|333"`), each exactly once, with no self-pair and no duplicate (e.g., no `"222|111"`).

**AC-04 (F1 — Pair overlap test, Y ignored, Logic)** — GIVEN crowd A at `pos=(0,0,0)` `radius=8.0` and crowd B at `pos=(10,50,0)` `radius=8.0`, WHEN the overlap test evaluates, THEN `distance_sq=100`, `combined_radius_sq=256`, `overlapping=true` (Y=50 delta ignored); AND for crowd C at `pos=(20,0,0)` `radius=8.0`, `distance_sq=400 > 256 → overlapping=false`.

**AC-05 (F2 — pair_key canonical form, Logic)** — GIVEN `crowdId` strings `"3891"` and `"512"`, WHEN `pairKey(a, b)` is called with both argument orderings, THEN both calls return `"3891|512"` (lex compare: `"3"` < `"5"` → `"3891"` lex-lower sorts first); AND `pairKey("512","3891") == pairKey("3891","512")`.

**AC-06 (Rule 4 — Skip conditions, Logic)** — GIVEN a pair where `CrowdStateServer.get(A.id) == nil`, AND a separate pair where `B.state == "Eliminated"`, WHEN a tick runs, THEN: (a) no `updateCount` call fires for either pair; (b) `setStillOverlapping` is NOT set to `true` for A or B from these pairs; (c) no Luau error is thrown.

**AC-07 (Rule 5 — Drip application, F3, Logic)** — GIVEN A (`count=100, Active`) and B (`count=50, Active`) overlapping, `TRANSFER_RATE_BASE=15`, `TRANSFER_RATE_SCALE=0.15`, `TRANSFER_RATE_MAX=60`, `SERVER_TICK_HZ=15`, WHEN one tick elapses, THEN `updateCount("A", +2)` then `updateCount("B", -2)` are called (`count_delta=50 → effective=22.5 → ceil(22.5/15)=2`); no other updateCount calls for this pair.

**AC-08 (Rule 5 — Equal-count mutual drain, F3, Logic)** — GIVEN A (`count=50, Active`) and B (`count=50, Active`) overlapping, defaults as AC-07, WHEN one tick elapses, THEN `updateCount("A", -1)` and `updateCount("B", -1)` are both called; NEITHER receives a `+` call (`count_delta=0 → effective=15 → delta_per_tick=1`; equal-count rule yields mutual drain per §C Rule 5). Matches Crowd State §AC-10.

**AC-09 (Rule 6 — Overlap-bit feed, Logic)** — GIVEN a tick where A and B overlap (both Active), C has no overlaps, D is in GraceWindow with a persisting overlap to A, WHEN the full pair pass completes, THEN `setStillOverlapping("A", true)`, `setStillOverlapping("B", true)`, `setStillOverlapping("C", false)`, `setStillOverlapping("D", true)` are each called exactly once; no crowd is called twice; calls happen AFTER all drip calls this tick.

**AC-10 (Rule 7 — PairEntered event fires only on first contact, Logic)** — GIVEN A and B overlapping on tick N (stored in `_prevOverlapKeys`), WHEN tick N+1 runs with A-B overlap still present, THEN `CollisionContactEvent` is NOT fired for A-B on tick N+1; AND if crowd C newly overlaps A on tick N+1, `CollisionContactEvent` fires once with `{A, C}` payload on that tick.

**AC-11 (F4 — Peel buffer relevance filter, Logic)** — GIVEN `_overlapPairs = [{attackId:"111", defendId:"222", delta:2}, {attackId:"333", defendId:"444", delta:1}]`, WHEN `PeelDispatcher.flush()` runs, THEN player `"222"` receives exactly one `FireClient` call with buffer `[{loserId:"222", winnerId:"111", n:2}]`; player `"555"` (not in any pair) receives NO `FireClient` call at all this tick.

**AC-12 (Rule 9 — Client peel observation, Integration)** — GIVEN `CollisionResolverClient` subscribed to `CollisionPeelEvent` receives buffer `[{loserId:"A", winnerId:"B", n:2}]`, WHEN the unreliable event fires, THEN `FollowerEntityClient.startPeel("A", "B", 2)` is called exactly once with those arguments. *Evidence: `tests/integration/collision/client_peel_observation_test.luau`.*

**AC-13 (Rule 10 — Write-access contract, Logic)** — GIVEN a full tick over 3 Active-vs-Active overlapping pairs, WHEN the tick completes, THEN the ONLY CrowdStateServer methods invoked are: `getAllActive()` (once), `get(id)` (as needed), `updateCount(id, ±delta)` (twice per drip pair), `setStillOverlapping(id, bool)` (once per crowd in `getAllActive()` result). No other CrowdStateServer methods are called.

**AC-14 (Edge — 2-vs-2 mutual GraceWindow, Integration)** — GIVEN A (`count=2, Active`) and B (`count=2, Active`) overlapping, WHEN one tick fires (equal-count mutual drain), THEN both drop to `count=1` via `updateCount(-1)`; `setStillOverlapping(A, true)` AND `setStillOverlapping(B, true)` fire this tick; Crowd State transitions both to `GraceWindow` this tick; timers start synchronously. WHEN next tick fires, the pair is skipped for drip (neither is `Active`); `setStillOverlapping` still reports `true` for both (geometric overlap persists).

**AC-15 (Edge — Stacked position, Logic)** — GIVEN A and B at identical XZ coordinates (`distance_sq=0`), any radii ≥ 3.05, WHEN overlap test runs, THEN `0 <= combined_radius_sq → overlapping=true`; drip and overlap-bit proceed normally; no divide-by-zero; no special-case branch fires.

**AC-16 (Edge — Lag-spike 2-tick overflow, Integration)** — GIVEN A (`count=10`) and B (`count=10`) overlapping, WHEN a Heartbeat callback fires with accumulator holding 2 full ticks of backlog (`dt ≈ 133ms`), THEN `TickOrchestrator` runs the tick loop twice sequentially in that callback; `updateCount` fires `-1` twice per side (total `-2` each); accumulator resets below threshold; no third tick fires.

**AC-17 (Edge — Equal-count two-way peel emission, Logic)** — GIVEN A (`count=50`) and B (`count=50`) overlapping, WHEN one tick runs, THEN `_overlapPairs` contains exactly two entries `{attackId:"A", defendId:"B", delta:1}` AND `{attackId:"B", defendId:"A", delta:1}`; PeelDispatcher sends one entry to player A's buffer (loser=B, winner=A direction) and one entry to player B's buffer (loser=A, winner=B direction); both `FireClient` calls are made this tick.

**AC-18 (Edge — Eliminated skip in peel dispatch, Logic)** — GIVEN `_overlapPairs` contains a pair involving a crowd just Eliminated (now absent from `getAllActive()`), WHEN `PeelDispatcher.flush()` runs, THEN the player whose `crowdId` matches the Eliminated crowd receives no `FireClient` call for that entry; other players' buffers still receive entries where the Eliminated crowd is the opposing party (they still see the peel visual on a stale rival mob for up to one tick until Follower Entity's rival-nil handling fires); no nil-deref errors.

**AC-19 (Edge — Unreliable peel packet drop is cosmetic-only, Integration)** — GIVEN the server fires `CollisionPeelEvent` to a client but the unreliable packet is dropped (handler not invoked), WHEN the client's next `CrowdStateBroadcast` arrives (≤67 ms later), THEN the client's authoritative `count` cache reflects the post-drip value; no gameplay state corruption; no retry or ACK attempted; client visual count matches server within one broadcast interval. *Evidence: `tests/integration/collision/peel_drop_cosmetic_test.luau`.*

**AC-20 (Perf — `CollisionResolverTick` p99 ≤ 0.15ms, Perf)** — GIVEN 12 active crowds (66 pairs) with ~6 overlapping pairs (per ADR-0001 prototype worst-case), WHEN the server runs 900 consecutive ticks (60-sec soak at 15 Hz) in a Studio-deployed test server, THEN `CollisionResolverTick` p99 wall time (via `debug.profilebegin("CollisionResolverTick")` / `debug.profileend`) is ≤ 0.15 ms; full tick (Collision + Absorb + Broadcast + PeelDispatch) p99 ≤ 0.80 ms. *Evidence: `production/qa/evidence/perf-soak-collision-[date].txt` (Micro Profiler JSON export, p99 extracted).* **Advisory gate — milestone check, not per-story.**

**AC-21 (Bandwidth — Batch FireClient + pileup budget, Bandwidth)** — GIVEN 12 crowds in a single pileup (11 pairs involving one player's crowd), WHEN `PeelDispatcher.flush()` runs for that player, THEN exactly ONE `FireClient` call is made (buffer batched with all 11 entries); per-client `CollisionPeelEvent` bandwidth measured via `StatsService.DataSendKbps` over a 60-sec sustained 12-crowd pileup does NOT exceed 6.6 KB/s; at 3-pair steady state the same metric does NOT exceed 1.8 KB/s. *Evidence: `production/qa/evidence/bandwidth-peel-[date].txt`.* **Advisory gate.**

---

**Test placement**:
- Logic tier (ACs 01-11, 13, 15, 17, 18): `tests/unit/collision/`
- Integration tier (ACs 12, 14, 16, 19): `tests/integration/collision/`
- Perf (AC-20): `production/qa/evidence/perf-soak-collision-[date].txt`
- Bandwidth (AC-21): `production/qa/evidence/bandwidth-peel-[date].txt`

**Required DI seams** (programmer prerequisite):
- `CrowdStateServer` injectable (not singleton require) — blocks ACs 02, 03, 06, 07, 08, 09, 13, 14, 16
- `Network.fireClients` spy-injectable — blocks AC 10
- `Players:GetPlayers()` injectable — blocks ACs 11, 17, 18
- `UnreliableRemote.FireClient` spy-injectable — blocks ACs 11, 17, 18, 21
- `FollowerEntityClient.startPeel` spy-injectable — blocks AC 12
- Heartbeat accumulator injectable clock — blocks ACs 01, 16
- `debug.profilebegin("CollisionResolverTick")` / `debug.profileend` labels — required by AC 20

**Gate classification**:
- **BLOCKING (per-story Done):** ACs 01-18 (Logic + Integration — 17 criteria)
- **ADVISORY (milestone check):** ACs 19-21 (cosmetic tolerance, perf, bandwidth)

## Open Questions

### Cross-GDD amendments required before implementation

- ✓ **OQ-1 RESOLVED 2026-04-24** — Both APIs (`CrowdStateServer.getAllActive()` + `CrowdStateServer.setStillOverlapping(crowdId, flag)`) landed in CSM §Server API via Batch 1 amendment hub. CSM §C.2 GraceWindow trigger now consumes `stillOverlapping` field via F7 evaluation each tick. Resolved via `/propagate-design-change` CSM Batch 1 run.
- **OQ-2 (Follower Entity GDD amendment)**: Add AC covering "arrival spawn suppressed when rival `crowdId` is Eliminated" (`CrowdStateClient.get(rivalId) == nil` guard at peel-arrival; follower reclaimed into own pool instead of joining Eliminated rival). Owner: game-designer + gameplay-programmer. Target: Follower Entity next revision.
- **OQ-3 (Round Lifecycle / CharacterSpawner constraint)**: Enforce minimum spawn separation `≥ 2 × radius_from_count(CROWD_START_COUNT) = 8.48 studs` between crowds on round-start spawn placement. Prevents tick-1 spawn collisions. Owner: game-designer (Round Lifecycle) + gameplay-programmer (CharacterSpawner). Target: Round Lifecycle next revision.
- **OQ-4 (Systems Index update)**: `TickOrchestrator` is a new sibling module introduced by this GDD. Add row to systems index (Core layer, MVP tier, depends on Network Layer + ADR-0001). Owner: systems-index curator. Target: Phase 5 of this GDD's authoring.
- **OQ-5 (Network Layer prereq)**: `UnreliableRemoteEventName.CollisionPeelEvent` + `RemoteEventName.CollisionContactEvent` enum entries + `Network.fireUnreliableClient` wrapper. Owner: gameplay-programmer. Shared prereq with Crowd State Manager broadcast. Target: Crowd Replication epic.

### Validation questions (for `/design-review`)

- **OQ-6**: Is naive O(p²) pair iteration still correct at 12 players + 8 neutral NPC crowds if Absorb NPCs were ever included in the collision pair space? (They are NOT in MVP — NPCs use a different overlap loop owned by Absorb System. Confirm if design evolves.)
- **OQ-7**: Playtest validation of `EQUAL_COUNT_VISUAL_MODE = two_way`: does the symmetric two-way peel visual read as "tense standoff" (intended Pillar 5 Foot Race) or as "both sides losing, confusing"? Fallback `single_winner` toggle reserved for this. Resolve in playtest after MVP integration.
- **OQ-8**: Advisory AC-20 p99 target of 0.15 ms for `CollisionResolverTick` — does this hold on deployed Roblox server (not Studio) under peak 66-pair-overlap load? Milestone-level validation required.

### Deferred-to-production questions

- **OQ-9 (mobile bandwidth)**: AC-21 bandwidth (6.6 KB/s worst-case per-client) validated theoretically only. Deferred to MVP integration per ADR-0001's "Multi-client bandwidth test deferred" note.
- **OQ-10 (lag-spike monitoring)**: §G "sustained 3+ catch-up ticks" detection is a logging flag, not a corrective mechanism. If playtest reveals frequent lag spikes causing accelerated eliminations, design a corrective (e.g., cap accumulator catch-up at 2 ticks and discard overflow). Owner: gameplay-programmer + game-designer.
