#!/bin/bash
# Evaluate kill criteria from recent metric trends.

set -euo pipefail

workspace="${1:-$(pwd)}"
mode="${2:-}"
metrics_file="$workspace/.ralph/quality-history.csv"

if [[ ! -f "$metrics_file" ]]; then
  echo "No metrics file found ($metrics_file)."
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required for kill criteria evaluation"
  exit 1
fi

python3 - "$metrics_file" "$mode" << 'PY'
import csv
import pathlib
import sys

metrics_file = pathlib.Path(sys.argv[1])
mode = sys.argv[2]

rows = list(csv.DictReader(metrics_file.read_text().splitlines()))
if len(rows) < 2:
    print("Kill criteria not evaluated: need at least 2 weeks of data.")
    sys.exit(0)

last = rows[-1]
prev = rows[-2]

def f(name):
    try:
        return float(last.get(name, "0") or 0)
    except Exception:
        return 0.0

def p(name):
    try:
        return float(prev.get(name, "0") or 0)
    except Exception:
        return 0.0

violations = []

# Kill criteria encoded from Harness-Minimum guidance.
if f("change_failure_rate") > p("change_failure_rate"):
    violations.append("change_failure_rate increased week-over-week")
if f("architecture_violations") > p("architecture_violations"):
    violations.append("architecture_violations increased week-over-week")

if violations:
    print("Kill criteria warning:")
    for v in violations:
        print(f"  - {v}")
    if mode == "--enforce":
        sys.exit(1)
    sys.exit(0)

print("Kill criteria check passed.")
PY
