#!/bin/bash
# Run deterministic soak tiers for SequencerEngine.

set -euo pipefail

workspace="${1:-$(pwd)}"
mode="${2:-ci}"

if [[ ! -d "$workspace" ]]; then
  echo "Workspace not found: $workspace"
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "swift is required to run soak tests."
  exit 1
fi

run_short() {
  echo "Running short soak tier..."
  SEQUENCER_SOAK_TIER=short swift test --filter "SoakShort"
}

run_medium() {
  echo "Running medium soak tier..."
  SEQUENCER_SOAK_TIER=medium swift test --filter "SoakShort|SoakMedium"
}

run_long() {
  echo "Running long soak tier..."
  SEQUENCER_SOAK_TIER=long swift test --filter "SoakShort|SoakMedium|SoakLong"
}

pushd "$workspace" >/dev/null

start_epoch="$(date +%s)"
case "$mode" in
  ci|short)
    run_short
    tier="short"
    ;;
  nightly|medium)
    run_medium
    tier="medium"
    ;;
  weekly|long)
    run_long
    tier="long"
    ;;
  local)
    run_short
    tier="short"
    ;;
  *)
    echo "Unknown soak mode: $mode (expected ci|nightly|weekly|local)"
    exit 1
    ;;
esac
end_epoch="$(date +%s)"

runtime_seconds="$((end_epoch - start_epoch))"
mkdir -p "$workspace/.ralph"
cat > "$workspace/.ralph/soak-metrics.json" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mode": "$mode",
  "tier": "$tier",
  "runtime_seconds": $runtime_seconds
}
EOF

echo "Soak tests completed (mode=$mode, tier=$tier, runtime_seconds=$runtime_seconds)"
popd >/dev/null
