# Architecture Contract

This repository enforces layered architecture as a mechanical gate.

## Layers
- `domain`: core business logic, no framework coupling.
- `application`: orchestrates use cases, depends on `domain`.
- `infrastructure`: IO adapters, depends on `application` and `domain`.
- `interface`: UI/API delivery layer, depends on `application`.

## Dependency Direction Rule

Allowed:
- `interface -> application`
- `application -> domain`
- `infrastructure -> application`
- `infrastructure -> domain`

Disallowed:
- `domain -> application|infrastructure|interface`
- `application -> interface|infrastructure`
- `interface -> infrastructure` (except explicit approved edges)

## Approved Edge Process
1. Add proposed edge to `harness/architecture/contract.yaml` under `approved_edges`.
2. Add rationale to `.ralph/governance-decisions.md`.
3. Run `harness/architecture/check-boundaries.sh` and include output in PR evidence.
