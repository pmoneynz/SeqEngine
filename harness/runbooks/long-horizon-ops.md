# Long Horizon Runbook

## Standard Cycle
1. Run Ralph loop for scoped tasks.
2. Enforce architecture, evidence, and kill criteria gates.
3. Merge only when dual review passes.
4. Run weekly quality report and trend evaluation.

## Parallel + Integration Pattern
- Execute independent tasks in parallel worktrees.
- Run a single integration pass for cross-cutting updates.
- Re-run architecture and review gates before merge.

## Recovery Pattern
1. If gutter repeats, stop scaling and inspect `.ralph/errors.log`.
2. Add remediation to `.ralph/governance-decisions.md`.
3. Re-run with smaller task units.

## Escalation Rules
- Escalate to humans only for risk acceptance, priority conflicts, or architecture contract changes.
