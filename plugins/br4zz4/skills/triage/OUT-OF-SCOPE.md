# Out-of-Scope Knowledge Base

A repo's `.out-of-scope/` directory holds lasting records of rejected feature requests. It does two jobs:

1. **Institutional memory**: it keeps the reasoning behind a rejection from vanishing when the issue is closed
2. **Deduplication**: when a new issue resembles an earlier rejection, the skill can bring up the previous decision rather than relitigating it

## Directory structure

```
.out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

Each file covers one **concept**, not one issue. Several issues asking for the same thing share a single file.

## File format

Write in a relaxed, readable voice, closer to a short design document than a database row. Paragraphs, code samples, and examples help the reasoning make sense to someone reading it cold.

```markdown
# Dark Mode

This project does not offer dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes one color palette, defined in
`ThemeConfig`. Supporting several themes would mean:

- A theme context provider around the whole component tree
- Per-component, theme-aware style resolution
- A persistence layer for each user's theme preference

That is a large architectural change, and it does not fit the
project's focus on content authoring. Theming is a concern for downstream
consumers who embed or redistribute the output.

```ts
// ThemeConfig was not designed for switching at runtime:
interface ThemeConfig {
  colors: ColorPalette; // one palette, fixed at build time
  fonts: FontStack;
}
```

## Prior requests

- #42: "Add dark mode support"
- #87: "Night theme for accessibility"
- #134: "Dark theme option"
```

### Naming the file

Pick a short, descriptive kebab-case name for the concept: `dark-mode.md`, `plugin-system.md`, `graphql-api.md`. Someone scanning the directory should grasp what was rejected without opening anything.

### Writing the reason

Give a substantive reason, never just "we don't want this". Good reasons cite:

- Project scope or philosophy ("This project focuses on X; theming belongs downstream")
- Technical constraints ("Doing this would require Y, which conflicts with our Z architecture")
- Strategic choices ("We picked A over B because...")

The reason has to last. Skip temporary circumstances ("we're too busy right now"); those are deferrals, not rejections.

## When to check `.out-of-scope/`

At triage time (Step 1: Gather context), read every file in `.out-of-scope/`. While evaluating a new issue:

- See whether the request matches an existing out-of-scope concept
- Match on concept similarity, not keywords: "night theme" matches `dark-mode.md`
- On a match, tell the maintainer: "This resembles `.out-of-scope/dark-mode.md`. It was rejected before because [reason]. Do you still agree?"

The maintainer can respond in three ways:

- **Confirm**: add the new issue to the existing file's "Prior requests" list, then close it
- **Reconsider**: delete or update the out-of-scope file, and let the issue continue through normal triage
- **Disagree**: the issues are related but distinct, so continue with normal triage

## When to write to `.out-of-scope/`

Only when an **enhancement** (never a bug) is *rejected* as `wontfix`. Enhancement PRs follow the same rule as issues: a rejected PR is recorded here so the identical request does not come back as fresh code.

Do **not** write here when the `wontfix` reason is that the thing is **already implemented**. That is a built feature, not a rejected one, and recording it would contaminate the dedup checks with false rejections. The closing comment should instead point at where the feature lives.

The flow:

1. The maintainer decides a feature request is out of scope
2. Look for an existing matching `.out-of-scope/` file
3. If one exists, append the new issue to its "Prior requests" list
4. If none exists, create a file named for the concept, holding the decision, the reason, and the first prior request
5. Comment on the issue explaining the decision and naming the `.out-of-scope/` file
6. Close the issue with the `wontfix` label

## Updating or removing out-of-scope files

If the maintainer changes their mind about a rejected concept:

- Delete the `.out-of-scope/` file
- No need to reopen old issues; they stay as historical records
- The new issue that prompted the reconsideration goes through normal triage
