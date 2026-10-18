# MCP Servers

MCP (Model Context Protocol) servers give the agent tools beyond the shell. The workflow asks for **capabilities**, not products — pick one server per capability that matches your stack.

> ⚠️ Endpoints, package names and auth flows change. The values below were accurate when written; confirm against each vendor's docs. Prefer **official** servers; treat third-party servers like any dependency you'd run with your credentials.

## Capability map

| Capability | Used by | Needed for | Options (official where available) | Without it |
|---|---|---|---|---|
| **Tracker** | `task-intake`, `/ship` | Read tickets, comment, transition | Jira/Confluence: Atlassian Remote MCP · Linear MCP · GitHub Issues (via GitHub MCP) · GitLab · Azure DevOps MCP · Asana / Notion MCPs | Paste ticket text; use CLI (`gh`, `jira`, `az`) |
| **VCS / CI** | `git-workflow`, `ci-guardian`, `/review --post` | Open PRs, read check runs + logs, post reviews | GitHub MCP · GitLab MCP · Azure DevOps MCP · Bitbucket (community) | `gh` / `glab` / `az` CLI |
| **Browser** | `ui-tester` | Drive a real browser, screenshots, console/network | Playwright MCP · Chrome DevTools MCP | Write + run headless E2E specs |
| **Docs / library knowledge** | planner, implementer | Up-to-date framework/library docs | Context7 · vendor doc MCPs | Web search / reading `node_modules` docs |
| **Error tracking** | `debugger`, `/fix-bug` | Stack traces, breadcrumbs, releases | Sentry MCP · other APM vendors' MCPs | Paste the stack trace |
| **Database (local!)** | `api-tester`, debugger | Inspect side effects, query plans | A Postgres/MySQL/SQLite MCP with a **read-only local** user | `psql` / `mysql` / `sqlite3` CLI |
| **Design** | planner, `ui-tester` | Read frames/specs/tokens | Figma MCP (Dev Mode) | Screenshots attached to ticket |
| **Knowledge base** | `task-intake` | Specs, RFCs, runbooks | Confluence (Atlassian MCP) · Notion MCP · Google Drive | Paste / link files |

**Minimum useful set:** Tracker + VCS + Browser. That gets you ticket → plan → code → browser-verified PR.

## Server reference

| Server | Transport | Endpoint / command | Auth |
|---|---|---|---|
| GitHub (remote) | HTTP | `https://api.githubcopilot.com/mcp/` | OAuth (supported clients) or `Authorization: Bearer <PAT>` |
| GitHub (local) | stdio | `docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server` | PAT env var |
| Atlassian (Jira + Confluence) | HTTP/SSE | `https://mcp.atlassian.com/v1/sse` (check docs for the current streamable-HTTP path) | OAuth in browser |
| Linear | HTTP | `https://mcp.linear.app/mcp` | OAuth |
| Azure DevOps | stdio | `npx -y @azure-devops/mcp <your-org>` | Azure login |
| GitLab | HTTP | GitLab's built-in MCP endpoint on recent versions (see GitLab docs), or a community server | OAuth / PAT |
| Playwright | stdio | `npx @playwright/mcp@latest` (add `--headless`, `--isolated`, `--browser chromium` as needed) | – |
| Chrome DevTools | stdio | `npx chrome-devtools-mcp@latest` | – |
| Sentry | HTTP | `https://mcp.sentry.dev/mcp` | OAuth |
| Context7 | stdio / HTTP | `npx -y @upstash/context7-mcp` or `https://mcp.context7.com/mcp` | optional API key |
| Notion | HTTP | `https://mcp.notion.com/mcp` | OAuth |
| Figma | HTTP | Desktop Dev Mode server (local URL shown in Figma) or Figma's remote MCP | Figma login |

Clients that only support stdio can reach remote servers through the `mcp-remote` bridge: `npx -y mcp-remote <url>`.

## Configuration per tool

