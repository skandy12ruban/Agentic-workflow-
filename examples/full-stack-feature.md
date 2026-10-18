# Example: Full-stack feature, ticket → PR

**Repo:** Next.js 14 web app + NestJS API, Postgres/Prisma, Vitest, Playwright, GitHub Actions.
**Tool:** any (shown with Claude Code). **MCP:** Jira (Atlassian), GitHub, Playwright.
**Ticket:** `SHOP-482 — Customers can cancel pending orders`.

---

### You
```
/task SHOP-482
```

### Agent — Phases 0–2
```
▶ Phase 0/11 Bootstrap — run dir .agentic/runs/SHOP-482/ created, tree clean, base=main
▶ Phase 1/11 Intake — fetched SHOP-482 via Jira MCP (+4 comments, 1 Figma link)
   AC1 Pending orders show a "Cancel order" button on the order page
   AC2 Confirming cancels the order; status shows "Cancelled"
   AC3 Shipped/delivered orders cannot be cancelled (button hidden; API rejects)
   AC4 (derived) Customer can't cancel another customer's order
   Note: comment from PM (Jan 12) says "no refund automation in this ticket"
▶ Phase 2/11 Discover — Stack: pnpm, Next 14 (apps/web), Nest 10 (apps/api), Prisma, Vitest, Playwright
   Precedent: refund flow — apps/api/src/orders/orders.service.ts:88, apps/web/app/orders/[id]/RefundButton.tsx
   Tests: unit beside source; API e2e in apps/api/test/*.e2e-spec.ts (supertest); web e2e in apps/web/e2e
```

### Agent — Phases 3–4: the approval gate
```
⛔ APPROVAL NEEDED — Plan for SHOP-482: "Customers can cancel pending orders"

Approach: OrderStatus.CANCELLED + migration; OrdersService.cancel() mirroring refund();
          POST /orders/:id/cancel (owner-only); CancelOrderButton with confirm dialog.
Size: M · 5 steps · ~280 LOC
Tests: 6 unit, 5 API e2e (incl. other-user 404), 2 Playwright journeys
Top risk: race with fulfilment webhook marking SHIPPED → conditional UPDATE … WHERE status='PENDING'

Needs your call:
  1. AC4 is derived — confirm other users get 404 (not 403) per our API convention?

Full plan: .agentic/runs/SHOP-482/plan.md
Reply:  approve  |  approve with changes: …  |  revise: …  |  stop
```

### You
```
approve — and yes, 404
```

### Agent — Phases 5–9
```
▶ Phase 5/11 Implement — branch feat/SHOP-482-cancel-pending-orders
   step 1/5 ✅ enum + migration (verified up/down)            a1f3c2e
   step 2/5 ✅ OrdersService.cancel()                          7b9d011
   step 3/5 ✅ POST /orders/:id/cancel + DTO + guard           c04e9aa
   step 4/5 ✅ CancelOrderButton + dialog                      e55b7d3
   step 5/5 ✅ wire into order page, hide unless PENDING       91aa0f4
   classification: full-stack
▶ Phase 6/11 Test — +6 unit, +5 API e2e; mutation check: removing the status guard fails 2 tests ✅
▶ Phase 7/11 Local CI — format ✅ lint ✅ (fixed 1) types ✅ build ✅ unit 412/412 ✅ api-e2e 58/58 ✅
▶ Phase 8/11 Review — code-reviewer: 1 major (dialog confirm button lacked loading state → double submit)
                      security-auditor: no blocking issues
   fixed major (3c1d8e0), re-review ✅
▶ Phase 9/11 E2E
   API: 9 cases ✅ — incl. other user → 404, shipped → 409, repeat cancel → 409, no DB change on rejects
   UI:  J1 cancel pending ✅ (mobile + desktop)  J2 shipped hides button ✅
        console: 0 errors · network: 0 failures · a11y: dialog traps focus, Esc closes ✅
        +2 Playwright specs in apps/web/e2e/cancel-order.spec.ts ✅
```

### Agent — Phase 10 gate (supervised mode)
```
⛔ READY TO PUSH — feat/SHOP-482-cancel-pending-orders (6 commits, +301 −12)
PR title: feat(orders): customers can cancel pending orders [SHOP-482]
PR body preview: .agentic/runs/SHOP-482/pr-body.md
Reply: approve | revise: …
```

### You
```
approve
```

### Agent — Phase 10–11
```
▶ Phase 10/11 Deliver — pushed; draft PR #913 opened; Jira comment posted; SHOP-482 → In Review
   remote CI: ✅ lint, ✅ test, ✅ e2e (8m 12s) → PR marked ready for review

✅ SHOP-482 — Customers can cancel pending orders
PR:        https://github.com/acme/shop/pull/913 (CI: ✅)
Branch:    feat/SHOP-482-cancel-pending-orders · 6 commits · +301 −12 in 11 files
Tests:     +6 unit, +5 API e2e, +2 Playwright · all green
Checks:    lint ✅ types ✅ build ✅ security ✅
Verified:  AC1 ✅ UI · AC2 ✅ UI+API · AC3 ✅ UI+API · AC4 ✅ API
Follow-ups: refund-on-cancel (suggested new ticket)
Artifacts: .agentic/runs/SHOP-482/
```

## What the run directory contains afterwards
```
.agentic/runs/SHOP-482/
├── state.md          phase: done, all steps + loop counters + log
├── ticket.md         4 ACs (1 derived, confirmed)
├── context.md        stack profile + context brief
├── plan.md           v1, approved
├── test-report.md    11 new tests, mutation check
├── ci-report.md      stage table
├── review.md         iteration 1 (1 major), iteration 2 (approve), security section
├── e2e-report.md     API matrix + UI journeys
├── artifacts/        j1-confirm-mobile.png, j1-cancelled-desktop.png, api-cancel-*.txt, dev-server.log
└── summary.md
```
