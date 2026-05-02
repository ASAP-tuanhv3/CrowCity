#!/usr/bin/env bash
#
# audit-no-currency-in-shutdown.sh — story-004 AC-7 invariant audit.
#
# Asserts that NO Currency module call appears in the BindToClose-reachable
# code path. Per ADR-0011 §BindToClose grace + manifest L106 + L142, currency
# grants happen ONLY at MSM Result entry — never on shutdown.
#
# Reachable path from game:BindToClose:
#   src/ServerScriptService/start.server.luau           (registration site)
#   src/ServerStorage/Source/ShutdownCoordinator/init.luau (chain body)
#   src/ServerStorage/Source/_PhaseStubs/MatchStateServerStub.luau (broadcast)
#   src/ServerStorage/Source/TickOrchestrator/init.luau (called via stop())
#
# Forbidden symbols (any match → fail):
#   Currency.            — any method on the Currency module
#   grantCoins           — soft currency grant entry point
#   grantMatchRewards    — bulk Result-entry grant entry point
#
# Exit 0 = clean (no currency code reachable from shutdown path).
# Exit 1 = violation found.
#
# Used by /smoke-check sprint and pre-commit before story-004 closure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# BindToClose-reachable files. Update this list when the shutdown chain
# adds a new call site (e.g. when MSM epic replaces MatchStateServerStub
# with the real MatchStateServer.requestServerClosing entry point).
REACHABLE_FILES=(
	"src/ServerScriptService/start.server.luau"
	"src/ServerStorage/Source/ShutdownCoordinator/init.luau"
	"src/ServerStorage/Source/_PhaseStubs/MatchStateServerStub.luau"
	"src/ServerStorage/Source/TickOrchestrator/init.luau"
)

# Verify every reachable file exists. Missing file = audit cannot run.
for f in "${REACHABLE_FILES[@]}"; do
	if [ ! -f "$f" ]; then
		echo "audit-no-currency-in-shutdown: FAIL — reachable file not found: $f"
		exit 1
	fi
done

# Forbidden symbols. ERE alternation; word-boundary not used because
# Luau identifiers are bounded by punctuation in practice.
FORBIDDEN_PATTERN='Currency\.|grantCoins|grantMatchRewards'

violations=""
for f in "${REACHABLE_FILES[@]}"; do
	matches=$(grep -nE "$FORBIDDEN_PATTERN" "$f" 2>/dev/null || true)
	if [ -n "$matches" ]; then
		while IFS= read -r line; do
			violations="${violations}${f}:${line}\n"
		done <<< "$matches"
	fi
done

if [ -n "$violations" ]; then
	echo "audit-no-currency-in-shutdown: FAIL — currency call(s) reachable from BindToClose:"
	echo -e "$violations"
	echo "Per ADR-0011 §BindToClose grace + manifest L106: currency grants only"
	echo "at MSM Result entry. NEVER during shutdown."
	exit 1
fi

echo "audit-no-currency-in-shutdown: PASS — no currency calls in shutdown chain."
exit 0
