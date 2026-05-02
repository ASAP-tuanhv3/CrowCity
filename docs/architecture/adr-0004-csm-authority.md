# ADR-0004: Crowd State Manager Authority + Write-Access Contract

## Status

**Accepted 2026-04-26** (validated by `/architecture-review` 2026-04-26 — verdict CONCERNS at project level; ADR-0004 specifically had D1 documentation drift fixed this pass: §Module Placement Firewall narrative "depends on ADR-0006 codification" reworded to "codified by ADR-0006 §Source Tree Map" — formal Depends On table unchanged; no cycle).

Status history:
- 2026-04-25 — Proposed (initial)
- 2026-04-26 — D1 fix: §Module Placement Firewall narrative reworded to remove "depends on ADR-0006 codification" phrasing per `/architecture-review` D1 finding; formal Depends On table (0001/0002/0003) unchanged
- **2026-04-26 — ACCEPTED** (batch flip with ADR-0001/0002/0003/0006)
- 2026-05-02 — amended per CSM story-003 implementation: §Write-Access Matrix appended `addActiveRelic` + `removeActiveRelic` rows (RelicEffectHandler-only callers); §Pillar 4 invariant explicit-forbidden-call list extended; §Read-vs-Write Split `activeRelics` row updated from "delegated through Relic-specific methods, NOT a direct CSM write API" to direct API contract (cap+dup enforcement inside CSM). No semantic change — caller restriction was always RelicEffectHandler-only; this amendment promotes the relic-mutation contract from implicit to explicit and aligns ADR with shipped code surface.

## Date

2026-04-25 (initial), 2026-04-26 (D1 fix + Accepted)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Core / Authority |
| **Knowledge Risk** | LOW — module placement (`ServerStorage` vs `ReplicatedStorage`) stable Roblox semantics predating LLM cutoff; no post-cutoff API risk |
| **References Consulted** | `docs/engine-reference/roblox/VERSION.md`, `docs/engine-reference/roblox/replication-best-practices.md`, ADR-0001 §Decision + §Key Interfaces, ADR-0002 §Decision (Phase 5 + Phase 8), ADR-0003 §Server Per-Tick CPU Budget, `design/gdd/crowd-state-manager.md` §Core Rules + §Server API + §Pillar 4 anti-P2W (L195), `docs/architecture/architecture.md` §5.1 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (A) Module placement audit at first MVP integration — `grep -r "require.*CrowdStateServer"` from `src/ReplicatedStorage/Source/`, `src/ReplicatedFirst/Source/` must return zero matches; (B) Caller restriction audit — code review checklist verifies each call site's caller matches §Decision write-access matrix |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (record shape + replication contract), ADR-0002 (Phase 5 + Phase 8 callback structure), ADR-0003 (Phase 5 + Phase 8 CPU budgets) |
| **Enables** | ADR-0006 Module Placement Rules (codifies the placement firewall this ADR depends on); Phase 1-4 implementation stories (Absorb / Collision / Chest / Relic — all CSM write callers) |
| **Blocks** | Every implementation story that mutates a CrowdRecord field — cannot start without locked write contract |
| **Ordering Note** | Must be Accepted before `/create-control-manifest` (manifest extracts caller restrictions verbatim). Skin System GDD (VS-tier) MUST cite this ADR's anti-P2W invariant in its Dependencies section. |

## Context

### Problem Statement

ADR-0001 established that crowd state is server-authoritative and decoupled from rendering. CSM GDD §Server API enumerates the public surface (`create`, `destroy`, `updateCount`, `recomputeRadius`, `get`, `getAllActive`, `getAllCrowdPositions`, `setStillOverlapping`, `stateEvaluate`, `broadcastAll`) and §Core Rules names the 4 authorised `updateCount` callers (Absorb, Collision, Chest, Relic). CSM GDD §195 added a Pillar 4 anti-P2W contract — cosmetic systems MUST NOT mutate any crowd record field.

But these constraints currently live only in a GDD. No ADR locks them. Implications:

