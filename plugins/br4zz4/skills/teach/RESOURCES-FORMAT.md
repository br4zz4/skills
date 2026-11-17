# RESOURCES.md Format

`RESOURCES.md` is the curated list of trusted sources on the topic. Explainers should take their knowledge from here, never from parametric guesses. The communities listed here are the source of wisdom.

## Structure

```md
# {Topic} Resources

## Knowledge

- [Book: _Designing Data-Intensive Applications_ by Martin Kleppmann](https://example.com)
  Foundational text on storage, replication, and consistency. Use for: anything involving transactions, queues, or how a database behaves under load.
- [Docs: Rails Guides, Active Record Migrations](https://example.com)
  Official reference for schema changes. Use for: writing safe, reversible migrations.

## Wisdom (Communities)

- [r/rails](https://reddit.com/r/rails)
  Active subreddit with experienced maintainers answering. Use for: reviews of design choices, upgrade troubleshooting.
- Local: monthly Ruby meetup at {venue}
  Use for: live feedback on code you are working on.
```

## Rules

- **Trust first.** Favour primary sources, recognised experts, peer-reviewed work, and well-moderated communities. Leave out anything that is marketing wearing the costume of education.
- **Annotate each entry.** In three months a bare link says nothing. Add one line on what it covers and when to use it.
- **Split into Knowledge / Wisdom.** This mirrors the philosophy in [SKILL.md](./SKILL.md). A resource is welcome to appear in just one group.
- **Name the gaps.** If nothing good exists for an area the mission needs, add a `## Gaps` section listing what is missing, which guides later searches.
- **Prune hard.** Remove a resource that proved wrong, shallow, or off-mission rather than burying it. Five sharp sources beat thirty mediocre ones.
- **Note community preferences.** When the user has opted out of communities, record it here so future sessions stop suggesting them.
