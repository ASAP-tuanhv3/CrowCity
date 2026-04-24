# Relic System

> **Status**: In Design (2026-04-24 CSM Batch 1 sync pass — `recomputeRadius(crowdId, newMultiplier)` two-arg signature adopted; 6 stale "CSM amendment required" flags cleared; direct `radiusMultiplier` field writes replaced with `recomputeRadius` API calls per CSM Batch 1 write-access contract. Remaining blocker: FLAG-1 Wingspan oppression (design decision, Batch 5).)
> **Author**: user + game-designer + systems-designer + economy-designer
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 2 (Risky Chests) primary, 5 (Comeback Always Possible), 3 (5-Minute Clean Rounds)
> **Scope**: Framework + 3 reference relics (remaining MVP content deferred to Vertical Slice)

## Overview

The **Relic System** is the server-authoritative registry, dispatch, and round-scoped lifecycle owner for every run-modifying effect a player can acquire during a match. Each crowd holds up to `MAX_RELIC_SLOTS = 4` active relics (cap owned by Crowd State Manager); grants flow in exclusively from the Chest System after a successful follower-toll payment and vanish at match end. The system itself is thin: a static **RelicRegistry** of typed specs (id, rarity, effect hooks, stack rules, UI copy) loaded at boot, plus a **RelicEffectHandler** module that wires each acquired relic to the system it actually modifies — count-mutating relics route through `CrowdStateServer.updateCount` (never direct), radius relics write a multiplier into the crowd record before `radius_from_count` is stored, and non-state relics (move speed, toll discount, absorb-radius, crowd magnetism) publish their modifier to the owning system (Follower Entity, Chest System, Absorb System). The handler is the integration seam; the registry is the content surface. The lifecycle is framed by Match State Machine: `clearAll()` fires at T9 (Intermission entry) after `RoundLifecycle.destroyAll()`, and `CrowdRelicChanged` (reliable, snapshot-on-change) tells clients when to redraw the HUD slot bar. State is strictly ephemeral — no relic survives a round (Pillar 3), no persistent power progression, no relic revives from `Eliminated` in MVP.

For the player, the system is the beat that makes Pillar 2 work: every chest opened is a relic draft, every relic is a run-shaper that demands a synergy read, and every slot filled narrows the next decision. A small crowd's single T3 gamble can land a game-flipping roll (Pillar 5 — comeback always possible); a large crowd's slot pressure makes each grab a real trade-off. Relics are the decision layer grafted onto the snowball — they are what a round is about once the third chest is in sight.

**Scope (MVP)**: framework + 3 reference relics proving the three effect-hook classes (count-mutation, radius-multiplier, non-state modifier). Remaining 2-5 MVP relics + full 5-8 VS roster authored in later passes using this framework.

## Player Fantasy

Every chest is a bet. Every relic is an answer.

You spend forty followers you could have kept. The T2 lid pops and *Magnet* drops into slot three — and your next heartbeat, you're already veering. That dense citizen cluster you were about to skip because the math didn't work? The math just changed. You roll into it and the snowball swells faster than it should, and for the next two minutes that one pull is the reason your crowd is the one rolling over the rival on the plaza steps. This is the gambler's beat grafted onto the snowball — the dopamine of a randomized gift that hands you a new plan mid-round.

The four-slot bar is the clock on the decision. Each pull narrows the next one: is this better than what I already hold, or do I skip the next chest and stay clean? A small crowd's desperate T3 raid and a lucky roll can be the whole reason they win (Pillar 5 — comeback is always one chest away). A big crowd's slot pressure is what keeps them honest — keeps every toll a real trade, not a rubber-stamp. Relics are the answer to *should I even open this?* — and in MVP we need only three of them to prove the feeling, because the fantasy is *this pull*, not *this build*.

## Detailed Design

### Core Rules

**1. Relic Lifecycle.** A relic slot progresses `Empty → Offered → Active → (Expiring →) Cleared → Empty`. Each of the 4 slots runs this state machine independently. See §States and Transitions for the full transition table.

**2. Draft Generation.** Chest System owns the roll. On successful chest open (toll paid, slot available): roll 3 candidate relics from `RelicRegistry`, filtered by chest tier and excluding any relic already in the opening crowd's `activeRelics`. If a slot collision re-rolls 3× without finding a distinct relic, that candidate slot draws from the next lower rarity tier. Rarity-weight-by-tier is owned by Chest System. Relic System's only constraint on the roll is "distinct from held".

**3. Slot Cap — Two-Layer Guard.** `MAX_RELIC_SLOTS = 4` (registry, owned by CSM).
- **Primary (prevent-open)**: Chest System greys out the chest billboard and blocks interaction when `#activeRelics >= 4`. Toll never spent.
- **Defensive (late-check)**: `RelicEffectHandler.grant()` re-asserts `#activeRelics < 4` at grant time. On fail (race condition — two chest draft UIs somehow resolved for the same crowd): silent reject, log server-side. No refund path needed because the primary guard keeps toll un-spent; any race implies a bug, not a legitimate player flow.

**4. Acquisition Flow — `grant()`.** Chest System calls `RelicEffectHandler.grant(crowdId, specId)` on player pick. Atomic sequence:
(a) Late-check slot cap.
(b) Write `ActiveRelicSlot` into `activeRelics[slotIndex]` with `grantedAtTick`, `durationTicks` (from spec), initialized `privateState`.
(c) Fire `onAcquire` (always fires — guaranteed by handler, not by spec).
(d) Register tick dispatch if spec declares `onTick` or `onCollisionTick`.
(e) Broadcast `CrowdRelicChanged` (reliable) with full slots snapshot.
No partial state observable to other systems.

**5. Hook Dispatch.** Handler dispatches via table lookup on the spec's `hookSet`. `onAcquire` and `onExpire` always fire for every grant/expire (handler-guaranteed). Other hooks (`onTick`, `onCollisionTick`, `onChestOpen`) fire only if the spec declares them. Absent hook key = no-op, no error.

**6. Effect Routing — Three Classes.** Spec declares `effectCategory ∈ {count, radius, non-state}`. Handler enforces routing:
- `count` → `CrowdStateServer.updateCount(crowdId, delta)`. Never a direct count write. Subject to CSM floor/ceiling clamps (1 via relic; 300 hard cap).
- `radius` → calls `CrowdStateServer.recomputeRadius(crowdId, newMultiplier)` (CSM Batch 1 API). CSM validates newMultiplier ∈ [0.5, 1.5], writes `crowd.radiusMultiplier` field, and recomposes `crowd.radius = radius_from_count(count) × radiusMultiplier`. RelicEffectHandler is the sole authorized caller. Absorb + Collision read post-multiplied `crowd.radius` via broadcast with no relic awareness.
- `non-state` → publishes `(crowdId, modifierKey, modifierValue)` to the owning system's modifier API (Follower Entity, Chest System, Absorb System). Owning system resolves composition.

**7. Same-Tick Ordering (locked by CSM §E).** TickOrchestrator runs: Collision → **Relic** → Absorb → Chest → Broadcast → PeelDispatch. Relic tick hooks (`onTick`, `onCollisionTick`) fire in step 2. Relic count-mutations may fire `CrowdStateServer.updateCount` from inside `onTick`; the Absorb step sees the updated count.

