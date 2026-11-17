# Domain Docs

How the engineering skills should read this repo's domain documentation while exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, or
- **`CONTEXT-MAP.md`** at the repo root when present: it points to one `CONTEXT.md` per context. Read each one that matters for the topic.
- **`docs/adr/`**: read the ADRs that touch the area you are about to work in. In multi-context repos, also look in `src/<context>/docs/adr/` for decisions scoped to a context.

When any of these files is missing, **carry on silently**. Do not point out the absence and do not suggest creating them up front. The `/br4zz4:domain-modeling` skill (reached through `/br4zz4:grill-with-docs` and `/br4zz4:improve-codebase-architecture`) creates them lazily once terms or decisions are actually resolved.

## File structure

Single-context repo (the usual case):

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-outbox-for-domain-events.md
│   └── 0002-postgres-for-write-model.md
└── app/
```

Multi-context repo (a `CONTEXT-MAP.md` sits at the root):

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← decisions spanning the system
└── app/
    ├── ordering/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← decisions for this context only
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

## Use the glossary's vocabulary

Whenever your output names a domain concept (an issue title, a refactor proposal, a hypothesis, a test name), use the term exactly as `CONTEXT.md` defines it. Do not slide into synonyms the glossary expressly avoids.

A concept missing from the glossary is a signal: either you are inventing language the project does not use (reconsider), or there is a real gap (note it for `/br4zz4:domain-modeling`).

## Flag ADR conflicts

When your output contradicts an existing ADR, say so explicitly instead of overriding it silently:

> _Contradicts ADR-0007 (outbox for domain events), but worth reopening because…_
