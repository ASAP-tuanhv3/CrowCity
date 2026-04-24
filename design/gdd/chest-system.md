# Chest System

> **Status**: In Design (2026-04-24 Batch 4 amendment — guard 3c tightened to `crowdState == "Active"` (rejects GraceWindow per CSM state table) per /review-all-gdds RC-B-NEW-1; draft modal close-on-opener-elim client hook added via `CrowdEliminated` subscription per S4-B1; 7 minimap references marked deferred to VS+ per HUD §C no-minimap-MVP decision.)
> **Author**: user + game-designer + systems-designer + economy-designer
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 2 (Risky Chests) primary; 5 (Comeback Always Possible) supporting
> **MVP Scope**: T1 chest + T2 car only. T3 building deferred to Alpha (systems-index row 30).

## Overview

The **Chest System** is the server-authoritative spawn, proximity-interaction, toll-deduction, and relic-draft-orchestration layer for every chest instance in a round. Static chest Parts are tagged with `ChestTag` + `ChestTierAttribute` by Level Design; on `RoundLifecycle.createAll()` the system scans the tagged instances, attaches a `ChestComponent` via `ComponentCreator` (ANATOMY §9), activates the `ProximityPrompt`, and raises the overhead toll billboard. When a player with `participationFlag = TRUE` and crowd state `Active` triggers the prompt, the system runs a serial pre-check pipeline — Match State is `Active`, relic slots are not full, and live `count > queryChestToll(tier, baseToll)` — any failure greys the prompt and rejects silently (no toll ever partial-spent). On success the system deducts the toll atomically via `CrowdStateServer.updateCount(crowdId, -effectiveToll)`, rolls a 3-candidate draft from `RelicRegistry` filtered by tier + excluding held, broadcasts the draft to the opening client's modal UI, and — on pick — fires `RelicEffectHandler.grant(crowdId, specId)` before destroying the chest instance and scheduling the tier's respawn. The system also exposes `setRelicModifier` / `clearRelicModifier` APIs consumed by non-state toll-discount relics (`TollBreaker`). Interactions server-guard on `participationFlag AND state == Active`; chests disappear at `RoundLifecycle.destroyAll()` and never persist (Pillar 3).

For the player, this is Pillar 2 made physical: a visible tier-coded target sitting in the city, demanding a follower sacrifice you watch peel off your mob and vanish into the box, then the lid pops and the draft cards slide up. The decision beat is three-layered — *is my crowd big enough to afford this?*, *which tier do I chase?*, *which of the three rolled relics do I want?* — and every one of those answers is visible in tier color, toll number, and rolled cards without a single menu nested deeper. Small crowds scout T1 chests to snowball a lucky Surge roll (Pillar 5 comeback); large crowds pay 120 into T3 for an Epic Wingspan because they can. The chest is the map-planted dopamine spike that makes the snowball a decision, not just a race.

**Scope (MVP)**: T1 chest (10-toll, gold) + T2 car (40-toll, silver-blue). T3 building (120-toll, violet) deferred to Alpha per concept MVP definition. Framework supports all 3 tiers from day one; T3 activation requires only asset + spawn-point authoring.

## Player Fantasy

Big crowds own the map. Small crowds steal the prize.

You see the violet beam on the far side of the arena — T3 — and two bigger crowds are already circling it. You look down: forty followers, not enough to pay in yet, and the minute three timer is ticking. You route for the T2 car instead, tucked behind a block where the leader can't see it, and commit the sprint while their eyes are on the bigger prize. Twenty-eight followers peel off into the silver-blue car, the lid snaps up, and you're already moving again before the draft UI finishes its slide. This is the chest beat — the approach, not the open. The decision lives in the commitment of movement: *which tier, which angle, which window*. Every beam on the map is a lure and a warning; every toll you pay is thirty seconds of absorb work you're betting on a roll you haven't rolled yet.

Big crowds get the luxury: they see every chest, they afford every tier, they stand on top of T3 and dare rivals to approach. Small crowds get the cunning: they read the map for the chest the leader can't spot, they time the raid for when the big mob is chasing a rival on the other side of the plaza, they take the T1 nobody's watching and snowball on a lucky Surge (Pillar 5 — the comeback is a route, not a miracle). The chest occlusion risk isn't a bug — it's the game. The crowd big enough to find the prize is big enough to be seen finding it. The crowd small enough to slip in unseen is small enough to pay the price. Approach is the verb. Raid is the fantasy.

## Detailed Design

### Core Rules

**1. Spawn and Attachment.** At Match State T4 (Active entry), `ChestSystem.createAll()` iterates every Part in Workspace tagged with `ChestTag` (CollectionService) and reads its `ChestTierAttribute` to determine tier. For MVP, tiers 1 and 2 are attached; `tier == 3` Parts are silently skipped (T3 deferred to Alpha). For each eligible Part, a `ChestComponent` is attached via ComponentCreator (ANATOMY §9). Each component owns the Part's `ProximityPrompt`, billboard binding, state machine, and respawn timer for that round. Parts are inert world geometry before `createAll()` and after `destroyAll()`.

**2. ProximityPrompt Activation Rules.** Each chest's `ProximityPrompt.MaxActivationDistance` is set to `CHEST_PROMPT_DISTANCE` (20 studs — clears worst-case crowd radius at count=300 with Wingspan ×1.35 = 16.2 studs, plus margin). `HoldDuration` is set to `CHEST_PROMPT_HOLD_SEC` (0.8s — prevents accidental trigger during mid-chase passes; short enough the exposure cost stays meaningful). Prompt visibility is gated: disabled when `#activeRelics >= MAX_RELIC_SLOTS`, billboard shows greyed "slots full" state. Prompt is also disabled whenever chest is not in `Available` state.

**3. Pre-Interaction Guard Pipeline.** When `ProximityPrompt.Triggered` fires server-side, guards evaluate in strict sequential order. First failure rejects the entire interaction; no later guards run; no side-effects:
- (a) `matchState == "Active"` — reject if Lobby/Countdown/Result/Intermission
- (b) `participationFlag == TRUE` — reject if excluded participant or spectator
- (c) `crowdState == "Active"` — reject if crowd is in `GraceWindow` OR `Eliminated` (strict Active-only per CSM state table §States: Chest column `no` for both GraceWindow and Eliminated). Was previously `!= "Eliminated"` which allowed GraceWindow — tightened 2026-04-24 Batch 4.
- (d) `#activeRelics < MAX_RELIC_SLOTS` — reject if all 4 slots full (prompt should be disabled upstream; server re-asserts defensively)
- (e1) `base_toll_scaled = max(T_FLAT[tier], ceil(crowd.count × T_PCT[tier]))` — F1 per-tier scaling (DSN-B-2 Batch 5)
- (e2) `effectiveToll = RelicEffectHandler.queryChestToll(crowdId, tier, base_toll_scaled)` — read-only query; chains `onChestOpen` hooks using F1 output
- (f) `crowdCount > effectiveToll` — strict greater-than (not ≥); reject if unaffordable

No guard has side-effects on reject. On pass, interaction proceeds to claim.

**4. Open Exclusivity and Tiebreak.** First `ProximityPrompt.Triggered` to pass all guards claims the chest. Two same-frame triggers (both arrive before state machine advances to `Claimed`) resolve by 2D squared-distance from crowd position to chest position; nearest wins. Ties on distance break by lower `UserId`. Losing trigger silently discarded.

**5. Toll Deduction Atomicity.** Claim-confirmed, the server executes as a single atomic step: `CrowdStateServer.updateCount(crowdId, -effectiveToll)` followed immediately by chest state set to `Claimed`. No other operation runs between these calls. Because chest runs LAST in the locked tick order (Collision → Relic → Absorb → Chest), the count seen by guard (f) already reflects all intra-tick mutations — partial-spend impossible.

**6. Peel-Off Visual Timing.** Post-`updateCount`, server fires `ChestPeelOff` event to opening client only with `{crowdId, chestId, followerCount: effectiveToll}`. Client plays peel-off animation: `effectiveToll` follower meshes detach from crowd formation, march toward chest over ~0.5s, vanish on contact. Purely cosmetic — authoritative count already decremented. Only opener sees the peel; other players see their own count broadcasts unaffected.

**7. Draft Roll Generation.** After toll deduction, server generates `DRAFT_CANDIDATE_COUNT = 3` relic candidates. Per candidate slot: (a) roll rarity from tier's `rarityWeights` table (T1 Common-heavy, T2 Rare-heavy, T3 Epic-heavy); (b) pick a random relic from `RelicRegistry` where `spec.params.allowedTiers` contains this chest's tier AND `specId ∉ crowd.activeRelics` AND `specId ∉ candidates_already_rolled_this_draft`; (c) on filter-empty at rolled rarity, re-roll the rarity up to `DRAFT_REROLL_ATTEMPTS_PER_SLOT = 3` times at the same rarity, then fall to next lower rarity. If lowest rarity also exhausts, that slot displays as "pool exhausted" (MVP 3-relic pool edge — see §E).

