---
description: Run the project's CI gate locally (format, lint, typecheck, build, tests, extra gates) exactly as CI does, fix failures caused by the change, and optionally check/fix remote CI on the open PR.
argument-hint: '[RUN-ID] [--remote] [--stage format|lint|types|build|test|all]'
---

# /ci-check — Make it green before CI does

**Input:** $ARGUMENTS

> **Requires** — agents: ci-guardian · skills: guardrails, ci-verification, stack-detection · MCP: VCS (optional, for --remote).
> Missing a file? Do that step yourself from the description here and say which file was missing. **Guardrails:** follow the `guardrails` skill throughout; stop if `.agentic/STOP` exists.

1. Delegate to the `ci-guardian` agent (it applies the `ci-verification` skill):
   - Discover the gate from project memory → CI config → scripts → defaults.
   - Run stages cheapest-first (or only `--stage`), using CI's flags.
   - Triage each failure: this diff / exposed by diff / pre-existing / environmental / flaky.
   - Fix failures caused or exposed by the change; report the rest with evidence.
2. With `--remote` (or if a PR exists for the current branch and a VCS MCP is available): fetch the PR's check runs for the head SHA, read failing job logs, reproduce locally, fix, push a new commit, and re-check. Budget: 3 iterations.
3. Write `ci-report.md` (run dir or `.agentic/adhoc/`) and print the stage table.

Forbidden without explicit human approval: skipping tests, ignore-comments, loosening lint/coverage config, editing CI definitions, `|| true`.
