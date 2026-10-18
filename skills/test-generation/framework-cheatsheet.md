# Framework Cheatsheet

Targeted runs, skeletons, and idioms for the most common frameworks. Always defer to the project's existing style.

## Targeted runs

| Framework | Run one file | Run by name | Watch / rerun failed |
|---|---|---|---|
| Vitest | `npx vitest run path/x.test.ts` | `-t "cancels"` | `npx vitest` |
| Jest | `npx jest path/x.test.ts` | `-t "cancels"` | `--watch`, `--onlyFailures` |
| Mocha | `npx mocha path/x.spec.js` | `--grep "cancels"` | |
| Node test | `node --test path/x.test.js` | `--test-name-pattern="cancels"` | |
| pytest | `pytest tests/test_x.py` | `-k cancel` / `tests/test_x.py::test_cancel` | `--lf` (last failed), `-x` |
| unittest | `python -m unittest tests.test_x` | `tests.test_x.TestOrder.test_cancel` | |
| Go | `go test ./orders/` | `-run 'TestCancel/shipped'` | `-count=1` (no cache), `-race` |
| JUnit (Maven) | `./mvnw -Dtest=OrderServiceTest test` | `-Dtest='OrderServiceTest#cancel*'` | |
| JUnit (Gradle) | `./gradlew test --tests 'com.x.OrderServiceTest'` | `--tests '*OrderServiceTest.cancel*'` | `--continuous` |
| .NET | `dotnet test --filter FullyQualifiedName~OrderServiceTests` | `--filter "Name~Cancel"` | `dotnet watch test` |
| RSpec | `bundle exec rspec spec/x_spec.rb` | `spec/x_spec.rb:42` / `-e "cancels"` | `--only-failures` |
| Minitest (Rails) | `bin/rails test test/x_test.rb` | `-n /cancel/` / `file:42` | |
| PHPUnit | `vendor/bin/phpunit tests/XTest.php` | `--filter testCancel` | |
| Pest | `vendor/bin/pest tests/XTest.php` | `--filter "cancels"` | |
| cargo | `cargo test --test orders` | `cargo test cancel` | `cargo watch -x test` |
| Elixir | `mix test test/x_test.exs` | `test/x_test.exs:42` | `--failed` |
| Flutter/Dart | `flutter test test/x_test.dart` | `--plain-name "cancels"` | |
| Playwright | `npx playwright test e2e/x.spec.ts` | `-g "cancels"` | `--last-failed`, `--ui` |
| Cypress | `npx cypress run --spec cypress/e2e/x.cy.ts` | (use `it.only` locally, never commit) | |

## Skeletons

**Vitest / Jest (TS)**
```ts
import { describe, it, expect, beforeEach, vi } from 'vitest'; // jest: globals or '@jest/globals'
import { OrderService } from './service';

describe('OrderService.cancel', () => {
  let repo: FakeOrderRepo; let events: { emit: ReturnType<typeof vi.fn> };
  beforeEach(() => { repo = new FakeOrderRepo(); events = { emit: vi.fn() }; });

  it('cancels a pending order', async () => {
    const order = repo.add({ status: 'pending' });
    await new OrderService(repo, events).cancel(order.id, actor);
    expect(repo.get(order.id).status).toBe('cancelled');
    expect(events.emit).toHaveBeenCalledWith('order.cancelled', { id: order.id });
  });

  it.each(['shipped', 'delivered'])('rejects a %s order', async (status) => {
    const order = repo.add({ status });
    await expect(new OrderService(repo, events).cancel(order.id, actor)).rejects.toThrow(OrderNotCancellable);
  });
});
```

**pytest**
```python
import pytest
from orders.service import cancel, OrderNotCancellable

def test_cancel_pending_order(order_factory, db):
    order = order_factory(status="pending")
    cancel(order.id, actor=order.owner)
    db.refresh(order)
    assert order.status == "cancelled"

@pytest.mark.parametrize("status", ["shipped", "delivered"])
def test_cancel_rejects_non_pending(order_factory, status):
    order = order_factory(status=status)
    with pytest.raises(OrderNotCancellable):
        cancel(order.id, actor=order.owner)
```

**Go (table-driven)**
```go
func TestCancel(t *testing.T) {
    tests := []struct{ name, status string; wantErr error }{
        {"pending", "pending", nil},
        {"shipped", "shipped", ErrNotCancellable},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := newFakeRepo(Order{ID: "1", Status: tt.status})
            err := NewService(repo).Cancel(context.Background(), "1")
            if !errors.Is(err, tt.wantErr) { t.Fatalf("got %v, want %v", err, tt.wantErr) }
        })
    }
}
```

**JUnit 5 + AssertJ**
```java
@ParameterizedTest
@ValueSource(strings = {"SHIPPED", "DELIVERED"})
void rejectsNonPending(String status) {
    var order = repo.save(anOrder().status(Status.valueOf(status)).build());
    assertThatThrownBy(() -> service.cancel(order.id(), actor))
        .isInstanceOf(OrderNotCancellableException.class);
}
```

**xUnit**
```csharp
[Theory]
[InlineData(OrderStatus.Shipped)]
[InlineData(OrderStatus.Delivered)]
public async Task Cancel_NonPending_Throws(OrderStatus status) {
    var order = _repo.Add(new Order { Status = status });
    await Assert.ThrowsAsync<OrderNotCancellableException>(() => _sut.CancelAsync(order.Id, _actor));
}
```

**RSpec**
```ruby
RSpec.describe Orders::Cancel do
  it "cancels a pending order" do
    order = create(:order, status: :pending)
    described_class.call(order:, actor: order.user)
    expect(order.reload).to be_cancelled
  end
end
```

**API (HTTP-level) examples**
```ts
// supertest
await request(app).post(`/orders/${id}/cancel`).set('Authorization', `Bearer ${token}`).expect(200);
```
```python
# FastAPI TestClient / httpx
r = client.post(f"/orders/{oid}/cancel", headers=auth(user)); assert r.status_code == 200
```
```java
// MockMvc
mvc.perform(post("/orders/{id}/cancel", id).with(user("alice"))).andExpect(status().isOk());
```

**Playwright E2E**
```ts
test('customer cancels a pending order', async ({ page }) => {
  await page.goto('/orders/123');
  await page.getByRole('button', { name: 'Cancel order' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect(page.getByText('Cancelled')).toBeVisible();
});
```

**Cypress E2E**
```ts
it('customer cancels a pending order', () => {
  cy.visit('/orders/123');
  cy.findByRole('button', { name: /cancel order/i }).click(); // with @testing-library/cypress
  cy.contains('Cancelled').should('be.visible');
});
```
