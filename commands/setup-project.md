---
description: One-time project onboarding - detect the stack and CI, check which MCP servers are available, and generate the project memory file (CLAUDE.md / AGENTS.md / GEMINI.md) with a Workflow Configuration section the other commands rely on.
argument-hint: '[--file CLAUDE.md|AGENTS.md|GEMINI.md] [--monorepo]'
---

# /setup-project — Prepare this repo for the agentic workflow

**Input:** $ARGUMENTS

> **Requires** — agents: docs-writer (optional) · skills: guardrails, stack-detection, ci-verification · MCP: none.
> Missing a file? Do that step yourself from the description here and say which file was missing. **Guardrails:** follow the `guardrails` skill throughout; stop if `.agentic/STOP` exists.

Goal: produce (or update) the project memory file so every other command works with zero guessing. **Ask before overwriting** an existing memory file — prefer merging a new `## Workflow Configuration` section into it.

1. **Pick the file:** `--file` if given; else the one that already exists; else ask which tool(s) the team uses:
   - Claude Code → `CLAUDE.md` · Gemini CLI → `GEMINI.md` · Codex, Cursor, Copilot, others → `AGENTS.md`.
   - Multiple tools → write `AGENTS.md` as the source of truth and make `CLAUDE.md` / `GEMINI.md` one-liners that import or reference it (e.g. `CLAUDE.md` containing `@AGENTS.md`; Gemini can be configured to read `AGENTS.md` directly).
2. **Detect** with the `stack-detection` skill (per package for monorepos) and the `ci-verification` skill (extract the CI gate). **Verify** each command actually runs (`--version`, list tests, quick lint on one file). Mark unverified ones.
3. **Detect conventions:** base branch, branch naming and commit style (from `git log`/branches/commitlint), PR template, CODEOWNERS, test file layout, protected/generated paths (codegen outputs, vendored code, migrations already applied, lockfiles).
4. **Check MCP availability:** list the tools you have. Classify into capabilities: tracker, VCS, browser, error-tracker, docs, DB, design. Note missing ones with the recommendation from the guide (don't install anything yourself).
5. **Ask the human** only for what can't be detected (batch the questions): tracker + project key, autonomy level, UI base URL/test user, API base URL/test auth, environments that are safe for E2E, auto-approve criteria (if `autonomous`).
6. **Write** the file using the `AGENTS.md` template from this library (installed at `.agentic/templates/AGENTS.md`; if the template isn't available, use the sections: Project overview, Commands, Conventions, Architecture map, Testing, Workflow Configuration, Boundaries). Keep it concise — every line should change agent behaviour.
7. **Add** `.agentic/runs/` to `.gitignore` (ask first).
8. **Report:** what was detected, what was asked, which MCP capabilities are missing, and the next step: `/plan <ticket>` or `/task <ticket>`.
