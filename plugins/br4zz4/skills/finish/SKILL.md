---
name: finish
description: Use when implementation is complete and you need to integrate the work and clean up.
version: 2.3.0
---

# br4zz4:finish

> **TLDR**: Suíte verde → DoD marcado → docs → integra conforme `integration:` do repo (sem perguntar) → devolve a sessão à raiz → remove a worktree → apaga a branch → imprime o banner FINISHED. Nada é integrado nem removido com testes vermelhos.

---

## When to use

- Implementation is complete, all tasks done
- About to integrate work back into main or hand it off via PR

## Integration rule

Read `integration:` from the `## Integração` section of the repo's `AGENTS.md`:

1. repo `AGENTS.md` declares `integration: main` or `integration: pr` → use it
2. repo has no such section → global default in `~/.config/opencode/AGENTS.md`, which is `pr`

Do not ask the user which option to use; the rule decides. Ask only when the work is to be discarded.

---

## Step 1 — Verify tests

Run the full test suite (ask the **tester** to run it twice in a row when working from a spec):

```bash
<test command>
```

If tests fail: stop. Do not integrate, do not remove anything. Fix, then restart from Step 1.

Staging is fed by the merge on `main`, so it is verified **after** integration (Step 6), not before.

---

## Step 2 — Close the spec

When the work came from `docs/specs/<file>.md`:

- Mark every verified item of `# definition of done` with `- [x]`
- Set `status: done` and update `updated:` in the frontmatter
- Commit: `docs: close spec <short_description>`

---

## Step 3 — Update docs

Apply `br4zz4:docs`:

- Business rule introduced or changed → create or update the rule file and its index
- A learning emerged → create a learning file
- Nothing to document → state "No documentation changes needed" and move on

Commit any doc changes: `docs: update <topic> documentation`.

---

## Step 4 — Integrate

### `integration: pr`

```bash
git push -u origin <branch>
```

Then apply `br4zz4:pr`. For stacked PRs, open them in the spec's sequence order. After opening, offer a review only if the reviewer has not already run for this spec.

### `integration: main`

Commits go straight to `main` with immediate push:

```bash
git checkout main
git pull --rebase origin main
git merge <branch>
<test command>
git push origin main
```

If working directly on `main` (no branch), just make sure everything is pushed. If tests fail after the merge, investigate before pushing.

---

## Step 5 — Clean up

Only when the work is integrated (merged, or PR pushed) **and** the worktree has no uncommitted changes.

1. **Check the worktree**:

   ```bash
   git -C <worktree> status --porcelain
   ```

   If it prints anything: **keep the worktree**, warn the user and list the pending files. Never remove it, and never call `worktree_remove` with `force` without explicit confirmation.

2. **Move the session back to the repo root** with `session_move`.
3. **Remove the worktree** with `worktree_remove` (without `force`). Worktrees live in `<project>/.worktrees/<name>` (see `br4zz4:worktree`).
4. **Delete the local branch** if already merged:

   ```bash
   git branch -d <branch>
   ```

5. **Prune**:

   ```bash
   git worktree prune
   ```

For `integration: pr`, keep the local branch until the PR is merged; only the worktree is removed.

After cleanup, `git status` and `.worktrees/` must have no leftovers.

---

## Step 6 — Staging check

Merging on `main` is what deploys to staging. After integration, ping the created/edited screens as described in `## Staging` of `AGENTS.md`, or report `staging: none`.

- `integration: main`: ping right after the push.
- `integration: pr`: report "aguardando merge"; ping once the user says the PR was merged.
- A failed ping is not rolled back: fix forward with a new commit/PR, or report it. Mark the staging item of the spec's DoD only with a successful ping.

---

## Step 7 — FINISHED banner

Last output of the turn, after every previous step. Print it as a code block so the user sees at a glance that the work is over:

```
╔══════════════════════════════════════════╗
║                                          ║
║     ✅  F I N I S H E D  ✅              ║
║                                          ║
║  spec: docs/specs/<file>.md              ║
║  ████████████████████  7/7 (100%)        ║
║  DoD: completo · suíte verde             ║
║  integração: <main|pr> · staging: <ok>   ║
║                                          ║
╚══════════════════════════════════════════╝
```

- Print `FINISHED` only when the DoD is fully ticked, the work is integrated and the staging ping is ok (or `staging: none`)
- Anything still open (PR awaiting merge, failed ping, dirty worktree) → print `⏳ P E N D I N G` in the same frame, never `FINISHED`. List every todo item: `✔` for done, `☐` for pending (same items as the `todowrite` list), so the user sees progress and what is missing:

```
╔══════════════════════════════════════════╗
║                                          ║
║     ⏳  P E N D I N G  ⏳                ║
║                                          ║
║  spec: docs/specs/<file>.md              ║
║  ████████████░░░░░░░░  4/7 (57%)         ║
║                                          ║
║  ✔ tasks do how (4/4)                    ║
║  ✔ testes verdes 2×                      ║
║  ✔ review                                ║
║  ✔ integração (PR #123 aberto)           ║
║  ☐ merge do PR #123                      ║
║  ☐ ping em staging                       ║
║  ☐ definition of done (5/7)              ║
║                                          ║
╚══════════════════════════════════════════╝
```
- No spec: omit the `spec:` line
- Progress bar right below the `spec:` line: 20 cells, `█` filled and `░` empty, `done/total (pct%)` counted over the todo items (the `✔`/`☐` list). `FINISHED` is always 100%

---

## Discarding work

Confirm first:

> "Isso vai deletar permanentemente a branch `<name>` e os commits: `[list]`. Digite 'descartar' para confirmar."

Wait for the exact confirmation. Then `git checkout main` and `git branch -D <branch>`.

---

## Rules

- Never integrate with failing tests
- Never force-push without explicit user request
- Never delete work without typed confirmation
- Never remove a worktree with uncommitted changes
- Never `worktree_remove` with `force` without explicit confirmation
- Always run `br4zz4:docs` before opening a PR
