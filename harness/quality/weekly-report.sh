#!/bin/bash
# Generate weekly quality report markdown from .ralph/quality-history.csv

set -euo pipefail

workspace="${1:-$(pwd)}"
metrics_file="$workspace/.ralph/quality-history.csv"
out_file="$workspace/docs/references/weekly-quality-report.md"

if [[ ! -f "$metrics_file" ]]; then
  echo "No metrics file found. Run harness/quality/collect-metrics.sh first."
  exit 1
fi

mkdir -p "$workspace/docs/references"

{
  echo "# Weekly Quality Report"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo ""
  echo "| Week | Lead Time (h) | Change Failure Rate | MTTR (h) | PR Cycle Count | Pre-Human Catch Rate | Architecture Violations |"
  echo "|---|---:|---:|---:|---:|---:|---:|"
  tail -n +2 "$metrics_file" | while IFS=, read -r week lead change mttr prcycle catchrate archv; do
    echo "| $week | $lead | $change | $mttr | $prcycle | $catchrate | $archv |"
  done
} > "$out_file"

echo "report written: $out_file"
