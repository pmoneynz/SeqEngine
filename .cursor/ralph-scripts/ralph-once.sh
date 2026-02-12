#!/bin/bash
# Run one safe Super Ralph preflight iteration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

TASK_FILE="$WORKSPACE/RALPH_TASK.md"
PROGRESS_FILE="$WORKSPACE/.ralph/progress.md"
GATES_SCRIPT="$SCRIPT_DIR/harness-gates.sh"

if [[ ! -f "$TASK_FILE" ]]; then
  echo "Missing required task file: $TASK_FILE"
  exit 1
fi

if [[ ! -d "$WORKSPACE/.git" ]]; then
  echo "Not a git repository: $WORKSPACE"
  exit 1
fi

if [[ ! -x "$GATES_SCRIPT" ]]; then
  echo "Harness gates script not executable: $GATES_SCRIPT"
  exit 1
fi

mkdir -p "$WORKSPACE/.ralph"
touch "$PROGRESS_FILE"

echo "== Ralph once: preflight =="
echo "workspace: $WORKSPACE"
echo "task:      $TASK_FILE"

# Safe trial iteration: enforce harness gates before autonomous looping.
bash "$GATES_SCRIPT" "$WORKSPACE"

{
  echo ""
  echo "## $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "- action: ralph-once preflight"
  echo "- result: harness gates passed"
} >> "$PROGRESS_FILE"

echo "Preflight complete. Ready for loop execution."