**8. GraceWindow + Eliminated Interaction.** In `GraceWindow` state: up-delta count relics apply (can restore count > 1 → Active transition). Down-delta count relics rejected at CSM write guard. Relics cannot push a crowd into or out of `Eliminated`. In `Eliminated` state: `onTick` continues to fire against the crowd between elimination and round-end (slot unregister is T6/T7 only — `clearAll()` at T9 Intermission or `CrowdDestroyed` signal); any mutation attempt lands on CSM §F5 clamp guard (silent no-op). Hooks must tolerate the no-op — never assume `updateCount` from `onTick` observably changed state post-Eliminated. Tick cost is trivial (few ticks before T9); no early-unregister optimisation required for MVP. (Added 2026-04-24 per SCE-NEW-1 of gdd-cross-review-2026-04-24-pm.md.)

**9. Duration Policy.** Spec declares `durationTicks: number?`. `nil` = permanent-for-round. Integer = countdown, decremented in step 2 each tick. On reach `0`: slot moves to `Expiring` (within that tick); handler processes all expiries after the full relic pass (no mid-pass slot mutation).

**10. Per-Relic Runtime State.** `ActiveRelicSlot.privateState: {[string]: any}?` holds server-only bookkeeping (charges, cooldowns, counters). Initialized by `onAcquire`. Mutated by tick hooks. **Never replicated.** HUD slot-bar renders from `RelicSnapshot` (specId + ticksRemaining only).

**11. `clearAll()` Sequence.** Called by Match State at T9 (Intermission entry), AFTER `RoundLifecycle.destroyAll()` completes synchronously:
(a) For each crowd, iterate slots in `slotIndex` ascending order; fire `onExpire` (always fires); non-state relics call owning system's `clearRelicModifier(crowdId, modifierKey)`; radius relics call `CrowdStateServer.recomputeRadius(crowdId, 1.0)` to reset multiplier via CSM API (direct field write forbidden by Batch 1 write-access contract).
(b) Empty all `activeRelics` tables.
(c) Do NOT broadcast `CrowdRelicChanged` during clearAll — round is ending and clients reset HUD via `MatchStateChanged` transition. Saves 8-12 broadcasts per round.
Idempotent; safe to call on an already-empty crowd.

**12. No Revival from Eliminated.** No hook may trigger an `Eliminated → Active` transition (CSM §C locked). Relic specs proposing revival are rejected at registry authoring time. `grant()` on an `Eliminated` crowd silently rejects.

### States and Transitions

Each of the 4 slots is an independent state machine.

| State | Description | Counts toward `#activeRelics`? |
|---|---|---|
| `Empty` | No relic. No effect. No tick registration. | No |
| `Offered` | Draft UI open; candidate pending pick. NOT in `activeRelics`. Transient. | No |
| `Active` | Record in `activeRelics[slotIndex]`. Effect applied. Hook dispatch enabled. | Yes |
| `Expiring` | Duration reached 0 mid-tick. `onExpire` queued for end-of-tick. Unstable. | Yes (for the partial tick) |
| `Cleared` | Record removed, `onExpire` fired, modifier retracted. Immediate transition to `Empty`. | No |

| # | From | To | Trigger | Owner |
|---|---|---|---|---|
| T1 | `Empty` | `Offered` | Chest draft opens | Chest System |
| T2 | `Offered` | `Active` | Player picks this relic in draft UI | `RelicEffectHandler.grant()` |
| T3 | `Offered` | `Empty` | Player picks different candidate, draft UI timeout, or PlayerRemoving | Chest System |
| T4 | `Active` | `Expiring` | `durationTicks` reaches 0 | Handler (end-of-tick scan) |
| T5 | `Expiring` | `Cleared` → `Empty` | End of tick; `onExpire` fires, record removed, broadcast | Handler |
| T6 | `Active` | `Cleared` → `Empty` | `clearAll()` called (T9 Intermission) | `RelicSystem.clearAll()` |
| T7 | `Active` | `Cleared` → `Empty` | `CrowdDestroyed` signal (PlayerRemoving mid-round) | Handler listening to CSM |

**Invariants:**
- `Offered` never goes directly to `Expiring` or `Cleared`. Must pass through `Active`.
- `Active → Offered` forbidden. Relics are not un-pickable.
- `Cleared` resolves to `Empty` within the same frame; never a resting state.
- `#activeRelics` counts `Active` + `Expiring` slots only. `Offered` does not occupy the cap.

### Interactions with Other Systems

**RelicSpec schema** (`ReplicatedStorage/Source/Relics/RelicSpec.luau`):

```lua
--!strict

export type RelicRarity = "Common" | "Rare" | "Epic"
export type RelicEffectCategory = "count" | "radius" | "non-state"

export type RelicHookSet = {
    onAcquire: boolean,       -- always true (handler enforces)
    onTick: boolean,
    onCollisionTick: boolean,
    onChestOpen: boolean,
    onExpire: boolean,        -- always true (handler enforces)
}

export type RelicParamTable = {
    -- count relics
    countDelta: number?,
    -- radius relics
    radiusMultiplier: number?,
    -- non-state relics
    targetSystem: string?,       -- "FollowerEntity" | "ChestSystem" | "AbsorbSystem"
    modifierKey: string?,        -- e.g. "TollDiscount"
    modifierValue: number?,
    modifierType: string?,       -- "multiplier" | "additive" | "override"
    durationTicks: number?,      -- nil = permanent-for-round
    allowedTiers: {number}?,     -- e.g. {2, 3} restricts to T2 + T3 chest pools
}

export type RelicUICopy = {
    iconAssetId: string,
    shortDesc: string,           -- ≤ 60 chars, loc-ready
}

export type RelicSpec = {
    id: string,                  -- matches RelicId enum key
    displayName: string,
    rarity: RelicRarity,
    hookSet: RelicHookSet,
    effectCategory: RelicEffectCategory,
    params: RelicParamTable,
    ui: RelicUICopy,
}
```

**Hook signatures and timing:**

| Hook | Signature | Timing |
|---|---|---|
| `onAcquire` | `(crowdId, spec, slotIndex) -> ()` | Fires synchronously in `grant()` before `CrowdRelicChanged` broadcast. Always fires. |
| `onTick` | `(crowdId, spec, dtServerTicks) -> ()` | TickOrchestrator step 2, after Collision, before Absorb. `dtServerTicks = 1` steady-state; `> 1` on accumulator catch-up. |
| `onCollisionTick` | `(crowdId, spec, overlappingRivals: {string}) -> ()` | Step 2 sub-call after Collision outputs `_overlapPairs`. Fires only when `overlappingRivals` non-empty. |
| `onChestOpen` | `(crowdId, spec, tier, toll) -> number` | Called by Chest System pre-deduction on EVERY active relic with this hook. Returns modified toll. Handler chains in `slotIndex` order. |
| `onExpire` | `(crowdId, spec, slotIndex) -> ()` | Fires in `remove()` before slot clear. Always fires. Non-state relics call owning-system `clearRelicModifier` here. |

**ActiveRelicSlot runtime shape** (server-only, in `CrowdState.activeRelics[slotIndex]`):

```lua
export type ActiveRelicSlot = {
    specId: string,
    slotIndex: number,
    grantedAtTick: number,
    durationTicks: number?,       -- countdown; nil = permanent-for-round
    privateState: {[string]: any}?,  -- never replicated
}
```

**RelicSnapshot replication shape** (in `CrowdRelicChanged` payload):

```lua
export type RelicSnapshot = {
    specId: string,
    slotIndex: number,
    ticksRemaining: number?,
}
-- Broadcast payload: { crowdId: string, slots: { RelicSnapshot } }
-- Full array replacement, not diff. Fires on: grant, expire, slot-clear.
-- Never per-tick. privateState never included.
```