1. **No architectural firewall** — a future Skin System (Vertical Slice tier) could plausibly add itself as a CSM write caller without contradicting any Accepted ADR. The anti-P2W rule has no architectural-level owner.
2. **Per-API caller restrictions are scattered** — `recomputeRadius` (RelicEffectHandler-only), `setStillOverlapping` (CollisionResolver-only), `create`/`destroy` (RoundLifecycle-only) appear in the GDD but have no consolidated reference for `/create-control-manifest` to extract.
3. **Module placement is convention** — `ServerStorage/Source/CrowdStateServer/init.luau` is the intended location per CSM §Server API + `CLAUDE.md` §Source Layout, but no ADR says "if a client module requires CrowdStateServer, that's a code review rejection."
4. **Pillar 4 violations are subtle** — a cosmetic skin granting an absorb-radius bonus would technically work via `recomputeRadius` and pass code review unless the reviewer knows the anti-P2W rule. Architectural firewall must make this impossible to slip through.
5. **Story authoring needs the contract** — `/create-stories` for Absorb/Collision/Chest/Relic stories needs an ADR to embed as the write-access source; pulling from a GDD is allowed but ADR linkage is preferred per `/story-readiness`.

### Constraints

- **Server-only module placement** — `CrowdStateServer` lives under `ServerStorage` per Roblox security model + `CLAUDE.md`. Client cannot `require` it.
- **No runtime caller-validation** — Luau lacks a cheap reliable way to inspect call-site identity at runtime (`debug.traceback` is expensive + brittle). Caller restrictions must be enforced at **design + code-review** time, not runtime.
- **Single-threaded Luau** — no concurrent writes possible; ordering is purely sequential within a tick (Phase 1 → Phase 4 per ADR-0002).
- **`CrowdStateClient` is shared** (`ReplicatedStorage/Source/CrowdStateClient/init.luau`) — read-only mirror; no write API; any cosmetic system reads here, never writes.
- **`CrowdRelicChanged` reliable event** — relic state changes broadcast as full-snapshot from server; never client-mutated.
- **Pillar 3 (no persistent power) + Pillar 4 (cosmetic only)** — anti-pillars in `game-concept.md:179` "NOT pay-to-win" lock this at concept level.

### Requirements

- Lock **`updateCount` 4-caller rule** at ADR level (Absorb, CollisionResolver, ChestSystem, RelicEffectHandler — and only these)
- Lock **per-API single-caller restrictions** at ADR level (`create`/`destroy` RoundLifecycle-only; `recomputeRadius` RelicEffectHandler-only; `setStillOverlapping` CollisionResolver-only; `stateEvaluate`/`broadcastAll` TickOrchestrator-only)
- Lock **Pillar 4 anti-P2W invariant** as architectural rule — cosmetic systems FORBIDDEN as CSM write callers under any future ADR or GDD
- Lock **module placement firewall** — `CrowdStateServer` under `ServerStorage`; no client require possible by Roblox semantics
- Define **enforcement layers** — primary firewall (module placement), secondary firewall (code review), tertiary firewall (`/create-control-manifest` extracted rules sheet)
- Surface **read-vs-write split** — `get`, `getAllActive`, `getAllCrowdPositions` are unrestricted server-side reads; mutation methods are caller-restricted

## Decision

**`CrowdStateServer` (server-only module at `ServerStorage/Source/CrowdStateServer/init.luau`) is the sole authority for crowd state mutation. Each mutation API has a fixed caller set; no system outside that set may invoke that API. Cosmetic systems (Skin System and any future visual-identity systems) are PERMANENTLY FORBIDDEN from appearing in any caller set — this is a Pillar 4 architectural invariant. Enforcement is defense-in-depth: (a) Roblox module placement physically prevents client require; (b) code review verifies each call site against the §Write-Access Matrix below; (c) `/create-control-manifest` extracts these rules into a flat manifest for daily implementation reference.**

### Write-Access Matrix (LOCKED)

