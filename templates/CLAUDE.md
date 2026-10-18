# CLAUDE.md

<!--
  Option A (recommended for multi-tool teams): keep AGENTS.md as the single source of truth
  and import it here. Claude Code expands @path imports in CLAUDE.md.
-->
@AGENTS.md

<!--
  Option B (Claude-only teams): delete the import above and paste the contents of
  templates/AGENTS.md here instead.

  Claude-specific notes (optional) go below. Keep them few — anything tool-agnostic belongs in AGENTS.md.
-->

## Claude Code specifics
- Subagents live in `.claude/agents/`, commands in `.claude/commands/`, skills in `.claude/skills/` — the "Agents/Skills" paths listed in AGENTS.md under `.agentic/` don't apply to Claude Code.
- Prefer delegating review to the `code-reviewer` and `security-auditor` subagents so reviews run in a fresh context.
- Personal, uncommitted preferences go in `CLAUDE.local.md` (gitignored).
