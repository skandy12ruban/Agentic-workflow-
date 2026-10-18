# Setup: Gemini CLI

Gemini CLI has project memory (`GEMINI.md`), custom commands (TOML), MCP, and extensions. Subagent and skills support have arrived in recent versions as experimental features — this guide works either way.

## 1. Install the library
```bash
git clone https://github.com/<you>/agentic-workflow.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool gemini --target /path/to/your/repo
```
This creates:
```
.gemini/commands/*.toml      ← commands converted from commands/*.md ($ARGUMENTS → {{args}})
.agentic/agents/*.md         ← role prompts (used when native subagents aren't enabled)
.agentic/skills/*/SKILL.md   ← skills (read on demand)
.agentic/templates/          ← AGENTS.md, GEMINI.md, PR template
```

### Manual conversion of a command
`commands/task.md` → `.gemini/commands/task.toml`:
```toml
description = "End-to-end agentic workflow - fetch a task, plan, approve, implement, test, CI, review, E2E, PR."
prompt = """
# /task — Ticket to Pull Request

**Input:** {{args}}

...rest of the markdown body, unchanged...
"""
```
Rules: drop the YAML frontmatter; `description` comes from it; replace `$ARGUMENTS` with `{{args}}`. Subfolders namespace commands: `.gemini/commands/wf/task.toml` → `/wf:task`. Gemini also supports `!{shell command}` and `@{path}` injection inside prompts. Reload with `/commands reload` (or restart).

## 2. Project memory
Create `AGENTS.md` from the template and either:
- add `GEMINI.md` that imports it (`templates/GEMINI.md` does `@./AGENTS.md`), **or**
- point Gemini directly at it in `.gemini/settings.json`:
```json
{ "context": { "fileName": ["AGENTS.md", "GEMINI.md"] } }
```
(Older versions: top-level `"contextFileName": ["AGENTS.md", "GEMINI.md"]`.) Check with `/memory show`.

Keep the **Agentic workflow library** section of `AGENTS.md` — it tells Gemini where the role and skill files are.

## 3. Agents & skills
- **Native subagents/skills enabled in your version?** Copy `agents/*.md` and `skills/*/` into the directories your version documents (they use the same markdown-with-frontmatter idea; adjust frontmatter fields if required).
- **Otherwise (always works):** commands say "delegate to the `X` agent" → Gemini reads `.agentic/agents/X.md` and performs the role as a focused sub-task. Explicitly encourage it in `GEMINI.md`:
  > When a command says "delegate to the `X` agent", read `.agentic/agents/X.md` and follow it as a separate focused step, then summarize its output before continuing.
- **Extensions:** you can package this library as a Gemini CLI extension (`gemini-extension.json` + `commands/` + context file + MCP servers) to install it with one command across machines. See Gemini CLI's extension docs.

## 4. MCP servers
See [MCP servers → Gemini CLI](../mcp-servers.md#gemini-cli). Check with `/mcp` (and `/mcp desc` for tool descriptions).

## 5. Safety settings
- Keep tool confirmation on for shell commands that write (Gemini prompts by default). Avoid `--yolo` outside disposable sandboxes.
- Use sandboxing (`--sandbox`, Docker/Podman/Seatbelt profiles) for autonomous runs.
- Exclude/allow tools per MCP server with `includeTools` / `excludeTools` in its settings entry (e.g. exclude a merge tool).
- Use `.geminiignore` to keep secrets dirs out of context.

## 6. Use it
```text
/task PROJ-123
/plan "Add CSV export to the reports page"
/review --security-only
```
Gemini's large context window helps with exploration; still keep the phase discipline — the approval gate and `state.md` are what make runs reliable and resumable.
