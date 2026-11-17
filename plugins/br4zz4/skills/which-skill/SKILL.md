---
name: which-skill
description: Find out which skill or flow suits your situation. A router across every skill in this plugin.
disable-model-invocation: true
---

# Which skill?

Nobody remembers every skill, so ask here.

A **flow** is a path through the skills. Most paths run along one **main flow**, and two **on-ramps** join it. Everything else stands alone, or is a vocabulary layer that sits underneath.

## The main flow: idea → ship

This is the route most work takes. You have an idea and want it built.

1. **`/br4zz4:grill-with-docs`** sharpens the idea through an interview. Begin here whenever you are **inside a working directory**: it keeps state, storing what it learns in `CONTEXT.md` and ADRs. (No working directory? Use `/br4zz4:grill-me` instead, described under Standalone. Both run the same `/br4zz4:grilling` primitive; `grill-with-docs` is the one that leaves a paper trail, so it is the better choice whenever a repo exists to hold it.)
2. **Branch: can every question be settled by talking?** If a question needs a runnable answer (state, business logic, a UI you must see), take a detour through a prototype, bridged by **`/br4zz4:handoff`** in both directions (a prototype lives in its own directory, which is precisely what `/br4zz4:handoff` is for; see Phase boundaries):
   - **`/br4zz4:handoff`** out, then open a fresh session on that file,
   - **`/br4zz4:prototype`** to answer the question with throwaway code,
   - **`/br4zz4:handoff`** what you learned back, and reference it from the original idea thread.
3. **Branch: is it a build spanning several sessions?**
   - **Yes** → **`/br4zz4:to-spec`** (turn the thread into a spec), then **`/br4zz4:to-tickets`** to cut it into tracer-bullet tickets, each declaring its **blocking edges**. On a local tracker that means one file per ticket under `.scratch/<feature>/issues/`, worked by hand with blockers first; on a real tracker the edges become native blocking links, so any ticket whose blockers are done can be taken: start **`/br4zz4:implement`** for each ticket and **`/clear` the context between them**. Every ticket is self-contained, so the previous one's context can be discarded.
   - **No** → **`/br4zz4:implement`** right here, in the same context window.

   Either way, **`/br4zz4:implement`** builds every issue by running **`/br4zz4:tdd`** inside it (one red-green slice at a time), then finishes with **`/br4zz4:code-review`**, a two-axis review (Standards + Spec) of the diff, before committing. Use **`/br4zz4:tdd`** alone when you only want to build a concrete behaviour test-first without a full spec, and **`/br4zz4:code-review`** alone whenever you want a branch or PR reviewed against a fixed point.

### Context hygiene

Keep steps 1–3 in **one unbroken context window** (no compact or clear until after `/br4zz4:to-tickets`), so the grilling, the spec, and the tickets all rest on the same thinking. Each `/br4zz4:implement` then starts clean, working from its ticket.

The limit is the **smart zone**: the window (about 150k tokens on current top models) in which the model still reasons sharply. If a session gets close to it before `/br4zz4:to-tickets`, do not push on while degraded; `/compact` at the nearest phase boundary and continue (see Phase boundaries).

## On-ramps

Starting situations that produce work and then join the main flow.

- **Bugs and requests piling up** → **`/br4zz4:triage`**. It moves issues through triage roles and produces agent-ready issues, which **`/br4zz4:implement`** picks up later.

  Triage applies only to issues **you did not create**: bug reports, incoming feature requests, anything that arrives raw. Tickets produced by `/br4zz4:to-tickets` are already agent-ready, so **do not triage them**.

- **Something is broken** → **`/br4zz4:diagnosing-bugs`**. For the hard cases: the bug that resists a first look, the intermittent flake, the regression that slipped in between two known-good states. It will not theorise until it has a **tight feedback loop** (one command that already fails on *this* bug), then fixes the bug with a regression test. Its post-mortem hands off to **`/br4zz4:improve-codebase-architecture`** when the real finding is that no good seam exists to pin the bug down.

