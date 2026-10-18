---
description: Implement an approved plan step by step on a feature branch, verifying and committing each step.
argument-hint: '<RUN-ID | path/to/plan.md>'
---

# /implement — Execute an approved plan

**Input:** $ARGUMENTS

> **Requires** — agents: implementer · skills: guardrails, workflow-state, approval-gate, git-workflow · MCP: none.
> Missing a file? Do that step yourself from the description here and say which file was missing. **Guardrails:** follow the `guardrails` skill throughout; stop if `.agentic/STOP` exists.

1. Locate the run: `.agentic/runs/<RUN-ID>/` or the given plan path. No plan → tell the user to run `/plan` first. Stop.
2. Verify `state.md` has `plan_approved: yes` **and** `plan.md` hasn't changed since approval (compare `plan_version`). Otherwise → apply the `approval-gate` skill first.
3. Apply the `git-workflow` skill: ensure a clean tree, fetch base, create/switch to the feature branch.
4. Delegate to the `implementer` agent with the plan and run directory.
5. Track progress in `state.md` (`workflow-state` skill). Print one status line per completed step.
6. On a material deviation → stop and present it via `approval-gate`.
7. When all steps are done: classify the diff (frontend/backend/full-stack/other), record it, and suggest next: `/test <RUN-ID>` (or `/resume <RUN-ID>` for the full remaining pipeline).

Output a summary: steps done, commits (hash + subject), deviations, notes for testing.
