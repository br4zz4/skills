---
name: domain-modeling
description: Build and refine a project's domain model. Use when talking about codebase terminology, writing or updating a CONTEXT.md, or recording or revising an ADR.
---

# Domain Modeling

Grow and refine the project's domain model while you design. This is the *active* discipline: questioning terms, inventing edge-case scenarios, and writing glossary entries and decisions down the instant they settle. (Simply *reading* `CONTEXT.md` to pick up vocabulary is not this skill; any skill can do that in one line. Use this one when you are changing the model rather than consuming it.)

## File structure

Most repos have one context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-outbox-for-domain-events.md
│       └── 0002-postgres-for-write-model.md
└── app/
```

A `CONTEXT-MAP.md` at the root means the repo holds several contexts, and the map says where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← decisions that span the system
├── app/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← decisions for this context only
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily, only once there is content for them. With no `CONTEXT.md` yet, create it when the first term gets resolved. With no `docs/adr/` yet, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

If the user's wording clashes with `CONTEXT.md`, say so right away. "The glossary defines 'cancellation' as X, but you seem to mean Y. Which one is it?"

### Sharpen fuzzy language

Vague or overloaded words deserve a precise canonical replacement. "You said 'account': is that the Customer or the User? They are different things."

### Discuss concrete scenarios

While relationships between domain concepts are on the table, stress-test them with specific scenarios. Make up cases that probe edge conditions and push the user to be exact about where one concept ends and another begins.

### Cross-reference with code

When the user describes how something behaves, verify it against the code. Any mismatch gets surfaced: "The code cancels a whole Order, yet you just described partial cancellation. Which is correct?"

### Update CONTEXT.md inline

As soon as a term is settled, edit `CONTEXT.md` on the spot. Do not accumulate changes for later; record them as they occur. Follow the layout in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Keep `CONTEXT.md` completely free of implementation detail. It is not a spec, not a scratch pad, and not a place for implementation decisions. It is a glossary, nothing more.

### Offer ADRs sparingly

Propose an ADR only when all three of these hold:

1. **Hard to reverse**: changing your mind later would cost something real
2. **Surprising without context**: a future reader will ask "why was it done this way?"
3. **The result of a real trade-off**: genuine alternatives existed and you chose one for concrete reasons

If even one is missing, do not write the ADR. Use the layout in [ADR-FORMAT.md](./ADR-FORMAT.md).
