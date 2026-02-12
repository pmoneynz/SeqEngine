# Scientific Validation Baseline Plan

## Hypothesis Template
Rule under test: `[name]` improves `[metric]` without degrading `[metric]`.

## Baseline Window
- Duration: 2 weeks minimum.
- Collect weekly metrics from `.ralph/quality-history.csv`.

## Controlled Trial
- A/B split by team, component, or time window.
- Keep task size and risk class comparable between cohorts.

## Decision Rule
- Keep rule: statistically meaningful improvement and no kill-criteria regressions.
- Revise rule: mixed results or metric noise.
- Remove rule: no benefit or clear regression.
