---
name: code-review
description: "Review everything changed since a fixed point (commit, branch, tag, or merge-base) on two axes: Standards (does the code respect the repo's documented coding standards?) and Spec (does it implement what the originating issue or spec asked for?). Both reviews run in parallel sub-agents and are reported side by side. Use when the user wants a branch, a PR, or work in progress reviewed, or says \"review since X\"."
---

This is a two-axis review of the diff between `HEAD` and a fixed point supplied by the user:

- **Standards**: does the code follow the coding standards documented in this repo?
- **Spec**: does the code implement the originating issue or spec faithfully?

Each axis runs in its own **parallel sub-agent**, so neither pollutes the other's context. This skill then gathers what they report.

The issue tracker should already be known to you. When `docs/agents/issue-tracker.md` does not exist, tell the user to run `/br4zz4:setup-repo`.

## Process

### 1. Pin the fixed point

Take the user's words as the fixed point: a commit SHA, branch name, tag, `main`, `HEAD~5`, and so on. Ask for one if none was given.

Record the diff command once: `git diff <fixed-point>...HEAD` (three dots, so the comparison starts at the merge-base). Also record the commits with `git log <fixed-point>..HEAD --oneline`.

Before moving on, check that the fixed point resolves (`git rev-parse <fixed-point>`) and that the diff has content. A bad ref or an empty diff must fail at this step, not inside two parallel sub-agents.

### 2. Find the spec

Search for the originating spec in this order:

1. Issue references in commit messages (`#123`, `Closes #45`, GitLab `!67`, ...), fetched using the workflow from `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A spec file in `docs/`, `specs/`, or `.scratch/` whose name matches the branch or the feature.
4. Nothing found: ask the user where the spec is. If they answer that there is none, the **Spec** sub-agent is skipped and the report says "no spec available".

### 3. Find the standards

Collect every file in the repo that documents how code should be written, for example `CODING_STANDARDS.md`, `CONTRIBUTING.md`, or the rules in `AGENTS.md`.

Beyond what the repo documents, the Standards axis always applies the **smell baseline** below: a fixed list of Fowler code smells (_Refactoring_, ch.3) that stays active even in a repo with no documented standards. Two rules govern it:

- **The repo wins.** A documented repo standard takes precedence; if it endorses something the baseline would flag, drop that smell.
- **Judgement only.** Every smell is a labelled heuristic ("possible Feature Envy"), not a hard violation. As with any standard here, ignore whatever tooling already enforces (RuboCop, ESLint, and similar).

Each smell is written as *what it is* → *how to fix*; compare each one with the diff:

- **Mysterious Name**: a function, variable, or type whose name does not say what it does or holds. → rename it; if no honest name comes to mind, the design is unclear.
- **Duplicated Code**: the same logic shape shows up in more than one hunk or file of the change. → extract the shared shape and call it from each place.
- **Feature Envy**: a method that uses another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same handful of fields or params always travel together (a type waiting to exist). → bundle them into one type and pass that.
- **Primitive Obsession**: a primitive or string stands in for a domain concept that deserves a type. → give the concept its own small type.
- **Repeated Switches**: the same `switch` or `if` cascade on one type appears again and again in the change. → use polymorphism, or a single map shared by every site.
- **Shotgun Surgery**: one logical change forces edits scattered across many files of the diff. → gather the things that change together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split it so each module changes for exactly one reason.
- **Speculative Generality**: abstractions, parameters, or hooks added for needs the spec never mentions. → delete them; inline until a real need appears.
- **Message Chains**: a long `a.b().c().d()` walk that the caller should not know about. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly forwards calls elsewhere. → remove it and call the real target directly.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance and compose instead.

### 4. Launch both sub-agents in parallel

**The Standards sub-agent prompt** must contain:

- The complete diff command and the list of commits.
- The standards files found in step 3, **and the whole smell baseline from step 3** pasted in (the sub-agent cannot see it any other way).
- This brief: "For each file or hunk where it applies, report (a) every place where the diff breaks a documented standard, citing the standard (file plus rule); and (b) every baseline smell you notice, naming it and quoting the hunk. Separate hard violations from judgement calls: breaking a documented standard can be a hard violation, while baseline smells are only judgement calls, and a documented repo standard overrides the baseline. Skip what tooling enforces. Stay under 400 words."

**The Spec sub-agent prompt** must contain:

- The diff command and the list of commits.
- The spec's path, or its fetched contents.
- This brief: "Report: (a) requirements in the spec that are missing or only partly done; (b) behaviour in the diff that nobody asked for (scope creep); (c) requirements that seem implemented but whose implementation looks wrong. Quote the spec line behind each finding. Stay under 400 words."

With no spec available, skip the Spec sub-agent and say so in the final report.

### 5. Aggregate

Show the two reports under the headings `## Standards` and `## Spec`, verbatim or lightly tidied. Do **not** merge them or re-rank the findings: the axes are intentionally kept apart (see _Why two axes_).

Close with a single summary line: the number of findings on each axis and the worst issue _inside each axis_, if there is one. Never choose one overall winner across axes, since that is exactly the re-ranking the separation prevents.

## Why two axes

A change can satisfy one axis and fail the other:

- Code that respects every standard but builds the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but ignores the project's conventions → **Spec pass, Standards fail.**

Separate reports keep one axis from hiding the other.
