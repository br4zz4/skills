# Deepening

A guide to deepening a cluster of shallow modules safely, taking its dependencies into account. It relies on the vocabulary of [SKILL.md](SKILL.md): **module**, **interface**, **seam**, **adapter**.

## Dependency categories

When judging a deepening candidate, first classify its dependencies. The category decides how the deepened module is tested across its seam.

### 1. In-process

Pure computation, in-memory state, no I/O. These can always be deepened: merge the modules and test through the new interface directly. No adapter is needed.

### 2. Local-substitutable

Dependencies with a local test stand-in (SQLite or a transactional test database for Postgres, an in-memory filesystem). Deepening works as long as the stand-in exists, and the test suite runs the deepened module against it. The seam stays internal: the module's external interface exposes no port.

### 3. Remote but owned (Ports & Adapters)

Services you own that sit across a network (microservices, internal APIs). Place a **port** (interface) at the seam. The deep module holds the logic, and the transport is injected as an **adapter**. Tests use an in-memory adapter; production uses an HTTP, gRPC, or queue adapter.

A recommendation can read like this: *"Put a port at the seam, build an HTTP adapter for production and an in-memory adapter for tests, so the logic stays in one deep module even though it is deployed over a network."*

### 4. True external (Mock)

Third-party services you do not control (Stripe, Twilio, and the like). The deepened module receives the external dependency as an injected port, and tests supply a mock adapter.

## Seam discipline

- **A single adapter makes a hypothetical seam; two adapters make a real one.** Add a port only when at least two adapters are justified (usually production plus test). A seam with one adapter is only indirection.
- **Internal versus external seams.** A deep module may have internal seams (private to the implementation, used by its own tests) in addition to the external seam at its interface. Do not push internal seams into the interface merely because tests use them.

## Testing strategy: replace, don't layer

- Once tests exist at the deepened module's interface, the old unit tests on the shallow modules are waste; delete them.
- Write the new tests at the deepened module's interface, which is the test surface.
- Assert on outcomes observable through the interface, never on internal state.
- Tests should survive internal refactors, since they describe behaviour and not implementation. A test that must change whenever the implementation changes is testing past the interface.
