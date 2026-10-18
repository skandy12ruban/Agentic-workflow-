---
name: code-review
description: A rigorous, language-agnostic code review checklist and method - intent match, correctness, edge cases, error handling, concurrency, data integrity, API contracts, performance, readability, consistency, and test quality - with a severity scale and evidence requirements. Use when reviewing a diff, a PR, or your own changes before shipping.
---

# Code Review

## Method
1. **Context first.** Read the ticket/plan, then `git diff --stat` to see the shape, then the full diff.
2. **Two passes.**
   - *Pass 1 — design:* Is this the right change in the right place? Does it follow existing patterns? Is anything missing (migration, config, docs, permission check, test)?
   - *Pass 2 — line by line:* the checklist below.
3. **Follow the blast radius.** For every changed function signature, exported symbol, schema, or config key, find its consumers (`grep`/`git grep`) and confirm they still work.
4. **Evidence or it didn't happen.** Each finding: location, failure scenario (concrete input → wrong behaviour), fix.

## Checklist

### Correctness
- Logic matches the acceptance criteria — including the negative cases.
- Off-by-one, inclusive/exclusive ranges, empty collections, `null`/`undefined`/`None`/zero values, integer overflow, float money (use decimal/minor units).
- Boolean logic: inverted conditions, `&&` vs `||`, short-circuit side effects, De Morgan mistakes.
- Async: missing `await`, unhandled promise rejections, fire-and-forget that should be awaited, blocking calls in async contexts.
- Equality/identity semantics (`==` vs `===`, `is` vs `==`, `.equals`), mutable default args, aliasing/mutation of shared objects.
- Time: timezone-naive datetimes, local vs UTC, DST, clock assumptions.

### Error handling
- Errors are caught at the right level, not swallowed; messages are actionable; no sensitive data in errors returned to clients.
- Failure of external calls (timeouts, retries with backoff, circuit breaking where the codebase does so).
- Partial failure: multi-step writes in a transaction or with compensation; no half-updated state.

### Concurrency & data integrity
- Race conditions (check-then-act without locking/transaction/unique constraint).
- Idempotency of handlers that can be retried (webhooks, queue consumers, POSTs with idempotency keys).
- Migrations: safe on large tables, backwards compatible with the running version during deploy, reversible.
- Constraints enforced in the DB (unique, FK, not-null) not only in code.

### Interfaces & compatibility
- Public API/route/event/schema changes are backward compatible or explicitly versioned.
- Request validation at the boundary; response shape matches docs/OpenAPI/GraphQL schema.
- Config/env vars: defaults are safe; documented; added to example env files.

### Performance
- N+1 queries; queries in loops; missing indexes for new query patterns; unbounded result sets (missing pagination/limits).
- Expensive work on hot paths or in render loops; unnecessary re-renders (UI); large bundle imports for small needs.
- Memory: unbounded caches/maps, listeners not removed, large payloads held in memory.

### Security (quick pass — the `security-review` skill goes deep)
- Authn/authz on every new entry point; object-level ownership checks.
- Injection-safe APIs (parameterized queries, no shell string concatenation, escaped output).
- Secrets not hard-coded or logged.

### Readability & consistency
- Names say what things are; functions do one thing; no dead code, commented-out blocks, or leftover debug output.
- Matches the surrounding code's patterns and abstractions — new patterns need a reason.
- Comments explain *why*, not *what*; no stale comments.

### Tests
- New behaviour has tests; bug fixes have a regression test that would fail without the fix.
- Tests assert meaningful outcomes; deterministic; no sleeps; no reliance on order.
- No existing tests deleted/skipped/weakened without explanation.

### Frontend specifics
- Loading/empty/error states; accessibility (labels, roles, focus, keyboard); i18n strings not hard-coded where the app is localized; responsive behaviour; XSS-safe rendering (no raw HTML injection without sanitizing).

## Severity & verdict
Use: 🔴 blocker · 🟠 major · 🟡 minor · 🔵 nit · ❔ question. **Changes requested** if any blocker/major remains. Approve otherwise; list minors/nits as optional.

## Review → fix loop
- The orchestrator (not the reviewer) applies fixes for blockers/majors, then re-runs tests and requests a **fresh** review of the new diff.
- Max 2 iterations by default. Still blocked → summarize the disagreement and ask the human.
- Minors/nits: fix if trivial and clearly correct; otherwise list them in the PR description as follow-ups.
