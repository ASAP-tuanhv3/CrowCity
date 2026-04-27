# Story 004: Asset ID static-audit gate (grep script)

> **Epic**: asset-id-registry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Manifest Version**: 2026-04-27
> **Estimate**: 1–2 hours
> **Completed**: 2026-04-27

## Context

**GDD**: N/A — verification clause from ADR-0006
**Requirement**: TR-asset-id-??? (Foundation infra — no TR registered)

**ADR Governing Implementation**: ADR-0006 — Module Placement Rules + Layer Boundary Enforcement
**ADR Decision Summary**: ADR-0006 §Verification Required clause (A) mandates "Static grep audit on first MVP integration — `grep -r "rbxassetid" src/` from outside `SharedConstants/AssetId.luau` returns zero matches". This story implements that gate as a runnable script.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Audit is shell-script + `grep`; no engine API surface. Selene custom rule listed in ADR-0006 §L3 is deferred to Production phase per active.md note "Selene custom rules (L3) remain deferred to Production-phase task".

**Control Manifest Rules (Foundation layer)**:
- Required: `AssetId enum for every model/texture/particle/sound reference` (control-manifest.md L29)
- Forbidden: `Magic strings cross-module` (control-manifest.md L47)
- Defense-in-depth: this story implements ADR-0006 §Verification Required clause (A); Selene rule (L3) deferred

---

## Acceptance Criteria

*Derived from ADR-0006 §Verification Required clause (A) + practical CI hookup:*

- [ ] AC-1: `tools/audit-asset-ids.sh` exists, is executable (`chmod +x`), and prints a banner identifying its purpose + the source ADR (ADR-0006 §Verification Required A)
- [ ] AC-2: Script runs `grep -rn "rbxassetid://" src/` filtered to exclude (a) the registry file itself `src/ReplicatedStorage/Source/SharedConstants/AssetId.luau` and (b) the vendored `src/ReplicatedStorage/Dependencies/` tree
- [ ] AC-3: Exit code 0 when zero matches found in non-exempt paths; exit code 1 when any match found, with each matching file:line printed
- [ ] AC-4: When run on the current clean tree (post-stories 001+002+003), the script exits 0
- [ ] AC-5: When a synthetic test plant is added (a literal `rbxassetid://12345` in any non-exempt `src/` file), the script exits 1 and prints that file:line
- [ ] AC-6: Documented in repo `README.md` (or `CLAUDE.md` Asset section) with one-line usage `bash tools/audit-asset-ids.sh` so contributors can run locally before commit
- [ ] AC-7: Script is idempotent — running multiple times produces identical output for identical tree state

---

## Implementation Notes

*Derived from ADR-0006 §Verification Required clause (A):*

- Place script under `tools/` per project convention (see `tools/` dir for existing build/pipeline tools).
- Use POSIX-portable shell (no `bash`-isms beyond `[[` if needed) since contributor toolchain is mixed (macOS / Linux). Test on the macOS dev box (project primary platform).
- Exempt paths via `--exclude-dir=Dependencies` + `--exclude=AssetId.luau` flags on `grep`. Avoid blacklist-via-pipe-and-`grep -v` which is fragile.
- Print summary line at end: `[OK] N rbxassetid:// references found, all in approved registry` (exit 0) OR `[FAIL] N raw rbxassetid:// references outside registry — see above` (exit 1).
- Selene custom rule listed in ADR-0006 §L3 is intentionally OUT OF SCOPE here — deferred per active.md status note.
- CI integration (GitHub Actions step) deferred to `/test-setup` epic story; this script must work standalone first.
- Synthetic test plant (AC-5) is a one-line throwaway used during development verification; document the verification in evidence doc, do not commit the plant.

Reference one-liner sketch:
```sh
#!/usr/bin/env bash
# tools/audit-asset-ids.sh — ADR-0006 §Verification Required clause (A)
matches=$(grep -rn --exclude-dir=Dependencies --exclude=AssetId.luau \
                  "rbxassetid://" src/)
if [ -z "$matches" ]; then
  echo "[OK] No raw rbxassetid:// references outside registry"
  exit 0
else
  echo "$matches"
  echo "[FAIL] Raw rbxassetid:// references outside SharedConstants/AssetId.luau"
  exit 1
fi
```

---

## Out of Scope

*Handled elsewhere — do not implement here:*

- Stories 001 / 002 / 003: registry skeleton + inventory
- `/test-setup` epic: GitHub Actions step that runs this script on PRs (CI hookup deferred)
- Selene custom rule (ADR-0006 §L3) — Production-phase deferred
- Real asset upload (art / audio pipeline)

---

## QA Test Cases

