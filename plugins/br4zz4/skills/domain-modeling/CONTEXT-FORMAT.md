# CONTEXT.md Format

## Structure

```md
# {Context Name}

{One or two sentences saying what this context is and why it exists.}

## Language

**Order**:
{One or two sentences defining the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment issued to a customer once delivery is complete.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Take a position.** When several words name the same concept, choose the best one and list the rest under `_Avoid_`.
- **Keep definitions short.** One or two sentences at most. Say what the thing IS, not what it does.
- **Include only terms that belong to this project's context.** Generic programming ideas (timeouts, error types, utility patterns) stay out, even if the project leans on them heavily. Before adding a term, ask whether it is unique to this context or a general programming concept; only the first kind belongs.
- **Group terms under subheadings** once natural clusters appear. If everything sits in one cohesive area, a flat list works.

## Single vs multi-context repos

**Single context (the common case):** one `CONTEXT.md` at the repo root.

**Multiple contexts:** a `CONTEXT-MAP.md` at the repo root names each context, shows where it lives, and describes how the contexts relate:

```md
# Context Map

## Contexts

- [Ordering](./app/ordering/CONTEXT.md): receives and tracks customer orders
- [Billing](./app/billing/CONTEXT.md): generates invoices and processes payments
- [Fulfillment](./app/fulfillment/CONTEXT.md): manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events, which Fulfillment consumes to begin picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events, which Billing consumes to produce invoices
- **Ordering ↔ Billing**: they share the `CustomerId` and `Money` types
```

How the skill decides which structure applies:

- `CONTEXT-MAP.md` present: read it to discover the contexts
- Only a root `CONTEXT.md` present: single context
- Neither present: create a root `CONTEXT.md` lazily once the first term is resolved

With several contexts, work out which one the current topic belongs to. If that is unclear, ask.