**Integration contracts (one line each):**
- **Crowd State Manager** — count relics route via `CrowdStateServer.updateCount(crowdId, delta, "Relic")`; radius relics call `CrowdStateServer.recomputeRadius(crowdId, newMultiplier)`, CSM validates in [0.5, 1.5], writes `crowd.radiusMultiplier`, and recomposes `crowd.radius = radius_from_count(count) × multiplier`. ✓ CSM Batch 1 2026-04-24: `radiusMultiplier` field + `recomputeRadius(crowdId, newMultiplier)` API added per this spec; amendment complete.
- **Chest System** — pre-deduction call `RelicEffectHandler.queryChestToll(crowdId, tier, base_toll_scaled) -> number`; returns final toll after chaining `onChestOpen` hooks in slot order. **`base_toll_scaled` is the Chest §F1 output** (`max(T_FLAT[tier], ceil(count × T_PCT[tier]))`) — post-Batch-5 DSN-B-2 resolution, Chest scales toll by count before passing into Relic's chain. Signature unchanged from Relic's perspective; the `baseToll` parameter is now sourced from F1 output rather than flat T1/T2/T3_TOLL constants. Chest also calls `RelicEffectHandler.grant(crowdId, specId)` on player draft pick.
- **Follower Entity** — non-state move-speed/magnetism relics call `FollowerEntity.setRelicModifier(crowdId, key, value)` in `onAcquire` and `clearRelicModifier(crowdId, key)` in `onExpire`.
- **Absorb System** — zero relic awareness. Reads `crowd.radius` post-multiplied.
- **Match State Machine** — calls `RelicSystem.clearAll()` at T9 entry after `RoundLifecycle.destroyAll()` returns; synchronous; no argument.
- **HUD** — subscribes to `CrowdRelicChanged` reliable RemoteEvent; replaces local slot-bar on every broadcast using `RelicSnapshot` array.
- **TickOrchestrator** — Relic registers as step-2 callback; handler's tick pass iterates all crowds with non-empty `activeRelics`.

### Reference Relics (MVP Scope — 3 relics proving all 3 effect classes)

#### `TollBreaker` — Non-state modifier (Common)
- **Display**: "Toll Breaker — Pay less to open chests. Toll costs reduced by 30%."
- **Rarity**: Common. Legibility is highest (printed number); introductory relic.
- **Chest tiers**: T1 + T2 only (`allowedTiers: {1, 2}`). Excluded from T3 — at 120-follower base toll, a 36-follower discount is proportionally small vs. draft opportunity cost; keeps T3 draft hot.
- **Effect class**: non-state.
- **Hooks**: `onAcquire` → `ChestSystem.setRelicModifier(crowdId, "TollDiscount", 0.70, "multiplier")`. `onExpire` → `ChestSystem.clearRelicModifier(crowdId, "TollDiscount")`. No tick hooks. Duration: permanent-for-round.
- **Toll impact** (post-Batch-5 DSN-B-2 scaling): at floor — T1 10→7, T2 40→28. Late-game — T1 @ count=300: 24→17; T2 @ count=300: 60→42. Over 2-3 chest opens typical/round = 20-40 followers saved depending on round-stage.
- **Counter-play**: zero value if no further chest opens after acquisition; players who skip chests after drafting this wasted a slot.
- **Playtest red flag**: watch for T1-chain-chest early-game abuse; watch that discounted toll displays in the billboard (else relic reads "invisible").

#### `Surge` — Count mutation (Rare)
- **Display**: "Surge — Your crowd instantly gains 40 followers."
- **Rarity**: Rare. High-impact one-time burst.
- **Chest tiers**: T2 + T3 only (`allowedTiers: {2, 3}`). Excluded from T1 — at early count ~100, +40 is a 40% instant jump; would collapse early-game diversity.
- **Effect class**: count.
- **Hooks**: `onAcquire` → `CrowdStateServer.updateCount(crowdId, +40)`. No other hooks. Duration: N/A (one-shot).
- **Count impact**: +40 immediate. At count=160 → 200 (+25%). CSM 300-cap clamps silently near cap. Up-delta in GraceWindow allowed (can clear GraceWindow → Active transition).
- **Counter-play**: near-cap picks waste delta; burst evaporates in a losing collision within seconds.
- **Playtest red flag**: T3 + near-cap players reaching 300 immediately and using full-cap radius + count as a collision bulldozer. If "lock-in win" observed → cut T3 availability.

#### `Wingspan` — Radius multiplier (Epic)
- **Display**: "Wingspan — Your crowd's reach grows. Absorb and collision radius ×1.35."
- **Rarity**: Epic. Highest degenerate-strategy risk (radius is shared absorb + collision field); Epic framing signals "read before picking".
- **Chest tiers**: T2 + T3 only (`allowedTiers: {2, 3}`). Excluded from T1 — at count=10, 1.35× radius boost during neutral-absorb phase is dominant with no counterplay window.
- **Effect class**: radius.
- **Hooks**: `onAcquire` → `CrowdStateServer.recomputeRadius(crowdId, 1.35)`; CSM writes `crowd.radiusMultiplier = 1.35` and recomposes `crowd.radius`. `onExpire` → `CrowdStateServer.recomputeRadius(crowdId, 1.0)`. Duration: permanent-for-round.
- **Radius impact**: count=100 → radius 8.00 → 10.80. count=300 → 12.03 → 16.24. Absorb rate at count=100 rises from ~12.8/s → ~17.3/s (+35%).
- **Counter-play**: enlarged collision hitbox is the self-limit. Multi-rival overlap (`triple_overlap_drain` F4) punishes careless positioning harder.
- **Magnitude rationale (why 1.35)**: at 1.5× count=300 combined radius vs. equal rival = 36 studs, approaching map-wide unavoidable contact. At 1.75×+ sit-still strategy viable. 1.35 is the ceiling keeping the collision side-effect meaningful.
- **Playtest red flag**: passive chest-camping (Wingspan player sits at T2 spawn, catches all arrivals). If observed: add 1-2s radius-pause after chest open, or gate Wingspan to T3-only. Also verify visual legibility — crowd visual spread is independent of hitbox radius; players may be confused about their own reach. Prototype a subtle ground-disc indicator at `crowd.radius` scale.

## Formulas

The Relic System itself does light math — most numeric specification lives in individual `RelicSpec.params` tables. Two formulas span the framework.

### F1. `effective_toll_chain`

Toll reduction from `onChestOpen` hooks chains multiplicatively in `slotIndex` order. Chest System calls `RelicEffectHandler.queryChestToll(crowdId, tier, baseToll)` before deduction.

