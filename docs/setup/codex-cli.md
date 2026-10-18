# Setup: OpenAI Codex CLI

Codex reads `AGENTS.md` natively (global `~/.codex/AGENTS.md`, repo root, and nested directories), supports custom prompts as slash commands, MCP via `config.toml`, and — in recent versions — skills.

## 1. Install the library
```bash
git clone https://github.com/skandy12ruban/Agentic-workflow-.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool codex --target /path/to/your/repo
```
This creates:
```
~/.codex/prompts/*.md        ← commands (user-level; Codex custom prompts are per-user)
.agentic/agents/*.md         ← role prompts
.agentic/skills/*/SKILL.md   ← skills
.agentic/templates/
```
Manual equivalent:
```bash
mkdir -p ~/.codex/prompts && cp ~/agentic-workflow/commands/*.md ~/.codex/prompts/ && rm ~/.codex/prompts/README.md
mkdir -p .agentic && cp -R ~/agentic-workflow/{agents,skills,templates} .agentic/
```

Invoke commands as **`/prompts:task PROJ-123`** (custom prompts are namespaced under `prompts:`). `$ARGUMENTS` and positional `$1…$9` are supported; the `description` and `argument-hint` frontmatter show in the menu.

## 2. Project memory
Copy `templates/AGENTS.md` → `AGENTS.md` at the repo root and fill it in (or run `/prompts:setup-project`). Keep the **Agentic workflow library** section so Codex knows where agents and skills live.

Add to `AGENTS.md`:
> When a command says "delegate to the `X` agent", read `.agentic/agents/X.md` and perform that role as a focused step. When it says "apply the `Y` skill", read `.agentic/skills/Y/SKILL.md` first.

## 3. Skills (native, recent versions)
If your Codex version supports skills, copy skill folders into the skills directory it documents (user-level `~/.codex/skills/` or repo-level) — `SKILL.md` with `name`/`description` frontmatter is the shared format. Otherwise the `.agentic/skills/` + AGENTS.md pointer approach works everywhere.

## 4. MCP
See [MCP servers → Codex](../mcp-servers.md#openai-codex-cli). Verify with `/mcp` in the TUI.

## 5. Approvals & sandbox
Codex's approval and sandbox modes complement the workflow's gates:
- Interactive work: default/`on-request` approvals with `workspace-write` sandbox — the agent can edit the repo and run local commands, and asks before network or out-of-workspace actions.
- Never combine "never ask" approvals with full access outside a disposable environment.
- Network access is restricted by default in the sandbox; installing deps or reaching MCP/remote CI may require enabling it for the session.

## 6. Use it
```text
/prompts:task PROJ-123
/prompts:review --fix
codex exec "/prompts:ci-check --remote"     # non-interactive
```
Codex Cloud / GitHub integration can run the same prompts as background tasks; keep `autonomy: supervised` or the headless approval-gate flow so a human approves the plan.
