---
description: Bug-fix workflow - intake the bug report or error (ticket, Sentry issue, stack trace, failing test), reproduce with a failing test, find the root cause, get approval for the fix, fix, verify, and optionally ship.
argument-hint: '<TICKET-KEY | error-tracker URL | "description / stack trace" | failing test name> [--ship]'
---

# /fix-bug — Reproduce, root-cause, fix

**Input:** $ARGUMENTS

A specialization of `/task` with a debugging-first middle.

1. **Bootstrap + intake** (as `/task` Phases 0–1). For error-tracker links (Sentry, Rollbar, Datadog, Bugsnag…), fetch the event via MCP: stack trace, breadcrumbs, release, frequency, tags. Redact PII.
2. **Discover:** `stack-detection` + `codebase-explorer` focused on the stack-trace frames and the code path in the report.
3. **Reproduce:** delegate to the `debugger` agent (applies `systematic-debugging`). Goal: a **failing automated test** that captures the bug. Can't reproduce → report what was tried and propose instrumentation; stop.
4. **Diagnose:** debugger returns root cause with evidence, why it wasn't caught, and the same pattern elsewhere.
5. **Gate ⛔:** present root cause + proposed fix + regression test via `approval-gate`. (Small, local, obviously-correct fixes may be bundled into one approval with the diagnosis.)
6. **Fix** on a `fix/<KEY>-<slug>` branch: minimal root-cause fix; regression test now passes.
7. **Verify:** affected suite (`/test`), local CI (`/ci-check`), review (`/review`), and UI/API verification of the original repro steps if the bug was user-visible.
8. **Deliver** with `--ship` (or ask): PR body includes *Root cause*, *Fix*, *Regression test*, *Same pattern elsewhere*.
9. **Report** using the debugger's report format plus PR/CI status.
