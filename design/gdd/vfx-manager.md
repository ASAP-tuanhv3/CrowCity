# VFX Manager

> **Status**: Designed (pending review)
> **Author**: user + game-designer + art-director + technical-artist + systems-designer + creative-director (fantasy framing) + qa-lead (AC validation)
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (Snowball Dopamine — absorb feel), Pillar 2 (Risky Chests — peel-off + rarity reveal payoff)
> **Review Mode**: lean
> **Creative Director Review (CD-GDD-ALIGN)**: SKIPPED — lean mode.

## Overview

The **VFX Manager** is the client-side presentation service that binds gameplay signals to on-screen visual effects. It owns no state, makes no gameplay decisions, and runs only on clients — servers fire events through the reliable/unreliable remote path defined by ADR-0001, VFX Manager subscribes on boot and plays the matching effect at client frame rate on receipt. It consumes seven contracts already locked in upstream GDDs: `Absorbed(crowdId, npcLastPosition)` from Absorb (→ 10-particle snap burst + Neon flash disc), `VFXEffect.HueShift(cframe)` from Follower Entity (→ optional 0.1s Neon pulse ring at peel hue-flip), `CollisionContactEvent(crowdIdA, crowdIdB)` from Crowd Collision Resolution (→ 12-particle midpoint burst + non-particle Neon ring), and `ChestPeelOff` / `ChestDraftOpenFX` / `ChestOpenBurst` from Chest System (→ follower-peel march + lid pop + tier-colored confetti column), plus `RelicGrantVFX` / `RelicExpireVFX` / `RelicDraftPick` from Relic System (→ rarity-tiered grant burst scaled by crowd radius, neutral-fade on expire). Beyond event dispatch, VFX Manager is the **budget enforcer** for art bible §8.7 — it maintains a scene-wide particle counter, clamps per-emitter rates at 20 p/s and per-event bursts at 40 particles, suppresses lower-priority emitters when the counter trends above 1,800 of the 2,000 ceiling, and recycles `ParticleEmitter` + `Part` instances through a small object pool to keep per-frame `Instance.new()` cost off the min-spec mobile main thread. Players experience this indirectly: the absorb counter ticks up and a white spark snaps where the NPC vanished, two rival crowds meet and a Neon boundary ring pulses at their midpoint, a T2 car explodes into a purple confetti column when you pay its toll. Without this system, those beats either cost too much (uncontrolled emitter spawns blow the 2,000 ceiling and tank mobile FPS) or never happen (no subscriber on the upstream contracts).

## Player Fantasy

You turn a corner. A cluster of white strangers. You don't slow down — you lean in.

Snap. Snap. Snap-snap-snap. Each brush triggers a flat burst at the spot they stood a heartbeat ago, a tiny disc of your signature hue blooming and gone. The stranger is already behind you, falling in line, wearing your color. You hear the rhythm before you feel it. Ten per second, fifteen, your whole screen pulsing in time with your footsteps.

It never stutters. Never tears. Even when the crowd behind you is a hundred deep and the street is confetti, every snap lands clean on the beat it belongs to. The absorb isn't a cost you pay for size — it's the sound your size makes.

You keep running.

**Behind the feeling.** VFX Manager exists so every absorb, every collision ring, every chest burst lands on its beat without the screen ever drowning in particles. It is the invisible budget — the reason a street-sweep run at 1-15 absorbs per second reads as rhythm instead of smear, and the reason a T2 car opening beside a mid-fight collision still reads both beats clearly. You don't notice it when it works. You'd feel it immediately if it didn't.

## Detailed Design

### Core Rules

**1. Client-only boot.** `VFXManagerClient` is a singleton module initialized exclusively from the client entry point (`ReplicatedFirst/Source/start.server.luau`) after `Network` and `CrowdStateClient` confirm init. Server-side require is a fatal assertion. No server code path exists.

**2. Single public API.** `VFXManager.playEffect(effectId: VFXEffectId, context: VFXContext)` is the only entry point. Both direct callers (Follower Entity at HueShift flip point) and internal remote-subscription handlers funnel through it. Suppression, priority, scene-count accounting, and pool management live in exactly one place.

**3. Event catalog completeness (9 live MVP events + 1 registered no-op).** Every upstream contract is handled or explicitly no-oped. Skipping is a configuration error, not a runtime-acceptable state. See Interactions table below for the full mapping.

**4. Registry-resolved asset ids — fail closed.** Particle textures resolve through `AssetId` enum (`SharedConstants/AssetId.luau`) at module require time. Missing / empty entry = effect skipped, `warn()` logged, `_particleCount` unchanged, no partial play. Never inline `rbxassetid://` strings in VFX Manager.

**5. Burst-fire + Debris self-destruct.** Every particle effect is burst-only (no continuous emission). After `ParticleEmitter:Emit(count)`, `Enabled = false` is set immediately on the same line. Owning Part scheduled for `Debris:AddItem(part, lifetime + 0.1s buffer)`. Emitters are never left attached to destroyed followers or world objects. Corollary: no sustained `Trail` or `Beam` effects at MVP.

**6. Scene-count tracking.** `_particleCount: number` integer incremented by burst count on emit. Decremented by same amount via `task.delay(lifetime + 0.1s, ...)` callback. On round end (`MatchStateChanged → Intermission`), `_particleCount` force-reset to 0 and pool force-reset to Idle (prevents drift from in-flight Janitor callbacks on teardown).

**7. Two-tier suppression + hysteresis recovery.**
- **Soft threshold 1,800**: effects with `priority ≤ 3` drop silently (not queued).
- **Hard threshold 1,950**: effects with `priority ≤ 5` also drop.
- **Recovery < 1,600**: return to `Subscribed` state. 200-count hysteresis prevents boundary flicker.
- Suppressed effects are never replayed; a suppressed AbsorbSnap is simply gone.

**8. Per-event priority table.** Priority integer per `VFXEffectId`, `[0, 10]`. Higher = more protected.

| Priority | Effect |
|---|---|
| 9 | `ChestOpenBurst`, `RelicGrantVFX.Epic` |
| 8 | `ChestDraftOpenFX`, `ChestPeelOff`, `RelicGrantVFX.Rare` |
| 7 | `RelicGrantVFX.Common`, `RelicDraftPick` |
| 6 | `CollisionContactEvent` (ImpactBurst) |
| 4 | `AbsorbSnap` |
| 3 | `RelicExpireVFX` (first to drop on budget pressure) |
| N/A | `HueShift` — VFX Manager owns no visual (see Rule 14); `NameplateHighlightSet` — registered no-op |

**9. Per-frame rate caps (distinct from suppression).** Fire BEFORE the suppression check:
- `AbsorbSnap`: max 6 / frame globally (caps 60 particles/frame addition from absorb alone).
- `CollisionContactEvent`: per-pair cooldown 0.5s; duplicates within that window dropped.
- `ChestPeelOff` arrival sparkle: 2 particles per arriving follower, hard capped at **20 particles / peel event** regardless of toll (prevents T3 120-follower peel blowing scene ceiling).
- No rate cap for Chest/Relic grant events (low-frequency by design).

**10. Effect anchoring — 3 modes.**
- `worldPos`: payload-embedded Vector3 or CFrame (AbsorbSnap, HueShift, ChestPeelOff, ChestDraftOpenFX, ChestOpenBurst).
- `crowdRelative`: resolved via `CrowdStateClient.get(crowdId).position` at play-time (RelicGrantVFX, RelicExpireVFX, RelicDraftPick).
- `computed`: midpoint `(A.pos + B.pos) / 2` at Y=0 (CollisionContactEvent).
- Anchor lookup must complete same frame; stale cached position acceptable up to `STALE_THRESHOLD_SEC = 0.5`; nil crowd → effect skipped + warn.

**11. Network failure = drop; no replay.** Reliable remotes dropped due to disconnect never re-fire. VFX is presentation-only; client-side reconciliation is not a concern.

**12. Framerate-independent lifetime.** All timings use wall-clock seconds via `TweenService` or `task.delay`. No `RenderStepped` frame counters.

**13. Non-blocking fire-and-forget.** `playEffect` never yields. Pool grant + property configuration + `:Emit()` + `Debris:AddItem` complete synchronously. Callers are never suspended.

