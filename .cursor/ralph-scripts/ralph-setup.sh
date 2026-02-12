#!/bin/bash
# Simple setup wrapper for local Super Ralph loop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

if [[ ! -f "$WORKSPACE/RALPH_TASK.md" ]]; then
  echo "Missing RALPH_TASK.md in workspace: $WORKSPACE"
  exit 1
fi

if [[ ! -d "$WORKSPACE/.git" ]]; then
  echo "Workspace is not a git repository: $WORKSPACE"
  exit 1
fi

echo "== Ralph setup =="
echo "workspace: $WORKSPACE"
echo ""
echo "Running single safe preflight iteration..."
bash "$SCRIPT_DIR/ralph-once.sh" "$WORKSPACE"
echo ""
echo "To continue autonomous runs:"
echo "  MAX_ITERATIONS=20 bash .cursor/ralph-scripts/ralph-loop.sh \"$WORKSPACE\""
