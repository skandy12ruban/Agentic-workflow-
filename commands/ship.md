---
description: Push the current branch and open (or update) a pull request with a complete description built from the run's ticket, plan, and reports; link the ticket; watch remote CI and fix failures.
argument-hint: '[RUN-ID] [--draft] [--reviewers a,b] [--no-watch]'
---

# /ship — Push, PR, and follow through

**Input:** $ARGUMENTS

Apply the `git-workflow` skill throughout. Hard rules: never push to base/protected branches, never force-push others' branches, never merge.

1. **Pre-flight**
   - On a feature branch? Clean tree? Commits ahead of base?
   - Latest local CI result green (`ci-report.md` newer than last commit)? If not → run `/ci-check` first.
   - Any blocking findings left in `review.md`? If yes → stop and list them.
2. **Gate (supervised autonomy):** show branch, commit list, PR title, and body preview. Apply `approval-gate`; wait.
3. **Push:** `git push -u origin <branch>` (retry on network errors with backoff).
4. **PR:** if one exists for the branch → update its description; else create one via VCS MCP (fallback: `gh`/`glab`/`az` CLI).
   - Use the repo's PR template if present; fill from `ticket.md`, `plan.md`, `test-report.md`, `ci-report.md`, `review.md`, `e2e-report.md`.
   - Link the ticket (`Closes #N`, `PROJ-123`, `AB#123`), set reviewers (`--reviewers`, CODEOWNERS, or project memory), labels, draft state.
   - Include or link screenshots for UI changes.
5. **Ticket:** comment with the PR link via tracker MCP; transition status only if project memory says so.
6. **Watch CI** (unless `--no-watch`): poll/subscribe to check runs for the head SHA. Red → delegate to `ci-guardian` in remote mode (max 3 iterations). If a check is red on the base branch too, note it in the PR rather than "fixing" it.
7. **Report:** PR URL, CI status, reviewers requested, follow-ups. Update `state.md` (`pr_url`, `phase: done` or `deliver` if CI still pending).
