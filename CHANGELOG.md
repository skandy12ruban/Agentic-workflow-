# Changelog

All notable changes to this library. Format: [Keep a Changelog](https://keepachangelog.com/); versioning: [SemVer](https://semver.org/).
A **major** bump means an agent/command output format or a configuration key changed in a breaking way; re-run `install.sh --force` and review your `AGENTS.md`.

## [Unreleased]
### Added
- MIT `LICENSE`.

## [1.1.0] - 2026-10-18
### Added
- `guardrails` skill: always-on rules (risk classes R0–R4, prompt-injection protocol, secrets, test integrity, honesty/evidence rule, kill switch, escalation format).
- Enforced guardrails in `hooks/`: Claude Code `guard-bash.sh` and `guard-files.sh` (fail closed), a hardened `settings.json`, tool-agnostic git `pre-commit` and `pre-push` hooks, the `.agentic/STOP` kill switch, and `.agentic/protected-paths`.
- `scripts/test-guardrails.sh` (150 regression cases) and `scripts/validate.sh`; CI workflow running both plus shellcheck.
- `docs/guardrail-tests.md` (behavioural red-team scenarios), `docs/references.md` (curated related repos and docs), `docs/engineering-review.md`.
- `llms.txt` (AI-readable index) and `INSTALL_WITH_AI.md` (paste-in install prompts).
- `curl | bash` install with no clone; guardrails installed by default (`--no-guardrails` to opt out).
- A "Requires" line on every command and a guardrails/skills/evidence header on every agent, so files can be cherry-picked safely.
### Changed
- `autonomy: autonomous` only takes effect when project memory declares `sandboxed: true`.
- Real repository URLs replace placeholders throughout.

## [1.0.0] - 2026-10-18
### Added
- 12 commands, 11 agents, 13 skills, templates, per-tool setup guides, MCP guide, examples, installer.
