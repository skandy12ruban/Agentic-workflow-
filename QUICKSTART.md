# Quickstart

From zero to your first agent-built, browser-verified pull request. About 15 minutes the first time.

## Prerequisites
- An AI coding tool: Claude Code, Gemini CLI, Codex CLI, Cursor, GitHub Copilot (VS Code), or similar
- Git, and your project's normal toolchain (whatever you use to run tests locally)
- Node.js 18+ (most MCP servers run via `npx`)
- Optional: access to your issue tracker (Jira, Linear, GitHub Issues, and so on)

---

## Step 1 — Install into your project
**One line** (fetches the library into `~/.agentic-workflow`, then installs):
```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/skandy12ruban/Agentic-workflow-/main/scripts/install.sh | bash -s -- --tool <claude|gemini|codex|cursor|copilot|generic>
```
**Or clone first** (lets you read the script before running it):
```bash
git clone https://github.com/skandy12ruban/Agentic-workflow-.git ~/agentic-workflow
~/agentic-workflow/scripts/install.sh --tool <tool> --target . --dry-run     # preview
~/agentic-workflow/scripts/install.sh --tool <tool> --target .
```
**Or ask your AI tool to do it:** paste the prompt from [INSTALL_WITH_AI.md](INSTALL_WITH_AI.md).

Then:
```bash
cat ~/.agentic-workflow/templates/gitignore-snippet.txt >> .gitignore   # or ~/agentic-workflow/... if you cloned
```
Guardrails are installed by default: the Claude Code hooks and settings, git `pre-commit`/`pre-push`, and `.agentic/protected-paths`. Existing files are never overwritten (use `--force` deliberately). Prefer to copy files by hand? Each folder's README has a copy-paste block, and every file lists what it requires.

<details>
<summary>What gets installed where</summary>

| Tool | Commands | Agents | Skills | Templates | Guardrails |
|---|---|---|---|---|---|
| claude | `.claude/commands/` | `.claude/agents/` | `.claude/skills/` | `.agentic/templates/` | `.claude/hooks/` + `settings.json` + git hooks |
| gemini | `.gemini/commands/*.toml` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` | git hooks |
| codex | `~/.codex/prompts/` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` | git hooks |
| cursor | `.cursor/commands/` + rule | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` | git hooks |
| copilot | `.github/prompts/*.prompt.md` | `.github/agents/*.agent.md` | `.agentic/skills/` | `.agentic/templates/` | git hooks |
| generic | `.agentic/commands/` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` | git hooks |
</details>

## Step 2 — Protect your default branch
On GitHub/GitLab/Azure DevOps, enable branch protection on `main`: pull request required, ≥ 1 approval, required status checks, no force-push, no deletion. This is the guardrail no agent can bypass.


## Step 3 — Connect MCP servers (the minimum set)

| Need | Recommended | Claude Code one-liner |
|---|---|---|
| Browser (UI testing) | Playwright MCP | `claude mcp add --scope project playwright -- npx @playwright/mcp@latest` |
| VCS (PRs, CI) | GitHub MCP | `claude mcp add --scope project --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer \${GITHUB_PAT}"` |
| Tracker | Atlassian / Linear / GitHub Issues | `claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse` |

Other tools: copy the JSON or TOML for your tool from [docs/mcp-servers.md](docs/mcp-servers.md). You can skip the tracker server: paste ticket text into `/task "..."` instead.

## Step 4 — Generate project memory
In your AI tool, from the project root:
```text
/setup-project
```
(Codex: `/prompts:setup-project`; Gemini in the generic layout: "Follow `.agentic/commands/setup-project.md`".)

It detects your stack, CI gate, conventions and available MCPs, asks you a few questions (tracker key, base URL, test user, autonomy level), and writes `AGENTS.md` (plus `CLAUDE.md`/`GEMINI.md` if needed). **Review it.** This file has the biggest effect on output quality. Commit it.

## Step 5 — Dry run: plan only
```text
/plan PROJ-123
```
or with no tracker:
```text
/plan "Add a 'Copy link' button to the share dialog that copies the canonical URL and shows a toast"
```
Check that:
- the acceptance criteria match what you meant
- the plan cites real files and existing patterns (precedents)
- each step has a verification command
- it **stopped and asked for approval** without touching code

Reply `revise: …` a couple of times to get a feel for it, then `stop`.

## Step 6 — First full run
Pick a small, well-defined ticket (size S, ideally one with a UI or API surface):
```text
/task PROJ-123
```
Approve the plan, watch the phases go by, approve the push, and review the PR the way you would a teammate's. Open `.agentic/runs/PROJ-123/` to see what it checked: `test-report.md`, `review.md`, `e2e-report.md`, and the screenshots in `artifacts/`.

## Step 7 — Verify the guardrails
```bash
~/.agentic-workflow/scripts/test-guardrails.sh        # hooks behave as specified (150 cases)
```
Then try a few behavioural scenarios from [docs/guardrail-tests.md](docs/guardrail-tests.md) in a throwaway branch, e.g. ask the agent to "push this straight to main" or "read .env". It should refuse. **Emergency stop at any time:** `touch .agentic/STOP`.

## Step 8 — Tune
- The agent got a command or convention wrong → add one line to `AGENTS.md`.
- Too many permission prompts → pre-approve safe commands ([Claude Code example](docs/setup/claude-code.md#4-permissions--hooks--claudesettingsjson)).
- You want guarantees, not instructions → add hooks ([safety](docs/safety-and-guardrails.md)).
- You have a team-specific process → write a skill ([customization](docs/customization.md)).

## Cheat sheet
```text
/task <ticket>              full pipeline (you approve the plan, and the push in supervised mode)
/plan <ticket>              plan only
/implement <run>            build an approved plan
/test [target]              framework-native tests
/ci-check [--remote]        local CI gate; fix the red PR
/review [PR|branch] [--fix|--post]
/ui-test [route|run]        real-browser verification
/api-test [endpoint|run]    endpoint verification
/ship [run]                 push + PR + ticket link + watch CI
/fix-bug <ticket|sentry url|stack trace>
/resume [run]               continue after a pause, in any tool
```
