# GLOSSARY.md Format

`GLOSSARY.md` holds the canonical language of this teaching workspace. Every explainer, exercise, and learning record should follow its terminology. Building it is part of the learning: squeezing a concept into a tight definition shows the user understands it.

## Structure

```md
# {Topic} Glossary

{A sentence or two on the subject this glossary spans.}

## Terms

**Idempotency**:
The property that running an operation several times leaves the system in the same state as running it once.
_Avoid_: Safe to retry, repeatable

**Outbox**:
A table written in the same transaction as a state change, from which events are published afterwards.
_Avoid_: Event queue table, staging events

**Backpressure**:
A signal from a slow consumer that tells a producer to slow down or stop sending.
_Avoid_: Throttling, rate cap
```

## Rules

- **Add a term only once the user understands it.** The glossary records compressed knowledge; it is no dictionary for learning from. When a concept has just been introduced, hold off until the user can apply it correctly.
- **Take a stance.** Where several words name one concept, choose the best and list the others as aliases to avoid. That is how language gets compressed.
- **Keep definitions tight.** One or two sentences. Say what the term IS, not what it does or how to use it.
- **Use the glossary's own terms in definitions.** Once a term is in, prefer it everywhere, even inside other definitions. This is how complicated terms become easier to grasp afterwards.
- **Group under subheadings** when natural clusters appear (e.g. `## Persistence`, `## Messaging`). A flat list is fine when the terms hang together.
- **Call out ambiguities.** If the wider field uses a term loosely, record the resolution: "In this workspace, 'job' always means a background job; cron entries are tracked separately."
- **Revise as understanding grows.** A definition written in week one may be wrong by week six. Edit it in place; never leave stale entries.
