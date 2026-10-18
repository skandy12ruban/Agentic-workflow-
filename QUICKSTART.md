# Quickstart

From zero to your first agent-built, browser-verified pull request. About 15 minutes the first time.

## Prerequisites
- An AI coding tool: Claude Code, Gemini CLI, Codex CLI, Cursor, GitHub Copilot (VS Code), or similar
- Git, and your project's normal toolchain (whatever you use to run tests locally)
- Node.js 18+ (most MCP servers run via `npx`)
- Optional: access to your issue tracker (Jira, Linear, GitHub Issues, and so on)

---

## Step 1 — Get the library
```bash
git clone https://github.com/<you>/agentic-workflow.git ~/agentic-workflow
```

## Step 2 — Install into your project
```bash
cd /path/to/your/project
~/agentic-workflow/scripts/install.sh --tool <claude|gemini|codex|cursor|copilot|generic>
cat ~/agentic-workflow/templates/gitignore-snippet.txt >> .gitignore
```
Prefer to copy files by hand? Each folder's README has a copy-paste block, and every file stands alone.

<details>
<summary>What gets installed where</summary>

| Tool | Commands | Agents | Skills | Templates |
|---|---|---|---|---|
| claude | `.claude/commands/` | `.claude/agents/` | `.claude/skills/` | `.agentic/templates/` |
| gemini | `.gemini/commands/*.toml` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` |
| codex | `~/.codex/prompts/` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` |
| cursor | `.cursor/commands/` + rule | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` |
| copilot | `.github/prompts/*.prompt.md` | `.github/agents/*.agent.md` | `.agentic/skills/` | `.agentic/templates/` |
| generic | `.agentic/commands/` | `.agentic/agents/` | `.agentic/skills/` | `.agentic/templates/` |
</details>

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

## Step 7 — Tune
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
