#!/usr/bin/env bash
#
# audit-no-competing-heartbeat.sh — ADR-0002 §Decision invariant audit.
#
# Asserts that exactly ONE module in src/ServerStorage + src/ReplicatedStorage
# connects to RunService.Heartbeat for gameplay-tick work: TickOrchestrator.
# NPCSpawner exemption (manifest L197) tolerated when present — own non-
# gameplay-tick Heartbeat for NPC pathing batch updates.
#
# Exit 0 = clean (only allowed connections). Exit 1 = competing connection
# found — caller wired a parallel accumulator outside the orchestrator.
#
# Used by CI lint gate (see .github/workflows/tests.yml) and pre-commit.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Allowed file paths. Add NPCSpawner here when its epic ships.
#
# Exemptions:
#   - TickOrchestrator: ADR-0002 sole gameplay-tick accumulator
#   - BeamBetween: template-shipped visual utility (cosmetic per-frame beam
#     update between two anchor parts; no gameplay state mutation, not a
#     tick consumer). Pre-existing template code.
#   - ProfileStore (vendored): auto-save scheduler internal to ProfileStore
#     library. Vendored at src/ReplicatedStorage/Dependencies/. Per
#     ADR-0006 §Vendored vs Wally Policy, vendored libraries are not
#     modified — exempt from project conventions.
ALLOWED_PATHS=(
	"src/ServerStorage/Source/TickOrchestrator/init.luau"
	"src/ReplicatedStorage/Source/BeamBetween.luau"
	"src/ReplicatedStorage/Dependencies/ProfileStore.luau"
)

# Find every Heartbeat:Connect occurrence in server + replicated source.
matches=$(grep -rn "Heartbeat:Connect" \
	src/ServerStorage src/ReplicatedStorage \
	2>/dev/null || true)

if [ -z "$matches" ]; then
	echo "audit-no-competing-heartbeat: no Heartbeat:Connect found anywhere — TickOrchestrator missing?"
	exit 1
fi

violations=""
while IFS= read -r line; do
	# Strip line:column to get path
	path="${line%%:*}"
	allowed=0
	for allowed_path in "${ALLOWED_PATHS[@]}"; do
		if [ "$path" = "$allowed_path" ]; then
			allowed=1
			break
		fi
	done
	if [ "$allowed" -eq 0 ]; then
		violations="$violations$line\n"
	fi
done <<< "$matches"

if [ -n "$violations" ]; then
	echo "audit-no-competing-heartbeat: FAIL — Heartbeat:Connect found outside allowed paths:"
	echo -e "$violations"
	echo "Per ADR-0002 §Decision: TickOrchestrator is the sole gameplay-tick accumulator."
	echo "Move the connection into TickOrchestrator's phase iteration, or add the file to ALLOWED_PATHS"
	echo "if it represents a legitimate exemption (e.g. NPCSpawner per manifest L197)."
	exit 1
fi

echo "audit-no-competing-heartbeat: PASS — only allowed paths use Heartbeat:Connect."
exit 0
