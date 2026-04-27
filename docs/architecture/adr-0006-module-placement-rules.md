# ADR-0006: Module Placement Rules + Layer Boundary Enforcement

## Status

**Accepted 2026-04-26** (validated by `/architecture-review` 2026-04-26 — verdict CONCERNS at project level; ADR-0006 specifically had no blocking issues; closes the must-have ADR set together with ADR-0001/0002/0003/0004).

Status history:
- 2026-04-26 — Proposed (initial)
- **2026-04-26 — ACCEPTED** (batch flip with ADR-0001/0002/0003/0004)

Selene custom rules (L3 enforcement layer) remain deferred to Production-phase task per §Migration Plan; Accept transition does not gate on L3 — defense-in-depth via L1 (engine), L2 (review), L4 (manifest), L5 (architecture review), L6 (story readiness) is sufficient.

## Date

2026-04-26 (initial), 2026-04-26 (Accepted)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Roblox (continuously-updated live service) |
| **Domain** | Core / Scripting / Build |
| **Knowledge Risk** | LOW — Roblox service tree (`ServerStorage`, `ReplicatedStorage`, `ReplicatedFirst`, `ServerScriptService`) + Rojo project layout are stable APIs predating LLM cutoff |
| **References Consulted** | `CLAUDE.md` §Source Layout + §Shared vs server-only code + §Forbidden Patterns, `docs/engine-reference/roblox/replication-best-practices.md` §Placement Rules, `docs/engine-reference/roblox/profilestore-reference.md`, `docs/engine-reference/roblox/luau-type-system.md`, ADR-0001/0002/0003/0004, `docs/architecture/architecture.md` §2 + §3 + §5, `.claude/docs/technical-preferences.md` §Forbidden Patterns + §Allowed Libraries, `ANATOMY.md` §1 (template-provided pattern reference) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | (A) Static grep audit on first MVP integration — `grep -r "require.*ServerStorage"` from `src/ReplicatedStorage/` + `src/ReplicatedFirst/` returns zero matches; (B) Selene custom rule (or CI lint script) catches `require` of forbidden paths from forbidden contexts; (C) Rojo project file (`default.project.json`) audit confirms service mappings match §Source Tree Map |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (server-authoritative architecture establishes need for placement firewall), ADR-0004 (CSM Authority — explicitly references this ADR for module placement firewall codification) |
| **Enables** | `/create-control-manifest` (extracts the placement matrix into the flat rules sheet); every implementation story (story authors must place new modules per §Source Tree Map); future Skin / Avatar / Banner ADRs (must respect the cosmetic-system placement constraint) |
| **Blocks** | First code PR — code review checklist depends on this ADR; Sprint planning for Foundation epic — sprint stories cite this ADR |
| **Ordering Note** | Closes the must-have ADR set (ADR-0002/0003/0004/0006). Must be Accepted before `/create-control-manifest` runs. Should be Accepted before `/gate-check pre-production` to enforce systems-design-to-technical-setup gate's TD CONCERNS resolution. |

## Context

### Problem Statement

Crowdsmith uses a layered architecture (Foundation / Core / Feature / Presentation per `docs/architecture/architecture.md` §2). The layer rules — server-only modules under `ServerStorage`, shared modules under `ReplicatedStorage`, no upward imports, client must not require server-only — currently live across multiple documents:

- `CLAUDE.md` §Source Layout + §Shared vs server-only code (canonical but informal)
- `docs/engine-reference/roblox/replication-best-practices.md` §Placement Rules (reference)
- `docs/architecture/architecture.md` §2.5 Layer-boundary rules (high-level)
- ADR-0004 §Module Placement Firewall (depends on this ADR for codification)
- Each GDD's Server API section (per-system, scattered)

No ADR consolidates the placement matrix or codifies the no-upward-import rule. Implications:

1. **ADR-0004 has a forward dependency** — its Pillar 4 anti-P2W invariant + 5-layer enforcement model assumes "Roblox engine semantics enforce server-only require" (L1 firewall) but no ADR locks WHERE each module goes.
2. **Forbidden imports lack architectural backing** — `CLAUDE.md` §Forbidden Patterns names "client requires from ServerStorage", "Direct DataStoreService calls", "Direct RemoteEvent access by path", "Direct Humanoid.WalkSpeed writes", "Client-side data mutation" but as conventions, not architecture.
3. **Code review has no checklist** — reviewers verify module placement ad-hoc, drift risk grows as systems are added.
4. **Sprint stories cannot cite a placement source** — `/create-stories` for any new module needs an ADR-level reference; CLAUDE.md is descriptive, not prescriptive.
5. **`/create-control-manifest` has no consolidated input** — manifest pulls from multiple docs, drift risk.
6. **New systems silently violate layer boundaries** — without explicit no-upward-import rule (Foundation never requires Core; Core never requires Feature; Feature never requires Presentation), a Feature-layer system could plausibly add a Presentation-layer dependency, creating tight coupling that breaks layer guarantees.
7. **Wally + Freeze + ProfileStore placement** — vendored vs Wally-managed dependencies have different placement rules; no ADR consolidates them.

### Constraints

- **Roblox service tree is fixed** — `ServerStorage`, `ReplicatedStorage`, `ReplicatedFirst`, `ServerScriptService`, `StarterGui`, `StarterPlayerScripts` semantics are engine-defined; this ADR maps source folders to services, not the other way around.
- **Rojo project file is source of truth** — `default.project.json` (or equivalent) defines folder→service mapping; this ADR specifies what the project file must contain.
- **Two entry-point model locked by template** — `src/ReplicatedFirst/Source/start.server.luau` (RunContext: Client) + `src/ServerScriptService/start.server.luau` (RunContext: Server) per `CLAUDE.md` §Two-entry-point model. No additional Scripts or LocalScripts.
- **Vendored vs Wally** — vendored libraries (ProfileStore, Freeze) live under `src/ReplicatedStorage/Dependencies/`; Wally-managed live under `Packages/` (auto-generated by `wally install`).
- **`CLAUDE.md` §Source Layout cannot conflict** — this ADR and CLAUDE.md must agree; if revised, CLAUDE.md is updated alongside.
- **Selene config is project-pinned** — custom lint rules require updating `selene.toml` + `roblox.yml`; out of scope for this ADR but flagged as Migration concern.
- **Single-threaded Luau** — no concurrent module loading concerns; require ordering is deterministic.

### Requirements

- Lock **per-module-class placement rules** — server-only / shared / client-only / vendored / Wally / SharedConstants / Network instances
- Lock **layer hierarchy** — Foundation (no upward imports) → Core → Feature → Presentation
- Lock **no-upward-import rule** — Core never requires Feature; Feature never requires Presentation; etc.
- Lock **client-must-not-require-ServerStorage rule** — primary security firewall (already engine-enforced; codified here)
- Lock **forbidden-pattern matrix** consolidating all `CLAUDE.md` §Forbidden Patterns with their architectural justification
- Lock **enum-module placement rule** — every cross-module identifier flows through `SharedConstants/`
- Lock **vendored vs Wally placement rules** — different folders, different enforcement
- Lock **two-entry-point invariant** — only two RunContext-bearing scripts in the whole project
- Lock **Rojo project file constraints** — what `default.project.json` must map
- Define **enforcement layers** — primary (Roblox engine semantics) + secondary (code review) + tertiary (Selene custom rules) + quaternary (control manifest extraction) + quinary (story readiness)
- Surface **vendored library upgrade policy** — when to update ProfileStore / Freeze / Wally pins

## Decision

**Module placement is locked per the §Source Tree Map below. Every Luau module belongs to exactly one of nine placement classes. Layer hierarchy enforces no-upward-imports: Foundation → Core → Feature → Presentation, never the reverse. The client physically cannot require `ServerStorage` modules (Roblox engine semantics — primary firewall). Same-server placement violations are caught at code review (secondary), with `/create-control-manifest` extracting the matrix verbatim for daily reference (tertiary). Two RunContext-bearing scripts only (`ReplicatedFirst/Source/start.server.luau` + `ServerScriptService/start.server.luau`); all logic in ModuleScripts required from those two.**

### Source Tree Map (LOCKED)

