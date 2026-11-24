---
name: finish
description: Use when implementation is complete and you need to integrate the work and clean up.
version: 2.5.0
---

# br4zz4:finish

> **TLDR**: Suíte verde → DoD marcado → docs → integra conforme `integration:` do repo (sem perguntar) → devolve a sessão à raiz → remove a worktree → apaga a branch → deixa a main atualizada → imprime o banner FINISHED. Nada é integrado nem removido com testes vermelhos.

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

Merging into `main` (and so into staging) is always authorized: once a PR's CI is green, merge it with a normal merge (`gh pr merge <n> --merge`), in the stack's order, retargeting each next PR to `main` (`gh pr edit <n> --base main`) and waiting for `CLEAN`. Never merge on a red check (fix at the origin), never force-push, never go to production.

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

6. **Update `main` in the repo root** (always, in both integration modes):

   ```bash
   git -C <repo-root> checkout main
   git -C <repo-root> pull --rebase origin main
   git -C <repo-root> status -sb
   ```

   `status` must show `main` clean and with no ahead/behind. After the builder merges the PR(s), pull again so `main` carries them; check the CI of `main` (`gh run list --branch main --limit 1`).

For `integration: pr`, delete the local branch once the PR is merged (the builder merges it).

After cleanup, `git status` and `.worktrees/` must have no leftovers.

---

## Step 6 — Staging check

Merging on `main` is what deploys to staging. After integration, ping the created/edited screens as described in `## Staging` of `AGENTS.md`, or report `staging: none`.

- `integration: main`: ping right after the push.
- `integration: pr`: the builder merges the PR when CI is green, then pings.
- A failed ping is not rolled back: fix forward with a new commit/PR, or report it. Mark the staging item of the spec's DoD only with a successful ping.

---

## Step 7 — FINISHED banner

Printed as the **last output of every turn while a spec is being executed**, not only at the very end. Every pause counts: waiting for a subagent, waiting for the user's answer or approval, a PR awaiting merge, a failed step. A turn that ends without a banner is a bug. Print it as a code block so the user sees at a glance whether the work is over:

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

- Every turn that ends mid-spec prints `PENDING`; only the turn that closes the spec prints `FINISHED`
- Print `FINISHED` only when the DoD is fully ticked, the work is integrated and the staging ping is ok (or `staging: none`)
- Anything still open (PR awaiting merge, failed ping, dirty worktree) → print `⏳ P E N D I N G` in the same frame, never `FINISHED`. List every todo item: `✔` for done, `☐` for pending (same items as the `todowrite` list), so the user sees progress and what is missing:

```
╔══════════════════════════════════════════╗
║                                          ║
║     ⏳  P E N D I N G  ⏳                ║
║                                          ║
║  spec: docs/specs/<file>.md              ║
║  ████████████░░░░░░░░  4/7 (57%)         ║
║  pausa: aguardando tester (green 2×)     ║
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
- `PENDING` always has a `pausa:` line right below the bar with the reason the turn stopped and what resumes it (`aguardando tester`, `aguardando sua aprovação`, `aguardando merge do PR #n`, `ping falhou`)
- Print it again on every pause with the current state: the todo list and the bar must match the latest `todowrite`
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
