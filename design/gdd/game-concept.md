# Game Concept: Crowdsmith

*Created: 2026-04-20*
*Status: Draft*

---

## Elevator Pitch

> It's a 5-minute Roblox multiplayer arena where you absorb neutral citizens to grow your crowd, pay follower tolls at scaling chest tiers (small chest → car → building) to draft run-modifying relics, and crush smaller rival crowds — last crowd standing wins.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Hypercasual .io arena + roguelike relic-draft hybrid |
| **Platform** | Roblox (cross-platform: PC, mobile, console) |
| **Target Audience** | See Player Profile section below |
| **Player Count** | Multiplayer (8-12 per server) |
| **Session Length** | 5-minute rounds; 15-30 minute sessions typical |
| **Monetization** | F2P with cosmetic-only shop (skins) + Robux premium currency |
| **Estimated Scope** | Medium (5-6 months, solo) |
| **Comparable Titles** | Crowd City (Voodoo), Paper.io 2, agar.io, Brawl Stars (meta loop) |

---

## Core Fantasy

You are the spark of an unstoppable tide. One citizen becomes ten, ten becomes a hundred, a hundred becomes a flood that swallows rivals whole. The fantasy is **domination through growth** — pure snowball catharsis where every absorption is audible, visible, and dopamine-loaded. You don't fight; you *overwhelm*. And when you're small, a single clever chest raid can flip the round — the underdog path is always open.

---

## Unique Hook

Like Crowd City, **AND ALSO** scattered across the map are tiered loot containers (small chests, abandoned cars, full buildings) that demand a follower toll to open and grant random run-modifying relics — turning pure snowball momentum into a constant risk/reward decision. Smaller containers are visible to small crowds; only huge mobs can even *find* buildings among their own followers, and only they can afford to raid one.

The tier system solves crowd-scale occlusion while creating a natural pacing curve: *your risk target grows as you grow.*

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 1 | Magnetic-snap absorb VFX, number-pop per citizen, crowd-size audio swell, cel-shaded chunky visuals |
| **Submission** (relaxation, comfort zone) | 2 | Low-friction movement-only inputs, no combat complexity, pure flow state |
| **Challenge** (obstacle course, mastery) | 3 | Chest-raid timing, rival evasion, relic-synergy decisions |
| **Expression** (self-expression) | 4 | Shop skins apply to player AND whole follower crowd — identity projection at scale |
| **Fantasy** | 5 | "I am a swarm" power trip |
| **Fellowship** | 6 | Roblox-native social (friends in server, leaderboards) |
| **Discovery** | 7 | Relic pool variety, seasonal chest rotations |
| **Narrative** | N/A | Not a story game |

### Key Dynamics (Emergent player behaviors)

- Players will route-plan around chest tier locations (choosing when to cash in toll for relic)
- Players will hunt smaller rivals to snowball, flee from bigger rivals, and use chest raids as comeback mechanic
- Players will develop "relic build" preferences and chase synergies within a round
- Players will project identity via skin selection visible across their whole crowd
- Players will log in daily to capture rotating skins + quest rewards

### Core Mechanics (Systems we build)

1. **Absorb mechanic** — Magnetic-snap proximity-based recruitment of neutral white NPCs
2. **Crowd collision resolution** — Larger mob consumes smaller on contact; equal mobs bounce or splinter
3. **Tiered chest system** — T1 chest / T2 car / T3 building, each with follower toll + random relic payout
4. **Relic draft** — Run-scoped modifiers (speed, absorb radius, toll discount, crowd magnetism, etc.)
5. **Cosmetic meta layer** — Shop skins apply to player + entire follower crowd; no power progression

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Route choice, chest-tier target selection, relic draft variance, skin identity | Supporting |
| **Competence** | Snowball feedback (number goes up), round wins, leaderboard climb, relic build mastery | Core |
| **Relatedness** | Friends-in-server, Roblox social, shared leaderboards | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — Leaderboard climb, round wins, daily quest completion
- [x] **Collectors** (Achiever sub-type) — Skin rotation, daily shop pulls, seasonal cosmetics
- [x] **Socializers** — Roblox-native friends, visible identity via skin broadcast to whole crowd
- [ ] **Explorers** — Minor (relic discovery only)
- [x] **Killers/Competitors** — Crushing rival crowds; note: no ranked ladder, no combat depth — casual competitor appeal only

