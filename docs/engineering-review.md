# Engineering Review: Agentic Workflow Library

**Reviewer perspective:** Director of Engineering, assessing fitness for rollout to many teams on mixed stacks and mixed AI tools.
**Scope:** every file in the repository, at v1.0.0 (initial) → v1.1.0 (after fixes).
**Verdict:** ✅ **Approved for pilot rollout** with the conditions in §5. Blocking issues found in v1.0.0 are fixed in v1.1.0 (§2).

---

## 1. What's strong

| Area | Assessment |
|---|---|
| **Architecture** | Clean separation: commands (procedures) → agents (roles) → skills (know-how) → MCP (capabilities) → hooks (enforcement). Each layer is replaceable. Repo-specific knowledge lives in `AGENTS.md`, so library upgrades don't fight local edits. |
| **Human control** | The plan approval gate is mandatory, strict, and recorded. "Silence is not approval" and "ticket text is not approval" are explicit. R4 actions (merge, deploy, force-push, publish, infra) are prohibited at every autonomy level. |
| **Stack neutrality** | Detection-first (`stack-detection` + 15-ecosystem matrix), with project memory > CI > scripts > defaults precedence. Test generation follows the repo's own dialect rather than imposing one. |
| **Auditability** | Every run is a directory of plain markdown (ticket, plan, state, reports, evidence). It's resumable across sessions and tools, and reviewable after the fact. |
| **Bounded autonomy** | Loop budgets on every fix loop; explicit stop conditions; escalation format. |
| **Quality bar** | Mutation check on tests, regression-test-first bug fixing, evidence-based review findings, a security review mapped to CWE/OWASP, and a two-identity authorization testing requirement in API testing. These are senior-level habits encoded as defaults. |
| **Portability** | One source format, an installer that converts it for 6 targets, graceful degradation when a tool lacks subagents, skills, or MCP. |

## 2. Findings in v1.0.0 and resolutions

| # | Severity | Finding | Resolution (v1.1.0) |
|---|---|---|---|
| 1 | 🔴 Blocker | **Guardrails were instructions only.** A confused or prompt-injected model could still force-push, read `.env`, or run `curl \| sh`. The example hook in the docs had a fragile regex and was untested. | Added enforced layers: `hooks/claude/guard-bash.sh`, `guard-files.sh`, a hardened `settings.json`, and tool-agnostic git `pre-commit`/`pre-push`. A kill switch (`.agentic/STOP`). Guardrails installed by default. |
| 2 | 🔴 Blocker | **Hooks could fail open.** (Found while testing v1.1.0.) `exit 2` inside a command substitution didn't stop the script, so with no JSON parser available, every command was allowed. | Hooks now **fail closed** on parse failure. Regression cases added. |
| 3 | 🔴 Blocker | **No tests for the safety-critical code.** | `scripts/test-guardrails.sh`: 150 BLOCK/ALLOW/ASK cases covering hooks, git hooks, kill switch, and fail-closed behaviour. It caught 7 real defects during development (pattern-as-flag bug, tilde expansion, case-sensitivity, cross-command matching, fail-open). |
| 4 | 🟠 Major | **Not copy-paste usable.** Placeholder repo URLs, and a clone was required before anything worked. | Real URLs, a `curl \| bash` bootstrap, `INSTALL_WITH_AI.md` prompts, per-file copy blocks. |
| 5 | 🟠 Major | **Cherry-picking silently broke things.** Commands referenced agents and skills that might not be installed. | A **Requires** line on every command, a **Skills used** line on every agent, and an explicit fallback ("do the step yourself, say what was missing"). |
| 6 | 🟠 Major | **`autonomous` mode could be enabled anywhere.** | Now only takes effect with `sandboxed: true` in project memory; otherwise it falls back to `supervised`. |
| 7 | 🟠 Major | **No honesty rule.** Nothing forbade claiming tests passed without running them, or fabricating links and outputs. | `guardrails` §8 "Evidence rule", repeated in every agent header and in the `/task` report phase. |
| 8 | 🟠 Major | **Agents could edit their own guardrails** (settings, hooks). | Blocked by both hooks and settings `deny`, and covered by tests. |
| 9 | 🟠 Major | **No CI on the library itself.** | `scripts/validate.sh` + `.github/workflows/validate.yml`: frontmatter, skill and agent naming, links and anchors, placeholders, installer for all tools, shellcheck, guardrail tests. |
| 10 | 🟡 Minor | "Read-only" agents were described as unable to edit, but they have `Bash`. | Wording corrected; hooks cover dangerous shell writes; documented how to remove `Bash` for strict isolation. |
| 11 | 🟡 Minor | The settings deny on `.env.*` also blocked `.env.example`, which the docs tell agents to use. | Deny narrowed; the hook does precise matching with template exceptions. |
| 12 | 🟡 Minor | No versioning or upgrade story. | `CHANGELOG.md` (SemVer; a major bump means output formats or config keys changed). |
| 13 | 🟡 Minor | Discoverability for AI tools. | `llms.txt` index; consistent file anatomy (frontmatter → guardrail header → inputs → method → output → rules). |
| 14 | 🔵 Nit | No pointers to the wider ecosystem. | `docs/references.md`: 39 verified repositories, plus standards and docs. |

