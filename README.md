# Agentic Workflow

**A copy-paste library of agents, commands, and skills that turns AI coding tools into a ticket-to-PR delivery pipeline.**
Works with Claude Code, Gemini CLI, OpenAI Codex CLI, Cursor, GitHub Copilot, and any tool that reads markdown instructions. Works with any language or framework, because it detects your stack instead of assuming one.

```text
/task PROJ-123
```
```
 INTAKE ─▶ DISCOVER ─▶ PLAN ─▶ ⛔ YOU APPROVE ─▶ IMPLEMENT ─▶ TEST ─▶ LOCAL CI ─▶ REVIEW ─▶ UI / API E2E ─▶ PR ─▶ REPORT
 tracker    stack +     plan.md                   small,       framework-  lint,      code +     browser MCP /   remote
 via MCP    conventions                           verified     native      types,     security   HTTP against    CI
                                                  commits      tests       build      fix loop   local service   watched
```

You approve the plan. The agent handles the rest and stops to ask when it hits something it shouldn't decide alone.

---

## What's inside

| Folder | Contents | Copy it if you want… |
|---|---|---|
| [`commands/`](commands/) | 12 slash commands: `/task`, `/plan`, `/implement`, `/test`, `/ci-check`, `/review`, `/ui-test`, `/api-test`, `/ship`, `/fix-bug`, `/resume`, `/setup-project` | entry points you type |
| [`agents/`](agents/) | 11 specialist subagents: explorer, planner, implementer, test-engineer, ci-guardian, code-reviewer, security-auditor, ui-tester, api-tester, debugger, docs-writer | focused roles with their own context and tools |
| [`skills/`](skills/) | 13 on-demand skills: task-intake, stack-detection (15+ ecosystems), planning, approval-gate, workflow-state, git-workflow, test-generation, ci-verification, code-review, security-review, ui-testing, api-testing, systematic-debugging | deep know-how, loaded only when relevant |
| [`templates/`](templates/) | `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` project memory, PR template, `.gitignore` snippet | project memory and conventions |
| [`docs/`](docs/) | Concepts, workflow, MCP setup, per-tool guides, safety, customization, troubleshooting | to understand and adapt it |
| [`examples/`](examples/) | Full walkthroughs: [full-stack feature](examples/full-stack-feature.md), [backend bug fix](examples/backend-bugfix.md) | to see a run before trying one |
| [`scripts/install.sh`](scripts/install.sh) | Installs everything for your tool and converts formats (e.g. TOML for Gemini) | a one-command setup |

## Quick start (5 minutes)

```bash
git clone https://github.com/<you>/agentic-workflow.git ~/agentic-workflow
cd /path/to/your/project
~/agentic-workflow/scripts/install.sh --tool claude     # or: gemini | codex | cursor | copilot | generic
```
Then, in your AI tool:
```text
/setup-project          # detects your stack, CI and MCPs, then writes AGENTS.md / CLAUDE.md
/plan PROJ-123          # see a plan without changing any code
/task PROJ-123          # the full pipeline
```
→ The step-by-step version, including MCP setup, is in **[QUICKSTART.md](QUICKSTART.md)**.

## Pick what you need

Every file stands alone. Some common à-la-carte setups:

| Goal | Copy |
|---|---|
| **Better code reviews** | `agents/code-reviewer.md`, `agents/security-auditor.md`, `skills/code-review/`, `skills/security-review/`, `commands/review.md` |
| **Tests in my framework** | `agents/test-engineer.md`, `skills/test-generation/`, `skills/stack-detection/`, `commands/test.md` |
| **Plan before coding** | `agents/codebase-explorer.md`, `agents/planner.md`, `skills/planning/`, `skills/approval-gate/`, `skills/task-intake/`, `commands/plan.md` |
| **Green CI** | `agents/ci-guardian.md`, `skills/ci-verification/`, `commands/ci-check.md` |
| **Browser-verified UI changes** | `agents/ui-tester.md`, `skills/ui-testing/`, `commands/ui-test.md` + Playwright MCP |
| **API verification** | `agents/api-tester.md`, `skills/api-testing/`, `commands/api-test.md` |
| **Bug fixing** | `agents/debugger.md`, `skills/systematic-debugging/`, `commands/fix-bug.md` |
| **Everything** | `scripts/install.sh --tool <yours>` |

## Tool support

| | Claude Code | Gemini CLI | Codex CLI | Cursor | Copilot | Others |
|---|---|---|---|---|---|---|
| Commands | native | converted to TOML | `/prompts:<name>` | native | `.prompt.md` | paste / workflows |
| Agents | native subagents | role files* | role files | role files | custom agents | role files / modes |
| Skills | native | role files* | native* / role files | rules | native* / role files | role files |
| MCP | ✅ | ✅ | ✅ | ✅ | ✅ | usually ✅ |
| Guide | [→](docs/setup/claude-code.md) | [→](docs/setup/gemini-cli.md) | [→](docs/setup/codex-cli.md) | [→](docs/setup/cursor.md) | [→](docs/setup/github-copilot.md) | [→](docs/setup/other-tools.md) |

\* Native support depends on your tool version. "Role files" means the agent reads `.agentic/agents/<name>.md` or `.agentic/skills/<name>/SKILL.md` itself. Same behaviour, no native isolation.

## MCP servers (what to connect)

| Capability | Examples | Enables |
|---|---|---|
| Tracker | Jira/Confluence (Atlassian), Linear, GitHub Issues, GitLab, Azure Boards | `/task PROJ-123` reads the ticket and posts the PR link back |
| VCS / CI | GitHub, GitLab, Azure DevOps | PRs, CI logs, review comments |
| Browser | Playwright MCP, Chrome DevTools MCP | Real-browser UI verification + screenshots |
| Optional | Sentry, Context7, Figma, Notion, local DB | Error-driven fixes, current docs, designs, specs, side-effect checks |

Details, configs for every tool, and a security checklist: **[docs/mcp-servers.md](docs/mcp-servers.md)**.

## Design principles

1. **Human approval before code.** The agent may explore and plan freely, and builds only after you say `approve`. It never merges, deploys, or force-pushes.
2. **Detect, don't assume.** Test framework, commands and dev server come from your repo and CI. Project memory overrides everything.
3. **Everything is a file.** Each run lives in `.agentic/runs/<RUN-ID>/` (ticket, plan, state, reports, screenshots), so you can resume it, audit it, or hand it to a different tool.
4. **Small verified steps, bounded loops.** Each step is checked before the next one starts. Fix loops have budgets, and when a budget runs out the agent stops and asks.
5. **Graceful degradation.** No MCP? Paste the ticket. No browser? Headless specs. No subagents? Role files.

## Learn more

- [Concepts](docs/concepts.md): memory, commands, agents, skills, MCP, hooks, and how they map across tools
- [The workflow](docs/workflow.md): every phase, gate, artifact and stop condition
- [Safety & guardrails](docs/safety-and-guardrails.md): permissions, hooks, sandboxing, prompt injection
- [Customization](docs/customization.md): add phases, team skills, monorepos, plugins
- [Troubleshooting & FAQ](docs/troubleshooting.md)
- [Contributing](CONTRIBUTING.md)