**8. Draft UI Delivery.** Server fires reliable `RemoteEvent` `ChestDraftOffer` to opening client only, payload `{chestId, tier, candidates: {specId×DRAFT_CANDIDATE_COUNT}}`. Chest transitions to `DraftOpen`. Client renders Relic Card UI using local `RelicRegistry` lookup per `specId`. Other players see chest prompt disabled; draft contents not revealed.

**9. Pick, Grant, Destroy, Respawn Schedule.** Server receives `ChestDraftPick` remote (validates `specId ∈ draftCandidates` + `player.UserId == claimedBy.UserId`). Sequence: (a) `RelicEffectHandler.grant(crowdId, specId)` — fires `onAcquire`, broadcasts `CrowdRelicChanged`; (b) transition to `Opened`; (c) `ChestComponent:destroy()` removes prompt + billboard; (d) defer respawn timer for `CHEST_RESPAWN_SEC_[tier]`. Part remains inert during `Cooldown`; re-materializes (opacity tween) during `Respawning`; component re-attaches and state returns to `Available`.

**10. Draft Timeout.** If client doesn't send `ChestDraftPick` within `DRAFT_TIMEOUT_SEC = 8`, server auto-picks candidate with highest rarity (Epic > Rare > Common); ties break by lowest candidate array index. Auto-pick proceeds identically to manual pick — grant fires, chest destroys, respawn schedules. No toll refund, no penalty.

**11. Non-State Modifier API.** ChestSystem exposes `setRelicModifier(crowdId, modifierKey, modifierValue, modifierType)` and `clearRelicModifier(crowdId, modifierKey)`. Storage lives in `ChestSystem._crowdModifiers: {[crowdId]: {[modifierKey]: {value, modifierType}}}` — per-crowd, not per-chest (TollBreaker applies to all chests for that player). `queryChestToll` reads this map + calls Relic's `onChestOpen` chain. Billboard always displays `effectiveToll` (post-queryChestToll), never raw `baseToll`.

**12. Round End Cleanup.** At Match State T9 (Intermission entry), `ChestSystem.destroyAll()` is called synchronously. All `ChestComponent` instances `destroy()`, cancelling respawn timers and removing prompts/billboards. Any `DraftOpen` chests auto-pick per rule 10 FIRST (ensures `grant()` fires and `CrowdRelicChanged` broadcasts before teardown). `Cooldown` / `Respawning` chests cancel without relic side-effects. `_crowdModifiers` cleared. No state persists across rounds.

**13. No Partial Toll Invariant.** Toll deduction is all-or-nothing. Any code path invoking `updateCount(crowdId, -toll)` without the guard-first pipeline is a bug. The tick ordering guarantee (Chest last) closes the race window: no mutation between guard check and deduction is possible.

### States and Transitions

Each `ChestComponent` instance is an independent per-chest state machine (not per-player).

| State | Description |
|---|---|
| `Dormant` | Default before `createAll()`. Part = inert geometry. No prompt, no billboard, no component. |
| `Available` | Component attached, prompt active, billboard shows toll + tier. Accepting triggers. |
| `Claimed` | A `crowdId` passed all guards; toll deducted. Prompt disabled for all players. Draft roll in progress. Transient (<1 frame). |
| `DraftOpen` | Candidates resolved; `ChestDraftOffer` sent. Awaiting pick or 8s timeout. |
| `Opened` | Pick confirmed; `grant()` called. Component tearing down. Transient (<1 frame). |
| `Cooldown` | Part inert; respawn timer ticking. Non-interactable. |
| `Respawning` | Timer fired; Part re-materializing (opacity tween). Component re-attaching. |

| # | From | To | Trigger | Owner |
|---|---|---|---|---|
| T1 | `Dormant` | `Available` | `createAll()` at Match State T4 (Active entry) | ChestSystem |
| T2 | `Available` | `Claimed` | `ProximityPrompt.Triggered` passes all guards; toll deducted atomically | ChestComponent |
| T3 | `Claimed` | `DraftOpen` | Draft candidates resolved; `ChestDraftOffer` fired | ChestComponent |
| T4 | `DraftOpen` | `Opened` | Player sends `ChestDraftPick` within 8s; `grant()` called | ChestComponent + RelicEffectHandler |
| T5 | `DraftOpen` | `Opened` | `DRAFT_TIMEOUT_SEC = 8` elapsed; auto-pick highest rarity | ChestComponent |
| T6 | `Opened` | `Cooldown` | `destroy()` completes; respawn timer started for tier | ChestComponent |
| T7 | `Cooldown` | `Respawning` | `CHEST_RESPAWN_SEC_[tier]` elapsed | ChestComponent (deferred timer) |
| T8 | `Respawning` | `Available` | Re-materialization complete; prompt re-enabled | ChestComponent |
| T9 | `Available` | `Dormant` | `destroyAll()` at Match State T9 | ChestSystem |
| T10 | `Claimed` | `Dormant` | `destroyAll()` during claim — grant fires before destroy completes | ChestSystem |
| T11 | `DraftOpen` | `Dormant` | `destroyAll()` during draft — auto-pick fires first per rule 12 | ChestSystem |
| T12 | `Cooldown` | `Dormant` | `destroyAll()` during cooldown — timer cancelled | ChestSystem |
| T13 | `Respawning` | `Dormant` | `destroyAll()` during respawn — aborted | ChestSystem |

**Invariants:**
- `Dormant` is the only valid state before first `createAll()`.
- Only one crowd occupies `Claimed → DraftOpen → Opened` path per chest at a time. All other triggers silently rejected until chest re-enters `Available`.
- No toll ever partial-spent across any transition. T2's deduction + state-set are atomic.
- `Cooldown → Respawning → Available` chains deterministically per tier. Only `destroyAll()` interrupts.
- `count > effectiveToll` permanently satisfied at T2 because Chest runs last in tick ordering.
- `destroyAll()` from any non-Dormant state: draft-open chests auto-pick first, ensuring no missed `CrowdRelicChanged` broadcast.

### Interactions with Other Systems

**ChestSpec schema** (`ReplicatedStorage/Source/Chests/ChestSpec.luau`):

```lua
--!strict
export type ChestTier = 1 | 2 | 3

export type RarityWeightTable = {
    Common: number,   -- probability weight, sum = 1.0
    Rare: number,
    Epic: number,
}

export type ChestSpec = {
    tier: ChestTier,
    baseToll: number,                      -- FLOOR; mirrors T1/T2/T3_TOLL registry. Per-tier tollPct scaling applied at runtime via §F1 `base_toll_scaled`.
    tollPct: number,                       -- percentage-of-count lever; mirrors T1/T2/T3_TOLL_PCT registry (Batch 5 DSN-B-2)
    modelAssetId: string,                  -- rbxassetid://...
    tierColor: string,                     -- hex e.g. "#FFD700"
    glowBeamAssetId: string,
    iconAssetId: string,
    proximityPromptDistance: number,       -- studs
    proximityPromptHoldDuration: number,   -- seconds
    respawnSec: number,                    -- cooldown after open
    rarityWeights: RarityWeightTable,
}
```

**ChestRegistry** — static table keyed by tier, boot-loaded, no runtime mutation. `ChestRegistry.getSpec(tier): ChestSpec` asserts tier registered.

**ChestState runtime shape** (server-only, per-instance):

```lua
export type ChestStateStatus = "Dormant" | "Available" | "Claimed" | "DraftOpen" | "Opened" | "Cooldown" | "Respawning"

export type ChestState = {
    chestId: string,                   -- unique per instance per round
    tier: ChestTier,
    position: Vector3,                 -- from tagged Part.Position; immutable after createAll
    state: ChestStateStatus,
    claimedBy: string?,                -- crowdId of claiming player; nil when Available
    openedAt: number?,                 -- os.clock() at toll-deduct success
    draftCandidates: { string }?,      -- specId array of length DRAFT_CANDIDATE_COUNT
    respawnAt: number?,                -- os.clock() + respawnSec; nil when not in Cooldown
    modelInstance: BasePart?,
    proximityPrompt: ProximityPrompt?,
}
```

Per-crowd modifier state lives on the ChestSystem module, NOT per-chest:

```lua
ChestSystem._crowdModifiers: {[crowdId: string]: {[modifierKey: string]: {value: number, modifierType: string}}}
```

**Integration contracts (one to two lines each):**

