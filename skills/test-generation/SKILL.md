---
name: test-generation
description: Generate high-value tests in whatever framework the project already uses (Jest, Vitest, pytest, JUnit, Go testing, RSpec, xUnit, PHPUnit/Pest, cargo test, Playwright, Cypress, and more) - test matrix design, edge cases, mocking strategy, fixtures, determinism, and mutation-style verification. Use when writing or improving unit, integration, component, or E2E tests.
---

# Test Generation

## 1. Learn the local dialect before writing a line
- Find 2–3 existing tests closest to the code under test (same directory, same layer).
- Note: file location & naming (`*.test.ts` beside source vs `tests/` mirror tree, `test_*.py`, `*_test.go`, `*Test.java`, `*_spec.rb`), assertion style (`expect`, `assert`, AssertJ, `should`), fixture approach (factories, builders, `conftest.py`, `beforeEach`), mocking library, test data conventions, how async is handled, how DB is handled (transactions rolled back, test DB, in-memory, testcontainers).
- Your tests must look like they were written by the same person.

## 2. Design the matrix (before code)
For each unit of behaviour, enumerate:

| Category | Ask yourself |
|---|---|
| Happy path | Typical valid input → expected output/state/side effect |
| Boundaries | 0, 1, many; empty string/list; max length; first/last page; min/max numeric; exactly-at-limit |
| Invalid input | wrong type, missing required, malformed format, out of range, injection-like strings |
| State | precondition not met (already cancelled, not logged in, expired) |
| Permissions | anonymous, wrong role, other tenant/user's object |
| Failure of dependencies | DB error, timeout, 5xx from upstream, partial failure — is the error surfaced correctly and no partial writes? |
| Concurrency / idempotency | double submit, retried message, two writers |
| Time & locale | timezones, DST, leap day, locale formatting, unicode/emoji, RTL |
| Regression | the exact scenario from the bug report |

Pick the cases that matter for *this* change; don't pad.

## 3. Choose the level
- **Unit**: pure logic, branching, calculations, validators, reducers, hooks/composables, small components.
- **Integration**: crosses a boundary you own (DB via ORM, HTTP handler via framework test client, message handler with in-memory broker).
- **E2E**: user journeys or API flows against a running system — few, focused on acceptance criteria.

## 4. Mocking strategy
- Mock at the **boundary you don't own** (third-party HTTP, payment provider, email, clock, randomness).
- Prefer fakes/in-memory implementations and the framework's test utilities over deep mocks of your own classes.
- HTTP: use the ecosystem's interceptor (`msw`/`nock`, `responses`/`respx`, `httptest.Server`, WireMock, WebMock/VCR) rather than mocking your HTTP client's internals.
- Time: inject a clock or use fake timers (`vi.useFakeTimers`, `jest.useFakeTimers`, `freezegun`/`time-machine`, `clock` interfaces in Go/Java).

## 5. Write
- Arrange / Act / Assert, visually separated.
- Names read as specs: `cancels a pending order`, `test_cancel_rejects_shipped_order`, `TestCancel_ShippedOrder_ReturnsErrNotCancellable`.
- Assert on outcomes the user/caller cares about: return values, persisted state, emitted events, HTTP status + body, rendered text/roles.
- UI component tests: query by role/label/text (Testing Library philosophy); avoid snapshot tests of whole trees unless the project already relies on them.
- Table-driven/parameterized tests where the project uses them (`it.each`, `@pytest.mark.parametrize`, Go table tests, JUnit `@ParameterizedTest`).

## 6. Run & prove
1. Run only the new tests (fast feedback) — see [`framework-cheatsheet.md`](framework-cheatsheet.md) for targeted-run syntax.
2. Run the affected suite.
3. **Mutation check:** flip a condition / remove a line in the implementation the core test targets → test must fail → revert. Report it.
4. Run the new tests several times (or with random order/shuffle if supported) to catch flakiness.

## 7. Anti-patterns to refuse
- Tests that assert the mock was called and nothing else.
- `sleep()` to wait for async — use the framework's await/polling/`waitFor`.
- Tests depending on execution order or shared mutable state.
- Catch-all `try/except: pass` in tests; `expect(true).toBe(true)`.
- Changing production code solely to make it testable in ways that hurt its design (dependency injection is fine; exposing private state is not).
- Deleting or `.skip`-ing a failing existing test.