**14. HueShift = Follower Entity-owned; VFX Manager owns no visual.** Follower Entity's existing single-frame `Body.Color = white → rival hue` write IS the HueShift visual. VFX Manager registers the event callback for Audio Manager coordination only (audio plays on callback). **Follower Entity GDD amendment flagged**: remove "VFX Manager MAY add a 0.1s Neon-material pulse ring" from §V/A.

**15. `NameplateHighlightSet` explicit no-op.** Registered in the catalog with a code comment naming Nameplate as owner. Prevents a future developer from accidentally re-implementing in VFX Manager.

### States and Transitions

#### Manager-level state machine

| State | Description |
|---|---|
| `Booting` | Module required; subscriptions not established; `CrowdStateClient` ready signal pending |
| `Subscribed` | All subscriptions established; effects play normally |
| `Suppressing` | `_particleCount ≥ 1,800` detected; low-priority effects dropped per Rule 7 |
| `Shutdown` | `MatchStateChanged → Intermission`; no new effects initiate; in-flight Debris timers run to completion |

| From | To | Trigger |
|---|---|---|
| `Booting` | `Subscribed` | `CrowdStateClient.ready` + all remote subscriptions confirmed |
| `Subscribed` | `Suppressing` | `_particleCount ≥ 1,800` at any `playEffect` call |
| `Suppressing` | `Subscribed` | `_particleCount < 1,600` on any decrement (hysteresis) |
| `{Subscribed, Suppressing}` | `Shutdown` | `MatchStateChanged → Intermission` received |
| `Shutdown` | `Subscribed` | Next round: `MatchStateChanged → Active` + `CrowdStateClient.ready` re-confirmed |

#### Pooled-instance lifecycle

`Idle → Acquired → Emitting → Cooldown → Idle`

| From | To | Condition |
|---|---|---|
| `Idle` | `Acquired` | `playEffect` claim; `Part.Parent = target`, `Transparency` restored, properties configured |
| `Acquired` | `Emitting` | Same frame: `ParticleEmitter:Emit(N)` + `Enabled=false` in one call (or `TweenService` start for non-particle Parts) |
| `Emitting` | `Cooldown` | Immediate — burst is instantaneous from code; particles remain in flight |
| `Cooldown` | `Idle` | `task.delay(lifetime + 0.1s)` callback fires; `Part.Parent = pool`, properties reset, `_particleCount -= N` |

Cooldown exists because Roblox ParticleEmitter physics takes a frame or two to settle after `:Emit()`. Same-frame re-parent causes visible artifacts. Cooldown per effect: AbsorbSnap 0.4s, ImpactBurst 0.5s, ChestPeelOff sparkle 0.3s, ChestOpenBurst 0.6s, Relic grants 0.6-1.3s.

#### Pool sizes (worst-case concurrency + ~50% headroom)

| Pool | Size | Worst-case basis |
|---|---|---|
| `ParticleEmitter` | 24 instances | 6 AbsorbSnap + 6 Collision + 1 Epic grant + 1 ChestOpenBurst concurrent, doubled for cooldown window |
| Flash-disc `Part` | 12 | 6 AbsorbSnap/frame × 0.15s × 60 FPS × 1.3 headroom ≈ 12 |
| Ring `Part` | 10 | 6 Collision + 1 Rare grant + headroom |
| Column `Part` | 4 | 1 ChestDraftOpenFX/Burst + 1 Epic grant + 2 headroom (serialized by design) |

Pool exhaustion policy: **hard drop + `warn()` once per session**. No grow-and-shrink. Pool sized from worst case; exhaustion means a pool size revision at next patch.

### Interactions with Other Systems

Inbound (VFX Manager subscribes or is called):

| System | Event | Direction | Interface | Source GDD |
|---|---|---|---|---|
| Absorb System | `Absorbed(crowdId, npcLastPosition)` | Inbound — reliable `GameplayEvent` | `Network.connectEvent` → `playEffect(AbsorbSnap, {pos, hue})` | design/gdd/absorb-system.md §C-F1 |
| Follower Entity | `HueShift(cframe)` | Inbound — direct call | `VFXManager.playEffect(HueShift, {cframe})` — audio coordination only; **no visual fires** | design/gdd/follower-entity.md §C.2 (amendment flagged) |
| Crowd Collision | `CollisionContactEvent(crowdIdA, crowdIdB)` | Inbound — reliable remote | `Network.connectEvent` → `playEffect(ImpactBurst, {idA, idB})` | design/gdd/crowd-collision-resolution.md §C Rule 7 |
| Chest System | `ChestPeelOff(chestId, crowdId, followerCount)` | Inbound — reliable, opener-only | `Network.connectEvent` → arrival sparkle (2 particles × follower, cap 20) | design/gdd/chest-system.md §V/A |
| Chest System | `ChestDraftOpenFX(chestId, tier)` | Inbound — reliable, global | `playEffect(DraftOpenFX, {chestId, tier})` | design/gdd/chest-system.md §V/A |
| Chest System | `ChestOpenBurst(chestId, tier, rarity)` | Inbound — reliable, global | `playEffect(OpenBurst, {chestId, tier, rarity})` | design/gdd/chest-system.md §V/A |
| Relic System | `RelicGrantVFX(crowdId, specId, slotIndex, rarity)` | Inbound — reliable, **global** | `playEffect(RelicGrant, {crowdId, rarity})` | design/gdd/relic-system.md §I |
| Relic System | `RelicExpireVFX(crowdId, specId, slotIndex)` | Inbound — reliable, global | `playEffect(RelicExpire, {crowdId})` | design/gdd/relic-system.md §I |
| Relic System | `RelicDraftPick(crowdId, specId)` | Inbound — reliable, global; pre-empts `RelicGrantVFX` within 0.1s dedup window per same `crowdId` | `playEffect(DraftPick, {crowdId, rarity})` | design/gdd/relic-system.md §I |
| (VS) Nameplate | `NameplateHighlightSet(crowdId, highlighted)` | Inbound — registered no-op | No visual fires; owned by Nameplate | design/gdd/player-nameplate.md |

Outbound / reads:

| System | Direction | Interface | Usage |
|---|---|---|---|
| `CrowdStateClient` | Read-only | `get(crowdId) → {position, radius, count, hue}` | Anchor lookup for `crowdRelative` effects; hue lookup for signature-hue particles |
| `Network` | Read-only | `connectEvent(RemoteEventName.*, handler)` | Subscribe to 7 reliable remotes at boot |
| `Debris` | Outbound call | `Debris:AddItem(part, lifetime + 0.1s)` | Self-destruct path for all spawned VFX Parts |
| `MatchStateClient` | Inbound signal | `MatchStateChanged` observer | Manager state transitions: `Shutdown` on Intermission; `Subscribed` on Active |
| `AssetId` (shared constants) | Read-only | `AssetId.VfxAbsorbSnapParticle`, etc. | Resolve particle textures at require time |
| Audio Manager (undesigned) | Outbound — event broadcast | Fires `VFXPlayed(effectId, context)` on every `playEffect` invocation for audio to mirror visual timing | **Contract defined here — Audio Manager GDD must register consumer.** Alternative: Audio Manager subscribes independently to the same upstream remotes. Flagged as Open Question. |

## Formulas

### F1 — Particle count estimator (`particle_count_estimator`)

The `particle_count_estimator` formula is defined as:

`_particleCount_next = _particleCount + burst_count_on_emit − burst_count_on_decay_callback`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `burst_count_on_emit` | N_emit | int | [1, 40] | Particles emitted in this `playEffect` call (per-effect constant from asset registry) |
| `burst_count_on_decay_callback` | N_decay | int | [1, 40] | Particles returning to pool via `task.delay(lifetime + 0.1s)` callback |
| `_particleCount` | C | int | [0, 2000+] | Running scene-wide estimate |

**Output Range:** 0 to ~2,000+ (may briefly overshoot ceiling by one burst before suppression engages). Clamped to ≥0 on any decrement.
**Example:** 3 `AbsorbSnap` fire in same frame → `_particleCount += 30` (3 × 10). 0.4s later, 3 decay callbacks fire → `_particleCount -= 30`. Net drift = 0.
**Conservative by design:** over-counts during particle decay tail (does not track per-particle Lifetime decay within the `0 → lifetime` window). Over-counting is correct — always err toward "budget tight" for a budget enforcer.

