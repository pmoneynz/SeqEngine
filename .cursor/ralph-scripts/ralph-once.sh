#!/bin/bash
# Run exactly one autonomous Super Ralph iteration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-common.sh"

WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

echo "== Ralph once =="
echo "workspace: $WORKSPACE"
echo "model:     ${RALPH_MODEL:-gpt-5.2-high}"

run_ralph_loop "$WORKSPACE" "$SCRIPT_DIR" "1"