### Flow State Design

- **Onboarding curve**: First round reveals absorb-and-grow in ~30 seconds. Chests introduced via on-screen prompt in first round. Relic effect telegraphed by icon + brief animation.
- **Difficulty scaling**: Pure skill-based matchmaking via Roblox server-fill; no tiered difficulty. Relic RNG modulates round-to-round variance.
- **Feedback clarity**: Crowd count visible on player nameplate. Round leaderboard mid-screen. Chest tolls clearly labeled above container.
- **Recovery from failure**: Losing a round = queue for next in ~10 seconds. No failure cost. Small crowd can still win via clever chest raid.

---

## Core Loop

### Moment-to-Moment (30 seconds)

Player runs through map. White neutrals in proximity magnetically snap into their crowd (satisfying tug + audio chime + count increment). Player sees a chest tier target, decides to raid or skip. Spots a rival crowd — sizes up (bigger? smaller? similar?) — chases or flees. Absorb, evaluate, route.

### Short-Term (5-15 minutes = one round)

5-minute round structure:
- **Minute 0-1**: Absorb neutrals. First T1 chest decision.
- **Minute 1-3**: Crowd builds. First rival contact. T2 car becomes relevant target.
- **Minute 3-4**: Top 2-3 crowds emerge. T3 building raids for rare relics. Eliminations begin.
- **Minute 4-5**: Final standoff. Last crowd standing wins.

"One more round" psychology driven by: new relic combo to try, daily quest progress, leaderboard rank ticking up, rotating skin in shop.

### Session-Level (30-120 minutes)

Typical session = 3-8 rounds + shop check + daily quest scan.
- Queue → play round → see result + currency earned → check daily progress → spend currency → queue next
- Natural stopping point: daily quests cleared OR desired skin purchased

### Long-Term Progression

**Zero power progression** — deliberate design constraint (Pillars 3 + 5).

Meta progression = **skin collection + leaderboard rank**:
- Earn soft currency per round (win bonus, participation)
- Shop rotates daily-featured + always-available skins
- Rare seasonal skins via battlepass or limited-time events
- Persistent leaderboards (global, friends, weekly)

### Retention Hooks

- **Curiosity**: Daily-rotating shop skins, seasonal relic pool additions
- **Investment**: Skin collection, leaderboard rank
- **Social**: Friends in server, cosmetic identity broadcast via follower crowd
- **Mastery**: Relic synergy discovery, chest-toll efficiency, route optimization

---

## Game Pillars

### Pillar 1: Snowball Dopamine

Every absorb must feel intrinsically great. Growth is the primary reward — feedback must be haptic, visual, audible.

*Design test*: If debating between two options, pick the one that makes growth feel better.

### Pillar 2: Risky Chests

Follower toll + relic draft creates meaningful mid-round decisions. Relics must reshape runs, not trivially stack.

*Design test*: If debating between two options, pick the one that makes chest choice harder, not safer.

### Pillar 3: 5-Minute Clean Rounds

Every round is self-contained. No power carried in. Matchmaking fair on skill/luck only.

*Design test*: If debating between two options, pick the one that preserves round purity.

### Pillar 4: Cosmetic Expression

Meta progression is identity, not power. Follower crowd mirrors player skin — every player broadcasts identity at scale.

*Design test*: If debating between two options, pick the one that extends player identity visually.

### Pillar 5: Comeback Always Possible

Small crowd can win via smart chest play + relic luck. Big crowd never guaranteed — big chest raids expose them.

*Design test*: If debating between two options, pick the one that keeps underdog path open.

### Anti-Pillars (What This Game Is NOT)

- **NOT pay-to-win**: Shop is cosmetic-only. Purchases grant zero in-round advantage. Breaks Pillar 3 otherwise.
- **NOT a persistent-power game**: No XP, no stat upgrades, no unlockable abilities. Breaks Pillars 3 + 5 otherwise.
- **NOT a combat game**: Movement-only input. No attacks, no combos, no skill shots. Breaks Pillar 1 and Relaxation/Flow aesthetic otherwise.
- **NOT a single-player game**: Multiplayer 5-min rounds are the game. No campaign, no story, no PvE.

---

## Visual Identity Anchor

**Selected direction**: **Roblox Default Stylized** — chunky low-poly, cel-shaded, bold silhouette-first.

