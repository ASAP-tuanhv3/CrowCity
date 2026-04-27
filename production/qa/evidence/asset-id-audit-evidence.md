# Asset ID Audit Gate — Smoke Evidence

> **Story**: production/epics/asset-id-registry/story-004-asset-id-audit-gate.md
> **Story Type**: Config/Data
> **Date**: 2026-04-27
> **Tester**: dev-story / story-done auto-verification
> **Result**: PASS — script ships, behaves correctly on clean tree + synthetic plant

## Artifact Under Test

`tools/audit-asset-ids.sh` — bash script implementing ADR-0006 §Verification Required clause (A).

## Acceptance Criteria Coverage

### AC-1: script exists, executable, banner cites ADR

```
$ ls -l tools/audit-asset-ids.sh
-rwxr-xr-x@ 1 lap60698  staff  2112 Apr 27 21:52 tools/audit-asset-ids.sh

$ head -3 tools/audit-asset-ids.sh
#!/usr/bin/env bash
#
# audit-asset-ids.sh — ADR-0006 §Verification Required clause (A)
```

Result: PASS — file present, mode 755, banner cites source ADR.

---

### AC-2: grep filtered to exclude registry + Dependencies

Script source (final):
```sh
matches="$(grep -rnE \
    --include="*.luau" \
    --exclude-dir=Dependencies \
    --exclude=AssetId.luau \
    "rbxassetid://[0-9]+" \
    "$REPO_ROOT/src" 2>/dev/null || true)"
```

Result: PASS — exclusions match story spec. **ADVISORY deviation from literal AC-2 wording**: added `--include="*.luau"` filter to scope the audit to Luau modules (not template `.rbxm` binaries or `.model.json` Rojo instance descriptors, which legitimately contain literal asset IDs by design); tightened pattern to `rbxassetid://[0-9]+` to skip the legitimate URI-scheme prefix constant in `SharedConstants/PlayerFacingString.luau:12` (`Prefix = "rbxassetid://"`). Both changes match story intent ("any non-exempt **module**" wording in AC-5) and ADR-0006 §V-A (governs Luau module placement, not Rojo build artifacts). Documented in `Story 004 Completion Notes`.

---

### AC-3 + AC-4: clean tree exits 0 with `[OK]` summary

```
$ bash tools/audit-asset-ids.sh; echo "exit:$?"
[OK] No raw rbxassetid:// references outside SharedConstants/AssetId.luau
exit:0
```

Result: PASS — clean tree (post-stories 001/002/003) audits clean.

---

### AC-3 + AC-5: synthetic plant exits 1 with file:line + `[FAIL]` summary

Plant injected (then reverted):
```sh
echo 'local _AUDIT_PLANT = "rbxassetid://99999" -- TEMPORARY: AC-5 verification, will be reverted' \
  >> src/ReplicatedStorage/Source/Network/init.luau
```

Script run with plant active:
```
src/ReplicatedStorage/Source/Network/init.luau:165:local _AUDIT_PLANT = "rbxassetid://99999" -- TEMPORARY: AC-5 verification, will be reverted

[FAIL] 1 raw rbxassetid:// reference(s) found outside SharedConstants/AssetId.luau
       Lift each value into src/ReplicatedStorage/Source/SharedConstants/AssetId.luau
       and replace the magic string with AssetId.<Category>.<Name> per ADR-0006.
exit:1
```

Plant reverted via `mv "$PLANT_FILE.bak" "$PLANT_FILE"` — confirmed clean tail returns `end\nreturn Network`.

Result: PASS — script detects plant at correct file:line, exits 1, prints `[FAIL]` summary. Plant cleanly reverted (NOT committed).

---

### AC-6: documented in CLAUDE.md

CLAUDE.md L50 (Technology Stack section) updated with:

```
- **Asset-ID audit**: `bash tools/audit-asset-ids.sh` — fails with exit 1 if any `rbxassetid://N` magic string lives in a `.luau` module outside `SharedConstants/AssetId.luau` (ADR-0006 §Verification Required A). Run before every commit that touches asset references.
```

Result: PASS — usage line + ADR cite + when-to-run guidance present.

---

### AC-7: idempotency

```
$ OUT1=$(bash tools/audit-asset-ids.sh 2>&1); EX1=$?
$ OUT2=$(bash tools/audit-asset-ids.sh 2>&1); EX2=$?
$ [ "$OUT1" = "$OUT2" ] && [ "$EX1" = "$EX2" ] && echo IDEMPOTENT
IDEMPOTENT
```

Result: PASS — two consecutive runs produce byte-identical stdout + identical exit codes.

---

## Verdict

**7/7 acceptance criteria PASS.** Script is production-ready for local pre-commit use. CI hookup deferred to `/test-setup` epic per Out of Scope §L78.

## Sign-off

- Self-verified: dev-story / story-done auto-verification 2026-04-27
- Lean mode: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per `production/review-mode.txt`