| API | Authorised callers (sole set) | Unauthorised — enforcement |
|---|---|---|
| `create(crowdId, initial)` | RoundLifecycle (`createAll` only) | All other systems |
| `destroy(crowdId)` | RoundLifecycle (`destroyAll` + `Players.PlayerRemoving` handler) | All other systems |
| `updateCount(crowdId, delta, source)` | AbsorbSystem (`source="Absorb"`), CollisionResolver (`source="Collision"`), ChestSystem (`source="Chest"`), RelicEffectHandler (`source="Relic"`) — exactly these 4 | All other systems including: HUD, Nameplate, FollowerEntity, FollowerLODManager, VFXManager, Skin System (VS+), Daily Quest System (Alpha+), Shop System (Alpha+) |
| `recomputeRadius(crowdId, newMultiplier)` | RelicEffectHandler (sole caller) | All other systems |
| `setStillOverlapping(crowdId, flag)` | CollisionResolver (sole caller) | All other systems |
| `addActiveRelic(crowdId, specId)` | RelicEffectHandler (relic-grant path; sole caller) | All other systems including all cosmetic systems (Pillar 4 forbidden) |
| `removeActiveRelic(crowdId, specId)` | RelicEffectHandler (relic-expiry path; sole caller) | All other systems |
| `stateEvaluate(tickCount)` | TickOrchestrator (Phase 5 dispatch only) | All other systems |
| `broadcastAll(tickCount)` | TickOrchestrator (Phase 8 dispatch only) | All other systems |
| `get(crowdId)` | Any server-side system (read-only) | — (no caller restriction) |
| `getAllActive()` | CollisionResolver (overlap scan); other server systems may read | Callers MUST NOT mutate returned references |
| `getAllCrowdPositions()` | NPCSpawner (min-distance gate); other server systems may read | Callers MUST NOT mutate returned snapshot |
| `CountChanged` BindableEvent (subscribe) | RoundLifecycle (peakCount tracking), analytics stubs (Alpha+), future in-session scoring | Server-only signal; clients use 15 Hz `CrowdStateBroadcast` instead |

**Enforcement**: violations are code-review blockers, not runtime guards. Module placement (server-only) prevents the most dangerous violation (client mutation) by Roblox engine semantics. Code review enforces the same-server caller restrictions.

### Pillar 4 Anti-P2W Invariant (LOCKED — architectural rule, cannot be amended without superseding this ADR)

**Cosmetic systems (Skin System, Avatar System, Banner System, Trail System, any future visual-identity system) MUST NOT appear in any CSM write caller set. They MUST NOT call `updateCount`, `recomputeRadius`, `setStillOverlapping`, `create`, `destroy`, `addActiveRelic`, or `removeActiveRelic`. They MUST NOT subscribe to `CountChanged` to gate any visual decision that affects gameplay (count display via `CrowdStateClient` is presentation-only and acceptable).**

**Why architectural-level**: Pillar 4 (Cosmetic Expression) + Pillar 3 (5-Min Clean Rounds) + the explicit anti-pillar "NOT pay-to-win" in `design/gdd/game-concept.md:179` make this a project-identity constraint, not a per-system implementation detail. Any GDD or ADR proposing to add a cosmetic system as a CSM caller is a design conflict that supersedes this ADR or compromises Pillar 4.

**Permitted cosmetic data flow**:

```text
Player buys Skin → PlayerData (Coins-deducted, OwnedSkins added) →
  Server fires reliable SkinChanged event →
  Client FollowerEntity reads PlayerDataClient.OwnedSkins/SelectedSkin →
  Client visual swap (BrickColor + decal/texture)
```

No CSM write API touched. No crowd record field mutated. Identity broadcast is rendering-only.

### Module Placement Firewall (codified by ADR-0006 §Source Tree Map)

```text
src/ServerStorage/Source/CrowdStateServer/
  init.luau                       -- public API + write methods
  internal.luau                   -- private state, hidden from server callers
  CrowdRecord.luau                -- type definitions + record helpers

src/ReplicatedStorage/Source/CrowdStateClient/
  init.luau                       -- read-only mirror (no write API)
  CrowdRecord.luau                -- shared type definitions
```

