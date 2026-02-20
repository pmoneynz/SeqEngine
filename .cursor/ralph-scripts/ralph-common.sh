#!/bin/bash
# Common execution logic for local Super Ralph scripts.

set -euo pipefail

MODEL="${RALPH_MODEL:-gpt-5.2-high}"
MAX_ITERATIONS="${MAX_ITERATIONS:-20}"

get_agent_cmd() {
  if [[ -n "${RALPH_AGENT_CMD:-}" ]]; then
    echo "$RALPH_AGENT_CMD"
    return 0
  fi
  if command -v cursor-agent >/dev/null 2>&1; then
    echo "cursor-agent"
    return 0
  fi
  return 1
}

init_ralph_dir() {
  local workspace="$1"
  mkdir -p "$workspace/.ralph"
  touch "$workspace/.ralph/activity.log"
  touch "$workspace/.ralph/errors.log"
  if [[ ! -f "$workspace/.ralph/progress.md" ]]; then
    cat > "$workspace/.ralph/progress.md" <<'EOF'
# Ralph Progress Log

Project: SequencerEngine
Initialized: 2026-02-12T00:00:00Z
---
EOF
  fi
}

log_progress() {
  local workspace="$1"
  local message="$2"
  {
    echo ""
    echo "## $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "- $message"
  } >> "$workspace/.ralph/progress.md"
}

check_task_complete() {
  local workspace="$1"
  local task_file="$workspace/RALPH_TASK.md"
  if [[ ! -f "$task_file" ]]; then
    echo "NO_TASK_FILE"
    return 0
  fi

  local unchecked
  unchecked=$(grep -cE '^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+\[ \]' "$task_file" 2>/dev/null || true)
  if [[ "${unchecked:-0}" -eq 0 ]]; then
    echo "COMPLETE"
  else
    echo "INCOMPLETE:$unchecked"
  fi
}

check_prerequisites() {
  local workspace="$1"
  if [[ ! -f "$workspace/RALPH_TASK.md" ]]; then
    echo "Missing RALPH_TASK.md in workspace: $workspace"
    return 1
  fi
  if [[ ! -d "$workspace/.git" ]]; then
    echo "Workspace is not a git repository: $workspace"
    return 1
  fi
  if ! get_agent_cmd >/dev/null 2>&1; then
    echo "No supported agent CLI found."
    echo "Install cursor-agent or set RALPH_AGENT_CMD explicitly."
    return 1
  fi
  return 0
}

