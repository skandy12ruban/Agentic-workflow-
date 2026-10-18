# Core Concepts

Every modern AI coding tool has converged on the same five building blocks, even if they name them differently. Understand these and you can port anything in this repo to any tool.

## The five building blocks

| Concept | What it is | When it's loaded | Analogy |
|---|---|---|---|
| **Project memory** | A markdown file of always-on instructions about *this* repo: how to build, test, conventions, do/don't. | Every session, automatically | The onboarding doc you give a new hire |
| **Command** | A reusable prompt you trigger explicitly with `/name args`. | Only when you type it | A runbook you hand someone: "do this procedure" |
| **Agent** (subagent) | A specialist persona with its own system prompt, tool allow-list, and (usually) its own context window. | When the main agent delegates, or you ask for it | A teammate with one job (reviewer, tester) |
| **Skill** | A packaged capability: instructions + optional scripts/reference files, discovered by its description and loaded on demand. | When the task matches the skill's description | A reference manual the teammate pulls off the shelf |
| **MCP server** | A connector that gives the agent new *tools*: read Jira, drive a browser, query a DB, open a PR. | Configured once; tools always available | Giving the teammate system access |

Plus one optional sixth: **hooks** — deterministic scripts the *harness* (not the model) runs on events like "after every file edit" or "before any shell command". Use them for things that must always happen (formatting, blocking dangerous commands), because the model can forget instructions; a hook can't.

## How they compose

```
You type:  /task PROJ-123
              │
              ▼
   ┌──────────────────────┐   reads    ┌───────────────────────┐
   │ COMMAND: task.md     │──────────▶ │ PROJECT MEMORY        │
   │ (the orchestrator)   │            │ CLAUDE.md / AGENTS.md │
   └──────────┬───────────┘            └───────────────────────┘
              │ delegates
   ┌──────────┼──────────────┬───────────────┬──────────────┐
   ▼          ▼              ▼               ▼              ▼
 planner   implementer   test-engineer   code-reviewer   ui-tester   ← AGENTS
   │          │              │               │              │
   │ uses     │ uses         │ uses          │ uses         │ uses
   ▼          ▼              ▼               ▼              ▼
 planning  git-workflow  test-generation  code-review    ui-testing  ← SKILLS
                              │                             │
                              │ calls tools                 │ calls tools
                              ▼                             ▼
                        shell (npm test)          Playwright MCP (browser) ← MCP
```

**Rule of thumb for where things go:**

- Is it true for *every* task in this repo? → **project memory**.
- Is it a *procedure* a human kicks off? → **command**.
- Is it a *role* that benefits from a fresh context or restricted tools? → **agent**.
- Is it *know-how* that's only sometimes relevant (and maybe long)? → **skill**.
- Does the agent need to *reach a system* it can't reach with the shell? → **MCP**.
- Must it happen *every time, no exceptions*? → **hook**.

## Name mapping across tools

| Concept | Claude Code | Gemini CLI | OpenAI Codex CLI | Cursor | GitHub Copilot (VS Code) |
|---|---|---|---|---|---|
| Project memory | `CLAUDE.md` (can also read `AGENTS.md`) | `GEMINI.md` (configurable, can read `AGENTS.md`) | `AGENTS.md` | `.cursor/rules/*.mdc`, `AGENTS.md` | `.github/copilot-instructions.md`, `AGENTS.md` |
| Commands | `.claude/commands/*.md` | `.gemini/commands/*.toml` | `~/.codex/prompts/*.md` | `.cursor/commands/*.md` | `.github/prompts/*.prompt.md` |
| Agents | `.claude/agents/*.md` | Extensions / experimental subagents — else inline roles | Inline roles via `AGENTS.md` | Custom modes / inline roles | `.github/agents/*.agent.md` |
| Skills | `.claude/skills/<name>/SKILL.md` | Experimental skills support in recent versions — else `@file` references | Skills support in recent versions — else referenced files | Referenced files / rules | Skills support in recent versions — else referenced files |
| MCP config | `.mcp.json` / `claude mcp add` | `.gemini/settings.json` → `mcpServers` / `gemini mcp add` | `~/.codex/config.toml` → `[mcp_servers.*]` / `codex mcp add` | `.cursor/mcp.json` | `.vscode/mcp.json` → `servers` |
| Hooks | `.claude/settings.json` → `hooks` | Hooks in recent versions | Limited / notify | Hooks in recent versions | – |

> Tool features move fast. Where a cell says "recent versions", check your tool's current docs; the [setup guides](setup/) show both the native path and a fallback that always works.

## Why the files in this repo use Claude Code format

Claude Code's formats are the most complete superset (frontmatter for agents, commands and skills). Every file's **body is plain, tool-agnostic markdown** — no Claude-only syntax beyond `$ARGUMENTS`. Converting to another tool means at most: rename the file, adjust frontmatter, swap `$ARGUMENTS` for that tool's placeholder. The [setup guides](setup/) and [`scripts/install.sh`](../scripts/install.sh) do this for you.

## Portability conventions used throughout

- **"Delegate to the `X` agent"** means: if your tool has subagents, spawn `X`; otherwise read `agents/X.md` and follow it yourself as a focused sub-task.
- **"Apply the `Y` skill"** means: load `skills/Y/SKILL.md` (auto-loaded in tools with skills support; otherwise read the file).
- **"Use the tracker MCP / browser MCP / VCS MCP"** names a *capability*, not a product. Jira, Linear, GitHub Issues, Azure Boards and GitLab all satisfy "tracker". See [MCP servers](mcp-servers.md).
- **`$ARGUMENTS`** is whatever the user typed after the command.
