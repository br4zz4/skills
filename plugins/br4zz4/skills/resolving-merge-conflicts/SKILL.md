---
name: resolving-merge-conflicts
description: "Use when a git merge or rebase has stopped on conflicts and needs to be resolved."
---

1. **Inspect where things stand.** Look at the merge/rebase status, the git history on both sides, and the list of conflicting files.

2. **Trace each conflict to its source.** Work out why each side changed and what it was trying to achieve. Read commit messages, the linked PRs, and the original issues or tickets.

3. **Settle every hunk.** Keep both intents whenever they can coexist. When they cannot, side with whichever matches the stated goal of the merge and record the trade-off. Never invent behaviour that neither side had. Always finish the resolution; never reach for `--abort`.

4. **Run the project's automated checks.** Find them first (in a Rails repo, typically `bin/rails test` and `rubocop`; elsewhere typecheck, then tests, then formatting) and repair whatever the merge broke.

5. **Complete the operation.** Stage all resolved files and commit. During a rebase, keep continuing until every commit has been replayed.
