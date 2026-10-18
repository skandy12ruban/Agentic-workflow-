---
name: ci-verification
description: Reproduce a project's CI pipeline locally (format, lint, typecheck, build, tests, security/audit) by reading CI configs from GitHub Actions, GitLab CI, Azure Pipelines, Jenkins, CircleCI, Bitbucket and others; triage failures; and read remote CI results and logs via MCP. Use before pushing, when CI is red, or when asked to "run CI" or "make the build green".
---

# CI Verification

## 1. Extract the pipeline

| CI system | File(s) | What to read |
|---|---|---|
| GitHub Actions | `.github/workflows/*.yml` | Workflows with `on: pull_request`/`push`; each job's `steps[].run`; `matrix`; `services` (DBs); `env` |
| GitLab CI | `.gitlab-ci.yml` (+ `include:`) | `stages`, jobs' `script`, `rules`/`only` for MRs, `services` |
| Azure Pipelines | `azure-pipelines.yml` | `stages/jobs/steps`, `script`/`task` entries |
| Jenkins | `Jenkinsfile` | `stage(...)` → `sh '...'` |
| CircleCI | `.circleci/config.yml` | `jobs.*.steps[].run`, orbs |
| Bitbucket | `bitbucket-pipelines.yml` | `pipelines.pull-requests` |
| Buildkite / Drone / Woodpecker | `.buildkite/`, `.drone.yml`, `.woodpecker.yml` | `command`/`commands` |
| Pre-commit | `.pre-commit-config.yaml`, `lefthook.yml`, `.husky/` | hook entries (often the lint/format gate) |

Translate each PR-triggered job into a local command list. Resolve reusable actions to their underlying commands where obvious (`actions/setup-node` → use local Node matching `node-version`; `pnpm/action-setup` → pnpm; `golangci/golangci-lint-action` → `golangci-lint run`).

Note matrix dimensions (Node 18/20/22, Python 3.10–3.13, OS). Locally run the **primary** version; flag if the change is version-sensitive (new syntax/APIs).

**`act`** (runs GitHub Actions locally in Docker) or `gitlab-ci-local` can be used if installed and the user agrees — they're heavier but more faithful.

## 2. Run order (fail fast, cheap first)
1. Install with the lockfile, frozen (`npm ci`, `pnpm i --frozen-lockfile`, `uv sync --frozen`, `poetry install --sync`, `bundle install` with frozen setting, `go mod download`).
2. Format check
3. Lint (on whole project as CI does, not only changed files — CI won't be that kind)
4. Typecheck
5. Build
6. Unit tests
7. Integration tests (start services via docker compose / testcontainers)
8. Extra gates CI runs: coverage threshold, license check, bundle-size check, dependency audit, migrations check (`makemigrations --check`, `prisma migrate diff`), codegen drift (`generate && git diff --exit-code`), docs build.

## 3. Failure triage
Determine the class (see `ci-guardian` agent): **this diff / exposed by diff / pre-existing / environmental / flaky**.

Quick test for pre-existing: `git stash -u && <failing cmd>; git stash pop` (or check base branch's latest CI status via VCS MCP). If base is red too → not your failure; report it.

Reading logs effectively:
- Find the **first** error, not the last. Later errors are often cascades.
- Search for markers: `error`, `Error:`, `FAIL`, `✕`, `E   `, `--- FAIL`, `[ERROR]`, `Traceback`, `panic:`, `exit code`.
- For test failures, extract: test name, assertion message, expected vs actual, file:line.

## 4. Remote CI via MCP
- **GitHub MCP**: list check runs / workflow runs for the PR head SHA → for failures, fetch job logs → triage. Re-run a job only to confirm a suspected flake, once.
- **GitLab**: pipeline for MR → failed jobs → job trace.
- **Azure DevOps**: build for PR → timeline → failed task logs.
- **No MCP**: CLI (`gh run list --branch <b>`, `gh run view <id> --log-failed`, `glab ci view`, `az pipelines runs list`).

After pushing a fix, wait for the new run (don't spam re-runs); a CI wait is a natural point to update state and report progress.

## 5. Forbidden "fixes" (require explicit human approval)
Disabling/skipping tests · loosening lint rules or adding ignore comments · lowering coverage thresholds · pinning to older tool versions to dodge a failure · editing CI config · `continue-on-error: true` · `|| true`.
