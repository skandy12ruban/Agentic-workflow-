# Setup: GitHub Copilot (VS Code agent mode, Copilot coding agent)

Copilot supports repository instructions, `AGENTS.md`, prompt files (slash commands), custom agents, MCP, and — in recent versions — skills.

## 1. Install the library
```bash
git clone https://github.com/skandy12ruban/Agentic-workflow-.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool copilot --target /path/to/your/repo
```
Creates:
```
.github/prompts/*.prompt.md        ← commands → /task, /plan, ... in Copilot Chat
.github/agents/*.agent.md          ← custom agents (selectable in the agent picker)
.github/copilot-instructions.md    ← created only if missing; points at AGENTS.md + library
.agentic/skills/  .agentic/agents/  .agentic/templates/
```

### Prompt file format
```markdown
---
description: End-to-end agentic workflow ...
agent: agent            # older VS Code versions: mode: agent
# tools: ['codebase', 'terminal', 'github/*', 'playwright/*']   # optional allow-list
---
# /task — Ticket to Pull Request
**Input:** ${input:args}
...
```
`$ARGUMENTS` → `${input:args}` (VS Code prompts for or accepts trailing text). Run from Chat: `/task PROJ-123`.

### Custom agent format
```markdown
---
description: Independent skeptical reviewer of a diff...
tools: ['codebase', 'search', 'usages', 'problems', 'changes']
---
<agent body from agents/code-reviewer.md>
```
> ⚠️ The installer **drops** the Claude-style `tools:` line (tool names differ in Copilot), so converted agents get Copilot's default tools. For the read-only roles (`codebase-explorer`, `code-reviewer`, `security-auditor`), add an explicit read-only `tools:` list for your Copilot version (search/read tools only, no edit or terminal tools).

Older versions called these *chat modes* (`.github/chatmodes/*.chatmode.md`). Copilot custom agents run in the main conversation rather than as isolated subagents unless your version supports subagent delegation — the workflow still works because each role is fully specified.

## 2. Project memory
- `AGENTS.md` at the root (from `templates/AGENTS.md`) — supported by Copilot.
- `.github/copilot-instructions.md` — repo-wide instructions; keep short and reference `AGENTS.md`.
- Path-specific instructions: `.github/instructions/*.instructions.md` with `applyTo: "**/*.test.ts"` frontmatter — handy for testing conventions.

## 3. Skills
If your Copilot version supports Agent Skills, copy `skills/*/` into the documented skills folder (e.g. `.github/skills/`). Otherwise keep `.agentic/skills/` and the AGENTS.md pointer.

## 4. MCP
`.vscode/mcp.json` — see [MCP servers → Copilot](../mcp-servers.md#github-copilot-vs-code). The GitHub MCP server is first-party here. Start servers from the MCP view or the `mcp.json` code lens; pick tools in the Chat tools picker.

## 5. Copilot coding agent (cloud, assigns from issues)
- Assign an issue to Copilot; it works in a GitHub Actions-powered environment and opens a draft PR.
- It reads `AGENTS.md` / `copilot-instructions.md`, so the conventions and boundaries apply.
- Configure its environment with `.github/workflows/copilot-setup-steps.yml` (install deps, start DB, install Playwright browsers) so tests and UI checks can run.
- MCP for the coding agent is configured in the repository's Copilot settings on GitHub.
- The PR review is your approval gate; for plan-first behaviour, ask in the issue: "Post your plan as a PR comment and wait for approval before implementing."

## 6. Safety
- Keep terminal command auto-approval limited to safe commands (`chat.tools.terminal.autoApprove` style settings) — tests, lint, git status/diff.
- Keep "auto-approve all tools" off outside sandboxes.
