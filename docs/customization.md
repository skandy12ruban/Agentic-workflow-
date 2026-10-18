# Customization

The library is designed so **you rarely edit the library files themselves**. Put repo-specific knowledge in project memory; put team-specific procedures in new skills; keep agents and commands upgradeable.

## Where should my change go?

| I want to… | Change | Not |
|---|---|---|
| Tell agents our test command / base branch / tracker | `AGENTS.md` → Commands / Workflow Configuration | agent files |
| Enforce a convention ("use `Money` type, never floats") | `AGENTS.md` → Conventions (one line) | – |
| Add our deploy/migration/release procedure | New skill `skills/<our-procedure>/SKILL.md` | `task.md` |
| Add a phase (e.g. performance budget, i18n check, license scan) | New agent + one step in `task.md` | – |
| Change how strict review is | `skills/code-review/SKILL.md` checklist; severities | `code-reviewer.md` method |
| Skip E2E for some paths | `classification_overrides` in Workflow Configuration | command logic |
| Make the agent stop asking for approval on tiny tickets | `autonomy: autonomous` + `auto_approve` criteria — sandboxed environments only | removing the gate from `task.md` |
| Use a cheaper model for exploration | `model:` in `codebase-explorer.md` frontmatter | – |

## Recipes

### Add a new phase: performance budget
1. Create `agents/perf-auditor.md` (copy `code-reviewer.md`; method: run Lighthouse via Chrome DevTools MCP or `npx lighthouse`, bundle analyzer, query `EXPLAIN` for new queries; output a table vs budgets).
2. In `commands/task.md`, Phase 8: "If classification is frontend, also delegate to `perf-auditor`; regressions over budget are blocking."
3. Put the budgets in `AGENTS.md` (`perf: { lcp_ms: 2500, bundle_kb: 250 }`).

### Add a team skill: "our-release-notes"
```markdown
---
name: release-notes
description: Write customer-facing release notes in Acme's format from merged PRs. Use when asked for release notes, changelog for customers, or "what shipped".
---
# Release notes (Acme)
1. Collect merged PRs since the last tag via the GitHub MCP …
2. Group by product area using labels `area:*` …
3. Voice: second person, benefit first, no ticket numbers …
```

### Different tracker conventions
`task-intake` handles any tracker, but if your acceptance criteria live in a custom Jira field, say so in `AGENTS.md`:
```yaml
tracker: { type: jira, project_key: PAY, ac_field: "customfield_10042", definition_of_done: "docs/dod.md" }
```

### Monorepo
- Nested memory files: `apps/web/AGENTS.md`, `services/billing/AGENTS.md` with package-specific commands.
- `classification_overrides` mapping package globs to frontend/backend.
- In `ci-verification`, the agent runs only affected packages via your orchestrator (`turbo --filter=...[origin/main]`, `nx affected -t test`, `bazel test` with target selection) — add the exact command to `AGENTS.md`.

### Regulated environments
- `autonomy: supervised` permanently; add a gate before *every* commit if needed ("Ask before each commit" in Boundaries).
- Commit `plan.md` and `review.md` into the PR (or attach) for audit trails.
- Restrict MCP tools to read-only scopes; route PR creation through humans (`--no-pr`).

## Package as a Claude Code plugin
To distribute your customized library across many repos, build a plugin directory (outside this repo's root, so the `README.md` files in `agents/` and `commands/` don't get loaded as an agent and a command):

```bash
scripts/install.sh --tool claude --target /tmp/plugin-build --only agents,commands,skills
mkdir -p my-plugin/.claude-plugin
mv /tmp/plugin-build/.claude/{agents,commands,skills} my-plugin/
cat > my-plugin/.claude-plugin/plugin.json <<'EOF'
{ "name": "acme-agentic-workflow", "version": "1.0.0",
  "description": "Ticket-to-PR agentic workflow: agents, commands, skills" }
EOF
```
Publish `my-plugin` in a git repo with a `.claude-plugin/marketplace.json` listing it, then teammates run `/plugin marketplace add <org>/<repo>` and `/plugin install`. Plugins can also bundle MCP server config (`.mcp.json`) and hooks. Check the Claude Code plugin docs for the current manifest schema.

Equivalent distribution options elsewhere: Gemini CLI **extensions**, a shared `~/.codex/prompts` dotfiles repo, or a git submodule at `.agentic/`.

## Keeping up to date
- Vendor the library as a **git submodule** or **subtree** at `.agentic/lib`, and re-run `install.sh --force` after pulling — your repo-specific knowledge lives in `AGENTS.md`, so overwriting library files is safe.
- If you did edit library files, keep a `CUSTOMIZATIONS.md` listing what and why, so upgrades are a quick diff.
