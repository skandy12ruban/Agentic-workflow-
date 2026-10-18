# Troubleshooting & FAQ

## Setup

**The command doesn't show up in the `/` menu.**
- Claude Code: file must be in `.claude/commands/` (project) or `~/.claude/commands/` (user), extension `.md`. Restart the session.
- Gemini CLI: `.toml` in `.gemini/commands/`; run `/commands reload` or restart. TOML syntax errors silently drop a command — validate with any TOML parser.
- Codex: files in `~/.codex/prompts/`; invoke as `/prompts:<name>`. Restart Codex after adding.
- Copilot: `.github/prompts/<name>.prompt.md`; prompt files must be enabled in VS Code settings for older versions.
- Cursor: `.cursor/commands/<name>.md`; reload the window.

**Subagents never get used.**
Make the `description` say *when* to use it ("Use PROACTIVELY after …"). Or name it explicitly: "Use the code-reviewer agent to review this." In tools without subagents, check that the *Agentic workflow library* section is in your memory file.

**Skills don't load.**
The `description` is the trigger — make it match how you phrase requests. Folder name must equal the `name` field. Check your tool version actually supports skills; otherwise use the `.agentic/skills` + memory-file pointer approach.

**MCP server shows as failed.**
Run the server command by hand (`npx @playwright/mcp@latest`) to see the real error. Common causes: Node version too old, proxy/firewall, OAuth not completed (Claude Code: `/mcp`), token missing from the environment, wrong transport type (`http` vs `sse`).

## During runs

**The agent started coding before I approved.**
Your memory file or tool settings may contain "act autonomously" style instructions that conflict. Search for them. Confirm `autonomy: supervised`. In Claude Code, plan mode also prevents edits. Report the exact transcript point — the gate wording in `approval-gate` is strict on purpose.

**It's looping on a failing test.**
Loop budgets should stop it at 3. If they don't, check `state.md` is being updated (the counter lives there). Tell it: "Stop. Apply the systematic-debugging skill and give me a debug report."

**It picked the wrong test framework / command.**
Put the right command in `AGENTS.md` → Commands. Explicit configuration always beats detection.

**UI testing says no browser tools are available.**
Install Playwright MCP or Chrome DevTools MCP (see [MCP servers](mcp-servers.md)). Without one, `ui-tester` falls back to writing and running headless E2E specs. On Linux CI/containers, Playwright may need system deps: `npx playwright install --with-deps chromium`.

**The dev server never becomes ready.**
Set `ui.start_command` and `ui.base_url` explicitly. Check `artifacts/dev-server.log`. Common: missing env vars (copy `.env.example`), port in use, DB not running.

**API tests can't authenticate.**
Document a local auth path in `AGENTS.md` (seed user + login endpoint, or a token helper script). The agent will not invent credentials or use production ones.

**Context gets too long on big tasks.**
That's what subagents and `state.md` are for. Split L-size tickets (the planner suggests this). In Claude Code, `/compact` between phases; then `/resume <RUN-ID>` if needed — the state file has everything.

**Remote CI fails but local passes.**
See "Works locally, fails in CI" in the `systematic-debugging` skill: versions, TZ, env vars, services, parallelism, caches.

## FAQ

**Do I need all the MCP servers?** No. Tracker + VCS + Browser is the sweet spot. Everything degrades gracefully: paste tickets, use `gh`, run headless specs.

**Can I use different tools on the same run?** Yes. Plan in one tool, `/resume` in another — the run directory is plain markdown.

**Will it work on Windows?** The markdown works everywhere. `install.sh` needs bash (Git Bash or WSL). Agents will run whatever shell your tool uses; put Windows-specific commands in `AGENTS.md`.

**Can it run fully unattended (e.g. on every new ticket)?** Technically yes (headless mode + `autonomous`), but keep the headless approval gate (post plan → wait for `/approve`) unless the environment is sandboxed and the tickets are trusted. See [safety](safety-and-guardrails.md).

**How do I measure whether this is helping?** Track per run: time from ticket to PR, review iterations, CI failures after PR, and defects found later. `state.md` logs make the first three easy to extract.

**Which model should I use?** Your tool's strongest model for planning and review; faster models are fine for exploration and mechanical fixes. Set `model:` per agent.
