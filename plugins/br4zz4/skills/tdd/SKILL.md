---
name: tdd
description: Test-driven development (red-green-refactor). Use when implementing any feature or bugfix test-first, before writing implementation code, when the user mentions "red-green-refactor", or asks for integration tests.
version: 3.0.0
---

# br4zz4:tdd

> **TLDR**: Write the test first, watch it fail, write minimal code to pass, refactor, commit. Repeat — one slice at a time, tested through public seams.

When exploring the codebase, read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you are touching.

In projects with the commons, run every test, lint and audit command through `make <module>.<target>` (for example `make core.test ARGS="spec/x_spec.rb"`) or, when there is no target, `docker compose --profile tools run --rm <service> <command>`; never on the host. See `br4zz4:make`.

---

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

No exceptions:
- Don't keep it "as reference"
- Don't "adapt" it while writing tests
- Delete means delete

---

## The cycle

```
RED → verify RED → GREEN → verify GREEN → REFACTOR → commit → repeat
```

### RED — Write the failing test

Write one minimal test showing what should happen. One behavior, one clear name, real code (no mocks unless unavoidable).

```
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' })
  expect(result.error).toBe('Email required')
})
```

### Verify RED — Watch it fail (MANDATORY, never skip)

```bash
<test command> <path>
```

Confirm:
- Test fails (not errors)
- Failure message is the expected one
- It fails because the feature is missing (not a typo)

If the test passes immediately, it covers existing behavior. Fix the test.

### GREEN — Write minimal implementation

Write the simplest code that makes the test pass. Duplicated logic, hardcoded values, naive loops — all acceptable. Correctness first.

Do not add features, refactor other code, or optimize beyond the test.

### Verify GREEN — Watch it pass (MANDATORY)

```bash
<test command> <path>
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, no warnings)

If another test breaks, fix it now, before moving on.

### REFACTOR — Clean up

After GREEN only:
- Remove duplication
- Improve names
- Extract helpers where intent is obscured
- Apply SOLID, DRY, KISS

Tests must stay green. Do not add behavior.

### Commit

```bash
git add <files>
git commit -m "<type>: <description>"
```

Commit at phase boundaries:

| When | Prefix |
|------|--------|
| Tests written, all RED | `test:` |
| Tests passing, GREEN | `feat:` or `fix:` |
| Refactor done | `refactor:` |
| Measured bottleneck fixed | `perf:` |

---

## What a good test is

Tests verify behavior through public interfaces, never implementation details. Code can change entirely; tests should not. A good test reads like a specification: "customer can check out with a valid cart" names a capability and survives refactors because it ignores internal structure.

Fixtures and factories carry only the bulk of a record. Every piece of data the result depends on is explicit in the test's arrange, never hidden in a fixture, a factory default or a `setup`/`let`.

Examples of good and bad tests: [tests.md](tests.md). When and how to mock: [mocking.md](mocking.md).

## Seams: where tests go

A **seam** is the public boundary a test exercises — the place where behavior is observable without reaching inside. Tests live at seams, never against internals.

**Agree on seams before writing any test.** Write down the seams under test and confirm them with the user; no test is written at an unconfirmed seam. Coverage of every possible edge is impossible, so settling the seams up front aims the effort at critical paths and complex logic.

Ask: "What is the public interface, and which seams should we test?"

If the shape of the interface itself is uncertain (module depth, seam placement, what to expose), load `br4zz4:codebase-design` for the vocabulary. It is a reference to consult, not a session to run.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks on a refactor that changed no behavior.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a hand-derived snapshot, a constant compared to itself), so it passes by construction. Expected values must come from an independent source: a known literal, a worked example, the spec.
- **Horizontal slicing**: writing every test first, then every implementation. Bulk tests verify *imagined* behavior and lock in structure before you understand the code. Work in **vertical slices**: one test → one implementation → repeat, each test a **tracer bullet** shaped by what the previous cycle taught you.

## Rules of the loop

- **Red before green.** Failing test first, then only enough code to pass it. No speculative features.
- **A single slice per cycle.** Each pass covers one seam, one test and the smallest implementation that satisfies it.
- **Refactor after green**, with the suite passing; behavior never changes during refactor.

---

## Coverage requirement

Every logical branch has a test:
- `if` → truthy path AND falsy path
- `switch` → every `case`
- Edge cases (empty input, nil, boundary values, error paths) each get their own test

---

## Who does what

Tests belong to the **tester**; production code belongs to the **builder** and **intern**. Nobody else edits tests (enforced by permissions).

| Phase | Owner |
|-------|-------|
| RED — write the failing tests from the Gherkin `## acceptance criteria`, without reading the new implementation | tester |
| GREEN — minimal implementation | builder / intern |
| Verify GREEN — full suite, 2× in a row | tester |
| REFACTOR — production code only; tests stay green | builder / intern |

Need a new or changed test during implementation → ask the tester; never edit it yourself.

## Executing a spec

When working from a `docs/specs/` file, follow its `# how` in order:

1. Mark the todo `in_progress`
2. Follow the steps exactly — the spec has full paths and exact commands
3. If a step is wrong or unclear, stop and raise it instead of improvising
4. Mark the todo `completed` only after tests are green and the commit is done
5. Move to the next task

After each task, apply `br4zz4:verify` before claiming it complete.

---

## Red flags — stop and correct

| Thought | Reality |
|---------|---------|
| "I'll write the test after, it's faster" | Tests written after pass immediately — they prove nothing |
| "This is too simple to test" | Simple code breaks. The test takes 30 seconds. Write it. |
| "I'll refactor while making it work" | Finish GREEN first |
| "The test is hard to write" | The design is hard to use. Simplify the interface |
| "I only need one test for this function" | Count the branches. One test per branch |
| "I already tested it by hand" | Manual checks leave no record and cannot be re-run |
| "Tests after achieve the same goals" | Tests-after answer "what does this do?"; tests-first answer "what should this do?" |

---

## When stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the wished-for API. Assert first, then implement |
| Test too complicated | The design is too complicated. Simplify the interface |
| Must mock everything | Code too coupled. Use dependency injection |
| Test setup huge | Extract helpers. Still complex? Simplify the design |

---

## Verification checklist (before marking any task complete)

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for the expected reason (feature missing, not a typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, no warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and error paths covered

Can't check every box? You skipped TDD. Start over.

Apply `br4zz4:verify` before any completion claim.
