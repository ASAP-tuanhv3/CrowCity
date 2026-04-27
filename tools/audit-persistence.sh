#!/usr/bin/env bash
#
# audit-persistence.sh — ADR-0011 §Verification Required clauses (A) + (B)
#
# Two-check static-audit gate for player-data persistence:
#
#   Check A — DataStoreService confinement
#     `game:GetService("DataStoreService")` (and equivalent call patterns)
#     must appear ONLY inside the vendored ProfileStore library.
#     ADR-0011 §Persistence Flow + ADR-0006 §Forbidden Patterns Matrix.
#
#   Check B — Pillar 3 forbidden keys
#     `PlayerDataKey.luau` and `DefaultPlayerData.luau` must NOT contain
#     any key matching the Pillar 3 Forbidden Keys catalog from
#     ADR-0011 §Pillar 3 Forbidden Keys.
#
# Pillar 3 Forbidden Key classes (case-insensitive substring patterns):
#   round.*count       — per-round crowd / participation counts
#   round.*radius      — per-round CSM radius state
#   round.*relic       — per-round relic inventory / history
#   round.*chest       — per-round chest cooldowns / opened state
#   round.*npc         — per-round NPC pool / kill counts
#   round.*match       — per-round match-state mirror
#   absorb.*bonus      — Pillar 4 violation: gameplay-outcome multiplier
#   draft.*weight      — Pillar 4 violation: relic-rarity weight
#   draw.*power        — Pillar 4 violation: drawing-power modifier
#   gameplay.*modifier — Pillar 4 catch-all
#
# Scope refinements (advisory deviation from literal AC-2 wording):
#   - Check A regex tightened from substring match `"DataStoreService"` to
#     call patterns `:GetService\(['"]DataStoreService['"]\)` — pre-existing
#     comments mentioning the service in prose (e.g. PlayerData/Readme.luau,
#     PlayerData/Server.luau:73 explanatory comments) are not violations.
#     AC-6 synthetic plant is exactly the call-pattern shape, so this
#     tightening preserves the gate's actual purpose.
#   - Check B uses `grep -iE` (case-insensitive extended regex) for
#     typo-tolerance: `roundCount`, `RoundCount`, `ROUND_COUNT` all flag.
#
# Exempt paths:
#   - src/ReplicatedStorage/Dependencies/                  (vendored ProfileStore + Freeze)
#
# Exit codes:
#   0  clean — both checks pass
#   1  fail  — either check failed; offending file:line printed before summary
#
# Usage:
#   bash tools/audit-persistence.sh
#
# CI hookup deferred to /test-setup epic. Selene custom rule deferred to Production phase.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$REPO_ROOT/src" ]; then
	echo "[OK] No src/ directory found — nothing to audit."
	exit 0
fi

exit_code=0

# ----------------------------------------------------------------------
# Check A — DataStoreService confinement
# ----------------------------------------------------------------------
# Match call patterns only; ignore comment-only mentions in prose docs.
matches_a="$(grep -rnE \
	--include="*.luau" \
	--exclude-dir=Dependencies \
	":GetService\([\"']DataStoreService[\"']\)" \
	"$REPO_ROOT/src" 2>/dev/null || true)"

if [ -n "$matches_a" ]; then
	echo "$matches_a"
	echo ""
	count_a="$(printf '%s\n' "$matches_a" | grep -c '.')"
	echo "[FAIL Check A] $count_a DataStoreService call site(s) outside vendored ProfileStore."
	echo "               Lift through PlayerDataServer / ProfileStore per ADR-0011 §Persistence Flow."
	exit_code=1
fi

# ----------------------------------------------------------------------
# Check B — Pillar 3 forbidden keys in persisted schema
# ----------------------------------------------------------------------
# Pattern alternation kept inline for auditability — every token MUST trace
# to ADR-0011 §Pillar 3 Forbidden Keys catalog (see header comment above).
forbidden_pattern='round.*count|round.*radius|round.*relic|round.*chest|round.*npc|round.*match|absorb.*bonus|draft.*weight|draw.*power|gameplay.*modifier'

# Files in scope: only the two persisted-schema source files.
matches_b="$(grep -rEni \
	"$forbidden_pattern" \
	"$REPO_ROOT/src/ReplicatedStorage/Source/SharedConstants/PlayerDataKey.luau" \
	"$REPO_ROOT/src/ServerStorage/Source/DefaultPlayerData.luau" \
	2>/dev/null || true)"

if [ -n "$matches_b" ]; then
	echo "$matches_b"
	echo ""
	count_b="$(printf '%s\n' "$matches_b" | grep -c '.')"
	echo "[FAIL Check B] $count_b Pillar 3 forbidden-class match(es) in persisted schema."
	echo "               Remove the offending key — round-scope state never persists."
	echo "               See ADR-0011 §Pillar 3 Forbidden Keys for the full catalog + rationale."
	exit_code=1
fi

# ----------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------
if [ "$exit_code" -eq 0 ]; then
	echo "[OK] Persistence audit clean — DataStoreService confined to ProfileStore + no forbidden keys"
fi

exit "$exit_code"
