# Good and bad tests

## Good tests

**Integration-style**: exercise real interfaces instead of mocking internal parts.

```typescript
test("customer can place an order with a valid basket", async () => {
  const basket = createBasket();
  basket.add(sku);
  const outcome = await placeOrder(basket, card);
  expect(outcome.status).toBe("confirmed");
});
```

What they have in common:

- Cover behavior that users or callers care about
- Touch the public API only
- Keep passing through internal refactors
- Describe WHAT happens, not HOW
- Make one logical assertion

## Bad tests

**Implementation-detail tests**: bound to internal structure.

```typescript
test("placeOrder invokes gateway.charge", async () => {
  const gateway = jest.mock(paymentGateway);
  await placeOrder(basket, card);
  expect(gateway.charge).toHaveBeenCalledWith(basket.total);
});
```

Warning signs:

- Mocks of internal collaborators
- Tests of private methods
- Assertions on call counts or call order
- The test fails after a refactor that changed no behavior
- The test name explains HOW instead of WHAT
- Verification through a side channel instead of the interface

```typescript
test("registerAccount writes a row", async () => {
  await registerAccount({ name: "Bia" });
  const row = await db.query("SELECT * FROM accounts WHERE name = ?", ["Bia"]);
  expect(row).toBeDefined();
});
```

Prefer verifying through the interface:

```typescript
test("registerAccount makes the account retrievable", async () => {
  const account = await registerAccount({ name: "Bia" });
  const found = await findAccount(account.id);
  expect(found.name).toBe("Bia");
});
```

**Tautological tests**: the expected value restates the implementation, so the test passes by construction.

```typescript
test("orderTotal adds up the lines", () => {
  const lines = [{ price: 10 }, { price: 5 }];
  const expected = lines.reduce((acc, l) => acc + l.price, 0);
  expect(orderTotal(lines)).toBe(expected);
});
```

Use an independent, known literal instead:

```typescript
test("orderTotal adds up the lines", () => {
  expect(orderTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```