```text
src/
├── ReplicatedFirst/
│   └── Source/
│       └── start.server.luau              # ENTRY POINT — RunContext: Client
│           # Loading screen → Network ready → PlayerData → Character →
│           # gameplay client init → UI → FTUE → hide loading screen.
│           # No other Scripts or LocalScripts.
│
├── ServerScriptService/
│   └── start.server.luau                  # ENTRY POINT — RunContext: Server
│       # Network → DataStore → global systems → per-PlayerAdded:
│       # load data → per-player systems → FTUE → spawn character.
│       # No other Scripts or LocalScripts. TickOrchestrator.start() called here.
│
├── ServerStorage/
│   └── Source/                            # SERVER-ONLY MODULES
│       ├── CrowdStateServer/init.luau     # ADR-0004 sole authority
│       ├── MatchStateServer/init.luau
│       ├── RoundLifecycle/init.luau
│       ├── TickOrchestrator/init.luau     # ADR-0002 sole accumulator
│       ├── CollisionResolver/init.luau    # Phase 1
│       ├── RelicSystem/init.luau          # Phase 2 + RelicEffectHandler
│       ├── AbsorbSystem/init.luau         # Phase 3
│       ├── ChestSystem/init.luau          # Phase 4
│       ├── PeelDispatcher/init.luau       # Phase 9
│       ├── NPCSpawner/init.luau
│       ├── PlayerDataServer.luau          # template-provided
│       ├── DefaultPlayerData.luau         # template-provided
│       ├── CharacterSpawner.luau          # template-provided
│       ├── PlayerObjectsContainer.luau    # template-provided
│       ├── CollisionGroupManager.luau     # template-provided (gap-filled)
│       ├── ReceiptProcessor.luau          # template-provided
│       ├── FtueManagerServer/             # template-provided + customised
│       └── ZoneHandler.luau               # template-provided
│
├── ReplicatedStorage/
│   ├── Source/                            # SHARED MODULES (client + server)
│   │   ├── Network/                       # template-provided + UnreliableRemoteEvent extension
│   │   │   ├── init.luau
│   │   │   └── RemoteName/
│   │   │       ├── RemoteEventName.luau
│   │   │       └── UnreliableRemoteEventName.luau   # NEW per ADR-0001/0002 prereq
│   │   ├── SharedConstants/               # ENUM modules — no magic strings
│   │   │   ├── Attribute.luau
│   │   │   ├── PlayerDataKey.luau
│   │   │   ├── ItemCategory.luau
│   │   │   ├── ContainerByCategory.luau
│   │   │   ├── UILayerId.luau
│   │   │   ├── AssetId.luau               # NEW (art bible §8.9 + ADR cited)
│   │   │   ├── CrowdConfig.luau           # NEW (CSM tuning knobs)
│   │   │   ├── MatchConfig.luau           # NEW (MSM + RoundLifecycle)
│   │   │   ├── ChestConfig.luau           # NEW (Chest tuning)
│   │   │   ├── MatchState.luau            # NEW (state enum)
│   │   │   ├── CrowdClientConfig.luau     # NEW (STALE_THRESHOLD_SEC etc.)
│   │   │   ├── DeltaSource.luau           # NEW (CSM updateCount enum)
│   │   │   ├── VFXEffectId.luau           # NEW
│   │   │   └── CollectionServiceTag/
│   │   │       ├── ChestTag.luau          # NEW
│   │   │       ├── ZonePartTag.luau
│   │   │       └── ZoneIdTag.luau
│   │   ├── CrowdStateClient/init.luau     # client cache (read-only mirror)
│   │   ├── MatchStateClient/init.luau
│   │   ├── FollowerEntity/                # client visual sim only — server roster lives in CSM record
│   │   │   └── Client.luau
│   │   ├── FollowerLODManager/init.luau
│   │   ├── VFXManager/init.luau
│   │   ├── PlayerNameplate/Client.luau
│   │   ├── ChestBillboard/Client.luau
│   │   ├── ChestDraftClient.luau          # draft modal client side
│   │   ├── PlayerDataClient.luau          # template-provided
│   │   ├── UI/                            # UIHandler + per-layer components
│   │   │   ├── UIHandler/init.luau        # template-provided
│   │   │   ├── UILayers/HUD/              # NEW per HUD GDD
│   │   │   ├── UILayers/Lobby/            # VS+
│   │   │   └── UIComponents/              # template-provided
│   │   ├── ComponentCreator.luau          # template-provided
│   │   ├── Connections.luau               # template-provided (RBXScriptConnection lifecycle)
│   │   └── ValueManager.luau              # template-provided (composed numeric stats)
│   │
│   ├── Dependencies/                      # VENDORED LIBRARIES (manual update)
│   │   ├── ProfileStore.luau              # session-locked DataStore wrapper
│   │   └── Freeze/                        # immutable Dictionary + List
│   │       ├── init.luau
│   │       ├── Dictionary.luau
│   │       └── List.luau
│   │
│   └── Instances/                         # GUI prefabs + item containers
│       ├── GuiPrefabs/
│       └── [ItemCategory folders]/        # one per ItemCategory enum
│
└── (no other src/ folders)

Packages/                                  # WALLY-MANAGED (auto-generated)
├── promise/                                # Packages.promise
├── janitor/                                # Packages.janitor
├── testez/                                 # Packages.testez
└── _Index/                                 # Wally internal — never edit

# Build + tooling (NOT under src/)
default.project.json                        # Rojo project file — folder→service mapping
aftman.toml                                 # Rojo / Selene / Wally version pins
wally.toml                                  # Wally dependency pins
selene.toml                                 # Selene linter config
roblox.yml                                  # Selene Roblox stdlib config
```

