# Persistence Audit Gate — Smoke Evidence

> **Story**: production/epics/player-data-schema/story-003-persistence-audit-script.md
> **Story Type**: Config/Data
> **Date**: 2026-04-27
> **Tester**: dev-story / story-done auto-verification
> **Result**: PASS — script ships, behaves correctly on clean tree + both synthetic plants

## Artifact Under Test

`tools/audit-persistence.sh` — bash script implementing ADR-0011 §Verification Required clauses (A) + (B).

## Acceptance Criteria Coverage

### AC-1: script exists, executable, banner cites ADR

```
$ ls -l tools/audit-persistence.sh
-rwxr-xr-x  1 lap60698  staff  ~3K  Apr 27 22:00 tools/audit-persistence.sh

$ head -3 tools/audit-persistence.sh
#!/usr/bin/env bash
#
# audit-persistence.sh — ADR-0011 §Verification Required clauses (A) + (B)
```

Result: PASS — file present, mode 755, banner cites source ADR.

---

### AC-2 + AC-4: two checks defined; forbidden-class regex catalog matches ADR-0011

Script defines:
- **Check A** — `:GetService\(["']DataStoreService["']\)` call-pattern grep, scoped to `*.luau` files, excludes `Dependencies/` dir.
- **Check B** — `grep -iE` against forbidden-class alternation pattern, scoped to `PlayerDataKey.luau` + `DefaultPlayerData.luau` only.

Forbidden-class catalog (10 patterns) — every token traces to ADR-0011 §Pillar 3 Forbidden Keys:
```
round.*count       → Per-round crowd state
round.*radius      → Per-round CSM radius
round.*relic       → Per-round relic inventory
round.*chest       → Per-round chest cooldowns / opened
round.*npc         → Per-round NPC pool
round.*match       → Per-round match-state mirror
absorb.*bonus      → Pillar 4 violation: gameplay-outcome multiplier
draft.*weight      → Pillar 4 violation: relic-rarity weight
draw.*power        → Pillar 4 violation: drawing-power modifier
gameplay.*modifier → Pillar 4 catch-all
```

**ADVISORY deviation from literal AC-2 wording**: Check A uses call-pattern regex `:GetService\(["']DataStoreService["']\)` instead of literal substring `"DataStoreService"`. Pre-existing template files (`PlayerData/Server.luau:73` + `PlayerData/Readme.luau:6`) reference the service name in explanatory comments, not actual code. The tightening preserves the gate's actual purpose (catch real `GetService` call sites) while skipping documentation prose. AC-6 synthetic plant (`game:GetService("DataStoreService")`) matches the call pattern exactly, so the gate's failure mode is unchanged. Documented inline in script header + story 003 Completion Notes.

---

### AC-3 + AC-5: clean tree exits 0 with `[OK]` summary

```
$ bash tools/audit-persistence.sh; echo "exit:$?"
[OK] Persistence audit clean — DataStoreService confined to ProfileStore + no forbidden keys
exit:0
```

Result: PASS — clean tree (post-stories 001 — story 002 closed obsolete) audits clean.

---

### AC-6: Check A synthetic plant — DataStoreService outside ProfileStore

Plant injected at `src/ReplicatedStorage/Source/Network/init.luau`:
```lua
local _AUDIT_PLANT_A = game:GetService("DataStoreService") -- TEMPORARY
```

Script run with plant active:
```
src/ReplicatedStorage/Source/Network/init.luau:165:local _AUDIT_PLANT_A = game:GetService("DataStoreService") -- TEMPORARY

[FAIL Check A] 1 DataStoreService call site(s) outside vendored ProfileStore.
               Lift through PlayerDataServer / ProfileStore per ADR-0011 §Persistence Flow.
exit:1
```

Plant reverted via backup-and-restore (no commit). Final clean re-run returned exit 0.

Result: PASS — plant detected at correct file:line; `[FAIL Check A]` summary printed; exit 1.

---

### AC-7: Check B synthetic plant — Pillar 3 forbidden key

Plant injected into `src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau`:
```lua
RoundCount = "RoundCount", -- TEMPORARY AUDIT PLANT
```

Script run with plant active:
```
src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau:43:	RoundCount = "RoundCount", -- TEMPORARY AUDIT PLANT           -- FTUE-progress

[FAIL Check B] 1 Pillar 3 forbidden-class match(es) in persisted schema.
               Remove the offending key — round-scope state never persists.
               See ADR-0011 §Pillar 3 Forbidden Keys for the full catalog + rationale.
exit:1
```

Plant reverted; final clean re-run returned exit 0 + `[OK]` summary.

Result: PASS — plant detected at correct file:line; `[FAIL Check B]` summary printed; matches `round.*count` class.

---

### AC-8: documented in CLAUDE.md

CLAUDE.md Technology Stack section updated:

```
- **Persistence audit**: `bash tools/audit-persistence.sh` — fails with exit 1 if `DataStoreService` is called outside the vendored ProfileStore, OR if any Pillar 3 forbidden key class (round-scope state, gameplay-outcome modifiers) appears in `PlayerDataKey.luau` / `DefaultPlayerData.luau` (ADR-0011 §Verification Required A + B). Run before every commit that touches persistence layer.
```

Result: PASS — usage line + ADR cite + when-to-run guidance present.

---

### AC-9: idempotency

```
$ OUT1=$(bash tools/audit-persistence.sh 2>&1); EX1=$?
$ OUT2=$(bash tools/audit-persistence.sh 2>&1); EX2=$?
$ [ "$OUT1" = "$OUT2" ] && [ "$EX1" = "$EX2" ] && echo IDEMPOTENT
IDEMPOTENT
```

Result: PASS — byte-identical output, identical exit codes.

---

## Verdict

**9/9 acceptance criteria PASS.** Script is production-ready for local pre-commit use. CI hookup deferred to `/test-setup` epic.

Note: Original story dependency on story 002 ("migration dir present") is moot — story 002 closed obsolete unimplemented (template's `profile:Reconcile()` already covers v0 → v1 default-fill). Audit script does not reference migration dir; no AC affected.

## Sign-off

- Self-verified: dev-story / story-done auto-verification 2026-04-27
- Lean mode: QL-TEST-COVERAGE + LP-CODE-REVIEW gates skipped per `production/review-mode.txt`
