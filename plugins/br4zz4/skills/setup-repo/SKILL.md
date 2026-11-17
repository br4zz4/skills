---
name: setup-repo
description: "Configure this repo for the engineering skills: its issue tracker, triage label vocabulary, and domain doc layout. Run once before using the other engineering skills for the first time."
disable-model-invocation: true
---

# Setup Repo

Scaffold the per-repo configuration the engineering skills rely on:

- **Issue tracker**: where issues live (GitHub by default; local markdown works out of the box too)
- **Triage labels**: the strings standing in for the five canonical triage roles
- **Domain docs**: where `CONTEXT.md` and the ADRs live, plus the rules for consuming them

This skill is driven by prompting, not by a deterministic script. Explore, show what you found, confirm with the user, and only then write.

## Process

### 1. Explore

Inspect the repo to learn its starting state. Read what exists and assume nothing:

- `git remote -v` and `.git/config`: is it a GitHub repo, and which one?
- `AGENTS.md` and `CLAUDE.md` at the repo root: does either exist, and does either already hold an `## Agent skills` section?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/`: has this skill already produced output there?
- `.scratch/`: a hint that a local-markdown issue tracker convention is in use
- Is the `br4zz4:triage` skill installed? (a `triage` skill folder next to this one, or `br4zz4:triage` among your available skills.) The answer decides whether Section B runs at all.
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These appear only in a truly large multi-package repo; without them the repo is single-context, which covers nearly every repo.

### 2. Present findings and ask

Summarise what exists and what is missing. Then go through the sections in order, one section and one answer at a time.

Open each section with the recommended answer so the user can accept it in a word. Add a one-line explainer only when the choice truly branches, and skip a section altogether when exploration already settled it (Section B when `br4zz4:triage` is not installed, Section C when there is no monorepo).

**Section A: Issue tracker.**

> Explainer: The "issue tracker" is where this repo's issues live. Skills like `br4zz4:to-tickets`, `br4zz4:triage`, and `br4zz4:to-spec` read from it and write to it, so they must know whether to run `gh issue create`, write a markdown file under `.scratch/`, or follow another workflow you describe. Choose the place where you really track work for this repo.

Default posture: these skills were built around GitHub. If a `git remote` points at GitHub, propose it. If a `git remote` points at GitLab (`gitlab.com` or a self-hosted host), propose GitLab. Otherwise, or if the user prefers, offer:

- **GitHub**: the repo's GitHub Issues hold the work, driven by the `gh` CLI
- **GitLab**: the repo's GitLab Issues hold the work, driven by the [`glab`](https://gitlab.com/gitlab-org/cli) CLI
- **Local markdown**: issues live as files under `.scratch/<feature>/` in this repo (suits solo projects or repos with no remote)
- **Other** (Jira, Linear, etc.): ask the user to describe the workflow in a paragraph; the skill records it as freeform prose

Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates include a "PRs as a request surface" flag that defaults to **off**. Leave it off and do not mention it: a user who wants external PRs in the triage queue can flip the flag in the file later.

**Section B: Triage label vocabulary.** Skip this section entirely when the `br4zz4:triage` skill is not installed (exploration tells you), because a skill that is not installed needs no labels.

When it is installed, ask exactly one question:

> Keep the default triage labels? (recommended: **yes**)

The defaults are the five canonical roles, each label string identical to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them unchanged. Only if the user says no, typically because the tracker already uses other names (for instance `bug:triage` for `needs-triage`), collect the overrides so `br4zz4:triage` applies the existing labels instead of creating duplicates.

**Section C: Domain docs.** Default to **single-context** (one `CONTEXT.md` plus `docs/adr/` at the repo root). This fits almost every repo, so write it without asking.

Offer **multi-context** (a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files) only when exploration found monorepo signals, and then confirm which layout the user wants.

### 3. Confirm and edit

Show the user a draft of:

- The `## Agent skills` block to add to whichever of `CLAUDE.md` / `AGENTS.md` is being edited (step 4 has the selection rules)
- The contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md` (the last one only when `br4zz4:triage` is installed)

Give them a chance to edit before anything is written.

### 4. Write

**Choose the file to edit:**

- If `CLAUDE.md` exists, edit it.
- Otherwise, if `AGENTS.md` exists, edit it.
- If neither exists, ask the user which one to create; do not choose for them.

Never create `AGENTS.md` when `CLAUDE.md` already exists (or the reverse); always edit the file that is already present.

If the chosen file already has an `## Agent skills` block, update it in place instead of appending a duplicate. Leave the user's edits to the surrounding sections alone.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when `br4zz4:triage` is installed and Section B ran. Otherwise omit both.

Then write the docs files, using the seed templates in this skill folder as the starting point:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [triage-labels.md](./triage-labels.md): label mapping (only if `br4zz4:triage` is installed)
- [domain.md](./domain.md): domain doc consumer rules and layout

For an "other" issue tracker, write `docs/agents/issue-tracker.md` from scratch based on the user's description.

### 5. Done

Tell the user setup is complete and name the engineering skills that will now read these files. Remind them that `docs/agents/*.md` can be edited directly later; running this skill again is needed only to switch issue trackers or start over.
