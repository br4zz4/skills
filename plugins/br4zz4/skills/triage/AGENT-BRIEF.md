# Writing Agent Briefs

An agent brief is a structured comment posted on a GitHub issue or PR once it moves to `ready-for-agent`. It is the authoritative specification an AFK agent works from. The original body and the discussion are background; the agent brief is the contract.

A brief states **what the agent must do**, and this covers both surfaces: for an issue it means building the change from scratch; for a PR it means what remains *on the existing diff*: finishing it, closing gaps, handling review points. The principles are identical, and the PR example below shows the difference.

## Principles

### Durability over precision

An issue can sit in `ready-for-agent` for days or weeks, while the codebase keeps changing. Write the brief so it stays useful even after files are renamed, moved, or refactored.

- **Do** describe interfaces, types, and behavioral contracts
- **Do** name the specific types, function signatures, or config shapes the agent should find or modify
- **Don't** cite file paths, since they go stale
- **Don't** cite line numbers
- **Don't** assume the present implementation structure will survive

### Behavioral, not procedural

Say **what** the system should do, not **how** to build it. The agent will explore the codebase fresh and make its own implementation choices.

- **Good:** "The `PaymentConfig` type should accept an optional `retry_schedule` field of type `CronExpression`"
- **Bad:** "Open app/models/payment_config.rb and add a retry_schedule attribute on line 42"
- **Good:** "When a user runs `/br4zz4:triage` with no arguments, they should get a summary of the issues needing attention"
- **Bad:** "Add a case statement inside the main handler method"

### Complete acceptance criteria

The agent has to know when it is finished. Each brief needs concrete, testable acceptance criteria, each one verifiable on its own.

- **Good:** "Running `gh issue list --label needs-triage` returns the issues that have completed initial classification"
- **Bad:** "Triage should work correctly"

### Explicit scope boundaries

Spell out what is out of scope. That keeps the agent from gold-plating or guessing about neighbouring features.

## Template

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** one line saying what has to happen

**Current behavior:**
Say what happens today. For a bug, that is the broken behavior.
For an enhancement, it is the status quo the feature builds on.

**Desired behavior:**
Say what should happen once the agent's work is done.
Be exact about edge cases and error conditions.

**Key interfaces:**
- `TypeName`: what must change and why
- `functionName()` return type: what it returns now versus what it should return
- Config shape: any new configuration options required

**Acceptance criteria:**
- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] Specific, testable criterion 3

**Out of scope:**
- Something that must NOT be changed or addressed in this issue
- A neighbouring feature that looks related but is separate
```

## Examples

### Good agent brief (bug)

```markdown
## Agent Brief

**Category:** bug
**Summary:** Truncating a skill description cuts words in half and yields broken text

**Current behavior:**
A skill description longer than 1024 characters is cut at exactly
1024 characters, ignoring word boundaries. The result ends
mid-word (for example "Use when the user wants to confi").

**Desired behavior:**
Truncation should stop at the last word boundary before 1024 characters
and append "..." to show that text was removed.

**Key interfaces:**
- The `description` field of the `SkillMetadata` type: no type change is
  needed, but the validation/processing logic that fills it must respect
  word boundaries
- Any function that reads SKILL.md frontmatter and extracts the description

**Acceptance criteria:**
- [ ] Descriptions of 1024 characters or fewer are left unchanged
- [ ] Longer descriptions are cut at the last word boundary
      before 1024 characters
- [ ] Truncated descriptions end with "..."
- [ ] The total length, "..." included, never exceeds 1024 characters

**Out of scope:**
- Changing the 1024 character limit itself
- Support for multi-line descriptions
```

### Good agent brief (enhancement)

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Support a `.out-of-scope/` directory that tracks rejected feature requests

**Current behavior:**
A rejected feature request gets its issue closed with a `wontfix` label
and a comment. Nothing durable records the decision or the reasoning.
Later, similar requests force the maintainer to remember or search for the
earlier discussion.

**Desired behavior:**
Rejected feature requests should be documented in `.out-of-scope/<concept>.md`
files that hold the decision, the reasoning, and links to every issue that
asked for the feature. While triaging new issues, these files should be
consulted for matches.

**Key interfaces:**
- Markdown file format in `.out-of-scope/`: every file needs a
  `# Concept Name` heading, a `**Decision:**` line, a `**Reason:**` line,
  and a `**Prior requests:**` list with issue links
- The triage workflow should read all `.out-of-scope/*.md` files early
  and compare incoming issues to them by concept similarity

**Acceptance criteria:**
- [ ] Closing a feature as wontfix creates or updates a file in `.out-of-scope/`
- [ ] The file holds the decision, the reasoning, and a link to the closed issue
- [ ] When a matching `.out-of-scope/` file already exists, the new issue is
      appended to its "Prior requests" list instead of creating a duplicate
- [ ] During triage, existing `.out-of-scope/` files are checked and shown
      when a new issue matches an earlier rejection

**Out of scope:**
- Automated matching (a human confirms the match)
- Reopening previously rejected features
- Bug reports (only enhancement rejections go to `.out-of-scope/`)
```

### Good agent brief (PR)

For a PR, "Current behavior" describes the state of the diff, and the brief asks the agent to finish or fix it rather than start over.

```markdown
## Agent Brief

**Category:** enhancement
**Summary:** Complete the contributor's `--json` output flag for `triage list`

**Current behavior:**
The PR introduces a `--json` flag that serializes the issue list as JSON. The
happy path works and the diff follows the project's command structure. Two gaps
remain: errors still print as human-readable text (not JSON), and the new flag
has no test coverage.

**Desired behavior:**
With `--json`, all output (errors included) is well-formed JSON on stdout,
and the command's exit codes stay the same. The existing human-readable output
is untouched when the flag is absent.

**Key interfaces:**
- Under `--json`, the command's error path should emit `{ "error": string }`
  rather than the plain-text error
- Reuse the serializer the PR already added; do not add a second one

**Acceptance criteria:**
- [ ] `triage list --json` emits valid JSON in both the success and error cases
- [ ] Exit codes are identical to the non-JSON command
- [ ] Tests exercise `--json` for a success run and for one failing run
- [ ] Default (non-JSON) output stays byte-for-byte identical

**Out of scope:**
- Adding `--json` to any other command
- Altering the JSON structure of the success payload already defined in the PR
```

### Bad agent brief

```markdown
## Agent Brief

**Summary:** Fix the triage bug

**What to do:**
Triage misbehaves somehow. Open the main file and repair it.
The method around line 150 has the problem.

**Files to change:**
- app/services/triage/handler.rb (line 150)
- app/models/issue.rb (line 42)
```

This brief fails for several reasons:
- No category
- A vague description ("the triage thing is broken")
- File paths and line numbers that will go stale
- No acceptance criteria
- No scope boundaries
- No account of current versus desired behavior
