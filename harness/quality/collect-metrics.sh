#!/bin/bash
# Collect weekly harness metrics and append to .ralph/quality-history.csv

set -euo pipefail

workspace="${1:-$(pwd)}"
metrics_file="$workspace/.ralph/quality-history.csv"
errors_file="$workspace/.ralph/errors.log"
activity_file="$workspace/.ralph/activity.log"
soak_metrics_file="$workspace/.ralph/soak-metrics.json"

mkdir -p "$workspace/.ralph"

expected_header="week,lead_time_hours,change_failure_rate,mttr_hours,pr_cycle_count,pre_human_catch_rate,architecture_violations,soak_tier,soak_runtime_seconds,soak_max_drift_ns,soak_avg_drift_ns,soak_dropped_packets"

if [[ ! -f "$metrics_file" ]]; then
  echo "$expected_header" > "$metrics_file"
fi

current_header="$(sed -n '1p' "$metrics_file" 2>/dev/null || true)"
if [[ "$current_header" != "$expected_header" ]]; then
  tmp_file="$(mktemp)"
  python3 - "$metrics_file" "$tmp_file" "$expected_header" <<'PY'
import csv
import pathlib
import sys

src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
expected_header = sys.argv[3].split(",")
rows = list(csv.DictReader(src.read_text().splitlines()))

with dst.open("w", newline="") as fh:
    writer = csv.DictWriter(fh, fieldnames=expected_header)
    writer.writeheader()
    for row in rows:
        writer.writerow({
            "week": row.get("week", ""),
            "lead_time_hours": row.get("lead_time_hours", 0),
            "change_failure_rate": row.get("change_failure_rate", 0),
            "mttr_hours": row.get("mttr_hours", 0),
            "pr_cycle_count": row.get("pr_cycle_count", 0),
            "pre_human_catch_rate": row.get("pre_human_catch_rate", 0),
            "architecture_violations": row.get("architecture_violations", 0),
            "soak_tier": row.get("soak_tier", "none"),
            "soak_runtime_seconds": row.get("soak_runtime_seconds", 0),
            "soak_max_drift_ns": row.get("soak_max_drift_ns", 0),
            "soak_avg_drift_ns": row.get("soak_avg_drift_ns", 0),
            "soak_dropped_packets": row.get("soak_dropped_packets", 0),
        })
PY
  mv "$tmp_file" "$metrics_file"
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

soak_tier="${SOAK_TIER:-none}"
soak_runtime_seconds="${SOAK_RUNTIME_SECONDS:-0}"
soak_max_drift_ns="${SOAK_MAX_DRIFT_NS:-0}"
soak_avg_drift_ns="${SOAK_AVG_DRIFT_NS:-0}"
soak_dropped_packets="${SOAK_DROPPED_PACKETS:-0}"

if [[ -f "$soak_metrics_file" ]]; then
  parsed_runtime="$(python3 - "$soak_metrics_file" <<'PY'
import json
import pathlib
import sys
payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload.get("runtime_seconds", 0))
PY
)"
  parsed_tier="$(python3 - "$soak_metrics_file" <<'PY'
import json
import pathlib
import sys
payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(payload.get("tier", "none"))
PY
)"
  soak_runtime_seconds="$parsed_runtime"
  soak_tier="$parsed_tier"
fi

echo "$week,$lead_time_hours,$change_failure_rate,$mttr_hours,$pr_cycle_count,$pre_human_catch_rate,$arch_violations,$soak_tier,$soak_runtime_seconds,$soak_max_drift_ns,$soak_avg_drift_ns,$soak_dropped_packets" >> "$metrics_file"
echo "metrics updated: $metrics_file"