### Claude Code
CLI (stores in your user config by default; `--scope project` writes a shareable `.mcp.json`):
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer $GITHUB_PAT"
claude mcp add --transport sse  atlassian https://mcp.atlassian.com/v1/sse
claude mcp add --transport http linear    https://mcp.linear.app/mcp
claude mcp add --transport http sentry    https://mcp.sentry.dev/mcp
claude mcp add playwright -- npx @playwright/mcp@latest
claude mcp add context7   -- npx -y @upstash/context7-mcp
claude mcp list            # verify; use /mcp inside a session to complete OAuth
```
Project file `.mcp.json` (commit it; `${VAR}` is expanded from the environment, so no secrets in git):
```json
{
  "mcpServers": {
    "github":     { "type": "http", "url": "https://api.githubcopilot.com/mcp/",
                    "headers": { "Authorization": "Bearer ${GITHUB_PAT}" } },
    "atlassian":  { "type": "sse",  "url": "https://mcp.atlassian.com/v1/sse" },
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] },
    "context7":   { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] }
  }
}
```

### Gemini CLI
`.gemini/settings.json` (project) or `~/.gemini/settings.json` (user):
```json
{
  "mcpServers": {
    "github":     { "httpUrl": "https://api.githubcopilot.com/mcp/",
                    "headers": { "Authorization": "Bearer $GITHUB_PAT" } },
    "atlassian":  { "url": "https://mcp.atlassian.com/v1/sse" },
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] }
  }
}
```
`httpUrl` = streamable HTTP, `url` = SSE, `command`/`args` = stdio. Recent versions also offer `gemini mcp add …`. Check with `/mcp` in a session.

### OpenAI Codex CLI
`~/.codex/config.toml`:
```toml
[mcp_servers.playwright]
command = "npx"
args = ["@playwright/mcp@latest"]

[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp/"
bearer_token_env_var = "GITHUB_PAT"

[mcp_servers.atlassian]
command = "npx"
args = ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"]
```
Recent versions also support `codex mcp add <name> -- <command>`. Remote (`url`) support may need a recent version — fall back to `mcp-remote` if not.

### Cursor
`.cursor/mcp.json` (project) or `~/.cursor/mcp.json` (global):
```json
{
  "mcpServers": {
    "github":     { "url": "https://api.githubcopilot.com/mcp/",
                    "headers": { "Authorization": "Bearer ${env:GITHUB_PAT}" } },
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] }
  }
}
```

### GitHub Copilot (VS Code)
`.vscode/mcp.json` — note the top-level key is `servers`, and `inputs` prompts for secrets:
```json
{
  "inputs": [{ "type": "promptString", "id": "github_pat", "description": "GitHub PAT", "password": true }],
  "servers": {
    "github":     { "type": "http", "url": "https://api.githubcopilot.com/mcp/",
                    "headers": { "Authorization": "Bearer ${input:github_pat}" } },
    "playwright": { "type": "stdio", "command": "npx", "args": ["@playwright/mcp@latest"] }
  }
}
```

## Security checklist for MCP
- **Least privilege tokens.** Fine-grained GitHub PAT scoped to the repos you need (contents, pull requests, issues, actions: read). Jira/Linear OAuth as a user who can't administer projects.
- **Read-only where possible.** Databases: dedicated read-only user, local DB only. Never point a DB MCP at production.
- **Secrets out of git.** Use env-var expansion (`${VAR}`), OS keychains, or the client's secret prompts.
- **Prompt injection is real.** Tickets, PR comments, web pages and logs can contain text that tries to steer the agent. The workflow treats all tool output as data; keep approval gates on, and restrict which tools agents can call without asking (see [safety](safety-and-guardrails.md)).
- **Pin or vet third-party servers.** `@latest` is convenient; pinning a version is safer for teams.
- **Limit tool surface.** Many servers expose dozens of tools. If your client supports tool filtering/toolsets (e.g. GitHub MCP toolsets), enable only what the workflow uses.
