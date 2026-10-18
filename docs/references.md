# References & Further Reading

Curated repositories and docs for going deeper. Every **GitHub repository** link was checked to resolve when this page was written (October 2026). Documentation links point to each project's canonical site. Projects move, so star the ones you rely on and check their READMEs for current usage.

## Official tools & docs

| Resource | What you'll learn |
|---|---|
| [anthropics/claude-code](https://github.com/anthropics/claude-code) · [docs](https://code.claude.com/docs/en/overview) | Claude Code itself: subagents, slash commands, skills, hooks, MCP, settings, plugins |
| [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) | Running Claude Code in GitHub Actions from issue/PR comments |
| [anthropics/skills](https://github.com/anthropics/skills) | Anthropic's example Agent Skills and the `SKILL.md` format |
| [anthropics/claude-cookbooks](https://github.com/anthropics/claude-cookbooks) | Patterns for agents, tool use, and evaluation |
| [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) | Gemini CLI: `GEMINI.md`, TOML commands, MCP, extensions, sandboxing |
| [openai/codex](https://github.com/openai/codex) | Codex CLI: `AGENTS.md`, custom prompts, `config.toml`, sandbox and approvals |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | Community prompt files, instructions, and custom agents for GitHub Copilot |
| [agentsmd/agents.md](https://github.com/agentsmd/agents.md) · [agents.md](https://agents.md) | The cross-tool `AGENTS.md` convention |

## Model Context Protocol (MCP)

| Resource | What you'll learn |
|---|---|
| [modelcontextprotocol/modelcontextprotocol](https://github.com/modelcontextprotocol/modelcontextprotocol) · [modelcontextprotocol.io](https://modelcontextprotocol.io) | The protocol spec, transports, auth, security best practices |
| [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) | Reference servers, plus a directory of official third-party servers |
| [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) | A large community catalogue of MCP servers by category |
| [github/github-mcp-server](https://github.com/github/github-mcp-server) | GitHub MCP: toolsets, remote vs local, read-only mode |
| [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) | Browser automation via accessibility snapshots, used by `ui-tester` |
| [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | DevTools-level debugging, network, and performance traces |
| [atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server) | Jira and Confluence remote MCP |
| [microsoft/azure-devops-mcp](https://github.com/microsoft/azure-devops-mcp) | Azure Boards, Repos, Pipelines |
| [getsentry/sentry-mcp](https://github.com/getsentry/sentry-mcp) | Error-tracker context for `/fix-bug` |
| [upstash/context7](https://github.com/upstash/context7) | Up-to-date library docs injected into context |

## Similar libraries: agents, commands, skills, workflows

Compare approaches, borrow ideas, mix and match.

| Repository | Approach | Good for |
|---|---|---|
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | Curated list of commands, workflows, hooks, and tooling | Discovering what others built |
| [wshobson/agents](https://github.com/wshobson/agents) | Large collection of specialized subagents and plugins | Domain-specific roles (languages, infra, data) |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | Categorized subagent catalogue | More specialist personas |
| [obra/superpowers](https://github.com/obra/superpowers) | Skills library emphasising TDD, systematic debugging, planning discipline | Rigorous engineering habits as skills |
| [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) | Curated list of Agent Skills | Finding skills to add |
| [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates) | CLI to install agents, commands, MCPs, and settings templates | Installer-driven setups |
| [SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) | Opinionated framework of commands, personas, and modes | A batteries-included alternative |
| [github/spec-kit](https://github.com/github/spec-kit) | Spec-driven development: specify → plan → tasks → implement, multi-tool | Heavier upfront specs for larger features |
| [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | Agile multi-agent method (analyst, PM, architect, dev, QA) | Product-to-code planning at team scale |
| [PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | Cursor rules for many stacks | Stack-specific conventions to paste into memory files |

How this repo differs: it focuses on a **single, end-to-end, ticket-to-PR pipeline** with strict approval gates, **tested, mechanically enforced guardrails**, framework detection instead of per-stack variants, and the same files working across Claude, Gemini, Codex, Cursor, and Copilot.

## Other open-source agentic coding tools

[Aider-AI/aider](https://github.com/Aider-AI/aider) · [cline/cline](https://github.com/cline/cline) · [continuedev/continue](https://github.com/continuedev/continue) · [block/goose](https://github.com/block/goose) · [sst/opencode](https://github.com/sst/opencode). All support project instructions and (most) MCP. See [setup/other-tools.md](setup/other-tools.md).

## Security & guardrails

| Resource | Why |
|---|---|
| [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) ([repo](https://github.com/OWASP/www-project-top-10-for-large-language-model-applications)) | Prompt injection, excessive agency, insecure output handling, and the core agent risks |
| [OWASP Top 10 (web)](https://owasp.org/www-project-top-ten/) · [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) | The basis of the `security-review` skill |
| [MCP specification](https://modelcontextprotocol.io/specification) (see *Security Best Practices*) | Token handling, confused deputy, and session risks for MCP |
| [gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) · [trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog) · [Yelp/detect-secrets](https://github.com/Yelp/detect-secrets) | Secret scanning (`pre-commit` hook uses gitleaks if installed) |
| [google/osv-scanner](https://github.com/google/osv-scanner) | Dependency vulnerability scanning across ecosystems |
| [nektos/act](https://github.com/nektos/act) | Run GitHub Actions locally (used optionally by `ci-verification`) |

## Engineering practices behind the workflow

- [Conventional Commits](https://www.conventionalcommits.org/) and [Keep a Changelog](https://keepachangelog.com/): commit and changelog conventions used by `git-workflow` and `docs-writer`
- [Testing Library guiding principles](https://testing-library.com/docs/guiding-principles): query by role/label, test behaviour not implementation
- [Playwright best practices](https://playwright.dev/docs/best-practices): locators, web-first assertions, isolation
- [Google engineering practices: code review](https://google.github.io/eng-practices/review/): the reviewer mindset behind `code-review`
- [Architecture Decision Records](https://adr.github.io/): used by `docs-writer` for significant decisions

Know a resource that belongs here? See [CONTRIBUTING.md](../CONTRIBUTING.md). Add it to the right table with a one-line "what you'll learn".
