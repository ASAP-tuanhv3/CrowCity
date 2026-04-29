# Follower LOD Manager

> **Status**: In Review (major revision 2026-04-22; 2026-04-24 Batch 3 — this GDD declared **sole owner** of render caps + LOD distances per /review-all-gdds RC-B-NEW-3. CRS + Follower Entity + ADR-0001 diagram updated to match tier 2 cap = 1 billboard per crowd. Internal fix: L388 AC-LOD-07 "Tier 2 → unchanged 4" → "unchanged 1".)
> **Blocked on**: ADR-0001 reaching `Accepted` — tier boundaries + cadence source from ADR-0001; render cap VALUES are now owned by this GDD (F3 cap table). No stories until ADR-0001 is Accepted.
> **Author**: user + technical-artist + gameplay-programmer + systems-designer + qa-lead
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 1 (Snowball Dopamine) via visible mass; 4 (Cosmetic Expression) via rival-hue readability at distance

## Overview

The **Follower LOD Manager** is the client-side coordinator that decides, ten times per second, how many followers each crowd should render and at which geometric fidelity. It is the sibling of **Follower Entity** — the LOD Manager owns the *decisions* (distance math, tier selection, render-cap lookup, own-vs-rival arbitration); Follower Entity owns the *execution* (pool granting, rig swap, CFrame updates). Both systems implement the client half of **ADR-0001 (Crowd Replication Strategy)**, which locks three LOD tiers at 20/40/100m camera distances, render caps 80/30 at close range, 15 at medium, 4 at far, and a 0.1s decision cadence instead of per-frame (Roblox distance-check cost amortises over 100ms without perceptible lag). Every tick, for every crowd in the session, the manager reads camera position, reads the crowd's authoritative `CrowdStateClient.position`, computes the camera-to-crowd distance, looks up the tier and the render cap (own-crowd vs rival-crowd), and dispatches `FollowerEntity.setLOD(crowdId, tier)` and `FollowerEntity.setPoolSize(crowdId, n)` if either value changed. Before any cap shrink, it queries `FollowerEntity.getPeelingCount(crowdId)` to protect mid-peel entities from eviction — the one contract the two sibling systems cannot break. If this system works correctly, no player ever knows it exists.

## Player Fantasy

You never see this system work — that's the point. The city stays smooth when forty rival crowds are colliding downtown. A challenger rounds the corner and their signature hue reads from a block away; as they close, followers fade in over 200ms as silhouettes resolve into shapes — the crowd feels like it's *arriving*, not spawning. Your own mob holds the screen even in peak chaos because the frame never stutters under it.

## Detailed Design

### Core Rules

**Tick loop — 10 Hz via `setInterval`**
- Run via `ReplicatedStorage/Source/Utility/setInterval.luau` (existing template utility — handles drift via `os.clock()`, runs on separate task, returns `clear()` closure for `stop()`).
- NOT `RenderStepped` or `Heartbeat` (would run 60+ Hz with 100ms accumulator overhead for nothing).
- Loop runs one iteration on empty crowd map (crowds may appear next tick).

**Per-tick algorithm (executed every 0.1s)**

1. Read `cameraPos = workspace.CurrentCamera.CFrame.Position`.
2. Fetch all active crowd IDs via `CrowdManagerClient:getAllCrowdIds(): {string}` (NOT `CrowdStateClient` — coordinator owns the live set).
3. For each `crowdId`:
   a. If `_eliminatedIds[crowdId]` is true: skip. (Crowd was eliminated; `CrowdEliminated` event already removed it from `_tracking`.)
   b. `crowdState = CrowdStateClient.get(crowdId)`. If `nil`: remove from tracking; skip.
   c. `d = (crowdState.position - cameraPos).Magnitude`.
   d. `tier = tierForDistance(d, lastTier)` — with hysteresis (see below).
   e. `isOwn = crowdId == tostring(localPlayer.UserId)`.
   f. `cap = capLookup(tier, isOwn)` — with mobile multiplier (see below).
   g. If `tier ~= lastTier` → `FollowerEntity.setLOD(crowdId, tier)`.
   h. If `cap ~= lastCap` → dispatch via `setPoolSize` (shrink-guarded via `getPeelingCount`, see below).
   i. Update `_tracking[crowdId] = {lastTier = tier, lastCap = cap}`.

**Elimination detection via `CrowdEliminated` reliable event**
`CrowdStateClient.get()` returns the last-broadcast state (non-nil) for eliminated crowds throughout the remainder of the round — 15 Hz broadcasts continue post-elimination per Crowd State Manager spec. The tick-level nil-check alone cannot detect elimination. On `start()`, connect to the reliable `CrowdEliminated` RemoteEvent. On receipt: immediately add `crowdId` to `_eliminatedIds` set and remove it from `_tracking`. The per-tick guard (step 3a) ensures eliminated crowds are skipped even if they remain in `CrowdManagerClient:getAllCrowdIds()` for the current tick.

**Hysteresis — ±1 stud dead zone (required)**

