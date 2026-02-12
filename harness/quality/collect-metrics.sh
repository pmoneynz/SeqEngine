#!/bin/bash
# Collect weekly harness metrics and append to .ralph/quality-history.csv

set -euo pipefail

workspace="${1:-$(pwd)}"
metrics_file="$workspace/.ralph/quality-history.csv"
errors_file="$workspace/.ralph/errors.log"
activity_file="$workspace/.ralph/activity.log"

mkdir -p "$workspace/.ralph"

if [[ ! -f "$metrics_file" ]]; then
  echo "week,lead_time_hours,change_failure_rate,mttr_hours,pr_cycle_count,pre_human_catch_rate,architecture_violations" > "$metrics_file"
fi

week="$(date +%G-W%V)"
lead_time_hours="${LEAD_TIME_HOURS:-0}"
change_failure_rate="${CHANGE_FAILURE_RATE:-0}"
mttr_hours="${MTTR_HOURS:-0}"
pr_cycle_count="${PR_CYCLE_COUNT:-0}"

total_failures=0
if [[ -f "$errors_file" ]]; then
  total_failures="$(rg -c "ERROR|FAIL|GUTTER|violation" "$errors_file" || echo 0)"
fi

agent_caught=0
if [[ -f "$activity_file" ]]; then
  agent_caught="$(rg -c "self-review|secondary-review|Architecture check passed" "$activity_file" || echo 0)"
fi

pre_human_catch_rate=0
if [[ "$total_failures" -gt 0 ]]; then
  pre_human_catch_rate="$(python3 - <<PY
total=$total_failures
caught=$agent_caught
print(round((caught/total)*100,2))
PY
)"
fi

arch_violations="$(rg -c "Architecture violations detected|HARNESS_ARCH_FAIL" "$errors_file" 2>/dev/null || echo 0)"

echo "$week,$lead_time_hours,$change_failure_rate,$mttr_hours,$pr_cycle_count,$pre_human_catch_rate,$arch_violations" >> "$metrics_file"
echo "metrics updated: $metrics_file"