`effective_toll = floor(baseToll × ∏ₛ relicₛ.onChestOpen(...))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `baseToll` | `B` | int | [10, 60] (T1+T2 scaling range) ∪ {120} (T3 flat) | Sourced from Chest §F1 `base_toll_scaled`; NOT raw T1/T2/T3_TOLL constants (those are now FLOORS per Batch 5 DSN-B-2). Relic's chain applies after Chest scales. |
| `relicₛ.onChestOpen(...)` | `Mₛ` | float | [0.5, 1.0] | per-relic multiplier; absent relic = 1.0 (identity) |
| `slotIndex s` | `s` | int | [1, 4] | iteration order; lower slots applied first |
| `effective_toll` | `E` | int | [1, 120] | final deduction; floor clamp 1 |

**Output range:** `E ∈ [1, 120]`. Floor=1 prevents zero-toll exploits at extreme stacking. Non-stackable MVP rule means at most one toll-discount relic active → single multiplier.

**Example (MVP):** TollBreaker (`M = 0.70`), T2 chest: `E = floor(40 × 0.70) = 28`.

**Example (future stacking scenario — informational, not MVP):** Two toll relics at 0.70 and 0.80, T3 chest: `E = floor(120 × 0.70 × 0.80) = 67`. Confirms multiplicative, not additive — prevents a second relic from pushing toll to zero. Pure multiplicative gives ratchet-like diminishing returns.

### F2. `crowd.radius_with_multiplier`

Radius relics compose with the authoritative `radius_from_count` formula (registry, source ADR-0001). CSM stores the post-multiplied value.

`crowd.radius = radius_from_count(count) × crowd.radiusMultiplier`

Where `radius_from_count(count) = 2.5 + sqrt(count) × 0.55` (unchanged — registry owner ADR-0001).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `count` | `n` | int | [1, 300] | follower count (CSM) |
| `radiusMultiplier` | `μ` | float | [0.5, 1.5] | CSM record field; default 1.0; range bounded by max radius relic magnitude + any future shrink relic |
| `crowd.radius` | `r` | float | [1.53, 18.04] | post-multiplied, stored in CSM, read by Absorb + Collision |

**Output range at MVP with only Wingspan (`μ ∈ {1.0, 1.35}`):**
- `r_min = radius_from_count(1) × 1.0 = 3.05` studs
- `r_max = radius_from_count(300) × 1.35 = 12.03 × 1.35 = 16.24` studs

**Recomputation trigger:** CSM recomputes `crowd.radius` whenever `count` or `radiusMultiplier` changes. Wingspan `onAcquire` calls `CrowdStateServer.recomputeRadius(crowdId, 1.35)` — CSM validates the value in [0.5, 1.5], writes `μ = 1.35`, and recomposes `crowd.radius` for the next broadcast. Wingspan `onExpire` (or `clearAll`) calls `recomputeRadius(crowdId, 1.0)`. Idempotent — passing the current `μ` is a no-op.

**Why multiplicative, not additive:** an additive `+stud_count` relic at high `count` would be trivial relative to the base radius (at count=300, +3 studs = +25%); at low `count` it would be dominant (at count=10, +3 studs doubles the radius). Multiplicative keeps the percentage impact consistent across the round arc.

### Non-formulas — explicit reference

Math that MIGHT seem to belong here but is owned elsewhere:

| Math | Owner | Why not here |
|---|---|---|
| Relic draft roll distribution (3 candidates, rarity weights by tier) | Chest System GDD | Relic System imposes only "distinct from held" constraint |
| `radius_from_count` base formula | ADR-0001 / CSM | Registered formula; Relic System consumes it |
| Count-cap clamping at 300 | CSM §F5 | Clamp owned by CSM `updateCount` |
| `collision_transfer_per_tick` (TRANSFER_RATE_effective) | CSM / CCR | Relic count-mutations route through same `updateCount` path; no separate math |
| Toll value tuning (T1/T2/T3 magnitudes) | CSM registry (provisional); Chest System GDD (final) | Relic System uses whatever baseToll is current |

## Edge Cases

### Grant / Acquisition

- **If `grant()` called with `#activeRelics == 4`**: silent reject, log. Primary chest pre-check should prevent this; late-check is defensive (race between two simultaneously-resolved draft UIs).
- **If `grant()` called on `Eliminated` crowd**: silent reject. Chest System should block this upstream (chest billboard non-interactable post-elimination), but handler enforces defensively.
- **If duplicate relic grant attempted (race condition — roll produced duplicate during two simultaneous opens)**: late-check scans `activeRelics` for `specId` match; silent reject the duplicate grant.
- **If `grant()` called with unknown `specId`**: error server-side (registry integrity bug); no partial state. Treat as bug, not a player flow.
- **If player picks a draft candidate at exactly the same tick their crowd is Eliminated**: Match State's same-tick ordering puts Collision first; Eliminated fires in CSM step; Relic grant in step 2 sees `Eliminated` status → silent reject. Chest System's draft UI closes via `CrowdEliminated` signal.

### Hook Dispatch

- **If `onAcquire` raises an error**: wrapped in `pcall` by handler; log the error with `{crowdId, specId}`; slot record remains; `CrowdRelicChanged` still broadcasts. Relic is Active but may have uninitialized state. Acceptable for MVP (relic spec bugs are bugs, not runtime edges); strengthen to roll-back in post-MVP.
- **If `onExpire` raises an error**: wrapped in `pcall`; log; slot still cleared from `activeRelics`; modifier retraction still attempted. Relic cannot block its own removal.
- **If `onChestOpen` returns non-number or `nil`**: handler treats as `1.0` (identity multiplier); log warning. Prevents a single buggy relic from breaking every chest.
- **If `onChestOpen` returns negative or `> baseToll × 2`**: handler clamps to `[0, baseToll]` before passing to next slot in chain; log clamp. Prevents a bug from granting followers or multiplying toll.
- **If a tick hook mutates `activeRelics` directly (e.g., tries to self-remove)**: forbidden. Handler's tick pass iterates a snapshot of slot indices. Self-removal must set a flag read in the post-tick expiry scan. Enforced by code review, not runtime guard.

### Effect Class: Count Mutation

- **If count relic delta would exceed 300**: CSM clamps to 300 silently. Relic consumed. HUD "MAX CROWD" flash (CSM §D edge).
- **If count relic delta would drop count to ≤0**: CSM clamps to 1 (floor); crowd stays `Active` (no GraceWindow from relic-only). CSM §F5 locked.
- **If Surge acquired at `count = 295`**: grants +5 (clamped); +40 is the spec value but CSM floor/ceil wins. No refund.
- **If Surge acquired in `GraceWindow` at `count = 1`**: applies +40, crosses `count > 1` threshold, `GraceWindow → Active` transition fires. Timer cancelled. Crowd continues.
- **If Surge acquired on the same tick as a fatal collision**: Collision fires step 1 (sets `count = 1`, enters GraceWindow); Relic fires step 2 (Surge +40 → `count = 41`, exits GraceWindow). Surge "saves" the crowd from an overlap that would have ended in elimination. Intentional — Pillar 5 (comeback).

### Effect Class: Radius Multiplier

- **If radius relic acquired while already at max `count = 300`**: `crowd.radius = 12.03 × 1.35 = 16.24`. No clamp. OK.
- **If two radius relics granted simultaneously (future stacking scenario)**: non-stackable MVP rejects the second. Post-MVP: multipliers compose multiplicatively (e.g., `1.35 × 1.20 = 1.62`). Flag for VS playtest.
- **If Wingspan active when `radius_from_count` is re-evaluated via `updateCount`**: CSM always multiplies through `crowd.radiusMultiplier`; no stale-radius window.
- **If `clearAll()` fires before `crowd.radiusMultiplier` is reset**: `clearAll` itself resets `μ = 1.0` during `onExpire`. No stale multiplier after Intermission.
- **If radius relic's multiplier is < 1.0 (future "shrink" relic) at `count = 1`**: `r = 3.05 × 0.5 = 1.53` studs. Collision pair-test still works; absorb radius smaller. No engine issue. Flag for playtest to check if absorb feels broken at tiny radius.

### Effect Class: Non-state Modifier

