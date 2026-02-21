# Architecture Contract

This repository follows layered architecture by convention and code review.

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
1. Document the proposed edge in this file.
2. Include a short rationale in the pull request.
3. Add or update tests that prove the new dependency is necessary and safe.
