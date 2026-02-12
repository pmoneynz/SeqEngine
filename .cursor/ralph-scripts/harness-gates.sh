#!/bin/bash
# Installed harness gates for local Ralph loop.

set -u

HARNESS_CONFIG_RELATIVE="harness/harness.config"

load_harness_config() {
  local workspace="$1"
  local config_file="$workspace/$HARNESS_CONFIG_RELATIVE"

  HARNESS_ENABLED=0
  HARNESS_ENFORCE_ARCH=0
  HARNESS_ENFORCE_EVIDENCE=0
  HARNESS_ENFORCE_KILL=0

  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  # shellcheck disable=SC1090
  source "$config_file"
  HARNESS_ENABLED=1
}

run_harness_architecture_gate() {
  local workspace="$1"
  if [[ "${HARNESS_ENFORCE_ARCH:-0}" -ne 1 ]]; then return 0; fi
  "$workspace/harness/architecture/check-boundaries.sh" "$workspace"
}

run_harness_evidence_gate() {
  local workspace="$1"
  if [[ "${HARNESS_ENFORCE_EVIDENCE:-0}" -ne 1 ]]; then return 0; fi
  "$workspace/harness/review/self-review.sh" "$workspace" --strict
}

run_harness_kill_gate() {
  local workspace="$1"
  if [[ "${HARNESS_ENFORCE_KILL:-0}" -ne 1 ]]; then return 0; fi
  "$workspace/harness/quality/evaluate-kill-criteria.sh" "$workspace" --enforce
}

run_harness_iteration_gates() {
  local workspace="$1"
  load_harness_config "$workspace"
  if [[ "${HARNESS_ENABLED:-0}" -ne 1 ]]; then return 0; fi
  run_harness_architecture_gate "$workspace" || return 1
  run_harness_evidence_gate "$workspace" || return 1
  run_harness_kill_gate "$workspace" || return 1
}

main() {
  local workspace="${1:-$(pwd)}"
  run_harness_iteration_gates "$workspace"
}

main "$@"
