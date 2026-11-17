# ADR Format

ADRs are stored in `docs/adr/` with sequential numbers in the file name: `0001-slug.md`, `0002-slug.md`, and so on.

The `docs/adr/` directory is created lazily, at the moment the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: the context, the decision taken, and the reason.}
```

That is the whole template. An ADR may be a single paragraph. Its worth lies in recording *that* a decision happened and *why*, not in filling out headings.

## Optional sections

Add these only when they carry real value; most ADRs need none of them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`): handy once decisions get revisited
- **Considered Options**: only when the rejected alternatives deserve to be remembered
- **Consequences**: only when there are non-obvious downstream effects to flag

## Numbering

Find the highest number already in `docs/adr/` and add one.

## When to offer an ADR

All three conditions must hold:

1. **Hard to reverse**: changing course later would cost something meaningful
2. **Surprising without context**: someone reading the code will wonder "why on earth was it built this way?"
3. **The result of a real trade-off**: genuine alternatives existed and one was picked for specific reasons

A decision that is easy to reverse needs no ADR, since you can simply reverse it. An unsurprising one raises no questions. And if no real alternative existed, there is nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "Domain events travel through a transactional outbox." "Writes go to Postgres; reads are projected into a separate table."
- **Integration patterns between contexts.** "Ordering and Billing talk through domain events, not synchronous HTTP calls."
- **Technology choices with lock-in.** Database, message bus, auth provider, deployment target. Not every gem or library, only those that would take a quarter to replace.
- **Boundary and scope decisions.** "The Customer context owns customer data; other contexts hold only its ID." The explicit refusals matter as much as the commitments.
- **Deliberate departures from the obvious path.** "Raw SQL instead of ActiveRecord here because X." Any case where a sensible reader would assume the opposite. These notes stop the next engineer from "fixing" a deliberate choice.
- **Constraints the code does not reveal.** "We cannot use AWS because of compliance requirements." "Responses must stay under 200ms per the partner API contract."
- **Rejected alternatives whose rejection is not obvious.** If you weighed GraphQL and chose REST for subtle reasons, write it down, or someone will propose GraphQL again in six months.
