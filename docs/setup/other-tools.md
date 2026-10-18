# Setup: Any Other Tool

Windsurf, Cline, Roo Code, Kilo Code, Continue, Aider, Amp, Zed, Goose, OpenCode, JetBrains AI/Junie, Amazon Q Developer, Kiro, or something released last week — the pattern is the same.

## The universal recipe

1. **Memory:** put `templates/AGENTS.md` at the repo root as `AGENTS.md` (widely supported), or as whatever file your tool loads automatically:

   | Tool | Memory / rules location (verify for your version) |
   |---|---|
   | Windsurf | `.windsurf/rules/*.md`, `AGENTS.md` |
   | Cline | `.clinerules` / `.clinerules/*.md` |
   | Roo Code / Kilo Code | `.roo/rules/`, `.kilocode/rules/`, custom modes |
   | Continue | `.continue/rules/*.md` |
   | Aider | `CONVENTIONS.md` loaded via `--read` or `.aider.conf.yml` `read:` |
   | Amazon Q Developer | `.amazonq/rules/*.md` |
   | Kiro | `.kiro/steering/*.md` |
   | JetBrains Junie | `.junie/guidelines.md` |
   | Zed | `.rules`, `AGENTS.md` |
   | Goose / OpenCode / Amp | `AGENTS.md` (also `.goosehints`) |

2. **Library:** copy `agents/`, `skills/`, `templates/` to `.agentic/`. Keep the *Agentic workflow library* section of `AGENTS.md`, which tells the agent where they live and how to use them.

3. **Commands:** use the tool's prompt/workflow feature if it has one (e.g. Windsurf workflows `.windsurf/workflows/*.md`, Cline workflows, Continue prompts, Roo custom modes, Kiro specs/hooks). Paste the command body; replace `$ARGUMENTS` with the tool's placeholder or just with your input.
   No command feature? Save them in `.agentic/commands/` and say:
   > Follow `.agentic/commands/task.md` with input: PROJ-123

4. **MCP:** nearly every agentic tool supports MCP now. Translate the JSON from [MCP servers](../mcp-servers.md) into your tool's config. The shape is almost always `{ name: { command, args, env } }` for stdio and `{ name: { url, headers } }` for remote.

5. **Roles without subagents:** commands say "delegate to `X`". Tell your tool in memory:
   > When asked to delegate to an agent, read `.agentic/agents/<name>.md` and perform that role as a separate, focused step; write its output to the run directory before continuing.

   Tools with custom modes/personas (Roo, Kilo, Continue, Copilot custom agents) can import each agent file as a mode for a cleaner separation.

## No agent tool at all? (plain chat)
The files are still useful as prompts:
- Paste `agents/code-reviewer.md` body + your diff → structured review.
- Paste `skills/planning/SKILL.md` + `plan-template.md` + your ticket → a solid plan.
- Paste `skills/test-generation/SKILL.md` + a source file + one existing test → tests in your style.

## Checklist to confirm it works
- [ ] Ask "What are this repo's test and lint commands?" → it answers from `AGENTS.md`.
- [ ] Ask "Which agents and skills are available?" → it lists the library.
- [ ] Run the plan command on a small ticket → it stops at the approval gate without editing code.
- [ ] MCP tools are listed by the tool (tracker, VCS, browser).
