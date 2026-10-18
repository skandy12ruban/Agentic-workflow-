# Skills

Skills are on-demand know-how. Each is a folder with a `SKILL.md` (frontmatter `name` + `description`, then instructions) and optional supporting files the skill links to. Tools with native skills support read only the `description` up front and load the body when a task matches — so you can install all of them without bloating every conversation.

| Skill | What it gives the agent | Supporting files | Used by |
|---|---|---|---|
| [`task-intake`](task-intake/SKILL.md) | Fetch + normalize tickets from any tracker into `ticket.md` | – | `/task`, `/plan`, `/fix-bug` |
| [`stack-detection`](stack-detection/SKILL.md) | Detect languages, frameworks, commands, UI/API surfaces | [`stack-matrix.md`](stack-detection/stack-matrix.md) (15+ ecosystems) | explorer, test-engineer, ci-guardian |
| [`planning`](planning/SKILL.md) | Write approvable, verifiable plans | [`plan-template.md`](planning/plan-template.md) | planner |
| [`approval-gate`](approval-gate/SKILL.md) | Present decisions; interpret approval strictly; record it | – | `/task`, `/plan`, `/ship` |
| [`workflow-state`](workflow-state/SKILL.md) | Run state file, loop budgets, resume protocol | [`state-template.md`](workflow-state/state-template.md) | `/task`, `/resume` |
| [`git-workflow`](git-workflow/SKILL.md) | Branches, commits, PRs, ticket linking, post-PR CI | – | implementer, `/ship` |
| [`test-generation`](test-generation/SKILL.md) | Framework-native test design and writing | [`framework-cheatsheet.md`](test-generation/framework-cheatsheet.md) | test-engineer |
| [`ci-verification`](ci-verification/SKILL.md) | Reproduce CI locally; triage; remote CI via MCP | – | ci-guardian |
| [`code-review`](code-review/SKILL.md) | Review checklist, severity, fix loop | – | code-reviewer |
| [`security-review`](security-review/SKILL.md) | OWASP/CWE source→sink checklist, deps, secrets | – | security-auditor |
| [`ui-testing`](ui-testing/SKILL.md) | Browser-MCP verification, a11y, responsive, E2E specs | – | ui-tester |
| [`api-testing`](api-testing/SKILL.md) | REST/GraphQL/gRPC/webhook verification + integration tests | – | api-tester |
| [`systematic-debugging`](systematic-debugging/SKILL.md) | Reproduce→falsify→fix loop + playbooks | – | debugger |

## Install

**Claude Code** — copy folders as-is:
```bash
mkdir -p .claude/skills && cp -R skills/*/ .claude/skills/        # project
# or: mkdir -p ~/.claude/skills && cp -R skills/*/ ~/.claude/skills/   # all projects
```

**Tools with Agent Skills support** (recent Gemini CLI, Codex CLI, GitHub Copilot, Cursor — check your version): the `SKILL.md` format is shared; copy the folders into that tool's skills directory (see [`docs/setup/`](../docs/setup/)).

**Any other tool**: copy to `.agentic/skills/` and add the index table above to your project memory file so the agent knows they exist and reads `SKILL.md` when relevant. Commands in this repo already say "apply the `X` skill", which works with both approaches.

## Writing your own skill

```markdown
---
name: my-skill                      # lowercase, hyphens; matches the folder name
description: What it does AND when to use it, with trigger words users would actually say. This is the only part the agent sees before deciding to load it — make it specific.
---

# My Skill
Instructions in imperative form. Link supporting files relatively: [details](reference.md).
```

Tips:
- **Description is the trigger.** "Helps with testing" never fires; "Generate pytest tests for Django views, use when adding or changing views" does.
- **Keep `SKILL.md` focused** (a few hundred lines max). Push long reference tables into sibling files the skill links to — they're only read when needed.
- **Scripts are allowed.** A skill folder can include `scripts/check.sh` the instructions tell the agent to run — great for deterministic steps.
- **Team-specific skills** (your deploy process, your design-system rules, your data-migration playbook) are where skills pay off most. Copy one of these as a starting point.
