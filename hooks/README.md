# Hooks: enforced guardrails

The [`guardrails` skill](../skills/guardrails/SKILL.md) tells the agent what not to do. The hooks here make sure it **can't**, even if the model is confused, misled, or prompt-injected. All of them are covered by regression tests (`scripts/test-guardrails.sh`, 150 cases, run in CI), and they **fail closed**: if a hook can't parse its input, it blocks.

| File | Runs in | Enforces | Works with |
|---|---|---|---|
| [`claude/guard-bash.sh`](claude/guard-bash.sh) | Claude Code `PreToolUse` (Bash) | Blocks force-push, pushes to protected branches, branch/tag deletion, `--no-verify`, `reset --hard`/`clean -f`, PR merges, dangerous `rm -rf`, `sudo`, `curl \| sh`, infra/cloud/k8s changes, deploys, destructive SQL/DB resets, package publishing, reading `.env`/keys/credential stores, env dumps, uploading secrets, editing guardrail files. Honours the `.agentic/STOP` kill switch. | Claude Code |
| [`claude/guard-files.sh`](claude/guard-files.sh) | Claude Code `PreToolUse` (Read/Edit/Write/MultiEdit/NotebookEdit/Grep/Glob) | Blocks reading/writing secret files, edits to guardrails/git hooks/`.git`, hand-edited lockfiles, project-specific protected paths, and writing content that contains credentials. **Asks** before CI/CD config or CODEOWNERS changes. Honours the kill switch. | Claude Code |
| [`claude/settings.json`](claude/settings.json) | Claude Code | Permission allow/ask/deny lists plus registration of both hooks | Claude Code |
| [`git/pre-commit`](git/pre-commit) | git | No commits on protected branches, no staged secret files, credential scan of added lines (+ gitleaks if installed), no leftover `DEBUG(agent)` markers | **Every tool** + humans |
| [`git/pre-push`](git/pre-push) | git | No pushes to protected branches, no force-pushes (non-fast-forward), no remote branch deletion, no tag pushes | **Every tool** + humans |

## Install (copy-paste)

**Everything, via the installer:**
```bash
~/agentic-workflow/scripts/install.sh --tool claude --with-guardrails
```

**Claude Code by hand:**
```bash
mkdir -p .claude/hooks
cp hooks/claude/guard-bash.sh hooks/claude/guard-files.sh .claude/hooks/ && chmod +x .claude/hooks/*.sh
[ -f .claude/settings.json ] || cp hooks/claude/settings.json .claude/settings.json   # otherwise merge the "hooks" block by hand
```
Restart Claude Code. Running `/hooks` in a session should list both hooks.

**Git hooks (any tool):**
```bash
cp hooks/git/pre-commit hooks/git/pre-push .git/hooks/ && chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```
If you use husky, lefthook, or pre-commit, call the scripts from your existing hooks instead, e.g. in `.husky/pre-push`: `bash path/to/hooks/git/pre-push "$@"` (pre-push reads refs from stdin, so it passes through).

> Git hooks live in `.git/hooks`, which isn't committed. Each developer or agent environment installs them, and the installer does it for you. For cloud agents, add the copy step to your environment setup script.

## Configuration

| Setting | Where | Default |
|---|---|---|
| Protected branches (regex) | env `AGENTIC_PROTECTED_BRANCHES` or `.agentic/guardrails.env` | `main\|master\|develop\|development\|trunk\|stable\|prod\|production\|release/.*\|releases/.*\|hotfix/.*` |
| Protected paths (globs, one per line, `*` spans dirs) | `.agentic/protected-paths` | none — e.g. `src/generated/*`, `infra/*`, `db/migrations/2024*` |
| Kill switch | `touch .agentic/STOP` (remove to resume) | off |
| Human override for one push/commit | `AGENTIC_ALLOW_PROTECTED_PUSH=1 git push …` / `AGENTIC_ALLOW_PROTECTED_COMMIT=1 git commit …` | – (agents are blocked from setting these) |
| Fake secret in a test fixture | add `guardrails:allow-secret` on the same line | – |

Example `.agentic/guardrails.env`:
```bash
AGENTIC_PROTECTED_BRANCHES="main|release/.*|env/.*"
```

## Other tools

| Tool | How to get equivalent enforcement |
|---|---|
| **Any** | Git hooks above, **branch protection** on the remote (required reviews + status checks + no force-push), least-privilege tokens. These cover the highest-impact risks for every tool. |
| Gemini CLI | Keep shell confirmations on, use `--sandbox` for autonomous runs, and restrict tools in `settings.json` (`excludeTools` / `tools.exclude`, including command-specific shell restrictions in recent versions). |
| Codex CLI | Use `workspace-write` sandbox with on-request approvals; network off by default; never "full access + never ask" outside disposable environments. |
| Cursor | Keep auto-run off or use its command allow/deny lists. Recent versions support hooks (e.g. before shell execution), and `guard-bash.sh`'s rules can be ported there. |
| Copilot | Limit terminal auto-approve to safe commands; keep "approve all tools" off; for the cloud coding agent, rely on branch protection plus the `copilot/*` branch model. |

## Known limits (be honest with your team)
- Pattern-based shell guards can be evaded by a determined adversary (e.g. writing a script and then running it). They stop accidents and naive injections. **Sandboxing, scoped credentials, and branch protection** are what contain a hostile agent. Use all the layers in [docs/safety-and-guardrails.md](../docs/safety-and-guardrails.md).
- Hooks run with your user's permissions. Review them like any script you execute.