### Placement Class Matrix (LOCKED)

Each Luau module belongs to exactly one class:

| Class | Folder | Rule | Examples |
|---|---|---|---|
| **Server-only** | `src/ServerStorage/Source/...` | Client cannot `require` (Roblox engine enforced). Authority modules (CSM, MSM, RoundLifecycle, TickOrchestrator), Phase 1-9 systems, NPCSpawner, PlayerDataServer | `CrowdStateServer`, `ChestSystem`, `RelicSystem` |
| **Shared (client + server)** | `src/ReplicatedStorage/Source/...` | Both sides may require. SharedConstants, client cache mirrors, client-side gameplay sims, UI, Network wrapper | `Network`, `CrowdStateClient`, `VFXManager`, `HUD` |
| **Client entry point** | `src/ReplicatedFirst/Source/start.server.luau` | Single Script; `RunContext: Client`; no other Scripts/LocalScripts | template-provided |
| **Server entry point** | `src/ServerScriptService/start.server.luau` | Single Script; `RunContext: Server`; no other Scripts/LocalScripts | template-provided |
| **Vendored library** | `src/ReplicatedStorage/Dependencies/...` | Manual update only; not in Wally; treat as third-party (no edits) | `ProfileStore`, `Freeze` |
| **Wally package** | `Packages/[name]/` (auto-generated) | Run `wally install`; pinned in `wally.toml`; never edit Packages/ directly | `Promise`, `Janitor`, `TestEZ` |
| **Enum / SharedConstants** | `src/ReplicatedStorage/Source/SharedConstants/...` | Every cross-module identifier — string keys, attribute names, asset IDs | `RemoteEventName`, `PlayerDataKey`, `AssetId`, `MatchState`, `CollectionServiceTag/*` |
| **Network instance registry** | `src/ReplicatedStorage/Source/Network/...` | Wrapper module + RemoteEvent / UnreliableRemoteEvent enum subfolders | `Network/init.luau`, `Network/RemoteName/RemoteEventName.luau` |
| **GUI prefabs / item instances** | `src/ReplicatedStorage/Instances/...` | Pre-authored `Instance` trees (not Luau modules); cloned at runtime | `GuiPrefabs/HudFrame`, `Skins/DefaultSkin` |

### Layer Hierarchy + No-Upward-Import Rule (LOCKED)

```text
Higher layer (depends on lower)
       ▲
       │
   PRESENTATION    ── may require ──▶  Foundation, Core (read-only)
       │                                — MUST NOT require Feature siblings*
       │                                — MUST NOT require other Presentation*
       │
   FEATURE         ── may require ──▶  Foundation, Core
       │                                — MUST NOT require Presentation
       │                                — MUST NOT require Feature siblings except via Core
       │
   CORE            ── may require ──▶  Foundation
       │                                — MUST NOT require Feature
       │                                — MUST NOT require Presentation
       │
   FOUNDATION      ── may require ──▶  vendored, Wally packages, SharedConstants
                                       — MUST NOT require Core, Feature, Presentation

* Exceptions: read-only consumption via SharedConstants is always allowed.
  HUD reading CrowdStateClient (Presentation→Presentation) is allowed because
  CrowdStateClient is a layer-foundation cache, not a sibling Presentation system.
  ADR-0006 §Cross-Layer Reads clarifies.
```

**No-upward-import rule** — a layer may only require modules in same layer or lower. Each layer's `require` set is bounded by §Module Ownership (architecture.md §3).

