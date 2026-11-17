---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, look for deepening opportunities, choose where a seam goes, make code easier to test or for AI to navigate, or when another skill needs the deep-module vocabulary.
---

# Codebase Design

Design **deep modules**: plenty of behaviour behind a small interface, placed at a clean seam, and testable through that interface. Apply this language and these principles wherever code is designed or restructured. The goal is leverage for callers, locality for maintainers, and testability for everyone.

## Glossary

Use these terms exactly as written: do not swap in "component," "service," "API," or "boundary." The value lies in consistent language.

**Module**: anything that has an interface and an implementation. It is deliberately independent of scale: a function, class, package, or a slice spanning several tiers (a Rails concern, a service object, a whole engine). _Avoid_: unit, component, service.

**Interface**: everything a caller has to know to use the module correctly. That covers the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (both too narrow, since they mean only the type-level surface).

**Implementation**: what lies inside a module, its body of code. Not the same as **Adapter**: something can be a small adapter with a large implementation (an ActiveRecord-backed repo) or a large adapter with a small implementation (an in-memory fake). Say "adapter" when the seam is under discussion, and "implementation" otherwise.

**Depth**: leverage at the interface. It is how much behaviour a caller (or a test) can exercise for each unit of interface it must learn. A module is **deep** when a lot of behaviour sits behind a small interface, and **shallow** when the interface is almost as complex as the implementation.

**Seam** _(Michael Feathers)_: a place where behaviour can be changed without editing that place; it is the *location* where a module's interface lives. Choosing where the seam goes is a separate design decision from choosing what goes behind it. _Avoid_: boundary (overloaded by DDD's bounded context).

**Adapter**: a concrete thing that satisfies an interface at a seam. It names a *role* (the slot it fills), not its substance (what it contains).

**Leverage**: what callers gain from depth. More capability for each unit of interface learned. One implementation pays back across N call sites and M tests.

**Locality**: what maintainers gain from depth. Change, bugs, knowledge, and verification gather in one place instead of spreading over callers. Fix it once and it is fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + a lot of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

While designing an interface, ask yourself:

- Can the number of methods go down?
- Can the parameters be simpler?
- Can more of the complexity be hidden inside?

## Principles

- **Depth belongs to the interface, not the implementation.** A deep module may be built internally from small, mockable, swappable parts; they are simply not part of its interface. A module can have **internal seams** (private to the implementation, used by its own tests) alongside the **external seam** at its interface.
- **The deletion test.** Picture the module deleted. If the complexity disappears, it was only a pass-through. If the complexity comes back in N callers, the module was earning its place.
- **The interface is the test surface.** Callers and tests cross the same seam. Needing to test *beyond* the interface suggests the module has the wrong shape.
- **A single adapter makes a hypothetical seam; two adapters make a real one.** Add a seam only when something really varies across it.

## Designing for testability

Good interfaces make testing come naturally:

1. **Accept dependencies instead of creating them.**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results instead of causing side effects.**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Keep the surface small.** Fewer methods need fewer tests. Fewer params make test setup simpler.

## Relationships

- Each **Module** has exactly one **Interface** (the surface it shows to callers and tests).
- **Depth** describes a **Module** and is measured relative to its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** yields **Leverage** for callers and **Locality** for maintainers.

## Rejected framings

- **Depth as the ratio of implementation lines to interface lines** (Ousterhout): it rewards padding the implementation. Depth-as-leverage is used instead.
- **"Interface" meaning the TypeScript `interface` keyword or a class's public methods**: too narrow, because here the interface includes every fact a caller must know.
- **"Boundary"**: overloaded by DDD's bounded context. Say **seam** or **interface**.

## Going deeper

- **Deepening a cluster, given its dependencies**: see [DEEPENING.md](DEEPENING.md) for dependency categories, seam discipline, and the replace-don't-layer approach to tests.
- **Trying alternative interfaces**: see [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) to run parallel sub-agents that each design the interface in a radically different way, then compare them on depth, locality, and seam placement.