**Roblox engine semantics enforce**: any `require(ServerStorage.Source.CrowdStateServer)` from `ReplicatedStorage.*` or `ReplicatedFirst.*` returns nil/errors at runtime. The client physically cannot call CSM write APIs. ADR-0006 §Layer Hierarchy + No-Upward-Import Rule codifies this for the project at large; ADR-0004 simply applies the rule to CSM specifically.

### Read-vs-Write Split

| Concern | Read API | Write API | Caller restriction |
|---|---|---|---|
| `count` | `get(crowdId).count`, `CrowdStateClient.get(crowdId).count`, broadcast | `updateCount` | 4 callers + delta source enum |
| `radius` (composed) | `get(crowdId).radius`, broadcast | implicit via `count` write or `recomputeRadius` | 4 callers (count) + RelicEffectHandler (multiplier) |
| `radiusMultiplier` | `get(crowdId).radiusMultiplier` | `recomputeRadius(id, newMultiplier)` | RelicEffectHandler only |
| `position` | `get(crowdId).position`, broadcast | internal Phase 5 lag-tick only — no public write | None (Phase 5 reads `Character.HumanoidRootPart` directly) |
| `state` | `get(crowdId).state`, broadcast | internal Phase 5 transition only — no public write | None (state machine internal) |
| `tick` | broadcast | `broadcastAll` increments — no public write | None |
| `stillOverlapping` | `get(crowdId).stillOverlapping` (read) | `setStillOverlapping(id, flag)` | CollisionResolver only |
| `timer_start` | internal | internal Phase 5 transition only | None |
| `hue` | `get(crowdId).hue`, broadcast | `create` only — immutable post-create | RoundLifecycle only (via `create`) |
| `activeRelics` | `get(crowdId).activeRelics`, reliable `CrowdRelicChanged` event | `addActiveRelic(id, specId)` / `removeActiveRelic(id, specId)` (added by CSM story-003 — direct write APIs, max 4 cap + dup-rejection enforced inside CSM) | RelicEffectHandler only |
| `crowdId` | `get(crowdId).crowdId`, broadcast | `create` only — immutable | RoundLifecycle only |

### Defense-in-depth enforcement layers

| Layer | Mechanism | What it catches |
|---|---|---|
| **L1** Module placement | `ServerStorage/Source/CrowdStateServer/` — Roblox enforces server-only require | All client-side mutation attempts (impossible by engine semantics) |
| **L2** Code review | PR reviewer checks every call site against §Write-Access Matrix | Same-server caller mismatches (e.g. HUD calling `updateCount`) |
| **L3** Control manifest | `/create-control-manifest` extracts matrix verbatim into flat rules sheet | Daily implementation reference for programmers; reduces L2 reviewer load |
| **L4** Architecture review | `/architecture-review` cross-checks each ADR/GDD's claimed callers vs the matrix | New systems silently adding themselves as callers |
| **L5** Story readiness | `/story-readiness` validates story embeds correct caller + source enum | Story-level violations before code is written |

### Caller-restriction style guide for module authors

```lua
-- ServerStorage/Source/CrowdStateServer/init.luau
--!strict

-- Module-level header comment names authorised callers per API
-- Code review checks the comment matches the implementation.

local CrowdStateServer = {}

--[[
    Caller restrictions (ADR-0004 §Write-Access Matrix):
      create()              — RoundLifecycle.createAll only
      destroy()             — RoundLifecycle (destroyAll + PlayerRemoving handler)
      updateCount()         — Absorb / Collision / Chest / Relic only (4 callers)
      recomputeRadius()     — RelicEffectHandler only
      setStillOverlapping() — CollisionResolver only
      stateEvaluate()       — TickOrchestrator (Phase 5) only
      broadcastAll()        — TickOrchestrator (Phase 8) only

    Pillar 4 anti-P2W invariant (ADR-0004 §Pillar 4):
      Cosmetic systems FORBIDDEN as callers. Skin System, future
      Avatar / Banner / Trail systems MUST NOT mutate any field.

    Read APIs (get / getAllActive / getAllCrowdPositions) are unrestricted
    server-side but callers MUST NOT mutate returned references.
]]

function CrowdStateServer.updateCount(crowdId: string, delta: number, source: DeltaSource): number
    -- source enum is the runtime-visible caller fingerprint;
    -- code review verifies each call site passes a source value
    -- consistent with its identity (Absorb/Collision/Chest/Relic).
    -- ...
end
```

