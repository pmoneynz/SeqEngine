#!/bin/bash
# Setup wrapper for autonomous Super Ralph loop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-common.sh"
WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

if ! check_prerequisites "$WORKSPACE"; then
  exit 1
fi

echo "== Ralph setup =="
echo "workspace: $WORKSPACE"
echo ""
echo "Running one autonomous trial iteration..."
bash "$SCRIPT_DIR/ralph-once.sh" "$WORKSPACE"
echo ""
echo "To continue autonomous runs:"
echo "  MAX_ITERATIONS=20 bash .cursor/ralph-scripts/ralph-loop.sh \"$WORKSPACE\""
