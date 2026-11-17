# Issue tracker: GitHub

This repo's issues and specs are GitHub issues. Run every operation through the `gh` CLI.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Pass multi-line bodies through a heredoc.
- **Read an issue**: `gh issue view <number> --comments`, filtering the comments with `jq` and also fetching the labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`, adding `--label` and `--state` filters as needed.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Add or remove labels**: `gh issue edit <number> --add-label "..."` or `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

The repo is inferred from `git remote -v`; `gh` handles that on its own inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Change to `yes` when this repo handles external PRs as feature requests; `/br4zz4:triage` reads this flag.)_

With `yes`, PRs go through the same labels and states as issues, via the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments`, plus `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments`, then retain only an `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (discard `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment, label, close**: use `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, and `gh pr close`.

GitHub uses a single number space for issues and PRs, so a bare `#42` could be either: resolve it with `gh pr view 42`, falling back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/br4zz4:wayfinder`. The **map** is one issue, with **child** issues as its tickets.

- **Map**: one issue labelled `wayfinder:map`, carrying the Notes / Decisions-so-far / Fog body. Create it with `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue attached to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues are not enabled, list the child in a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). When claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies**, the canonical representation that the UI shows. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only, the live gate). Where dependencies are unavailable, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked once every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`, scoped to the map's sub-issues / task list), discard any that have an open blocker (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the `Blocked by` line) or an assignee; the first in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me`, which is the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`, then add a context pointer (gist + link) to the map's Decisions-so-far.