- **Crowd State Manager** — read `CrowdStateServer.get(crowdId).count` against strict `count > effectiveToll` guard AND `crowdState == "Active"` guard (rejects GraceWindow + Eliminated per CSM state table); write `CrowdStateServer.updateCount(crowdId, -effectiveToll, "Chest")` atomically post-guard. **Server-side:** listens to `CrowdDestroyed` signal (reliable RemoteEvent, CSM Batch 1) to flush `_crowdModifiers[crowdId]` on record-destruction (DC/round-end). **Client-side:** draft modal subscribes to `CrowdEliminated` (reliable RemoteEvent) for opener crowdId and closes modal on fire (AC-23 / S4-B1). Two signals serve distinct purposes: Eliminated = state transition (record persists), Destroyed = record removal (record gone).
- **Relic System** — call `RelicEffectHandler.queryChestToll(crowdId, tier, baseToll) → number` pre-deduction; call `RelicEffectHandler.grant(crowdId, specId)` on pick; expose `setRelicModifier` / `clearRelicModifier` consumed by TollBreaker and future non-state toll-discount relics; pre-check `#activeRelics >= MAX_RELIC_SLOTS` (prevent-open guard).
- **Match State Machine** — guard all triggers with `MatchStateServer.get() == "Active"` AND `MatchStateServer.getParticipation(player)`; no fallback behavior outside Active.
- **Round Lifecycle** — register ChestSystem's `createAll(participants)` + `destroyAll()` hooks; createAll scans `ChestTag`-tagged Parts and instantiates state records; destroyAll synchronous, draft-open chests auto-pick first.
- **Level Design** (undesigned — provisional) — chest spawn points are Workspace `Part` instances tagged `ChestTag` with `ChestTierAttribute: int ∈ {1, 2, 3}`. MVP honors tiers 1 and 2; tier 3 silently skipped. Minimum separation from `NPCSpawnPointTag` Parts (no overlap) — flag for Level Design GDD.
- **Network Layer** — three remotes in `RemoteEventName`:
  - `ChestDraftOffer` (server → single client, reliable): `{chestId, tier, candidates: {specId×3}}`
  - `ChestDraftPick` (client → server, reliable): `{chestId, specId}`; server validates specId ∈ offer AND player == claimedBy
  - `ChestStateChanged` (server → all clients, reliable): `{chestId, tier, state, position}` on every state transition — consumer: HUD (future minimap, deferred to VS+) + billboard UI (visibility toggle)
- **HUD** — subscribes `ChestStateChanged` for future minimap rendering (**DEFERRED to VS+** per HUD §C no-minimap-MVP decision — art bible §7 locks no-minimap for MVP). MVP chest discovery relies on billboard visibility + `ProximityPrompt.GUI`; broadcast is still wired for post-MVP consumption.
- **Chest Billboard UI** — displays `effectiveToll` (post-`queryChestToll`), never raw `baseToll`; shows greyed "Relic slots full" state on pre-check fail; non-interactable when `state != "Available"`.
- **Relic Card / Reveal UI** (VS tier) — on `ChestDraftOffer` receipt, renders pick-1-of-3 modal using `RelicRegistry[specId]`; owns 8s timeout countdown + auto-pick-highest-rarity fallback; fires `ChestDraftPick` on confirm.
- **VFX Manager** — two events: `ChestPeelOff {chestId, crowdId, followerCount}` at toll-deduct; `ChestOpenBurst {chestId, tier}` at chest destroy (lid-pop + tier-colored confetti column).
- **Audio Manager** — three events: `ChestPromptDing` on proximity acknowledge; `ChestTollSacrifice {chestId, tier}` on deduction (tier-scaled swell); `ChestOpenSting {chestId, tier, rarity}` on pick confirmed (rarity-tiered reveal sting).

**Rarity roll schema (two-phase):**
1. **Rarity phase**: weighted random draw from `ChestSpec.rarityWeights[tier]`.
2. **Spec phase**: from `RelicRegistry`, filter `spec.params.allowedTiers contains tier` AND `specId ∉ crowd.activeRelics` AND `specId ∉ candidates_already_rolled`. Uniform random pick from filtered set.
3. **Fallback**: if filter is empty at rolled rarity, re-roll rarity up to 3× at same tier. If still empty, step down to next lower rarity and repeat spec phase. If Common also exhausts, slot = "pool exhausted" (MVP edge — see §E).

**Cross-system facts introduced** (candidates for registry in Phase 5):

| Constant | Proposed value | Unit |
|---|---|---|
| `CHEST_RESPAWN_SEC_T1` | 90 | seconds |
| `CHEST_RESPAWN_SEC_T2` | 120 | seconds |
| `CHEST_RESPAWN_SEC_T3` | 150 | seconds (deferred MVP) |
| `CHEST_PROMPT_DISTANCE` | 20 | studs |
| `CHEST_PROMPT_HOLD_SEC` | 0.8 | seconds |
| `DRAFT_TIMEOUT_SEC` | 8 | seconds |
| `T1_CHEST_COUNT` | 6 | locations (Level Design owns final) |
| `T2_CHEST_COUNT` | 3 | locations |
| `T3_CHEST_COUNT` | 2 | locations (deferred) |

## Formulas

Chest System is primarily state + dispatch; most numeric specification lives in per-tier `ChestSpec` params and the Tuning Knobs table. Two formulas define cross-system contracts.

### F1. `base_toll_scaled` (Batch 5 DSN-B-2 resolution — 2026-04-24)

Base toll scales with current crowd count so late-game T1/T2 stay meaningful. Resolves DSN-B-2 (flat T1=10 at count=300 = 3.3% of crowd = mechanically trivial).

`base_toll_scaled(tier, count) = max(T_FLAT[tier], ceil(count × T_PCT[tier]))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `tier` | `t` | enum | {1, 2, 3} | Chest tier |
| `count` | `c` | int | [1, 300] | Current crowd count at trigger time (`CrowdStateServer.get(crowdId).count`) |
| `T_FLAT[t]` | `F_t` | int | {10, 40, 120} | Floor toll per tier — registry T1/T2/T3_TOLL |
| `T_PCT[t]` | `P_t` | float | {0.08, 0.20, 0.0} | Percentage lever per tier — registry T1/T2/T3_TOLL_PCT |
| `base_toll_scaled` | `B_s` | int | [T_FLAT[t], ceil(300 × P_t)] | Pre-relic toll fed into F2 |

**Per-tier behavior:**

| Tier | Floor | PCT | Transition count | Toll @ count=100 | Toll @ count=200 | Toll @ count=300 |
|---|---|---|---|---|---|---|
| T1 | 10 | 0.08 | 125 | 10 (floor) | 16 | 24 |
| T2 | 40 | 0.20 | 200 | 40 (floor) | 40 (floor) | 60 |
| T3 | 120 | 0.00 | — | 120 (flat) | 120 (flat) | 120 (flat) |

T3 stays flat — already 40% of MAX_CROWD_COUNT at peak, scaling not needed. T1 + T2 float above their floor once crowd exceeds the transition count, preserving Pillar 2 (Risky Chests) decision weight late-round.

**Count-read timing:** `count` is read at **trigger receipt** (guard 3c), not at prompt render. Billboard text may briefly lag by 1 tick during rapid drain; acceptable — the trigger guard is authoritative, the billboard is advisory.

### F2. `effective_toll` (consumed from Relic System registry)

Effective toll = `RelicEffectHandler.queryChestToll(crowdId, tier, base_toll_scaled)` — returns the post-modifier toll per Relic §F1 `effective_toll_chain`:

`effective_toll = floor(base_toll_scaled × ∏ₛ relicₛ.onChestOpen(...)) clamped to [TOLL_FLOOR, base_toll_scaled]`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `base_toll_scaled` | `B_s` | int | [F_t, ceil(300 × P_t)] | Output of F1 — replaces raw `baseToll` here |
| `M_s` | `M_s` | float | [0.5, 1.0] | Per-active-relic multiplier from `onChestOpen` hook |
| `TOLL_FLOOR` | — | int | 1 | Hard floor clamp (registry) |
| `effective_toll` | `E` | int | [1, 60] | Deducted via `updateCount(crowdId, -E)` |

**Output range (MVP single TollBreaker):** T1 ∈ [7, 24], T2 ∈ [28, 60], T3 = 120 (TollBreaker excluded from T3 pool).

**Guard predicate (Core Rule 3f):**
`can_open = (crowd.count > effective_toll)` — strict greater-than; failure rejects interaction.

**Examples:**
- T1 chest @ count=150, no relics: `B_s = max(10, ceil(150 × 0.08)) = max(10, 12) = 12`. `E = 12`. Player with count=13 can open.
- T1 chest @ count=300, TollBreaker held: `B_s = max(10, 24) = 24`. `E = floor(24 × 0.70) = 16`.
- T2 chest @ count=40, no relics: `B_s = max(40, ceil(40 × 0.20)) = max(40, 8) = 40` (floor). `E = 40`.
- T2 chest @ count=300, TollBreaker held: `B_s = 60`. `E = floor(60 × 0.70) = 42`.
- T3 chest @ count=121, no relics: `B_s = 120` (flat). `E = 120`. Player with count=121 can open.

### F3. `rarity_roll_per_slot`

Draft candidate rarity selection per slot. Weighted categorical sample, then filter to valid specs.

`rarity_s = weighted_sample(ChestSpec.rarityWeights[tier])`
`spec_s = uniform_pick(filter(RelicRegistry, rarity_s, tier, held, already_drawn))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `rarityWeights[tier]` | `W_t` | table | sum=1.0 | Tier-specific `{Common: p1, Rare: p2, Epic: p3}` |
| `rarity_s` | `r_s` | enum | Common/Rare/Epic | Rolled rarity for slot s ∈ [1, 3] |
| `filter_set` | `F` | {RelicSpec} | [0, pool_size] | Specs matching rarity `r_s` + `tier ∈ allowedTiers` + `specId ∉ held` + `specId ∉ already_drawn` |
| `spec_s` | `S_s` | RelicSpec | — | Picked spec for slot s, or nil on fallback-exhaust |