**Visual rule (one line)**: *No gradients, no realism — every silhouette reads at distance, every color flat and bold.*

**Supporting principles**:

1. **Silhouette-first** — Every follower must be recognizable as a silhouette against the city backdrop. *Design test*: If an asset doesn't read at 50m on a mobile screen, it fails.
2. **Flat saturated palette** — Bold primary/secondary colors only. No gradients, no photoreal textures. *Design test*: If an asset uses a gradient, it fails.
3. **Chunky low-poly geometry** — Embrace Roblox blocky charm. Buildings, cars, props all use simple polygon language. *Design test*: If an asset requires custom shaders or normal maps, it fails.

**Color philosophy**: Each player's crowd = one vivid signature hue (hot pink, cyan, lime, etc.) applied via skin. Neutral white NPCs pop against darker city palette. City environment = muted desaturated backdrop so crowds pop visually.

This anchor is the seed of the art bible — it gates all asset production decisions. Run `/art-bible` next to expand into full visual specification.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Crowd City (Voodoo) | Absorb-and-snowball core loop, 5-min round structure | Add tiered chest system + relic draft; Roblox multiplayer; cosmetic meta | Validates 100M+ downloads for this verb; we extend via decision depth |
| Slay the Spire | Run-scoped relic modifiers that reshape play | Multiplayer arena context; relics short-duration and visually immediate | Validates relic-draft satisfaction; forces us to keep relics readable at a glance |
| Paper.io 2 | Scaling risk — bigger territory = bigger commitment window | Crowd growth replaces territory; chest raids replace expansion | Validates "getting bigger makes you more vulnerable" dynamic |
| Brawl Stars | Cosmetic skin meta + daily shop rotation | Cosmetics apply to whole follower crowd, not just avatar | Validates daily-pull retention loop for short-session mobile-class players |
| Dave the Diver | Cozy-dopamine progression feel + accessible controls | Multiplayer arena context; no single-player narrative | Validates that cozy feel can drive deep engagement |

**Non-game inspirations**: Crowd dynamics in K-pop flash mobs (sudden-appearance mass coordination); time-lapse ant colonies (growth visualization); vaporwave/flat-design illustration aesthetic for Roblox-stylized visual direction.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 10-25 (Roblox core demographic) |
| **Gaming experience** | Casual to mid-core |
| **Time availability** | 10-30 minute sessions, often multiple per day |
| **Platform preference** | Roblox on mobile primary, PC secondary |
| **Current games they play** | Roblox hypercasual .io titles, Brawl Stars, Stumble Guys, Voodoo casual titles |
| **What they're looking for** | Quick-session dopamine with a reason to return daily (skins, quests) |
| **What would turn them away** | Pay-to-win mechanics, rounds longer than 5 min, complex controls, content gated behind grinding |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Roblox (locked — existing project template) |
| **Key Technical Challenges** | Crowd-replication netcode (hundreds of follower entities per player × 8-12 players); chest balance tuning; matchmaking tuning for crowd density |
| **Art Style** | 3D stylized low-poly cel-shaded (Roblox default language) |
| **Art Pipeline Complexity** | Low — Roblox Studio native workflow, no custom shaders |
| **Audio Needs** | Moderate — absorb SFX variants (small/medium/large crowd swell), chest UI SFX, round start/end stingers, ambient city |
| **Networking** | Client-Server (Roblox-managed, authoritative server, ProfileStore for persistence) |
| **Content Volume** | 3 cities, 25-30 relics, 10-15 skin sets at Full Vision tier |
| **Procedural Systems** | Relic draft RNG (weighted by chest tier); map NPC respawn; no procgen geometry |

---

## Risks and Open Questions

### Design Risks

- **Chest balance fragility** — Toll cost vs. relic value must not dominate strategy; too cheap = spam, too expensive = ignored. Needs playtesting iteration.
- **Snowball death spiral** — If growth advantage compounds without chest-raid comebacks landing, rounds become unfun for early-eliminated players. Comeback mechanic must actually work.
- **Follower skin broadcast** — If skins too similar across players, identity-projection pillar fails. Needs vivid palette enforcement.

### Technical Risks

