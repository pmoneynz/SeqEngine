#!/bin/bash
# Detect API-breaking changes against a baseline treeish.

set -euo pipefail

workspace="${1:-$(pwd)}"
baseline_treeish="${2:-origin/main}"
baseline_dir="$workspace/.build/api-baseline"

if ! command -v swift >/dev/null 2>&1; then
  echo "swift is required for API diff checks"
  exit 1
fi

echo "Running API diff against baseline: $baseline_treeish"

swift package \
  --package-path "$workspace" \
  diagnose-api-breaking-changes \
  "$baseline_treeish" \
  --products SequencerEngine \
  --products SequencerEngineIO \
  --baseline-dir "$baseline_dir"

echo "API diff check passed."