**Fallback behavior:**
- If `F = ∅` at rolled rarity, re-roll rarity up to `DRAFT_REROLL_ATTEMPTS_PER_SLOT = 3`.
- Still empty → step to next lower rarity (Epic → Rare → Common).
- Common also empty → slot = "pool exhausted" (UI renders <3 cards).

**Output range per draft:** array of length 3 containing specIds or `nil` (pool exhausted slots).

**MVP 3-relic pool caveat:**
With only TollBreaker/Surge/Wingspan in MVP registry:
- T1 filter (allowedTiers contains 1) = {TollBreaker} only → every T1 draft pre-held = TollBreaker × 3; post-held = pool-exhausted
- T2 filter = {TollBreaker, Surge, Wingspan} → full pool available; pseudo-pity as player holds more
- Rarity weights mechanically inert at MVP — full effect emerges at Vertical Slice pool size (5-8 relics)

Document this sharply in §E edge cases: in MVP, weights are a framework future-proofing, not an active tuning surface.

### Non-formulas — explicitly owned elsewhere

| Math | Owner | Why not here |
|---|---|---|
| `radius_from_count`, `collision_transfer_per_tick`, `triple_overlap_drain` | CSM / CCR | Chest System does not read crowd geometry beyond proximity |
| `effective_toll_chain` multiplier composition | Relic §F1 | Chest consumes result; does not compute chain |
| `population_at_rest` | NPC Spawner | Chest density is spatial, not temporal |
| Chest-to-chest spacing geometry | Level Design (undesigned) | Chest System reads tagged Parts, doesn't compute placement |
| Grant-hook dispatch timing | Relic §C | Chest calls `grant()`; handler owns dispatch |

## Edge Cases

### Guard / Interaction

- **If player's count drops between prompt visible and trigger (rival collision in-flight)**: guard 3f re-checks on `Triggered` event; insufficient count = silent reject, no toll, no side-effects.
- **If `queryChestToll` returns value > `baseToll` (bug — relic hook returned >1.0 multiplier)**: handler clamps to `[TOLL_FLOOR, baseToll]` per Relic §E. Chest uses clamped value.
- **If two players trigger same chest same frame at equal distance AND equal UserId**: impossible (UserIds unique). No fallback needed.
- **If player triggers chest, then gets eliminated before `Claimed` resolves**: guard 3c catches in re-check on atomic transaction; if CSM Eliminated signal fired between guard and updateCount, the updateCount on Eliminated crowd is CSM-clamped per CSM §F5 (count stays at floor). Chest aborts claim, returns to `Available`, no toll deducted (defensive).
- **If `ProximityPrompt.Triggered` fires during `DraftOpen` for a different player**: prompt should be disabled upstream; server re-checks `state == "Available"` and silently rejects.

### Draft Roll

- **If all registry relics for tier are held (MVP edge — player holds all 3 relics at 4th chest open)**: pool-exhausted case. Each of 3 candidate slots resolves to nil after rarity fallback. UI renders 0 cards; client fires `ChestDraftPick` with `specId = nil` after 1s grace; server refunds toll via `updateCount(crowdId, +effectiveToll)`, transitions chest to Cooldown, logs "pool exhausted refund". Rationale: player pre-check at guard 3d should prevent this (since slots-full implies held=4 which in MVP equals full pool-held at any tier), but defense-in-depth covers the race. Flag: player cannot reach 4 active relics in MVP without exhausting the pool for that tier.
- **If draft has <3 distinct candidates available (2 held, 1 available)**: 1 valid candidate + 2 pool-exhausted slots. UI renders 1 card; player picks or times out to that card. Same refund path if they timeout without picking — but auto-pick prefers the valid card.
- **If a relic is added to registry mid-round (hot-reload)**: NOT SUPPORTED. Registry is boot-loaded, immutable for server lifetime. Adding a relic requires server restart.
- **If `allowedTiers` is empty array on a RelicSpec**: spec never appears in any draft. Treat as disabled relic.

### State Machine

- **If `destroyAll()` fires while `Claimed` (between guard-pass and draft-roll)**: toll already deducted. Force transition to `Opened` via synthetic auto-pick on empty candidates array (pool-exhaust refund path). CrowdRelicChanged fires with empty delta (no grant). Toll returned. Then chest → Dormant.
- **If a chest Part is deleted from Workspace mid-round**: `ChestComponent` catches destroy signal, state → Dormant, respawn timer cancelled, any in-flight draft auto-picks + grants first. If destroyed during `Opened`, grant already fired — safe. If destroyed during `Available`, no player state affected.
- **If `Cooldown` timer fires after `destroyAll()` (race)**: Janitor destroys the timer connection on destroyAll. Timer fire after destroy finds `self._state == nil` and returns silently.
- **If a Part has `ChestTag` but no `ChestTierAttribute`**: `createAll` logs error, skips Part. Not a valid chest. Flag for Level Design QA.
- **If a Part has `ChestTierAttribute` but no `ChestTag`**: `createAll` doesn't find it. Attribute alone insufficient.

### Toll / Economy

