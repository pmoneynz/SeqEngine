#!/bin/bash
# Run autonomous Super Ralph iterations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-common.sh"

WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
MAX="${MAX_ITERATIONS:-20}"

if ! [[ "$MAX" =~ ^[0-9]+$ ]] || [[ "$MAX" -lt 1 ]]; then
  echo "MAX_ITERATIONS must be a positive integer."
  exit 1
fi

echo "== Ralph loop =="
echo "workspace:      $WORKSPACE"
echo "max iterations: $MAX"
echo "model:          ${RALPH_MODEL:-gpt-5.2-high}"
if [[ -n "${RALPH_AGENT_CMD:-}" ]]; then
  echo "agent cmd:      $RALPH_AGENT_CMD"
else
  echo "agent cmd:      cursor-agent (auto)"
fi

run_ralph_loop "$WORKSPACE" "$SCRIPT_DIR" "$MAX"
