---
description: Intake a task, explore the codebase, and produce an implementation plan for approval - without changing any code.
argument-hint: '<TICKET-KEY | issue URL | "free-text task">'
---

# /plan — Plan only

**Input:** $ARGUMENTS

> **Requires** — agents: codebase-explorer, planner · skills: guardrails, workflow-state, task-intake, stack-detection, planning, approval-gate · MCP: tracker (optional).
> Missing a file? Do that step yourself from the description here and say which file was missing. **Guardrails:** follow the `guardrails` skill throughout; stop if `.agentic/STOP` exists.

Run Phases 0–4 of the `/task` workflow and stop at the approval gate. **Do not modify any source files.** Only write under `.agentic/runs/<RUN-ID>/`.

1. **Bootstrap:** read project memory; determine RUN-ID; create `state.md` (`workflow-state` skill).
2. **Intake:** apply the `task-intake` skill → `ticket.md`. Ask blocking questions now.
3. **Discover:** apply `stack-detection`; delegate to the `codebase-explorer` agent → `context.md`.
4. **Plan:** delegate to the `planner` agent → `plan.md`. Check it against the `planning` skill's quality bar.
5. **Gate:** apply the `approval-gate` skill — present the summary and wait.

On approval: record it in `state.md` and tell the user they can continue with `/implement <RUN-ID>` (or `/resume <RUN-ID>` to run the rest of the pipeline).
On revise: produce plan v2 and gate again.