Prevents tier-flip thrash at boundaries. At 10 Hz, a crowd oscillating within 1 stud of the 20m boundary would toggle tier 0/1 every 200ms → 65-follower `setPoolSize` swing → constant `Despawning:FadeOut` + `Spawning:FadeIn` flicker.

```
tierForDistance(d, lastTier):
  PROMOTE only when d > boundary + HYSTERESIS     (move to farther tier)
  DEMOTE only when d < boundary - HYSTERESIS      (move to closer tier)
  HYSTERESIS = 1 stud
```

First-tick (`lastTier == nil`): use raw boundaries (`≤20` → 0, etc.) without dead zone. Dead zone only applies to transitions.

**Mobile cap override**

On `start()`: detect mobile via `UserInputService.TouchEnabled AND NOT UserInputService.GamepadEnabled`.

```
MOBILE_CAP_MULTIPLIER = 0.5   -- applied to base caps on mobile
```

Mobile-adjusted caps (tier 0): own = `floor(80 * 0.5) = 40`, rival = `floor(30 * 0.5) = 15`. Tier 1/2 unchanged (already tight — no further cut).

**Cap-shrink protection (step g detail)**

```
if cap < lastCap then
    peelCount = FollowerEntity.getPeelingCount(crowdId)
    n_effective = max(cap, peelCount)
    FollowerEntity.setPoolSize(crowdId, n_effective)
else
    FollowerEntity.setPoolSize(crowdId, cap)
end
```

Gating `getPeelingCount` on shrink-only avoids ~10 redundant reads per rival per second steady-state.

**Follower Entity throughput contract (cascade despawn bound)**
On any `setPoolSize` call that decreases the pool, Follower Entity must not start more than **30 FadeOut tweens per Heartbeat frame** from that call. Excess despawns are queued and drained at ≤30/frame until the pool reaches cap. This bounds the worst-case camera-jump scenario (12 crowds simultaneously culled, up to 410 despawns) to approximately 14 Heartbeat frames (~233ms at 60 Hz) of drain time rather than a single-frame spike. Follower Entity's `setPoolSize` implementation is responsible for enforcing this queue; the LOD Manager fires the call and does not throttle its own dispatch.

