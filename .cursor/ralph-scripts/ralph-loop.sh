#!/bin/bash
# Minimal loop runner for local Super Ralph workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${1:-$(pwd)}"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

MAX_ITERATIONS="${MAX_ITERATIONS:-20}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"

if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || [[ "$MAX_ITERATIONS" -lt 1 ]]; then
  echo "MAX_ITERATIONS must be a positive integer."
  exit 1
fi

echo "== Ralph loop =="
echo "workspace:      $WORKSPACE"
echo "max iterations: $MAX_ITERATIONS"

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo ""
  echo "-- iteration $i/$MAX_ITERATIONS --"
  bash "$SCRIPT_DIR/ralph-once.sh" "$WORKSPACE"
  sleep "$SLEEP_SECONDS"
done

echo "Loop finished after $MAX_ITERATIONS iteration(s)."