- **If player at `count = 1` (GraceWindow) triggers chest**: guard 3c (`crowdState == "Active"`) REJECTS on GraceWindow — primary reject. Even if 3c were bypassed, guard 3f (`count > effectiveToll`) would also fail at any tier (T1 needs count ≥ 11). Double-protected. Silent reject, no toll, no state change.
- **If player holds TollBreaker + Surge simultaneously at count=40 and opens T2**: Surge was acquired by a prior T2 open; TollBreaker cuts T2 toll to 28. guard 3f checks `40 > 28` ✓. Valid.
- **If `TOLL_FLOOR` clamp prevents further discount stacking at T1=10**: with single TollBreaker, T1 → 7 (above floor). With future stacked discount hypothetical (2× 0.70), T1 would be `floor(10 × 0.49) = 4` (above floor). Extreme stack (10× 0.5) → `floor(10 × 0.00098) = 0` → clamps to 1. Floor is the exploit guard. MVP non-stackable prevents stacking entirely.
- **If TollBreaker is granted mid-raid (player opens T1, gets TollBreaker, immediately approaches T2 while TollBreaker's `onAcquire` already fired `setRelicModifier`)**: by the time player triggers T2, modifier is in `_crowdModifiers`, `queryChestToll` returns 28. No retroactive application needed; state is per-crowd persistent.

### Respawn / Lifecycle

- **If `CHEST_RESPAWN_SEC_T2 = 120` but only 60 seconds remain in round**: respawn timer fires at 60s remaining if started at 120s remaining from round-end. If round ends before respawn completes, `destroyAll()` cancels the pending timer. No chest respawned post-round.
- **If player DCs during `DraftOpen`**: server-side 8s timeout fires auto-pick; grant applies to the (now-nil) crowd; `grant()` silent-rejects on `Eliminated`/DC'd crowd (Relic §E). Toll is forfeit — player paid but lost the relic. Defensible: DC during an open draft is rare; toll refund would add exploit vector (open chest → fake DC to refund).
- **If a rival eliminates the opening player mid-`DraftOpen`**: Server fires `CrowdEliminated(opener.crowdId)` reliable event (state transition, record still exists). Client-side draft modal subscribes to `CrowdEliminated` for opener's crowdId and **closes the modal within one broadcast interval (≤67 ms)** + shows brief "opener eliminated" toast (1s). Server-side 8s timeout still fires the auto-pick path; `grant()` silent-rejects on Eliminated crowd (Relic §E). Chest transitions to `Opened` and schedules respawn normally. Toll already deducted, no refund. Later, on round end or player DC, `CrowdDestroyed` fires for the record-destruction cleanup path (distinct from elimination).
- **If `createAll()` fires without any ChestTag-tagged Parts in Workspace**: silent; no chests active this round. Log warning (likely Level Design bug). Round proceeds without chest layer — Pillar 2 disabled. Flag as critical integration test.

### Cross-System

- **If Relic System's `grant()` silently rejects (Eliminated crowd, slots full, unknown specId)**: Chest still transitions to `Opened` and schedules respawn — toll was deducted, chest is consumed. This is Relic-side bug territory; Chest doesn't retry.
- **If Match State transitions from Active → Result during a `DraftOpen`**: rule 12 `destroyAll()` auto-picks + grants BEFORE transitioning `Opened → Dormant`. Match State's T9 ordering (`destroyAll → clearAll → broadcast`) means chest grant fires, then Relic `clearAll` wipes it. The player never sees the relic — effectively wasted toll. Flag for UX: this is cosmetically ugly but correctness-correct.
- **If Chest Billboard UI is not yet implemented at MVP scope**: chests still function; players use default ProximityPrompt UI. Toll value shows in the default prompt label. Degraded but functional.
- **If Level Design hasn't authored any T2 Parts in Workspace**: ChestSystem respects what's tagged. Rounds ship with T1-only. Pillar 2 still partially functional (just fewer tiers).

### Performance / Budget

- **If 20+ chests active simultaneously**: proximity prompts are Roblox-managed; no bespoke overlap test needed. Server cost is negligible (only fires on player trigger, not per-tick).
- **If 8 players all trigger 8 different chests same frame**: all guards run serially per trigger (no race between different chests). 8× guard pipeline runs in <1ms total.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| Network Layer (template) | Approved | `RemoteEvent` `ChestDraftOffer` (reliable, server → single client); `RemoteEvent` `ChestDraftPick` (reliable, client → server); `RemoteEvent` `ChestStateChanged` (reliable, server → all clients); `CollectionService` tagging | Broadcast + event dispatch |
| PlayerData / ProfileStore (template) | Approved | None — Chest System is ephemeral, no persistence (Pillar 3) | N/A |
| Crowd State Manager | In Review | `CrowdStateServer.get(crowdId).count` for guard 3f; `CrowdStateServer.updateCount(crowdId, -effectiveToll)` post-guard atomic; `CrowdDestroyed` signal subscription for `_crowdModifiers` flush | Read + Write |
| Relic System | Designed (pending review) | `RelicEffectHandler.queryChestToll(crowdId, tier, baseToll) → number` pre-deduction; `RelicEffectHandler.grant(crowdId, specId)` on pick; `RelicRegistry.getSpec(specId)` for draft filter | Read + Write (via function call) |
| Match State Machine | In Revision | `MatchStateServer.get() == "Active"` guard 3a; `MatchStateServer.getParticipation(player)` guard 3b | Read-only |
| Round Lifecycle | In Review | Register `createAll(participants)` + `destroyAll()` hooks; invoked at T4 (Active entry) and T9 (Intermission entry) | Incoming hook calls |
| ADR-0001 Crowd Replication Strategy | Proposed | Same-tick order lock: Collision → Relic → Absorb → **Chest last** (guarantees guard 3f sees post-drain count); `SERVER_TICK_HZ = 15` for respawn timer cadence | Reused constants + ordering lock |
| Level Design (undesigned) | Not Started | Tagged Workspace Parts with `ChestTag` + `ChestTierAttribute: int ∈ {1, 2, 3}`; minimum separation from `NPCSpawnPointTag` Parts; spawn count budget per tier | Read tags/attributes only |
| AssetId Registry (art-bible §8.9 convention) | Approved | `ChestSpec.modelAssetId / glowBeamAssetId / iconAssetId` resolved via string constants | String-constant read |
| Art Bible §4 (safe palette), §8 (chest visual spec) | Approved | Tier colors locked: T1 #FFD700, T2 #72B5F5, T3 #B44FFF; prop dimensions per tier; billboard + beam height rules | Design reference |
| Pillar 2 (Risky Chests) | Approved | Primary pillar — chest toll + draft = decision depth | Locks scope |
| Pillar 5 (Comeback Always Possible) | Approved | Small-crowd T1 raids + lucky Surge = comeback vector | Supports design goals |
| Pillar 3 (5-Minute Clean Rounds) | Approved | Ephemeral only; no persistence; `destroyAll()` contract | Locks lifecycle |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| Chest Billboard UI | Not Started | Displays `effectiveToll` (never `baseToll`); greyed-state on `#activeRelics >= MAX_RELIC_SLOTS`; tier color + icon per ChestSpec; non-interactable when chest `state != "Available"` | Read-only (state broadcast consumer) |
| Relic Card / Reveal UI | Not Started (VS) | Consumes `ChestDraftOffer` payload; renders 3-card modal via `RelicRegistry[specId]`; fires `ChestDraftPick` on player pick; owns 8s timeout + auto-pick-highest-rarity | Read + Write |
| HUD (minimap / chest indicator) | Not Started | Subscribes `ChestStateChanged` reliable for post-MVP minimap rendering (**DEFERRED to VS+** per HUD §C no-minimap-MVP decision — art bible §7). MVP uses billboard + ProximityPrompt visibility for chest discovery. Broadcast wired now to avoid post-MVP re-plumbing. | Read-only (post-MVP consumer) |
| Relic System | Designed | Consumes `queryChestToll`, `grant`, `setRelicModifier`, `clearRelicModifier` API calls from this GDD (bidirectional confirm — Relic §Dependencies lists Chest as upstream) | Write + read (via function calls) |
| VFX Manager | Not Started | `ChestPeelOff {chestId, crowdId, followerCount}` at toll-deduct; `ChestOpenBurst {chestId, tier}` at chest destroy | Event dispatch |
| Audio Manager | Not Started (VS) | `ChestPromptDing`, `ChestTollSacrifice {tier}`, `ChestOpenSting {tier, rarity}` events | Event dispatch |
| Daily Quest System | Not Started (Alpha) | `chest_opened {tier, rarity}` analytics event; `toll_paid` counter | Event source |
| Leaderboard System | Not Started (Alpha) | None directly; rounds result reads from round-scoped player data | N/A |
| Analytics | Not Started (Alpha) | Per-chest-open event payload (tier, toll, rarity granted, round time) | Event source |

### Provisional assumptions (flagged for cross-check)

1. **Level Design GDD** must author chest spawn points — tagged Parts with `ChestTag` + `ChestTierAttribute`, minimum 8.48-stud separation from NPC spawn points per CCR spawn-separation math. Target: 6 T1, 3 T2 Parts for MVP. 2 T3 Parts pre-placed for Alpha activation.
2. **Chest Billboard UI GDD** must implement `effectiveToll` display (reading `ChestSpec.baseToll` + subscribing to per-player `_crowdModifiers` via remote query or broadcast); greyed-out "Relic slots full" state; tier color + icon per art bible §8.8. Flagged: without Billboard UI, default ProximityPrompt label suffices for MVP.
3. **Relic Card / Reveal UI GDD** (VS tier) must handle 8s timeout + auto-pick-highest-rarity fallback client-side; also handles the pool-exhausted refund UI path (§E draft roll edge).
4. **HUD GDD** — chest indicator minimap icons **DEFERRED to VS+** per HUD §C no-minimap-MVP decision (art bible §7). MVP chest discovery via billboard visibility + `ProximityPrompt.GUI`; playtest iteration to confirm sufficient. `ChestStateChanged` broadcast stays wired as post-MVP consumption hook.
5. **VFX Manager GDD** (MVP) must implement `ChestPeelOff` follower-peel animation (N followers detach, march into chest over ~0.5s) and `ChestOpenBurst` tier-colored confetti column. These are Pillar 2 core-beat VFX; degrading to no-op is acceptable for earliest MVP builds.
6. **Analytics** schema for `chest_opened` event requires `{tier, effectiveToll, rarityGranted, specIdGranted, roundTimeSec, crowdCountBefore, crowdCountAfter}` at minimum.

### Bidirectional consistency notes

- **RESOLVES** Relic System §Dependencies provisional "Chest System GDD (when authored) to implement draft UI, pool roll, pre-check slot cap, setRelicModifier/clearRelicModifier API, queryChestToll call before deduction, grant call on pick" — all locked by this GDD.
- **RESOLVES** CSM §Dependencies "Chest System calls `get(crowdId).count` for `count > toll` guard; `updateCount(crowdId, -toll)` on purchase" — contract formalized.
- **RESOLVES** Match State §Dependencies "chests server-guard on `participationFlag AND state == Active`" — confirmed in guards 3a + 3b.
- **REQUIRES** Level Design GDD (when authored) to specify: chest spawn point counts + positions + min-separation-from-NPC-spawn constraint + Part tagging conventions.
- **REQUIRES** Chest Billboard UI GDD for visual polish; graceful degradation to default ProximityPrompt acceptable.
- **Systems Index update** required: mark Chest System as "Designed (pending review)"; add downstream references across Relic, CSM, HUD, Chest Billboard, VFX Manager, Audio Manager, Daily Quest, Analytics.

### No cross-server or persistence dependency

Chest System explicitly REJECTS any DataStore, ProfileStore, or MessagingService usage. Every chest is round-scoped (Pillar 3). Each server runs independent `ChestSystem` singleton. No cross-server chest state, leaderboards, or event aggregation from this module.

## Tuning Knobs

Framework constants stabilize once implementation lands; per-tier specs + spawn counts will iterate in playtest.

### Framework-level knobs

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low | Interacts with |
|---|---|---|---|---|---|---|
| `CHEST_PROMPT_DISTANCE` | 20 studs | [15, 30] | `ProximityPrompt.MaxActivationDistance` per chest | 30+ = player can trigger without intent; crowds passing trigger accidentally | <15 = count=300 Wingspan crowd (radius 16.24) can't reach prompt without character collision | `radius_from_count` max + `WINGSPAN_RADIUS_MULTIPLIER` |
| `CHEST_PROMPT_HOLD_SEC` | 0.8 s | [0.3, 1.5] | `ProximityPrompt.HoldDuration` | 1.5+ = sluggish, punishes small crowds (exposure too long) | 0.3 trivializes exposure cost; tap-to-open accidental triggers | Rival collision drain rate — shorter hold = less vulnerable window |
| `DRAFT_TIMEOUT_SEC` | 8 s | [5, 15] | Client auto-pick timer | 15+ = round stalls; opener holds modal mid-round | <5 rushed; player can't read 3 cards | Round phase — late-round short timeout is harsher |

### Per-tier knobs (ChestSpec)

| Knob | T1 default | T2 default | T3 default (deferred) | Affects |
|---|---|---|---|---|
| `baseToll` (FLOOR) | 10 | 40 | 120 | `max()` FLOOR branch of `base_toll_scaled` (§F1). Registry-locked by CSM as T1/T2/T3_TOLL. |
| `tollPct` | 0.08 | 0.20 | 0.0 | Per-tier percentage-of-count scaling lever (§F1). T3 stays flat (0). Registry T1/T2/T3_TOLL_PCT (Batch 5 DSN-B-2). |
| `respawnSec` | 90 | 120 | 150 | Cooldown from `Opened → Respawning`. |
| `rarityWeights` | `{C: 0.70, R: 0.30, E: 0.00}` | `{C: 0.30, R: 0.55, E: 0.15}` | `{C: 0.00, R: 0.40, E: 0.60}` | Draft rarity distribution. MVP pool-inert; effect emerges at VS pool (5-8 relics). |
| `proximityPromptDistance` | 20 | 20 | 20 | Shared default; tier-override allowed if T3 building needs 25+ for size. |
| `proximityPromptHoldDuration` | 0.8 | 0.8 | 0.8 | Shared default. |

**Respawn rationale:**
- T1 90s → 2 respawns per 300s round (opens ~60s → respawn 150s → respawn 240s). Prevents single-location camping (90s idle is punishing).
- T2 120s → 1 respawn per round (opens ~120s → respawn 240s for late game). 3 locations × 2 opens = 6 T2 opens per round.
- T3 150s → effectively one-shot (opens ~180s → respawn 330s > round end 300s). Intentional: T3 = one opportunity per location.

**Rarity-weight caveat (MVP):**
With 3-relic pool, weights are mechanically inert — draft resolves via pool availability, not probability. Example at T1: only TollBreaker is T1-eligible; every T1 roll picks TollBreaker at any Common roll. Weights become an active tuning surface at Vertical Slice (pool ≥ 5-8 relics).

### Level Design knobs (provisional — Level Design GDD owns final)

| Knob | Default | Safe range | Affects |
|---|---|---|---|
| `T1_CHEST_COUNT` | 6 locations | [4, 10] | T1 density across arena. Target ~50-70 stud nearest-T1 distance. |
| `T2_CHEST_COUNT` | 3 locations | [2, 5] | T2 density. Deliberately half-T1 for contested feel. |
| `T3_CHEST_COUNT` | 2 locations (deferred) | [1, 4] | T3 density. Alpha activation. |
| `CHEST_MIN_SEPARATION_SUDS` | 8.48 | — | Locked — `2 × radius_from_count(CROWD_START_COUNT)`; overlap with NPC spawn points forbidden. Cross-ref CCR §E spawn-collision math. |

### Locked constants (not tuning knobs — changing requires amendment)

- Tier tolls `T1/T2/T3_TOLL = 10/40/120` — owned by CSM registry; Chest System references, not owns. Changes require CSM + economy review.
- `MAX_RELIC_SLOTS = 4` — CSM registry. Changes affect slot-full guard.
- `DRAFT_CANDIDATE_COUNT = 3` — Relic registry.
- `DRAFT_REROLL_ATTEMPTS_PER_SLOT = 3` — Relic registry.
- Same-tick order `Collision → Relic → Absorb → Chest` — CSM §E / CCR lock.
- Round-scoped lifecycle — Pillar 3 lock.
- Server authority over toll deduction + draft roll — anti-cheat baseline.

### Interaction caveats (tuning knob crossovers)

- **Tolls + respawn**: if `T1_TOLL` rises above `CROWD_START_COUNT`, first-T1-at-minute-1 target (concept Q2) fails. Keep `T1_TOLL ≥ CROWD_START_COUNT` OR raise `CROWD_START_COUNT` to match. Current equality (both 10 with `count > toll` strict) means exactly 1 absorb required — intentional.
- **Prompt distance + crowd radius**: any future radius-boost relic beyond Wingspan (μ=1.35) requires re-deriving `CHEST_PROMPT_DISTANCE`. Max radius at μ=1.5, count=300 = 18.04 studs → 20 stud prompt still clears with 2-stud margin; beyond μ=1.5 requires prompt bump.
- **Respawn + spawn count**: effective T1 opens per round = `T1_CHEST_COUNT × floor(round_time / (T1_RESPAWN_SEC + avg_player_reach_time))`. At 6 locations, 90s respawn, ~60s initial, round duration 300s → 6 × floor(300 / 90) = 6 × 3 = 18 opens/round shared across 8-12 players = 1.5-2.25 T1 opens per player. Matches 2-4 opens/round design target.
- **Draft timeout + match state**: during last 8s of round, draft timeout + round-end `destroyAll()` can collide. Rule 12 auto-picks before destroy regardless; no ordering knob needed.

### Provisional defaults owned elsewhere

- Chest billboard height above chest Part — owned by Chest Billboard UI GDD (art-bible §6 baseline: tall enough to read above 300-count crowd).
- Confetti particle count (`ChestOpenBurst`) — owned by VFX Manager (art-bible §9 cap: 40 particles per burst event).
- Rarity-tier SFX stings — owned by Audio Manager / Sound Designer.
- T1/T2/T3 model asset IDs — owned by AssetId Registry (art-bible §8.9).

### Where knobs live (implementation guidance)

- `ChestRegistry` (per-tier `ChestSpec` entries) → `ReplicatedStorage/Source/Chests/ChestRegistry.luau`
- `ChestTier` enum (avoid magic ints) → `ReplicatedStorage/Source/SharedConstants/ChestTier.luau`
- Framework constants (`CHEST_PROMPT_DISTANCE`, `CHEST_PROMPT_HOLD_SEC`, `DRAFT_TIMEOUT_SEC`) → `ReplicatedStorage/Source/SharedConstants/ChestConfig.luau`
- `ChestSystem` module → `ServerStorage/Source/Chests/ChestSystem.luau`
- `ChestComponent` module → `ServerStorage/Source/Chests/ChestComponent.luau`
- `ChestTag` + `ChestTierAttribute` string constants → `ReplicatedStorage/Source/SharedConstants/CollectionServiceTag/ChestTag.luau` + `Attribute.luau`

## Visual/Audio Requirements

Chest System is an event source. Asset rendering + animations owned by VFX Manager + Audio Manager + Chest Billboard UI + Relic Card UI. This section specifies the trigger catalog.

### Event catalog (trigger → receiver contract)

| Event | Fires on | Payload | Receivers | Asset spec owner |
|---|---|---|---|---|
| `ChestPromptDing` | `ProximityPrompt.PromptShown` (Roblox native) | `{chestId, tier}` | Audio Manager | Audio Director — tier-scaled proximity ding |
| `ChestPeelOff` | Post-toll-deduct (Core Rule 6) | `{chestId, crowdId, followerCount: effectiveToll}` | VFX Manager (client-only, opener); Audio Manager (toll sacrifice swell) | Art Bible §8.8 — N follower meshes peel from crowd, march to chest, vanish over ~0.5s; tier-colored confetti accent |
| `ChestTollSacrifice` | Same event as `ChestPeelOff` | `{chestId, tier, followerCount}` | Audio Manager | Audio Director — tier-scaled swell (T1 light, T2 mid, T3 deep) |
| `ChestDraftOpenFX` | Chest `Claimed → DraftOpen` | `{chestId, tier}` | VFX Manager (lid pops, rising light column); Audio Manager (draft-open sting) | Art Bible §8 — tier-colored beam widens briefly |
| `ChestOpenBurst` | Chest destroys after pick (post-grant) | `{chestId, tier, rarity}` | VFX Manager (confetti burst + tier-column dissolve); Audio Manager (rarity-tiered reveal sting) | Art Bible §9 — 40-particle cap; tier color + rarity accent |
| `ChestStateChanged` | Every state transition | `{chestId, tier, state, position}` | Chest Billboard UI (MVP consumer — visibility toggle); HUD minimap (**DEFERRED to VS+** per HUD no-minimap-MVP) | Chest Billboard UI GDD + (future VS+) HUD GDD |
| `ChestSlotsFullFlash` | Proximity + `#activeRelics >= 4` | `{chestId, crowdId}` | Chest Billboard UI (greyed overlay); Audio Manager (negative click) | Chest Billboard UI GDD |

### SFX intent (handoff to Audio Director / Sound Designer)

- **Proximity ding** — short, low-intensity; acknowledges prompt availability
- **Toll sacrifice swell** — tier-scaled; T1 quick chime, T2 mid-body swell, T3 deep-boom rise. Pairs with peel-off animation timing (~0.5s)
- **Draft-open sting** — 0.4s tension cascade on lid-pop; pulls player attention toward cards
- **Rarity reveal sting** — distinct per rarity; Common light chime, Rare brass pulse, Epic low-boom (Pillar 2 emotional payoff — must exceed absorb dopamine per beat)
- **Slots-full denied click** — short negative tick; must NOT sound punishing (player did nothing wrong)

### VFX intent (handoff to Technical Artist / VFX Manager)

- **Peel-off**: N follower meshes detach from crowd center, pathfind to chest Part over ~0.5s via simple lerp (no physics), vanish on contact with tier-colored sparkle. Tier-color tint applied to peel path
- **Lid pop**: chest Part scale-tweens 1.0 → 1.2 → 0 over ~0.8s total (up 0.2s, hold 0.3s, dissolve 0.3s). Tier-colored confetti emits during hold phase
- **Tier-column**: rising light column from chest Part anchor to 15 studs above; tier color; fades with chest dissolve
- **Re-materialization on respawn**: opacity tween 0 → 1 over 1.2s; tier-color pulse during ramp
- No per-frame VFX emissions — all event-triggered

**Visual discipline (art bible §8 compliance):**
- T1 chest 2×2×2 box, gold #FFD700 glow + beam + icon
- T2 car standard car prop, silver-blue #72B5F5
- T3 building (deferred) violet #B44FFF
- Icon shape-coded (chest / car / building) for colorblind legibility per art-bible §4

📌 **Asset Spec** — V/A requirements defined. After art bible is approved, run `/asset-spec system:chest-system` to produce per-asset specs (2 chest models + 1 car model + 2 beam VFX + 5 SFX + peel-off animation).

## UI Requirements

Chest System provides data; UI is owned by Chest Billboard UI + Relic Card / Reveal UI + HUD.

### Chest Billboard (owner: Chest Billboard UI GDD — MVP)

- `BillboardGui` anchored above chest Part at fixed world-space offset (15 studs). Must clear 300-count crowd silhouette height
- Displays `effectiveToll` (post-`queryChestToll`), NEVER raw `baseToll` — else TollBreaker reads invisible
- Tier icon badge (chest / car / building) + tier color frame
- Greyed-out state when `#activeRelics >= MAX_RELIC_SLOTS`: desaturated, "Slots Full" label, prompt disabled
- State-aware visibility: hidden during `Cooldown` + `Respawning`; fades in on state change to `Available`
- Accessibility: toll value ≥18pt at standard chest distance; shape badge independent of color

### Relic Card / Reveal UI (owner: Relic Card UI GDD — Vertical Slice)

- Modal card-draft screen on `ChestDraftOffer` receipt
- 3 cards large-format, rarity-banner + displayName + iconAssetId + shortDesc per card
- Pool-exhausted slots render as `"Pool exhausted"` label card (cannot be picked); on all-three-exhausted, 1s grace + auto-refund (see §E)
- Tap/click to pick; confirm fires `ChestDraftPick`
- 8s timeout countdown overlay; auto-picks highest rarity on fire (first on tie by array index)
- Modal does NOT block absorb / movement input — world continues; crowd keeps flocking around player
- Pairs with `ChestDraftOpenFX` trigger — VFX plays on chest, modal slides up concurrently

### HUD (owner: HUD GDD — **MVP scope: billboard discovery only**; minimap deferred VS+)

- Minimap icons per chest — **DEFERRED to VS+** per HUD §C no-minimap-MVP decision. Broadcast wiring preserved for post-MVP consumption.
- Subscribes `ChestStateChanged` reliable broadcast (wired MVP, consumed VS+)
- Optional `GetActiveChestCount(tier) -> int` RemoteFunction for compact counters (VS+)
- Per-player proximity ring is client-local (ProximityPrompt.PromptShown event driven)
- MVP chest discovery: diegetic beam above chest silhouette + ProximityPrompt (see Chest Billboard UI)

### ProximityPrompt (fallback + default)

- Roblox-native prompt; `ActionText = "Open [Tier] Chest"` (localizable via Relic UI copy table)
- `ObjectText = "Toll: [effectiveToll] followers"` dynamically updated per crowd's modifiers
- Default label is sufficient for earliest MVP builds if Billboard UI deferred

### Data flow summary

```
ChestStateChanged (server broadcast)  -->  Chest Billboard (MVP), HUD minimap (VS+, deferred)
ProximityPrompt.PromptShown (client)  -->  Chest Billboard (highlight active)
ChestDraftOffer (server → single client)  -->  Relic Card UI modal
CrowdEliminated (server → all clients)  -->  Relic Card UI modal closes if opener eliminated (S4-B1 fix, AC-23)
Player pick (client)  -->  ChestDraftPick (remote)  -->  RelicEffectHandler.grant  -->  CrowdRelicChanged (broadcast)  -->  HUD slot-bar re-render
```

All UI elements are read-only consumers except the Relic Card pick-fire. No UI reads server state directly.

**📌 UX Flag — Chest System**: Two distinct UX surfaces for MVP (billboard, draft modal). Minimap icon deferred to VS+ per HUD no-minimap-MVP decision. In Phase 4, run `/ux-design` for: `design/ux/chest-billboard.md` (MVP), `design/ux/relic-card.md` (VS — includes close-on-opener-elim hook per AC-23). `design/ux/hud-minimap.md` deferred until VS+ scope opens.

## Acceptance Criteria

**AC-1 — Spawn: T1/T2 attachment, T3 skip.** GIVEN Workspace contains Parts tagged `ChestTag` with `ChestTierAttribute` values 1, 2, and 3, WHEN `ChestSystem.createAll()` is called at Match State T4 (Active entry), THEN a `ChestComponent` is attached to each tier-1 and tier-2 Part, all tier-3 Parts are silently skipped and remain inert geometry, and each component's state is `Available`. *Evidence: unit.*

**AC-2 — Spawn: missing attribute.** GIVEN a Part has `ChestTag` but no `ChestTierAttribute`, WHEN `createAll()` is called, THEN the Part is skipped, an error is logged, and no `ChestComponent` is created for it. *Evidence: unit.*

**AC-3 — ProximityPrompt distance + hold duration.** GIVEN a `ChestComponent` is in `Available` state, WHEN the component is inspected post-creation, THEN `ProximityPrompt.MaxActivationDistance == 20` studs and `ProximityPrompt.HoldDuration == 0.8` seconds. *Evidence: unit.*

**AC-4 — Guard pipeline reject paths (3a-3f).** GIVEN a chest is `Available` and `ProximityPrompt.Triggered` fires, WHEN each of these conditions is individually set true (all others passing): (a) matchState not Active; (b) `participationFlag == false`; (c-i) `crowdState == "Eliminated"`; (c-ii) `crowdState == "GraceWindow"` (both reject via `crowdState == "Active"` strict guard — 2026-04-24 tightened); (d) `#activeRelics >= 4`; (f) `crowdCount <= effectiveToll`, THEN each path produces silent reject with no toll deducted and no state change, and no subsequent guard is evaluated. *Evidence: unit (6 test functions, one per reject path).*

**AC-5 — Guard pipeline full pass.** GIVEN matchState `Active`, `participationFlag true`, `crowdState == "Active"` (strict), `#activeRelics < 4`, `crowdCount > effectiveToll`, WHEN `ProximityPrompt.Triggered` fires, THEN interaction proceeds, toll deducted, chest transitions to `Claimed`. *Evidence: unit.*

**AC-6 — Open exclusivity: distance + UserId tiebreak.** GIVEN two players trigger same chest same frame, both passing guards, WHEN their 2D squared-distances differ, THEN nearer player claims; farther discarded. WHEN distances equal, THEN lower `UserId` claims. *Evidence: unit (two sub-cases).*

**AC-7 — Toll deduction atomicity.** GIVEN player passes all guards on T2 chest (count=100 → F1 `base_toll_scaled = max(40, ceil(100 × 0.20)) = 40` FLOOR, no relic modifier → `effectiveToll = 40`), WHEN claim executes, THEN `CrowdStateServer.updateCount(crowdId, -40, "Chest")` + chest state → `Claimed` are atomic with no interleaving; count decreases by exactly 40. *Evidence: unit.*

**AC-7b — F1 scaled toll at peak count.** GIVEN player at `count=300` opens T2 chest, no relics, WHEN `base_toll_scaled(2, 300) = max(40, ceil(300 × 0.20)) = 60` is computed pre-Relic chain, THEN `effectiveToll = 60`; `CrowdStateServer.updateCount(crowdId, -60, "Chest")` fires. Guard 3f requires `count > 60`. Batch 5 DSN-B-2 scaled branch coverage. *Evidence: unit.*

**AC-8 — F2 effective toll: TollBreaker discount at floor.** GIVEN crowdId holds TollBreaker (multiplier 0.70) and opens T2 chest at `count ≤ 200` (F1 returns FLOOR 40), WHEN `queryChestToll(crowdId, 2, 40)` is called, THEN returns 28 (`floor(40 × 0.70)`). Crowd at count=29 passes guard 3f; count=28 does not. *Evidence: unit.*

**AC-8b — F2 effective toll: TollBreaker discount at scaled peak.** GIVEN crowdId holds TollBreaker and opens T2 chest at `count=300` (F1 returns scaled 60), WHEN `queryChestToll(crowdId, 2, 60)` is called, THEN returns 42 (`floor(60 × 0.70)`). Crowd at count=43 passes guard 3f; count=42 does not. Batch 5 DSN-B-2 scaled + relic interaction coverage. *Evidence: unit.*

**AC-9 — No partial toll: count-at-floor reject.** GIVEN player with `crowdCount == 10` approaches T1 (baseToll=10, no modifier, `effectiveToll=10`), WHEN guard 3f evaluates `10 > 10`, THEN interaction rejected silently; no toll deducted. *Evidence: unit (boundary value).*

**AC-10 — Peel-off visual: opener-only routing.** GIVEN player successfully opens chest, WHEN toll deduction completes server-side, THEN server fires `ChestPeelOff` to opening client only, payload `{crowdId, chestId, followerCount: effectiveToll}`; no other client receives. *Evidence: integration (two-player remote-targeting mock).*

**AC-11 — Draft roll: distinct + re-roll + fallback.** GIVEN chest roll generates 3 candidates from registry with ≥5 eligible relics for tier, WHEN roll executes, THEN all 3 candidates have distinct `specId` values, none matches held, no specId appears twice. WHEN initial rarity roll produces empty filter, re-rolls up to 3× before stepping to next lower rarity. *Evidence: unit (deterministic seed).*

**AC-12 — Draft UI delivery: single-client routing.** GIVEN chest transitions to `Claimed` and candidates resolve, WHEN `ChestDraftOffer` fires, THEN reliable `RemoteEvent` delivered to claiming client only with `{chestId, tier, candidates: [specId × 3]}`; chest → `DraftOpen`; other players see prompt disabled. *Evidence: integration.*

**AC-13 — Pick, grant, destroy, respawn.** GIVEN chest `DraftOpen` and claiming player fires `ChestDraftPick` with valid `specId` within 8s, WHEN server validates `specId ∈ draftCandidates` + `player.UserId == claimedBy.UserId`, THEN in order: (a) `RelicEffectHandler.grant` fires, (b) state → `Opened`, (c) `ChestComponent:destroy()` removes prompt + billboard, (d) respawn timer scheduled for tier's `respawnSec`, (e) Part re-materializes + returns to `Available` after timer. *Evidence: integration (full sequence with timing).*

**AC-14 — Auto-pick on timeout.** GIVEN chest `DraftOpen` and `DRAFT_TIMEOUT_SEC = 8` elapses without `ChestDraftPick`, WHEN server timeout fires, THEN highest-rarity candidate auto-picked; ties break by lowest array index. Grant fires, chest destroys, respawn schedules. No toll refund. *Evidence: unit (mock timer + rarity sort).*

**AC-15 — destroyAll during DraftOpen: auto-pick first.** GIVEN ≥1 chests in `DraftOpen`, WHEN `ChestSystem.destroyAll()` called, THEN auto-pick fires per rule 10 for each DraftOpen chest (grant called, `CrowdRelicChanged` broadcasts) BEFORE any component destroys; all chests → `Dormant`; `_crowdModifiers` cleared. *Evidence: integration.*

**AC-16 — destroyAll cleanup across states.** GIVEN chests exist in `Available`, `Cooldown`, `Respawning` when `destroyAll()` called, WHEN complete, THEN all → `Dormant`, all respawn timers cancelled, all prompts + billboards removed, no relic side-effects for non-DraftOpen chests. *Evidence: unit.*

**AC-17 — Non-state modifier API.** GIVEN `setRelicModifier(crowdId, "TollBreaker", 0.70, "multiply")` called, WHEN `queryChestToll(crowdId, 2, 40)` called, THEN returns 28. After `clearRelicModifier(crowdId, "TollBreaker")`, same query returns 40. Modifiers live in `_crowdModifiers` per-crowd, not per-chest. *Evidence: unit.*

**AC-18 — CrowdDestroyed flushes _crowdModifiers.** GIVEN crowdId has active modifiers in `_crowdModifiers`, WHEN `CrowdDestroyed` signal fires for that crowdId, THEN `_crowdModifiers[crowdId]` deleted; subsequent `queryChestToll` uses `baseToll` unmodified. *Evidence: unit.*

**AC-19 — Player DC mid-DraftOpen: toll forfeit.** GIVEN chest `DraftOpen` and opening player disconnects (crowd Eliminated), WHEN 8s timeout fires and auto-pick calls `RelicEffectHandler.grant`, THEN grant silent-rejects on DC'd crowd (Relic §E); chest destroys + schedules respawn; no toll refund. *Evidence: manual playtest (requires Roblox DC simulation) — documented in `production/qa/evidence/`.*

**AC-20 — Pool-exhausted refund path.** GIVEN all relics eligible for tier are held by opening player (MVP 3-relic edge), WHEN draft roll produces 3 pool-exhausted slots (all nil), THEN server refunds toll via `updateCount(crowdId, +effectiveToll)`, transitions chest to `Cooldown`, logs "pool exhausted refund". No relic granted. *Evidence: unit (controlled registry mock).*

**AC-21 — Rival triggers same chest during DraftOpen.** GIVEN chest `DraftOpen` (prompt disabled server-side), WHEN different player's `ProximityPrompt.Triggered` fires for that chest, THEN server re-checks `state == "Available"`, finds `DraftOpen`, silently rejects with no toll + no state change. *Evidence: unit.*

**AC-22 — 8-player simultaneous guard pipelines.** GIVEN 8 players trigger 8 different chests same server frame, WHEN all guard pipelines run serially, THEN all 8 resolve correctly with no cross-chest interference; total server execution <1ms. *Evidence: integration (requires `run-in-roblox` headless runner) — ADVISORY until CI runner available.*

**AC-23 — Draft modal close-on-opener-eliminated (S4-B1 fix).** GIVEN a client has an open chest draft modal for opener crowdId B, AND the client is subscribed to `CrowdEliminated` via `CrowdStateClient`, WHEN server fires `CrowdEliminated({crowdId = B.crowdId})`, THEN within one broadcast interval (≤67 ms) the draft modal closes client-side, a brief "opener eliminated" toast displays for 1.0s, and no further `ChestDraftPick` input is accepted on that modal. Server-side auto-pick path (AC-14 / AC-19) still fires after 8s; `grant()` silent-rejects on the now-Eliminated crowd per Relic §E. Toll was already deducted at claim; no refund. *Evidence: integration — two-client Roblox Studio test with elimination trigger mock.*

**AC classification summary:**
- BLOCKING — unit: AC-1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 14, 16, 17, 18, 20, 21
- BLOCKING — integration: AC-10, 12, 13, 15
- ADVISORY — integration: AC-22
- ADVISORY — manual playtest: AC-19 (+ visual fidelity of peel-off, card modal layout during pool-exhausted)

## Open Questions

1. **T1 first-raid timing validation** — concept Q2 asks "starting T1 toll for first raid at minute 1". Current `T1_TOLL = 10 = CROWD_START_COUNT` with strict `>` guard means exactly 1 absorb required. At `R_absorb ≈ 9/s`, player can reach count=11 in ~0.1s. So first T1 is technically available at tick 0. Playtest question: do players DELAY their first T1 raid (choosing to snowball first) or open immediately? If immediate, the "first T1 at minute 1" target is already hit; if delayed, consider lowering T1_TOLL or adding a lockout. Resolve via playtest. Owner: game-designer.
2. **Pool-exhausted UX polish** — the all-nil draft refund path (§E + AC-20) is mechanically correct but cosmetically ugly. Consider a special "Empty Pool" card variant with explicit "+10 followers refunded" animation rather than silent refund. Owner: UX + Relic Card UI GDD. Target: Vertical Slice.
3. **T3 asset + spawn authoring** — deferred to Alpha but framework supports. Decide: do level designers pre-place T3 Parts in MVP maps (silent-skipped by createAll) or add them at Alpha? Pre-placement lets MVP ship with T3 shells visible as map geometry (art bible §8 beam + icon) without mechanics. Owner: level-designer + art-director.
4. **Minimap + HUD scope** — **DEFERRED to VS+** 2026-04-24 Batch 4. HUD §C locks no-minimap for MVP per art bible §7; MVP chest discovery relies on billboard visibility + `ProximityPrompt.GUI`. `ChestStateChanged` broadcast stays wired for post-MVP minimap consumption. If playtest shows players can't find T1 chests at count=200 despite billboard, promote `hud-minimap.md` UX spec + HUD amendment as a VS+ priority item (not MVP blocker). Owner: HUD GDD + playtest. Target: VS+.
5. **Daily Quest event schema** — `chest_opened {tier, rarity}` event shape provisional until Daily Quest GDD authors. Owner: live-ops-designer (Alpha).
