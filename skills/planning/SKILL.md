---
name: planning
description: Write a concrete, approvable implementation plan - goal, acceptance criteria, approach, ordered verifiable steps, test strategy across unit/integration/E2E, risks, scope boundaries, and size. Use when producing plan.md for /plan or /task, or when asked to "plan", "design", or "break down" a change.
---

# Planning

A good plan lets a competent engineer implement the change **without asking a single question**, and lets a reviewer **approve it in two minutes**. Use [`plan-template.md`](plan-template.md) as the output structure.

## Principles

1. **Acceptance criteria first.** If you can't say how you'll know it's done, you're not ready to plan steps.
2. **Follow precedents.** The best design is usually "do it the way the codebase already does it next door". Cite the precedent file.
3. **Vertical slices.** Order steps so each leaves the system working: data model → service logic → interface (API/UI) → wiring → docs. Tests come *with* each step, not all at the end.
4. **Every step is verifiable.** Each step names the command (or observation) that proves it worked.
5. **Make reversibility explicit.** Migrations: forward + rollback. Behaviour changes: behind a flag if the project uses flags. Breaking API changes: version or deprecate.
6. **Smallest change that meets the criteria.** Note "nice-to-haves" in an *Out of scope / follow-ups* section rather than doing them.

## Step-writing format

```markdown
### Step 2 — Add `cancel()` to OrderService
- Files: `src/orders/service.ts`, `src/orders/service.test.ts`
- Change: add `cancel(orderId, actor)`; reject if status ∈ {shipped, delivered}; emit `order.cancelled`. Mirror `refund()` at `service.ts:88` for the event pattern.
- Tests: unit — cancels pending; rejects shipped (throws `OrderNotCancellable`); emits event once; unknown id → `NotFound`.
- Verify: `pnpm vitest run src/orders/service.test.ts`
```

Bad step: "Implement cancel logic and handle edge cases." (no files, no verification, "edge cases" unspecified.)

## Test strategy guidance

| Change type | Unit | Integration | E2E |
|---|---|---|---|
| Pure logic / utility | ✅ thorough | – | – |
| New API endpoint | ✅ service/validators | ✅ HTTP-level (framework test client) | API tester against running service |
| DB schema/migration | ✅ model logic | ✅ migration up/down on test DB | – |
| UI component | ✅ component test (render/interaction) | – | UI tester journey if user-visible flow changes |
| Full feature (UI+API) | ✅ | ✅ | ✅ both, mapped to every AC |
| Bug fix | ✅ **regression test that fails before the fix** | as needed | if the bug was user-visible |
| Refactor (no behaviour change) | existing tests must pass unchanged; add characterization tests if coverage is thin | – | – |

## Risk checklist (include only those that apply)
- Data: migrations on large tables (locks, backfills), nullable → non-null, data loss.
- Compatibility: public API/SDK consumers, mobile clients on old versions, serialized formats, events/queues schemas.
- Security: new inputs, auth paths, permissions, PII, secrets.
- Performance: N+1 queries, unbounded lists, hot paths, bundle size.
- Operability: config/env vars to add in every environment, feature flags, monitoring/alerts, rollout order across services.
- Concurrency: races, idempotency, retries, duplicate events.

## Sizing
- **S**: < ~100 LOC, 1–3 steps. Plan can be compact.
- **M**: 100–500 LOC, 3–8 steps.
- **L**: > 500 LOC or > 8 steps or multiple services → propose splitting into sequenced PRs (each independently shippable) and plan only the first, unless the user insists.

## Revising a plan
When the user rejects or edits: keep the previous version as `plan.v1.md`, write the new `plan.md`, add a *Changes since v1* section at the top, and re-request approval.
