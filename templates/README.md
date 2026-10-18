# Templates

| File | Copy to | Purpose |
|---|---|---|
| [`AGENTS.md`](AGENTS.md) | repo root as `AGENTS.md` | **Project memory** — commands, conventions, architecture, boundaries, and the `Workflow Configuration` block every command reads. Source of truth for multi-tool teams. |
| [`CLAUDE.md`](CLAUDE.md) | repo root | Claude Code memory; imports `AGENTS.md` via `@AGENTS.md`. |
| [`GEMINI.md`](GEMINI.md) | repo root | Gemini CLI memory; imports `AGENTS.md`. |
| [`pull_request_template.md`](pull_request_template.md) | `.github/` (or GitLab/Azure equivalent) | PR structure agents fill from run artifacts — also good for humans. |
| [`gitignore-snippet.txt`](gitignore-snippet.txt) | append to `.gitignore` | Keep run scratch files out of git. |

Run-time templates (plan, state) live inside their skills so they travel with them:
[`skills/planning/plan-template.md`](../skills/planning/plan-template.md) · [`skills/workflow-state/state-template.md`](../skills/workflow-state/state-template.md).

## Writing good project memory

- **Be specific and verifiable.** "Run `pnpm test`" beats "make sure tests pass". "Use `assertOwns()` in services" beats "check permissions".
- **Prefer pointers over prose.** Link `docs/architecture.md` instead of pasting it — the agent can read it when needed, and you avoid paying for it in every session.
- **Encode the things that bit you.** Every time an agent makes the same mistake twice, add one line here.
- **Keep it under ~200 lines.** Long memory files dilute attention. Move rarely-needed detail into skills.
- **Nest for monorepos.** Most tools also load memory files in subdirectories (`apps/web/AGENTS.md`) when working there — use that for package-specific commands and conventions.
