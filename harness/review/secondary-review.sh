#!/bin/bash
# Secondary review gate - verifies evidence and marks review completion.

set -euo pipefail

workspace="${1:-$(pwd)}"
evidence_file="$workspace/.ralph/evidence/latest.json"

if [[ ! -f "$evidence_file" ]]; then
  echo "Evidence file missing: $evidence_file"
  exit 1
fi

python3 - "$evidence_file" << 'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
if "review" not in data:
    data["review"] = {}
data["review"]["secondary_reviewed"] = True
for check in data.get("checks", []):
    if check.get("status") != "pass":
        raise SystemExit(f"Secondary review blocked by failed check: {check}")
path.write_text(json.dumps(data, indent=2) + "\n")
print("secondary review passed")
PY
