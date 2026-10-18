---
name: api-testing
description: Verify backend/API changes (REST, GraphQL, gRPC, WebSocket, webhooks, queue consumers) against a locally running service - environment bring-up, contract discovery (OpenAPI/GraphQL/proto), request matrices for validation/auth/authz/idempotency, side-effect verification in the DB, backward compatibility, and codifying as integration tests. Use for /api-test or any backend change in /task.
---

# API Testing

## 1. Bring up the service locally
| Framework | Start (prefer project script) | Default port | Health |
|---|---|---|---|
| Express/Fastify/Nest/Hono/Koa | `npm run dev` / `npm run start:dev` | 3000 | `/health` (if defined) |
| FastAPI / Starlette | `uvicorn <module>:app --reload` | 8000 | `/docs`, `/openapi.json` |
| Django / DRF | `python manage.py runserver` | 8000 | |
| Flask | `flask run` | 5000 | |
| Spring Boot | `./mvnw spring-boot:run` / `./gradlew bootRun` | 8080 | `/actuator/health` |
| Quarkus | `./mvnw quarkus:dev` | 8080 | `/q/health` |
| ASP.NET Core | `dotnet run --project <Api>` | see `Properties/launchSettings.json` | `/health` (if mapped) |
| Go | `go run ./cmd/<svc>` | per config | per routes |
| Rails | `bin/rails server` | 3000 | `/up` (Rails 7.1+) |
| Laravel | `php artisan serve` | 8000 | `/up` (Laravel 11+) |
| Phoenix | `mix phx.server` | 4000 | |

Dependencies: `docker compose up -d <db> <cache> <broker>` if a compose file exists; else testcontainers config; else in-memory/SQLite test settings. Run migrations + seeds against **local** DB only. Use `.env.test`/`.env.example` values; never real third-party keys — point integrations at sandboxes or mocks (WireMock, MockServer, Prism for OpenAPI mocks, LocalStack for AWS).

## 2. Discover the contract
- OpenAPI: `openapi.(yaml|json)`, `swagger.*`, `/openapi.json`, `/v3/api-docs`, `/swagger/v1/swagger.json`, framework annotations.
- GraphQL: `schema.graphql`, SDL files, introspection query (local only).
- gRPC: `.proto` files; `grpcurl -plaintext localhost:<port> list` if reflection is on.
- None? Derive from route definitions and existing tests; recommend adding a contract in the report.

## 3. Auth for tests
Use, in order: project test helpers/fixtures that mint tokens → seed users with known passwords → local login endpoint → dev-only auth bypass documented in project memory. Create at least **two users** (owner and non-owner) and, if roles exist, one per role — authorization bugs need two identities to find.

## 4. Request matrix (per new/changed operation)
| Category | Cases |
|---|---|
| Happy | minimal valid; full valid; each optional field |
| Validation | each required field missing; wrong type; boundary lengths/values; invalid enum; extra unknown fields (rejected or ignored per convention) |
| AuthN | no credentials → 401; expired/invalid token → 401 |
| AuthZ | other user's resource → 403/404 (per convention, no data leak); insufficient role → 403 |
| State | operation invalid for current state → 409/422 with clear error |
| Not found | unknown id → 404 |
| Idempotency/concurrency | retry same request / idempotency key → no duplicate; two concurrent updates → consistent result |
| Pagination/filtering | first/last/empty page; limit caps; sort param allow-list |
| Errors | dependency failure (mocked) → correct 5xx/503 and error shape, no stack trace |
| Compatibility | existing clients' payloads still accepted; response fields not removed/renamed |

For **GraphQL**: also test field-level authorization, nested resolvers' access checks, query depth/complexity limits, and that errors don't leak internals.
For **webhooks**: signature verification (valid / invalid / missing / replayed timestamp), idempotency on redelivery.
For **queues/events**: publish a message to the local broker, assert consumer side effects, poison message handling.
For **WebSockets**: connect with/without auth, subscribe to another user's channel (must fail), message schema.

## 5. Execute and record
- `curl -sS -i -X POST "$BASE/orders/1/cancel" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{}'`
- `http POST :8000/orders/1/cancel "Authorization:Bearer $TOKEN"` (httpie)
- `grpcurl -plaintext -d '{"id":"1"}' localhost:50051 orders.v1.Orders/Cancel`
- Save request + response (status, headers, body) to `artifacts/api-<op>-<case>.txt` with secrets redacted.

## 6. Verify side effects
Query the local DB (CLI or a DB MCP pointed at the local DB) for created/updated rows; check outbox/events/queues; check emails captured by a local catcher (MailHog/Mailpit) — and verify **nothing** changed for rejected requests.

## 7. Contract validation
- Validate responses against OpenAPI (e.g. `schemathesis run openapi.yaml --base-url $BASE` for property-based fuzzing if available, or Prism validation proxy, or the project's contract tests — Pact, Spring Cloud Contract).
- Update the OpenAPI/GraphQL schema if the change modifies the contract and the project keeps it in-repo (or regenerates it).

## 8. Codify
Convert the matrix into integration tests using the project's framework and HTTP test client (see the `test-generation` skill's cheatsheet). Keep fixtures/factories consistent with existing tests. Run them in the normal suite.

## 9. Clean up
Stop the service and any containers you started (`docker compose stop <svc>`, not `down -v`, unless volumes were created by you for this run).