- **A huge, foggy effort: a greenfield project or a giant feature, too big for one session** → **`/br4zz4:wayfinder`**, the most cognitively demanding flow here. When the way from here to the destination cannot be seen, it charts a **shared map** of **decision tickets** on the issue tracker and resolves them one by one, producing **decisions, not deliverables**, until the fog lifts and the way is clear. **`/br4zz4:grill-with-docs`** sharpens an idea you can hold in one session; wayfinder is for the idea you cannot, and it is slower and denser, so keep it for exactly that and never for a well-scoped feature.

  When the map clears, **it hands off, it does not build**: join the main flow at **`/br4zz4:to-spec`**, which folds the map's linked decisions into a buildable plan, then `/br4zz4:to-tickets` and `/br4zz4:implement` as usual. Feeding the map straight into `/br4zz4:implement` skips that folding and drops the linked detail, so go directly to `/br4zz4:implement` only when the effort proved small after all.

## Codebase health

Upkeep, not feature work.

- **`/br4zz4:improve-codebase-architecture`** is for any spare moment, to keep the codebase pleasant for agents to work in. It surfaces **deepening opportunities**; choosing one _produces an idea_ you can take into the main flow at `/br4zz4:grill-with-docs`. It is the survey that finds candidates; **`/br4zz4:codebase-design`** (below) is the workbench for designing the chosen one.

## Vocabulary underneath

Two model-invoked references that run *beneath* the other skills, each the single source of truth for its vocabulary. Use them directly when the **words**, not the process, are the problem, or let the skills above pull them in.

- **`/br4zz4:domain-modeling`**: sharpen the project's *domain* language: question a fuzzy term, settle an overloaded word ("account" doing three jobs), record a hard-to-reverse decision as an ADR. It is the active discipline that `/br4zz4:grill-with-docs` drives to keep `CONTEXT.md` a clean glossary.
- **`/br4zz4:codebase-design`** is the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: plenty of behaviour behind a small interface at a clean seam. `/br4zz4:tdd` and `/br4zz4:improve-codebase-architecture` both use it.

## Phase boundaries

A **phase** is a block of work inside a session: the grilling, the implementation, the QA. At the **boundary** between two of them you have five options, and choosing among them is the fuzziest decision in this whole map:

- **Continue**: stay put. It costs nothing and loses nothing.
- **`/clear`**: empty the window when nothing here matters for what comes next.
- **`/br4zz4:handoff`** writes a portable markdown file. Narrow use: only for a **new harness**, a **new directory**, a **colleague**, or forking a side task **mid-phase**. What it buys is portability.
- **Subagent**: send a tightly scoped task to its own window and receive a report.
- **`/compact`** compresses this context and seeds a fresh session with it. It is the **default**, at the bottom of the tree rather than the first thing to reach for.

Read [PHASE-BOUNDARIES.md](PHASE-BOUNDARIES.md) for the ordered tree: the five questions, the reasoning behind each branch, and why the cost of losing the primary source makes **Continue** the first option to rule out. Decide **at** a boundary; in the middle of a phase, continue or split the remainder across subagents.

## Standalone

Entirely off the main flow.

