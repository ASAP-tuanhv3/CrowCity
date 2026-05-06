# Story 011: Delete RelicSystemStub + selene clean post-removal

> **Epic**: RelicSystem (Relic System)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: 1h
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/relic-system.md` §Definition of Done
**Requirement**: epic Definition of Done bullet "RelicSystemStub deleted from `_PhaseStubs/`; selene clean post-removal"
*(No specific TR-ID — closure task.)*

**ADR Governing Implementation**: ADR-0006 Module Placement Rules
**ADR Decision Summary**: Sprint 3 introduced `_PhaseStubs/RelicSystemStub.luau` to satisfy Phase 2 callback registration. With Stories 001-010 complete, the stub is replaced by the full RelicSystem module. Stub file MUST be deleted; Phase 2 wiring re-pointed to real module; selene + asset-id audit + persistence audit ALL pass.

**Engine**: Roblox | **Risk**: LOW
**Engine Notes**: Tooling-only story.

**Control Manifest Rules:**
- Required: Selene clean (ADR-0006 §L3 planned Production phase)
- Required: asset-id audit + persistence audit pass on every commit

---

## Acceptance Criteria

*From GDD epic DoD + closing tasks:*

- [ ] **Stub file deleted**: `src/ServerStorage/Source/_PhaseStubs/RelicSystemStub.luau` no longer exists.
- [ ] **Phase 2 callback re-pointed**: `start.server.luau` registers `RelicSystem.tickPhase2` (from Story 003) instead of stub.
- [ ] **`selene src/`**: 0 errors, ≤ pre-existing warning count.
- [ ] **`bash tools/audit-asset-ids.sh`**: exit 0.
- [ ] **`bash tools/audit-persistence.sh`**: exit 0.
- [ ] **Test suite**: all tests pass post-stub-removal (no test imports stub).

---

## Implementation Notes

*Derived from ANATOMY §Stubs pattern + Sprint 3 closure notes:*

- Delete: `git rm src/ServerStorage/Source/_PhaseStubs/RelicSystemStub.luau`.
- Update `src/ServerScriptService/start.server.luau` Phase 2 wiring:
  - Old: `local RelicSystemStub = require(...) ; TickOrchestrator.registerPhase(2, RelicSystemStub.tickPhase2)`
  - New: `local RelicSystem = require(ServerStorage.Source.RelicSystem); RelicSystem.init(deps); TickOrchestrator.registerPhase(2, RelicSystem.tickPhase2)`.
- Search-replace any other module that imports stub (likely none beyond start.server.luau).
- Run all 3 audits + selene before committing.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 001-010: full RelicSystem implementation (this story replaces stub with real module).

---

## QA Test Cases

- **Stub removed**:
  - Given: post-Stories 001-010
  - When: `ls src/ServerStorage/Source/_PhaseStubs/`
  - Then: RelicSystemStub.luau absent
  - Edge cases: re-add via stash → fail.

- **Phase 2 wiring**:
  - Given: start.server.luau diff
  - When: grep for `RelicSystemStub`
  - Then: 0 matches; `RelicSystem` import + Phase 2 register present
  - Edge cases: tests/ might still mention old stub — clean those up.

- **Selene clean**:
  - Given: `selene src/`
  - When: run
  - Then: 0 errors; warnings ≤ baseline
  - Edge cases: pre-existing 7 warnings (per Sprint 4 baseline) acceptable; new warnings fail.

- **Audits**:
  - Given: audit scripts
  - When: each runs
  - Then: exit 0
  - Edge cases: introduces magic asset-id or persistence key → fail (intended).

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-2026-XX-XX.md` post-stub-removal — smoke check pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-010 (full RelicSystem implementation).
- Unlocks: Relic epic DoD.
