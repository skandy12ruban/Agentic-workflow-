# Install with your AI tool

Don't want to run the script yourself? Open your AI coding tool **in your project folder** and paste one of the prompts below. It installs the library, adapts it to your stack, and stops for your confirmation before changing anything that already exists.

## Prompt: full install

```text
Install the agentic workflow library from https://github.com/skandy12ruban/Agentic-workflow- into this project.

1. Identify which AI coding tool you are (Claude Code, Gemini CLI, Codex CLI, Cursor, GitHub Copilot, or other)
   and tell me. If unsure, ask me.
2. Clone the library to ~/.agentic-workflow (or update it if it already exists). Read its llms.txt and README.md first.
3. Show me what you will create or change (the output of `~/.agentic-workflow/scripts/install.sh --tool <tool> --dry-run`)
   and wait for my "go".
4. Run the installer with --tool <tool> --target . (keep the default guardrails). Do NOT use --force unless I say so.
   For every file it skipped because it already exists, tell me and propose a merge instead of overwriting.
5. Append templates/gitignore-snippet.txt to .gitignore if those lines aren't already there.
6. Run the setup-project command (/setup-project, /prompts:setup-project, or follow .agentic/commands/setup-project.md)
   to generate AGENTS.md for this repo. Ask me only what you can't detect.
7. Tell me which MCP servers I still need to connect (tracker, VCS, browser) with the exact config for this tool,
   from docs/mcp-servers.md. Do not add MCP servers or credentials yourself.
8. Finish with a summary: files created, files skipped, guardrails active (hooks, git hooks), and the first command to try.

Follow skills/guardrails/SKILL.md from the library throughout: no pushes, no secrets, no changes outside this project
except ~/.agentic-workflow (and ~/.codex/prompts for Codex).
```

## Prompt: just one piece

```text
From https://github.com/skandy12ruban/Agentic-workflow- install only the <code-reviewer agent + review command> for the AI tool you are,
including the skills they list under "Requires"/"Skills used". Show me the target paths first and wait for my OK.
Don't overwrite existing files.
```

## Prompt: verify my setup

```text
Using the agentic workflow library installed in this project, verify my setup:
1. List the commands, agents, and skills you can see and where they are installed.
2. List the MCP tools available to you, grouped by capability (tracker, VCS, browser, other).
3. Check that the guardrails are active. For Claude Code, run ~/.agentic-workflow/scripts/test-guardrails.sh
   and confirm the hooks are registered in .claude/settings.json. For any tool, confirm .git/hooks/pre-push exists.
4. Read AGENTS.md (or CLAUDE.md/GEMINI.md) and tell me the test, lint, and build commands you would use.
Report anything missing, with the exact fix.
```