- **Crowd-sync netcode** — Replicating hundreds of follower transforms per player at 8-12 players/server may exceed Roblox bandwidth. MUST prototype early. Likely solution: follower flock simulation client-side, authoritative crowd-count/radius replicated.
- **Matchmaking density** — Server player count must produce dense-enough NPC + rival encounter frequency. Tuning required.
- **Chest occlusion** — Even with tier system, huge crowds may obscure T1 chests entirely. Needs clear visual marker above crowd height.

### Market Risks

- **Saturated .io genre on Roblox** — Many hypercasual clones. Hook (tiered chests + relic draft) must be visible in screenshots/thumbnails to stand out.
- **Cosmetic-only monetization** — Lower ARPU than gacha/P2W competitors; relies on volume via low-friction Roblox discovery.

### Scope Risks

- **Skin production treadmill** — 10-15 skin sets at V1.5 means ~3-5 skins/month sustained. Solo dev art pipeline must be efficient (modular skin system).
- **Relic design debt** — 25-30 balanced relics is substantial design+balance work. Start with 5-8 strong MVP relics and iterate.

### Open Questions

- **Q1**: Can Roblox replicate 100-300 follower entities per player smoothly? → Resolve via networking prototype (highest priority risk).
- **Q2**: What's the right starting toll for T1 chests so the first raid happens around minute 1? → Resolve via playtest iteration.
- **Q3**: Should relics persist only within a round, or seasonal long-run? → Concept says round-only (Pillar 3). Validate in playtest.
- **Q4**: Daily quest design — completion time target? → Resolve during `/design-system` for meta loop.

---

## MVP Definition

**Core hypothesis**: *Tiered chest + relic draft mid-round decisions make Crowd City snowball mechanic sustain engagement past the first novelty run — specifically, players average 3+ rounds per session and return the next day.*

**Required for MVP**:

1. Absorb mechanic with magnetic-snap feel (neutral NPC → player crowd)
2. Crowd-vs-crowd collision resolution (larger consumes smaller)
3. Tiered chest system (T1 chest + T2 car; T3 building deferrable)
4. Relic draft (5-8 starter relics, round-scoped only)
5. One city map (modern theme)
6. Matchmaking for 8-12 players, 5-minute rounds
7. Round win screen + basic currency reward
8. One skin set (default + 2 color variants) proving the skin-applies-to-crowd pipeline

**Explicitly NOT in MVP** (defer to later):

- Shop UI beyond stub
- Daily quests
- Leaderboards (global/friends)
- Multiple cities
- T3 buildings (add in V1 if networking allows)
- Battlepass / seasonal events
- Friend invites / party queue

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 city, 5-8 relics, 1 skin set | Core loop + T1/T2 chests + basic matchmaking | 6-8 weeks |
| **Vertical Slice** | 1 city polished, 10-12 relics, 3 skin sets | Core + T3 buildings + round win/currency | 10-12 weeks |
| **V1 (Ship)** | 2 cities, 15 relics, 5 skin sets | Daily quests + shop + leaderboards | 3-4 months |
| **V1.5 (Full Vision)** | 3 cities, 25-30 relics, 10-15 skins | Seasonal events + battlepass + full retention loop | 5-6 months |

---

## Next Steps

- [ ] Configure engine + reference docs (`/setup-engine` — Roblox already locked, validates version)
- [ ] Author the art bible (`/art-bible` — expand the Visual Identity Anchor above into a full visual spec)
- [ ] Validate concept completeness (`/design-review design/gdd/game-concept.md`)
- [ ] Optional creative-director pillar discussion (skipped in lean mode)
- [ ] Decompose into systems (`/map-systems`)
- [ ] Author per-system GDDs (`/design-system` — one per MVP system, in dependency order)
- [ ] Cross-system consistency check (`/review-all-gdds`)
- [ ] Pre-architecture phase gate (`/gate-check`)
- [ ] Create master architecture blueprint (`/create-architecture`)
- [ ] Record required ADRs (`/architecture-decision` ×N — follow the Required ADR list from `/create-architecture`)
- [ ] Compile control manifest (`/create-control-manifest`)
- [ ] Architecture coverage review (`/architecture-review`)
- [ ] Prototype the riskiest system — crowd netcode (`/prototype crowd-sync`)
- [ ] Playtest report after prototype (`/playtest-report`)
- [ ] Break epics and stories (`/create-epics` → `/create-stories`)
- [ ] Plan first sprint (`/sprint-plan new`)