**Tracking table housekeeping**
- `_tracking`: `{ [crowdId: string]: { lastTier: number, lastCap: number } }` — simple dict, ≤12 entries.
- `_eliminatedIds`: `{ [crowdId: string]: true }` — set of eliminated crowd IDs, populated by `CrowdEliminated` listener, checked at step 3a each tick, cleared on `stop()`.
- On crowd destroy (absent from `getAllCrowdIds` next tick and not in `_eliminatedIds`): remove entry. Follower Entity handles pool teardown internally — this manager does NOT call `setPoolSize(crowdId, 0)` on destroy (race with Follower Entity's own teardown path).
- On `localPlayer.UserId` becoming available (first tick post-session): resolves naturally each tick via `tostring(...)`. No special re-evaluation pass.

**Write-access contract**
- External callers: `FollowerLodManager.start()` / `.stop()` only.
- Internal: module-owned tick loop calls Follower Entity mutators. No other caller drives LOD.
- `start()` + `stop()` are idempotent (no-op on double-start/stop, warn-log).
- `start()` also connects `CrowdEliminated` reliable RemoteEvent listener (single connection, stored for cleanup).
- `stop()` disconnects the `CrowdEliminated` listener and clears `_eliminatedIds`.

### States and Transitions

2 module-level states.

| State | Tick loop | Tracking table | Invoked by |
|---|---|---|---|
| `Dormant` | stopped | empty | initial state + after `stop()` |
| `Ticking` | 10 Hz active | populated per tick | after `start()` |

| # | From | To | Trigger | Action |
|---|---|---|---|---|
| L1 | `Dormant` | `Ticking` | `start()` called (by client gameplay init, post-`CrowdStateClient` registration) | `setInterval(onTick, 0.1)`; retain `clear()` closure; connect `CrowdEliminated` listener |
| L2 | `Ticking` | `Dormant` | `stop()` called (by round teardown / match-state `Intermission` entry) | `clear()` closure invoked; disconnect `CrowdEliminated` listener; `_tracking` + `_eliminatedIds` cleared |

No internal error state. Empty-crowd-map tick is a no-op; loop continues.

### Interactions with Other Systems

| System | Direction | Call / Read |
|---|---|---|
| Follower Entity | OUT | `setLOD(crowdId, tier)` on tier change |
| Follower Entity | OUT | `setPoolSize(crowdId, n_effective)` on cap change (shrink-guarded via `getPeelingCount`) — see throughput bound below |
| Follower Entity | IN | `getPeelingCount(crowdId): number` before any cap-shrink |
| `CrowdManagerClient` (coordinator) | IN | `:getAllCrowdIds(): {string}` — live crowd set |
| `CrowdStateClient` | IN | `.get(crowdId).position` per-crowd centroid |
| `CrowdEliminated` RemoteEvent | IN | Reliable event received when a crowd is eliminated. Triggers immediate removal from `_tracking` and add to `_eliminatedIds`. Required because `CrowdStateClient.get()` remains non-nil for eliminated crowds until `destroyAll()` at round end. |
| `workspace.CurrentCamera` | IN | `.CFrame.Position` per tick (camera, NOT character — zoomed-out cases favor camera) |
| `Players.LocalPlayer` | IN | `.UserId` for own-crowd identification |
| `UserInputService` | IN | `.TouchEnabled`, `.GamepadEnabled` at `start()` for mobile detection |

### Design tensions flagged

1. **Single tier per crowd vs per-follower LOD** — manager assigns one tier to the whole crowd based on centroid distance. At large crowds (count=300, radius ~12 studs) near tier boundaries, followers on the far side of the crowd cross the boundary before centroid does. **Accepted** — per-follower LOD would require iterating 300 entries per crowd per tick, defeating the 0.1s amortization the cadence was designed to provide.

2. **`setLOD` + `setPoolSize` ordering** — when both change same tick (normal case, cap is a function of tier), dispatch order is `setLOD` first then `setPoolSize`. Follower Entity must treat these as independent triggers (rig swap + pool resize); wrong-order same-tick application must not corrupt state. **Contract requirement** on Follower Entity implementation — flagged for implementation review.

## Formulas

### F1. distance_camera_to_crowd

```
d = (crowd.position - cameraPos).Magnitude
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `crowd.position` | Vector3 | world | `CrowdStateClient.get(crowdId).position` |
| `cameraPos` | Vector3 | world | `workspace.CurrentCamera.CFrame.Position` |
| `d` | float | [0, ∞) studs | Camera-to-centroid distance |

**Output range:** `d >= 0`. Coincident centroid → `d = 0` (→ tier 0 via F2). No negative.

### F2. tier_with_hysteresis

**Constant declaration (required in `SharedConstants/FollowerLodConfig.luau`):**
```
CULL = 3   -- integer sentinel for the beyond-tier-2 state; must be declared before any formula referencing it
```

First-tick (`lastTier == nil`): raw bucket assignment with strict inequalities:

```
if d <= 20  then tier = 0
elseif d <= 40  then tier = 1
elseif d <= 100 then tier = 2
else                tier = CULL    -- CULL = 3
end
```

Subsequent ticks: explicit per-tier branches (replaces boundary-array indexing — avoids Luau nil-index crashes at tier extremes):

```
-- tierForDistance(d, lastTier)

if lastTier == 0 then
    if d > 20 + HYSTERESIS then return 1 end
    -- Cannot demote below tier 0

elseif lastTier == 1 then
    if d > 40 + HYSTERESIS then return 2
    elseif d < 20 - HYSTERESIS then return 0
    end

elseif lastTier == 2 then
    if d > 100 + HYSTERESIS then return CULL
    elseif d < 40 - HYSTERESIS then return 1
    end

elseif lastTier == CULL then
    if d <= 100 - HYSTERESIS then return 2 end   -- re-entry: drop to tier 2; subsequent ticks refine via tier-2 branch
    -- Cannot promote above CULL
end

return lastTier   -- no change: inside dead zone
```

**Why explicit branches**: `boundaries = {20, 40, 100}` is 1-indexed in Luau. `boundaries[0]` = nil (DEMOTE from tier 0 crashes). `boundaries[3]` = nil (PROMOTE from tier 2 crashes). The boundary-array pattern is structurally unsafe at tier extremes; explicit branches eliminate all nil-arithmetic paths.

**CULL re-entry**: When `lastTier == CULL` and `d <= 100 - HYSTERESIS`, drop directly to tier 2 (not tier 1 or 0 — the crowd centroid just crossed back under 99m; tier refinement happens on the next tick via the tier-2 branch). No intermediate state needed.

| Variable | Type | Range | Description |
|---|---|---|---|
| `d` | float | [0, ∞) | From F1 |
| `lastTier` | int or nil | {0, 1, 2, CULL=3, nil} | Tier from prior tick |
| `CULL` | int | 3 | Sentinel constant declared in `FollowerLodConfig.luau` |
| `HYSTERESIS` | float | [0.5, 3] studs | Default **1** — dead-zone width |

**Output range:** {0, 1, 2, CULL}. All transitions are guarded; no nil arithmetic reachable.

### F3. cap_with_mobile_multiplier

```
-- CULL = 3 (from FollowerLodConfig.luau — same constant as F2)
BASE_CAPS = {
    [0]    = { own = 80, rival = 30 },
    [1]    = { own = 15, rival = 15 },
    [2]    = { own =  1, rival =  1 },    -- 1 billboard impostor per crowd (see below)
    [3]    = { own =  0, rival =  0 },    -- CULL = 3; key is the integer value
}

baseCap = BASE_CAPS[tier][isOwn and "own" or "rival"]

if isMobile AND tier == 0 then
    cap = floor(baseCap * MOBILE_CAP_MULTIPLIER)
else
    cap = baseCap
end
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `tier` | int | {0, 1, 2, 3} | From F2 (3 = CULL) |
| `isOwn` | bool | — | `crowdId == tostring(localPlayer.UserId)` |
| `isMobile` | bool | — | `UserInputService.TouchEnabled AND NOT UserInputService.GamepadEnabled` detected at `start()` |
| `MOBILE_CAP_MULTIPLIER` | float | [0.3, 0.7] | Default **0.5** — mobile tier-0 cap reduction |

**Explicit rule — tier 2 = billboard impostor**: `cap = 1` at tier 2 means one billboard impostor per crowd, not one follower rig. `setLOD(crowdId, 2)` signals Follower Entity to enter billboard mode: render a single colour-matched billboard quad (one Part) per crowd rather than individual rig slots. `setPoolSize(crowdId, 1)` allocates the one billboard slot. This resolves the ADR-0001 discrepancy — ADR's "billboard impostor" label is the authoritative spec; this GDD previously listed "4 real follower rigs" which was incorrect.

**Explicit rule — `MOBILE_CAP_MULTIPLIER` applies ONLY to tier 0**: Tier 1 caps (15) and tier 2 (1 billboard) are platform-invariant. Further mobile reduction at tier 1 would defeat rival-silhouette readability (Pillar 4). Tier 2 billboard is already 1 Part; no reduction possible.

**Explicit rule — mobile safe range lower bound**: At `MOBILE_CAP_MULTIPLIER = 0.3` (minimum), `floor(30 × 0.3) = 9` rival followers at tier 0. The stated lower bound of 0.3 risks rival-hue readability at close range (Pillar 4) as well as own-crowd dominance (Pillar 1). Operators should not tune below 0.4 without playtest evidence that rival hue reads at 9 followers.

**Explicit rule**: phone with Bluetooth gamepad connected → `TouchEnabled AND GamepadEnabled` both true → treated as PC-class (`isMobile = false`). Controller-connected phone typically has better thermal headroom. Note: touchscreen laptops (Surface Pro, Lenovo Yoga) with no gamepad connected yield `isMobile = true` permanently; own-crowd cap is halved all session. This is a known mis-detection; cosmetic Pillar 1 impact accepted for the session.

**Output range per tier (mobile)**: tier 0 own = 40, rival = 15. Tier 1 unchanged. Tier 2 = 1 billboard (platform-invariant).

### F4. n_effective_shrink_guard

```
if cap < lastCap then
    n_effective = max(cap, FollowerEntity.getPeelingCount(crowdId))
else
    n_effective = cap
end
```

| Variable | Type | Range | Description |
|---|---|---|---|
| `cap` | int | [0, 80] | From F3 (this tick) |
| `lastCap` | int | [0, 80] | From tracking table (prior tick) |
| `getPeelingCount(crowdId)` | int | [0, render_cap] | Queried from Follower Entity only on shrink |

**Output range:** `n_effective >= max(cap, peelCount)` — guarantees no mid-peel eviction.

**CULL-tier edge**: when `tier == CULL` AND `peelCount > 0`: `cap = 0`, `n_effective = peelCount`. Crowd retains pool slots for peeling entities only. Non-peel rendered count = 0. Peel completion naturally drops `getPeelingCount` → next tick's shrink reduces `n_effective` to 0 normally.

## Edge Cases

### Startup / detection
- **If `workspace.CurrentCamera == nil` on first tick** (pre-login transient): early-return the tick. Loop continues; camera is always initialized within 100ms. No log.
- **If mobile detection changes mid-session** (gamepad connect/disconnect mid-round): `isMobile` evaluated once at `start()`, cached. No re-evaluation. A mid-round controller connect leaves `isMobile = true` until next `stop()`/`start()` cycle (round restart). Cap difference at tier 0 (40 vs 80 own) is cosmetic, not a correctness issue.
- **If `localPlayer.UserId == 0`** (Studio solo test): `tostring(0) == "0"`. A crowd keyed `"0"` would mis-identify as own-crowd. Acceptable in Studio; not reachable in production (all `UserId` are positive integers).

### Tier / boundary
- **Tier-flip thrash** at 20/40/100m boundaries: `HYSTERESIS = 1 stud` dead zone prevents raw boundary crossings after first tick.
- **First-tick no dead zone**: raw bucket assignment via strict inequalities (`<=20` tier 0, etc.). Hysteresis applies from tick 2.
- **If `d == 20` exactly on first-tick** (`lastTier == nil`): `<=20` → tier 0. Next tick hysteresis requires `d > 21` for promote. No boundary ambiguity.

### Crowd lifecycle
- **If crowd eliminated mid-tick** (between `getAllCrowdIds` + `CrowdStateClient.get`): `get` returns `nil` → remove from tracking, skip. Follower Entity handles its own pool teardown. No `setPoolSize(0)` call from this manager.
- **If `CrowdStateClient.get` returns stale position during broadcast gap** (15 Hz vs 10 Hz tick, up to 167ms stale): accepted. A crowd at 40 studs/s can be up to 199ms past a tier boundary before the LOD Manager's next tick assigns the new tier. Note: this is a **snapshot lag**, not a hysteresis failure — hysteresis guards oscillation at boundaries, not tick-interval delay. Consequence: up to one-to-two ticks (100-200ms) of wrong-tier rendering on fast boundary crossing. This is imperceptible to the player and accepted.
- **If `getAllCrowdIds` returns different set between ticks** (player join/leave during round transition): new IDs assigned raw tier on first tick they appear; departed IDs have `get` return `nil` → removed normally. No special round-transition logic needed.
- **If a `crowdId` appears in `getAllCrowdIds` more than once** (coordinator bug / Studio collision): second occurrence overwrites tracking within same tick. One redundant `setLOD` + `setPoolSize` pair per duplicate. Log warn if defensive mode desired; not a supported production scenario.

### Mobile / multiplier
- **Mobile multiplier ONLY on tier 0** (not tier 1/2): explicit. Tier 1/2 caps (15 / 4) unchanged across platforms.
- **Gamepad-connected phone**: `TouchEnabled AND GamepadEnabled` both true → `isMobile = false`; treated as PC. Acceptable — controller-paired phones usually have better thermal headroom.

### CULL + peel interaction
- **If `tier == CULL` AND `getPeelingCount > 0`**: `cap = 0`, `n_effective = peelCount` via F4. Crowd retains pool slots for peeling entities only. Non-peel rendered count = 0. Peel completion drops `getPeelingCount` → next tick reduces `n_effective` to 0 normally.

### Idempotence / race
- **Double `start()` or `stop()`**: idempotent — no-op on same-state call, warn-log.
- **If `setInterval` callback fires during `stop()` execution**: `clear()` prevents further invocations; in-flight tick completes normally. **Ordering mandate**: `stop()` must call `clear()` FIRST, then clear `_tracking` — in-flight tick may still write to `_tracking` before `clear()` takes effect.

### Error handling
- **If `FollowerEntity.setLOD` / `setPoolSize` errors** (pool exhausted, invalid tier, internal fault): LOD Manager does NOT retry and does NOT halt. Error logged by Follower Entity. Tracking table NOT updated on failed call — next tick re-attempts naturally if divergence persists. Creates free 100ms retry without explicit retry logic. **Follower Entity contract**: must not throw on invalid tier; must warn + clamp.
- **If `getPeelingCount` errors** (Follower Entity internal): LOD Manager treats as `0`; `n_effective = cap`. Risk: one tick of over-shrink. Accepted — recovers next tick.

## Dependencies

### Upstream (this GDD consumes)

| System | Status | Interface used | Data flow |
|---|---|---|---|
| Follower Entity | Designed (pending review) | `setLOD(crowdId, tier)`, `setPoolSize(crowdId, n)`, `getPeelingCount(crowdId): number`; tier-2 requires billboard mode implementation; `setPoolSize` must enforce ≤30 FadeOut/Heartbeat throughput bound | Call + read |
| Crowd State Manager | In Revision | `CrowdStateClient.get(crowdId).position` per-tick; `CrowdEliminated` reliable RemoteEvent (event fires when a crowd is eliminated — `get()` remains non-nil post-elimination until `destroyAll()`) | Read-only + event |
| `CrowdManagerClient` (sibling coordinator) | Not Started | `:getAllCrowdIds(): {string}` — live crowd set (contract defined here; must be honoured when CrowdManagerClient GDD is authored) | Read-only |
| ADR-0001 Crowd Replication | **Proposed (⚠ blocking)** | LOD distance boundaries (20/40/100m), render caps (80/30/15/4), 0.1s cadence, billboard impostor for tier 2. **This GDD is blocked on ADR-0001 reaching Accepted.** | Architecture foundation |
| Art Bible §5 | Approved | 3-tier LOD distances confirmed; "every 0.1s not every frame" cadence | Visual specs |
| `workspace.CurrentCamera` | Roblox API | `.CFrame.Position` per tick | Read-only |
| `Players.LocalPlayer` | Roblox API | `.UserId` for own-crowd detection | Read-only |
| `UserInputService` | Roblox API | `.TouchEnabled`, `.GamepadEnabled` at `start()` for mobile detection | Read-only |
| `ReplicatedStorage/Source/Utility/setInterval.luau` | Template utility | `setInterval(fn, 0.1) → clear()` — 10 Hz tick scheduler | Function ref |

### Downstream (systems this GDD provides for)

| System | Status | Interface provided | Data flow |
|---|---|---|---|
| `CrowdManagerClient` / gameplay init | Not Started | `FollowerLodManager.start()` called post-session-init; `.stop()` called on round teardown | Function-call API |
| Follower Entity | Designed (pending review) | Drives `setLOD` + `setPoolSize` dispatches; this manager is the ONLY caller of these methods | Coordination |

### Provisional assumptions (flagged for cross-check)
- `CrowdManagerClient:getAllCrowdIds(): {string}` signature — assumed. CrowdManagerClient is a sibling implementation singleton not yet authored; contract defined here.
- Follower Entity's `setLOD` + `setPoolSize` signatures — assumed from Follower Entity §F, matched.
- `setInterval` utility at `ReplicatedStorage/Source/Utility/setInterval.luau` exists per template — verify at implementation time.

### Bidirectional consistency notes
- **REQUIRES** Follower Entity to honor `setLOD` / `setPoolSize` / `getPeelingCount` contracts as declared in Follower Entity §F. All 3 already locked.
- **CREATES** new requirement: `CrowdManagerClient` coordinator must expose `:getAllCrowdIds()`. Contract defined in this GDD; sibling `CrowdManagerClient` GDD not yet authored.
- **RESOLVES** Follower Entity §F flag: "Follower LOD Manager MUST honor `getPeelingCount` contract before any `setPoolSize` call." Explicitly codified in F4 + C.1 shrink-guarded dispatch.

### Engine constraints
- No custom 3D-culling API in Roblox — distance math is all-Luau
- `workspace.CurrentCamera` can be nil during session startup — handled via early-return edge
- `UserInputService` flags are evaluated once per session; dynamic re-eval deemed unnecessary (cap difference is cosmetic)

### No cross-server dependency
Client-local only. No server RPCs, no DataStore, no `MessagingService`.

## Tuning Knobs

### Owned by this GDD

| Knob | Default | Safe range | Affects | Breaks if too high | Breaks if too low |
|---|---|---|---|---|---|
| `LOD_TICK_HZ` | **10** | [5, 30] | Decision loop frequency (0.1s interval) | >30 Hz = needless CPU; approaches per-frame overhead | <5 Hz = tier response lag noticeable on approach/retreat |
| `HYSTERESIS` | **1** stud | [0.5, 3] | Tier-boundary dead zone | >3 = noticeable tier-upgrade lag on crowd approach | <0.5 = flicker under camera walk-sway |
| `MOBILE_CAP_MULTIPLIER` | **0.5** | [0.3, 0.7] | Tier-0 cap reduction for touch-only clients | >0.7 = no meaningful perf savings | <0.3 = crowd reads as "small" not "dominant" (Pillar 1 erosion) |

### Render caps + LOD distances (SOLE OWNER — 2026-04-24 Batch 3 declaration)

Per /review-all-gdds 2026-04-24 RC-B-NEW-3 resolution: **This GDD is the sole owner of render cap VALUES and LOD distance thresholds.** CRS (`crowd-replication-strategy.md`) references these constants but does NOT define them — CRS defines the broadcast transport contract only. Follower Entity + ADR-0001 architecture diagram consume these values as downstream.

| Constant | Value | Provenance |
|---|---|---|
| Tier 0 boundary (`LOD_TIER_NEAR`) | 20 studs | art bible §5 shape/distance; adopted here |
| Tier 1 boundary (`LOD_TIER_MID`) | 40 studs | art bible §5; adopted here |
| Tier 2 boundary (`LOD_TIER_FAR`) | 100 studs | art bible §5; adopted here |
| Tier 0 own cap (`OWN_CLOSE_MAX`) | 80 Parts per crowd | ADR-0001 prototype-validated; **owned here** (tunable via §F3 cap table) |
| Tier 0 rival cap (`RIVAL_CLOSE_MAX`) | 30 Parts per crowd | ADR-0001 prototype-validated; **owned here** |
| Tier 1 cap (own/rival) (`MID_RANGE_MAX`) | 15 Parts per crowd | ADR-0001 prototype-validated; **owned here** |
| Tier 2 cap (own/rival) (`FAR_RANGE_MAX`) | **1 billboard impostor per crowd** | ADR-0001 billboard spec (1 per crowd, NOT 4 rigs — prior "4" value superseded 2026-04-22); **owned here** |
| CULL cap | 0 | ADR-0001; **owned here** |

**Tunability:** Any change to these values requires a `/propagate-design-change` pass on this GDD to re-verify CRS + Follower Entity + ADR-0001 diagram alignment. Tier 2 billboard count is locked at 1 per crowd; changing to >1 would require billboard→rig transition logic redesign.

### Non-tunable runtime flags

| Flag | Eval | Notes |
|---|---|---|
| `isMobile` | `TouchEnabled AND NOT GamepadEnabled` at `start()` | Cached; no mid-session re-eval |

### Where knobs live (implementation guidance)
- All three knobs → `SharedConstants/FollowerLodConfig.luau` (new file)
- Constants (ADR-locked) referenced directly from `SharedConstants/FollowerLodConstants.luau` or co-located with Follower Entity's `FollowerVisualConfig.luau`

**Design note**: LOD Manager's tuning surface is deliberately thin. The real feel knobs live in Follower Entity (peel speed, spawn fade, boids weights) and Crowd State Manager (count ceiling, transfer rate). This system is cadence + threshold + platform tier — everything else is inherited.

## Acceptance Criteria

All ACs are **Logic** tier (BLOCKING) — TestEZ unit tests with mocked `FollowerEntity`, `CrowdStateClient`, `CrowdManagerClient`, `workspace.CurrentCamera`, `UserInputService`.

**AC-LOD-01 (Tick cadence + idempotence)** — GIVEN Dormant, WHEN `start()` called then `start()` called again, THEN 2nd call = no-op (warn-log, no 2nd tick loop); interval fires at 10 Hz (mock clock advances 0.1s per step); `stop()` once returns to Dormant, no further ticks.

**AC-LOD-02 (stop ordering — deferred tick safety)** — GIVEN tick loop active AND a tick callback has been `task.defer`'d but not yet fired, WHEN `stop()` is called synchronously (no yield points in `stop()`), THEN `clear()` is invoked and `_tracking` + `_eliminatedIds` are wiped before `stop()` returns; when the deferred tick fires afterward, it completes without nil-table error (deferred tick finds empty or absent `_tracking` and exits early without writing); `_tracking` is empty after the deferred tick completes. Note: `stop()` must contain no yield points — in single-threaded Luau without Actors, true concurrent interleave between two coroutines is impossible without a `task.wait()` yield; the ordering mandate is enforced by keeping `stop()` synchronous.

**AC-LOD-03 (Camera nil)** — GIVEN `workspace.CurrentCamera == nil`, WHEN first tick fires, THEN tick exits early, no `getAllCrowdIds` call, no `setLOD`/`setPoolSize` call, no error.

**AC-LOD-04 (F1 + raw first-tick tier)** — GIVEN crowd at `(25,0,0)`, camera at `(0,0,0)`, `lastTier == nil`, WHEN tick fires, THEN `d=25` → tier 1 (raw `20 < 25 <= 40`); `setLOD(crowdId, 1)` called.

**AC-LOD-05 (F2 hysteresis)** — GIVEN tracked `lastTier = 0` (HYSTERESIS=1): WHEN `d=20.5` (inside dead zone 20<d≤21), THEN `setLOD` NOT called; WHEN `d=21.5` (past promote threshold 20+1=21), THEN `setLOD(crowdId, 1)` called. GIVEN `lastTier=1`, demote boundary = `boundaries[tier-1] - HYSTERESIS = 20 - 1 = 19`: WHEN `d=19.5` (19.5 > 19, INSIDE dead zone 19≤d<20), THEN `setLOD` NOT called; WHEN `d=18.9` (below demote threshold 19), THEN `setLOD(crowdId, 0)` called. AND GIVEN `lastTier=2`: WHEN `d=100.5`, THEN `setLOD` NOT called (inside dead zone); WHEN `d=101.5`, THEN `setLOD(crowdId, CULL)` called.

**AC-LOD-06 (F3 base caps)** — GIVEN PC client, `localPlayer.UserId = 42` (number; system calls `tostring(42)` = `"42"` for comparison), two crowds own=`"42"` tier 0 + rival=`"99"` tier 0, WHEN first tick, THEN `setPoolSize("42", 80)` + `setPoolSize("99", 30)`. Tier 1 → 15. Tier 2 → `setPoolSize(1)` + `setLOD(crowdId, 2)` (billboard mode). CULL → 0 via F4.

**AC-LOD-07 (F3 mobile multiplier tier-0 only)** — GIVEN `TouchEnabled=true, GamepadEnabled=false` at `start()`, WHEN crowd at tier 0 own, THEN `setPoolSize` called with `floor(80*0.5)=40`. Rival tier 0 → `floor(30*0.5)=15`. Tier 1 → unchanged 15. Tier 2 → unchanged 1 (billboard per crowd; platform-invariant per §F3 cap table and §L233 billboard mode spec).

**AC-LOD-08 (F3 gamepad phone = PC)** — GIVEN `TouchEnabled=true AND GamepadEnabled=true`, WHEN crowd at tier 0 own, THEN `isMobile=false`; `setPoolSize` called with 80 (PC cap, not 40).

**AC-LOD-09 (F4 shrink-gated getPeelingCount)** — GIVEN `lastCap=40, cap=80` (`cap > lastCap` — genuine increase), WHEN tick fires, THEN `getPeelingCount` NOT called; `setPoolSize(crowdId, 80)` called directly. AND GIVEN `lastCap=80, cap=40, getPeelingCount()=50` (`cap < lastCap` — shrink), WHEN tick fires, THEN `getPeelingCount` called once; `setPoolSize(crowdId, 50)` via `max(40, 50)`. AND GIVEN `lastCap=80, cap=80` (unchanged), WHEN tick fires, THEN `getPeelingCount` NOT called and `setPoolSize` NOT called (no-change path per AC-LOD-13).

**AC-LOD-10 (F4 CULL + peels)** — GIVEN crowd at tier CULL (`cap=0`), `getPeelingCount=3`, WHEN shrink tick fires, THEN `setPoolSize(3)` via `max(0, 3)`. AND GIVEN `getPeelingCount=0` next tick, THEN `setPoolSize(0)`.

**AC-LOD-11 (Crowd destroyed mid-tick)** — GIVEN `"99"` in `getAllCrowdIds()` but `CrowdStateClient.get("99") == nil`, WHEN tick fires, THEN `_tracking["99"]` removed; `setLOD`/`setPoolSize` NOT called for `"99"`; no error.

**AC-LOD-12 (Error handling — basic non-propagation)** — GIVEN `FollowerEntity.setLOD` throws for crowd `"42"`, WHEN tick dispatches, THEN error does NOT propagate to the tick loop itself (no unhandled error, loop runs to completion); `_tracking["42"]` NOT updated; next tick re-attempts dispatch naturally (divergence persists → retry). See AC-LOD-19 for the full multi-crowd continuation proof (proves iteration continues to next crowd in the same tick).

**AC-LOD-13 (No-change no-dispatch)** — GIVEN crowd w/ `lastTier=1, lastCap=15` and unchanged tier + cap this tick, WHEN tick fires, THEN neither `setLOD` nor `setPoolSize` called for that crowd.

**AC-LOD-14 (Tracking bounded)** — GIVEN `getAllCrowdIds` returns 12 IDs first-tick, WHEN tick fires, THEN `_tracking` contains exactly 12 entries. AND crowd disappearing (`get` returns `nil`) reduces count to 11 next tick.

**AC-LOD-15 (Per-tick steady-state no-dispatch)** [Logic — BLOCKING] — GIVEN 12 crowds stable (no tier/cap changes, camera stationary), WHEN 100 ticks execute against synchronous mocks, THEN `setLOD` and `setPoolSize` are called 0 times total (no-change no-dispatch path exercised for all 12 crowds across all 100 ticks).

**AC-LOD-15b (Per-tick decision cost)** [Performance/Integration — NOT a CI gate] — GIVEN 12 crowds stable, camera stationary, synchronous mocks for all downstream calls, WHEN 100 ticks execute, THEN per-tick wall-clock `os.clock()` delta < 0.1ms avg. Measured on M1/M2 Mac or equivalent; not enforced in CI due to hardware variance. Run manually as a performance benchmark, not a TestEZ test.

**AC-LOD-16 (CrowdEliminated elimination detection)** — GIVEN tick loop active, crowd `"42"` in tracking, WHEN `CrowdEliminated` event fires with `crowdId = "42"`, THEN `_tracking["42"]` is removed immediately (before next tick); `_eliminatedIds["42"]` is true; on next tick `"42"` appears in `getAllCrowdIds()` result but is skipped at step 3a; `setLOD`/`setPoolSize` NOT called for `"42"`. AND GIVEN `stop()` called, THEN `_eliminatedIds` is cleared.

**AC-LOD-17 (F2 CULL→tier-2 re-entry)** — GIVEN `lastTier=CULL (3)`, HYSTERESIS=1: WHEN `d=98.9` (below 100-1=99), THEN `setLOD(crowdId, 2)` called (re-entry to tier 2); `setPoolSize(crowdId, 1)` called (billboard cap). WHEN `d=99.5` (inside CULL dead zone, above 99), THEN `setLOD` NOT called (stays at CULL). AND GIVEN after re-entry `lastTier=2`, WHEN `d=95`, THEN tier stays at 2 (normal tier-2 branch, no double-transition).

**AC-LOD-18 (setLOD dispatched before setPoolSize, same tick)** — GIVEN crowd with `lastTier=0, lastCap=80`, WHEN tick fires with `d=25` (tier 1, cap=15), THEN in the same tick: `setLOD(crowdId, 1)` is called FIRST, then `setPoolSize(crowdId, 15)` is called SECOND. Verify call order via mock that appends to a shared call-sequence array; assert `calls = ["setLOD", "setPoolSize"]` not `["setPoolSize", "setLOD"]`.

**AC-LOD-19 (AC-LOD-12 continuation proof)** — GIVEN crowds `["42", "99"]`, `FollowerEntity.setLOD` throws only for `"42"`, WHEN tick dispatches both crowds, THEN `setLOD("42",...)` throws (mock-verified); `setLOD("99", tier)` IS called in the same tick (call count on mock's "99" = 1); `_tracking["42"]` NOT updated; `_tracking["99"]` IS updated; error does NOT propagate to the tick loop itself (no unhandled error, loop runs to completion).

**AC-LOD-20 (Rival readability at tier 1)** [Visual/Feel — ADVISORY] — GIVEN rival crowd with cap=15 at 30m (tier-1 boundary midpoint), WHEN ≥5 fresh playtesters observe during a 5-minute session, THEN ≥70% identify the rival crowd as "large" or "threatening" in a forced-choice recognition question. Run at first multiplayer playtest milestone. This validates cap=15 delivers Pillar 2 (Territorial Tension) + Pillar 4 (Cosmetic Expression); if it fails, raise tier-1 rival cap and re-test.

**AC-LOD-21 (Mobile own-crowd dominance)** [Visual/Feel — ADVISORY] — GIVEN mobile client with own crowd of 280 followers at tier-0 cap=40, WHEN mobile playtesters self-report after a 5-minute session, THEN ≥70% rate their crowd as "dominant" or "large" on a 5-point scale (4-5). Run at first mobile playtest milestone. This validates MOBILE_CAP_MULTIPLIER=0.5 preserves Pillar 1 (Snowball Dopamine) on mobile; if it fails, raise multiplier or reduce range.

---

**Test file**: `tests/unit/follower-lod-manager/follower_lod_manager.spec.luau`

**Required mocks**: `FollowerEntity` (setLOD/setPoolSize/getPeelingCount stubs — record call order for AC-LOD-18), `CrowdStateClient.get`, `CrowdManagerClient.getAllCrowdIds`, `workspace.CurrentCamera`, `UserInputService.{TouchEnabled, GamepadEnabled}`, `CrowdEliminated` RemoteEvent (fire mock event directly on the module under test for AC-LOD-16), `setInterval` replaced with synchronous stepper for deterministic tests.
