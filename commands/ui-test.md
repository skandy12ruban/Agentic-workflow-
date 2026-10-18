---
description: Verify frontend behaviour in a real browser via a browser MCP (Playwright/Chrome DevTools) - journeys from acceptance criteria, console/network checks, accessibility, responsive, screenshots - and optionally codify as E2E specs.
argument-hint: '[RUN-ID | URL or route | "journey to verify"] [--codify] [--viewport mobile|desktop|both]'
---

# /ui-test — Browser verification

**Input:** $ARGUMENTS

> **Requires** — agents: ui-tester · skills: guardrails, ui-testing, test-generation · MCP: browser (Playwright / Chrome DevTools); falls back to headless specs.
> Missing a file? Do that step yourself from the description here and say which file was missing. **Guardrails:** follow the `guardrails` skill throughout; stop if `.agentic/STOP` exists.

1. **Target:**
   - RUN-ID → ACs from `ticket.md`, changed UI from the diff.
   - URL/route → verify that page (and what changed on it in the current branch, if anything).
   - Free text → treat as the journey to verify.
   - Nothing → current branch's UI changes; derive journeys from the diff and commit messages, confirm with the user if unclear.
2. **Check capability:** is a browser MCP available? If not, say so and use fallback mode (write + run headless E2E specs) — ask before adding a new E2E framework.
3. Delegate to the `ui-tester` agent (applies the `ui-testing` skill): start the app if needed, run journeys, collect console/network/a11y/responsive findings and screenshots.
4. `--codify` (default **on** inside a `/task` run when an E2E framework exists) → add specs in the project's E2E framework and run them headless.
5. Write `e2e-report.md` (UI section) and print the journey table with evidence paths. Stop any servers you started.
