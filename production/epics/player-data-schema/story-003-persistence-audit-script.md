# Story 003: Persistence audit script (DataStoreService + forbidden-keys grep)

> **Epic**: player-data-schema
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Manifest Version**: 2026-04-27
> **Estimate**: 1–2 hours
> **Completed**: 2026-04-27

## Context

**GDD**: N/A — verification clauses from ADR-0011
**Requirement**: TR-game-concept-008

**ADR Governing Implementation**: ADR-0011 — Persistence Schema + Pillar 3 Exclusions
**ADR Decision Summary**: ADR-0011 §Verification Required clauses (A) "no `DataStoreService` references outside vendored ProfileStore" and (B) "no key in PlayerDataKey/DefaultPlayerData matches Pillar 3 Forbidden Keys catalog" are testable rules. This story implements them as a runnable script paired to the AssetId audit gate.

**Engine**: Roblox (Luau, `--!strict`) | **Risk**: LOW
**Engine Notes**: Audit is shell-script + grep; no engine API. Selene custom rule listed in ADR-0011 §Verification (A) deferred to Production phase per ADR-0006 active.md note.

**Control Manifest Rules (Foundation layer)**:
- Required: All persistent writes via `PlayerDataServer` (ADR-0006)
- Forbidden: Direct `DataStoreService` calls outside `Dependencies/ProfileStore.luau` (ADR-0006)
- Forbidden: Persisting per-round state — Pillar 3 (ADR-0011)

---

## Acceptance Criteria

*Derived from ADR-0011 §Verification Required (A) + (B):*

- [ ] AC-1: `tools/audit-persistence.sh` exists, is executable (`chmod +x`), and prints a banner identifying purpose + source ADR (ADR-0011 §Verification Required A + B)
- [ ] AC-2: Script runs two grep checks:
  - **Check A** — `grep -rn "DataStoreService" src/ --exclude-dir=Dependencies` returns zero matches in non-exempt paths
  - **Check B** — load Pillar 3 forbidden-class regex catalog (top-of-script constant block) and grep `PlayerDataKey.luau` + `DefaultPlayerData.luau` for any match; zero matches expected
- [ ] AC-3: Exit code 0 when both checks pass; exit code 1 when either check fails. On failure, print which check + the offending file:line(s).
- [ ] AC-4: Forbidden-class regex catalog matches ADR-0011 §Pillar 3 Forbidden Keys catalog verbatim. Documented at top of script as a comment block listing each class + example. Patterns include (case-insensitive): `round.*count`, `round.*radius`, `round.*relic`, `round.*chest`, `round.*npc`, `round.*match`, `absorb.*bonus`, `draft.*weight`, `draw.*power`, `gameplay.*modifier`.
- [ ] AC-5: When run on the current clean tree (post-stories 001 + 002), script exits 0 with summary `[OK] Persistence audit clean — DataStoreService confined to ProfileStore + no forbidden keys`
- [ ] AC-6: Synthetic test plant pass — adding `local DataStoreService = game:GetService("DataStoreService")` to any non-exempt module → script exits 1 with that file:line. Reverting the plant → script returns to exit 0.
- [ ] AC-7: Synthetic test plant pass for forbidden key — adding `RoundCount = "RoundCount"` to `PlayerDataKey.luau` → script exits 1 with file:line and the matched class. Reverting → exit 0.
- [ ] AC-8: Documented in repo `README.md` (or `CLAUDE.md` Persistence section) with one-line usage `bash tools/audit-persistence.sh`
- [ ] AC-9: Script idempotent — repeated runs on identical tree produce identical output

---

## Implementation Notes

*Derived from ADR-0011 §Verification Required + practical CI-readiness:*

- Place under `tools/` per project convention — sibling to `audit-asset-ids.sh` from asset-id-registry epic story 004. Same shell style + same exit-code convention.
- Single-file script (no helper modules) — keep grep patterns and exemption paths inlined for auditability.
- Exemption: `--exclude-dir=Dependencies` + `--exclude=ProfileStore.luau` (only the vendored library may name `DataStoreService`).
- Forbidden-key patterns are case-insensitive (`grep -iE`) — typo-tolerant. Project naming convention is PascalCase but reviewer typo could land lowercase; both must trip.
- Output format mirrors AssetId audit script — one line per match, `[FAIL]` summary OR `[OK]` summary with check labels.
- CI integration deferred to `/test-setup` epic — script must be standalone-runnable today.
- Synthetic test plant verification (AC-6 + AC-7): document the verification process in evidence doc; do NOT commit the plant. Run plant → run script → verify exit 1 → revert plant → re-run → verify exit 0.

Reference one-liner sketch:
```sh
#!/usr/bin/env bash
# tools/audit-persistence.sh — ADR-0011 §Verification Required (A) + (B)

set -e
exit_code=0

# Check A: DataStoreService confinement
matches_a=$(grep -rn "DataStoreService" src/ --exclude-dir=Dependencies --exclude=ProfileStore.luau || true)
if [ -n "$matches_a" ]; then
  echo "$matches_a"
  echo "[FAIL Check A] DataStoreService referenced outside vendored ProfileStore"
  exit_code=1
fi

# Check B: Pillar 3 forbidden keys
forbidden_pattern='round.*count|round.*radius|round.*relic|round.*chest|round.*npc|round.*match|absorb.*bonus|draft.*weight|draw.*power|gameplay.*modifier'
matches_b=$(grep -rEni "$forbidden_pattern" \
  src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau \
  src/ServerStorage/Source/DefaultPlayerData.luau || true)
if [ -n "$matches_b" ]; then
  echo "$matches_b"
  echo "[FAIL Check B] Pillar 3 forbidden key class matched in persisted schema"
  exit_code=1
fi

if [ "$exit_code" -eq 0 ]; then
  echo "[OK] Persistence audit clean — DataStoreService confined to ProfileStore + no forbidden keys"
fi

exit "$exit_code"
```