**Cross-layer reads** — CrowdStateClient (Presentation in §3.4 ownership) is functionally a Foundation cache for client-side data. Presentation systems (HUD, Nameplate, FollowerEntity, VFXManager) require it freely. This is the sole "Presentation requires Presentation" exception, justified because CrowdStateClient owns no behaviour — purely state mirror. Any other Presentation→Presentation require must be flagged at code review.

### Forbidden Patterns Matrix (consolidates `CLAUDE.md` §Forbidden Patterns)

| Pattern | Architectural Justification | Enforcement |
|---|---|---|
| `require(ServerStorage.*)` from `ReplicatedStorage` / `ReplicatedFirst` | Server modules cannot exist on client (security + Roblox semantics) | L1 Roblox engine (returns nil/errors at runtime) |
| Direct `RemoteEvent` access by path or string literal | Bypasses Network wrapper; no enum safety; no rate-limit hooks | L2 code review + L3 Selene rule (planned) |
| Direct `DataStoreService` calls | Bypasses ProfileStore session-lock; corrupts data on duplicate-load | L2 code review |
| Direct `Humanoid.WalkSpeed` writes | Bypasses ValueManager composed-stat layer; conflicting writes silently overwrite | L2 code review |
| Client-side data mutation | All writes flow client → remote → server validate → ProfileStore → broadcast back | L2 code review (server-only modules unreachable from client by L1) |
| Magic strings for cross-module identifiers | No type safety; refactor breaks; search-unfriendly | L2 code review + L3 Selene rule (planned) |
| Multiple Scripts / LocalScripts beyond two entry points | Two-entry-point model violated; init order ambiguous | L2 code review |
| Wally package directly edited | Edits lost on `wally install`; breaks pin reproducibility | L2 code review |
| Vendored library directly modified | ProfileStore / Freeze upgrades become impossible without merge conflicts | L2 code review (allowed: bug-fix patches with explicit "VENDORED PATCH" comment block + tracking issue) |
| `tostring(player.UserId)` for crowdId computed in multiple places | crowdId computation must be one canonical helper per ADR-0001 + ADR-0004 | L2 code review (helper module recommended in `SharedConstants/CrowdId.luau`) |
| Folder-as-module without `init.luau` | Roblox does not auto-resolve folders without `init`; require fails | L1 Roblox engine |
| `--!nonstrict` or `--!nocheck` in `src/` | Project type-safety requires `--!strict`; only vendored libs may use looser modes | L2 code review + L3 Selene config |
| `task.spawn` / `task.defer` inside TickOrchestrator phase callback | ADR-0002 §forbidden_patterns `yielding_inside_tick_phase` — breaks tick atomicity | L2 code review |

### Two-Entry-Point Invariant

```text
Project must have EXACTLY two .server.luau Scripts with explicit RunContext:

  src/ReplicatedFirst/Source/start.server.luau      → RunContext: Client
  src/ServerScriptService/start.server.luau         → RunContext: Server

Both have a sibling .meta.json setting RunContext explicitly. All other logic
lives in ModuleScripts required from these two. No additional Scripts. No
LocalScripts. No StarterCharacterScripts. No StarterPlayerScripts custom code.
```

**Rationale**: deterministic init order, single ownership of bootstrap, easier to reason about loading lifecycle. ADR-level lock prevents drift as new systems are added (each new system extends one of the two entry points; never adds a third).

### Vendored vs Wally Policy

**Vendored libraries** (`src/ReplicatedStorage/Dependencies/`): ProfileStore, Freeze. Manual update process:

1. Identify upstream version (e.g. ProfileStore latest on creator forum)
2. Replace file contents in `Dependencies/`; commit with "vendored update: [name] [old-version] → [new-version]"
3. Run integration tests (TestEZ + manual session)
4. Add `VENDORED PATCH` block in code if local fix needed; track via project issue

**Wally packages** (`Packages/`): Promise, Janitor, TestEZ. Update process:

1. Update version pin in `wally.toml`
2. Run `wally install`
3. Commit changes to `Packages/_Index/...` + version-changed package folder
4. Never edit `Packages/` files directly

**Adding a new vendored library**: requires ADR amendment to add it to §Source Tree Map.
**Adding a new Wally package**: requires updating `wally.toml` + ADR amendment to list it in §Allowed Libraries (also reflected in `.claude/docs/technical-preferences.md`).

### Enforcement Layers (Defense-in-Depth)