### F2 — Suppression tier selector (`suppression_tier`)

The `suppression_tier` formula is defined as:

```
suppression_tier(C) =
  0  if C < 1,800                    (no suppression, Subscribed state)
  1  if 1,800 ≤ C < 1,950            (drop priority ≤ 3)
  2  if C ≥ 1,950                    (drop priority ≤ 5)
```

Hysteresis recovery: if manager state is `Suppressing` AND `C < 1,600` → transition to `Subscribed`.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `_particleCount` | C | int | [0, 2000+] | Current estimator value (F1) |
| `SUPPRESS_THRESHOLD_SOFT` | T_s | int | 1,800 | Configurable; activates tier-1 drop |
| `SUPPRESS_THRESHOLD_HARD` | T_h | int | 1,950 | Configurable; activates tier-2 drop |
| `SUPPRESS_RECOVER` | R | int | 1,600 | Hysteresis floor |

**Output Range:** `{0, 1, 2}`.
**Example:** `ChestOpenBurst` fires while C=1,820 → tier=1 → priority-3 `RelicExpireVFX` in same frame dropped, priority-4 `AbsorbSnap` plays, priority-9 `ChestOpenBurst` plays. 0.6s later decay brings C to 1,600 → state returns to `Subscribed`.
**Edge:** a single 40-particle burst can cross soft→hard threshold in one frame. Tier is evaluated per `playEffect` call (not per frame), so the next call reads the new tier correctly.

### F3 — Relic grant scatter radius (`relic_scatter_radius`)

The `relic_scatter_radius` formula is defined as:

