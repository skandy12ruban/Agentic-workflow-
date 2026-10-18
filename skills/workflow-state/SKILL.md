---
name: workflow-state
description: Create, update, and resume the per-run state file (.agentic/runs/<RUN-ID>/state.md) that tracks phase, approvals, step progress, loop counters, blockers, and artifacts. Use at every phase transition in /task, and to resume an interrupted run with /resume.
---

# Workflow State

`state.md` is the run's **single source of truth**. Agents and humans read it to know where things stand; `/resume` reads it to continue. Write it so any agent in any tool could pick up the run cold.

## Rules
1. **Create** it in Phase 0 from [`state-template.md`](state-template.md).
2. **Update on every phase transition** and after every plan step, loop iteration, gate, or blocker. Update *before* starting long operations, so an interruption leaves an accurate record.
3. **Never delete history.** Append to the `log`; don't rewrite it.
4. **Counters enforce loop budgets.** Increment before each retry; when `count >= budget`, stop and set a blocker.
5. **Keep it short and structured.** YAML front block for machine-readable fields, a markdown log for humans.

## Resuming a run
1. Read `state.md`. If it doesn't exist, the run can't be resumed — offer to start `/task` fresh.
2. Re-verify reality vs. recorded state:
   - Branch exists and is checked out? `git status` clean apart from expected changes?
   - Commits listed in state exist on the branch?
   - Approval still recorded? (If the plan file changed after approval → re-approve.)
3. If there's an open blocker, show it and ask whether the user has resolved it.
4. Continue from `phase` / the first unchecked step. Don't redo completed phases unless their inputs changed (e.g. new commits on base → re-run CI).

## Phase values
`intake → discover → plan → awaiting_approval → implement → test → ci → review → e2e → deliver → done`
plus terminal/side states: `blocked`, `stopped`, `failed`.

## Loop budgets (defaults; override in project memory)
| Loop | Budget |
|---|---|
| Implement: per-step verification attempts | 3 |
| Test fix iterations | 3 |
| Local CI fix iterations | 3 |
| Review → fix iterations | 2 |
| E2E fix iterations | 2 |
| Remote CI fix iterations | 3 |
