# Story 003: Populate Particle + Sound inventory + retire Sounds.luau

> **Epic**: asset-id-registry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-27
> **Estimate**: 2–3 hours
> **Completed**: 2026-04-27

## Context

**GDD**: VFX Manager GDD `design/gdd/vfx-manager.md` (V/A 12-row catalog) + game-concept `design/gdd/game-concept.md` Pillar 1 audio cues + Absorb / Chest / Relic / Collision GDDs (event names that consumers fire)
**Requirement**: TR-asset-id-??? (Foundation infra — no TR registered)

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: All particle + sound references resolve through `SharedConstants/AssetId`. Story 001 reserved empty sub-tables; this story populates them and retires the template-stub `Sounds.luau`.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: ParticleEmitter texture refs and Sound `SoundId` props both use `rbxassetid://N`. Volume / Looped / per-emitter rate are NOT held in this registry — consumers wrap the URI with their own playback config (see VFX Manager GDD §C and Audio Manager GDD when authored).

**Control Manifest Rules (Foundation layer)**:
- Required: `AssetId enum for every particle/sound reference` (control-manifest.md L29)
- Required: `--!strict` (global)
- Forbidden: `Magic strings cross-module` (control-manifest.md L47)

---

## Acceptance Criteria

*Derived from VFX Manager GDD §V/A catalog + game-concept audio inventory + downstream consumer effect names:*

- [ ] AC-1: `AssetId.Particle` populated with the 12 effect IDs from VFX Manager GDD V/A: `AbsorbSnap`, `CollisionContactRing`, `ChestPeelMarch`, `ChestOpenT1Confetti`, `ChestOpenT2Confetti`, `ChestDraftOpen`, `RelicGrantCommon`, `RelicGrantRare`, `RelicGrantEpic`, `RelicExpire`, `PeelVanish`, `MaxCrowdFlash`
- [ ] AC-2: `AssetId.Sound` populated with MVP audio cues: `AbsorbCue`, `ChestOpenT1Cue`, `ChestOpenT2Cue`, `RelicGrantCommonCue`, `RelicGrantRareCue`, `RelicGrantEpicCue`, `MatchStartCue`, `MatchEndCue`, `EliminationCue`, `FinalMinuteCue` (10 entries)
- [ ] AC-3: All values follow `rbxassetid://N` format (placeholder `rbxassetid://0` allowed pre-asset-upload)
- [ ] AC-4: All keys follow PascalCase per CLAUDE.md §Naming
- [ ] AC-5: `src/ReplicatedStorage/Source/SharedConstants/Sounds.luau` deleted; any references in `src/` updated to point at `AssetId.Sound.*` equivalents (zero `require(...Sounds)` matches via grep)
- [ ] AC-6: Top-of-file comment in `AssetId.luau` cross-references VFX Manager GDD §V/A row IDs and game-concept §Audio cue inventory so future readers can trace each entry to its source spec

---

## Implementation Notes

*Derived from ADR-0006 + VFX Manager GDD + game-concept:*

- Particle effect IDs MUST match exactly the names VFX Manager GDD §V/A uses — those names are also the lookup keys VFXManager will use when consumer systems call `playEffect(effectId)`. A typo here breaks the wire contract.
- Sound IDs are the names Audio Manager (VS+) will look up — naming convention `*Cue` suffix per game-concept.
- `Sounds.luau` retirement: it is a template stub with only TODO comments (verified via Read). No production code currently requires it. Run `grep -rn "require.*Sounds" src/` before deletion to confirm zero callers; if any caller exists, update it to `AssetId.Sound.*` first.
- Volume / Looped / per-emitter rate are NOT in this registry. Consumers wrap:
  ```luau
  local sound = Instance.new("Sound")
  sound.SoundId = AssetId.Sound.AbsorbCue
  sound.Volume = 0.7  -- consumer-owned
  ```
- ParticleEmitter texture refs work the same way — VFXManager pool-creates emitters and sets `Texture = AssetId.Particle.AbsorbSnap`.

---

## Out of Scope

*Handled elsewhere:*

- Story 002: Mesh inventory
- Story 004: Static-audit gate
- Real asset upload (art / audio pipeline)
- VFXManager + AudioManager wire-up (their own future epics)
- Per-effect tuning (suppression tier, particle-count cap) — owned by VFX Manager GDD, not this registry

