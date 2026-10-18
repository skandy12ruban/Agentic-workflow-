# Plan: <KEY> — <title>

> Status: **DRAFT — awaiting approval** · Size: S | M | L · Version: 1
> Ticket: <url> · Run: `.agentic/runs/<RUN-ID>/`

## 1. Goal
<One sentence in user-visible terms.>

## 2. Acceptance criteria
- [ ] **AC1** — Given … when … then …
- [ ] **AC2** — …
- [ ] **AC3** *(derived — please confirm)* — …

## 3. Approach
<3–6 sentences: the design, and why. Name the precedent being followed (`path:line`).>

**Alternatives considered:** <one line each, or "none — straightforward">

## 4. Steps
### Step 1 — <title>
- Files: `…`
- Change: …
- Tests: …
- Verify: `…`

### Step 2 — <title>
…

## 5. Test strategy
| AC | Unit | Integration | E2E (UI / API) |
|---|---|---|---|
| AC1 | `service.test.ts › cancels pending` | `orders.api.test.ts › POST cancel 200` | UI: cancel from detail page |
| AC2 | … | … | … |

Commands: unit `<cmd>` · integration `<cmd>` · e2e `<cmd>`

## 6. Risks & mitigations
| Risk | Likelihood / impact | Mitigation |
|---|---|---|

## 7. Scope
**In scope:** …
**Out of scope / follow-ups:** …
**Protected — will not touch:** …

## 8. Rollout & operations
<Env vars/config to add, migrations order, feature flag, backward compatibility, monitoring. "N/A" if none.>

## 9. Open questions
- [blocking] … *(proposed default: …)*
- [non-blocking] … *(assuming: …)*

---
**To approve:** reply `approve` (or `approve with changes: …`). **To revise:** reply with what to change.
