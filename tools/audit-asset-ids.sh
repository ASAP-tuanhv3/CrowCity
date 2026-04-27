#!/usr/bin/env bash
#
# audit-asset-ids.sh — ADR-0006 §Verification Required clause (A)
#
# Static-audit gate: verifies that every `rbxassetid://` URI string in src/
# lives inside the central registry `SharedConstants/AssetId.luau`.
# Any raw asset-id string outside the registry is a magic-string violation
# of ADR-0006 (Module Placement Rules) and should be lifted into AssetId.
#
# Scope:
#   - .luau files only — Roblox model binaries (.rbxm) and Rojo instance
#     descriptors (.model.json) ship with literal asset IDs by design.
#     ADR-0006 governs Luau module placement; instance descriptors are
#     Rojo-build artifacts, not modules.
#   - Pattern is "rbxassetid://[0-9]+" — matches actual asset IDs only,
#     not the bare URI-scheme prefix constant used for runtime concatenation
#     (see PlayerFacingString.luau ImageAsset.Prefix).
#
# Exempt paths:
#   - src/ReplicatedStorage/Source/SharedConstants/AssetId.luau   (the registry itself)
#   - src/ReplicatedStorage/Dependencies/                          (vendored libraries)
#
# Exit codes:
#   0  clean — zero raw rbxassetid:// references outside registry
#   1  fail  — one or more raw rbxassetid:// references found; lines printed above summary
#
# Usage:
#   bash tools/audit-asset-ids.sh
#
# CI hookup (GitHub Actions step) is deferred to /test-setup epic.
# Selene custom rule (ADR-0006 §L3) is deferred to Production phase.

set -u

# Resolve repo root from script location so the audit can run from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$REPO_ROOT/src" ]; then
	echo "[OK] No src/ directory found — nothing to audit."
	exit 0
fi

# grep -r recursively, exclude registry file by name and Dependencies dir by name.
# Using --exclude / --exclude-dir keeps the audit deterministic regardless of cwd.
matches="$(grep -rnE \
	--include="*.luau" \
	--exclude-dir=Dependencies \
	--exclude=AssetId.luau \
	"rbxassetid://[0-9]+" \
	"$REPO_ROOT/src" 2>/dev/null || true)"

if [ -z "$matches" ]; then
	echo "[OK] No raw rbxassetid:// references outside SharedConstants/AssetId.luau"
	exit 0
else
	echo "$matches"
	echo ""
	# Count lines portably (avoid `wc -l` whitespace inconsistencies across platforms).
	count="$(printf '%s\n' "$matches" | grep -c '.')"
	echo "[FAIL] $count raw rbxassetid:// reference(s) found outside SharedConstants/AssetId.luau"
	echo "       Lift each value into src/ReplicatedStorage/Source/SharedConstants/AssetId.luau"
	echo "       and replace the magic string with AssetId.<Category>.<Name> per ADR-0006."
	exit 1
fi
