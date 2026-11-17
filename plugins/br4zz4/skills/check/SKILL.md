---
name: check
description: Use when asked to review or check code against project rules.
version: 2.0.0
---

# br4zz4:check

Review code against the project's rules and standards. Read-only: never switches branches and never edits.

## Input

Invoke optionally followed by a file path, branch name, or GitHub PR URL:

- No argument → review the current diff (staged + unstaged)
- `path/to/file` → review a specific file
- `<branch>` → review its diff against the base branch
- `https://github.com/.../pull/123` → review the PR diff

## 1. Determine scope

- **No argument**: `git diff HEAD`
- **File path** (contains `/` or `.` but not `github.com`): read the file directly
- **Branch name**: `git fetch origin <branch>` then `git diff main...origin/<branch>`
- **GitHub PR URL**: extract repo and number, then
  1. `gh pr view <number> --repo <owner>/<repo> --json headRefName,baseRefName`
  2. `git fetch origin <headRefName>`
  3. `git diff origin/<baseRefName>...origin/<headRefName>`

Never run `git checkout`: it would change the branch of whoever called the check.

## 2. Load project rules

Load only what exists, in this order:

1. `<repo>/.commons/ai/rules/shared/*.md`
2. By extension in the diff, under `<repo>/.commons/ai/rules/`:
   - `.sh`, `.zsh`, `.bash` → `shell/main.md`
   - `.ex`, `.exs` → `elixir/*.md`
   - `.py` → `django/*.md`
   - `.rb` → `ruby/main.md` + skill `br4zz4:rails`
   - `.ts`, `.tsx`, `.js`, `.jsx` → `react/*.md`
   - `.tf` → `terraform/main.md`
   - `compose.yml`, `compose.*.yml`, `docker-compose.yml` → skill `br4zz4:docker`
3. The repo's `AGENTS.md`
4. Skill `br4zz4:patterns`, plus `br4zz4:architecture` when the diff touches application code organized in ports/core/bridges/platform

If `.commons/ai/rules/` does not exist, apply only steps 3 and 4 and state in the report: "no commons rules found".

## 3. Review

Evaluate each changed file against the loaded rules. Focus on:

- Code quality and size limits
- Style and naming conventions
- Architecture and layer boundaries
- Documentation requirements
- Test structure (if test files are in scope)
- Seeds and fixtures: if the diff introduces or changes models/entities, verify factories and seeds exist and are idempotent
- Docker compose: apply `br4zz4:docker` when a compose file is in scope

## 4. Report

Group findings by file. For each issue:

- State the rule violated
- Quote the offending code
- Suggest the fix

End with a summary: **X issues found** across Y files, grouped by severity (blocking / warning).

Only report actual violations — do not praise compliant code.
