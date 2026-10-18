# Agentic Workflow

**Copy-paste agents, commands, skills, and *enforced* guardrails that turn any AI coding tool into a safe ticket-to-pull-request pipeline.**

Works with **Claude Code, Gemini CLI, OpenAI Codex CLI, Cursor, GitHub Copilot**, and any tool that reads markdown instructions. Works with any language or framework, because it detects your stack instead of assuming one.

[![validate](https://github.com/skandy12ruban/Agentic-workflow-/actions/workflows/validate.yml/badge.svg)](https://github.com/skandy12ruban/Agentic-workflow-/actions/workflows/validate.yml)
![tools](https://img.shields.io/badge/tools-Claude%20%C2%B7%20Gemini%20%C2%B7%20Codex%20%C2%B7%20Cursor%20%C2%B7%20Copilot-blue)
![guardrail tests](https://img.shields.io/badge/guardrail%20tests-150%20passing-brightgreen)

```text
/task PROJ-123
```
```
 INTAKE ─▶ DISCOVER ─▶ PLAN ─▶ ⛔ YOU APPROVE ─▶ IMPLEMENT ─▶ TEST ─▶ LOCAL CI ─▶ REVIEW ─▶ UI / API E2E ─▶ PR ─▶ REPORT
 tracker    stack +     plan.md                   small,       framework-  lint,      code +     browser MCP /   remote
 via MCP    conventions                           verified     native      types,     security   HTTP against    CI
                                                  commits      tests       build      fix loop   local service   watched
```

You approve the plan. The agent does the rest and stops to ask when it hits something it shouldn't decide alone. It **cannot** merge, deploy, force-push, or read your secrets: hooks block those, not just instructions.

---

## Install in one line

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/skandy12ruban/Agentic-workflow-/main/scripts/install.sh | bash -s -- --tool claude
#   --tool  claude | gemini | codex | cursor | copilot | generic        add --dry-run to preview
```
<details><summary>Prefer to read the script first? (recommended)</summary>

```bash
git clone https://github.com/skandy12ruban/Agentic-workflow-.git ~/agentic-workflow
less ~/agentic-workflow/scripts/install.sh
~/agentic-workflow/scripts/install.sh --tool claude --target . --dry-run
~/agentic-workflow/scripts/install.sh --tool claude --target .
```
</details>

**Or let your AI install it:** paste the prompt from [INSTALL_WITH_AI.md](INSTALL_WITH_AI.md) into your tool.

Then, in your AI tool:
```text
/setup-project          # detects stack, CI and MCPs → writes AGENTS.md / CLAUDE.md
/plan PROJ-123          # see a plan, no code changed
/task PROJ-123          # the full pipeline
```
Full walkthrough with MCP setup: **[QUICKSTART.md](QUICKSTART.md)** (about 15 minutes).

## What's inside

| Folder | Contents |
|---|---|
| [`commands/`](commands/) | **12 slash commands.** `/task` (full pipeline), `/plan`, `/implement`, `/test`, `/ci-check`, `/review`, `/ui-test`, `/api-test`, `/ship`, `/fix-bug`, `/resume`, `/setup-project` |
| [`agents/`](agents/) | **11 specialist subagents.** explorer, planner, implementer, test-engineer, ci-guardian, code-reviewer, security-auditor, ui-tester, api-tester, debugger, docs-writer |
| [`skills/`](skills/) | **14 on-demand skills.** `guardrails` (always on), task-intake, stack-detection (15+ ecosystems), planning, approval-gate, workflow-state, git-workflow, test-generation, ci-verification, code-review, security-review, ui-testing, api-testing, systematic-debugging |
| [`hooks/`](hooks/) | **Enforced guardrails.** Claude Code pre-tool hooks, git `pre-commit`/`pre-push` for every tool, a kill switch, protected paths. Tested, and they fail closed. |
| [`templates/`](templates/) | `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` project memory, PR template, `.gitignore` snippet |
| [`docs/`](docs/) | [Concepts](docs/concepts.md) · [Workflow](docs/workflow.md) · [MCP servers](docs/mcp-servers.md) · [Per-tool setup](docs/setup/) · [Safety](docs/safety-and-guardrails.md) · [Red-team tests](docs/guardrail-tests.md) · [Customization](docs/customization.md) · [Troubleshooting](docs/troubleshooting.md) · [References](docs/references.md) · [Engineering review](docs/engineering-review.md) |
| [`examples/`](examples/) | Full run transcripts: [full-stack feature](examples/full-stack-feature.md) · [backend bug fix](examples/backend-bugfix.md) |
| [`scripts/`](scripts/) | `install.sh` (converts formats per tool), `test-guardrails.sh` (150 cases), `validate.sh` (CI) |
| [`llms.txt`](llms.txt) | An index for AI agents reading this repo |

## Guardrails: defence in depth

| Layer | What it does | Bypassable by the model? |
|---|---|---|
| [`guardrails` skill](skills/guardrails/SKILL.md) | Risk classes R0–R4, prompt-injection protocol, secrets and PII rules, test integrity, **evidence rule** (never claim unobserved results), escalation format | Yes, in principle. It's instructions. |
| [Approval gates](skills/approval-gate/SKILL.md) | No code before an explicit `approve`; re-approval for scope changes; `autonomous` only when `sandboxed: true` | Yes, in principle. |
| [Claude Code hooks](hooks/claude/) | Block force-push, protected-branch pushes, `--no-verify`, `reset --hard`, PR merges, dangerous `rm`, `sudo`, `curl \| sh`, cloud/k8s/infra mutations, deploys, DB drops, publishing, reading `.env`/keys, env dumps, credentials in written files, and edits to the guardrails themselves | **No.** The harness enforces them. |
| [Git hooks](hooks/git/) | No commits or pushes to protected branches, no force-push or deletion, no tag pushes, secret scan | **No**, for any tool. |
| Kill switch | `touch .agentic/STOP` halts the agent instantly | **No.** |
| Your Git host | Branch protection + required review (the last line of defence) | **No.** |

Verify your setup: `scripts/test-guardrails.sh` (mechanical) and [the red-team scenarios](docs/guardrail-tests.md) (behavioural).

## Pick what you need

Every file stands alone. Each command lists what it **Requires**, and each agent lists the skills it uses.

| Goal | Copy |
|---|---|
| **Better code reviews** | `agents/code-reviewer.md`, `agents/security-auditor.md`, `skills/code-review/`, `skills/security-review/`, `commands/review.md` |
| **Tests in my framework** | `agents/test-engineer.md`, `skills/test-generation/`, `skills/stack-detection/`, `commands/test.md` |
| **Plan before coding** | `agents/codebase-explorer.md`, `agents/planner.md`, `skills/planning/`, `skills/approval-gate/`, `skills/task-intake/`, `commands/plan.md` |
| **Green CI** | `agents/ci-guardian.md`, `skills/ci-verification/`, `commands/ci-check.md` |
| **Browser-verified UI** | `agents/ui-tester.md`, `skills/ui-testing/`, `commands/ui-test.md` + Playwright MCP |
| **API verification** | `agents/api-tester.md`, `skills/api-testing/`, `commands/api-test.md` |
| **Bug fixing** | `agents/debugger.md`, `skills/systematic-debugging/`, `commands/fix-bug.md` |
| **Just the guardrails** | `skills/guardrails/`, `hooks/` (see [hooks/README.md](hooks/README.md)) |
| **Everything** | the one-line install above |

Always include `skills/guardrails/` whatever else you take.

Single file without cloning, e.g. the reviewer for Claude Code:
```bash
mkdir -p .claude/agents && curl -fsSL -o .claude/agents/code-reviewer.md \
  https://raw.githubusercontent.com/skandy12ruban/Agentic-workflow-/main/agents/code-reviewer.md
```

## Tool support

| | Claude Code | Gemini CLI | Codex CLI | Cursor | Copilot | Others |
|---|---|---|---|---|---|---|
| Commands | native | converted to TOML | `/prompts:<name>` | native | `.prompt.md` | paste / workflows |
| Agents | native subagents | role files* | role files | role files | custom agents | role files / modes |
| Skills | native | role files* | native* / role files | rules | native* / role files | role files |
| MCP | ✅ | ✅ | ✅ | ✅ | ✅ | usually ✅ |
| Enforced hooks | ✅ pre-tool + git | git | git | git | git | git |
| Guide | [→](docs/setup/claude-code.md) | [→](docs/setup/gemini-cli.md) | [→](docs/setup/codex-cli.md) | [→](docs/setup/cursor.md) | [→](docs/setup/github-copilot.md) | [→](docs/setup/other-tools.md) |

\* Native support depends on the tool version. "Role files" means the agent reads `.agentic/agents/<name>.md` or `.agentic/skills/<name>/SKILL.md` itself: same behaviour, without native context isolation.

## MCP servers to connect

| Capability | Examples | Enables |
|---|---|---|
| Tracker | Jira/Confluence (Atlassian), Linear, GitHub Issues, GitLab, Azure Boards | `/task PROJ-123` reads the ticket and posts the PR link back |
| VCS / CI | GitHub, GitLab, Azure DevOps | PRs, CI logs, review comments |
| Browser | Playwright MCP, Chrome DevTools MCP | Real-browser UI verification + screenshots |
| Optional | Sentry, Context7, Figma, Notion, local DB | Error-driven fixes, current docs, designs, specs, side-effect checks |

Configs for every tool and a security checklist: **[docs/mcp-servers.md](docs/mcp-servers.md)**. Without MCP, everything still works: paste tickets, use the `gh` CLI, run headless specs.

## Design principles

1. **Human approval before code.** The agent explores and plans freely, and builds only after an explicit `approve`.
2. **Enforce, don't just instruct.** The rules that matter most are backed by hooks that fail closed, and by tests.
3. **Evidence over claims.** Reports say what was run and observed. Anything else is labelled *assumed* or *not checked*.
4. **Detect, don't assume.** Test framework, commands, and dev server come from your repo and CI. `AGENTS.md` overrides anything detected.
5. **Everything is a file.** Each run lives in `.agentic/runs/<RUN-ID>/`, which you can resume, audit, or hand to another tool.
6. **Small verified steps, bounded loops.** When a budget is exhausted, the agent stops and asks.
7. **Graceful degradation.** No MCP? Paste the ticket. No browser? Headless specs. No subagents? Role files.

## Learn more

- **[References](docs/references.md)**: 39 related repositories (official tools, MCP servers, similar agent/skill libraries like awesome-claude-code, wshobson/agents, superpowers, spec-kit, BMAD) plus security standards
- [Engineering review](docs/engineering-review.md): a director-level assessment, findings, residual risks, rollout checklist
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

> **License:** none chosen yet. Add a `LICENSE` file (e.g. MIT or Apache-2.0) before sharing widely; without one, others can't legally reuse these files.
