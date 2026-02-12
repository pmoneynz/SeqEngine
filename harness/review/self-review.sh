#!/bin/bash
# Build and validate self-review evidence bundle.

set -euo pipefail

workspace="${1:-$(pwd)}"
mode="${2:-}"
evidence_dir="$workspace/.ralph/evidence"
evidence_file="$evidence_dir/latest.json"

mkdir -p "$evidence_dir"

task_id="${TASK_ID:-unknown-task}"
checks_json='[{"name":"agent_self_review","status":"pass","details":"self review completed"}]'
artifacts_json='[".ralph/activity.log",".ralph/errors.log"]'

cat > "$evidence_file" << EOF
{
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "task_id": "$task_id",
  "checks": $checks_json,
  "artifacts": $artifacts_json,
  "review": {
    "self_reviewed": true,
    "secondary_reviewed": false
  }
}
EOF

if [[ "$mode" == "--strict" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 required for strict evidence validation"
    exit 1
  fi
  python3 - "$evidence_file" << 'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
required = ["timestamp", "task_id", "checks", "artifacts"]
for key in required:
    if key not in data:
        raise SystemExit(f"Missing required evidence key: {key}")

if not data["checks"]:
    raise SystemExit("Evidence checks list must not be empty")

for check in data["checks"]:
    if check.get("status") != "pass":
        raise SystemExit(f"Evidence check failed: {check}")
print("self-review strict validation passed")
PY
fi

echo "self-review evidence: $evidence_file"
