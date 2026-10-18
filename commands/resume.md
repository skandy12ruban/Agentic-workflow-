---
description: Resume an interrupted or paused workflow run from its state file - after approval, after a blocker was resolved, or in a new session or a different AI tool.
argument-hint: '[RUN-ID]  (omit to list resumable runs)'
---

# /resume — Continue a run

**Input:** $ARGUMENTS

1. **No RUN-ID:** list `.agentic/runs/*/state.md` whose `phase` isn't `done`/`stopped`, newest first, as a table (RUN-ID, title, phase, blockers, updated). Ask which to resume.
2. **Load** `state.md` and apply the `workflow-state` skill's resume protocol:
   - Reconcile with reality: branch exists/checked out, commits present, working tree state, plan unchanged since approval.
   - Base branch moved? → note it; you'll need to re-run CI after updating the branch.
3. **Open blocker?** Show it. Ask whether it's resolved (or read the answer if the user just gave it). Record the resolution in the log.
4. **Awaiting approval?** Re-present the gate (`approval-gate`) — previous silence is not approval. In headless mode, check the ticket/PR for an approval comment from an authorized user.
5. **Continue** the `/task` workflow from the recorded phase / first unfinished step, following the same rules and gates. Don't redo completed phases unless their inputs changed.
