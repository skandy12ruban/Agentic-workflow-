---
description: Verify backend endpoints (REST/GraphQL/gRPC/WebSocket/webhooks) against a locally running service - request matrix for validation, auth, authz, idempotency, side effects, contract - and codify as integration tests.
argument-hint: '[RUN-ID | "METHOD /path" | operation name | spec file] [--codify] [--no-start]'
---

# /api-test — Endpoint verification

**Input:** $ARGUMENTS

1. **Target:**
   - RUN-ID → ACs + new/changed endpoints from the diff.
   - `METHOD /path`, GraphQL operation, or gRPC method → that operation.
   - OpenAPI/proto/schema file → operations defined there (prioritize those changed on this branch).
   - Nothing → endpoints changed on the current branch.
2. Delegate to the `api-tester` agent (applies the `api-testing` skill):
   - Bring up dependencies and the service locally (skip with `--no-start` if already running; read `api.base_url` from project memory).
   - Discover the contract, mint test identities (≥ 2 users), build and execute the request matrix, verify DB/queue side effects, validate against the contract.
3. `--codify` (default **on** inside a `/task` run) → add integration tests in the project's framework and run them.
4. Write `e2e-report.md` (API section) with transcripts in `artifacts/` (secrets redacted). Stop services you started.

Never send write requests to non-local environments unless project memory explicitly names one as allowed.