The `source: DeltaSource` enum on `updateCount` is the closest the system comes to a runtime caller fingerprint — code review verifies the source value matches the calling module's identity.

## Alternatives Considered

### Alternative 1: Convention-only via CSM GDD (status quo)

- **Description**: Keep `updateCount` 4-caller rule, anti-P2W contract, and per-API restrictions in CSM GDD only. No ADR.
- **Pros**: Zero ADR overhead. CSM GDD already specifies all rules.
- **Cons**: GDDs are design documents; their constraints are advisory unless an ADR locks them. Future Skin System GDD has no architectural-level "you cannot do this" — only "the CSM GDD asked you not to." Anti-P2W relies on every reviewer remembering Pillar 4. `/create-control-manifest` has nothing to extract from. `/architecture-review` cannot detect violations.
- **Rejection Reason**: Pillar 4 is a project-identity constraint (anti-pillar in game-concept.md), not a per-system design choice. It deserves architectural-level locking. Convention-only also makes the rules invisible to programmers who read ADRs but skim GDDs.

### Alternative 2: Runtime caller-validation guards via debug.traceback

- **Description**: Each write API inspects `debug.traceback` to identify the calling module and rejects unauthorised callers at runtime.
- **Pros**: Hard runtime enforcement; impossible to slip past.
- **Cons**: `debug.traceback` is expensive (~100 µs per call) — would consume Phase 1-4 CPU budget ADR-0003 allocates. Brittle: traceback string format isn't stable API, breaks with module restructure. Adds complexity to every write API. Tests would need to bypass the guard, creating its own test-vs-prod divergence.
- **Rejection Reason**: Defense-in-depth at design time + code review is sufficient. Module placement (L1) catches the high-impact case (client mutation) for free. Spending Phase 1-4 CPU on caller validation is poor use of the 3 ms/tick budget.

### Alternative 3: Capability-token pattern — write APIs require a token-passed handle

- **Description**: `CrowdStateServer.create()` returns a writeToken. Mutators require token: `updateCount(token, crowdId, delta)`. Tokens minted only at boot for the 4 authorised modules.
- **Pros**: Compile-time-ish enforcement via type system (token type required).
- **Cons**: Adds API complexity (every call needs token). Token-leak attack surface (a module receiving a token by accident gains write access). Luau type system can't enforce token uniqueness at compile time. Doesn't prevent Skin System from being granted a token in a future ADR — same caller-set-as-data problem.
- **Rejection Reason**: Adds complexity without solving the Pillar 4 architectural-invariant problem. The anti-P2W rule is policy, not a token-scope decision.

### Alternative 4: Split CrowdStateServer into per-caller submodules

- **Description**: `CrowdStateServer.AbsorbWriter`, `.CollisionWriter`, `.ChestWriter`, `.RelicWriter`. Each submodule exposes only its own subset of write APIs. Caller imports only its submodule.
- **Pros**: Smaller per-caller surface. Imports show authorisation explicitly.
- **Cons**: 4× more module files. Same enforcement story (placement + review) — submodule split doesn't add a new firewall layer. CSM internal state must still be shared across submodules, increasing coupling. Read APIs (`get`, `getAllActive`) duplicated across submodules or routed back through main module.
- **Rejection Reason**: Doesn't change the enforcement model materially. Single CSM module with documented write-access matrix is simpler.

## Consequences

### Positive

