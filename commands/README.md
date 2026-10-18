# Commands

Commands are the entry points a human types. `/task` runs the whole pipeline; every other command is one phase you can run on its own — useful when you want to stay hands-on, or when adopting the workflow gradually.

| Command | What it does | Gates | Typical use |
|---|---|---|---|
| [`/task <ticket>`](task.md) | **Full pipeline**: intake → plan → ⛔ approve → implement → test → CI → review → E2E → PR → report | Plan (+ push in supervised mode) | "Here's a ticket, take it to a PR" |
| [`/plan <ticket>`](plan.md) | Intake + explore + plan, stop at approval | Plan | Want to see the approach first |
| [`/implement <run>`](implement.md) | Execute an approved plan | Requires prior approval | After `/plan` |
| [`/test [target]`](test.md) | Generate + run tests in the project's framework | – | Add tests to anything |
| [`/ci-check [--remote]`](ci-check.md) | Run CI gate locally; fix; check remote CI | – | Before pushing; when CI is red |
| [`/review [target]`](review.md) | Code + security review; `--fix` / `--post` | Before posting | Self-review or review a teammate's PR |
| [`/ui-test [target]`](ui-test.md) | Browser verification via MCP; E2E specs | – | Frontend changes |
| [`/api-test [target]`](api-test.md) | Endpoint verification; integration tests | – | Backend changes |
| [`/ship [run]`](ship.md) | Push + PR + ticket link + watch CI | Push (supervised) | Deliver finished work |
| [`/fix-bug <report>`](fix-bug.md) | Reproduce → root cause → ⛔ approve → fix → verify | Fix | Bugs, Sentry errors, failing tests |
| [`/resume [run]`](resume.md) | Continue a paused/interrupted run | Re-presents pending gates | After approval, new session, other tool |
| [`/setup-project`](setup-project.md) | Detect stack/CI/MCPs; write project memory | Before overwriting | **Run once per repo, first** |

## Typical flows

```text
# First time in a repo
/setup-project

# Hands-off (you only approve the plan)
/task PROJ-123

# Hands-on, phase by phase
/plan PROJ-123          → approve
/implement PROJ-123
/test PROJ-123
/ci-check PROJ-123
/review PROJ-123 --fix
/ui-test PROJ-123       (or /api-test)
/ship PROJ-123

# Bugs
/fix-bug https://sentry.io/organizations/acme/issues/12345/
/fix-bug "TypeError: cannot read 'id' of undefined at OrderList.tsx:42"

# Utilities on any branch, no ticket
/review 482 --post      # review PR #482 and post comments (asks first)
/test src/billing/      # characterization tests for existing code
/ci-check --remote      # fix the red build on my PR
```

## Install

**Claude Code** — copy as-is (filename = command name):
```bash
mkdir -p .claude/commands && cp commands/*.md .claude/commands/ && rm .claude/commands/README.md
```
Invoke with `/task PROJ-123`. User-level install (`~/.claude/commands/`) makes them available in every repo.

**Gemini CLI** — commands are TOML. `scripts/install.sh --tool gemini` converts them, or by hand:
```toml
# .gemini/commands/task.toml
description = "End-to-end agentic workflow ..."
prompt = """
<paste the markdown body of commands/task.md here, replacing $ARGUMENTS with {{args}}>
"""
```

**Codex CLI** — copy to `~/.codex/prompts/` and invoke as `/prompts:task PROJ-123` (`$ARGUMENTS` is supported).

**Cursor** — copy to `.cursor/commands/` (markdown; arguments are appended to the prompt).

**GitHub Copilot (VS Code)** — rename to `.github/prompts/task.prompt.md`, set frontmatter `agent: agent` (older versions: `mode: agent`); invoke `/task PROJ-123` in Chat. Replace `$ARGUMENTS` with `${input:args}`.

**Anything else** — paste the body as a prompt, replacing `$ARGUMENTS` with your input.

See [`docs/setup/`](../docs/setup/) for complete per-tool guides.

## Frontmatter reference (Claude Code)

```yaml
---
description: Shown in the / menu; also helps the model pick the command.
argument-hint: '<TICKET> [--flag]'   # shown as a placeholder after the command name (quote it: a leading [ is YAML list syntax)
allowed-tools: Bash(git status:*), Read   # optional: tools pre-approved while this command runs
model: <model-id>                         # optional: force a model for this command
---
```
Inside the body: `$ARGUMENTS` (everything after the command), `$1`, `$2`… (positional), `@path/to/file` (inline a file), and `` !`cmd` `` (inline a shell command's output, requires that command to be in `allowed-tools`).

## Writing your own command

Keep commands thin: **what** to do and in what order, delegating the **how** to agents and skills. A good command reads like a runbook: numbered phases, each with an exit criterion, and explicit gates.