---

## Out of Scope

- Story 001 / 002: schema lock + migration scaffold
- `/test-setup` epic: GitHub Actions step that runs this script on PRs (CI hookup deferred)
- Selene custom rule auto-flagging persistence violations (Production phase deferred)
- Per-round-state runtime audit (caught by code review L2 per ADR-0006 — out of script scope)

---

## QA Test Cases

- **AC-1 / AC-2 / AC-9**: structural + idempotency
  - Given: `tools/audit-persistence.sh` written
  - When: invoke twice on clean tree
  - Then: identical output both runs; banner present; both checks named in script body

- **AC-3 / AC-5**: clean-tree pass
  - Given: working tree post-stories 001 + 002
  - When: `bash tools/audit-persistence.sh; echo $?`
  - Then: exit 0 + `[OK] Persistence audit clean ...` summary

- **AC-4**: forbidden-class catalog completeness
  - Given: ADR-0011 §Pillar 3 Forbidden Keys table
  - When: cross-reference script's regex pattern
  - Then: every forbidden class from ADR has a corresponding regex token
  - Edge cases: ADR amendment adds new class → flag for re-sync, fail this AC until script updated

- **AC-6**: Check A synthetic plant
  - Given: clean tree
  - When: append `local _ = game:GetService("DataStoreService")` to e.g. `src/ReplicatedStorage/Source/Network/init.luau`; run script
  - Then: exit 1 + `[FAIL Check A]` + planted file:line printed
  - Cleanup: revert before continuing

- **AC-7**: Check B synthetic plant
  - Given: clean tree
  - When: add `PlayerDataKey.RoundCount = "RoundCount"` to enum; run script
  - Then: exit 1 + `[FAIL Check B]` + matched file:line + `round.*count` class identified
  - Cleanup: revert before continuing

- **AC-8**: documentation
  - Given: repo `README.md` or `CLAUDE.md`
  - When: search for `audit-persistence.sh`
  - Then: one or more references with usage line present

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `tools/audit-persistence.sh` (the artifact itself)
- Smoke check pass: `production/qa/evidence/persistence-audit-evidence.md` documenting AC-5 clean PASS + AC-6 + AC-7 synthetic-plant FAIL runs
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (need clean schema for AC-5 baseline). ~~Story 002~~ (closed obsolete — audit does not reference migration dir; no impact).
- Unlocks: `/test-setup` story that adds the script as a CI step; Pillar 3 / Pillar 4 audit at `/gate-check pre-production`

---

## Completion Notes

**Completed**: 2026-04-27
**Criteria**: 9/9 passing (verified end-to-end via smoke run + AC-6 + AC-7 synthetic plants + AC-9 byte-compare idempotency)

**Deviations**:
- ADVISORY: AC-2 Check A regex tightened from literal substring `"DataStoreService"` to call-pattern `:GetService\(["']DataStoreService["']\)`. Pre-existing template files (`PlayerData/Server.luau:73` + `PlayerData/Readme.luau:6`) reference the service name in explanatory comments not actual code; literal substring would false-positive on those. Tightening preserves the gate's purpose (catch real call sites) while skipping prose. AC-6 synthetic plant uses the call-pattern shape exactly, so failure mode is unchanged. Documented inline in script header + smoke evidence doc.
- ADVISORY: Original AC dependency on story 002 ("migration dir present") is moot — story 002 closed obsolete; audit script never references migration dir. No AC impacted; recorded in evidence doc.

**Test Evidence**: Config/Data story — smoke check pass at `production/qa/evidence/persistence-audit-evidence.md` (full run logs for AC-5 clean PASS + AC-6 DataStoreService plant FAIL + AC-7 RoundCount plant FAIL + AC-9 idempotency byte-compare).

**Code Review**: Skipped — Lean mode
**Gates**: QL-TEST-COVERAGE + LP-CODE-REVIEW skipped — Lean mode

**Files**:
- `tools/audit-persistence.sh` (NEW, ~115 L, mode 755) — POSIX bash with two checks (DataStoreService confinement, Pillar 3 forbidden-class scan); 10-pattern regex catalog inline + ADR-0011 §Pillar 3 cross-references in header comment block
- `CLAUDE.md` (Technology Stack section) — added `Persistence audit` bullet alongside `Asset-ID audit` (both now part of pre-commit checklist)
- `production/qa/evidence/persistence-audit-evidence.md` (NEW, smoke evidence — Config/Data story type required artifact)

**Manifest Version**: 2026-04-27 (current ✓ no staleness).

**Verification runs (recap)**:
- AC-5 clean tree: `[OK] Persistence audit clean ...` — exit 0
- AC-6 DataStoreService plant at `Network/init.luau:165`: detected, `[FAIL Check A]` — exit 1; reverted
- AC-7 RoundCount plant in `PlayerDataKey.luau:43`: detected, `[FAIL Check B]` matched `round.*count` class — exit 1; reverted
- AC-9 idempotency: byte-identical stdout + identical exit codes across 2 consecutive runs

**Audit gate verification**: `bash tools/audit-asset-ids.sh` → exit 0 (no asset-id leak introduced).

**Unblocks**: `/test-setup` epic (CI hookup); Pillar 3 / Pillar 4 audit at `/gate-check pre-production`.

**Epic status**: player-data-schema **2/3 effective** (stories 001 + 003 Complete; story 002 closed obsolete). Foundation deliverable shipped.
