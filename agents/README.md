# Agents

Specialist roles the orchestrator (`/task`) delegates to. Each runs best in its own context window with a focused tool set, so a long implementation session doesn't drown the reviewer in noise — and the reviewer genuinely hasn't "seen" the code being written.

| Agent | Role | Edits code? | Typical tools | Used in phase |
|---|---|---|---|---|
| [`codebase-explorer`](codebase-explorer.md) | Maps relevant code, precedents, tests, landmines | No | Read, Grep, Glob, read-only shell | 2 Discover |
| [`planner`](planner.md) | Writes the implementation plan | Plan file only | Read, Grep, Glob, Write | 3 Plan |
| [`implementer`](implementer.md) | Executes the approved plan step by step | Yes | All | 5 Implement |
| [`test-engineer`](test-engineer.md) | Writes + runs tests in the project's framework | Tests (+ trivial fixes) | All | 6 Test |
| [`ci-guardian`](ci-guardian.md) | Runs the local CI gate; fixes red builds; reads remote CI | Yes (fixes) | All + VCS MCP | 7 CI, 10 Deliver |
| [`code-reviewer`](code-reviewer.md) | Independent correctness/design review | No | Read, Grep, Glob, Bash | 8 Review |
| [`security-auditor`](security-auditor.md) | Security review of the diff + deps + secrets | No | Read, Grep, Glob, Bash | 8 Review |
| [`ui-tester`](ui-tester.md) | Verifies frontend in a real browser via MCP | E2E specs only | All + browser MCP | 9 E2E |
| [`api-tester`](api-tester.md) | Exercises endpoints, codifies API tests | API tests only | All (+ HTTP/DB MCP) | 9 E2E |
| [`debugger`](debugger.md) | Reproduce → isolate → root-cause fix | Yes | All (+ error-tracker MCP) | `/fix-bug`, escalations |
| [`docs-writer`](docs-writer.md) | Updates docs/CHANGELOG/ADRs | Docs only | Read, Write, Edit | 10 Deliver, `/setup-project` |

## Install

**Claude Code** — copy as-is:
```bash
mkdir -p .claude/agents && cp agents/*.md .claude/agents/   # project-level (commit it for your team)
# or user-level, for all projects:
mkdir -p ~/.claude/agents && cp agents/*.md ~/.claude/agents/
rm .claude/agents/README.md ~/.claude/agents/README.md 2>/dev/null
```

**Other tools** — see the per-tool guide in [`docs/setup/`](../docs/setup/). Short version: copy them to `.agentic/agents/` and the commands will read them as role prompts when native subagents aren't available. GitHub Copilot users can rename to `.github/agents/<name>.agent.md`.

## Frontmatter reference (Claude Code)

```yaml
---
name: code-reviewer          # unique id, lowercase-hyphenated
description: ...             # WHEN to use it. The main agent reads this to decide delegation. "Use PROACTIVELY" encourages auto-delegation.
tools: Read, Grep, Glob, Bash  # optional allow-list. Omit to inherit ALL tools, including MCP tools.
model: inherit               # inherit | sonnet | opus | haiku (or a full model id)
---
```

**Tool design choices made here:**
- Read-only agents (`codebase-explorer`, `code-reviewer`, `security-auditor`) have an explicit allow-list so they *can't* edit, which makes their independence real rather than requested.
- Agents that need MCP tools (`ui-tester`, `api-tester`, `ci-guardian`, `debugger`) omit `tools:` so they inherit your configured MCP servers. If you prefer explicit lists, add MCP tool names such as `mcp__playwright__browser_navigate` (Claude Code naming: `mcp__<server>__<tool>`).

## Customizing

- **Model per role:** reviewers and planners benefit most from your strongest model; explorers can use a faster/cheaper one. Change `model:`.
- **Team conventions:** don't edit the agent bodies for repo-specific rules — put those in project memory (`CLAUDE.md`/`AGENTS.md`). Agents read it. This keeps the agents upgradeable.
- **New role?** Copy the closest agent, change `name`, `description`, tools, and the method. Keep the "Output" section — the orchestrator depends on predictable outputs.
