# The Workflow: Ticket → Pull Request

This is the end-to-end pipeline that `/task` runs. Every other command in this repo is one phase of it, runnable on its own.

```
 ┌─────────┐   ┌──────────┐   ┌────────┐   ┌──────────────┐   ┌───────────┐
 │ 1 INTAKE│──▶│2 DISCOVER│──▶│ 3 PLAN │──▶│4 APPROVAL ⛔ │──▶│5 IMPLEMENT│
 └─────────┘   └──────────┘   └────────┘   └──────────────┘   └─────┬─────┘
  tracker MCP    stack +         plan.md      human says              │ small,
  or free text   conventions                  "approve"               │ verified steps
                                                                      ▼
 ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌────────────┐   ┌───────────┐
 │11 REPORT │◀──│10 DELIVER│◀──│ 9 E2E    │◀──│ 8 REVIEW   │◀──│6 TEST +   │
 └──────────┘   └──────────┘   └──────────┘   └────────────┘   │7 LOCAL CI │
  summary,       branch, PR,    UI (browser    code + security  └───────────┘
  ticket update  remote CI      MCP) / API     fix loop (≤ N)    lint, types,
                                (HTTP)                            build, tests
```

## Design principles

1. **Human in the loop where it matters.** The agent may read, explore and plan freely. It may not write code until a human approves the plan. It may not merge, deploy, or force-push at all.
2. **Everything is a file.** Plans, state, test reports and reviews are written to `.agentic/runs/<RUN-ID>/`. A run can be paused, resumed (`/resume`), audited, or handed to another agent or another tool.
3. **Framework-agnostic by detection, not by assumption.** The `stack-detection` skill figures out the language, package manager, test framework, lint/type/build commands and UI/API surface *from the repo*. Project memory (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) can override anything it detects.
4. **Small verified steps.** Implement → run the relevant check → continue. Never pile up 500 lines of unverified changes.
5. **Bounded loops.** Every fix loop (tests, review, CI) has a max iteration count. When exhausted, the agent stops and asks instead of thrashing.
6. **Graceful degradation.** No tracker MCP? Paste the ticket text. No browser MCP? UI testing falls back to writing Playwright/Cypress specs and running them headless. No subagents in your tool? The orchestrator adopts each role inline.

## Phases in detail

| # | Phase | Command | Agent(s) | Skill(s) | Output artifact | Gate |
|---|-------|---------|----------|----------|-----------------|------|
| 1 | Intake | `/task`, `/plan` | – | `task-intake` | `ticket.md` | Ambiguities → ask |
| 2 | Discover | `/task`, `/plan` | `codebase-explorer` | `stack-detection` | `context.md` | – |
| 3 | Plan | `/plan` | `planner` | `planning` | `plan.md` | – |
| 4 | Approval | `/plan`, `/task` | – | `approval-gate` | `state.md` (approved: yes) | **Human must approve** |
| 5 | Implement | `/implement` | `implementer` | `git-workflow` | code + commits | Plan step checks pass |
| 6 | Test | `/test` | `test-engineer` | `test-generation` | tests + `test-report.md` | All tests green |
| 7 | Local CI | `/ci-check` | `ci-guardian` | `ci-verification` | `ci-report.md` | Lint/type/build/test green |
| 8 | Review | `/review` | `code-reviewer`, `security-auditor` | `code-review`, `security-review` | `review.md` | No blocking findings |
| 9 | E2E | `/ui-test`, `/api-test` | `ui-tester`, `api-tester` | `ui-testing`, `api-testing` | `e2e-report.md` (+ screenshots) | Acceptance criteria verified |
| 10 | Deliver | `/ship` | – | `git-workflow` | PR URL, ticket comment | Remote CI green |
| 11 | Report | `/task` | – | `workflow-state` | `summary.md` | – |

## The run directory

```
.agentic/
└── runs/
    └── PROJ-123/                # RUN-ID = ticket key, or slug + date for free-text tasks
        ├── state.md             # current phase, approvals, loop counters, blockers  (source of truth)
        ├── ticket.md            # normalized task: goal, acceptance criteria, links
        ├── context.md           # stack profile + relevant code map
        ├── plan.md              # the approved plan (versioned if revised)
        ├── test-report.md
        ├── ci-report.md
        ├── review.md
        ├── e2e-report.md
        ├── artifacts/           # screenshots, traces, HTTP transcripts
        └── summary.md           # final hand-off
```

Add `.agentic/runs/` to `.gitignore` unless your team wants run history in the repo (some teams commit `plan.md` for auditability — your call).

## Change classification (drives Phase 9)

After implementation, the orchestrator classifies the diff:

| Signal in the diff | Classification | E2E action |
|---|---|---|
| Components, pages, templates, styles, client routing (`*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.html`, `*.css`, `*.scss`, `templates/`, `views/`, `app/`, `pages/`, mobile UI files) | **frontend** | `ui-tester` drives a real browser via MCP |
| Routes, controllers, handlers, resolvers, serializers, OpenAPI/GraphQL schemas, DB migrations, middleware | **backend** | `api-tester` exercises endpoints over HTTP |
| Both | **full-stack** | Both, API first (UI depends on it) |
| Library code, CLI, infra-as-code, docs only | **other** | Skip E2E; unit/integration tests are the gate |

Project memory can override this mapping (e.g. a monorepo where `packages/web` is frontend).

## Failure and stop conditions

The orchestrator **stops and asks the human** when:

- The ticket is ambiguous in a way that changes the design (not a naming nit).
- The plan is rejected, or approval is not explicitly given.
- A fix loop exceeds its iteration budget (defaults: tests 3, CI 3, review 2, E2E 2).
- It needs a secret, credential, paid service, or production access.
- A change would touch something the plan marked out of scope, or a protected path.
- Remote CI fails for reasons unrelated to the diff (flaky infra, base branch red).

It records the blocker in `state.md` so `/resume` can pick up after the human responds.

## Autonomy levels

Set `autonomy` in your project memory's Workflow Configuration:

| Level | Behaviour |
|---|---|
| `supervised` (default) | Approval required for the plan **and** before pushing/opening the PR. |
| `standard` | Approval required for the plan only. Push + PR are automatic. |
| `autonomous` | Plan auto-approved for tickets labelled e.g. `agent-ok` and below a size threshold. Use only in sandboxes / CI-runner agents. |

No level ever allows: merging, deploying, force-pushing, deleting branches you didn't create, rotating secrets, or running destructive DB commands against non-local databases.