| Layer | Mechanism | Catches |
|---|---|---|
| **L1** Roblox engine semantics | Service tree placement; client cannot resolve `ServerStorage` paths | Client-from-server requires (impossible by engine) |
| **L2** Code review | PR reviewer checks placement against §Source Tree Map + §Forbidden Patterns Matrix | Same-side placement violations, magic-string usage, direct DataStoreService, direct Humanoid writes |
| **L3** Selene custom rules (PLANNED — separate task) | `selene.toml` extension to flag forbidden imports | Direct RemoteEvent path access, magic-string CollectionService tags, `task.spawn` in phase callbacks |
| **L4** `/create-control-manifest` | Extracts §Source Tree Map + §Forbidden Patterns into flat sheet | Daily implementation reference; reduces L2 reviewer load |
| **L5** `/architecture-review` | Cross-checks ADR + GDD references against this ADR's matrix | New systems silently drifting from the layer hierarchy |
| **L6** `/story-readiness` | Validates story embeds correct module path + layer | Story-level violations before code is written |

### Rojo Project File Constraints

`default.project.json` (or equivalent) MUST map the source tree as follows:

```json
{
  "name": "Crowdsmith",
  "tree": {
    "$className": "DataModel",
    "ServerStorage": {
      "Source": { "$path": "src/ServerStorage/Source" }
    },
    "ServerScriptService": {
      "start": { "$path": "src/ServerScriptService/start.server.luau" }
    },
    "ReplicatedStorage": {
      "Source":       { "$path": "src/ReplicatedStorage/Source" },
      "Dependencies": { "$path": "src/ReplicatedStorage/Dependencies" },
      "Instances":    { "$path": "src/ReplicatedStorage/Instances" }
    },
    "ReplicatedFirst": {
      "Source": { "$path": "src/ReplicatedFirst/Source" }
    }
  }
}
```

Wally `Packages/` is mapped via Wally's own Rojo integration (auto-generated). Do not hand-map.

## Alternatives Considered

### Alternative 1: Convention-only (status quo via `CLAUDE.md`)

- **Description**: Keep all placement rules in `CLAUDE.md` §Source Layout + §Forbidden Patterns. No ADR.
- **Pros**: Zero ADR overhead. CLAUDE.md is loaded into every session automatically.
- **Cons**: CLAUDE.md is descriptive; ADRs are prescriptive. Stories cannot cite CLAUDE.md as the placement source per `/story-readiness` template (which expects ADR linkage). `/create-control-manifest` cannot extract placement rules from a markdown narrative. ADR-0004 has a forward dependency on this ADR for the firewall codification — no ADR means ADR-0004's enforcement model is incomplete.
- **Rejection Reason**: ADR-0004 already references this ADR explicitly. CLAUDE.md remains the day-to-day reference but the ADR provides the architectural-level lock that stories + manifest + review pipeline expect.

### Alternative 2: Per-system placement ADRs (one per module)

- **Description**: ADR-NNNN-CrowdStateServer-Placement, ADR-NNNN-MatchStateServer-Placement, etc.
- **Pros**: Per-system specificity.
- **Cons**: 30+ ADRs for placement alone. Massive maintenance overhead. No consolidated matrix for `/create-control-manifest`. Cross-system rules (no upward import, two-entry-point) have no owned-by location.
- **Rejection Reason**: Placement is a project-wide invariant, not a per-system decision.

### Alternative 3: Move forbidden-pattern matrix to control manifest only

- **Description**: ADR-0006 covers placement only; forbidden patterns live exclusively in the control manifest.
- **Pros**: Smaller ADR. Manifest is the daily reference anyway.
- **Cons**: Control manifest is a generated artifact — its rules need an ADR-level source. Forbidden patterns have architectural justification (CSM authority, Pillar 4, server authority); justification belongs in an ADR, not a manifest. ADR-0006 + manifest = two-step extract. ADR-only = one source.
- **Rejection Reason**: Patterns + their rationale belong in the ADR; manifest extracts them. Putting rationale in the manifest creates the same source-of-truth problem this ADR solves.

### Alternative 4: Strict-mode-only enforcement via Selene custom rules + CI

