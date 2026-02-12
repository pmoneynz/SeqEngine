## How To Write A High-Quality `RALPH_TASK.md`

A weak task file is the #1 reason Ralph runs go sideways.  
If your task is vague, you get vague output plus wasted iterations.

Use this structure and quality bar.

### 1) Start with strict frontmatter

Keep the metadata minimal and executable.

```markdown
---
task: "Build user auth API with JWT refresh tokens"
test_command: "pnpm test && pnpm lint"
---
```

Rules:
- `task` must be specific, not generic (“improve auth” is bad).
- `test_command` must be real and runnable locally.
- If tests/lint don’t exist yet, define the closest real validation command.

---

### 2) Define scope in plain language

Say exactly what is in/out so the agent doesn’t invent work.

```markdown
# Task: JWT Auth API

Implement login, refresh, logout endpoints with token rotation.

## In Scope
- POST /auth/login
- POST /auth/refresh
- POST /auth/logout
- Unit tests for token service
- API docs for these endpoints

## Out of Scope
- OAuth providers
- UI changes
- Database migration beyond auth tables
```

---

### 3) Write measurable success criteria as checkboxes

This is the core. If criteria are fuzzy, quality collapses.

```markdown
## Success Criteria

1. [ ] `POST /auth/login` returns access+refresh tokens for valid credentials
2. [ ] Invalid credentials return 401 with stable error schema
3. [ ] `POST /auth/refresh` rotates refresh token and invalidates old token
4. [ ] `POST /auth/logout` invalidates current refresh token
5. [ ] `pnpm test && pnpm lint` exits 0
6. [ ] OpenAPI docs include request/response examples for all auth endpoints
```

Rules:
- Every checkbox must be binary pass/fail.
- Include command-level checks (`exit 0` style).
- Include failure-path behavior, not only happy path.
- Avoid “looks good”, “works well”, “clean code”.

---

### 4) Add constraints that prevent bad implementation choices

```markdown
## Constraints
- Use existing `TokenService`; do not introduce a second token abstraction.
- Follow architecture boundaries in `harness/architecture/contract.yaml`.
- No `any` in TypeScript.
- No placeholder TODO code in merged result.
```

---

### 5) Add verification evidence requirements

This forces reliability, not vibes.

```markdown
## Validation Evidence Required
- test output summary
- lint output summary
- changed files list
- short note on edge cases tested
```

---

### 6) Break large work into phases/groups

If the task is large, group it so Ralph can complete in clean iterations.

```markdown
## Phased Criteria

- [ ] Implement token domain model <!-- group: 1 -->
- [ ] Implement auth endpoints <!-- group: 2 -->
- [ ] Add tests and docs <!-- group: 3 -->
```

---

## Quality Checklist (Use Before Running)

If any item is “no”, rewrite the task.

- Does every criterion have objective pass/fail?
- Could a new engineer verify completion without guessing?
- Are failure modes included (invalid input, auth errors, etc.)?
- Is scope bounded (clear in/out)?
- Is there a real `test_command`?
- Would this likely finish in 1–5 iterations (or grouped phases)?

---

## Bad vs Good (blunt)

- Bad: “Improve performance and clean up auth.”
- Good: “Reduce `/auth/login` p95 latency from 350ms to <200ms under 200 RPS in local load test; add benchmark script; keep test/lint passing.”

- Bad: “Refactor API.”
- Good: “Move auth handlers from `routes.ts` into `auth.controller.ts` without changing public routes; all integration tests unchanged and passing.”

---
