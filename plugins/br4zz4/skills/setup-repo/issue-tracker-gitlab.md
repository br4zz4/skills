# Issue tracker: GitLab

This repo's issues and specs are GitLab issues. Run every operation through the [`glab`](https://gitlab.com/gitlab-org/cli) CLI.

## Conventions

- **Create an issue**: `glab issue create --title "..." --description "..."`. Pass multi-line descriptions through a heredoc. Use `--description -` to open an editor.
- **Read an issue**: `glab issue view <number> --comments`. Add `-F json` for machine-readable output.
- **List issues**: `glab issue list -F json`, adding `--label` filters as needed.
- **Comment on an issue**: `glab issue note <number> --message "..."` (comments are called "notes" in GitLab).
- **Apply / remove labels**: `glab issue update <number> --label "..."` / `--unlabel "..."`. Several labels can be comma-separated or passed by repeating the flag.
- **Close**: `glab issue close <number>`. It takes no closing comment, so post the explanation first with `glab issue note <number> --message "..."` and then close.
- **Merge requests**: GitLab's name for PRs is "merge requests". Use `glab mr create`, `glab mr view`, `glab mr note`, and so on, mirroring `gh pr ...` with `mr` replacing `pr` and `note`/`--message` replacing `comment`/`--body`.

The repo is inferred from `git remote -v`; `glab` handles that on its own inside a clone.

## Merge requests as a triage surface

**MRs as a request surface: no.** _(Change to `yes` when this repo handles external merge requests as feature requests; `/br4zz4:triage` reads this flag.)_

With `yes`, MRs go through the same labels and states as issues, via the `glab mr` equivalents:

- **Read an MR**: `glab mr view <number> --comments`, plus `glab mr diff <number>` for the diff.
- **List external MRs for triage**: `glab mr list -F json`, then retain only MRs whose author is not a project member/owner (a contributor's MR, not a maintainer's work in progress).
- **Comment, label, close**: use `glab mr note`, `glab mr update --label`/`--unlabel`, and `glab mr close`.

GitLab numbers issues and MRs separately, unlike GitHub, so `#42` is unambiguous once you know which surface the maintainer means.

## When a skill says "publish to the issue tracker"

Create a GitLab issue.

## When a skill says "fetch the relevant ticket"

Run `glab issue view <number> --comments`.

## Wayfinding operations

Used by `/br4zz4:wayfinder`. The **map** is one issue, with **child** issues as its tickets.

- **Map**: one issue labelled `wayfinder:map`, carrying the Notes / Decisions-so-far / Fog body. Create it with `glab issue create --label wayfinder:map`. (On GitLab tiers with native epics, an epic can hold the map instead; a labelled issue works everywhere.)
- **Child ticket**: an issue with `Part of #<map>` at the top of its description and the labels `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). When claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitLab's **native blocking link**, the canonical representation that the UI shows. Add it with the `/blocked_by #<n>` quick action, posted as a note (`glab issue note <child> --message "/blocked_by #<blocker>"`). Native blocking links need Premium/Ultimate; on the free tier (or wherever they are unavailable) fall back to a `Blocked by: #<n>, #<n>` line at the top of the description. A ticket is unblocked once every blocker is closed.
- **Frontier query**: `glab issue list -F json` scoped to the map's children, discarding any with an open blocker (a native `blocked_by` link to an open issue via `glab api projects/:id/issues/:iid/links`, or an open issue in the `Blocked by` line) or an assignee; the first in map order wins.
- **Claim**: `glab issue update <n> --assignee @me`, which is the session's first write.
- **Resolve**: `glab issue note <n> --message "<answer>"`, then `glab issue close <n>`, then add a context pointer (gist + link) to the map's Decisions-so-far.
