# AGENTS.md — <Project name>

<!--
  Project memory for AI coding agents. Loaded automatically at the start of every session.
  Filename by tool: CLAUDE.md (Claude Code) · GEMINI.md (Gemini CLI) · AGENTS.md (Codex, Cursor, Copilot, most others).
  Keep it SHORT and SPECIFIC. Every line should change what the agent does. Delete sections that don't apply.
  Generate a first draft with /setup-project, then edit by hand.
-->

## Project overview
<2–4 sentences: what this is, who uses it, the main moving parts.>
- Stack: <e.g. TypeScript monorepo — Next.js web (apps/web), NestJS API (apps/api), Postgres via Prisma>
- Key directories: `apps/web` (UI), `apps/api` (REST API), `packages/shared` (types), `infra/` (Terraform — do not apply)

## Commands
| Task | Command |
|---|---|
| Install | `pnpm install --frozen-lockfile` |
| Dev (all) | `pnpm dev` |
| Format check | `pnpm format:check` |
| Lint | `pnpm lint` |
| Typecheck | `pnpm typecheck` |
| Build | `pnpm build` |
| Unit tests | `pnpm test` · single file: `pnpm vitest run <path>` |
| Integration tests | `pnpm test:int` (needs `docker compose up -d db`) |
| E2E tests | `pnpm e2e` · single: `pnpm playwright test <spec>` |
| DB migrate (local) | `pnpm db:migrate` · new: `pnpm prisma migrate dev --name <name>` |
| Codegen | `pnpm generate` (run after editing `schema.prisma` or `openapi.yaml`) |

## Conventions
- Code style: enforced by ESLint + Prettier; don't hand-format.
- Naming: <e.g. React components PascalCase files; hooks `useX`; API DTOs `XRequest`/`XResponse`>
- Errors: <e.g. throw domain errors from `src/errors.ts`; never return raw DB errors to clients>
- Logging: <e.g. use `logger` from `@acme/log`; never log tokens or PII>
- Commits: Conventional Commits with ticket key, e.g. `feat(orders): add cancel endpoint [PROJ-123]`
- Branches: `<type>/<TICKET>-<slug>`
- PRs: use `.github/pull_request_template.md`; one ticket per PR; < 500 LOC preferred

## Architecture map
<Short bullets an agent needs to place code correctly. Link deeper docs rather than inlining them.>
- Request flow: `routes → controllers → services → repositories → Prisma`
- Auth: JWT via `AuthGuard`; ownership checks in services with `assertOwns(actor, resource)`
- Feature flags: `flags.isEnabled('<name>')` from `src/flags.ts`
- Background jobs: BullMQ in `apps/api/src/jobs`
- Deeper docs: `docs/architecture.md`, ADRs in `docs/adr/`

## Testing
- Unit tests next to source as `*.test.ts`; integration in `apps/api/test/`; E2E in `apps/web/e2e/`.
- Factories in `test/factories/`; never hit real third-party APIs — use `msw` handlers in `test/mocks/`.
- Test user for local UI: `customer@example.test` / `password123` (seeded by `pnpm db:seed`).
- A bug fix must include a regression test that fails without the fix.

## Workflow Configuration
<!-- Read by /task, /plan, /ship, etc. Anything omitted falls back to detection/defaults. -->

```yaml
tracker:
  type: jira                  # jira | linear | github | gitlab | azure-boards | none
  project_key: PROJ           # bare "123" → PROJ-123
  transition_on_pr: "In Review"   # or null to never change ticket status
  comment_on_pr: true
vcs:
  host: github                # github | gitlab | azure-devops | bitbucket
  base_branch: main
  draft_prs: true             # open agent PRs as drafts until CI is green
  reviewers: [ "@acme/web-team" ]   # or rely on CODEOWNERS
autonomy: supervised          # supervised | standard | autonomous
auto_approve:                 # only used when autonomy: autonomous
  labels: [ "agent-ok" ]
  max_size: S
loop_budgets: { step_verify: 3, test: 3, ci: 3, review: 2, e2e: 2, remote_ci: 3 }
classification_overrides:     # path globs → surface (for monorepos / unusual layouts)
  frontend: [ "apps/web/**", "packages/ui/**" ]
  backend:  [ "apps/api/**" ]
ui:
  start_command: "pnpm --filter web dev"
  base_url: "http://localhost:3000"
  test_user: "customer@example.test"   # password in .env.test, not here
  viewports: [ "375x812", "1440x900" ]
api:
  start_command: "pnpm --filter api start:dev"
  base_url: "http://localhost:4000"
  health: "/health"
  contract: "apps/api/openapi.yaml"
  dependencies: "docker compose up -d db redis"
  safe_environments: []       # e.g. [ "https://staging.example.com" ] for read-only checks ONLY
security:
  secret_scanner: "gitleaks detect --no-banner"
  dependency_audit: "pnpm audit --prod"
library:                      # where this workflow's agents/skills are installed (non-Claude tools)
  agents: ".agentic/agents"
  skills: ".agentic/skills"
```

## Boundaries
- ✅ **Always:** run lint + typecheck + affected tests before saying a task is done; follow existing patterns; ask when requirements are ambiguous.
- ⚠️ **Ask first:** adding dependencies; DB schema changes; changing public API contracts; touching CI config; anything in `infra/`; deleting files.
- 🚫 **Never:** commit secrets or `.env*`; push to `main`; force-push; merge PRs; run `terraform apply`, `prisma migrate reset`, or anything against staging/prod; edit generated files in `src/generated/` by hand; disable or skip tests to make CI pass.

## Agentic workflow library
Commands: `/task`, `/plan`, `/implement`, `/test`, `/ci-check`, `/review`, `/ui-test`, `/api-test`, `/ship`, `/fix-bug`, `/resume`, `/setup-project`.
<!-- For tools WITHOUT native subagents/skills, keep the two lines below so the agent can find the role/skill files: -->
Agents (role prompts): `.agentic/agents/<name>.md` — codebase-explorer, planner, implementer, test-engineer, ci-guardian, code-reviewer, security-auditor, ui-tester, api-tester, debugger, docs-writer.
Skills (read `SKILL.md` when relevant): `.agentic/skills/<name>/SKILL.md` — task-intake, stack-detection, planning, approval-gate, workflow-state, git-workflow, test-generation, ci-verification, code-review, security-review, ui-testing, api-testing, systematic-debugging.
