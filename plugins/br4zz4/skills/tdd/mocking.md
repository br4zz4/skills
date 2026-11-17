# When to mock

Mock only at **system boundaries**:

- External APIs (payments, email, and similar)
- Databases (occasionally — a test database is usually better)
- Time and randomness
- The file system (occasionally)

Never mock:

- Your own classes or modules
- Internal collaborators
- Anything you control

## Designing for mockability

At a boundary, shape the interface so it is easy to replace.

**1. Inject dependencies**

Receive external collaborators as arguments instead of building them inside the function:

```typescript
function chargeOrder(order, gateway) {
  return gateway.charge(order.total);
}
```

Hard to replace — the dependency is created inside:

```typescript
function chargeOrder(order) {
  const gateway = new CardGateway(process.env.GATEWAY_KEY);
  return gateway.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over a generic fetcher**

Expose one function per external operation rather than a single function with branching:

```typescript
const accountsApi = {
  getAccount: (id) => fetch(`/accounts/${id}`),
  listInvoices: (accountId) => fetch(`/accounts/${accountId}/invoices`),
  createInvoice: (data) => fetch("/invoices", { method: "POST", body: data }),
};
```

Harder to replace — the mock would need conditional logic:

```typescript
const accountsApi = {
  request: (path, options) => fetch(path, options),
};
```

Benefits of the SDK style:
- Each mock returns one specific shape
- No conditionals in test setup
- A test shows at a glance which endpoints it touches
- Types stay precise per endpoint