- ADR-level lock on Pillar 4 anti-P2W — Skin System and any future cosmetic system cannot quietly become a CSM caller without superseding this ADR (high-friction by design)
- `/create-control-manifest` has a single canonical source for caller restrictions
- `/architecture-review` can verify every Phase 1-4 ADR's claimed callers match this matrix
- `/story-readiness` can validate every Absorb/Collision/Chest/Relic story embeds the correct `source: DeltaSource` value
- Module placement firewall (L1) is free — Roblox engine semantics enforce server-only
- Defense-in-depth (5 layers) catches violations at multiple stages — design, review, manifest, architecture review, story readiness
- New Skin System GDD has explicit constraint to cite — accelerates VS+ design work

### Negative

- Code-review burden — every Phase 1-4 PR must verify call sites match matrix
- Anti-P2W invariant friction — any future feature legitimately needing cosmetic-affects-gameplay (e.g. ranked-only relic) requires superseding ADR + project-pillar discussion
- No runtime guard — same-server violations rely on review discipline (mitigated by L3 manifest + L4 review + L5 story readiness)
- Documentation duplication — write-access matrix appears in CSM GDD §Server API + this ADR + future control manifest. Drift risk if any of the three updates without the others.

### Risks

- **Risk 1 (LOW)** — Code review misses a same-server caller-restriction violation. Mitigation: `/create-control-manifest` extracts matrix into a flat sheet; `/story-readiness` validates story-level claims; `/architecture-review` cross-checks ADR claims. Three additional layers beyond raw code review.
- **Risk 2 (MEDIUM)** — Future feature legitimately needs a cosmetic-affects-gameplay path (e.g. seasonal event grants temporary radius bonus to all skin-X holders). Mitigation: feature must propose a superseding ADR with explicit Pillar 4 amendment and creative-director sign-off. High friction is the feature, not the bug.
- **Risk 3 (LOW)** — Documentation drift between CSM GDD §Server API + this ADR + control manifest. Mitigation: `/architecture-review` includes consistency check; `/propagate-design-change` runs when any of three is edited.
- **Risk 4 (LOW)** — Test code needs to mutate CSM state without going through authorised callers (e.g. integration test fixture). Mitigation: test-only `_setForTest(crowdId, partialRecord)` API gated by `RunService:IsStudio()`-like guard, used only in TestEZ fixtures; flagged in code review when used in non-test paths.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `design/gdd/crowd-state-manager.md` §Core Rules `updateCount` 4-caller | "No other system may call `updateCount`. Enforced by server-only module placement" | ADR §Write-Access Matrix locks 4-caller rule + names enforcement (L1 module placement + L2 review) |
| `design/gdd/crowd-state-manager.md` §Server API per-API caller restrictions | "RelicEffectHandler only" / "CollisionResolver only" / "RoundLifecycle only" annotations | ADR §Write-Access Matrix consolidates all per-API single-caller rules into one table |
| `design/gdd/crowd-state-manager.md` §195 Pillar 4 anti-P2W contract | "Cosmetic systems MUST NOT mutate any field of a crowd record" | ADR §Pillar 4 Anti-P2W Invariant escalates to architectural-level invariant (cannot amend without superseding) |
| `design/gdd/game-concept.md:179` anti-pillar "NOT pay-to-win" | Concept-level anti-pillar | ADR locks the anti-pillar at architecture level so it cannot drift via incremental GDD additions |
| `design/gdd/absorb-system.md` §Core | "Fires `updateCount(crowdId, +1, "Absorb")`" | ADR confirms Absorb as 1 of 4 authorised callers + locks `source="Absorb"` |
| `design/gdd/crowd-collision-resolution.md` §Core | "Updates count via `CSM.updateCount(±drip, "Collision")`" + sole `setStillOverlapping` caller | ADR confirms CollisionResolver as 1 of 4 + sole `setStillOverlapping` caller |
| `design/gdd/chest-system.md` §Core Rule TR-toll-deduction | "`CSM.updateCount(crowdId, -toll, "Chest")` after guard pipeline" | ADR confirms Chest as 1 of 4 authorised callers |
| `design/gdd/relic-system.md` §Core | "Mutating relics route through RelicEffectHandler → CSM" + sole `recomputeRadius` caller | ADR confirms Relic as 1 of 4 + sole `recomputeRadius` caller |
| `design/gdd/round-lifecycle.md` §Core | "calls `CrowdStateServer.create(crowdId, initial)` per player" + `destroy` on T9 | ADR confirms RoundLifecycle as sole `create`/`destroy` caller |
| ADR-0001 §Decision write-access | "Server is source of truth per Roblox best practice" | ADR-0004 implements ADR-0001's authority directive at module-API level |
| ADR-0002 §Decision Phase 5 + Phase 8 | "TickOrchestrator drives CSM.stateEvaluate at Phase 5 + .broadcastAll at Phase 8" | ADR-0004 confirms TickOrchestrator as sole caller of phase-hook APIs |