- **AC-1 / AC-2**: script structure
  - Given: `tools/audit-asset-ids.sh` written
  - When: invoke with `--help` or read top-of-file comment
  - Then: banner cites ADR-0006 §Verification Required A
  - Edge cases: missing shebang → fail; non-executable → fail

- **AC-3 / AC-4**: clean-tree pass
  - Given: working tree post-stories 001/002/003 (only `AssetId.luau` contains `rbxassetid://` strings)
  - When: `bash tools/audit-asset-ids.sh; echo $?`
  - Then: exit code 0 + `[OK]` summary line printed
  - Edge cases: tree has no `src/` → script must still succeed gracefully

- **AC-5**: dirty-tree fail (synthetic plant)
  - Given: clean tree
  - When: append a line `local _ = "rbxassetid://99999"` to any non-exempt module (e.g. `src/ReplicatedStorage/Source/Network/init.luau`); run script
  - Then: exit code 1 + the planted file:line printed + `[FAIL]` summary
  - Cleanup: revert the plant before continuing development
  - Edge cases: plant inside `Dependencies/` → script must NOT fail (exemption holds)

- **AC-6**: documentation
  - Given: repo `README.md` or `CLAUDE.md`
  - When: search for `audit-asset-ids.sh`
  - Then: one or more references with usage line present
  - Edge cases: doc references stale path → fail at `/story-done` review

- **AC-7**: idempotency
  - Given: clean tree
  - When: run script twice, capture both outputs
  - Then: outputs identical
  - Edge cases: trailing whitespace differences → fail (script must produce stable output)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `tools/audit-asset-ids.sh` (the artifact itself)
- Smoke check pass: `production/qa/evidence/asset-id-audit-evidence.md` documenting the AC-4 + AC-5 verification runs (clean PASS + synthetic-plant FAIL)
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (registry must exist for AC-4 clean-tree pass to be meaningful)
- Recommended: stories 002 + 003 land first so AC-4 covers the real populated registry, not just the empty-sub-table skeleton
- Unlocks: `/test-setup` story that adds the script as a CI step

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 7/7 passing (all ACs verified end-to-end via smoke run)
**Deviations**:
- ADVISORY: AC-2 literal wording vs implementation. Story spec says `grep -rn "rbxassetid://" src/`; implementation uses `grep -rnE --include="*.luau" --exclude-dir=Dependencies --exclude=AssetId.luau "rbxassetid://[0-9]+"`. Two refinements: (a) `--include="*.luau"` filter scopes audit to Luau modules only — pre-existing template `.rbxm` binaries (LoadingScreenPrefab, Bundle*.rbxm, GuiPrefabs/*.rbxm) and `.model.json` Rojo instance descriptors (Sky.model.json, SoundEffects/*.model.json) ship with literal asset IDs by Rojo design and are NOT Luau modules governed by ADR-0006 §V-A; (b) regex tightened to require ≥1 digit after `://` so the legitimate URI-scheme prefix constant in `SharedConstants/PlayerFacingString.luau:12` (`Prefix = "rbxassetid://"` for runtime concatenation) does not trigger false positives. Both refinements match story intent — AC-5 plant scenario explicitly says "any non-exempt **module**" (modules = .luau code). Rationale documented inline in script header + smoke evidence doc.

**Test Evidence**: Config/Data story — smoke check pass at `production/qa/evidence/asset-id-audit-evidence.md` (full run logs for AC-4 clean PASS + AC-5 synthetic-plant FAIL + AC-7 idempotency).

**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `tools/audit-asset-ids.sh` (new, ~50 L, mode 755) — POSIX bash; resolves repo root from script location; produces `[OK]` / `[FAIL]` summary lines + counts; exit 0 / 1 contract
- `CLAUDE.md` (Technology Stack section) — added `Asset-ID audit` bullet with usage line + ADR cite + when-to-run guidance (AC-6)
- `production/qa/evidence/asset-id-audit-evidence.md` (new, smoke evidence — Config/Data story type required artifact)

**Manifest Version**: 2026-04-27 (current ✓ no staleness)

**Verification runs (recap)**:
- AC-4 clean tree: `[OK] No raw rbxassetid:// references outside SharedConstants/AssetId.luau` — exit 0
- AC-5 synthetic plant `local _AUDIT_PLANT = "rbxassetid://99999"` injected at `Network/init.luau:165`: detected at correct file:line, `[FAIL] 1 raw rbxassetid:// reference(s) found...` — exit 1; plant cleanly reverted (NOT committed)
- AC-7 two-run idempotency: byte-identical stdout + identical exit codes

**Unblocks**: `/test-setup` epic story that wires `tools/audit-asset-ids.sh` into GitHub Actions PR-gate. Asset-id-registry epic now COMPLETE (4/4 stories Complete).
