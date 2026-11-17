---
name: to-tickets
description: Slice a plan, a spec, or the ongoing conversation into tracer-bullet tickets that each state their blocking edges, then publish them on the configured tracker (text edges inside one file per ticket when local, or native blocking links when the tracker is a real one).
disable-model-invocation: true
---

# To Tickets

Slice a plan, spec, or conversation into **tickets**, which are tracer-bullet vertical slices that each name the tickets **blocking** them.

The issue tracker and the triage label vocabulary should already be known to you. Otherwise, send the user to `/br4zz4:setup-repo`.

## Process

### 1. Gather context

Start from what the conversation already holds. If the user passes a reference as an argument (a spec path, an issue number, or a URL), fetch it and read the whole body plus its comments.

### 2. Explore the codebase (optional)

If the codebase is still unexplored, look through it now to learn its current state. Titles and descriptions of tickets should use the project's domain glossary vocabulary and honour the ADRs covering the touched area.

Watch for prefactoring that would simplify the implementation: make the change easy, then make the easy change.

### 3. Draft vertical slices

Cut the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Every slice is a narrow yet COMPLETE path across all layers (schema, API, UI, tests). It is vertical, NOT a horizontal cut of one layer
- A finished slice can be demoed or verified on its own
- Size each slice to fit inside one fresh context window
- Put any prefactoring first

</vertical-slice-rules>

Give each ticket its **blocking edges**, meaning the other tickets that have to complete before it begins. A ticket with no blockers can begin immediately.

**Wide refactors break the vertical-slice rule.** A **wide refactor** is a single mechanical change (renaming a column, retyping a shared symbol) with a **blast radius** that spreads across the entire codebase, so one edit breaks thousands of call sites together and no vertical slice can land green. Forcing it into a tracer bullet fails. Sequence it as **expand–contract** instead. Expand first by adding the new form alongside the old, leaving everything working. Next, migrate call sites in batches sized to the blast radius (per package or directory), each batch being its own ticket blocked by the expand, and CI stays green between batches since the old form survives. Contract last, deleting the old form once nothing calls it, in a ticket blocked by every migrate batch. If even individual batches can't stay green, retain the sequence but let them share an integration branch, with all of them blocking one final integrate-and-verify ticket, where green is promised only at the end.

### 4. Quiz the user

Show the proposed breakdown as a numbered list. For every ticket, list:

- **Title**: a short, descriptive name
- **Blocked by**: the other tickets, if any, that need to finish beforehand
- **What it delivers**: the end-to-end behaviour that this ticket makes work

Then ask the user:

- Does the granularity feel right, or is it too coarse or too fine?
- Do the blocking edges hold, with each ticket depending only on tickets that really gate it?
- Would any tickets be better merged, or split further?

Keep iterating until the user signs off on the breakdown.

### 5. Publish the tickets to the configured tracker

Now publish the approved set. **How** depends on the tracker that `/br4zz4:setup-repo` set up. The tickets themselves don't change, only the form of the blocking edges:

- **Local files** → write each ticket to its own file at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbering from `01` in dependency order with blockers first. In every file, "Blocked by" names the numbers or titles it relies on. Use the per-ticket template below, with one ticket per file and never a combined file.
- **A real issue tracker (GitHub, Linear, …)** → create one issue per ticket, going in dependency order with blockers first, so blocking edges can cite real identifiers. Use the platform's native blocking or sub-issue relation if it offers one; if not, fill each ticket's "Blocked by" with the blocking issues. Apply the `ready-for-agent` triage label unless told otherwise, since tickets are agent-grabbable by construction.

Work the **frontier**, which is every ticket whose blockers are all complete. In a purely linear chain, that simply means working from the top down.

Leave any parent issue open and unchanged.

<local-ticket-template>

# <NN> - <Ticket title>

**What to build:** the end-to-end behaviour this ticket enables, seen from the user's side and not as a list of per-layer implementation work.

**Blocked by:** the numbers or titles of gating tickets, or write "None (can start immediately)".

**Status:** ready-for-agent

- [ ] First acceptance criterion
- [ ] Second acceptance criterion

</local-ticket-template>

<issue-template>

## Parent

A link to the parent issue on the tracker. Include it only when the source was an existing issue; otherwise drop the section.

## What to build

The end-to-end behaviour that this ticket makes work, from the user's side, not an implementation split by layer.

## Acceptance criteria

- [ ] First criterion
- [ ] Second criterion

## Blocked by

- One link per blocking ticket; if there are none, write "None (can start immediately)".

</issue-template>

Both forms should omit specific file paths and code snippets, which go stale quickly. One exception: if a prototype yielded a snippet that captures a decision better than prose could (a state machine, reducer, schema, or type shape), inline it and briefly mention its prototype origin. Cut it down to the parts that carry the decision; leave out any working demo and keep only the key bits.