`scatter_radius_studs = max(RELIC_SCATTER_MIN, min(RELIC_SCATTER_MAX, crowd.radius × RELIC_SCATTER_COEF))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `crowd.radius` | r_c | float | [1.53, 18.04] | Hitbox radius from registry formula `radius_from_count` (includes Wingspan composition) |
| `RELIC_SCATTER_COEF` | k | float | 0.3 | Tuning knob |
| `RELIC_SCATTER_MIN` | s_min | float | 1.5 | Floor: prevents embarrassingly tiny sparkle at count=1 |
| `RELIC_SCATTER_MAX` | s_max | float | 3.0 | Ceiling: prevents scene-filling sparkle at count=300 |

**Output Range:** 1.5 to 3.0 studs across all valid `crowd.radius` values.
**Example:**
- count=1 (r_c=3.05) → `min(3.0, max(1.5, 3.05 × 0.3)) = min(3.0, max(1.5, 0.92)) = 1.5`
- count=300 (r_c=12.03) → `min(3.0, max(1.5, 3.61)) = 3.0`
- count=50 (r_c=6.39) → `min(3.0, max(1.5, 1.92)) = 1.92`

**Rationale:** sqrt compression in `radius_from_count` already softens count-to-radius growth; this adds a 2-stop clamp so small crowds get a visible floor and large crowds do not fill a 30-stud area. Ring + column sizes are **NOT** radius-scaled — they use fixed diameters (6-stud Rare ring, 12-stud Epic column). Only the particle scatter cloud scales.

### F4 — Peel vanish particle budget (`peel_vanish_particles`)

The `peel_vanish_particles` formula is defined as:

`peel_particles_total = min(PEEL_PARTICLE_CAP, PEEL_PARTICLES_PER_FOLLOWER × followerCount)`

`particles_per_follower_actual = peel_particles_total / followerCount`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| `followerCount` | n | int | [1, 120] | Effective toll from `ChestPeelOff` payload (discounted by TollBreaker via registry `effective_toll_chain`) |
| `PEEL_PARTICLE_CAP` | P_cap | int | 20 | Hard event cap |
| `PEEL_PARTICLES_PER_FOLLOWER` | p_pf | int | 2 | Per-follower ideal |

**Output Range:** 2 to 20 particles per peel event. `particles_per_follower_actual`: 2.0 (n ≤ 10) down to 0.17 (n = 120, T3 full-toll).
**Example:**
- T1 toll n=10 → `min(20, 2×10) = 20` → 2.0 particles per follower
- T1 TollBreaker n=7 → `min(20, 2×7) = 14` → 2.0 particles per follower
- T2 toll n=40 → `min(20, 2×40) = 20` → 0.5 particles per follower (distributed over 40 arrivals)
- T3 toll n=120 → `min(20, 2×120) = 20` → 0.17 particles per follower

**Implementation:** particles distributed over the ~0.5s peel transit. At n > 10, the sparkle fractionalizes — implementation uses stochastic emit (each arriving follower emits 1 particle with probability `20/n`, else 0). Preserves event total at 20 regardless of n.

## Edge Cases

### Routing & lifecycle

- **If event arrives before `Subscribed` state**: Network subscription handlers queue a single-frame defer (`task.defer`). If manager still not `Subscribed` after one frame, drop the effect silently. Events arriving during `Shutdown` are dropped immediately (no defer).
- **If event arrives for an eliminated crowd**: `CrowdStateClient.get(crowdId)` returns nil. Skip effect, log once per crowdId per round. Expected path for mid-tick elimination races — not a bug.
- **If reliable remote is dropped (disconnect / reconnect)**: VFX is not replayed. Per Rule 11, no reconciliation mechanism; a missed absorb snap stays missed.
- **If broadcast position is stale (> `STALE_THRESHOLD_SEC = 0.5s`)**: for `crowdRelative` effects, use last-known cached position rather than skip — Relic grant is too important to suppress on a brief drop. For `computed` midpoint (Collision), if either crowd is stale, fall back to the non-stale crowd's position; if both stale, skip + log.

### Payload validation

- **If `rarity` field missing / invalid on `RelicGrantVFX`**: treat as `"Common"` fallback (lowest-intensity effect). Log malformed payload. Protects against future registry additions that add a rarity string before VFX Manager is updated.
- **If `followerCount ≤ 0` on `ChestPeelOff`**: skip peel visual (nothing to peel). Do not attempt to spawn 0 follower arrival sparkles.
- **If `CFrame` is nil on direct HueShift call**: skip. Rule 14 means this path is audio-only anyway; missing CFrame = no audio anchor → skip.
- **If `chestId` chest Part is no longer in `Workspace`** (destroyed between server fire and client process): fallback to `crowdId` position as anchor for the 3 chest events. Visually imprecise but the beat still plays in a meaningful location.

### Concurrency & budget

- **If single 40-particle `ChestOpenBurst` crosses soft threshold 1,800 in one frame**: per F2, suppression tier is evaluated per `playEffect` call, not per frame. Next call reads the new tier correctly. The burst itself plays (priority 9, above both drop floors).
- **If `_particleCount` reaches hard engine ceiling 2,000**: Roblox begins dropping particles regardless of VFX Manager logic. Tier-2 suppression at 1,950 is the safety margin; consistently hitting 2,000 is a failure mode that requires pool re-sizing, not a runtime-acceptable state.
- **If pool is exhausted at `pool.grant()`**: return nil, log warning once per session per pool, drop effect silently. No grow-and-shrink allocation. Pool sizes are calculated from worst case; exhaustion indicates a design miscalculation surfaced for next patch.
- **If `RelicDraftPick` and `RelicGrantVFX` arrive within 0.1s for same `crowdId`**: Pick plays; Grant suppresses for that specific invocation only (tracked via `_recentPickEvents: {[crowdId]: timestamp}`). If Grant arrives more than 0.1s after Pick, Grant plays normally. Dedup window only suppresses duplicates within the same pick→grant beat pair.
- **If same `CollisionContactEvent` pair arrives twice within 0.5s** (network artifact on reconnect): per-pair cooldown map `_lastContactFX[pairKey]` (lex-ordered `"idA|idB"`) suppresses duplicate. First event plays, second dropped.
- **If HueShift fires at 80/sec burst during peel storm**: per Rule 14, VFX Manager owns no visual for HueShift — only the audio callback fires. Follower Entity's `Body.Color` write is the visual, already a 1-frame operation with no VFX pool cost. The 80/sec rate is tolerable because VFX Manager does not enter the pool path.

### Round lifecycle & state reset

- **If round ends (Intermission) with in-flight `task.delay` decrements pending**: manager state → `Shutdown`. On next round's `Subscribed` entry, `_particleCount` is force-reset to 0 and all pool slots force-reset to `Idle`. Any stale decrement callbacks that fire during `Shutdown` harmlessly decrement a zeroed counter. Pool slot drift is prevented by the force-reset.
- **If player's crowd is eliminated while own `AbsorbSnap` burst is in-flight**: effect completes its lifecycle (already spawned). No retroactive cancellation. Server-side `CrowdEliminated` is a separate signal; VFX Manager does not subscribe.

## Dependencies

| System | Relationship | Interface | Status | Reverse-listed? |
|---|---|---|---|---|
| **AssetId Registry** (art bible §8.9 convention) | Hard — upstream | Particle texture constants: `AssetId.VfxAbsorbSnapParticle`, `AssetId.VfxCollisionImpactParticle`, `AssetId.VfxChestBurstParticle`, `AssetId.VfxRelicGrantParticle` (tier / rarity colors set at runtime, not in texture) | Convention (approved) | Art bible §8.9 is convention-only; this GDD adds 4 registry keys |
| **CrowdStateClient** (from Crowd State Manager) | Hard — upstream | `CrowdStateClient.get(crowdId) → {position, radius, count, hue, state, radiusMultiplier}` read at play-time for `crowdRelative` effects + hue lookup. Post-Batch-1 cache fields (state, radiusMultiplier) available. | Batch 1 Applied 2026-04-24 | CSM §G declares `CrowdStateClient` as read-only mirror of `CrowdStateBroadcast`. Consumer enumeration is informational (no contract action); VFX reads post-composed `crowd.radius` per CSM F1. No amendment required. |
| **Network Layer** (template-provided) | Hard — upstream | `Network.connectEvent(RemoteEventName.*, handler)` for 7 reliable remotes at boot | Approved (template) | Template-provided |
| **Debris service** (Roblox built-in) | Hard — upstream | `Debris:AddItem(part, lifetime + 0.1s)` for all spawned Parts | N/A (engine) | — |
| **Absorb System** | Soft — downstream source | Subscribes to `GameplayEvent.Absorbed(crowdId, npcLastPosition)` | Designed (pending review) | Absorb §F explicitly lists VFX Manager consumer contract ✓ |
| **Follower Entity** | Hard — downstream source (direct call) | Receives `playEffect(HueShift, {cframe})` synchronous call at 50% peel transit | In Review | Follower Entity §Dep explicitly lists VFX Manager call ✓. **Amendment flagged**: remove "MAY add 0.1s Neon pulse ring" language per Rule 14. |
| **Crowd Collision Resolution** | Hard — downstream source | Subscribes to reliable `CollisionContactEvent(crowdIdA, crowdIdB)` fired on `pairEntered` | Designed (pending review) | Collision §F explicitly lists VFX Manager consumer contract ✓ |
| **Chest System** | Hard — downstream source | Subscribes to `ChestPeelOff`, `ChestDraftOpenFX`, `ChestOpenBurst` | Designed (pending review) | Chest §F, §V/A explicitly list VFX Manager consumer contract ✓ |
| **Relic System** | Hard — downstream source | Subscribes to `RelicGrantVFX`, `RelicExpireVFX`, `RelicDraftPick` | Designed (pending review) | Relic §I explicitly lists VFX Manager consumer contract ✓. **Scope lock**: all three are GLOBAL broadcasts (all clients see). Relic GDD does not currently specify scope; **amendment flagged**. |
| **Match State Client** (from Match State Machine) | Soft — upstream | Observes `MatchStateChanged` for manager state transitions (`Shutdown` on Intermission, `Subscribed` on Active) | In Review | MSM GDD lists state broadcasts generally; VFX Manager observer is new — amendment optional (MSM already fires to all clients). |
| **`AssetId` enum module** (`SharedConstants/AssetId.luau`) | Hard — upstream | Required at module load; 4 new keys added per this GDD | Convention | Register 4 new keys as part of this GDD's acceptance |
| **Player Nameplate** | Soft — downstream source | Registered no-op for `NameplateHighlightSet` (VS scope) | Designed (pending review) | Nameplate §V/A lists VFX Manager as optional consumer (VS scope); registered as explicit no-op in MVP per Rule 15 ✓ |
| **Audio Manager** (undesigned) | Soft — downstream receiver | VFX Manager fires `VFXPlayed(effectId, context)` on every `playEffect` invocation so Audio can mirror timing. **Contract defined here.** Alternative: Audio Manager subscribes independently to the same upstream remotes (avoids VFX → Audio coupling). Open Question. | Not started | — |

### Dependency amendments required (propagate later via `/propagate-design-change`)

1. **Follower Entity** — §V/A: remove "VFX Manager MAY add a 0.1s Neon-material pulse ring (1-Part BillboardGui, 32×32px, rival hue, instant scale-up then alpha-fade) if particle budget permits. Particle-free fallback is acceptable." Replace with: "VFX Manager notified for audio coordination only; no VFX ring. HueShift visual = `Body.Color` single-frame write (already owned here)."
2. **Crowd State Manager** — §Dep: add VFX Manager as a listed client-cache reader.
3. **Relic System** — §Dep: explicitly lock `RelicGrantVFX` / `RelicExpireVFX` / `RelicDraftPick` remote scope as GLOBAL (all clients receive). Currently unspecified.
4. **Art bible §8.4** — extend Neon-material permit language to cover "temporary VFX punctuation Parts (rings, columns) with a destroy-after-tween contract." Current wording covers "VFX emitters + flash disc + ability indicators + UI billboards" which is ambiguous for the 12-stud Epic column and 6-stud Rare ring.

### Cross-system facts confirmed consistent (no conflicts)

- `MAX_CROWD_COUNT = 300` → F4 uses `followerCount` max 120 (T3 toll); no conflict.
- `radius_from_count` → F3 reads `crowd.radius` range [1.53, 18.04]; matches registry.
- `STALE_THRESHOLD_SEC = 0.5` → consumed correctly in edge cases.
- `effective_toll_chain` → F4 reads `followerCount` = post-discount toll; matches registry.

## Tuning Knobs

| Knob | Default | Safe range | Unit | What it affects | Breaks if too high | Breaks if too low | Owner |
|---|---|---|---|---|---|---|---|
| `SUPPRESS_THRESHOLD_SOFT` | 1,800 | [1,500, 1,950] | particles | Tier-1 drop floor (priority ≤ 3 dropped — RelicExpireVFX first) | Too few suppressions before Roblox ceiling breach (≥2,000) causes engine-level drops | Over-aggressive suppression; RelicExpireVFX fades drop silently under even modest scene load | technical-artist |
| `SUPPRESS_THRESHOLD_HARD` | 1,950 | [1,800, 1,990] | particles | Tier-2 drop floor (priority ≤ 5 dropped) | Scene hits 2,000 ceiling → engine drops particles non-deterministically | Over-aggressive mid-priority drop; collisions + relic expires vanish during normal play | technical-artist |
| `SUPPRESS_RECOVER` | 1,600 | [1,000, 1,750] | particles | Hysteresis floor for `Suppressing → Subscribed` | Recovery too close to activation; state flickers every frame | Recovery lags; effects suppressed long after scene clears | technical-artist |
| `RELIC_SCATTER_COEF` | 0.3 | [0.1, 0.5] | multiplier | Particle scatter radius vs `crowd.radius` (F3) | Very large crowds get oversized sparkle clouds that fragment silhouette | Scatter stuck at floor (1.5 studs) across all counts — Epic grant looks identical on count=1 vs count=300 | art-director |
| `RELIC_SCATTER_MIN` | 1.5 | [1.0, 2.5] | studs | F3 floor | Small-crowd grant loses intimacy | Tiny crowd Epic grant looks embarrassingly small (<1 stud scatter) | art-director |
| `RELIC_SCATTER_MAX` | 3.0 | [2.0, 5.0] | studs | F3 ceiling | Large-crowd grant clouds break crowd silhouette | Large-crowd Epic grant feels undersized next to 12-stud column | art-director |
| `PEEL_PARTICLE_CAP` | 20 | [10, 40] | particles | F4 event cap | T3 120-follower peel can blow scene ceiling + force suppression cascade | Peel vanish reads as stochastic noise even on small T1 tolls | art-director |
| `PEEL_PARTICLES_PER_FOLLOWER` | 2 | [1, 4] | particles | F4 per-follower ideal | Low-toll peels exceed cap; cap engagement becomes the common case | Per-follower sparkle invisible at n=1; peel does not read as event | art-director |
| `ABSORB_PER_FRAME_CAP` | 6 | [4, 12] | effects/frame | Rule 9 AbsorbSnap rate cap | Single frame adds 60+ particles to scene; combined with other events crosses soft threshold | Below Follower Entity 4/frame spawn throttle means some absorbs get no VFX (desync with counter) | systems-designer |
| `COLLISION_PAIR_COOLDOWN` | 0.5 | [0.1, 2.0] | seconds | Rule 9 per-pair ImpactBurst dedup | Long sustained collisions play ring only once; dead-silent during 10-sec wrestle | Network duplicates bypass dedup; rings stack at midpoint | systems-designer |
| `DRAFT_PICK_DEDUP_WINDOW` | 0.1 | [0.05, 0.5] | seconds | RelicDraftPick → RelicGrantVFX suppression window per same `crowdId` (Edge) | Grant sparkles suppressed on legitimate second-event arrivals | Pick + Grant play simultaneously, doubling the visual beat | game-designer |
| `EMITTER_POOL_SIZE` | 24 | [12, 48] | instances | ParticleEmitter pool size (§C) | Memory overhead on min-spec mobile (~2KB per emitter × 48 = 96KB) | Pool exhausted in normal play → effects drop silently | technical-artist |
| `FLASH_DISC_POOL_SIZE` | 12 | [8, 24] | instances | Flash-disc Part pool size | Minor memory bump | Burst-absorb exhausts pool, discs drop | technical-artist |
| `RING_POOL_SIZE` | 10 | [6, 16] | instances | Ring Part pool size | Minor memory bump | Multi-collision + Rare grant exhausts pool | technical-artist |
| `COLUMN_POOL_SIZE` | 4 | [2, 8] | instances | Column Part pool size | Minor memory bump | Chest + Epic column overlap exhausts pool (rare) | technical-artist |
| `COOLDOWN_BUFFER_SEC` | 0.1 | [0.05, 0.3] | seconds | Added to `lifetime` before pool reclaim (§C state machine) | Long cooldown reduces effective pool capacity | Re-parent artifact (particles teleport mid-flight to new target) | technical-artist |

**Locked constants (NOT tuning knobs):**
- `MAX_CROWD_COUNT = 300` — locked by CSM (registry).
- `STALE_THRESHOLD_SEC = 0.5` — locked by CSM (registry).
- Per-effect particle counts (10 absorb, 12 collision, 15 / 20 / 30 relic rarity, 40 chest burst) — locked by art bible §8.7 + upstream GDD §V/A sections.

## Visual/Audio Requirements

**Scope.** This section catalogs all effect beats VFX Manager plays. Authoritative visual spec for each beat lives in its source GDD (Absorb §V/A, Collision §V/A, Chest §V/A, Relic §V/A, Follower Entity §V/A). VFX Manager does not re-spec — it declares the motion language, the rarity palette, the audio-coordination contract, and consolidates the per-beat catalog. Any change to per-beat visual properties must flow back to the source GDD first via `/propagate-design-change`.

### Motion grammar (locked for VFX Manager catalog)

Four verbs, one per event class:

| Motion | Events | Meaning |
|---|---|---|
| **Outward radial** | `AbsorbSnap`, `ImpactBurst` | Contact event — something happened TO the entity at this point |
| **Upward vertical** | `ChestDraftOpenFX`, `ChestOpenBurst`, `RelicGrantVFX.Epic`, `RelicDraftPick` | Payoff — something valuable happened, look up |
| **Inward directional** | `ChestPeelOff` (follower march toward chest) | Sacrifice — giving something up |
| **Fade / decay** | `RelicExpireVFX` | Expiry — not a new event, a winding down |

Additions to the catalog must declare which verb they use. Effects that mix verbs (e.g., `ImpactBurst` = radial + ring expansion) are permitted only when the mix reinforces the verb (ring expansion IS outward radial at a different geometric scale).

### Rarity palette for in-world VFX (locked)

- **Common** = Neutral White `#F5F5F5` — reads as baseline; reuses the NPC ambient value
- **Rare** = Bright Aqua `#00D9C8` — distinct from all 12 player hues + all 3 tier colors; deuteranopia-safe
- **Epic** = Pale Warm Gold `#FFE5AA` — distinct from T1 Chest Gold `#FFD700` + player Gold-Yellow `#FFAA00`; reads as "precious"

