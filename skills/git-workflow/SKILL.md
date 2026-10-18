---
name: git-workflow
description: Safe, conventional git and pull-request workflow for agents - base branch detection, branch naming, conventional commits, rebasing vs merging, pushing, PR creation via VCS MCP or CLI with a structured description, ticket linking, and post-PR CI follow-up. Use whenever creating branches, committing, pushing, or opening/updating a PR.
---

# Git Workflow

## Hard rules (no autonomy level overrides these)
- ❌ Never commit to or push to the base/default branch or any protected branch.
- ❌ Never `push --force` to a branch you didn't create in this run. On your own branch use `--force-with-lease` only, and only when project convention calls for rebasing.
- ❌ Never merge a PR, delete remote branches, rewrite published history, or change branch protection.
- ❌ Never commit secrets, `.env` files, credentials, large binaries, or generated build output (check `.gitignore`).
- ❌ Never use `--no-verify` to bypass hooks. If a pre-commit hook fails, fix the cause.
- ✅ Stage files explicitly (`git add <paths>`), not `git add -A`, so stray files don't sneak in. Review `git status` and `git diff --staged` before each commit.

## 1. Base branch
Precedence: project memory `base_branch` → `git symbolic-ref refs/remotes/origin/HEAD` → `main` → `master` → `develop`. Fetch it first: `git fetch origin <base>`.

## 2. Branch name
Project convention first (check `CONTRIBUTING.md`, recent branch names via `git branch -r | head -30`). Default:
```
<type>/<TICKET-KEY>-<short-kebab-summary>      e.g. feat/PROJ-123-cancel-pending-orders
types: feat | fix | chore | refactor | docs | test | perf | ci
```
Create from the fresh base: `git switch -c <branch> origin/<base>`.

## 3. Commits
Follow the project's convention (look at `git log --oneline -20`, commitlint config). Default to **Conventional Commits**:
```
<type>(<scope>): <imperative summary, ≤ 72 chars> [<TICKET-KEY>]

<body: what and why, wrapped at 72. Not how — the diff shows how.>

Refs: <TICKET-KEY>
```
- One logical change per commit; each commit should build.
- Breaking change → `feat(api)!: …` and a `BREAKING CHANGE:` footer.
- Add any attribution trailers your organisation or tool requires.

## 4. Keeping up with base
- If base moved and there are conflicts or CI requires up-to-date branches: on **your own unpublished branch**, `git rebase origin/<base>`; once pushed/reviewed, prefer `git merge origin/<base>` unless the project mandates rebase.
- Resolve conflicts by understanding both sides; re-run tests after resolving. Regenerate lockfiles with the package manager, don't hand-merge them.

## 5. Push
`git push -u origin <branch>`. On network failure retry with backoff (2s, 4s, 8s, 16s). On rejection, **don't force** — fetch, inspect, reconcile.

## 6. Pull request
Prefer the VCS MCP (GitHub: `create_pull_request`; GitLab/Azure DevOps equivalents); fall back to CLI (`gh pr create`, `glab mr create`, `az repos pr create`).

- **Use the repo's PR template** if present (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `.gitlab/merge_request_templates/`, `docs/pull_request_template.md`). Fill its sections from the run artifacts. Otherwise use the default below.
- Open as **draft** if remote CI hasn't passed yet or the project prefers drafts for agent PRs.
- Title: `<type>(<scope>): <summary> [<KEY>]` or the project's convention.
- Link the ticket so trackers auto-transition: `Closes #123` (GitHub/GitLab issues), `PROJ-123` in title/branch (Jira smart commits/dev panel), `Fixes AB#123` (Azure Boards).
- Request reviewers from `CODEOWNERS` or project memory; add labels per convention.

Default PR body:
```markdown
## Summary
<2–4 sentences: what and why>

## Ticket
<link> — Closes <ref>

## Changes
- <bullet per meaningful change>

## How it was verified
- Unit/integration: <n> tests added, suite ✅ (`<cmd>`)
- Lint/types/build: ✅
- UI: <journeys verified, screenshots attached or linked>
- API: <endpoints/cases verified>

## Acceptance criteria
- [x] AC1 …
- [x] AC2 …

## Risks / rollout notes
<migrations, flags, env vars, backward compatibility — or "none">

## Reviewer notes
<where to start reading; anything intentionally left out>
```

## 7. After the PR
1. Watch remote CI via VCS MCP (check runs / pipelines for the head SHA). If red → `ci-guardian` remote loop.
2. Post a short comment on the ticket (tracker MCP) with the PR link and status; transition the ticket only if project memory says to (e.g. "In Review").
3. Address review comments: small, local requests → fix and push; design-level requests → summarize and ask the user.
