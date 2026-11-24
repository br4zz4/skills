---
name: issue
description: Use when something unplanned shows up during implementation (bug, risk, debt, missing piece outside the current scope) and must be recorded as a GitHub issue with a classified urgency, critical ones also get an automatic fix PR.
version: 1.0.0
---

# br4zz4:issue

> **TLDR**: Found something outside the current scope? Don't derail and don't forget it: classify urgency (`critical` | `normal`), open a GitHub issue. `normal` → only the issue, keep working. `critical` → issue **plus** an automatic fix PR on its own branch.

## When to use

Mid-implementation you discover something that is **not part of the current task**: a bug in neighbouring code, a security risk, tech debt, a missing test, a flaky behaviour, a needed follow-up. If it is part of the current spec's `# how`, it is a task, not an issue.

## Step 1 — Classify urgency

| Urgency | Criteria (any one) |
|---------|--------------------|
| `critical` | security vulnerability or leaked secret · data loss/corruption · production or `main` broken · regression already on `main` · blocks the current spec from reaching its DoD |
| `normal` | everything else: tech debt, improvement, minor/cosmetic bug, missing docs or tests, refactor idea |

In doubt between the two → `normal`, unless data or security is at stake.

## Step 2 — Open the issue

1. **Dedupe:** `gh issue list --state open --search "<keywords>"`. Already tracked → comment on it instead of opening another.
2. **Labels:** ensure `urgency:critical` and `urgency:normal` exist (`gh label create ... --force`), apply the matching one.
3. **Create** (English, technical):

   ```bash
   gh issue create --title "<type>: <short description>" \
     --label "urgency:<critical|normal>" --body-file <file>
   ```

Body:

```markdown
## TLDR
<one line>

## Context
Found while implementing `<spec or task>`. Where: `<file:line>`.

## Impact
<what breaks or risks, who is affected>

## Suggested fix
<if known>

## Urgency
<critical|normal> — <the criterion that matched>
```

Never put secrets, tokens, personal data or an exploitable recipe in the body. Security findings in a public repo: describe the area only and ask the user how to disclose (private advisory).

## Step 3a — `normal`: issue only

Stop here. Do **not** branch, fix or open a PR. Record the issue number in your final report and go back to the current task.

## Step 3b — `critical`: issue + automatic PR

Right after the issue exists, without asking:

1. **Isolate:** new worktree/branch from `main` (`br4zz4:worktree`), named `fix/issue-<n>-<slug>`. Never mix the fix into the current spec's branch.
2. **Red first:** the **tester** writes the failing test that reproduces it (`br4zz4:tdd`), without reading the implementation.
3. **Fix** at the source (see "fix at the origin" rules: own code in the owning repo, never a workaround in the consumer).
4. **Verify:** `br4zz4:verify`, full suite green.
5. **PR:** apply `br4zz4:pr` with `Fixes #<n>` in the body and the `urgency:critical` label. Merge it yourself only when its CI is green (merging into `main`/staging is always authorized; never production).
6. **Comment** the PR link on the issue.

Stop and leave only the issue open (reporting why) when: no clear cause after **2 attempts**, the fix needs another repo or a decision from the user, or it would exceed the PR size hard limit.

## Repos with the Autofix

A repo whose `.github/modules.json` has the `autofix` key fixes every issue labelled `urgency:critical` by itself: the pipeline hands the issue to an agent and opens the PR (automerge) only after proving a regression test red then green. In such a repo:

- Apply `module:<m>` too (the module that owns the bug); without it the autofix rejects the issue.
- Write the body for the agent: the exact reproduction, the observed behaviour and the **expected behaviour**. It reads only the masked body and comments from maintainers.
- Do not run Step 3b: the local agent does not open the fix PR, the Autofix does. Record the issue and keep working.
- A `urgency:critical` label starts the run, so apply it only to what must be fixed now; `autofix:blocked` keeps a human in charge.

## Final report

End the turn with a table of what was opened:

| issue | urgency | PR |
|-------|---------|----|
| #<n> <title> | critical | #<pr> |
| #<n> <title> | normal | — |

## Rules

- One issue per finding; never bundle unrelated problems
- Never fix a `normal` issue in the middle of the current task
- Merge the critical PR only with green CI; never on a red check (the Autofix PR enters by automerge)
- Never include secrets or personal data in issues, PRs or comments
