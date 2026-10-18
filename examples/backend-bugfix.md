# Example: Backend bug fix from an error tracker

**Repo:** Python 3.12, FastAPI, SQLAlchemy, Postgres, pytest, GitLab CI.
**Tool:** Gemini CLI (works identically elsewhere). **MCP:** Sentry, GitLab.
**Report:** Sentry issue — `KeyError: 'currency'` in `/invoices/{id}/pdf`, 312 events, first seen after release `2026.01.14`.

---

### You
```
/fix-bug https://acme.sentry.io/issues/4471/
```

### Agent
```
▶ Intake — Sentry MCP: KeyError 'currency' at app/invoices/render.py:57 in format_total()
   312 events / 41 users · first seen 2026-01-14 09:02 (release 2026.01.14) · only invoices created before 2025-06
   Breadcrumbs: GET /invoices/{id}/pdf → render_invoice() → format_total(line_items)
▶ Discover — stack: uv, FastAPI, SQLAlchemy 2, pytest (+ factory_boy), ruff, mypy; CI: .gitlab-ci.yml
▶ Reproduce — debugger agent
   Hypothesis log:
     H1 "line_items JSON from old invoices lacks 'currency'" → checked migration 0042: currency added
        to new rows only, no backfill → CONSISTENT
     H2 "regression from release 2026.01.14" → git log: commit 9e1f… replaced item.get('currency', inv.currency)
        with item['currency'] in a refactor → CONFIRMED
   Failing test written: tests/invoices/test_render.py::test_pdf_renders_legacy_items_without_currency  ❌ KeyError
```
```
⛔ APPROVAL NEEDED — Fix for Sentry-4471

Root cause: refactor 9e1f2ab (render.py:57) assumes every line item has 'currency'; invoices created
            before migration 0042 (2025-06) store items without it.
Proposed fix: restore fallback to the invoice-level currency in format_total(); add the regression test.
Not proposed (follow-up): data backfill migration for legacy line items — needs a product/ops decision.
Same pattern elsewhere: app/invoices/csv_export.py:31 has the same item['currency'] access → fix too?

Reply:  approve  |  approve with changes: …  |  revise: …  |  stop
```

### You
```
approve, include the csv export fix
```

### Agent
```
▶ Fix — branch fix/sentry-4471-legacy-invoice-currency
   render.py + csv_export.py fallback · regression tests for both ✅ (fail before, pass after)
▶ Test — invoices suite 88/88 ✅; looped new tests 20× ✅
▶ CI — ruff ✅ ruff format ✅ mypy ✅ pytest 1,204/1,204 ✅ (postgres via docker compose)
▶ Review — no blocking findings; nit: extract fallback helper → done (shared item_currency())
▶ API — GET /invoices/{legacy_id}/pdf → 200 application/pdf ✅; new invoice → 200 ✅; other tenant → 404 ✅
▶ Deliver — MR !377 opened (draft), links Sentry issue; pipeline ✅ → ready for review

✅ Sentry-4471 fixed — MR !377
Root cause: refactor 9e1f2ab dropped the currency fallback for pre-2025-06 line items
Regression tests: test_pdf_renders_legacy_items_without_currency, test_csv_export_legacy_items
Follow-up suggested: backfill migration for legacy line_items.currency
```

## Why this goes well
- **Reproduction before fix:** the failing test came first, so the fix is provably correct.
- **Hypotheses were falsified, not assumed** — and the log is in the debug report for reviewers.
- **Scope stayed tight:** the backfill (data change, needs ops sign-off) became a follow-up instead of sneaking into the hotfix.
- **Same-pattern search** caught a second instance of the bug before users did.
