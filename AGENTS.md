# AGENTS Map

This file is intentionally short. Use it as an entrypoint.

## Core Docs
- `docs/index.md` - documentation index
- `docs/design-docs/architecture-contract.md` - architecture boundaries
- `docs/product-specs/` - product requirements
- `docs/exec-plans/active/` - active plans
- `docs/exec-plans/completed/` - completed plans
- `docs/tech-debt-tracker.md` - debt register

## Harness Controls
- `harness/harness.config` - enforcement toggles
- `harness/architecture/check-boundaries.sh` - architecture gate
- `harness/quality/evaluate-kill-criteria.sh` - kill criteria gate
- `harness/review/self-review.sh` - evidence bundle generation and strict validation
- `harness/review/secondary-review.sh` - secondary review gate

## Operational Logs
- `.ralph/progress.md` - execution continuity
- `.ralph/governance-decisions.md` - architecture/reliability decisions
- `.ralph/quality-history.csv` - weekly metrics history