- **Description**: Skip ADR; encode all rules as Selene custom rules + a CI lint script.
- **Pros**: Hard runtime enforcement at PR time.
- **Cons**: Selene custom rules are non-trivial to author + maintain. Doesn't help during design (a new GDD can claim a placement that violates the rules; lint catches it after coding starts). Doesn't help `/architecture-review` or `/story-readiness`. Doesn't capture rationale for future maintainers.
- **Rejection Reason**: Lint is a complementary L3 enforcement layer, not a replacement for the ADR. ADR-0006 + planned Selene rule together give defense-in-depth.

## Consequences

### Positive

- ADR-level lock on the layer hierarchy + no-upward-import rule
- ADR-0004's L1 firewall reference becomes concrete (this ADR codifies it)
- `/create-control-manifest` has single canonical source for placement + forbidden patterns
- `/architecture-review` cross-checks new ADRs/GDDs against §Source Tree Map
- `/story-readiness` validates new module paths + layer assignment
- Forbidden patterns get architectural justification (not just "convention")
- Rojo project file constraints captured — prevents accidental remap that breaks placement firewall
- Vendored vs Wally policy explicit — upgrade procedure documented
- Two-entry-point invariant locked — prevents Script proliferation

### Negative

- Code-review burden — every new module PR requires §Source Tree Map check
- Rule density — §Forbidden Patterns Matrix has 13 rows; reviewers must internalise
- Drift risk between this ADR + `CLAUDE.md` + control manifest + Selene config (4 sources)
- Future Skin / Avatar / Banner systems have prescribed placement; deviation requires ADR amendment
- Vendored library upgrade is high-friction (manual replace + retest + commit)

### Risks

- **Risk 1 (LOW)** — `CLAUDE.md` and ADR-0006 drift over time. Mitigation: `/architecture-review` includes consistency check between the two; `/propagate-design-change` runs on either edit.
- **Risk 2 (MEDIUM)** — Selene custom rules (L3) deferred — code review is sole same-server enforcement until rules are written. Mitigation: `/create-control-manifest` extracts patterns into reviewer cheat-sheet; planned task to author Selene rules in Production phase.
- **Risk 3 (LOW)** — A new dependency (third-party library) appears that doesn't fit vendored or Wally classes. Mitigation: ADR amendment adds new placement class.
- **Risk 4 (LOW)** — Rojo project file gets edited without updating this ADR. Mitigation: `/architecture-review` audits `default.project.json` against §Rojo Project File Constraints.
- **Risk 5 (LOW)** — Test code (TestEZ) needs to mock server-only modules from client-side test fixtures. Mitigation: TestEZ runs server-side per project convention; cross-side test mocking deferred to dedicated test ADR if needed.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `CLAUDE.md` §Source Layout | "Rojo maps each subfolder to its Roblox service" | §Source Tree Map locks the canonical mapping at ADR level |
| `CLAUDE.md` §Shared vs server-only code | "client must never require from ServerStorage" | §Forbidden Patterns Matrix + §Enforcement Layers L1 |
| `CLAUDE.md` §Forbidden Patterns | 7 listed patterns | §Forbidden Patterns Matrix expands to 13 with architectural justification |
| `CLAUDE.md` §Two-entry-point model | "Everything boots from exactly two scripts" | §Two-Entry-Point Invariant |
| `CLAUDE.md` §Naming conventions | enum modules in `SharedConstants/` | §Source Tree Map enum class + §Forbidden Patterns Matrix magic-string row |
| `docs/architecture/architecture.md` §2.5 Layer-boundary rules | "No upward imports; client modules MUST NOT require ServerStorage" | §Layer Hierarchy + §Forbidden Patterns Matrix |
| `docs/engine-reference/roblox/replication-best-practices.md` §Placement Rules | "Remotes live under ReplicatedStorage" | §Source Tree Map Network class + §Network instance registry row |
| ADR-0001 §Decision | Server-authoritative architecture | §Source Tree Map server-only class + L1 firewall |
| ADR-0004 §Module Placement Firewall | "Roblox engine semantics enforce server-only require" | This ADR is the codification ADR-0004 references |
| `design/gdd/crowd-state-manager.md` §Server API | "server APIs in ServerStorage; client cache in ReplicatedStorage" | §Source Tree Map locks both placements |
| `.claude/docs/technical-preferences.md` §Allowed Libraries | "Promise, Janitor, TestEZ via Wally; ProfileStore + Freeze vendored" | §Vendored vs Wally Policy |

## Performance Implications

