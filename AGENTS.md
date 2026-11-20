# AGENTS.md

Repo of agent skills published as the Claude plugin `br4zz4`. Glossary in `docs/CONTEXT.md`.

## Rules

- Every skill lives in `plugins/br4zz4/skills/<name>/SKILL.md`; `name` equals the folder name.
- Every change passes `make validate` and `make test`.
- Never reference skills by old prefixes; use `br4zz4:<name>`.
- Run `make hooks` once per clone: a `pre-push` hook runs `br4zz4-skills-sync` after pushes to `main`.

## Integração

```
integration: main
```

## Staging

```
staging: none
```