- **`/br4zz4:grill-me`**: the same relentless interview as `/br4zz4:grill-with-docs`, but **stateless**: nothing is saved locally and no `CONTEXT.md` is built. Use it when you are **not in a working directory** (sharpening a plan, a design, a piece of writing, anything without a repo under it). Inside a working directory, use `/br4zz4:grill-with-docs` instead: it runs the same interview and leaves a paper trail, so it is strictly the better one.
- **`/br4zz4:grilling`** is the interview primitive itself: rounds, the frontier, facts being the agent's job and decisions being yours. `/br4zz4:grill-me` and `/br4zz4:grill-with-docs` are its two named entry points, and `/br4zz4:triage`, `/br4zz4:wayfinder` and `/br4zz4:improve-codebase-architecture` all run it internally. Reach for it directly only when you want the interview with no wrapper.
- **`/br4zz4:resolving-merge-conflicts`** works through an in-progress merge or rebase conflict hunk by hunk, resolving by **intent** traced to each side's primary source instead of choosing lines, then finishes the operation. It never runs `--abort`. It is standalone and off every flow: use it when you are already mid-conflict.
- **`/br4zz4:prototype`** is a small, throwaway program that answers one design question: does this state model feel right, or what should this UI look like. Throwaway describes how the code is written, not a promise to destroy it: the answer folds into the real code, and the prototype itself stays as a **primary source** on a `prototype/<name>` branch out of main, pointed to from the implementation issue. It is the detour in step 2 of the main flow, but use it any time a design question is hard to settle on paper.
- **`/br4zz4:research`**: hand reading legwork to a **background agent**: it investigates a question against **primary sources**, then leaves a cited Markdown file in the repo. Keep working while it reads. The file is something to take *into* the main flow at `/br4zz4:grill-with-docs`, since research feeds the thinking and does not replace it.
- **`/br4zz4:to-questionnaire`** applies when what blocks you is not in your head or the codebase but in **someone else's**, and it writes them a questionnaire to fill in. It is the inverse of `/br4zz4:grill-me`: rather than interviewing you about the subject, it interviews you about the **send** (who gets it, what you need back) and aims the questions at the gap. What returns is material for `/br4zz4:grill-with-docs` or `/br4zz4:to-spec`.
- **`/br4zz4:wizard`** covers steps only a **human** can take: provisioning infrastructure, setting up credentials or CI secrets, clicking through an unfamiliar third-party dashboard, running a one-off migration or cutover. It generates an interactive bash script that opens each URL, captures each value, and writes it into `.env` and GitHub secrets, so the procedure stops being something you re-explain to an agent every time. It is model-invoked, so the agent reaches for it the moment it meets a wall only you can pass. If the agent can simply do the step, it should; this is for where a human is truly in the loop.
- **`/br4zz4:wait-what`** corrects a message that did not land. Use it mid-conversation, inside any other skill, and the agent re-pitches what it just said with the context you were missing, in plain English, using the `CONTEXT.md` vocabulary. It works after the fact; `/br4zz4:grill-with-docs` is the upfront cure, because a shared language agreed early stops the jargon from arriving at all.
- **`/br4zz4:teach`**: learn a concept across several sessions, using the current directory as a stateful workspace.
- **`/br4zz4:writing-for-agents`** is the reference for writing documents that agents consume: skills, AGENTS.md, docs they are pointed to.

## Precondition

**`/br4zz4:setup-repo`**: run it before your first engineering flow to configure the issue tracker, triage labels, and doc layout that the other skills assume. Custom issue trackers work too.

## Project and operations skills

Day-to-day skills for the repo and the dev environment, independent of the flows above:

- **`/br4zz4:architecture`**, **`/br4zz4:patterns`**, **`/br4zz4:rails`**: how to structure and write application code.
- **`/br4zz4:spec`**, **`/br4zz4:team`**, **`/br4zz4:structure`**: planning a change, the agent roster and delegation, and how projects are laid out.
- **`/br4zz4:check`**, **`/br4zz4:verify`**, **`/br4zz4:finish`**: review against project rules, confirm work before claiming it done, and integrate and clean up.
- **`/br4zz4:commit`**, **`/br4zz4:pr`**, **`/br4zz4:worktree`**: commits, pull requests, and git worktrees.
- **`/br4zz4:ci`**, **`/br4zz4:docker`**, **`/br4zz4:make`**, **`/br4zz4:credentials`**, **`/br4zz4:cross-platform`**: workflows, containers, Makefiles, secrets, and macOS plus Linux compatibility.
- **`/br4zz4:docs`**, **`/br4zz4:find-in-root`**, **`/br4zz4:vision`**: documenting rules and learnings, searching across projects, and reading images.
- **`/br4zz4:qwert-ops`**, **`/br4zz4:qwert-opencode-plugin`**, **`/br4zz4:qwert-terminal-shortcut`**: operating qwert, building OpenCode plugins, and terminal shortcuts.
