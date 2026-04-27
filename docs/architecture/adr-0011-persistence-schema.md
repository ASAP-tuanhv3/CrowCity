# ADR-0011: Persistence Schema + Pillar 3 Exclusions

## Status

**Accepted 2026-04-27** (closes ~5 gap TRs from `/architecture-review` 2026-04-26; no remaining amendment dependencies; game-concept Pillar 3+4 + ADR-0001/0004/0005/0006 all aligned with this ADR's schema lock).

Status history:
- 2026-04-26 — Proposed (initial)
- **2026-04-27 — ACCEPTED** (must-have ADR set complete: 0001/0002/0003/0004/0005/0006/0008/0010/0011; stories may now reference this ADR per `/story-readiness`)

## Date

2026-04-26 (initial Proposed), 2026-04-27 (Accepted)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Persistence + Core (player data lifecycle + cross-server identity) |
| **Knowledge Risk** | LOW — ProfileStore vendored at `src/ReplicatedStorage/Dependencies/ProfileStore.luau`; session-lock + BindToClose + retry stable; `DataStoreService` semantics predate LLM cutoff and are wrapped exclusively |
| **References Consulted** | `docs/engine-reference/roblox/profilestore-reference.md`, `docs/engine-reference/roblox/VERSION.md`, ADR-0001 §Constraints (no per-follower persistence — Pillar 3), ADR-0004 §Permitted Cosmetic Data Flow + §Pillar 4 Anti-P2W Invariant, ADR-0005 §Round-End Ordering Invariants T9 (clean-wipe; no per-round persistence), ADR-0006 §Source Tree Map (`PlayerDataServer` server-only + `PlayerDataClient` shared) + §Forbidden Patterns Matrix (`Direct DataStoreService calls`), `design/gdd/game-concept.md` Pillar 3 (5-Min Clean Rounds) + Pillar 4 (Cosmetic Expression) + anti-pillar L179 ("NOT pay-to-win"), `CLAUDE.md` §Player data flow + §Currency, `ANATOMY.md` §7 Player data system |
| **Post-Cutoff APIs Used** | None — ProfileStore is vendored; uses standard `DataStoreService` underneath |
| **Verification Required** | (A) Persistence audit at first MVP integration — `grep -r "DataStoreService" src/` returns zero matches outside `ReplicatedStorage/Dependencies/ProfileStore.luau`; (B) Per-round state audit — no key in `PlayerDataKey.luau` or `DefaultPlayerData.luau` matches the §Pillar 3 Forbidden Keys catalog; (C) Schema migration test — fixture profile at older `_schemaVersion` upgrades cleanly via `PlayerDataServer/migrations/` handlers; (D) BindToClose flush — ProfileStore platform 30 s grace handles in-flight saves on shutdown without data loss |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (Pillar 3 no-per-follower-persistence rule established), ADR-0004 (Pillar 4 anti-P2W invariant + cosmetic data flow established), ADR-0005 (clean-wipe at T9 — round state ephemeral), ADR-0006 (`Direct DataStoreService calls` forbidden + `Source Tree Map` placement) |
| **Enables** | Currency System implementation (Coins persistence + grant flow); Skin System implementation (VS+ — OwnedSkins / SelectedSkin); Daily Quest System (Alpha+ — DailyQuestState); Shop System (Alpha+ — Robux receipts via ReceiptProcessor); FTUE persistence (FtueStage already template-provided); analytics stubs (LifetimeAbsorbs / LifetimeWins for retention dashboards) |
| **Blocks** | Currency grant story; Skin System story; any system claiming a new PlayerDataKey; Pillar 3 / Pillar 4 audit at `/gate-check pre-production` |
| **Ordering Note** | Should be Accepted before `/create-control-manifest` (manifest extracts §PlayerDataKey schema + §Pillar 3 Forbidden Keys verbatim). No GDD amendment dependencies. Currency / Skin / Daily Quest GDDs (when authored) MUST cite this ADR for PlayerDataKey + persistence rules. |

## Context

### Problem Statement

Crowdsmith uses ProfileStore (vendored) for all player-data persistence; the template ships with `PlayerDataServer` / `PlayerDataClient` / `DefaultPlayerData` and a working `ReceiptProcessor` for Robux dev products. ADR-0001 established Pillar 3 (no per-follower persistence). ADR-0004 §Permitted Cosmetic Data Flow established the read path for skins. ADR-0005 §Round-End Ordering Invariants established clean-wipe semantics. ADR-0006 §Forbidden Patterns Matrix banned direct `DataStoreService` calls. **But no ADR locks the schema**:

1. **PlayerDataKey enum unowned at ADR level** — keys exist in `SharedConstants/PlayerDataKey.luau` (template default) but no ADR enumerates the MVP + VS+ + Alpha+ scope. Future story authors may add keys ad-hoc without checking Pillar 3/4 alignment.
2. **Pillar 3 forbidden-key catalog implicit** — the rule "no per-round state in ProfileStore" is repeated across ADR-0001/0004/0005 but no list spells out *what* is forbidden. A story author migrating relic state to ProfileStore for "QoL" would technically not violate any specific Accepted-ADR clause without a forbidden-list.
3. **Schema migration policy missing** — ProfileStore exposes `OnProfileVersionUpgrade` but no project policy on when to bump version, where migration handlers live, or how to validate.
4. **Default template ownership scattered** — `DefaultPlayerData.luau` is the sole source of truth, but no ADR locks it; a Story author might reasonably fork defaults inline (e.g. `PlayerDataServer.updateValue(player, MyKey, function(c) return c or 0 end)` defaults bleed across modules).
5. **Pillar 4 boundary at persistence layer unspecified** — ADR-0004 §Pillar 4 forbids cosmetic-system CSM mutations; an extension is needed: persisted keys must not affect gameplay outcome. Without lock, a key like `OwnedAbsorbBonusMultiplier` would technically pass Accepted-ADR scrutiny.
6. **Receipt-processing flow unowned at ADR level** — `ReceiptProcessor` template handles `ProcessReceipt` callback; dev products registered in `Utility/registerDevProducts.luau`; save-before-confirm guarantees in template; no ADR locks the boundary.
7. **Currency-grant timing dependency on T9** — ADR-0005 §Result-entry ordering specifies grant-before-broadcast; this ADR must confirm where Coins live (PlayerData) and that grants are server-only.
8. **`/gate-check pre-production`** — needs a single source for the persistence policy to verify.
9. **Stories blocked** — `/create-stories` for Currency grant, Skin System, Daily Quest, future Shop cannot embed an ADR ref for "what may persist + how"; `/story-readiness` rejects.

### Constraints

- **ProfileStore is vendored** — `src/ReplicatedStorage/Dependencies/ProfileStore.luau` is the wrapper for `DataStoreService`. Updates are manual per ADR-0006 §Vendored vs Wally Policy.
- **Session lock** — ProfileStore guarantees one server holds a profile at a time; rejoin elsewhere waits for lock release. Cross-server identity is ProfileStore's responsibility.
- **`BindToClose` 30 s grace** — Roblox platform; ProfileStore registers its own `BindToClose` for save-on-shutdown with retry. Per ADR-0005, no mid-round currency grant on shutdown.
- **Pillar 3 (5-Min Clean Rounds)** — no per-round state persists; round-scoped state lives entirely in CSM / RoundLifecycle / MSM / Chest / Relic / NPCSpawner in-memory tables, cleared at T9.
- **Pillar 4 (Cosmetic Expression + anti-pay-to-win)** — only cosmetic + lifetime-statistic keys may persist. Anything that gates gameplay outcome (count, radius, draw-power, draft-rarity-weights, etc.) is forbidden as a persisted key.
- **Network wrapper required** — `PlayerDataUpdated` reliable RemoteEvent fires on server mutation; client reads via `PlayerDataClient.getValue`. Direct `DataStoreService` on client impossible by Roblox semantics; ADR-0006 forbids on server.
- **MVP scope is narrow** — Coins (soft currency) + OwnedSkins + SelectedSkin + LifetimeAbsorbs + LifetimeWins + FtueStage. Six keys.
- **VS+ adds** — DailyQuestState + LastDailyResetTime (when Daily Quest System lands).
- **Alpha+ adds** — analytics opt-in flags + accessibility settings (when those systems land).
- **Schema versioning** — `_schemaVersion` field at top of every profile; migrations under `src/ServerStorage/Source/PlayerDataServer/migrations/`; ProfileStore `OnProfileVersionUpgrade` callback dispatches.

### Requirements

- Lock **MVP PlayerDataKey schema** — exactly 6 keys for MVP launch
- Lock **VS+ keys + Alpha+ keys** — extension scope per phase
- Lock **Pillar 3 Forbidden Keys** — explicit catalog of what may NOT persist
- Lock **Pillar 4 anti-P2W persistence boundary** — persisted keys must not affect gameplay outcome
- Lock **ProfileStore-only rule** — every persistent write goes through `PlayerDataServer.updateValue` → ProfileStore; reinforces ADR-0006 ban on direct `DataStoreService`
- Lock **schema versioning + migration policy** — `_schemaVersion` field; migrations dir; bump rules
- Lock **default template ownership** — `src/ServerStorage/Source/DefaultPlayerData.luau` is sole source of defaults
- Lock **read-write split** — `PlayerDataServer.updateValue` server-only; `PlayerDataClient.getValue` read-only cache via `PlayerDataUpdated`
- Lock **receipt-processing flow** — Robux dev products via `Utility/registerDevProducts.luau` + `ReceiptProcessor` template; save-before-confirm guarantees
- Lock **no cross-server state via MessagingService** — ProfileStore session lock is the sole cross-server mechanism for player data
- Lock **currency authority** — Coins balance is ProfileStore-persisted; mutations via `PlayerDataServer.updateValue(player, PlayerDataKey.Coins, fn)`; client cache via `PlayerDataClient`
- Define **enforcement layers** — module placement (L1) + code review (L2) + control manifest (L3) + architecture review (L4) + story readiness (L5) + pre-production gate-check (L6)
- Surface **forbidden patterns** — persisting per-round state; persisting Pillar-4-violating keys; adding keys to enum without defaults; schema bumps without migration handler; client-side data mutation; ReceiptProcessor bypass; cross-server state via MessagingService

## Decision

**`PlayerDataServer` (server-only at `ServerStorage/Source/PlayerDataServer.luau`, template-provided) wrapping vendored `ProfileStore` is the sole persistence authority. All persistent writes flow `client → remote → server validate → PlayerDataServer.updateValue → ProfileStore → PlayerDataUpdated reliable → client cache refresh`. The MVP schema has exactly 6 keys (`Coins`, `OwnedSkins`, `SelectedSkin`, `LifetimeAbsorbs`, `LifetimeWins`, `FtueStage`) plus `_schemaVersion`. VS+ adds 2 keys; Alpha+ adds 2-4 keys; the schema is otherwise frozen. Pillar 3 Forbidden Keys are an explicit catalog — round-scope state never persists, not even as a "QoL convenience". Pillar 4 boundary: every persisted key is either cosmetic, lifetime-statistic, or FTUE-progress; no key may affect gameplay outcome. Schema migrations go through ProfileStore `OnProfileVersionUpgrade` with handlers under `PlayerDataServer/migrations/`; bumps are versioned and reviewed.**

### MVP PlayerDataKey Schema (LOCKED — 6 keys + 1 meta)

| Key | Type | Default | Pillar | Mutator | Purpose |
|---|---|---|---|---|---|
| `_schemaVersion` | number | 1 | meta | `PlayerDataServer/migrations/` | Schema version for migration dispatch |
| `Coins` | number | 0 | 4 (cosmetic-economy) | `PlayerDataServer.updateValue` ← `Currency.grantMatchRewards(placements)` (MSM Result entry); `Market` purchase deduction | Soft currency; spent on cosmetic skins |
| `OwnedSkins` | `{ [skinId: string]: true }` | `{}` | 4 (cosmetic) | `Market` purchase callback; `ReceiptProcessor` Robux callback | Set of owned skin IDs |
| `SelectedSkin` | string? | `"Default"` | 4 (cosmetic) | client request → server validate ownership → `PlayerDataServer.updateValue` | Currently equipped skin |
| `LifetimeAbsorbs` | number | 0 | analytics (lifetime stat) | server increments per absorb (rate-limited; aggregated per round at T6/T7/T8) | Cumulative absorb count for retention dashboards |
| `LifetimeWins` | number | 0 | analytics (lifetime stat) | server increments at T6/T7/T8 if `_winnerId == player.crowdId` | Cumulative round wins |
| `FtueStage` | string | `"Stage1"` | onboarding | `FtueManagerServer/StageHandlers/` per stage advance | First-time-user-experience progress (template-provided) |

**Defaults source**: `src/ServerStorage/Source/DefaultPlayerData.luau` (template-provided; this ADR locks the contents). Reconciliation auto-fills missing keys on profile load.

### VS+ Schema Additions (LOCKED — 2 keys; lands when Daily Quest System lands)

| Key | Type | Default | Pillar | Mutator | Purpose |
|---|---|---|---|---|---|
| `DailyQuestState` | `{ questId: string, progress: number, completedAt: number? }?` | `nil` | 4 (cosmetic-tied progression — rewards Coins) | `DailyQuestSystem` server-side | Today's quest |
| `LastDailyResetTime` | number? | `nil` | 4 | server-side reset check | Unix timestamp of last quest reset |

**Bump path**: when Daily Quest System lands, increment `_schemaVersion` 1 → 2; add migration handler that initializes both keys to nil for existing profiles.

### Alpha+ Schema Additions (PRELIMINARY — exact key list locks when Analytics + Settings GDDs land)

| Key (preliminary) | Type | Default | Purpose |
|---|---|---|---|
| `AnalyticsOptIn` | boolean | true | GDPR-friendly opt-out flag |
| `AccessibilitySettings` | `{ [string]: any }` | `{}` | Color-blind mode, text scale, subtitle prefs |
| `LastShopRefreshTime` | number? | nil | Shop rotation cache key |

**Authorisation note**: this section is preliminary; final Alpha+ keys land in their respective system ADRs. ADR-0011 amendment required at that time.

### Pillar 3 Forbidden Keys (LOCKED — never persist)

The following state classes MUST NOT appear in `PlayerDataKey.luau` or `DefaultPlayerData.luau` at any phase:

| Forbidden Key Class | Examples | Why forbidden |
|---|---|---|
| **Per-round crowd state** | `CurrentCount`, `CurrentRadius`, `CurrentHue`, `CurrentPosition`, `ActiveCrowdId` | Pillar 3 — round-scope; CSM in-memory at `_crowds` table; cleared at T9 |
| **Per-round relic inventory** | `OwnedRelics`, `ActiveRelics`, `RelicHistory` | Pillar 3 — relics are round-scoped; CSM `activeRelics` field cleared at T9 |
| **Per-round chest state** | `OpenedChestIds`, `ChestCooldowns`, `LastChestOpenTime` | Pillar 3 — Chest System `_chests` cleared at T9 |
| **Per-round elimination state** | `EliminationCount`, `LastEliminationTime`, `IsEliminated` | Pillar 3 — RoundLifecycle `eliminationTime` cleared at T9 |
| **Per-round peak/placement** | `PeakCount`, `BestPlacement`, `LastPlacement` | Pillar 3 — RoundLifecycle `peakCount` cleared at T9 (analytics aggregation goes via `LifetimeAbsorbs`/`LifetimeWins` lifetime-stat keys instead) |
| **In-flight VFX state** | `LastVfxId`, `ActiveParticleCount` | Pillar 3 — VFXManager `_particleCount` reset at Intermission |
| **NPC pool state** | `OwnedNpcs`, `NpcKills`, `NpcRespawnTimers` | Pillar 3 — NPCSpawner `_activeNpcs` cleared at T9 (round) or per-respawn (lifecycle) |
| **MSM state mirror** | `LastMatchState`, `LastMatchEndTime`, `ParticipationFlag` | Pillar 3 — MSM `_state` is server-side authoritative; clients receive via `MatchStateChanged` reliable, no persistence |
| **Pillar-4-violating gameplay modifiers** | `OwnedAbsorbBonusMultiplier`, `BoughtRadiusBoost`, `RareDraftRollChance` | Pillar 4 — gameplay outcome must not be purchasable/persistable |
| **Cross-player social state** | `Friends`, `BlockedPlayers`, `Mailbox` | Out of scope MVP; future may add but distinct ADR required |
| **Round-state replay buffers** | `LastRoundReplay`, `MatchHistoryDetails` | Out of scope; bandwidth + storage cost unjustified |

**Enforcement**: any PR adding a key that semantically maps to one of these classes is a code-review reject. `/architecture-review` cross-checks new keys against this catalog.

### Pillar 4 Anti-P2W Persistence Boundary (LOCKED)

Every persisted key MUST fit one of three categories:

1. **Cosmetic** — Skins, banners, trails, avatars (visual identity only; no gameplay effect)
2. **Lifetime statistic** — Aggregated cumulative count not affecting current-round outcome (`LifetimeAbsorbs`, `LifetimeWins`); used for retention dashboards + future progression-titles
3. **Onboarding/meta** — FtueStage (template), `_schemaVersion`, `AnalyticsOptIn`

**Forbidden categories**:
- Power modifiers (radius bonus, count multiplier, faster absorb, slower decay)
- Round-affecting consumables (one-shot speed boost, free-relic-draft, skip-toll)
- Persistent currency types beyond Coins/Robux that gate gameplay (e.g. "PrestigePoints" that unlock relic-rarity tiers)

**Why architectural-level**: Pillar 4 + the anti-pillar at `game-concept.md:179` ("NOT pay-to-win") is project identity. Any future feature proposing a persisted gameplay modifier requires superseding this ADR + creative-director sign-off + Pillar 4 amendment review.

### Persistence Flow (LOCKED — per CLAUDE.md §Player data flow)

```text
client                              wire                        server                    persistence
─────────────────────────────────────────────────────────────────────────────────────────────────────
(client wants to change own data)
  Network.fireServer(EquipSkin,
    {skinId="Tiger"})
                              ──RemoteEvent──►
                                                          RemoteValidator 4-check
                                                            (ADR-0010)
                                                          PlayerDataServer.updateValue(
                                                            player, SelectedSkin,
                                                            function(current)
                                                              if not OwnedSkins[skinId]
                                                                then return current end
                                                              return skinId
                                                            end)
                                                                                  ──update──►  ProfileStore
                                                                                                  (auto save)
                                                                                  ◄──ack───
                                                          Network.fireClient(player,
                                                            PlayerDataUpdated,
                                                            {SelectedSkin = "Tiger"})
                              ◄──RemoteEvent reliable──
PlayerDataClient cache update
  fires local PlayerDataUpdated
    ├─► UI re-renders
    └─► FollowerEntity reads
        OwnedSkins/SelectedSkin
        for visual swap
        (per ADR-0004 §Permitted
        cosmetic data flow)
```

**Invariant**: client never writes to `PlayerDataClient` cache directly. Every mutation flows through server. Client cache is read-only via `PlayerDataClient.getValue` + `PlayerDataUpdated:Connect` for change notifications.

### Currency Authority (LOCKED — extends template)

| Currency | Storage | Mutator | Grant trigger | Spend trigger |
|---|---|---|---|---|
| **Coins (soft)** | `PlayerDataKey.Coins` | `PlayerDataServer.updateValue` (server-only) | `Currency.grantMatchRewards(placements)` at MSM Result entry per ADR-0005 §Result-entry ordering | `Market` module purchase callback (cosmetic skins) |
| **Robux (hard)** | Roblox platform; `ReceiptProcessor` callback | Roblox `ProcessReceipt` callback handler | Player buys dev product → `ReceiptProcessor` validates → grants Coins or Skin via `PlayerDataServer.updateValue` | Roblox handles purchase flow; project handles fulfilment |

**Forbidden**: Coin grant mid-round (anti-exploit per MSM AC-perf + Pillar 3); Coin grant by client request (server is sole authority); bypassing `Market` for purchases (would skip ownership checks); bypassing `ReceiptProcessor` for Robux (would break duplicate-prevention).

### Schema Migration Policy (LOCKED)

**When to bump `_schemaVersion`**:
- Any field shape change (type change, key rename)
- Field deletion (default-template no longer reconciles)
- New required field that needs computation from existing data

**When NOT to bump**:
- New optional field with default value (ProfileStore reconciliation auto-fills)
- New cosmetic enum value (e.g. new SkinId added to `OwnedSkins` semantics)

**Migration procedure**:
1. Increment `_schemaVersion` constant in `SharedConstants/PlayerDataKey.luau`
2. Add migration handler at `src/ServerStorage/Source/PlayerDataServer/migrations/v[N]_to_v[N+1].luau`
3. Register handler in `PlayerDataServer.init` via `ProfileStore:OnProfileVersionUpgrade(N, handler)`
4. Handler signature: `function(profile: ProfileStore.Profile, oldVersion: number) → ()` — mutates `profile.Data` in place; ProfileStore writes back atomically
5. Test fixture: snapshot of older profile JSON; assert post-migration shape matches current default
6. Code-review: every schema-bump PR includes migration handler + test fixture

**Forbidden**: schema bump without migration handler (would crash on legacy profile load); migration handler that deletes player-owned data (e.g. wiping `OwnedSkins`) — additive migrations only.

### Default Template Ownership

`src/ServerStorage/Source/DefaultPlayerData.luau` is the **sole** source of defaults. ProfileStore's reconciliation reads from this template on profile load.

**Forbidden**:
- Inline defaults in mutator callbacks (`function(current) return current or 0 end` — masks missing keys; pre-empts reconciliation)
- Per-system "default override" tables (creates drift between modules)
- Adding a key to `PlayerDataKey.luau` without a corresponding `DefaultPlayerData.luau` entry (profile load fails reconciliation gracefully but new key is `nil` for existing players forever — dangerous)

### Defense-in-Depth Enforcement Layers

| Layer | Mechanism | What it catches |
|---|---|---|
| **L1** Module placement (Roblox engine) | `PlayerDataServer` is server-only; `PlayerDataClient` cache is read-only | Client-side persistence mutation (impossible by engine semantics); direct DataStore access from client (impossible) |
| **L2** Code review | PR reviewer checks every persistence change against §MVP Schema + §Pillar 3 Forbidden Keys + §Pillar 4 Boundary | Schema drift, forbidden-key additions, inline defaults, missing migration handlers |
| **L3** Control manifest | `/create-control-manifest` extracts §Schema + §Forbidden Keys + §Pillar 4 Boundary verbatim | Daily implementation reference; reduces L2 reviewer load |
| **L4** Architecture review | `/architecture-review` cross-checks new ADR/GDD persistence claims against this ADR's schema | Future systems silently adding forbidden keys |
| **L5** Story readiness | `/story-readiness` validates story embeds correct PlayerDataKey + Pillar-3/4 alignment | Story-level violations before code |
| **L6** Pre-production gate-check | `/gate-check pre-production` audits persistence layer against this ADR | Final pre-launch verification |

## Alternatives Considered

### Alternative 1: No schema lock — keys evolve ad-hoc per story

- **Description**: Keep template-provided template; story authors add keys to `PlayerDataKey.luau` + `DefaultPlayerData.luau` as needed; no ADR enumerates the schema.
- **Pros**: Zero ADR overhead. Schema flexibility for emergent needs.
- **Cons**: No Pillar 3 / Pillar 4 enforcement at architectural level. Story authors must independently judge whether a key is forbidden — drift compounds. `/architecture-review` cannot detect schema violations. Future Daily Quest / Skin / Shop authors have no canonical reference for "what may persist". Schema migrations land randomly. Pillar 4 anti-P2W posture relies on story author discipline.
- **Rejection Reason**: Pillar 3 + Pillar 4 are project-identity invariants; they deserve architectural-level enforcement. Schema flexibility is valuable but not at the cost of allowing forbidden keys to slip in.

### Alternative 2: Centralised mutation broker (single API for all persistence writes)

- **Description**: `PlayerDataBroker` module proxies all `PlayerDataServer.updateValue` calls; broker validates each mutation against a runtime allowlist.
- **Pros**: Hard runtime enforcement of allowlist.
- **Cons**: Adds runtime cost per mutation (allowlist check). Duplicates ProfileStore + `PlayerDataServer` template. Allowlist still needs a source-of-truth — that source is exactly this ADR's schema. Broker is a code-style choice; the architectural lock is the schema, not the broker.
- **Rejection Reason**: Schema lock is the architectural decision. A broker can be added at implementation time if desired; it doesn't replace the ADR.

### Alternative 3: Versioning per-key instead of profile-level `_schemaVersion`

- **Description**: Each persistent key has its own `_keyVersions` map; migrations target individual keys.
- **Pros**: Smaller migrations; key-scoped versioning reduces "all-at-once" upgrade risk.
- **Cons**: ProfileStore's `OnProfileVersionUpgrade` is profile-level; mismatching with per-key versioning duplicates ProfileStore's mechanism. Per-key versioning makes "what schema is this profile?" ambiguous — debugging is harder. Industry standard is profile-level versioning.
- **Rejection Reason**: ProfileStore already provides profile-level versioning; matching the underlying tool's model is simpler. Migrations at MVP scope (6 keys) are small enough that profile-level bumps don't bottleneck.

### Alternative 4: No Pillar 3 Forbidden Keys catalog — rely on Pillar 3 verbal rule

- **Description**: Keep "no per-round state in ProfileStore" as a verbal rule; trust reviewers to spot violations.
- **Pros**: Less ADR text.
- **Cons**: Verbal rules are interpretation-prone. A story author may genuinely believe "ChestCooldowns persisted to ProfileStore = QoL improvement" without realising it leaks round-scope state into player profile (and worse, allows Pillar 4 violation if cooldowns differ per skin tier). Explicit catalog removes interpretation room.
- **Rejection Reason**: Catalog is small (10 forbidden classes); cost-of-listing is low; benefit of explicitness is high.

## Consequences

### Positive

- ADR-level lock on PlayerDataKey schema — closes ~5 gap TRs; unblocks Currency / Skin / Daily Quest / Shop stories
- Pillar 3 + Pillar 4 anti-P2W invariants gain persistence-layer enforcement
- `/create-control-manifest` has single canonical source for schema + forbidden keys
- `/architecture-review` cross-checks new ADRs/GDDs persistence claims against this catalog
- Schema migration policy explicit — bump procedure + handler placement + test-fixture rule
- Currency authority confirmed at architectural level — Coins are server-only, grant flow locked at Result entry per ADR-0005
- Receipt-processing flow confirmed — Robux dev products via `ReceiptProcessor` template; no bypass

### Negative

- Schema lock reduces flexibility — adding keys outside MVP/VS+/Alpha+ phases requires ADR amendment
- Documentation surface grows — schema + forbidden keys + migration policy + Pillar 4 boundary = 4 sections to maintain
- Future feature requests for "persistent power" (e.g. seasonal-event temporary buffs) must propose superseding ADR + creative-director review — high friction is intentional
- Migration handler authoring + testing per schema bump adds cost
- Inline default audit at code review — every PR checked for the inline-default anti-pattern

### Risks

- **Risk 1 (LOW)** — Schema migration handler bug breaks existing profiles. Mitigation: every schema bump PR requires fixture-based test; ProfileStore handles per-profile retry on failure (data isn't lost, just refused to load).
- **Risk 2 (MEDIUM)** — Future feature legitimately needs persistent gameplay state (e.g. "permanent cosmetic-tied progression that unlocks new skins through gameplay"). Mitigation: distinguish carefully — unlocking a skin via in-game achievement IS Pillar-4-compatible (cosmetic outcome); progression that unlocks gameplay power is forbidden. Boundary cases require creative-director sign-off + ADR-0011 amendment.
- **Risk 3 (LOW)** — `LifetimeAbsorbs` / `LifetimeWins` increment cost — server-side increment per absorb (60+/min/player at peak) × 12 players × 5-min round = ~3,600 mutations per round. Mitigation: aggregate lifetime stats per round; increment once at MSM Result entry alongside currency grant (single mutation per round per player).
- **Risk 4 (LOW)** — `_schemaVersion` rollback impossible (ProfileStore is forward-only). Mitigation: schema bumps are reviewed; downgrade scenario forbidden by ProfileStore architecture; if a bump breaks, fix-forward via subsequent bump (e.g. 2 → 3 with corrective handler).
- **Risk 5 (LOW)** — ProfileStore session lock latency on cross-server moves (player teleports to another instance during active session). Mitigation: ProfileStore handles via session-lock release with retry; mid-round teleport is not an MVP feature; deferred to post-MVP.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/game-concept.md` Pillar 3 | "5-Min Clean Rounds — no persistent power" | §Pillar 3 Forbidden Keys catalogues 10 forbidden state classes |
| `design/gdd/game-concept.md` Pillar 4 | "Cosmetic Expression — skins persist, no power" | §Pillar 4 Anti-P2W Persistence Boundary locks 3 allowed categories + forbidden-categories list |
| `design/gdd/game-concept.md:179` anti-pillar | "NOT pay-to-win" | §Pillar 4 Persistence Boundary architectural-level lock |
| `design/gdd/game-concept.md` Technical Considerations | "ProfileStore persistence (meta only)" | §MVP Schema 6 keys + §Pillar 3 Forbidden Keys |
| ADR-0001 §Constraints | "Must not require per-follower persistence (Pillar 3)" | §Pillar 3 Forbidden Keys row "NPC pool state" + "Per-round crowd state" |
| ADR-0001 §Consequences §Positive | "Follower identity is cosmetic only; no individual follower state persists" | §Persistence Flow + §MVP Schema |
| ADR-0004 §Permitted Cosmetic Data Flow | "Player buys Skin → PlayerData (Coins-deducted, OwnedSkins added) → SkinChanged → client visual swap" | §Persistence Flow + §MVP Schema confirms |
| ADR-0004 §Pillar 4 Anti-P2W Invariant | "Cosmetic systems FORBIDDEN as CSM write callers" | §Pillar 4 Persistence Boundary extends: cosmetic-tied keys must not be gameplay-affecting |
| ADR-0005 §Round-End Ordering Invariants T9 | "destroyAll → clearAll → broadcast" (clean-wipe) | §Pillar 3 Forbidden Keys confirms round-state never persists; T9 cleanup is in-memory only |
| ADR-0005 §Result-Entry Ordering | "grantMatchRewards before broadcast" | §Currency Authority Coins grant trigger = MSM Result entry |
| ADR-0005 §BindToClose | "30 s grace + no partial currency grant" | §Currency Authority forbids mid-round Coin grant; §Risks Risk 5 ProfileStore session-lock |
| ADR-0006 §Forbidden Patterns Matrix | "Direct DataStoreService calls" | §Persistence Flow confirms; §Forbidden Patterns this ADR adds reinforcing entries |
| ADR-0006 §Source Tree Map | "Vendored: ProfileStore at src/ReplicatedStorage/Dependencies/" + "Server-only: PlayerDataServer" | §Decision module placement confirmed |
| ADR-0010 §Identity Trust Model | "Engine-set player only; payload userId NEVER trusted" | §Persistence Flow: server reads player from RemoteEvent arg, derives crowdId/userId server-side |
| ADR-0010 §4-Check Guard Pattern | "Mandatory on every client→server handler" | §Persistence Flow: client-initiated PlayerData mutations (e.g. EquipSkin) go through 4-check before `PlayerDataServer.updateValue` |
| `CLAUDE.md` §Player data flow | "client fires Network.fireServer → server validates → PlayerDataServer.updateValue → ProfileStore → PlayerDataUpdated → client cache refresh" | §Persistence Flow architectural lock |
| `CLAUDE.md` §Currency | "Soft (Coins): PlayerDataServer.updateValue. Hard (Robux): dev products + ReceiptProcessor" | §Currency Authority confirms |
| `ANATOMY.md` §7 | "Session-locked player data persistence (ProfileStore)" | §Decision + §Schema Migration Policy |
| `ANATOMY.md` §10 | "Market & economy" | §Currency Authority Robux row + §Persistence Flow |
| `ANATOMY.md` §13 | "Analytics system" | §MVP Schema LifetimeAbsorbs / LifetimeWins as analytics-feeder lifetime stats |

## Performance Implications

- **CPU (server)**: per-mutation `updateValue` ~50 µs (function call + closure invocation + ProfileStore queue). Aggregate stat increment at Result entry (12 players × 1 mutation) = trivial. No per-tick persistence work.
- **CPU (client)**: zero — PlayerData reads are O(1) table lookups in client cache.
- **Memory (server)**: per-profile ~1 KB × 12 active players = 12 KB (per ADR-0003 §Server Memory ProfileStore row). Trivial.
- **Memory (client)**: cache mirror ~1 KB per local player.
- **Load Time**: `loadProfileAsync` per `PlayerAdded` ~200-1000 ms (DataStore round-trip); player can play once profile loads. Within Roblox baseline expectations.
- **Network**: `PlayerDataUpdated` reliable RemoteEvent fires on mutation; per ADR-0003 §Network table row 0.2 KB/s/client (Currency grant at Result only).

## Migration Plan

Project is at pre-production stage; template ships with `Coins` + `OwnedSkins` + `SelectedSkin` + `FtueStage` already in `DefaultPlayerData.luau`. This ADR locks the schema as MVP-final + adds 2 lifetime-stat keys.

1. **Audit existing template** — `DefaultPlayerData.luau` should already have 4 of 6 MVP keys (Coins, OwnedSkins, SelectedSkin, FtueStage). Add `LifetimeAbsorbs = 0` + `LifetimeWins = 0` + `_schemaVersion = 1`.
2. **PlayerDataKey enum sync** — verify `SharedConstants/PlayerDataKey.luau` lists all 6 keys + `_schemaVersion`.
3. **Migration handlers dir** — create `src/ServerStorage/Source/PlayerDataServer/migrations/` (empty for v1 baseline).
4. **Pillar 3 audit** — `grep -r "PlayerDataServer.updateValue" src/` confirms no key in §Forbidden Keys catalog is being written.
5. **Currency grant integration** — Currency System (when authored) calls `Currency.grantMatchRewards(placements)` at MSM Result entry per ADR-0005; under the hood, `PlayerDataServer.updateValue(player, PlayerDataKey.Coins, fn)` per placement.
6. **Code-review template** — add "Verify ADR-0011 schema + Pillar 3/4 alignment" checklist item for any persistence PR.
7. **`/create-control-manifest`** extracts §Schema + §Forbidden Keys + §Pillar 4 Boundary verbatim.

## Validation Criteria

- [ ] `grep -rE "DataStoreService" src/` returns matches only inside `src/ReplicatedStorage/Dependencies/ProfileStore.luau` (vendored) — confirms ADR-0006 ban + this ADR's ProfileStore-only rule
- [ ] `grep -rE "PlayerDataServer\\.updateValue" src/` — every match writes to a key listed in §MVP Schema or §VS+ Schema; zero matches write to a §Pillar 3 Forbidden Key
- [ ] `DefaultPlayerData.luau` contents match §MVP Schema 6 keys + `_schemaVersion = 1` exactly; no extra keys
- [ ] `SharedConstants/PlayerDataKey.luau` lists exactly the keys in §MVP Schema (+ VS+/Alpha+ keys gated behind their respective phases when those land)
- [ ] No inline defaults: `grep -rE "function\\(current\\) return current or" src/` returns zero matches (or only justified cases with code-review approval comment)
- [ ] Migration test: fixture profile at `_schemaVersion = 0` (legacy) loads and upgrades to v1 cleanly via `OnProfileVersionUpgrade` handler
- [ ] Currency-grant audit: `Currency.grantMatchRewards` called only at MSM Result entry (per ADR-0005); never during round
- [ ] Receipt-processing audit: every Robux purchase routes through `ReceiptProcessor` template; no direct `MarketplaceService:ProcessReceipt` overrides outside that module
- [ ] Pillar 4 audit: every persisted key is cosmetic / lifetime-stat / onboarding category; no gameplay-modifier key
- [ ] No MessagingService usage for player data: `grep -rE "MessagingService" src/` returns zero matches (or only justified non-player-data uses)

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — Pillar 3 no-per-follower-persistence rule established
- **ADR-0004** CSM Authority — Pillar 4 anti-P2W invariant + cosmetic data flow established
- **ADR-0005** MSM/RoundLifecycle Split — clean-wipe T9 + Result-entry ordering for Coin grant
- **ADR-0006** Module Placement Rules — `Direct DataStoreService calls` already forbidden + Source Tree Map placement
- **ADR-0010** Server-Authoritative Validation — client→server PlayerData mutation requests go through 4-check pattern + RemoteValidator
- **Expected downstream**:
  - Future Currency System ADR — `Currency.grantMatchRewards(placements)` signature + Coin grant flow per this ADR's §Currency Authority
  - Future Skin System ADR (VS+) — `OwnedSkins` write path via `Market` purchase callback + `ReceiptProcessor` Robux callback
  - Future Daily Quest System ADR (Alpha+) — `DailyQuestState` + `LastDailyResetTime` schema bump (v1 → v2) + migration handler
  - Future Shop System ADR (Alpha+) — Robux dev product registration in `Utility/registerDevProducts.luau`
  - Future Settings System ADR (Alpha+) — `AccessibilitySettings` + `AnalyticsOptIn` schema bump

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). ProfileStore is vendored + extensively documented in creator forum; `DataStoreService` semantics + `BindToClose` are stable Roblox primitives predating LLM cutoff.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
