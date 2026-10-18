# Setup: Claude Code

Claude Code supports every building block natively — agents, commands, skills, MCP, hooks — so files install **as-is**.

## 1. Install the library (pick one)

**A. Install script (project-level, recommended for teams)**
```bash
git clone https://github.com/<you>/agentic-workflow.git ~/agentic-workflow
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
Pre-approve safe, frequent commands to reduce prompts; hard-deny dangerous ones; add deterministic hooks. Adjust commands to your stack:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)", "Bash(git switch:*)",
      "Bash(git add:*)", "Bash(git commit:*)",
      "Bash(pnpm test:*)", "Bash(pnpm lint:*)", "Bash(pnpm typecheck:*)", "Bash(pnpm build:*)",
      "Bash(npx vitest:*)", "Bash(npx playwright test:*)",
      "mcp__playwright"
    ],
    "ask": [
      "Bash(git push:*)", "Bash(pnpm add:*)", "Bash(npm install:*)",
      "mcp__github__create_pull_request"
    ],
    "deny": [
      "Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git reset --hard:*)",
      "Bash(rm -rf:*)", "Bash(terraform apply:*)", "Bash(kubectl delete:*)",
      "mcp__github__merge_pull_request",
      "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": "npx prettier --write \"$(jq -r '.tool_input.file_path')\" >/dev/null 2>&1 || true" }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": ".claude/hooks/guard-bash.sh" }]
      }
    ]
  }
}
```
MCP permission names: `mcp__<server>` (all tools of a server) or `mcp__<server>__<tool>`.

Example guard hook — `.claude/hooks/guard-bash.sh` (make it executable). Exit code 2 blocks the call and shows stderr to the model:
```bash
#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // ""')
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##'); base=${base:-main}
if echo "$cmd" | grep -Eq "git push .*(origin )?($base|master|main)(\s|$)"; then
  echo "Blocked: pushing to the base branch is not allowed. Push a feature branch instead." >&2; exit 2
fi
if echo "$cmd" | grep -Eq -- "--no-verify"; then
  echo "Blocked: do not bypass git hooks; fix the hook failure." >&2; exit 2
fi
exit 0
```

Other useful hooks: `Stop` → run a quick typecheck and block finishing if it fails; `SessionStart` → print `git status` and the active run's `state.md` summary; `Notification` → desktop/phone notification when an approval gate is waiting.

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
