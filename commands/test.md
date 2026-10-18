---
description: Generate and run tests for the current change (or a given path) using the project's own test framework, mapped to acceptance criteria.
argument-hint: '[RUN-ID | path/or/glob | "describe what to test"] [--level unit|integration|e2e|all]'
---

# /test — Framework-native test generation

**Input:** $ARGUMENTS

1. **Determine the target:**
   - RUN-ID → the run's diff vs base + `plan.md` test strategy + `ticket.md` ACs.
   - A path/glob → that code (and its current behaviour as the spec — write characterization tests).
   - Free text → find the code it describes, confirm the target with the user if ambiguous.
   - Nothing → the current branch's diff vs base (`git diff <base>...HEAD`, plus uncommitted changes).
2. **Detect the stack** (`stack-detection` skill) unless a Stack Profile already exists in `context.md`.
3. Delegate to the `test-engineer` agent with: target, ACs (if any), stack profile, requested `--level` (default: unit + integration where boundaries exist).
4. Product-code bugs revealed by tests → report them clearly. In a run, fix (or delegate to `debugger`) and re-run; standalone, ask before changing product code.
5. Write/print `test-report.md` (run dir, or `.agentic/adhoc/` for standalone use).

Never delete, skip, or weaken existing tests to make things pass.