Shape redundancy for colorblind safety: built into the escalation itself (particles only → particles + ring → particles + column). No per-tier shape coding in the VFX layer itself.

### Per-beat catalog (authoritative spec in source GDD)

| Event | Anchor | Particles (count / material / color / life) | Non-particle Parts | Duration | Source GDD |
|---|---|---|---|---|---|
| **AbsorbSnap** | `worldPos` at NPC last pos | 10 flat-quad / SmoothPlastic / signature hue / 0.3s, radial ≤1 stud | 1 Neon disc / white `#F5F5F5` / 0 → 0.5-stud dia → 0 / 0.15s | 0.3s | design/gdd/absorb-system.md §V/A |
| **HueShift** | N/A — VFX Manager owns no visual (Rule 14) | None | None | `Body.Color` 1-frame write | design/gdd/follower-entity.md §C.2 + §V/A |
| **ImpactBurst** | `computed` midpoint at Y=0 | 12 flat-quad / SmoothPlastic / white `#F5F5F5` / 0.4s, radial ≤2.5 studs | 1 Neon ring / white / 0 → 3-stud dia / 0.45s | 0.45s | design/gdd/crowd-collision-resolution.md §V/A |
| **ChestPeelOff arrival sparkle** | `worldPos` at chest Part | min(20, 2×n) flat-quad / SmoothPlastic / tier color × 0.85 saturation / 0.2s — stochastic distribution per F4 | None | ~0.5s transit | design/gdd/chest-system.md §V/A + this GDD F4 |
| **ChestDraftOpenFX** | `worldPos` at chest Part | None | 1 Neon cylinder / tier color / 0.5-stud dia, 0 → 15-stud height over 0.3s + hold 0.2s + fade 0.3s | 0.8s | design/gdd/chest-system.md §V/A |
| **ChestOpenBurst** | `worldPos` at chest Part | 40 flat-quad confetti / SmoothPlastic / tier color (30) + rarity color accent (10) / 0.5s, upward scatter ≤3 studs lateral + upward velocity | 1 column dissolve (continuation of `DraftOpenFX`) / 0.3s fade | 0.5s (particles) + 0.3s (column dissolve) | design/gdd/chest-system.md §V/A |
| **RelicGrantVFX — Common** | `crowdRelative` at `crowd.position` | 15 flat-quad sparkle / SmoothPlastic / white `#F5F5F5` / 0.5s, radial via F3 | 1 Neon micro-disc / white / 0 → 0.3-stud dia → 0 / 0.15s | 0.5s | design/gdd/relic-system.md §V/A + this GDD F3 |
| **RelicGrantVFX — Rare** | `crowdRelative` at `crowd.position` | 20 flat-quad sparkle / SmoothPlastic / Rare aqua `#00D9C8` / 0.5s, radial via F3 | 1 Neon ring / white / **fixed** 6-stud dia over 0.3s + hold 0.1s + fade 0.2s | 0.6s | design/gdd/relic-system.md §V/A + this GDD F3 |
| **RelicGrantVFX — Epic** | `crowdRelative` at `crowd.position` | 30 flat-quad sparkle / SmoothPlastic / Epic pale gold `#FFE5AA` / 0.7s, radial via F3 | 1 Neon column / white / **fixed** 0.5-stud dia, 0 → 12-stud height over 0.4s + hold 0.4s + fade 0.4s; 1 Neon base-disc / Epic pale gold / 0 → 0.8-stud dia → 0 / 0.2s | 1.2s | design/gdd/relic-system.md §V/A + this GDD F3 |
| **RelicExpireVFX** | `crowdRelative` at `crowd.position` | 6 flat-quad / SmoothPlastic / neutral grey `#8A8A8A` / 0.3s, inward scatter ≤1 stud (decay, not radial) | None | 0.3s | design/gdd/relic-system.md §V/A |
| **RelicDraftPick** | `crowdRelative` at `crowd.position` (pre-empts Grant) | 8 flat-quad / SmoothPlastic / rarity color (matched to pending grant) / 0.25s, upward velocity +3 studs/s | None | 0.25s | design/gdd/relic-system.md §V/A |
| **NameplateHighlight** (VS) | N/A — registered no-op | — | — | — | design/gdd/player-nameplate.md §V/A |

