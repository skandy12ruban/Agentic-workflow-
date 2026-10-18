# Setup: Claude Code

Claude Code supports every building block natively — agents, commands, skills, MCP, hooks — so files install **as-is**.

## 1. Install the library (pick one)

**A. Install script (project-level, recommended for teams)**
```bash
git clone https://github.com/skandy12ruban/Agentic-workflow-.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool claude --target /path/to/your/repo
```

**B. Manual copy**
```bash
cd /path/to/your/repo
LIB=~/agentic-workflow
mkdir -p .claude/agents .claude/commands .claude/skills .agentic/templates
cp $LIB/agents/*.md   .claude/agents/   && rm .claude/agents/README.md
cp $LIB/commands/*.md .claude/commands/ && rm .claude/commands/README.md
cp -R $LIB/skills/*/  .claude/skills/
cp $LIB/templates/*   .agentic/templates/
```

**C. User-level (available in every repo)** — same as B but into `~/.claude/agents`, `~/.claude/commands`, `~/.claude/skills`.

**D. As a team plugin** — see [Customization → Package as a Claude Code plugin](../customization.md#package-as-a-claude-code-plugin).

**Cherry-pick** — every file is standalone. Want only the reviewer? Copy `agents/code-reviewer.md` + `skills/code-review/`.

## 2. Project memory
```bash
/setup-project            # inside Claude Code — detects and writes CLAUDE.md / AGENTS.md
```
Or copy `templates/AGENTS.md` → `AGENTS.md`, `templates/CLAUDE.md` → `CLAUDE.md` (which imports it), and edit.

## 3. MCP servers
See [MCP servers](../mcp-servers.md#claude-code). Minimum: GitHub (or your VCS), your tracker, Playwright.
```bash
claude mcp add --scope project playwright -- npx @playwright/mcp@latest
claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer \${GITHUB_PAT}"
```
Run `/mcp` in a session to authenticate OAuth servers and check status.

## 4. Permissions & hooks — `.claude/settings.json`
The installer sets this up by default. To do it by hand:
```bash
mkdir -p .claude/hooks
cp ~/agentic-workflow/hooks/claude/guard-*.sh .claude/hooks/ && chmod +x .claude/hooks/*.sh
[ -f .claude/settings.json ] || cp ~/agentic-workflow/hooks/claude/settings.json .claude/settings.json
cp ~/agentic-workflow/hooks/git/pre-commit ~/agentic-workflow/hooks/git/pre-push .git/hooks/
```
What you get (details and configuration in [`hooks/README.md`](../../hooks/README.md)):
- **[`settings.json`](../../hooks/claude/settings.json)**: *allow* read-only git plus common test/lint/build commands; *ask* for push, installs, network, and PR creation; *deny* force-push, `reset --hard`, `sudo`, infra applies, publishing, PR merges, secret files, and edits to the guardrails themselves.
- **[`guard-bash.sh`](../../hooks/claude/guard-bash.sh)**: a `PreToolUse` hook that blocks dozens of destructive, external, and bypass command families (protected-branch pushes, `--no-verify`, `curl | sh`, cloud and k8s mutations, DB drops, env dumps, …).
- **[`guard-files.sh`](../../hooks/claude/guard-files.sh)**: blocks secret files, guardrail edits, lockfile hand-edits, and protected paths. Asks before CI config changes. Blocks writing credentials into files.
- Both honour the **kill switch**: `touch .agentic/STOP` halts the agent instantly.
- Both are covered by `scripts/test-guardrails.sh`, and both **fail closed**.

Adjust the `allow` list to your stack's commands (e.g. add `Bash(make test:*)`). MCP permission names look like `mcp__<server>` (all tools of a server) or `mcp__<server>__<tool>`.

Optional extra hooks: `PostToolUse` on `Edit|Write` to auto-format the edited file (`"command": "npx prettier --write \"$(jq -r '.tool_input.file_path')\""`, needs jq and prettier). `Notification` to ping you when an approval gate is waiting. `SessionStart` to print the active run's `state.md` summary.

## 5. Use it
```text
/task PROJ-123
```
Tips:
- **Plan mode** (Shift+Tab to cycle modes) is a natural fit for `/plan`; the approval gate still applies when you leave it.
- **Parallel review**: the orchestrator can run `code-reviewer` and `security-auditor` concurrently.
- **Headless / CI**: `claude -p "/task PROJ-123 --autonomy standard" --output-format stream-json` in a runner. Keep the approval gate by using the headless mode described in the `approval-gate` skill (post plan, wait for an `/approve` comment), or restrict to `autonomous` with tight criteria in a sandbox.
- **GitHub Actions**: Anthropic's Claude Code GitHub Action can run these commands on issue/PR comments (e.g. `@claude /task`). Give it the same `.claude/` directory.
- **Context hygiene**: long runs benefit from subagents (each has its own context). Use `/compact` between phases if your session gets long — `state.md` preserves everything that matters.