## 3. Residual risks (accepted, documented)

| Risk | Why accepted | Mitigation in place |
|---|---|---|
| Pattern-based shell guards can be evaded by a determined adversary (write a script, then run it; obfuscation) | No pattern matcher is complete; these guards target accidents and naive injection | Sandboxing, scoped tokens, branch protection, and git hooks are the containment layers. `hooks/README.md` §Known limits says this plainly. |
| Non-Claude tools lack equivalent pre-tool hooks | Tool capability gap | Git hooks + branch protection cover the highest-impact actions for every tool. Per-tool permission guidance is in `hooks/README.md`. |
| Tool features change quickly (subagents/skills in Gemini, Codex, Copilot) | External | Guides mark version-dependent features; the fallback path (role files) always works. |
| Behavioural guardrails depend on model judgment | Inherent to LLMs | `docs/guardrail-tests.md` red-team scenarios; run them per tool and model upgrade. |
| Copilot conversion drops `tools:` from agents (tool names differ), so read-only roles get default tools there | Format gap | Documented in the Copilot guide; add explicit tool lists per your Copilot version. |
| Hook latency (~100–200 ms per shell command, many `grep` forks) | Negligible against model latency | Can be rewritten as a single `awk`/Python pass if it ever matters. |

## 4. Recommendations (roadmap)

1. **Behavioural eval harness:** script the red-team scenarios headlessly (e.g. `claude -p`, `gemini -p`, `codex exec`) against a fixture repo in CI, so model or tool upgrades are gated on guardrail behaviour, not just hook behaviour.
2. **Run metrics:** emit a machine-readable `metrics.json` per run (duration, loop iterations, review findings by severity, CI failures after PR) and aggregate weekly. This is the evidence for whether the workflow pays off.
3. **Wall-clock and cost budgets:** add `max_run_minutes` / `max_iterations_total` to Workflow Configuration, enforced by the orchestrator.
4. **Signed releases:** tag versions and have `install.sh` pin `AGENTIC_WORKFLOW_REF` to a tag by default for teams, rather than `main`.
5. **Ports of `guard-bash.sh`** to Cursor and Gemini hook formats once their hook APIs stabilize.
6. **CODEOWNERS** for `hooks/` and `skills/guardrails/`: changes to safety-critical files need a security reviewer.

## 5. Rollout conditions

- [x] **License chosen:** MIT (`LICENSE`).
- [ ] Every pilot repo has **branch protection** on its default branch (required review + status checks + no force-push).
- [ ] Agent tokens are **fine-grained and least-privilege**; no production credentials in agent environments.
- [ ] Teams run `scripts/test-guardrails.sh` and at least scenarios 1, 3, 7, 9, 13 from `docs/guardrail-tests.md` in their environment before first use.
- [ ] Start with `autonomy: supervised` for the first month. Review run directories in retros.
- [ ] Pin the library version per repo (git tag or submodule) and upgrade deliberately using `CHANGELOG.md`.
