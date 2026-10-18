---
name: systematic-debugging
description: Evidence-driven debugging method - reproduce, minimize, observe, hypothesize, falsify, fix root cause, add regression test - plus playbooks for crashes, wrong output, performance regressions, flaky tests, environment-only bugs, and production errors from trackers like Sentry. Use for any bug, failing test, or unexplained behaviour.
---

# Systematic Debugging

## The loop
```
REPRODUCE → MINIMIZE → OBSERVE → HYPOTHESIZE → FALSIFY → FIX → VERIFY → PREVENT
     ↑                                   │
     └────────── hypothesis rejected ────┘
```
- **Reproduce:** deterministic failing test or command. No repro = no fix (instrument instead).
- **Minimize:** smallest input/config/code path that still fails.
- **Observe:** read the actual values (debugger, logs, prints marked `DEBUG(agent)`), don't assume them.
- **Hypothesize:** one sentence, specific, testable.
- **Falsify:** design the observation that would prove it *wrong*. Run it.
- **Fix:** root cause, minimal change.
- **Verify:** repro passes; suite passes; flakiness checked if relevant.
- **Prevent:** regression test; search for the same pattern elsewhere.

Keep a short hypothesis log in the debug report — it stops you from re-testing ideas you've already rejected.

## Playbooks

### Exception / crash
1. Full stack trace; find the first frame in project code.
2. Identify the bad value at that frame; walk back up the call chain to where it was produced.
3. Ask: is the bad value *invalid input that should be rejected earlier*, or *valid input the code mishandles*? The fix location differs.

### Wrong output
1. Write the failing assertion with the expected value from the ticket.
2. Binary-search the pipeline: assert intermediate values at the midpoint; recurse into the half that's wrong.

### Regression ("it used to work")
1. Find a known-good commit/tag/release.
2. `git bisect start <bad> <good>` → `git bisect run <repro-command>`.
3. Read the culprit commit's diff carefully — the bug is usually an unintended side effect of an intended change.

### Flaky test
Sources, in order of frequency: shared state between tests · time/date/timezone · async race / missing await / not waiting for UI · test order dependence · randomness without seed · network/external services · resource limits/timeouts in CI.
1. Reproduce by looping: `for i in $(seq 50); do <cmd> || break; done`, or runner options (`--repeat-each`, `pytest-repeat` / `pytest -p randomly`, `go test -count=50 -race`, `--runInBand` vs parallel).
2. Run in isolation vs with the full suite (order dependence) and with randomized order.
3. Fix the nondeterminism; never add retries/sleeps as the fix.

### Works locally, fails in CI (or vice versa)
Diff the environments: runtime versions, OS (case-sensitive paths, line endings), timezone/locale (`TZ=UTC`), env vars, parallelism, available services, file permissions, network access, caches (clear them), lockfile vs fresh install.

### Performance regression
1. Measure first: a benchmark or timed repro with numbers.
2. Profile (`--cpu-prof`, `py-spy`, `pprof`, async-profiler, dotnet-trace, browser performance trace via DevTools MCP).
3. Look for: N+1 queries (enable query logging), missing index (`EXPLAIN`), algorithmic blow-up, unnecessary serialization, render storms.
4. Fix, re-measure, include before/after numbers.

### Production error (error tracker)
With an error-tracker MCP (e.g. Sentry) or pasted event: get stack trace, breadcrumbs, request data (redacted), release/commit, frequency, first seen, affected users. Correlate first-seen with deploys (`git log` between releases). Reproduce locally with the captured input shape. Never copy real user PII into tests — synthesize equivalent data.

### Memory leak
Heap snapshots over time; look for growing collections, un-removed listeners/subscriptions, caches without eviction, closures retaining large objects.

## Rules
- Change one thing at a time.
- Remove every `DEBUG(agent)` marker before committing (`git grep -n "DEBUG(agent)"` must be empty).
- If after ~3 rejected hypotheses you're not converging, stop and summarize findings for the human with the best next experiment.