## Performance Implications

- **CPU (server)**: zero overhead — caller restrictions enforced at design + review time, not runtime. ADR-0003 Phase 5 (0.2 ms) + Phase 8 (0.4 ms) budgets unchanged.
- **CPU (client)**: zero — no client-side enforcement.
- **Memory**: zero overhead.
- **Load Time**: zero.
- **Network**: zero — no new traffic.

The defense-in-depth model deliberately moves enforcement cost off the runtime hot path onto the design-review pipeline.

## Migration Plan

No existing CSM implementation. Clean implementation against this ADR.

1. Implement `ServerStorage/Source/CrowdStateServer/init.luau` with §Decision write-access matrix as module header doc-comment (the style-guide example above).
2. Each Phase 1-4 implementation story (Absorb, Collision, Chest, Relic) cites this ADR as its CSM contract source.
3. Code-review template for any Phase 1-4 PR includes "Verify CSM call sites match ADR-0004 §Write-Access Matrix" checklist item.
4. `/create-control-manifest` extracts §Write-Access Matrix verbatim once this ADR is Accepted.
5. Any future Skin System / Avatar System / Banner System GDD MUST include `Dependencies` row citing ADR-0004 anti-P2W invariant — flagged at `/design-review` time.

## Validation Criteria

- [ ] Module placement audit: `grep -r "require.*CrowdStateServer" src/ReplicatedStorage/Source src/ReplicatedFirst/Source` returns zero matches (post-implementation)
- [ ] Caller-restriction audit: every call site of `updateCount` passes a `source` value matching its module's identity per matrix
- [ ] Caller-restriction audit: every call site of `recomputeRadius` originates in a module under `ServerStorage/Source/RelicSystem/`
- [ ] Caller-restriction audit: every call site of `setStillOverlapping` originates in `ServerStorage/Source/CollisionResolver/`
- [ ] Caller-restriction audit: every call site of `create`/`destroy` originates in `ServerStorage/Source/RoundLifecycle/`
- [ ] Anti-P2W audit: no call site of any CSM write API originates in a Skin / Cosmetic / Avatar / Banner / Trail module
- [ ] Control manifest extraction: `/create-control-manifest` produces a section that matches §Write-Access Matrix verbatim
- [ ] `/architecture-review` cross-check: ADR-0001/0002/0003/0006 + Phase 1-4 ADRs (when written) all reference ADR-0004's caller restrictions consistently

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — record shape + replication contract; this ADR adds the authority/caller layer
- **ADR-0002** TickOrchestrator — Phase 5 + Phase 8 callback structure; this ADR confirms TickOrchestrator as sole phase-hook caller
- **ADR-0003** Performance Budget — Phase 5 + Phase 8 CPU budgets; this ADR's runtime cost is zero
- **Expected downstream**:
  - ADR-0006 Module Placement Rules — codifies the no-upward-import rule this ADR depends on
  - Future Skin System ADR (VS+) — must cite anti-P2W invariant from this ADR
  - Phase 1-4 implementation ADRs (if authored) — cite this ADR's caller restrictions

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). Module placement (`ServerStorage` vs `ReplicatedStorage`) is stable Roblox semantics with extensive creator-forum documentation; no validation risk.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