- **CPU (server)**: zero — placement rules are design-time + review-time enforced.
- **CPU (client)**: zero.
- **Memory**: zero overhead.
- **Load Time**: indirectly improved — two-entry-point model has deterministic init order, no Script proliferation overhead.
- **Network**: zero.

The defense-in-depth model deliberately moves enforcement off the runtime hot path onto the design + review + lint pipeline.

## Migration Plan

Project is at pre-production stage; most listed modules are not yet implemented. Migration steps:

1. **Audit existing template-provided code** — verify `src/ServerStorage/Source/`, `src/ReplicatedStorage/Source/`, `src/ReplicatedFirst/Source/`, `src/ServerScriptService/` match §Source Tree Map. Existing template should already be compliant; flag any deviations.
2. **Audit Rojo project file** — verify `default.project.json` matches §Rojo Project File Constraints. Update if needed.
3. **Author missing SharedConstants files** — `AssetId.luau`, `CrowdConfig.luau`, `MatchConfig.luau`, `ChestConfig.luau`, `MatchState.luau`, `CrowdClientConfig.luau`, `DeltaSource.luau`, `VFXEffectId.luau`, `CollectionServiceTag/ChestTag.luau`. These are listed as "NEW" in §Source Tree Map and tracked as Foundation epic stories.
4. **Author `Network/RemoteName/UnreliableRemoteEventName.luau`** — required by ADR-0001/0002 prereq.
5. **Code review checklist update** — add §Forbidden Patterns Matrix as PR review checklist item.
6. **`/create-control-manifest`** runs after this ADR is Accepted — extracts §Source Tree Map + §Forbidden Patterns Matrix.
7. **Selene custom rules** — deferred; tracked as Production-phase task.

## Validation Criteria

- [ ] `grep -rEl "require\\(.*ServerStorage" src/ReplicatedStorage src/ReplicatedFirst` returns zero matches at any commit
- [ ] `grep -rEl "require\\(.*Packages" src/` matches only `ReplicatedStorage` consumers (Wally is shared; never `ServerStorage`-only consumers — ProfileStore + Freeze are vendored, not Wally)
- [ ] `find src -name "*.server.luau" -o -name "*.client.luau"` returns exactly two `.server.luau` files (the two entry points; no `.client.luau` files)
- [ ] `find src -name "*.luau" ! -path "*/Dependencies/*" -exec grep -L "^--!strict" {} \;` returns zero matches (every project Luau file has `--!strict`)
- [ ] Every cross-module identifier passes through `SharedConstants/` — verified by Selene rule (planned) or manual audit
- [ ] `default.project.json` matches §Rojo Project File Constraints exactly
- [ ] `wally.toml` lists Promise, Janitor, TestEZ at versions matching `docs/engine-reference/roblox/VERSION.md` Toolchain Pins
- [ ] `aftman.toml` lists Rojo, Selene, Wally at pinned versions
- [ ] `/create-control-manifest` produces a section that matches §Forbidden Patterns Matrix verbatim

## Related Decisions

- **ADR-0001** Crowd Replication Strategy — establishes server-authoritative model that requires placement firewall
- **ADR-0002** TickOrchestrator — server-only by §Source Tree Map; phase callbacks must follow placement
- **ADR-0003** Performance Budget — references module placement implicitly (per-system budgets assume single-server-module ownership)
- **ADR-0004** CSM Authority — explicitly references this ADR for module placement firewall codification
- **Expected downstream**:
  - ADR-0005 MSM/RoundLifecycle Split — both modules placed per §Source Tree Map server-only class
  - ADR-0008 NPC Spawner Authority — placed per §Source Tree Map server-only class
  - ADR-0010 Server-Authoritative Validation Policy — operates within the placement firewall this ADR codifies
  - ADR-0011 Persistence Schema — PlayerData paths follow §Source Tree Map (template-provided)
  - Future Skin System ADR — must follow §Source Tree Map (placement TBD: client-side renderer in `ReplicatedStorage/Source/SkinSystem/Client.luau`, server-side stub in `ServerStorage/Source/SkinSystem/init.luau` if any server validation needed)

## Engine Specialist Validation

Skipped — Roblox has no dedicated engine specialist in this project (per `.claude/docs/technical-preferences.md`). Module placement is stable Roblox semantics with extensive creator-forum documentation; no validation risk.

## Technical Director Strategic Review

Skipped — Lean review mode (TD-ADR not a required phase gate in lean per `.claude/docs/director-gates.md`).
