---
description: Independent code + security review of the current branch, a PR, or a path - findings by severity with evidence and fixes. Optionally apply fixes or post the review to the PR.
argument-hint: '[RUN-ID | PR number/URL | branch | path] [--fix] [--post] [--security-only]'
---

# /review — Independent review

**Input:** $ARGUMENTS

1. **Resolve the diff:**
   - PR number/URL → fetch the PR diff + description + existing review comments via VCS MCP (or `gh pr diff`).
   - Branch → `git diff <base>...<branch>`. RUN-ID → that run's branch.
   - Path → review that code as-is (no diff).
   - Nothing → current branch vs base, including uncommitted changes.
2. **Gather intent:** ticket/plan if available (run dir, PR description, linked issue).
3. **Review in parallel** (if supported):
   - `code-reviewer` agent (skip if `--security-only`).
   - `security-auditor` agent — always if the diff touches inputs, auth, data access, files, network, config, or dependencies; otherwise a quick pass.
4. **Consolidate** into `review.md`: deduplicate, sort by severity, one verdict.
5. **Then:**
   - `--fix` → apply fixes for blockers/majors (and trivial minors), re-run affected tests and `ci-check` stages, request a fresh review (max 2 iterations).
   - `--post` → post as a PR review via VCS MCP: a summary comment + inline comments on specific lines for each finding. Use "request changes" only if blockers exist and project memory allows the agent to do so; otherwise "comment". **Ask before posting** unless already authorized.
   - Neither → print the findings table and verdict.

Reviewing someone else's PR: never push to their branch unless they asked; propose changes as review suggestions instead.
