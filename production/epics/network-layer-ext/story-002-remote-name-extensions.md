# Story 002: RemoteEventName + RemoteFunctionName extensions

> **Epic**: network-layer-ext
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 2–3 hours (enum extension, 22 entries)

## Context

**GDD**: N/A — additions enumerated by `docs/architecture/architecture.md` §5.7 (Wire contracts) drawn from CSM, MSM, NPC Spawner, Chest, Relic, VFX Manager GDDs
**Requirement**: TR-network-??? (no TR registered)

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: Cross-module identifiers via `SharedConstants/` enums; magic strings forbidden. Story expands `RemoteEventName` + `RemoteFunctionName` enums per architecture.md §5.7 wire contract list.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Standard `RemoteEvent` + `RemoteFunction` — already used template-side. No post-cutoff surface in this story.

**Control Manifest Rules (Foundation layer)**:
- Required: Cross-module identifiers via SharedConstants/ enums (ADR-0006)
- Forbidden: Direct path access to `RemoteEvent` instances (ADR-0006)

---

## Acceptance Criteria

*Derived from architecture.md §5.7 wire contracts table (verbatim list):*

- [ ] AC-1: `src/ReplicatedStorage/Source/Network/RemoteName/RemoteEventName.luau` updated with these new entries: `MatchStateChanged`, `ParticipationChanged`, `CrowdCreated`, `CrowdDestroyed`, `CrowdEliminated`, `CrowdCountClamped`, `CrowdRelicChanged`, `ChestInteract`, `ChestDraftOffer`, `ChestDraftPick`, `ChestStateChanged`, `ChestPeelOff`, `ChestDraftOpenFX`, `ChestOpenBurst`, `Absorbed`, `HueShift`, `CollisionContactEvent`, `RelicGrantVFX`, `RelicExpireVFX`, `RelicDraftPick`, `AFKToggle`, `NpcPoolBootstrap` (22 entries)
- [ ] AC-2: New `src/ReplicatedStorage/Source/Network/RemoteName/RemoteFunctionName.luau` enum module exists (or extends existing) with entry `GetParticipation`
- [ ] AC-3: All new `RemoteEventName` entries appear as `RemoteEvent`-classed children of `ReplicatedStorage.RemoteEvents` after server boot
- [ ] AC-4: `RemoteFunctionName.GetParticipation` appears as a `RemoteFunction`-classed child of `ReplicatedStorage.RemoteFunctions` after server boot
- [ ] AC-5: Enum values are unique within their enum (no duplicates); enum keys are unique within their enum
- [ ] AC-6: `--!strict` type checks pass on the modified files
- [ ] AC-7: No new magic-string remote refs introduced anywhere in `src/` outside the enum + `Network/init.luau` (grep gate)

---

## Implementation Notes

*Derived from architecture.md §5.7 + ADR-0006 + existing template pattern:*

- Source list is canonical — copy verbatim from architecture.md §5.7 to avoid drift. If a remote is missing from §5.7 but needed by a downstream consumer GDD, that's a separate amendment story; do not add ad-hoc here.
- Existing `RemoteEventName.luau` already follows enum pattern; append entries alphabetically OR grouped-by-system (existing file convention determines). Match whichever the file currently uses.
- `RemoteFunctionName.luau` may not exist yet — check first. If absent, create with `--!strict` and a single entry `GetParticipation`. Extend boot logic in `Network/init.luau` to walk this new enum and create RemoteFunction instances.
- Each entry's value MUST equal its key (e.g. `RemoteEventName.AFKToggle = "AFKToggle"`). This is the project convention — confirms via existing `RemoteEventName.luau` template content.
- Direction comments per §5.7 (e.g. `-- server → all clients reliable`) are recommended in the enum source for reviewer clarity but not enforced by tests.

---

## Out of Scope

- Story 001: Unreliable wrapper + UnreliableRemoteEventName (handled in parallel story)
- Story 003: Buffer codec
- Story 004 / 005: RemoteValidator + RateLimitConfig
- Per-remote handler wiring (consumer epics — CSM, MSM, Chest, etc.)

---

## QA Test Cases

- **AC-1 / AC-2**: enum completeness
  - Given: working tree post-implementation
  - When: load `RemoteEventName` + `RemoteFunctionName` modules
  - Then: every name from architecture.md §5.7 list present (test asserts against literal Luau-table list)
  - Edge cases: missing entry → fail with name; extra entry not in §5.7 → warn (advisory; may indicate amendment needed)

- **AC-3 / AC-4**: instance creation at boot
  - Given: server harness boot
  - When: inspect `ReplicatedStorage.RemoteEvents` + `ReplicatedStorage.RemoteFunctions`
  - Then: every enum entry has a matching ClassName child
  - Edge cases: ClassName mismatch → fail; duplicate child → fail

- **AC-5**: uniqueness
  - Given: enum tables
  - When: build value-Set + key-Set
  - Then: |Set| == |table| (no duplicates)
  - Edge cases: typo collision (`ChestOpen` vs `ChestOpenBurst`) → must not collide

- **AC-6**: strict type-check
  - Standard `--!strict` Selene pass

- **AC-7**: magic-string grep gate
  - Given: working tree
  - When: `grep -rn "fireServer\\(\"\\|connectEvent(\"\\|fireAllClients(\"" src/ --exclude-dir=Dependencies` (raw remote calls with string literal)
  - Then: zero matches (all calls go via `RemoteEventName.X` enum lookup)
  - Edge cases: any match → fail

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/network/remote-name-enum_test.luau` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (parallel with Story 001)
- Unlocks: Story 003 (codec uses `UnreliableRemoteEventName.CrowdStateBroadcast` from story 001 + reliable companions from this story); all consumer-system stories that fire/connect any of the new remotes