- **If `setRelicModifier` called on an owning system that has already been destroyed (player DC'd)**: owning system's API must no-op gracefully. Responsibility of the owning system (Follower Entity, Chest System, Absorb System), not Relic System. Flagged as a cross-system contract note.
- **If TollBreaker active when chest toll is already below 1 (edge case if future relic sets baseToll < 2)**: F1 floor clamp prevents final toll < 1. TollBreaker's multiplier still applies mathematically; floor wins.
- **If `clearRelicModifier` called before `setRelicModifier` ever ran (handler bug)**: owning system should no-op silently. Defensive.

### Slot State / Lifecycle

- **If player DCs with an `Offered` slot (draft UI open)**: Chest System's `PlayerRemoving` hook fires; Offered slot returns to Empty; any rolled-but-not-picked candidates discarded.
- **If player DCs with `Active` slots**: CSM fires `CrowdDestroyed` signal; Relic handler flushes all slots via T7 transition (`Active → Cleared → Empty`); fires `onExpire` for each; no `CrowdRelicChanged` broadcast to the DC'd player.
- **If `durationTicks` reaches 0 on the same tick as `clearAll()` is called**: clearAll wins. `onExpire` fires exactly once (clearAll path). Defensive: handler's expiry scan checks slot still exists before calling `onExpire`.
- **If `durationTicks` reaches 0 on the same tick as a new relic is granted to a different slot**: independent slots; both process correctly. Expiry scan runs after the full tick relic pass, including the new grant.

### Replication / Broadcast

- **If `CrowdRelicChanged` fires faster than clients can receive (granted + expired in same tick)**: both broadcasts fire; client receives both; second overwrites first. Idempotent (full snapshot). Acceptable.
- **If client reconnects mid-round**: no per-player backfill broadcast (cost). Client reads its own `activeRelics` on first `CrowdBroadcast` tick. **Gap**: spectator-mode and late-join scenario should reconcile via a new `RemoteFunction` `GetActiveRelics(crowdId)` stateless query. Flagged in Open Questions.
- **If `CrowdRelicChanged` reliable event fires during Intermission**: handler rule §Core-11 says clearAll does NOT broadcast. If another source fires it (bug), client ignores per Match State transition reset. Defensive.

### Match Lifecycle

- **If `clearAll()` called during `Active` state (not Intermission)**: handler still executes correctly (idempotent). But violates Match State contract. Treat as bug. Flag at code review.
- **If Match State `ServerClosing` fires mid-round with `activeRelics` populated**: no cleanup needed. Relic state is server-memory only; process termination wipes it. No DataStore writes from Relic System ever (round-scoped, Pillar 3).
- **If a new round starts and Relic System state from previous round persists (clearAll bug)**: `createAll` on next round's Crowd State creation initializes `activeRelics = {}`. Even if `clearAll` failed, new round starts clean. Belt-and-suspenders.

### Cross-System

- **If Chest System calls `queryChestToll` before any relic is granted**: no hooks registered; handler returns `baseToll` unchanged. F1 with empty product = 1.0 identity.
- **If Chest System calls `grant(crowdId, specId)` and the spec's `effectCategory` mismatches the declared params (e.g., `count` category with no `countDelta`)**: handler logs integrity error at grant time; relic is rejected. Registry boot should have caught this; runtime is defensive.
- **If Follower Entity's `setRelicModifier` API is not yet implemented at MVP implementation time**: non-state modifier relics (TollBreaker is the only MVP non-state relic, and it targets Chest System, not Follower Entity) work. Move-speed relic class is MVP-deferred.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| Network Layer (template) | Approved | `RemoteEvent` for `CrowdRelicChanged` (reliable); `RemoteEvent` for draft UI pick (Chest System owns); `RemoteFunction` `GetActiveRelics` (proposed, see Open Questions) | Broadcast dispatch |
| PlayerData / ProfileStore (template) | Approved | None — Relic System is ephemeral, Pillar 3. No DataStore writes ever. | N/A |
| Crowd State Manager | Batch 1 Applied 2026-04-24 | `activeRelics` field on CrowdState record; `updateCount(crowdId, delta, "Relic")` for count relics; `crowd.radiusMultiplier` field (✓ added Batch 1); `recomputeRadius(crowdId, newMultiplier)` API (✓ added Batch 1 — two-arg signature); `CrowdDestroyed` signal (✓ added Batch 1) for slot flush on DC/round-end | Read + Write |
| Match State Machine | In Revision | `clearAll()` call at T9 Intermission entry (already specified in MSM §Interactions); `MatchStateChanged` broadcast consumer on client for HUD reset | Read + incoming call |
| ADR-0001 Crowd Replication Strategy | Proposed | `SERVER_TICK_HZ = 15` cadence; `radius_from_count` formula composition; `CrowdState.activeRelics` schema | Reused constants + schema |
| TickOrchestrator (spin-off, Core MVP) | Designed (within CCR GDD) | Registers Relic as step-2 callback after Collision, before Absorb. Locked ordering. | Incoming tick call |
| Pillar 2 (Risky Chests) | Approved | Primary pillar — chest toll + relic draft decision depth. Relic System is the decision-space owner. | Locks scope |
| Pillar 3 (5-Minute Clean Rounds) | Approved | Round-scoped only. No persistence. Enforces `clearAll()` hook. | Locks ephemerality |
| Pillar 5 (Comeback Always Possible) | Approved | Relic RNG variance + Surge-style pivots are the Pillar 5 lever. | Supports design goals |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Chest System | Not Started | `RelicEffectHandler.grant(crowdId, specId)` on draft pick; `queryChestToll(crowdId, tier, baseToll) -> number` pre-deduction; `RelicRegistry` content + `allowedTiers` filter metadata for draft roll; chest pre-check reads `#activeRelics` against `MAX_RELIC_SLOTS` | Read + Write (via function call) |
| HUD | Not Started (MVP) | Subscribes to `CrowdRelicChanged` reliable RemoteEvent; renders 4-slot bar from `{ RelicSnapshot }` array; reads `spec.ui.iconAssetId` + `spec.ui.shortDesc` via local `RelicRegistry` | Read-only (broadcast consumer) |
| Relic Card / Reveal UI | Not Started (Vertical Slice) | Reads `RelicRegistry[specId]` for 3 candidates Chest System passes; owns the pick-1-of-3 visual; on pick → fires `ChestSystem.pickRelic` remote which ultimately calls `RelicEffectHandler.grant` | Read via Chest System |
| Follower Entity | In Review | `setRelicModifier(crowdId, modifierKey, modifierValue, modifierType)` and `clearRelicModifier(crowdId, modifierKey)` API — **future (VS+)** for move-speed / magnetism relics. Not exercised by MVP 3-relic scope. | Write (via function call) — VS+ only |
| Absorb System | Designed (pending review) | Zero relic awareness required — Absorb reads `crowd.radius` post-multiplied. Contract confirmed by Absorb §E provisional (resolved by this GDD). | Indirect (via CSM) |
| Crowd State Manager | Batch 1 Applied 2026-04-24 | Count deltas via `updateCount(crowdId, delta, "Relic")`; radius multiplier via `recomputeRadius(crowdId, newMultiplier)` API (✓ CSM Batch 1 landed `radiusMultiplier` field + two-arg API); relic record storage on CSM via `activeRelics` | Write |

### Provisional assumptions (flagged for cross-check)

1. ✓ **RESOLVED 2026-04-24** via `/propagate-design-change` CSM Batch 1 hub. CSM now holds a mutable `radiusMultiplier: number` field (default 1.0, hard-ceiling range [0.5, 1.5] per registry `RADIUS_MULTIPLIER_MAX`) on the CrowdState record + exposes `CrowdStateServer.recomputeRadius(crowdId, newMultiplier)` as the RelicEffectHandler-only write path. No further CSM amendment required for radius composition.
2. **Chest System API: `setRelicModifier` / `clearRelicModifier`**. Chest System GDD must expose a ValueManager-equivalent API keyed by `modifierKey: string` to receive TollBreaker's toll-discount publication. Composition rule on Chest side: `effective_toll = floor(baseToll × ∏ multipliers)` per F1 of this GDD.
3. **Chest System draft UI and pool filtering**. Chest System owns the pick-1-of-3 UI, roll weighting by rarity+tier, and the `allowedTiers` filter read. Relic System only requires "distinct from held" filtering.
4. **Relic Card / Reveal UI** (VS tier) will render the draft screen using `RelicRegistry[specId]` data. Confirmed with UX when that GDD is authored.
5. **Follower Entity modifier API** (VS+) — not exercised by MVP scope but needed for move-speed / magnetism relic classes. Flag for Follower Entity GDD amendment when those relics are authored.

### Bidirectional consistency notes

- **RESOLVES** Absorb System §E provisional ("Relic modifies absorb radius") — Relic System now owns the radius-multiplier contract. Absorb confirmed radius-ignorant.
- **RESOLVES** CSM §C.1 / §F5 provisional ("Relic routing through RelicEffectHandler") — contract formalized here.
- **RESOLVES** Match State Machine §Interactions provisional ("Relic System exposes `clearAll()`") — formal `clearAll()` contract defined with ordering guarantee (after `destroyAll`, before Intermission timer).
- ✓ **CSM GDD Batch 1 amendment landed 2026-04-24** (`radiusMultiplier` field + `recomputeRadius(crowdId, newMultiplier)` API). This GDD's dependency on CSM radius-composition is fully satisfied. See `docs/architecture/change-impact-2026-04-24-csm-batch1.md` for the propagation record.
- **REQUIRES** Chest System GDD (when authored) to implement: draft UI, pool roll, pre-check slot cap, `setRelicModifier`/`clearRelicModifier` API, `queryChestToll` call before deduction, `grant` call on pick.
- **Systems Index update** required to mark `Relic System` In Review / Designed and update `Depended on by` column across CSM, MSM, Chest, HUD, Relic Card UI, Follower Entity, Absorb.

### No cross-server or persistence dependency

Relic System explicitly REJECTS any DataStore, ProfileStore, or MessagingService usage. Every relic is round-scoped (Pillar 3). Any proposal to persist relics across rounds, meta-progression-style, is blocked at design review — requires pillar amendment.

## Tuning Knobs

Framework-level knobs are stable; per-relic knobs are the balance surface that will iterate in playtest. All knobs live in config tables, never inline in code.

### Framework-level knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `DRAFT_CANDIDATE_COUNT` | 3 | [2, 4] | Pick-1-of-N at chest open | 4+ floods the decision, reads as analysis paralysis on mobile | 1 = no decision; flattens Pillar 2 | Chest System UI layout; Relic Card / Reveal UI |
| `DRAFT_REROLL_ATTEMPTS_PER_SLOT` | 3 | [1, 5] | Chest System re-roll cap when roll duplicates a held relic | 5+ can slow draft generation at small relic pools; negligible at ≥10 relics | 0 = duplicates leak into draft; breaks non-stackable rule | `#activeRelics` and pool size |
| `TOLL_FLOOR` | 1 | [1, 5] | F1 effective_toll floor clamp | 5+ invalidates toll-discount relic value at T1 | <1 = exploit: free T1 chests with stacked discounts | F1; TollBreaker balance |
| `RADIUS_MULTIPLIER_MIN` | 0.5 | [0.25, 0.9] | F2 `μ` lower bound (future shrink relic cap) | 0.9 = shrink relic negligible | 0.25 = shrink relic makes crowd uncatchable; breaks collision | F2; future relic design |
| `RADIUS_MULTIPLIER_MAX` | 1.5 | [1.2, 2.0] | F2 `μ` upper bound (future growth relic cap) | 2.0+ enables sit-still radius strategy | 1.2 = Wingspan not viable | F2; Wingspan + future radius relics |

### Per-relic knobs (MVP 3-relic scope)

#### TollBreaker
| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `TOLL_DISCOUNT_MULTIPLIER` | 0.70 | [0.50, 0.90] | Final toll vs base. Lower = bigger discount. |
| `TOLL_DISCOUNT_ALLOWED_TIERS` | {1, 2} | subset of {1, 2, 3} | Chest tiers that roll TollBreaker into draft pool |
| `TOLL_DISCOUNT_RARITY` | Common | Common/Rare | Rarity weight in Chest System draft roll |

**Break conditions**: at 0.50 + future stacking the floor exploit opens; at 0.90 the relic delivers <4 followers total per round, not worth a slot. Allowing T3 makes the 36-follower discount dominant relative to other T3 draft options.

#### Surge
| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `SURGE_COUNT_GRANT` | +40 | [20, 60] | One-shot count delta on acquire |
| `SURGE_ALLOWED_TIERS` | {2, 3} | subset of {2, 3} | T1 excluded — too dominant at early count |
| `SURGE_RARITY` | Rare | Common/Rare/Epic | Chest pool weight |

**Break conditions**: at +60 on T2 (count ~120 typical) is a 50% instant jump, collapsing early-game diversity; at +20 doesn't justify a 40-follower T2 toll. Including T1 breaks early-game balance (see red flag).

#### Wingspan
| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `WINGSPAN_RADIUS_MULTIPLIER` | 1.35 | [1.20, 1.50] | Compound multiplier on `crowd.radius` (F2) |
| `WINGSPAN_ALLOWED_TIERS` | {2, 3} | subset of {2, 3} | T1 excluded — too dominant at early count |
| `WINGSPAN_RARITY` | Epic | Rare/Epic | Chest pool weight |

**Break conditions**: at 1.50 + count=300 → 18 studs, combined-radius = 36 studs → map-width pressure; at 1.20 absorb-rate gain only +18% vs. +35% at 1.35 — may not feel worth Epic slot. Allowing T1 makes it instant-dominance in neutral-absorb phase.

### Locked constants (not tuning knobs — changing requires amendment)

- `MAX_RELIC_SLOTS = 4` — owned by CSM (registry). Changing needs CSM amendment + HUD slot-bar redesign.
- Same-tick ordering `Collision → Relic → Absorb → Chest` — locked by CSM §E / CCR GDD.
- `CrowdRelicChanged` reliable (not unreliable) — correctness requirement; switching to unreliable would allow dropped slot-bar updates.
- Round-scoped lifecycle — Pillar 3 lock; any persistent relic proposal requires pillar amendment.

### Provisional defaults owned elsewhere

- Chest System draft rarity weights by tier — owned by Chest System GDD when authored.
- Chest tolls T1/T2/T3 = 10/40/120 — CSM registry (provisional); Chest System GDD final.
- Relic UI iconography (`spec.ui.iconAssetId`) — owned by Art Bible §8.8 AssetId Registry.

### Where knobs live (implementation guidance)

- `RelicRegistry` table with one `RelicSpec` per relic → `ReplicatedStorage/Source/Relics/RelicRegistry.luau`
- `RelicId` enum (avoid magic strings per project convention) → `ReplicatedStorage/Source/SharedConstants/RelicId.luau`
- Framework constants (`DRAFT_CANDIDATE_COUNT`, `TOLL_FLOOR`, `RADIUS_MULTIPLIER_MIN/MAX`) → `ReplicatedStorage/Source/SharedConstants/RelicConfig.luau`
- `RelicEffectHandler` module → `ServerStorage/Source/Relics/RelicEffectHandler.luau`
- `RelicSpec` type + shared helpers → `ReplicatedStorage/Source/Relics/RelicSpec.luau`

## Visual/Audio Requirements

Relic System is not itself an asset owner — it's the event source. Assets + rendering live in HUD / Relic Card UI / VFX Manager / Audio Manager. This section specifies the trigger catalog those systems must honor.

### Event catalog (trigger → receiver contract)

| Event | Fires on | Payload | Receivers | Asset spec owner |
|---|---|---|---|---|
| `RelicGrantVFX` | `onAcquire` (all relics) | `{crowdId, specId, slotIndex, rarity}` | VFX Manager (burst at player crowd center); HUD (slot-bar pop-in) | Art Bible §8.8 — per-rarity VFX (Common = sparkle, Rare = ring-pulse, Epic = column-of-light) |
| `RelicExpireVFX` | `onExpire` (duration relics only) | `{crowdId, specId, slotIndex}` | VFX Manager (fade); HUD (slot-bar fade-out) | Art Bible §8.8 — neutral dissipate |
| `RelicDraftOpen` | Chest draft UI opens | `{crowdId, tier, candidates: {specId×3}}` | Relic Card / Reveal UI (VS tier); Audio Manager (draft-open sting) | Relic Card UI GDD (VS) |
| `RelicDraftPick` | Player confirms draft choice | `{crowdId, specId}` | Audio Manager (confirm sting); VFX Manager (pre-empts `RelicGrantVFX`) | Relic Card UI GDD (VS) |
| `RelicMaxSlotsFlash` | Chest billboard greyed (slots full) | `{crowdId}` | Chest Billboard UI; Audio Manager (denied tick) | Chest Billboard UI GDD |
| `RelicCountMaxFlash` | Count relic (e.g., Surge) triggers CSM 300-clamp | `{crowdId}` | HUD ("MAX CROWD" flash) | HUD GDD |

### SFX intent (handoff to Audio Director / Sound Designer)

- **Grant sting** — rarity-tiered, 0.4-0.8 s. Common: light chime. Rare: brass pulse. Epic: low-boom-and-rise (strongest emotional payoff — Pillar 2 moment).
- **Draft open** — tension-building 3-voice cascade; loops at low volume if player hesitates >2 s.
- **Draft pick** — decisive confirm click; distinct from standard UI SFX.
- **Slot full (denied chest)** — short negative tick; must NOT sound punishing (player did nothing wrong).
- **Count flash (Surge-caps)** — crowd-swell audio peak, tied to HUD flash.

### VFX intent (handoff to Technical Artist / VFX Manager)

- Grant FX anchored at `crowd.position` (CSM record); scale by `crowd.radius` so large crowds get proportionally larger bursts.
- Rarity color-coded but must respect the player's signature hue — use hue as base tint, rarity as accent (white / gold / iridescent).
- Wingspan's radius expansion should be visible on grant (one-shot ring at new radius); optional ground-disc at `crowd.radius` during Active is a playtest item (see §Wingspan red flag).
- No per-tick VFX emissions from the Relic System itself — all VFX are event-triggered (acquire, expire, draft).

📌 **Asset Spec** — Visual/Audio requirements are defined. After art bible is approved, run `/asset-spec system:relic-system` to produce per-asset specs (3 grant FX variants + 3 SFX variants + draft UI FX) and generation prompts.

## UI Requirements

Relic System provides data; UI is owned by HUD (persistent slot bar) + Relic Card / Reveal UI (draft modal).

### HUD slot bar (owner: HUD GDD)

- 4-slot horizontal bar, bottom-right of screen (art bible §6 HUD anchor).
- Each slot renders: `iconAssetId` (center), `ticksRemaining` (radial countdown overlay if non-nil), hover/long-press tooltip showing `shortDesc`.
- Empty slots rendered as dim outlined placeholder.
- Slot-bar state updates only on `CrowdRelicChanged` receipt. Client reads local `RelicRegistry` for icon + copy (avoids per-broadcast asset lookup).
- Mobile: tap-and-hold shows tooltip; PC: hover.
- Accessibility: colorblind-safe rarity indicator (shape badge, not color-only — art bible §4 principle applied).

### Relic Card / Reveal UI (owner: Relic Card UI GDD — Vertical Slice)

- Modal card-draft screen on chest open. Pauses input outside modal for draft duration.
- 3 cards, large-format, each showing: rarity banner, displayName, iconAssetId, shortDesc.
- Tap/click a card to pick; confirm click finalizes.
- Draft UI timeout (provisional): 8 s. On timeout, auto-pick card with highest rarity (or first if tie). Flag in Open Questions — final timeout owned by Relic Card UI GDD.
- Must not block absorb / movement input during modal (player's crowd keeps flocking around them; absorb paused server-side but visuals continue).

### Chest Billboard (owner: Chest Billboard UI GDD)

- Greyed-out state when `#activeRelics >= MAX_RELIC_SLOTS` — tooltip: "Relic slots full".
- Toll label shows `effective_toll` (post-F1), not `baseToll` — else TollBreaker reads invisible (see §C TollBreaker red flag).

### Data flow summary

```
CrowdRelicChanged (server)  -->  HUD slot bar
Chest draft open (server)   -->  Relic Card UI
Player pick (client)        -->  ChestSystem.pickRelic (remote)
                                   |
                                   v
                             RelicEffectHandler.grant (server)
                                   |
                                   v
                             CrowdRelicChanged (server) --> HUD re-render
```

All UI elements are read-only consumers of `RelicRegistry` (boot-loaded) and `CrowdRelicChanged` broadcasts. No UI reads server state directly.

**📌 UX Flag — Relic System**: HUD slot bar + Relic Card draft UI have distinct spec needs. In Phase 4 (Pre-Production), run `/ux-design` for Relic Card UI (VS tier) before writing Relic Card UI epics. Stories referencing draft-modal UX should cite `design/ux/relic-card.md`, not this GDD directly.

## Acceptance Criteria

### Lifecycle & State Machine

**AC-1 — Lifecycle: Empty → Offered → Active on grant.** GIVEN a crowd with an empty slot and fewer than 4 active relics, WHEN the Chest System calls `RelicEffectHandler.grant(crowdId, specId)`, THEN the targeted slot transitions from `Empty` through the grant sequence to `Active`; `activeRelics` count increments by 1; and `CrowdRelicChanged` fires exactly once carrying the new slot in the snapshot. *Evidence: integration.*

**AC-2 — Draft distinct-from-held constraint.** GIVEN a crowd with TollBreaker already in slot 1, WHEN the Chest System generates a 3-candidate draft and all 3 raw rolls return TollBreaker, THEN all 3 candidates are re-rolled (up to `DRAFT_REROLL_ATTEMPTS_PER_SLOT` times) and TollBreaker does not appear as a selectable candidate; if no distinct candidate is found after 3 re-rolls, the slot draws from the next lower rarity tier. *Evidence: unit.*

**AC-3 — Slot cap primary guard: chest interaction blocked at 4 relics.** GIVEN a crowd has exactly 4 Active relic slots (`#activeRelics == 4`), WHEN the player approaches a chest billboard, THEN the billboard is greyed out and non-interactable; no toll is deducted; `grant()` is never called. *Evidence: manual playtest (co-owned with Chest System test plan).*

**AC-4 — Slot cap defensive late-check: silent reject on race.** GIVEN a crowd already holds 4 Active relics (cap reached between chest UI resolution and grant call), WHEN `RelicEffectHandler.grant(crowdId, specId)` is called, THEN the call returns without modifying `activeRelics`, logs a server-side message, and fires no `CrowdRelicChanged` broadcast. *Evidence: unit.*

**AC-5 — `grant()` atomic sequence: acquire-hook fires before broadcast.** GIVEN a valid grant call for any relic spec that declares `onAcquire`, WHEN `grant()` executes, THEN the `onAcquire` hook completes before `CrowdRelicChanged` is broadcast; at no point between hook invocation and broadcast is partial state observable to another system. *Evidence: unit (spy log call order).*

**AC-6 — Hook dispatch: absent hook is a no-op, no error.** GIVEN a RelicSpec with `hookSet.onTick = false`, WHEN TickOrchestrator fires step-2 for that crowd, THEN the handler does not invoke any tick callback for that relic slot and raises no error. *Evidence: unit.*

**AC-7 — Hook dispatch: declared hook fires at correct tick-pass position.** GIVEN a relic with `hookSet.onTick = true` is Active, WHEN one server tick completes, THEN the `onTick` callback fires in TickOrchestrator step 2 (after Collision step 1, before Absorb step 3), confirmed by mock call-order log. *Evidence: unit.*

### Effect Routing

**AC-8 — Count relic routes through `updateCount`, not direct write.** GIVEN Surge is Active for a crowd, WHEN `onAcquire` fires, THEN `CrowdStateServer.updateCount(crowdId, +40)` is called exactly once; no direct write to `CrowdState.count` occurs from within the Relic handler. *Evidence: unit.*

**AC-9 — Radius relic writes `radiusMultiplier`, CSM computes `crowd.radius`.** GIVEN Wingspan is granted to a crowd with count = 100, WHEN `onAcquire` fires, THEN `crowd.radiusMultiplier` is set to 1.35 and `crowd.radius` is recomputed to `radius_from_count(100) × 1.35 = 8.00 × 1.35 = 10.80` studs (±0.01 float tolerance); Absorb System and Collision read this post-multiplied value with no relic awareness. *Evidence: unit.*

**AC-10 — Non-state relic publishes modifier to owning system.** GIVEN TollBreaker is granted, WHEN `onAcquire` fires, THEN `ChestSystem.setRelicModifier(crowdId, "TollDiscount", 0.70, "multiplier")` is called once; and `onExpire` later calls `ChestSystem.clearRelicModifier(crowdId, "TollDiscount")`. *Evidence: unit.*

### GraceWindow & Count Guards

**AC-11 — GraceWindow: up-delta count relic applies; can trigger Active transition.** GIVEN a crowd in `GraceWindow` state at count = 1, WHEN Surge is granted (`onAcquire` fires `updateCount(crowdId, +40)`), THEN CSM applies the delta (count becomes 41), the `GraceWindow → Active` transition fires, and the crowd continues the round. *Evidence: integration.*

**AC-12 — GraceWindow: down-delta count relic rejected.** GIVEN a crowd in `GraceWindow` state at count = 1, WHEN a count relic with `countDelta = -10` attempts `updateCount(crowdId, -10)`, THEN CSM rejects the down-delta; count remains 1; crowd state does not change. *Evidence: unit.*

### Duration & Expiry

**AC-13 — Duration policy: `durationTicks` countdown and end-of-tick expiry.** GIVEN a relic with `durationTicks = 5` is Active, WHEN 5 server ticks complete, THEN the slot transitions to `Expiring` within tick 5; `onExpire` fires during the post-tick expiry scan (after the full relic pass of that tick); the slot is cleared to `Empty` and `CrowdRelicChanged` broadcasts the updated snapshot. *Evidence: unit.*

### Replication & Privacy

**AC-14 — `privateState` not included in broadcast.** GIVEN a relic with `privateState = { charges = 3 }` is Active, WHEN `CrowdRelicChanged` fires, THEN the broadcast payload contains only `{ specId, slotIndex, ticksRemaining }` per slot; no `privateState` field is present. *Evidence: unit.*

**AC-15 — `CrowdRelicChanged` fires on acquire/expire only, not per-tick.** GIVEN a crowd with 2 Active relics (one with `onTick` hook), WHEN 10 server ticks pass with no grant or expiry, THEN `CrowdRelicChanged` fires 0 times during those ticks. *Evidence: unit.*

### `clearAll()` Contract

**AC-16 — `clearAll()` fires `onExpire` per slot, clears all, emits no broadcast.** GIVEN a crowd with 3 Active relics (including Wingspan with `radiusMultiplier = 1.35`), WHEN `RelicSystem.clearAll()` is called, THEN `onExpire` fires for each of the 3 slots in ascending `slotIndex` order; `crowd.radiusMultiplier` resets to 1.0; `activeRelics` is empty; and `CrowdRelicChanged` is not broadcast. *Evidence: unit.*

**AC-17 — `clearAll()` is idempotent.** GIVEN `clearAll()` has already been called and all slots are empty, WHEN `clearAll()` is called again, THEN no errors are raised, `onExpire` is not called, and `activeRelics` remains empty. *Evidence: unit.*

### No Revival & DC Handling

**AC-18 — `grant()` on Eliminated crowd: silent reject.** GIVEN a crowd in `Eliminated` state, WHEN `RelicEffectHandler.grant(crowdId, specId)` is called, THEN the grant is silently rejected; `activeRelics` is unchanged; no `CrowdRelicChanged` fires; no error is thrown. *Evidence: unit.*

**AC-19 — Player DC with Active relics: slots flushed via `CrowdDestroyed`.** GIVEN a player with 2 Active relics disconnects mid-round, WHEN CSM fires the `CrowdDestroyed` signal, THEN the Relic handler fires `onExpire` for each Active slot and clears them to `Empty`; `CrowdRelicChanged` is not broadcast to the disconnected player. *Evidence: integration.*

### Formulas

**AC-20 — F1 TollBreaker: T2 toll 40 → 28 (multiplicative floor).** GIVEN TollBreaker (`M = 0.70`) is Active, WHEN Chest System calls `RelicEffectHandler.queryChestToll(crowdId, 2, 40)`, THEN the return value is `floor(40 × 0.70) = 28`. *Evidence: unit.*

**AC-21 — F1 `onChestOpen` returning `nil` treated as identity (1.0).** GIVEN a relic whose `onChestOpen` hook returns `nil` (bug simulation), WHEN `queryChestToll` chains through that slot, THEN the handler substitutes `1.0` for the `nil` return; logs a warning; and the toll is unchanged by that slot; no error propagates. *Evidence: unit.*

**AC-22 — F2 Wingspan: μ = 1.35 applied; absorb and collision both read post-multiplied radius.** GIVEN Wingspan is Active on a crowd at count = 300, WHEN any system reads `crowd.radius`, THEN the value is `radius_from_count(300) × 1.35 = 12.03 × 1.35 = 16.24` studs (±0.01); neither Absorb System nor Collision System hold a stale pre-multiplied value. *Evidence: integration.*

### Performance

**AC-23 — Relic tick pass within budget (0.1 ms per tick, advisory).** GIVEN 3 active crowds each with 2 Active tick-hook relics, WHEN TickOrchestrator fires step 2, THEN the total time spent inside the Relic handler's tick pass does not exceed 0.1 ms, measured via `os.clock()` instrumentation in a Studio test environment. *Evidence: integration (advisory — Studio hardware not isolated; fallback to 5-min soak with no TickOrchestrator watchdog warnings if isolated bench unavailable).*

**AC classification summary:**
- BLOCKING — unit: AC-2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 20, 21
- BLOCKING — integration: AC-1, 11, 19, 22
- ADVISORY — integration: AC-23
- ADVISORY — manual playtest: AC-3

## Open Questions

None blocking at authoring time. All cross-system contracts tracked in §Dependencies Provisional Assumptions (5 items) and §Detailed Design Integration Contracts. Two items to watch during implementation:

1. **Late-join / reconnect relic state reconciliation** — `GetActiveRelics(crowdId)` `RemoteFunction` proposed in §Edge Cases Replication for spectator + mid-round-rejoin. Keep as deferred until playtest confirms cost; if dropped slot-bar updates observed on reconnects, implement before Vertical Slice.
2. **Wingspan ground-disc indicator** — Prototype subtle ground-disc VFX at `crowd.radius` scale during Wingspan Active. Ship only if playtests show confusion about reach. Handoff: VFX Manager GDD.