---

## QA Test Cases

- **AC-1**: particle inventory completeness
  - Given: `AssetId.luau` loaded
  - When: read `AssetId.Particle`
  - Then: every effect ID from VFX Manager GDD V/A is present (test asserts against literal 12-name list)
  - Edge cases: missing key → fail with name; extra key → fail (registry tightly scoped to GDD)

- **AC-2**: sound inventory completeness
  - Given: `AssetId.Sound` table
  - When: iterate
  - Then: 10 expected `*Cue` keys present; all string values in `rbxassetid://N` form
  - Edge cases: missing cue → fail; non-`*Cue`-suffix key → fail (suffix is contract)

- **AC-3 / AC-4**: format + naming integrity
  - Same pattern as story 002 (`^rbxassetid://%d+$` + PascalCase regex)

- **AC-5**: Sounds.luau retirement
  - Given: working tree
  - When: `grep -rln "Sounds.luau\|require.*\\.SharedConstants\\.Sounds" src/`
  - Then: zero matches; file `src/ReplicatedStorage/Source/SharedConstants/Sounds.luau` does not exist
  - Edge cases: stale require in any client/server module → fail before delete

- **AC-6**: documentation cross-ref
  - Given: `AssetId.luau` opened
  - When: scan top-of-file comment block
  - Then: comment cites `design/gdd/vfx-manager.md §V/A` and `design/gdd/game-concept.md` audio inventory by section ID
  - Edge cases: comment missing → fail (manual review at `/story-done`)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/asset-id/particle-sound-inventory_test.luau` — must exist and pass.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (skeleton must exist with `Particle = {}` and `Sound = {}` reserved)
- Unlocks: VFX Manager epic, Audio Manager epic (VS+)

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 6/6 passing
**Deviations**:
- ADVISORY (user-approved Path A scope conflict resolution): `src/ReplicatedStorage/Source/SoundManager.luau` modified — out of stated scope per Out of Scope §"VFXManager + AudioManager wire-up". Story Implementation Notes incorrectly claimed "no production code currently requires Sounds.luau" — SoundManager required it as a `{[name] = {SoundId, Volume, Looped}}` lookup. Migrated to `AssetId.Sound` (string-only contract per ADR-0006); per-cue Volume / Looped defaults now consumer-owned inside SoundManager (`DEFAULT_SFX_VOLUME = 0.7`, `DEFAULT_MUSIC_VOLUME = 0.5`). Functional API surface preserved; rich per-cue config dict dropped (was always-empty template stub).
**Test Evidence**: Logic story — unit test at `tests/unit/asset-id/particle-sound-inventory_test.luau` (7 test functions, all 6 ACs covered with AC-5/AC-6 marked ADVISORY proxies — full grep + manual review at /story-done passes)
**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` (86 L) — Particle = 12 entries (VFX Manager GDD §V/A names), Sound = 10 entries (*Cue suffix), top-of-file comment cross-refs both source GDDs
- `src/ReplicatedStorage/Source/SoundManager.luau` (143 L) — **OOS-advisory** migrated from Sounds.luau to AssetId.Sound; introduced `applySound()` helper with consumer-owned Volume / Looped defaults; preserved 7-method public API
- `src/ReplicatedStorage/Source/SharedConstants/Sounds.luau` — DELETED (was template stub with all entries commented)
- `tests/unit/asset-id/particle-sound-inventory_test.luau` (136 L, 7 test fns) — TestEZ unit test; AC-1 + AC-2 enforce literal name lists + count assertions; AC-5 + AC-6 marked ADVISORY (file-system / comment introspection not TestEZ-runtime-introspectable; verified at /story-done via Bash grep + manual review)

**Manifest Version**: 2026-04-27 (current ✓ no staleness)

**AC-5 grep evidence**: `grep -rn "require.*Sounds\b" src/` → exit 1 (zero matches). `ls src/ReplicatedStorage/Source/SharedConstants/Sounds.luau` → No such file or directory.

**Unblocks**: Story 004 (Static-audit gate). VFX Manager epic, Audio Manager epic (VS+) now have stable AssetId.Particle + AssetId.Sound contracts to wire into.