### Audio coordination contract

VFX Manager fires one signal per `playEffect` invocation:

`VFXPlayed(effectId: VFXEffectId, context: VFXContext, anchor: Vector3)`

`anchor` is the resolved world-space position (for `crowdRelative` effects, the looked-up `crowd.position`; for `computed` midpoints, the computed Vector3). Audio Manager consumes to position 3D positional SFX. Firing happens AFTER suppression check but BEFORE pool grant — a suppressed effect still fires the audio signal (unless audio is also priority-gated per Audio Manager's own policy).

**Alternative design (Open Question):** Audio Manager subscribes independently to the same upstream remotes, avoiding VFX → Audio coupling. Resolution deferred to Audio Manager GDD.

### Art bible alignment

| Art bible §ref | How this system honors it |
|---|---|
| §1 Visual Identity ("bold silhouette at 50m") | Ring + column fixed sizes (6 studs / 12 studs) always visible above crowd head-ridge. Peel-vanish tier sparkle desaturated to 85% prevents hue collision with sig-hue AbsorbSnap clouds. |
| §4 Flat Saturated Color / No Gradients | All VFX colors are flat — no gradients. Epic column is flat white with flat gold base-disc; no color tween between them. Rarity accent in `ChestOpenBurst` is a discrete particle subset, not a gradient. |
| §4 Neutral NPC Treatment | `AbsorbSnap` signature-hue disc + `HueShift` identity-flash are single-frame discontinuities, not lerps. |
| §8.4 Material Standards | Neon on VFX Parts (flash disc, rings, columns, base-disc). **Ambiguous permit for 6-stud / 12-stud scale — amendment flagged in §Dep.** SmoothPlastic on emitters is fine. No Neon on structural geometry. All Neon Parts self-destroy via `Debris:AddItem`. |
| §8.5 LOD Policy | VFX Parts are not LOD-tiered (too brief to matter). Debris at `lifetime + 0.1s` removes them before LOD would kick in. |
| §8.7 VFX Budgets | Per-emitter ≤20 p/s: all emitters burst-only (rate not relevant after `:Emit`). Burst cap 40 per event: `ChestOpenBurst` is exactly 40; all others ≤30. Scene ceiling 2,000 with suppression at 1,800: enforced by F1 + F2. |
| §8.10 Perf Validation | MicroProfiler tags: `VFXManager_PlayEffect`, `VFXManager_Reclaim`, `VFXManager_BudgetEnforcer`. Target budget: ≤0.5 ms/frame on iPhone SE. |

---

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:vfx-manager` to produce per-asset visual descriptions + generation prompts for the 4 particle textures (`VfxAbsorbSnapParticle`, `VfxCollisionImpactParticle`, `VfxChestBurstParticle`, `VfxRelicGrantParticle`). Non-particle Parts are runtime-generated (no asset spec needed).

## UI Requirements

**VFX Manager owns no screen-space UI.** All screen-space tweens and overlays are owned by their respective UI GDDs:

| UI effect | Owner GDD | Rationale |
|---|---|---|
| HUD count-pop tween | `design/gdd/hud.md` §V/A | Pure `TweenService` on `TextLabel.Size`, not a ParticleEmitter |
| MAX CROWD flash (opacity 0 → 1 → 0) | `design/gdd/hud.md` Rule 5 + §V/A | Pure opacity tween on `MaxCrowdFlashWidget` |
| Timer urgency tween (≤10s red + scale 1.1×) | `design/gdd/hud.md` §V/A | Pure `TweenService` on `TextLabel` |
| Relic shelf rarity-frame render | `design/gdd/hud.md` Rule 11 | Static `Frame` hierarchy |
| Nameplate text render + tier offset | `design/gdd/player-nameplate.md` §C | `BillboardGui` + `UIStroke`; no VFX Manager involvement |
| Nameplate FTUE highlight glow (VS) | `design/gdd/player-nameplate.md` §V/A (Intent) | Registered as no-op in VFX Manager Rule 15 |
| Relic Card draft modal (VS) | Relic Card / Reveal UI GDD (undesigned, VS) | Screen-space modal |
| Round Result Screen (VS) | Round Result Screen GDD (undesigned, VS) | Screen-space modal |

**Rationale for separation.** Screen-space tweens on `TextLabel` / `Frame` / `ImageLabel` run through Roblox's `GuiService` render path, not through the ParticleEmitter pipeline. Grouping them into VFX Manager would:
- Conflate the scene particle ceiling (2,000) with UI tween budgets (no ceiling — per-frame TweenService cost).
- Force HUD / Nameplate code to call through a third module instead of owning their own lifecycle.
- Break the art bible §8.7 scope (scene-wide concurrent particle ceiling is world-space only).

**Consequence for VFX Manager implementation.** The `VFXManagerClient` module does NOT require any `UIHandler` / `ScreenGui` dependencies. No `GuiService` API surface. Pure `Workspace` + `Debris` + `TweenService` (for non-particle world-space Parts only) + `Network`.

## Acceptance Criteria

QA-lead validated and extended SysD's initial 8 ACs. 29 ACs cover all 15 Core Rules, all 4 formulas, all state-machine transitions, rate caps, and edges. Priority contradiction (FLAG-1) resolved 2026-04-23: `RelicExpireVFX` priority 5 → 3, `AbsorbSnap` stays at 4.

**Evidence tier legend:** `unit` = TestEZ with mocked dependencies; `integration` = TestEZ + test harness or MicroProfiler; `manual` = screenshot + lead sign-off. Logic ACs are BLOCKING per coding standards; perf ACs are ADVISORY.

### Core Rules

**AC-1 (Server-side require is fatal — Rule 1)** — GIVEN VFX Manager module required from a server execution context (mocked `RunService.IsServer = true`), WHEN `require(VFXManagerClient)` executes, THEN the call throws before any subscription or pool init occurs, and no `_particleCount` field is created. *Evidence: unit.* **BLOCKING.**

**AC-2 (All 10 catalog entries registered before Subscribed — Rule 3)** — GIVEN VFX Manager boots with mocked Network + CrowdStateClient, WHEN `CrowdStateClient.ready` fires and subscriptions confirm, THEN calling `playEffect` with each of the 10 `VFXEffectId` values produces no "unknown effectId" error; `HueShift` + `NameplateHighlightSet` produce zero pool-grant calls. *Evidence: unit.* **BLOCKING.**

**AC-3 (Missing AssetId fails closed — Rule 4)** — GIVEN AssetId registry mock where `AssetId.VfxAbsorbSnapParticle` returns `""`, WHEN `playEffect(AbsorbSnap, validContext)` is called, THEN `_particleCount` is unchanged, a `warn()` is emitted exactly once, `pool.grant` is never called, and the function returns without error. *Evidence: unit.* **BLOCKING.**

**AC-4 (Burst-fire + Debris self-destruct — Rule 5)** — GIVEN mocked `Debris` service recording `AddItem(part, t)` calls and a valid pool with one available emitter, WHEN `playEffect(AbsorbSnap, validContext)` is called, THEN `ParticleEmitter.Enabled = false` on the same frame as `Emit()`, and `Debris.AddItem` called with `t = lifetime + 0.1s = 0.4s`. *Evidence: unit.* **BLOCKING.**

**AC-5 (Direct-call + remote-subscription both increment `_particleCount` — Rule 2 + Rule 13)** — GIVEN `_particleCount = 0` and valid pool, WHEN (a) `VFXManager.playEffect(AbsorbSnap, validContext)` called directly, then (b) mocked `Absorbed` remote handler fires with identical context, THEN after each call `_particleCount` increases by the same `N_emit = 10`; `playEffect` returns without yielding (verified by coroutine spy asserting no suspension). *Evidence: unit.* **BLOCKING.**

**AC-6 (Network failure = no replay — Rule 11)** — GIVEN mocked Network where `Absorbed` fires once then mock replaced with no-op (simulating disconnect), WHEN `playEffect` would be called 0 additional times after disconnect, THEN no deferred or scheduled `playEffect` fires for the missed event; `_particleCount` after the single fired event matches exactly `N_emit = 10`. *Evidence: unit.* **BLOCKING.**

**AC-7 (Non-blocking fire-and-forget — Rule 13)** — GIVEN VFX Manager in `Subscribed` state, WHEN `playEffect(ChestOpenBurst, validContext)` called from within a coroutine spy, THEN the spy records zero yields and function returns within the same logical frame. *Evidence: unit.* **BLOCKING.**

**AC-8 (HueShift fires zero pool grants and zero particle emits — Rule 14)** — GIVEN `Subscribed` state, `_particleCount = 0`, spy on `pool.grant`, WHEN `playEffect(HueShift, {cframe = CFrame.new()})` called, THEN `pool.grant` called 0 times, `_particleCount` remains 0, no `Debris.AddItem` recorded. *Evidence: unit.* **BLOCKING.**

**AC-9 (NameplateHighlightSet explicit no-op — Rule 15)** — GIVEN `Subscribed` state + spies on `pool.grant`, `warn`, internal log, WHEN `playEffect(NameplateHighlightSet, anyContext)` called, THEN `pool.grant` 0 times, `_particleCount` unchanged, no `warn` emitted (correctly registered no-op, not missing-asset error), call returns without error. *Evidence: unit.* **BLOCKING.**

**AC-10a (Anchoring — `worldPos` passthrough — Rule 10)** — GIVEN `playEffect(AbsorbSnap, {position = Vector3.new(10, 0, 20)})`, WHEN pool-grant Part CFrame is read post-call, THEN Part `Position == Vector3.new(10, 0, 20)` exactly (no crowd lookup invoked; CrowdStateClient.get spy records 0 calls). *Evidence: unit.* **BLOCKING.**

**AC-10b (Anchoring — `computed` midpoint + stale fallback — Rule 10)** — GIVEN `CollisionContactEvent(A, B)` with `CrowdStateClient.get(A)` returning `{position = Vector3.new(0,0,0)}` and `get(B)` returning `{position = Vector3.new(10,0,0)}`, WHEN effect plays, THEN emitter Part `Position == Vector3.new(5, 0, 0)` (midpoint at Y=0). If `get(B)` returns nil (stale), THEN midpoint falls back to A's position `Vector3.new(0, 0, 0)`. If both nil, effect skipped + `warn` emitted. *Evidence: unit.* **BLOCKING.**

### Formulas

**AC-11 (F1 — count increments on emit, decrements on decay; floor ≥ 0)** — GIVEN `_particleCount = 0` and mocked `task.delay` firing synchronously, WHEN `playEffect(AbsorbSnap, context)` called (`N_emit = 10`) then decay callback fires, THEN `_particleCount` reaches 10 after emit, 0 after decay; a second decay on already-zero counter does not produce a negative value. *Evidence: unit.* **BLOCKING.**

**AC-12 (F1 — multi-burst accumulation at three boundary points)** — GIVEN `_particleCount = 0` and synchronous `task.delay` mock, WHEN three `AbsorbSnap` calls fire in same logical frame, THEN `_particleCount = 30` immediately after; after three decay callbacks, `_particleCount = 0`. Verify: one `ChestOpenBurst` raises to 40; one `RelicGrantVFX.Common` raises to 15. *Evidence: unit.* **BLOCKING.**

**AC-13 (F2 — suppression tier at five boundary points)** — GIVEN `_particleCount` set to (a) 1,799, (b) 1,800, (c) 1,949, (d) 1,950, (e) 1,600, WHEN `suppression_tier(_particleCount)` evaluated, THEN: (a) tier 0; (b) tier 1; (c) tier 1; (d) tier 2; (e) tier 0. *Evidence: unit.* **BLOCKING.**

**AC-14 (F2 — soft suppress drops priority ≤ 3, plays priority 4)** — GIVEN `_particleCount = 1,820` (tier 1), WHEN `playEffect(RelicExpireVFX, context)` (priority 3 — drops) then `playEffect(AbsorbSnap, context)` (priority 4 — plays) then `playEffect(ChestOpenBurst, context)` (priority 9 — plays), THEN RelicExpireVFX is dropped (pool.grant not called, `_particleCount` unchanged for that call); AbsorbSnap and ChestOpenBurst play normally (`_particleCount += 10` and `+= 40`). *Evidence: unit.* **BLOCKING.**

**AC-15 (F3 — scatter radius clamps at three boundary points)** — GIVEN mocked `CrowdStateClient` returning `radius` of (a) 3.05 (count≈1), (b) 6.39 (count≈50), (c) 12.03 (count≈300), WHEN `playEffect(RelicGrantVFX.Common, {crowdId})` resolves scatter via F3, THEN: (a) scatter = 1.5 (clamped to min); (b) scatter ≈ 1.92 (unclamped: 6.39 × 0.3); (c) scatter = 3.0 (clamped to max). *Evidence: unit.* **BLOCKING.**

**AC-16 (F4 — peel particle budget at four boundary points)** — GIVEN `followerCount` of (a) 7, (b) 10, (c) 40, (d) 120 in `ChestPeelOff` context, WHEN `peel_vanish_particles(followerCount)` evaluated, THEN: (a) 14; (b) 20; (c) 20; (d) 20. Also: `followerCount = 0` returns 0 and effect skipped. *Evidence: unit.* **BLOCKING.**

### State Machine Transitions

**AC-17 (Manager: Booting → Subscribed)** — GIVEN VFX Manager required (state = `Booting`), Network + CrowdStateClient mocks initialized but `ready` not yet fired, WHEN `CrowdStateClient.ready` fires and all 7 subscriptions confirm, THEN manager transitions to `Subscribed`; a `playEffect` call now processes normally (pool grant occurs, `_particleCount` increments). *Evidence: unit.* **BLOCKING.**

**AC-18 (Manager: Subscribed → Suppressing)** — GIVEN state = `Subscribed` and `_particleCount = 1,799`, WHEN a `playEffect` adds `N_emit ≥ 1` crossing 1,800, THEN manager state becomes `Suppressing` before the next `playEffect` is evaluated. *Evidence: unit.* **BLOCKING.**

**AC-19 (Manager: Suppressing → Subscribed via hysteresis)** — GIVEN state = `Suppressing` and `_particleCount = 1,601`, WHEN decay callback fires reducing `_particleCount` to 1,599, THEN state transitions to `Subscribed`; subsequent `playEffect(AbsorbSnap)` (priority 4) is no longer dropped. *Evidence: unit.* **BLOCKING.**

**AC-20 (Manager: Subscribed → Shutdown on Intermission)** — GIVEN state = `Subscribed`, WHEN `MatchStateChanged(MatchState.Intermission)` fires, THEN state = `Shutdown`; any subsequent `playEffect` during `Shutdown` dropped immediately (no defer, no pool grant). *Evidence: unit.* **BLOCKING.**

**AC-21 (Manager: Shutdown → Subscribed on next round + force-reset)** — GIVEN state = `Shutdown` with `_particleCount = 450` (non-zero residual) and two pool slots in `Cooldown`, WHEN `MatchStateChanged(MatchState.Active)` + `CrowdStateClient.ready` re-confirms, THEN `_particleCount` force-reset to 0, all pool slots force-reset to `Idle`, state = `Subscribed`. *Evidence: unit.* **BLOCKING.**

**AC-22 (Pool: Idle → Acquired → Emitting → Cooldown → Idle)** — GIVEN single pool slot in `Idle`, WHEN `playEffect(AbsorbSnap, validContext)` called, THEN slot transitions: `Idle → Acquired` (re-parent to Workspace), `Acquired → Emitting` (`:Emit()` + `Enabled=false`), `Emitting → Cooldown` (same frame), `Cooldown → Idle` after `task.delay(0.4s)` fires (re-parent to pool, properties reset, `_particleCount -= N`). *Evidence: unit. Mock `task.delay` to fire synchronously.* **BLOCKING.**

### Rate Caps (Rule 9)

**AC-23 (AbsorbSnap max 6 / frame)** — GIVEN `_particleCount = 0` and 10 `AbsorbSnap` events queued within same frame, WHEN all 10 processed in same `playEffect` batch, THEN exactly 6 pool grants occur (`_particleCount = 60`); remaining 4 dropped silently without `warn`. *Evidence: unit. Frame boundary injectable.* **BLOCKING.**

**AC-24 (Collision per-pair 0.5s cooldown, symmetric)** — GIVEN pair `(crowdA, crowdB)` with no prior contact, WHEN `CollisionContactEvent(A, B)` fires at t=0 and again at t=0.3s (within 0.5s window), THEN only first event plays (1 pool grant); second dropped. At t=0.6s a third event plays (second pool grant). Symmetric: `(B, A)` at t=0.7s is also deduped (lex-ordered key). *Evidence: unit. Mock clock function.* **BLOCKING.**

**AC-25 (ChestPeelOff hard cap 20 particles/event)** — GIVEN `followerCount = 120` (T3 full toll), WHEN `ChestPeelOff` fires, THEN total particles emitted ≤ 20 (F4 cap); `_particleCount` increases by ≤ 20, not `2 × 120 = 240`. *Evidence: unit.* **BLOCKING.**

### Edges

**AC-26 (Round-end force-reset — `_particleCount = 0` after Shutdown)** — GIVEN `_particleCount = 1,200` with 5 pool slots in `Cooldown` and pending unfired `task.delay` decay callbacks, WHEN `MatchStateChanged(Intermission)` then `MatchStateChanged(Active)` fire consecutively, THEN `_particleCount = 0` exactly (force-reset, independent of decay callbacks); all 5 pool slots `Idle`; any stale decay callback firing later does not make `_particleCount` negative. *Evidence: unit.* **BLOCKING.**

**AC-27 (Pool exhaustion — drop + warn-once per session)** — GIVEN all `EMITTER_POOL_SIZE = 24` slots in `Cooldown` (pool exhausted), WHEN `playEffect(AbsorbSnap, validContext)` called twice, THEN both drop silently (no pool grant, `_particleCount` unchanged); `warn()` emitted exactly once across both calls. *Evidence: unit.* **BLOCKING.**

**AC-28 (Nil crowd lookup — skip + warn-once per crowdId per round)** — GIVEN CrowdStateClient mock where `get(crowdId)` returns `nil`, WHEN `playEffect(RelicGrantVFX.Common, {crowdId})` called three times for same `crowdId`, THEN effect skipped all three times (`_particleCount` unchanged, no pool grant); `warn()` emitted exactly once. *Evidence: unit.* **BLOCKING.**

### Performance

**AC-29 (Frame budget ≤ 0.5 ms/frame on min-spec mobile — Art bible §8.10)** — GIVEN test harness firing 6 `AbsorbSnap` + 2 `ImpactBurst` + 1 `ChestOpenBurst` in single frame (worst-case mid-fight burst), WHEN measured via MicroProfiler tag `VFXManager_PlayEffect` over 60 consecutive frames, THEN tag averages ≤ 0.5 ms/frame on iPhone SE hardware.

Preconditions required before AC-29 can be run: MicroProfiler tags `VFXManager_PlayEffect`, `VFXManager_Reclaim`, `VFXManager_BudgetEnforcer` must exist in implementation (art bible §8.10 integration). Flag as FUTURE WORK until tags ship. *Evidence: integration (MicroProfiler).* **ADVISORY.**

### Dependency injection requirements

ACs above assume DI per ANATOMY.md §16 (DI over singletons). `VFXManagerClient.init(deps)` must accept:

| Dependency | Interface | Used by |
|---|---|---|
| `RunService` | `{ IsServer: () -> boolean }` | AC-1 |
| `Network` | `{ connectEvent: (name, handler) -> () }` | AC-2, AC-5, AC-6, AC-17 |
| `CrowdStateClient` | `{ get: (crowdId) -> {position, radius, count, hue}? }` | AC-10b, AC-15, AC-28, all crowdRelative ACs |
| `AssetId` registry | `{ [string]: string }` table (swappable at test setup) | AC-3 |
| `Debris` service | `{ AddItem: (part, t) -> () }` | AC-4 |
| `task.delay` (clock) | `(t: number, fn: () -> ()) -> ()` injectable | AC-11, AC-12, AC-22, AC-24, AC-26 |
| `MatchStateClient` signal | `{ subscribe: (handler) -> () }` or signal mock | AC-20, AC-21, AC-26 |
| Frame batch trigger | Injectable frame-flush function | AC-23 |
| Pool internals | White-box expose OR inject pool mock | AC-22, AC-27 |

**Lead-programmer sign-off required** on DI shape before sprint start. Consistent with `task.delay` injection pattern already used in CSM, Absorb System, Match State Machine ACs.

## Open Questions

1. **Audio Manager subscription coupling** — Does Audio Manager subscribe to VFX Manager's `VFXPlayed` broadcast signal (tight coupling, guaranteed sync) OR subscribe independently to the same 7 upstream remotes (loose coupling, risk of timing drift)? **Owner:** audio-director + lead-programmer. **Target:** Audio Manager GDD authoring (VS design phase).

2. **§8.4 Neon permit extension for VFX Parts at scale** — Art bible §8.4 permits Neon on "VFX emitters + flash disc + ability indicators + UI billboards." RelicGrantVFX Rare ring (6-stud fixed diameter) + Epic column (12-stud height, 0.5-stud diameter) are VFX Parts at a larger scale than "flash disc"; §8.4 does not explicitly cover them. **Owner:** art-director. **Target:** art bible §8.4 amendment via `/propagate-design-change` before Vertical Slice.

3. **Static chest beacon vs animated DraftOpenFX column overlap** — Chest System §6 specifies a static Neon cylinder beacon (15 studs) above each chest during `Available` state. `ChestDraftOpenFX` fires an animated 15-stud Neon cylinder at the same position. Specify: beacon hides during `DraftOpen + Opened` states, restored during `Respawning`. **Owner:** chest-system GDD + art-director. **Target:** `/propagate-design-change` pass on Chest GDD.

4. **RelicDraftPick world-space vs screen-space** — Current spec: world-space at `crowd.position`, rival-visible. Alternative: screen-space on the selected relic card (opener-only, more readable for pick confirmation). Both could coexist (screen-space confirm + world-space grant). **Owner:** ux-designer + relic-system GDD. **Target:** Relic Card UI GDD (VS scope).

5. **HueShift `crowdId` context parameter** — Follower Entity GDD §C.2 specifies `VFXManager.playEffect(VFXEffect.HueShift, entity.Body.CFrame)` without `crowdId`. Rule 14 now says VFX Manager owns no visual for HueShift, so `crowdId` is immaterial for visual grouping — but audio coordination may need it. **Owner:** audio-director when Audio Manager GDD is authored. **Target:** possibly append optional `crowdId` to signature at that time.

6. **Rare ring geometry — filled disc vs hollow annulus** — AD §8 flags: solid 6-stud disc blocks crowd silhouette at center; hollow annulus preserves silhouette but requires MeshPart import. Provisional: implement as thin flat-disc Part (1-stud thick, effectively solid at the scale). Revisit if playtest shows silhouette occlusion issue. **Owner:** art-director + technical-artist. **Target:** first playtest with Rare relic granted on a large crowd.

7. **MicroProfiler tag implementation for AC-29** — Perf acceptance criterion references tags `VFXManager_PlayEffect`, `VFXManager_Reclaim`, `VFXManager_BudgetEnforcer`. Tags not yet in codebase. **Owner:** gameplay-programmer at implementation time. **Target:** day-1 coding checklist for VFX Manager sprint.

8. **DI contract for `Network.connectEvent` mocking** — AC-6 + AC-17 assume `Network` is injectable at boot. Current Network module is template-provided and may or may not support injection wrappers cleanly. **Owner:** lead-programmer. **Target:** pre-sprint architecture review.

9. **Pool vs CFrame-reposition for emitter recycling** — TA flagged mobile re-parent artifact risk; proposed alternative is CFrame-reposition a persistent emitter Part rather than re-parent. **Owner:** technical-artist + gameplay-programmer. **Target:** prototype-before-ship task (1 sprint budget).

10. **Scene-count estimator drift validation** — F1 is a conservative estimator, not a live count. At steady state it should match Roblox's internal count within ±5%; needs validation on real hardware before relying on 1,800 threshold for production. **Owner:** technical-artist. **Target:** prototype-before-ship task.
