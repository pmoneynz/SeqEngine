#!/bin/bash
# Daily garbage collection loop for docs and slop cleanup.

set -euo pipefail

workspace="${1:-$(pwd)}"
log_file="$workspace/.ralph/cleanup-log.md"
mkdir -p "$workspace/.ralph"

{
  echo "## $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "- Ran doc freshness and slop scan."
  stale_docs="$(rg -l 'TODO|TBD|FIXME' "$workspace/docs" 2>/dev/null || true)"
  if [[ -n "$stale_docs" ]]; then
    echo "- Potential stale docs detected:"
    echo "$stale_docs" | sed 's/^/  - /'
  else
    echo "- No stale docs markers found."
  fi
  echo ""
} >> "$log_file"

echo "cleanup log updated: $log_file"