build_prompt() {
  local iteration="$1"
  cat <<EOF
# Ralph Iteration $iteration

You are executing one autonomous Super Ralph iteration in this repository.

Required steps:
1. Read \`RALPH_TASK.md\`, \`.ralph/progress.md\`, and \`AGENTS.md\`.
2. Implement the highest-priority unchecked criterion in \`RALPH_TASK.md\`.
3. Run required verification commands listed in task files/docs.
4. Update \`RALPH_TASK.md\` checkboxes to reflect truth.
5. Append a concise entry to \`.ralph/progress.md\`.
6. Commit meaningful changes with a descriptive message.

If all criteria are complete, output exactly: <ralph>COMPLETE</ralph>
If blocked after repeated attempts, output exactly: <ralph>GUTTER</ralph>
EOF
}

run_agent_iteration() {
  local workspace="$1"
  local iteration="$2"
  local agent_cmd
  agent_cmd="$(get_agent_cmd)"
  local prompt
  prompt="$(build_prompt "$iteration")"

  local tmp_out
  tmp_out="$(mktemp)"
  local activity="$workspace/.ralph/activity.log"
  local errors="$workspace/.ralph/errors.log"

  cd "$workspace"

  if [[ "$agent_cmd" == "cursor-agent" ]]; then
    # cursor-agent supports direct prompt and model parameters.
    if ! cursor-agent -p --force --model "$MODEL" "$prompt" >"$tmp_out" 2>&1; then
      cat "$tmp_out" >> "$activity"
      {
        echo "[$(date -u '+%H:%M:%S')] iteration $iteration failed"
        cat "$tmp_out"
      } >> "$errors"
      rm -f "$tmp_out"
      echo "ERROR"
      return 0
    fi
  else
    # Caller-supplied command via RALPH_AGENT_CMD.
    # If {PROMPT} is present, substitute it; otherwise pipe prompt on stdin.
    if [[ "$agent_cmd" == *"{PROMPT}"* ]]; then
      local escaped_prompt
      escaped_prompt="$(printf '%q' "$prompt")"
      local rendered_cmd
      rendered_cmd="${agent_cmd//\{PROMPT\}/$escaped_prompt}"
      if ! bash -lc "$rendered_cmd" >"$tmp_out" 2>&1; then
        cat "$tmp_out" >> "$activity"
        {
          echo "[$(date -u '+%H:%M:%S')] iteration $iteration failed"
          cat "$tmp_out"
        } >> "$errors"
        rm -f "$tmp_out"
        echo "ERROR"
        return 0
      fi
    elif ! printf "%s" "$prompt" | bash -lc "$agent_cmd" >"$tmp_out" 2>&1; then
      cat "$tmp_out" >> "$activity"
      {
        echo "[$(date -u '+%H:%M:%S')] iteration $iteration failed"
        cat "$tmp_out"
      } >> "$errors"
      rm -f "$tmp_out"
      echo "ERROR"
      return 0
    fi
  fi

  cat "$tmp_out" >> "$activity"

  local signal=""
  if command -v rg >/dev/null 2>&1; then
    if rg -n "<ralph>COMPLETE</ralph>" "$tmp_out" >/dev/null; then
      signal="COMPLETE"
    elif rg -n "<ralph>GUTTER</ralph>" "$tmp_out" >/dev/null; then
      signal="GUTTER"
    fi
  else
    if grep -n "<ralph>COMPLETE</ralph>" "$tmp_out" >/dev/null; then
      signal="COMPLETE"
    elif grep -n "<ralph>GUTTER</ralph>" "$tmp_out" >/dev/null; then
      signal="GUTTER"
    fi
  fi

  rm -f "$tmp_out"
  echo "$signal"
}

run_harness_gates() {
  local workspace="$1"
  local script_dir="$2"
  bash "$script_dir/harness-gates.sh" "$workspace"
}

run_ralph_loop() {
  local workspace="$1"
  local script_dir="$2"

  init_ralph_dir "$workspace"
  check_prerequisites "$workspace"

  local max="${3:-$MAX_ITERATIONS}"
  local status
  status="$(check_task_complete "$workspace")"
  if [[ "$status" == "COMPLETE" ]]; then
    echo "Task already complete. Nothing to run."
    return 0
  fi

  for ((i=1; i<=max; i++)); do
    echo ""
    echo "-- iteration $i/$max --"
    log_progress "$workspace" "iteration $i started (model: $MODEL)"

    local signal
    signal="$(run_agent_iteration "$workspace" "$i")"

    if ! run_harness_gates "$workspace" "$script_dir"; then
      log_progress "$workspace" "iteration $i failed harness gates"
      echo "Harness gate failed after iteration $i."
      return 1
    fi

    status="$(check_task_complete "$workspace")"
    if [[ "$signal" == "GUTTER" ]]; then
      log_progress "$workspace" "iteration $i ended in GUTTER"
      echo "Agent reported GUTTER. Stopping."
      return 1
    fi
    if [[ "$signal" == "ERROR" ]]; then
      log_progress "$workspace" "iteration $i agent command failed"
      echo "Agent command failed. Check .ralph/errors.log."
      return 1
    fi
    if [[ "$status" == "COMPLETE" ]]; then
      log_progress "$workspace" "task complete at iteration $i"
      echo "Task complete at iteration $i."
      return 0
    fi

    log_progress "$workspace" "iteration $i ended; $status"
  done

  echo "Max iterations reached without full completion."
  return 1
}
