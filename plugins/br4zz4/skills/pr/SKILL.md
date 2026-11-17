---
name: pr
description: Use when creating a pull request.
version: 1.6.0
---

# commons:pr

> **TLDR**: Create a PR from current branch to `main` (or a specified branch), filling the project's PR template.

## Default behavior

- Target branch: `main`
- Override: user says "pr to `staging`" or "pr para `branch-name`" → use that branch

## Steps

0. **Update documentation first**
   Apply `br4zz4:docs` before opening any PR:
   - If the change introduces or modifies a business rule: update the rule file and `RULES.md`
   - If the change reveals a learning: create a learning file in `docs/learnings/`
   - If nothing to document: confirm "No documentation changes needed" and proceed
   Commit any doc changes before opening the PR.

1. **Check for PR template**
   - If `.github/PULL_REQUEST_TEMPLATE.md` exists → use it
   - If not → copy `.commons/ai/templates/PULL_REQUEST_TEMPLATE.md` to `.github/PULL_REQUEST_TEMPLATE.md`, then use it

2. **Analyze the diff**
   ```bash
   git log <base>...HEAD --oneline
   git diff <base>...HEAD --stat
   ```

   **Count only code files** — exclude documentation and specs from the count:
   - Exclude: `*.md`, `*.txt`, `docs/**`, `ai/shared/rules/**`, `ai/shared/skills/**`
   - Count everything else as a code file.

   **Check file count before proceeding:**
   - If ≤ 5 code files → proceed normally.
   - If 6–10 code files → explain the rule ("alvo de 5 arquivos de código; teto de 10"), show the list of files, check cohesion and atomicity, and ask: "Quer abrir em um PR só ou dividir?"
     - If one PR (the change is one cohesive, atomic unit) → proceed, note the exception in the TLDR.
     - If splitting → propose the split by **well-defined context** (not random grouping). Two PRs may touch the same file as long as each PR remains consistent and atomic. Wait for confirmation before opening any PR.
   - If > 10 code files and it is a rename/move refactor → proceed, note it in the TLDR.
   - If > 10 code files and it is not a rename refactor → stop. Tell the user the hard limit was exceeded and propose a split into sequential stacked PRs, each cohesive and atomic. Wait for confirmation before opening any PR.

3. **Fill the template sections**
   - **TLDR**: 1-2 lines summarizing what changed
   - **CONTEXT**: why this change was needed
   - **CHANGES**: bullet list of files/areas modified
   - **HOW TO TEST**: concrete steps to validate

4. **Create the PR**
   ```bash
   gh pr create --base <base> --title "<title>" --body "<filled template>"
   ```

## Merge strategy

Default: **normal merge** (merge commit). Squash and rebase stay allowed; the repo's `main` ruleset decides which methods exist, so check `gh api repos/<owner>/<repo>/rulesets` before assuming.

```bash
gh pr merge <n> --merge    # default: keeps the PR's commits and the branch ancestry
gh pr merge <n> --squash   # when the PR's commits are noise
gh pr merge <n> --rebase   # when the commits are atomic and history must stay linear
```

- Stacked PRs: merge in sequence order. With a normal merge the next PR needs no rebase (its base branch is already an ancestor of `main`); retarget it to `main` and merge. With squash or rebase, rebase the next PR onto `main` first, because the commits change identity.
- If a repo's ruleset requires linear history, normal merge is unavailable: use `--rebase`.

## PR sequence

When a change spans multiple dependent PRs that must merge in a fixed order, add
a `## SEQUENCE` section (uppercase) **immediately after the TLDR** (or after the
first summary block if the template has no TLDR) — not at the top, not at the
bottom.

Format: a numbered list of the PRs in merge order using bare `#<n>` references
(GitHub auto-expands each into a link with the PR title). Mark the current PR with
`(este)`. Below the list, a single line `Merge in this order: #<n1> #<n2> #<n3>`
with bare references too.

```markdown
> TLDR: ...

## SEQUENCE

1. #<n1>
2. #<n2> (este)
3. #<n3>

Merge in this order: #<n1> #<n2> #<n3>
```

- Same-repo PRs only — bare `#<n>` auto-links within the repo. For cross-repo,
  use the full `owner/repo#<n>` reference instead.
- Keep the same list on every PR in the group; only `(este)` moves per PR.

## After PR is open

After opening the PR, always ask:

> "PR aberto. Quer chamar `br4zz4:finish` para decidir o próximo passo (merge local, manter branch, ou revisar)?"

## Rules

- Title: max 70 chars, no AI mentions
- Keep CHANGES objective — list modified files and what changed
- HOW TO TEST must be actionable steps, not vague descriptions
- Never include Co-Authored-By or AI references in the PR body
- **File count excludes docs** — `*.md`, `docs/**`, `ai/shared/rules/**`, `ai/shared/skills/**` do not count toward the limit
- **Target: 5 code files per PR. Hard limit: 10** — cohesion and atomicity matter more than the count
- Each PR must work on its own: build and tests green, safe to deploy to prod without the next PR
- When splitting, two PRs may touch the same file — what matters is that each PR is consistent and atomic, not that files are exclusive
- Stacked PRs: base of PR n+1 is the branch of PR n; the `## SEQUENCE` section lists them in merge order
- Merge with `--merge` by default; squash or rebase when the repo ruleset or the PR's commits call for it
- Pode pushar a branch e abrir o PR direto, **sem pedir autorização antes** — o usuário autorizou a criação de PRs. Merge continua sendo decisão explícita do usuário.
