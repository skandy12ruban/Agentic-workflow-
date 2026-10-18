# Setup: Cursor

Cursor has project rules (`.cursor/rules/*.mdc`), reads `AGENTS.md`, supports custom slash commands (`.cursor/commands/*.md`), and MCP (`.cursor/mcp.json`). Recent versions add more agent features (background agents, hooks, subagent-like modes); this guide uses the parts that are stable.

## 1. Install the library
```bash
git clone https://github.com/<you>/agentic-workflow.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool cursor --target /path/to/your/repo
```
Creates:
```
.cursor/commands/*.md        ← commands (type / in Agent chat)
.cursor/rules/agentic-workflow.mdc  ← always-on rule pointing to the library
.agentic/agents/  .agentic/skills/  .agentic/templates/
```

## 2. Project memory
Use `AGENTS.md` at the root (from `templates/AGENTS.md`) — Cursor picks it up. For finer control, split repo-specific rules into `.cursor/rules/*.mdc`:
```markdown
---
description: Agentic workflow conventions
globs:
alwaysApply: true
---
- This repo uses the agentic workflow library in `.agentic/`.
- When a command says "delegate to the `X` agent", read `.agentic/agents/X.md` and follow it as a focused step.
- When a command says "apply the `Y` skill", read `.agentic/skills/Y/SKILL.md` first.
- Never write source code before the plan is approved (see `.agentic/skills/approval-gate/SKILL.md`).
```
Rule types: `alwaysApply: true` (always), `globs:` (auto-attach for matching files, e.g. a testing rule for `**/*.test.ts`), or description-only (agent-requested — this works like a skill).

**Skills as rules:** for any skill you want auto-discovered, you can create an agent-requested rule whose `description` is the skill's description and whose body is `See .agentic/skills/<name>/SKILL.md`.

## 3. Commands
`.cursor/commands/task.md` is the body of `commands/task.md`. Text typed after `/task` is passed along with the command; the `$ARGUMENTS` line tells the agent where the input goes (Cursor appends your text to the prompt).

## 4. MCP
See [MCP servers → Cursor](../mcp-servers.md#cursor). Enable/disable servers and individual tools in Settings → MCP. Keep Playwright or Chrome DevTools MCP enabled for `/ui-test`.

## 5. Safety
- Keep auto-run (YOLO) off, or use its allow/deny command lists: allow test/lint commands; deny `git push --force`, `rm -rf`, deploy commands.
- Use `.cursorignore` for secrets directories and large generated folders.
- Background agents run on remote machines with repo access — use `autonomy: supervised` and branch-only pushes.

## 6. Use it
In Agent mode: `/task PROJ-123`, `/review`, `/ui-test /checkout`.
